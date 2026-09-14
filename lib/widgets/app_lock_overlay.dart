import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/services/biometric_service.dart';

/// Wraps the entire application and displays a high-security lock screen overlay
/// when [AppLockService.to.isLocked] is true.
class AppLockOverlay extends StatelessWidget {
  final Widget child;

  const AppLockOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // If AppLockService is not yet registered (e.g. initial setup), render child directly
    if (!Get.isRegistered<AppLockService>()) {
      return child;
    }

    final lockService = AppLockService.to;

    return Stack(
      children: [
        child,
        Obx(() {
          if (!lockService.isLocked.value) {
            return const SizedBox.shrink();
          }

          return const Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: _AppLockScreenView(),
            ),
          );
        }),
      ],
    );
  }
}

class _AppLockScreenView extends StatelessWidget {
  const _AppLockScreenView();

  @override
  Widget build(BuildContext context) {
    final lockService = AppLockService.to;
    final biometricService = Get.isRegistered<BiometricService>()
        ? BiometricService.to
        : null;

    final biometricLabel =
        biometricService?.biometricTypeLabel ?? 'Face Lock or Biometrics';
    final biometricIcon =
        biometricService?.biometricIcon ?? Icons.fingerprint_rounded;
    final biometricPrompt =
        biometricService?.biometricActionPrompt ??
        'Scan face or touch sensor to unlock';
    final biometricHint =
        biometricService?.biometricHint ??
        'Glance at camera or place finger on sensor';

    return Stack(
      children: [
        // 1. High-Security Backdrop Filter matching app theme (soft translucent light crimson glow)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFF7F7).withValues(alpha: 0.96),
                    const Color(0xFFFEF2F1).withValues(alpha: 0.98),
                    const Color(0xFFFFF1F1).withValues(alpha: 0.97),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),

        // 2. Lock Screen Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Obx(() {
              final bool showMpinOnly = lockService.shouldShowMpinOnly;
              final int failedAttempts =
                  lockService.biometricFailedAttempts.value;

              return Column(
                children: [
                  const Spacer(flex: 1),

                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: primaryRed.withValues(alpha: 0.25),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryRed.withValues(alpha: 0.14),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock_rounded,
                        color: primaryRed,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Title
                  const Text(
                    "App Locked",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    showMpinOnly
                        ? (failedAttempts > AppLockService.maxBiometricAttempts
                              ? "Face Lock / Biometric incorrect more than 3 times\nPlease enter your 4-digit MPIN to unlock"
                              : "Enter your 4-digit MPIN to unlock")
                        : "Unlock using $biometricLabel",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: secondaryText,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  if (!showMpinOnly) ...[
                    const Spacer(flex: 1),

                    InkWell(
                      onTap: lockService.promptBiometricUnlock,
                      borderRadius: BorderRadius.circular(50),
                      splashColor: primaryRed.withValues(alpha: 0.2),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: primaryRed.withValues(alpha: 0.35),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryRed.withValues(alpha: 0.16),
                              blurRadius: 28,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            biometricIcon,
                            color: primaryRed,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      biometricPrompt,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      biometricHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: secondaryText,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),

                    // Failed attempts warning banner (1..3)
                    if (failedAttempts > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: primaryRed.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryRed.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: primaryRed,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              failedAttempts >=
                                      AppLockService.maxBiometricAttempts
                                  ? "3 incorrect attempts. 1 more will require MPIN."
                                  : "Face or biometric not recognized ($failedAttempts of 3 used)",
                              style: const TextStyle(
                                color: primaryRed,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(flex: 2),

                    // Manual MPIN Option
                    TextButton.icon(
                      onPressed: lockService.switchToMpin,
                      icon: const Icon(
                        Icons.pin_outlined,
                        size: 18,
                        color: primaryRed,
                      ),
                      label: const Text(
                        "Use 4-digit MPIN instead",
                        style: TextStyle(
                          color: primaryRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Log Out action
                    TextButton(
                      onPressed: lockService.logoutAndReset,
                      child: const Text(
                        "Log Out",
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final pin = lockService.enteredPin.value;
                        final hasError = lockService.pinError.value.isNotEmpty;
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
                                        : Colors.black.withValues(alpha: 0.18)),
                              width: 2,
                            ),
                            boxShadow: isFilled
                                ? [
                                    BoxShadow(
                                      color: primaryRed.withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.03,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                          ),
                        );
                      }),
                    ),

                    // Error / Verifying Status Message
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 20,
                      child: Builder(
                        builder: (context) {
                          if (lockService.isVerifyingPin.value) {
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

                          if (lockService.pinError.value.isNotEmpty) {
                            return Text(
                              lockService.pinError.value,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: primaryRed,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Custom Numeric Keypad
                    _buildKeypad(
                      lockService: lockService,
                      isBiometricReady:
                          lockService.isBiometricAvailable &&
                          failedAttempts <= AppLockService.maxBiometricAttempts,
                      biometricIcon: biometricIcon,
                    ),

                    const SizedBox(height: 8),

                    // Switch back to Face Lock / Fingerprint option if not locked out
                    if (lockService.isBiometricAvailable &&
                        failedAttempts <=
                            AppLockService.maxBiometricAttempts) ...[
                      TextButton.icon(
                        onPressed: lockService.switchToBiometrics,
                        icon: Icon(biometricIcon, size: 18, color: primaryRed),
                        label: Text(
                          "Use $biometricLabel instead",
                          style: const TextStyle(
                            color: primaryRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],

                    // Logout / Emergency option
                    TextButton(
                      onPressed: lockService.logoutAndReset,
                      child: const Text(
                        "Forgot MPIN?  Log Out",
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
    );
  }

  Widget _buildKeypad({
    required AppLockService lockService,
    required bool isBiometricReady,
    required IconData biometricIcon,
  }) {
    return Column(
      children: [
        _keyRow(lockService, ['1', '2', '3']),
        const SizedBox(height: 10),
        _keyRow(lockService, ['4', '5', '6']),
        const SizedBox(height: 10),
        _keyRow(lockService, ['7', '8', '9']),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Left Action: Biometric icon or empty spacer
            if (isBiometricReady)
              _KeypadButton(
                icon: biometricIcon,
                iconColor: primaryRed,
                onTap: lockService.switchToBiometrics,
              )
            else
              const SizedBox(width: 72, height: 50),

            // Zero
            _KeypadButton(label: '0', onTap: () => lockService.onKeyTap('0')),

            // Backspace / Delete
            _KeypadButton(
              icon: Icons.backspace_outlined,
              iconColor: textColor,
              onTap: lockService.onDeleteKey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _keyRow(AppLockService lockService, List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map(
            (d) =>
                _KeypadButton(label: d, onTap: () => lockService.onKeyTap(d)),
          )
          .toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _KeypadButton({
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
        highlightColor: primaryRed.withValues(alpha: 0.08),
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
