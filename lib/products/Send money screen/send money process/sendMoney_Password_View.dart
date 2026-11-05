import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendMoney_Password_Controller.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/constsize.dart';

class SendMoneyPasswordView extends GetView<SendMoneyPasswordController> {
  const SendMoneyPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SendMoneyPasswordController>()) {
      Get.put(SendMoneyPasswordController());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
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
          "MPIN",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          SizedBox(height: context.responsive(16)),

                          // Recipient & Amount Summary Pill
                          if (controller.amount > 0) ...[
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: primaryRed.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.send_rounded,
                                      size: 16,
                                      color: primaryRed,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: RichText(
                                      overflow: TextOverflow.ellipsis,
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                        children: [
                                          const TextSpan(text: "Paying "),
                                          TextSpan(
                                            text:
                                                "₹${controller.amount.toStringAsFixed(controller.amount.truncateToDouble() == controller.amount ? 0 : 2)}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: primaryRed,
                                            ),
                                          ),
                                          const TextSpan(text: " to "),
                                          TextSpan(
                                            text:
                                                controller.recipient?['name'] ??
                                                'Recipient',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: context.responsive(20)),
                          ],

                          // Lock Icon
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryRed.withValues(alpha: 0.06),
                              border: Border.all(
                                color: primaryYellow.withValues(alpha: 0.8),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.lock_outline_rounded,
                              color: primaryRed,
                              size: 26,
                            ),
                          ),

                          SizedBox(height: context.responsive(16)),

                          const Text(
                            "Enter 4-Digit MPIN",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              "Enter your 4-digit MPIN to authorize this transfer.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                          ),

                          SizedBox(height: context.responsive(28)),

                          // Dots indicator
                          Obx(() {
                            final length = controller.passcode.value.length;
                            final isError = controller.isError.value;

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(4, (index) {
                                final isFilled = index < length;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  width: isFilled ? 16 : 14,
                                  height: isFilled ? 16 : 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isFilled
                                        ? (isError ? Colors.red : primaryRed)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isFilled
                                          ? (isError ? Colors.red : primaryRed)
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                  ),
                                );
                              }),
                            );
                          }),

                          // Error text display
                          Obx(() {
                            if (controller.isError.value &&
                                controller.errorMessage.value.isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  controller.errorMessage.value,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox(height: 16);
                          }),

                          // Keypad
                          _buildKeypad(context),

                          SizedBox(height: context.responsive(24)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Loading overlay
            Obx(() {
              if (!controller.isLoading.value) return const SizedBox.shrink();
              return Container(
                color: Colors.black.withValues(alpha: 0.25),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryRed,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          controller.statusMessage.value.isNotEmpty
                              ? controller.statusMessage.value
                              : "Processing...",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          height10,
          _keypadRow(["1", "2", "3"]),
          _keypadRow(["4", "5", "6"]),
          _keypadRow(["7", "8", "9"]),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _keypadRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((key) => _keypadButton(key)).toList(),
      ),
    );
  }

  Widget _buildBottomRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left: Biometric button if supported, else blank spacer
          // if (controller.canUseBiometric)
          //   _actionButton(
          //     icon: Icons.fingerprint_rounded,
          //     color: primaryRed,
          //     onTap: () => controller.authenticateWithBiometrics(),
          //   )
          // else
          const SizedBox(width: 72, height: 56),

          // Middle: "0"
          _keypadButton("0"),

          // Right: Backspace
          _actionButton(
            icon: Icons.backspace_outlined,
            color: Colors.black87,
            onTap: () => controller.addDigit("back"),
          ),
        ],
      ),
    );
  }

  Widget _keypadButton(String digit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.addDigit(digit),
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 56,
          decoration: BoxDecoration(
            color: primaryLightYellow,
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: Text(
            digit,
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

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 56,
          alignment: Alignment.center,
          child: Icon(icon, size: 24, color: color),
        ),
      ),
    );
  }
}
