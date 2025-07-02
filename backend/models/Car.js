const { DataTypes } = require('sequelize');

module.exports = (sequelize) => {
  const Car = sequelize.define('Car', {
    id: {
      type: DataTypes.INTEGER,
      primaryKey: true,
      autoIncrement: true
    },
    plate_number: {
      type: DataTypes.STRING(20),
      allowNull: false,
      unique: true,
      comment: '车牌号',
      validate: {
        notEmpty: {
          msg: '车牌号不能为空'
        },
        len: {
          args: [1, 20],
          msg: '车牌号长度必须在1-20个字符之间'
        }
      }
    },
    vin: {
      type: DataTypes.STRING(50),
      allowNull: false,
      unique: true,
      comment: '车架号',
      validate: {
        notEmpty: {
          msg: '车架号不能为空'
        },
        len: {
          args: [17, 50],
          msg: '车架号长度必须在17-50个字符之间'
        }
      }
    },
    brand: {
      type: DataTypes.STRING(50),
      allowNull: true,
      comment: '品牌'
    },
    model: {
      type: DataTypes.STRING(50),
      allowNull: true,
      comment: '型号'
    },
    year: {
      type: DataTypes.INTEGER,
      allowNull: true,
      comment: '年份',
      validate: {
        min: {
          args: [1900],
          msg: '年份不能小于1900年'
        },
        max: {
          args: [new Date().getFullYear() + 1],
          msg: '年份不能超过明年'
        }
      }
    },
    color: {
      type: DataTypes.STRING(20),
      allowNull: true,
      comment: '颜色'
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
    }
  }, {
    tableName: 'cars',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
      {
        fields: ['plate_number']
      },
      {
        fields: ['vin']
      }
    ]
  });

  return Car;
}; 