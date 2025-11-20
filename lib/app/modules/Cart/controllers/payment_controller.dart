import 'package:eccomerce_app/app/core/config/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/services/api_service.dart';
import 'package:dio/dio.dart';

import '../../../core/utils/logger.dart';
import '../../../services/toast_service.dart';
import 'cart_controller.dart';

class PaymentDialogController extends GetxController {
  final Map<String, dynamic> orderData;
  final ImagePicker _imagePicker = ImagePicker();
  final ApiService _apiService = ApiService();

  PaymentDialogController({required this.orderData}) {
    final total =
        (orderData['grandTotal']?.toDouble() ?? 0.0).toStringAsFixed(2);
    amountController.text = total;
    validateAmount(total);
  }

  // -------------------- Reactive Variables --------------------
  var selectedMethod = 'cash'.obs;
  var uploadedFiles = <File>[].obs;
  var isLoading = false.obs;
  var uploadProgress = 0.0.obs;
  var amountError = ''.obs;
  var canSubmit = false.obs;
  var remarksController = TextEditingController();
  final amountController = TextEditingController();
  RxBool showProgress = false.obs;
  RxBool isHidePaymentButton = false.obs;
  final List<String> paymentMethods = [
    "cash",
    "upi",
    "bank_transfer",
    "cheque",
    "bkash"
  ];

  // -------------------- Getters for compatibility --------------------
  List<File> get uploadedImages => uploadedFiles;

  // -------------------- Display Name --------------------
  String getPaymentMethodDisplayName(String method) {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'upi':
        return 'UPI';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'cheque':
        return 'Cheque';
      case 'bkash':
        return 'Bkash';
      default:
        return method;
    }
  }

  // -------------------- Validation --------------------
  void validateAmount(String value) {
    if (value.isEmpty) {
      amountError.value = 'Please enter payment amount';
      canSubmit.value = false;
    } else if (double.tryParse(value) == null) {
      amountError.value = 'Please enter a valid amount';
      canSubmit.value = false;
    } else if (double.parse(value) <= 0) {
      amountError.value = 'Amount must be greater than 0';
      canSubmit.value = false;
    } else {
      amountError.value = '';
      updateCanSubmit();
    }
  }

  void updateCanSubmit() {
    canSubmit.value = selectedMethod.isNotEmpty &&
        amountError.isEmpty &&
        amountController.text.isNotEmpty;
  }

  // -------------------- Image / PDF Picker --------------------
  Future<void> pickFile({required ImageSource source}) async {
    try {
      if (uploadedFiles.length >= 5) {
        ApptoastUtils.showWarning('You can upload up to 5 files only.');
        return;
      }

      final XFile? file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (file != null) {
        uploadedFiles.add(File(file.path));
        ApptoastUtils.showSuccess('File added successfully!');
      }
    } catch (e) {
      AppLogger.error('Failed to pick file: $e');
      ApptoastUtils.showError('Failed to pick file');
    }
  }

  // Alias methods for compatibility
  Future<void> pickImageFromCamera() async {
    await pickFile(source: ImageSource.camera);
  }

  Future<void> pickImageFromGallery() async {
    await pickFile(source: ImageSource.gallery);
  }

  Future<void> pickMultipleFiles() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      for (final img in images) {
        if (uploadedFiles.length < 5) {
          uploadedFiles.add(File(img.path));
        }
      }

      if (images.isNotEmpty) {
        ApptoastUtils.showSuccess('${images.length} image(s) added');
      }
    } catch (e) {
      AppLogger.error('Failed to pick images: $e');
      ApptoastUtils.showError('Failed to pick images');
    }
  }

  void removeFile(int index) {
    uploadedFiles.removeAt(index);
  }

  // Alias method for compatibility
  void removeImage(int index) {
    removeFile(index);
  }

  // -------------------- Submit Payment --------------------
  Future<void> submitPayment() async {
    if (!canSubmit.value) return;

    isLoading.value = true;
    uploadProgress.value = 0.0;
    showProgress.value = true;

    try {
      final paymentFields = {
        'orderId': orderData['_id'],
        'companyId': orderData['companyId'],
        'customerId': orderData['customerId']['_id'],
        'mode': selectedMethod.value,
        'amount': double.parse(amountController.text),
        'remarks': remarksController.text.isNotEmpty
            ? remarksController.text
            : 'Payment for order ${orderData['orderCode']}',
      };

      AppLogger.info('Payment Fields: $paymentFields');

      final response = await _apiService.uploadFilesAuth(
        ApiEndpoints.paymentPoast,
        fields: paymentFields,
        files: uploadedFiles,
        fileFieldName: 'documents',
        onProgress: (sent, total) {
          if (total > 0) {
            final progress = sent / total;
            uploadProgress.value = progress;

            if (sent % 50000 == 0 || sent == total) {
              final sentKB = (sent / 1024).toStringAsFixed(1);
              final totalKB = (total / 1024).toStringAsFixed(1);
              AppLogger.debug(
                  '📤 Upload: ${sentKB}KB / ${totalKB}KB (${(progress * 100).toStringAsFixed(1)}%)');
            }
          }
        },
      );

      final data = response.data;
      AppLogger.info('Payment Response: $data');

      if (data['success'] == true) {
        // Update cart controller first
        final CartController cartController = Get.find<CartController>();
        cartController.isHidePaymentButton.value = true;

        showProgress.value = false;
        isLoading.value = false;

        // Reset all variables before closing dialog
        resetForm();

        // Close the dialog first, then show success message
        if (Get.isDialogOpen == true) {
          Get.back(); // Close the dialog
        }

        // Use a small delay to ensure dialog is completely closed
        await Future.delayed(const Duration(milliseconds: 300));

        // Now show the success message
        ApptoastUtils.showGetXSuccess(
          'Payment Successful 🎉',
          'Your payment of ₹${amountController.text} has been processed.',
        );
      } else {
        throw Exception(data['message'] ?? 'Payment failed');
      }
    } catch (e) {
      showProgress.value = false;
      isLoading.value = false;
      String errorMessage = 'Please try again';

      if (e is DioException) {
        if (e.response != null) {
          errorMessage =
              'HTTP ${e.response!.statusCode}: ${e.response!.data?['message'] ?? e.response!.statusMessage}';
          AppLogger.error('Dio Error Response: ${e.response!.data}');
        } else {
          errorMessage = 'Network error: ${e.message}';
          AppLogger.error('Network error: ${e.message}');
        }
      } else {
        errorMessage = e.toString();
        AppLogger.error('Payment error: $e');
      }

      // Show error without closing the dialog
      ApptoastUtils.showGetXError('Payment Failed ❌', errorMessage);
    } finally {
      uploadProgress.value = 0.0;
    }
  }

  // -------------------- Lifecycle --------------------
  @override
  void onInit() {
    super.onInit();
    ever(selectedMethod, (_) => updateCanSubmit());
    amountController.addListener(() {
      validateAmount(amountController.text);
    });
  }

  @override
  void onClose() {
    amountController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  void resetForm() {
    // Clear uploaded files
    uploadedFiles.clear();

    // Reset payment method to default
    selectedMethod.value = 'cash';

    // Clear text controllers
    remarksController.clear();

    // Reset amount to original order total
    final total =
        (orderData['grandTotal']?.toDouble() ?? 0.0).toStringAsFixed(2);
    amountController.text = total;

    // Reset validation states
    amountError.value = '';
    canSubmit.value = false;
    validateAmount(total);

    // Reset progress states
    uploadProgress.value = 0.0;
    showProgress.value = false;
    Navigator.pop(Get.context!);
    AppLogger.debug('Payment form reset successfully');
  }
}
