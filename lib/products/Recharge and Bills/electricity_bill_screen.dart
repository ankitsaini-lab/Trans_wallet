import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/products/Recharge and Bills/theme.dart';
import 'package:transwallet/products/Recharge and Bills/pay_summary_sheet.dart';
import 'package:transwallet/products/Recharge and Bills/payment_success_screen.dart';

class ElectricityBillScreen extends StatefulWidget {
  const ElectricityBillScreen({super.key});

  @override
  State<ElectricityBillScreen> createState() => _ElectricityBillScreenState();
}

class _ElectricityBillScreenState extends State<ElectricityBillScreen> {
  final TextEditingController _consumerController = TextEditingController();
  final GetStorage _box = GetStorage();
  String _selectedBoard = "BSES Rajdhani - Delhi";
  double? _fetchedBillAmount;
  bool _isFetching = false;

  final List<String> _boards = [
    "BSES Rajdhani - Delhi",
    "Tata Power - Mumbai",
    "BESCOM - Bengaluru",
    "MSEDCL - Maharashtra",
  ];

  @override
  void dispose() {
    _consumerController.dispose();
    super.dispose();
  }

  void _fetchBill() {
    if (_consumerController.text.length < 5) {
      Get.snackbar(
        "Invalid Consumer Number",
        "Please enter a valid Consumer ID.",
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
      return;
    }
    setState(() {
      _isFetching = true;
      _fetchedBillAmount = null;
    });

    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isFetching = false;
          _fetchedBillAmount = 1450.00;
        });
      }
    });
  }

  void _onPay() {
    if (_fetchedBillAmount == null) return;

    Get.bottomSheet(
      PaySummarySheet(
        title: "Electricity Bill",
        subtitle: "CA: ${_consumerController.text} ($_selectedBoard)",
        amount: _fetchedBillAmount!,
        onSuccess: () {
          double currentBalance = _box.read('balance') ?? 45280.50;
          _box.write('balance', currentBalance - _fetchedBillAmount!);
          Get.offNamed(
            '/payment_success',
            arguments: {
              'title': "Bill Paid Successfully",
              'message': "Electricity bill of ₹$_fetchedBillAmount for Consumer Account ${_consumerController.text} was completed successfully.",
              'amount': _fetchedBillAmount!,
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
          "Electricity Bill",
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
              "Select Electricity Board",
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
                  value: _selectedBoard,
                  items: _boards.map((b) {
                    return DropdownMenuItem(value: b, child: Text(b));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBoard = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Consumer Account Number",
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
                controller: _consumerController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter Consumer CA Number",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_fetchedBillAmount == null)
              CustomButton(
                text: "Fetch Outstanding Bill",
                btncolor: Colors.black,
                onPressed: _fetchBill,
                prefixIcon: _isFetching
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : null,
              ),
            if (_fetchedBillAmount != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Outstanding Amount",
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Due Date: 12th next month",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "₹$_fetchedBillAmount",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: "Pay Bill",
                btncolor: Colors.black,
                onPressed: _onPay,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
