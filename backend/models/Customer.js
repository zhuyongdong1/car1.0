const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
const Customer = sequelize.define('Customer', {
  id: {
    type: DataTypes.INTEGER,
    primaryKey: true,
    autoIncrement: true,
    comment: '客户ID'
  },
  name: {
    type: DataTypes.STRING(100),
    allowNull: false,
    comment: '客户姓名',
    validate: {
      notEmpty: {
        msg: '客户姓名不能为空'
      },
      len: {
        args: [2, 100],
        msg: '客户姓名长度应在2-100字符之间'
      }
    }
  },
  phone: {
    type: DataTypes.STRING(20),
    allowNull: false,
    comment: '联系电话',
    unique: {
      msg: '该手机号已存在'
    },
    validate: {
      notEmpty: {
        msg: '联系电话不能为空'
      },
      is: {
        args: /^1[3-9]\d{9}$/,
        msg: '请输入有效的手机号码'
      }
    }
  },
  phoneSecondary: {
    type: DataTypes.STRING(20),
    allowNull: true,
    field: 'phone_secondary',
    comment: '备用电话',
    validate: {
      isPhoneNumber(value) {
        if (value && !/^1[3-9]\d{9}$/.test(value)) {
          throw new Error('备用电话格式不正确');
        }
      }
    }
  },
  address: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: '客户地址'
  },
  email: {
    type: DataTypes.STRING(100),
    allowNull: true,
    comment: '邮箱地址',
    validate: {
      isEmail: {
        msg: '请输入有效的邮箱地址'
      }
    }
  },
  wechat: {
    type: DataTypes.STRING(100),
    allowNull: true,
    comment: '微信号'
  },
  idCard: {
    type: DataTypes.STRING(18),
    allowNull: true,
    field: 'id_card',
    comment: '身份证号',
    validate: {
      isIdCard(value) {
        if (value && !/^[1-9]\d{5}(18|19|20)\d{2}((0[1-9])|(1[0-2]))(([0-2][1-9])|10|20|30|31)\d{3}[0-9Xx]$/.test(value)) {
          throw new Error('身份证号格式不正确');
        }
      }
    }
  },
  company: {
    type: DataTypes.STRING(200),
    allowNull: true,
    comment: '公司名称'
  },
  notes: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: '客户备注'
  },
  customerType: {
    type: DataTypes.ENUM('个人', '企业'),
    defaultValue: '个人',
    field: 'customer_type',
    comment: '客户类型'
  },
  vipLevel: {
    type: DataTypes.ENUM('普通', '银卡', '金卡', '钻石'),
    defaultValue: '普通',
    field: 'vip_level',
    comment: 'VIP等级'
  },
  totalSpent: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0.00,
    field: 'total_spent',
    comment: '累计消费金额'
  },
  visitCount: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
    field: 'visit_count',
    comment: '到店次数'
  },
  lastVisitDate: {
    type: DataTypes.DATE,
    allowNull: true,
    field: 'last_visit_date',
    comment: '最后到店时间'
  },
  createdAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
    field: 'created_at',
    comment: '创建时间'
  },
  updatedAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
    field: 'updated_at',
    comment: '更新时间'
  }
}, {
  tableName: 'customers',
  timestamps: true,
  createdAt: 'created_at',
  updatedAt: 'updated_at',
  underscored: true,
  charset: 'utf8mb4',
  collate: 'utf8mb4_unicode_ci',
  comment: '客户信息表',
  indexes: [
    {
      fields: ['phone']
    },
    {
      fields: ['name']
    },
    {
      fields: ['customer_type']
    },
    {
      fields: ['vip_level']
    },
    {
      fields: ['created_at']
    }
  ],
  hooks: {
    beforeCreate: async (customer) => {
      // 创建客户时的钩子
      customer.name = customer.name?.trim();
      customer.phone = customer.phone?.replace(/\s/g, '');
      if (customer.email) {
        customer.email = customer.email.toLowerCase();
      }
      // 确保数值字段有默认值
      if (customer.totalSpent === undefined || customer.totalSpent === null) {
        customer.totalSpent = 0.00;
      }
      if (customer.visitCount === undefined || customer.visitCount === null) {
        customer.visitCount = 0;
      }
    },
    beforeUpdate: async (customer) => {
      // 更新客户时的钩子
      if (customer.changed('name')) {
        customer.name = customer.name?.trim();
      }
      if (customer.changed('phone')) {
        customer.phone = customer.phone?.replace(/\s/g, '');
      }
      if (customer.changed('email') && customer.email) {
        customer.email = customer.email.toLowerCase();
      }
    }
  }
});

// 定义与其他模型的关系
Customer.associate = function(models) {
  // 一个客户可以有多辆车
  Customer.hasMany(models.Car, {
    foreignKey: 'customer_id',
    as: 'cars',
    onDelete: 'SET NULL',
    onUpdate: 'CASCADE'
  });

  // 一个客户可以有多个维修记录
  Customer.hasMany(models.Repair, {
    foreignKey: 'customer_id',
    as: 'repairs',
    onDelete: 'SET NULL',
    onUpdate: 'CASCADE'
  });

  // 一个客户可以有多个洗车记录
  Customer.hasMany(models.WashLog, {
    foreignKey: 'customer_id',
    as: 'washLogs',
    onDelete: 'SET NULL',
    onUpdate: 'CASCADE'
  });
};

// 实例方法
Customer.prototype.updateVisitInfo = async function(amount = 0) {
  this.visitCount += 1;
  this.lastVisitDate = new Date();
  if (amount > 0) {
    this.totalSpent = parseFloat(this.totalSpent) + parseFloat(amount);
  }
  return await this.save();
};

Customer.prototype.getFullInfo = function() {
  return {
    id: this.id,
    name: this.name,
    phone: this.phone,
    phoneSecondary: this.phoneSecondary,
    address: this.address,
    email: this.email,
    wechat: this.wechat,
    idCard: this.idCard,
    company: this.company,
    notes: this.notes,
    customerType: this.customerType,
    vipLevel: this.vipLevel,
    totalSpent: parseFloat(this.totalSpent),
    visitCount: this.visitCount,
    lastVisitDate: this.lastVisitDate,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt
  };
};

// 类方法
Customer.searchByKeyword = async function(keyword, options = {}) {
  const { limit = 10, offset = 0 } = options;
  const { Op } = require('sequelize');
  
  return await Customer.findAndCountAll({
    where: {
      [Op.or]: [
        { name: { [Op.like]: `%${keyword}%` } },
        { phone: { [Op.like]: `%${keyword}%` } },
        { company: { [Op.like]: `%${keyword}%` } }
      ]
    },
    order: [['created_at', 'DESC']],
    limit,
    offset
  });
};

Customer.getVipCustomers = async function() {
  const { Op, literal } = require('sequelize');
  
  return await Customer.findAll({
    where: {
      vipLevel: {
        [Op.in]: ['银卡', '金卡', '钻石']
      }
    },
    order: [
      [literal("FIELD(vip_level, '钻石', '金卡', '银卡')"), 'ASC'],
      ['total_spent', 'DESC']
    ]
  });
};

return Customer;
}; 