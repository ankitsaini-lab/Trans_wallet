import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/services/biometric_service.dart';
import 'package:transwallet/services/network_service.dart';

class SplashscreenController extends GetxController {
  Worker? _netWorker;
  bool _hasNavigated = false;

  @override
  void onInit() {
    super.onInit();
    // Listen for internet connection restoration to resume navigation automatically
    if (Get.isRegistered<NetworkService>()) {
      _netWorker = ever<bool>(NetworkService.to.isConnected, (connected) {
        if (connected && !_hasNavigated) {
          splash();
        }
      });
    }
  }

  @override
  void onReady() {
    super.onReady();
    splash();
  }

  @override
  void onClose() {
    _netWorker?.dispose();
    super.onClose();
  }

  Future<void> splash() async {
    if (_hasNavigated) return;

    try {
      // Verify internet connectivity before proceeding
      if (Get.isRegistered<NetworkService>()) {
        NetworkService.to.checkConnectivity();
      }

      // Smooth splash video duration delay
      await Future.delayed(const Duration(milliseconds: 2800));

      if (_hasNavigated) return;
      _hasNavigated = true;

      // 1. Is there an active valid user session?
      if (Get.isRegistered<AuthService>() && AuthService.to.isLoggedIn) {
        Get.offAllNamed('/dashboard');
        return;
      }

      // 2. Is Biometric Quick Login enabled for a returning user?
      if (Get.isRegistered<BiometricService>() &&
          BiometricService.to.canQuickLogin) {
        Get.offAllNamed('/quick_biometric_login');
        return;
      }

      // 3. Fallback to normal onboarding / login screen
      Get.offAllNamed('/login_singupview');
    } catch (e) {
      debugPrint('[SplashscreenController] Exception during splash: $e');
      if (!_hasNavigated) {
        _hasNavigated = true;
        Get.offAllNamed('/login_singupview');
      }
    }
  }
}
