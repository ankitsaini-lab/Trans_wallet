import 'package:flutter/material.dart';

const Color primaryRed = Color(0xFFED292A);
const Color primaryYellow = Color.fromRGBO(255, 184, 184, 1);
const Color lightprimaryred = Color.fromRGBO(255, 247, 247, 1);
const Color textColor = Color(0xFF111111);
const Color secondaryText = Color(0xFF6B7280);
const Color backgroundColor = Color(0xFFF9FAFB);
const Color borderColor = Color(0xFFECECEC);

// Global Onboarding UI Colors
const Color activeDotColor = primaryRed;
const Color inactiveDotColor = primaryYellow;
const Color nextButtonBgColor = primaryRed;
const Color nextButtonOuterBgColor = Color(
  0x26ED292A,
); // 15% opacity primaryRed

const LinearGradient appBarGradient = LinearGradient(
  colors: [
    Color.fromRGBO(255, 247, 247, 1),
    Color.fromRGBO(255, 241, 241, 1),
    Color.fromRGBO(255, 231, 231, 1),
  ],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

const LinearGradient headerGradient = LinearGradient(
  colors: [
    Color.fromRGBO(255, 247, 247, 0.9),
    Color.fromRGBO(255, 241, 241, 0.9),
  ],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);
const LinearGradient ordercardGradient = LinearGradient(
  begin: Alignment.bottomCenter,
  end: Alignment.topCenter,
  colors: [
    Color.fromRGBO(255, 241, 241, 0.5),
    Color.fromRGBO(255, 241, 241, 0.5),
    Color.fromRGBO(237, 41, 42, 0.6),
    Color.fromRGBO(237, 41, 42, 0.6),
  ],
);

// Global Dashboard UI Colors
const Color secondaryRed = Color.fromRGBO(255, 255, 255, 0.2);
const Color primaryLightYellow = Color.fromRGBO(254, 242, 241, 1);
const Color utilitiesFillColor = Color.fromRGBO(255, 241, 241, 1);
const Color utilitiesBorderColor = Color.fromRGBO(255, 184, 184, 1);

const LinearGradient topBackgroundGradient = LinearGradient(
  colors: [
    Color.fromRGBO(254, 242, 241, 1),
    Color.fromRGBO(255, 241, 241, 1),
    Color.fromRGBO(237, 41, 42, 1),
  ],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);
