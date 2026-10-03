/// Product model matching the `products` table returned by
/// `getproducts.php`. PHP/MySQL may return numeric columns as
/// int, double, or String depending on driver/config, so every
/// field is parsed defensively.
class Product {
  final int id;
  final int brandId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int stock;
  final String status;
  final String createdAt;

  Product({
    required this.id,
    required this.brandId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.stock,
    required this.status,
    required this.createdAt,
  });

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString().trim()) ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString().trim()) ?? 0.0;
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: _asInt(json['id']),
      brandId: _asInt(json['brand_id']),
      name: _asString(json['name']),
      description: _asString(json['description']),
      price: _asDouble(json['price']),
      imageUrl: _asString(json['image_url']),
      stock: _asInt(json['stock']),
      status: _asString(json['status']),
      createdAt: _asString(json['created_at']),
    );
  }
}
