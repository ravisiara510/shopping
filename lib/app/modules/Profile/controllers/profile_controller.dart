import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../services/toast_service.dart';
import '../../SignUp/repositories/auth_repository.dart';

class ProfileController extends GetxController {
  final count = 0.obs;
  final AuthRepository _authRepository = AuthRepository();

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void increment() => count.value++;
  void showLogoutConfirmation() {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Get.theme.colorScheme.error,
            fontSize: 14.sp,
          ),
        ),
        content: Text(
          'Are you sure you want to logout? You will need to sign in again to access your account.',
          style: TextStyle(
            fontSize: 12.sp,
            color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          // Cancel Button
          TextButton(
            onPressed: () {
              Navigator.pop(Get.context!);
            },
            style: TextButton.styleFrom(
              foregroundColor: Get.theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Logout Button
          TextButton(
            onPressed: () {
              Navigator.pop(Get.context!);
              _performLogout();
            },
            style: TextButton.styleFrom(
              foregroundColor: Get.theme.colorScheme.error,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  // PERFORM ACTUAL LOGOUT
  Future<void> _performLogout() async {
    try {
      // Show loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Perform logout
      await _authRepository.logout();

      // Show success message
      ApptoastUtils.showSuccess('logout success'.tr);
    } catch (e) {
      ApptoastUtils.showError('logout failed'.tr);
    } finally {
      if (Get.isDialogOpen == true) {
        Navigator.pop(Get.context!);
      }
    }
  }
}
