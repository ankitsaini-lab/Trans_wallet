import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendMoney_Password_Controller.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/custom_numeric_keypad.dart';

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
                final double availH = constraints.maxHeight;
                final bool isVeryCompact = availH < 560;
                final bool isCompact = availH < 680;

                final double btnSize = context.responsive(
                  isVeryCompact ? 52.0 : (isCompact ? 60.0 : 68.0),
                );
                final double vGap = context.responsive(
                  isVeryCompact ? 8.0 : (isCompact ? 12.0 : 18.0),
                );
                final double kpWidth = context.responsive(
                  isVeryCompact ? 236.0 : (isCompact ? 254.0 : 272.0),
                );

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        maxWidth: 480,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            SizedBox(
                              height: context.responsive(isCompact ? 14 : 22),
                            ),

                            // Recipient & Amount Summary Pill
                            if (controller.amount > 0) ...[
                              Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: context.responsive(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.responsive(16),
                                  vertical: context.responsive(10),
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(
                                    context.responsive(16),
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFEEEEEE),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: RichText(
                                        overflow: TextOverflow.ellipsis,
                                        text: TextSpan(
                                          style: TextStyle(
                                            fontSize: context.responsive(14),
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
                              SizedBox(
                                height: context.responsive(isCompact ? 12 : 18),
                              ),
                            ],

                            // Lock Icon
                            Container(
                              padding: EdgeInsets.all(context.responsive(14)),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryRed.withValues(alpha: 0.06),
                                border: Border.all(
                                  color: primaryYellow.withValues(alpha: 0.8),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.lock_outline_rounded,
                                color: primaryRed,
                                size: context.responsive(26),
                              ),
                            ),

                            SizedBox(height: context.responsive(14)),

                            Text(
                              "Enter 4-Digit MPIN",
                              style: TextStyle(
                                fontSize: context.responsive(19),
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),

                            SizedBox(height: context.responsive(6)),

                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.responsive(40),
                              ),
                              child: Text(
                                "Enter your 4-digit MPIN to authorize this transfer.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: context.responsive(13),
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                            ),

                            SizedBox(
                              height: context.responsive(isCompact ? 18 : 26),
                            ),

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
                                    margin: EdgeInsets.symmetric(
                                      horizontal: context.responsive(10),
                                    ),
                                    width: context.responsive(isFilled ? 16 : 14),
                                    height: context.responsive(isFilled ? 16 : 14),
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
                                  padding: EdgeInsets.only(
                                    top: context.responsive(10),
                                  ),
                                  child: Text(
                                    controller.errorMessage.value,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: context.responsive(13),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }
                              return SizedBox(height: context.responsive(14));
                            }),

                            const Spacer(flex: 1),

                            // Keypad
                            Padding(
                              padding: EdgeInsets.only(
                                bottom: context.responsive(isCompact ? 16 : 28),
                              ),
                              child: Center(
                                child: CustomNumericKeypad(
                                  buttonSize: btnSize,
                                  vGap: vGap,
                                  keypadWidth: kpWidth,
                                  onDigitTap: (digit) => controller.addDigit(digit),
                                  onDeleteTap: () => controller.addDigit("back"),
                                  onClear: () => controller.addDigit("clear"),
                                ),
                              ),
                            ),
                          ],
                        ),
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
}
