import 'dart:io';

import 'package:eccomerce_app/app/core/data/sharedPre.dart';
import 'package:eccomerce_app/app/core/utils/appString/app_storage_string.dart';
import 'package:eccomerce_app/app/custom/imagecustom.dart';
import 'package:eccomerce_app/app/modules/PrivicyPolicy/views/disclamer_view.dart';
import 'package:eccomerce_app/app/modules/PrivicyPolicy/views/refund_policy_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../routes/app_pages.dart';
import '../../Base/controllers/base_controller.dart';
import '../../PrivicyPolicy/views/term_conditions_view.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final BaseController baseController = Get.put(BaseController());

    return WillPopScope(
      onWillPop: () async {
        baseController.changeTabIndex(0);
        return false;
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text('profile'.tr),
          leading: IconButton(
              onPressed: () async {
                baseController.changeTabIndex(0);
              },
              icon: Icon(Platform.isIOS
                  ? Icons.arrow_back_ios_new_outlined
                  : Icons.arrow_back_outlined)),
          // actions: [
          //   PopupMenuButton<String>(
          //     onSelected: (String language) {
          //       if (language == 'en') {
          //         Get.updateLocale(const Locale('en', 'US'));
          //       } else if (language == 'bn') {
          //         Get.updateLocale(const Locale('bn', 'BD'));
          //       }
          //     },
          //     itemBuilder: (BuildContext context) => [
          //       const PopupMenuItem<String>(
          //         value: 'en',
          //         child: Text('English'),
          //       ),
          //       const PopupMenuItem<String>(
          //         value: 'bn',
          //         child: Text('বাংলা'),
          //       ),
          //     ],
          //   ),
          // ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(theme, size),
                SizedBox(height: size.height * 0.02),
                _buildMenuItems(theme, size),
                _buildAppInfo(theme, size),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(ThemeData theme, Size size) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(size.width * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: size.width * 0.01,
            offset: Offset(0, size.width * 0.005),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
              width: size.width * 0.15,
              height: size.width * 0.15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer,
              ),
              child:
                  SharedpreferenceUtil.getString(AppStorage.profileImage) != ""
                      ? Icon(
                          Icons.person,
                          size: size.width * 0.08,
                          color: theme.colorScheme.onPrimaryContainer,
                        )
                      : CustomImageView(
                          url: SharedpreferenceUtil.getString(
                              AppStorage.profileImage),
                        )),
          SizedBox(width: size.width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  SharedpreferenceUtil.getString(AppStorage.username),
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: size.height * 0.005),
                Text(
                  SharedpreferenceUtil.getString(AppStorage.userEmail),
                  style: TextStyle(
                    fontSize: size.width * 0.035,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(ThemeData theme, Size size) {
    final menuItems = [
      _MenuItem(
        icon: Icons.production_quantity_limits_outlined,
        title: "my_order".tr,
        onTap: () {
          Get.toNamed(Routes.ORDER_DETAILS);
        },
      ),
      _MenuItem(
        icon: Icons.payment_outlined,
        title: "payment_management".tr,
        onTap: () {
          Get.toNamed(Routes.PAYMENT_MANAGEMENT);
        },
      ),
      // _MenuItem(
      //   icon: Icons.language_outlined,
      //   title: "language".tr,
      //   onTap: () {
      //     _showLanguageDialog();
      //   },
      // ),
      _MenuItem(
        icon: Icons.support_agent_outlined,
        title: "contact_support".tr,
        onTap: () {
          Get.toNamed(Routes.CONTACT);
        },
      ),
      _MenuItem(
        icon: Icons.description_outlined,
        title: "terms_conditions".tr,
        onTap: () {
          Get.to(() => const TermConditionsView());
        },
      ),
      _MenuItem(
        icon: Icons.privacy_tip_outlined,
        title: "privacy_policy".tr,
        onTap: () {
          Get.toNamed(Routes.PRIVICY_POLICY);
        },
      ),
      _MenuItem(
        icon: Icons.payment_outlined,
        title: "Refund Policy".tr,
        onTap: () {
          Get.to(() => const RefundPolicyView());
        },
      ),
      _MenuItem(
        icon: Icons.warning_amber_outlined,
        title: "disclaimer".tr,
        onTap: () {
          Get.to(() => const DisclamerView());
        },
      ),
      _MenuItem(
        icon: Icons.logout_outlined,
        title: "logout".tr,
        onTap: () {
          controller.showLogoutConfirmation();
        },
        isLogout: true,
      ),
    ];

    return Column(
      children:
          menuItems.map((item) => _buildMenuItem(item, theme, size)).toList(),
    );
  }

  Widget _buildMenuItem(_MenuItem item, ThemeData theme, Size size) {
    return Container(
      margin: EdgeInsets.only(bottom: size.height * 0.015),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(size.width * 0.03),
          splashColor: item.isLogout
              ? theme.colorScheme.error.withOpacity(0.1)
              : theme.colorScheme.primary.withOpacity(0.1),
          highlightColor: item.isLogout
              ? theme.colorScheme.error.withOpacity(0.05)
              : theme.colorScheme.primary.withOpacity(0.05),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.02,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(size.width * 0.03),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: size.width * 0.01,
                  offset: Offset(0, size.width * 0.002),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: size.width * 0.1,
                  height: size.width * 0.1,
                  decoration: BoxDecoration(
                    color: item.isLogout
                        ? theme.colorScheme.error.withOpacity(0.1)
                        : theme.colorScheme.primaryContainer.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    size: size.width * 0.04,
                    color: item.isLogout
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
                SizedBox(width: size.width * 0.04),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: size.width * 0.035,
                      fontWeight: FontWeight.w500,
                      color: item.isLogout
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: size.width * 0.06,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfo(ThemeData theme, Size size) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData
            ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
            : '1.0.0+1'; // Fallback version

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(size.width * 0.04),
          child: Column(
            children: [
              Text(
                'Developed by Siara Technology',
                style: TextStyle(
                  fontSize: size.width * 0.032,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: size.height * 0.005),
              // Clickable website link
              GestureDetector(
                onTap: () {
                  _launchWebsite('https://siaratechnology.com');
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    'https://siaratechnology.com',
                    style: TextStyle(
                      fontSize: size.width * 0.032,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.005),
              // Clickable email
              GestureDetector(
                onTap: () {
                  _launchEmail('sales@siaratechnology.com');
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    'sales@siaratechnology.com',
                    style: TextStyle(
                      fontSize: size.width * 0.032,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: theme.colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.01),
              Text(
                'Version: $version',
                style: TextStyle(
                  fontSize: size.width * 0.03,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

// Method to launch website
  void _launchWebsite(String url) async {
    try {
      if (await canLaunchUrlString(url)) {
        await launchUrlString(url);
      } else {
        Get.snackbar(
          'Error',
          'Could not launch website',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not launch website: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

// Method to launch email
  void _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
    );

    try {
      if (await canLaunchUrlString(emailLaunchUri.toString())) {
        await launchUrlString(emailLaunchUri.toString());
      } else {
        Get.snackbar(
          'Error',
          'Could not launch email app',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not launch email app: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _showLanguageDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('choose_language'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('English'),
              onTap: () {
                Get.updateLocale(const Locale('en', 'US'));
                Navigator.pop(Get.context!);
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('বাংলা'),
              onTap: () {
                Get.updateLocale(const Locale('bn', 'BD'));
                Navigator.pop(Get.context!);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLogout;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLogout = false,
  });
}
