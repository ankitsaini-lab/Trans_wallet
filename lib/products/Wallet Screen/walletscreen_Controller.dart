import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Wallet%20Screen/Add%20Money/addmoney_View.dart';
import 'package:transwallet/products/Wallet%20Screen/ncmc_topup_view.dart';
import 'package:transwallet/products/Dashboard%20screen/dashboardscreen_Controller.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

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

  void clear() {
    _autoHideTimer?.cancel();
    wallets.clear();
    expandedIndex.value = 0;
    isBalanceRevealed.value = false;
    isLoadingBalance.value = false;
  }

  var wallets = <Map<String, dynamic>>[].obs;

  var isLoadingBalance = false.obs;
  var isToppingUpNcmc = false.obs;

  double get generalWalletBalance {
    for (var w in wallets) {
      if (w["title"].toString().toLowerCase().contains("general")) {
        return (w["balance"] as num?)?.toDouble() ?? 0.0;
      }
    }
    return ((box.read('balance') ?? 0) as num).toDouble();
  }

  double get ncmcWalletBalance {
    for (var w in wallets) {
      if (w["title"].toString().toLowerCase().contains("ncmc wallet")) {
        return (w["balance"] as num?)?.toDouble() ?? 0.0;
      }
    }
    for (var w in wallets) {
      if (w["title"].toString().toLowerCase().contains("ncmc")) {
        return (w["balance"] as num?)?.toDouble() ?? 0.0;
      }
    }
    return ((box.read('transit_balance') ?? 0) as num).toDouble();
  }

  double get ncmcCardBalance {
    for (var w in wallets) {
      if (w["title"].toString().toLowerCase().contains("ncmc card")) {
        return (w["balance"] as num?)?.toDouble() ?? 0.0;
      }
    }
    return ((box.read('transit_balance') ?? 0) as num).toDouble();
  }

  String get ncmcProductId {
    final storedProducts = box.read('wallet_products');
    if (storedProducts is List) {
      for (var p in storedProducts) {
        if (p is Map) {
          final id = p['productId']?.toString().toUpperCase() ?? '';
          if (id == 'FF01' ||
              id == 'FFFE' ||
              id == '9100' ||
              id.contains('NCMC') ||
              id.contains('TRANSIT')) {
            return id;
          }
        }
      }
    }
    return 'FF01';
  }

  void openNcmcTopupScreen() {
    Get.toNamed('/ncmctopup');
  }

  void showNcmcTopupBottomSheet(BuildContext context) {
    openNcmcTopupScreen();
  }

  Future<Map<String, dynamic>?> topupNcmcWallet({
    required double amount,
  }) async {
    if (amount <= 0) {
      AppSnackbar.error(
        "Please enter a valid amount.",
        title: "Invalid Amount",
      );
      return null;
    }
    if (amount > generalWalletBalance) {
      AppSnackbar.error(
        "Amount exceeds available General Wallet balance (₹${generalWalletBalance.toStringAsFixed(2)}).",
        title: "Insufficient Balance",
      );
      return null;
    }

    isToppingUpNcmc.value = true;
    try {
      if (Get.isRegistered<ApiService>()) {
        final res = await ApiService.to.topupNcmcWallet(
          amount: amount,
          fromProductId: 'GENERAL',
          productId: ncmcProductId,
        );
        final bool success =
            res?['apiSuccess'] == true || res?['success'] == true;
        if (success) {
          fetchBalanceFromApi();
          return res;
        } else {
          final msg =
              res?['message'] ??
              res?['error'] ??
              "Failed to top up NCMC Wallet. Please try again.";
          AppSnackbar.error(msg.toString(), title: "Top-up Failed");
          return null;
        }
      } else {
        return {
          'success': true,
          'data': {'status': 'PAYMENT_SUCCESS'},
        };
      }
    } catch (e) {
      log('Error topping up NCMC: $e');
      AppSnackbar.error("Error topping up NCMC wallet: $e", title: "Error");
      return null;
    } finally {
      isToppingUpNcmc.value = false;
    }
  }

  bool get _canFetchBalance {
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
    _loadInitialWallets();
    if (_canFetchBalance) {
      fetchBalanceFromApi();
    }
  }

  void _loadInitialWallets() {
    final double storedTotalBalance = ((box.read('balance') ?? 0) as num)
        .toDouble();
    final storedProducts = box.read('wallet_products');

    if (storedProducts is List && storedProducts.isNotEmpty) {
      _applyProductsList(storedProducts, storedTotalBalance);
    } else {
      final double storedTransitBalance =
          ((box.read('transit_balance') ?? 0) as num).toDouble();
      _applyDefaultWallets(
        storedTotalBalance,
        0,
        0,
        0,
        storedTransitBalance,
        storedTransitBalance,
      );
    }
  }

  Future<void> fetchBalanceFromApi() async {
    if (!_canFetchBalance || !Get.isRegistered<ApiService>()) return;
    isLoadingBalance.value = true;
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
    } finally {
      isLoadingBalance.value = false;
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
    final double ncmcWalletBal = prodBalances['FF01'] ?? 0.0;
    final double ncmcCardBal =
        prodBalances['FFFE'] ?? prodBalances['9100'] ?? 0.0;

    _applyDefaultWallets(
      generalBal,
      foodBal,
      fuelBal,
      medicalBal,
      ncmcWalletBal,
      ncmcCardBal,
    );
  }

  void _applyDefaultWallets(
    double generalBal,
    double foodBal,
    double fuelBal,
    double medicalBal,
    double ncmcWalletBal,
    double ncmcCardBal,
  ) {
    wallets.value = [
      {
        "title": "General Wallet",
        "subtitle": "Primary account",
        "balance": generalBal,
        "icon": "assets/generalwallet.png",
        "detailsicon": "assets/generalwalletdetails.png",
        "bgimage": "assets/bgwallettansaction.png",
        "bgColor": const Color(0xFFFFF5F5),
        "borderColor": const Color(0xFFFFE5E5),
        "buttonColor": const Color(0xFFFFCCCC),
        "productId": "GENERAL",
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
        "productId": "FOOD",
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
        "productId": "FUEL",
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
        "productId": "MEDICAL",
      },
      {
        "title": "NCMC Wallet",
        "subtitle": "Virtual transit wallet",
        "balance": ncmcWalletBal,
        "icon": "assets/ncmcwallet.png",
        "detailsicon": "assets/NCMCwalletdetails.png",
        "bgimage": "assets/NcmcdetailsBG.png",
        "bgColor": const Color(0xFFF9F5FF),
        "borderColor": const Color(0xFFEFE5FF),
        "buttonColor": const Color(0xFFE0CCFF),
        "productId": "FF01",
      },
      {
        "title": "NCMC Card",
        "subtitle": "For transit payment",
        "balance": ncmcCardBal,
        "icon": "assets/ncmcwallet.png",
        "detailsicon": "assets/NCMCwalletdetails.png",
        "bgimage": "assets/NcmcdetailsBG.png",
        "bgColor": const Color(0xFFF0FDFA),
        "borderColor": const Color(0xFFCCFBF1),
        "buttonColor": const Color(0xFF99F6E4),
        "productId": "FFFE",
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
    final bool isGeneralWallet = wallet["title"]
        .toString()
        .toLowerCase()
        .contains("general");
    final bool isNcmcWallet = wallet["title"].toString().toLowerCase().contains(
      "ncmc",
    );

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
                        ? "₹${(wallet["balance"] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}"
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
                    if (isGeneralWallet) ...[
                      actionButton(
                        "Add Money",
                        onTap: () {
                          if (Get.isRegistered<DashboardscreenController>()) {
                            final dashCtrl =
                                Get.find<DashboardscreenController>();
                            if (dashCtrl.isCardPermanentlyBlocked) {
                              dashCtrl.showPermanentlyBlockedAddMoneyNotice();
                              return;
                            }
                          }
                          Get.to(
                            () => const AddmoneyView(showGeneralWalletOption: true),
                            transition: Transition.rightToLeftWithFade,
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                    ] else if (isNcmcWallet) ...[
                      actionButton(
                        "Top Up",
                        onTap: () {
                          if (Get.isRegistered<DashboardscreenController>()) {
                            final dashCtrl =
                                Get.find<DashboardscreenController>();
                            if (dashCtrl.isCardPermanentlyBlocked) {
                              dashCtrl.showPermanentlyBlockedAddMoneyNotice();
                              return;
                            }
                          }
                          openNcmcTopupScreen();
                        },
                      ),
                      const SizedBox(width: 12),
                    ],
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
