import 'package:flutter/material.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/notification_button.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/premium_visa_card.dart';
import 'package:transwallet/products/Dashboard%20screen/controllers/wallet_card_controller.dart';
import 'package:transwallet/products/Dashboard%20screen/models/wallet_card_model.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/mpin_verify_sheet.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/card_popups.dart';

class AllCardsScreen extends StatelessWidget {
  const AllCardsScreen({super.key});

  void _onCardTap(WalletCardModel card) {
    final cardMap = {
      "id": card.id,
      "kitNumber": card.id,
      "fullNumber": card.cardNumber,
      "holder": card.cardHolder,
      "expiry": card.expiry,
      "bgImage": card.bgImage,
      "useBlackLogos": card.useBlackLogos,
      "isBlocked": card.isBlocked,
      "status": card.isBlocked ? "LOCKED" : "ALLOCATED",
      "colors": [card.primaryColor, card.secondaryColor],
      "label": card.type,
      "brand": card.brand,
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
    final walletController = Get.isRegistered<WalletCardController>()
        ? Get.find<WalletCardController>()
        : Get.put(WalletCardController());

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
            child: Center(
              child: NotificationButton(),
            ),
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
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            final card = cardsList[index];
            final String fullNumber = card.cardNumber;
            final String cleanNum = fullNumber.replaceAll(RegExp(r'\s+'), '');
            final String last4 = cleanNum.length >= 4
                ? cleanNum.substring(cleanNum.length - 4)
                : "0000";

            return GestureDetector(
              onTap: () => _onCardTap(card),
              child: Stack(
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
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${card.type} ···· $last4",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: card.isBlocked
                                            ? const Color(0xFFFFEBEE)
                                            : const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        card.isBlocked ? "Blocked" : "Active",
                                        style: TextStyle(
                                          color: card.isBlocked
                                              ? const Color(0xFFC62828)
                                              : const Color(0xFF2E7D32),
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
                        ],
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
                      useBlackLogos: card.useBlackLogos,
                      isBlocked: card.isBlocked,
                      shadowColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
