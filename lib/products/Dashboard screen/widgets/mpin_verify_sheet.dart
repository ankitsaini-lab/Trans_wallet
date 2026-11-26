import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/pressable_scale.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/widgets/custom_numeric_keypad.dart';

class MpinVerifySheet extends StatefulWidget {
  final VoidCallback onSuccess;
  final String title;
  final String subtitle;

  const MpinVerifySheet({
    super.key,
    required this.onSuccess,
    this.title = "Enter MPIN to View Balance",
    this.subtitle = "For your security, enter your 4-digit mobile PIN",
  });

  /// Presents the MPIN verification bottom sheet and awaits verification.
  /// Returns `true` only if MPIN was verified successfully via the API.
  static Future<bool> show({
    String title = "Enter MPIN for Confirmation",
    String subtitle = "Enter your 4-digit MPIN for confirmation",
  }) async {
    final result = await Get.bottomSheet<bool>(
      MpinVerifySheet(
        title: title,
        subtitle: subtitle,
        onSuccess: () {},
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
    );
    return result == true;
  }

  @override
  State<MpinVerifySheet> createState() => _MpinVerifySheetState();
}

class _MpinVerifySheetState extends State<MpinVerifySheet> {
  String _mpin = "";
  bool _isVerifying = false;
  bool _hasError = false;
  String _errorMessage = "";

  void _keypadPress(String value) {
    if (_isVerifying) return;

    setState(() {
      if (_hasError) {
        _hasError = false;
        _errorMessage = "";
        _mpin = "";
      }
      if (_mpin.length < 4) {
        _mpin += value;
      }
    });

    if (_mpin.length == 4) {
      _verifyMpin();
    }
  }

  void _deletePress() {
    if (_isVerifying) {
      _isVerifying = false;
    }
    setState(() {
      _hasError = false;
      _errorMessage = "";
      if (_mpin.isNotEmpty) {
        _mpin = _mpin.substring(0, _mpin.length - 1);
      }
    });
  }

  void _clearPress() {
    if (_isVerifying) {
      _isVerifying = false;
    }
    setState(() {
      _hasError = false;
      _errorMessage = "";
      _mpin = "";
    });
  }

  Future<void> _verifyMpin() async {
    final pinToVerify = _mpin;

    setState(() {
      _isVerifying = true;
      _hasError = false;
      _errorMessage = "";
    });

    MpinVerifyResponse res;
    if (Get.isRegistered<ApiService>()) {
      res = await ApiService.to.verifyMpin(pinToVerify);
    } else {
      final box = GetStorage();
      final savedMpin =
          box.read<String>('saved_mpin') ?? box.read('mpin')?.toString();
      final ok = savedMpin != null && savedMpin == pinToVerify;
      res = MpinVerifyResponse(
        isSuccess: ok,
        message: ok ? 'MPIN verified' : 'Invalid MPIN. Try again.',
      );
    }

    if (mounted) {
      if (res.isSuccess) {
        if (Get.isRegistered<AppLockService>()) {
          AppLockService.to.clearMpinLockout();
        }
        Get.back(result: true);
        widget.onSuccess();
      } else {
        setState(() {
          _mpin = pinToVerify;
          _isVerifying = false;
          _hasError = true;
          _errorMessage = res.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Color(0xFFED292A);
    const Color textColor = Color(0xFF111111);
    const Color secondaryText = Color(0xFF6B7280);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFECECEC),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryRed.withOpacity(0.12),
              border: Border.all(
                color: primaryRed.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.lock_rounded,
                color: primaryRed,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: secondaryText, fontSize: 13),
          ),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final bool isFilled = index < _mpin.length;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled
                      ? (_hasError
                          ? primaryRed
                          : (_isVerifying
                              ? primaryRed.withOpacity(0.4)
                              : primaryRed))
                      : Colors.white,
                  border: Border.all(
                    color: isFilled
                        ? primaryRed
                        : (_hasError
                            ? primaryRed.withOpacity(0.35)
                            : Colors.black.withOpacity(0.18)),
                    width: 2,
                  ),
                  boxShadow: (isFilled && !_hasError)
                      ? [
                          BoxShadow(
                            color: primaryRed.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          if (_isVerifying) ...[
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
              ),
            ),
            const SizedBox(height: 16),
          ] else if (_hasError) ...[
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: primaryRed,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            const SizedBox(height: 36),
          ],

          CustomNumericKeypad(
            onDigitTap: _keypadPress,
            onDeleteTap: _deletePress,
            onClear: _clearPress,
          ),
          const SizedBox(height: 20),

          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: secondaryText,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
