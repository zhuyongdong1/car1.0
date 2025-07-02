-- 为repairs和wash_logs表添加customer_id字段来建立与customers表的关联
-- 执行时间：预计执行时间很短（几秒钟）

USE car_maintenance_system;

-- 1. 为repairs表添加customer_id字段
-- 检查字段是否已存在
SELECT COUNT(*) as repairs_column_exists
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'car_maintenance_system' 
  AND TABLE_NAME = 'repairs' 
  AND COLUMN_NAME = 'customer_id';

-- 添加customer_id字段到repairs表
ALTER TABLE repairs 
ADD COLUMN customer_id INT NULL 
COMMENT '关联的客户ID';

-- 创建外键约束
ALTER TABLE repairs 
ADD CONSTRAINT FK_repairs_customer_id 
FOREIGN KEY (customer_id) REFERENCES customers(id) 
ON UPDATE CASCADE 
ON DELETE SET NULL;

-- 创建索引以提高查询性能
CREATE INDEX idx_repairs_customer_id ON repairs(customer_id);

-- 2. 为wash_logs表添加customer_id字段
-- 检查字段是否已存在
SELECT COUNT(*) as wash_logs_column_exists
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'car_maintenance_system' 
  AND TABLE_NAME = 'wash_logs' 
  AND COLUMN_NAME = 'customer_id';

-- 添加customer_id字段到wash_logs表
ALTER TABLE wash_logs 
ADD COLUMN customer_id INT NULL 
COMMENT '关联的客户ID';

-- 创建外键约束
ALTER TABLE wash_logs 
ADD CONSTRAINT FK_wash_logs_customer_id 
FOREIGN KEY (customer_id) REFERENCES customers(id) 
ON UPDATE CASCADE 
ON DELETE SET NULL;

-- 创建索引以提高查询性能
CREATE INDEX idx_wash_logs_customer_id ON wash_logs(customer_id);

-- 3. 根据car_id自动填充customer_id（如果cars表中有customer_id的话）
-- 更新repairs表的customer_id
UPDATE repairs r 
JOIN cars c ON r.car_id = c.id 
SET r.customer_id = c.customer_id 
WHERE c.customer_id IS NOT NULL;

-- 更新wash_logs表的customer_id  
UPDATE wash_logs w 
JOIN cars c ON w.car_id = c.id 
SET w.customer_id = c.customer_id 
WHERE c.customer_id IS NOT NULL;

-- 4. 验证更新结果
-- 检查repairs表结构
DESCRIBE repairs;

-- 检查wash_logs表结构
DESCRIBE wash_logs;

-- 显示外键约束
SELECT 
    CONSTRAINT_NAME,
    TABLE_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'car_maintenance_system'
  AND TABLE_NAME IN ('repairs', 'wash_logs')
  AND REFERENCED_TABLE_NAME IS NOT NULL;

-- 检查数据统计
SELECT 'repairs' as table_name, 
       COUNT(*) as total_records,
       COUNT(customer_id) as records_with_customer
FROM repairs
UNION ALL
SELECT 'wash_logs' as table_name,
       COUNT(*) as total_records, 
       COUNT(customer_id) as records_with_customer
FROM wash_logs; 