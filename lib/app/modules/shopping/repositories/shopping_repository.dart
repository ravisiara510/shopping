// lib/app/modules/Shopping/repositories/shopping_repository.dart
import 'dart:developer';
import 'package:eccomerce_app/app/core/services/api_service.dart';
import 'package:eccomerce_app/app/core/services/api_exceptions.dart';

class ShoppingRepository {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> fetchStockItems(
    String companyId, {
    int page = 1,
    String search = '',
    int limit = 24,
  }) async {
    try {
      final url =
          "stock-items/stockItem/$companyId?search=$search&status=&sortBy=createdAt&sortOrder=desc&page=$page&limit=$limit&companyId=$companyId";

      final response = await _apiService.getRequestAuth(url);

      return response.data;
    } on ApiException catch (e) {
      // 401 is already handled by ApiService, just rethrow for other errors
      if (!e.isUnauthorized) {
        assert(() {
          log("❌ Stock items ApiException: ${e.message}");
          return true;
        }());
      }
      rethrow;
    } catch (e) {
      assert(() {
        log("❌ Unexpected error while fetching stock items: $e");
        return true;
      }());
      rethrow;
    }
  }
}
