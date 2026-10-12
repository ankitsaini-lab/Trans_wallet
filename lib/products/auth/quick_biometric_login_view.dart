import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/products/auth/quick_biometric_login_controller.dart';

class QuickBiometricLoginView extends StatelessWidget {
  const QuickBiometricLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(QuickBiometricLoginController());

    return Scaffold(
      body: Stack(
        children: [
          // Background design matching App Lock & fintech theme
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFF9F9),
                    Color(0xFFFEF2F1),
                    Color(0xFFFFF5F5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Obx(() {
                final showMpin = controller.showMpinKeypad.value;

                return Column(
                  children: [
                    const Spacer(flex: 1),

                    // User Avatar / Branding
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: primaryRed.withValues(alpha: 0.3),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryRed.withValues(alpha: 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person_rounded,
                          color: primaryRed,
                          size: 42,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Greeting / Phone
                    Text(
                      "Welcome Back",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      controller.maskedPhone.isNotEmpty
                          ? controller.maskedPhone
                          : "Transwallet Quick Login",
                      style: const TextStyle(
                        fontSize: 14,
                        color: secondaryText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(flex: 1),

                    if (!showMpin) ...[
                      // Biometric Scanner Button
                      InkWell(
                        onTap: controller.triggerBiometricLogin,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: primaryRed.withValues(alpha: 0.35),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryRed.withValues(alpha: 0.18),
                                blurRadius: 32,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              controller.biometricIcon,
                              color: primaryRed,
                              size: 56,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Authenticate using ${controller.biometricLabel}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Tap icon above to scan again",
                        style: const TextStyle(
                          fontSize: 13,
                          color: secondaryText,
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Switch to MPIN keypad option
                      TextButton.icon(
                        onPressed: controller.switchToMpin,
                        icon: const Icon(
                          Icons.pin_outlined,
                          color: primaryRed,
                          size: 18,
                        ),
                        label: const Text(
                          "Use 4-digit MPIN instead",
                          style: TextStyle(
                            color: primaryRed,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Log in with another account
                      TextButton(
                        onPressed: controller.navigateToFullLogin,
                        child: const Text(
                          "Log in with another account",
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else ...[
                      // MPIN Input Dots
                      const Text(
                        "Enter 4-Digit MPIN",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final pin = controller.enteredPin.value;
                          final hasError =
                              controller.pinError.value.isNotEmpty;
                          final isFilled = index < pin.length;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasError
                                  ? primaryRed
                                  : (isFilled ? primaryRed : Colors.white),
                              border: Border.all(
                                color: hasError
                                    ? primaryRed
                                    : (isFilled
                                          ? primaryRed
                                          : Colors.black.withValues(
                                              alpha: 0.18,
                                            )),
                                width: 2,
                              ),
                              boxShadow: isFilled
                                  ? [
                                      BoxShadow(
                                        color: primaryRed.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                          );
                        }),
                      ),

                      // Error message
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 20,
                        child: Builder(
                          builder: (_) {
                            if (controller.isVerifyingMpin.value) {
                              return const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: primaryRed,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }
                            if (controller.pinError.value.isNotEmpty) {
                              return Text(
                                controller.pinError.value,
                                style: const TextStyle(
                                  color: primaryRed,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Keypad
                      _buildKeypad(controller),

                      const SizedBox(height: 12),

                      // Switch back to biometrics button
                      TextButton.icon(
                        onPressed: controller.switchToBiometrics,
                        icon: Icon(
                          controller.biometricIcon,
                          color: primaryRed,
                          size: 18,
                        ),
                        label: Text(
                          "Use ${controller.biometricLabel} instead",
                          style: const TextStyle(
                            color: primaryRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      // Full Login
                      TextButton(
                        onPressed: controller.navigateToFullLogin,
                        child: const Text(
                          "Log in with another account",
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad(QuickBiometricLoginController controller) {
    return Column(
      children: [
        _keyRow(controller, ['1', '2', '3']),
        const SizedBox(height: 10),
        _keyRow(controller, ['4', '5', '6']),
        const SizedBox(height: 10),
        _keyRow(controller, ['7', '8', '9']),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _KeypadBtn(
              icon: controller.biometricIcon,
              iconColor: primaryRed,
              onTap: controller.switchToBiometrics,
            ),
            _KeypadBtn(
              label: '0',
              onTap: () => controller.onKeyTap('0'),
            ),
            _KeypadBtn(
              icon: Icons.backspace_outlined,
              iconColor: textColor,
              onTap: controller.onDeleteKey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _keyRow(
    QuickBiometricLoginController controller,
    List<String> digits,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map((d) => _KeypadBtn(label: d, onTap: () => controller.onKeyTap(d)))
          .toList(),
    );
  }
}

class _KeypadBtn extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _KeypadBtn({
    this.label,
    this.icon,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 50,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        splashColor: primaryRed.withValues(alpha: 0.15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: label != null
                ? Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  )
                : Icon(icon, color: iconColor ?? textColor, size: 22),
          ),
        ),
      ),
    );
  }
}
