const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { WashLog, Car } = require('../models');
const { Op } = require('sequelize');
const auth = require('../middleware/auth');

const router = express.Router();
router.use(auth);

// 验证中间件
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: '请求参数验证失败',
      errors: errors.array().map(err => err.msg),
      code: 'VALIDATION_ERROR'
    });
  }
  next();
};

// POST /api/wash - 添加洗车记录
router.post('/', [
  body('car_id')
    .optional()
    .isInt()
    .withMessage('车辆ID必须是整数'),
  body('plate_number')
    .if(body('car_id').not().exists())
    .notEmpty()
    .withMessage('车牌号不能为空'),
  body('wash_time')
    .optional()
    .isISO8601()
    .withMessage('洗车时间格式不正确'),
  body('wash_type')
    .optional()
    .isIn(['self', 'auto', 'manual'])
    .withMessage('洗车类型必须是self、auto或manual其中之一'),
  body('price')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('洗车费用必须是大于等于0的数字'),
  body('location')
    .optional()
    .isLength({ max: 100 })
    .withMessage('洗车地点不能超过100个字符'),
  body('note')
    .optional()
    .isLength({ max: 500 })
    .withMessage('备注不能超过500个字符')
], handleValidationErrors, async (req, res) => {
  try {
    const { 
      car_id, 
      plate_number, 
      wash_time, 
      wash_type = 'manual', 
      price = 0, 
      location, 
      note 
    } = req.body;
    
    let carId = car_id;
    
    // 如果没有car_id，通过车牌号查找
    if (!carId && plate_number) {
      const car = await Car.findOne({
        where: { 
          plate_number: { 
            [Op.iLike]: plate_number.trim().toUpperCase() 
          } 
        }
      });
      
      if (!car) {
        return res.status(404).json({
          success: false,
          message: '未找到该车牌号对应的车辆，请先添加车辆信息',
          code: 'CAR_NOT_FOUND'
        });
      }
      carId = car.id;
    }
    
    if (!carId) {
      return res.status(400).json({
        success: false,
        message: '必须提供车辆ID或车牌号',
        code: 'MISSING_CAR_INFO'
      });
    }

    const washData = {
      car_id: carId,
      wash_type,
      price: parseFloat(price),
      location: location?.trim(),
      note: note?.trim()
    };

    // 如果提供了洗车时间，使用提供的时间，否则使用当前时间
    if (wash_time) {
      washData.wash_time = new Date(wash_time);
    }

    const washLog = await WashLog.create(washData);

    // 获取完整的洗车记录（包含车辆信息）
    const fullWashLog = await WashLog.findByPk(washLog.id, {
      include: [{
        model: Car,
        as: 'car',
        attributes: ['id', 'plate_number', 'vin', 'brand', 'model']
      }]
    });

    res.status(201).json({
      success: true,
      message: '洗车记录添加成功',
      data: fullWashLog
    });
  } catch (error) {
    console.error('添加洗车记录失败:', error);
    res.status(500).json({
      success: false,
      message: '添加洗车记录失败',
      code: 'CREATE_WASH_ERROR'
    });
  }
});

// GET /api/wash/:plate_number - 获取某车辆的洗车次数和记录
router.get('/:plate_number', [
  param('plate_number')
    .notEmpty()
    .withMessage('车牌号不能为空')
    .isLength({ min: 1, max: 20 })
    .withMessage('车牌号长度必须在1-20个字符之间')
], handleValidationErrors, async (req, res) => {
  try {
    const { plate_number } = req.params;
    const { 
      start_date, 
      end_date, 
      wash_type,
      page = 1, 
      limit = 10 
    } = req.query;
    
    // 查找车辆
    const car = await Car.findOne({
      where: { 
        plate_number: { 
          [Op.iLike]: plate_number.trim().toUpperCase() 
        } 
      }
    });

    if (!car) {
      return res.status(404).json({
        success: false,
        message: '未找到该车辆信息',
        code: 'CAR_NOT_FOUND'
      });
    }

    // 构建查询条件
    const whereClause = { car_id: car.id };
    
    // 日期范围过滤
    if (start_date || end_date) {
      whereClause.wash_time = {};
      if (start_date) {
        whereClause.wash_time[Op.gte] = new Date(start_date);
      }
      if (end_date) {
        whereClause.wash_time[Op.lte] = new Date(end_date);
      }
    }
    
    // 洗车类型过滤
    if (wash_type && ['self', 'auto', 'manual'].includes(wash_type)) {
      whereClause.wash_type = wash_type;
    }

    // 获取洗车记录（分页）
    const offset = (page - 1) * limit;
    const { count, rows: washLogs } = await WashLog.findAndCountAll({
      where: whereClause,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['wash_time', 'DESC']],
      include: [{
        model: Car,
        as: 'car',
        attributes: ['id', 'plate_number', 'vin', 'brand', 'model']
      }]
    });

    // 统计信息
    const totalWashes = await WashLog.count({
      where: { car_id: car.id }
    });

    const totalCost = await WashLog.sum('price', {
      where: { car_id: car.id }
    }) || 0;

    // 按类型统计
    const typeStats = await WashLog.findAll({
      where: { car_id: car.id },
      attributes: [
        'wash_type',
        [require('sequelize').fn('COUNT', '*'), 'count'],
        [require('sequelize').fn('SUM', require('sequelize').col('price')), 'total_cost']
      ],
      group: ['wash_type'],
      raw: true
    });

    // 最近洗车时间
    const lastWash = await WashLog.findOne({
      where: { car_id: car.id },
      order: [['wash_time', 'DESC']],
      attributes: ['wash_time', 'wash_type', 'location']
    });

    const stats = {
      totalWashes,
      totalCost: parseFloat(totalCost),
      typeStats,
      lastWash,
      averageCost: totalWashes > 0 ? parseFloat(totalCost) / totalWashes : 0
    };

    res.json({
      success: true,
      message: '查询成功',
      data: {
        car: {
          id: car.id,
          plate_number: car.plate_number,
          vin: car.vin,
          brand: car.brand,
          model: car.model
        },
        washLogs,
        stats,
        pagination: {
          current: parseInt(page),
          limit: parseInt(limit),
          total: count,
          pages: Math.ceil(count / limit)
        }
      }
    });
  } catch (error) {
    console.error('获取洗车记录失败:', error);
    res.status(500).json({
      success: false,
      message: '获取洗车记录失败',
      code: 'GET_WASH_LOGS_ERROR'
    });
  }
});

// GET /api/wash - 获取所有洗车记录
router.get('/', [
  query('page').optional().isInt({ min: 1 }).withMessage('页码必须是大于0的整数'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('每页数量必须是1-100之间的整数'),
  query('car_id').optional().isInt().withMessage('车辆ID必须是整数'),
  query('start_date').optional().isISO8601().withMessage('开始日期格式不正确'),
  query('end_date').optional().isISO8601().withMessage('结束日期格式不正确')
], handleValidationErrors, async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 10, 
      car_id, 
      plate_number,
      start_date, 
      end_date,
      wash_type,
      location
    } = req.query;
    
    const offset = (page - 1) * limit;
    const whereClause = {};
    
    // 车辆过滤
    if (car_id) {
      whereClause.car_id = car_id;
    }
    
    // 日期范围过滤
    if (start_date || end_date) {
      whereClause.wash_time = {};
      if (start_date) {
        whereClause.wash_time[Op.gte] = new Date(start_date);
      }
      if (end_date) {
        whereClause.wash_time[Op.lte] = new Date(end_date);
      }
    }
    
    // 洗车类型过滤
    if (wash_type && ['self', 'auto', 'manual'].includes(wash_type)) {
      whereClause.wash_type = wash_type;
    }
    
    // 地点搜索
    if (location) {
      whereClause.location = { [Op.iLike]: `%${location}%` };
    }

    // 车牌号过滤（需要join查询）
    const includeClause = [{
      model: Car,
      as: 'car',
      attributes: ['id', 'plate_number', 'vin', 'brand', 'model'],
      ...(plate_number && {
        where: {
          plate_number: { [Op.iLike]: `%${plate_number}%` }
        }
      })
    }];

    const { count, rows: washLogs } = await WashLog.findAndCountAll({
      where: whereClause,
      include: includeClause,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['wash_time', 'DESC']]
    });

    res.json({
      success: true,
      message: '查询成功',
      data: {
        washLogs,
        pagination: {
          current: parseInt(page),
          limit: parseInt(limit),
          total: count,
          pages: Math.ceil(count / limit)
        }
      }
    });
  } catch (error) {
    console.error('获取洗车记录列表失败:', error);
    res.status(500).json({
      success: false,
      message: '获取洗车记录列表失败',
      code: 'LIST_WASH_LOGS_ERROR'
    });
  }
});

// PUT /api/wash/:id - 更新洗车记录
router.put('/:id', [
  param('id').isInt().withMessage('洗车记录ID必须是整数'),
  body('wash_time')
    .optional()
    .isISO8601()
    .withMessage('洗车时间格式不正确'),
  body('wash_type')
    .optional()
    .isIn(['self', 'auto', 'manual'])
    .withMessage('洗车类型必须是self、auto或manual其中之一'),
  body('price')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('洗车费用必须是大于等于0的数字'),
  body('location')
    .optional()
    .isLength({ max: 100 })
    .withMessage('洗车地点不能超过100个字符'),
  body('note')
    .optional()
    .isLength({ max: 500 })
    .withMessage('备注不能超过500个字符')
], handleValidationErrors, async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    const washLog = await WashLog.findByPk(id);
    if (!washLog) {
      return res.status(404).json({
        success: false,
        message: '未找到该洗车记录',
        code: 'WASH_LOG_NOT_FOUND'
      });
    }

    // 清理和转换数据
    if (updateData.location) {
      updateData.location = updateData.location.trim();
    }
    if (updateData.note) {
      updateData.note = updateData.note.trim();
    }
    if (updateData.price !== undefined) {
      updateData.price = parseFloat(updateData.price);
    }
    if (updateData.wash_time) {
      updateData.wash_time = new Date(updateData.wash_time);
    }

    await washLog.update(updateData);

    // 获取更新后的完整记录
    const updatedWashLog = await WashLog.findByPk(id, {
      include: [{
        model: Car,
        as: 'car',
        attributes: ['id', 'plate_number', 'vin', 'brand', 'model']
      }]
    });

    res.json({
      success: true,
      message: '洗车记录更新成功',
      data: updatedWashLog
    });
  } catch (error) {
    console.error('更新洗车记录失败:', error);
    res.status(500).json({
      success: false,
      message: '更新洗车记录失败',
      code: 'UPDATE_WASH_LOG_ERROR'
    });
  }
});

// DELETE /api/wash/:id - 删除洗车记录
router.delete('/:id', [
  param('id').isInt().withMessage('洗车记录ID必须是整数')
], handleValidationErrors, async (req, res) => {
  try {
    const { id } = req.params;
    
    const washLog = await WashLog.findByPk(id);
    if (!washLog) {
      return res.status(404).json({
        success: false,
        message: '未找到该洗车记录',
        code: 'WASH_LOG_NOT_FOUND'
      });
    }

    await washLog.destroy();

    res.json({
      success: true,
      message: '洗车记录删除成功'
    });
  } catch (error) {
    console.error('删除洗车记录失败:', error);
    res.status(500).json({
      success: false,
      message: '删除洗车记录失败',
      code: 'DELETE_WASH_LOG_ERROR'
    });
  }
});

// GET /api/wash/export - 导出洗车记录CSV
router.get('/export', async (req, res) => {
  try {
    const logs = await WashLog.findAll({ include: [{ model: Car, as: 'car' }] });
    const fields = ['id', 'car_id', 'wash_time', 'wash_type', 'price', 'location'];
    const header = fields.join(',');
    const rows = logs.map(l =>
      fields.map(f => {
        const val = f === 'car_id' ? l.car_id : l[f];
        return `"${(val ?? '').toString().replace(/"/g, '""')}"`;
      }).join(',')
    );
    const csv = [header, ...rows].join('\n');
    res.header('Content-Type', 'text/csv');
    res.attachment('wash_logs.csv');
    res.send(csv);
  } catch (error) {
    console.error('导出洗车记录失败:', error);
    res.status(500).json({ success: false, message: '导出洗车记录失败' });
  }
});

module.exports = router;
