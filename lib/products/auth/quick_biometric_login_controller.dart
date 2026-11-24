import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/services/biometric_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

class QuickBiometricLoginController extends GetxController {
  final GetStorage _storage = GetStorage();

  final RxBool isAuthenticating = false.obs;
  final RxBool isVerifyingMpin = false.obs;
  final RxBool showMpinKeypad = false.obs;
  final RxString enteredPin = ''.obs;
  final RxString pinError = ''.obs;
  final RxString userPhone = ''.obs;
  final RxString userName = ''.obs;

  bool get isBiometricEnabled {
    if (Get.isRegistered<BiometricService>()) {
      return BiometricService.to.isBiometricEnabled.value;
    }
    return false;
  }

  bool get isBiometricAvailable {
    if (Get.isRegistered<BiometricService>()) {
      return BiometricService.to.isBiometricAvailable;
    }
    return false;
  }

  @override
  void onInit() {
    super.onInit();
    _loadUserInfo();
    showMpinKeypad.value = true;
  }

  void _loadUserInfo() {
    final phone = _storage.read<String>('phone') ??
        _storage.read<String>('mobileNumber') ??
        _storage.read<String>('remembered_phone') ??
        '';
    final name = _storage.read<String>('name') ??
        _storage.read<String>('remembered_name') ??
        'Transwallet User';

    userPhone.value = phone;
    userName.value = name;
  }

  String get maskedPhone {
    final p = userPhone.value;
    if (p.length >= 10) {
      return '${p.substring(0, 3)} **** ${p.substring(p.length - 4)}';
    }
    return p;
  }

  String get biometricLabel {
    if (Get.isRegistered<BiometricService>()) {
      return BiometricService.to.biometricTypeLabel;
    }
    return 'Biometrics';
  }

  IconData get biometricIcon {
    if (Get.isRegistered<BiometricService>()) {
      return BiometricService.to.biometricIcon;
    }
    return Icons.fingerprint_rounded;
  }

  /// Triggers native biometric login
  Future<void> triggerBiometricLogin() async {
    if (isAuthenticating.value) return;

    if (!Get.isRegistered<BiometricService>()) {
      switchToMpin();
      return;
    }

    final biometricService = BiometricService.to;
    if (!biometricService.isBiometricAvailable) {
      HapticFeedback.lightImpact();
      AppSnackbar.info(
        "Biometric authentication is not supported or enrolled on this device.",
        title: "Biometrics Unavailable",
      );
      switchToMpin();
      return;
    }

    if (!biometricService.isBiometricEnabled.value) {
      HapticFeedback.lightImpact();
      AppSnackbar.info(
        "Biometric authentication is disabled. Please enable it in Profile Settings.",
        title: "Biometrics Disabled",
      );
      switchToMpin();
      return;
    }

    if (!biometricService.canQuickLogin) {
      switchToMpin();
      return;
    }

    isAuthenticating.value = true;
    try {
      final success = await biometricService.authenticateAndLogin(
        mobileNumber: userPhone.value.isNotEmpty ? userPhone.value : null,
      );

      if (!success) {
        // Fallback to MPIN keypad on failure/cancellation
        showMpinKeypad.value = true;
      }
    } catch (e) {
      developer.log('[QuickBiometricLoginController] Error: $e');
      showMpinKeypad.value = true;
    } finally {
      isAuthenticating.value = false;
    }
  }

  void switchToMpin() {
    showMpinKeypad.value = true;
    _resetPin();
  }

  void switchToBiometrics() {
    if (!isBiometricAvailable) {
      HapticFeedback.lightImpact();
      AppSnackbar.info(
        "Biometric authentication is not supported or enrolled on this device.",
        title: "Biometrics Unavailable",
      );
      return;
    }
    if (!isBiometricEnabled) {
      HapticFeedback.lightImpact();
      AppSnackbar.info(
        "Biometric authentication is disabled. Please enable it in Profile Settings.",
        title: "Biometrics Disabled",
      );
      return;
    }
    showMpinKeypad.value = false;
    _resetPin();
    triggerBiometricLogin();
  }

  void _resetPin() {
    enteredPin.value = '';
    pinError.value = '';
    isVerifyingMpin.value = false;
  }

  void onKeyTap(String digit) {
    if (isVerifyingMpin.value) return;

    if (pinError.value.isNotEmpty) {
      pinError.value = '';
      enteredPin.value = '';
    }

    if (enteredPin.value.length >= 4) return;

    HapticFeedback.lightImpact();
    enteredPin.value += digit;

    if (enteredPin.value.length == 4) {
      verifyMpin(enteredPin.value);
    }
  }

  void onDeleteKey() {
    if (isVerifyingMpin.value) {
      isVerifyingMpin.value = false;
    }
    HapticFeedback.lightImpact();
    pinError.value = '';
    if (enteredPin.value.isNotEmpty) {
      enteredPin.value = enteredPin.value.substring(
        0,
        enteredPin.value.length - 1,
      );
    }
  }

  void clearPin() {
    if (isVerifyingMpin.value) {
      isVerifyingMpin.value = false;
    }
    HapticFeedback.mediumImpact();
    pinError.value = '';
    enteredPin.value = '';
  }

  Future<void> verifyMpin(String pinToVerify) async {
    isVerifyingMpin.value = true;
    try {
      if (Get.isRegistered<ApiService>()) {
        final res = await ApiService.to.verifyMpin(
          pinToVerify,
          mobileNumber: userPhone.value,
        );
        if (res.isSuccess) {
          if (Get.isRegistered<AppLockService>()) {
            AppLockService.to.clearMpinLockout();
          }
          await _onMpinLoginSuccess();
          return;
        } else {
          HapticFeedback.heavyImpact();
          final msg = res.message;
          pinError.value = msg;
          enteredPin.value = pinToVerify;
          return;
        }
      }

      // Offline fallback: check locally saved MPIN
      final savedMpin = _storage.read<String>('saved_mpin') ??
          _storage.read('mpin')?.toString();
      if (savedMpin != null && savedMpin == pinToVerify) {
        if (Get.isRegistered<AppLockService>()) {
          AppLockService.to.clearMpinLockout();
        }
        await _onMpinLoginSuccess();
        return;
      }

      HapticFeedback.heavyImpact();
      pinError.value = 'Incorrect MPIN. Please try again.';
      enteredPin.value = pinToVerify;
    } catch (e) {
      developer.log('[QuickBiometricLoginController] MPIN error: $e');
      pinError.value = 'MPIN verification failed.';
      enteredPin.value = pinToVerify;
    } finally {
      isVerifyingMpin.value = false;
    }
  }

  Future<void> _onMpinLoginSuccess() async {
    HapticFeedback.mediumImpact();
    _storage.write('is_logged_in', true);
    final bool wasAppLockActive =
        (_storage.read<bool>('app_lock_enabled') == true) &&
        (_storage.read<bool>('app_lock_disabled') != true);
    _storage.write('app_lock_enabled', wasAppLockActive);
    if (!wasAppLockActive) {
      _storage.write('app_lock_disabled', true);
    }
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.setAppLockEnabled(wasAppLockActive);
      AppLockService.to.clearColdStart();
    }
    if (Get.isRegistered<ApiService>()) {
      ApiService.to.registerDeviceToken();
    }
    AppSnackbar.success('Logged in successfully');
    Get.offAllNamed('/dashboard');
  }

  void navigateToFullLogin() {
    Get.offAllNamed('/login_singupview');
  }
}
