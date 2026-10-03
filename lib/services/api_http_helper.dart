import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Thin exception type so screens can show a friendly message without
/// caring whether the failure was a timeout, a socket error, bad
/// JSON, or an explicit `success: false` from the API. Shared by
/// every service (address/cart/order) so error handling is
/// consistent across the whole app.
class AppApiException implements Exception {
  final String message;
  AppApiException(this.message);

  @override
  String toString() => message;
}

/// Small shared HTTP helper used by AddressService / CartService /
/// OrderService. Centralizes timeouts, network-error translation,
/// and parsing of the backend's common
/// `{ "success": bool, "message": "...", "data": ... }` envelope so
/// each service only has to describe *which* endpoint/params it
/// needs, not how to talk HTTP.
///
/// This backend uses two different conventions, confirmed directly
/// from the PHP source of `addtocart.php` / `getcart.php` /
/// `getorderhistory.php`:
///  - "get*.php" (read) endpoints read `$_GET[...]` — a plain HTTP
///    GET with the parameters in the URL's query string.
///  - action endpoints (`addtocart.php`, and by the same convention
///    `updatecartquantity.php`, `removecartitem.php`, `clearcart.php`,
///    `placeorder.php`, `addaddress.php`, `updateaddress.php`,
///    `deleteaddress.php`) decode a JSON object from the raw POST
///    body (`php://input`), not `$_POST`.
/// [get] and [post] below implement exactly these two shapes. This
/// does NOT apply to `getproducts.php` / `getproductimages.php` in
/// `api_service.dart`, which are already confirmed working with
/// plain GET and no query params, and are left untouched.
class ApiHttp {
  static const Duration timeout = Duration(seconds: 20);

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    // Some shared-hosting setups run bot/WAF filtering that blocks
    // requests with no recognizable browser-style User-Agent (Dart's
    // default is a bare "Dart/x.x (dart:io)" string). Sending a
    // normal-looking User-Agent is a cheap, harmless precaution.
    'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Mobile) HamZainTradersApp/1.0',
  };

  /// Plain HTTP GET with [query] appended as the URL's query string
  /// — matches `$_GET[...]` reads in getcart.php / getorderhistory.php
  /// and (by the same convention) getmyorders.php / getorderdetails.php
  /// / getorderreceipt.php / getaddresses.php.
  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, dynamic>? query,
  }) async {
    final stringQuery = (query ?? const {}).map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final uri = Uri.parse(url).replace(queryParameters: stringQuery);
    return _send(() => http.get(uri, headers: _headers).timeout(timeout));
  }

  /// POST with [body] JSON-encoded as the raw request body — matches
  /// `json_decode(file_get_contents("php://input"), true)` reads in
  /// addtocart.php, and (by the same convention) the other
  /// add/update/delete/place action endpoints. [body] values may be
  /// plain strings/numbers or nested lists/maps (e.g. an `items`
  /// array for placeorder.php). When [alsoAsQuery] is true, every
  /// scalar (non-list/map) value in [body] is also appended to the
  /// URL's query string, so a script that happens to check `$_GET`
  /// instead of (or in addition to) the JSON body still finds it —
  /// used for endpoints whose exact convention hasn't been confirmed
  /// from source.
  static Future<Map<String, dynamic>> post(
    String url, {
    required Map<String, dynamic> body,
    bool alsoAsQuery = false,
  }) async {
    var uri = Uri.parse(url);
    if (alsoAsQuery) {
      final stringQuery = <String, String>{
        for (final entry in body.entries)
          if (entry.value is! List && entry.value is! Map)
            entry.key: entry.value.toString(),
      };
      uri = uri.replace(queryParameters: stringQuery);
    }
    return _send(
      () => http
          .post(
            uri,
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(timeout),
    );
  }

  /// POST with [query] sent BOTH as the URL's query string (so
  /// `$_GET[...]` sees it, matching getcart.php/getorderhistory.php's
  /// confirmed convention) AND as a JSON body (so a script reading
  /// `php://input`, matching addtocart.php's confirmed convention,
  /// sees it too). Used for endpoints whose exact convention hasn't
  /// been confirmed from source, to maximize the chance the backend
  /// finds the parameter it's looking for without needing to guess
  /// and iterate again.
  static Future<Map<String, dynamic>> getWithJsonFallback(
    String url, {
    Map<String, dynamic>? query,
  }) async {
    final params = query ?? const {};
    final stringQuery = params.map((key, value) => MapEntry(key, value.toString()));
    final uri = Uri.parse(url).replace(queryParameters: stringQuery);
    return _send(
      () => http
          .post(
            uri,
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: json.encode(params),
          )
          .timeout(timeout),
    );
  }

  static Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    http.Response response;
    try {
      response = await request();
    } on TimeoutException {
      throw AppApiException('The request timed out. Please try again.');
    } on SocketException {
      throw AppApiException('No internet connection. Please check your network.');
    } on http.ClientException {
      throw AppApiException('Could not connect to the server.');
    } catch (_) {
      throw AppApiException('Something went wrong. Please try again.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AppApiException('Server error (${response.statusCode}). Please try again.');
    }

    if (response.body.trim().isEmpty) {
      // Some endpoints (e.g. delete/clear) may legitimately return an
      // empty body on success.
      return const {'success': true};
    }

    dynamic decoded;
    try {
      decoded = json.decode(response.body);
    } catch (_) {
      throw AppApiException('Received an invalid response from the server.');
    }

    if (decoded is List) {
      return {'success': true, 'data': decoded};
    }

    if (decoded is Map<String, dynamic>) {
      final success = decoded['success'] ?? decoded['status'];
      final isExplicitFailure = success == false ||
          success?.toString().toLowerCase() == 'false' ||
          success?.toString().toLowerCase() == 'error';
      if (isExplicitFailure) {
        final message = decoded['message'] ?? decoded['error'];
        throw AppApiException(
          message?.toString() ?? 'The server reported an error.',
        );
      }
      return decoded;
    }

    throw AppApiException('Unexpected response format from the server.');
  }

  /// Pulls the `data` list out of a decoded envelope, tolerating a
  /// bare JSON array as well.
  static List<dynamic> extractList(Map<String, dynamic> decoded) {
    final data = decoded['data'] ?? decoded['orders'] ?? decoded['items'];
    if (data is List) return data;
    if (data is Map<String, dynamic>) return [data];
    return const [];
  }

  /// Pulls the `data` object out of a decoded envelope, tolerating a
  /// bare JSON object as well.
  static Map<String, dynamic>? extractMap(Map<String, dynamic> decoded) {
    final data = decoded['data'] ?? decoded['order'];
    if (data is Map<String, dynamic>) return data;
    if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
      return data.first as Map<String, dynamic>;
    }
    // Some APIs return the record fields directly at the top level
    // instead of nested under `data`.
    if (decoded.containsKey('id') || decoded.containsKey('order_number')) {
      return decoded;
    }
    return null;
  }
}
