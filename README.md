# 车辆维修记录管理系统

一个完整的车辆维修记录管理应用，包含Flutter前端、Node.js后端和MySQL数据库。

## 📱 项目概述

这是一个专业的车辆维修记录管理系统，支持：

- 🚗 车辆信息管理（车牌号、车架号等）
- 🔧 维修记录管理（维修项目、费用、日期等）
- 🚿 洗车记录管理（洗车类型、地点、费用等）
- 📊 统计分析功能（费用统计、次数统计等）
- 🔍 智能搜索功能（车牌号、维修项目等）
- 📷 OCR文字识别（车牌、VIN码、发票识别）
- 📱 移动端友好界面

## 🏗️ 项目结构

```
car2/
├── frontend/           # Flutter移动应用
│   ├── lib/
│   │   ├── models/     # 数据模型
│   │   ├── providers/  # 状态管理
│   │   ├── services/   # API服务
│   │   ├── pages/      # 界面页面
│   │   ├── config/     # 配置文件
│   │   └── routes/     # 路由管理
│   └── pubspec.yaml    # Flutter依赖配置
├── backend/            # Node.js后端API
│   ├── models/         # 数据库模型
│   ├── routes/         # API路由
│   ├── config.js       # 数据库配置
│   └── server.js       # 服务器入口
├── database/           # 数据库脚本
│   ├── create_tables.sql  # 建表脚本
│   ├── sample_data.sql    # 示例数据
│   └── README.md          # 数据库说明
└── README.md           # 项目说明
```

## 🚀 快速开始

### 环境要求

- Node.js 14+
- Flutter 3.0+
- MySQL 5.7+
- Android Studio 或 Xcode（用于移动端开发）

### 1. 数据库安装

```bash
# 登录MySQL
mysql -u root -p

# 创建数据库
CREATE DATABASE car_maintenance_system;
USE car_maintenance_system;

# 执行建表脚本
source database/create_tables.sql

# （可选）导入示例数据
source database/sample_data.sql
```

### 2. 后端安装运行

```bash
cd backend

# 安装依赖
npm install

# 配置数据库连接（编辑config.js）
# 修改数据库连接信息

# （可选）配置百度OCR
# 创建.env文件并添加：
# BAIDU_OCR_APP_ID=your_app_id
# BAIDU_OCR_API_KEY=your_api_key
# BAIDU_OCR_SECRET_KEY=your_secret_key

# 启动服务器
npm start

# 服务器将在 http://localhost:3000 启动
```

### 3. 前端安装运行

```bash
cd frontend

# 获取依赖
flutter pub get

# 运行应用（连接模拟器或真机）
flutter run

# 或构建APK
flutter build apk
```

## 📡 API接口

### 车辆管理

- `GET /api/cars` - 获取车辆列表
- `POST /api/cars` - 添加车辆
- `GET /api/cars/:plateNumber` - 根据车牌号获取车辆
- `PUT /api/cars/:id` - 更新车辆信息

### 维修记录管理

- `GET /api/repairs` - 获取维修记录列表
- `POST /api/repairs` - 添加维修记录
- `GET /api/repairs/:id` - 获取单条维修记录
- `PUT /api/repairs/:id` - 更新维修记录
- `DELETE /api/repairs/:id` - 删除维修记录

### 洗车记录管理

- `GET /api/wash` - 获取洗车记录列表
- `POST /api/wash` - 添加洗车记录
- `GET /api/wash/:id` - 获取单条洗车记录
- `PUT /api/wash/:id` - 更新洗车记录
- `DELETE /api/wash/:id` - 删除洗车记录

### 统计接口

- `GET /api/cars/:id/stats` - 获取车辆统计信息
- `GET /api/repairs/stats` - 获取维修统计信息
- `GET /api/wash/stats` - 获取洗车统计信息

### OCR文字识别

- `POST /api/ocr/recognize` - 通用OCR识别
- `POST /api/ocr/license-plate` - 车牌号识别
- `POST /api/ocr/vin` - VIN码识别
- `POST /api/ocr/invoice` - 发票信息识别
- `GET /api/ocr/config` - 获取OCR配置

详细的API文档请参考 [`backend/README.md`](backend/README.md)

## 📱 功能特性

### 🚗 车辆管理
- 添加车辆（车牌号、车架号、品牌、型号等）
- 车辆信息查看和编辑
- 车辆统计信息显示

### 🔧 维修记录
- 添加维修记录（维修项目、费用、日期、维修店等）
- 维修记录列表和搜索
- 维修类型分类（保养、维修、更换等）
- 维修费用统计

### 🚿 洗车记录
- 快速洗车打卡
- 洗车记录管理
- 洗车类型分类（基础洗车、精洗等）
- 洗车费用统计

### 📊 统计分析
- 费用统计图表
- 维修/洗车次数统计
- 按时间范围统计
- 车辆维护历史分析

### 📷 OCR文字识别
- 车牌号智能识别
- VIN码自动识别
- 维修发票信息提取
- 通用文字识别
- 拍照或相册选择图片
- 识别结果自动填充表单

## 🛠️ 技术栈

### 前端
- **Flutter 3.0+** - 跨平台移动应用框架
- **Provider** - 状态管理
- **Dio/HTTP** - 网络请求
- **Flutter Form Builder** - 表单构建
- **Go Router** - 路由管理
- **Image Picker** - 图片选择和相机功能
- **Permission Handler** - 权限管理

### 后端
- **Node.js** - 服务器运行环境
- **Express.js** - Web框架
- **Sequelize** - ORM数据库操作
- **MySQL** - 关系型数据库
- **Helmet** - 安全中间件
- **CORS** - 跨域支持
- **百度OCR SDK** - 文字识别服务
- **Multer** - 文件上传处理
- **Sharp** - 图片处理和优化

### 数据库
- **MySQL 8.0+** - 主数据库
- 4个核心表：customers（客户）、cars（车辆）、repairs（维修）、wash_logs（洗车）
- 数据库名称：`car_maintenance_system`

## 🌐 在线演示

- **Web应用**: http://localhost:8080 （本地运行）
- **API接口**: http://localhost:3000/api （本地运行）

## 📊 项目现状

### ✅ 已完成功能
- ✅ 完整的车辆信息管理
- ✅ 维修记录的增删改查
- ✅ 洗车记录管理
- ✅ OCR文字识别集成（百度OCR）
- ✅ 数据统计和分析
- ✅ Web端和移动端响应式设计
- ✅ API接口完整实现
- ✅ 数据库设计和优化

### 🔧 配置信息
- **后端端口**: 3000
- **前端端口**: 8080  
- **数据库**: MySQL 8.0+
- **OCR服务**: 百度智能云OCR（已配置测试账号）

## 📋 待办功能

- [ ] 用户认证和权限管理
- [ ] 数据导出功能（Excel/PDF）  
- [ ] 维修提醒和保养提醒
- [ ] 车辆照片管理功能
- [ ] 二维码扫描功能
- [ ] 数据备份和恢复
- [ ] 多语言支持（国际化）
- [ ] 移动端推送通知
- [ ] 报表生成和打印

## 🐛 已知问题

1. Flutter Web端某些权限功能需要优化
2. OCR识别准确率在光线不佳时可能下降
3. 部分依赖包版本需要持续更新

## 🚀 性能优化

- 数据库连接池优化
- API响应缓存机制
- 图片压缩和处理
- Flutter Web资源懒加载

## 🤝 贡献指南

欢迎贡献代码！请遵循以下步骤：

1. Fork 这个项目 
2. 创建特性分支: `git checkout -b feature/AmazingFeature`
3. 提交更改: `git commit -m 'Add some AmazingFeature'`
4. 推送到分支: `git push origin feature/AmazingFeature`
5. 创建 Pull Request

### 代码规范
- 后端遵循 ESLint 规范
- 前端遵循 Flutter/Dart 官方规范
- 提交信息使用中文，格式：`功能: 具体描述`

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 📧 联系方式

- **项目仓库**: [https://github.com/zhuyongdong1/car1.0.git](https://github.com/zhuyongdong1/car1.0.git)
- **问题反馈**: [GitHub Issues](https://github.com/zhuyongdong1/car1.0/issues)
- **功能建议**: 欢迎提交 Issue 或 Pull Request

## 🔧 技术支持

遇到问题？查看以下资源：

1. **文档**: 查看各模块的 README 文件
2. **API文档**: `backend/README.md`
3. **数据库文档**: `database/README.md`
4. **部署指南**: `DEPLOYMENT.md`
5. **OCR配置**: `OCR_GUIDE.md`

## 🙏 致谢

感谢以下开源项目和服务：

- **Flutter** - 跨平台移动开发框架
- **Node.js & Express** - 后端服务框架
- **MySQL** - 可靠的数据库系统
- **百度智能云** - OCR文字识别服务
- **Sequelize** - Node.js ORM框架

---

<div align="center">

**🚗 让车辆管理更智能，让维修记录更清晰 ✨**

如果这个项目对您有帮助，请给我们一个 ⭐ Star ⭐

</div> 