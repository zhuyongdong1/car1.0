-- 车辆维修记录管理系统数据库
-- 创建数据库
CREATE DATABASE IF NOT EXISTS car_maintenance_system DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE car_maintenance_system;

-- 车辆表
CREATE TABLE IF NOT EXISTS cars (
    id INT AUTO_INCREMENT PRIMARY KEY,
    plate_number VARCHAR(20) NOT NULL UNIQUE COMMENT '车牌号',
    vin VARCHAR(50) NOT NULL UNIQUE COMMENT '车架号',
    brand VARCHAR(50) COMMENT '品牌',
    model VARCHAR(50) COMMENT '型号', 
    year INT COMMENT '年份',
    color VARCHAR(20) COMMENT '颜色',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_plate_number (plate_number),
    INDEX idx_vin (vin)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='车辆信息表';

-- 维修记录表
CREATE TABLE IF NOT EXISTS repairs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    car_id INT NOT NULL COMMENT '车辆ID',
    repair_date DATE NOT NULL COMMENT '维修日期',
    item TEXT NOT NULL COMMENT '维修项目',
    price DECIMAL(10,2) DEFAULT 0.00 COMMENT '维修费用',
    note TEXT COMMENT '备注',
    mechanic VARCHAR(50) COMMENT '维修师傅',
    garage_name VARCHAR(100) COMMENT '维修厂名称',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE CASCADE,
    INDEX idx_car_id (car_id),
    INDEX idx_repair_date (repair_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='维修记录表';

-- 洗车记录表
CREATE TABLE IF NOT EXISTS wash_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    car_id INT NOT NULL COMMENT '车辆ID',
    wash_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '洗车时间',
    wash_type ENUM('self', 'auto', 'manual') DEFAULT 'manual' COMMENT '洗车类型：self自助,auto自动,manual人工',
    price DECIMAL(8,2) DEFAULT 0.00 COMMENT '洗车费用',
    location VARCHAR(100) COMMENT '洗车地点',
    note TEXT COMMENT '备注',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    FOREIGN KEY (car_id) REFERENCES cars(id) ON DELETE CASCADE,
    INDEX idx_car_id (car_id),
    INDEX idx_wash_time (wash_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='洗车记录表'; 