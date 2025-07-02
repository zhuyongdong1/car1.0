const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const WashLog = sequelize.define('WashLog', {
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
    wash_time: {
      type: DataTypes.DATE,
      allowNull: false,
      defaultValue: DataTypes.NOW,
      comment: '洗车时间',
      validate: {
        isDate: {
          msg: '请输入有效的洗车时间'
        }
      }
    },
    wash_type: {
      type: DataTypes.ENUM('self', 'auto', 'manual'),
      allowNull: false,
      defaultValue: 'manual',
      comment: '洗车类型：self自助,auto自动,manual人工',
      validate: {
        isIn: {
          args: [['self', 'auto', 'manual']],
          msg: '洗车类型必须是self、auto或manual其中之一'
        }
      }
    },
    price: {
      type: DataTypes.DECIMAL(8, 2),
      allowNull: false,
      defaultValue: 0.00,
      comment: '洗车费用',
      validate: {
        min: {
          args: [0],
          msg: '洗车费用不能为负数'
        }
      }
    },
    location: {
      type: DataTypes.STRING(100),
      allowNull: true,
      comment: '洗车地点'
    },
    note: {
      type: DataTypes.TEXT,
      allowNull: true,
      comment: '备注',
      validate: {
        len: {
          args: [0, 500],
          msg: '备注不能超过500个字符'
        }
      }
    }
  }, {
    tableName: 'wash_logs',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false, // 洗车记录不需要更新时间
    indexes: [
      {
        fields: ['car_id']
      },
      {
        fields: ['wash_time']
      }
    ]
  });

  return WashLog;
}; 