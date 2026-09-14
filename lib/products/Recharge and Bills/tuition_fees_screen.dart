import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/products/Recharge and Bills/theme.dart';
import 'package:transwallet/products/Recharge and Bills/pay_summary_sheet.dart';
import 'package:transwallet/products/Recharge and Bills/payment_success_screen.dart';

class TuitionFeesScreen extends StatefulWidget {
  const TuitionFeesScreen({super.key});

  @override
  State<TuitionFeesScreen> createState() => _TuitionFeesScreenState();
}

class _TuitionFeesScreenState extends State<TuitionFeesScreen> {
  final TextEditingController _studentController = TextEditingController();
  final TextEditingController _rollNoController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final GetStorage _box = GetStorage();
  String _selectedInstitute = "DPS International";

  final List<String> _institutes = [
    "DPS International",
    "Amity Global School",
    "Harvard High School",
    "GD Goenka Academy",
  ];

  @override
  void dispose() {
    _studentController.dispose();
    _rollNoController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onPay() {
    if (_studentController.text.isEmpty || _rollNoController.text.isEmpty) {
      Get.snackbar(
        "Invalid Input",
        "Please enter Student Name and Roll Number.",
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
        title: "Tuition Fees Payment",
        subtitle: "${_studentController.text} - $_selectedInstitute",
        amount: amount,
        onSuccess: () {
          double currentBalance = _box.read('balance') ?? 45280.50;
          _box.write('balance', currentBalance - amount);
          Get.offNamed(
            '/payment_success',
            arguments: {
              'title': "Fees Paid Successfully",
              'message': "Tuition fees of ₹$amount for ${_studentController.text} at $_selectedInstitute has been credited.",
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
          "Tuition Fees",
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
              "Student Info",
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
              child: Column(
                children: [
                  TextField(
                    controller: _studentController,
                    decoration: const InputDecoration(
                      hintText: "Student Full Name",
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(color: borderColor, height: 1),
                  TextField(
                    controller: _rollNoController,
                    decoration: const InputDecoration(
                      hintText: "Roll Number / Student ID",
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Select Institute",
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
                  value: _selectedInstitute,
                  items: _institutes.map((inst) {
                    return DropdownMenuItem(value: inst, child: Text(inst));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedInstitute = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Fee Amount",
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
              text: "Pay Tuition Fees",
              btncolor: Colors.black,
              onPressed: _onPay,
            ),
          ],
        ),
      ),
    );
  }
}
