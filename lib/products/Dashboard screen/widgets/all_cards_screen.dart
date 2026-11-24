import 'package:flutter/material.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/notification_button.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/premium_visa_card.dart';
import 'package:transwallet/products/Dashboard%20screen/controllers/wallet_card_controller.dart';
import 'package:transwallet/products/Dashboard%20screen/models/wallet_card_model.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/mpin_verify_sheet.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/card_popups.dart';
import 'package:transwallet/products/Manage%20Card/managecard_Controller.dart';

class AllCardsScreen extends StatefulWidget {
  const AllCardsScreen({super.key});

  @override
  State<AllCardsScreen> createState() => _AllCardsScreenState();
}

class _AllCardsScreenState extends State<AllCardsScreen> {
  late final WalletCardController walletController;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    walletController = Get.isRegistered<WalletCardController>()
        ? Get.find<WalletCardController>()
        : Get.put(WalletCardController());
    walletController.fetchCardsFromApi();
  }

  void _onCardTap(WalletCardModel card) {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 1500)) {
      return;
    }
    _lastTapTime = now;

    if (card.isPermanentlyBlocked) {
      walletController.showPermanentlyBlockedNotice();
      return;
    }

    final cardMap = {
      "id": card.id,
      "kitNumber": card.id,
      "fullNumber": card.cardNumber,
      "holder": card.cardHolder,
      "expiry": card.expiry,
      "bgImage": card.bgImage,
      "useBlackLogos": card.useBlackLogos,
      "isBlocked": card.isBlocked,
      "isPermanentlyBlocked": card.isPermanentlyBlocked,
      "status": card.status,
      "colors": [card.primaryColor, card.secondaryColor],
      "label": card.type,
      "brand": card.brand,
      "cardType": card.type.toUpperCase().contains('PHYSICAL')
          ? 'PHYSICAL'
          : 'VIRTUAL',
      "type": card.type.toUpperCase().contains('PHYSICAL')
          ? 'PHYSICAL'
          : 'VIRTUAL',
      "isVirtual": !card.type.toUpperCase().contains('PHYSICAL'),
      "isPhysical": card.type.toUpperCase().contains('PHYSICAL'),
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

  void _onManageCardTap(WalletCardModel card) {
    if (card.isPermanentlyBlocked) {
      walletController.showPermanentlyBlockedNotice();
      return;
    }

    final cardMap = {
      "id": card.id,
      "kitNumber": card.id,
      "fullNumber": card.cardNumber,
      "cardNumber": card.cardNumber,
      "holder": card.cardHolder,
      "expiry": card.expiry,
      "bgImage": card.bgImage,
      "useBlackLogos": card.useBlackLogos,
      "isBlocked": card.isBlocked,
      "isPermanentlyBlocked": card.isPermanentlyBlocked,
      "status": card.status,
      "colors": [card.primaryColor, card.secondaryColor],
      "label": "Card Details",
      "brand": card.brand,
      "cardType": card.type.toUpperCase().contains('PHYSICAL')
          ? 'PHYSICAL'
          : 'VIRTUAL',
      "type": card.type.toUpperCase().contains('PHYSICAL')
          ? 'PHYSICAL'
          : 'VIRTUAL',
      "isVirtual": !card.type.toUpperCase().contains('PHYSICAL'),
      "isPhysical": card.type.toUpperCase().contains('PHYSICAL'),
    };

    if (Get.isRegistered<ManagecardController>()) {
      Get.delete<ManagecardController>(force: true);
    }
    Get.toNamed('/managecard', arguments: cardMap);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        title: const Text(
          'My Cards',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 20,
            letterSpacing: 0,
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: Center(child: NotificationButton()),
          ),
        ],
      ),
      body: Obx(() {
        final cardsList = walletController.cards;
        if (cardsList.isEmpty) {
          return const Center(
            child: Text(
              "No cards found",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          itemCount: cardsList.length,
          separatorBuilder: (context, index) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            final card = cardsList[index];
            final String fullNumber = card.cardNumber;
            final String cleanNum = fullNumber.replaceAll(RegExp(r'\s+'), '');
            final String last4 = cleanNum.length >= 4
                ? cleanNum.substring(cleanNum.length - 4)
                : "****";

            return Stack(
              children: [
                Positioned(
                  bottom: 0,
                  left: 10,
                  right: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      border: Border.all(color: Colors.black12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      child: InkWell(
                        onTap: () => _onManageCardTap(card),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: 18,
                                    color: Colors.black87,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Manage Card",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: card.isPermanentlyBlocked
                                          ? const Color(0xFFFFEBEE)
                                          : (card.isBlocked
                                                ? const Color(0xFFFFF3E0)
                                                : const Color(0xFFE8F5E9)),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      card.isPermanentlyBlocked
                                          ? "Blocked"
                                          : (card.isBlocked
                                                ? "Frozen"
                                                : "Active"),
                                      style: TextStyle(
                                        color: card.isPermanentlyBlocked
                                            ? const Color(0xFFC62828)
                                            : (card.isBlocked
                                                  ? const Color(0xFFE65100)
                                                  : const Color(0xFF2E7D32)),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_ios_outlined,
                                    size: 14,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 55),
                  child: PremiumVisaCard(
                    cardNumber: fullNumber,
                    cardHolder: card.cardHolder,
                    expiryDate: card.expiry,
                    cvv: "•••",
                    bgImage: card.bgImage,
                    brand: card.brand,
                    useBlackLogos: card.useBlackLogos,
                    isBlocked: card.isBlocked,
                    isPermanentlyBlocked: card.isPermanentlyBlocked,
                    shadowColor: Colors.transparent,
                    onTap: () {
                      if (card.isPermanentlyBlocked) {
                        walletController.showPermanentlyBlockedNotice();
                      } else if (card.isBlocked) {
                        walletController.promptUnfreezeCard(index);
                      } else {
                        _onCardTap(card);
                      }
                    },
                  ),
                ),
                if (!card.isBlocked && !card.isPermanentlyBlocked)
                  Positioned(
                    top: context.responsive(65),
                    right: context.responsive(15),
                    child: IgnorePointer(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive(10),
                          vertical: context.responsive(5),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(
                            context.responsive(20),
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: context.responsive(12),
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                            SizedBox(width: context.responsive(5)),
                            Text(
                              "Tap to see Card details",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: context.responsive(11),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      }),
    );
  }
}
