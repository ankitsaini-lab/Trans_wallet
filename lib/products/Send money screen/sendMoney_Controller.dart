import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Dashboard screen/dashboardscreen_Controller.dart';
import 'package:transwallet/products/Dashboard screen/controllers/wallet_card_controller.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

class SendmoneyController extends GetxController {
  static const String recentRecipientsKey = 'recent_w2w_recipients';

  var searchQuery = ''.obs;
  var contactSearchQuery = ''.obs;
  var mobileNumber = ''.obs;
  var isP2PTransfer = true.obs;
  var isLoading = false.obs;
  var checkingPhone = ''.obs;
  var isLoadingContacts = false.obs;
  var hasContactPermission = true.obs;

  final searchController = TextEditingController();
  final contactSearchController = TextEditingController();
  final mobileController = TextEditingController();

  // Dynamic device contacts and recent recipients
  final RxList<Map<String, String>> phoneContacts = <Map<String, String>>[].obs;
  final RxList<Map<String, String>> recentRecipients =
      <Map<String, String>>[].obs;
  final RxBool isFullKyc = false.obs;
  final RxBool isCardFrozen = false.obs;
  final RxBool isCardPermanentlyBlocked = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkKycStatus();
    checkCardStatus();
    loadRecentRecipients();
    fetchPhoneContacts();
  }

  void checkCardStatus() {
    final box = GetStorage();

    // 1. Direct explicit flags in storage
    if (box.read('is_permanently_blocked') == true ||
        box.read('is_card_permanently_blocked') == true) {
      isCardPermanentlyBlocked.value = true;
    } else {
      isCardPermanentlyBlocked.value = false;
    }

    bool frozen = false;
    if (box.read('is_blocked') == true ||
        box.read('is_card_blocked') == true ||
        box.read('is_frozen') == true) {
      frozen = true;
    }

    // 2. Dashboard controller status
    if (Get.isRegistered<DashboardscreenController>()) {
      final dashCtrl = Get.find<DashboardscreenController>();
      if (dashCtrl.isCardFrozen) frozen = true;
      if (dashCtrl.isCardPermanentlyBlocked) {
        isCardPermanentlyBlocked.value = true;
      }
    } else if (Get.isRegistered<WalletCardController>()) {
      final wcc = Get.find<WalletCardController>();
      if (wcc.cards.any((c) => c.isBlocked && !c.isPermanentlyBlocked)) {
        frozen = true;
      }
      if (wcc.cards.any((c) => c.isPermanentlyBlocked)) {
        isCardPermanentlyBlocked.value = true;
      }
    }

    // 3. Check user_cards
    final storedCards = box.read('user_cards');
    if (storedCards is List && storedCards.isNotEmpty) {
      for (var c in storedCards) {
        if (c is Map) {
          final rawStatus = c['status']?.toString().toUpperCase() ?? '';
          final bool isPerm = rawStatus == 'BLOCKED' ||
              rawStatus == 'PERMANENT_BLOCK' ||
              rawStatus == 'PERMANENTLY_BLOCKED' ||
              c['isPermanentlyBlocked'] == true;
          if (isPerm) {
            isCardPermanentlyBlocked.value = true;
          } else if (rawStatus == 'LOCKED' ||
              rawStatus == 'FROZEN' ||
              c['isBlocked'] == true) {
            frozen = true;
          }
        }
      }
    }

    isCardFrozen.value = frozen;
  }

  void checkKycStatus() {
    final box = GetStorage();
    final rawStatus = box.read('kyc_status')?.toString().toLowerCase() ?? '';
    final currentLevel =
        box.read('kyc_current_level')?.toString().toUpperCase() ?? '';
    final underReview =
        rawStatus == 'under_review' ||
        rawStatus == 'in_review' ||
        rawStatus == 'review';
    final completed =
        !underReview &&
        (box.read('full_kyc_completed') == true ||
            box.read('is_full_kyc') == true ||
            box.read('is_kyc_completed') == true ||
            currentLevel == 'FULL' ||
            rawStatus == 'verified' ||
            rawStatus == 'completed' ||
            rawStatus == 'approved');
    isFullKyc.value = completed;
  }

  /// Clean phone number to 10 digits
  static String cleanPhoneNumber(String raw) {
    String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) {
      return digits.substring(digits.length - 10);
    }
    return digits;
  }

  /// Extract initials for contact avatar
  static String getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'C';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      final first = parts[0][0];
      final second = parts[1][0];
      return '$first$second'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  /// Load persisted recent recipients from GetStorage
  void loadRecentRecipients() {
    try {
      final raw = box.read(recentRecipientsKey);
      if (raw != null && raw is List) {
        final list = raw
            .map((e) => Map<String, String>.from(e as Map))
            .toList();
        recentRecipients.assignAll(list);
      } else {
        recentRecipients.clear();
      }
    } catch (e) {
      developer.log('Error loading recent recipients: $e');
      recentRecipients.clear();
    }
  }

  /// Save recipient to recent recipients in GetStorage
  void saveRecentRecipient(Map<String, String> user) {
    try {
      final raw = box.read(recentRecipientsKey);
      List<Map<String, String>> list = [];
      if (raw != null && raw is List) {
        list = raw.map((e) => Map<String, String>.from(e as Map)).toList();
      }
      final cleaned = cleanPhoneNumber(user['phone'] ?? '');
      list.removeWhere(
        (item) => cleanPhoneNumber(item['phone'] ?? '') == cleaned,
      );
      list.insert(0, Map<String, String>.from(user));
      if (list.length > 20) {
        list = list.sublist(0, 20);
      }
      box.write(recentRecipientsKey, list);
      recentRecipients.assignAll(list);
    } catch (e) {
      developer.log('Error saving recent recipient: $e');
    }
  }

  /// Delete a single recipient from recent list
  void removeRecentRecipient(String phone) {
    try {
      final cleaned = cleanPhoneNumber(phone);
      recentRecipients.removeWhere(
        (item) => cleanPhoneNumber(item['phone'] ?? '') == cleaned,
      );
      box.write(recentRecipientsKey, recentRecipients.toList());
    } catch (e) {
      developer.log('Error removing recent recipient: $e');
    }
  }

  /// Clear all recent recipients
  void clearRecentRecipients() {
    try {
      box.remove(recentRecipientsKey);
      recentRecipients.clear();
    } catch (e) {
      developer.log('Error clearing recent recipients: $e');
    }
  }

  /// Fetch phone contacts from device
  Future<void> fetchPhoneContacts({bool forceRefresh = false}) async {
    if (phoneContacts.isNotEmpty && !forceRefresh) return;

    try {
      isLoadingContacts.value = true;

      // Check / request permission using flutter_contacts 2.x
      final status = await FlutterContacts.permissions.request(
        PermissionType.read,
      );
      if (status != PermissionStatus.granted) {
        hasContactPermission.value = false;
        isLoadingContacts.value = false;
        return;
      }

      hasContactPermission.value = true;
      final contacts = await FlutterContacts.getAll(
        properties: {ContactProperty.phone},
      );

      final Set<String> seenNumbers = {};
      final List<Map<String, String>> loaded = [];

      for (final contact in contacts) {
        final name = (contact.displayName ?? '').trim();
        for (final phone in contact.phones) {
          final raw = phone.number.trim();
          final cleaned = cleanPhoneNumber(raw);
          if (cleaned.length < 10) continue; // skip non-phone/short numbers

          if (seenNumbers.contains(cleaned)) continue;
          seenNumbers.add(cleaned);

          final displayName = name.isNotEmpty ? name : "Contact $cleaned";
          loaded.add({
            "name": displayName,
            "phone": "+91 $cleaned",
            "rawPhone": cleaned,
            "avatar": getInitials(displayName),
          });
        }
      }

      // Sort contacts alphabetically
      loaded.sort(
        (a, b) => (a['name'] ?? '').toLowerCase().compareTo(
          (b['name'] ?? '').toLowerCase(),
        ),
      );

      phoneContacts.assignAll(loaded);
    } catch (e) {
      developer.log("Error loading device contacts: $e");
    } finally {
      isLoadingContacts.value = false;
    }
  }

  /// Open native system contact picker directly
  Future<void> pickFromNativeContacts() async {
    try {
      final contact = await FlutterContacts.native.showPicker(
        properties: {ContactProperty.phone},
      );
      if (contact != null) {
        String? selectedPhone;
        if (contact.phones.isNotEmpty) {
          selectedPhone = contact.phones.first.number;
        } else if (contact.id != null) {
          final full = await FlutterContacts.get(
            contact.id!,
            properties: {ContactProperty.phone},
          );
          if (full != null && full.phones.isNotEmpty) {
            selectedPhone = full.phones.first.number;
          }
        }

        if (selectedPhone != null && selectedPhone.isNotEmpty) {
          final cleaned = cleanPhoneNumber(selectedPhone);
          if (cleaned.length >= 10) {
            final rawName = (contact.displayName ?? '').trim();
            final name = rawName.isNotEmpty ? rawName : "User ($cleaned)";
            mobileController.text = cleaned;
            mobileNumber.value = cleaned;

            final user = {
              "name": name,
              "phone": "+91 $cleaned",
              "avatar": getInitials(name),
            };
            selectRecipient(user);
          } else {
            AppSnackbar.error(
              "Selected contact does not have a valid 10-digit mobile number",
            );
          }
        } else {
          AppSnackbar.error("Selected contact does not have a phone number");
        }
      }
    } catch (e) {
      developer.log("Error in pickFromNativeContacts: $e");
      AppSnackbar.error("Unable to open native contact picker");
    }
  }

  /// Open app settings if contact permission was permanently denied
  Future<void> openSettingsForPermission() async {
    await FlutterContacts.permissions.openSettings();
  }

  /// Filtered phone contacts for phonebook modal
  List<Map<String, String>> get filteredPhoneContacts {
    final query = contactSearchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      return phoneContacts;
    }
    return phoneContacts.where((contact) {
      final name = (contact['name'] ?? '').toLowerCase();
      final phone = (contact['phone'] ?? '').replaceAll(' ', '');
      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  /// Filtered recipients / contacts for the main screen
  List<Map<String, String>> get filteredRecipients {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      return recentRecipients;
    }

    final List<Map<String, String>> results = [];
    final Set<String> seen = {};

    // 1. Search in recent recipients first
    for (final user in recentRecipients) {
      final name = (user['name'] ?? '').toLowerCase();
      final phone = (user['phone'] ?? '').replaceAll(' ', '');
      if (name.contains(query) || phone.contains(query)) {
        final c = cleanPhoneNumber(phone);
        seen.add(c);
        results.add(user);
      }
    }

    // 2. Also search in loaded phone contacts for instant contact suggestions
    for (final contact in phoneContacts) {
      final name = (contact['name'] ?? '').toLowerCase();
      final phone = (contact['phone'] ?? '').replaceAll(' ', '');
      final c = cleanPhoneNumber(phone);
      if ((name.contains(query) || phone.contains(query)) &&
          !seen.contains(c)) {
        seen.add(c);
        results.add(contact);
      }
    }

    return results;
  }

  Future<void> verifyAndProceed(Map<String, String> user) async {
    checkCardStatus();
    if (isCardFrozen.value) {
      AppSnackbar.error(
        "Your card is currently frozen. Please unfreeze your card to send money.",
        title: "Card Frozen",
      );
      return;
    }
    if (isCardPermanentlyBlocked.value) {
      AppSnackbar.error(
        "Your card is permanently blocked. Send Money is disabled.",
        title: "Card Blocked",
      );
      return;
    }

    checkKycStatus();
    if (!isFullKyc.value) {
      AppSnackbar.error(
        "Full KYC is required to send money. Please complete your Full KYC.",
      );
      return;
    }

    final rawPhone = user['phone'] ?? '';
    final cleanedPhone = rawPhone.replaceAll(RegExp(r'\D'), '');

    final phoneToVerify = cleanedPhone.length > 10
        ? cleanedPhone.substring(cleanedPhone.length - 10)
        : cleanedPhone;

    if (phoneToVerify.length < 10) {
      AppSnackbar.error("Please enter a valid 10-digit mobile number");
      return;
    }

    // Check if sending to own mobile number
    final myMobile = (box.read('mobileNumber') ?? box.read('phone') ?? '')
        .toString()
        .replaceAll(RegExp(r'\D'), '');
    final my10 = myMobile.length > 10
        ? myMobile.substring(myMobile.length - 10)
        : myMobile;
    if (my10.isNotEmpty && my10 == phoneToVerify) {
      AppSnackbar.error("You cannot send money to your own mobile number");
      return;
    }

    try {
      isLoading.value = true;
      checkingPhone.value = phoneToVerify;
      final res = await ApiService.to.checkC2CRecipient(
        toMobileNumber: phoneToVerify,
      );

      if (res != null) {
        // 1. Verify existence
        final bool exists = res['exists'] == true;
        if (!exists) {
          final errorMsg =
              res['message']?.toString() ??
              "This mobile number is not registered on TransWallet.";
          AppSnackbar.error(errorMsg);
          return;
        }

        // 2. Verify capability to receive transfer (canReceiveW2W / canReceiveC2C)
        final bool? canReceive = res['canReceiveW2W'] ?? res['canReceiveC2C'];
        if (canReceive == false) {
          final String reasonCode = res['reasonCode']?.toString() ?? '';
          final String errorMsg =
              res['message']?.toString() ??
              (reasonCode == 'FULL_KYC_REQUIRED'
                  ? "Recipient must complete full KYC before wallet transfer"
                  : "Recipient cannot receive transfers at this time.");
          AppSnackbar.error(errorMsg);
          return;
        }

        // 3. Recipient verified successfully: extract registered details
        final String firstName = (res['firstName'] ?? '').toString().trim();
        final updatedUser = Map<String, String>.from(user);
        if (firstName.isNotEmpty &&
            (updatedUser['name'] == null ||
                updatedUser['name']!.isEmpty ||
                updatedUser['name']!.startsWith('User ('))) {
          updatedUser['name'] = firstName;
          updatedUser['avatar'] = getInitials(firstName);
        }

        // Attach KYC and status metadata for the transaction flow
        if (res['kycLevel'] != null) {
          updatedUser['kycLevel'] = res['kycLevel'].toString();
        }
        if (res['kycStatus'] != null) {
          updatedUser['kycStatus'] = res['kycStatus'].toString();
        }
        if (res['isFullKyc'] != null) {
          updatedUser['isFullKyc'] = res['isFullKyc'] == true
              ? 'true'
              : 'false';
        }

        // Normalize phone number to +91 format
        updatedUser['phone'] = "+91 $phoneToVerify";

        // Save to recent recipients list
        saveRecentRecipient(updatedUser);

        Get.toNamed("/sendmoneyprocess", arguments: updatedUser);
      } else {
        AppSnackbar.error("Failed to verify recipient. Please try again.");
      }
    } catch (e) {
      developer.log("Error in verifyAndProceed: $e");
      AppSnackbar.error("An error occurred while checking recipient status.");
    } finally {
      isLoading.value = false;
      checkingPhone.value = '';
    }
  }

  void selectRecipient(Map<String, String> user) {
    if (isLoading.value) return;
    verifyAndProceed(user);
  }

  void proceedWithManualNumber() {
    if (isLoading.value) return;
    final phone = mobileController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty || phone.length < 10) {
      AppSnackbar.error("Please enter a valid 10-digit mobile number");
      return;
    }

    final String name = "User ($phone)";
    final user = {
      "name": name,
      "phone": "+91 $phone",
      "avatar": getInitials(name),
    };
    verifyAndProceed(user);
  }

  @override
  void onClose() {
    searchController.dispose();
    contactSearchController.dispose();
    mobileController.dispose();
    super.onClose();
  }
}
