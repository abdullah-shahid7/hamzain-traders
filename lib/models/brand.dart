class Brand {
  final String id;
  final String brandName;
  final String brandImage;
  final String brandDescription;
  final String status;

  Brand({
    required this.id,
    required this.brandName,
    required this.brandImage,
    required this.brandDescription,
    required this.status,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'].toString(),
      brandName: json['brand_name'].toString(),
      brandImage: json['brand_image'].toString(),
      brandDescription: json['brand_description'].toString(),
      status: json['status'].toString(),
    );
  }
}
