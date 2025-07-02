# 车辆维修记录管理系统 - 技术架构文档

## 📋 目录

1. [系统概述](#系统概述)
2. [技术架构](#技术架构)
3. [数据库设计](#数据库设计)
4. [API设计](#api设计)
5. [安全架构](#安全架构)
6. [测试架构](#测试架构)
7. [部署架构](#部署架构)

## 系统概述

车辆维修记录管理系统是一个基于现代Web技术栈构建的全栈应用，旨在为汽修店和车主提供完整的车辆维护记录管理解决方案。

### 核心功能模块
- 🚗 车辆信息管理
- 👥 客户信息管理
- 🔧 维修记录管理
- 🚿 洗车记录管理
- 📷 OCR文字识别
- 📊 数据统计分析
- 🔐 用户认证授权
- 📤 数据导出功能

## 技术架构

### 整体架构图

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter Web   │    │  Mobile Apps    │    │   Admin Panel   │
│   (Frontend)    │    │   (iOS/Android) │    │   (管理后台)     │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          └──────────────┬───────────────────────────────┘
                         │ HTTPS/REST API
          ┌──────────────▼───────────────┐
          │        Express.js            │
          │      (API Gateway)           │
          └──────────────┬───────────────┘
                         │
          ┌──────────────▼───────────────┐
          │      Business Logic          │
          │  ┌─────────┐ ┌─────────────┐ │
          │  │  Auth   │ │   Services  │ │
          │  │ Service │ │  (Car/OCR)  │ │
          │  └─────────┘ └─────────────┘ │
          └──────────────┬───────────────┘
                         │
          ┌──────────────▼───────────────┐
          │       Data Layer             │
          │  ┌─────────┐ ┌─────────────┐ │
          │  │  MySQL  │ │ File Storage│ │
          │  │Database │ │ (Images)    │ │
          │  └─────────┘ └─────────────┘ │
          └─────────────────────────────┘
```

### 前端技术栈

```yaml
Framework: Flutter 3.24.5
Language: Dart
Architecture: Provider Pattern (状态管理)
Navigation: Go Router
HTTP Client: Dio/HTTP
UI Components:
  - Material Design Components
  - Custom Widgets
  - Responsive Layout (flutter_screenutil)
  - Form Builder & Validation
  - Image Processing (image_picker)
Testing:
  - Widget Tests
  - Unit Tests
  - Integration Tests
```

### 后端技术栈

```yaml
Runtime: Node.js 14+
Framework: Express.js 4.x
Language: JavaScript (ES6+)
ORM: Sequelize 6.x
Database: MySQL 8.0+
Authentication: JWT (jsonwebtoken)
Security:
  - Helmet (Security Headers)
  - CORS (Cross-Origin)
  - Rate Limiting
  - Input Validation
File Processing:
  - Multer (File Upload)
  - Sharp (Image Processing)
External Services:
  - 百度OCR SDK
Testing:
  - Jest (Unit Tests)
  - SuperTest (API Tests)
Logging: Morgan
```

## 数据库设计

### ER图

```
┌─────────────┐      ┌─────────────┐
│  customers  │      │    cars     │
│─────────────│      │─────────────│
│ id (PK)     │◄─┐   │ id (PK)     │
│ name        │  │   │ customer_id │ (FK)
│ phone       │  │   │ plate_number│ (UNIQUE)
│ email       │  │   │ vin         │ (UNIQUE)
│ address     │  │   │ brand       │
│ note        │  │   │ model       │
│ created_at  │  │   │ year        │
│ updated_at  │  │   │ color       │
└─────────────┘  │   │ created_at  │
                 │   │ updated_at  │
                 │   └─────────────┘
                 │          │
                 │          │ 1:N
                 │   ┌──────▼──────┐      ┌─────────────┐
                 │   │   repairs   │      │ wash_logs   │
                 │   │─────────────│      │─────────────│
                 │   │ id (PK)     │      │ id (PK)     │
                 └───┤ customer_id │ (FK) │ customer_id │ (FK)
                     │ car_id      │ (FK) │ car_id      │ (FK)
                     │ repair_date │      │ wash_time   │
                     │ item        │      │ wash_type   │
                     │ price       │      │ price       │
                     │ note        │      │ location    │
                     │ mechanic    │      │ note        │
                     │ garage_name │      │ created_at  │
                     │ created_at  │      └─────────────┘
                     │ updated_at  │
                     └─────────────┘
```

### 数据表详细设计

#### customers 表（客户信息）
```sql
CREATE TABLE customers (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL COMMENT '客户姓名',
  phone VARCHAR(20) UNIQUE COMMENT '手机号码',
  email VARCHAR(100) COMMENT '邮箱地址',
  address TEXT COMMENT '客户地址',
  note TEXT COMMENT '备注信息',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

#### cars 表（车辆信息）
```sql
CREATE TABLE cars (
  id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT COMMENT '客户ID',
  plate_number VARCHAR(20) UNIQUE NOT NULL COMMENT '车牌号',
  vin VARCHAR(50) UNIQUE NOT NULL COMMENT '车架号',
  brand VARCHAR(50) NOT NULL COMMENT '品牌',
  model VARCHAR(50) NOT NULL COMMENT '型号',
  year YEAR COMMENT '年份',
  color VARCHAR(30) COMMENT '颜色',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL
);
```

#### repairs 表（维修记录）
```sql
CREATE TABLE repairs (
  id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT COMMENT '客户ID',
  car_id INT NOT NULL COMMENT '车辆ID',
  repair_date DATE NOT NULL COMMENT '维修日期',
  item TEXT NOT NULL COMMENT '维修项目',
  price DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '维修费用',
  note TEXT COMMENT '备注',
  mechanic VARCHAR(50) COMMENT '维修师傅',
  garage_name VARCHAR(100) COMMENT '维修厂名称',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
  FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE CASCADE
);
```

#### wash_logs 表（洗车记录）
```sql
CREATE TABLE wash_logs (
  id INT PRIMARY KEY AUTO_INCREMENT,
  customer_id INT COMMENT '客户ID',
  car_id INT NOT NULL COMMENT '车辆ID',
  wash_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '洗车时间',
  wash_type ENUM('self','auto','manual') DEFAULT 'manual' COMMENT '洗车类型',
  price DECIMAL(8,2) DEFAULT 0 COMMENT '洗车费用',
  location VARCHAR(200) COMMENT '洗车地点',
  note TEXT COMMENT '备注',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
  FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE CASCADE
);
```

## API设计

### RESTful API规范

```yaml
Base URL: http://localhost:3000/api
Content-Type: application/json
Authentication: Bearer JWT Token (部分接口)

Response Format:
  Success:
    status: 200/201
    body:
      success: true
      message: string
      data: object|array
  
  Error:
    status: 4xx/5xx
    body:
      success: false
      message: string
      code: string
      errors: array (optional)
```

### 接口分类

#### 1. 认证接口 (`/api/auth`)
- `POST /login` - 用户登录
- `POST /register` - 用户注册
- `POST /refresh` - 刷新令牌
- `POST /logout` - 用户登出

#### 2. 客户管理 (`/api/customers`)
- `GET /` - 获取客户列表
- `POST /` - 创建客户
- `GET /:id` - 获取单个客户
- `PUT /:id` - 更新客户
- `DELETE /:id` - 删除客户

#### 3. 车辆管理 (`/api/cars`)
- `GET /` - 获取车辆列表
- `POST /` - 添加车辆
- `GET /:plateNumber` - 根据车牌获取车辆
- `PUT /:id` - 更新车辆信息
- `GET /:id/stats` - 获取车辆统计

#### 4. 维修记录 (`/api/repairs`)
- `GET /` - 获取维修记录
- `POST /` - 添加维修记录
- `GET /:id` - 获取单条记录
- `PUT /:id` - 更新记录
- `DELETE /:id` - 删除记录
- `GET /stats` - 维修统计

#### 5. 洗车记录 (`/api/wash`)
- `GET /` - 获取洗车记录
- `POST /` - 添加洗车记录
- `GET /:id` - 获取单条记录
- `PUT /:id` - 更新记录
- `DELETE /:id` - 删除记录
- `GET /stats` - 洗车统计

#### 6. OCR识别 (`/api/ocr`)
- `POST /recognize` - 通用文字识别
- `POST /license-plate` - 车牌识别
- `POST /vin` - VIN码识别
- `POST /invoice` - 发票识别

#### 7. 数据导出 (`/api/export`)
- `GET /cars` - 导出车辆数据
- `GET /repairs` - 导出维修记录
- `GET /wash` - 导出洗车记录

## 安全架构

### 认证机制

```javascript
// JWT Token结构
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "user_id": 1,
    "username": "admin",
    "role": "admin",
    "iat": 1640995200,    // 签发时间
    "exp": 1641081600     // 过期时间
  },
  "signature": "..."
}

// Token管理
- Access Token: 15分钟有效期
- Refresh Token: 7天有效期
- 支持令牌刷新机制
- 登出时令牌列入黑名单
```

### 安全中间件

```javascript
// 1. Helmet - 安全HTTP头部
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"]
    }
  }
}));

// 2. CORS配置
app.use(cors({
  origin: ['http://localhost:3000', 'http://localhost:8080'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// 3. API限流
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分钟
  max: 100, // 最多100个请求
  message: '请求过于频繁，请稍后再试'
});
```

### 数据验证

```javascript
// 使用express-validator进行数据验证
const { body, validationResult } = require('express-validator');

// 车辆信息验证规则
const carValidation = [
  body('plate_number').isLength({ min: 1, max: 20 }).withMessage('车牌号1-20个字符'),
  body('vin').isLength({ min: 17, max: 50 }).withMessage('车架号17-50个字符'),
  body('brand').notEmpty().withMessage('品牌不能为空'),
  body('model').notEmpty().withMessage('型号不能为空'),
  body('year').optional().isInt({ min: 1900, max: 2030 }).withMessage('年份格式错误')
];
```

## 测试架构

### 后端测试

```javascript
// Jest + SuperTest测试配置
module.exports = {
  testEnvironment: 'node',
  collectCoverageFrom: [
    'routes/**/*.js',
    'models/**/*.js',
    'services/**/*.js',
    'middleware/**/*.js'
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html']
};

// API接口测试示例
describe('Cars API', () => {
  test('POST /api/cars - 创建车辆', async () => {
    const carData = {
      plate_number: '京A12345',
      vin: 'LNBSCB1E5AH123456',
      brand: '丰田',
      model: '卡罗拉'
    };
    
    const response = await request(app)
      .post('/api/cars')
      .send(carData)
      .expect(201);
      
    expect(response.body.success).toBe(true);
    expect(response.body.data.plate_number).toBe(carData.plate_number);
  });
});
```

### 前端测试

```dart
// Widget测试示例
void main() {
  group('CarProvider Tests', () {
    testWidgets('添加车辆功能测试', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      
      // 查找添加车辆按钮
      final addButton = find.byKey(Key('add_car_button'));
      expect(addButton, findsOneWidget);
      
      // 点击按钮
      await tester.tap(addButton);
      await tester.pumpAndSettle();
      
      // 验证页面跳转
      expect(find.text('添加车辆'), findsOneWidget);
    });
  });
}
```

## 部署架构

### 开发环境

```yaml
Environment: Development
Frontend:
  - Flutter Web Development Server
  - Hot Reload Support
  - Debug Mode
  - Port: 8080

Backend:
  - Node.js with Nodemon
  - Auto-restart on changes
  - Debug Logging
  - Port: 3000

Database:
  - MySQL Local Instance
  - Development Data
  - Port: 3306
```

### 生产环境

```yaml
Environment: Production
Frontend:
  - Flutter Web Build
  - Minified Assets
  - CDN Distribution
  - HTTPS Only

Backend:
  - Node.js PM2 Process Manager
  - Load Balancing
  - Error Monitoring
  - HTTPS with SSL Certificate

Database:
  - MySQL Cluster
  - Master-Slave Replication
  - Automated Backups
  - SSL Connection

Infrastructure:
  - Nginx Reverse Proxy
  - Docker Containers
  - CI/CD Pipeline
  - Monitoring & Logging
```

### Docker部署

```dockerfile
# 后端Dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]

# 前端Dockerfile
FROM nginx:alpine
COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### 数据备份策略

```bash
#!/bin/bash
# database/backup.sh

# 1. 定时自动备份
# 每天凌晨2点执行
# 0 2 * * * /path/to/backup.sh

# 2. 备份保留策略
# - 每日备份保留30天
# - 每周备份保留3个月
# - 每月备份保留1年

# 3. 备份验证
# - 自动验证备份文件完整性
# - 定期恢复测试

# 4. 备份存储
# - 本地存储 + 云存储
# - 多地域备份
```

## 性能优化

### 前端优化
- 代码分割和懒加载
- 图片压缩和缓存
- Bundle Size优化
- 响应式设计优化

### 后端优化
- 数据库查询优化
- 缓存策略
- API响应优化
- 文件上传优化

### 数据库优化
- 索引优化
- 查询优化
- 连接池配置
- 读写分离

---

*最后更新时间: 2024-01-15*
*文档版本: v1.2.0* 