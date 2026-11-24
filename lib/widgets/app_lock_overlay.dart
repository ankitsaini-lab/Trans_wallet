import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/products/Profile screen/change_pin/forgot_pin_view.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/custom_numeric_keypad.dart';

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
          if (!lockService.isLocked.value || !lockService.isAppLockEnabled) {
            return const SizedBox.shrink();
          }

          return Positioned.fill(
            child: Material(
              color: Colors.white,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (childWidget, animation) {
                  return FadeTransition(opacity: animation, child: childWidget);
                },
                child: lockService.isResettingPinFromLock.value
                    ? const _ForgotPinFromLockWrapper(
                        key: ValueKey('forgot_pin_flow_view'),
                      )
                    : const _AppLockScreenView(
                        key: ValueKey('app_lock_screen_view'),
                      ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ForgotPinFromLockWrapper extends StatelessWidget {
  const _ForgotPinFromLockWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final lockService = AppLockService.to;
    return Material(
      color: Colors.white,
      child: HeroControllerScope.none(
        child: Navigator(
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (ctx) => ForgotPinView(
                onSuccess: () {
                  lockService.onForgotPinSuccessFromLock();
                },
                onCancel: () {
                  lockService.onForgotPinCancelFromLock();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AppLockScreenView extends StatefulWidget {
  const _AppLockScreenView({super.key});

  @override
  State<_AppLockScreenView> createState() => _AppLockScreenViewState();
}

class _AppLockScreenViewState extends State<_AppLockScreenView>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  Worker? _errorWorker;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    if (Get.isRegistered<AppLockService>()) {
      _errorWorker = ever(AppLockService.to.pinError, (String err) {
        if (err.isNotEmpty && mounted) {
          _shakeController.forward(from: 0.0);
        }
      });
    }
  }

  @override
  void dispose() {
    _errorWorker?.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  double _getShakeOffset(double progress) {
    if (progress <= 0 || progress >= 1.0) return 0.0;
    return math.sin(progress * 3 * 2 * math.pi) * 10 * (1.0 - progress);
  }

  @override
  Widget build(BuildContext context) {
    final lockService = AppLockService.to;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double availableHeight = constraints.maxHeight;
            final bool isVeryCompact = availableHeight < 620;
            final bool isCompact = availableHeight < 760;

            final double shieldHeight = context.responsive(
              isVeryCompact ? 76 : (isCompact ? 92 : 108),
            );
            final double gapShieldToTitle = context.responsive(
              isVeryCompact ? 14 : (isCompact ? 10 : 10),
            );
            final double gapTitleToSubtitle = context.responsive(
              isVeryCompact ? 6 : (isCompact ? 10 : 14),
            );
            final double gapSubtitleToDots = context.responsive(
              isVeryCompact ? 22 : (isCompact ? 28 : 34),
            );
            final double gapDotsToKeypad = context.responsive(
              isVeryCompact ? 18 : (isCompact ? 22 : 28),
            );
            final double gapKeypadToFooter = context.responsive(
              isVeryCompact ? 24 : (isCompact ? 30 : 38),
            );

            return Center(
              child: SingleChildScrollView(
                physics: isCompact
                    ? const BouncingScrollPhysics()
                    : const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: availableHeight,
                    maxWidth: context.responsive(420),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive(20),
                      vertical: context.responsive(isVeryCompact ? 8 : 16),
                    ),
                    child: Obx(() {
                      return IntrinsicHeight(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Top Balancer Spacer (Centers the entire cluster)
                            const Spacer(flex: 1),

                            // 1. 3D Red Shield with Padlock Illustration
                            Image.asset(
                              'assets/Applock .png',
                              height: shieldHeight,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: shieldHeight * 0.9,
                                  height: shieldHeight,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFEF2F2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.security,
                                    color: primaryRed,
                                    size: 40,
                                  ),
                                );
                              },
                            ),

                            SizedBox(height: gapShieldToTitle),

                            // 2. Title: 'App Locked'
                            Text(
                              "App Locked",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: context.responsive(
                                  isVeryCompact ? 21 : 23,
                                ),
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                letterSpacing: -0.3,
                              ),
                            ),

                            SizedBox(height: gapTitleToSubtitle),

                            // 3. Subtitle: 'Enter Your 4-Digit MPIN To Unlock'
                            Text(
                              "Enter Your 4-Digit MPIN To Unlock",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: context.responsive(
                                  isVeryCompact ? 12 : 13.5,
                                ),
                                color: const Color(0xFF9E9E9E),
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.1,
                              ),
                            ),

                            SizedBox(height: gapSubtitleToDots),

                            // 4. 4 PIN Indicator Circles with Animated Shake
                            AnimatedBuilder(
                              animation: _shakeAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    _getShakeOffset(_shakeAnimation.value),
                                    0,
                                  ),
                                  child: child,
                                );
                              },
                              child: _buildPinIndicatorDots(
                                context: context,
                                lockService: lockService,
                                isCompact: isCompact,
                                isVeryCompact: isVeryCompact,
                              ),
                            ),

                            // Status / Error Banner (Compact overlay if error/verifying exists)
                            _buildStatusOrErrorBadge(
                              context: context,
                              lockService: lockService,
                              isCompact: isCompact,
                              isVeryCompact: isVeryCompact,
                            ),

                            SizedBox(height: gapDotsToKeypad),

                            // 5. Numeric Keypad (Flat #F4F6F7 Circular Buttons)
                            _buildKeypad(
                              context: context,
                              lockService: lockService,
                              isCompact: isCompact,
                              isVeryCompact: isVeryCompact,
                            ),

                            SizedBox(height: gapKeypadToFooter),

                            // 6. Footer: 'Forgot MPIN?' | 'Log Out'
                            _buildFooterActions(
                              context: context,
                              lockService: lockService,
                              isCompact: isCompact,
                            ),

                            // Bottom Balancer Spacer (Balances with Top Spacer)
                            const Spacer(flex: 1),
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
    );
  }

  Widget _buildPinIndicatorDots({
    required BuildContext context,
    required AppLockService lockService,
    required bool isCompact,
    required bool isVeryCompact,
  }) {
    final pin = lockService.enteredPin.value;
    final hasError = lockService.pinError.value.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < pin.length;
        final double dotSize = context.responsive(isVeryCompact ? 13 : 15);
        final double dotMargin = context.responsive(
          isVeryCompact ? 5 : (isCompact ? 6 : 7),
        );

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(horizontal: dotMargin),
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? (hasError ? primaryRed : Colors.black)
                : Colors.transparent,
            border: Border.all(
              color: hasError ? primaryRed : Colors.black,
              width: context.responsive(1.8),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStatusOrErrorBadge({
    required BuildContext context,
    required AppLockService lockService,
    required bool isCompact,
    required bool isVeryCompact,
  }) {
    if (lockService.isVerifyingPin.value) {
      return Padding(
        padding: EdgeInsets.only(top: context.responsive(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: context.responsive(13),
              height: context.responsive(13),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryRed,
              ),
            ),
            SizedBox(width: context.responsive(6)),
            Text(
              "Verifying MPIN...",
              style: TextStyle(
                color: secondaryText,
                fontSize: context.responsive(isCompact ? 11 : 12),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final displayError = lockService.pinError.value;
    if (displayError.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: context.responsive(8)),
        child: Text(
          displayError,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: primaryRed,
            fontWeight: FontWeight.w600,
            fontSize: context.responsive(isCompact ? 11.5 : 12.5),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildKeypad({
    required BuildContext context,
    required AppLockService lockService,
    required bool isCompact,
    required bool isVeryCompact,
  }) {
    return CustomNumericKeypad(
      onDigitTap: lockService.onKeyTap,
      onDeleteTap: lockService.onDeleteKey,
      onClear: lockService.clearPin,
      buttonSize: context.responsive(
        isVeryCompact ? 56 : (isCompact ? 62 : 68),
      ),
      vGap: context.responsive(
        isVeryCompact ? 14 : (isCompact ? 18 : 22),
      ),
      keypadWidth: context.responsive(
        isVeryCompact ? 236 : (isCompact ? 254 : 268),
      ),
    );
  }

  Widget _buildFooterActions({
    required BuildContext context,
    required AppLockService lockService,
    required bool isCompact,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 'Forgot MPIN?' in primaryRed with underline
        InkWell(
          onTap: lockService.openForgotPinScreen,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive(10),
              vertical: context.responsive(4),
            ),
            child: Text(
              "Forgot MPIN?",
              style: TextStyle(
                color: primaryRed,
                fontSize: context.responsive(isCompact ? 13.5 : 14),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: primaryRed,
              ),
            ),
          ),
        ),

        // Vertical divider
        Container(
          width: 1,
          height: context.responsive(18),
          color: const Color(0xFFE5E7EB),
          margin: EdgeInsets.symmetric(horizontal: context.responsive(10)),
        ),

        // 'Log Out' in Black without underline
        InkWell(
          onTap: lockService.logoutAndReset,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive(10),
              vertical: context.responsive(4),
            ),
            child: Text(
              "Log Out",
              style: TextStyle(
                color: Colors.black,
                fontSize: context.responsive(isCompact ? 13.5 : 14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
