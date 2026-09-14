import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/products/Recharge and Bills/theme.dart';
import 'package:transwallet/products/Recharge and Bills/pay_summary_sheet.dart';
import 'package:transwallet/products/Recharge and Bills/payment_success_screen.dart';

class FastagRechargeScreen extends StatefulWidget {
  const FastagRechargeScreen({super.key});

  @override
  State<FastagRechargeScreen> createState() => _FastagRechargeScreenState();
}

class _FastagRechargeScreenState extends State<FastagRechargeScreen> {
  final TextEditingController _vehicleNoController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final GetStorage _box = GetStorage();
  String _selectedBank = "Paytm Fastag";

  final List<String> _banks = [
    "Paytm Fastag",
    "NHAI Fastag",
    "HDFC Bank Fastag",
    "ICICI Bank Fastag",
  ];

  @override
  void dispose() {
    _vehicleNoController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onPay() {
    if (_vehicleNoController.text.length < 6) {
      Get.snackbar(
        "Invalid Vehicle Number",
        "Please enter a valid vehicle registration number.",
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

    final vehicleUpper = _vehicleNoController.text.toUpperCase();

    Get.bottomSheet(
      PaySummarySheet(
        title: "Fastag Recharge",
        subtitle: "$vehicleUpper ($_selectedBank)",
        amount: amount,
        onSuccess: () {
          double currentBalance = _box.read('balance') ?? 45280.50;
          _box.write('balance', currentBalance - amount);
          Get.offNamed(
            '/payment_success',
            arguments: {
              'title': "Fastag Recharge Completed",
              'message': "Fastag recharge of ₹$amount for vehicle $vehicleUpper has been completed successfully.",
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
          "Fastag Recharge",
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
              "Select Fastag Issuer Bank",
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
              "Vehicle Registration Number",
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
                controller: _vehicleNoController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: "e.g. DL 1C A 1234",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Recharge Amount",
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
                  hintText: "Enter Amount",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: "Recharge Fastag",
              btncolor: Colors.black,
              onPressed: _onPay,
            ),
          ],
        ),
      ),
    );
  }
}
