class B2BOrderModel {
  final String id;
  final String farmerGroupId;
  final String commodityId;
  final String commodityName;
  final double totalQuotaKg;
  final double totalAllocatedKg;
  final double remainingQuotaKg;
  final String buyerName;
  final String deadline;
  final String status;
  final DateTime? createdAt;

  const B2BOrderModel({
    required this.id,
    required this.farmerGroupId,
    required this.commodityId,
    required this.commodityName,
    required this.totalQuotaKg,
    required this.totalAllocatedKg,
    required this.remainingQuotaKg,
    required this.buyerName,
    required this.deadline,
    required this.status,
    this.createdAt,
  });

  factory B2BOrderModel.fromJson(Map<String, dynamic> json) {
    final double totalQuota = double.tryParse((json['total_quota_kg'] ?? '0').toString()) ?? 0.0;
    final double allocated = double.tryParse((json['total_allocated_kg'] ?? '0').toString()) ?? 0.0;
    final double remaining = double.tryParse((json['remaining_quota_kg'] ?? (totalQuota - allocated).toString()).toString()) ?? (totalQuota - allocated);

    DateTime? parsedDate;
    if (json['created_at'] != null) {
      parsedDate = DateTime.tryParse(json['created_at'].toString());
    }

    return B2BOrderModel(
      id: (json['id'] ?? '').toString(),
      farmerGroupId: (json['farmer_group_id'] ?? '').toString(),
      commodityId: (json['commodity_id'] ?? '').toString(),
      commodityName: (json['commodity_name'] ?? 'Komoditas').toString(),
      totalQuotaKg: totalQuota,
      totalAllocatedKg: allocated,
      remainingQuotaKg: remaining < 0 ? 0.0 : remaining,
      buyerName: (json['buyer_name'] ?? 'Mitra B2B').toString(),
      deadline: (json['deadline'] ?? '-').toString(),
      status: (json['status'] ?? 'draft').toString(),
      createdAt: parsedDate,
    );
  }
}

