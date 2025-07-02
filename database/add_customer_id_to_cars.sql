-- 为cars表添加customer_id字段来建立与customers表的关联
-- 执行时间：预计执行时间很短（几秒钟）

USE car_maintenance_system;

-- 检查字段是否已存在
SELECT COLUMN_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'car_maintenance_system' 
  AND TABLE_NAME = 'cars' 
  AND COLUMN_NAME = 'customer_id';

-- 添加customer_id字段（如果不存在）
ALTER TABLE cars 
ADD COLUMN IF NOT EXISTS customer_id INT NULL 
COMMENT '关联的客户ID';

-- 创建外键约束
ALTER TABLE cars 
ADD CONSTRAINT FK_cars_customer_id 
FOREIGN KEY (customer_id) REFERENCES customers(id) 
ON UPDATE CASCADE 
ON DELETE SET NULL;

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_cars_customer_id ON cars(customer_id);

-- 验证字段已成功添加
DESCRIBE cars;

-- 显示外键约束
SELECT 
    CONSTRAINT_NAME,
    TABLE_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'car_maintenance_system'
  AND TABLE_NAME = 'cars'
  AND REFERENCED_TABLE_NAME IS NOT NULL;

SHOW CREATE TABLE cars; 