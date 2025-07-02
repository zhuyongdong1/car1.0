# 车辆维修记录管理系统 - 后端API

## 概述

基于 Node.js + Express + Sequelize + MySQL 构建的车辆维修记录管理系统后端服务。

## 技术栈

- **Node.js** >= 14.x
- **Express** 4.x - Web框架
- **Sequelize** 6.x - ORM
- **MySQL** 8.x - 数据库
- **JWT** - 身份认证和授权
- **Jest/SuperTest** - 测试框架
- **express-validator** - 数据验证
- **CORS** - 跨域支持
- **Helmet** - 安全防护
- **Rate Limiting** - API限流
- **Morgan** - 请求日志记录
- **Multer** - 文件上传处理
- **Sharp** - 图片处理
- **百度OCR SDK** - 文字识别服务

## 快速开始

### 1. 安装依赖
```bash
npm install
```

### 2. 配置环境变量
创建 `.env` 文件（可参考 `config.js` 中的默认值）：
```env
DB_HOST=localhost
DB_PORT=3306
DB_NAME=car_maintenance_system
DB_USER=root
DB_PASSWORD=your_password
PORT=3000
NODE_ENV=development
```

### 3. 设置数据库
确保MySQL服务运行并创建数据库：
```sql
CREATE DATABASE car_maintenance_system;
```

### 4. 启动服务
```bash
# 开发模式（自动重启）
npm run dev

# 生产模式
npm start
```

## API 接口文档

### 基础响应格式

所有API响应都遵循统一格式：

**成功响应:**
```json
{
  "success": true,
  "message": "操作成功",
  "data": {...}
}
```

**错误响应:**
```json
{
  "success": false,
  "message": "错误信息",
  "code": "ERROR_CODE",
  "errors": ["详细错误信息"]
}
```

### 车辆管理 API (`/api/cars`)

#### 1. 添加车辆
- **POST** `/api/cars`
- **请求体:**
```json
{
  "plate_number": "京A12345",
  "vin": "LNBSCB1E5AH123456",
  "brand": "丰田",
  "model": "卡罗拉",
  "year": 2020,
  "color": "白色"
}
```

#### 2. 查询车辆记录
- **GET** `/api/cars/:plate_number`
- **响应:** 车辆信息 + 所有维修记录 + 洗车记录 + 统计信息

#### 3. 获取车辆列表
- **GET** `/api/cars?search=关键词&page=1&limit=10`
- **查询参数:**
  - `search`: 搜索关键词（车牌号、车架号、品牌、型号）
  - `page`: 页码（默认1）
  - `limit`: 每页数量（默认10）

#### 4. 更新车辆信息
- **PUT** `/api/cars/:id`

### 维修记录 API (`/api/repairs`)

#### 1. 添加维修记录
- **POST** `/api/repairs`
- **请求体:**
```json
{
  "plate_number": "京A12345",  // 或使用 car_id
  "repair_date": "2024-03-20",
  "item": "更换机油、机滤",
  "price": 320.00,
  "note": "使用全合成机油",
  "mechanic": "张师傅",
  "garage_name": "小李汽修店"
}
```

#### 2. 获取维修记录列表
- **GET** `/api/repairs`
- **查询参数:**
  - `car_id`: 车辆ID
  - `plate_number`: 车牌号
  - `start_date`: 开始日期
  - `end_date`: 结束日期
  - `search`: 搜索关键词
  - `page`: 页码
  - `limit`: 每页数量

#### 3. 获取单个维修记录
- **GET** `/api/repairs/:id`

#### 4. 更新维修记录
- **PUT** `/api/repairs/:id`

#### 5. 删除维修记录
- **DELETE** `/api/repairs/:id`

### 洗车记录 API (`/api/wash`)

#### 1. 添加洗车记录
- **POST** `/api/wash`
- **请求体:**
```json
{
  "plate_number": "京A12345",  // 或使用 car_id
  "wash_time": "2024-03-20T14:30:00Z",  // 可选，默认当前时间
  "wash_type": "manual",  // self/auto/manual
  "price": 25.00,
  "location": "小区门口洗车店",
  "note": "精洗+打蜡"
}
```

#### 2. 获取车辆洗车记录
- **GET** `/api/wash/:plate_number`
- **响应:** 包含洗车记录列表、统计信息、分类统计

#### 3. 获取所有洗车记录
- **GET** `/api/wash`
- **查询参数:**
  - `car_id`: 车辆ID
  - `plate_number`: 车牌号
  - `start_date`: 开始日期
  - `end_date`: 结束日期
  - `wash_type`: 洗车类型
  - `location`: 地点搜索
  - `page`: 页码
  - `limit`: 每页数量

#### 4. 更新洗车记录
- **PUT** `/api/wash/:id`

#### 5. 删除洗车记录
- **DELETE** `/api/wash/:id`

### 客户管理 API (`/api/customers`)

#### 1. 添加客户
- **POST** `/api/customers`
- **请求体:**
```json
{
  "name": "张三",
  "phone": "13800138000",
  "email": "zhangsan@example.com",
  "address": "北京市朝阳区xxx路xxx号",
  "note": "VIP客户"
}
```

#### 2. 获取客户列表
- **GET** `/api/customers`
- **查询参数:**
  - `search`: 搜索关键词（姓名、手机号）
  - `page`: 页码
  - `limit`: 每页数量

#### 3. 获取单个客户信息
- **GET** `/api/customers/:id`

#### 4. 更新客户信息
- **PUT** `/api/customers/:id`

#### 5. 删除客户
- **DELETE** `/api/customers/:id`

### OCR文字识别 API (`/api/ocr`)

#### 1. 通用文字识别
- **POST** `/api/ocr/recognize`
- **请求体:** `multipart/form-data`
  - `image`: 图片文件

#### 2. 车牌号识别
- **POST** `/api/ocr/license-plate`
- **请求体:** `multipart/form-data`
  - `image`: 图片文件

#### 3. VIN码识别
- **POST** `/api/ocr/vin`
- **请求体:** `multipart/form-data`
  - `image`: 图片文件

#### 4. 发票识别
- **POST** `/api/ocr/invoice`
- **请求体:** `multipart/form-data`
  - `image`: 图片文件

### 认证授权 API (`/api/auth`)

#### 1. 用户登录
- **POST** `/api/auth/login`
- **请求体:**
```json
{
  "username": "admin",
  "password": "password"
}
```

#### 2. 用户注册
- **POST** `/api/auth/register`
- **请求体:**
```json
{
  "username": "newuser",
  "password": "password",
  "email": "user@example.com"
}
```

#### 3. 刷新令牌
- **POST** `/api/auth/refresh`
- **请求头:** `Authorization: Bearer <refresh_token>`

#### 4. 用户登出
- **POST** `/api/auth/logout`
- **请求头:** `Authorization: Bearer <access_token>`

### 数据导出 API (`/api/export`)

#### 1. 导出车辆数据
- **GET** `/api/export/cars?format=csv|excel`
- **查询参数:**
  - `format`: 导出格式（csv或excel）
  - `search`: 搜索过滤

#### 2. 导出维修记录
- **GET** `/api/export/repairs?format=csv|excel`
- **查询参数:**
  - `format`: 导出格式
  - `start_date`: 开始日期
  - `end_date`: 结束日期

#### 3. 导出洗车记录
- **GET** `/api/export/wash?format=csv|excel`
- **查询参数:**
  - `format`: 导出格式
  - `start_date`: 开始日期
  - `end_date`: 结束日期

## 安全特性

### JWT认证
- 使用JWT进行用户身份验证
- Access Token有效期：15分钟
- Refresh Token有效期：7天
- 支持令牌刷新机制

### API限流
- 全局限流：100请求/15分钟
- OCR限流：50请求/15分钟（更严格）
- 基于IP地址限流

### 安全中间件
- **Helmet**: 设置安全HTTP头部
- **CORS**: 配置跨域访问策略
- **Morgan**: 记录访问日志

### 数据验证
- 所有输入数据进行严格验证
- SQL注入防护（Sequelize ORM）
- XSS攻击防护

## 数据备份

### 自动备份脚本
位置：`database/backup.sh`

```bash
# 执行数据库备份
./database/backup.sh car_maintenance_system root your_password

# 备份文件保存在
database/backups/car_maintenance_system_YYYYMMDD_HHMMSS.sql
```

### 定时备份设置
可以使用crontab设置定时备份：
```bash
# 每天凌晨2点自动备份
0 2 * * * /path/to/database/backup.sh car_maintenance_system root password
```

## 测试

### 运行测试
```bash
# 运行所有测试
npm test

# 测试覆盖率
npm run test:coverage
```

### 测试框架
- **Jest**: 测试运行器
- **SuperTest**: HTTP接口测试
- 包含API接口的完整测试套件

## 数据验证

API使用 `express-validator` 进行数据验证：

- 车牌号：1-20个字符，必填
- 车架号：17-50个字符，必填
- 维修费用/洗车费用：≥0的数字
- 日期格式：ISO8601标准
- 洗车类型：只能是 `self`、`auto`、`manual`

## 错误处理

### 常见错误码

- `VALIDATION_ERROR`: 数据验证失败
- `CAR_NOT_FOUND`: 车辆不存在
- `REPAIR_NOT_FOUND`: 维修记录不存在
- `WASH_LOG_NOT_FOUND`: 洗车记录不存在
- `DUPLICATE_ERROR`: 数据重复（车牌号/车架号已存在）
- `TOO_MANY_REQUESTS`: 请求限流
- `INTERNAL_ERROR`: 服务器内部错误

## 安全特性

1. **CORS配置**: 限制跨域访问源
2. **Helmet**: 设置安全HTTP头部
3. **Rate Limiting**: API请求频率限制（15分钟100次）
4. **数据验证**: 所有输入数据严格验证
5. **SQL注入防护**: 使用Sequelize ORM参数化查询

## 性能优化

1. **数据库索引**: 在常用查询字段上建立索引
2. **分页查询**: 所有列表接口支持分页
3. **连接池**: 配置数据库连接池
4. **缓存**: 可配置Redis缓存（可选）

## 部署说明

### 生产环境配置

1. 设置环境变量 `NODE_ENV=production`
2. 配置生产数据库连接
3. 启用日志记录
4. 配置反向代理（Nginx）
5. 使用PM2进程管理

### Docker部署（可选）

```dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

## 监控和日志

- 使用 `morgan` 记录HTTP请求日志
- 错误日志记录到控制台
- 健康检查端点：`GET /health`

## 开发注意事项

1. 所有API都返回统一的JSON格式
2. 错误处理遵循RESTful约定
3. 数据库事务处理（如需要）
4. 输入数据清理和转换
5. 适当的HTTP状态码 