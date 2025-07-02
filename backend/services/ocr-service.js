const AipOcrClient = require('baidu-aip-sdk').ocr;
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const config = require('../config');

class OCRService {
  constructor() {
    this.client = new AipOcrClient(
      config.baiduOcr.appId,
      config.baiduOcr.apiKey,
      config.baiduOcr.secretKey
    );
    
    // 设置超时时间
    this.client.timeout = 10000;
  }

  /**
   * 预处理图片 - 提高OCR识别准确率
   */
  async preprocessImage(imagePath) {
    try {
      const processedPath = imagePath.replace(/\.(jpg|jpeg|png)$/i, '_processed.jpg');
      
      await sharp(imagePath)
        .resize(2000, 2000, { 
          fit: 'inside',
          withoutEnlargement: true 
        })
        .sharpen()
        .normalize()
        .jpeg({ quality: 90 })
        .toFile(processedPath);
        
      return processedPath;
    } catch (error) {
      console.error('图片预处理失败:', error);
      return imagePath; // 返回原图片路径
    }
  }

  /**
   * 通用OCR文字识别
   */
  async recognizeText(imagePath, options = {}) {
    try {
      const processedImagePath = await this.preprocessImage(imagePath);
      const image = fs.readFileSync(processedImagePath);
      
      const ocrOptions = {
        language_type: 'CHN_ENG',
        detect_direction: true,
        detect_language: true,
        probability: true,
        ...options
      };

      const result = await this.client.generalBasic(image, ocrOptions);
      
      // 清理临时文件
      if (processedImagePath !== imagePath && fs.existsSync(processedImagePath)) {
        fs.unlinkSync(processedImagePath);
      }
      
      if (result.error_code) {
        throw new Error(`OCR识别失败: ${result.error_msg}`);
      }

      return this.formatGeneralResult(result);
    } catch (error) {
      console.error('OCR识别失败:', error);
      throw error;
    }
  }

  /**
   * 车牌号识别
   */
  async recognizeLicensePlate(imagePath) {
    try {
      const processedImagePath = await this.preprocessImage(imagePath);
      const image = fs.readFileSync(processedImagePath);
      
      const result = await this.client.licensePlate(image);
      
      // 清理临时文件
      if (processedImagePath !== imagePath && fs.existsSync(processedImagePath)) {
        fs.unlinkSync(processedImagePath);
      }
      
      if (result.error_code) {
        throw new Error(`车牌识别失败: ${result.error_msg}`);
      }

      return this.formatLicensePlateResult(result);
    } catch (error) {
      console.error('车牌识别失败:', error);
      throw error;
    }
  }

  /**
   * VIN码识别
   */
  async recognizeVIN(imagePath) {
    try {
      const result = await this.recognizeText(imagePath, {
        language_type: 'ENG',
        detect_direction: true
      });
      
      // 从识别结果中提取可能的VIN码
      const vinPattern = /[A-HJ-NPR-Z0-9]{17}/g;
      const extractedText = result.words.map(item => item.words).join(' ');
      const vinMatches = extractedText.match(vinPattern);
      
      return {
        success: true,
        vins: vinMatches || [],
        fullText: extractedText,
        confidence: result.words.length > 0 ? 
          result.words.reduce((sum, item) => sum + item.probability, 0) / result.words.length : 0
      };
    } catch (error) {
      console.error('VIN码识别失败:', error);
      throw error;
    }
  }

  /**
   * 发票信息识别
   */
  async recognizeInvoice(imagePath) {
    try {
      const processedImagePath = await this.preprocessImage(imagePath);
      const image = fs.readFileSync(processedImagePath);
      
      // 先尝试增值税发票识别
      let result;
      try {
        result = await this.client.vatInvoice(image);
      } catch (vatError) {
        // 如果增值税发票识别失败，使用通用发票识别
        result = await this.client.receipt(image);
      }
      
      // 清理临时文件
      if (processedImagePath !== imagePath && fs.existsSync(processedImagePath)) {
        fs.unlinkSync(processedImagePath);
      }
      
      if (result.error_code) {
        throw new Error(`发票识别失败: ${result.error_msg}`);
      }

      return this.formatInvoiceResult(result);
    } catch (error) {
      console.error('发票识别失败:', error);
      throw error;
    }
  }

  /**
   * 格式化通用OCR结果
   */
  formatGeneralResult(result) {
    return {
      success: true,
      direction: result.direction || 0,
      language: result.language || 'unknown',
      words: (result.words_result || []).map(item => ({
        words: item.words,
        probability: item.probability || 0,
        location: item.location || null
      })),
      fullText: (result.words_result || []).map(item => item.words).join('\n')
    };
  }

  /**
   * 格式化车牌识别结果
   */
  formatLicensePlateResult(result) {
    const wordsResult = result.words_result;
    return {
      success: true,
      plateNumber: wordsResult?.number || '',
      color: wordsResult?.color || '',
      confidence: wordsResult?.probability || 0,
      location: wordsResult?.vertexes_location || null
    };
  }

  /**
   * 格式化发票识别结果
   */
  formatInvoiceResult(result) {
    const wordsResult = result.words_result || {};
    
    return {
      success: true,
      invoiceType: wordsResult.InvoiceType || '',
      invoiceCode: wordsResult.InvoiceCode || '',
      invoiceNum: wordsResult.InvoiceNum || '',
      invoiceDate: wordsResult.InvoiceDate || '',
      totalAmount: wordsResult.TotalAmount || '',
      amountInWords: wordsResult.AmountInWords || '',
      sellerName: wordsResult.SellerName || '',
      purchaserName: wordsResult.PurchaserName || '',
      commodityDetails: this.extractCommodityDetails(wordsResult),
      fullResult: wordsResult
    };
  }

  /**
   * 提取商品详情
   */
  extractCommodityDetails(wordsResult) {
    const details = [];
    
    // 处理不同类型发票的商品信息
    if (wordsResult.CommodityName) {
      details.push({
        name: wordsResult.CommodityName,
        amount: wordsResult.CommodityAmount || '',
        price: wordsResult.CommodityPrice || ''
      });
    }
    
    return details;
  }

  /**
   * 智能提取维修相关信息
   */
  extractRepairInfo(ocrResult) {
    const fullText = ocrResult.fullText || '';
    const words = ocrResult.words || [];
    
    // 提取金额
    const amountPattern = /(?:金额|费用|总计|合计|应付)[：:\s]*¥?(\d+(?:\.\d{2})?)/gi;
    const amounts = [];
    let match;
    while ((match = amountPattern.exec(fullText)) !== null) {
      amounts.push(parseFloat(match[1]));
    }
    
    // 提取日期
    const datePattern = /(\d{4}[-年]\d{1,2}[-月]\d{1,2}[日]?)/g;
    const dates = [];
    while ((match = datePattern.exec(fullText)) !== null) {
      dates.push(match[1].replace(/[年月]/g, '-').replace(/日/g, ''));
    }
    
    // 提取维修项目关键词
    const repairKeywords = [
      '换油', '保养', '维修', '更换', '检查', '清洗', '调整', '修理',
      '机油', '刹车', '轮胎', '空调', '电池', '火花塞', '滤芯'
    ];
    
    const detectedItems = [];
    repairKeywords.forEach(keyword => {
      if (fullText.includes(keyword)) {
        detectedItems.push(keyword);
      }
    });
    
    return {
      amounts: amounts,
      dates: dates,
      repairItems: detectedItems,
      confidence: ocrResult.words.length > 0 ? 
        ocrResult.words.reduce((sum, item) => sum + item.probability, 0) / ocrResult.words.length : 0
    };
  }
}

module.exports = new OCRService(); 