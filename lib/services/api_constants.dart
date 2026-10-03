/// All PHP API endpoints for the HamZainTraders backend. Every URL
/// here is exact and must not be renamed or duplicated — see the
/// integration spec for the full list of required endpoints.
class ApiConstants {
  static const String _base =
      "https://devtechnical.com/Abdullah.Shahid/HamZainTraders";

  // ---- Products (existing, already working — do not replace) ----
  static const String getProducts = "$_base/getproducts.php";
  static const String getProductImages = "$_base/getproductimages.php";

  // ---- Address ----
  static const String addAddress = "$_base/addaddress.php";
  static const String getAddresses = "$_base/getaddresses.php";
  static const String updateAddress = "$_base/updateaddress.php";
  static const String deleteAddress = "$_base/deleteaddress.php";

  // ---- Cart ----
  static const String addToCart = "$_base/addtocart.php";
  static const String getCart = "$_base/getcart.php";
  static const String updateCartQuantity = "$_base/updatecartquantity.php";
  static const String removeCartItem = "$_base/removecartitem.php";
  static const String clearCart = "$_base/clearcart.php";

  // ---- Orders ----
  static const String placeOrder = "$_base/placeorder.php";
  static const String getMyOrders = "$_base/getmyorders.php";
  static const String getOrderHistory = "$_base/getorderhistory.php";
  static const String getOrderDetails = "$_base/getorderdetails.php";
  static const String getOrderReceipt = "$_base/getorderreceipt.php";
}
