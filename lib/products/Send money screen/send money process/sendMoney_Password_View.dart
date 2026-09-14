import 'package:flutter/material.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendMoney_Password_Controller.dart';

class SendMoneyPasswordView extends GetView<SendMoneyPasswordController> {
  const SendMoneyPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => SendMoneyPasswordController());

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
          "Password",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 20,
            letterSpacing: 0,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Lock Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryYellow, width: 2),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Colors.orange,
                size: 28,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Enter your password",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Enter your 4-digit passcode in order to perform this transaction.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Dots indicator
            Obx(() {
              final length = controller.passcode.value.length;
              final isError = controller.isError.value;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? (isError ? Colors.red : Colors.black)
                          : Colors.transparent,
                      border: Border.all(
                        color: isFilled
                            ? (isError ? Colors.red : Colors.black)
                            : Colors.black45,
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              );
            }),

            const Spacer(),

            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 1.8,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  _keypadButton("1"),
                  _keypadButton("2"),
                  _keypadButton("3"),
                  _keypadButton("4"),
                  _keypadButton("5"),
                  _keypadButton("6"),
                  _keypadButton("7"),
                  _keypadButton("8"),
                  _keypadButton("9"),
                  const SizedBox(),
                  _keypadButton("0"),
                  _keypadButton("back", isIcon: true),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _keypadButton(String value, {bool isIcon = false}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        controller.addDigit(value);
      },
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
    );
  }
}
