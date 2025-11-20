import 'package:carousel_slider/carousel_slider.dart';
import 'package:eccomerce_app/app/custom/button.dart';
import 'package:eccomerce_app/app/modules/Cart/controllers/cart_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shimmer/shimmer.dart';
import '../../../routes/app_pages.dart';
import '../../../services/toast_service.dart';
import '../controllers/shopping_controller.dart';
import '../models/shopping_models.dart';

class ShoppingView extends GetView<ShoppingController> {
  const ShoppingView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ShoppingController());
    final CartController cartController = Get.put(CartController());

    return AnnotatedRegion(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildFixedHeader(context, controller, cartController),
              Obx(() => controller.showFilters.value
                  ? _buildSearchSection(context, controller)
                  : const SizedBox()),
              _buildActiveFiltersChips(context, controller),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    controller.refreshProducts();
                    cartController.fetchCartItems();
                  },
                  child: _buildContent(context, cartController, controller),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Obx(
          () => cartController.hasItems
              ? _buildBottomCartBar(context, cartController)
              : const SizedBox(),
        ),
      ),
    );
  }

  Widget _buildFixedHeader(BuildContext context, ShoppingController controller,
      CartController cartController) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10.w,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 53.h,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => controller.showCompanySelection(),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.business_rounded,
                                color: theme.colorScheme.primary,
                                size: 18.w,
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      ' Current Company',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Obx(() => Text(
                                          controller
                                              .selectedCompany.value.namePrint,
                                          style: TextStyle(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        )),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 20.sp,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Container(
                      width: 50.w,
                      height: 53.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12.r),
                          onTap: () => controller.toggleFilters(),
                          child: Icon(
                            Iconsax.search_normal_1,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Stack(
                      children: [
                        Container(
                          width: 50.w,
                          height: 55.h,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12.r),
                              onTap: () {
                                if (cartController.hasItems) {
                                  Get.toNamed(Routes.CART);
                                } else {
                                  _showEmptyCartDialog(context, theme);
                                }
                              },
                              child: Icon(
                                Iconsax.shopping_cart,
                                size: 18.sp,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        Obx(() => cartController.cartItemCount.value > 0
                            ? Positioned(
                                right: 4.w,
                                top: 4.h,
                                child: Container(
                                  padding: EdgeInsets.all(4.w),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    cartController.cartItemCount.value
                                        .toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink()),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmptyCartDialog(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 0.2.sw,
                height: 0.2.sw,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 0.1.sw,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Your cart is empty',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Add some amazing items to get started!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Continue Browsing',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(Get.context!);
                        controller.clearFilters();
                      },
                      icon: Icon(Icons.explore_outlined, size: 18.w),
                      label: Text(
                        'Explore',
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(
      BuildContext context, ShoppingController controller) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10.w,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: controller.searchController.value,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Iconsax.search_normal_1,
                        color: theme.colorScheme.primary),
                    suffixIcon:
                        Obx(() => controller.searchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.5)),
                                onPressed: () => controller.clearSearch(),
                              )
                            : const SizedBox.shrink()),
                    hintText: 'Search products...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () => _showFilterBottomSheet(context, controller),
                  child: Icon(
                    Iconsax.setting_4,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersChips(
      BuildContext context, ShoppingController controller) {
    final theme = Theme.of(context);

    return Obx(() {
      final hasFilters = controller.selectedGroup.value != 'All' ||
          controller.selectedCategory.value != 'All' ||
          controller.searchQuery.value.isNotEmpty;

      if (!hasFilters) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text(
                'Active:',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(width: 8.w),
              if (controller.selectedGroup.value != 'All')
                _buildFilterChip(
                  context,
                  controller.selectedGroup.value,
                  () => controller.filterByGroup('All'),
                ),
              if (controller.selectedCategory.value != 'All')
                _buildFilterChip(
                  context,
                  controller.selectedCategory.value,
                  () => controller.filterByCategory('All'),
                ),
              if (controller.searchQuery.value.isNotEmpty)
                _buildFilterChip(
                  context,
                  'Search: "${controller.searchQuery.value}"',
                  () => controller.clearSearch(),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFilterChip(
      BuildContext context, String label, VoidCallback onRemove) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(right: 8.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 4.w),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 16.w,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, CartController cartController,
      ShoppingController controller) {
    return Obx(() {
      if (controller.showShimmer.value && controller.allProducts.isEmpty) {
        return _buildShimmerState(context);
      }

      if (controller.isProductsLoading.value &&
          controller.allProducts.isEmpty) {
        return _buildLoadingState(context);
      }

      if (controller.filteredProducts.isEmpty) {
        return _buildEmptyState(context, controller);
      }

      return NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 100 &&
              !controller.isLoadMore.value &&
              controller.hasMore.value) {
            controller.loadMoreProducts();
          }
          return false;
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildModernCarouselSection(context, controller),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Products',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${controller.filteredProducts.length} products',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 6.w,
                  mainAxisSpacing: 8.h,
                  childAspectRatio: _getChildAspectRatio(context),
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == controller.filteredProducts.length &&
                        controller.hasMore.value) {
                      return _buildLoadMoreIndicator();
                    }
                    final product = controller.filteredProducts[index];
                    return _buildModernProductCard(
                        product, context, cartController, controller);
                  },
                  childCount: controller.filteredProducts.length +
                      (controller.hasMore.value ? 1 : 0),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Obx(() => controller.isLoadMore.value
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : const SizedBox.shrink()),
            ),
          ],
        ),
      );
    });
  }

  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    print('📱 SCREEN WIDTH: $screenWidth');
    print('🔄 Checking breakpoints...');

    if (screenWidth > 1200) {
      print('✅ DESKTOP: 4 columns');
      return 4; // Desktop
    }
    if (screenWidth > 800) {
      print('✅ TABLET: 3 columns');
      return 3; // Tablet
    }
    if (screenWidth > 600) {
      print('✅ LARGE MOBILE: 2 columns');
      return 2; // Large mobile
    }

    print('✅ SMALL MOBILE: 2 columns');
    return 2; // Small mobile
  }

  double _getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final crossAxisCount = _getCrossAxisCount(context);

    print('🎯 CROSS AXIS COUNT: $crossAxisCount');
    print(
        '📐 SCREEN DIMENSIONS: ${screenWidth.toStringAsFixed(1)} x ${screenHeight.toStringAsFixed(1)}');

    // Calculate screen aspect ratio
    final screenAspectRatio = screenWidth / screenHeight;
    print('📱 SCREEN ASPECT RATIO: ${screenAspectRatio.toStringAsFixed(2)}');

    // Calculate available space for cards
    final horizontalPadding = 12.w * 2;
    final crossAxisSpacing = 6.w * (crossAxisCount - 1);

    final availableWidth = screenWidth - horizontalPadding - crossAxisSpacing;
    final cardWidth = availableWidth / crossAxisCount;

    print('📏 CALCULATIONS:');
    print('   Available Width: $availableWidth');
    print('   Card Width: $cardWidth');

    double cardHeight;

    if (screenAspectRatio > 1.0) {
      cardHeight = cardWidth * 1.1;
      print('   Orientation: Landscape');
    } else {
      // Portrait orientation
      cardHeight = cardWidth * 1.3;
    }

    // Adjust based on screen size and column count
    if (crossAxisCount == 4) {
      cardHeight = cardWidth * 1.15;
    } else if (crossAxisCount == 3) {
      cardHeight = cardWidth * 1.25;
    } else {
      cardHeight = cardWidth * 1.80;
    }

    // Ensure minimum and maximum heights
    cardHeight = cardHeight.clamp(230.h, 300.h);

    final calculatedRatio = cardWidth / cardHeight;

    return calculatedRatio;
  }

  Widget _buildShimmerState(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildModernCarouselSection(
              context, Get.put(ShoppingController())),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 120.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                Container(
                  width: 80.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildShimmerGrid(context),
        ),
      ],
    );
  }

  Widget _buildShimmerGrid(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
      highlightColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 6.w,
          mainAxisSpacing: 8.h,
          childAspectRatio: _getChildAspectRatio(context),
        ),
        itemCount: 6,
        itemBuilder: (context, index) => _buildProductShimmer(context),
      ),
    );
  }

  Widget _buildProductShimmer(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(9.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15.w,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(9.r),
                topRight: Radius.circular(9.r),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        width: double.infinity,
                        height: 40.h,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernProductCard(Product product, BuildContext context,
      CartController cartController, ShoppingController shoppingController) {
    final theme = Theme.of(context);
    final discountPercentage =
        shoppingController.getDiscountPercentage(product.mrp, product.price);

    return GestureDetector(
      onTap: () {
        Get.toNamed(
          Routes.PRODUCT_DETAILS,
          arguments: {'productId': product.id},
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(9.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15.w,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(9.r),
                      topRight: Radius.circular(9.r),
                    ),
                  ),
                  child: product.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(9.r),
                            topRight: Radius.circular(9.r),
                          ),
                          child: Image.network(
                            product.images.first.fileUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildImagePlaceholder(theme),
                          ),
                        )
                      : _buildImagePlaceholder(theme),
                ),
                if (discountPercentage > 0)
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.red, Colors.orange],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${discountPercentage.toInt()}% OFF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          product.description,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.discount > 0)
                          Row(
                            children: [
                              Text(
                                '₹${product.mrp.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                '₹${product.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        SizedBox(height: 8.h),
                        _buildAddToCartButton(
                            product, shoppingController, cartController),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddToCartButton(Product product,
      ShoppingController shoppingController, CartController cartController) {
    final theme = Theme.of(Get.context!);

    return Obx(() {
      final isInCart = cartController.isProductInCart(product.id);
      final isLoading = shoppingController.isProductLoading(product.id);

      // Consistent height for all states
      final buttonHeight = 36.h;

      if (isLoading) {
        return Container(
          width: double.infinity,
          height: buttonHeight,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: SizedBox(
              width: 18.w,
              height: 18.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
          ),
        );
      }

      if (isInCart) {
        return Container(
          width: double.infinity,
          height: buttonHeight,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: Colors.green),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 14.w),
              SizedBox(width: 6.w),
              Text(
                'In Cart',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        );
      }

      return SizedBox(
        height: buttonHeight,
        width: double.infinity,
        child: CustomButton(
          textStyle: TextStyle(fontSize: 12.sp),
          text: 'Add to Cart',
          onPressed: () {
            shoppingController.addToCartWithLoading(
              productId: product.id,
              quantity: 1,
              onSuccess: () {
                ApptoastUtils.showSuccess('${product.name} added to cart');
              },
              onError: (error) {
                ApptoastUtils.showError('Failed to add to cart: $error');
              },
            );
          },
        ),
      );
    });
  }

  Widget _buildModernCarouselSection(
      BuildContext context, ShoppingController controller) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
      child: Stack(
        children: [
          Container(
            height: 180.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.r),
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.8),
                  theme.colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CarouselSlider(
              options: CarouselOptions(
                autoPlay: true,
                viewportFraction: 1,
                height: 180.h,
                autoPlayInterval: const Duration(seconds: 4),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                onPageChanged: (index, reason) {
                  controller.currentPage.value = index;
                },
              ),
              items: [1, 2].map((i) {
                return Container(
                  height: 0.18.h,
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    image: DecorationImage(
                      image: AssetImage("assets/download ($i).jpeg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Positioned(
            bottom: 12.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) {
                return Obx(() => Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      width: controller.currentPage.value == index ? 20.w : 6.w,
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: controller.currentPage.value == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ));
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCartBar(
      BuildContext context, CartController cartController) {
    final theme = Theme.of(context);

    return Container(
      height: 70.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15.w,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Items count container
                Container(
                  constraints: BoxConstraints(
                    minHeight: 40.h,
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_checkout,
                          color: theme.colorScheme.primary, size: 14.sp),
                      SizedBox(width: 6.w),
                      Obx(() => Text(
                            '${cartController.cartItemCount.value} items',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                              fontSize: 10.sp,
                            ),
                          )),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),

                // Expanded button
                Expanded(
                  child: SizedBox(
                    height: 40.h, // Explicit height for button
                    child: CustomButton(
                      textStyle: TextStyle(fontSize: 12.sp),
                      text: 'View Cart',
                      onPressed: () => Get.toNamed(Routes.CART),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: 16.h),
          Text(
            'Loading Products...',
            style: TextStyle(fontSize: 16.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ShoppingController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20.h),
          Icon(
            Icons.search_off_rounded,
            size: 60.w,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          SizedBox(height: 16.h),
          Obx(() => Text(
                controller.searchQuery.value.isNotEmpty
                    ? 'No products found for "${controller.searchQuery.value}"'
                    : 'No products found',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              )),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your filters or search terms',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 20.h),
          ElevatedButton.icon(
            onPressed: () => controller.clearFilters(),
            icon: Icon(Icons.refresh_rounded, size: 16.w),
            label: Text(
              'Clear Filters',
              style: TextStyle(fontSize: 12.sp),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 40.w,
        color: theme.colorScheme.primary.withOpacity(0.3),
      ),
    );
  }

  void _showFilterBottomSheet(
      BuildContext context, ShoppingController controller) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 0.7.sh,
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28.r),
            topRight: Radius.circular(28.r),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      controller.clearFilters();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterSection(
                      context: context,
                      label: 'Group',
                      controller: controller,
                      isGroup: true,
                    ),
                    SizedBox(height: 20.h),
                    _buildFilterSection(
                      context: context,
                      label: 'Category',
                      controller: controller,
                      isGroup: false,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.w),
              child: SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection({
    required BuildContext context,
    required String label,
    required ShoppingController controller,
    required bool isGroup,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 10.h),
        Obx(() {
          final items = isGroup
              ? controller.availableGroups
              : controller.availableCategories;
          final selectedValue = isGroup
              ? controller.selectedGroup.value
              : controller.selectedCategory.value;

          return Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: items.map((item) {
              final isSelected = selectedValue == item;
              return GestureDetector(
                onTap: () {
                  if (isGroup) {
                    controller.filterByGroup(item);
                  } else {
                    controller.filterByCategory(item);
                  }
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}
