import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Onboarding%20Screen/onboardingscreen_controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/widgets/constsize.dart';

class OnboardingscreenView extends GetView<OnboardingscreenController> {
  const OnboardingscreenView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => OnboardingscreenController());

    return Scaffold(
      backgroundColor: lightprimaryred,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.onPageChanged,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildPage1(context),
              _buildPage2(context),
              _buildPage3(context),
            ],
          ),

          // Top Skip Button
          Positioned(
            top: MediaQuery.of(context).padding.top + context.responsive(14),
            right: context.responsive(20),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive(14),
                        vertical: context.responsive(7),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryRed.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Skip",
                            style: TextStyle(
                              color: textColor,
                              fontSize: context.responsive(13),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: context.responsive(2)),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: context.responsive(16),
                            color: textColor,
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
            bottom:
                MediaQuery.of(context).padding.bottom + context.responsive(24),
            left: context.responsive(24),
            right: context.responsive(24),
            child: SizedBox(
              height: context.responsive(60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(
                      3,
                      (index) => Obx(() {
                        final bool isActive =
                            controller.currentPage.value == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: isActive ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive ? activeDotColor : inactiveDotColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Right: Next Button (Circular)
                  _PressableScale(
                    onTap: controller.nextPage,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: nextButtonOuterBgColor,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: nextButtonBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Page 1 ---
  Widget _buildPage1(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Image.asset(
            'assets/step1.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        // Text Content
        Positioned(
          bottom: context.responsive(
            110,
          ), // Adjusted to sit above bottom navigation
          left: context.responsive(24),
          right: context.responsive(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "All Your Finances In One Wallet",
                style: TextStyle(
                  color: textColor,
                  fontSize: context.responsive(24),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
              ),
              SizedBox(height: context.responsive(12)),
              Text(
                "Send money, add funds, pay utility bills, and manage your prepaid cards in one secure place.",
                style: TextStyle(
                  color: secondaryText,
                  fontSize: context.responsive(14),
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Page 2 ---
  Widget _buildPage2(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Image.asset(
            'assets/step2.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        // Text Content
        Positioned(
          bottom: context.responsive(110),
          left: context.responsive(24),
          right: context.responsive(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Fast. Simple. Effortless.",
                style: TextStyle(
                  color: textColor,
                  fontSize: context.responsive(24),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              SizedBox(height: context.responsive(12)),
              Text(
                "Experience instant transfers, lightning-fast recharges, and zero-hassle everyday payments.",
                style: TextStyle(
                  color: secondaryText,
                  fontSize: context.responsive(14),
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Page 3 ---
  Widget _buildPage3(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Image.asset(
            'assets/step3.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        // Text Content
        Positioned(
          bottom: context.responsive(100),
          left: context.responsive(24),
          right: context.responsive(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Security You Can Trust",
                style: TextStyle(
                  color: textColor,
                  fontSize: context.responsive(24),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              SizedBox(height: context.responsive(12)),
              Text(
                "Bank-grade 256-bit encryption with RBI-compliant standards and biometric protection for every transaction.",
                style: TextStyle(
                  color: secondaryText,
                  fontSize: context.responsive(14),
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LockWidget extends StatelessWidget {
  const LockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shackle (U-shaped metallic loop)
          Positioned(
            top: 2,
            child: Container(
              width: 44,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
                border: Border.all(color: const Color(0xFFB0B3B8), width: 7),
              ),
            ),
          ),

          Positioned(
            bottom: 4,
            child: Container(
              width: 70,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFD54F),
                    Color(0xFFFFA000),
                    Color(0xFFFF8F00),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFA000).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 2,
                    left: 2,
                    right: 2,
                    child: Container(
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: CustomPaint(
                      size: const Size(14, 22),
                      painter: KeyholePainter(const Color(0xFF0F1013)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}

class KeyholePainter extends CustomPainter {
  final Color color;

  KeyholePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    final radius = size.width / 2;
    path.addOval(
      Rect.fromCircle(center: Offset(size.width / 2, radius), radius: radius),
    );

    path.moveTo(size.width * 0.25, radius * 1.5);
    path.lineTo(size.width * 0.1, size.height);
    path.lineTo(size.width * 0.9, size.height);
    path.lineTo(size.width * 0.75, radius * 1.5);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant KeyholePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
