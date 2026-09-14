import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Order%20Card%20screen/Order%20Details%20Screen/orderDetailsscreen_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/custombutton.dart';

class OrderdetailsscreenView extends GetView<OrderdetailsscreenController> {
  const OrderdetailsscreenView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => OrderdetailsscreenController());

    const Color textColor = Color(0xFF111111);
    const Color secondaryText = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryRed.withOpacity(0.06),
                ),
              ),
            ),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4CAF50).withOpacity(0.05),
                ),
              ),
            ),
          ),

          // 2. Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // Concentric pulsing success animation
                  const _PulsingSuccessIcon(),

                  const SizedBox(height: 20),

                  // Core Title & Subtitle
                  const Text(
                    "Card Order Confirmed!",
                    style: TextStyle(
                      color: textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Your Premium Card has been successfully ordered.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondaryText, fontSize: 14),
                  ),

                  const SizedBox(height: 28),

                  _buildPhysicalCardMockup(),

                  const SizedBox(height: 28),

                  _buildDeliveryTimeline(),

                  const SizedBox(height: 24),

                  _buildInvoiceSummary(),

                  const SizedBox(height: 30),

                  CustomButton(
                    text: "Back to Home",
                    btncolor: primaryRed,
                    textColor: Colors.white,
                    onPressed: () {
                      Get.offAllNamed('/dashboard');
                    },
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () {
                      Get.toNamed(
                        '/trackcard',
                        arguments: {
                          'amount': controller.amount.value,
                          'cardStyleName': controller.cardStyleName.value,
                          'referenceId': controller.referenceId.value,
                          'cardBgImage': controller.cardBgImage.value,
                        },
                      );
                    },
                    child: const Text(
                      "Track Live Status",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),

          const Positioned.fill(child: IgnorePointer(child: _ConfettiShower())),
        ],
      ),
    );
  }

  Widget _buildPhysicalCardMockup() {
    return Obx(() {
      final holderName = controller.receiverName.value;
      final String cardImg = controller.cardBgImage.value;
      final bool useBlackLogos = cardImg.contains("yellow");
      final Color textColor = useBlackLogos ? Colors.white : Colors.white;

      return AspectRatio(
        aspectRatio: 85.60 / 53.98,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: AssetImage(cardImg),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 24,
                left: 24,
                child: Text(
                  holderName,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildDeliveryTimeline() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECECEC), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Estimated delivery",
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Obx(
                () => Text(
                  controller.deliveryDateStr.value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TimelineStep(
                label: "Ordered",
                isActive: true,
                isCompleted: true,
              ),
              _TimelineStepDivider(isCompleted: true),
              _TimelineStep(
                label: "Preparing",
                isActive: true,
                isCompleted: false,
              ),
              _TimelineStepDivider(isCompleted: false),
              _TimelineStep(
                label: "In Transit",
                isActive: false,
                isCompleted: false,
              ),
              _TimelineStepDivider(isCompleted: false),
              _TimelineStep(
                label: "Delivered",
                isActive: false,
                isCompleted: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECECEC), width: 1.5),
      ),
      child: Column(
        children: [
          Obx(() => _buildReceiptRow("Card", controller.cardStyleName.value)),
          const SizedBox(height: 14),
          Obx(() => _buildReceiptRow("Order ID", controller.referenceId.value)),
          const SizedBox(height: 14),
          Obx(
            () => _buildReceiptRow(
              "Payment Method",
              controller.paymentMethod.value,
            ),
          ),
          const SizedBox(height: 14),
          Obx(
            () => _buildAddressRow(
              "Shipment Address",
              controller.deliveryAddress.value,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFECECEC), height: 1, thickness: 1.5),
          ),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Paid Amount",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "₹${controller.amount.value}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9CA3AF),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  void _showShipmentTrackingSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Shipment Tracking",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111111),
                    letterSpacing: -0.4,
                  ),
                ),
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      controller.referenceId.value,
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildTrackingStep(
              title: "Card Customization Confirmed",
              time:
                  "Today, ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
              subtitle:
                  "Signature chip successfully configured with dynamic authentication encryption keys.",
              isCompleted: true,
              isLast: false,
            ),
            _buildTrackingStep(
              title: "Quality Inspection & Laser Engraving",
              time:
                  "Today, ${DateTime.now().hour}:${(DateTime.now().minute + 1).toString().padLeft(2, '0')}",
              subtitle:
                  "Laser etching finished. Metallic cardholder sign-off approved by Western Union Lab.",
              isCompleted: true,
              isLast: false,
            ),
            _buildTrackingStep(
              title: "Handed over to Express Courier Partner",
              time: "In Progress",
              subtitle:
                  "Dispatched from Delhi Hub. Blue Dart tracking link will be shared via registered SMS.",
              isCompleted: false,
              isLast: false,
              isActive: true,
            ),
            _buildTrackingStep(
              title: "Delivered to Residence",
              time: "Estimate: 7 Days",
              subtitle:
                  "Secure package delivery requires OTP authorization at home.",
              isCompleted: false,
              isLast: true,
            ),

            const SizedBox(height: 12),
            CustomButton(
              text: "Close Status Drawer",
              btncolor: Colors.black,
              onPressed: () => Get.back(),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildTrackingStep({
    required String title,
    required String time,
    required String subtitle,
    required bool isCompleted,
    required bool isLast,
    bool isActive = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFF4CAF50)
                    : (isActive ? primaryRed : const Color(0xFFE5E7EB)),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  if (isActive)
                    BoxShadow(
                      color: primaryRed.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 9)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: isCompleted
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFE5E7EB),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isCompleted || isActive
                          ? const Color(0xFF111111)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? primaryRed : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF6B7280),
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }
}

class _PulsingSuccessIcon extends StatefulWidget {
  const _PulsingSuccessIcon();

  @override
  State<_PulsingSuccessIcon> createState() => _PulsingSuccessIconState();
}

class _PulsingSuccessIconState extends State<_PulsingSuccessIcon>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 30,
      ),
    ]).animate(_scaleController);

    _pulseAnimation = Tween<double>(
      begin: 0.9,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Center(
        child: SizedBox(
          width: 150,
          height: 150,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 90 * _pulseAnimation.value,
                    height: 90 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFDCFCE7).withOpacity(
                        (0.25 * (1.0 - (_pulseAnimation.value - 0.9) / 0.6))
                            .clamp(0.0, 1.0),
                      ),
                    ),
                  ),

                  Container(
                    width: 76 * _pulseAnimation.value,
                    height: 76 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFDCFCE7).withOpacity(
                        (0.45 * (1.0 - (_pulseAnimation.value - 0.9) / 0.6))
                            .clamp(0.0, 1.0),
                      ),
                    ),
                  ),

                  Container(
                    height: 60,
                    width: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF22C55E),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x2922C55E),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 32,
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
}

class _CutoutDivider extends StatelessWidget {
  const _CutoutDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: List.generate(40, (index) {
              return Expanded(
                child: Container(
                  height: 1.5,
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  color: const Color(0xFFECECEC),
                ),
              );
            }),
          ),

          Positioned(
            left: -8,
            child: Container(
              height: 16,
              width: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF9FAFB),
                border: Border.all(color: const Color(0xFFECECEC), width: 1.5),
              ),
            ),
          ),

          Positioned(
            right: -8,
            child: Container(
              height: 16,
              width: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF9FAFB),
                border: Border.all(color: const Color(0xFFECECEC), width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _TimelineStep({
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    Widget dot;
    if (isCompleted) {
      dot = Container(
        height: 14,
        width: 14,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
      );
    } else if (isActive) {
      dot = Container(
        height: 18,
        width: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryRed,
          border: Border.all(color: Colors.white, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: primaryRed.withOpacity(0.4),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      );
    } else {
      dot = Container(
        height: 14,
        width: 14,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE5E7EB),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 18, child: Center(child: dot)),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isCompleted || isActive
                ? const Color(0xFF111111)
                : const Color(0xFF9CA3AF),
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _TimelineStepDivider extends StatelessWidget {
  final bool isCompleted;

  const _TimelineStepDivider({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 21),
        color: isCompleted ? Colors.black : const Color(0xFFE5E7EB),
      ),
    );
  }
}

class _CardMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.015)
      ..strokeWidth = 1.0;

    const spacing = 15.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i + 40, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConfettiShower extends StatefulWidget {
  const _ConfettiShower();

  @override
  State<_ConfettiShower> createState() => _ConfettiShowerState();
}

class _ConfettiShowerState extends State<_ConfettiShower>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();

    final colors = [
      const Color(0xFFFFCC00),
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFFEB3B),
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
    ];
    final rand = javaMathRand();

    for (int i = 0; i < 45; i++) {
      _particles.add(
        _ConfettiParticle(
          x: rand.nextDouble(),
          y: -rand.nextDouble() * 0.5,
          speed: 0.15 + rand.nextDouble() * 0.25,
          angle: rand.nextDouble() * 360,
          spinSpeed: -4 + rand.nextDouble() * 8,
          size: 5 + rand.nextDouble() * 7,
          color: colors[rand.nextInt(colors.length)],
        ),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  _Random javaMathRand() => _Random();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final progress = _animController.value;
        return CustomPaint(
          painter: _ConfettiPainter(particles: _particles, progress: progress),
        );
      },
    );
  }
}

class _Random {
  final _rand = _javaMathRandom();
  double nextDouble() => _rand.nextDouble();
  int nextInt(int max) => _rand.nextInt(max);
}

_JavaMathRandGenerator _javaMathRandom() {
  return _javaMathRandomInstance;
}

final _javaMathRandomInstance = _JavaMathRandGenerator();

class _JavaMathRandGenerator {
  final _r = _JavaMathSeedGen();
  double nextDouble() => _r.nextDouble();
  int nextInt(int max) => _r.nextInt(max);
}

class _JavaMathSeedGen {
  int _seed = 123456789;
  double nextDouble() {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed / 0x7fffffff;
  }

  int nextInt(int max) {
    return (nextDouble() * max).floor();
  }
}

class _ConfettiParticle {
  double x;
  double y;
  final double speed;
  double angle;
  final double spinSpeed;
  final double size;
  final Color color;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.angle,
    required this.spinSpeed,
    required this.size,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      // Calculate active drop height based on timeline
      final double activeY = (p.y + progress * p.speed) * size.height;
      if (activeY < 0 || activeY > size.height) continue;

      // Slight horizontal oscillation
      final double activeX =
          (p.x + progress * 0.05 * (p.spinSpeed > 0 ? 1 : -1)) * size.width;
      final double activeAngle = p.angle + progress * 360 * p.spinSpeed;

      canvas.save();
      canvas.translate(activeX, activeY);
      canvas.rotate(activeAngle * 0.0174533); // convert to radians

      paint.color = p.color.withOpacity(
        1.0 - progress.clamp(0.7, 1.0) * 2.5 + 1.75,
      ); // fade out at end

      // Draw random shapes (square/rectangle/circle)
      if (p.size % 2 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(-p.size / 2, -p.size / 2, p.size, p.size),
          paint,
        );
      } else {
        canvas.drawOval(
          Rect.fromLTWH(-p.size / 2, -p.size / 2, p.size, p.size * 0.6),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
