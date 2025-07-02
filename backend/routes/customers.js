const express = require('express');
const Joi = require('joi');
const { Customer, Car, Repair, WashLog } = require('../models');
const router = express.Router();

// 验证模式
const customerSchema = Joi.object({
  name: Joi.string().min(2).max(100).required().messages({
    'string.min': '客户姓名至少2个字符',
    'string.max': '客户姓名最多100个字符',
    'any.required': '客户姓名是必填项'
  }),
  phone: Joi.string().pattern(/^1[3-9]\d{9}$/).required().messages({
    'string.pattern.base': '请输入有效的手机号码',
    'any.required': '联系电话是必填项'
  }),
  phoneSecondary: Joi.string().pattern(/^1[3-9]\d{9}$/).allow('', null),
  address: Joi.string().max(500).allow('', null),
  email: Joi.string().email().allow('', null),
  wechat: Joi.string().max(100).allow('', null),
  idCard: Joi.string().pattern(/^[1-9]\d{5}(18|19|20)\d{2}((0[1-9])|(1[0-2]))(([0-2][1-9])|10|20|30|31)\d{3}[0-9Xx]$/).allow('', null),
  company: Joi.string().max(200).allow('', null),
  notes: Joi.string().max(1000).allow('', null),
  customerType: Joi.string().valid('个人', '企业').default('个人'),
  vipLevel: Joi.string().valid('普通', '银卡', '金卡', '钻石').default('普通')
});

const updateCustomerSchema = customerSchema.fork(['name', 'phone'], (schema) => schema.optional());

/**
 * @route GET /api/customers
 * @desc 获取客户列表（支持分页和搜索）
 * @access Public
 */
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = Math.min(parseInt(req.query.limit) || 10, 50);
    const offset = (page - 1) * limit;
    const search = req.query.search?.trim();
    const customerType = req.query.customer_type;
    const vipLevel = req.query.vip_level;

    let whereCondition = {};
    
    // 搜索条件
    if (search) {
      const { Op } = require('sequelize');
      whereCondition = {
        [Op.or]: [
          { name: { [Op.like]: `%${search}%` } },
          { phone: { [Op.like]: `%${search}%` } },
          { company: { [Op.like]: `%${search}%` } }
        ]
      };
    }

    // 筛选条件
    if (customerType) {
      whereCondition.customerType = customerType;
    }
    if (vipLevel) {
      whereCondition.vipLevel = vipLevel;
    }

    const result = await Customer.findAndCountAll({
      where: whereCondition,
      order: [['createdAt', 'DESC']],
      limit,
      offset,
      distinct: true
    });

    res.json({
      success: true,
      message: '获取客户列表成功',
      data: {
        customers: result.rows,
        pagination: {
          page,
          limit,
          total: result.count,
          pages: Math.ceil(result.count / limit)
        }
      }
    });
  } catch (error) {
    console.error('获取客户列表失败:', error);
    res.status(500).json({
      success: false,
      message: '获取客户列表失败',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route GET /api/customers/:id
 * @desc 获取单个客户详情
 * @access Public
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const customer = await Customer.findByPk(id);

    if (!customer) {
      return res.status(404).json({
        success: false,
        message: '客户不存在'
      });
    }

    // 计算统计信息
    const stats = {
      totalCars: 0,
      totalRepairs: 0,
      totalWashes: 0,
      totalSpent: parseFloat(customer.totalSpent),
      avgRepairCost: 0,
      lastVisit: customer.lastVisitDate
    };

    res.json({
      success: true,
      message: '获取客户详情成功',
      data: {
        customer: customer,
        stats
      }
    });
  } catch (error) {
    console.error('获取客户详情失败:', error);
    res.status(500).json({
      success: false,
      message: '获取客户详情失败',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route POST /api/customers
 * @desc 创建新客户
 * @access Public
 */
router.post('/', async (req, res) => {
  try {
    // 验证输入数据
    const { error, value } = customerSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: '数据验证失败',
        details: error.details[0].message
      });
    }

    // 检查手机号是否已存在
    const existingCustomer = await Customer.findOne({
      where: { phone: value.phone }
    });

    if (existingCustomer) {
      return res.status(400).json({
        success: false,
        message: '该手机号已存在'
      });
    }

    // 创建客户 - 确保默认值
    const customerData = {
      ...value,
      totalSpent: 0.00,
      visitCount: 0
    };
    const customer = await Customer.create(customerData);

    res.status(201).json({
      success: true,
      message: '创建客户成功',
      data: customer
    });
  } catch (error) {
    console.error('创建客户失败:', error);
    res.status(500).json({
      success: false,
      message: '创建客户失败',
      error: error.message,
      stack: error.stack
    });
  }
});

/**
 * @route PUT /api/customers/:id
 * @desc 更新客户信息
 * @access Public
 */
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // 验证输入数据
    const { error, value } = updateCustomerSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: '数据验证失败',
        details: error.details[0].message
      });
    }

    // 查找客户
    const customer = await Customer.findByPk(id);
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: '客户不存在'
      });
    }

    // 如果更新手机号，检查是否重复
    if (value.phone && value.phone !== customer.phone) {
      const existingCustomer = await Customer.findOne({
        where: { phone: value.phone }
      });
      if (existingCustomer) {
        return res.status(400).json({
          success: false,
          message: '该手机号已存在'
        });
      }
    }

    // 更新客户信息
    await customer.update(value);

    res.json({
      success: true,
      message: '更新客户信息成功',
      data: customer.getFullInfo()
    });
  } catch (error) {
    console.error('更新客户信息失败:', error);
    res.status(500).json({
      success: false,
      message: '更新客户信息失败',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route DELETE /api/customers/:id
 * @desc 删除客户（软删除，关联记录保留）
 * @access Public
 */
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const customer = await Customer.findByPk(id);
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: '客户不存在'
      });
    }

    // 检查是否有关联的车辆
    const carCount = await Car.count({ where: { customer_id: id } });
    if (carCount > 0) {
      return res.status(400).json({
        success: false,
        message: `该客户有 ${carCount} 辆关联车辆，请先处理车辆信息`
      });
    }

    await customer.destroy();

    res.json({
      success: true,
      message: '删除客户成功'
    });
  } catch (error) {
    console.error('删除客户失败:', error);
    res.status(500).json({
      success: false,
      message: '删除客户失败',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route GET /api/customers/search/:keyword
 * @desc 客户搜索（快速搜索）
 * @access Public
 */
router.get('/search/:keyword', async (req, res) => {
  try {
    const { keyword } = req.params;
    const limit = Math.min(parseInt(req.query.limit) || 10, 20);

    if (!keyword.trim()) {
      return res.status(400).json({
        success: false,
        message: '搜索关键词不能为空'
      });
    }

    const result = await Customer.searchByKeyword(keyword.trim(), { limit });

    res.json({
      success: true,
      message: '搜索客户成功',
      data: {
        customers: result.rows,
        total: result.count
      }
    });
  } catch (error) {
    console.error('搜索客户失败:', error);
    res.status(500).json({
      success: false,
      message: '搜索客户失败',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route GET /api/customers/vip/list
 * @desc 获取VIP客户列表
 * @access Public
 */
router.get('/vip/list', async (req, res) => {
  try {
    const vipCustomers = await Customer.getVipCustomers();

    res.json({
      success: true,
      message: '获取VIP客户列表成功',
      data: vipCustomers
    });
  } catch (error) {
    console.error('获取VIP客户列表失败:', error);
    res.status(500).json({
      success: false,
      message: '获取VIP客户列表失败',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route POST /api/customers/:id/visit
 * @desc 更新客户到店信息
 * @access Public
 */
router.post('/:id/visit', async (req, res) => {
  try {
    const { id } = req.params;
    const { amount } = req.body;

    const customer = await Customer.findByPk(id);
    if (!customer) {
      return res.status(404).json({
        success: false,
        message: '客户不存在'
      });
    }

    await customer.updateVisitInfo(amount || 0);

    res.json({
      success: true,
      message: '更新客户到店信息成功',
      data: customer.getFullInfo()
    });
  } catch (error) {
    console.error('更新客户到店信息失败:', error);
    res.status(500).json({
      success: false,
      message: '更新客户到店信息失败',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

/**
 * @route GET /api/customers/stats/overview
 * @desc 获取客户统计概览
 * @access Public
 */
router.get('/stats/overview', async (req, res) => {
  try {
    const { Op, fn, col } = require('sequelize');

    // 基础统计
    const totalCustomers = await Customer.count();
    const newCustomersThisMonth = await Customer.count({
      where: {
        createdAt: {
          [Op.gte]: new Date(new Date().getFullYear(), new Date().getMonth(), 1)
        }
      }
    });

    // VIP客户统计
    const vipStats = await Customer.findAll({
      attributes: [
        'vipLevel',
        [fn('COUNT', col('id')), 'count']
      ],
      group: ['vipLevel']
    });

    // 客户类型统计
    const typeStats = await Customer.findAll({
      attributes: [
        'customerType',
        [fn('COUNT', col('id')), 'count']
      ],
      group: ['customerType']
    });

    // 消费排行（前10）
    const topSpenders = await Customer.findAll({
      order: [['totalSpent', 'DESC']],
      limit: 10,
      attributes: ['id', 'name', 'phone', 'totalSpent', 'visitCount', 'vipLevel']
    });

    res.json({
      success: true,
      message: '获取客户统计概览成功',
      data: {
        summary: {
          totalCustomers,
          newCustomersThisMonth,
          vipCustomers: vipStats.reduce((sum, item) => 
            ['银卡', '金卡', '钻石'].includes(item.vipLevel) ? sum + parseInt(item.dataValues.count) : sum, 0
          )
        },
        vipDistribution: vipStats.map(item => ({
          level: item.vipLevel,
          count: parseInt(item.dataValues.count)
        })),
        typeDistribution: typeStats.map(item => ({
          type: item.customerType,
          count: parseInt(item.dataValues.count)
        })),
        topSpenders: topSpenders.map(customer => ({
          id: customer.id,
          name: customer.name,
          phone: customer.phone,
          totalSpent: parseFloat(customer.totalSpent),
          visitCount: customer.visitCount,
          vipLevel: customer.vipLevel
        }))
      }
    });
  } catch (error) {
    console.error('获取客户统计概览失败:', error);
    res.status(500).json({
      success: false,
      message: '获取客户统计概览失败',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

module.exports = router; 