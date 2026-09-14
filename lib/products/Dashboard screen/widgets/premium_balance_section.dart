import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/services/biometric_service.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/mpin_verify_sheet.dart';

class PremiumBalanceSection extends StatefulWidget {
  const PremiumBalanceSection({super.key});

  @override
  State<PremiumBalanceSection> createState() => _PremiumBalanceSectionState();
}

class _PremiumBalanceSectionState extends State<PremiumBalanceSection> {
  bool _isRevealed = false;
  Timer? _autoHideTimer;

  void _toggleBalance() {
    if (_isRevealed) {
      _autoHide();
    } else {
      _showMpinSheet();
    }
  }

  Future<void> _reveal() async {
    if (Get.isRegistered<ApiService>()) {
      await ApiService.to.fetchWalletBalance();
    }

    if (mounted) {
      setState(() {
        _isRevealed = true;
      });

      _autoHideTimer?.cancel();
      _autoHideTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _isRevealed = false;
          });
        }
      });
    }
  }

  void _autoHide() {
    _autoHideTimer?.cancel();
    setState(() {
      _isRevealed = false;
    });
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    super.dispose();
  }

  Future<void> _showMpinSheet() async {
    if (Get.isRegistered<BiometricService>()) {
      final bioService = BiometricService.to;
      if (bioService.isBiometricAvailable && bioService.isBiometricEnabled.value) {
        final result = await bioService.authenticate(
          localizedReason: "Authenticate to view total balance",
        );
        if (result.success && mounted) {
          _reveal();
          return;
        }
      }
    }

    Get.bottomSheet(
      MpinVerifySheet(
        onSuccess: _reveal,
        title: "Enter MPIN to View Balance",
        subtitle: "For your security, enter your 4-digit mobile PIN or use biometrics",
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color _textColor = Color(0xFF111111);
    const Color _secondaryText = Color(0xFF6B7280);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    "Total Balance",
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleBalance,
                    child: Icon(
                      _isRevealed
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: const Color(0xFF111111),
                      size: 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _toggleBalance,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedCrossFade(
                      firstChild: const Text(
                        "₹ ••••••",
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      secondChild: Text(
                        "₹${((box.read('balance') ?? 0) as num).toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: _textColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
                      ),
                      crossFadeState: _isRevealed
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 250),
                    ),
                    if (!_isRevealed) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFCC00).withOpacity(0.15),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF111111),
                          size: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
