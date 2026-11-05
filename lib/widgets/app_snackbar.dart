import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';

class AppSnackbar {
  static DateTime? _lastShownTime;
  static String? _lastShownMessage;

  static void show({
    required String title,
    required String message,
    bool isSuccess = true,
    SnackPosition snackPosition = SnackPosition.TOP,
    Duration debounceDuration = const Duration(milliseconds: 1500),
  }) {
    if (Get.testMode || Get.context == null) {
      debugPrint('[AppSnackbar] $title: $message');
      return;
    }

    final now = DateTime.now();
    if (_lastShownTime != null &&
        now.difference(_lastShownTime!) < debounceDuration &&
        (_lastShownMessage == message || Get.isSnackbarOpen)) {
      return;
    }
    _lastShownTime = now;
    _lastShownMessage = message;

    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    final accentColor = isSuccess ? const Color(0xFF4ADE80) : primaryRed;

    Get.snackbar(
      title,
      message,
      snackPosition: snackPosition,
      backgroundColor: const Color(0xFF111111),
      colorText: Colors.white,
      borderRadius: 18,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      borderWidth: 1,
      borderColor: accentColor.withValues(alpha: 0.35),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          color: accentColor,
          size: 22,
        ),
      ),
      shouldIconPulse: true,
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      duration: const Duration(seconds: 3),
      barBlur: 16,
      forwardAnimationCurve: Curves.elasticOut,
      reverseAnimationCurve: Curves.easeOutBack,
      animationDuration: const Duration(milliseconds: 750),
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  static void success(
    String message, {
    String title = "Success",
    SnackPosition position = SnackPosition.TOP,
  }) {
    show(
      title: title,
      message: message,
      isSuccess: true,
      snackPosition: position,
    );
  }

  static void showSuccess({
    required String title,
    required String message,
    SnackPosition position = SnackPosition.TOP,
  }) {
    show(
      title: title,
      message: message,
      isSuccess: true,
      snackPosition: position,
    );
  }

  static void error(
    String message, {
    String title = "Error",
    SnackPosition position = SnackPosition.TOP,
  }) {
    show(
      title: title,
      message: message,
      isSuccess: false,
      snackPosition: position,
    );
  }

  static void showError({
    required String title,
    required String message,
    SnackPosition position = SnackPosition.TOP,
  }) {
    show(
      title: title,
      message: message,
      isSuccess: false,
      snackPosition: position,
    );
  }

  static void info(
    String message, {
    String title = "Notice",
    SnackPosition position = SnackPosition.TOP,
  }) {
    show(
      title: title,
      message: message,
      isSuccess: true,
      snackPosition: position,
    );
  }

  static void warning(
    String message, {
    String title = "Warning",
    SnackPosition position = SnackPosition.TOP,
  }) {
    show(
      title: title,
      message: message,
      isSuccess: false,
      snackPosition: position,
    );
  }

  static void serverError({
    String? message,
    int? statusCode,
    String title = "Server Error",
    SnackPosition position = SnackPosition.TOP,
  }) {
    final codeBadge = (statusCode != null && statusCode > 0)
        ? " ($statusCode)"
        : "";
    show(
      title: "$title$codeBadge",
      message:
          message ??
          "The server is currently unavailable. Please try again shortly.",
      isSuccess: false,
      snackPosition: position,
    );
  }
}
