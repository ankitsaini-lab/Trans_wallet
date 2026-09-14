import 'package:flutter/material.dart';
import 'package:transwallet/widgets/notification_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/History%20screen/historyscreen_Controller.dart';
import 'package:transwallet/products/Notification%20screen/notification_View.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/globalbottombar/Globalbottombar_View.dart';
import 'package:transwallet/widgets/user_avatar.dart';

class HistoryscreenView extends GetView<HistoryscreenController> {
  const HistoryscreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    if (!Get.isRegistered<HistoryscreenController>()) {
      Get.lazyPut(() => HistoryscreenController());
    }
    String greeting = "Good Evening";
    if (hour < 12) {
      greeting = "Good Morning";
    } else if (hour < 17) {
      greeting = "Good Afternoon";
    }

    return Scaffold(
      bottomNavigationBar: GlobalbottombarView(seletedIndex: 2.obs),
      extendBody: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: context.responsive(80),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                UserAvatar(
                  size: context.responsive(48),
                  // border: Border.all(color: primaryYellow, width: 2),
                ),
                SizedBox(width: context.responsive(12)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        color: const Color(0xFF6B7280),
                        fontSize: context.responsive(13),
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                    ),
                    Text(
                      box.read('name') ?? "User",
                      style: TextStyle(
                        color: const Color.fromRGBO(0, 0, 0, 1),
                        fontWeight: FontWeight.w800,
                        fontSize: context.responsive(20),
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const NotificationButton(),
          ],
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: context.responsive(16)),
            _buildSearchPanel(context),
            _buildFilterPanel(context),
            Expanded(
              child: Obx(() {
                final list = controller.filteredTransactions;

                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: context.responsive(48),
                          color: Colors.grey.shade300,
                        ),
                        SizedBox(height: context.responsive(12)),
                        Text(
                          "No transactions found",
                          style: TextStyle(
                            color: const Color(0xFF6B7280),
                            fontSize: context.responsive(14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.only(
                    left: context.responsive(20),
                    right: context.responsive(20),
                    top: context.responsive(12),
                    bottom: context.responsive(120),
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final tx = list[index];
                    return transactionItem(context, tx);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchPanel(BuildContext context) {
    return Obx(() {
      if (!controller.isSearchActive.value) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive(20),
          vertical: context.responsive(8),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(context.responsive(16)),
            border: Border.all(color: const Color(0xFFECECEC)),
          ),
          padding: EdgeInsets.symmetric(horizontal: context.responsive(16)),
          child: TextField(
            onChanged: (val) => controller.searchQuery.value = val,
            style: TextStyle(
              color: const Color(0xFF111111),
              fontSize: context.responsive(14),
            ),
            decoration: InputDecoration(
              icon: const Icon(Icons.search, color: Color(0xFF111111)),
              hintText: "Search transactions...",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: context.responsive(14),
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildFilterPanel(BuildContext context) {
    return Obx(() {
      if (!controller.isFilterActive.value) return const SizedBox.shrink();

      final current = controller.selectedFilter.value;

      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive(20),
          vertical: context.responsive(8),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterChip(context, "all", "All", current == "all"),
              SizedBox(width: context.responsive(8)),
              _buildFilterChip(
                context,
                "income",
                "📥 Income",
                current == "income",
              ),
              SizedBox(width: context.responsive(8)),
              _buildFilterChip(
                context,
                "expense",
                "💸 Expense",
                current == "expense",
              ),
              SizedBox(width: context.responsive(8)),
              _buildFilterChip(
                context,
                "failed",
                "❌ Failed",
                current == "failed",
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFilterChip(
    BuildContext context,
    String filterVal,
    String label,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => controller.selectedFilter.value = filterVal,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive(16),
          vertical: context.responsive(8),
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF111111) : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(context.responsive(20)),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF111111)
                : const Color(0xFFECECEC),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontSize: context.responsive(12),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget transactionItem(BuildContext context, Map<String, dynamic> tx) {
    final amount = (tx["amount"] as num).toDouble();
    final isCredit = tx["isCredit"] == true;
    final isFailed = tx["isFailed"] == true;

    return GestureDetector(
      onTap: () => Get.toNamed("/transactiondetails", arguments: {"tx": tx}),
      child: Container(
        margin: EdgeInsets.only(bottom: context.responsive(12)),
        padding: EdgeInsets.all(context.responsive(14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.responsive(20)),
          border: Border.all(color: const Color(0xFFECECEC)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            avatar(context, isCredit),
            SizedBox(width: context.responsive(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx["name"]?.toString() ?? "Payment",
                    style: TextStyle(
                      color: const Color(0xFF111111),
                      fontSize: context.responsive(15),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: context.responsive(4)),
                  Row(
                    children: [
                      Text(
                        tx["date"]?.toString() ?? "",
                        style: TextStyle(
                          color: const Color(0xFF6B7280),
                          fontSize: context.responsive(12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isFailed) ...[
                        SizedBox(width: context.responsive(8)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsive(6),
                            vertical: context.responsive(2),
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(
                              context.responsive(6),
                            ),
                          ),
                          child: Text(
                            "Failed",
                            style: TextStyle(
                              color: const Color(0xFFC62828),
                              fontSize: context.responsive(10),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              "${isCredit ? '+' : '-'} ₹${amount.abs()}",
              style: TextStyle(
                color: isCredit
                    ? const Color(0xFF2E7D32)
                    : isFailed
                    ? const Color(0xFFC62828)
                    : const Color(0xFF111111),
                fontWeight: FontWeight.w900,
                fontSize: context.responsive(15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget avatar(BuildContext context, bool isCredit) {
    final iconColor = isCredit
        ? const Color(0xFF059669)
        : const Color(0xFFD84315);
    final iconBgColor = isCredit
        ? const Color(0xFF059669).withOpacity(0.08)
        : const Color(0xFFD84315).withOpacity(0.08);
    final icon = isCredit
        ? Icons.south_west_rounded
        : Icons.arrow_outward_rounded;

    return Container(
      height: context.responsive(48),
      width: context.responsive(48),
      decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: iconColor, size: context.responsive(20)),
    );
  }
}
