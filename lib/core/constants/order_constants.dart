/// Order-related constants shared by Cart, Checkout, and order
/// placement so the delivery charge shown to the user always matches
/// what's actually sent to placeorder.php.
///
/// NOTE: placeorder.php owns the source of truth for delivery
/// charges/final totals in the database (`orders.delivery_charges`).
/// This flat rate is only used client-side to show an estimated
/// total before the order is placed. If the backend calculates
/// delivery charges differently (e.g. by city or order value), update
/// this single constant to match rather than introducing a second,
/// divergent delivery system.
class OrderConstants {
  OrderConstants._();

  static const double flatDeliveryCharge = 250.0;
}
