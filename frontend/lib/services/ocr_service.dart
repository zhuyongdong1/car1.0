import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// OCR识别类型枚举
enum OCRType {
  general,
  licensePlate,
  vin,
  invoice,
}

/// OCR识别结果模型
class OCRResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final String? error;

  OCRResult({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory OCRResult.fromJson(Map<String, dynamic> json) {
    return OCRResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
      error: json['error'],
    );
  }
}

class OCRService {
  static const String _baseUrl = 'http://localhost:3000/api';
  final Dio _dio = Dio();

  /// 通用OCR文字识别
  Future<OCRResult> recognizeText(File imageFile, OCRType type) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        'type': _getTypeString(type),
      });

      final response = await _dio.post(
        '$_baseUrl/ocr/recognize',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      return OCRResult.fromJson(response.data);
    } catch (e) {
      debugPrint('OCR识别失败: $e');
      return OCRResult(
        success: false,
        message: '识别失败: ${e.toString()}',
        error: e.toString(),
      );
    }
  }

  /// 车牌号识别
  Future<LicensePlateResult> recognizeLicensePlate(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '$_baseUrl/ocr/license-plate',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.data['success']) {
        return LicensePlateResult.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      debugPrint('车牌识别失败: $e');
      throw Exception('车牌识别失败: ${e.toString()}');
    }
  }

  /// VIN码识别
  Future<VINResult> recognizeVIN(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '$_baseUrl/ocr/vin',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.data['success']) {
        return VINResult.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      debugPrint('VIN码识别失败: $e');
      throw Exception('VIN码识别失败: ${e.toString()}');
    }
  }

  /// 发票识别
  Future<InvoiceResult> recognizeInvoice(File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '$_baseUrl/ocr/invoice',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.data['success']) {
        return InvoiceResult.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      debugPrint('发票识别失败: $e');
      throw Exception('发票识别失败: ${e.toString()}');
    }
  }

  /// 获取OCR配置信息
  Future<OCRConfig> getOCRConfig() async {
    try {
      final response = await _dio.get('$_baseUrl/ocr/config');

      if (response.data['success']) {
        return OCRConfig.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      debugPrint('获取OCR配置失败: $e');
      throw Exception('获取OCR配置失败: ${e.toString()}');
    }
  }

  /// 将OCR类型转换为字符串
  String _getTypeString(OCRType type) {
    switch (type) {
      case OCRType.general:
        return 'general';
      case OCRType.licensePlate:
        return 'license_plate';
      case OCRType.vin:
        return 'vin';
      case OCRType.invoice:
        return 'invoice';
    }
  }
}

/// 车牌识别结果
class LicensePlateResult {
  final String plateNumber;
  final String color;
  final double confidence;
  final Map<String, dynamic>? location;

  LicensePlateResult({
    required this.plateNumber,
    required this.color,
    required this.confidence,
    this.location,
  });

  factory LicensePlateResult.fromJson(Map<String, dynamic> json) {
    return LicensePlateResult(
      plateNumber: json['plateNumber'] ?? '',
      color: json['color'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
      location: json['location'],
    );
  }
}

/// VIN码识别结果
class VINResult {
  final List<String> vins;
  final String fullText;
  final double confidence;

  VINResult({
    required this.vins,
    required this.fullText,
    required this.confidence,
  });

  factory VINResult.fromJson(Map<String, dynamic> json) {
    return VINResult(
      vins: List<String>.from(json['vins'] ?? []),
      fullText: json['fullText'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}

/// 发票识别结果
class InvoiceResult {
  final InvoiceInfo invoice;
  final RepairInfo? repairInfo;
  final String fullText;

  InvoiceResult({
    required this.invoice,
    this.repairInfo,
    required this.fullText,
  });

  factory InvoiceResult.fromJson(Map<String, dynamic> json) {
    return InvoiceResult(
      invoice: InvoiceInfo.fromJson(json['invoice'] ?? {}),
      repairInfo: json['repairInfo'] != null
          ? RepairInfo.fromJson(json['repairInfo'])
          : null,
      fullText: json['fullText'] ?? '',
    );
  }
}

/// 发票信息
class InvoiceInfo {
  final String invoiceType;
  final String invoiceCode;
  final String invoiceNum;
  final String invoiceDate;
  final String totalAmount;
  final String amountInWords;
  final String sellerName;
  final String purchaserName;
  final List<CommodityDetail> commodityDetails;

  InvoiceInfo({
    required this.invoiceType,
    required this.invoiceCode,
    required this.invoiceNum,
    required this.invoiceDate,
    required this.totalAmount,
    required this.amountInWords,
    required this.sellerName,
    required this.purchaserName,
    required this.commodityDetails,
  });

  factory InvoiceInfo.fromJson(Map<String, dynamic> json) {
    return InvoiceInfo(
      invoiceType: json['invoiceType'] ?? '',
      invoiceCode: json['invoiceCode'] ?? '',
      invoiceNum: json['invoiceNum'] ?? '',
      invoiceDate: json['invoiceDate'] ?? '',
      totalAmount: json['totalAmount'] ?? '',
      amountInWords: json['amountInWords'] ?? '',
      sellerName: json['sellerName'] ?? '',
      purchaserName: json['purchaserName'] ?? '',
      commodityDetails: (json['commodityDetails'] as List?)
              ?.map((item) => CommodityDetail.fromJson(item))
              .toList() ??
          [],
    );
  }
}

/// 商品详情
class CommodityDetail {
  final String name;
  final String amount;
  final String price;

  CommodityDetail({
    required this.name,
    required this.amount,
    required this.price,
  });

  factory CommodityDetail.fromJson(Map<String, dynamic> json) {
    return CommodityDetail(
      name: json['name'] ?? '',
      amount: json['amount'] ?? '',
      price: json['price'] ?? '',
    );
  }
}

/// 维修信息
class RepairInfo {
  final List<double> amounts;
  final List<String> dates;
  final List<String> repairItems;
  final double confidence;

  RepairInfo({
    required this.amounts,
    required this.dates,
    required this.repairItems,
    required this.confidence,
  });

  factory RepairInfo.fromJson(Map<String, dynamic> json) {
    return RepairInfo(
      amounts: (json['amounts'] as List?)
              ?.map((item) => (item as num).toDouble())
              .toList() ??
          [],
      dates: List<String>.from(json['dates'] ?? []),
      repairItems: List<String>.from(json['repairItems'] ?? []),
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}

/// OCR配置
class OCRConfig {
  final int maxFileSize;
  final List<String> allowedMimeTypes;
  final List<String> supportedTypes;

  OCRConfig({
    required this.maxFileSize,
    required this.allowedMimeTypes,
    required this.supportedTypes,
  });

  factory OCRConfig.fromJson(Map<String, dynamic> json) {
    return OCRConfig(
      maxFileSize: json['maxFileSize'] ?? 5242880,
      allowedMimeTypes: List<String>.from(json['allowedMimeTypes'] ?? []),
      supportedTypes: List<String>.from(json['supportedTypes'] ?? []),
    );
  }
}
