import 'package:eccomerce_app/app/core/data/sharedPre.dart';
import 'package:eccomerce_app/app/core/utils/appString/app_storage_string.dart';
import 'package:eccomerce_app/app/routes/app_pages.dart';
import 'package:eccomerce_app/app/services/toast_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import '../../../core/theme/summer_text_style.dart';

class CompanySelectionDialog extends StatelessWidget {
  final List<dynamic> companies;

  const CompanySelectionDialog({super.key, required this.companies});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _showCloseConfirmation(context, theme);
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
          vertical: MediaQuery.of(context).size.height * 0.05,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.business,
                        color: theme.cardColor,
                        size: 28,
                      ),
                      title: Text(
                        "Select Company",
                        style: SummerTextStyle.headingMedium.copyWith(
                          color: theme.cardColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Choose a company to continue",
                        style: SummerTextStyle.bodyMedium.copyWith(
                          color: theme.cardColor.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Companies List
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: companies.isEmpty
                      ? _buildEmptyState(theme)
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemCount: companies.length,
                          itemBuilder: (context, index) {
                            final company = companies[index];
                            return _buildCompanyCard(company, context, theme);
                          },
                        ),
                ),
              ),

              // Close Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => _showCloseConfirmation(context, theme),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(
                      double.infinity,
                      MediaQuery.of(context).size.height * 0.06,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    "Close",
                    style: SummerTextStyle.buttonMedium.copyWith(
                      color: theme.cardColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCloseConfirmation(BuildContext context, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Close Company Selection?",
          style: SummerTextStyle.headingMedium.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Text(
          "Are you sure you want to close without selecting a company?",
          style: SummerTextStyle.bodyMedium.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        actions: [
          // Cancel Button
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
            child: Text(
              "Cancel",
              style: SummerTextStyle.buttonMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // Confirm Close Button
          ElevatedButton(
            onPressed: () {
              _safeBack(); // Close confirmation dialog
              _safeBack(delay: 100); // Close company selection dialog
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text(
              "Yes, Close",
              style: SummerTextStyle.buttonMedium.copyWith(
                color: theme.colorScheme.onError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _safeBack({int delay = 0}) {
    if (delay > 0) {
      Future.delayed(Duration(milliseconds: delay), () {
        if (Get.isDialogOpen == true) {
          Navigator.pop(Get.context!);
        }
      });
    } else {
      if (Get.isDialogOpen == true) {
        Navigator.pop(Get.context!);
      }
    }
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No Companies Available",
            style: SummerTextStyle.headingSmall.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Please check back later",
            style: SummerTextStyle.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(
      dynamic company, BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final companyData = _extractCompanyData(company);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline
              : theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _onCompanySelected(company, theme);
          },
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          highlightColor: theme.colorScheme.primary.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Company Logo
                Container(
                  width: MediaQuery.of(context).size.width * 0.12,
                  height: MediaQuery.of(context).size.width * 0.12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  ),
                  child: companyData['logo'] != null &&
                          companyData['logo'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            companyData['logo'].toString(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultLogo(theme);
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildLogoPlaceholder(theme);
                            },
                          ),
                        )
                      : _buildDefaultLogo(theme),
                ),

                SizedBox(width: MediaQuery.of(context).size.width * 0.04),

                // Company Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyData['namePrint']?.toString() ?? 'No Name',
                        style: SummerTextStyle.headingSmall.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.005),
                      Text(
                        companyData['nameStreet']?.toString() ?? 'No Address',
                        style: SummerTextStyle.bodyMedium.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.003),
                      Text(
                        "Code: ${companyData['code']?.toString() ?? 'N/A'}",
                        maxLines: 1,
                        style: SummerTextStyle.bodySmall.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection Icon
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _extractCompanyData(dynamic company) {
    try {
      if (company is Map<String, dynamic>) {
        return {
          'id': company['_id']?.toString() ?? company['id']?.toString(),
          'namePrint': company['namePrint']?.toString() ?? 'Unknown Company',
          'nameStreet': company['nameStreet']?.toString() ?? 'No Address',
          'code': company['code']?.toString() ?? 'N/A',
          'logo': company['logo']?.toString(),
        };
      } else {
        return {
          'id': 'unknown',
          'namePrint': 'Unknown Company',
          'nameStreet': 'No Address',
          'code': 'N/A',
          'logo': null,
        };
      }
    } catch (e) {
      return {
        'id': 'error',
        'namePrint': 'Error',
        'nameStreet': 'Error',
        'code': 'N/A',
        'logo': null,
      };
    }
  }

  Widget _buildDefaultLogo(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.business,
        size: 28,
        color: theme.colorScheme.primary,
      ),
    );
  }

  Widget _buildLogoPlaceholder(ThemeData theme) {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: theme.colorScheme.primary,
      ),
    );
  }

  void _onCompanySelected(dynamic company, ThemeData theme) async {
    _safeBack();

    final companyData = _extractCompanyData(company);
    final companyId = companyData['id']?.toString() ?? '';

    if (companyId.isEmpty) {
      return;
    }

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      await SharedpreferenceUtil.setString(
          AppStorage.selectedCompanyId, companyId);
      await SharedpreferenceUtil.setString(AppStorage.selectedCompanyName,
          companyData['namePrint']?.toString() ?? 'Unknown Company');
      await _saveCompanyModules(companyId, company);

      if (Get.isDialogOpen == true) Get.back();

      Get.offAllNamed(Routes.BASE, arguments: {
        'companyId': companyId,
        'companyName':
            companyData['namePrint']?.toString() ?? 'Unknown Company',
      });

      ApptoastUtils.showSuccess("Company selected successfully");
    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen == true) Get.back();

      ApptoastUtils.showError("Failed to select company: $e");
    }
  }

  Future<void> _saveCompanyModules(String companyId, dynamic company) async {
    try {
      // Extract modules from the company data
      final modules = _extractModulesFromCompany(company);

      if (modules != null && modules.isNotEmpty) {
        await SharedpreferenceUtil.setString(
            AppStorage.companyModules, jsonEncode(modules));
        print("✅ Company modules saved for company: $companyId");

        // Print CustomerRegistration create permission
        if (modules.containsKey('BusinessManagement')) {
          final businessManagement = modules['BusinessManagement'];
          if (businessManagement is Map &&
              businessManagement.containsKey('CustomerRegistration')) {
            final customerRegistration =
                businessManagement['CustomerRegistration'];
            if (customerRegistration is Map) {
              final createPermission = customerRegistration['create'];
              print(
                  "✅ CustomerRegistration create permission: $createPermission");
              await SharedpreferenceUtil.setBool(
                  AppStorage.customerCreatPermission, createPermission);
            }
          }
        }

        print("📦 Full modules data: ${jsonEncode(modules)}");
      } else {
        print("⚠️ No modules found for company: $companyId");
        // Clear any existing modules if none found
        await SharedpreferenceUtil.setString(AppStorage.companyModules, '');
      }
    } catch (e) {
      print("❌ Error saving company modules: $e");
      rethrow;
    }
  }

  Map<String, dynamic>? _extractModulesFromCompany(dynamic company) {
    try {
      // Check if modules are directly in company object (from access array)
      if (company is Map &&
          company.containsKey('modules') &&
          company['modules'] is Map) {
        return Map<String, dynamic>.from(company['modules']);
      }

      return null;
    } catch (e) {
      print("❌ Error extracting modules from company: $e");
      return null;
    }
  }
}
