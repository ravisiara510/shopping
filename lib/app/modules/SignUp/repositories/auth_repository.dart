import 'dart:convert';
import 'package:eccomerce_app/app/core/config/api_endpoints.dart';
import 'package:eccomerce_app/app/core/utils/appString/app_storage_string.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../../core/data/sharedPre.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/api_exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../../routes/app_pages.dart';
import '../../../services/toast_service.dart';
import '../views/company_selection_dialog_view.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();
  var isLoading = false.obs;
  String? _deviceId;

  Future<void> initializeDeviceId() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (GetPlatform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceId = androidInfo.id;
      } else if (GetPlatform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceId = iosInfo.identifierForVendor;
      } else {
        _deviceId = 'web-device-${DateTime.now().millisecondsSinceEpoch}';
      }

      AppLogger.info("Device ID initialized: $_deviceId");
    } catch (e) {
      _deviceId = 'fallback-device-${DateTime.now().millisecondsSinceEpoch}';
      AppLogger.error("Failed to get device ID, using fallback: $e");
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Ensure device ID is initialized
      if (_deviceId == null) {
        await initializeDeviceId();
      }

      final response = await _apiService.postRequest(
        ApiEndpoints.login,
        {
          "email": email,
          "password": password,
          "deviceId": _deviceId,
        },
      );
      final responseData = response.data;
      Map<String, dynamic> data;
      if (responseData is Map && responseData.containsKey('data')) {
        data = responseData['data'];
      } else {
        data =
            responseData is Map ? Map<String, dynamic>.from(responseData) : {};
      }
      final token = _extractToken(data);
      final user = _extractUser(data);
      final profileImage = user['profilePicture']?.toString() ?? '';

      if (token.isNotEmpty) {
        await _saveUserData(token, user);
        if (profileImage.isNotEmpty) {
          await SharedpreferenceUtil.setString(
              AppStorage.profileImage, profileImage);
        }
        await SharedpreferenceUtil.setString(AppStorage.deviceID, _deviceId!);
      }

      AppLogger.info("Login successful for: ${user['name']}");

      await _handleCompanySelection(user);

      return data;
    } on ApiException catch (e) {
      if (_isAnotherDeviceError(e)) {
        await _handleAnotherDeviceError();
        return {};
      }

      AppLogger.error("ApiException: ${e.message}");
      rethrow;
    } catch (e) {
      AppLogger.error("Unexpected error during login: $e");
      rethrow;
    }
  }

  String _extractToken(Map<String, dynamic> data) {
    try {
      if (data.containsKey('token')) {
        return data['token']?.toString() ?? '';
      }
      if (data.containsKey('accessToken')) {
        return data['accessToken']?.toString() ?? '';
      }
      if (data.containsKey('access_token')) {
        return data['access_token']?.toString() ?? '';
      }
      return '';
    } catch (e) {
      AppLogger.error("Error extracting token: $e");
      return '';
    }
  }

  Map<String, dynamic> _extractUser(Map<String, dynamic> data) {
    try {
      if (data.containsKey('user') && data['user'] is Map) {
        return Map<String, dynamic>.from(data['user']);
      }
      if (data.containsKey('userData') && data['userData'] is Map) {
        return Map<String, dynamic>.from(data['userData']);
      }
      // If no user object found, return relevant fields from data
      return {
        'name': data['name']?.toString() ?? '',
        'email': data['email']?.toString() ?? '',
        '_id': data['_id']?.toString() ?? data['id']?.toString() ?? '',
        'role': data['role']?.toString() ?? '',
        'profilePicture': data['profilePicture']?.toString() ??
            data['profileImage']?.toString() ??
            '',
      };
    } catch (e) {
      AppLogger.error("Error extracting user: $e");
      return {};
    }
  }

  bool _isAnotherDeviceError(ApiException e) {
    try {
      final statusCode = e.response?.statusCode;
      final errorMessage = e.message.toLowerCase();

      // Also check response data for error message
      final responseData = e.response?.data;
      String serverMessage = '';

      if (responseData is Map) {
        serverMessage = responseData['message']?.toString().toLowerCase() ?? '';
      } else if (responseData is String) {
        serverMessage = responseData.toLowerCase();
      }

      return statusCode == 401 &&
          (errorMessage.contains('another device') ||
              errorMessage.contains('different device') ||
              errorMessage.contains('device mismatch') ||
              serverMessage.contains('another device') ||
              serverMessage.contains('different device') ||
              serverMessage.contains('device mismatch'));
    } catch (e) {
      AppLogger.error("Error checking another device error: $e");
      return false;
    }
  }

  Future<void> _handleAnotherDeviceError() async {
    AppLogger.warning("User logged in from another device");

    await SharedpreferenceUtil.clear();

    Get.dialog(
      _buildSessionExpiredDialog(),
      barrierDismissible: false,
    );
  }

  Widget _buildSessionExpiredDialog() {
    return AlertDialog(
      title: Text(
        'session_expired'.tr,
        style: TextStyle(
          color: Get.theme.colorScheme.error,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'session_expired_message'.tr,
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Get.back(); // Close dialog
            Get.offAllNamed(Routes.SIGN_UP); // Navigate to sign up
          },
          child: Text(
            'ok'.tr,
            style: TextStyle(
              color: Get.theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveUserData(String token, Map<String, dynamic> user) async {
    try {
      final role = user['role']?.toString() ?? '';

      await SharedpreferenceUtil.setString(AppStorage.userToken, token);
      await SharedpreferenceUtil.setString(AppStorage.userRole, role);
      await SharedpreferenceUtil.setString(
          AppStorage.userDetails, jsonEncode(user));

      await SharedpreferenceUtil.setString(
          AppStorage.username, user['name']?.toString() ?? '');
      await SharedpreferenceUtil.setString(
          AppStorage.userEmail, user['email']?.toString() ?? '');
      await SharedpreferenceUtil.setString(AppStorage.userId,
          user['_id']?.toString() ?? user['id']?.toString() ?? '');

      AppLogger.info("Token saved: $token");
      AppLogger.info("Role saved: $role");
      AppLogger.debug("User data saved: ${jsonEncode(user)}");
    } catch (e) {
      AppLogger.error("Error saving user data: $e");
    }
  }

  Future<void> logout() async {
    await SharedpreferenceUtil.clear();

    Get.offAllNamed(Routes.SIGN_UP);
  }

  String getUserToken() => SharedpreferenceUtil.getString(AppStorage.userToken);

  String getUserRole() => SharedpreferenceUtil.getString(AppStorage.userRole);

  Map<String, dynamic> getUserDetails() {
    try {
      final userData = SharedpreferenceUtil.getString(AppStorage.userDetails);
      if (userData.isEmpty) return {};
      return jsonDecode(userData);
    } catch (e) {
      AppLogger.error("Error getting user details: $e");
      return {};
    }
  }

  String getDeviceId() => SharedpreferenceUtil.getString(AppStorage.deviceID);

  bool isUserLoggedIn() {
    final token = getUserToken();
    return token.isNotEmpty;
  }

  Future<bool> validateToken() async {
    final token = getUserToken();
    if (token.isEmpty) return false;

    try {
      // For now, just check if token exists
      return true;
    } catch (e) {
      AppLogger.error("Token validation failed: $e");
      return false;
    }
  }

  Future<void> _handleCompanySelection(dynamic user) async {
    try {
      List<dynamic> companies = _extractCompaniesFromUser(user);

      AppLogger.info("Found ${companies.length} companies for user");

      if (companies.isEmpty) {
        ApptoastUtils.showInfo("No companies available");
        Get.offAllNamed(Routes.BASE);
        return;
      }

      // Log company details for debugging
      for (var company in companies) {
        AppLogger.debug("Company data: $company");
      }

      if (companies.length == 1) {
        final singleCompany = companies.first;
        final companyData = _extractCompanyData(singleCompany);
        final companyId = companyData['id'];
        final companyName = companyData['name'];

        if (companyId != null && companyId.isNotEmpty) {
          await _saveSelectedCompanyData(companyId, companyName, singleCompany);
          Get.offAllNamed(Routes.BASE, arguments: {
            'companyId': companyId,
            'companyName': companyName,
          });
          ApptoastUtils.showSuccess("Auto-selected company: $companyName");
          AppLogger.info(
              "Auto-selected company: $companyName (ID: $companyId)");
        } else {
          _showCompanySelectionDialog(companies);
        }
      } else {
        _showCompanySelectionDialog(companies);
      }
    } catch (e) {
      AppLogger.error("Error handling company selection: $e");
      Get.offAllNamed(Routes.BASE);
    }
  }

  // Helper method to extract company data safely
  Map<String, dynamic> _extractCompanyData(dynamic company) {
    try {
      if (company is Map<String, dynamic>) {
        return {
          'id': company['_id']?.toString() ?? company['id']?.toString(),
          'name': company['namePrint']?.toString() ?? 'Unknown Company',
          'namePrint': company['namePrint']?.toString() ?? 'Unknown Company',
          'nameStreet': company['nameStreet']?.toString() ?? 'No Address',
          'code': company['code']?.toString() ?? 'N/A',
          'logo': company['logo']?.toString(),
        };
      } else {
        return {
          'id': 'unknown',
          'name': 'Unknown Company',
          'namePrint': 'Unknown Company',
          'nameStreet': 'No Address',
          'code': 'N/A',
          'logo': null,
        };
      }
    } catch (e) {
      AppLogger.error("Error in _extractCompanyData: $e");
      return {
        'id': 'error',
        'name': 'Error',
        'namePrint': 'Error',
        'nameStreet': 'Error',
        'code': 'N/A',
        'logo': null,
      };
    }
  }

  Future<void> _saveSelectedCompanyData(
      String companyId, String companyName, dynamic companyData) async {
    try {
      await SharedpreferenceUtil.setString(
          AppStorage.selectedCompanyId, companyId);
      await SharedpreferenceUtil.setString(
          AppStorage.selectedCompanyName, companyName);

      // Extract and save modules from the company data
      final modules = _extractModulesFromCompanyData(companyData);
      if (modules != null && modules.isNotEmpty) {
        await SharedpreferenceUtil.setString(
            AppStorage.companyModules, jsonEncode(modules));
        AppLogger.info("Company modules saved for: $companyName");

        bool createPermission = _extractCustomerCreatePermission(modules);

        await SharedpreferenceUtil.setBool(
            AppStorage.customerCreatPermission, createPermission);

        print(
            "✅ CustomerRegistration create permission: ${SharedpreferenceUtil.getBool(AppStorage.customerCreatPermission)}");

        AppLogger.debug("Full modules data: ${jsonEncode(modules)}");
      } else {
        AppLogger.warning("No modules found for company: $companyName");
        await SharedpreferenceUtil.setString(AppStorage.companyModules, '');
      }

      AppLogger.info("Company auto-selected: $companyName (ID: $companyId)");
    } catch (e) {
      AppLogger.error("Error saving company data: $e");
    }
  }

  bool _extractCustomerCreatePermission(Map<String, dynamic> modules) {
    try {
      if (modules.containsKey('BusinessManagement')) {
        final businessManagement = modules['BusinessManagement'];
        if (businessManagement is Map &&
            businessManagement.containsKey('CustomerRegistration')) {
          final customerRegistration =
              businessManagement['CustomerRegistration'];
          if (customerRegistration is Map &&
              customerRegistration.containsKey('create')) {
            return customerRegistration['create'] == true;
          }
        }
      }
      return false;
    } catch (e) {
      AppLogger.error("Error extracting customer create permission: $e");
      return false;
    }
  }

  Map<String, dynamic>? _extractModulesFromCompanyData(dynamic companyData) {
    try {
      if (companyData is Map<String, dynamic>) {
        // Check if modules are directly in companyData (from access array)
        if (companyData.containsKey('modules') &&
            companyData['modules'] is Map) {
          return Map<String, dynamic>.from(companyData['modules']);
        }
      }
      return null;
    } catch (e) {
      AppLogger.error("Error extracting modules from company data: $e");
      return null;
    }
  }

  void _showCompanySelectionDialog(List<dynamic> companies) {
    try {
      Get.dialog(
        CompanySelectionDialog(companies: companies),
        barrierDismissible: false,
      );
    } catch (e) {
      AppLogger.error("Error showing company selection dialog: $e");
      // Navigate to base as fallback
      Get.offAllNamed(Routes.BASE);
    }
  }

  List<dynamic> _extractCompaniesFromUser(dynamic user) {
    try {
      if (user is Map && user.containsKey('access')) {
        final accessList = user['access'] as List<dynamic>;
        List<dynamic> companies = [];
        for (var access in accessList) {
          if (access is Map && access.containsKey('company')) {
            // Include both company data and modules in the company object
            final company = access['company'];
            if (company is Map) {
              // Add modules to the company data
              final companyWithModules = Map<String, dynamic>.from(company);
              if (access.containsKey('modules')) {
                companyWithModules['modules'] = access['modules'];
              }
              companies.add(companyWithModules);
            } else {
              companies.add(company);
            }
          }
        }
        return companies;
      }
      return [];
    } catch (e) {
      AppLogger.error("Error extracting companies: $e");
      return [];
    }
  }

  Map<String, dynamic>? getCompanyModules(String companyId, dynamic user) {
    try {
      if (user is Map && user.containsKey('access')) {
        final accessList = user['access'] as List<dynamic>;
        for (var access in accessList) {
          if (access is Map &&
              access.containsKey('company') &&
              access['company'] is Map &&
              access['company']['_id'] == companyId &&
              access.containsKey('modules')) {
            return access['modules'];
          }
        }
      }
      return null;
    } catch (e) {
      AppLogger.error("Error getting company modules: $e");
      return null;
    }
  }

  Map<String, dynamic> getSavedCompanyModules() {
    try {
      final modulesJson =
          SharedpreferenceUtil.getString(AppStorage.companyModules);
      if (modulesJson.isEmpty) return {};
      final modules = jsonDecode(modulesJson);
      if (modules.containsKey('BusinessManagement')) {
        final businessManagement = modules['BusinessManagement'];
        if (businessManagement is Map &&
            businessManagement.containsKey('CustomerRegistration')) {
          final customerRegistration =
              businessManagement['CustomerRegistration'];
          if (customerRegistration is Map) {
            final createPermission = customerRegistration['create'];
            print(
                "📋 Retrieved CustomerRegistration create permission: $createPermission");
          }
        }
      }

      return modules;
    } catch (e) {
      AppLogger.error("Error getting saved company modules: $e");
      return {};
    }
  }

  bool checkModulePermission(String module, String subModule, String action) {
    try {
      final modules = getSavedCompanyModules();

      if (modules.containsKey(module)) {
        final moduleData = modules[module];
        if (moduleData is Map && moduleData.containsKey(subModule)) {
          final subModuleData = moduleData[subModule];
          if (subModuleData is Map && subModuleData.containsKey(action)) {
            final permission = subModuleData[action] == true;

            return permission;
          }
        }
      }

      return false;
    } catch (e) {
      AppLogger.error("Error checking module permission: $e");
      return false;
    }
  }

  void printAllModules() {
    final modules = getSavedCompanyModules();

    if (modules.containsKey('BusinessManagement')) {
      final businessManagement = modules['BusinessManagement'];
      if (businessManagement is Map &&
          businessManagement.containsKey('CustomerRegistration')) {
        final customerRegistration = businessManagement['CustomerRegistration'];
      }
    }
  }
}
