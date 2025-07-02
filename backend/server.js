const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const morgan = require('morgan');
const { testConnection, sequelize } = require('./models');
const config = require('./config');

const app = express();
const PORT = config.server.port;

// 中间件配置
app.use(helmet()); // 安全头部
app.use(morgan('combined')); // 日志记录

// CORS配置
app.use(cors({
  origin: ['http://localhost:3000', 'http://127.0.0.1:3000', 'http://localhost:8080'],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
}));

// 请求体解析
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// API限流
const limiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.max,
  message: {
    error: '请求太频繁，请稍后再试',
    code: 'TOO_MANY_REQUESTS'
  },
  standardHeaders: true,
  legacyHeaders: false
});
app.use('/api', limiter);

// OCR专用限制（更严格）
const ocrLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分钟
  max: 50, // OCR请求限制更严格
  message: {
    success: false,
    message: 'OCR请求过于频繁，请稍后再试'
  }
});

// 健康检查
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// API路由
app.use('/api/cars', require('./routes/cars'));
app.use('/api/repairs', require('./routes/repairs'));
app.use('/api/wash', require('./routes/wash'));
app.use('/api/ocr', ocrLimiter, require('./routes/ocr'));
app.use('/api/customers', require('./routes/customers'));

// 404处理
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: '接口不存在',
    code: 'NOT_FOUND'
  });
});

// 全局错误处理
app.use((err, req, res, next) => {
  console.error('❌ 服务器错误:', err);
  
  // Sequelize验证错误
  if (err.name === 'SequelizeValidationError') {
    return res.status(400).json({
      success: false,
      message: '数据验证失败',
      errors: err.errors.map(e => e.message),
      code: 'VALIDATION_ERROR'
    });
  }
  
  // Sequelize唯一约束错误
  if (err.name === 'SequelizeUniqueConstraintError') {
    return res.status(409).json({
      success: false,
      message: '数据已存在',
      field: err.errors[0]?.path,
      code: 'DUPLICATE_ERROR'
    });
  }
  
  // 默认错误响应
  res.status(500).json({
    success: false,
    message: '服务器内部错误',
    code: 'INTERNAL_ERROR'
  });
});

// 启动服务器
const startServer = async () => {
  try {
    // 测试数据库连接
    await testConnection();
    
    // 同步数据库模型（不强制重建表）
    await sequelize.sync({ alter: false });
    console.log('✅ 数据库模型同步成功');
    
    app.listen(PORT, () => {
      console.log(`🚀 服务器启动成功: http://localhost:${PORT}`);
      console.log(`📊 健康检查: http://localhost:${PORT}/health`);
      console.log(`🌍 环境: development`);
    });
  } catch (error) {
    console.error('❌ 服务器启动失败:', error);
    process.exit(1);
  }
};

// 优雅关闭
process.on('SIGTERM', () => {
  console.log('👋 收到SIGTERM信号，正在关闭服务器...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('👋 收到SIGINT信号，正在关闭服务器...');
  process.exit(0);
});

startServer(); 