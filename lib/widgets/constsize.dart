import 'package:flutter/material.dart';

const SizedBox height2 = SizedBox(height: 2);
const SizedBox height4 = SizedBox(height: 4);
const SizedBox height6 = SizedBox(height: 6);
const SizedBox height8 = SizedBox(height: 8);
const SizedBox height10 = SizedBox(height: 10);
const SizedBox height12 = SizedBox(height: 12);
const SizedBox height14 = SizedBox(height: 14);
const SizedBox height16 = SizedBox(height: 16);
const SizedBox height20 = SizedBox(height: 20);
const SizedBox height24 = SizedBox(height: 24);
const SizedBox height30 = SizedBox(height: 30);
const SizedBox height40 = SizedBox(height: 40);

const SizedBox width2 = SizedBox(width: 2);
const SizedBox width4 = SizedBox(width: 4);
const SizedBox width6 = SizedBox(width: 6);
const SizedBox width8 = SizedBox(width: 8);
const SizedBox width10 = SizedBox(width: 10);
const SizedBox width12 = SizedBox(width: 12);
const SizedBox width16 = SizedBox(width: 16);
const SizedBox width20 = SizedBox(width: 20);
const SizedBox width24 = SizedBox(width: 24);
const SizedBox width32 = SizedBox(width: 32);

const SizedBox heightZero = SizedBox.shrink();

extension ResponsiveSize on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  // Base width is 390. Clamped between 0.85 and 1.15 to prevent extreme scaling.
  double get scaleFactor => (screenWidth / 390).clamp(0.85, 1.15);
  
  double responsive(double size) => size * scaleFactor;
}
