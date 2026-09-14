import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/products/Recharge and Bills/theme.dart';
import 'package:transwallet/products/Recharge and Bills/pay_summary_sheet.dart';
import 'package:transwallet/products/Recharge and Bills/payment_success_screen.dart';

class MobileRechargeScreen extends StatefulWidget {
  const MobileRechargeScreen({super.key});

  @override
  State<MobileRechargeScreen> createState() => _MobileRechargeScreenState();
}

class _MobileRechargeScreenState extends State<MobileRechargeScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final GetStorage _box = GetStorage();
  String _selectedOperator = "Jio";
  String? _selectedPlan;
  final List<String> _operators = ["Jio", "Airtel", "Vi", "BSNL"];

  final List<Map<String, dynamic>> _plans = [
    {
      "price": 299,
      "validity": "28 Days",
      "data": "1.5 GB/Day",
      "desc": "Unlimited calls + 100 SMS/Day",
    },
    {
      "price": 719,
      "validity": "84 Days",
      "data": "2.0 GB/Day",
      "desc": "Disney+ Hotstar subscription included",
    },
    {
      "price": 239,
      "validity": "24 Days",
      "data": "1.0 GB/Day",
      "desc": "Popular budget data plan",
    },
    {
      "price": 1799,
      "validity": "365 Days",
      "data": "24 GB Total",
      "desc": "Best yearly plan for voice calls",
    },
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onPay() {
    if (_phoneController.text.length < 10) {
      Get.snackbar(
        "Invalid Input",
        "Please enter a valid 10-digit mobile number.",
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
      return;
    }
    if (_selectedPlan == null) {
      Get.snackbar(
        "Select Plan",
        "Please select a recharge plan to continue.",
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
      return;
    }

    final selectedPlanDetails = _plans.firstWhere(
      (p) => p["price"].toString() == _selectedPlan,
    );
    final int amount = selectedPlanDetails["price"] as int;

    Get.bottomSheet(
      PaySummarySheet(
        title: "Mobile Recharge",
        subtitle: "${_phoneController.text} ($_selectedOperator)",
        amount: amount.toDouble(),
        onSuccess: () {
          double currentBalance = _box.read('balance') ?? 45280.50;
          _box.write('balance', currentBalance - amount);
          Get.offNamed(
            '/payment_success',
            arguments: {
              'title': "Recharge Successful",
              'message': "Mobile recharge of ₹$amount for ${_phoneController.text} has been processed successfully.",
              'amount': amount.toDouble(),
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
          "Mobile Recharge",
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
              "Enter Mobile Details",
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
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  icon: Icon(Icons.phone_iphone_rounded, color: secondaryText),
                  hintText: "10-digit Mobile Number",
                  counterText: "",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Select Operator",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _operators.map((op) {
                final isSelected = _selectedOperator == op;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedOperator = op),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.black : borderColor,
                        ),
                      ),
                      child: Text(
                        op,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              "Select Plan",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: _plans.map((p) {
                final isSelected = _selectedPlan == p["price"].toString();
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedPlan = p["price"].toString()),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? primaryRed : borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "₹${p["price"]}",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      p["validity"] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: secondaryText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Data: ${p["data"]}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p["desc"] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected ? primaryRed : borderColor,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: "Proceed to Recharge",
              btncolor: Colors.black,
              onPressed: _onPay,
            ),
          ],
        ),
      ),
    );
  }
}
