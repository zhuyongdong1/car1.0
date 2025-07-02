import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/customer_provider.dart';
import '../../providers/car_provider.dart';
import '../../providers/repair_provider.dart';
import '../../providers/wash_provider.dart';
import '../../models/customer.dart';
import '../../models/car.dart';
import '../../config/app_config.dart';
import 'add_customer_page.dart';

class CustomerDetailPage extends StatefulWidget {
  final int customerId;

  const CustomerDetailPage({super.key, required this.customerId});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Customer? _customer;
  List<Car> _customerCars = [];
  List<Repair> _customerRepairs = [];
  List<WashLog> _customerWashLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCustomerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customerProvider = context.read<CustomerProvider>();
      final carProvider = context.read<CarProvider>();
      final repairProvider = context.read<RepairProvider>();
      final washProvider = context.read<WashProvider>();

      // 加载客户信息
      await customerProvider.fetchCustomerById(widget.customerId);
      _customer = customerProvider.selectedCustomer;

      if (_customer != null) {
        // 并行加载关联数据
        await Future.wait([
          carProvider.fetchCars(),
          repairProvider.fetchRepairs(),
          washProvider.fetchAllWashLogs(),
        ]);

        // 筛选出属于当前客户的数据
        _customerCars = carProvider.cars
            .where((car) => car.customerId == widget.customerId)
            .toList();

        _customerRepairs = repairProvider.repairs
            .where((repair) => repair.customerId == widget.customerId)
            .toList();

        _customerWashLogs = washProvider.washLogs
            .where((washLog) => washLog.customerId == widget.customerId)
            .toList();

        // 按时间排序
        _customerRepairs.sort((a, b) => b.repairDate.compareTo(a.repairDate));
        _customerWashLogs.sort((a, b) => b.washTime.compareTo(a.washTime));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载客户信息失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('客户详情'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_customer == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('客户详情'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('客户信息不存在'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_customer!.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editCustomer(),
            tooltip: '编辑客户',
          ),
          PopupMenuButton(
            onSelected: (value) {
              switch (value) {
                case 'visit':
                  _updateVisitInfo();
                  break;
                case 'delete':
                  _showDeleteDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'visit',
                child: ListTile(
                  leading: Icon(Icons.store_mall_directory),
                  title: Text('更新到店信息'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('删除客户', style: TextStyle(color: Colors.red)),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: '基本信息', icon: Icon(Icons.person)),
            Tab(
                text: '车辆 (${_customerCars.length})',
                icon: const Icon(Icons.directions_car)),
            Tab(
                text: '维修 (${_customerRepairs.length})',
                icon: const Icon(Icons.build)),
            Tab(
                text: '洗车 (${_customerWashLogs.length})',
                icon: const Icon(Icons.local_car_wash)),
          ],
          labelColor: const Color(AppConfig.primaryColorValue),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(AppConfig.primaryColorValue),
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicInfoTab(),
          _buildCarsTab(),
          _buildRepairsTab(),
          _buildWashLogsTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 客户头像和基本信息
          _buildCustomerHeader(),

          const SizedBox(height: 16),

          // 统计卡片
          _buildStatsCards(),

          const SizedBox(height: 16),

          // 联系信息
          _buildContactInfo(),

          const SizedBox(height: 16),

          // 其他信息
          _buildOtherInfo(),
        ],
      ),
    );
  }

  Widget _buildCustomerHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 客户头像
            CircleAvatar(
              radius: 40,
              backgroundColor: _getVipColor(_customer!.vipLevel.value),
              child: Text(
                _customer!.name.isNotEmpty ? _customer!.name[0] : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 客户姓名和VIP等级
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _customer!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                _buildVipBadge(_customer!.vipLevel.value),
              ],
            ),

            const SizedBox(height: 8),

            // 客户类型
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _customer!.customerType.value == '企业'
                    ? Colors.blue[100]
                    : Colors.green[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _customer!.customerType.value,
                style: TextStyle(
                  fontSize: 14,
                  color: _customer!.customerType.value == '企业'
                      ? Colors.blue[800]
                      : Colors.green[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 电话号码
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _customer!.phone,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.call, size: 20),
                  onPressed: () => _callCustomer(_customer!.phone),
                  color: Colors.green,
                  tooltip: '拨打电话',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '车辆数量',
            '${_customerCars.length}',
            Icons.directions_car,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '到店次数',
            '${_customer!.visitCount}',
            Icons.store_mall_directory,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            '累计消费',
            '¥${_customer!.totalSpent}',
            Icons.monetization_on,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.contact_phone,
                    color: Color(AppConfig.primaryColorValue)),
                SizedBox(width: 8),
                Text(
                  '联系信息',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_customer!.phoneSecondary != null &&
                _customer!.phoneSecondary!.isNotEmpty) ...[
              _buildInfoRow(Icons.phone, '备用电话', _customer!.phoneSecondary!),
              const SizedBox(height: 12),
            ],
            if (_customer!.wechat != null && _customer!.wechat!.isNotEmpty) ...[
              _buildInfoRow(Icons.chat, '微信号', _customer!.wechat!),
              const SizedBox(height: 12),
            ],
            if (_customer!.email != null && _customer!.email!.isNotEmpty) ...[
              _buildInfoRow(Icons.email, '邮箱', _customer!.email!),
              const SizedBox(height: 12),
            ],
            if (_customer!.address != null &&
                _customer!.address!.isNotEmpty) ...[
              _buildInfoRow(Icons.location_on, '地址', _customer!.address!),
            ],
            if (_customer!.lastVisitDate != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.access_time,
                '最近到店',
                _formatDate(_customer!.lastVisitDate!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOtherInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Color(AppConfig.primaryColorValue)),
                SizedBox(width: 8),
                Text(
                  '其他信息',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_customer!.idCard != null && _customer!.idCard!.isNotEmpty) ...[
              _buildInfoRow(Icons.credit_card, '身份证号', _customer!.idCard!),
              const SizedBox(height: 12),
            ],
            if (_customer!.company != null &&
                _customer!.company!.isNotEmpty) ...[
              _buildInfoRow(Icons.business, '公司名称', _customer!.company!),
              const SizedBox(height: 12),
            ],
            if (_customer!.notes != null && _customer!.notes!.isNotEmpty) ...[
              _buildInfoRow(Icons.note, '备注', _customer!.notes!),
              const SizedBox(height: 12),
            ],
            _buildInfoRow(
              Icons.calendar_today,
              '创建时间',
              _customer!.createdAt != null
                  ? _formatDate(_customer!.createdAt!)
                  : '未知',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarsTab() {
    if (_customerCars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              '暂无车辆信息',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _addCarForCustomer(),
              icon: const Icon(Icons.add),
              label: const Text('添加车辆'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _customerCars.length,
      itemBuilder: (context, index) {
        final car = _customerCars[index];
        return _buildCarCard(car);
      },
    );
  }

  Widget _buildCarCard(Car car) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewCarDetail(car),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_car, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      car.plateNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showCarMenu(car),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (car.brand != null || car.model != null) ...[
                Text(
                  '${car.brand ?? ''} ${car.model ?? ''}'.trim(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (car.vin.isNotEmpty) ...[
                Text(
                  'VIN: ${car.vin}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepairsTab() {
    if (_customerRepairs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.build_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '暂无维修记录',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _customerRepairs.length,
      itemBuilder: (context, index) {
        final repair = _customerRepairs[index];
        return _buildRepairCard(repair);
      },
    );
  }

  Widget _buildRepairCard(Repair repair) {
    // 找到对应的车辆信息
    final car = _customerCars.firstWhere(
      (c) => c.id == repair.carId,
      orElse: () => Car(plateNumber: '未知车辆', vin: ''),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    repair.item,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '¥${repair.price}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  car.plateNumber,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(repair.repairDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (repair.note != null && repair.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                repair.note!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWashLogsTab() {
    if (_customerWashLogs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_car_wash_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '暂无洗车记录',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _customerWashLogs.length,
      itemBuilder: (context, index) {
        final washLog = _customerWashLogs[index];
        return _buildWashLogCard(washLog);
      },
    );
  }

  Widget _buildWashLogCard(WashLog washLog) {
    // 找到对应的车辆信息
    final car = _customerCars.firstWhere(
      (c) => c.id == washLog.carId,
      orElse: () => Car(plateNumber: '未知车辆', vin: ''),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_car_wash, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_getWashTypeDisplay(washLog.washType)}洗车',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '¥${washLog.price}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  car.plateNumber,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(washLog.washTime),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (washLog.location != null && washLog.location!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    washLog.location!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            if (washLog.note != null && washLog.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                washLog.note!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () {
        switch (_tabController.index) {
          case 1: // 车辆列表
            _addCarForCustomer();
            break;
          case 2: // 维修记录
            _addRepairForCustomer();
            break;
          case 3: // 洗车记录
            _addWashForCustomer();
            break;
          default:
            _editCustomer();
        }
      },
      child: Icon(_getFloatingActionButtonIcon()),
    );
  }

  IconData _getFloatingActionButtonIcon() {
    switch (_tabController.index) {
      case 1:
        return Icons.add_road;
      case 2:
        return Icons.build;
      case 3:
        return Icons.local_car_wash;
      default:
        return Icons.edit;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVipBadge(String vipLevel) {
    Color color = _getVipColor(vipLevel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        vipLevel,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getVipColor(String vipLevel) {
    switch (vipLevel) {
      case '银卡':
        return Colors.grey[600]!;
      case '金卡':
        return Colors.amber[600]!;
      case '钻石':
        return Colors.purple[600]!;
      default:
        return Colors.blue[600]!;
    }
  }

  String _getWashTypeDisplay(String washType) {
    switch (washType) {
      case 'self':
        return '自助';
      case 'auto':
        return '自动';
      case 'manual':
        return '人工';
      default:
        return '普通';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _editCustomer() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => AddCustomerPage(customer: _customer),
      ),
    )
        .then((_) {
      // 编辑完成后刷新数据
      _loadCustomerData();
    });
  }

  void _callCustomer(String phone) {
    // 这里可以集成拨号功能
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('拨打电话: $phone')),
    );
  }

  void _updateVisitInfo() async {
    try {
      final customerProvider = context.read<CustomerProvider>();
      await customerProvider.updateVisit(widget.customerId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('到店信息更新成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _loadCustomerData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除客户 "${_customer!.name}" 吗？\n\n此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCustomer();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _deleteCustomer() async {
    try {
      final customerProvider = context.read<CustomerProvider>();
      final success = await customerProvider.deleteCustomer(widget.customerId);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('客户删除成功！'),
            backgroundColor: Colors.green,
          ),
        );
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addCarForCustomer() {
    // 导航到添加车辆页面，预填充客户信息
    context.push('/add-car?customerId=${widget.customerId}');
  }

  void _addRepairForCustomer() {
    // 导航到添加维修页面，预填充客户信息
    context.push('/add-repair?customerId=${widget.customerId}');
  }

  void _addWashForCustomer() {
    // 导航到洗车页面，预填充客户信息
    context.push('/wash-checkin?customerId=${widget.customerId}');
  }

  void _viewCarDetail(Car car) {
    context.push('/car-detail?id=${car.id}');
  }

  void _showCarMenu(Car car) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('查看详情'),
              onTap: () {
                Navigator.pop(context);
                _viewCarDetail(car);
              },
            ),
            ListTile(
              leading: const Icon(Icons.build),
              title: const Text('添加维修'),
              onTap: () {
                Navigator.pop(context);
                context.push('/add-repair?carId=${car.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_car_wash),
              title: const Text('添加洗车'),
              onTap: () {
                Navigator.pop(context);
                context.push('/wash-checkin?carId=${car.id}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
