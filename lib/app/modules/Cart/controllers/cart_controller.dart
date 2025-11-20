import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:eccomerce_app/app/core/data/sharedPre.dart';
import 'package:eccomerce_app/app/core/utils/appString/app_storage_string.dart';
import 'package:eccomerce_app/app/core/utils/logger.dart';
import '../../../routes/app_pages.dart';
import '../../../services/toast_service.dart';
import '../../shopping/controllers/shopping_controller.dart';
import '../repositories/cart_repository.dart';
import 'payment_controller.dart';

class CartController extends GetxController {
  final CartRepository _cartRepository = CartRepository();
  var isHidePaymentButton = false.obs;
  final cartItems = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final specialInstructions = ''.obs;
  final selectedCoupon = ''.obs;
  final isCouponApplied = false.obs;
  final itemsAddedViaOrderAgain = false.obs;

  final selectedCustomer = Rx<Map<String, dynamic>?>(null);
  final addressLine1 = ''.obs;
  final city = ''.obs;
  final state = ''.obs;
  final zipCode = ''.obs;

  final productsInCart = <String, bool>{}.obs;
  final cartItemCount = 0.obs;
  final loadingItems = <String, bool>{}.obs;

  bool isItemLoading(String productId) {
    return loadingItems[productId] ?? false;
  }

  void setItemLoading(String productId, bool loading) {
    if (loading) {
      loadingItems[productId] = true;
    } else {
      loadingItems.remove(productId);
    }
    update();
  }

  @override
  void onInit() {
    super.onInit();
    fetchCartItems();
  }

  void selectCustomer(Map<String, dynamic> customer) {
    selectedCustomer.value = customer;
    update();
  }

  void clearSelectedCustomer() {
    selectedCustomer.value = null;
    update();
  }

  RxDouble get subtotal => cartItems
      .fold(
          0.0,
          (sum, item) =>
              sum + ((item['finalPrice'] ?? 0.0) * (item['quantity'] ?? 1)))
      .obs;

  RxDouble get totalDiscount => cartItems.fold(0.0, (sum, item) {
        final product = item['product'] ?? {};
        final mrp = (product['MRP'] ?? 0.0).toDouble();
        final price = (product['Price'] ?? 0.0).toDouble();
        final quantity = item['quantity'] ?? 1;
        return sum + ((mrp - price) * quantity);
      }).obs;

  RxDouble get deliveryCharge => (subtotal.value >= 200 ? 0.0 : 45.0).obs;
  RxDouble get grandTotal => (subtotal.value + deliveryCharge.value).obs;

  bool isProductInCart(String productId) {
    final fromMap = productsInCart[productId] ?? false;
    final fromList = cartItems.any(
        (item) => (item['productId'] ?? item['product']?['_id']) == productId);
    return fromMap || fromList;
  }

  bool get hasItems => cartItemCount.value > 0;

  // Method to reset all cart values after successful order
  void resetCartAfterOrder() {
    cartItems.clear();
    productsInCart.clear();
    cartItemCount.value = 0;
    specialInstructions.value = '';
    selectedCoupon.value = '';
    isCouponApplied.value = false;
    selectedCustomer.value = null;
    addressLine1.value = '';
    city.value = '';
    state.value = '';
    zipCode.value = '';
    loadingItems.clear();

    _notifyShoppingController();

    update();
    AppLogger.debug("🔄 Cart reset successfully after order completion");
  }

  Future<void> fetchCartItems() async {
    try {
      // isLoading.value = true;

      final response = await _cartRepository.fetchCartItemsApi();

      if (response['success'] == true) {
        final responseData = response;
        List<dynamic> items = [];

        cartItemCount.value = (responseData['totalItems'] ?? 0).toInt();

        if (responseData['cart'] != null) {
          items = responseData['cart'] is List
              ? responseData['cart']
              : [responseData['cart']];
        } else if (responseData['data'] != null &&
            responseData['data'] is List) {
          items = responseData['data'];
        }

        cartItems.assignAll(items.cast<Map<String, dynamic>>());

        productsInCart.clear();

        for (var item in cartItems) {
          final productId = item['productId'] ?? item['product']?['_id'];
          if (productId != null) {
            productsInCart[productId] = true;
          }
        }

        if (cartItems.isEmpty) {
          _notifyShoppingController();
        }
        update();
      } else {
        cartItemCount.value = 0;
        cartItems.clear();
        productsInCart.clear();
        _notifyShoppingController();
      }
    } catch (e) {
      cartItemCount.value = 0;
      cartItems.clear();
      productsInCart.clear();
      _notifyShoppingController();
      ApptoastUtils.showError('Failed to fetch cart items');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addToCart({
    required String productId,
    required int quantity,
  }) async {
    try {
      final response = await _cartRepository.addToCart(
        productId: productId,
        quantity: quantity,
      );

      if (response['success'] == true) {
        productsInCart[productId] = true;
        await fetchCartItems();
        ApptoastUtils.showSuccess('Item added to cart!');
      } else {
        throw Exception("Failed to add item to cart!");
      }
    } catch (e) {
      ApptoastUtils.showError('Failed to add item to cart');
    }
  }

  Future<void> removeFromCart(String itemID) async {
    try {
      final response = await _cartRepository.removeFromCart(itemID);

      if (response['success'] == true) {
        await fetchCartItems();
        ApptoastUtils.showSuccess('Item removed from cart!');
      } else {
        throw Exception("Failed to remove item from cart!");
      }
    } catch (e) {
      ApptoastUtils.showError('Failed to remove item from cart');
    }
  }

  Future<void> clearCart() async {
    try {
      isLoading.value = true;
      final response = await _cartRepository.clearCart();

      if (response['success'] == true) {
        itemsAddedViaOrderAgain.value = false;
        // ✅ सभी cart data को clear करें
        resetCartAfterOrder();

        ApptoastUtils.showSuccess('Cart cleared successfully');
      } else {
        throw Exception("Failed to clear cart!");
      }
    } catch (e) {
      ApptoastUtils.showError('Failed to clear cart');
    } finally {
      isLoading.value = false;
    }
  }

  void _notifyShoppingController() {
    try {
      if (Get.isRegistered<ShoppingController>()) {
        final shoppingController = Get.put(ShoppingController());

        shoppingController.refreshProducts();
        AppLogger.debug("✅ Notified ShoppingController to refresh products");
      }
    } catch (e) {
      AppLogger.warning("⚠️ Could not notify ShoppingController: $e");
    }
  }

  Future<void> incrementQuantity(String productId, int currentQuantity) async {
    try {
      setItemLoading(productId, true);
      final newQuantity = currentQuantity + 1;
      await addToCart(productId: productId, quantity: newQuantity);
    } catch (e) {
      ApptoastUtils.showError('Failed to increment quantity');
    } finally {
      setItemLoading(productId, false);
    }
  }

  Future<void> decrementQuantity(String productId, int currentQuantity) async {
    try {
      setItemLoading(productId, true);
      if (currentQuantity > 1) {
        final newQuantity = currentQuantity - 1;
        await addToCart(productId: productId, quantity: newQuantity);
      } else {
        await removeFromCart(productId);
      }
    } catch (e) {
      ApptoastUtils.showError('Failed to decrement quantity');
    } finally {
      setItemLoading(productId, false);
    }
  }

  void updateAddress({
    required String addressLine1,
    required String city,
    required String state,
    required String zipCode,
  }) {
    this.addressLine1.value = addressLine1;
    this.city.value = city;
    this.state.value = state;
    this.zipCode.value = zipCode;
    update();
  }

  bool _validateAddress() {
    if (addressLine1.value.isEmpty) {
      ApptoastUtils.showWarning('Please add a delivery address');
      return false;
    }

    if (city.value.isEmpty) {
      ApptoastUtils.showWarning('Please enter your city');
      return false;
    }

    if (state.value.isEmpty) {
      ApptoastUtils.showWarning('Please enter your state');
      return false;
    }

    if (zipCode.value.isEmpty) {
      ApptoastUtils.showWarning('Please enter your ZIP code');
      return false;
    }

    return true;
  }

  bool _validateCustomer() {
    if (selectedCustomer.value == null) {
      ApptoastUtils.showWarning('Please select a customer');
      return false;
    }
    return true;
  }

  void confirmOrder() {
    if (cartItems.isEmpty) {
      ApptoastUtils.showWarning('Your cart is empty');
      return;
    }

    if (!_validateCustomer()) return;
    if (!_validateAddress()) {
      _showAddressRequiredDialog();
      return;
    }

    createOrder();
  }

  void _showAddressRequiredDialog() {
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on_outlined, color: Colors.orange, size: 24),
            SizedBox(width: 12),
            Text(
              'Address Required',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ],
        ),
        content: const Text(
          'Please add a complete delivery address to proceed with your order.',
          style: TextStyle(fontSize: 16, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(Get.context!),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(Get.context!);
              Future.delayed(const Duration(milliseconds: 100), () {
                _showAddressBottomSheet(Get.context!);
              });
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Add Address'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> createOrder() async {
    try {
      if (cartItems.isEmpty) return;
      if (!_validateCustomer()) return;
      if (!_validateAddress()) {
        _showAddressRequiredDialog();
        return;
      }

      isLoading.value = true;

      final orderData = {
        "companyId":
            SharedpreferenceUtil.getString(AppStorage.selectedCompanyId),
        "customerId":
            selectedCustomer.value?['_id'] ?? selectedCustomer.value?['id'],
        "shippingAddress": {
          "street": addressLine1.value,
          "line2": "",
          "city": city.value,
          "state": state.value,
          "postalCode": zipCode.value,
          "country": "India"
        },
        "items": cartItems.map((item) {
          final product = item['product'] ?? {};
          final mrp = (product['MRP'] ?? 0.0).toDouble();
          final price = (product['Price'] ?? 0.0).toDouble();
          final discount = mrp - price;

          return {
            "productId": item['productId'] ?? product['_id'],
            "quantity": item['quantity'] ?? 1,
            "price": mrp,
            "total": price * (item['quantity'] ?? 1),
            "discount": discount * (item['quantity'] ?? 1)
          };
        }).toList(),
        "orderSource": "mobile_app"
      };

      final response = await _cartRepository.createOrder(orderData);

      if (response['statusCode'] == 201) {
        // Clear cart and reset all values after successful order creation
        resetCartAfterOrder();
        itemsAddedViaOrderAgain.value = false;
        _showOrderConfirmationBottomSheet(response['data'] ?? {});
        isHidePaymentButton.value = false;

        AppLogger.debug('order status: ${response['statusCode']}');
      } else {
        throw Exception(response['message'] ?? 'Failed to create order');
      }
    } catch (e) {
      ApptoastUtils.showError('Failed to create order');
    } finally {
      isLoading.value = false;
    }
  }

  void _showOrderConfirmationBottomSheet(Map<String, dynamic> orderData) {
    // Check if payment is already successful
    final isPaymentSuccessful =
        orderData['payment']?['status'] == 'completed' ||
            orderData['payment']?['status'] == 'success';
    final hasPaymentData = orderData['payment'] != null;
    final showPaymentButton = (!hasPaymentData || !isPaymentSuccessful);

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(Get.context!).size.width,
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          width: double.infinity, // Full width of the screen.
          decoration: BoxDecoration(
            color: Get.theme.colorScheme.background,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 3.h,
                      decoration: BoxDecoration(
                        color: Get.theme.colorScheme.onSurface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(1.5.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Success Icon & Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 22.w),
                          SizedBox(width: 8.w),
                          Text(
                            'Order Confirmed!',
                            style: Get.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.close_outlined,
                          color: Get.theme.colorScheme.error,
                          size: 18.w,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 32.w,
                          minHeight: 32.h,
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Payment Status Badge (NEW)
                  if (hasPaymentData) ...[
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: isPaymentSuccessful
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: isPaymentSuccessful
                              ? Colors.green
                              : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPaymentSuccessful
                                ? Icons.check_circle
                                : Icons.pending,
                            color: isPaymentSuccessful
                                ? Colors.green
                                : Colors.orange,
                            size: 14.w,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            isPaymentSuccessful
                                ? 'Payment Completed'
                                : 'Payment Pending',
                            style: TextStyle(
                              color: isPaymentSuccessful
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],

                  // Order ID
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.receipt, color: Colors.blue, size: 16.w),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order ID',
                                style: Get.textTheme.bodySmall?.copyWith(
                                  color: Colors.blue,
                                  fontSize: 10.sp,
                                ),
                              ),
                              Text(
                                orderData['_id'] ?? 'N/A',
                                style: Get.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Delivery Details
                  _buildInfoSection(
                    title: 'Delivery Details',
                    icon: Icons.location_on,
                    color: Colors.green,
                    children: [
                      Text(
                        'Address: ${addressLine1.value.isNotEmpty ? addressLine1.value : orderData['shippingAddress']?['street'] ?? 'Not provided'}',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'City: ${city.value.isNotEmpty ? city.value : orderData['shippingAddress']?['city'] ?? 'Not provided'}, '
                        '${state.value.isNotEmpty ? state.value : orderData['shippingAddress']?['state'] ?? 'Not provided'} - '
                        '${zipCode.value.isNotEmpty ? zipCode.value : orderData['shippingAddress']?['postalCode'] ?? 'Not provided'}',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                      if (selectedCustomer.value != null) ...[
                        SizedBox(height: 6.h),
                        Text(
                          'Customer: ${selectedCustomer.value!['customerName']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Modern Button Arrangement
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Column(
                      children: [
                        if (showPaymentButton) ...[
                          // Make Payment Button - Primary Action
                          Container(
                            width: double.infinity,
                            height: 44.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Get.theme.colorScheme.primary,
                                  Get.theme.colorScheme.primary
                                      .withOpacity(0.9),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Get.theme.colorScheme.primary
                                      .withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (isHidePaymentButton.isFalse) {
                                    _showPaymentDialog(orderData);
                                  } else {
                                    ApptoastUtils.showSuccess(
                                      'Payment Completed - This order has already been paid successfully.',
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(12.r),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.payment,
                                        color: Colors.white, size: 16.w),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'Make Payment',
                                      style: Get.textTheme.bodyLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8.h),
                        ],

                        // View Order Details Button - Secondary Action
                        Container(
                          width: double.infinity,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: Get.theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: Get.theme.colorScheme.primary
                                  .withOpacity(0.3),
                              width: 1.2,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                Get.offAndToNamed(Routes.ORDER_DETAILS,
                                    arguments: orderData);
                              },
                              borderRadius: BorderRadius.circular(10.r),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long,
                                      color: Get.theme.colorScheme.primary,
                                      size: 16.w),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'View Order Details',
                                    style: Get.textTheme.bodyMedium?.copyWith(
                                      color: Get.theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),

                        // Continue Shopping Button - Tertiary Action
                        Container(
                          width: double.infinity,
                          height: 36.h,
                          decoration: BoxDecoration(
                            color:
                                Get.theme.colorScheme.surface.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                Get.offAndToNamed(Routes.BASE);
                              },
                              borderRadius: BorderRadius.circular(8.r),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_bag_outlined,
                                      color: Get.theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                      size: 14.w),
                                  SizedBox(width: 6.w),
                                  Text(
                                    'Continue Shopping',
                                    style: Get.textTheme.bodyMedium?.copyWith(
                                      color: Get.theme.colorScheme.onSurface
                                          .withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 6.h),

                  // Security/Status Note
                  if (showPaymentButton)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline,
                              color: Get.theme.colorScheme.primary, size: 12.w),
                          SizedBox(width: 4.w),
                          Text(
                            'Complete payment to process your order',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: Get.theme.colorScheme.onSurface
                                  .withOpacity(0.6),
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Payment Completed Note (NEW)
                  if (!showPaymentButton)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 12.w),
                          SizedBox(width: 4.w),
                          Text(
                            'Payment already completed',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  void _showPaymentDialog(Map<String, dynamic> orderData) {
    final paymentController =
        Get.put(PaymentDialogController(orderData: orderData));

    // Extract customer data from order response
    final customerData = orderData['customerId'];
    final customerName = customerData?['customerName'] ?? 'N/A';
    final customerId = customerData?['_id'] ?? 'N/A';

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: !paymentController.isLoading.value,
      constraints: BoxConstraints(
        maxHeight: Get.height * 0.85,
        maxWidth: double.infinity,
      ),
      builder: (context) => Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: Get.height * 0.85,
          maxWidth: double.infinity,
        ),
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Obx(() => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 32.w,
                        height: 3.h,
                        decoration: BoxDecoration(
                          color:
                              Get.theme.colorScheme.onSurface.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(1.5.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Header with Gradient
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Get.theme.colorScheme.primary.withOpacity(0.1),
                            Get.theme.colorScheme.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Get.theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.payment,
                                color: Colors.white, size: 18.w),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Complete Payment',
                                  style: Get.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Get.theme.colorScheme.primary,
                                    fontSize: 16.sp,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Secure payment processing',
                                  style: Get.textTheme.bodySmall?.copyWith(
                                    color: Get.theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: Get.theme.colorScheme.onSurface
                                    .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.close, size: 16.w),
                            ),
                            onPressed: paymentController.isLoading.value
                                ? null
                                : () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(
                              minWidth: 32.w,
                              minHeight: 32.h,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Customer Card
                    _buildModernCard(
                      icon: Icons.person,
                      iconColor: Colors.blue,
                      title: 'Customer Information',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.person_outline,
                                    size: 14.w, color: Colors.blue),
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Name',
                                      style: Get.textTheme.bodySmall?.copyWith(
                                        color: Get.theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                    Text(
                                      customerName,
                                      style: Get.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.fingerprint,
                                    size: 14.w, color: Colors.green),
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Customer ID',
                                      style: Get.textTheme.bodySmall?.copyWith(
                                        color: Get.theme.colorScheme.onSurface
                                            .withOpacity(0.6),
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                    Text(
                                      customerId,
                                      style: Get.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Email information (if available)
                          if (customerData?['emailAddress'] != null) ...[
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(6.w),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.email_outlined,
                                      size: 14.w, color: Colors.orange),
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Email',
                                        style:
                                            Get.textTheme.bodySmall?.copyWith(
                                          color: Get.theme.colorScheme.onSurface
                                              .withOpacity(0.6),
                                          fontSize: 10.sp,
                                        ),
                                      ),
                                      Text(
                                        customerData!['emailAddress'],
                                        style:
                                            Get.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Payment Method Card
                    _buildModernCard(
                      icon: Icons.credit_card,
                      iconColor: Colors.purple,
                      title: 'Payment Method',
                      child: Column(
                        children: [
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children:
                                paymentController.paymentMethods.map((method) {
                              final isSelected =
                                  paymentController.selectedMethod.value ==
                                      method;
                              return GestureDetector(
                                onTap: paymentController.isLoading.value
                                    ? null
                                    : () => paymentController
                                        .selectedMethod.value = method,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Get.theme.colorScheme.primary
                                            .withOpacity(0.1)
                                        : Get.theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: isSelected
                                          ? Get.theme.colorScheme.primary
                                          : Get.theme.colorScheme.outline
                                              .withOpacity(0.3),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: Get
                                                  .theme.colorScheme.primary
                                                  .withOpacity(0.2),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        color: isSelected
                                            ? Get.theme.colorScheme.primary
                                            : Colors.grey,
                                        size: 16.w,
                                      ),
                                      SizedBox(width: 6.w),
                                      Text(
                                        paymentController
                                            .getPaymentMethodDisplayName(
                                                method),
                                        style:
                                            Get.textTheme.bodyMedium?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? Get.theme.colorScheme.primary
                                              : null,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Amount Card
                    _buildModernCard(
                      icon: Icons.currency_rupee,
                      iconColor: Colors.green,
                      title: 'Payment Amount',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: paymentController.amountController,
                            keyboardType: TextInputType.number,
                            style: Get.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Get.theme.colorScheme.primary,
                              fontSize: 16.sp,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Container(
                                margin: EdgeInsets.only(right: 8.w, left: 6.w),
                                child: Icon(Icons.currency_rupee,
                                    color: Get.theme.colorScheme.primary,
                                    size: 18.w),
                              ),
                              hintText: '0.00',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: BorderSide(
                                    color: Get.theme.colorScheme.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: BorderSide(
                                    color: Get.theme.colorScheme.primary,
                                    width: 1.5),
                              ),
                              filled: true,
                              fillColor: Get.theme.colorScheme.surface,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                            ),
                            onChanged: (value) =>
                                paymentController.validateAmount(value),
                          ),
                          if (paymentController
                              .amountError.value.isNotEmpty) ...[
                            SizedBox(height: 6.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red, size: 14.w),
                                  SizedBox(width: 6.w),
                                  Expanded(
                                    child: Text(
                                      paymentController.amountError.value,
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 10.sp),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Remarks Card
                    _buildModernCard(
                      icon: Icons.note_alt_outlined,
                      iconColor: Colors.orange,
                      title: 'Remarks (Optional)',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: paymentController.remarksController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText:
                                  'Add any remarks or notes about this payment...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: BorderSide(
                                    color: Get.theme.colorScheme.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.r),
                                borderSide: BorderSide(
                                    color: Get.theme.colorScheme.primary,
                                    width: 1.5),
                              ),
                              filled: true,
                              fillColor: Get.theme.colorScheme.surface,
                              contentPadding: EdgeInsets.all(12.w),
                            ),
                            style: TextStyle(fontSize: 12.sp),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'This will be saved with your payment record',
                            style: Get.textTheme.bodySmall?.copyWith(
                              color: Get.theme.colorScheme.onSurface
                                  .withOpacity(0.6),
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // Document Upload Card
                    _buildModernCard(
                      icon: Icons.attach_file,
                      iconColor: Colors.blue,
                      title: 'Upload Documents (Optional)',
                      child: Column(
                        children: [
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              ...paymentController.uploadedFiles
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final index = entry.key;
                                final file = entry.value;
                                return Stack(
                                  children: [
                                    Container(
                                      width: 60.w,
                                      height: 60.h,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                        image: DecorationImage(
                                          image: FileImage(file),
                                          fit: BoxFit.cover,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: -4.h,
                                      right: -4.w,
                                      child: IconButton(
                                        icon: Container(
                                          padding: EdgeInsets.all(3.w),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.close,
                                              color: Colors.white, size: 10.w),
                                        ),
                                        onPressed:
                                            paymentController.isLoading.value
                                                ? null
                                                : () => paymentController
                                                    .removeFile(index),
                                        padding: EdgeInsets.zero,
                                        constraints: BoxConstraints(
                                          minWidth: 20.w,
                                          minHeight: 20.h,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                              if (paymentController.uploadedFiles.length < 5)
                                GestureDetector(
                                  onTap: paymentController.isLoading.value
                                      ? null
                                      : () => _showImageSourceBottomSheet(
                                          paymentController),
                                  child: Container(
                                    width: 60.w,
                                    height: 60.h,
                                    decoration: BoxDecoration(
                                      color: Get.theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(8.r),
                                      border: Border.all(
                                        color: Get.theme.colorScheme.primary
                                            .withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          color: Get.theme.colorScheme.primary,
                                          size: 18.w,
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          'Add',
                                          style: TextStyle(
                                            color:
                                                Get.theme.colorScheme.primary,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (paymentController.uploadedFiles.isEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              child: Column(
                                children: [
                                  Icon(Icons.photo_library,
                                      size: 30.w,
                                      color: Colors.grey.withOpacity(0.5)),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'No documents uploaded yet',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                  Text(
                                    'Add receipts or payment proofs',
                                    style: TextStyle(
                                      color: Colors.grey.withOpacity(0.7),
                                      fontSize: 9.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // Submit Button
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Get.theme.colorScheme.primary,
                            Get.theme.colorScheme.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Get.theme.colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: paymentController.canSubmit.value &&
                                  !paymentController.isLoading.value
                              ? () => paymentController.submitPayment()
                              : null,
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (paymentController.isLoading.value)
                                  SizedBox(
                                    width: 16.w,
                                    height: 16.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                else
                                  Icon(Icons.lock,
                                      color: Colors.white, size: 16.w),
                                SizedBox(width: 8.w),
                                Text(
                                  paymentController.isLoading.value
                                      ? 'Processing...'
                                      : 'Confirm Payment - ₹${paymentController.amountController.text}',
                                  style: Get.textTheme.bodyLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),

                    // Security Note
                    Center(
                      child: Text(
                        '🔒 Secure SSL Encrypted Payment',
                        style: Get.textTheme.bodySmall?.copyWith(
                          color:
                              Get.theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ],
                )),
          ),
        ),
      ),
    );
  }

  Widget _buildModernCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Get.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Get.theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Get.theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  void _showImageSourceBottomSheet(PaymentDialogController controller) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Get.theme.colorScheme.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Get.theme.colorScheme.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Get.theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt,
                        color: Get.theme.colorScheme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Upload Document',
                    style: Get.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                'Choose how you want to capture the document',
                style: Get.textTheme.bodyMedium?.copyWith(
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Options
              Row(
                children: [
                  Expanded(
                    child: _buildImageOption(
                      icon: Icons.camera_alt,
                      title: 'Camera',
                      subtitle: 'Take a photo',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(Get.context!);

                        controller.pickImageFromCamera();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildImageOption(
                      icon: Icons.photo_library,
                      title: 'Gallery',
                      subtitle: 'Choose from gallery',
                      color: Colors.green,
                      onTap: () {
                        Navigator.pop(Get.context!);

                        controller.pickImageFromGallery();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Get.theme.colorScheme.outline),
                  ),
                  child: Text(
                    'Cancel',
                    style: Get.textTheme.bodyLarge?.copyWith(
                      color: Get.theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Get.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddressBottomSheet(BuildContext context) {
    final addressLine1Controller =
        TextEditingController(text: addressLine1.value);
    final cityController = TextEditingController(text: city.value);
    final stateController = TextEditingController(text: state.value);
    final zipCodeController = TextEditingController(text: zipCode.value);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width, // Full screen width
        minWidth: MediaQuery.of(context).size.width, // Full screen width
      ),
      builder: (context) => Container(
        width: MediaQuery.of(context).size.width, // Full screen width
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * 0.9, // 90% of screen height
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20.w, // Add left padding
          right: 20.w, // Add right padding
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBottomSheetHandle(context),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 4.w), // Additional horizontal padding if needed
                child: _buildAddressForm(
                  context,
                  addressLine1Controller,
                  cityController,
                  stateController,
                  zipCodeController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

// Helper method for bottom sheet handle
  Widget _buildBottomSheetHandle(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

// Helper method for address form
// Helper method for address form
  Widget _buildAddressForm(
    BuildContext context,
    TextEditingController addressLine1Controller,
    TextEditingController cityController,
    TextEditingController stateController,
    TextEditingController zipCodeController,
  ) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width, // Full width
      ),
      child: IntrinsicWidth(
        // Takes the intrinsic width of children
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Stretch to full width
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: theme.colorScheme.primary,
                        size: 20.w,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Delivery Address',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.close_outlined,
                    size: 20.w,
                  ),
                )
              ],
            ),
            SizedBox(height: 20.h),
            _buildAddressField(
              context,
              controller: addressLine1Controller,
              label: 'Address Line 1',
              hint: 'House No., Building, Street',
              icon: Icons.home_outlined,
            ),
            SizedBox(height: 12.h),
            _buildAddressField(
              context,
              controller: cityController,
              label: 'City',
              hint: 'Enter your city',
              icon: Icons.location_city_outlined,
            ),
            SizedBox(height: 12.h),
            _buildAddressField(
              context,
              controller: zipCodeController,
              label: 'ZIP Code',
              hint: '000000',
              icon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12.h),
            _buildAddressField(
              context,
              controller: stateController,
              label: 'State',
              hint: 'State',
              icon: Icons.map_outlined,
            ),
            SizedBox(height: 20.h),
            FilledButton(
              onPressed: () {
                addressLine1.value = addressLine1Controller.text;
                city.value = cityController.text;
                state.value = stateController.text;
                zipCode.value = zipCodeController.text;
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Save Address',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

// Helper method for address fields
  Widget _buildAddressField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 11.sp),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 10.sp),
        hintText: hint,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
  }
}
