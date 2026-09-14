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
  final String bgImage;
  final bool useBlackLogos;
  final Color shadowColor;

  const PremiumVisaCard({
    Key? key,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    this.cvv,
    this.isBlocked = false,
    this.isPermanentlyBlocked = false,
    this.onTap,
    this.topRightAction,
    this.bgImage = 'assets/unioncardblack.webp',
    this.useBlackLogos = false,
    this.shadowColor = primaryRed,
  }) : super(key: key);

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

    final cardContent = AspectRatio(
      aspectRatio: 85.60 / 53.98,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // border: Border.all(color: primaryLightYellow, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(isBlocked ? 0.05 : 0.18),
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

                final double scale = (cardWidth / 340.0).clamp(0.65, 1.0);

                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(bgImage, fit: BoxFit.cover),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20 * scale,
                        vertical: 16 * scale,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/WHITE TRANSCORP .png',
                                height: 14 * scale,
                                fit: BoxFit.contain,
                                color: useBlackLogos ? Colors.black : null,
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                _formatCardNumber(cardNumber),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 18 * scale,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          height30,

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cardHolder.toUpperCase(),
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 14 * scale,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/VisaFree.png',
                                    height: 18 * scale,
                                    fit: BoxFit.contain,
                                    color: useBlackLogos ? Colors.black : null,
                                  ),
                                  height24,
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (isPermanentlyBlocked)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16 * scale,
                                vertical: 10 * scale,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
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
                              color: Colors.black.withOpacity(0.1),
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
