import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';

class OrdercardController extends GetxController {
  var activeCardIndex = 0.obs;
  var amount = 897.obs;

  final List<Map<String, dynamic>> cardStyles = [
    {
      "name": "Prepaid Card",
      "glowColor": primaryRed,
      "label": "Gold Elite",
      "textColor": const Color(0xFF111111),
      "subColor": const Color(0xFF4B5563),
      "bgImage": 'assets/unioncardyellow.png',
      "useBlackLogos": false,
      "isPopular": false,
    },
  ];
}
