import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Wallet%20Screen/Add%20Money/addmoney_View.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/utilities/getStorage.dart';

class WalletscreenController extends GetxController {
  var expandedIndex = (0).obs;

  var isBalanceRevealed = false.obs;
  Timer? _autoHideTimer;

  Future<void> revealBalance() async {
    await fetchBalanceFromApi();
    isBalanceRevealed.value = true;
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 5), () {
      isBalanceRevealed.value = false;
    });
  }

  void hideBalance() {
    _autoHideTimer?.cancel();
    isBalanceRevealed.value = false;
  }

  @override
  void onClose() {
    _autoHideTimer?.cancel();
    super.onClose();
  }

  var wallets = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialWallets();
  }

  void _loadInitialWallets() {
    final double storedTotalBalance = ((box.read('balance') ?? 0) as num)
        .toDouble();
    final storedProducts = box.read('wallet_products');

    if (storedProducts is List && storedProducts.isNotEmpty) {
      _applyProductsList(storedProducts, storedTotalBalance);
    } else {
      _applyDefaultWallets(storedTotalBalance, 0, 0, 0, 0);
    }
  }

  Future<void> fetchBalanceFromApi() async {
    if (!Get.isRegistered<ApiService>()) return;
    try {
      final res = await ApiService.to.fetchWalletBalance();
      if (res != null) {
        final double totalBal = (res['balance'] is num)
            ? (res['balance'] as num).toDouble()
            : double.tryParse(res['balance']?.toString() ?? '0') ?? 0.0;
        final List products = (res['products'] is List)
            ? (res['products'] as List)
            : [];
        _applyProductsList(products, totalBal);
      }
    } catch (e) {
      log('Error fetching wallet balance in WalletscreenController: $e');
    }
  }

  void _applyProductsList(List products, double totalBal) {
    Map<String, double> prodBalances = {};
    for (var p in products) {
      if (p is Map) {
        final id = p['productId']?.toString().toUpperCase() ?? '';
        final bal = (p['balance'] is num)
            ? (p['balance'] as num).toDouble()
            : double.tryParse(p['balance']?.toString() ?? '0') ?? 0.0;
        prodBalances[id] = bal;
      }
    }

    final double generalBal = prodBalances['GENERAL'] ?? totalBal;
    final double foodBal = prodBalances['FOOD'] ?? 0.0;
    final double fuelBal = prodBalances['FUEL'] ?? 0.0;
    final double medicalBal = prodBalances['MEDICAL'] ?? 0.0;
    final double transitBal =
        prodBalances['FF01'] ??
        prodBalances['FFFE'] ??
        prodBalances['9100'] ??
        0.0;

    _applyDefaultWallets(generalBal, foodBal, fuelBal, medicalBal, transitBal);
  }

  void _applyDefaultWallets(
    double generalBal,
    double foodBal,
    double fuelBal,
    double medicalBal,
    double transitBal,
  ) {
    wallets.value = [
      {
        "title": "General Wallet",
        "subtitle": "Wallet ID : GW-1025",
        "balance": generalBal,
        "icon": "assets/generalwallet.png",
        "detailsicon": "assets/generalwalletdetails.png",
        "bgimage": "assets/bgwallettansaction.png",
        "bgColor": const Color(0xFFFFF5F5),
        "borderColor": const Color(0xFFFFE5E5),
        "buttonColor": const Color(0xFFFFCCCC),
      },
      {
        "title": "Meal Wallet",
        "subtitle": "For meals & foods",
        "balance": foodBal,
        "icon": "assets/mealwallet.png",
        "detailsicon": "assets/mealwalletdetails.png",
        "bgimage": "assets/mealdetailbg.png",
        "bgColor": const Color(0xFFFFFCE8),
        "borderColor": const Color(0xFFFFF5CC),
        "buttonColor": const Color(0xFFFFEA66),
      },
      {
        "title": "Fuel Wallet",
        "subtitle": "For fuel & mobility",
        "balance": fuelBal,
        "icon": "assets/fuelwallet.png",
        "detailsicon": "assets/fuelwalletdetails.png",
        "bgimage": "assets/fueldetailsBG.png",
        "bgColor": const Color(0xFFF4F8FF),
        "borderColor": const Color(0xFFE5EFFF),
        "buttonColor": const Color(0xFFCCE0FF),
      },
      {
        "title": "Medical Wallet",
        "subtitle": "For healthcare",
        "balance": medicalBal,
        "icon": "assets/medicalwallet.png",
        "detailsicon": "assets/mealwalletdetails.png",
        "bgimage": "assets/medicaldetailsBG.png",
        "bgColor": const Color(0xFFF2FCF5),
        "borderColor": const Color(0xFFE0F5E6),
        "buttonColor": const Color(0xFFB3E6C2),
      },
      {
        "title": "NCMC Wallet",
        "subtitle": "For transit payment",
        "balance": transitBal,
        "icon": "assets/ncmcwallet.png",
        "detailsicon": "assets/NCMCwalletdetails.png",
        "bgimage": "assets/NcmcdetailsBG.png",
        "bgColor": const Color(0xFFF9F5FF),
        "borderColor": const Color(0xFFEFE5FF),
        "buttonColor": const Color(0xFFE0CCFF),
      },
    ];
  }

  Widget walletList() {
    return Obx(
      () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: wallets.length,
        itemBuilder: (context, index) {
          final wallet = wallets[index];
          return walletCard(wallet, index);
        },
      ),
    );
  }

  Widget walletCard(Map wallet, int index) {
    return Obx(() {
      bool isExpanded = expandedIndex.value == index;
      return GestureDetector(
        onTap: () => expandedIndex.value = isExpanded ? -1 : index,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage(wallet["icon"].toString()),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet["title"],
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "Available Balance",
                          style: TextStyle(color: Colors.black54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    isBalanceRevealed.value
                        ? "₹${wallet["balance"]}"
                        : "₹ •••••••",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.black54,
                  ),
                ],
              ),

              if (isExpanded) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    actionButton(
                      "Add Money",
                      onTap: () {
                        Get.bottomSheet(
                          const AddmoneyView(showGeneralWalletOption: true),
                          isScrollControlled: true,
                          isDismissible: false,
                          enableDrag: false,
                          backgroundColor: Colors.transparent,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    actionButton(
                      "Transactions",
                      onTap: () {
                        Get.toNamed(
                          "/walletdetails",
                          arguments: {"data": wallet},
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget actionButton(String text, {VoidCallback? onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFD64550).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD64550).withOpacity(0.2)),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFD64550),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
