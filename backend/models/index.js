const { Sequelize } = require('sequelize');
const config = require('../config');

const env = process.env.NODE_ENV || 'development';
const dbConfig = config[env];

// 创建Sequelize实例
const sequelize = new Sequelize(
  dbConfig.database,
  dbConfig.username,
  dbConfig.password,
  {
    host: dbConfig.host,
    port: dbConfig.port,
    dialect: dbConfig.dialect,
    timezone: dbConfig.timezone,
    define: dbConfig.define,
    logging: dbConfig.logging,
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  }
);

// 导入模型
const Car = require('./Car')(sequelize);
const Repair = require('./Repair')(sequelize);
const WashLog = require('./WashLog')(sequelize);
const Customer = require('./Customer')(sequelize);

// 定义模型关联
// 客户与车辆的关系
Customer.hasMany(Car, { foreignKey: 'customer_id', as: 'cars' });
Car.belongsTo(Customer, { foreignKey: 'customer_id', as: 'customer' });

// 客户与维修记录的关系
Customer.hasMany(Repair, { foreignKey: 'customer_id', as: 'repairs' });
Repair.belongsTo(Customer, { foreignKey: 'customer_id', as: 'customer' });

// 客户与洗车记录的关系
Customer.hasMany(WashLog, { foreignKey: 'customer_id', as: 'washLogs' });
WashLog.belongsTo(Customer, { foreignKey: 'customer_id', as: 'customer' });

// 车辆与维修记录的关系
Car.hasMany(Repair, { foreignKey: 'car_id', as: 'repairs' });
Repair.belongsTo(Car, { foreignKey: 'car_id', as: 'car' });

// 车辆与洗车记录的关系
Car.hasMany(WashLog, { foreignKey: 'car_id', as: 'washLogs' });
WashLog.belongsTo(Car, { foreignKey: 'car_id', as: 'car' });

// 测试数据库连接
const testConnection = async () => {
  try {
    await sequelize.authenticate();
    console.log('✅ 数据库连接成功');
  } catch (error) {
    console.error('❌ 数据库连接失败:', error);
  }
};

module.exports = {
  sequelize,
  Car,
  Repair,
  WashLog,
  Customer,
  testConnection
}; 