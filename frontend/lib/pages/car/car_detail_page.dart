import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/car.dart';
import '../../providers/car_provider.dart';
import '../../providers/repair_provider.dart';
import '../../providers/wash_provider.dart';

class CarDetailPage extends StatefulWidget {
  final int carId;

  const CarDetailPage({super.key, required this.carId});

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Car? car;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final carProvider = Provider.of<CarProvider>(context, listen: false);
    final repairProvider = Provider.of<RepairProvider>(context, listen: false);
    final washProvider = Provider.of<WashProvider>(context, listen: false);

    // 根据carId获取车辆信息
    try {
      car = carProvider.cars.firstWhere((c) => c.id == widget.carId);
    } catch (e) {
      // 如果找不到车辆，car将保持为null
      car = null;
    }

    repairProvider.fetchRepairsByCarId(widget.carId);
    washProvider.fetchWashLogsByCarId(widget.carId);
  }

  @override
  Widget build(BuildContext context) {
    if (car == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('车辆详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(car!.plateNumber),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '车辆信息'),
            Tab(text: '维修记录'),
            Tab(text: '洗车记录'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCarInfoTab(),
          _buildRepairHistoryTab(),
          _buildWashHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildCarInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_car,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '基本信息',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildInfoRow('车牌号码', car!.plateNumber),
                  _buildInfoRow('车架号', car!.vin),
                  if (car!.brand != null) _buildInfoRow('品牌', car!.brand!),
                  if (car!.model != null) _buildInfoRow('型号', car!.model!),
                  if (car!.year != null)
                    _buildInfoRow('年份', car!.year.toString()),
                  if (car!.color != null) _buildInfoRow('颜色', car!.color!),
                  if (car!.createdAt != null)
                    _buildInfoRow('添加时间',
                        '${car!.createdAt!.year}-${car!.createdAt!.month.toString().padLeft(2, '0')}-${car!.createdAt!.day.toString().padLeft(2, '0')}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Consumer2<RepairProvider, WashProvider>(
            builder: (context, repairProvider, washProvider, child) {
              final carRepairs = repairProvider.repairs
                  .where((repair) => repair.carId == widget.carId)
                  .toList();
              final carWashes = washProvider.washLogs
                  .where((wash) => wash.carId == widget.carId)
                  .toList();

              final totalRepairCost = carRepairs.fold<double>(
                  0.0, (sum, repair) => sum + repair.price);
              final totalWashCost =
                  carWashes.fold<double>(0.0, (sum, wash) => sum + wash.price);

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            '统计信息',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              '维修次数',
                              carRepairs.length.toString(),
                              Icons.build,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              '洗车次数',
                              carWashes.length.toString(),
                              Icons.local_car_wash,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              '维修费用',
                              '¥${totalRepairCost.toStringAsFixed(2)}',
                              Icons.attach_money,
                              Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              '洗车费用',
                              '¥${totalWashCost.toStringAsFixed(2)}',
                              Icons.water_drop,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairHistoryTab() {
    return Consumer<RepairProvider>(
      builder: (context, provider, child) {
        final carRepairs = provider.repairs
            .where((repair) => repair.carId == widget.carId)
            .toList();

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (carRepairs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无维修记录', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: carRepairs.length,
          itemBuilder: (context, index) {
            final repair = carRepairs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.build, color: Colors.white),
                ),
                title: Text(repair.item),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(repair.garageName ?? ''),
                    Text(
                      '${repair.repairDate.year}-${repair.repairDate.month.toString().padLeft(2, '0')}-${repair.repairDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: Text(
                  '¥${repair.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWashHistoryTab() {
    return Consumer<WashProvider>(
      builder: (context, provider, child) {
        final carWashes = provider.washLogs
            .where((wash) => wash.carId == widget.carId)
            .toList();

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (carWashes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_car_wash_outlined,
                    size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('暂无洗车记录', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: carWashes.length,
          itemBuilder: (context, index) {
            final wash = carWashes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.local_car_wash, color: Colors.white),
                ),
                title: Text(wash.washType),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (wash.location != null) Text(wash.location!),
                    Text(
                      '${wash.washTime.year}-${wash.washTime.month.toString().padLeft(2, '0')}-${wash.washTime.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: Text(
                  '¥${wash.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
