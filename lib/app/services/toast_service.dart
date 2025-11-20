import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

class ApptoastUtils {
  static void showGetXSnackbar({
    required String title,
    required String message,
    Color backgroundColor = Colors.black87,
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 3),
    SnackPosition snackPosition = SnackPosition.TOP,
    bool forceNew = false,
  }) {
    _safeGetXSnackbar(
      title: title,
      message: message,
      backgroundColor: backgroundColor,
      colorText: textColor,
      duration: duration,
      snackPosition: snackPosition,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      forceNew: forceNew,
    );
  }

  static void showGetXSuccess(String title, String message) {
    _safeGetXSnackbar(
      title: title,
      message: message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  static void showGetXError(String title, String message) {
    _safeGetXSnackbar(
      title: title,
      message: message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  // Safe wrapper for Get.snackbar with error handling
  static void _safeGetXSnackbar({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? colorText,
    Duration? duration,
    SnackPosition? snackPosition,
    EdgeInsets? margin,
    double? borderRadius,
    Widget? icon,
    bool forceNew = false,
  }) {
    try {
      // Close existing snackbar if forceNew is true
      if (forceNew && Get.isSnackbarOpen) {
        closeCurrentSnackbar();
      }

      // Use a small delay to ensure clean state
      Future.delayed(Duration.zero, () {
        try {
          Get.snackbar(
            title,
            message,
            backgroundColor: backgroundColor,
            colorText: colorText,
            duration: duration,
            snackPosition: snackPosition,
            margin: margin,
            borderRadius: borderRadius,
            icon: icon,
            shouldIconPulse: true,
            isDismissible: true,
          );
        } catch (e) {
          // Fallback to Fluttertoast if Get.snackbar fails
          _showCustomToast(
            message: '$title: $message',
            backgroundColor: backgroundColor ?? Colors.black87,
            textColor: colorText ?? Colors.white,
          );
        }
      });
    } catch (e) {
      // Ultimate fallback
      _showCustomToast(
        message: '$title: $message',
        backgroundColor: backgroundColor ?? Colors.black87,
        textColor: colorText ?? Colors.white,
      );
    }
  }

  // Safe method to close current snackbar
  static void closeCurrentSnackbar() {
    try {
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }
    } catch (e) {
      // Ignore errors when closing snackbar
    }
  }

  // Close all GetX snackbars safely
  static void closeAllGetXSnackbars() {
    try {
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
      }
    } catch (e) {
      // Ignore errors when closing snackbars
    }
  }

  // Your existing Fluttertoast methods (unchanged)
  static void showSuccess(String message) {
    _showCustomToast(
      message: message,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  static void showError(String message) {
    _showCustomToast(
      message: message,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  static void showWarning(String message) {
    _showCustomToast(
      message: message,
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );
  }

  static void showInfo(String message) {
    _showCustomToast(
      message: message,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
    );
  }

  // Custom color toast (your original method)
  static void showToastUtil(String msg, Color toastBg) {
    _showCustomToast(
      message: msg,
      backgroundColor: toastBg,
      textColor: Colors.white,
    );
  }

  // Toast with custom position
  static void showTopToast(String message,
      {Color backgroundColor = Colors.black87}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 1,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showCenterToast(String message,
      {Color backgroundColor = Colors.black87}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showBottomToast(String message,
      {Color backgroundColor = Colors.black87}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // Toast with different durations
  static void showLongToast(String message,
      {Color backgroundColor = Colors.black87}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showShortToast(String message,
      {Color backgroundColor = Colors.black87}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static void showCustomToast({
    required String message,
    Toast toastLength = Toast.LENGTH_SHORT,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Color backgroundColor = Colors.black87,
    Color textColor = Colors.white,
    double fontSize = 16.0,
    int timeInSecForIosWeb = 1,
    bool webShowClose = false,
    Color webBgColor = Colors.black,
    String webPosition = "right",
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: gravity,
      timeInSecForIosWeb: timeInSecForIosWeb,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: fontSize,
      webShowClose: webShowClose,
      webBgColor: webBgColor,
      webPosition: webPosition,
    );
  }

  static void cancelAllToasts() {
    Fluttertoast.cancel();
  }

  static void _showCustomToast({
    required String message,
    Color backgroundColor = Colors.black87,
    Color textColor = Colors.white,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Toast length = Toast.LENGTH_SHORT,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: length,
      gravity: gravity,
      timeInSecForIosWeb: 1,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 16.0,
    );
  }

  // New method for safe navigation scenarios
  static void safeShowInfo(String message, {bool useToast = false}) {
    if (useToast) {
      showInfo(message);
    } else {
      showGetXInfo(message);
    }
  }

  static void showGetXInfo(String message) {
    _safeGetXSnackbar(
      title: 'Info',
      message: message,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  // Method to safely show messages during navigation
  static void showDuringNavigation(String message, {bool isError = false}) {
    // Use Fluttertoast during navigation as it's more stable
    if (isError) {
      showError(message);
    } else {
      showInfo(message);
    }
  }
}
