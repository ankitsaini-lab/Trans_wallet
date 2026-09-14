import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/products/Recharge and Bills/theme.dart';

class PaySummarySheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final VoidCallback onSuccess;

  const PaySummarySheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Payment Confirmation",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                _buildSummaryRow("Service", title),
                const Divider(color: borderColor, height: 16),
                _buildSummaryRow("Details", subtitle),
                const Divider(color: borderColor, height: 16),
                _buildSummaryRow(
                  "Amount to Pay",
                  "₹$amount",
                  isBoldValue: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: "Confirm & Pay ₹$amount",
            btncolor: Colors.black,
            onPressed: () {
              Get.back(); // close sheet
              onSuccess();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBoldValue = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: isBoldValue ? 16 : 13,
            fontWeight: isBoldValue ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
