import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Dashboard screen/controllers/wallet_card_controller.dart';
import 'package:transwallet/products/Dashboard screen/widgets/realistic_wallet_widget.dart';
import 'package:transwallet/products/Dashboard screen/widgets/mpin_verify_sheet.dart';
import 'package:transwallet/products/Dashboard screen/widgets/card_popups.dart';

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

    if (cardModel.isPermanentlyBlocked) {
      _walletController.showPermanentlyBlockedNotice();
      return;
    }
    if (cardModel.isBlocked) {
      _walletController.promptUnfreezeCard(index);
      return;
    }

    final cardMap = {
      "id": cardModel.id,
      "kitNumber": cardModel.id,
      "fullNumber": cardModel.cardNumber,
      "holder": cardModel.cardHolder,
      "expiry": cardModel.expiry,
      "bgImage": cardModel.bgImage,
      "useBlackLogos": cardModel.useBlackLogos,
      "isBlocked": cardModel.isBlocked,
      "isPermanentlyBlocked": cardModel.isPermanentlyBlocked,
      "status": cardModel.status,
      "colors": [cardModel.primaryColor, cardModel.secondaryColor],
      "label": cardModel.type,
      "brand": cardModel.brand,
      "cardType": cardModel.type.toUpperCase().contains('PHYSICAL')
          ? 'PHYSICAL'
          : 'VIRTUAL',
      "type": cardModel.type.toUpperCase().contains('PHYSICAL')
          ? 'PHYSICAL'
          : 'VIRTUAL',
      "isVirtual": !cardModel.type.toUpperCase().contains('PHYSICAL'),
      "isPhysical": cardModel.type.toUpperCase().contains('PHYSICAL'),
    };

    Get.bottomSheet(
      MpinVerifySheet(
        onSuccess: () {
          Get.to(
            () => CardDetailsPopup(card: cardMap),
            transition: Transition.rightToLeftWithFade,
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
