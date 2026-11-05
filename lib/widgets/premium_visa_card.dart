import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/constsize.dart';

class PremiumVisaCard extends StatelessWidget {
  final String cardNumber;
  final String cardHolder;
  final String expiryDate;
  final String? cvv;
  final bool isBlocked;
  final bool isPermanentlyBlocked;
  final VoidCallback? onTap;
  final Widget? topRightAction;
  final String? bgImage;
  final String? brand;
  final bool useBlackLogos;
  final Color shadowColor;

  const PremiumVisaCard({
    super.key,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    this.cvv,
    this.isBlocked = false,
    this.isPermanentlyBlocked = false,
    this.onTap,
    this.topRightAction,
    this.bgImage,
    this.brand,
    this.useBlackLogos = false,
    this.shadowColor = primaryRed,
  });

  /// Helper to resolve dynamic card background image:
  /// - for Rupee / RuPay: assets/rupeecard.png
  /// - for Visa: assets/visacard.png
  static String resolveCardBgImage({
    String? brand,
    String? network,
    String? bgImage,
  }) {
    final raw = '${brand ?? ''} ${network ?? ''}'.toLowerCase();
    if (raw.contains('rupay') || raw.contains('rupee') || raw.contains('rup')) {
      return 'assets/rupeecard.png';
    }
    if (raw.contains('visa')) {
      return 'assets/visacard.png';
    }
    if (bgImage != null && bgImage.isNotEmpty) {
      final bgLower = bgImage.toLowerCase();
      if (bgLower.contains('rupay') || bgLower.contains('rupee')) {
        return 'assets/rupeecard.png';
      }
      if (bgLower.contains('visa')) {
        return 'assets/visacard.png';
      }
      return bgImage;
    }
    return 'assets/visacard.png';
  }

  String _formatExpiry(String expiry) {
    final cleaned = expiry.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 4) {
      return '${cleaned.substring(0, 2)}/${cleaned.substring(2, 4)}';
    }
    if (expiry.contains('/')) {
      return expiry;
    }
    return expiry.isNotEmpty ? expiry : '--/--';
  }

  String _formatCardNumber(String number) {
    String cleaned = number.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length >= 4) {
      return '•••• •••• •••• ${cleaned.substring(cleaned.length - 4)}';
    }
    return number;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = useBlackLogos ? Colors.black : Colors.white;
    final resolvedBgImage = resolveCardBgImage(brand: brand, bgImage: bgImage);

    final cardContent = AspectRatio(
      aspectRatio: 85.60 / 53.98,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: isBlocked ? 0.05 : 0.18),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              isBlocked ? Colors.grey : Colors.transparent,
              BlendMode.saturation,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double cardWidth = constraints.maxWidth;
                final double cardHeight = cardWidth / (85.60 / 53.98);

                final double scale = (cardWidth / 340.0).clamp(0.5, 1.5);

                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(resolvedBgImage, fit: BoxFit.cover),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: cardWidth * 0.06,
                        vertical: cardHeight * 0.08,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (topRightAction != null) topRightAction!,
                          const Spacer(flex: 2),

                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: cardWidth * 0.04),
                              child: Text(
                                _formatCardNumber(cardNumber),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: (cardWidth * 0.052).clamp(
                                    12.0,
                                    22.0,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: (cardWidth * 0.005).clamp(
                                    0.5,
                                    2.0,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          height12,

                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: cardWidth * 0.04),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "VALID THRU  ",
                                    style: TextStyle(
                                      color: textColor.withValues(alpha: 0.75),
                                      fontSize: (cardWidth * 0.022).clamp(
                                        7.0,
                                        10.0,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  Text(
                                    _formatExpiry(expiryDate),
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: (cardWidth * 0.035).clamp(
                                        10.0,
                                        15.0,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          height12,

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: cardWidth * 0.04,
                                    bottom: cardHeight * 0.0,
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      cardHolder.toUpperCase(),
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: (cardWidth * 0.04).clamp(
                                          10.0,
                                          16.0,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (isPermanentlyBlocked)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.5),
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16 * scale,
                                vertical: 10 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.block,
                                    color: Colors.white,
                                    size: 18 * scale,
                                  ),
                                  SizedBox(width: 8 * scale),
                                  Text(
                                    "CARD BLOCKED",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14 * scale,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    else if (isBlocked)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.1),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 14 * scale,
                                        vertical: 8 * scale,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.lock_outline,
                                            color: Colors.black,
                                            size: 16 * scale,
                                          ),
                                          SizedBox(width: 6 * scale),
                                          Text(
                                            "Card frozen",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 13 * scale,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 8 * scale),
                                    Text(
                                      "Tap the lock to unfreeze",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12 * scale,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: cardContent);
    }
    return cardContent;
  }
}
