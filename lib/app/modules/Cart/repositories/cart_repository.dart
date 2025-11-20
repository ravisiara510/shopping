import 'package:get/get.dart';
import 'package:eccomerce_app/app/core/services/api_service.dart';
import 'package:eccomerce_app/app/core/services/api_exceptions.dart';
import 'package:eccomerce_app/app/core/config/api_endpoints.dart';
import 'package:eccomerce_app/app/core/data/sharedPre.dart';
import 'package:eccomerce_app/app/core/utils/appString/app_storage_string.dart';

class CartRepository extends GetxService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> fetchCartItemsApi() async {
    try {
      final endpoint =
          "${ApiEndpoints.getCartApi}${SharedpreferenceUtil.getString(AppStorage.selectedCompanyId)}";
      final response = await _apiService.getRequestAuth(endpoint);
      return response.data;
    } on ApiException catch (e) {
      throw Exception('Failed to fetch cart items: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch cart items: $e');
    }
  }

  Future<Map<String, dynamic>> addToCart({
    required String productId,
    required int quantity,
  }) async {
    try {
      final endpoint =
          "${ApiEndpoints.addtoCart}${SharedpreferenceUtil.getString(AppStorage.selectedCompanyId)}";
      final data = {
        "items": [
          {
            "productId": productId,
            "quantity": quantity,
          }
        ]
      };
      final response = await _apiService.postRequestAuth(endpoint, data);
      return response.data;
    } on ApiException catch (e) {
      throw Exception('Failed to add item to cart: ${e.message}');
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

  Future<Map<String, dynamic>> removeFromCart(String itemID) async {
    try {
      final endpoint = "${ApiEndpoints.removeItemCart}$itemID";
      final response = await _apiService.deleteRequestAuth(endpoint);
      return response.data;
    } on ApiException catch (e) {
      throw Exception('Failed to remove item from cart: ${e.message}');
    } catch (e) {
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  Future<Map<String, dynamic>> clearCart() async {
    try {
      final endpoint =
          "${ApiEndpoints.clearCartApi}${SharedpreferenceUtil.getString(AppStorage.selectedCompanyId)}";
      final response = await _apiService.deleteRequestAuth(endpoint);
      return response.data;
    } on ApiException catch (e) {
      throw Exception('Failed to clear cart: ${e.message}');
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> orderData) async {
    try {
      final response = await _apiService.postRequestAuth(
        ApiEndpoints.createOrderApi,
        orderData,
      );
      return response.data;
    } on ApiException catch (e) {
      throw Exception('Failed to create order: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Add this method to your CartRepository class
// Add this method to your CartRepository class
  Future<Map<String, dynamic>> addMultipleToCart({
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final endpoint =
          "${ApiEndpoints.addtoCart}${SharedpreferenceUtil.getString(AppStorage.selectedCompanyId)}";
      final data = {
        "items": items
            .map((item) => {
                  "productId": item['productId'],
                  "quantity": item['quantity'],
                })
            .toList()
      };
      final response = await _apiService.postRequestAuth(endpoint, data);
      return response.data;
    } on ApiException catch (e) {
      throw Exception('Failed to add items to cart: ${e.message}');
    } catch (e) {
      throw Exception('Failed to add items to cart: $e');
    }
  }
}
