/// AddressModel matching the `address` table (NOT `addresses`) used by
/// addaddress.php / getaddresses.php / updateaddress.php / deleteaddress.php.
///
/// Columns: id, user_id, full_name, phone, email, address, city, area,
/// address_notes, address_type, created_at, updated_at.
class AddressModel {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String area;
  final String addressNotes;
  final String addressType;
  final String createdAt;
  final String updatedAt;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.area,
    required this.addressNotes,
    required this.addressType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      addressNotes: json['address_notes']?.toString() ?? '',
      addressType: json['address_type']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'area': area,
      'address_notes': addressNotes,
      'address_type': addressType,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// One-line summary used in Checkout / order summaries.
  String get oneLineSummary {
    final parts = [address, area, city].where((s) => s.trim().isNotEmpty);
    return parts.join(', ');
  }
}
