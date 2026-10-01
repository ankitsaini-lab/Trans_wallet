import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:transwallet/products/Dashboard screen/models/wallet_card_model.dart';
import 'package:transwallet/services/api_service.dart';

class WalletCardController extends GetxController {
  final RxList<WalletCardModel> cards = <WalletCardModel>[].obs;
  final RxInt selectedIndex = 0.obs;
  final RxBool isAnimating = false.obs;
  Timer? _autoResetTimer;

  @override
  void onInit() {
    super.onInit();
    _loadInitialCards();
    fetchCardsFromApi();
    _startAutoResetTimer();
  }

  @override
  void onClose() {
    _autoResetTimer?.cancel();
    super.onClose();
  }

  void _loadInitialCards() {
    final String holderName = GetStorage().read('name') ?? "USER";
    final storedCards = GetStorage().read('user_cards');

    if (storedCards is List && storedCards.isNotEmpty) {
      final List<WalletCardModel> apiList = storedCards.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = Map<String, dynamic>.from(entry.value as Map);
        final masked = item['maskedNumber']?.toString() ?? '';
        final expiryRaw = item['expiryMmYy']?.toString() ?? '';
        String expiryFormatted = '08/28';
        if (expiryRaw.length == 4) {
          expiryFormatted = '${expiryRaw.substring(0, 2)}/${expiryRaw.substring(2)}';
        }
        final cardType = item['cardType']?.toString() ?? 'VIRTUAL';
        final network = item['network']?.toString() ?? 'RUPAY';
        final status = item['status']?.toString().toUpperCase() ?? 'ALLOCATED';
        final bool isCardLocked = status == 'LOCKED' || status == 'BLOCKED';

        final isYellow = idx % 2 == 0;
        return WalletCardModel(
          id: item['kitNumber']?.toString() ?? '${idx + 1}',
          type: cardType == 'VIRTUAL' ? 'Virtual Card' : 'Physical Card',
          cardNumber: masked.isNotEmpty
              ? masked
              : '•••• •••• •••• ${item['last4'] ?? 2203}',
          cardHolder: holderName,
          expiry: expiryFormatted,
          brand: network,
          primaryColor: isYellow
              ? const Color(0xFFE5A93C)
              : const Color(0xFF8E9EAB),
          secondaryColor: isYellow
              ? const Color(0xFFF7D070)
              : const Color(0xFFEEF2F3),
          bgImage: isYellow
              ? 'assets/unioncardyellow.png'
              : 'assets/unioncardblack.png',
          useBlackLogos: false,
          isBlocked: isCardLocked,
        );
      }).toList();

      cards.assignAll(apiList);
      return;
    }

    cards.clear();
  }

  Future<void> fetchCardsFromApi() async {
    if (!Get.isRegistered<ApiService>()) return;
    try {
      final res = await ApiService.to.fetchUserCards();
      if (res != null && res['cards'] != null && res['cards'] is List) {
        final List rawList = res['cards'] as List;
        if (rawList.isNotEmpty) {
          final String holderName = GetStorage().read('name') ?? "USER";
          final List<WalletCardModel> apiList = rawList.asMap().entries.map((
            entry,
          ) {
            final idx = entry.key;
            final item = Map<String, dynamic>.from(entry.value as Map);
            final masked = item['maskedNumber']?.toString() ?? '';
            final expiryRaw = item['expiryMmYy']?.toString() ?? '';
            String expiryFormatted = '08/28';
            if (expiryRaw.length == 4) {
              expiryFormatted =
                  '${expiryRaw.substring(0, 2)}/${expiryRaw.substring(2)}';
            }
            final cardType = item['cardType']?.toString() ?? 'VIRTUAL';
            final network = item['network']?.toString() ?? 'RUPAY';
            final status = item['status']?.toString().toUpperCase() ?? 'ALLOCATED';
            final bool isCardLocked = status == 'LOCKED' || status == 'BLOCKED';

            final isYellow = idx % 2 == 0;
            return WalletCardModel(
              id: item['kitNumber']?.toString() ?? '${idx + 1}',
              type: cardType == 'VIRTUAL' ? 'Virtual Card' : 'Physical Card',
              cardNumber: masked.isNotEmpty
                  ? masked
                  : '•••• •••• •••• ${item['last4'] ?? 2203}',
              cardHolder: holderName,
              expiry: expiryFormatted,
              brand: network,
              primaryColor: isYellow
                  ? const Color(0xFFE5A93C)
                  : const Color(0xFF8E9EAB),
              secondaryColor: isYellow
                  ? const Color(0xFFF7D070)
                  : const Color(0xFFEEF2F3),
              bgImage: isYellow
                  ? 'assets/unioncardyellow.png'
                  : 'assets/unioncardblack.png',
              useBlackLogos: false,
              isBlocked: isCardLocked,
            );
          }).toList();

          cards.assignAll(apiList);
        }
      }
    } catch (e) {
      log('Error fetching cards in WalletCardController: $e');
    }
  }

  void selectCard(int index) {
    if (index < 0 || index >= cards.length) return;

    if (selectedIndex.value != index) {
      HapticFeedback.selectionClick();
      selectedIndex.value = index;
    }

    _startAutoResetTimer();
  }

  void _startAutoResetTimer() {
    _autoResetTimer?.cancel();
    _autoResetTimer = Timer(const Duration(seconds: 10), () {
      if (selectedIndex.value != 0) {
        selectCard(0);
      }
    });
  }

  void nextCard() {
    if (cards.isEmpty) return;
    final nextIndex = (selectedIndex.value + 1) % cards.length;
    selectCard(nextIndex);
  }

  void previousCard() {
    if (cards.isEmpty) return;
    final prevIndex = (selectedIndex.value - 1 + cards.length) % cards.length;
    selectCard(prevIndex);
  }

  Future<void> toggleBlockCard(int index) async {
    if (index < 0 || index >= cards.length) return;
    final card = cards[index];
    final bool isCurrentlyBlocked = card.isBlocked;
    final String action = isCurrentlyBlocked ? "UNLOCK" : "LOCK";
    final String kitNumber = card.id;

    if (kitNumber.isNotEmpty && Get.isRegistered<ApiService>()) {
      final res = await ApiService.to.manageCardLock(
        kitNumber: kitNumber,
        action: action,
        reason: isCurrentlyBlocked ? "Unlocking card via Dashboard" : "Locking card via Dashboard",
      );
      if (res != null) {
        final String status = res['status']?.toString().toUpperCase() ?? '';
        final String resAction = res['action']?.toString().toUpperCase() ?? '';
        final bool isNowLocked = (status == 'LOCKED' || status == 'BLOCKED' || resAction == 'LOCK' || resAction == 'PERMANENT_BLOCK') ||
            (action == 'LOCK' && status.isEmpty && resAction.isEmpty);
        cards[index] = cards[index].copyWith(isBlocked: isNowLocked);
        cards.refresh();
        Get.snackbar(
          "Success",
          isNowLocked ? "Card Freezed Successfully" : "Card Unfreezed Successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black,
          colorText: Colors.white,
          margin: const EdgeInsets.all(14),
          borderRadius: 12,
        );
      } else {
        Get.snackbar(
          "Error",
          isCurrentlyBlocked ? "Failed to unfreeze card. Please try again." : "Failed to freeze card. Please try again.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade900,
          colorText: Colors.white,
          margin: const EdgeInsets.all(14),
          borderRadius: 12,
        );
      }
      return;
    }

    cards[index] = cards[index].copyWith(isBlocked: !isCurrentlyBlocked);
    cards.refresh();
  }
}
