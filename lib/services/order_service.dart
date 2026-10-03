import 'package:hamzain_traders/models/address_model.dart';
import 'package:hamzain_traders/models/cart_model.dart';
import 'package:hamzain_traders/models/order_model.dart';
import 'package:hamzain_traders/services/api_constants.dart';
import 'package:hamzain_traders/services/api_http_helper.dart';

export 'package:hamzain_traders/services/api_http_helper.dart' show AppApiException;

/// Result returned after a successful placeorder.php call.
class PlaceOrderResult {
  final String orderId;
  final String orderNumber;
  final double totalAmount;

  const PlaceOrderResult({
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
  });
}

/// Talks to the order backend (placeorder.php / getmyorders.php /
/// getorderhistory.php / getorderdetails.php / getorderreceipt.php).
/// Every method uses the real logged-in user's id and real cart /
/// address data — nothing here is ever hardcoded or simulated
/// locally.
class OrderService {
  /// Places an order for [userId] using the real selected [address]
  /// and real cart [items]. The backend (placeorder.php) is
  /// responsible for creating the `orders` + `order_items` rows and
  /// for clearing the cart as part of that transaction.
  Future<PlaceOrderResult> placeOrder({
    required String userId,
    required AddressModel address,
    required List<CartItemModel> items,
    required double subtotal,
    required double deliveryCharges,
    required double totalAmount,
    int? cartId,
    String paymentMethod = 'Cash on Delivery',
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'customer_name': address.fullName,
      'phone': address.phone,
      'email': address.email,
      'address': address.address,
      'city': address.city,
      'area': address.area,
      'address_notes': address.addressNotes,
      'subtotal': subtotal.toStringAsFixed(2),
      'delivery_charges': deliveryCharges.toStringAsFixed(2),
      'total_amount': totalAmount.toStringAsFixed(2),
      'payment_method': paymentMethod,
      if (cartId != null) 'cart_id': cartId.toString(),
      // Sent as a real JSON array of objects (not flattened
      // `items[0][...]` keys) since placeorder.php reads a JSON body.
      'items': items
          .map((item) => {
                'product_id': item.productId,
                'quantity': item.quantity,
                'unit_price': item.unitPrice,
              })
          .toList(),
    };

    final decoded = await ApiHttp.post(ApiConstants.placeOrder, body: body);
    final data = ApiHttp.extractMap(decoded) ?? decoded;

    final orderId = (data['order_id'] ?? data['id'])?.toString();
    final orderNumber = (data['order_number'])?.toString();

    if (orderId == null && orderNumber == null) {
      throw AppApiException(
        'The order could not be confirmed. Please try again.',
      );
    }

    final returnedTotal = data['total_amount'];
    return PlaceOrderResult(
      orderId: orderId ?? '',
      orderNumber: orderNumber ?? '',
      totalAmount: returnedTotal != null
          ? (double.tryParse(returnedTotal.toString()) ?? totalAmount)
          : totalAmount,
    );
  }

  /// Loads the current user's active/ongoing orders.
  Future<List<OrderModel>> getMyOrders({required String userId}) async {
    final decoded = await ApiHttp.get(
      ApiConstants.getMyOrders,
      query: {'user_id': userId},
    );
    final list = ApiHttp.extractList(decoded);
    return list
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .where((o) => o.userId.isEmpty || o.userId == userId)
        .toList();
  }

  /// Loads the current user's historical/past orders.
  Future<List<OrderModel>> getOrderHistory({required String userId}) async {
    final decoded = await ApiHttp.get(
      ApiConstants.getOrderHistory,
      query: {'user_id': userId},
    );
    final list = ApiHttp.extractList(decoded);
    return list
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .where((o) => o.userId.isEmpty || o.userId == userId)
        .toList();
  }

  /// Loads full order details (including order_items) for a single
  /// real order id, scoped to [userId] — confirmed from
  /// getorderdetails.php's source: it requires BOTH `order_id` and
  /// `user_id` (`WHERE id = ? AND user_id = ?`), rejecting the
  /// request entirely if either is missing. The previous version
  /// only sent `order_id`, which is exactly why every Order
  /// Details/Receipt load failed.
  Future<OrderModel> getOrderDetails({
    required String orderId,
    required String userId,
  }) async {
    final decoded = await ApiHttp.get(
      ApiConstants.getOrderDetails,
      query: {'order_id': orderId, 'user_id': userId},
    );
    final map = ApiHttp.extractMap(decoded);
    if (map == null) {
      throw AppApiException('Order details could not be found.');
    }
    var order = OrderModel.fromJson(map);
    if (order.items.isEmpty) {
      // Some backends return order_items as a sibling list instead of
      // nested inside the order object.
      final itemsList = decoded['order_items'] ?? decoded['items'];
      if (itemsList is List) {
        order = order.copyWithItems(
          itemsList
              .whereType<Map<String, dynamic>>()
              .map(OrderItemModel.fromJson)
              .toList(),
        );
      }
    }
    return order;
  }

  /// Loads the receipt for a single real order id, scoped to
  /// [userId] — getorderreceipt.php requires both, same as
  /// getorderdetails.php (confirmed from source).
  Future<OrderModel> getOrderReceipt({
    required String orderId,
    required String userId,
  }) async {
    final decoded = await ApiHttp.get(
      ApiConstants.getOrderReceipt,
      query: {'order_id': orderId, 'user_id': userId},
    );
    final map = ApiHttp.extractMap(decoded);
    if (map == null) {
      throw AppApiException('Receipt could not be found.');
    }
    var order = OrderModel.fromJson(map);
    if (order.items.isEmpty) {
      final itemsList = decoded['order_items'] ?? decoded['items'];
      if (itemsList is List) {
        order = order.copyWithItems(
          itemsList
              .whereType<Map<String, dynamic>>()
              .map(OrderItemModel.fromJson)
              .toList(),
        );
      }
    }
    return order;
  }
}
