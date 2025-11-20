import 'dart:io';
import 'package:eccomerce_app/app/core/data/sharedPre.dart';
import 'package:eccomerce_app/app/core/utils/appString/app_storage_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/utils/logger.dart';
import '../../../services/toast_service.dart';
import '../../Customer/controllers/customer_controller.dart';
import '../controllers/payment_management_controller.dart';

class PaymentManagementView extends GetView<PaymentManagementController> {
  const PaymentManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            title: Text(
              'Payment Management',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Iconsax.refresh, size: 18.w),
                onPressed: () {
                  final CustomerController customerController =
                      Get.put(CustomerController());
                  controller.fetchPayments();
                  customerController.fetchCustomers();
                },
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: Obx(() => controller.selectedPayment.isEmpty
              ? _buildPaymentList(context)
              : _buildPaymentDetails(context)),
          floatingActionButton: _buildFloatingActionButton(context),
        );
      },
    );
  }

  Widget _buildPaymentList(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingPayments.value) {
        return _buildLoadingState(context);
      }

      if (controller.payments.isEmpty) {
        return _buildEmptyState(context);
      }

      return RefreshIndicator(
        onRefresh: () => controller.fetchPayments(),
        child: ListView.builder(
          padding: EdgeInsets.all(12.w),
          itemCount: controller.payments.length,
          itemBuilder: (context, index) {
            final payment = controller.payments[index];
            return _buildPaymentCard(context, payment);
          },
        ),
      );
    });
  }

  Widget _buildPaymentCard(BuildContext context, Map<String, dynamic> payment) {
    final theme = Theme.of(context);
    final amount = payment['amount']?.toString() ?? '0';
    final method = payment['mode'] ?? 'cash';
    final status = payment['status'] ?? 'initiated';
    final date = payment['createdAt'] ?? '';
    final remarks = payment['remarks'] ?? '';

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () => controller.selectPayment(payment),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹$amount',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: controller.getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: controller.getStatusColor(status),
                      ),
                    ),
                    child: Text(
                      controller.getPaymentStatusDisplay(status),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: controller.getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(
                    Iconsax.wallet,
                    size: 14.w,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    controller.getPaymentMethodDisplayName(method),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Iconsax.calendar,
                    size: 14.w,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
              if (remarks.isNotEmpty) ...[
                SizedBox(height: 6.h),
                Text(
                  remarks,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 10.sp,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 6.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tap to view details',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
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

  Widget _buildPaymentDetails(BuildContext context) {
    final theme = Theme.of(context);
    final payment = controller.selectedPayment;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Payment Details',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Platform.isIOS
              ? Icon(Icons.arrow_back_ios_new_outlined, size: 18.w)
              : Icon(Iconsax.arrow_left, size: 18.w),
          onPressed: () => controller.clearSelectedPayment(),
        ),
        actions: [
          IconButton(
            icon: Icon(Iconsax.share, size: 18.w),
            onPressed: () => _sharePaymentDetails(payment),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(8.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    Text(
                      'Payment Amount',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary.withOpacity(0.8),
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '₹${payment['amount'] ?? '0'}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onPrimary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        controller.getPaymentStatusDisplay(
                            payment['status'] ?? 'initiated'),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8.h),

            // Payment Information
            Text(
              'Payment Information',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onBackground,
              ),
            ),
            SizedBox(height: 12.h),
            _buildDetailCard(
              context,
              [
                _buildDetailItem(
                  context,
                  Iconsax.receipt,
                  'Payment ID',
                  payment['_id'] ?? 'N/A',
                ),
                _buildDetailItem(
                  context,
                  Iconsax.wallet,
                  'Payment Method',
                  controller
                      .getPaymentMethodDisplayName(payment['mode'] ?? 'cash'),
                ),
                _buildDetailItem(
                  context,
                  Iconsax.calendar,
                  'Created Date',
                  _formatDate(payment['createdAt'] ?? ''),
                ),
                _buildDetailItem(
                  context,
                  Iconsax.calendar_tick,
                  'Updated Date',
                  _formatDate(payment['updatedAt'] ?? ''),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Remarks
            if (payment['remarks'] != null &&
                payment['remarks'].isNotEmpty) ...[
              Text(
                'Remarks',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onBackground,
                ),
              ),
              SizedBox(height: 6.h),
              _buildDetailCard(
                context,
                [
                  Padding(
                    padding: EdgeInsets.all(10.w),
                    child: Text(
                      payment['remarks'],
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 12.sp,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
            ],

            // Documents
            if (payment['documents'] != null &&
                payment['documents'].isNotEmpty) ...[
              Text(
                'Supporting Documents',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onBackground,
                ),
              ),
              SizedBox(height: 6.h),
              _buildDocumentsSection(context, payment['documents']),
              SizedBox(height: 8.h),
            ],

            Text(
              'Additional Information',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onBackground,
              ),
            ),
            SizedBox(height: 12.h),
            _buildDetailCard(
              context,
              [
                _buildDetailItem(
                  context,
                  Iconsax.building,
                  'Company ID',
                  payment['companyId'] ?? 'N/A',
                ),
                _buildDetailItem(
                  context,
                  Iconsax.profile_circle,
                  'Customer ID',
                  payment['customerId'] ?? 'N/A',
                ),
                _buildDetailItem(
                  context,
                  Iconsax.user,
                  'User ID',
                  payment['userId'] ?? 'N/A',
                ),
                _buildDetailItem(
                  context,
                  Iconsax.receipt_item,
                  'Order ID',
                  payment['orderId'] ?? 'N/A',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDetailItem(
      BuildContext context, IconData icon, String title, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16.w,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(BuildContext context, List<dynamic> documents) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: documents.map((docUrl) {
        final fileName = _getFileNameFromUrl(docUrl.toString());
        final isImage = _isImageFile(fileName);

        return GestureDetector(
          onTap: () => _openDocument(docUrl.toString()),
          child: Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: theme.colorScheme.surface,
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isImage ? Iconsax.gallery : Iconsax.document,
                  size: 20.w,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(height: 2.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Text(
                    fileName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 8.sp,
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      return pathSegments.isNotEmpty ? pathSegments.last : 'Document';
    } catch (e) {
      return 'Document';
    }
  }

  bool _isImageFile(String fileName) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final lowerFileName = fileName.toLowerCase();
    return imageExtensions.any((ext) => lowerFileName.endsWith(ext));
  }

  void _openDocument(String url) {
    ApptoastUtils.showInfo('Opening: ${_getFileNameFromUrl(url)}');
  }

  void _sharePaymentDetails(Map<String, dynamic> payment) {
    ApptoastUtils.showInfo('Sharing payment details');
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
          SizedBox(height: 12.h),
          Text(
            'Loading payments...',
            style: TextStyle(
              fontSize: 12.sp,
              color: theme.colorScheme.onBackground.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.receipt_add,
              size: 32.w,
              color: theme.colorScheme.primary,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            'No Payments Yet',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onBackground,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Start by adding your first payment record\nTap the + button below to begin',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              color: theme.colorScheme.onBackground.withOpacity(0.6),
              height: 1.4,
            ),
          ),
          SizedBox(height: 6.h),
          Container(
            width: 40.w,
            height: 3.h,
            margin: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),
          _buildFeatureGrid(context),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final theme = Theme.of(context);
    final features = [
      {'icon': Iconsax.security_safe, 'text': 'Secure Payments'},
      {'icon': Iconsax.receipt_discount, 'text': 'Multiple Methods'},
      {'icon': Iconsax.document_upload, 'text': 'Document Upload'},
      {'icon': Iconsax.chart_success, 'text': 'Easy Tracking'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.6,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                features[index]['icon'] as IconData,
                size: 20.w,
                color: theme.colorScheme.primary,
              ),
              SizedBox(height: 6.h),
              Text(
                features[index]['text'] as String,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final theme = Theme.of(context);

    return FloatingActionButton(
      onPressed: () => _showModernPaymentSheet(context),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(Iconsax.add, size: 18.w),
      ),
    );
  }

  void _showModernPaymentSheet(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final customerController = Get.put(CustomerController());

    showModalBottomSheet(
      constraints: BoxConstraints(maxWidth: double.infinity),
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: size.height * 0.85,
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          children: [
            // Header with drag handle
            Container(
              padding: EdgeInsets.all(12.w),
              child: Column(
                children: [
                  Container(
                    width: 32.w,
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Icon(
                        Iconsax.receipt_add,
                        color: theme.colorScheme.primary,
                        size: 18.w,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'New Payment',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Iconsax.close_circle,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          size: 18.w,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    _buildCustomerSection(context, customerController),
                    SizedBox(height: 16.h),
                    _buildPaymentMethodSection(context),
                    SizedBox(height: 16.h),
                    _buildAmountSection(context),
                    SizedBox(height: 16.h),
                    _buildRemarksSection(context),
                    SizedBox(height: 16.h),
                    _buildDocumentSection(context),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            // Footer with submit button
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(() => ElevatedButton(
                          onPressed: controller.canSubmit.value &&
                                  !controller.isLoading.value
                              ? () => _submitPayment(customerController)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            elevation: 0,
                          ),
                          child: controller.isLoading.value
                              ? SizedBox(
                                  width: 18.w,
                                  height: 18.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Iconsax.send_2, size: 16.w),
                                    SizedBox(width: 6.w),
                                    Text(
                                      'Submit Payment',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitPayment(CustomerController customerController) async {
    final selectedCustomerId = controller.selectedCustomer.value;

    if (selectedCustomerId.isEmpty) {
      ApptoastUtils.showError('Please select a customer');
      return;
    }

    final selectedCustomer = customerController.customers.firstWhere(
      (customer) => customer['_id'] == selectedCustomerId,
      orElse: () => {},
    );

    if (selectedCustomer.isEmpty) {
      ApptoastUtils.showError('Invalid customer selected');
      return;
    }

    final customerData = {
      'companyId': SharedpreferenceUtil.getString(AppStorage.selectedCompanyId),
      'customerId': selectedCustomerId,
      'customerName': selectedCustomer['customerName'] ?? 'Unknown Customer',
    };

    await controller.submitPayment(customerData);
  }

  Widget _buildCustomerSection(
      BuildContext context, CustomerController customerController) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.profile_circle,
              size: 16.w,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: 6.w),
            Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onBackground,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Obx(() {
          if (customerController.isLoading.value) {
            return Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Loading customers...',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          if (customerController.customers.isEmpty) {
            return Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Iconsax.profile_remove,
                    size: 24.w,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'No customers found',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Add customers first to process payments',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: controller.selectedCustomer.value.isEmpty
                    ? null
                    : controller.selectedCustomer.value,
                hint: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Text(
                    'Select a customer...',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                items: [
                  ...customerController.customers.map((customer) {
                    final customerId = customer['_id'] ?? '';
                    final customerName = customer['customerName'] ?? 'Unknown';
                    final customerEmail = customer['customerEmail'] ?? '';

                    return DropdownMenuItem<String>(
                      value: customerId,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              customerName,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            if (customerEmail.isNotEmpty) ...[
                              SizedBox(height: 2.h),
                              Text(
                                customerEmail,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  if (value != null) {
                    controller.selectedCustomer.value = value;
                  }
                },
                dropdownColor: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12.r),
                icon: Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: Icon(
                    Iconsax.arrow_down_1,
                    color: theme.colorScheme.onSurface,
                    size: 16.w,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.wallet,
              size: 16.w,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: 6.w),
            Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onBackground,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Obx(() => Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: controller.paymentMethods.map((method) {
                final isSelected =
                    controller.selectedPaymentMethod.value == method;
                return GestureDetector(
                  onTap: () => controller.selectedPaymentMethod.value = method,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withOpacity(0.2),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected ? Iconsax.tick_circle : Icons.circle,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.4),
                          size: 16.w,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          controller.getPaymentMethodDisplayName(method),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            )),
      ],
    );
  }

  Widget _buildAmountSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.money,
              size: 16.w,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: 6.w),
            Text(
              'Payment Amount',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onBackground,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: TextFormField(
            controller: controller.amountController,
            onChanged: (value) => controller.validateAmount(value),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(
                fontSize: 16.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 14.h,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: 12.w),
                child: Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: 24.w,
              ),
              errorText: controller.amountError.value.isEmpty
                  ? null
                  : controller.amountError.value,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemarksSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.note_text,
              size: 16.w,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: 6.w),
            Text(
              'Remarks (Optional)',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onBackground,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: TextFormField(
            controller: controller.remarksController,
            maxLines: 3,
            style: TextStyle(
              fontSize: 12.sp,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Add any additional remarks...',
              hintStyle: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(12.w),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.document_upload,
              size: 16.w,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: 6.w),
            Text(
              'Supporting Documents',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onBackground,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Obx(() => Column(
              children: [
                if (controller.uploadedFiles.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Iconsax.document,
                          size: 24.w,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'No documents added',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      ...controller.uploadedFiles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;
                        final fileName = file.path.split('/').last;
                        final isImage = _isImageFile(fileName);

                        return GestureDetector(
                          onTap: () => _showDocumentPreview(
                              context, file, fileName, isImage),
                          child: Stack(
                            children: [
                              Container(
                                width: 50.w,
                                height: 50.w,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: theme.colorScheme.outline
                                        .withOpacity(0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: isImage
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                        child: Image.file(
                                          file,
                                          width: 50.w,
                                          height: 50.w,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return _buildFileIcon(
                                                theme, fileName);
                                          },
                                        ),
                                      )
                                    : _buildFileIcon(theme, fileName),
                              ),
                              Positioned(
                                top: -4,
                                right: -4,
                                child: GestureDetector(
                                  onTap: () => controller.removeFile(index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.error,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.all(4.w),
                                    child: Icon(
                                      Icons.close,
                                      color: theme.colorScheme.onError,
                                      size: 10.w,
                                    ),
                                  ),
                                ),
                              ),
                              // File name overlay for non-image files
                              if (!isImage)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 2.w,
                                      vertical: 1.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(8.r),
                                        bottomRight: Radius.circular(8.r),
                                      ),
                                    ),
                                    child: Text(
                                      _getFileExtension(fileName).toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 6.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      _buildAddDocumentButton(context),
                    ],
                  ),
                SizedBox(height: 8.h),
                _buildUploadOptions(context),
              ],
            )),
      ],
    );
  }

  Widget _buildAddDocumentButton(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: 50.w,
        height: 50.w,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.add,
              color: theme.colorScheme.primary,
              size: 16.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 8.sp,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Method to show document preview
  void _showDocumentPreview(
      BuildContext context, File file, String fileName, bool isImage) {
    final theme = Theme.of(context);

    if (isImage) {
      // Show image in full screen dialog
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(20.w),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  color: Colors.black87,
                ),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Center(
                    child: Image.file(
                      file,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.gallery_slash,
                              size: 40.w,
                              color: Colors.white54,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Failed to load image',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 20.h,
                right: 20.w,
                child: IconButton(
                  icon: Icon(
                    Iconsax.close_circle,
                    size: 24.w,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Positioned(
                bottom: 20.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      fileName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Show file info dialog for non-image files
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: theme.colorScheme.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(
                Iconsax.document,
                color: theme.colorScheme.primary,
                size: 20.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Document Info',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFileInfoItem('File Name', fileName),
              SizedBox(height: 8.h),
              _buildFileInfoItem(
                  'File Type', _getFileExtension(fileName).toUpperCase()),
              SizedBox(height: 8.h),
              _buildFileInfoItem('File Path', file.path),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: [
                    Icon(
                      _getFileIcon(fileName),
                      size: 32.w,
                      color: theme.colorScheme.primary,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'This file cannot be previewed in the app',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // You can add functionality to open the file with external app
                _openFileWithExternalApp(file);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: Text(
                'Open File',
                style: TextStyle(fontSize: 12.sp),
              ),
            ),
          ],
        ),
      );
    }
  }

// Helper method to build file info item
  Widget _buildFileInfoItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

// Method to open file with external app
  void _openFileWithExternalApp(File file) async {
    try {
      ApptoastUtils.showInfo('Opening file with external app...');

      ApptoastUtils.showSuccess('File opened successfully');
    } catch (e) {
      AppLogger.error('Error opening file: $e');
      ApptoastUtils.showError('Failed to open file');
    }
  }

// Helper method to get file icon based on file type
  IconData _getFileIcon(String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();

    switch (extension) {
      case 'pdf':
        return Iconsax.document_text;
      case 'doc':
      case 'docx':
        return Iconsax.document_text;
      case 'xls':
      case 'xlsx':
        return Iconsax.document_text;
      case 'txt':
        return Iconsax.document_text;
      case 'zip':
      case 'rar':
        return Iconsax.archive;
      default:
        return Iconsax.document;
    }
  }

// Helper method to get file extension
  String _getFileExtension(String fileName) {
    try {
      final parts = fileName.split('.');
      return parts.length > 1 ? parts.last : 'file';
    } catch (e) {
      return 'file';
    }
  }

// Helper method to build file icon widget
  Widget _buildFileIcon(ThemeData theme, String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();

    IconData icon;
    Color color;

    switch (extension) {
      case 'pdf':
        icon = Iconsax.document_text;
        color = Colors.red;
        break;
      case 'doc':
      case 'docx':
        icon = Iconsax.document_text;
        color = Colors.blue;
        break;
      case 'xls':
      case 'xlsx':
        icon = Iconsax.document_text;
        color = Colors.green;
        break;
      case 'txt':
        icon = Iconsax.document_text;
        color = Colors.grey;
        break;
      case 'zip':
      case 'rar':
        icon = Iconsax.archive;
        color = Colors.orange;
        break;
      default:
        icon = Iconsax.document;
        color = theme.colorScheme.primary;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20.w,
          color: color,
        ),
        SizedBox(height: 2.h),
        Text(
          _getFileExtension(fileName).toUpperCase(),
          style: TextStyle(
            fontSize: 6.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadOptions(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => controller.pickImageFromCamera(),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            icon: Icon(Iconsax.camera, size: 14.w),
            label: Text(
              'Camera',
              style: TextStyle(fontSize: 10.sp),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => controller.pickImageFromGallery(),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            icon: Icon(Iconsax.gallery, size: 14.w),
            label: Text(
              'Gallery',
              style: TextStyle(fontSize: 10.sp),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => controller.pickMultipleFiles(),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            icon: Icon(Iconsax.gallery_add, size: 14.w),
            label: Text(
              'Multiple',
              style: TextStyle(fontSize: 10.sp),
            ),
          ),
        )
      ],
    );
  }

  void _showImageSourceDialog() {
    final theme = Theme.of(Get.context!);

    showModalBottomSheet(
      context: Get.context!,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32.w,
              height: 3.h,
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Text(
              'Choose Document Source',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onBackground,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _buildSourceOption(
                    context,
                    Iconsax.camera,
                    'Camera',
                    'Take a photo',
                    () {
                      Navigator.pop(context);
                      controller.pickImageFromCamera();
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildSourceOption(
                    context,
                    Iconsax.gallery,
                    'Gallery',
                    'Choose from gallery',
                    () {
                      Navigator.pop(context);
                      controller.pickImageFromGallery();
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildSourceOption(
                    context,
                    Iconsax.gallery_add,
                    'Multiple',
                    'Select multiple',
                    () {
                      Navigator.pop(context);
                      controller.pickMultipleFiles();
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20.w,
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: 6.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
