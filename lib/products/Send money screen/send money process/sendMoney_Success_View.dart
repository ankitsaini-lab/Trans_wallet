import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendMoney_Success_Controller.dart';
import 'package:transwallet/widgets/constsize.dart';

class SendMoneySuccessView extends StatefulWidget {
  const SendMoneySuccessView({super.key});

  @override
  State<SendMoneySuccessView> createState() => _SendMoneySuccessViewState();
}

class _SendMoneySuccessViewState extends State<SendMoneySuccessView>
    with SingleTickerProviderStateMixin {
  late final SendMoneySuccessController controller =
      Get.isRegistered<SendMoneySuccessController>()
      ? Get.find<SendMoneySuccessController>()
      : Get.put(SendMoneySuccessController());

  late final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(milliseconds: 1800),
  );

  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  late final Animation<double> _iconScaleAnimation = CurvedAnimation(
    parent: _animController,
    curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
  );

  late final Animation<Offset> _contentSlideAnimation =
      Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animController,
          curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
        ),
      );

  late final Animation<double> _contentFadeAnimation = CurvedAnimation(
    parent: _animController,
    curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
  );

  // PhonePe-inspired brand colors
  static const Color primaryColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF22C55E);
  static const Color textColor = Color(0xFF111827);
  static const Color secondaryTextColor = Color(0xFF6B7280);
  static const Color cardBorderColor = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();
    _animController.forward();
    _confettiController.play();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (!_animController.isAnimating && !_animController.isCompleted) {
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipientName = controller.recipient?['name']?.trim();
    final displayName = (recipientName != null && recipientName.isNotEmpty)
        ? recipientName
        : 'Recipient';
    final isWhole = controller.amount.truncateToDouble() == controller.amount;
    final amountFormatted = isWhole
        ? NumberFormat('#,##,###', 'en_IN').format(controller.amount)
        : NumberFormat('#,##,##0.00', 'en_IN').format(controller.amount);

    final formattedDate = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(DateTime.now());

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
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              controller.goToDashboard();
            }
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsive(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: context.responsive(12)),

                              // Top status bar with centered title and close icon
                              SizedBox(
                                height: 36,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text(
                                      "Payment Status",
                                      style: TextStyle(
                                        fontSize: context.responsive(16),
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 22,
                                          color: secondaryTextColor,
                                        ),
                                        onPressed: () =>
                                            controller.goToDashboard(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: context.responsive(20)),

                              // Success checkmark with celebratory halo & particles
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Subtle celebratory particles & ambient halo
                                  CustomPaint(
                                    // painter: _CelebrationParticlesPainter(),
                                    child: Container(
                                      width: context.responsive(110),
                                      height: context.responsive(110),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: successColor.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Animated green success checkmark
                                  ScaleTransition(
                                    scale: _iconScaleAnimation,
                                    child: Container(
                                      width: context.responsive(76),
                                      height: context.responsive(76),
                                      decoration: const BoxDecoration(
                                        color: successColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0x3D22C55E),
                                            blurRadius: 18,
                                            offset: Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: context.responsive(44),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: context.responsive(20)),

                              // Animated Text Content
                              SlideTransition(
                                position: _contentSlideAnimation,
                                child: FadeTransition(
                                  opacity: _contentFadeAnimation,
                                  child: Column(
                                    children: [
                                      // Heading
                                      Text(
                                        "Money Sent Successfully!",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: context.responsive(22),
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                          letterSpacing: -0.3,
                                        ),
                                      ),

                                      SizedBox(height: context.responsive(6)),

                                      // Subtitle
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: context.responsive(16),
                                        ),
                                        child: Text(
                                          "Your money has been sent successfully to the recipient.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: context.responsive(13),
                                            fontWeight: FontWeight.w400,
                                            color: secondaryTextColor,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),

                                      SizedBox(height: context.responsive(16)),

                                      // Prominent Transferred Amount
                                      Text(
                                        "₹$amountFormatted",
                                        style: TextStyle(
                                          fontSize: context.responsive(34),
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                          letterSpacing: -0.5,
                                        ),
                                      ),

                                      SizedBox(height: context.responsive(24)),

                                      // PhonePe-Inspired Transaction Details Card
                                      Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.all(
                                          context.responsive(18),
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: cardBorderColor,
                                            width: 1,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x0A000000),
                                              blurRadius: 16,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            // Recipient Header row
                                            Row(
                                              children: [
                                                // Recipient Profile Avatar
                                                CircleAvatar(
                                                  radius: context.responsive(
                                                    20,
                                                  ),
                                                  backgroundColor: primaryColor
                                                      .withValues(alpha: 0.1),
                                                  child: Text(
                                                    displayName.isNotEmpty
                                                        ? displayName[0]
                                                              .toUpperCase()
                                                        : 'R',
                                                    style: TextStyle(
                                                      color: primaryColor,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: context
                                                          .responsive(16),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: context.responsive(12),
                                                ),
                                                // Recipient Name & Masked Account
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        displayName,
                                                        style: TextStyle(
                                                          fontSize: context
                                                              .responsive(15),
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: textColor,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        controller
                                                            .maskedAccountNumber,
                                                        style: TextStyle(
                                                          fontSize: context
                                                              .responsive(12),
                                                          color:
                                                              secondaryTextColor,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Success verified mini-badge
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: successColor
                                                        .withValues(alpha: 0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.check_rounded,
                                                    color: successColor,
                                                    size: 14,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 14,
                                              ),
                                              child: Divider(
                                                height: 1,
                                                thickness: 1,
                                                color: dividerColor,
                                              ),
                                            ),

                                            // Transaction Amount
                                            _buildRow(
                                              label: "Transaction Amount",
                                              value: "₹$amountFormatted",
                                              isHighlight: true,
                                            ),

                                            const SizedBox(height: 12),

                                            // Transaction Date and Time
                                            _buildRow(
                                              label: "Date & Time",
                                              value: formattedDate,
                                            ),

                                            const SizedBox(height: 12),

                                            // Transaction ID / UTR Number
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  flex: 5,
                                                  child: Text(
                                                    "Transaction ID / UTR",
                                                    style: TextStyle(
                                                      color: secondaryTextColor,
                                                      fontSize: context
                                                          .responsive(13),
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  flex: 5,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          controller
                                                              .referenceId,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          textAlign:
                                                              TextAlign.right,
                                                          style: TextStyle(
                                                            color: textColor,
                                                            fontSize: context
                                                                .responsive(13),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        onTap: () => controller
                                                            .copyReferenceId(),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets.all(
                                                                2,
                                                              ),
                                                          child: Icon(
                                                            Icons.copy_rounded,
                                                            size: context
                                                                .responsive(14),
                                                            color: primaryColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),

                                            if (controller.note.isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              _buildRow(
                                                label: "Note",
                                                value: controller.note,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: context.responsive(20)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Celebratory Confetti emitter (positioned over checkmark)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: context.responsive(60)),
                      child: ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirectionality: BlastDirectionality.explosive,
                        shouldLoop: false,
                        numberOfParticles: 20,
                        emissionFrequency: 0.05,
                        maxBlastForce: 15,
                        minBlastForce: 6,
                        gravity: 0.25,
                        colors: const [
                          Color(0xFF22C55E),
                          Color(0xFFE53935),
                          Color(0xFFFFB800),
                          Color(0xFF3B82F6),
                          Color(0xFFA855F7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Persistent Bottom Action Bar (always visible & properly inset from system navigation bar)
            bottomNavigationBar: SafeArea(
              top: false,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.only(
                  left: context.responsive(20),
                  right: context.responsive(20),
                  top: 8,
                  bottom: mediaQuery.padding.bottom > 0 ? 8 : 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Download Receipt Button
                    OutlinedButton.icon(
                      onPressed: () => controller.downloadReceipt(),

                      label: const Text(
                        "View Receipt",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(
                          double.infinity,
                          context.responsive(50),
                        ),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.black, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            context.responsive(25),
                          ),
                        ),
                        elevation: 0,
                      ),
                    ),

                    SizedBox(height: context.responsive(10)),

                    // Back to Home Button
                    SizedBox(
                      width: double.infinity,
                      height: context.responsive(50),
                      child: ElevatedButton(
                        onPressed: () => controller.goToDashboard(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              context.responsive(25),
                            ),
                          ),
                        ),
                        child: Text(
                          "Back to Home",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.responsive(15),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: secondaryTextColor,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
