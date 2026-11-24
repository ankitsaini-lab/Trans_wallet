import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/premium_visa_card.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/services/deep_link_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/products/Dashboard screen/controllers/wallet_card_controller.dart';
import 'package:transwallet/products/Dashboard screen/dashboardscreen_Controller.dart';

class FeatureControl {
  RxBool enabled;
  RxDouble limit;

  FeatureControl({bool enabled = false, double limit = 50})
    : enabled = enabled.obs,
      limit = limit.obs;
}

class ManagecardController extends GetxController {
  final RxBool isCardBlocked = false.obs;
  final RxBool isCardPermanentlyBlocked = false.obs;
  final RxBool isLoadingPreferences = false.obs;
  final RxMap<String, dynamic> cardData = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> preferencesData = <String, dynamic>{}.obs;

  /// Returns whether the current card is a Virtual Card
  bool get isVirtualCard {
    final rawType =
        (cardData['cardType'] ??
                cardData['card_type'] ??
                cardData['type'] ??
                cardData['label'])
            ?.toString()
            .toUpperCase() ??
        '';

    if (cardData['isVirtual'] == true || rawType.contains('VIRTUAL')) {
      return true;
    }
    if (cardData['isPhysical'] == true || rawType.contains('PHYSICAL')) {
      return false;
    }

    final kit = _getKitNumber();
    final storedCards = GetStorage().read('user_cards');
    if (storedCards is List && storedCards.isNotEmpty) {
      for (var c in storedCards) {
        if (c is Map &&
            (c['kitNumber']?.toString() == kit ||
                c['last4']?.toString() == cardData['last4']?.toString())) {
          final cType =
              (c['cardType'] ?? c['type'] ?? c['label'])
                  ?.toString()
                  .toUpperCase() ??
              '';
          if (c['isVirtual'] == true || cType.contains('VIRTUAL')) return true;
          if (c['isPhysical'] == true || cType.contains('PHYSICAL'))
            return false;
        }
      }
      final first = storedCards.first;
      if (first is Map) {
        final cType =
            (first['cardType'] ?? first['type'] ?? first['label'])
                ?.toString()
                .toUpperCase() ??
            '';
        if (first['isVirtual'] == true || cType.contains('VIRTUAL'))
          return true;
        if (first['isPhysical'] == true || cType.contains('PHYSICAL'))
          return false;
      }
    }

    // Default to virtual
    return true;
  }

  final atm = FeatureControl(enabled: true, limit: 100);
  final pos = FeatureControl();
  final ecom = FeatureControl();
  final international = FeatureControl();
  final dcc = FeatureControl();
  final contactless = FeatureControl();

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is Map) {
      cardData.addAll(Map<String, dynamic>.from(Get.arguments as Map));
    } else {
      final storedCards = GetStorage().read('user_cards');
      if (storedCards is List &&
          storedCards.isNotEmpty &&
          storedCards.first is Map) {
        cardData.addAll(Map<String, dynamic>.from(storedCards.first as Map));
      }
    }

    String status = cardData['status']?.toString().toUpperCase() ?? '';
    if (status.isEmpty) {
      final kit = _getKitNumber();
      final storedCards = GetStorage().read('user_cards');
      if (storedCards is List && storedCards.isNotEmpty) {
        for (var c in storedCards) {
          if (c is Map &&
              (c['kitNumber']?.toString() == kit ||
                  c['last4']?.toString() == cardData['last4']?.toString())) {
            status = c['status']?.toString().toUpperCase() ?? '';
            break;
          }
        }
      }
    }

    if (status == 'BLOCKED' ||
        status == 'PERMANENT_BLOCK' ||
        status == 'PERMANENTLY_BLOCKED' ||
        cardData['isPermanentlyBlocked'] == true) {
      isCardPermanentlyBlocked.value = true;
      isCardBlocked.value = false;
      cardData['isPermanentlyBlocked'] = true;
      cardData['isBlocked'] = false;
      cardData['status'] = 'BLOCKED';
    } else if (status == 'LOCKED' ||
        status == 'FROZEN' ||
        cardData['isBlocked'] == true) {
      isCardBlocked.value = true;
      isCardPermanentlyBlocked.value = false;
      cardData['isPermanentlyBlocked'] = false;
      cardData['isBlocked'] = true;
      cardData['status'] = 'LOCKED';
    } else {
      isCardBlocked.value = false;
      isCardPermanentlyBlocked.value = false;
      cardData['isPermanentlyBlocked'] = false;
      cardData['isBlocked'] = false;
      cardData['status'] = status.isNotEmpty ? status : 'ALLOCATED';
    }
    if (isVirtualCard) {
      atm.enabled.value = false;
      pos.enabled.value = false;
      contactless.enabled.value = false;
    }
    update();

    if (!isCardPermanentlyBlocked.value && _canFetchPreferences) {
      fetchCardPreferences();
    }
  }

  bool get _canFetchPreferences {
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

  void fetchCardDetails() => fetchCardPreferences();

  Future<void> fetchCardPreferences() async {
    if (!_canFetchPreferences || !Get.isRegistered<ApiService>()) return;
    isLoadingPreferences.value = true;
    try {
      final res = await ApiService.to.fetchCardPreferences();
      if (res != null) {
        preferencesData.assignAll(res);
        if (res.containsKey('atm')) {
          atm.enabled.value = isVirtualCard ? false : (res['atm'] == true);
        }
        if (res.containsKey('pos')) {
          pos.enabled.value = isVirtualCard ? false : (res['pos'] == true);
        }
        if (res.containsKey('ecom')) {
          ecom.enabled.value = res['ecom'] == true;
        }
        if (res.containsKey('international')) {
          international.enabled.value = res['international'] == true;
        }
        if (res.containsKey('dcc')) {
          dcc.enabled.value = res['dcc'] == true;
        }
        if (res.containsKey('contactless')) {
          contactless.enabled.value = isVirtualCard
              ? false
              : (res['contactless'] == true);
        }

        if (res['limits'] != null && res['limits'] is List) {
          final limitsList = res['limits'] as List;
          for (var item in limitsList) {
            if (item is Map) {
              final txnType = item['txnType']?.toString().toUpperCase() ?? '';
              final limitValue =
                  (item['maxAmount'] as num?)?.toDouble() ??
                  (item['dailyLimitValue'] as num?)?.toDouble();

              if (limitValue != null) {
                switch (txnType) {
                  case 'ATM':
                    atm.limit.value = limitValue;
                    break;
                  case 'POS':
                    pos.limit.value = limitValue;
                    break;
                  case 'ECOM':
                    ecom.limit.value = limitValue;
                    break;
                  case 'INTERNATIONAL':
                    international.limit.value = limitValue;
                    break;
                  case 'DCC':
                    dcc.limit.value = limitValue;
                    break;
                  case 'CONTACTLESS':
                    contactless.limit.value = limitValue;
                    break;
                }
              }
            }
          }
        }

        update();
      }
    } catch (e) {
      debugPrint("Error fetching card preferences: $e");
    } finally {
      isLoadingPreferences.value = false;
    }
  }

  Map<String, dynamic> buildSetLimitPayload({
    required String txnType,
    required num dailyLimitValue,
  }) {
    int dailyLimitCount = 0;
    num minAmount = 0;
    num maxAmountVal = txnType == 'ATM' ? 10000 : 200000;

    if (preferencesData['limits'] != null &&
        preferencesData['limits'] is List) {
      final limitsList = preferencesData['limits'] as List;
      for (var item in limitsList) {
        if (item is Map &&
            item['txnType']?.toString().toUpperCase() == txnType) {
          if (item['dailyLimitCount'] != null) {
            dailyLimitCount = (item['dailyLimitCount'] as num).toInt();
          }
          if (item['minAmount'] != null) {
            minAmount = item['minAmount'] as num;
          }
          if (item['dailyLimitValue'] != null) {
            maxAmountVal = item['dailyLimitValue'] as num;
          } else if (item['maxAmount'] != null) {
            maxAmountVal = item['maxAmount'] as num;
          }
          break;
        }
      }
    }

    final int roundedVal = dailyLimitValue.round();
    num maxCap = maxAmountVal >= roundedVal ? maxAmountVal : roundedVal;

    return {
      "txnType": txnType == "CONTACTLESS" ? "NFC" : txnType,
      "dailyLimitValue": maxCap.round(),
      "dailyLimitCount": dailyLimitCount,
      "minAmount": minAmount.round(),
      "maxAmount": roundedVal,
    };
  }

  Future<bool> setDailyLimit({
    required String title,
    required num dailyLimitValue,
  }) async {
    final String cleanTitle = title.toUpperCase().replaceAll(' ', '');
    if (isVirtualCard &&
        (cleanTitle == 'ATM' ||
            cleanTitle == 'POS' ||
            cleanTitle == 'CONTACTLESS')) {
      AppSnackbar.info(
        "$title transactions are not supported on Virtual Cards.",
        title: "Virtual Card",
      );
      return false;
    }
    if (!Get.isRegistered<ApiService>()) return false;
    final String txnType = title.toUpperCase().replaceAll(' ', '_');
    final int intLimit = dailyLimitValue.round();
    final payload = buildSetLimitPayload(
      txnType: txnType,
      dailyLimitValue: intLimit,
    );
    print('[API Daily Limit Request Body] $payload');
    developer.log('[API Daily Limit Request Body] $payload');
    debugPrint('[API Daily Limit Request Body] $payload');
    final res = await ApiService.to.setCardDailyLimit(payload);

    if (res != null) {
      if (preferencesData['limits'] != null &&
          preferencesData['limits'] is List) {
        final limitsList = preferencesData['limits'] as List;
        for (var item in limitsList) {
          if (item is Map &&
              item['txnType']?.toString().toUpperCase() == txnType) {
            item['maxAmount'] = intLimit;
            item['dailyLimitValue'] = intLimit;
            break;
          }
        }
      }
      AppSnackbar.success(
        "Daily limit for $title updated to ₹$intLimit",
        title: "Success",
        position: SnackPosition.TOP,
      );
      return true;
    } else {
      AppSnackbar.error(
        "Failed to update daily limit for $title",
        title: "Error",
        position: SnackPosition.TOP,
      );
      return false;
    }
  }

  void toggleCardStatus() {
    if (isCardPermanentlyBlocked.value) return;
    showFreezeCardBottomSheet();
  }

  void _updateStoredCards({
    required String kitNumber,
    required bool isBlocked,
    required bool isPermanentlyBlocked,
    required String status,
  }) {
    final box = GetStorage();
    final storedCards = box.read('user_cards');
    if (storedCards is List) {
      final updatedList = storedCards.map((c) {
        if (c is Map &&
            (c['kitNumber']?.toString() == kitNumber ||
                c['id']?.toString() == kitNumber ||
                c['last4']?.toString() == cardData['last4']?.toString())) {
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

    box.write('is_blocked', isBlocked);
    box.write('is_card_blocked', isBlocked);
    if (isPermanentlyBlocked) {
      box.write('is_permanently_blocked', true);
      box.write('is_card_permanently_blocked', true);
    }
    if (Get.isRegistered<DashboardscreenController>()) {
      Get.find<DashboardscreenController>().checkCardBlockedStatus();
    }

    if (Get.isRegistered<WalletCardController>()) {
      Get.find<WalletCardController>().syncCardStatus(
        kitNumber: kitNumber,
        isBlocked: isBlocked,
        isPermanentlyBlocked: isPermanentlyBlocked,
        status: status,
      );
      Get.find<WalletCardController>().fetchCardsFromApi();
    } else if (Get.isRegistered<ApiService>()) {
      ApiService.to.fetchUserCards();
    }
  }

  String _getKitNumber() {
    String kit =
        cardData['kitNumber']?.toString() ?? cardData['id']?.toString() ?? '';
    if (kit.isEmpty || kit == '1' || kit == '2') {
      final storedCards = GetStorage().read('user_cards');
      if (storedCards is List && storedCards.isNotEmpty) {
        final first = storedCards.first;
        if (first is Map && first['kitNumber'] != null) {
          kit = first['kitNumber'].toString();
        }
      }
    }
    if (kit.isEmpty || kit == '1' || kit == '2') {
      kit = GetStorage().read('kitNumber')?.toString() ?? '1000000000000001';
    }
    return kit;
  }

  void showFreezeCardBottomSheet() {
    if (isCardPermanentlyBlocked.value) {
      AppSnackbar.error(
        "This card is permanently blocked and cannot be frozen or unfreezed.",
        title: "Card Blocked",
      );
      return;
    }
    final bool isCurrentlyBlocked = isCardBlocked.value;

    if (!isCurrentlyBlocked) {
      // FREEZE CARD: User MUST provide reason
      showCardActionWithReasonBottomSheet(
        isPermanent: false,
        onConfirm: (reason) async {
          final kitNumber = _getKitNumber();

          if (Get.isRegistered<ApiService>()) {
            final res = await ApiService.to.manageCardLock(
              kitNumber: kitNumber,
              action: "LOCK",
              reason: reason,
            );
            if (res != null) {
              final String status =
                  res['status']?.toString().toUpperCase() ?? '';
              final String resAction =
                  res['action']?.toString().toUpperCase() ?? '';
              final bool isNowLocked =
                  (status == 'LOCKED' ||
                      status == 'BLOCKED' ||
                      resAction == 'LOCK' ||
                      resAction == 'PERMANENT_BLOCK') ||
                  (status.isEmpty && resAction.isEmpty);

              isCardBlocked.value = isNowLocked;
              cardData['isBlocked'] = isNowLocked;
              cardData['status'] = isNowLocked ? 'LOCKED' : 'ALLOCATED';
              update();

              _updateStoredCards(
                kitNumber: kitNumber,
                isBlocked: isNowLocked,
                isPermanentlyBlocked: false,
                status: isNowLocked ? 'LOCKED' : 'ALLOCATED',
              );

              AppSnackbar.success(
                "Card Freezed Successfully",
                title: "Success",
                position: SnackPosition.TOP,
              );
            } else {
              AppSnackbar.error(
                "Failed to freeze card. Please try again.",
                title: "Error",
                position: SnackPosition.TOP,
              );
            }
            return;
          }

          isCardBlocked.value = true;
          cardData['isBlocked'] = true;
          cardData['status'] = 'LOCKED';
          update();

          _updateStoredCards(
            kitNumber: kitNumber,
            isBlocked: true,
            isPermanentlyBlocked: false,
            status: 'LOCKED',
          );

          AppSnackbar.success(
            "Card Freezed",
            title: "Success",
            position: SnackPosition.TOP,
          );
        },
      );
      return;
    }

    // UNFREEZE CARD: Standard unfreeze confirmation
    showConfirmationBottomSheet(
      title: "Unfreeze your card?",
      subtitle: "Your card will be active for all transactions again.",
      icon: Icons.lock_open,
      iconColor: primaryRed,
      iconBorderColor: primaryYellow,
      actionText: "Unfreeze card",
      actionButtonColor: Colors.black,
      actionTextColor: Colors.white,
      cardSubtext: "Ready To Unfreeze",
      onConfirm: () async {
        final kitNumber = _getKitNumber();

        if (Get.isRegistered<ApiService>()) {
          final res = await ApiService.to.manageCardLock(
            kitNumber: kitNumber,
            action: "UNLOCK",
            reason: "Card unfreeze requested by user",
          );
          if (res != null) {
            isCardBlocked.value = false;
            cardData['isBlocked'] = false;
            cardData['status'] = 'ALLOCATED';
            update();

            _updateStoredCards(
              kitNumber: kitNumber,
              isBlocked: false,
              isPermanentlyBlocked: false,
              status: 'ALLOCATED',
            );

            AppSnackbar.success(
              "Card Unfreezed Successfully",
              title: "Success",
              position: SnackPosition.TOP,
            );
          } else {
            AppSnackbar.error(
              "Failed to unfreeze card. Please try again.",
              title: "Error",
              position: SnackPosition.TOP,
            );
          }
          return;
        }

        isCardBlocked.value = false;
        cardData['isBlocked'] = false;
        cardData['status'] = 'ALLOCATED';
        update();

        _updateStoredCards(
          kitNumber: kitNumber,
          isBlocked: false,
          isPermanentlyBlocked: false,
          status: 'ALLOCATED',
        );

        AppSnackbar.success(
          "Card Unfreezed",
          title: "Success",
          position: SnackPosition.TOP,
        );
      },
    );
  }

  void showPermanentBlockBottomSheet() {
    if (isCardPermanentlyBlocked.value) {
      AppSnackbar.error(
        "This card is already permanently blocked.",
        title: "Card Blocked",
      );
      return;
    }

    // PERMANENT BLOCK: User MUST provide reason
    showCardActionWithReasonBottomSheet(
      isPermanent: true,
      onConfirm: (reason) async {
        final kitNumber = _getKitNumber();
        if (Get.isRegistered<ApiService>()) {
          final res = await ApiService.to.manageCardLock(
            kitNumber: kitNumber,
            action: "PERMANENT_BLOCK",
            reason: reason,
          );
          if (res != null) {
            isCardPermanentlyBlocked.value = true;
            isCardBlocked.value = false;
            cardData['isBlocked'] = false;
            cardData['isPermanentlyBlocked'] = true;
            cardData['status'] = 'BLOCKED';
            update();

            _updateStoredCards(
              kitNumber: kitNumber,
              isBlocked: false,
              isPermanentlyBlocked: true,
              status: 'BLOCKED',
            );

            AppSnackbar.success(
              "Card Permanently Blocked",
              title: "Success",
              position: SnackPosition.TOP,
            );
          } else {
            AppSnackbar.error(
              "Failed to block card. Please try again.",
              title: "Error",
              position: SnackPosition.TOP,
            );
          }
          return;
        }

        isCardPermanentlyBlocked.value = true;
        isCardBlocked.value = false;
        cardData['isBlocked'] = false;
        cardData['isPermanentlyBlocked'] = true;
        cardData['status'] = 'BLOCKED';
        update();

        _updateStoredCards(
          kitNumber: kitNumber,
          isBlocked: false,
          isPermanentlyBlocked: true,
          status: 'BLOCKED',
        );
        AppSnackbar.success(
          "Card Permanently Blocked",
          title: "Success",
          position: SnackPosition.TOP,
        );
      },
    );
  }

  void confirmToggleFeature(
    String title,
    FeatureControl control,
    bool newValue,
  ) {
    if (isCardPermanentlyBlocked.value) return;

    final upperTitle = title.toUpperCase().replaceAll(' ', '');
    if (isVirtualCard &&
        (upperTitle == 'ATM' ||
            upperTitle == 'POS' ||
            upperTitle == 'CONTACTLESS')) {
      control.enabled.value = false;
      update();
      AppSnackbar.info(
        "$title transactions are not supported on Virtual Cards. Order a Physical Card to use ATM, POS, and Contactless payments.",
        title: "Virtual Card",
      );
      return;
    }

    final String actionText = newValue ? "Enable" : "Disable";
    final bool previousState = control.enabled.value;

    showConfirmationBottomSheet(
      title: "$actionText $title transactions?",
      subtitle: newValue
          ? "Are you sure you want to enable $title transactions for this card?"
          : "Are you sure you want to disable $title transactions for this card?",
      icon: newValue ? Icons.check_circle_outline : Icons.block_outlined,
      iconColor: newValue ? primaryYellow : primaryRed,
      iconBorderColor: newValue ? primaryYellow : primaryRed,
      actionText: "$actionText $title",
      actionButtonColor: Colors.black,
      actionTextColor: Colors.white,
      cardSubtext: "$title Status Change",
      onConfirm: () async {
        control.enabled.value = newValue;
        update();

        if (Get.isRegistered<ApiService>()) {
          final String featureKey = title.toLowerCase().replaceAll(' ', '');
          final payload = {featureKey: newValue};
          print('[API Toggle Feature Request Body] $payload');
          developer.log('[API Toggle Feature Request Body] $payload');
          debugPrint('[API Toggle Feature Request Body] $payload');
          final res = await ApiService.to.setCardDailyLimit(payload);

          if (res != null) {
            AppSnackbar.success(
              "$title transactions ${newValue ? 'enabled' : 'disabled'} successfully",
              title: "Success",
              position: SnackPosition.TOP,
            );
          } else {
            control.enabled.value = previousState;
            update();
            AppSnackbar.error(
              "Failed to ${newValue ? 'enable' : 'disable'} $title transactions. Please try again.",
              title: "Error",
              position: SnackPosition.TOP,
            );
          }
        } else {
          AppSnackbar.success(
            "$title transactions ${newValue ? 'enabled' : 'disabled'} successfully",
            title: "Success",
            position: SnackPosition.TOP,
          );
        }
      },
    );
  }

  final Map<String, double> dragInitialLimits = {};

  void onLimitSliderStart(String title, double value) {
    dragInitialLimits[title] = value.roundToDouble();
  }

  void onLimitSliderEnd(
    String title,
    FeatureControl control,
    double newLimitValue,
  ) {
    final double initialVal =
        dragInitialLimits.remove(title) ?? control.limit.value.roundToDouble();
    confirmSetDailyLimit(
      title: title,
      control: control,
      initialLimitValue: initialVal,
      newLimitValue: newLimitValue.roundToDouble(),
    );
  }

  void confirmSetDailyLimit({
    required String title,
    required FeatureControl control,
    required double initialLimitValue,
    required double newLimitValue,
  }) {
    if (isCardPermanentlyBlocked.value) {
      control.limit.value = initialLimitValue.roundToDouble();
      return;
    }

    final int oldVal = initialLimitValue.round();
    final int newVal = newLimitValue.round();

    if (oldVal == newVal) {
      control.limit.value = newVal.toDouble();
      return;
    }

    bool isConfirmed = false;

    showConfirmationBottomSheet(
      title: "Update $title Limit?",
      subtitle:
          "Are you sure you want to change the daily limit for $title transactions from ₹$oldVal to ₹$newVal?",
      icon: Icons.tune_rounded,
      iconColor: primaryYellow,
      iconBorderColor: primaryYellow,
      actionText: "Update Limit",
      actionButtonColor: Colors.black,
      actionTextColor: Colors.white,
      cardSubtext: "$title Daily Limit Update",
      onConfirm: () async {
        isConfirmed = true;
        final success = await setDailyLimit(
          title: title,
          dailyLimitValue: newVal,
        );
        if (!success) {
          control.limit.value = initialLimitValue.roundToDouble();
        } else {
          control.limit.value = newVal.toDouble();
          update();
        }
      },
      onCancel: () {
        if (!isConfirmed) {
          control.limit.value = initialLimitValue.roundToDouble();
        }
      },
    );
  }

  void showEditLimitDialog({
    required String title,
    required FeatureControl control,
    required double maxLimit,
  }) {
    if (isCardPermanentlyBlocked.value) return;

    final int maxAllowed = maxLimit.round();
    final int initialVal = control.limit.value.round().clamp(0, maxAllowed);
    final textController = TextEditingController(
      text: initialVal > 0 ? initialVal.toString() : '',
    );
    final RxString errorMessage = ''.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Set $title Daily Limit",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Enter daily limit (₹0 to ₹$maxAllowed)",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      textController.text = maxAllowed.toString();
                      textController.selection = TextSelection.fromPosition(
                        TextPosition(offset: textController.text.length),
                      );
                      errorMessage.value = '';
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: lightprimaryred,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: primaryYellow, width: 1),
                      ),
                      child: const Text(
                        "SET MAX",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (newValue.text.isEmpty) {
                      errorMessage.value = '';
                      return newValue;
                    }
                    final val = int.tryParse(newValue.text);
                    if (val == null) return oldValue;
                    if (val > maxAllowed) {
                      errorMessage.value =
                          "Cannot exceed maximum limit of ₹$maxAllowed";
                      return oldValue;
                    }
                    errorMessage.value = '';
                    return newValue;
                  }),
                ],
                onChanged: (text) {
                  if (text.isEmpty) {
                    errorMessage.value = '';
                    return;
                  }
                  final val = int.tryParse(text);
                  if (val != null && val > maxAllowed) {
                    errorMessage.value =
                        "Cannot exceed maximum limit of ₹$maxAllowed";
                  } else {
                    errorMessage.value = '';
                  }
                },
                autofocus: true,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  prefixText: "₹ ",
                  prefixStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  hintText: "Enter amount",
                  hintStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey.shade400,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryRed, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              Obx(() {
                if (errorMessage.value.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      errorMessage.value,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final text = textController.text.trim();
                        final val = int.tryParse(text);
                        if (val == null) {
                          errorMessage.value = "Please enter a valid amount";
                          return;
                        }
                        if (val < 0 || val > maxAllowed) {
                          errorMessage.value =
                              "Amount must be between ₹0 and ₹$maxAllowed";
                          return;
                        }
                        Get.back();
                        final initialLimit = control.limit.value;
                        control.limit.value = val.toDouble();
                        confirmSetDailyLimit(
                          title: title,
                          control: control,
                          initialLimitValue: initialLimit,
                          newLimitValue: val.toDouble(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Update",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> showResetPinDialog() async {
    if (!Get.isRegistered<ApiService>()) {
      AppSnackbar.error("API Service unavailable");
      return;
    }

    // Show loading dialog
    Get.dialog(
      Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: primaryRed,
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Initializing Reset PIN...",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    final res = await ApiService.to.fetchCardWidgetSession(
      widgetType: "SET_PIN",
      callbackUrl: "transwallet://reset-pin/return",
    );

    // Dismiss loading dialog if open
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    final String? widgetUrl =
        // "https://devtc.transcorpint.com/widget/new-set-pin-for-m2p.html";
        res?['result']?.toString() ?? res?['widgetUrl']?.toString();

    if (widgetUrl == null || widgetUrl.isEmpty) {
      AppSnackbar.error("Unable to load Reset PIN session. Please try again.");
      return;
    }

    // Open Reset PIN WebView Modal Screen
    Get.to(
      () => ResetPinWebViewSheet(widgetUrl: widgetUrl, cardData: cardData),
      fullscreenDialog: true,
      transition: Transition.downToUp,
      duration: const Duration(milliseconds: 280),
    );
  }

  void showCardActionWithReasonBottomSheet({
    required bool isPermanent,
    required Function(String reason) onConfirm,
    VoidCallback? onCancel,
  }) {
    final String cardNum = cardData['fullNumber'] ?? "**** **** **** ****";
    final String last4 = cardNum.length >= 4
        ? cardNum.substring(cardNum.length - 4)
        : "****";

    final List<String> reasons = isPermanent
        ? [
            "Card lost or stolen",
            "Fraudulent / Unauthorized activity",
            "Card damaged or broken",
            "Card retained by ATM",
            "Closing this card / account",
            "Other reason",
          ]
        : [
            "Temporarily not using card",
            "Misplaced my card",
            "Suspected fraudulent activity",
            "Security precaution while traveling",
            "Other reason",
          ];

    String? selectedReason;
    final customReasonController = TextEditingController();
    String? validationError;

    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

    Get.bottomSheet(
      StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final mediaQuery = MediaQuery.of(sheetContext);
          final keyboardHeight = mediaQuery.viewInsets.bottom;
          final screenHeight = mediaQuery.size.height;

          return Container(
            constraints: BoxConstraints(
              maxHeight: keyboardHeight > 0
                  ? (screenHeight - mediaQuery.padding.top - 20)
                  : (screenHeight * 0.88),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              keyboardHeight + (keyboardHeight > 0 ? 12 : 16),
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              bottom: keyboardHeight == 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Scrollable Content
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header icon
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPermanent
                                  ? const Color(0xFFFEF2F2)
                                  : const Color(0xFFEFF6FF),
                              border: Border.all(
                                color: isPermanent
                                    ? const Color(0xFFFECACA)
                                    : const Color(0xFFBFDBFE),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              isPermanent
                                  ? Icons.credit_card_off_outlined
                                  : Icons.lock_outline_rounded,
                              color: isPermanent
                                  ? Colors.red
                                  : const Color(0xFF2563EB),
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Title
                          Text(
                            isPermanent
                                ? "Block your card?"
                                : "Freeze your card?",
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Subtitle
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              isPermanent
                                  ? "This action is permanent and cannot be undone. Please specify a reason for blocking your card."
                                  : "Your card will be temporarily blocked. Please specify a reason for freezing your card.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Card Preview Snippet
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isPermanent
                                        ? const Color(0xFFFEF2F2)
                                        : lightprimaryred,
                                    border: Border.all(
                                      color: isPermanent
                                          ? const Color(0xFFFECACA)
                                          : primaryYellow,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.credit_card,
                                    color: isPermanent
                                        ? Colors.red
                                        : Colors.black,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Card Ending **** **** **** $last4",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isPermanent
                                            ? "Ready To Block Permanently"
                                            : "Ready To Freeze",
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Reason selection label
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Reason for ${isPermanent ? 'blocking' : 'freezing'} *",
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              Text(
                                "Required",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isPermanent
                                      ? Colors.red
                                      : const Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Reasons Radio Items
                          ...reasons.map((r) {
                            final isSelected = selectedReason == r;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: InkWell(
                                onTap: () {
                                  setModalState(() {
                                    selectedReason = r;
                                    validationError = null;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isPermanent
                                              ? const Color(0xFFFEF2F2)
                                              : const Color(0xFFEFF6FF))
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? (isPermanent
                                                ? Colors.red.shade400
                                                : const Color(0xFF2563EB))
                                          : Colors.grey.shade200,
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        color: isSelected
                                            ? (isPermanent
                                                  ? Colors.red.shade700
                                                  : const Color(0xFF2563EB))
                                            : Colors.grey.shade400,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          r,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? const Color(0xFF0F172A)
                                                : const Color(0xFF334155),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),

                          // Custom reason input if "Other reason" is selected
                          if (selectedReason == "Other reason") ...[
                            const SizedBox(height: 4),
                            TextField(
                              controller: customReasonController,
                              maxLines: 2,
                              maxLength: 120,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: isPermanent
                                    ? "Please explain why you are blocking this card..."
                                    : "Please explain why you are freezing this card...",
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                                contentPadding: const EdgeInsets.all(10),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                counterText: "",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isPermanent
                                        ? Colors.red.shade600
                                        : const Color(0xFF2563EB),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onChanged: (_) {
                                if (validationError != null) {
                                  setModalState(() => validationError = null);
                                }
                              },
                            ),
                          ],

                          // Validation Error Banner
                          if (validationError != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFECACA),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Color(0xFFDC2626),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      validationError!,
                                      style: const TextStyle(
                                        color: Color(0xFFDC2626),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Buttons Row (Pinned at bottom)
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
                            if (onCancel != null) onCancel();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            String finalReason = '';
                            if (selectedReason == null ||
                                selectedReason!.isEmpty) {
                              setModalState(() {
                                validationError =
                                    "Please select a reason to proceed.";
                              });
                              return;
                            }
                            if (selectedReason == "Other reason") {
                              final custom = customReasonController.text.trim();
                              if (custom.isEmpty) {
                                setModalState(() {
                                  validationError =
                                      "Please enter your reason in the text box.";
                                });
                                return;
                              }
                              finalReason = custom;
                            } else {
                              finalReason = selectedReason!;
                            }

                            if (Navigator.of(sheetContext).canPop()) {
                              Navigator.of(sheetContext).pop();
                            } else {
                              Get.back();
                            }
                            onConfirm(finalReason);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPermanent
                                ? Colors.red.shade700
                                : Colors.black,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            isPermanent ? "Block Card" : "Freeze Card",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
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

  void showConfirmationBottomSheet({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBorderColor,
    required String actionText,
    required Color actionButtonColor,
    required Color actionTextColor,
    required String cardSubtext,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
  }) {
    final String cardNum = cardData['fullNumber'] ?? "**** **** **** ****";
    final String last4 = cardNum.length >= 4
        ? cardNum.substring(cardNum.length - 4)
        : "****";

    bool confirmedHandled = false;

    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

    Get.bottomSheet(
      Builder(
        builder: (sheetContext) {
          return Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: iconBorderColor, width: 1.5),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: lightprimaryred,
                            border: Border.all(
                              color: primaryYellow,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.credit_card,
                            color: Colors.black,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Card Ending **** **** **** $last4",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cardSubtext,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
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
                            if (onCancel != null) onCancel();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            confirmedHandled = true;
                            if (Navigator.of(sheetContext).canPop()) {
                              Navigator.of(sheetContext).pop();
                            } else {
                              Get.back();
                            }
                            onConfirm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: actionButtonColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            actionText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: actionTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).then((_) {
      if (!confirmedHandled && onCancel != null) {
        onCancel();
      }
    });
  }

  Widget cardPreview() {
    final box = GetStorage();
    return Obx(() {
      final String cardNum =
          cardData['fullNumber'] ??
          (cardData['maskedNumber'] != null &&
                  cardData['maskedNumber'].toString().isNotEmpty
              ? cardData['maskedNumber'].toString()
              : (cardData['last4'] != null &&
                        cardData['last4'].toString().isNotEmpty
                    ? '•••• •••• •••• ${cardData['last4']}'
                    : '•••• •••• •••• ••••'));
      final String rawHolder =
          (box.read('name') ??
                  box.read('userName') ??
                  cardData['holder'] ??
                  cardData['name'] ??
                  '')
              .toString()
              .trim();
      final String holder = rawHolder.isNotEmpty
          ? rawHolder.toUpperCase()
          : "CARDHOLDER";
      final String rawExp =
          cardData['expiryMmYy']?.toString() ??
          cardData['expiry']?.toString() ??
          "";
      String exp = "--/--";
      final digits = rawExp.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length == 4) {
        exp = '${digits.substring(0, 2)}/${digits.substring(2, 4)}';
      } else if (rawExp.contains('/')) {
        exp = rawExp;
      } else if (rawExp.isNotEmpty) {
        exp = rawExp;
      }
      final String cvvVal = cardData['cvv']?.toString() ?? "•••";
      final String? brand =
          cardData['brand']?.toString() ?? cardData['network']?.toString();
      final String bgImg = PremiumVisaCard.resolveCardBgImage(
        brand: brand,
        bgImage: cardData['bgImage']?.toString(),
      );
      final bool useBlackLg = cardData['useBlackLogos'] ?? false;
      final Color shadowCol =
          (cardData['colors'] != null &&
              (cardData['colors'] as List).length > 1)
          ? (cardData['colors'] as List)[1]
          : primaryRed;

      return Center(
        child: PremiumVisaCard(
          cardNumber: cardNum,
          cardHolder: holder,
          expiryDate: exp,
          cvv: cvvVal,
          isBlocked: isCardBlocked.value,
          isPermanentlyBlocked: isCardPermanentlyBlocked.value,
          onTap: isCardBlocked.value && !isCardPermanentlyBlocked.value
              ? () => toggleCardStatus()
              : null,
          bgImage: bgImg,
          brand: brand,
          useBlackLogos: useBlackLg,
          shadowColor: shadowCol,
        ),
      );
    });
  }
}

Widget featureTile(
  String title,
  FeatureControl control,
  String iconData,
  bool showSlider, {
  double maxLimit = 200000,
  bool isLast = false,
  bool? isAvailable,
  String? disabledReason,
}) {
  bool available = isAvailable ?? true;
  if (isAvailable == null && Get.isRegistered<ManagecardController>()) {
    final ctrl = Get.find<ManagecardController>();
    final upper = title.toUpperCase().replaceAll(' ', '');
    if (ctrl.isVirtualCard &&
        (upper == 'ATM' || upper == 'POS' || upper == 'CONTACTLESS')) {
      available = false;
    }
  }

  // If this feature is disabled / unavailable (e.g. ATM, POS, or Contactless on virtual cards),
  // return the static disabled UI directly without an Obx wrapper.
  if (!available) {
    return _buildFeatureTileContent(
      title: title,
      control: control,
      iconData: iconData,
      showSlider: showSlider,
      maxLimit: maxLimit,
      isLast: isLast,
      available: false,
      disabledReason: disabledReason,
    );
  }

  // When available, reactively observe control.enabled and control.limit
  return Obx(
    () => _buildFeatureTileContent(
      title: title,
      control: control,
      iconData: iconData,
      showSlider: showSlider,
      maxLimit: maxLimit,
      isLast: isLast,
      available: true,
      disabledReason: disabledReason,
    ),
  );
}

Widget _buildFeatureTileContent({
  required String title,
  required FeatureControl control,
  required String iconData,
  required bool showSlider,
  required double maxLimit,
  required bool isLast,
  required bool available,
  String? disabledReason,
}) {
  final bool isControlEnabled = available && control.enabled.value;
  final double currentLimit = available ? control.limit.value : 0.0;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: isLast
          ? null
          : Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.5)),
    ),
    child: Column(
      children: [
        InkWell(
          onTap: !available
              ? () {
                  AppSnackbar.info(
                    "$title transactions are not supported on Virtual Cards. Order a Physical Card to use ATM, POS, and Contactless payments.",
                    title: "Physical Card Required",
                    position: SnackPosition.TOP,
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: available ? lightprimaryred : Colors.grey.shade100,
                  border: Border.all(
                    color: available ? primaryYellow : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: SvgPicture.asset(
                  iconData.toString(),
                  colorFilter: available
                      ? null
                      : const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: available ? Colors.black : Colors.grey.shade600,
                      ),
                    ),
                    if (!available) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          disabledReason ?? "Physical card only",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PremiumToggle(
                value: isControlEnabled,
                isEnabled: available,
                onChanged: (value) {
                  if (!available) {
                    AppSnackbar.info(
                      "$title transactions are not supported on Virtual Cards. Order a Physical Card to use ATM, POS, and Contactless payments.",
                      title: "Physical Card Required",
                      position: SnackPosition.TOP,
                    );
                    return;
                  }
                  if (Get.isRegistered<ManagecardController>()) {
                    Get.find<ManagecardController>().confirmToggleFeature(
                      title,
                      control,
                      value,
                    );
                  } else {
                    control.enabled.value = value;
                  }
                },
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: (available && showSlider && isControlEnabled)
              ? Column(
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Daily limit",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (Get.isRegistered<ManagecardController>()) {
                              Get.find<ManagecardController>()
                                  .showEditLimitDialog(
                                    title: title,
                                    control: control,
                                    maxLimit: maxLimit,
                                  );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "₹${currentLimit.round()}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit_outlined,
                                  size: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    PremiumSlider(
                      value: currentLimit.roundToDouble(),
                      min: 0,
                      max: maxLimit,
                      onChanged: (value) {
                        control.limit.value = value.roundToDouble();
                      },
                      onChangeStart: (value) {
                        if (Get.isRegistered<ManagecardController>()) {
                          Get.find<ManagecardController>().onLimitSliderStart(
                            title,
                            control.limit.value.roundToDouble(),
                          );
                        }
                      },
                      onChangeEnd: (value) {
                        if (Get.isRegistered<ManagecardController>()) {
                          Get.find<ManagecardController>().onLimitSliderEnd(
                            title,
                            control,
                            control.limit.value.roundToDouble(),
                          );
                        }
                      },
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );
}

class PremiumToggle extends StatelessWidget {
  final bool value;
  final bool isEnabled;
  final Function(bool) onChanged;

  const PremiumToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = isEnabled && value;
    return GestureDetector(
      onTap: () {
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 55,
        height: 31,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: active
              ? const LinearGradient(colors: [primaryRed, primaryRed])
              : null,
          color: active
              ? null
              : (isEnabled ? Colors.grey.shade300 : Colors.grey.shade200),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),
          alignment: active ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnabled ? Colors.white : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final Function(double) onChanged;
  final Function(double)? onChangeStart;
  final Function(double)? onChangeEnd;

  const PremiumSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0,
    this.max = 500,
  });

  @override
  Widget build(BuildContext context) {
    final double safeVal = value.roundToDouble().clamp(min, max);
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,

            activeTrackColor: primaryRed,
            inactiveTrackColor: primaryRed.withOpacity(0.18),
            thumbColor: Colors.white,
            overlayColor: primaryRed.withOpacity(.15),

            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
          ),

          child: Slider(
            value: safeVal,

            min: min,
            max: max,

            onChanged: (val) {
              onChanged(val.roundToDouble());
            },
            onChangeStart: (val) {
              onChangeStart?.call(val.roundToDouble());
            },
            onChangeEnd: (val) {
              onChangeEnd?.call(val.roundToDouble());
            },
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "₹ ${min.toInt()}",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              Text(
                "Max ₹ ${max.toInt()}",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ResetPinWebViewSheet extends StatefulWidget {
  final String widgetUrl;
  final Map<String, dynamic> cardData;

  const ResetPinWebViewSheet({
    super.key,
    required this.widgetUrl,
    required this.cardData,
  });

  @override
  State<ResetPinWebViewSheet> createState() => _ResetPinWebViewSheetState();
}

class _ResetPinWebViewSheetState extends State<ResetPinWebViewSheet> {
  bool _isLoading = true;
  double _progress = 0.0;
  bool _isFinished = false;
  InAppWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.startExternalFlow(ExternalFlowType.customWebview);
    }
  }

  @override
  void dispose() {
    _isFinished = true;
    try {
      _webViewController?.stopLoading();
      _webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri("about:blank")),
      );
      _webViewController = null;
    } catch (_) {}
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.finishExternalFlow(ExternalFlowType.customWebview);
    }
    super.dispose();
  }

  void _handleCallback(String url) {
    if (_isFinished) return;
    developer.log("Reset PIN Callback intercepted URL: $url");
    final lower = url.toLowerCase();
    final uri = Uri.tryParse(url);

    final bool isDeepLink =
        lower.startsWith("transwallet://") ||
        lower.startsWith("ppiapp://") ||
        lower.startsWith("yappay://") ||
        lower.contains("card-widget/return") ||
        lower.contains("reset-pin") ||
        lower.contains("card-pin") ||
        lower.contains("set-pin") ||
        lower.contains("transcorpint.com/ppi-card") ||
        lower.contains("transcorpint.com") ||
        lower.contains("ppi-card") ||
        lower.contains("success") ||
        lower.contains("return") ||
        lower.contains("done") ||
        lower.contains("close") ||
        lower.contains("cancel") ||
        lower.contains("failed");

    if (isDeepLink) {
      _isFinished = true;
      try {
        _webViewController?.stopLoading();
      } catch (_) {}

      // Defer route popping so shouldOverrideUrlLoading can return CANCEL to the native engine first
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        } else {
          Get.back();
        }
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
        if (Get.isBottomSheetOpen ?? false) {
          Get.back();
        }

        if (Get.isRegistered<DeepLinkService>()) {
          final deepLinkUrl = lower.startsWith("transwallet://")
              ? url
              : (lower.contains("failed") || lower.contains("error")
                  ? "transwallet://reset-pin/failed"
                  : (lower.contains("cancel") || lower.contains("close")
                      ? "transwallet://reset-pin/cancel"
                      : "transwallet://reset-pin/success"));
          DeepLinkService.to.handleDeepLink(deepLinkUrl);
          return;
        }

        if (Get.currentRoute != '/managecard') {
          Get.toNamed('/managecard', arguments: widget.cardData);
        }

        final queryParams = uri?.queryParameters ?? {};
        final status =
            queryParams['status']?.toLowerCase() ??
            queryParams['result']?.toLowerCase() ??
            queryParams['event']?.toLowerCase() ??
            queryParams['action']?.toLowerCase() ??
            queryParams['code']?.toLowerCase();
        final msg =
            queryParams['message'] ??
            queryParams['msg'] ??
            queryParams['desc'] ??
            queryParams['description'];

        if (lower.contains("failed") ||
            lower.contains("error") ||
            status == "failed" ||
            status == "error" ||
            status == "rejected") {
          AppSnackbar.error(msg ?? "Failed to reset Card PIN. Please try again.");
        } else if (lower.contains("cancel") ||
            lower.contains("close") ||
            status == "cancel" ||
            status == "close") {
          AppSnackbar.info(msg ?? "Reset PIN was cancelled.");
        } else {
          AppSnackbar.success(msg ?? "Card PIN has been updated successfully!");
          if (Get.isRegistered<ManagecardController>()) {
            Get.find<ManagecardController>().fetchCardDetails();
            Get.find<ManagecardController>().fetchCardPreferences();
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.lock_reset_rounded,
                        color: primaryRed,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Reset Card PIN",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      } else {
                        Get.back();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                backgroundColor: Colors.grey.shade200,
                color: primaryRed,
                minHeight: 3,
              ),

            // WebView
            Expanded(
              child: Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(widget.widgetUrl),
                    ),
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<VerticalDragGestureRecognizer>(
                        () => VerticalDragGestureRecognizer(),
                      ),
                      Factory<HorizontalDragGestureRecognizer>(
                        () => HorizontalDragGestureRecognizer(),
                      ),
                      Factory<ScaleGestureRecognizer>(
                        () => ScaleGestureRecognizer(),
                      ),
                    },
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      domStorageEnabled: true,
                      useShouldOverrideUrlLoading: true,
                      useOnRenderProcessGone: true,
                      transparentBackground: false,
                      allowFileAccessFromFileURLs: true,
                      allowUniversalAccessFromFileURLs: true,
                      mediaPlaybackRequiresUserGesture: false,
                      supportZoom: false,
                      builtInZoomControls: false,
                      displayZoomControls: false,
                      verticalScrollBarEnabled: true,
                      horizontalScrollBarEnabled: false,
                      overScrollMode: OverScrollMode.ALWAYS,
                      clearCache: false,
                    ),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                      controller.addJavaScriptHandler(
                        handlerName: 'WidgetCallback',
                        callback: (args) {
                          developer.log("JS WidgetCallback received: $args");
                          _handleCallback("transwallet://reset-pin/success");
                        },
                      );
                      controller.addJavaScriptHandler(
                        handlerName: 'CardWidget',
                        callback: (args) {
                          developer.log("JS CardWidget received: $args");
                          _handleCallback("transwallet://reset-pin/success");
                        },
                      );
                      controller.addJavaScriptHandler(
                        handlerName: 'CardPinCallback',
                        callback: (args) {
                          developer.log("JS CardPinCallback received: $args");
                          _handleCallback("transwallet://reset-pin/success");
                        },
                      );
                    },
                    onRenderProcessGone: (controller, detail) async {
                      developer.log(
                        "Reset PIN WebView onRenderProcessGone: didCrash=${detail.didCrash}",
                      );
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
                    onLoadStart: (controller, url) {
                      if (url != null) {
                        final urlStr = url.toString();
                        final lower = urlStr.toLowerCase();
                        if (lower.startsWith("transwallet://") ||
                            lower.startsWith("ppiapp://") ||
                            lower.startsWith("yappay://") ||
                            lower.contains("card-widget/return") ||
                            lower.contains("reset-pin") ||
                            lower.contains("card-pin") ||
                            lower.contains("set-pin") ||
                            lower.contains("transcorpint.com/ppi-card") ||
                            lower.contains("transcorpint.com") ||
                            lower.contains("ppi-card")) {
                          controller.stopLoading();
                          _handleCallback(urlStr);
                          return;
                        }
                      }
                      if (mounted) {
                        setState(() => _isLoading = true);
                      }
                    },
                    onProgressChanged: (controller, progress) {
                      if (!mounted) return;
                      setState(() {
                        _progress = progress / 100;
                        if (progress == 100) _isLoading = false;
                      });
                    },
                    onLoadStop: (controller, url) async {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                      if (url != null) {
                        final urlStr = url.toString();
                        final lower = urlStr.toLowerCase();
                        if (lower.startsWith("transwallet://") ||
                            lower.startsWith("ppiapp://") ||
                            lower.startsWith("yappay://") ||
                            lower.contains("card-widget/return") ||
                            lower.contains("reset-pin") ||
                            lower.contains("card-pin") ||
                            lower.contains("set-pin") ||
                            lower.contains("transcorpint.com/ppi-card") ||
                            lower.contains("transcorpint.com") ||
                            lower.contains("ppi-card")) {
                          _handleCallback(urlStr);
                          return;
                        }
                        _handleCallback(urlStr);
                      }
                      try {
                        await controller.evaluateJavascript(
                          source: """
                      (function() {
                        var viewport = document.querySelector('meta[name="viewport"]');
                        if (!viewport) {
                          viewport = document.createElement('meta');
                          viewport.name = 'viewport';
                          viewport.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                          document.getElementsByTagName('head')[0].appendChild(viewport);
                        }
                        document.body.style.paddingBottom = '24px';
                        document.documentElement.style.paddingBottom = '24px';

                        // Listen to postMessage callbacks from card widget
                        window.addEventListener('message', function(event) {
                          if (event && event.data) {
                            var dataStr = typeof event.data === 'string' ? event.data : JSON.stringify(event.data);
                            if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                              window.flutter_inappwebview.callHandler('CardPinCallback', dataStr);
                            }
                            if (dataStr.indexOf('success') !== -1 || dataStr.indexOf('200') !== -1 || dataStr.indexOf('ppi-card') !== -1) {
                              window.location.href = 'transwallet://reset-pin/success';
                            }
                          }
                        });

                        // Auto scroll focused input into viewport center smoothly when keyboard opens
                        window.addEventListener('focusin', function(e) {
                          if (e.target && (e.target.tagName === 'INPUT' || e.target.tagName === 'SELECT' || e.target.tagName === 'TEXTAREA')) {
                            setTimeout(function() {
                              e.target.scrollIntoView({ behavior: 'smooth', block: 'center' });
                            }, 250);
                          }
                        });
                      })();
                    """,
                        );
                      } catch (e) {
                        developer.log(
                          "Error evaluating JS for bottom padding: $e",
                        );
                      }
                    },
                    onReceivedError: (controller, request, error) {
                      final urlString = request.url.toString();
                      developer.log(
                        "Reset PIN WebView Error: $urlString -> ${error.description}",
                      );
                      final lower = urlString.toLowerCase();
                      if (lower.startsWith("transwallet://") ||
                          lower.startsWith("ppiapp://") ||
                          lower.startsWith("yappay://") ||
                          lower.contains("card-widget/return") ||
                          lower.contains("reset-pin") ||
                          lower.contains("card-pin") ||
                          lower.contains("set-pin") ||
                          lower.contains("transcorpint.com/ppi-card") ||
                          lower.contains("transcorpint.com") ||
                          lower.contains("ppi-card")) {
                        _handleCallback(urlString);
                        return;
                      }
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    },
                    onLoadError: (controller, url, code, message) {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                      developer.log("WebView error: $code, $message");
                    },
                    shouldOverrideUrlLoading:
                        (controller, navigationAction) async {
                          final uri = navigationAction.request.url;
                          if (uri != null) {
                            final urlStr = uri.toString();
                            final lower = urlStr.toLowerCase();
                            if (lower.startsWith("transwallet://") ||
                                lower.startsWith("ppiapp://") ||
                                lower.startsWith("yappay://") ||
                                lower.contains("card-widget/return") ||
                                lower.contains("reset-pin") ||
                                lower.contains("card-pin") ||
                                lower.contains("set-pin") ||
                                lower.contains("transcorpint.com/ppi-card") ||
                                lower.contains("transcorpint.com") ||
                                lower.contains("ppi-card")) {
                              _handleCallback(urlStr);
                              return NavigationActionPolicy.CANCEL;
                            }
                          }
                          return NavigationActionPolicy.ALLOW;
                        },
                  ),

                  if (_isLoading && _progress < 0.1)
                    Container(
                      color: Colors.white,
                      child: const Center(
                        child: CircularProgressIndicator(color: primaryRed),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
