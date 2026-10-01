import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/widgets/constsize.dart';

const List<Map<String, dynamic>> kCards = [];

class CardDetailsPopup extends StatefulWidget {
  final Map<String, dynamic> card;
  const CardDetailsPopup({super.key, required this.card});

  @override
  State<CardDetailsPopup> createState() => _CardDetailsPopupState();
}

class _CardDetailsPopupState extends State<CardDetailsPopup>
    with SingleTickerProviderStateMixin {
  bool _showCvv = false;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutBack);
    _scaleCtrl.forward();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _copyNumber() {
    final numStr =
        widget.card['fullNumber'] as String? ??
        widget.card['cardNumber'] as String? ??
        '';
    if (numStr.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: numStr));
      Get.rawSnackbar(
        message: 'Card number copied',
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF111111),
        borderRadius: 14,
        margin: const EdgeInsets.all(16),
        snackStyle: SnackStyle.FLOATING,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardData = widget.card;
    final fullNumber =
        cardData['fullNumber']?.toString() ??
        cardData['cardNumber']?.toString() ??
        '';
    final holderName =
        GetStorage().read('name')?.toString() ??
        cardData['holder']?.toString() ??
        cardData['cardHolder']?.toString() ??
        '';
    final expiryDate = cardData['expiry']?.toString() ?? '';
    final cvvCode = cardData['cvv']?.toString() ?? '';
    final bgImagePath = cardData['bgImage']?.toString();

    final useBlackLogos = cardData['useBlackLogos'] as bool? ?? false;
    final textColor = useBlackLogos ? Colors.black : Colors.white;
    final subColor = useBlackLogos ? Colors.black54 : Colors.white70;
    final statusStr = cardData['status']?.toString().toUpperCase() ?? '';
    final bool isBlocked =
        cardData['isBlocked'] == true ||
        statusStr == 'LOCKED' ||
        statusStr == 'BLOCKED';

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black.withOpacity(0.45)),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 240,

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        image: bgImagePath != null && bgImagePath.isNotEmpty
                            ? DecorationImage(
                                image: AssetImage(bgImagePath),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),

                      child: Stack(
                        children: [
                          if (bgImagePath == null || bgImagePath.isEmpty) ...[
                            Positioned(
                              top: -30,
                              right: -30,
                              child: Container(
                                height: 120,
                                width: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: -40,
                              left: -40,
                              child: Container(
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withOpacity(0.08),
                                ),
                              ),
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/WHITE TRANSCORP .png',
                                      height: 14,
                                      fit: BoxFit.contain,
                                      color: useBlackLogos
                                          ? Colors.black
                                          : null,
                                    ),
                                    if (isBlocked)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade700,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(
                                              Icons.lock_outline,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              "FROZEN",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),

                                const Spacer(flex: 3),
                                GestureDetector(
                                  onTap: _copyNumber,
                                  child: Row(
                                    children: [
                                      width24,
                                      Text(
                                        fullNumber,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 18,
                                          letterSpacing: 2,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(flex: 1),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    width2,
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              " VALID\n THRU   ",
                                              style: TextStyle(
                                                color: subColor,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            Text(
                                              expiryDate,
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          holderName.toUpperCase(),
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'CVV',
                                          style: TextStyle(
                                            color: subColor,
                                            fontSize: 10,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        GestureDetector(
                                          onTap: () => setState(
                                            () => _showCvv = !_showCvv,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _showCvv
                                                    ? (cvvCode.isNotEmpty
                                                          ? cvvCode
                                                          : '***')
                                                    : '***',
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(
                                                _showCvv
                                                    ? Icons.visibility_rounded
                                                    : Icons
                                                          .visibility_off_rounded,
                                                color: subColor,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    Column(
                                      children: [
                                        Image.asset(
                                          'assets/VisaFree.png',
                                          height: 21,
                                          fit: BoxFit.contain,
                                          color: useBlackLogos
                                              ? Colors.black
                                              : null,
                                        ),
                                        height14,
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isBlocked)
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(26),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 5.0,
                                    sigmaY: 5.0,
                                  ),
                                  child: Container(
                                    color: Colors.black.withOpacity(0.3),
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.25,
                                              ),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(
                                              Icons.lock_outline,
                                              color: Colors.black,
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Card frozen",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            Get.back();
                            Get.toNamed('/managecard', arguments: widget.card);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              'Manage',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FullCardDetailsPopup extends StatefulWidget {
  final Map<String, dynamic>? card;
  const FullCardDetailsPopup({super.key, this.card});

  @override
  State<FullCardDetailsPopup> createState() => _FullCardDetailsPopupState();
}

class _FullCardDetailsPopupState extends State<FullCardDetailsPopup>
    with SingleTickerProviderStateMixin {
  bool _showCvv = false;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutBack);
    _scaleCtrl.forward();
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _copyCardNumber() {
    final numStr =
        widget.card?['fullNumber'] as String? ??
        widget.card?['cardNumber'] as String? ??
        '';
    if (numStr.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: numStr));
      Get.rawSnackbar(
        message: "Card number copied",
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF111111),
        borderRadius: 14,
        margin: const EdgeInsets.all(16),
        snackStyle: SnackStyle.FLOATING,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardData = widget.card ?? {};
    final cardNumber =
        cardData['fullNumber'] as String? ??
        cardData['cardNumber'] as String? ??
        '';
    final cardHolder =
        GetStorage().read('name') ??
        cardData['holder'] as String? ??
        cardData['cardHolder'] as String? ??
        '';
    final expiry = cardData['expiry'] as String? ?? '';
    final cvv = cardData['cvv'] as String? ?? '';
    final bgImage =
        cardData['bgImage'] as String? ?? 'assets/unioncardblack.webp';

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black.withOpacity(0.45)),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        image: DecorationImage(
                          image: AssetImage(bgImage),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFCC00).withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/WU.png',
                                    height: 22,
                                    fit: BoxFit.contain,
                                  ),
                                  Image.asset(
                                    'assets/WHITE TRANSCORP .png',
                                    height: 14,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: 45,
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFECB3),
                                      Color(0xFFE5C158),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    cardNumber,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _copyCardNumber,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.copy_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "CARD HOLDER",
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 10,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          cardHolder,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Text(
                                              "VALID THRU  ",
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            Text(
                                              expiry,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "CVV",
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      GestureDetector(
                                        onTap: () => setState(
                                          () => _showCvv = !_showCvv,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _showCvv
                                                  ? (cvv.isNotEmpty
                                                        ? cvv
                                                        : '•••')
                                                  : "•••",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              _showCvv
                                                  ? Icons.visibility_rounded
                                                  : Icons
                                                        .visibility_off_rounded,
                                              color: Colors.white70,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Image.asset(
                                    'assets/VisaFree.png',
                                    height: 18,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Text(
                              "Close",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            Get.back();
                            Get.toNamed('/managecard', arguments: cardData);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFCC00),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFFCC00,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Manage',
                              style: TextStyle(
                                color: Color(0xFF0F1013),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
