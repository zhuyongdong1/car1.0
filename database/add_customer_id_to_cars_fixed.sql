-- 为cars表添加customer_id字段来建立与customers表的关联
-- 执行时间：预计执行时间很短（几秒钟）

USE car_maintenance_system;

-- 检查字段是否已存在
SELECT COUNT(*) as column_exists
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'car_maintenance_system' 
  AND TABLE_NAME = 'cars' 
  AND COLUMN_NAME = 'customer_id';

-- 显示当前cars表结构
DESCRIBE cars;

-- 由于MySQL版本可能不支持IF NOT EXISTS，我们手动检查后再执行
-- 如果字段不存在，执行以下语句：

-- 添加customer_id字段
ALTER TABLE cars 
ADD COLUMN customer_id INT NULL 
COMMENT '关联的客户ID';

-- 创建外键约束
ALTER TABLE cars 
ADD CONSTRAINT FK_cars_customer_id 
FOREIGN KEY (customer_id) REFERENCES customers(id) 
ON UPDATE CASCADE 
ON DELETE SET NULL;

-- 创建索引以提高查询性能
CREATE INDEX idx_cars_customer_id ON cars(customer_id);

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