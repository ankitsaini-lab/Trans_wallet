import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/services/biometric_service.dart';
import 'package:transwallet/widgets/constsize.dart';

class AppLockOverlay extends StatelessWidget {
  final Widget child;

  const AppLockOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
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
        // 1. Ultra-High Security Frosted Glass Backdrop
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFFDFD).withValues(alpha: 0.98),
                    const Color(0xFFFEF5F4).withValues(alpha: 0.98),
                    const Color(0xFFFFF2F2).withValues(alpha: 0.98),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),

        // Ambient Top Illumination Orb
        Positioned(
          top: -60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryRed.withValues(alpha: 0.09),
                    primaryRed.withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                  radius: 0.85,
                ),
              ),
            ),
          ),
        ),

        // Ambient Bottom Soft Glow Orb
        Positioned(
          bottom: -80,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primaryRed.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
        ),

        // 2. Responsive Center-Aligned Lock Screen View
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double availableHeight = constraints.maxHeight;
              final bool isCompact = availableHeight < 720;
              final bool isVeryCompact = availableHeight < 580;

              return Center(
                child: SingleChildScrollView(
                  physics: isCompact
                      ? const BouncingScrollPhysics()
                      : const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: availableHeight,
                      maxWidth: context.responsive(400),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive(22),
                        vertical: context.responsive(
                          isVeryCompact ? 6 : (isCompact ? 8 : 14),
                        ),
                      ),
                      child: Obx(() {
                        final bool showMpinOnly =
                            lockService.shouldShowMpinOnly;
                        final int failedAttempts =
                            lockService.biometricFailedAttempts.value;

                        return IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Top Balancer Spacer (Balances with bottom spacer for true center alignment)
                              Spacer(
                                flex: isVeryCompact ? 1 : (isCompact ? 1 : 2),
                              ),

                              // Luxury Multi-Ring Security Badge
                              Container(
                                width: context.responsive(
                                  isVeryCompact ? 48 : (isCompact ? 54 : 66),
                                ),
                                height: context.responsive(
                                  isVeryCompact ? 48 : (isCompact ? 54 : 66),
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFF8F8),
                                      Color(0xFFFFEEEE),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: primaryRed.withValues(alpha: 0.28),
                                    width: context.responsive(2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryRed.withValues(alpha: 0.16),
                                      blurRadius: context.responsive(20),
                                      offset: Offset(0, context.responsive(5)),
                                    ),
                                    BoxShadow(
                                      color: Colors.white,
                                      blurRadius: context.responsive(5),
                                      offset: const Offset(0, -2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.lock_rounded,
                                    color: primaryRed,
                                    size: context.responsive(
                                      isVeryCompact
                                          ? 22
                                          : (isCompact ? 25 : 30),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: context.responsive(
                                  isVeryCompact ? 6 : (isCompact ? 8 : 12),
                                ),
                              ),

                              // Screen Title
                              Text(
                                "App Locked",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: context.responsive(
                                    isVeryCompact ? 19 : (isCompact ? 21 : 23),
                                  ),
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              SizedBox(
                                height: context.responsive(
                                  isVeryCompact ? 3 : 5,
                                ),
                              ),

                              // Subtitle
                              Text(
                                showMpinOnly
                                    ? (failedAttempts >
                                              AppLockService
                                                  .maxBiometricAttempts
                                          ? "Face Lock / Biometric incorrect more than 3 times\nPlease enter your 4-digit MPIN to unlock"
                                          : "Enter your 4-digit MPIN to unlock")
                                    : "Unlock using $biometricLabel",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: context.responsive(
                                    isVeryCompact ? 11 : (isCompact ? 12 : 13),
                                  ),
                                  color: secondaryText,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              if (!showMpinOnly) ...[
                                Spacer(
                                  flex: isVeryCompact ? 1 : (isCompact ? 1 : 2),
                                ),

                                // Biometric Scanner Target (Concentric Pulse Rings)
                                InkWell(
                                  onTap: lockService.promptBiometricUnlock,
                                  borderRadius: BorderRadius.circular(
                                    context.responsive(60),
                                  ),
                                  splashColor: primaryRed.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: Container(
                                    width: context.responsive(
                                      isVeryCompact
                                          ? 80
                                          : (isCompact ? 90 : 104),
                                    ),
                                    height: context.responsive(
                                      isVeryCompact
                                          ? 80
                                          : (isCompact ? 90 : 104),
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: primaryRed.withValues(alpha: 0.05),
                                      border: Border.all(
                                        color: primaryRed.withValues(
                                          alpha: 0.2,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: context.responsive(
                                          isVeryCompact
                                              ? 66
                                              : (isCompact ? 76 : 88),
                                        ),
                                        height: context.responsive(
                                          isVeryCompact
                                              ? 66
                                              : (isCompact ? 76 : 88),
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.white,
                                              Color(0xFFFAFAFA),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          border: Border.all(
                                            color: primaryRed.withValues(
                                              alpha: 0.35,
                                            ),
                                            width: context.responsive(2),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryRed.withValues(
                                                alpha: 0.2,
                                              ),
                                              blurRadius: context.responsive(
                                                24,
                                              ),
                                              offset: Offset(
                                                0,
                                                context.responsive(7),
                                              ),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Icon(
                                            biometricIcon,
                                            color: primaryRed,
                                            size: context.responsive(
                                              isVeryCompact
                                                  ? 32
                                                  : (isCompact ? 38 : 44),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: context.responsive(
                                    isVeryCompact ? 10 : (isCompact ? 12 : 16),
                                  ),
                                ),

                                // Prompt Badge Pill
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.responsive(16),
                                    vertical: context.responsive(7),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      context.responsive(20),
                                    ),
                                    border: Border.all(
                                      color: Colors.black.withValues(
                                        alpha: 0.06,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.03,
                                        ),
                                        blurRadius: context.responsive(8),
                                        offset: Offset(
                                          0,
                                          context.responsive(2),
                                        ),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    biometricPrompt,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: context.responsive(
                                        isVeryCompact
                                            ? 12
                                            : (isCompact ? 13 : 14.5),
                                      ),
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ),
                                SizedBox(height: context.responsive(4)),

                                Text(
                                  biometricHint,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: secondaryText,
                                    fontWeight: FontWeight.w500,
                                    fontSize: context.responsive(
                                      isVeryCompact
                                          ? 10.5
                                          : (isCompact ? 11 : 12),
                                    ),
                                  ),
                                ),

                                // Warning Banner on failed attempts (Wrapped in Flexible to prevent overflow)
                                if (failedAttempts > 0) ...[
                                  SizedBox(
                                    height: context.responsive(
                                      isVeryCompact ? 6 : (isCompact ? 10 : 14),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.responsive(12),
                                      vertical: context.responsive(6),
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryRed.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(
                                        context.responsive(12),
                                      ),
                                      border: Border.all(
                                        color: primaryRed.withValues(
                                          alpha: 0.25,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: primaryRed,
                                          size: context.responsive(15),
                                        ),
                                        SizedBox(width: context.responsive(6)),
                                        Flexible(
                                          child: Text(
                                            failedAttempts >=
                                                    AppLockService
                                                        .maxBiometricAttempts
                                                ? "3 incorrect attempts. 1 more will require MPIN."
                                                : "Face or biometric not recognized ($failedAttempts of 3 used)",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: primaryRed,
                                              fontSize: context.responsive(
                                                11.5,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                Spacer(
                                  flex: isVeryCompact ? 1 : (isCompact ? 1 : 2),
                                ),

                                // Premium Capsule Button: Use MPIN
                                InkWell(
                                  onTap: lockService.switchToMpin,
                                  borderRadius: BorderRadius.circular(
                                    context.responsive(24),
                                  ),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.responsive(18),
                                      vertical: context.responsive(9),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        context.responsive(24),
                                      ),
                                      border: Border.all(
                                        color: primaryRed.withValues(
                                          alpha: 0.25,
                                        ),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryRed.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: context.responsive(8),
                                          offset: Offset(
                                            0,
                                            context.responsive(2),
                                          ),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.pin_outlined,
                                          size: context.responsive(17),
                                          color: primaryRed,
                                        ),
                                        SizedBox(width: context.responsive(7)),
                                        Flexible(
                                          child: Text(
                                            "Use 4-digit MPIN instead",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: primaryRed,
                                              fontSize: context.responsive(
                                                isCompact ? 11.5 : 12.5,
                                              ),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: context.responsive(3)),

                                // Secondary Log Out action
                                TextButton(
                                  onPressed: lockService.logoutAndReset,
                                  child: Text(
                                    "Log Out",
                                    style: TextStyle(
                                      color: secondaryText,
                                      fontSize: context.responsive(
                                        isCompact ? 11.5 : 12.5,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                // Bottom Balancer Spacer
                                Spacer(
                                  flex: isVeryCompact ? 1 : (isCompact ? 1 : 2),
                                ),
                              ] else ...[
                                // MPIN Mode
                                SizedBox(
                                  height: context.responsive(
                                    isVeryCompact ? 8 : (isCompact ? 11 : 14),
                                  ),
                                ),

                                // 4 PIN Indicator Pod
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.responsive(20),
                                    vertical: context.responsive(10),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      context.responsive(24),
                                    ),
                                    border: Border.all(
                                      color:
                                          lockService.pinError.value.isNotEmpty
                                          ? primaryRed.withValues(alpha: 0.45)
                                          : Colors.black.withValues(
                                              alpha: 0.06,
                                            ),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: context.responsive(10),
                                        offset: Offset(
                                          0,
                                          context.responsive(2),
                                        ),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(4, (index) {
                                      final pin = lockService.enteredPin.value;
                                      final hasError =
                                          lockService.pinError.value.isNotEmpty;
                                      final isFilled = index < pin.length;
                                      final double dotSize = context.responsive(
                                        isVeryCompact
                                            ? 11
                                            : (isCompact ? 13 : 15),
                                      );

                                      return AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        margin: EdgeInsets.symmetric(
                                          horizontal: context.responsive(
                                            isCompact ? 7 : 9,
                                          ),
                                        ),
                                        width: dotSize,
                                        height: dotSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: isFilled || hasError
                                              ? const LinearGradient(
                                                  colors: [
                                                    primaryRed,
                                                    Color(0xFFE53935),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                )
                                              : null,
                                          color: isFilled || hasError
                                              ? null
                                              : const Color(0xFFF1F5F9),
                                          border: Border.all(
                                            color: hasError
                                                ? primaryRed
                                                : (isFilled
                                                      ? primaryRed
                                                      : const Color(
                                                          0xFFCBD5E1,
                                                        )),
                                            width: context.responsive(1.5),
                                          ),
                                          boxShadow: isFilled
                                              ? [
                                                  BoxShadow(
                                                    color: primaryRed
                                                        .withValues(
                                                          alpha: 0.45,
                                                        ),
                                                    blurRadius: context
                                                        .responsive(7),
                                                    spreadRadius: 1,
                                                    offset: Offset(
                                                      0,
                                                      context.responsive(1),
                                                    ),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                                // Error / Verifying Status Message
                                SizedBox(
                                  height: context.responsive(
                                    isVeryCompact ? 4 : 6,
                                  ),
                                ),
                                SizedBox(
                                  height: context.responsive(
                                    isVeryCompact ? 16 : 20,
                                  ),
                                  child: Center(
                                    child: Builder(
                                      builder: (context) {
                                        if (lockService.isVerifyingPin.value) {
                                          return SizedBox(
                                            width: context.responsive(15),
                                            height: context.responsive(15),
                                            child:
                                                const CircularProgressIndicator(
                                                  color: primaryRed,
                                                  strokeWidth: 2,
                                                ),
                                          );
                                        }

                                        if (lockService
                                            .pinError
                                            .value
                                            .isNotEmpty) {
                                          return Text(
                                            lockService.pinError.value,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: primaryRed,
                                              fontWeight: FontWeight.w600,
                                              fontSize: context.responsive(
                                                isCompact ? 11.5 : 12.5,
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ),
                                ),

                                // Mid Spacer between PIN dots and keypad
                                Spacer(flex: 1),

                                // Center-Aligned Luxury Numeric Keypad
                                Center(
                                  child: _buildKeypad(
                                    context: context,
                                    lockService: lockService,
                                    isBiometricReady:
                                        lockService.isBiometricAvailable &&
                                        failedAttempts <=
                                            AppLockService.maxBiometricAttempts,
                                    biometricIcon: biometricIcon,
                                    isCompact: isCompact,
                                    isVeryCompact: isVeryCompact,
                                  ),
                                ),

                                // Mid Spacer between keypad and action buttons
                                Spacer(flex: 1),

                                // Switch back to Face Lock / Fingerprint
                                if (lockService.isBiometricAvailable &&
                                    failedAttempts <=
                                        AppLockService
                                            .maxBiometricAttempts) ...[
                                  InkWell(
                                    onTap: lockService.switchToBiometrics,
                                    borderRadius: BorderRadius.circular(
                                      context.responsive(24),
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: context.responsive(16),
                                        vertical: context.responsive(8),
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          context.responsive(24),
                                        ),
                                        border: Border.all(
                                          color: primaryRed.withValues(
                                            alpha: 0.25,
                                          ),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryRed.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: context.responsive(8),
                                            offset: Offset(
                                              0,
                                              context.responsive(2),
                                            ),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            biometricIcon,
                                            size: context.responsive(17),
                                            color: primaryRed,
                                          ),
                                          SizedBox(
                                            width: context.responsive(7),
                                          ),
                                          Flexible(
                                            child: Text(
                                              "Use $biometricLabel instead",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: primaryRed,
                                                fontSize: context.responsive(
                                                  isCompact ? 11.5 : 12.5,
                                                ),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: context.responsive(3)),
                                ],

                                // Forgot MPIN / Logout
                                TextButton(
                                  onPressed: lockService.logoutAndReset,
                                  child: Text(
                                    "Forgot MPIN?  Log Out",
                                    style: TextStyle(
                                      color: secondaryText,
                                      fontSize: context.responsive(
                                        isCompact ? 11.5 : 12.5,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                // Bottom Balancer Spacer (Matches top spacer for perfect vertical center)
                                Spacer(
                                  flex: isVeryCompact ? 1 : (isCompact ? 1 : 2),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKeypad({
    required BuildContext context,
    required AppLockService lockService,
    required bool isBiometricReady,
    required IconData biometricIcon,
    required bool isCompact,
    required bool isVeryCompact,
  }) {
    final double buttonSize = context.responsive(
      isVeryCompact ? 48 : (isCompact ? 52 : 62),
    );
    final double gap = context.responsive(
      isVeryCompact ? 6 : (isCompact ? 8 : 11),
    );
    final double keypadWidth = context.responsive(270);

    const Map<String, String> keypadLetters = {
      '1': '',
      '2': 'ABC',
      '3': 'DEF',
      '4': 'GHI',
      '5': 'JKL',
      '6': 'MNO',
      '7': 'PQRS',
      '8': 'TUV',
      '9': 'WXYZ',
      '0': '',
    };

    Widget keyRow(List<String> digits) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: digits
            .map(
              (d) => _KeypadButton(
                label: d,
                subLabel: keypadLetters[d],
                onTap: () => lockService.onKeyTap(d),
                size: buttonSize,
              ),
            )
            .toList(),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: keypadWidth),
      child: Column(
        children: [
          keyRow(['1', '2', '3']),
          SizedBox(height: gap),
          keyRow(['4', '5', '6']),
          SizedBox(height: gap),
          keyRow(['7', '8', '9']),
          SizedBox(height: gap),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Left: Biometric icon or empty balanced spacer
              if (isBiometricReady)
                _KeypadButton(
                  icon: biometricIcon,
                  iconColor: primaryRed,
                  onTap: lockService.switchToBiometrics,
                  size: buttonSize,
                  isSpecial: true,
                )
              else
                SizedBox(width: buttonSize, height: buttonSize),

              // Center: Zero
              _KeypadButton(
                label: '0',
                onTap: () => lockService.onKeyTap('0'),
                size: buttonSize,
              ),

              // Right: Backspace / Delete
              _KeypadButton(
                icon: Icons.backspace_outlined,
                iconColor: textColor,
                onTap: lockService.onDeleteKey,
                size: buttonSize,
                isSpecial: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String? label;
  final String? subLabel;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback onTap;
  final double size;
  final bool isSpecial;

  const _KeypadButton({
    this.label,
    this.subLabel,
    this.icon,
    this.iconColor,
    required this.onTap,
    required this.size,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          customBorder: const CircleBorder(),
          splashColor: primaryRed.withValues(alpha: 0.15),
          highlightColor: primaryRed.withValues(alpha: 0.08),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isSpecial
                    ? [const Color(0xFFFFF7F7), const Color(0xFFFAFAFA)]
                    : [Colors.white, const Color(0xFFF9FAFB)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: isSpecial
                    ? primaryRed.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: context.responsive(6),
                  offset: Offset(0, context.responsive(2)),
                ),
                BoxShadow(
                  color: Colors.white,
                  blurRadius: context.responsive(2),
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Center(
              child: label != null
                  ? (subLabel != null && subLabel!.isNotEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                label!,
                                style: TextStyle(
                                  fontSize: context.responsive(20),
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                  height: 1.0,
                                ),
                              ),
                              SizedBox(height: context.responsive(2)),
                              Text(
                                subLabel!,
                                style: TextStyle(
                                  fontSize: context.responsive(8),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.6,
                                  color: const Color(0xFF94A3B8),
                                  height: 1.0,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            label!,
                            style: TextStyle(
                              fontSize: context.responsive(21),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ))
                  : Icon(
                      icon,
                      color: iconColor ?? textColor,
                      size: context.responsive(19),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
