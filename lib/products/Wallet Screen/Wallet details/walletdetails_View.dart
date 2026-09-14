import 'package:flutter/material.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/notification_button.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Notification%20screen/notification_View.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';

import 'package:transwallet/products/Wallet%20Screen/Wallet%20details/walletdetails_controller.dart';
import 'package:transwallet/widgets/constsize.dart';

class WalletdetailsView extends GetView<WalletdetailsController> {
  const WalletdetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => WalletdetailsController());

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),

        elevation: 0,
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        title: const Text(
          "Transactions",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 8, bottom: 8),
            child: const NotificationButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            walletCard(),
            _buildSearchPanel(),
            _buildFilterPanel(),
            const SizedBox(height: 8),
            transactionList(),
          ],
        ),
      ),
    );
  }

  Widget walletCard() {
    return Obx(() {
      final w = controller.wallet;

      if (w.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: primaryRed),
        );
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: w["bgColor"] ?? const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: w["borderColor"] ?? const Color(0xFFFFE5E5),
          ),
          image: DecorationImage(
            image: AssetImage(w["bgimage"] ?? "assets/bgwallettansaction.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(0),
              child: Row(
                children: [
                  width20,
                  Container(
                    padding: const EdgeInsets.only(
                      top: 20,
                      bottom: 8,
                      left: 8,
                      right: 8,
                    ),
                    decoration: BoxDecoration(
                      color: w["borderColor"] ?? const Color(0xFFFFE5E5),
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(40),
                        bottomLeft: Radius.circular(40),
                      ),
                    ),
                    child: Image.asset(
                      w["detailsicon"] ?? "assets/generalwallet.png",
                      height: 56,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w["title"]?.toString() ?? "General Wallet",
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        w["subtitle"]?.toString() ?? "Wallet ID : GW-1025",
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 35, bottom: 15, left: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Available Balance",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                    ),
                    child: Text(
                      "₹ ${(w["balance"] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSearchPanel() {
    return Obx(() {
      if (!controller.isSearchActive.value) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECECEC)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            onChanged: (val) => controller.searchQuery.value = val,
            style: const TextStyle(color: Color(0xFF111111), fontSize: 14),
            decoration: InputDecoration(
              icon: const Icon(Icons.search, color: Color(0xFF111111)),
              hintText: "Search transactions...",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildFilterPanel() {
    return Obx(() {
      final current = controller.selectedFilter.value;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _buildFilterChip("all", "All", current == "all"),
            const SizedBox(width: 12),
            _buildFilterChip("income", "Added", current == "income"),
            const SizedBox(width: 12),
            _buildFilterChip("expense", "Spent", current == "expense"),
          ],
        ),
      );
    });
  }

  Widget _buildFilterChip(String filterVal, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => controller.selectedFilter.value = filterVal,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryRed : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryRed : const Color(0xFFECECEC),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget transactionList() {
    return Flexible(
      child: Obx(() {
        final list = controller.filteredTransactions;

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                const Text(
                  "No transactions found",
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECECEC)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: list.length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              color: const Color(0xFFECECEC),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            itemBuilder: (context, index) {
              final tx = list[index];
              return transactionItem(tx);
            },
          ),
        );
      }),
    );
  }

  Widget transactionItem(Map<String, dynamic> tx) {
    final amount = (tx["amount"] as num).toDouble();
    final isCredit = amount > 0;

    final amountStr =
        "₹ ${amount.abs().toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}";

    return GestureDetector(
      onTap: () => Get.toNamed("/transactiondetails", arguments: {"tx": tx}),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        color: Colors.transparent,
        child: Row(
          children: [
            avatar(isCredit),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx["name"]?.toString() ?? "Payment",
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tx["date"]?.toString() ?? "9 Nov 2024 . 04:45 PM",
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              isCredit ? "+$amountStr" : "- $amountStr",
              style: TextStyle(
                color: isCredit
                    ? const Color(0xFF009688)
                    : const Color(0xFFE53935),
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget avatar(bool isCredit) {
    final iconColor = isCredit
        ? const Color(0xFF009688)
        : const Color(0xFFE53935);
    final iconBgColor = isCredit
        ? const Color(0xFFE0F2F1)
        : const Color(0xFFFFEBEE);
    final icon = isCredit
        ? Icons.call_received_rounded
        : Icons.call_made_rounded;

    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 18),
    );
  }
}
