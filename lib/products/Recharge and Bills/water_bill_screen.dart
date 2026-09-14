import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/products/Recharge and Bills/theme.dart';
import 'package:transwallet/products/Recharge and Bills/pay_summary_sheet.dart';
import 'package:transwallet/products/Recharge and Bills/payment_success_screen.dart';

class WaterBillScreen extends StatefulWidget {
  const WaterBillScreen({super.key});

  @override
  State<WaterBillScreen> createState() => _WaterBillScreenState();
}

class _WaterBillScreenState extends State<WaterBillScreen> {
  final TextEditingController _consumerIdController = TextEditingController();
  final GetStorage _box = GetStorage();
  String _selectedBoard = "Delhi Jal Board";
  double? _fetchedAmount;
  bool _isFetching = false;

  final List<String> _boards = [
    "Delhi Jal Board",
    "BMC Water Department - Mumbai",
    "BWSSB - Bengaluru",
    "HMWSSB - Hyderabad",
  ];

  @override
  void dispose() {
    _consumerIdController.dispose();
    super.dispose();
  }

  void _fetchBill() {
    if (_consumerIdController.text.isEmpty) {
      Get.snackbar(
        "Invalid Consumer ID",
        "Please enter a valid Consumer ID.",
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
      return;
    }
    setState(() {
      _isFetching = true;
      _fetchedAmount = null;
    });

    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isFetching = false;
          _fetchedAmount = 350.00;
        });
      }
    });
  }

  void _onPay() {
    if (_fetchedAmount == null) return;

    Get.bottomSheet(
      PaySummarySheet(
        title: "Water Bill Payment",
        subtitle: "CA: ${_consumerIdController.text} ($_selectedBoard)",
        amount: _fetchedAmount!,
        onSuccess: () {
          double currentBalance = _box.read('balance') ?? 45280.50;
          _box.write('balance', currentBalance - _fetchedAmount!);
          Get.offNamed(
            '/payment_success',
            arguments: {
              'title': "Water Bill Paid",
              'message': "Water bill of ₹$_fetchedAmount for Connection Account ${_consumerIdController.text} was completed.",
              'amount': _fetchedAmount!,
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
          "Water Bill",
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
              "Select Water Board",
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
              "Connection / Consumer ID",
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
                controller: _consumerIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter Connection CA Number",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_fetchedAmount == null)
              CustomButton(
                text: "Fetch Water Bill",
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
            if (_fetchedAmount != null) ...[
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
                          "Outstanding Bill",
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Due Date: End of month",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "₹$_fetchedAmount",
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
