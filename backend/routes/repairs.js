const express = require('express');
const { body, param, query, validationResult } = require('express-validator');
const { Repair, Car } = require('../models');
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

// POST /api/repairs - 添加维修记录
router.post('/', [
  body('car_id')
    .optional()
    .isInt()
    .withMessage('车辆ID必须是整数'),
  body('plate_number')
    .if(body('car_id').not().exists())
    .notEmpty()
    .withMessage('车牌号不能为空'),
  body('repair_date')
    .notEmpty()
    .withMessage('维修日期不能为空')
    .isDate()
    .withMessage('维修日期格式不正确'),
  body('item')
    .notEmpty()
    .withMessage('维修项目不能为空')
    .isLength({ min: 1, max: 1000 })
    .withMessage('维修项目描述长度必须在1-1000个字符之间'),
  body('price')
    .isFloat({ min: 0 })
    .withMessage('维修费用必须是大于等于0的数字'),
  body('note')
    .optional()
    .isLength({ max: 1000 })
    .withMessage('备注不能超过1000个字符'),
  body('mechanic')
    .optional()
    .isLength({ max: 50 })
    .withMessage('维修师傅姓名不能超过50个字符'),
  body('garage_name')
    .optional()
    .isLength({ max: 100 })
    .withMessage('维修厂名称不能超过100个字符')
], handleValidationErrors, async (req, res) => {
  try {
    const { car_id, plate_number, repair_date, item, price, note, mechanic, garage_name } = req.body;
    
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

    const repair = await Repair.create({
      car_id: carId,
      repair_date,
      item: item.trim(),
      price: parseFloat(price),
      note: note?.trim(),
      mechanic: mechanic?.trim(),
      garage_name: garage_name?.trim()
    });

    // 获取完整的维修记录（包含车辆信息）
    const fullRepair = await Repair.findByPk(repair.id, {
      include: [{
        model: Car,
        as: 'car',
        attributes: ['id', 'plate_number', 'vin', 'brand', 'model']
      }]
    });

    res.status(201).json({
      success: true,
      message: '维修记录添加成功',
      data: fullRepair
    });
  } catch (error) {
    console.error('添加维修记录失败:', error);
    res.status(500).json({
      success: false,
      message: '添加维修记录失败',
      code: 'CREATE_REPAIR_ERROR'
    });
  }
});

// GET /api/repairs - 获取维修记录列表
router.get('/', [
  query('page').optional().isInt({ min: 1 }).withMessage('页码必须是大于0的整数'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('每页数量必须是1-100之间的整数'),
  query('car_id').optional().isInt().withMessage('车辆ID必须是整数'),
  query('start_date').optional().isDate().withMessage('开始日期格式不正确'),
  query('end_date').optional().isDate().withMessage('结束日期格式不正确')
], handleValidationErrors, async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 10, 
      car_id, 
      plate_number,
      start_date, 
      end_date,
      search 
    } = req.query;
    
    const offset = (page - 1) * limit;
    const whereClause = {};
    
    // 车辆过滤
    if (car_id) {
      whereClause.car_id = car_id;
    }
    
    // 日期范围过滤
    if (start_date || end_date) {
      whereClause.repair_date = {};
      if (start_date) {
        whereClause.repair_date[Op.gte] = start_date;
      }
      if (end_date) {
        whereClause.repair_date[Op.lte] = end_date;
      }
    }
    
    // 搜索过滤
    if (search) {
      whereClause[Op.or] = [
        { item: { [Op.iLike]: `%${search}%` } },
        { note: { [Op.iLike]: `%${search}%` } },
        { mechanic: { [Op.iLike]: `%${search}%` } },
        { garage_name: { [Op.iLike]: `%${search}%` } }
      ];
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

    const { count, rows: repairs } = await Repair.findAndCountAll({
      where: whereClause,
      include: includeClause,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['repair_date', 'DESC'], ['created_at', 'DESC']]
    });

    res.json({
      success: true,
      message: '查询成功',
      data: {
        repairs,
        pagination: {
          current: parseInt(page),
          limit: parseInt(limit),
          total: count,
          pages: Math.ceil(count / limit)
        }
      }
    });
  } catch (error) {
    console.error('获取维修记录列表失败:', error);
    res.status(500).json({
      success: false,
      message: '获取维修记录列表失败',
      code: 'LIST_REPAIRS_ERROR'
    });
  }
});

// GET /api/repairs/:id - 获取单个维修记录详情
router.get('/:id', [
  param('id').isInt().withMessage('维修记录ID必须是整数')
], handleValidationErrors, async (req, res) => {
  try {
    const { id } = req.params;
    
    const repair = await Repair.findByPk(id, {
      include: [{
        model: Car,
        as: 'car',
        attributes: ['id', 'plate_number', 'vin', 'brand', 'model', 'year', 'color']
      }]
    });

    if (!repair) {
      return res.status(404).json({
        success: false,
        message: '未找到该维修记录',
        code: 'REPAIR_NOT_FOUND'
      });
    }

    res.json({
      success: true,
      message: '查询成功',
      data: repair
    });
  } catch (error) {
    console.error('获取维修记录详情失败:', error);
    res.status(500).json({
      success: false,
      message: '获取维修记录详情失败',
      code: 'GET_REPAIR_ERROR'
    });
  }
});

// PUT /api/repairs/:id - 更新维修记录
router.put('/:id', [
  param('id').isInt().withMessage('维修记录ID必须是整数'),
  body('repair_date')
    .optional()
    .isDate()
    .withMessage('维修日期格式不正确'),
  body('item')
    .optional()
    .notEmpty()
    .withMessage('维修项目不能为空')
    .isLength({ min: 1, max: 1000 })
    .withMessage('维修项目描述长度必须在1-1000个字符之间'),
  body('price')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('维修费用必须是大于等于0的数字'),
  body('note')
    .optional()
    .isLength({ max: 1000 })
    .withMessage('备注不能超过1000个字符'),
  body('mechanic')
    .optional()
    .isLength({ max: 50 })
    .withMessage('维修师傅姓名不能超过50个字符'),
  body('garage_name')
    .optional()
    .isLength({ max: 100 })
    .withMessage('维修厂名称不能超过100个字符')
], handleValidationErrors, async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    const repair = await Repair.findByPk(id);
    if (!repair) {
      return res.status(404).json({
        success: false,
        message: '未找到该维修记录',
        code: 'REPAIR_NOT_FOUND'
      });
    }

    // 清理和转换数据
    if (updateData.item) {
      updateData.item = updateData.item.trim();
    }
    if (updateData.note) {
      updateData.note = updateData.note.trim();
    }
    if (updateData.mechanic) {
      updateData.mechanic = updateData.mechanic.trim();
    }
    if (updateData.garage_name) {
      updateData.garage_name = updateData.garage_name.trim();
    }
    if (updateData.price !== undefined) {
      updateData.price = parseFloat(updateData.price);
    }

    await repair.update(updateData);

    // 获取更新后的完整记录
    const updatedRepair = await Repair.findByPk(id, {
      include: [{
        model: Car,
        as: 'car',
        attributes: ['id', 'plate_number', 'vin', 'brand', 'model']
      }]
    });

    res.json({
      success: true,
      message: '维修记录更新成功',
      data: updatedRepair
    });
  } catch (error) {
    console.error('更新维修记录失败:', error);
    res.status(500).json({
      success: false,
      message: '更新维修记录失败',
      code: 'UPDATE_REPAIR_ERROR'
    });
  }
});

// DELETE /api/repairs/:id - 删除维修记录
router.delete('/:id', [
  param('id').isInt().withMessage('维修记录ID必须是整数')
], handleValidationErrors, async (req, res) => {
  try {
    const { id } = req.params;
    
    const repair = await Repair.findByPk(id);
    if (!repair) {
      return res.status(404).json({
        success: false,
        message: '未找到该维修记录',
        code: 'REPAIR_NOT_FOUND'
      });
    }

    await repair.destroy();

    res.json({
      success: true,
      message: '维修记录删除成功'
    });
  } catch (error) {
    console.error('删除维修记录失败:', error);
    res.status(500).json({
      success: false,
      message: '删除维修记录失败',
      code: 'DELETE_REPAIR_ERROR'
    });
  }
});

// GET /api/repairs/export - 导出维修记录CSV
router.get('/export', async (req, res) => {
  try {
    const repairs = await Repair.findAll({ include: [{ model: Car, as: 'car' }] });
    const fields = ['id', 'car_id', 'repair_date', 'item', 'price', 'note'];
    const header = fields.join(',');
    const rows = repairs.map(r =>
      fields.map(f => {
        const val = f === 'car_id' ? r.car_id : r[f];
        return `"${(val ?? '').toString().replace(/"/g, '""')}"`;
      }).join(',')
    );
    const csv = [header, ...rows].join('\n');
    res.header('Content-Type', 'text/csv');
    res.attachment('repairs.csv');
    res.send(csv);
  } catch (error) {
    console.error('导出维修记录失败:', error);
    res.status(500).json({ success: false, message: '导出维修记录失败' });
  }
});

module.exports = router;
