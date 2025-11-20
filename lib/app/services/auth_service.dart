// lib/core/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/data/sharedPre.dart';
import 'package:eccomerce_app/app/routes/app_pages.dart';

class AuthService extends GetxService {
  static AuthService get instance => Get.find<AuthService>();

  Future<AuthService> init() async {
    return this;
  }

  Future<void> _performLogout() async {
    try {
      await SharedpreferenceUtil.clear();

      Get.offAllNamed(Routes.SIGN_UP);
    } catch (e) {
      await SharedpreferenceUtil.clear();
      Get.offAllNamed(Routes.SIGN_UP);
    }
  }

  Future<void> handleUnauthorizedError() async {
    await _showSessionExpiredDialog();
  }

  Future<void> _showSessionExpiredDialog() async {
    if (Get.isDialogOpen == true) return;

    await Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_off_rounded,
                    color: Colors.orange.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Session Expired',
                  style: Get.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'It looks like you\'ve been logged in from another device or your session has expired for security reasons.',
                  textAlign: TextAlign.center,
                  style: Get.textTheme.bodyMedium?.copyWith(
                    color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      _performLogout();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Get.theme.colorScheme.primary,
                      foregroundColor: Get.theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Continue to Login',
                      style: Get.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Get.theme.cardColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
