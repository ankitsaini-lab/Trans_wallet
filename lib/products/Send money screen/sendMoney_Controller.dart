import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SendmoneyController extends GetxController {
  var isP2PTransfer = true.obs;
  var searchQuery = ''.obs;
  final searchController = TextEditingController();

  final List<Map<String, String>> recentRecipients = [
    {"name": "Ankit Saini", "phone": "+61 9327856473", "avatar": "AS"},
    {"name": "Olivia Taylor", "phone": "+61 9327856474", "avatar": "OT"},
    {"name": "Elaine Covington", "phone": "+61 9327856475", "avatar": "EC"},
    {"name": "Robert Cooper", "phone": "+61 9327856476", "avatar": "RC"},
    {"name": "Austin Cannon", "phone": "+61 9327856477", "avatar": "AC"},
    {"name": "Nadia Page", "phone": "+61 9327856478", "avatar": "NP"},
    {"name": "Maria Charles", "phone": "+61 9327856479", "avatar": "MC"},
  ];

  List<Map<String, String>> get filteredRecipients {
    if (searchQuery.value.isEmpty) {
      return recentRecipients;
    }
    return recentRecipients.where((user) {
      final query = searchQuery.value.toLowerCase();
      return user['name']!.toLowerCase().contains(query) ||
             user['phone']!.contains(query);
    }).toList();
  }

  void switchTab(bool isP2P) {
    isP2PTransfer.value = isP2P;
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
