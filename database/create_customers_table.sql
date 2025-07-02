-- 创建客户信息表
CREATE TABLE IF NOT EXISTS customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT '客户姓名',
    phone VARCHAR(20) NOT NULL COMMENT '联系电话',
    phone_secondary VARCHAR(20) DEFAULT NULL COMMENT '备用电话',
    address TEXT DEFAULT NULL COMMENT '客户地址',
    email VARCHAR(100) DEFAULT NULL COMMENT '邮箱地址',
    wechat VARCHAR(100) DEFAULT NULL COMMENT '微信号',
    id_card VARCHAR(18) DEFAULT NULL COMMENT '身份证号',
    company VARCHAR(200) DEFAULT NULL COMMENT '公司名称',
    notes TEXT DEFAULT NULL COMMENT '客户备注',
    customer_type ENUM('个人', '企业') DEFAULT '个人' COMMENT '客户类型',
    vip_level ENUM('普通', '银卡', '金卡', '钻石') DEFAULT '普通' COMMENT 'VIP等级',
    total_spent DECIMAL(10,2) DEFAULT 0.00 COMMENT '累计消费金额',
    visit_count INT DEFAULT 0 COMMENT '到店次数',
    last_visit_date DATETIME DEFAULT NULL COMMENT '最后到店时间',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_phone (phone),
    INDEX idx_name (name),
    INDEX idx_customer_type (customer_type),
    INDEX idx_vip_level (vip_level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='客户信息表';

-- 修改车辆表，添加客户关联
ALTER TABLE cars 
ADD COLUMN customer_id INT DEFAULT NULL COMMENT '客户ID' AFTER id,
ADD INDEX idx_customer_id (customer_id),
ADD CONSTRAINT fk_cars_customer 
    FOREIGN KEY (customer_id) REFERENCES customers(id) 
    ON DELETE SET NULL ON UPDATE CASCADE;

-- 修改维修记录表，添加客户关联
ALTER TABLE repairs 
ADD COLUMN customer_id INT DEFAULT NULL COMMENT '客户ID' AFTER id,
ADD INDEX idx_customer_id (customer_id),
ADD CONSTRAINT fk_repairs_customer 
    FOREIGN KEY (customer_id) REFERENCES customers(id) 
    ON DELETE SET NULL ON UPDATE CASCADE;

-- 修改洗车记录表，添加客户关联  
ALTER TABLE wash_logs 
ADD COLUMN customer_id INT DEFAULT NULL COMMENT '客户ID' AFTER id,
ADD INDEX idx_customer_id (customer_id),
ADD CONSTRAINT fk_wash_logs_customer 
    FOREIGN KEY (customer_id) REFERENCES customers(id) 
    ON DELETE SET NULL ON UPDATE CASCADE;

-- 添加一些示例客户数据
INSERT INTO customers (name, phone, address, customer_type, notes) VALUES
('张三', '13800138001', '北京市朝阳区某某街道123号', '个人', '老客户，信誉良好'),
('李四', '13800138002', '北京市海淀区某某小区456号', '个人', '新客户'),
('王五汽车租赁公司', '13800138003', '北京市丰台区某某路789号', '企业', '企业客户，车辆较多'),
('赵六', '13800138004', '北京市西城区某某胡同101号', '个人', 'VIP客户'),
('钱七', '13800138005', '北京市东城区某某大厦202室', '个人', '经常保养'); 