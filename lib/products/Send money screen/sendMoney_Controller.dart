import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

class SendmoneyController extends GetxController {
  var searchQuery = ''.obs;
  var mobileNumber = ''.obs;
  var isP2PTransfer = true.obs;
  var isLoading = false.obs;
  var checkingPhone = ''.obs;

  final searchController = TextEditingController();
  final mobileController = TextEditingController();

  final List<Map<String, String>> phonebookContacts = [
    {"name": "Rahul Sharma", "phone": "9876543210", "avatar": "RS"},
    {"name": "Priya Verma", "phone": "9812345678", "avatar": "PV"},
    {"name": "Amit Kumar", "phone": "9765432109", "avatar": "AK"},
    {"name": "Sneha Gupta", "phone": "9654321098", "avatar": "SG"},
    {"name": "Vikram Singh", "phone": "9543210987", "avatar": "VS"},
    {"name": "Neha Kapoor", "phone": "9432109876", "avatar": "NK"},
    {"name": "Siddharth Malhotra", "phone": "9321098765", "avatar": "SM"},
  ];

  final List<Map<String, String>> recentRecipients = [
    {"name": "Ankit Saini", "phone": "+91 9327856473", "avatar": "AS"},
    {"name": "Olivia Taylor", "phone": "+91 9327856474", "avatar": "OT"},
    {"name": "Elaine Covington", "phone": "+91 9327856475", "avatar": "EC"},
    {"name": "Robert Cooper", "phone": "+91 9327856476", "avatar": "RC"},
    {"name": "Austin Cannon", "phone": "+91 9327856477", "avatar": "AC"},
    {"name": "Nadia Page", "phone": "+91 9327856478", "avatar": "NP"},
    {"name": "Maria Charles", "phone": "+91 9327856479", "avatar": "MC"},
  ];

  List<Map<String, String>> get filteredRecipients {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      return recentRecipients;
    }
    return recentRecipients.where((user) {
      final name = user['name']?.toLowerCase() ?? '';
      final phone = user['phone']?.replaceAll(' ', '') ?? '';
      return name.contains(query) || phone.contains(query);
    }).toList();
  }

  Future<void> verifyAndProceed(Map<String, String> user) async {
    final rawPhone = user['phone'] ?? '';
    final cleanedPhone = rawPhone.replaceAll(RegExp(r'\D'), '');

    final phoneToVerify = cleanedPhone.length > 10
        ? cleanedPhone.substring(cleanedPhone.length - 10)
        : cleanedPhone;

    if (phoneToVerify.length < 10) {
      AppSnackbar.error("Please enter a valid 10-digit mobile number");
      return;
    }

    try {
      isLoading.value = true;
      checkingPhone.value = phoneToVerify;
      final res = await ApiService.to.checkW2WRecipient(
        toMobileNumber: phoneToVerify,
      );

      if (res != null) {
        final canReceive = res['canReceiveW2W'] == true;
        final exists = res['exists'] == true;

        if (canReceive) {
          final String firstName = res['firstName'] ?? '';
          final updatedUser = Map<String, String>.from(user);
          if (firstName.isNotEmpty &&
              (updatedUser['name'] == null ||
                  updatedUser['name']!.startsWith('User ('))) {
            updatedUser['name'] = firstName;
          }
          Get.toNamed("/sendmoneyprocess", arguments: updatedUser);
        } else {
          final String msg = res['message'] ??
              (exists
                  ? "Recipient must complete full KYC before wallet transfer."
                  : "Recipient user does not exist or cannot receive W2W transfers.");
          AppSnackbar.error(msg);
        }
      } else {
        AppSnackbar.error("Failed to verify recipient. Please try again.");
      }
    } catch (e) {
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
      "avatar": "W2W",
    };
    verifyAndProceed(user);
  }

  @override
  void onClose() {
    searchController.dispose();
    mobileController.dispose();
    super.onClose();
  }
}
