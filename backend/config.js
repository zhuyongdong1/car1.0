require('dotenv').config();

module.exports = {
  // 数据库配置
  database: {
    host: 'localhost',
    port: 3306,
    username: 'root',
    password: '',
    database: 'car_maintenance_system',
    dialect: 'mysql',
    timezone: '+08:00',
    logging: console.log,
    pool: {
      max: 10,
      min: 0,
      acquire: 30000,
      idle: 10000
    },
    define: {
      timestamps: true,
      createdAt: 'created_at',
      updatedAt: 'updated_at',
      underscored: true,
      charset: 'utf8mb4',
      collate: 'utf8mb4_unicode_ci'
    }
  },
  
  // 服务器配置
  server: {
    port: process.env.PORT || 3000,
    host: '0.0.0.0'
  },
  
  // CORS配置
  cors: {
    origin: ['http://localhost:3000', 'http://127.0.0.1:3000'],
    credentials: true
  },
  
  // 百度OCR配置
  baiduOcr: {
    appId: process.env.BAIDU_OCR_APP_ID || '119153115', // 百度OCR应用ID
    apiKey: process.env.BAIDU_OCR_API_KEY || 'rijBYArTbty3m9rnD6ana15W',
    secretKey: process.env.BAIDU_OCR_SECRET_KEY || 'pzUlxP7VJNmfDn40LWmXAuVNlWHRNiO2'
  },
  
  // 文件上传配置
  upload: {
    maxFileSize: 5 * 1024 * 1024, // 5MB
    allowedMimeTypes: ['image/jpeg', 'image/png', 'image/jpg'],
    uploadDir: './uploads'
  },

  development: {
    database: process.env.DB_NAME || 'car_maintenance_system',
    username: process.env.DB_USER || 'carapp',
    password: process.env.DB_PASSWORD || 'carapp123',
    host: process.env.DB_HOST || 'localhost',
    port: process.env.DB_PORT || 3306,
    dialect: 'mysql',
    timezone: '+08:00',
    define: {
      charset: 'utf8mb4',
      collate: 'utf8mb4_unicode_ci',
      timestamps: true,
      underscored: false
    },
    logging: console.log
  },
  production: {
    database: process.env.DB_NAME,
    username: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 3306,
    dialect: 'mysql',
    timezone: '+08:00',
    define: {
      charset: 'utf8mb4',
      collate: 'utf8mb4_unicode_ci',
      timestamps: true,
      underscored: false
    },
    logging: false
  },
  // API限流配置
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15分钟
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100 // 最多100个请求
  }
}; 