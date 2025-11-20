import 'package:eccomerce_app/app/custom/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../Base/controllers/base_controller.dart';
import '../controllers/cart_controller.dart';
import 'cart_item_widget.dart';
import 'special_instructions.dart';

class CartItemsContainer extends GetView<CartController> {
  final Size size;
  final ThemeData theme;

  const CartItemsContainer({
    super.key,
    required this.size,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        decoration: BoxDecoration(
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
        child: Column(
          children: [
            _buildCartItemsList(),
            Divider(
              height: 1,
              thickness: 1,
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
            SpecialInstructions(size: size, theme: theme, isInContainer: true),
            // ✅ Show button only when items were added via Order Again
            if (controller.cartItems.isNotEmpty &&
                controller.itemsAddedViaOrderAgain.value)
              Padding(
                padding: EdgeInsets.all(16.w),
                child: CustomButton(
                  text: 'Add More Items',
                  onPressed: _navigateToHome,
                ),
              ),
          ],
        ),
      );
    });
  }

  void _navigateToHome() {
    try {
      if (Get.isDialogOpen ?? false) Get.back();
      if (Get.isBottomSheetOpen ?? false) Get.back();
      if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();

      // Reset the flag when navigating away
      controller.itemsAddedViaOrderAgain.value = false;

      Get.until((route) {
        return route.settings.name == Routes.BASE || route.isFirst;
      });

      final baseController = Get.find<BaseController>();
      baseController.changeTabIndex(0);
      baseController.initializeDashbord();
    } catch (e) {
      Get.offAllNamed(Routes.BASE);
    }
  }

  Widget _buildCartItemsList() {
    if (controller.cartItems.isEmpty) {
      return _buildEmptyCart();
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: controller.cartItems.length,
      itemBuilder: (context, index) {
        final item = controller.cartItems[index];

        return Column(
          children: [
            CartItemWidget(
              item: item,
              size: size,
              theme: theme,
              isInContainer: true,
            ),
            if (index < controller.cartItems.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Container(
      padding: EdgeInsets.all(28.w),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 60.w,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          SizedBox(height: 12.h),
          Text(
            'Your cart is empty',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }
}
