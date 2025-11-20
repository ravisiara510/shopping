// order_details_controller.dart
import 'package:eccomerce_app/app/core/services/api_service.dart';
import 'package:eccomerce_app/app/modules/Cart/controllers/cart_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart' as open_file;

import '../../../core/config/api_endpoints.dart';
import '../../../core/services/pdf_service.dart';
import '../../../routes/app_pages.dart';
import '../../../services/toast_service.dart';
import '../../Cart/repositories/cart_repository.dart';

class OrderDetailsController extends GetxController {
  final ApiService _apiService = ApiService();
  final searchController = TextEditingController();
  final CartRepository cartRepository = CartRepository();
  CartController get cartController => Get.find<CartController>();

  final orders = <Map<String, dynamic>>[].obs;
  final filteredOrders = <Map<String, dynamic>>[].obs;
  final selectedOrder = <String, dynamic>{}.obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isGeneratingPdf = false.obs;

  // Search and filter variables
  final searchQuery = ''.obs;
  final selectedDateRange = Rxn<DateTimeRange>();
  final showSearchBar = false.obs;

  Map<String, dynamic> get selectedOrderMap {
    return Map<String, dynamic>.from(selectedOrder);
  }

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });

    debounce(searchQuery, (_) => filterOrders(),
        time: const Duration(milliseconds: 300));
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchOrders() async {
    try {
      isLoading.value = true;

      // Build API URL based on date range
      String url = ApiEndpoints.getOrders;
      if (selectedDateRange.value != null) {
        final start =
            selectedDateRange.value!.start.toIso8601String().split('T')[0];
        final end =
            selectedDateRange.value!.end.toIso8601String().split('T')[0];
        url = '${ApiEndpoints.getOrders}/date-range/$start/$end';
      }

      final response = await _apiService.getRequestAuth(url);

      if (response.data != null && response.data['orders'] != null) {
        final List<dynamic> ordersData = response.data['orders'];
        orders.value = ordersData.cast<Map<String, dynamic>>();
        filterOrders(); // Apply existing filters
      } else {
        orders.clear();
        filteredOrders.clear();
      }
    } catch (e) {
      _showErrorSnackbar('Failed to fetch orders: $e');
      orders.clear();
      filteredOrders.clear();
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> orderAgain() async {
    try {
      if (selectedOrder.isEmpty) {
        _showErrorSnackbar('No order selected');
        return;
      }

      final order = selectedOrderMap;
      final items = order['items'] as List<dynamic>? ?? [];

      if (items.isEmpty) {
        _showErrorSnackbar('No items found in this order');
        return;
      }

      // Show loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final cartItems = items.map((item) {
        return {
          'productId': item['productId'],
          'quantity': item['quantity'] ?? 1,
        };
      }).toList();

      final response = await cartRepository.addMultipleToCart(items: cartItems);

      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Navigator.pop(Get.context!);
      }

      if (response['success'] == true) {
        await cartController.fetchCartItems();
        cartController.itemsAddedViaOrderAgain.value = true;

        if (Get.isBottomSheetOpen ?? false) {
          Navigator.pop(Get.context!);
        }

        ApptoastUtils.showSuccess('All items added to cart!');

        Future.delayed(const Duration(milliseconds: 500), () {
          Get.toNamed(Routes.CART);
        });
      } else {
        throw Exception("Failed to add items to cart");
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Navigator.pop(Get.context!);
      }
      _showErrorSnackbar('Failed to add items to cart: ${e.toString()}');
    }
  }

  Future<bool> areItemsInCart(List<dynamic> orderItems) async {
    try {
      final cartResponse = await cartRepository.fetchCartItemsApi();

      if (cartResponse['success'] == true) {
        final List<dynamic> cartItems = cartResponse['cart'] ?? [];

        for (var orderItem in orderItems) {
          final productId = orderItem['productId'];
          final exists = cartItems.any((cartItem) =>
              cartItem['productId'] == productId ||
              cartItem['product']?['_id'] == productId);
          if (exists) return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void filterOrders() {
    if (searchQuery.value.isEmpty && selectedDateRange.value == null) {
      filteredOrders.value = List.from(orders);
      return;
    }

    final query = searchQuery.value.toLowerCase();
    filteredOrders.value = orders.where((order) {
      final matchesSearch =
          searchQuery.value.isEmpty ? true : _orderMatchesSearch(order, query);

      final matchesDate = selectedDateRange.value == null
          ? true
          : _orderMatchesDateRange(order);

      return matchesSearch && matchesDate;
    }).toList();
  }

  bool _orderMatchesSearch(Map<String, dynamic> order, String query) {
    if (order['orderCode']?.toString().toLowerCase().contains(query) == true) {
      return true;
    }
    if (order['customerId']?['customerName']
            ?.toString()
            .toLowerCase()
            .contains(query) ==
        true) {
      return true;
    }

    // Search in customer email
    if (order['customerId']?['emailAddress']
            ?.toString()
            .toLowerCase()
            .contains(query) ==
        true) {
      return true;
    }

    // Search in contact person
    if (order['customerId']?['contactPerson']
            ?.toString()
            .toLowerCase()
            .contains(query) ==
        true) {
      return true;
    }

    // Search in status
    if (getOrderStatusText(order['status'] ?? '')
        .toLowerCase()
        .contains(query)) {
      return true;
    }

    // Search in invoice number
    if (order['InvoiceNumber']?.toString().toLowerCase().contains(query) ==
        true) {
      return true;
    }

    return false;
  }

  bool _orderMatchesDateRange(Map<String, dynamic> order) {
    if (selectedDateRange.value == null) return true;

    try {
      final orderDate = DateTime.parse(order['createdAt']).toLocal();
      final startDate = selectedDateRange.value!.start;
      final endDate = selectedDateRange.value!.end;

      return orderDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          orderDate.isBefore(endDate.add(const Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }

  void setDateRange(DateTimeRange? range) {
    selectedDateRange.value = range;
    filterOrders();
  }

  void clearDateRange() {
    selectedDateRange.value = null;
    filterOrders();
  }

  void clearSearch() {
    searchQuery.value = '';
    searchController.clear();

    filterOrders();
  }

  void clearAllFilters() {
    searchQuery.value = '';
    selectedDateRange.value = null;
    filterOrders();
  }

  String getDateRangeText() {
    if (selectedDateRange.value == null) {
      return 'All Time';
    }

    final start = selectedDateRange.value!.start;
    final end = selectedDateRange.value!.end;

    return '${start.day}/${start.month}/${start.year} - ${end.day}/${end.month}/${end.year}';
  }

  bool get hasActiveFilters {
    return searchQuery.isNotEmpty || selectedDateRange.value != null;
  }

  Future<void> refreshOrders() async {
    isRefreshing.value = true;
    await fetchOrders();
  }

  void selectOrder(Map<String, dynamic> order) {
    selectedOrder.value = order;
  }

  void clearSelection() {
    selectedOrder.value = {};
  }

  Future<void> downloadInvoicePdf() async {
    try {
      if (selectedOrder.isEmpty) {
        _showErrorSnackbar('No order selected');
        return;
      }

      isGeneratingPdf.value = true;

      final order = selectedOrderMap;
      final filePath = await PdfInvoiceService.generateInvoicePdf(order);

      isGeneratingPdf.value = false;

      Get.snackbar(
        'Success',
        'Invoice downloaded successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      await open_file.OpenFile.open(filePath);
    } catch (e) {
      isGeneratingPdf.value = false;
      _showErrorSnackbar('Failed to generate invoice: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ApptoastUtils.showError(message);
  }

  String getOrderStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'cancelled':
        return 'Cancelled';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'approved':
        return 'Approved';
      default:
        return status;
    }
  }

  Color getOrderStatusColor(String status) {
    switch (status) {
      case 'completed':
      case 'delivered':
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'processing':
      case 'shipped':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getOrderStatusIcon(String status) {
    switch (status) {
      case 'completed':
      case 'delivered':
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'processing':
        return Icons.autorenew;
      case 'shipped':
        return Icons.local_shipping;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String formatDateShort(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  double calculateSubtotal(List<dynamic> items) {
    return items.fold(0.0, (sum, item) => sum + (item['total'] ?? 0.0));
  }

  int calculateTotalItems(List<dynamic> items) {
    return items.fold<int>(0, (sum, item) {
      final q = item['quantity'];
      final int intQty =
          q is num ? q.toInt() : int.tryParse(q?.toString() ?? '') ?? 0;
      return sum + intQty;
    });
  }
}
