import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/products/Recharge and Bills/theme.dart';
import 'package:transwallet/products/Recharge and Bills/pay_summary_sheet.dart';
import 'package:transwallet/products/Recharge and Bills/payment_success_screen.dart';

class LoanEmiPaymentScreen extends StatefulWidget {
  const LoanEmiPaymentScreen({super.key});

  @override
  State<LoanEmiPaymentScreen> createState() => _LoanEmiPaymentScreenState();
}

class _LoanEmiPaymentScreenState extends State<LoanEmiPaymentScreen> {
  final TextEditingController _loanAccountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final GetStorage _box = GetStorage();
  String _selectedLender = "Bajaj Finance";

  final List<String> _lenders = [
    "Bajaj Finance",
    "Muthoot Finance",
    "L&T Finance",
    "HDFC Home Loans",
  ];

  @override
  void dispose() {
    _loanAccountController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onPay() {
    if (_loanAccountController.text.isEmpty) {
      Get.snackbar(
        "Invalid Account ID",
        "Please enter a valid loan account number.",
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
      return;
    }
    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      Get.snackbar(
        "Invalid Amount",
        "Please enter a valid amount.",
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
      return;
    }

    Get.bottomSheet(
      PaySummarySheet(
        title: "Loan EMI Payment",
        subtitle: "Loan ID: ${_loanAccountController.text} ($_selectedLender)",
        amount: amount,
        onSuccess: () {
          double currentBalance = _box.read('balance') ?? 45280.50;
          _box.write('balance', currentBalance - amount);
          Get.offNamed(
            '/payment_success',
            arguments: {
              'title': "EMI Payment Successful",
              'message': "EMI payment of ₹$amount to $_selectedLender has been completed successfully.",
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
          "Loan/EMI Payments",
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
              "Select Financial Institution / Lender",
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
                  value: _selectedLender,
                  items: _lenders.map((l) {
                    return DropdownMenuItem(value: l, child: Text(l));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedLender = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Loan Account Number",
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
                controller: _loanAccountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter Loan Account ID Number",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "EMI Amount to Pay",
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
                  hintText: "Enter EMI Amount",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: "Proceed to EMI Payment",
              btncolor: Colors.black,
              onPressed: _onPay,
            ),
          ],
        ),
      ),
    );
  }
}
