const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');
const Joi = require('joi');
const ocrService = require('../services/ocr-service');
const config = require('../config');

const router = express.Router();

// 确保上传目录存在
const uploadDir = config.upload?.uploadDir || './uploads';
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// 配置multer文件上传
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    const filename = `ocr_${uuidv4()}${ext}`;
    cb(null, filename);
  }
});

const fileFilter = (req, file, cb) => {
  const allowedMimeTypes = config.upload?.allowedMimeTypes || ['image/jpeg', 'image/png', 'image/jpg'];
  if (allowedMimeTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('不支持的文件类型，请上传 JPG、PNG 格式的图片'), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: config.upload?.maxFileSize || 5 * 1024 * 1024 // 5MB
  }
});

// 验证模式
const ocrRequestSchema = Joi.object({
  type: Joi.string().valid('general', 'license_plate', 'vin', 'invoice').required()
});

/**
 * @route POST /api/ocr/recognize
 * @desc 通用OCR文字识别
 * @access Public
 */
router.post('/recognize', upload.single('image'), async (req, res) => {
  let filePath = null;
  
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: '请上传图片文件'
      });
    }

    filePath = req.file.path;
    
    // 验证请求参数
    const { error, value } = ocrRequestSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        success: false,
        message: '参数验证失败',
        details: error.details[0].message
      });
    }

    const { type } = value;
    let result;

    // 根据类型调用不同的OCR方法
    switch (type) {
      case 'general':
        result = await ocrService.recognizeText(filePath);
        break;
      case 'license_plate':
        result = await ocrService.recognizeLicensePlate(filePath);
        break;
      case 'vin':
        result = await ocrService.recognizeVIN(filePath);
        break;
      case 'invoice':
        result = await ocrService.recognizeInvoice(filePath);
        // 如果是发票识别，额外提取维修信息
        if (result.success) {
          const repairInfo = ocrService.extractRepairInfo(result);
          result.repairInfo = repairInfo;
        }
        break;
      default:
        return res.status(400).json({
          success: false,
          message: '不支持的识别类型'
        });
    }

    res.json({
      success: true,
      message: 'OCR识别成功',
      data: result,
      fileInfo: {
        originalName: req.file.originalname,
        size: req.file.size,
        type: req.file.mimetype
      }
    });

  } catch (error) {
    console.error('OCR识别接口错误:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'OCR识别失败',
      error: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  } finally {
    // 清理上传的文件
    if (filePath && fs.existsSync(filePath)) {
      try {
        fs.unlinkSync(filePath);
      } catch (cleanupError) {
        console.error('清理临时文件失败:', cleanupError);
      }
    }
  }
});

/**
 * @route POST /api/ocr/license-plate
 * @desc 车牌号专用识别
 * @access Public
 */
router.post('/license-plate', upload.single('image'), async (req, res) => {
  let filePath = null;
  
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: '请上传车牌图片'
      });
    }

    filePath = req.file.path;
    const result = await ocrService.recognizeLicensePlate(filePath);

    res.json({
      success: true,
      message: '车牌识别成功',
      data: result
    });

  } catch (error) {
    console.error('车牌识别错误:', error);
    res.status(500).json({
      success: false,
      message: error.message || '车牌识别失败'
    });
  } finally {
    if (filePath && fs.existsSync(filePath)) {
      try {
        fs.unlinkSync(filePath);
      } catch (cleanupError) {
        console.error('清理临时文件失败:', cleanupError);
      }
    }
  }
});

/**
 * @route POST /api/ocr/invoice
 * @desc 发票信息识别（带维修信息提取）
 * @access Public
 */
router.post('/invoice', upload.single('image'), async (req, res) => {
  let filePath = null;
  
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: '请上传发票图片'
      });
    }

    filePath = req.file.path;
    const invoiceResult = await ocrService.recognizeInvoice(filePath);
    
    // 同时进行通用OCR识别以提取更多信息
    const generalResult = await ocrService.recognizeText(filePath);
    const repairInfo = ocrService.extractRepairInfo(generalResult);

    res.json({
      success: true,
      message: '发票识别成功',
      data: {
        invoice: invoiceResult,
        repairInfo: repairInfo,
        fullText: generalResult.fullText
      }
    });

  } catch (error) {
    console.error('发票识别错误:', error);
    res.status(500).json({
      success: false,
      message: error.message || '发票识别失败'
    });
  } finally {
    if (filePath && fs.existsSync(filePath)) {
      try {
        fs.unlinkSync(filePath);
      } catch (cleanupError) {
        console.error('清理临时文件失败:', cleanupError);
      }
    }
  }
});

/**
 * @route POST /api/ocr/vin
 * @desc VIN码专用识别
 * @access Public
 */
router.post('/vin', upload.single('image'), async (req, res) => {
  let filePath = null;
  
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: '请上传包含VIN码的图片'
      });
    }

    filePath = req.file.path;
    const result = await ocrService.recognizeVIN(filePath);

    res.json({
      success: true,
      message: 'VIN码识别成功',
      data: result
    });

  } catch (error) {
    console.error('VIN码识别错误:', error);
    res.status(500).json({
      success: false,
      message: error.message || 'VIN码识别失败'
    });
  } finally {
    if (filePath && fs.existsSync(filePath)) {
      try {
        fs.unlinkSync(filePath);
      } catch (cleanupError) {
        console.error('清理临时文件失败:', cleanupError);
      }
    }
  }
});

/**
 * @route GET /api/ocr/config
 * @desc 获取OCR配置信息（不包含敏感信息）
 * @access Public
 */
router.get('/config', (req, res) => {
  res.json({
    success: true,
    data: {
      maxFileSize: config.upload?.maxFileSize || 5 * 1024 * 1024,
      allowedMimeTypes: config.upload?.allowedMimeTypes || ['image/jpeg', 'image/png', 'image/jpg'],
      supportedTypes: ['general', 'license_plate', 'vin', 'invoice']
    }
  });
});

// 错误处理中间件
router.use((error, req, res, next) => {
  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        success: false,
        message: '文件大小超过限制（最大5MB）'
      });
    }
  }
  
  res.status(500).json({
    success: false,
    message: error.message || '服务器内部错误'
  });
});

module.exports = router; 