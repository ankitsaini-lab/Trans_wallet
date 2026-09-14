import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

class ContactSupportScreenController extends GetxController {
  final messageController = TextEditingController();
  
  var selectedCategory = 'KYC Status'.obs;
  var isSubmitting = false.obs;
  var ticketCreated = false.obs;
  var ticketId = ''.obs;

  final List<String> categories = [
    'KYC Status',
    'Card Delivery',
    'Transaction Dispute',
    'Wallet Deposit',
    'Other Issue'
  ];

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }

  void sendTicket() async {
    if (messageController.text.trim().isEmpty) {
      AppSnackbar.warning(
        "Please enter details of your query or issue.",
        title: "Empty Query",
        position: SnackPosition.BOTTOM,
      );
      return;
    }

    isSubmitting.value = true;
    
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final rand = DateTime.now().millisecondsSinceEpoch.toString();
    ticketId.value = "TKT-${rand.substring(rand.length - 6)}";
    
    isSubmitting.value = false;
    ticketCreated.value = true;
  }

  void resetForm() {
    messageController.clear();
    ticketCreated.value = false;
    ticketId.value = '';
  }
}