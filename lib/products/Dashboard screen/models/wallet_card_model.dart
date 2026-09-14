import 'package:flutter/material.dart';

class WalletCardModel {
  final String id;
  final String type; // e.g. Visa Card, Forex Card, Virtual Card, Physical Card
  final String cardNumber;
  final String cardHolder;
  final String expiry;
  final String brand; // Visa, Mastercard, Transcorp
  final Color primaryColor;
  final Color secondaryColor;
  final String bgImage;
  final bool useBlackLogos;
  final bool isBlocked;

  WalletCardModel({
    required this.id,
    required this.type,
    required this.cardNumber,
    required this.cardHolder,
    required this.expiry,
    this.brand = 'Visa',
    this.primaryColor = const Color(0xFFFFCC00),
    this.secondaryColor = const Color(0xFF111111),
    this.bgImage = 'assets/unioncardblack.webp',
    this.useBlackLogos = false,
    this.isBlocked = false,
  });

  WalletCardModel copyWith({
    String? id,
    String? type,
    String? cardNumber,
    String? cardHolder,
    String? expiry,
    String? brand,
    Color? primaryColor,
    Color? secondaryColor,
    String? bgImage,
    bool? useBlackLogos,
    bool? isBlocked,
  }) {
    return WalletCardModel(
      id: id ?? this.id,
      type: type ?? this.type,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolder: cardHolder ?? this.cardHolder,
      expiry: expiry ?? this.expiry,
      brand: brand ?? this.brand,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      bgImage: bgImage ?? this.bgImage,
      useBlackLogos: useBlackLogos ?? this.useBlackLogos,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}
