const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Repair = sequelize.define('Repair', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    car_id: {
      type: DataTypes.INTEGER,
      allowNull: false,
      comment: '车辆ID',
      references: {
        model: 'cars',
        key: 'id'
      }
    },
    customer_id: {
      type: DataTypes.INTEGER,
      allowNull: true,
      comment: '关联的客户ID',
      references: {
        model: 'customers',
        key: 'id'
      },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL'
    },
    repair_date: {
      type: DataTypes.DATEONLY,
      allowNull: false,
      comment: '维修日期',
      validate: {
        isDate: {
          msg: '请输入有效的维修日期'
        },
        notEmpty: {
          msg: '维修日期不能为空'
        }
      }
    },
    item: {
      type: DataTypes.TEXT,
      allowNull: false,
      comment: '维修项目',
      validate: {
        notEmpty: {
          msg: '维修项目不能为空'
        },
        len: {
          args: [1, 1000],
          msg: '维修项目描述不能超过1000个字符'
        }
      }
    },
    price: {
      type: DataTypes.DECIMAL(10, 2),
      allowNull: false,
      defaultValue: 0.00,
      comment: '维修费用',
      validate: {
        min: {
          args: [0],
          msg: '维修费用不能为负数'
        }
      }
    },
    note: {
      type: DataTypes.TEXT,
      allowNull: true,
      comment: '备注',
      validate: {
        len: {
          args: [0, 1000],
          msg: '备注不能超过1000个字符'
        }
      }
    },
    mechanic: {
      type: DataTypes.STRING(50),
      allowNull: true,
      comment: '维修师傅'
    },
    garage_name: {
      type: DataTypes.STRING(100),
      allowNull: true,
      comment: '维修厂名称'
    }
  }, {
    tableName: 'repairs',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
      {
        fields: ['car_id']
      },
      {
        fields: ['repair_date']
      }
    ]
  });

  return Repair;
}; 