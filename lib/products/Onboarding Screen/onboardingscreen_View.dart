import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Onboarding%20Screen/onboardingscreen_controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';

class OnboardingscreenView extends GetView<OnboardingscreenController> {
  const OnboardingscreenView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(OnboardingscreenController());

    final mediaQuery = MediaQuery.of(context);

    final clampedMediaQuery = mediaQuery.copyWith(
      textScaler: mediaQuery.textScaler.clamp(
        minScaleFactor: 0.85,
        maxScaleFactor: 1.15,
      ),
    );

    return MediaQuery(
      data: clampedMediaQuery,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: lightprimaryred,
          extendBodyBehindAppBar: true,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final double screenHeight = constraints.maxHeight;
              final double screenWidth = constraints.maxWidth;
              final double bottomInset = mediaQuery.padding.bottom;
              final double topInset = mediaQuery.padding.top;

              final bool isShortScreen = screenHeight < 720;
              final bool isNarrowScreen = screenWidth < 360;

              final double nextBtnDiameter = isShortScreen ? 58.0 : 64.0;
              final double bottomBarMargin = bottomInset > 0
                  ? bottomInset + (isShortScreen ? 12.0 : 16.0)
                  : 24.0;
              final double bottomControlsTopFromBottom =
                  bottomBarMargin + nextBtnDiameter;

              final double textToControlsGap = isShortScreen ? 14.0 : 20.0;
              final double textBottomPosition =
                  bottomControlsTopFromBottom + textToControlsGap;

              final double titleFontSize = isShortScreen
                  ? 20.0
                  : (isNarrowScreen ? 21.0 : 23.0);
              final double subtitleFontSize = isShortScreen ? 13.0 : 14.0;
              final double titleToSubtitleSpacing = isShortScreen ? 8.0 : 12.0;

              return Stack(
                fit: StackFit.expand,
                children: [
                  PageView(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildPage(
                        context: context,
                        imageAsset: 'assets/step1.png',
                        title: "All Your Finances In One Wallet",
                        description:
                            "Send money, add funds, pay utility bills, and manage your prepaid cards in one secure place.",
                        textBottomPosition: textBottomPosition,
                        titleFontSize: titleFontSize,
                        subtitleFontSize: subtitleFontSize,
                        titleToSubtitleSpacing: titleToSubtitleSpacing,
                        isShortScreen: isShortScreen,
                      ),
                      _buildPage(
                        context: context,
                        imageAsset: 'assets/step2.png',
                        title: "Fast. Simple. Effortless.",
                        description:
                            "Experience instant transfers, lightning-fast recharges, and zero-hassle everyday payments.",
                        textBottomPosition: textBottomPosition,
                        titleFontSize: titleFontSize,
                        subtitleFontSize: subtitleFontSize,
                        titleToSubtitleSpacing: titleToSubtitleSpacing,
                        isShortScreen: isShortScreen,
                      ),
                      _buildPage(
                        context: context,
                        imageAsset: 'assets/step3.png',
                        title: "Security You Can Trust",
                        description:
                            "Bank-grade 256-bit encryption with RBI-compliant standards and MPIN protection for every transaction.",
                        textBottomPosition: textBottomPosition,
                        titleFontSize: titleFontSize,
                        subtitleFontSize: subtitleFontSize,
                        titleToSubtitleSpacing: titleToSubtitleSpacing,
                        isShortScreen: isShortScreen,
                      ),
                    ],
                  ),

                  Positioned(
                    top: topInset + (isShortScreen ? 10.0 : 16.0),
                    left: 10.0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      opacity: 1.0,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          child: SvgPicture.asset(
                            "assets/transcorp logo black.svg",
                            width: 120,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: topInset + (isShortScreen ? 8.0 : 12.0),
                    right: 20.0,
                    child: Obx(() {
                      final bool isLastPage = controller.currentPage.value == 2;
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        opacity: isLastPage ? 0.0 : 1.0,
                        child: IgnorePointer(
                          ignoring: isLastPage,
                          child: _PressableScale(
                            onTap: controller.skip,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: primaryLightYellow,
                                borderRadius: BorderRadius.circular(20),
                                // border: Border.all(
                                //   color: Colors.black.withValues(alpha: 0.08),
                                //   width: 1,
                                // ),
                                // boxShadow: [
                                //   BoxShadow(
                                //     color: primaryYellow,
                                //     blurRadius: 8,
                                //     offset: const Offset(0, 2),
                                //   ),
                                // ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Skip",
                                    style: TextStyle(
                                      color: primaryRed,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: primaryRed,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  Positioned(
                    bottom: bottomBarMargin,
                    left: 24.0,
                    right: 24.0,
                    child: SizedBox(
                      height: nextBtnDiameter,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              3,
                              (index) => Obx(() {
                                final bool isActive =
                                    controller.currentPage.value == index;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(right: 6),
                                  width: isActive ? 22 : 7,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? activeDotColor
                                        : inactiveDotColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          ),

                          _PressableScale(
                            onTap: controller.nextPage,
                            child: Container(
                              width: nextBtnDiameter,
                              height: nextBtnDiameter,
                              decoration: const BoxDecoration(
                                color: nextButtonOuterBgColor,
                                shape: BoxShape.circle,
                              ),
                              padding: EdgeInsets.all(isShortScreen ? 8 : 9),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: nextButtonBgColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: isShortScreen ? 22 : 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    required BuildContext context,
    required String imageAsset,
    required String title,
    required String description,
    required double textBottomPosition,
    required double titleFontSize,
    required double subtitleFontSize,
    required double titleToSubtitleSpacing,
    required bool isShortScreen,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            imageAsset,
            fit: BoxFit.cover,
            alignment: Alignment(0.0, isShortScreen ? 0.0 : -0.2),
          ),
        ),

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: textBottomPosition + (isShortScreen ? 140 : 170),
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.45, 1.0],
                  colors: [
                    lightprimaryred.withValues(alpha: 0.0),
                    lightprimaryred.withValues(alpha: 0.75),
                    lightprimaryred,
                  ],
                ),
              ),
            ),
          ),
        ),

        Positioned(
          bottom: textBottomPosition,
          left: 24.0,
          right: 24.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.22,
                ),
              ),
              SizedBox(height: titleToSubtitleSpacing),
              Text(
                description,
                style: TextStyle(
                  color: secondaryText,
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.w400,
                  height: 1.48,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
