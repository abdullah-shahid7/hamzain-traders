import 'package:hamzain_traders/models/cart_model.dart';
import 'package:hamzain_traders/services/api_constants.dart';
import 'package:hamzain_traders/services/api_http_helper.dart';

export 'package:hamzain_traders/services/api_http_helper.dart' show AppApiException;

/// Talks to the cart backend (addtocart.php / getcart.php /
/// updatecartquantity.php / removecartitem.php / clearcart.php).
/// Every method requires the real logged-in user's id — this service
/// never assumes or hardcodes `user_id = 1`.
class CartService {
  /// Adds [quantity] of [productId] to [userId]'s cart.
  ///
  /// If the product is already in the user's cart, this increases the
  /// existing row's quantity via updatecartquantity.php instead of
  /// calling addtocart.php again — inserting a second row for a
  /// product that's already in the cart is exactly the kind of thing
  /// a unique-constraint / duplicate-item check on the backend would
  /// reject, so checking first avoids that class of failure entirely
  /// and matches how a cart is supposed to behave anyway (adding an
  /// already-cart product again should raise its quantity, not fail).
  Future<bool> addToCart({
    required String userId,
    required int productId,
    required int quantity,
  }) async {
    CartData? existingCart;
    try {
      existingCart = await getCart(userId: userId);
    } catch (_) {
      // If the cart can't be read for some reason, fall through to a
      // plain add — addtocart.php is still the source of truth.
      existingCart = null;
    }

    CartItemModel? existingItem;
    if (existingCart != null) {
      for (final item in existingCart.items) {
        if (item.productId == productId) {
          existingItem = item;
          break;
        }
      }
    }

    if (existingItem != null) {
      var newQuantity = existingItem.quantity + quantity;
      if (existingItem.stock > 0 && newQuantity > existingItem.stock) {
        newQuantity = existingItem.stock;
      }
      await updateCartQuantity(
        cartItemId: existingItem.id,
        userId: userId,
        quantity: newQuantity,
      );
      return true;
    }

    // Confirmed from addtocart.php's source: it reads exactly
    // user_id, product_id, quantity as JSON keys from the raw POST
    // body — no other variants needed.
    await ApiHttp.post(
      ApiConstants.addToCart,
      body: {
        'user_id': userId,
        'product_id': productId,
        'quantity': quantity,
      },
    );
    return true;
  }

  /// Loads the current cart (and its items, joined with product
  /// info) for [userId].
  Future<CartData> getCart({required String userId}) async {
    final decoded = await ApiHttp.get(
      ApiConstants.getCart,
      query: {'user_id': userId},
    );

    final list = ApiHttp.extractList(decoded);
    final items = list
        .whereType<Map<String, dynamic>>()
        .map(CartItemModel.fromJson)
        .toList();

    // cart_id may be present at the envelope's top level (e.g.
    // `{ "cart_id": 12, "data": [...] }`) or on each item row.
    int? cartId;
    final topLevelCartId = decoded['cart_id'];
    if (topLevelCartId != null) {
      cartId = int.tryParse(topLevelCartId.toString());
    } else if (items.isNotEmpty) {
      cartId = items.first.cartId;
    }

    return CartData(cartId: cartId, items: items);
  }

  /// Updates the quantity of a single cart item via
  /// updatecartquantity.php.
  Future<bool> updateCartQuantity({
    required int cartItemId,
    required String userId,
    required int quantity,
  }) async {
    await ApiHttp.post(
      ApiConstants.updateCartQuantity,
      body: {
        'cart_item_id': cartItemId,
        'user_id': userId,
        'quantity': quantity,
      },
    );
    return true;
  }

  /// Removes a single cart item via removecartitem.php.
  Future<bool> removeCartItem({
    required int cartItemId,
    required String userId,
  }) async {
    await ApiHttp.post(
      ApiConstants.removeCartItem,
      body: {
        'cart_item_id': cartItemId,
        'user_id': userId,
      },
    );
    return true;
  }

  /// Clears the entire cart for [userId] via clearcart.php.
  Future<bool> clearCart({required String userId}) async {
    await ApiHttp.post(
      ApiConstants.clearCart,
      body: {'user_id': userId},
    );
    return true;
  }
}
