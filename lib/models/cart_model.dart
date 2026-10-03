/// Cart models matching the `cart` + `cart_items` tables (joined with
/// `products` / `product_images` server-side) as returned by
/// getcart.php. Parsing is defensive about exact key names since the
/// join shape isn't guaranteed (e.g. unit price may come back as
/// `price` or `unit_price`), mirroring the defensive parsing already
/// used by [Product] / [ProductImage].
class CartItemModel {
  /// `cart_items.id` — required by updatecartquantity.php /
  /// removecartitem.php to identify the row being changed.
  final int id;
  final int cartId;
  final int productId;
  final int quantity;

  // Joined product snapshot (for display only — never sent back to
  // the server as the source of truth for price).
  final String productName;
  final String productImage;
  final double unitPrice;
  final int stock;

  CartItemModel({
    required this.id,
    required this.cartId,
    required this.productId,
    required this.quantity,
    required this.productName,
    required this.productImage,
    required this.unitPrice,
    required this.stock,
  });

  double get itemTotal => unitPrice * quantity;

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString().trim()) ?? 0;
  }

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString().trim()) ?? 0.0;
  }

  static String _asString(dynamic v) => v == null ? '' : v.toString().trim();

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // cart_items.id may be returned as `id` or `cart_item_id`
    // depending on how the join aliases it.
    final id = json['cart_item_id'] ?? json['id'];
    final unitPrice = json['unit_price'] ?? json['price'] ?? json['product_price'];
    final image = json['product_image'] ?? json['image_url'];
    final name = json['product_name'] ?? json['name'];
    final stock = json['stock'] ?? json['available_stock'];

    return CartItemModel(
      id: _asInt(id),
      cartId: _asInt(json['cart_id']),
      productId: _asInt(json['product_id']),
      quantity: _asInt(json['quantity']),
      productName: _asString(name),
      productImage: _asString(image),
      unitPrice: _asDouble(unitPrice),
      stock: _asInt(stock),
    );
  }

  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      id: id,
      cartId: cartId,
      productId: productId,
      quantity: quantity ?? this.quantity,
      productName: productName,
      productImage: productImage,
      unitPrice: unitPrice,
      stock: stock,
    );
  }
}

/// Whole-cart snapshot returned by getcart.php: the cart id (if any),
/// its items, and derived totals used across Cart / Checkout.
class CartData {
  final int? cartId;
  final List<CartItemModel> items;

  const CartData({required this.cartId, required this.items});

  static const empty = CartData(cartId: null, items: []);

  int get totalQuantity =>
      items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + item.itemTotal);

  bool get isEmpty => items.isEmpty;
}
