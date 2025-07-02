class Customer {
  final int? id;
  final String name;
  final String phone;
  final String? phoneSecondary;
  final String? address;
  final String? email;
  final String? wechat;
  final String? idCard;
  final String? company;
  final String? notes;
  final CustomerType customerType;
  final VipLevel vipLevel;
  final double totalSpent;
  final int visitCount;
  final DateTime? lastVisitDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.phoneSecondary,
    this.address,
    this.email,
    this.wechat,
    this.idCard,
    this.company,
    this.notes,
    this.customerType = CustomerType.personal,
    this.vipLevel = VipLevel.normal,
    this.totalSpent = 0.0,
    this.visitCount = 0,
    this.lastVisitDate,
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      phoneSecondary: json['phoneSecondary'],
      address: json['address'],
      email: json['email'],
      wechat: json['wechat'],
      idCard: json['idCard'],
      company: json['company'],
      notes: json['notes'],
      customerType: CustomerType.fromString(json['customerType'] ?? '个人'),
      vipLevel: VipLevel.fromString(json['vipLevel'] ?? '普通'),
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      visitCount: json['visitCount'] ?? 0,
      lastVisitDate: json['lastVisitDate'] != null
          ? DateTime.parse(json['lastVisitDate'])
          : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'phoneSecondary': phoneSecondary,
      'address': address,
      'email': email,
      'wechat': wechat,
      'idCard': idCard,
      'company': company,
      'notes': notes,
      'customerType': customerType.value,
      'vipLevel': vipLevel.value,
      'totalSpent': totalSpent,
      'visitCount': visitCount,
      'lastVisitDate': lastVisitDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? phoneSecondary,
    String? address,
    String? email,
    String? wechat,
    String? idCard,
    String? company,
    String? notes,
    CustomerType? customerType,
    VipLevel? vipLevel,
    double? totalSpent,
    int? visitCount,
    DateTime? lastVisitDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      phoneSecondary: phoneSecondary ?? this.phoneSecondary,
      address: address ?? this.address,
      email: email ?? this.email,
      wechat: wechat ?? this.wechat,
      idCard: idCard ?? this.idCard,
      company: company ?? this.company,
      notes: notes ?? this.notes,
      customerType: customerType ?? this.customerType,
      vipLevel: vipLevel ?? this.vipLevel,
      totalSpent: totalSpent ?? this.totalSpent,
      visitCount: visitCount ?? this.visitCount,
      lastVisitDate: lastVisitDate ?? this.lastVisitDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName {
    if (customerType == CustomerType.company &&
        company != null &&
        company!.isNotEmpty) {
      return '$name (${company!})';
    }
    return name;
  }

  String get vipLevelText => vipLevel.displayName;
  String get customerTypeText => customerType.displayName;

  bool get isVip => vipLevel != VipLevel.normal;

  String get phoneDisplay {
    if (phoneSecondary != null && phoneSecondary!.isNotEmpty) {
      return '$phone / $phoneSecondary';
    }
    return phone;
  }

  @override
  String toString() {
    return 'Customer{id: $id, name: $name, phone: $phone, customerType: ${customerType.value}, vipLevel: ${vipLevel.value}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id && other.phone == phone;
  }

  @override
  int get hashCode => id.hashCode ^ phone.hashCode;
}

enum CustomerType {
  personal('个人'),
  company('企业');

  const CustomerType(this.value);
  final String value;

  String get displayName => value;

  static CustomerType fromString(String value) {
    return CustomerType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => CustomerType.personal,
    );
  }
}

enum VipLevel {
  normal('普通'),
  silver('银卡'),
  gold('金卡'),
  diamond('钻石');

  const VipLevel(this.value);
  final String value;

  String get displayName => value;

  static VipLevel fromString(String value) {
    return VipLevel.values.firstWhere(
      (level) => level.value == value,
      orElse: () => VipLevel.normal,
    );
  }

  bool get isVip => this != VipLevel.normal;
}

class CustomerStatistics {
  final int totalCars;
  final int totalRepairs;
  final int totalWashes;
  final double totalSpent;
  final double avgRepairCost;
  final DateTime? lastVisit;

  CustomerStatistics({
    this.totalCars = 0,
    this.totalRepairs = 0,
    this.totalWashes = 0,
    this.totalSpent = 0.0,
    this.avgRepairCost = 0.0,
    this.lastVisit,
  });

  factory CustomerStatistics.fromJson(Map<String, dynamic> json) {
    return CustomerStatistics(
      totalCars: json['totalCars'] ?? 0,
      totalRepairs: json['totalRepairs'] ?? 0,
      totalWashes: json['totalWashes'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      avgRepairCost: (json['avgRepairCost'] ?? 0).toDouble(),
      lastVisit:
          json['lastVisit'] != null ? DateTime.parse(json['lastVisit']) : null,
    );
  }
}

class CustomerOverview {
  final int totalCustomers;
  final int newCustomersThisMonth;
  final int vipCustomers;
  final List<VipDistribution> vipDistribution;
  final List<TypeDistribution> typeDistribution;
  final List<TopSpender> topSpenders;

  CustomerOverview({
    required this.totalCustomers,
    required this.newCustomersThisMonth,
    required this.vipCustomers,
    required this.vipDistribution,
    required this.typeDistribution,
    required this.topSpenders,
  });

  factory CustomerOverview.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] ?? {};
    return CustomerOverview(
      totalCustomers: summary['totalCustomers'] ?? 0,
      newCustomersThisMonth: summary['newCustomersThisMonth'] ?? 0,
      vipCustomers: summary['vipCustomers'] ?? 0,
      vipDistribution: (json['vipDistribution'] as List?)
              ?.map((item) => VipDistribution.fromJson(item))
              .toList() ??
          [],
      typeDistribution: (json['typeDistribution'] as List?)
              ?.map((item) => TypeDistribution.fromJson(item))
              .toList() ??
          [],
      topSpenders: (json['topSpenders'] as List?)
              ?.map((item) => TopSpender.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class VipDistribution {
  final VipLevel level;
  final int count;

  VipDistribution({
    required this.level,
    required this.count,
  });

  factory VipDistribution.fromJson(Map<String, dynamic> json) {
    return VipDistribution(
      level: VipLevel.fromString(json['level'] ?? '普通'),
      count: json['count'] ?? 0,
    );
  }
}

class TypeDistribution {
  final CustomerType type;
  final int count;

  TypeDistribution({
    required this.type,
    required this.count,
  });

  factory TypeDistribution.fromJson(Map<String, dynamic> json) {
    return TypeDistribution(
      type: CustomerType.fromString(json['type'] ?? '个人'),
      count: json['count'] ?? 0,
    );
  }
}

class TopSpender {
  final int id;
  final String name;
  final String phone;
  final double totalSpent;
  final int visitCount;
  final VipLevel vipLevel;

  TopSpender({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalSpent,
    required this.visitCount,
    required this.vipLevel,
  });

  factory TopSpender.fromJson(Map<String, dynamic> json) {
    return TopSpender(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      totalSpent: (json['totalSpent'] ?? 0).toDouble(),
      visitCount: json['visitCount'] ?? 0,
      vipLevel: VipLevel.fromString(json['vipLevel'] ?? '普通'),
    );
  }
}
