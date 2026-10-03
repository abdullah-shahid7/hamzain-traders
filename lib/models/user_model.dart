class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  // Kept only so the model matches the exact `users` table structure
  // (id, full_name, email, phone_number, password, created_at, status).
  // This is intentionally never read or displayed anywhere in the UI.
  final String password;
  final String createdAt;
  final String status;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    required this.createdAt,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // The login API's user id has been observed under a couple of
    // different possible key names depending on how the backend
    // serializes the `users` row — fall back through the common
    // variants so a real, non-empty id is captured regardless.
    final rawId = json['id'] ??
        json['user_id'] ??
        json['userId'] ??
        json['ID'] ??
        json['Id'];

    return UserModel(
      id: rawId?.toString().trim() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'password': password,
      'created_at': createdAt,
      'status': status,
    };
  }
}
