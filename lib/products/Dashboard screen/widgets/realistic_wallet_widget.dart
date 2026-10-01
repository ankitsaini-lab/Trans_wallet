import 'package:flutter/material.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/services/biometric_service.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/mpin_verify_sheet.dart';
import 'package:transwallet/products/Dashboard screen/controllers/wallet_card_controller.dart';
import 'package:transwallet/products/Dashboard screen/models/wallet_card_model.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/premium_visa_card.dart';
import 'package:transwallet/widgets/constsize.dart';

class RealisticWalletWidget extends StatefulWidget {
  final WalletCardController controller;
  final Function(int index)? onCardTap;

  const RealisticWalletWidget({
    super.key,
    required this.controller,
    this.onCardTap,
  });

  @override
  State<RealisticWalletWidget> createState() => _RealisticWalletWidgetState();
}

class _RealisticWalletWidgetState extends State<RealisticWalletWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  int _previousIndex = 0;
  int _currentIndex = 0;

  Timer? _hintTimer;
  bool _showHint = false;
  bool _isSwipeHint = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _setupAnimations();

    _currentIndex = widget.controller.selectedIndex.value;
    _previousIndex = _currentIndex;

    widget.controller.selectedIndex.listen((newIndex) {
      if (newIndex != _currentIndex && mounted) {
        bool wasClosed = _animController.value == 0.0;
        setState(() {
          _previousIndex = wasClosed ? newIndex : _currentIndex;
          _currentIndex = newIndex;
          _isSwipeHint = false;
        });
        _animController.forward(from: 0.0);

        _resetInactivityTimer();
      }
    });

    _resetInactivityTimer();
  }

  void _resetInactivityTimer() {
    _hintTimer?.cancel();
    if (_showHint && mounted) {
      setState(() {
        _showHint = false;
      });
    }
    _hintTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _isSwipeHint = true;
          _showHint = true;
        });
      }
    });
  }

  void _setupAnimations() {
    final CurvedAnimation slideCurve = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(slideCurve);
  }

  double _getTiltAngle() {
    double t = _animController.value.clamp(0.0, 1.0);
    // Apply the easeInOutCubic curve
    t = Curves.easeInOutCubic.transform(t);

    // Mimic TweenSequence: 40% to -0.04, 60% back to 0.0
    if (t <= 0.4) {
      return (t / 0.4) * -0.04;
    } else {
      return (1.0 - ((t - 0.4) / 0.6)) * -0.04;
    }
  }

  bool _isBalanceRevealed = false;
  Timer? _balanceAutoHideTimer;

  void _toggleBalance() {
    if (_isBalanceRevealed) {
      _autoHideBalance();
    } else {
      _showMpinSheetForBalance();
    }
  }

  Future<void> _revealBalance() async {
    if (Get.isRegistered<ApiService>()) {
      await ApiService.to.fetchWalletBalance();
    }

    if (mounted) {
      setState(() {
        _isBalanceRevealed = true;
      });

      _balanceAutoHideTimer?.cancel();
      _balanceAutoHideTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _isBalanceRevealed = false;
          });
        }
      });
    }
  }

  void _autoHideBalance() {
    _balanceAutoHideTimer?.cancel();
    setState(() {
      _isBalanceRevealed = false;
    });
  }

  Future<void> _showMpinSheetForBalance() async {
    if (Get.isRegistered<BiometricService>()) {
      final bioService = BiometricService.to;
      if (bioService.isBiometricAvailable &&
          bioService.isBiometricEnabled.value) {
        final result = await bioService.authenticate(
          localizedReason: "Authenticate to view total balance",
        );
        if (result.success && mounted) {
          _revealBalance();
          return;
        }
      }
    }

    Get.bottomSheet(
      MpinVerifySheet(
        onSuccess: _revealBalance,
        title: "Enter MPIN to View Balance",
        subtitle:
            "For your security, enter your 4-digit mobile PIN or use biometrics",
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _balanceAutoHideTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final double velocity = details.velocity.pixelsPerSecond.dy;
    if (velocity < -300) {
      widget.controller.nextCard();
    } else if (velocity > 300) {
      widget.controller.previousCard();
    }
  }

  String _getFormattedBalance() {
    num bal = 0;
    if (GetStorage().read('balance') != null) {
      final stored = GetStorage().read('balance');
      if (stored is num) bal = stored;
    }
    return "₹ ${bal.toStringAsFixed(2)}";
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      behavior: HitTestBehavior.translucent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth;
          final double cardHeight = (availableWidth - 100) / (90.60 / 60.98);
          final double walletContainerHeight = cardHeight + 85.0 + 45.0;

          return Obx(() {
            final cards = widget.controller.cards;
            if (cards.isEmpty) return const SizedBox.shrink();

            return GestureDetector(
              onVerticalDragEnd: _handleVerticalDragEnd,

              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                height: walletContainerHeight,
                width: availableWidth,
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    final List<Widget> stackLayers = [];

                    // 1. BACK LAYER: Tucked inactive cards (placed behind pocket)
                    for (int i = 0; i < cards.length; i++) {
                      if (i != _currentIndex && i != _previousIndex) {
                        stackLayers.add(
                          _buildTuckedCard(i, cards[i], cards.length),
                        );
                      }
                    }

                    // 2. RETRACTING CARD: The card transitioning back into the wallet
                    if (_previousIndex != _currentIndex &&
                        _previousIndex >= 0 &&
                        _previousIndex < cards.length) {
                      stackLayers.add(
                        _buildRetractingCard(
                          _previousIndex,
                          cards[_previousIndex],
                        ),
                      );
                    }

                    stackLayers.add(
                      Positioned(
                        bottom: context.responsive(45),
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.responsive(20),
                              vertical: context.responsive(10),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromRGBO(0, 0, 0, 0.40),

                                    blurRadius: 35,

                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/ChatGPT Image Aug 10, 2026, 12_42_26 PM.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                    stackLayers.add(
                      Positioned(
                        bottom: context.responsive(45),
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Container(
                            decoration: const BoxDecoration(
                              // boxShadow: [
                              //   BoxShadow(
                              //     color: Color.fromRGBO(0, 0, 0, 0.25),

                              //     blurRadius: 40,

                              //     offset: const Offset(0, 2),
                              //   ),
                              // ],
                            ),
                            child: Image.asset(
                              'assets/ChatGPT Image Aug 10, 2026, 12_42_26 PM.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    );

                    if (_currentIndex >= 0 && _currentIndex < cards.length) {
                      stackLayers.add(
                        _buildActiveCard(_currentIndex, cards[_currentIndex]),
                      );
                    }
                    stackLayers.add(
                      Positioned(
                        bottom: context.responsive(53),
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Image.asset(
                            'assets/frontwallet.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );

                    stackLayers.add(
                      Positioned(
                        bottom: context.responsive(72),
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            Text(
                              "Total Balance",
                              style: TextStyle(
                                color: const Color.fromRGBO(255, 255, 255, 1),
                                fontSize: context.responsive(16),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: context.responsive(4)),
                            GestureDetector(
                              onTap: _toggleBalance,
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isBalanceRevealed
                                        ? _getFormattedBalance()
                                        : "₹ ••••••",
                                    style: TextStyle(
                                      color: const Color.fromRGBO(
                                        255,
                                        255,
                                        255,
                                        1,
                                      ),
                                      fontSize: context.responsive(22),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: context.responsive(8)),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color.fromRGBO(255, 255, 255, 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        context.responsive(4.0),
                                      ),
                                      child: Icon(
                                        _isBalanceRevealed
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: Colors.white,
                                        size: context.responsive(16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: context.responsive(4)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.security,
                                  color: Colors.white54,
                                  size: context.responsive(12),
                                ),
                                SizedBox(width: context.responsive(4)),
                                Text(
                                  "Secured by RBI",
                                  style: TextStyle(
                                    color: const Color.fromRGBO(
                                      255,
                                      255,
                                      255,
                                      1,
                                    ),
                                    fontSize: context.responsive(10),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );

                    stackLayers.add(
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => Get.toNamed('/all_cards'),
                          child: Center(
                            child: Container(
                              width: context.responsive(120),
                              height: context.responsive(35),
                              padding: EdgeInsets.symmetric(
                                horizontal: context.responsive(14),
                                vertical: context.responsive(6),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(
                                  context.responsive(20),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "More Cards ",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: context.responsive(12),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_outlined,
                                    color: Colors.white,
                                    size: context.responsive(12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );

                    return Stack(
                      clipBehavior: Clip.none,
                      children: stackLayers,
                    );
                  },
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildTuckedCard(int index, WalletCardModel card, int totalCards) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final double maxVisibleStack = screenWidth * 0.42;

    final double stackSpacing = totalCards <= 1
        ? 0
        : (maxVisibleStack / (totalCards - 1)).clamp(
            screenWidth * 0.025,
            screenWidth * 0.043,
          );

    final double topOffset = (screenWidth * 0.005) + (index * stackSpacing);

    final double scale = totalCards <= 1
        ? 1.0
        : (1.0 - (index * 0.012)).clamp(0.88, 1.0);

    final double horizontalPadding =
        (screenWidth * 0.085 - (index * screenWidth * 0.007)).clamp(
          screenWidth * 0.045,
          screenWidth * 0.085,
        );

    return Positioned(
      top: topOffset,
      left: horizontalPadding,
      right: horizontalPadding,
      child: Transform.scale(
        scale: scale,
        child: GestureDetector(
          onTap: () => widget.controller.selectCard(index),
          child: PremiumVisaCard(
            cardNumber: card.cardNumber,
            cardHolder: card.cardHolder,
            expiryDate: card.expiry,
            cvv: "•••",
            isBlocked: card.isBlocked,
            bgImage: card.bgImage,
            useBlackLogos: card.useBlackLogos,
          ),
        ),
      ),
    );
  }

  // Card sliding BACK into wallet slot
  Widget _buildRetractingCard(int index, WalletCardModel card) {
    final double progress = _slideAnimation.value;
    final double screenWidth = MediaQuery.of(context).size.width;
    final int totalCards = widget.controller.cards.length;
    final double maxVisibleStack = screenWidth * 0.42;
    final double stackSpacing = totalCards <= 1
        ? 0
        : (maxVisibleStack / (totalCards - 1)).clamp(
            screenWidth * 0.025,
            screenWidth * 0.055,
          );
    final double targetTuckedTop =
        (screenWidth * 0.05) + (index * stackSpacing);
    final double topOffset = progress * targetTuckedTop;
    final double initialScale = 0.92 - (index * 0.03);
    final double scale = 1.0 - (progress * (1.0 - initialScale));
    final double tilt = (1.0 - progress) * -0.03;

    return Positioned(
      top: topOffset,
      left: context.responsive(28),
      right: context.responsive(28),
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateZ(tilt),
        alignment: Alignment.center,
        child: Transform.scale(
          scale: scale,
          child: PremiumVisaCard(
            cardNumber: card.cardNumber,
            cardHolder: card.cardHolder,
            expiryDate: card.expiry,
            cvv: "•••",
            isBlocked: card.isBlocked,
            bgImage: card.bgImage,
            useBlackLogos: card.useBlackLogos,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveCard(int index, WalletCardModel card) {
    final double progress = _slideAnimation.value;
    final double initialTuckedTop = context.responsive(
      36.0,
    ); // Fixed front pocket depth
    final double topOffset = initialTuckedTop * (0.35 - progress);
    final double initialScale = 0.98 - (index * 0.03);
    final double scale = initialScale + (progress * (1.0 - initialScale));
    final double tilt = _getTiltAngle();

    return Positioned(
      top: topOffset,
      left: context.responsive(26),
      right: context.responsive(26),
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateZ(tilt),
        alignment: Alignment.center,
        child: Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: () {
              if (_animController.value > 0.0) {
                _animController.reverse();
              } else {
                _animController.forward(from: 0.0);
              }
            },
            onLongPress: () {
              if (widget.onCardTap != null) {
                widget.onCardTap!(index);
              }
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.responsive(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18 * progress),
                    blurRadius: 20 * progress,
                    offset: Offset(0, 10 * progress),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  PremiumVisaCard(
                    cardNumber: card.cardNumber,
                    cardHolder: card.cardHolder,
                    expiryDate: card.expiry,
                    cvv: "•••",
                    isBlocked: card.isBlocked,
                    bgImage: card.bgImage,
                    useBlackLogos: card.useBlackLogos,
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        opacity: _showHint ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.83),
                                borderRadius: BorderRadius.circular(
                                  context.responsive(16),
                                ),
                              ),
                            ),
                            Positioned(
                              top: context.responsive(-20),
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Lottie.asset(
                                  "assets/cardanimation_final.json",
                                  // 'assets/cardanimation.json',
                                  width: context.responsive(200),
                                  height: context.responsive(200),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Positioned(
                              top: context.responsive(10),
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Text(
                                  textAlign: TextAlign.center,
                                  "Swipe Up Next • Press & Hold",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: context.responsive(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}

class AnimatedSwipeHintIcon extends StatefulWidget {
  const AnimatedSwipeHintIcon({super.key});
  @override
  State<AnimatedSwipeHintIcon> createState() => _AnimatedSwipeHintIconState();
}

class _AnimatedSwipeHintIconState extends State<AnimatedSwipeHintIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        // Opacity fades in at the start, stays, and fades out at the end
        double opacity = 1.0;
        if (_ctrl.value < 0.2) {
          opacity = _ctrl.value / 0.2;
        } else if (_ctrl.value > 0.8) {
          opacity = (1.0 - _ctrl.value) / 0.2;
        }

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            // Moves from bottom (10) to top (-10)
            offset: Offset(0, 10 - (_ctrl.value * 20)),
            child: const Icon(
              Icons.touch_app_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        );
      },
    );
  }
}

class AnimatedPressHintIcon extends StatefulWidget {
  const AnimatedPressHintIcon({super.key});
  @override
  State<AnimatedPressHintIcon> createState() => _AnimatedPressHintIconState();
}

class _AnimatedPressHintIconState extends State<AnimatedPressHintIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        // Ripple effect expands and fades out
        double rippleScale = 1.0 + (_ctrl.value * 1.5);
        double rippleOpacity = 1.0 - _ctrl.value;
        if (_ctrl.value < 0.2) rippleOpacity = 0.0; // Wait before rippling

        // Hand scales down (presses) and holds
        double handScale = 1.0;
        if (_ctrl.value > 0.1 && _ctrl.value < 0.8) {
          handScale = 0.8;
        } else if (_ctrl.value >= 0.8) {
          handScale = 0.8 + ((_ctrl.value - 0.8) / 0.2 * 0.2);
        } else {
          handScale = 1.0 - (_ctrl.value / 0.1 * 0.2);
        }

        return SizedBox(
          width: 24,
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_ctrl.value > 0.2)
                Opacity(
                  opacity: rippleOpacity,
                  child: Transform.scale(
                    scale: rippleScale,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
              Transform.scale(
                scale: handScale,
                child: const Icon(
                  Icons.touch_app_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
