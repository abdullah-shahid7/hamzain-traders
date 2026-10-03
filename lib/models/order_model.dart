/// OrderModel matching the `orders` table returned by getmyorders.php /
/// getorderhistory.php / getorderdetails.php / getorderreceipt.php.
///
/// Columns: id, order_number, user_id, customer_name, phone, email,
/// address, city, area, address_notes, subtotal, delivery_charges,
/// total_amount, status, estimated_delivery_date, created_at.
class OrderModel {
  final String id;
  final String orderNumber;
  final String userId;
  final String customerName;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String area;
  final String addressNotes;
  final double subtotal;
  final double deliveryCharges;
  final double totalAmount;
  final String status;
  final String estimatedDeliveryDate;
  final String createdAt;

  /// Populated by getorderdetails.php / getorderreceipt.php, and
  /// also by getorderhistory.php (confirmed from its PHP source — it
  /// fetches each order's order_items too). getmyorders.php's exact
  /// shape isn't confirmed, so this defaults to empty if absent.
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.customerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.area,
    required this.addressNotes,
    required this.subtotal,
    required this.deliveryCharges,
    required this.totalAmount,
    required this.status,
    required this.estimatedDeliveryDate,
    required this.createdAt,
    this.items = const [],
  });

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString().trim()) ?? 0.0;
  }

  static String _asString(dynamic v) => v == null ? '' : v.toString().trim();

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['order_items'];
    return OrderModel(
      id: _asString(json['id']),
      orderNumber: _asString(json['order_number']),
      userId: _asString(json['user_id']),
      customerName: _asString(json['customer_name']),
      phone: _asString(json['phone']),
      email: _asString(json['email']),
      address: _asString(json['address']),
      city: _asString(json['city']),
      area: _asString(json['area']),
      addressNotes: _asString(json['address_notes']),
      subtotal: _asDouble(json['subtotal']),
      deliveryCharges: _asDouble(json['delivery_charges']),
      totalAmount: _asDouble(json['total_amount']),
      status: _asString(json['status']),
      estimatedDeliveryDate: _asString(json['estimated_delivery_date']),
      createdAt: _asString(json['created_at']),
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(OrderItemModel.fromJson)
              .toList()
          : const [],
    );
  }

  OrderModel copyWithItems(List<OrderItemModel> newItems) {
    return OrderModel(
      id: id,
      orderNumber: orderNumber,
      userId: userId,
      customerName: customerName,
      phone: phone,
      email: email,
      address: address,
      city: city,
      area: area,
      addressNotes: addressNotes,
      subtotal: subtotal,
      deliveryCharges: deliveryCharges,
      totalAmount: totalAmount,
      status: status,
      estimatedDeliveryDate: estimatedDeliveryDate,
      createdAt: createdAt,
      items: newItems,
    );
  }
}

/// OrderItemModel matching the `order_items` table — a frozen
/// snapshot of the product at the time of purchase. Historical order
/// views must always use these fields, never the live `products` row.
class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String productImage;
  final double unitPrice;
  final int quantity;
  final double itemTotal;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.unitPrice,
    required this.quantity,
    required this.itemTotal,
  });

  static double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString().trim()) ?? 0.0;
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString().trim()) ?? 0;
  }

  static String _asString(dynamic v) => v == null ? '' : v.toString().trim();

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: _asString(json['id']),
      orderId: _asString(json['order_id']),
      productId: _asString(json['product_id']),
      productName: _asString(json['product_name']),
      productImage: _asString(json['product_image']),
      unitPrice: _asDouble(json['unit_price']),
      quantity: _asInt(json['quantity']),
      itemTotal: _asDouble(json['item_total']),
    );
  }
}
