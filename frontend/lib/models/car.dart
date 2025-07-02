class Car {
  final int? id;
  final String plateNumber;
  final String vin;
  final String? brand;
  final String? model;
  final int? year;
  final String? color;
  final int? customerId; // 关联的客户ID
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Repair>? repairs;
  final List<WashLog>? washLogs;
  final int? repairCount;
  final int? washCount;

  Car({
    this.id,
    required this.plateNumber,
    required this.vin,
    this.brand,
    this.model,
    this.year,
    this.color,
    this.customerId,
    this.createdAt,
    this.updatedAt,
    this.repairs,
    this.washLogs,
    this.repairCount,
    this.washCount,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      plateNumber: json['plate_number'] ?? '',
      vin: json['vin'] ?? '',
      brand: json['brand'],
      model: json['model'],
      year: json['year'] != null ? int.tryParse(json['year'].toString()) : null,
      color: json['color'],
      customerId: json['customer_id'] != null
          ? int.tryParse(json['customer_id'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      repairs: json['repairs'] != null
          ? (json['repairs'] as List).map((e) => Repair.fromJson(e)).toList()
          : null,
      washLogs: json['washLogs'] != null
          ? (json['washLogs'] as List).map((e) => WashLog.fromJson(e)).toList()
          : null,
      repairCount: json['repairCount'] != null
          ? int.tryParse(json['repairCount'].toString())
          : null,
      washCount: json['washCount'] != null
          ? int.tryParse(json['washCount'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plate_number': plateNumber,
      'vin': vin,
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'customer_id': customerId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Car copyWith({
    int? id,
    String? plateNumber,
    String? vin,
    String? brand,
    String? model,
    int? year,
    String? color,
    int? customerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Repair>? repairs,
    List<WashLog>? washLogs,
    int? repairCount,
    int? washCount,
  }) {
    return Car(
      id: id ?? this.id,
      plateNumber: plateNumber ?? this.plateNumber,
      vin: vin ?? this.vin,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      customerId: customerId ?? this.customerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      repairs: repairs ?? this.repairs,
      washLogs: washLogs ?? this.washLogs,
      repairCount: repairCount ?? this.repairCount,
      washCount: washCount ?? this.washCount,
    );
  }

  @override
  String toString() {
    return 'Car(id: $id, plateNumber: $plateNumber, vin: $vin, brand: $brand, model: $model)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Car && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Repair {
  final int? id;
  final int carId;
  final int? customerId;
  final DateTime repairDate;
  final String item;
  final double price;
  final String? note;
  final String? mechanic;
  final String? garageName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Car? car;

  Repair({
    this.id,
    required this.carId,
    this.customerId,
    required this.repairDate,
    required this.item,
    required this.price,
    this.note,
    this.mechanic,
    this.garageName,
    this.createdAt,
    this.updatedAt,
    this.car,
  });

  factory Repair.fromJson(Map<String, dynamic> json) {
    return Repair(
      id: json['id'],
      carId: json['car_id'],
      customerId: json['customer_id'],
      repairDate: DateTime.parse(json['repair_date']),
      item: json['item'] ?? '',
      price: double.parse(json['price'].toString()),
      note: json['note'],
      mechanic: json['mechanic'],
      garageName: json['garage_name'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      car: json['car'] != null ? Car.fromJson(json['car']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'car_id': carId,
      if (customerId != null) 'customer_id': customerId,
      'repair_date': repairDate.toIso8601String().split('T')[0],
      'item': item,
      'price': price,
      'note': note,
      'mechanic': mechanic,
      'garage_name': garageName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Repair copyWith({
    int? id,
    int? carId,
    int? customerId,
    DateTime? repairDate,
    String? item,
    double? price,
    String? note,
    String? mechanic,
    String? garageName,
    DateTime? createdAt,
    DateTime? updatedAt,
    Car? car,
  }) {
    return Repair(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      customerId: customerId ?? this.customerId,
      repairDate: repairDate ?? this.repairDate,
      item: item ?? this.item,
      price: price ?? this.price,
      note: note ?? this.note,
      mechanic: mechanic ?? this.mechanic,
      garageName: garageName ?? this.garageName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      car: car ?? this.car,
    );
  }

  @override
  String toString() {
    return 'Repair(id: $id, carId: $carId, repairDate: $repairDate, item: $item, price: $price)';
  }
}

class WashLog {
  final int? id;
  final int carId;
  final int? customerId;
  final DateTime washTime;
  final String washType;
  final double price;
  final String? location;
  final String? note;
  final DateTime? createdAt;
  final Car? car;

  WashLog({
    this.id,
    required this.carId,
    this.customerId,
    required this.washTime,
    required this.washType,
    required this.price,
    this.location,
    this.note,
    this.createdAt,
    this.car,
  });

  factory WashLog.fromJson(Map<String, dynamic> json) {
    return WashLog(
      id: json['id'],
      carId: json['car_id'],
      customerId: json['customer_id'],
      washTime: DateTime.parse(json['wash_time']),
      washType: json['wash_type'] ?? 'manual',
      price: double.parse(json['price'].toString()),
      location: json['location'],
      note: json['note'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      car: json['car'] != null ? Car.fromJson(json['car']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'car_id': carId,
      if (customerId != null) 'customer_id': customerId,
      'wash_time': washTime.toIso8601String(),
      'wash_type': washType,
      'price': price,
      'location': location,
      'note': note,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  WashLog copyWith({
    int? id,
    int? carId,
    int? customerId,
    DateTime? washTime,
    String? washType,
    double? price,
    String? location,
    String? note,
    DateTime? createdAt,
    Car? car,
  }) {
    return WashLog(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      customerId: customerId ?? this.customerId,
      washTime: washTime ?? this.washTime,
      washType: washType ?? this.washType,
      price: price ?? this.price,
      location: location ?? this.location,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      car: car ?? this.car,
    );
  }

  String get washTypeDisplay {
    switch (washType) {
      case 'self':
        return '自助洗车';
      case 'auto':
        return '自动洗车';
      case 'manual':
        return '人工洗车';
      default:
        return '未知';
    }
  }

  @override
  String toString() {
    return 'WashLog(id: $id, carId: $carId, washTime: $washTime, washType: $washType, price: $price)';
  }
}
