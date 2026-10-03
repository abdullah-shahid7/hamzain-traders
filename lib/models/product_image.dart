/// ProductImage model matching the `product_images` table returned by
/// `getproductimages.php`. Values are parsed defensively since
/// PHP/MySQL may return numeric fields as int, double, or String.
class ProductImage {
  final int id;
  final int productId;
  final String imageUrl;
  final int sortOrder;
  final String createdAt;

  ProductImage({
    required this.id,
    required this.productId,
    required this.imageUrl,
    required this.sortOrder,
    required this.createdAt,
  });

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString().trim()) ?? 0;
  }

  static String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: _asInt(json['id']),
      productId: _asInt(json['product_id']),
      imageUrl: _asString(json['image_url']),
      sortOrder: _asInt(json['sort_order']),
      createdAt: _asString(json['created_at']),
    );
  }
}
