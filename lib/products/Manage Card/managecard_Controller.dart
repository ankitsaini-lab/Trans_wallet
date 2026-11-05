import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/premium_visa_card.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/products/Dashboard screen/controllers/wallet_card_controller.dart';

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

  final atm = FeatureControl(enabled: true, limit: 100);
  final pos = FeatureControl();
  final ecom = FeatureControl();
  final international = FeatureControl();
  final dcc = FeatureControl();
  final contactless = FeatureControl();

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      cardData.addAll(Get.arguments as Map<String, dynamic>);
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
    update();

    if (!isCardPermanentlyBlocked.value) {
      fetchCardPreferences();
    }
  }

  Future<void> fetchCardPreferences() async {
    if (!Get.isRegistered<ApiService>()) return;
    isLoadingPreferences.value = true;
    try {
      final res = await ApiService.to.fetchCardPreferences();
      if (res != null) {
        preferencesData.assignAll(res);
        if (res.containsKey('atm')) {
          atm.enabled.value = res['atm'] == true;
        }
        if (res.containsKey('pos')) {
          pos.enabled.value = res['pos'] == true;
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
          contactless.enabled.value = res['contactless'] == true;
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

    num maxCap = maxAmountVal >= dailyLimitValue
        ? maxAmountVal
        : dailyLimitValue;

    return {
      "txnType": txnType,
      "dailyLimitValue": maxCap,
      "dailyLimitCount": dailyLimitCount,
      "minAmount": minAmount,
      "maxAmount": dailyLimitValue,
    };
  }

  Future<bool> setDailyLimit({
    required String title,
    required num dailyLimitValue,
  }) async {
    if (!Get.isRegistered<ApiService>()) return false;
    final String txnType = title.toUpperCase().replaceAll(' ', '_');
    final payload = buildSetLimitPayload(
      txnType: txnType,
      dailyLimitValue: dailyLimitValue,
    );
    print('[API Daily Limit Request Body] $payload');
    developer.log('[API Daily Limit Request Body] $payload');
    debugPrint('[API Daily Limit Request Body] $payload');
    final res = await ApiService.to.setCardDailyLimit(payload);

    if (res != null) {
      AppSnackbar.success(
        "Daily limit for $title updated to ₹${dailyLimitValue.toInt()}",
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

    showConfirmationBottomSheet(
      title: isCurrentlyBlocked ? "Unfreeze your card?" : "Freeze your card?",
      subtitle: isCurrentlyBlocked
          ? "Your card will be active for all transactions again."
          : "Your card will be temporarily blocked for all transactions. You can unfreeze it anytime.",
      icon: isCurrentlyBlocked ? Icons.lock_open : Icons.lock_outline,
      iconColor: primaryRed,
      iconBorderColor: primaryYellow,
      actionText: isCurrentlyBlocked ? "Unfreeze card" : "Freeze card",
      actionButtonColor: Colors.black,
      actionTextColor: Colors.white,
      cardSubtext: isCurrentlyBlocked ? "Ready To Unfreeze" : "Ready To Freeze",
      onConfirm: () async {
        final kitNumber = _getKitNumber();
        final action = isCurrentlyBlocked ? "UNLOCK" : "LOCK";

        if (Get.isRegistered<ApiService>()) {
          final res = await ApiService.to.manageCardLock(
            kitNumber: kitNumber,
            action: action,
            reason: isCurrentlyBlocked
                ? "Card unfreeze requested by user"
                : "Card freeze requested by user",
          );
          if (res != null) {
            final String status = res['status']?.toString().toUpperCase() ?? '';
            final String resAction =
                res['action']?.toString().toUpperCase() ?? '';
            final bool isNowLocked =
                (status == 'LOCKED' ||
                    status == 'BLOCKED' ||
                    resAction == 'LOCK' ||
                    resAction == 'PERMANENT_BLOCK') ||
                (action == 'LOCK' && status.isEmpty && resAction.isEmpty);

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
              isNowLocked
                  ? "Card Freezed Successfully"
                  : "Card Unfreezed Successfully",
              title: "Success",
              position: SnackPosition.TOP,
            );
          } else {
            AppSnackbar.error(
              isCurrentlyBlocked
                  ? "Failed to unfreeze card. Please try again."
                  : "Failed to freeze card. Please try again.",
              title: "Error",
              position: SnackPosition.TOP,
            );
          }
          return;
        }

        final bool isNowLocked = !isCurrentlyBlocked;
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
          isCurrentlyBlocked ? "Card Unfreezed" : "Card Freezed",
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
    showConfirmationBottomSheet(
      title: "Block your card?",
      subtitle:
          "This action is permanent and cannot be undone. You will need to request a new card.",
      icon: Icons.credit_card_off_outlined,
      iconColor: Colors.red,
      iconBorderColor: Colors.red.shade200,
      actionText: "Block Card",
      actionButtonColor: Colors.black,
      actionTextColor: Colors.white,
      cardSubtext: "Ready To Block",
      onConfirm: () async {
        final kitNumber = _getKitNumber();
        if (Get.isRegistered<ApiService>()) {
          final res = await ApiService.to.manageCardLock(
            kitNumber: kitNumber,
            action: "PERMANENT_BLOCK",
            reason: "Permanent card block requested by user",
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
    dragInitialLimits[title] = value;
  }

  void onLimitSliderEnd(
    String title,
    FeatureControl control,
    double newLimitValue,
  ) {
    final double initialVal =
        dragInitialLimits.remove(title) ?? control.limit.value;
    confirmSetDailyLimit(
      title: title,
      control: control,
      initialLimitValue: initialVal,
      newLimitValue: newLimitValue,
    );
  }

  void confirmSetDailyLimit({
    required String title,
    required FeatureControl control,
    required double initialLimitValue,
    required double newLimitValue,
  }) {
    if (isCardPermanentlyBlocked.value) {
      control.limit.value = initialLimitValue;
      return;
    }

    final int oldVal = initialLimitValue.round();
    final int newVal = newLimitValue.round();

    if (oldVal == newVal) {
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
          control.limit.value = initialLimitValue;
        }
      },
      onCancel: () {
        if (!isConfirmed) {
          control.limit.value = initialLimitValue;
        }
      },
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
      callbackUrl: "ppiapp://card-widget/return",
    );

    // Dismiss loading dialog if open
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    final String?
    widgetUrl = // "https://devtc.transcorpint.com/widget/new-set-pin-for-m2p.html";
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
}) {
  return Obx(
    () => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1.5),
              ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: lightprimaryred,
                  border: Border.all(color: primaryYellow, width: 1.5),
                ),
                child: SvgPicture.asset(iconData.toString()),
                // Icon(iconData, color: Colors.black, size: 18),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              PremiumToggle(
                value: control.enabled.value,
                onChanged: (value) {
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: (showSlider && control.enabled.value)
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "₹${control.limit.value.toInt()}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      PremiumSlider(
                        value: control.limit.value,
                        min: 0,
                        max: maxLimit,
                        onChanged: (value) {
                          control.limit.value = value;
                        },
                        onChangeStart: (value) {
                          if (Get.isRegistered<ManagecardController>()) {
                            Get.find<ManagecardController>().onLimitSliderStart(
                              title,
                              value,
                            );
                          }
                        },
                        onChangeEnd: (value) {
                          if (Get.isRegistered<ManagecardController>()) {
                            Get.find<ManagecardController>().onLimitSliderEnd(
                              title,
                              control,
                              value,
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
    ),
  );
}

class PremiumToggle extends StatelessWidget {
  final bool value;
  final Function(bool) onChanged;

  const PremiumToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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

          gradient: value
              ? const LinearGradient(colors: [primaryRed, primaryRed])
              : null,

          color: value ? null : Colors.grey.shade300,
        ),

        child: AnimatedAlign(
          duration: const Duration(milliseconds: 250),

          alignment: value ? Alignment.centerRight : Alignment.centerLeft,

          child: Container(
            width: 25,
            height: 25,

            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
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
            value: value.clamp(min, max),

            min: min,
            max: max,

            onChanged: onChanged,
            onChangeStart: onChangeStart,
            onChangeEnd: onChangeEnd,
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

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.startExternalFlow(ExternalFlowType.customWebview);
    }
  }

  @override
  void dispose() {
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.finishExternalFlow(ExternalFlowType.customWebview);
    }
    super.dispose();
  }

  void _handleCallback(String url) {
    if (_isFinished) return;
    developer.log("Reset PIN Callback intercepted URL: $url");
    final lower = url.toLowerCase();
    if (lower.contains("ppiapp://card-widget/return") ||
        lower.contains("yappay://") ||
        lower.contains("success") ||
        lower.contains("return") ||
        lower.contains("done") ||
        lower.contains("close") ||
        lower.contains("cancel") ||
        lower.contains("failed")) {
      _isFinished = true;
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      if (lower.contains("failed") || lower.contains("cancel")) {
        AppSnackbar.info("Reset PIN cancelled or uncompleted.");
      } else {
        AppSnackbar.success("PIN reset action processed successfully!");
      }
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
                      controller.addJavaScriptHandler(
                        handlerName: 'WidgetCallback',
                        callback: (args) {
                          developer.log("JS WidgetCallback received: $args");
                          _handleCallback("success");
                        },
                      );
                      controller.addJavaScriptHandler(
                        handlerName: 'CardWidget',
                        callback: (args) {
                          developer.log("JS CardWidget received: $args");
                          _handleCallback("success");
                        },
                      );
                    },
                    onLoadStart: (controller, url) {
                      setState(() => _isLoading = true);
                      if (url != null) {
                        _handleCallback(url.toString());
                      }
                    },
                    onProgressChanged: (controller, progress) {
                      setState(() {
                        _progress = progress / 100;
                        if (progress == 100) _isLoading = false;
                      });
                    },
                    onLoadStop: (controller, url) async {
                      setState(() => _isLoading = false);
                      if (url != null) {
                        _handleCallback(url.toString());
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
                    onLoadError: (controller, url, code, message) {
                      setState(() => _isLoading = false);
                      developer.log("WebView error: $code, $message");
                    },
                    shouldOverrideUrlLoading:
                        (controller, navigationAction) async {
                          final uri = navigationAction.request.url;
                          if (uri != null) {
                            final urlStr = uri.toString();
                            final lower = urlStr.toLowerCase();
                            if (lower.startsWith("ppiapp://") ||
                                lower.startsWith("yappay://") ||
                                lower.contains("card-widget/return")) {
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
