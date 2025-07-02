import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/customer_provider.dart';
import '../../models/customer.dart';
import '../../config/app_config.dart';

class CustomerListPage extends StatefulWidget {
  const CustomerListPage({super.key});

  @override
  State<CustomerListPage> createState() => _CustomerListPageState();
}

class _CustomerListPageState extends State<CustomerListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchKeyword = '';
  String _selectedVipFilter = 'all';
  String _selectedTypeFilter = 'all';

  @override
  void initState() {
    super.initState();
    // 初始化加载客户列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers();
    });

    // 监听滚动事件实现分页加载
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        final customerProvider = context.read<CustomerProvider>();
        if (!customerProvider.isLoading && customerProvider.hasMore) {
          customerProvider.loadMoreCustomers();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('客户管理'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CustomerProvider>().fetchCustomers(refresh: true);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索和筛选区域
          _buildSearchAndFilter(),

          // 统计信息
          _buildStatsBar(),

          // 客户列表
          Expanded(
            child: _buildCustomerList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/add-customer');
        },
        tooltip: '添加客户',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 搜索框
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索客户姓名或电话',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchKeyword = '';
                        });
                        _performSearch();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchKeyword = value;
              });
            },
            onSubmitted: (value) {
              _performSearch();
            },
          ),

          const SizedBox(height: 12),

          // 筛选选项
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedVipFilter,
                  decoration: const InputDecoration(
                    labelText: 'VIP等级',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('全部')),
                    DropdownMenuItem(value: '普通', child: Text('普通')),
                    DropdownMenuItem(value: '银卡', child: Text('银卡')),
                    DropdownMenuItem(value: '金卡', child: Text('金卡')),
                    DropdownMenuItem(value: '钻石', child: Text('钻石')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedVipFilter = value!;
                    });
                    _performSearch();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTypeFilter,
                  decoration: const InputDecoration(
                    labelText: '客户类型',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('全部')),
                    DropdownMenuItem(value: '个人', child: Text('个人')),
                    DropdownMenuItem(value: '企业', child: Text('企业')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedTypeFilter = value!;
                    });
                    _performSearch();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar() {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('总客户', '${customerProvider.totalCount}'),
              _buildStatItem('VIP客户', '${customerProvider.vipCount}'),
              _buildStatItem('今日到店', '${customerProvider.todayVisits}'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(AppConfig.primaryColorValue),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerList() {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        if (customerProvider.isLoading && customerProvider.customers.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (customerProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  customerProvider.error!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    customerProvider.fetchCustomers(refresh: true);
                  },
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        if (customerProvider.customers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  '暂无客户数据',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '点击右下角按钮添加第一个客户',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await customerProvider.fetchCustomers(refresh: true);
          },
          child: ListView.builder(
            controller: _scrollController,
            itemCount: customerProvider.customers.length +
                (customerProvider.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == customerProvider.customers.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final customer = customerProvider.customers[index];
              return _buildCustomerCard(customer);
            },
          ),
        );
      },
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          context.push('/customer-detail?id=${customer.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 客户基本信息行
              Row(
                children: [
                  // 客户头像
                  CircleAvatar(
                    backgroundColor: _getVipColor(customer.vipLevel.value),
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0] : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 客户信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              customer.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildVipBadge(customer.vipLevel.value),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.phone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 客户类型标签
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: customer.customerType.value == '企业'
                          ? Colors.blue[100]
                          : Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      customer.customerType.value,
                      style: TextStyle(
                        fontSize: 12,
                        color: customer.customerType.value == '企业'
                            ? Colors.blue[800]
                            : Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),

              // 地址
              if (customer.address != null && customer.address!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        customer.address!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // 统计信息
              Row(
                children: [
                  _buildInfoChip(
                    Icons.store_mall_directory,
                    '到店${customer.visitCount}次',
                    Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.monetization_on,
                    '消费¥${customer.totalSpent}',
                    Colors.green,
                  ),
                  const Spacer(),
                  if (customer.lastVisitDate != null)
                    Text(
                      '最近：${_formatDate(customer.lastVisitDate!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVipBadge(String vipLevel) {
    Color color = _getVipColor(vipLevel);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        vipLevel,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '今天';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  void _performSearch() {
    final customerProvider = context.read<CustomerProvider>();

    // 构建搜索参数
    Map<String, dynamic> params = {};

    if (_searchKeyword.isNotEmpty) {
      params['search'] = _searchKeyword;
    }

    if (_selectedVipFilter != 'all') {
      params['vipLevel'] = _selectedVipFilter;
    }

    if (_selectedTypeFilter != 'all') {
      params['customerType'] = _selectedTypeFilter;
    }

    // 设置筛选条件并重新获取客户列表
    customerProvider.setFilter(
      customerType: _selectedTypeFilter != 'all' ? _selectedTypeFilter : null,
      vipLevel: _selectedVipFilter != 'all' ? _selectedVipFilter : null,
    );

    if (_searchKeyword.isNotEmpty) {
      customerProvider.searchCustomers(_searchKeyword);
    } else {
      customerProvider.fetchCustomers(refresh: true);
    }
  }
}
