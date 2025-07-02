import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/repair_provider.dart';
import 'add_repair_page.dart';

class RepairListPage extends StatefulWidget {
  const RepairListPage({super.key});

  @override
  State<RepairListPage> createState() => _RepairListPageState();
}

class _RepairListPageState extends State<RepairListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _currentSearch = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRepairs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadRepairs() {
    final provider = Provider.of<RepairProvider>(context, listen: false);
    provider.fetchRepairs(refresh: true);
  }

  void _searchRepairs(String query) {
    setState(() {
      _currentSearch = query;
    });
    final provider = Provider.of<RepairProvider>(context, listen: false);
    if (query.isNotEmpty) {
      provider.searchRepairs(query);
    } else {
      provider.fetchRepairs(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('维修记录'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRepairs,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索车牌号、维修项目或维修店',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _currentSearch.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchRepairs('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _searchRepairs,
            ),
          ),
          Expanded(
            child: Consumer<RepairProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.repairs.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          '加载失败: ${provider.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadRepairs,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.repairs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.build_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '暂无维修记录',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '点击右下角按钮添加维修记录',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadRepairs(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.repairs.length +
                        (provider.hasMoreData ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.repairs.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final repair = provider.repairs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.build, color: Colors.white),
                          ),
                          title: Text(
                            repair.item,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('维修店: ${repair.garageName ?? ''}'),
                              Text(
                                '日期: ${repair.repairDate.year}-${repair.repairDate.month.toString().padLeft(2, '0')}-${repair.repairDate.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '¥${repair.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showRepairDetail(repair),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddRepairPage(),
            ),
          );
          if (result == true) {
            _loadRepairs();
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _getRepairTypeText(String type) {
    switch (type) {
      case 'maintenance':
        return '保养维护';
      case 'repair':
        return '故障维修';
      case 'replacement':
        return '零件更换';
      case 'upgrade':
        return '改装升级';
      case 'inspection':
        return '检查检验';
      case 'other':
        return '其他';
      default:
        return type;
    }
  }

  void _showRepairDetail(repair) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(repair.item),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (repair.plateNumber != null)
                _buildDetailRow('车牌号', repair.plateNumber!),
              _buildDetailRow('维修店', repair.repairShop),
              _buildDetailRow(
                '维修日期',
                '${repair.repairDate.year}-${repair.repairDate.month.toString().padLeft(2, '0')}-${repair.repairDate.day.toString().padLeft(2, '0')}',
              ),
              _buildDetailRow('费用', '¥${repair.cost.toStringAsFixed(2)}'),
              if (repair.mileage != null)
                _buildDetailRow('里程数', '${repair.mileage} 公里'),
              if (repair.repairType != null)
                _buildDetailRow('维修类型', _getRepairTypeText(repair.repairType!)),
              if (repair.notes != null && repair.notes!.isNotEmpty)
                _buildDetailRow('备注', repair.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                  fontWeight: FontWeight.w500, color: Colors.grey),
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
}
