import 'dart:async';
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:transwallet/products/Dashboard screen/models/wallet_card_model.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/widgets/premium_visa_card.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/products/Dashboard screen/dashboardscreen_Controller.dart';

class WalletCardController extends GetxController {
  final RxList<WalletCardModel> cards = <WalletCardModel>[].obs;
  final RxInt selectedIndex = 0.obs;
  final RxBool isAnimating = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isError = false.obs;
  final RxString errorMessage = ''.obs;
  Timer? _autoResetTimer;
  DateTime? _lastBlockedNoticeTime;

  bool get _canFetchCards {
    final box = GetStorage();
    final bool loggedIn =
        (box.read<bool>('is_logged_in') ?? false) &&
        (box.read<String>('accessToken') != null ||
            box.read<String>('auth_token') != null);
    final bool isLoggingOut =
        (Get.isRegistered<AuthService>() && AuthService.to.isLoggingOut) ||
        (Get.isRegistered<ApiService>() && ApiService.to.isLoggingOut);
    return loggedIn && !isLoggingOut;
  }

  @override
  void onInit() {
    super.onInit();
    _loadInitialCards();
    if (_canFetchCards) {
      fetchCardsFromApi();
      _startAutoResetTimer();
    }
  }

  @override
  void onClose() {
    _autoResetTimer?.cancel();
    super.onClose();
  }

  void clear() {
    _autoResetTimer?.cancel();
    cards.clear();
    selectedIndex.value = 0;
    isAnimating.value = false;
    isLoading.value = false;
    isError.value = false;
    errorMessage.value = '';
  }

  void _loadInitialCards() {
    final rawName =
        (GetStorage().read('name') ?? GetStorage().read('userName') ?? '')
            .toString()
            .trim();
    final String holderName = rawName.isNotEmpty
        ? rawName.toUpperCase()
        : "CARDHOLDER";
    final storedCards = GetStorage().read('user_cards');

    if (storedCards is List && storedCards.isNotEmpty) {
      final List<WalletCardModel> apiList = storedCards.asMap().entries.map((
        entry,
      ) {
        final idx = entry.key;
        final item = Map<String, dynamic>.from(entry.value as Map);
        final masked = item['maskedNumber']?.toString() ?? '';
        final expiryRaw =
            item['expiryMmYy']?.toString() ?? item['expiry']?.toString() ?? '';
        String expiryFormatted = '--/--';
        final digits = expiryRaw.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length == 4) {
          expiryFormatted =
              '${digits.substring(0, 2)}/${digits.substring(2, 4)}';
        } else if (expiryRaw.contains('/')) {
          expiryFormatted = expiryRaw;
        } else if (expiryRaw.isNotEmpty) {
          expiryFormatted = expiryRaw;
        }
        final cardType = item['cardType']?.toString() ?? 'VIRTUAL';
        final network =
            item['network']?.toString() ??
            item['brand']?.toString() ??
            item['cardNetwork']?.toString() ??
            'RUPAY';
        final status = item['status']?.toString().toUpperCase() ?? 'ALLOCATED';
        final bool isPermBlocked =
            status == 'BLOCKED' ||
            status == 'PERMANENT_BLOCK' ||
            status == 'PERMANENTLY_BLOCKED' ||
            item['isPermanentlyBlocked'] == true;
        final bool isCardLocked =
            !isPermBlocked &&
            (status == 'LOCKED' ||
                status == 'FROZEN' ||
                item['isBlocked'] == true);
        final dynamicBg = PremiumVisaCard.resolveCardBgImage(
          brand: item['brand']?.toString(),
          network: network,
          bgImage: item['bgImage']?.toString(),
        );

        final isYellow = idx % 2 == 0;
        final last4 = item['last4']?.toString() ?? '';
        return WalletCardModel(
          id: item['kitNumber']?.toString() ?? '${idx + 1}',
          type: cardType == 'VIRTUAL' ? 'Virtual Card' : 'Physical Card',
          cardNumber: masked.isNotEmpty
              ? masked
              : (last4.isNotEmpty
                    ? '•••• •••• •••• $last4'
                    : '•••• •••• •••• ••••'),
          cardHolder: holderName,
          expiry: expiryFormatted,
          brand: network,
          primaryColor: isYellow
              ? const Color(0xFFE5A93C)
              : const Color(0xFF8E9EAB),
          secondaryColor: isYellow
              ? const Color(0xFFF7D070)
              : const Color(0xFFEEF2F3),
          bgImage: dynamicBg,
          useBlackLogos: false,
          isBlocked: isCardLocked,
          isPermanentlyBlocked: isPermBlocked,
          status: status,
        );
      }).toList();

      cards.assignAll(apiList);
      if (selectedIndex.value >= apiList.length) {
        selectedIndex.value = 0;
      }
      return;
    }

    cards.clear();
  }

  Future<void> fetchCardsFromApi({bool isRetry = false}) async {
    if (!_canFetchCards || !Get.isRegistered<ApiService>()) return;
    if (cards.isEmpty || isRetry) {
      isLoading.value = true;
    }
    isError.value = false;
    errorMessage.value = '';
    try {
      final res = await ApiService.to.fetchUserCards();
      if (res != null && res['cards'] != null && res['cards'] is List) {
        final List rawList = res['cards'] as List;
        if (rawList.isNotEmpty) {
          final rawName =
              (GetStorage().read('name') ?? GetStorage().read('userName') ?? '')
                  .toString()
                  .trim();
          final String holderName = rawName.isNotEmpty
              ? rawName.toUpperCase()
              : "CARDHOLDER";
          final List<WalletCardModel> apiList = rawList.asMap().entries.map((
            entry,
          ) {
            final idx = entry.key;
            final item = Map<String, dynamic>.from(entry.value as Map);
            final masked = item['maskedNumber']?.toString() ?? '';
            final expiryRaw =
                item['expiryMmYy']?.toString() ??
                item['expiry']?.toString() ??
                '';
            String expiryFormatted = '--/--';
            final digits = expiryRaw.replaceAll(RegExp(r'[^0-9]'), '');
            if (digits.length == 4) {
              expiryFormatted =
                  '${digits.substring(0, 2)}/${digits.substring(2, 4)}';
            } else if (expiryRaw.contains('/')) {
              expiryFormatted = expiryRaw;
            } else if (expiryRaw.isNotEmpty) {
              expiryFormatted = expiryRaw;
            }
            final cardType = item['cardType']?.toString() ?? 'VIRTUAL';
            final network =
                item['network']?.toString() ??
                item['brand']?.toString() ??
                item['cardNetwork']?.toString() ??
                'RUPAY';
            final status =
                item['status']?.toString().toUpperCase() ?? 'ALLOCATED';
            final bool isPermBlocked =
                status == 'BLOCKED' ||
                status == 'PERMANENT_BLOCK' ||
                status == 'PERMANENTLY_BLOCKED' ||
                item['isPermanentlyBlocked'] == true;
            final bool isCardLocked =
                !isPermBlocked &&
                (status == 'LOCKED' ||
                    status == 'FROZEN' ||
                    item['isBlocked'] == true);
            final dynamicBg = PremiumVisaCard.resolveCardBgImage(
              brand: item['brand']?.toString(),
              network: network,
              bgImage: item['bgImage']?.toString(),
            );

            final isYellow = idx % 2 == 0;
            final last4 = item['last4']?.toString() ?? '';
            return WalletCardModel(
              id: item['kitNumber']?.toString() ?? '${idx + 1}',
              type: cardType == 'VIRTUAL' ? 'Virtual Card' : 'Physical Card',
              cardNumber: masked.isNotEmpty
                  ? masked
                  : (last4.isNotEmpty
                        ? '•••• •••• •••• $last4'
                        : '•••• •••• •••• ••••'),
              cardHolder: holderName,
              expiry: expiryFormatted,
              brand: network,
              primaryColor: isYellow
                  ? const Color(0xFFE5A93C)
                  : const Color(0xFF8E9EAB),
              secondaryColor: isYellow
                  ? const Color(0xFFF7D070)
                  : const Color(0xFFEEF2F3),
              bgImage: dynamicBg,
              useBlackLogos: false,
              isBlocked: isCardLocked,
              isPermanentlyBlocked: isPermBlocked,
              status: status,
            );
          }).toList();

          cards.assignAll(apiList);
          if (selectedIndex.value >= apiList.length) {
            selectedIndex.value = 0;
          }
        }
      }
    } catch (e) {
      log('Error fetching cards in WalletCardController: $e');
      if (cards.isEmpty) {
        isError.value = true;
        errorMessage.value = 'Failed to load cards';
      }
    } finally {
      isLoading.value = false;
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

  void showPermanentlyBlockedNotice({String? message}) {
    final now = DateTime.now();
    if (_lastBlockedNoticeTime != null &&
        now.difference(_lastBlockedNoticeTime!) <
            const Duration(milliseconds: 1500)) {
      return;
    }
    if (Get.isSnackbarOpen) {
      return;
    }
    _lastBlockedNoticeTime = now;
    HapticFeedback.lightImpact();
    AppSnackbar.show(
      title: "Card Blocked",
      message:
          message ??
          "This card is permanently blocked and its details cannot be viewed or accessed.",
      isSuccess: false,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void promptUnfreezeCard(int index) {
    if (index < 0 || index >= cards.length) return;
    final card = cards[index];
    if (card.isPermanentlyBlocked) {
      showPermanentlyBlockedNotice(
        message: "This card is permanently blocked and cannot be unfreezed.",
      );
      return;
    }

    final cardNum = card.cardNumber.replaceAll(RegExp(r'\s+'), '');
    final last4 = cardNum.length >= 4
        ? cardNum.substring(cardNum.length - 4)
        : (cardNum.isNotEmpty ? cardNum : "****");

    final cardMap = {
      "id": card.id,
      "kitNumber": card.id,
      "fullNumber": card.cardNumber,
      "holder": card.cardHolder,
      "expiry": card.expiry,
      "bgImage": card.bgImage,
      "useBlackLogos": card.useBlackLogos,
      "isBlocked": true,
      "isPermanentlyBlocked": card.isPermanentlyBlocked,
      "status": card.status.isNotEmpty ? card.status : "LOCKED",
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

    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

    Get.bottomSheet(
      Builder(
        builder: (sheetContext) {
          return Container(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header icon - Snowflake / Frozen Lock
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEFF6FF),
                      border: Border.all(
                        color: const Color(0xFFBFDBFE),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.ac_unit_rounded,
                      color: Color(0xFF2563EB),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "Card is Frozen",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    "Your card is currently frozen and transactions are temporarily paused. To unfreeze this card, please go to Card Controls.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Card preview tile
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEFF6FF),
                            border: Border.all(
                              color: const Color(0xFFBFDBFE),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.credit_card,
                            color: Color(0xFF2563EB),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Card Ending •••• $last4",
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "Frozen / Temporarily Blocked",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (Navigator.of(sheetContext).canPop()) {
                              Navigator.of(sheetContext).pop();
                            } else {
                              Get.back();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (Navigator.of(sheetContext).canPop()) {
                              Navigator.of(sheetContext).pop();
                            } else {
                              Get.back();
                            }
                            Get.toNamed(
                              '/managecard',
                              arguments: cardMap,
                            )?.then((_) {
                              fetchCardsFromApi();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Manage Card / Unfreeze",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> toggleBlockCard(int index) async {
    if (index < 0 || index >= cards.length) return;
    final card = cards[index];
    if (card.isPermanentlyBlocked) {
      showPermanentlyBlockedNotice(
        message:
            "This card is permanently blocked and cannot be unfreezed or modified.",
      );
      return;
    }

    final bool isCurrentlyBlocked = card.isBlocked;
    final String action = isCurrentlyBlocked ? "UNLOCK" : "LOCK";
    final String kitNumber = card.id;

    if (kitNumber.isNotEmpty && Get.isRegistered<ApiService>()) {
      final res = await ApiService.to.manageCardLock(
        kitNumber: kitNumber,
        action: action,
        reason: isCurrentlyBlocked
            ? "Unlocking card via Dashboard"
            : "Locking card via Dashboard",
      );
      if (res != null) {
        final String status = res['status']?.toString().toUpperCase() ?? '';
        final String resAction = res['action']?.toString().toUpperCase() ?? '';
        final bool isNowPermBlocked =
            status == 'BLOCKED' || resAction == 'PERMANENT_BLOCK';
        final bool isNowLocked =
            !isNowPermBlocked &&
            ((status == 'LOCKED' || resAction == 'LOCK') ||
                (action == 'LOCK' && status.isEmpty && resAction.isEmpty));

        syncCardStatus(
          kitNumber: kitNumber,
          isBlocked: isNowLocked,
          isPermanentlyBlocked: isNowPermBlocked,
          status: isNowPermBlocked
              ? 'BLOCKED'
              : (isNowLocked ? 'LOCKED' : 'ALLOCATED'),
        );
        // Refresh cards from API in background to ensure complete sync
        fetchCardsFromApi();
        Get.snackbar(
          "Success",
          isNowLocked
              ? "Card Freezed Successfully"
              : "Card Unfreezed Successfully",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black,
          colorText: Colors.white,
          margin: const EdgeInsets.all(14),
          borderRadius: 12,
        );
      } else {
        Get.snackbar(
          "Error",
          isCurrentlyBlocked
              ? "Failed to unfreeze card. Please try again."
              : "Failed to freeze card. Please try again.",
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

  void syncCardStatus({
    required String kitNumber,
    required bool isBlocked,
    required bool isPermanentlyBlocked,
    required String status,
  }) {
    final idx = cards.indexWhere(
      (c) =>
          c.id == kitNumber ||
          c.cardNumber.replaceAll(RegExp(r'\s+'), '').endsWith(kitNumber),
    );
    if (idx != -1) {
      cards[idx] = cards[idx].copyWith(
        isBlocked: isBlocked,
        isPermanentlyBlocked: isPermanentlyBlocked,
        status: status,
      );
      cards.refresh();
    } else if (cards.isNotEmpty) {
      if (cards.length == 1) {
        cards[0] = cards[0].copyWith(
          isBlocked: isBlocked,
          isPermanentlyBlocked: isPermanentlyBlocked,
          status: status,
        );
        cards.refresh();
      }
    }

    final box = GetStorage();
    box.write('is_blocked', isBlocked);
    box.write('is_card_blocked', isBlocked);
    if (isPermanentlyBlocked) {
      box.write('is_permanently_blocked', true);
      box.write('is_card_permanently_blocked', true);
    }
    if (Get.isRegistered<DashboardscreenController>()) {
      Get.find<DashboardscreenController>().checkCardBlockedStatus();
    }
    final storedCards = box.read('user_cards');
    if (storedCards is List) {
      final updatedList = storedCards.map((c) {
        if (c is Map &&
            (c['kitNumber']?.toString() == kitNumber ||
                c['id']?.toString() == kitNumber)) {
          final copy = Map<String, dynamic>.from(c);
          copy['status'] = status;
          copy['isBlocked'] = isBlocked;
          copy['isPermanentlyBlocked'] = isPermanentlyBlocked;
          return copy;
        }
        return c;
      }).toList();
      box.write('user_cards', updatedList);
    }
  }
}
