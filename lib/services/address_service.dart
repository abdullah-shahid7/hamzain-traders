import 'package:hamzain_traders/models/address_model.dart';
import 'package:hamzain_traders/services/api_constants.dart';
import 'package:hamzain_traders/services/api_http_helper.dart';

export 'package:hamzain_traders/services/api_http_helper.dart' show AppApiException;

/// Talks to the NEW `address` table backend (addaddress.php /
/// getaddresses.php / updateaddress.php / deleteaddress.php). Every
/// method uses the real logged-in user's id — callers must never pass
/// a hardcoded id.
class AddressService {
  /// Fetches every address belonging to [userId].
  ///
  /// Sent so that `user_id` is available regardless of whether
  /// getaddresses.php reads `$_GET` (like getcart.php /
  /// getorderhistory.php, confirmed from source) or a JSON body
  /// (like addtocart.php, also confirmed from source) — its own
  /// source hasn't been seen, so this covers both known conventions
  /// in one request rather than guessing which one it uses. Results
  /// are also filtered client-side by `user_id` afterward as a
  /// safety net in case the endpoint ignores the filter and returns
  /// every row.
  Future<List<AddressModel>> getAddresses({required String userId}) async {
    final decoded = await ApiHttp.getWithJsonFallback(
      ApiConstants.getAddresses,
      query: {'user_id': userId},
    );
    final list = ApiHttp.extractList(decoded);
    return list
        .whereType<Map<String, dynamic>>()
        .map(AddressModel.fromJson)
        .where((a) => a.userId == userId)
        .toList();
  }

  /// Adds a new address for [userId] via addaddress.php.
  Future<bool> addAddress({
    required String userId,
    required String fullName,
    required String phone,
    required String email,
    required String address,
    required String city,
    required String area,
    required String addressNotes,
    required String addressType,
  }) async {
    await ApiHttp.post(
      ApiConstants.addAddress,
      alsoAsQuery: true,
      body: {
        'user_id': userId,
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
        'area': area,
        'address_notes': addressNotes,
        'address_type': addressType,
      },
    );
    return true;
  }

  /// Updates an existing address via updateaddress.php.
  Future<bool> updateAddress({
    required String id,
    required String userId,
    required String fullName,
    required String phone,
    required String email,
    required String address,
    required String city,
    required String area,
    required String addressNotes,
    required String addressType,
  }) async {
    await ApiHttp.post(
      ApiConstants.updateAddress,
      alsoAsQuery: true,
      body: {
        'id': id,
        'user_id': userId,
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
        'area': area,
        'address_notes': addressNotes,
        'address_type': addressType,
      },
    );
    return true;
  }

  /// Deletes an address via deleteaddress.php.
  Future<bool> deleteAddress({required String id, required String userId}) async {
    await ApiHttp.post(
      ApiConstants.deleteAddress,
      alsoAsQuery: true,
      body: {'id': id, 'user_id': userId},
    );
    return true;
  }
}
