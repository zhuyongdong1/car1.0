# 车辆维修记录管理系统 - 部署指南

本文档详细介绍如何在生产环境中部署车辆维修记录管理系统。

## 📋 目录

1. [系统要求](#系统要求)
2. [生产环境部署](#生产环境部署)
3. [Docker部署](#docker部署)
4. [云服务器部署](#云服务器部署)
5. [移动应用发布](#移动应用发布)
6. [监控和维护](#监控和维护)
7. [故障排除](#故障排除)

## 🖥️ 系统要求

### 服务器硬件要求

**最低配置：**
- CPU: 2核心
- 内存: 4GB
- 存储: 20GB SSD
- 网络: 1Mbps带宽

**推荐配置：**
- CPU: 4核心+
- 内存: 8GB+
- 存储: 40GB+ SSD
- 网络: 10Mbps+带宽

### 软件要求

- **操作系统**: Ubuntu 20.04+ / CentOS 8+ / Windows Server 2019+
- **Node.js**: v16.0+
- **MySQL**: v8.0+
- **Nginx**: v1.18+（可选，用于反向代理）
- **SSL证书**（生产环境推荐）

## 🚀 生产环境部署

### 1. 服务器准备

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装必要软件
sudo apt install -y curl wget git nginx mysql-server

# 安装Node.js (使用NodeSource仓库)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# 验证安装
node --version
npm --version
mysql --version
```

### 2. 数据库配置

```bash
# 安全配置MySQL
sudo mysql_secure_installation

# 登录MySQL
sudo mysql -u root -p

# 创建生产数据库和用户
CREATE DATABASE car_maintenance_prod;
CREATE USER 'car_app'@'localhost' IDENTIFIED BY 'your_secure_password';
GRANT ALL PRIVILEGES ON car_maintenance_prod.* TO 'car_app'@'localhost';
FLUSH PRIVILEGES;
EXIT;

# 导入数据结构
mysql -u car_app -p car_maintenance_prod < database/create_tables.sql
```

### 3. 后端部署

```bash
# 创建应用目录
sudo mkdir -p /var/www/car-maintenance
sudo chown $USER:$USER /var/www/car-maintenance

# 克隆代码
cd /var/www/car-maintenance
git clone https://github.com/your-username/car-maintenance-app.git .

# 安装后端依赖
cd backend
npm install --production

# 创建生产环境配置
cp config.js config.prod.js

# 编辑生产配置（修改数据库连接）
nano config.prod.js
```

**生产环境配置示例 (config.prod.js):**

```javascript
module.exports = {
  database: {
    host: 'localhost',
    port: 3306,
    username: 'car_app',
    password: 'your_secure_password',
    database: 'car_maintenance_prod',
    dialect: 'mysql',
    logging: false,
    pool: {
      max: 20,
      min: 5,
      acquire: 30000,
      idle: 10000
    }
  },
  server: {
    port: process.env.PORT || 3000,
    host: '127.0.0.1'
  },
  cors: {
    origin: ['https://your-domain.com', 'https://app.your-domain.com'],
    credentials: true
  },
  security: {
    jwtSecret: 'your-super-secret-jwt-key',
    bcryptRounds: 12
  }
};
```

### 4. 进程管理（PM2）

```bash
# 全局安装PM2
sudo npm install -g pm2

# 创建PM2配置文件
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'car-maintenance-api',
    script: 'server.js',
    cwd: '/var/www/car-maintenance/backend',
    instances: 'max',
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: '/var/log/car-maintenance/error.log',
    out_file: '/var/log/car-maintenance/access.log',
    log_file: '/var/log/car-maintenance/combined.log',
    time: true
  }]
};
EOF

# 创建日志目录
sudo mkdir -p /var/log/car-maintenance
sudo chown $USER:$USER /var/log/car-maintenance

# 启动应用
pm2 start ecosystem.config.js

# 设置开机自启
pm2 startup
pm2 save
```

### 5. Nginx反向代理

```bash
# 创建Nginx配置
sudo nano /etc/nginx/sites-available/car-maintenance
```

**Nginx配置示例:**

```nginx
server {
    listen 80;
    server_name api.your-domain.com;

    # 重定向到HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.your-domain.com;

    # SSL配置
    ssl_certificate /path/to/your/certificate.crt;
    ssl_certificate_key /path/to/your/private.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;

    # 安全头
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;

    # API代理
    location /api/ {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
    }

    # 健康检查
    location /health {
        proxy_pass http://127.0.0.1:3000/health;
        access_log off;
    }
}
```

```bash
# 启用站点
sudo ln -s /etc/nginx/sites-available/car-maintenance /etc/nginx/sites-enabled/

# 测试配置
sudo nginx -t

# 重启Nginx
sudo systemctl restart nginx
```

## 🐳 Docker部署

### 1. 后端Dockerfile

```dockerfile
# backend/Dockerfile
FROM node:18-alpine

WORKDIR /app

# 复制package文件
COPY package*.json ./

# 安装依赖
RUN npm ci --only=production

# 复制源代码
COPY . .

# 暴露端口
EXPOSE 3000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# 启动应用
CMD ["node", "server.js"]
```

### 2. Docker Compose

```yaml
# docker-compose.prod.yml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: car-maintenance-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: car_maintenance_prod
      MYSQL_USER: car_app
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
      - ./database/create_tables.sql:/docker-entrypoint-initdb.d/create_tables.sql
    ports:
      - "3306:3306"
    networks:
      - car-maintenance-network

  api:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: car-maintenance-api
    restart: unless-stopped
    environment:
      NODE_ENV: production
      DB_HOST: mysql
      DB_PORT: 3306
      DB_NAME: car_maintenance_prod
      DB_USER: car_app
      DB_PASSWORD: ${MYSQL_PASSWORD}
    ports:
      - "3000:3000"
    depends_on:
      - mysql
    networks:
      - car-maintenance-network
    volumes:
      - ./logs:/app/logs

  nginx:
    image: nginx:alpine
    container_name: car-maintenance-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - api
    networks:
      - car-maintenance-network

volumes:
  mysql_data:

networks:
  car-maintenance-network:
    driver: bridge
```

### 3. 启动Docker服务

```bash
# 创建环境变量文件
cat > .env << EOF
MYSQL_ROOT_PASSWORD=your_super_secure_root_password
MYSQL_PASSWORD=your_secure_app_password
EOF

# 启动服务
docker-compose -f docker-compose.prod.yml up -d

# 查看日志
docker-compose -f docker-compose.prod.yml logs -f
```

## ☁️ 云服务器部署

### AWS EC2部署

1. **创建EC2实例**
   - 选择Ubuntu 20.04 LTS AMI
   - 实例类型：t3.medium或更高
   - 配置安全组：开放22(SSH)、80(HTTP)、443(HTTPS)端口

2. **配置RDS数据库**
   ```bash
   # 创建RDS MySQL实例
   # 配置安全组允许EC2访问
   # 记录RDS端点地址
   ```

3. **部署应用**
   ```bash
   # SSH连接EC2
   ssh -i your-key.pem ubuntu@your-ec2-ip

   # 按照上述生产环境部署步骤操作
   # 修改数据库配置为RDS端点
   ```

### 阿里云ECS部署

1. **购买ECS实例**
   - 系统：Ubuntu 20.04
   - 配置：2核4GB或更高
   - 开放安全组端口

2. **配置RDS数据库**
   ```bash
   # 购买RDS MySQL实例
   # 配置白名单允许ECS访问
   ```

3. **域名和SSL配置**
   ```bash
   # 购买域名并备案
   # 申请免费SSL证书
   # 配置DNS解析
   ```

## 📱 移动应用发布

### Android应用发布

1. **生成签名密钥**
   ```bash
   # 生成keystore
   keytool -genkey -v -keystore car-maintenance-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias car-maintenance-key
   ```

2. **配置签名**
   ```properties
   # android/key.properties
   storePassword=your_store_password
   keyPassword=your_key_password
   keyAlias=car-maintenance-key
   storeFile=../car-maintenance-key.jks
   ```

3. **构建APK**
   ```bash
   cd frontend
   flutter build apk --release
   ```

4. **发布到Google Play**
   - 创建Google Play开发者账号
   - 上传APK到Google Play Console
   - 填写应用信息和描述
   - 提交审核

### iOS应用发布

1. **配置Xcode项目**
   ```bash
   cd frontend
   flutter build ios --release
   open ios/Runner.xcworkspace
   ```

2. **配置签名证书**
   - 在Apple Developer中创建应用ID
   - 配置Provisioning Profile
   - 在Xcode中配置Team和Bundle ID

3. **发布到App Store**
   - 构建Archive
   - 上传到App Store Connect
   - 填写应用信息
   - 提交审核

## 📊 监控和维护

### 1. 日志监控

```bash
# 安装日志分析工具
sudo apt install logrotate

# 配置日志轮转
sudo nano /etc/logrotate.d/car-maintenance
```

```
/var/log/car-maintenance/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
}
```

### 2. 性能监控

```bash
# 安装监控工具
npm install -g clinic

# 性能分析
clinic doctor -- node server.js
```

### 3. 数据库备份

```bash
# 创建备份脚本
cat > /home/ubuntu/backup-db.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/car-maintenance"
mkdir -p $BACKUP_DIR

mysqldump -u car_app -p$MYSQL_PASSWORD car_maintenance_prod > \
  $BACKUP_DIR/car_maintenance_$DATE.sql

# 保留最近30天的备份
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
EOF

chmod +x /home/ubuntu/backup-db.sh

# 添加到crontab（每天凌晨2点备份）
echo "0 2 * * * /home/ubuntu/backup-db.sh" | crontab -
```

## 🔧 故障排除

### 常见问题

1. **API响应慢**
   ```bash
   # 检查数据库连接
   pm2 logs car-maintenance-api
   
   # 优化数据库查询
   # 添加索引
   # 检查慢查询日志
   ```

2. **内存不足**
   ```bash
   # 查看内存使用
   free -h
   htop
   
   # 调整PM2实例数
   pm2 scale car-maintenance-api 2
   ```

3. **SSL证书过期**
   ```bash
   # 检查证书有效期
   openssl x509 -in certificate.crt -noout -dates
   
   # 更新证书
   # 重启Nginx
   sudo systemctl reload nginx
   ```

### 应急恢复

1. **数据库恢复**
   ```bash
   # 从备份恢复
   mysql -u car_app -p car_maintenance_prod < backup_file.sql
   ```

2. **服务快速重启**
   ```bash
   # 重启所有服务
   pm2 restart all
   sudo systemctl restart nginx mysql
   ```

## 📞 技术支持

如遇到部署问题，请通过以下方式获取支持：

- 📧 邮箱：support@your-domain.com
- 📱 电话：+86-xxx-xxxx-xxxx
- 💬 在线客服：https://your-domain.com/support

---

**部署完成后，请及时更新系统和依赖包，定期备份数据！** 