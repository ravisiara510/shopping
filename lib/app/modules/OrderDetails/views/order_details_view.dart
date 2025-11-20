// order_details_view.dart
import 'package:eccomerce_app/app/custom/button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/order_details_controller.dart';

class OrderDetailsView extends GetView<OrderDetailsController> {
  const OrderDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Obx(() => Text(
              controller.showSearchBar.value ? 'Search Orders' : 'My Orders',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16.sp,
              ),
            )),
        actions: [
          // Search Toggle Button
          IconButton(
            onPressed: () {
              controller.showSearchBar.toggle();
              if (!controller.showSearchBar.value) {
                controller.clearSearch();
              }
            },
            icon: Obx(() => Icon(
                  controller.showSearchBar.value
                      ? Iconsax.close_circle
                      : Iconsax.search_normal,
                  size: 22.w,
                )),
          ),

          // Filter Button
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'date_range') {
                _showDateRangePicker(context);
              } else if (value == 'clear_filters') {
                controller.clearAllFilters();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date_range',
                child: Row(
                  children: [
                    Icon(Iconsax.calendar, size: 20.w),
                    SizedBox(width: 8.w),
                    Text('Date Range'),
                  ],
                ),
              ),
              if (controller.hasActiveFilters)
                PopupMenuItem(
                  value: 'clear_filters',
                  child: Row(
                    children: [
                      Icon(Iconsax.refresh, size: 20.w),
                      SizedBox(width: 8.w),
                      Text('Clear Filters'),
                    ],
                  ),
                ),
            ],
            icon: Icon(Iconsax.filter, size: 22.w),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Obx(() => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: controller.showSearchBar.value ? 80.h : 0,
                child: controller.showSearchBar.value
                    ? _buildSearchBar()
                    : const SizedBox(),
              )),

          Obx(() => controller.hasActiveFilters
              ? _buildFilterChips()
              : const SizedBox()),

          // Orders List
          Expanded(
            child: _buildOrderList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Obx(() => TextFormField(
              autofocus: true,
              controller: controller.searchController,
              onChanged: (value) {},
              decoration: InputDecoration(
                hintText: 'Search by order ID, customer, email, status...',
                hintStyle: TextStyle(fontSize: 14.sp),
                border: InputBorder.none,
                prefixIcon: Icon(Iconsax.search_normal, size: 20.w),
                suffixIcon: controller.searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: controller.clearSearch,
                        icon: Icon(Iconsax.close_circle, size: 20.w),
                      )
                    : null,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              ),
              style: TextStyle(fontSize: 14.sp),
            )),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Obx(() {
      if (controller.selectedDateRange.value == null &&
          controller.searchQuery.isEmpty) {
        return const SizedBox();
      }

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            if (controller.selectedDateRange.value != null)
              _buildFilterChip(
                label: controller.getDateRangeText(),
                onDeleted: controller.clearDateRange,
                icon: Iconsax.calendar,
              ),
            if (controller.searchQuery.isNotEmpty)
              _buildFilterChip(
                label: 'Search: ${controller.searchQuery.value}',
                onDeleted: controller.clearSearch,
                icon: Iconsax.search_normal,
              ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
    required IconData icon,
  }) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(fontSize: 11.sp),
      ),
      deleteIcon: Icon(Icons.close, size: 16.w),
      onDeleted: onDeleted,
      avatar: Icon(icon, size: 16.w),
      backgroundColor:
          Theme.of(Get.context!).colorScheme.primary.withOpacity(0.1),
    );
  }

  void _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().subtract(const Duration(days: 1)),
      currentDate: DateTime.now().subtract(const Duration(days: 1)),
      saveText: 'Apply',
      confirmText: 'Apply',
      cancelText: 'Cancel',
      helpText: 'Select Date Range',
      initialDateRange: controller.selectedDateRange.value,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setDateRange(picked);
    }
  }

  Widget _buildOrderList() {
    return Obx(() {
      if (controller.isLoading.value && controller.orders.isEmpty) {
        return _buildLoadingState();
      }

      if (controller.filteredOrders.isEmpty) {
        if (controller.orders.isEmpty) {
          return _buildEmptyState();
        } else {
          return _buildNoResultsState();
        }
      }

      return RefreshIndicator(
        onRefresh: controller.refreshOrders,
        backgroundColor: Theme.of(Get.context!).colorScheme.background,
        color: Theme.of(Get.context!).colorScheme.primary,
        strokeWidth: 3,
        child: Padding(
          padding: const EdgeInsetsGeometry.only(top: 10),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16.w,
              10.h,
              16.w,
              16.h,
            ),
            itemCount: controller.filteredOrders.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final order = controller.filteredOrders[index];
              return TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 300 + (index * 100)),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: _buildOrderCard(order),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
    });
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16.w,
        100.h,
        16.w,
        16.h,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + (index * 100)),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: _buildOrderShimmer(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOrderShimmer() {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(Get.context!).colorScheme.surface,
            Theme.of(Get.context!).colorScheme.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(140.w, 18.h),
              _shimmerBox(100.w, 22.h),
            ],
          ),
          SizedBox(height: 12.h),
          _shimmerBox(200.w, 13.h),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _shimmerBox(112.w, 13.h),
              _shimmerBox(88.w, 24.h),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shimmerBox(double width, double height) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(Get.context!)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.08 * value),
                Theme.of(Get.context!)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.15 * value),
                Theme.of(Get.context!)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.08 * value),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(8.r),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 160.w,
                    height: 160.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(Get.context!)
                              .colorScheme
                              .primary
                              .withOpacity(0.15),
                          Theme.of(Get.context!)
                              .colorScheme
                              .primary
                              .withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(Get.context!)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Iconsax.receipt_search,
                      size: 60.w,
                      color: Theme.of(Get.context!).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 32.h),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Column(
                    children: [
                      Text(
                        'No Orders Yet',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color:
                              Theme.of(Get.context!).colorScheme.onBackground,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'When you place orders, they will appear here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(Get.context!)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.6),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 32.h),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1000),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: FilledButton.icon(
                    onPressed: controller.fetchOrders,
                    icon: Icon(Iconsax.refresh, size: 20.w),
                    label: Text(
                      'Refresh',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(Get.context!).colorScheme.primary,
                      foregroundColor:
                          Theme.of(Get.context!).colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.w,
                        vertical: 16.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      elevation: 8,
                      shadowColor: Theme.of(Get.context!)
                          .colorScheme
                          .primary
                          .withOpacity(0.4),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 140.w,
                    height: 140.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(Get.context!)
                              .colorScheme
                              .primary
                              .withOpacity(0.15),
                          Theme.of(Get.context!)
                              .colorScheme
                              .primary
                              .withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(Get.context!)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Iconsax.search_status,
                      size: 50.w,
                      color: Theme.of(Get.context!).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 32.h),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Column(
                    children: [
                      Text(
                        'No Orders Found',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color:
                              Theme.of(Get.context!).colorScheme.onBackground,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Try adjusting your search or filters',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(Get.context!)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.6),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 32.h),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1000),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: FilledButton.icon(
                    onPressed: controller.clearAllFilters,
                    icon: Icon(Iconsax.refresh, size: 20.w),
                    label: Text(
                      'Clear Filters',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(Get.context!).colorScheme.primary,
                      foregroundColor:
                          Theme.of(Get.context!).colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.w,
                        vertical: 16.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      elevation: 8,
                      shadowColor: Theme.of(Get.context!)
                          .colorScheme
                          .primary
                          .withOpacity(0.4),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          colors: [
            Theme.of(Get.context!).colorScheme.surface,
            Theme.of(Get.context!).colorScheme.surface.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            controller.selectOrder(order);
            _showOrderDetails();
          },
          borderRadius: BorderRadius.circular(24.r),
          splashColor:
              Theme.of(Get.context!).colorScheme.primary.withOpacity(0.05),
          highlightColor:
              Theme.of(Get.context!).colorScheme.primary.withOpacity(0.03),
          child: Padding(
            padding: EdgeInsets.all(18.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 5.h,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(Get.context!)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.15),
                                      Theme.of(Get.context!)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.08),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  '#${order['orderCode'] ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(Get.context!)
                                        .colorScheme
                                        .primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          // Customer Name
                          if (order['customerId'] != null &&
                              order['customerId']['customerName'] != null)
                            Text(
                              order['customerId']['customerName'],
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(Get.context!)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.8),
                              ),
                            ),
                          SizedBox(height: 4.h),
                          Text(
                            controller
                                .formatDateShort(order['createdAt'] ?? ''),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Theme.of(Get.context!)
                                  .colorScheme
                                  .onBackground
                                  .withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            controller
                                .getOrderStatusColor(order['status'] ?? '')
                                .withOpacity(0.15),
                            controller
                                .getOrderStatusColor(order['status'] ?? '')
                                .withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: controller
                              .getOrderStatusColor(order['status'] ?? '')
                              .withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6.w,
                            height: 6.w,
                            decoration: BoxDecoration(
                              color: controller
                                  .getOrderStatusColor(order['status'] ?? ''),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            controller
                                .getOrderStatusText(order['status'] ?? ''),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: controller
                                  .getOrderStatusColor(order['status'] ?? ''),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(Get.context!)
                            .colorScheme
                            .primary
                            .withOpacity(0.08),
                        Theme.of(Get.context!)
                            .colorScheme
                            .primary
                            .withOpacity(0.03),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Theme.of(Get.context!)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹${order['grandTotal']?.toStringAsFixed(2) ?? '0.00'}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(Get.context!).colorScheme.primary,
                          letterSpacing: -0.5,
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
    );
  }

  void _showOrderDetails() {
    showModalBottomSheet(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(Get.context!).size.width,
      ),
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOrderDetailsSheet(),
    );
  }

  Widget _buildOrderDetailsSheet() {
    return Obx(() {
      if (controller.selectedOrder.isEmpty) return const SizedBox();

      final order = controller.selectedOrderMap;

      return Container(
        constraints: BoxConstraints(
          maxHeight: 0.92.sh,
        ),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            _buildSheetHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderOverview(order),
                    SizedBox(height: 16.h),
                    _buildCustomerInfo(order),
                    SizedBox(height: 16.h),
                    _buildOrderItems(order),
                    SizedBox(height: 16.h),
                    _buildShippingAddress(order),
                    SizedBox(height: 16.h),
                    _buildPaymentDetails(order),
                    SizedBox(height: 16.h),
                    _buildOrderSummary(order),
                    SizedBox(height: 16.h),
                    Obx(() {
                      final order = controller.selectedOrderMap;
                      final items = order['items'] as List<dynamic>? ?? [];

                      return Column(
                        children: [
                          CustomButton(
                            text: 'Order Again',
                            onPressed: () => controller.orderAgain(),
                          ),
                          if (items.isNotEmpty) ...[
                            SizedBox(height: 8.h),
                            Text(
                              '${items.length} item${items.length > 1 ? 's' : ''} will be added to your cart',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Theme.of(Get.context!)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                          SizedBox(height: 16.h),
                        ],
                      );
                    }),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSheetHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        12.h,
        16.w,
        16.h,
      ),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48.w,
            height: 4.h,
            decoration: BoxDecoration(
              color:
                  Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Details',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Row(
                children: [
                  // Share Button
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(Get.context!)
                          .colorScheme
                          .surface
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: IconButton(
                      onPressed: _showShareOptions,
                      icon: Icon(Iconsax.share, size: 22.w),
                      color: Theme.of(Get.context!).colorScheme.primary,
                      tooltip: 'Share Order Details',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Close Button
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(Get.context!)
                          .colorScheme
                          .surface
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: IconButton(
                      onPressed: () {
                        if (Navigator.of(Get.context!).canPop()) {
                          Navigator.of(Get.context!).pop();
                        }
                      },
                      icon: Icon(Iconsax.close_circle, size: 22.w),
                      color: Theme.of(Get.context!)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderOverview(Map<String, dynamic> order) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(Get.context!).colorScheme.primary.withOpacity(0.08),
            Theme.of(Get.context!).colorScheme.primary.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORDER',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Theme.of(Get.context!)
                          .colorScheme
                          .primary
                          .withOpacity(0.6),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '#${order['orderCode'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(Get.context!).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: controller
                      .getOrderStatusColor(order['status'] ?? '')
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: controller
                        .getOrderStatusColor(order['status'] ?? '')
                        .withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      controller.getOrderStatusIcon(order['status'] ?? ''),
                      size: 18.w,
                      color:
                          controller.getOrderStatusColor(order['status'] ?? ''),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      controller.getOrderStatusText(order['status'] ?? ''),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: controller
                            .getOrderStatusColor(order['status'] ?? ''),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Invoice', order['InvoiceNumber'] ?? 'N/A'),
                    _buildDetailRow('Date',
                        controller.formatDate(order['createdAt'] ?? '')),
                    if (order['TallyTransactionID'] != null)
                      _buildDetailRow(
                          'Transaction', order['TallyTransactionID']!),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfo(Map<String, dynamic> order) {
    final customer = order['customerId'] ?? {};
    final customerName = customer['customerName'] ?? 'N/A';
    final contactPerson = customer['contactPerson'] ?? 'N/A';
    final emailAddress = customer['emailAddress'] ?? 'N/A';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(Get.context!)
                          .colorScheme
                          .primary
                          .withOpacity(0.15),
                      Theme.of(Get.context!)
                          .colorScheme
                          .primary
                          .withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Iconsax.profile_circle,
                  size: 20.w,
                  color: Theme.of(Get.context!).colorScheme.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Customer Information',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildCustomerDetailRow('Customer Name', customerName),
          _buildCustomerDetailRow('Contact Person', contactPerson),
          _buildCustomerDetailRow('Email Address', emailAddress),
        ],
      ),
    );
  }

  Widget _buildCustomerDetailRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11.sp,
                color: Theme.of(Get.context!)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: Theme.of(Get.context!).colorScheme.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(Get.context!)
                          .colorScheme
                          .primary
                          .withOpacity(0.15),
                      Theme.of(Get.context!)
                          .colorScheme
                          .primary
                          .withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Iconsax.shopping_bag,
                  size: 20.w,
                  color: Theme.of(Get.context!).colorScheme.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Items (${items.length})',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                _buildOrderItem(item),
                if (index < items.length - 1)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Divider(
                      color: Theme.of(Get.context!)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.08),
                      thickness: 1,
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56.w,
          height: 56.w,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(Get.context!).colorScheme.primary.withOpacity(0.15),
                Theme.of(Get.context!).colorScheme.primary.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Icon(
            Iconsax.box_1,
            size: 28.w,
            color: Theme.of(Get.context!).colorScheme.primary,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product ${item['productId']?.toString().substring(0, 8) ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '${item['quantity']} × ₹${item['price']?.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Theme.of(Get.context!)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 8.h,
          ),
          decoration: BoxDecoration(
            color: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            '₹${item['total']?.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: Theme.of(Get.context!).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShippingAddress(Map<String, dynamic> order) {
    final address = order['shippingAddress'] ?? {};

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(Get.context!)
                          .colorScheme
                          .primary
                          .withOpacity(0.15),
                      Theme.of(Get.context!)
                          .colorScheme
                          .primary
                          .withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Iconsax.location,
                  size: 20.w,
                  color: Theme.of(Get.context!).colorScheme.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Shipping Address',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildAddressRow(address),
        ],
      ),
    );
  }

  Widget _buildAddressRow(Map<String, dynamic> address) {
    final street = address['street'] ?? '';
    final line2 = address['line2'] ?? '';
    final city = address['city'] ?? '';
    final state = address['state'] ?? '';
    final postalCode = address['postalCode'] ?? '';
    final country = address['country'] ?? '';

    final fullAddress = [street, line2, '$city, $state', postalCode, country]
        .where((part) => part.isNotEmpty)
        .join('\n');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).colorScheme.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Iconsax.map_1,
            size: 20.w,
            color: Theme.of(Get.context!).colorScheme.primary,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              fullAddress.isEmpty ? 'No address provided' : fullAddress,
              style: TextStyle(
                fontSize: 11.sp,
                height: 1.6,
                color: Theme.of(Get.context!)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(Map<String, dynamic> order) {
    final payment = order['payment'] ?? {};

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(Get.context!)
                          .colorScheme
                          .primary
                          .withOpacity(0.15),
                      Theme.of(Get.context!)
                          .colorScheme
                          .primary
                          .withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Iconsax.card,
                  size: 20.w,
                  color: Theme.of(Get.context!).colorScheme.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Payment Details',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildDetailRow(
            'Payment Mode',
            (payment['mode']?.toString() ?? 'N/A').toUpperCase(),
          ),
          _buildDetailRow('Status', payment['status'] ?? 'N/A'),
          if (payment['transactionId'] != null)
            _buildDetailRow('Transaction ID', payment['transactionId']!),
          _buildDetailRow(
            'Payment Date',
            controller.formatDate(payment['date'] ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final subtotal = controller.calculateSubtotal(items);
    final discount = order['discount'] ?? 0;
    final tax = order['tax'] ?? 0;
    final grandTotal = order['grandTotal'] ?? 0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(Get.context!).colorScheme.primary.withOpacity(0.08),
            Theme.of(Get.context!).colorScheme.primary.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Theme.of(Get.context!)
                      .colorScheme
                      .primary
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Iconsax.receipt_2,
                  size: 20.w,
                  color: Theme.of(Get.context!).colorScheme.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildSummaryRow('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
          if (discount > 0)
            _buildSummaryRow('Discount', '-₹${discount.toStringAsFixed(2)}',
                isDiscount: true),
          if (tax > 0) _buildSummaryRow('Tax', '+₹${tax.toStringAsFixed(2)}'),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Divider(
              color:
                  Theme.of(Get.context!).colorScheme.primary.withOpacity(0.2),
              thickness: 1.5,
            ),
          ),
          _buildSummaryRow(
            'Grand Total',
            '₹${grandTotal.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11.sp,
              color:
                  Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 16.w),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: Theme.of(Get.context!).colorScheme.onSurface,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    String value, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: isTotal
                ? TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  )
                : TextStyle(
                    fontSize: 11.sp,
                    color: Theme.of(Get.context!)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
          ),
          Text(
            value,
            style: isTotal
                ? TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(Get.context!).colorScheme.primary,
                    letterSpacing: -0.5,
                  )
                : TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: isDiscount
                        ? Colors.green
                        : Theme.of(Get.context!).colorScheme.onSurface,
                  ),
          ),
        ],
      ),
    );
  }

  // ... (Keep all the share functionality methods from your original code)
  // They should remain exactly as they were

  String _createShareableContent(Map<String, dynamic> order) {
    // Your original share content creation code
    final customer = order['customerId'] ?? {};
    final items = order['items'] as List<dynamic>? ?? [];
    final payment = order['payment'] ?? {};
    final address = order['shippingAddress'] ?? {};

    final subtotal = controller.calculateSubtotal(items);
    final discount = order['discount'] ?? 0;
    final tax = order['tax'] ?? 0;
    final grandTotal = order['grandTotal'] ?? 0;
    final totalItems = controller.calculateTotalItems(items);

    StringBuffer content = StringBuffer();

    // Header
    content.writeln('🛒 ORDER RECEIPT');
    content.writeln('=' * 50);
    content.writeln();

    // Order Information
    content.writeln('📋 ORDER INFORMATION');
    content.writeln('─' * 30);
    content.writeln('Order ID:    #${order['orderCode'] ?? 'N/A'}');
    content.writeln(
        'Date:        ${controller.formatDate(order['createdAt'] ?? '')}');
    content.writeln(
        'Status:      ${controller.getOrderStatusText(order['status'] ?? '')}');
    if (order['InvoiceNumber'] != null) {
      content.writeln('Invoice:     ${order['InvoiceNumber']}');
    }
    content.writeln();

    // Customer Information
    content.writeln('👤 CUSTOMER DETAILS');
    content.writeln('─' * 30);
    content.writeln('Name:    ${customer['customerName'] ?? 'N/A'}');
    content.writeln('Contact: ${customer['contactPerson'] ?? 'N/A'}');
    content.writeln('Email:   ${customer['emailAddress'] ?? 'N/A'}');
    content.writeln();

    // Order Items
    content.writeln('📦 ORDER ITEMS ($totalItems items)');
    content.writeln('─' * 40);
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      content.writeln('${i + 1}. Product: ${item['productId'] ?? 'N/A'}');
      content.writeln(
          '   Quantity: ${item['quantity']} × ₹${item['price']?.toStringAsFixed(2)}');
      content.writeln('   Total:    ₹${item['total']?.toStringAsFixed(2)}');
      content.writeln();
    }

    // Shipping Address
    content.writeln('📍 SHIPPING ADDRESS');
    content.writeln('─' * 30);
    final street = address['street'] ?? '';
    final line2 = address['line2'] ?? '';
    final city = address['city'] ?? '';
    final state = address['state'] ?? '';
    final postalCode = address['postalCode'] ?? '';
    final country = address['country'] ?? '';

    final fullAddress = [street, line2, '$city, $state', postalCode, country]
        .where((part) => part.isNotEmpty)
        .join('\n           ');

    content.writeln(fullAddress.isEmpty ? 'No address provided' : fullAddress);
    content.writeln();

    // Payment Details
    content.writeln('💳 PAYMENT INFORMATION');
    content.writeln('─' * 30);
    content.writeln(
        'Mode:     ${(payment['mode']?.toString() ?? 'N/A').toUpperCase()}');
    content.writeln('Status:   ${payment['status'] ?? 'N/A'}');
    if (payment['transactionId'] != null) {
      content.writeln('Txn ID:   ${payment['transactionId']!}');
    }
    if (payment['date'] != null) {
      content.writeln('Date:     ${controller.formatDate(payment['date'])}');
    }
    content.writeln();

    // Order Summary
    content.writeln('💰 ORDER SUMMARY');
    content.writeln('─' * 30);
    content.writeln('Subtotal:      ₹${subtotal.toStringAsFixed(2)}');
    if (discount > 0) {
      content.writeln('Discount:      -₹${discount.toStringAsFixed(2)}');
    }
    if (tax > 0) {
      content.writeln('Tax:           +₹${tax.toStringAsFixed(2)}');
    }
    content.writeln('─' * 30);
    content.writeln('GRAND TOTAL:   ₹${grandTotal.toStringAsFixed(2)}');
    content.writeln();
    content.writeln('=' * 50);
    content.writeln('Thank you for your order!');

    return content.toString();
  }

  void _showShareOptions() {
    final order = controller.selectedOrderMap;
    final shareContent = _createShareableContent(order);

    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share Options',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 16.h),

            // WhatsApp
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Iconsax.message, size: 20.w, color: Colors.green),
              ),
              title: const Text('WhatsApp'),
              subtitle: const Text('Share via WhatsApp'),
              onTap: () {
                Navigator.pop(context);
                _shareToWhatsApp();
              },
            ),

            // Message
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Iconsax.message, size: 20.w, color: Colors.blue),
              ),
              title: const Text('Message'),
              subtitle: const Text('Share via SMS/Message'),
              onTap: () {
                Navigator.pop(context);
                _shareToMessage();
              },
            ),

            // Other Apps
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Iconsax.share,
                    size: 20.w, color: Theme.of(context).colorScheme.primary),
              ),
              title: const Text('Other Apps'),
              subtitle: const Text('Share via other applications'),
              onTap: () {
                Navigator.pop(context);
                _shareToOtherApps();
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Iconsax.document_download,
                    size: 20.w, color: Colors.pink),
              ),
              title: const Text('Download Invoice'),
              subtitle: const Text('Export & share with others'),
              onTap: () {
                Navigator.pop(context);
                controller.downloadInvoicePdf();
              },
            ),

            // Copy to Clipboard
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Iconsax.copy, size: 20.w, color: Colors.orange),
              ),
              title: const Text('Copy to Clipboard'),
              subtitle: const Text('Copy order details to clipboard'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: shareContent));

                Navigator.pop(context);
              },
            ),

            SizedBox(height: 8.h),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _shareToWhatsApp() async {
    try {
      final order = controller.selectedOrderMap;
      if (order.isEmpty) return;

      final shareContent = _createShareableContent(order);
      final encodedContent = Uri.encodeComponent(shareContent);
      final whatsappUrl = "whatsapp://send?text=$encodedContent";

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
      } else {
        await Share.share(
          shareContent,
          subject: 'Order Details - #${order['orderCode'] ?? ''}',
        );
      }
    } catch (e) {
      _shareToOtherApps();
    }
  }

  void _shareToMessage() async {
    try {
      final order = controller.selectedOrderMap;
      if (order.isEmpty) return;

      final shareContent = _createShareableContent(order);
      final encodedContent = Uri.encodeComponent(shareContent);
      final smsUrl = "sms:?body=$encodedContent";

      if (await canLaunchUrl(Uri.parse(smsUrl))) {
        await launchUrl(Uri.parse(smsUrl));
      } else {
        await Share.share(
          shareContent,
          subject: 'Order Details - #${order['orderCode'] ?? ''}',
        );
      }
    } catch (e) {
      _shareToOtherApps();
    }
  }

  void _shareToOtherApps() async {
    try {
      final order = controller.selectedOrderMap;
      if (order.isEmpty) return;

      final shareContent = _createShareableContent(order);

      await Share.share(
        shareContent,
        subject: 'Order Details - #${order['orderCode'] ?? ''}',
      );
    } catch (e) {
      _showShareFallbackDialog();
    }
  }

  void _showShareFallbackDialog() {
    final order = controller.selectedOrderMap;
    final shareContent = _createShareableContent(order);

    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: Text(
          'Order Details',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              shareContent,
              style: TextStyle(
                fontSize: 11.sp,
                fontFamily: 'Monospace',
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: shareContent));
              ScaffoldMessenger.of(Get.context!).showSnackBar(
                const SnackBar(
                  content: Text('Order details copied to clipboard!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Copy to Clipboard'),
          ),
        ],
      ),
    );
  }
}
