import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/cart_controller.dart';

class CartItemWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final Size size;
  final ThemeData theme;
  final bool isInContainer;

  const CartItemWidget({
    super.key,
    required this.item,
    required this.size,
    required this.theme,
    required this.isInContainer,
  });

  void _showRemoveItemBottomSheet(BuildContext context,
      CartController controller, String itemID, String itemName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          margin: EdgeInsets.all(12.w),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36.w,
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.remove_shopping_cart_rounded,
                          color: theme.colorScheme.error,
                          size: 28.w,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Remove Item?',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '"$itemName" will be removed from your cart.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          height: 1.4,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                              child: Text(
                                'Keep Item',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                try {
                                  controller.setItemLoading(itemID, true);
                                  await controller.removeFromCart(itemID);
                                } finally {
                                  controller.setItemLoading(itemID, false);
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                              child: Text(
                                'Remove',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final CartController controller = Get.put(CartController());

    return Obx(() {
      final updatedItem = controller.cartItems.firstWhere(
        (cartItem) => cartItem['_id'] == item['_id'],
        orElse: () => item,
      );

      final productId = updatedItem['productId'];
      final isItemLoading = controller.isItemLoading(productId);

      return _buildItemWidget(controller, updatedItem, isItemLoading, context);
    });
  }

  Widget _buildItemWidget(
    CartController controller,
    Map<String, dynamic> item,
    bool isItemLoading,
    BuildContext context,
  ) {
    final product = item['product'] ?? {};
    final mrp = (product['MRP'] ?? 0.0).toDouble();
    final price = (product['Price'] ?? 0.0).toDouble();
    final discountPercentage =
        mrp > 0 ? ((mrp - price) / mrp * 100).round() : 0;
    final quantity = item['quantity'] ?? 1;
    final itemName = item['itemName'] ?? 'Unknown Product';
    final productId = item['productId'];
    final itemID = item['_id'];

    return Container(
      margin: isInContainer ? EdgeInsets.zero : EdgeInsets.only(bottom: 8.h),
      decoration: isInContainer
          ? null
          : BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10.w,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
      child: ClipRRect(
        borderRadius:
            isInContainer ? BorderRadius.zero : BorderRadius.circular(16.r),
        child: Column(
          children: [
            Padding(
              padding:
                  EdgeInsets.only(top: 8.h, left: 6.w, right: 6.w, bottom: 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(discountPercentage),
                  SizedBox(width: 12.w),
                  _buildProductDetails(controller, itemName, product, mrp,
                      price, discountPercentage, itemID, context),
                ],
              ),
            ),
            _buildQuantityControls(
                controller, productId, quantity, item, isItemLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(int discountPercentage) {
    return Container(
      width: 80.w,
      height: 70.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.3),
            theme.colorScheme.secondaryContainer.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.shopping_bag_rounded,
              color: theme.colorScheme.primary.withOpacity(0.4),
              size: 36.w,
            ),
          ),
          if (discountPercentage > 0)
            Positioned(
              top: 2.h,
              right: 2.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  '$discountPercentage%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductDetails(
    CartController controller,
    String itemName,
    Map<String, dynamic> product,
    double mrp,
    double price,
    int discountPercentage,
    String itemID,
    BuildContext context,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  itemName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.normal,
                    fontSize: 12.sp,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => _showRemoveItemBottomSheet(
                    context, controller, itemID, itemName),
                borderRadius: BorderRadius.circular(4.r),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Icon(
                    Icons.close,
                    color: theme.colorScheme.error,
                    size: 14.w,
                  ),
                ),
              ),
            ],
          ),
          Text(
            '${product['Group']} • ${product['Category']}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 11.sp,
            ),
          ),
          Row(
            children: [
              if (discountPercentage > 0) ...[
                Text(
                  '₹${mrp.toStringAsFixed(0)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                    decoration: TextDecoration.lineThrough,
                    decorationThickness: 2,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(width: 4.w),
              ],
              Text(
                '₹${price.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls(
    CartController controller,
    String productId,
    int quantity,
    Map<String, dynamic> item,
    bool isItemLoading,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹${(item['finalPrice'] ?? 0.0).toStringAsFixed(0)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  fontSize: 13.sp, // Adjusted
                ),
              ),
            ],
          ),
          if (isItemLoading)
            _buildShimmerQuantityControls()
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(width: 0.8, color: theme.primaryColor),
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8.r), // -4 from 12
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8.w,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: Row(
                children: [
                  InkWell(
                    onTap: () =>
                        controller.decrementQuantity(productId, quantity),
                    borderRadius: BorderRadius.circular(8.r), // -4 from 12
                    child: Container(
                      padding: EdgeInsets.all(5.w), // -4 from 8
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8.r), // -4 from 12
                      ),
                      child: Icon(
                        Icons.remove,
                        size: 12.sp, // -4 from 14
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w), // -4 from 16
                    child: Text(
                      quantity.toString(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp, // Adjusted
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () =>
                        controller.incrementQuantity(productId, quantity),
                    borderRadius: BorderRadius.circular(8.r),
                    child: Container(
                      padding: EdgeInsets.all(5.w),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 13.sp,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerQuantityControls() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.r), // -4 from 12
        ),
        padding: EdgeInsets.symmetric(
            horizontal: 4.w, vertical: 2.h), // -4 from 8, 4
        child: Row(
          children: [
            Container(
              width: 26.w, // -4 from 30
              height: 26.h, // -4 from 30
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(8.r), // -4 from 12
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 12.w), // -4 from 16
              width: 16.w, // -4 from 20
              height: 16.h, // -4 from 20
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            Container(
              width: 26.w, // -4 from 30
              height: 26.h, // -4 from 30
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(8.r), // -4 from 12
              ),
            ),
          ],
        ),
      ),
    );
  }
}
