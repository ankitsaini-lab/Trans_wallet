import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/products/Recharge and Bills/theme.dart';
import 'package:transwallet/products/Recharge and Bills/pay_summary_sheet.dart';
import 'package:transwallet/products/Recharge and Bills/payment_success_screen.dart';

class GasBillScreen extends StatefulWidget {
  const GasBillScreen({super.key});

  @override
  State<GasBillScreen> createState() => _GasBillScreenState();
}

class _GasBillScreenState extends State<GasBillScreen> {
  final TextEditingController _customerIdController = TextEditingController();
  final GetStorage _box = GetStorage();
  String _selectedProvider = "Indraprastha Gas (IGL)";
  double? _fetchedAmount;
  bool _isFetching = false;

  final List<String> _providers = [
    "Indraprastha Gas (IGL)",
    "Mahanagar Gas (MGL)",
    "Adani Gas",
    "Gujarat Gas (GGL)",
  ];

  @override
  void dispose() {
    _customerIdController.dispose();
    super.dispose();
  }

  void _fetchBill() {
    if (_customerIdController.text.isEmpty) {
      Get.snackbar(
        "Invalid Customer ID",
        "Please enter a valid Customer ID.",
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
          _fetchedAmount = 820.00;
        });
      }
    });
  }

  void _onPay() {
    if (_fetchedAmount == null) return;

    Get.bottomSheet(
      PaySummarySheet(
        title: "Gas Bill Payment",
        subtitle: "Cust ID: ${_customerIdController.text} ($_selectedProvider)",
        amount: _fetchedAmount!,
        onSuccess: () {
          double currentBalance = _box.read('balance') ?? 45280.50;
          _box.write('balance', currentBalance - _fetchedAmount!);
          Get.offNamed(
            '/payment_success',
            arguments: {
              'title': "Gas Bill Paid",
              'message': "Piped gas bill of ₹$_fetchedAmount for Customer ID ${_customerIdController.text} was completed.",
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
          "Gas Bill",
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
              "Select Gas Provider",
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
                  value: _selectedProvider,
                  items: _providers.map((p) {
                    return DropdownMenuItem(value: p, child: Text(p));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedProvider = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Customer BP Number",
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
                controller: _customerIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter BP / Customer Number",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_fetchedAmount == null)
              CustomButton(
                text: "Fetch Gas Bill",
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
                          "Due Date: 15th next month",
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
