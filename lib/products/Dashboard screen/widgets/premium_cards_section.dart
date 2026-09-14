import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Dashboard screen/controllers/wallet_card_controller.dart';
import 'package:transwallet/products/Dashboard screen/widgets/realistic_wallet_widget.dart';
import 'package:transwallet/products/Dashboard screen/widgets/mpin_verify_sheet.dart';
import 'package:transwallet/products/Dashboard screen/widgets/card_popups.dart';
import 'package:transwallet/products/Dashboard screen/widgets/all_cards_screen.dart';

class PremiumCardsSection extends StatefulWidget {
  const PremiumCardsSection({super.key});

  @override
  State<PremiumCardsSection> createState() => _PremiumCardsSectionState();
}

class _PremiumCardsSectionState extends State<PremiumCardsSection> {
  late final WalletCardController _walletController;

  @override
  void initState() {
    super.initState();
    _walletController = Get.put(WalletCardController());
  }

  void _onActiveCardTap(int index) {
    if (index < 0 || index >= _walletController.cards.length) return;
    final cardModel = _walletController.cards[index];
    final cardMap = {
      "id": cardModel.id,
      "kitNumber": cardModel.id,
      "fullNumber": cardModel.cardNumber,
      "holder": cardModel.cardHolder,
      "expiry": cardModel.expiry,
      "bgImage": cardModel.bgImage,
      "useBlackLogos": cardModel.useBlackLogos,
      "isBlocked": cardModel.isBlocked,
      "status": cardModel.isBlocked ? "LOCKED" : "ALLOCATED",
      "colors": [cardModel.primaryColor, cardModel.secondaryColor],
      "label": cardModel.type,
      "brand": cardModel.brand,
    };

    Get.bottomSheet(
      MpinVerifySheet(
        onSuccess: () {
          Get.dialog(
            CardDetailsPopup(card: cardMap),
            barrierColor: Colors.transparent,
          );
        },
        title: 'Verify MPIN',
        subtitle: 'Enter MPIN to view card details',
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RealisticWalletWidget(
          controller: _walletController,
          onCardTap: _onActiveCardTap,
        ),
        const SizedBox(height: 35),
      ],
    );
  }
}
