import 'dart:convert';

enum OrderStatus {
  pendingPayment,
  needHarvest,
  readyToShip,
  inTransit,
  delivered,
  completed,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get key {
    switch (this) {
      case OrderStatus.pendingPayment:
        return 'pending_payment';
      case OrderStatus.needHarvest:
        return 'need_harvest';
      case OrderStatus.readyToShip:
        return 'ready_to_ship';
      case OrderStatus.inTransit:
        return 'in_transit';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pendingPayment:
        return 'Menunggu Bayar';
      case OrderStatus.needHarvest:
        return 'Perlu Dipetik';
      case OrderStatus.readyToShip:
        return 'Siap Dikirim';
      case OrderStatus.inTransit:
        return 'Dalam Pengiriman';
      case OrderStatus.delivered:
        return 'Tiba di Tujuan';
      case OrderStatus.completed:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  static OrderStatus fromKey(String key) {
    switch (key) {
      case 'pending_payment':
        return OrderStatus.pendingPayment;
      case 'need_harvest':
      case 'processing':
        return OrderStatus.needHarvest;
      case 'ready_to_ship':
        return OrderStatus.readyToShip;
      case 'in_transit':
        return OrderStatus.inTransit;
      case 'delivered':
        return OrderStatus.delivered;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.needHarvest;
    }
  }
}

class OrderItem {
  final String id;
  final String? productId;
  final String title;
  final int qty;
  final String unit;
  final int price;
  final String imageUrl;
  final String? grade;

  const OrderItem({
    required this.id,
    this.productId,
    required this.title,
    required this.qty,
    required this.unit,
    required this.price,
    required this.imageUrl,
    this.grade,
  });

  String get effectiveProductId => productId ?? id;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId ?? id,
      'title': title,
      'qty': qty,
      'unit': unit,
      'price': price,
      'imageUrl': imageUrl,
      'grade': grade,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id']?.toString() ?? '',
      productId: map['productId']?.toString() ?? map['id']?.toString(),
      title: map['title']?.toString() ?? '',
      qty: (map['qty'] as num?)?.toInt() ?? 1,
      unit: map['unit']?.toString() ?? 'kg',
      price: (map['price'] as num?)?.toInt() ?? 0,
      imageUrl: map['imageUrl']?.toString() ?? '',
      grade: map['grade']?.toString(),
    );
  }
}

class CourierInfo {
  final String name;
  final String phone;
  final String vehicle;
  final String serviceName;
  final String? photoUrl;

  const CourierInfo({
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.serviceName,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'vehicle': vehicle,
      'serviceName': serviceName,
      'photoUrl': photoUrl,
    };
  }

  factory CourierInfo.fromMap(Map<String, dynamic> map) {
    return CourierInfo(
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      vehicle: map['vehicle']?.toString() ?? '',
      serviceName: map['serviceName']?.toString() ?? 'Kurir LapakTani',
      photoUrl: map['photoUrl']?.toString(),
    );
  }
}

class TrackingCheckpoint {
  final String title;
  final String description;
  final String timestamp;
  final String location;
  final bool isCompleted;
  final bool isCurrent;

  const TrackingCheckpoint({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.location,
    required this.isCompleted,
    this.isCurrent = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'location': location,
      'isCompleted': isCompleted,
      'isCurrent': isCurrent,
    };
  }

  factory TrackingCheckpoint.fromMap(Map<String, dynamic> map) {
    return TrackingCheckpoint(
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      timestamp: map['timestamp']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      isCompleted: map['isCompleted'] == true,
      isCurrent: map['isCurrent'] == true,
    );
  }
}

class OrderModel {
  final String id;
  final String buyerName;
  final String buyerPhone;
  final String buyerAddress;
  final String sellerName;
  final String sellerLocation;
  final DateTime createdAt;
  final OrderStatus status;
  final String paymentMethod;
  final String paymentStatus;
  final List<OrderItem> items;
  final int totalPrice;
  final int shippingFee;
  final String trackingNumber;
  final String estimatedDelivery;
  final String temperature;
  final CourierInfo courier;
  final List<TrackingCheckpoint> checkpoints;

  const OrderModel({
    required this.id,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerAddress,
    required this.sellerName,
    required this.sellerLocation,
    required this.createdAt,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.items,
    required this.totalPrice,
    required this.shippingFee,
    required this.trackingNumber,
    required this.estimatedDelivery,
    required this.temperature,
    required this.courier,
    required this.checkpoints,
  });

  OrderModel copyWith({
    String? id,
    String? buyerName,
    String? buyerPhone,
    String? buyerAddress,
    String? sellerName,
    String? sellerLocation,
    DateTime? createdAt,
    OrderStatus? status,
    String? paymentMethod,
    String? paymentStatus,
    List<OrderItem>? items,
    int? totalPrice,
    int? shippingFee,
    String? trackingNumber,
    String? estimatedDelivery,
    String? temperature,
    CourierInfo? courier,
    List<TrackingCheckpoint>? checkpoints,
  }) {
    return OrderModel(
      id: id ?? this.id,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      buyerAddress: buyerAddress ?? this.buyerAddress,
      sellerName: sellerName ?? this.sellerName,
      sellerLocation: sellerLocation ?? this.sellerLocation,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      shippingFee: shippingFee ?? this.shippingFee,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      temperature: temperature ?? this.temperature,
      courier: courier ?? this.courier,
      checkpoints: checkpoints ?? this.checkpoints,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerAddress': buyerAddress,
      'sellerName': sellerName,
      'sellerLocation': sellerLocation,
      'createdAt': createdAt.toIso8601String(),
      'status': status.key,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'items': items.map((x) => x.toMap()).toList(),
      'totalPrice': totalPrice,
      'shippingFee': shippingFee,
      'trackingNumber': trackingNumber,
      'estimatedDelivery': estimatedDelivery,
      'temperature': temperature,
      'courier': courier.toMap(),
      'checkpoints': checkpoints.map((x) => x.toMap()).toList(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id']?.toString() ?? '',
      buyerName: map['buyerName']?.toString() ?? '',
      buyerPhone: map['buyerPhone']?.toString() ?? '',
      buyerAddress: map['buyerAddress']?.toString() ?? '',
      sellerName: map['sellerName']?.toString() ?? '',
      sellerLocation: map['sellerLocation']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      status: OrderStatusExtension.fromKey(map['status']?.toString() ?? ''),
      paymentMethod: map['paymentMethod']?.toString() ?? 'LapakPay',
      paymentStatus: map['paymentStatus']?.toString() ?? 'Lunas',
      items: (map['items'] as List<dynamic>?)
              ?.map((x) => OrderItem.fromMap(x as Map<String, dynamic>))
              .toList() ??
          [],
      totalPrice: (map['totalPrice'] as num?)?.toInt() ?? 0,
      shippingFee: (map['shippingFee'] as num?)?.toInt() ?? 0,
      trackingNumber: map['trackingNumber']?.toString() ?? '',
      estimatedDelivery: map['estimatedDelivery']?.toString() ?? '',
      temperature: map['temperature']?.toString() ?? '4-8°C',
      courier: CourierInfo.fromMap((map['courier'] as Map<String, dynamic>?) ?? {}),
      checkpoints: (map['checkpoints'] as List<dynamic>?)
              ?.map((x) => TrackingCheckpoint.fromMap(x as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  String toJson() => jsonEncode(toMap());
  factory OrderModel.fromJson(String source) => OrderModel.fromMap(jsonDecode(source));
}
