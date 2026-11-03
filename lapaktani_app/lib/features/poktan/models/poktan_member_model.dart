class PoktanMemberModel {
  final String farmerId;
  final String fullName;
  final String email;
  final String phone;
  final String nikNumber;
  final double landAreaHa;
  final String soilType;
  final bool isChairman;

  const PoktanMemberModel({
    required this.farmerId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.nikNumber,
    required this.landAreaHa,
    required this.soilType,
    required this.isChairman,
  });

  factory PoktanMemberModel.fromJson(Map<String, dynamic> json) {
    return PoktanMemberModel(
      farmerId: (json['farmer_id'] ?? json['id'] ?? '').toString(),
      fullName: (json['full_name'] ?? json['name'] ?? 'Petani Anggota').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '-').toString(),
      nikNumber: (json['nik_number'] ?? json['nik'] ?? '-').toString(),
      landAreaHa: double.tryParse((json['land_area_ha'] ?? json['land_area'] ?? '0').toString()) ?? 0.0,
      soilType: (json['soil_type'] ?? 'Subur').toString(),
      isChairman: json['is_chairman'] == 1 || json['is_chairman'] == true,
    );
  }
}

