import 'package:flutter/material.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/notification_button.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendmoneyProcess_Controller.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/products/Notification%20screen/notification_View.dart';

class SendmoneyprocessView extends GetView<SendmoneyprocessController> {
  const SendmoneyprocessView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => SendmoneyprocessController());

    // Fallback recipient if arguments not passed (e.g. debugging)
    final recipient =
        controller.recipient ??
        {"name": "Ankit Saini", "phone": "+61 9327856473", "avatar": "AS"};

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        title: const Text(
          "Send Money",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 20,
            letterSpacing: 0,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: const NotificationButton(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Recipient Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: primaryYellow.withOpacity(0.2),
                              child: Text(
                                recipient['avatar'] ?? 'AS',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recipient['name'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    recipient['phone'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryYellow.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "ENTER AMOUNT",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Amount Display
                    Obx(() {
                      final amountStr = controller.enteredAmount.value.isEmpty
                          ? "0"
                          : controller.enteredAmount.value;
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  "₹",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                amountStr,
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 8),

                    // Subtitle limits
                    const Text(
                      "Minimum ₹1 · Maximum ₹1,00,000",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Presets
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _presetPill(500, "₹500"),
                          const SizedBox(width: 8),
                          _presetPill(1000, "₹1,000"),
                          const SizedBox(width: 8),
                          _presetPill(2000, "₹2,000"),
                          const SizedBox(width: 8),
                          _presetPill(5000, "₹5,000"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Note
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Container(
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: controller.noteController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: "Add a note (optional)",
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _keypadButton("1")),
                      const SizedBox(width: 10),
                      Expanded(child: _keypadButton("2")),
                      const SizedBox(width: 10),
                      Expanded(child: _keypadButton("3")),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _keypadButton("4")),
                      const SizedBox(width: 10),
                      Expanded(child: _keypadButton("5")),
                      const SizedBox(width: 10),
                      Expanded(child: _keypadButton("6")),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _keypadButton("7")),
                      const SizedBox(width: 10),
                      Expanded(child: _keypadButton("8")),
                      const SizedBox(width: 10),
                      Expanded(child: _keypadButton("9")),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _keypadButton(".")),
                      const SizedBox(width: 10),
                      Expanded(child: _keypadButton("0")),
                      const SizedBox(width: 10),
                      Expanded(child: _keypadButton("back", isIcon: true)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Send Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Obx(
                () => CustomButton(
                  text: "Send",
                  btncolor: primaryRed,
                  textColor: Colors.black,
                  borderRadius: 24,
                  onPressed: controller.amount > 0
                      ? () => controller.proceedToPassword()
                      : () {},
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetPill(int value, String label) {
    return Obx(() {
      final isSelected = controller.selectedPreset.value == value;
      return GestureDetector(
        onTap: () => controller.setPreset(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFEA66) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFFEA66)
                  : Colors.grey.shade200,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      );
    });
  }

  Widget _keypadButton(String value, {bool isIcon = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (value == '.')
          return; // Ignore dot for now or implement decimal logic in controller
        controller.setAmount(value);
      },
      child: AspectRatio(
        aspectRatio: 2.2,
        child: Center(
          child: isIcon
              ? const Icon(
                  Icons.backspace_outlined,
                  size: 24,
                  color: Colors.black,
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
        ),
      ),
    );
  }
}
