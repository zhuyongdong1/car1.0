import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wash_provider.dart';
import 'wash_checkin_page.dart';

class WashListPage extends StatefulWidget {
  const WashListPage({super.key});

  @override
  State<WashListPage> createState() => _WashListPageState();
}

class _WashListPageState extends State<WashListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _currentSearch = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWashLogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadWashLogs() {
    final provider = Provider.of<WashProvider>(context, listen: false);
    provider.fetchAllWashLogs(refresh: true);
  }

  void _searchWashLogs(String query) {
    setState(() {
      _currentSearch = query;
    });
    final provider = Provider.of<WashProvider>(context, listen: false);
    if (query.isNotEmpty) {
      provider.searchWashLogsByLocation(query);
    } else {
      provider.fetchAllWashLogs(refresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('洗车记录'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWashLogs,
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
                hintText: '搜索车牌号或洗车地点',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _currentSearch.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchWashLogs('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _searchWashLogs,
            ),
          ),
          Expanded(
            child: Consumer<WashProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.washLogs.isEmpty) {
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
                          onPressed: _loadWashLogs,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.washLogs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_car_wash_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '暂无洗车记录',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '点击右下角按钮添加洗车记录',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadWashLogs(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.washLogs.length +
                        (provider.hasMoreData ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.washLogs.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final wash = provider.washLogs[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getWashTypeColor(wash.washType),
                            child: Icon(
                              _getWashTypeIcon(wash.washType),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            _getWashTypeText(wash.washType),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (wash.location != null)
                                Text('地点: ${wash.location}'),
                              Text(
                                '时间: ${wash.washTime.year}-${wash.washTime.month.toString().padLeft(2, '0')}-${wash.washTime.day.toString().padLeft(2, '0')} ${wash.washTime.hour.toString().padLeft(2, '0')}:${wash.washTime.minute.toString().padLeft(2, '0')}',
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
                                '¥${wash.price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${DateTime.now().difference(wash.washTime).inDays}天前',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showWashDetail(wash),
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
              builder: (context) => const WashCheckinPage(),
            ),
          );
          if (result == true) {
            _loadWashLogs();
          }
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _getWashTypeText(String type) {
    switch (type) {
      case 'basic':
        return '基础洗车';
      case 'premium':
        return '精洗服务';
      case 'interior':
        return '内饰清洁';
      case 'wax':
        return '打蜡护理';
      case 'detail':
        return '精细美容';
      case 'engine':
        return '发动机清洗';
      case 'self':
        return '自助洗车';
      default:
        return type;
    }
  }

  Color _getWashTypeColor(String type) {
    switch (type) {
      case 'basic':
        return Colors.blue;
      case 'premium':
        return Colors.purple;
      case 'interior':
        return Colors.green;
      case 'wax':
        return Colors.orange;
      case 'detail':
        return Colors.red;
      case 'engine':
        return Colors.brown;
      case 'self':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getWashTypeIcon(String type) {
    switch (type) {
      case 'basic':
        return Icons.local_car_wash;
      case 'premium':
        return Icons.star;
      case 'interior':
        return Icons.airline_seat_recline_extra;
      case 'wax':
        return Icons.auto_fix_high;
      case 'detail':
        return Icons.details;
      case 'engine':
        return Icons.settings;
      case 'self':
        return Icons.self_improvement;
      default:
        return Icons.local_car_wash;
    }
  }

  void _showWashDetail(wash) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getWashTypeText(wash.washType)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (wash.plateNumber != null)
                _buildDetailRow('车牌号', wash.plateNumber!),
              _buildDetailRow('洗车类型', _getWashTypeText(wash.washType)),
              _buildDetailRow(
                '洗车时间',
                '${wash.washTime.year}-${wash.washTime.month.toString().padLeft(2, '0')}-${wash.washTime.day.toString().padLeft(2, '0')} ${wash.washTime.hour.toString().padLeft(2, '0')}:${wash.washTime.minute.toString().padLeft(2, '0')}',
              ),
              _buildDetailRow('费用', '¥${wash.price.toStringAsFixed(2)}'),
              if (wash.location != null && wash.location!.isNotEmpty)
                _buildDetailRow('地点', wash.location!),
              if (wash.notes != null && wash.notes!.isNotEmpty)
                _buildDetailRow('备注', wash.notes!),
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
