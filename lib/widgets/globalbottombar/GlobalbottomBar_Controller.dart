import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/services_more_screen.dart';
import 'package:transwallet/products/Profile%20screen/Profilescreen_View.dart';

class GlobalbottombarController extends GetxController {
  var selectedIndex = 0.obs;

  void changeIndex(int index) {
    selectedIndex.value = index;

    switch (index) {
      case 0:
        Get.offNamed("/dashboard");
        break;
      case 1:
        Get.offNamed("/wallet");
        break;
      case 2:
        Get.offNamed("/history");
        break;
      case 3:
        Get.offNamed("/profileview");
        break;
    }
  }
}

class WaterDropClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    double w = size.width;
    double h = size.height;

    path.moveTo(w / 2, 0);
    path.quadraticBezierTo(0, h * 0.3, w / 2, h);
    path.quadraticBezierTo(w, h * 0.3, w / 2, 0);

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
