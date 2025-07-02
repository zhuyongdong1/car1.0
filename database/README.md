# 数据库设置指南

## 环境要求
- MySQL 8.0 或更高版本
- 确保MySQL服务已启动

## 快速设置

### 1. 登录MySQL
```bash
mysql -u root -p
```

### 2. 执行建表脚本
```sql
source create_tables.sql;
```

### 3. 插入示例数据（可选）
```sql
source sample_data.sql;
```

## 数据库结构

### cars 表（车辆信息）
- `id`: 主键，自增
- `plate_number`: 车牌号（唯一）
- `vin`: 车架号（唯一）
- `brand`: 品牌
- `model`: 型号
- `year`: 年份
- `color`: 颜色
- `created_at`: 创建时间
- `updated_at`: 更新时间

### repairs 表（维修记录）
- `id`: 主键，自增
- `car_id`: 车辆ID（外键）
- `repair_date`: 维修日期
- `item`: 维修项目
- `price`: 维修费用
- `note`: 备注
- `mechanic`: 维修师傅
- `garage_name`: 维修厂名称
- `created_at`: 创建时间
- `updated_at`: 更新时间

### wash_logs 表（洗车记录）
- `id`: 主键，自增
- `car_id`: 车辆ID（外键）
- `wash_time`: 洗车时间
- `wash_type`: 洗车类型（self/auto/manual）
- `price`: 洗车费用
- `location`: 洗车地点
- `note`: 备注
- `created_at`: 创建时间

## 数据库配置

确保在后端应用中使用以下配置：

```javascript
const config = {
  database: 'car_maintenance_system',
  username: 'root',
  password: 'your_password',
  host: 'localhost',
  port: 3306,
  dialect: 'mysql'
};
```

## 注意事项

1. 确保数据库字符集为 `utf8mb4` 以支持中文
2. 车牌号和车架号设置了唯一索引
3. 使用外键约束保证数据完整性
4. 示例数据包含了常见的维修和洗车场景

## 数据备份

使用 `backup.sh` 脚本可以快速备份数据库：

```bash
cd database
./backup.sh [数据库名] [用户名] [密码]
```

备份文件会保存到 `database/backups/` 目录下，文件名包含时间戳。
