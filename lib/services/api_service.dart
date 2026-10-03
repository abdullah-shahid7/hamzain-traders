import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:hamzain_traders/models/product.dart';
import 'package:hamzain_traders/models/product_image.dart';
import 'package:hamzain_traders/services/api_constants.dart';

/// Thin exception type so screens can show a friendly message without
/// caring whether the failure was a timeout, a socket error, bad JSON,
/// or an explicit `success: false` from the API.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Centralizes all HTTP calls + response parsing for the existing
/// `getproducts.php` and `getproductimages.php` endpoints so the UI
/// screens never have to know about the raw response shape. If the
/// backend's exact JSON structure ever changes, only this file needs
/// to be updated.
class ApiService {
  static const Duration _timeout = Duration(seconds: 20);

  /// Parses the common `{ "success": bool, "data": [...] }` envelope.
  /// Falls back to treating the body as a bare JSON array if the
  /// envelope isn't present, so the service stays resilient to minor
  /// backend response differences without touching the UI.
  List<dynamic> _extractDataList(String body) {
    dynamic decoded;
    try {
      decoded = json.decode(body);
    } catch (_) {
      throw ApiException('Received an invalid response from the server.');
    }

    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      final success = decoded['success'];
      if (success == false) {
        final message = decoded['message']?.toString();
        throw ApiException(message ?? 'The server returned no data.');
      }
      final data = decoded['data'];
      if (data is List) {
        return data;
      }
      if (data == null) {
        return const [];
      }
    }

    throw ApiException('Unexpected response format from the server.');
  }

  Future<String> _get(String url) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          'Server error (${response.statusCode}). Please try again.',
        );
      }
      return response.body;
    } on TimeoutException {
      throw ApiException('The request timed out. Please try again.');
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on http.ClientException {
      throw ApiException('Could not connect to the server.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Something went wrong. Please try again.');
    }
  }

  /// Fetches every product from the backend. Screens are responsible
  /// for filtering by `brandId` client-side.
  Future<List<Product>> getProducts() async {
    final body = await _get(ApiConstants.getProducts);
    final list = _extractDataList(body);
    return list
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }

  /// Fetches images for a given product. The backend endpoint may
  /// return either just that product's images or the full images
  /// table depending on its implementation, so results are always
  /// filtered by `productId` and sorted by `sortOrder` here to
  /// guarantee correct behavior regardless.
  Future<List<ProductImage>> getProductImages(int productId) async {
    final uri = Uri.parse(ApiConstants.getProductImages)
        .replace(queryParameters: {'product_id': productId.toString()});
    final body = await _get(uri.toString());
    final list = _extractDataList(body);
    final images = list
        .whereType<Map<String, dynamic>>()
        .map(ProductImage.fromJson)
        .where((image) => image.productId == productId)
        .toList();
    images.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return images;
  }
}
