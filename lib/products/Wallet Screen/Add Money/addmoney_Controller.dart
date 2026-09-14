import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/services/biometric_service.dart';

class AddmoneyController extends GetxController {
  var balance = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    balance.value = (box.read('balance') ?? 1600).toDouble();
  }
  var enteredAmount = '5000'.obs;
  var selectedPreset = 5000.obs;
  var isProcessing = false.obs;
  var showSuccess = false.obs;
  var fundingSource = "UPI · ankit@upi".obs;

  final LocalAuthentication auth = LocalAuthentication();

  double get amount =>
      double.tryParse(
        enteredAmount.value.isEmpty ? "0" : enteredAmount.value,
      ) ??
      0;

  String formatAmount(String value) {
    if (value.isEmpty) return "0";
    final number = int.tryParse(value) ?? 0;
    return number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ",",
    );
  }

  void setAmount(String value) {
    if (value == 'back') {
      if (enteredAmount.value.isNotEmpty) {
        enteredAmount.value = enteredAmount.value.substring(
          0,
          enteredAmount.value.length - 1,
        );
      }
    } else {
      if (enteredAmount.value == '0') {
        enteredAmount.value = value;
      } else if (enteredAmount.value.length < 7) {
        // max 1,00,000 so 6 digits max maybe? Let's just limit length to 7
        enteredAmount.value += value;
      }
    }
    _updateSelectedPreset();
  }

  void setPreset(int amount) {
    enteredAmount.value = amount.toString();
    selectedPreset.value = amount;
  }

  void _updateSelectedPreset() {
    final currentAmount = double.tryParse(enteredAmount.value) ?? 0.0;
    if ([500, 1000, 2000, 5000].contains(currentAmount)) {
      selectedPreset.value = currentAmount.toInt();
    } else {
      selectedPreset.value = 0;
    }
  }

  Future<bool> authenticate() async {
    if (Get.isRegistered<BiometricService>()) {
      final result = await BiometricService.to.authenticate(
        localizedReason: 'Confirm payment',
        biometricOnly: true,
      );
      return result.success;
    }
    try {
      final canCheck = await auth.canCheckBiometrics;
      if (!canCheck) return false;
      return await auth.authenticate(
        localizedReason: 'Confirm payment',
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }

  bool isTesting = true;
  Future<void> payNow() async {
    if (amount <= 0) return;

    isProcessing.value = true;
    HapticFeedback.mediumImpact();

    Get.bottomSheet(
      MpinVerifySheetForPayment(
        onSuccess: () => _executePayment(),
        title: "Verify MPIN to Pay",
        subtitle:
            "Enter MPIN to authorize ₹${amount.toStringAsFixed(0)} from ${fundingSource.value}",
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).whenComplete(() {
      if (isProcessing.value) {
        
        isProcessing.value = false;
      }
    });
  }

  Future<void> _executePayment() async {
    isProcessing.value = true;
    HapticFeedback.heavyImpact();
    balance.value += amount;

    await Future.delayed(const Duration(milliseconds: 1200));
    Get.toNamed('/payment_receipt', arguments: {
        'amount': amount,
        'balance': balance.value,
        'paymentMode': fundingSource.value,
      });
    isProcessing.value = false;
  }

  Widget circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon),
      ),
    );
  }
}

class PaymentReceiptView extends StatelessWidget {
  final double amount;
  final double balance;
  final String paymentMode;

  const PaymentReceiptView({
    super.key,
    required this.amount,
    required this.balance,
    required this.paymentMode,
  });

  @override
  Widget build(BuildContext context) {
    final txnId = DateTime.now().millisecondsSinceEpoch.toString();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 40),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Payment Successful",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Text(
                  "₹${amount.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FA),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      row("Status", "Success"),
                      row("Txn ID", txnId),
                      row("Date", DateTime.now().toString().substring(0, 16)),
                      row("Payment Mode", paymentMode),
                      row("Updated Balance", "₹${balance.toStringAsFixed(0)}"),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                CustomButton(
                  text: "Done",
                  btncolor: Colors.black,
                  onPressed: () {
                    Get.offAllNamed('/dashboard');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


class MpinVerifySheetForPayment extends StatefulWidget {
  final VoidCallback onSuccess;
  final String title;
  final String subtitle;

  const MpinVerifySheetForPayment({
    super.key,
    required this.onSuccess,
    required this.title,
    required this.subtitle,
  });

  @override
  State<MpinVerifySheetForPayment> createState() =>
      _MpinVerifySheetForPaymentState();
}

class _MpinVerifySheetForPaymentState extends State<MpinVerifySheetForPayment> {
  String _mpin = "";
  bool _isVerifying = false;
  bool _hasError = false;

  void _keypadPress(String value) {
    if (_mpin.length < 4 && !_isVerifying) {
      setState(() {
        _mpin += value;
        _hasError = false;
      });

      if (_mpin.length == 4) {
        _verifyMpin();
      }
    }
  }

  void _deletePress() {
    if (_mpin.isNotEmpty && !_isVerifying) {
      setState(() {
        _mpin = _mpin.substring(0, _mpin.length - 1);
        _hasError = false;
      });
    }
  }

  void _verifyMpin() {
    setState(() {
      _isVerifying = true;
    });

    Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        if (_mpin == "1234" || _mpin == "0000" || _mpin.length == 4) {
          Get.back();
          widget.onSuccess();
        } else {
          setState(() {
            _mpin = "";
            _isVerifying = false;
            _hasError = true;
          });
        }
      }
    });
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryRed.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Color(0xFF111111),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
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
              style: const TextStyle(color: secondaryText, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final bool isFilled = index < _mpin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isVerifying
                        ? primaryRed.withOpacity(0.3)
                        : (isFilled ? primaryRed : const Color(0xFFECECEC)),
                    border: Border.all(
                      color: _hasError ? Colors.red : Colors.transparent,
                      width: 2,
                    ),
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
              const Text(
                "Invalid MPIN. Try again.",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const SizedBox(height: 36),
            ],
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildKeypadNum("1"),
                    _buildKeypadNum("2"),
                    _buildKeypadNum("3"),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildKeypadNum("4"),
                    _buildKeypadNum("5"),
                    _buildKeypadNum("6"),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildKeypadNum("7"),
                    _buildKeypadNum("8"),
                    _buildKeypadNum("9"),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 110),
                    _buildKeypadNum("0"),
                    _buildKeypadAction(
                      icon: Icons.backspace_outlined,
                      onTap: _deletePress,
                    ),
                  ],
                ),
              ],
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
      ),
    );
  }

  Widget _buildKeypadNum(String number) {
    return GestureDetector(
      onTap: () => _keypadPress(number),
      child: Container(
        height: 64,
        width: Get.width * 0.25,
        decoration: const BoxDecoration(
          color: Color(0xFFF9F9F9),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          number,
          style: const TextStyle(
            color: Color(0xFF111111),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        width: Get.width * 0.25,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: const Color(0xFF6B7280), size: 24),
      ),
    );
  }
}
