import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/products/Recharge and Bills/theme.dart';
import 'package:transwallet/products/Recharge and Bills/pay_summary_sheet.dart';
import 'package:transwallet/products/Recharge and Bills/payment_success_screen.dart';

class CreditCardBillScreen extends StatefulWidget {
  const CreditCardBillScreen({super.key});

  @override
  State<CreditCardBillScreen> createState() => _CreditCardBillScreenState();
}

class _CreditCardBillScreenState extends State<CreditCardBillScreen> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final GetStorage _box = GetStorage();
  String _selectedBank = "HDFC Bank";

  final List<String> _banks = [
    "HDFC Bank",
    "SBI Card",
    "ICICI Bank",
    "Axis Bank",
  ];

  @override
  void dispose() {
    _cardNumberController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onPay() {
    if (_cardNumberController.text.length < 16) {
      Get.snackbar(
        "Invalid Card",
        "Please enter a valid 16-digit credit card number.",
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
      return;
    }
    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      Get.snackbar(
        "Invalid Amount",
        "Please enter a valid payment amount.",
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
      return;
    }

    final maskedCard =
        "•••• •••• •••• ${_cardNumberController.text.substring(12)}";

    Get.bottomSheet(
      PaySummarySheet(
        title: "Credit Card Bill",
        subtitle: "$_selectedBank ($maskedCard)",
        amount: amount,
        onSuccess: () {
          double currentBalance = _box.read('balance') ?? 45280.50;
          _box.write('balance', currentBalance - amount);
          Get.offNamed(
            '/payment_success',
            arguments: {
              'title': "Card Bill Credited",
              'message': "Credit card payment of ₹$amount to $_selectedBank ($maskedCard) was successfully processed.",
              'amount': amount,
            },
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: appBarGradient)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFECECEC), width: 1.5),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: textColor,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          "Credit Card Bill",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 20,
            letterSpacing: 0,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Card Issuing Bank",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBank,
                  items: _banks.map((b) {
                    return DropdownMenuItem(value: b, child: Text(b));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBank = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Credit Card Number",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                maxLength: 16,
                decoration: const InputDecoration(
                  icon: Icon(Icons.credit_card_rounded, color: secondaryText),
                  hintText: "16-digit Card Number",
                  counterText: "",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Payment Amount",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: "₹ ",
                  hintText: "Enter Amount to Pay",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: "Pay Bill",
              btncolor: Colors.black,
              onPressed: _onPay,
            ),
          ],
        ),
      ),
    );
  }
}
