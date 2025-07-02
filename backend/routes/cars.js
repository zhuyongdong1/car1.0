const express = require('express');
const { body, param, validationResult } = require('express-validator');
const { Car, Repair, WashLog } = require('../models');
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

// POST /api/cars - 添加车辆
router.post('/', [
  body('plate_number')
    .notEmpty()
    .withMessage('车牌号不能为空')
    .isLength({ min: 1, max: 20 })
    .withMessage('车牌号长度必须在1-20个字符之间'),
  body('vin')
    .notEmpty()
    .withMessage('车架号不能为空')
    .isLength({ min: 17, max: 50 })
    .withMessage('车架号长度必须在17-50个字符之间'),
  body('brand')
    .optional()
    .isLength({ max: 50 })
    .withMessage('品牌名称不能超过50个字符'),
  body('model')
    .optional()
    .isLength({ max: 50 })
    .withMessage('型号不能超过50个字符'),
  body('year')
    .optional()
    .isInt({ min: 1900, max: new Date().getFullYear() + 1 })
    .withMessage('年份必须是1900年到明年之间的整数'),
  body('color')
    .optional()
    .isLength({ max: 20 })
    .withMessage('颜色不能超过20个字符')
], handleValidationErrors, async (req, res) => {
  try {
    const { plate_number, vin, brand, model, year, color } = req.body;
    
    const car = await Car.create({
      plate_number: plate_number.trim().toUpperCase(),
      vin: vin.trim().toUpperCase(),
      brand: brand?.trim(),
      model: model?.trim(),
      year,
      color: color?.trim()
    });

    res.status(201).json({
      success: true,
      message: '车辆添加成功',
      data: car
    });
  } catch (error) {
    console.error('添加车辆失败:', error);
    res.status(500).json({
      success: false,
      message: '添加车辆失败',
      code: 'CREATE_CAR_ERROR'
    });
  }
});

// GET /api/cars/:plate_number - 查询某辆车的所有记录
router.get('/:plate_number', [
  param('plate_number')
    .notEmpty()
    .withMessage('车牌号不能为空')
    .isLength({ min: 1, max: 20 })
    .withMessage('车牌号长度必须在1-20个字符之间')
], handleValidationErrors, async (req, res) => {
  try {
    const { plate_number } = req.params;
    
    const car = await Car.findOne({
      where: { 
        plate_number: { 
          [Op.iLike]: plate_number.trim().toUpperCase() 
        } 
      },
      include: [
        {
          model: Repair,
          as: 'repairs',
          order: [['repair_date', 'DESC']]
        },
        {
          model: WashLog,
          as: 'washLogs',
          order: [['wash_time', 'DESC']]
        }
      ]
    });

    if (!car) {
      return res.status(404).json({
        success: false,
        message: '未找到该车辆信息',
        code: 'CAR_NOT_FOUND'
      });
    }

    // 统计信息
    const stats = {
      totalRepairs: car.repairs.length,
      totalRepairCost: car.repairs.reduce((sum, repair) => sum + parseFloat(repair.price), 0),
      totalWashes: car.washLogs.length,
      totalWashCost: car.washLogs.reduce((sum, wash) => sum + parseFloat(wash.price), 0),
      lastRepairDate: car.repairs.length > 0 ? car.repairs[0].repair_date : null,
      lastWashDate: car.washLogs.length > 0 ? car.washLogs[0].wash_time : null
    };

    res.json({
      success: true,
      message: '查询成功',
      data: {
        car,
        stats
      }
    });
  } catch (error) {
    console.error('查询车辆记录失败:', error);
    res.status(500).json({
      success: false,
      message: '查询车辆记录失败',
      code: 'QUERY_CAR_ERROR'
    });
  }
});

// GET /api/cars - 获取所有车辆列表（支持搜索）
router.get('/', async (req, res) => {
  try {
    const { search, page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;
    
    const whereClause = {};
    if (search) {
      whereClause[Op.or] = [
        { plate_number: { [Op.iLike]: `%${search}%` } },
        { vin: { [Op.iLike]: `%${search}%` } },
        { brand: { [Op.iLike]: `%${search}%` } },
        { model: { [Op.iLike]: `%${search}%` } }
      ];
    }

    const { count, rows: cars } = await Car.findAndCountAll({
      where: whereClause,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [['created_at', 'DESC']],
      include: [
        {
          model: Repair,
          as: 'repairs',
          attributes: ['id'],
          required: false
        },
        {
          model: WashLog,
          as: 'washLogs',
          attributes: ['id'],
          required: false
        }
      ]
    });

    const carsWithStats = cars.map(car => ({
      ...car.toJSON(),
      repairCount: car.repairs.length,
      washCount: car.washLogs.length
    }));

    res.json({
      success: true,
      message: '查询成功',
      data: {
        cars: carsWithStats,
        pagination: {
          current: parseInt(page),
          limit: parseInt(limit),
          total: count,
          pages: Math.ceil(count / limit)
        }
      }
    });
  } catch (error) {
    console.error('获取车辆列表失败:', error);
    res.status(500).json({
      success: false,
      message: '获取车辆列表失败',
      code: 'LIST_CARS_ERROR'
    });
  }
});

// PUT /api/cars/:id - 更新车辆信息
router.put('/:id', [
  param('id').isInt().withMessage('车辆ID必须是整数'),
  body('plate_number')
    .optional()
    .isLength({ min: 1, max: 20 })
    .withMessage('车牌号长度必须在1-20个字符之间'),
  body('vin')
    .optional()
    .isLength({ min: 17, max: 50 })
    .withMessage('车架号长度必须在17-50个字符之间'),
  body('brand')
    .optional()
    .isLength({ max: 50 })
    .withMessage('品牌名称不能超过50个字符'),
  body('model')
    .optional()
    .isLength({ max: 50 })
    .withMessage('型号不能超过50个字符'),
  body('year')
    .optional()
    .isInt({ min: 1900, max: new Date().getFullYear() + 1 })
    .withMessage('年份必须是1900年到明年之间的整数'),
  body('color')
    .optional()
    .isLength({ max: 20 })
    .withMessage('颜色不能超过20个字符')
], handleValidationErrors, async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    const car = await Car.findByPk(id);
    if (!car) {
      return res.status(404).json({
        success: false,
        message: '未找到该车辆',
        code: 'CAR_NOT_FOUND'
      });
    }

    // 清理和转换数据
    if (updateData.plate_number) {
      updateData.plate_number = updateData.plate_number.trim().toUpperCase();
    }
    if (updateData.vin) {
      updateData.vin = updateData.vin.trim().toUpperCase();
    }
    if (updateData.brand) {
      updateData.brand = updateData.brand.trim();
    }
    if (updateData.model) {
      updateData.model = updateData.model.trim();
    }
    if (updateData.color) {
      updateData.color = updateData.color.trim();
    }

    await car.update(updateData);

    res.json({
      success: true,
      message: '车辆信息更新成功',
      data: car
    });
  } catch (error) {
    console.error('更新车辆信息失败:', error);
    res.status(500).json({
      success: false,
      message: '更新车辆信息失败',
      code: 'UPDATE_CAR_ERROR'
    });
  }
});

// GET /api/cars/export - 导出车辆列表CSV
router.get('/export', async (req, res) => {
  try {
    const cars = await Car.findAll();
    const fields = ['id', 'plate_number', 'vin', 'brand', 'model', 'year', 'color'];
    const header = fields.join(',');
    const rows = cars.map(c =>
      fields.map(f => `"${(c[f] ?? '').toString().replace(/"/g, '""')}"`).join(',')
    );
    const csv = [header, ...rows].join('\n');
    res.header('Content-Type', 'text/csv');
    res.attachment('cars.csv');
    res.send(csv);
  } catch (error) {
    console.error('导出车辆失败:', error);
    res.status(500).json({ success: false, message: '导出车辆失败' });
  }
});

module.exports = router;
