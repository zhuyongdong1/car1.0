import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../services/ocr_service.dart';

class OCRScanPage extends StatefulWidget {
  final OCRType? initialType;
  final Function(Map<String, dynamic>)? onResult;

  const OCRScanPage({
    super.key,
    this.initialType,
    this.onResult,
  });

  @override
  State<OCRScanPage> createState() => _OCRScanPageState();
}

class _OCRScanPageState extends State<OCRScanPage> {
  final OCRService _ocrService = OCRService();
  final ImagePicker _picker = ImagePicker();

  OCRType _selectedType = OCRType.general;
  File? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _ocrResult;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文字识别'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 识别类型选择
          _buildTypeSelector(),

          // 图片选择区域
          _buildImagePicker(),

          // 识别结果展示
          if (_ocrResult != null) _buildResultDisplay(),

          // 操作按钮
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择识别类型',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTypeChip('通用文字', OCRType.general, Icons.text_fields),
              _buildTypeChip('车牌号', OCRType.licensePlate, Icons.directions_car),
              _buildTypeChip('VIN码', OCRType.vin, Icons.confirmation_number),
              _buildTypeChip('发票信息', OCRType.invoice, Icons.receipt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, OCRType type, IconData icon) {
    final isSelected = _selectedType == type;
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = type;
            _ocrResult = null; // 清除之前的结果
          });
        }
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildImagePicker() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (_selectedImage != null)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.grey.shade300, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt,
                    size: 48,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '选择或拍摄图片',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('拍照'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('相册'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultDisplay() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '识别结果',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _copyResult,
                  icon: const Icon(Icons.copy),
                  tooltip: '复制结果',
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: _buildResultContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent() {
    switch (_selectedType) {
      case OCRType.licensePlate:
        return _buildLicensePlateResult();
      case OCRType.vin:
        return _buildVINResult();
      case OCRType.invoice:
        return _buildInvoiceResult();
      default:
        return _buildGeneralResult();
    }
  }

  Widget _buildLicensePlateResult() {
    final result = _ocrResult?['plateNumber'];
    final color = _ocrResult?['color'];
    final confidence = _ocrResult?['confidence'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultItem('车牌号', result ?? '未识别'),
        _buildResultItem('车牌颜色', color ?? '未识别'),
        _buildResultItem(
            '识别置信度', '${((confidence ?? 0) * 100).toStringAsFixed(1)}%'),
      ],
    );
  }

  Widget _buildVINResult() {
    final vins = _ocrResult?['vins'] as List<String>? ?? [];
    final fullText = _ocrResult?['fullText'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultItem('识别到的VIN码', vins.isEmpty ? '未识别' : vins.join('\n')),
        const SizedBox(height: 16),
        _buildResultItem('完整文本', fullText),
      ],
    );
  }

  Widget _buildInvoiceResult() {
    final invoice = _ocrResult?['invoice'];
    final repairInfo = _ocrResult?['repairInfo'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (invoice != null) ...[
          const Text('发票信息', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildResultItem('发票号码', invoice['invoiceNum'] ?? ''),
          _buildResultItem('发票日期', invoice['invoiceDate'] ?? ''),
          _buildResultItem('总金额', invoice['totalAmount'] ?? ''),
          _buildResultItem('销售方', invoice['sellerName'] ?? ''),
          const SizedBox(height: 16),
        ],
        if (repairInfo != null) ...[
          const Text('维修信息', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (repairInfo['amounts']?.isNotEmpty == true)
            _buildResultItem('识别金额', repairInfo['amounts'].join(', ')),
          if (repairInfo['dates']?.isNotEmpty == true)
            _buildResultItem('识别日期', repairInfo['dates'].join(', ')),
          if (repairInfo['repairItems']?.isNotEmpty == true)
            _buildResultItem('维修项目', repairInfo['repairItems'].join(', ')),
        ],
      ],
    );
  }

  Widget _buildGeneralResult() {
    final fullText = _ocrResult?['fullText'] ?? '';
    return Text(fullText, style: const TextStyle(fontSize: 14));
  }

  Widget _buildResultItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_selectedImage != null)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _performOCR,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isLoading ? '识别中...' : '开始识别'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (_ocrResult != null) ...[
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _applyResult,
              icon: const Icon(Icons.check),
              label: const Text('应用结果'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // 请求权限
      if (source == ImageSource.camera) {
        final permission = await Permission.camera.request();
        if (!permission.isGranted) {
          _showToast('需要相机权限才能拍照');
          return;
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _ocrResult = null; // 清除之前的结果
        });
      }
    } catch (e) {
      _showToast('选择图片失败: ${e.toString()}');
    }
  }

  Future<void> _performOCR() async {
    if (_selectedImage == null) {
      _showToast('请先选择图片');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      late dynamic result;

      switch (_selectedType) {
        case OCRType.licensePlate:
          final licenseResult =
              await _ocrService.recognizeLicensePlate(_selectedImage!);
          result = {
            'plateNumber': licenseResult.plateNumber,
            'color': licenseResult.color,
            'confidence': licenseResult.confidence,
          };
          break;
        case OCRType.vin:
          final vinResult = await _ocrService.recognizeVIN(_selectedImage!);
          result = {
            'vins': vinResult.vins,
            'fullText': vinResult.fullText,
            'confidence': vinResult.confidence,
          };
          break;
        case OCRType.invoice:
          final invoiceResult =
              await _ocrService.recognizeInvoice(_selectedImage!);
          result = {
            'invoice': {
              'invoiceNum': invoiceResult.invoice.invoiceNum,
              'invoiceDate': invoiceResult.invoice.invoiceDate,
              'totalAmount': invoiceResult.invoice.totalAmount,
              'sellerName': invoiceResult.invoice.sellerName,
            },
            'repairInfo': invoiceResult.repairInfo != null
                ? {
                    'amounts': invoiceResult.repairInfo!.amounts,
                    'dates': invoiceResult.repairInfo!.dates,
                    'repairItems': invoiceResult.repairInfo!.repairItems,
                  }
                : null,
            'fullText': invoiceResult.fullText,
          };
          break;
        default:
          final ocrResult =
              await _ocrService.recognizeText(_selectedImage!, _selectedType);
          if (ocrResult.success) {
            result = ocrResult.data;
          } else {
            throw Exception(ocrResult.message);
          }
          break;
      }

      setState(() {
        _ocrResult = result;
      });

      _showToast('识别成功！');
    } catch (e) {
      _showToast('识别失败: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyResult() {
    if (_ocrResult == null) return;

    String textToCopy = '';
    switch (_selectedType) {
      case OCRType.licensePlate:
        textToCopy = _ocrResult!['plateNumber'] ?? '';
        break;
      case OCRType.vin:
        final vins = _ocrResult!['vins'] as List<String>? ?? [];
        textToCopy = vins.join('\n');
        break;
      case OCRType.invoice:
        textToCopy = _ocrResult!['fullText'] ?? '';
        break;
      default:
        textToCopy = _ocrResult!['fullText'] ?? '';
        break;
    }

    Clipboard.setData(ClipboardData(text: textToCopy));
    _showToast('已复制到剪贴板');
  }

  void _applyResult() {
    if (_ocrResult != null && widget.onResult != null) {
      widget.onResult!(_ocrResult!);
      Navigator.of(context).pop(_ocrResult);
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }
}
