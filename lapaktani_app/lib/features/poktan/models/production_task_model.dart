class ProductionTaskModel {
  final String taskId;
  final String b2bOrderId;
  final String farmerId;
  final double allocatedKg;
  final String? plantingDeadline;
  final String? harvestDeadline;
  final String taskStatus;
  final String buyerName;
  final String? contractDeadline;
  final String commodityId;
  final String commodityName;
  final String poktanName;
  final DateTime? createdAt;

  const ProductionTaskModel({
    required this.taskId,
    required this.b2bOrderId,
    required this.farmerId,
    required this.allocatedKg,
    this.plantingDeadline,
    this.harvestDeadline,
    required this.taskStatus,
    required this.buyerName,
    this.contractDeadline,
    required this.commodityId,
    required this.commodityName,
    required this.poktanName,
    this.createdAt,
  });

  factory ProductionTaskModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString());
    }

    return ProductionTaskModel(
      taskId: (json['task_id'] ?? json['id'] ?? '').toString(),
      b2bOrderId: (json['b2b_order_id'] ?? '').toString(),
      farmerId: (json['farmer_id'] ?? '').toString(),
      allocatedKg: double.tryParse((json['allocated_kg'] ?? '0').toString()) ?? 0.0,
      plantingDeadline: json['planting_deadline']?.toString(),
      harvestDeadline: json['harvest_deadline']?.toString(),
      taskStatus: (json['task_status'] ?? json['status'] ?? 'pending').toString(),
      buyerName: (json['buyer_name'] ?? 'Mitra B2B').toString(),
      contractDeadline: json['contract_deadline']?.toString(),
      commodityId: (json['commodity_id'] ?? '').toString(),
      commodityName: (json['commodity_name'] ?? 'Komoditas').toString(),
      poktanName: (json['poktan_name'] ?? 'Kelompok Tani').toString(),
      createdAt: parsedDate,
    );
  }
}

class PoktanNotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;

  const PoktanNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.createdAt,
  });

  factory PoktanNotificationModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString());
    }

    return PoktanNotificationModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      type: (json['type'] ?? 'quota_task').toString(),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: parsedDate,
    );
  }
}

