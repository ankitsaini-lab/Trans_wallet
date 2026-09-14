import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/widgets/premium_visa_card.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

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
      if (cardData['isBlocked'] == true ||
          cardData['status'] == 'LOCKED' ||
          cardData['status'] == 'BLOCKED') {
        isCardBlocked.value = true;
      }
    }
    fetchCardPreferences();
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
    isCardBlocked.toggle();
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
    if (isCardPermanentlyBlocked.value) return;
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
      actionButtonColor: primaryYellow,
      actionTextColor: Colors.black,
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
            cardData['status'] = isNowLocked ? 'LOCKED' : 'UNLOCKED';
            update();

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

        toggleCardStatus();
        AppSnackbar.success(
          isCurrentlyBlocked ? "Card Unfreezed" : "Card Freezed",
          title: "Success",
          position: SnackPosition.TOP,
        );
      },
    );
  }

  void showPermanentBlockBottomSheet() {
    if (isCardPermanentlyBlocked.value) return;
    showConfirmationBottomSheet(
      title: "Block your card?",
      subtitle:
          "This action is permanent and cannot be undone. You will need to request a new card.",
      icon: Icons.credit_card_off_outlined,
      iconColor: Colors.red,
      iconBorderColor: Colors.red.shade200,
      actionText: "Block Card",
      actionButtonColor: Colors.red,
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
            cardData['status'] = 'BLOCKED';
            update();
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
        update();
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
      actionButtonColor: newValue ? primaryYellow : primaryRed,
      actionTextColor: newValue ? Colors.black : Colors.white,
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
      actionButtonColor: primaryYellow,
      actionTextColor: Colors.black,
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

  void showResetPinDialog() {
    final cardDigitsController = TextEditingController();
    final mobileController = TextEditingController();
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();

    final step1FormKey = GlobalKey<FormState>();
    final step2FormKey = GlobalKey<FormState>();

    final RxInt currentStep = 1.obs;

    Get.dialog(
      Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Obx(
          () => Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: currentStep.value == 1
                  ? Form(
                      key: step1FormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 55,
                            width: 55,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryYellow,
                            ),
                            child: const Icon(
                              Icons.credit_card_rounded,
                              size: 24,
                              color: Color(0xFF111111),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            "Verify Card Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: cardDigitsController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: InputDecoration(
                              labelText: "Last 4 Digits of Card",
                              counterText: "",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.length != 4) {
                                return "Enter last 4 digits of your card";
                              }
                              if (val != "4567") {
                                return "Incorrect card digits";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: mobileController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: InputDecoration(
                              labelText: "Registered Mobile Number",
                              counterText: "",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.length != 10) {
                                return "Enter 10-digit mobile number";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: Get.back,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text("Cancel"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (step1FormKey.currentState!.validate()) {
                                      currentStep.value = 2;
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF111111),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    "Continue",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Form(
                      key: step2FormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 55,
                            width: 55,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryYellow,
                            ),
                            child: const Icon(
                              Icons.password_rounded,
                              size: 24,
                              color: Color(0xFF111111),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            "Set New PIN",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: pinController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            maxLength: 4,
                            decoration: InputDecoration(
                              labelText: "New 4-Digit PIN",
                              counterText: "",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.length != 4) {
                                return "Enter a valid 4-digit PIN";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: confirmPinController,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            maxLength: 4,
                            decoration: InputDecoration(
                              labelText: "Confirm New PIN",
                              counterText: "",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (val) {
                              if (val != pinController.text) {
                                return "PINs do not match";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => currentStep.value = 1,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text("Back"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (step2FormKey.currentState!.validate()) {
                                      Get.back();
                                      AppSnackbar.success(
                                        "Card PIN Reset Successfully",
                                        title: "Success",
                                        position: SnackPosition.TOP,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF111111),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    "Reset PIN",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
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
      barrierDismissible: false,
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
    final String cardNum = cardData['fullNumber'] ?? "**** **** **** 7852";
    final String last4 = cardNum.length >= 4
        ? cardNum.substring(cardNum.length - 4)
        : "7852";

    bool confirmedHandled = false;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      border: Border.all(color: primaryYellow, width: 1.5),
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
                      Get.back();
                      if (onCancel != null) onCancel();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
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
                      Get.back();
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      actionText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
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
      final String cardNum = cardData['fullNumber'] ?? "••••••••••••4567";
      final String holder =
          box.read('name') ?? cardData['holder'] ?? "John Doe";
      final String exp = cardData['expiry'] ?? "12/28";
      final String cvvVal = cardData['cvv'] ?? "•••";
      final String bgImg = cardData['bgImage'] ?? 'assets/unioncardblack.webp';
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
  IconData iconData,
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
                child: Icon(iconData, color: Colors.black, size: 18),
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
