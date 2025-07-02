import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/car_provider.dart';
import '../config/app_config.dart';
import '../services/ocr_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 初始化时加载车辆列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CarProvider>().fetchCars();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 搜索栏
          _buildSearchBar(),

          // 功能按钮组
          _buildActionButtons(),

          // 分隔线
          const Divider(),

          // 车辆列表
          Expanded(
            child: _buildCarList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/add-car');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索车牌号或车架号',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: PopupMenuButton<String>(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'OCR识别',
            onSelected: (value) {
              _openOCRScan(value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'license_plate',
                child: ListTile(
                  leading: Icon(Icons.directions_car),
                  title: Text('车牌识别'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'vin',
                child: ListTile(
                  leading: Icon(Icons.confirmation_number),
                  title: Text('VIN码识别'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'invoice',
                child: ListTile(
                  leading: Icon(Icons.receipt),
                  title: Text('发票识别'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'general',
                child: ListTile(
                  leading: Icon(Icons.text_fields),
                  title: Text('通用识别'),
                  dense: true,
                ),
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onSubmitted: (value) {
          _searchCar(value);
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/customers');
                  },
                  icon: const Icon(Icons.people, size: 20),
                  label: const Text('客户管理'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/add-repair');
                  },
                  icon: const Icon(Icons.build, size: 20),
                  label: const Text('添加维修'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/wash-checkin');
                  },
                  icon: const Icon(Icons.local_car_wash, size: 20),
                  label: const Text('洗车打卡'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.pushNamed('ocr-scan');
                  },
                  icon: const Icon(Icons.camera_alt, size: 20),
                  label: const Text('文字识别'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarList() {
    return Consumer<CarProvider>(
      builder: (context, carProvider, child) {
        if (carProvider.isLoading && carProvider.cars.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (carProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64.r,
                  color: Colors.red,
                ),
                SizedBox(height: 16.h),
                Text(
                  carProvider.error!,
                  style: TextStyle(fontSize: 16.sp),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    carProvider.refreshCars();
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        if (carProvider.cars.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_car_outlined,
                  size: 64.r,
                  color: Colors.grey,
                ),
                SizedBox(height: 16.h),
                Text(
                  '暂无车辆记录',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    context.push('/add-car');
                  },
                  child: const Text('添加车辆'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => carProvider.refreshCars(),
          child: ListView.builder(
            itemCount: carProvider.cars.length,
            itemBuilder: (context, index) {
              final car = carProvider.cars[index];
              return Card(
                margin: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 8.h,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      car.plateNumber.isNotEmpty
                          ? car.plateNumber
                              .substring(car.plateNumber.length - 1)
                          : '车',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    car.plateNumber,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (car.brand != null && car.model != null)
                        Text('${car.brand} ${car.model}'),
                      Text(
                        '维修: ${car.repairCount ?? 0}次 | 洗车: ${car.washCount ?? 0}次',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('/car-detail?plateNumber=${car.plateNumber}');
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _searchCar(String query) {
    if (query.trim().isEmpty) {
      context.read<CarProvider>().refreshCars();
      return;
    }

    final carProvider = context.read<CarProvider>();

    // 先检查是否是完整的车牌号查询
    if (query.length >= 6) {
      carProvider.fetchCarByPlateNumber(query).then((found) {
        if (mounted) {
          if (found) {
            context.push('/car-detail?plateNumber=$query');
          } else {
            _showToast('未找到车牌号为 $query 的车辆');
          }
        }
      });
    } else {
      // 否则进行模糊搜索
      carProvider.searchCars(query);
    }
  }

  void _openOCRScan(String type) {
    OCRType? ocrType;
    switch (type) {
      case 'license_plate':
        ocrType = OCRType.licensePlate;
        break;
      case 'vin':
        ocrType = OCRType.vin;
        break;
      case 'invoice':
        ocrType = OCRType.invoice;
        break;
      case 'general':
        ocrType = OCRType.general;
        break;
    }

    if (ocrType != null) {
      context.pushNamed('ocr-scan', extra: {
        'type': ocrType,
        'onResult': (Map<String, dynamic> result) {
          // 处理OCR识别结果
          _handleOCRResult(result, ocrType!);
        },
      });
    }
  }

  void _handleOCRResult(Map<String, dynamic> result, OCRType type) {
    switch (type) {
      case OCRType.licensePlate:
        final plateNumber = result['plateNumber'] as String?;
        if (plateNumber != null && plateNumber.isNotEmpty) {
          _searchController.text = plateNumber;
          _searchCar(plateNumber);
        }
        break;
      case OCRType.vin:
        final vins = result['vins'] as List<String>?;
        if (vins != null && vins.isNotEmpty) {
          _searchController.text = vins.first;
          _searchCar(vins.first);
        }
        break;
      case OCRType.invoice:
        // 发票识别后可以直接跳转到添加维修记录页面
        final invoice = result['invoice'];
        final repairInfo = result['repairInfo'];
        if (invoice != null || repairInfo != null) {
          _showToast('识别成功！可以使用识别结果添加维修记录');
          // 可以在这里传递识别结果到添加维修页面
          context.push('/add-repair');
        }
        break;
      case OCRType.general:
        final fullText = result['fullText'] as String?;
        if (fullText != null && fullText.isNotEmpty) {
          _searchController.text = fullText;
          _showToast('文字识别完成');
        }
        break;
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
