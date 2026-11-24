import 'package:flutter/material.dart';
import 'package:transwallet/widgets/notification_button.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/History%20screen/historyscreen_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/globalbottombar/Globalbottombar_View.dart';
import 'package:transwallet/widgets/user_avatar.dart';
import 'package:transwallet/utilities/string_extensions.dart';

class HistoryscreenView extends GetView<HistoryscreenController> {
  const HistoryscreenView({super.key});

  @override
  HistoryscreenController get controller =>
      Get.isRegistered<HistoryscreenController>()
      ? Get.find<HistoryscreenController>()
      : Get.put(HistoryscreenController());

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    if (!Get.isRegistered<HistoryscreenController>()) {
      Get.put(HistoryscreenController());
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
            Expanded(
              child: Row(
                children: [
                  UserAvatar(size: context.responsive(48)),
                  SizedBox(width: context.responsive(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          greeting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF6B7280),
                            fontSize: context.responsive(13),
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
                          ),
                        ),
                        Text(
                          formatUserName(box.read('name')),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color.fromRGBO(0, 0, 0, 1),
                            fontWeight: FontWeight.w800,
                            fontSize: context.responsive(16),
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const NotificationButton(),
          ],
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: context.responsive(12)),
            _buildSearchPanel(context),
            _buildDateFilterBar(context),
            SizedBox(height: context.responsive(4)),
            _buildFilterPanel(context),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2.5,
                    ),
                  );
                }

                final list = controller.filteredTransactions;

                if (list.isEmpty) {
                  return RefreshIndicator(
                    color: Colors.black,
                    onRefresh: () => controller.loadData(isRefresh: true),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: Center(
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
                                  controller.isCustomDateRange
                                      ? "No transactions in selected date range"
                                      : "No transactions found",
                                  style: TextStyle(
                                    color: const Color(0xFF6B7280),
                                    fontSize: context.responsive(14),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (controller.isCustomDateRange) ...[
                                  SizedBox(height: context.responsive(10)),
                                  TextButton.icon(
                                    onPressed: controller.resetToDefaultMonth,
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 16,
                                      color: primaryRed,
                                    ),
                                    label: const Text(
                                      "Reset to Last 1 Month",
                                      style: TextStyle(
                                        color: primaryRed,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final bool showPagination =
                    controller.hasMore.value || controller.isLoadingMore.value;
                final bool showAllLoaded =
                    !controller.hasMore.value && list.length >= 20;
                final int footerCount = (showPagination || showAllLoaded)
                    ? 1
                    : 0;

                return RefreshIndicator(
                  color: Colors.black,
                  onRefresh: () => controller.loadData(isRefresh: true),
                  child: ListView.builder(
                    controller: controller.scrollController,
                    padding: EdgeInsets.only(
                      left: context.responsive(20),
                      right: context.responsive(20),
                      top: context.responsive(12),
                      bottom: context.responsive(140),
                    ),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: list.length + footerCount,
                    itemBuilder: (context, index) {
                      if (index < list.length) {
                        final tx = list[index];
                        return transactionItem(context, tx);
                      }
                      return _buildPaginationFooter(context);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilterBar(BuildContext context) {
    return Obx(() {
      final fromText = controller.formatDateForDisplay(
        controller.fromDate.value,
      );
      final toText = controller.formatDateForDisplay(controller.toDate.value);
      final isCustom = controller.isCustomDateRange;

      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive(20),
          vertical: context.responsive(4),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive(10),
            vertical: context.responsive(8),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(context.responsive(16)),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
          ),
          child: Row(
            children: [
              // From Date Pod
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => controller.pickFromDate(context),
                    borderRadius: BorderRadius.circular(context.responsive(10)),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive(10),
                        vertical: context.responsive(6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          context.responsive(10),
                        ),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: context.responsive(11),
                                color: primaryRed,
                              ),
                              SizedBox(width: context.responsive(4)),
                              Text(
                                "From",
                                style: TextStyle(
                                  color: const Color(0xFF6B7280),
                                  fontSize: context.responsive(10),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.responsive(3)),
                          Text(
                            fromText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF111111),
                              fontSize: context.responsive(12),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Arrow separator
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(6),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: context.responsive(14),
                  color: const Color(0xFF9CA3AF),
                ),
              ),

              // To Date Pod
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => controller.pickToDate(context),
                    borderRadius: BorderRadius.circular(context.responsive(10)),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive(10),
                        vertical: context.responsive(6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          context.responsive(10),
                        ),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.event_available_outlined,
                                size: context.responsive(11),
                                color: primaryRed,
                              ),
                              SizedBox(width: context.responsive(4)),
                              Text(
                                "To",
                                style: TextStyle(
                                  color: const Color(0xFF6B7280),
                                  fontSize: context.responsive(10),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: context.responsive(3)),
                          Text(
                            toText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF111111),
                              fontSize: context.responsive(12),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (isCustom) ...[
                SizedBox(width: context.responsive(6)),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: controller.resetToDefaultMonth,
                    borderRadius: BorderRadius.circular(context.responsive(10)),
                    child: Container(
                      width: context.responsive(36),
                      height: context.responsive(38),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          context.responsive(10),
                        ),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: context.responsive(18),
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    });
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

      final current = controller.selectedFilter.value.toLowerCase().trim();

      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive(20),
          vertical: context.responsive(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildFilterChip(
                context,
                "all",
                "All",
                "",
                current == "all",
              ),
            ),
            SizedBox(width: context.responsive(8)),
            Expanded(
              child: _buildFilterChip(
                context,
                "Credit",
                "Credit",
                "assets/Income.png",
                current == "credit" ||
                    current == "received" ||
                    current == "loaded" ||
                    current == "income",
              ),
            ),
            SizedBox(width: context.responsive(8)),
            Expanded(
              child: _buildFilterChip(
                context,
                "Debit",
                "Debit",
                "assets/expense.png",
                current == "debit" ||
                    current == "spent" ||
                    current == "expense",
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterChip(
    BuildContext context,
    String filterVal,
    String label,
    String imagePath,
    bool isSelected,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.selectedFilter.value = filterVal,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: context.responsive(38),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: context.responsive(8)),
        decoration: BoxDecoration(
          color: isSelected ? primaryRed : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(context.responsive(20)),
          border: Border.all(
            color: isSelected ? primaryRed : const Color(0xFFECECEC),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (imagePath.isNotEmpty) ...[
              Image.asset(
                imagePath,
                height: context.responsive(18),
                width: context.responsive(18),
                fit: BoxFit.contain,
              ),
              SizedBox(width: context.responsive(6)),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  fontSize: context.responsive(12),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingMore.value) {
        return Container(
          margin: EdgeInsets.symmetric(vertical: context.responsive(16)),
          padding: EdgeInsets.all(context.responsive(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: context.responsive(18),
                height: context.responsive(18),
                child: const CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                ),
              ),
              SizedBox(width: context.responsive(12)),
              Text(
                "Loading more transactions...",
                style: TextStyle(
                  color: const Color(0xFF6B7280),
                  fontSize: context.responsive(13),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }

      if (controller.hasMore.value) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: context.responsive(12)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => controller.loadMore(),
              borderRadius: BorderRadius.circular(context.responsive(14)),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: context.responsive(12),
                  horizontal: context.responsive(16),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(context.responsive(14)),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: context.responsive(16),
                      color: primaryRed,
                    ),
                    SizedBox(width: context.responsive(8)),
                    Text(
                      "Load More Transactions",
                      style: TextStyle(
                        color: const Color(0xFF111111),
                        fontSize: context.responsive(13),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      return Container(
        margin: EdgeInsets.symmetric(vertical: context.responsive(16)),
        alignment: Alignment.center,
        child: Text(
          "All transactions loaded",
          style: TextStyle(
            color: const Color(0xFF9CA3AF),
            fontSize: context.responsive(12),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    });
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
              color: Colors.black.withValues(alpha: 0.02),
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
                    (tx["name"]?.toString() ?? "Payment").safeUtf16(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF111111),
                      fontSize: context.responsive(15),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: context.responsive(4)),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          (tx["date"]?.toString() ?? "").safeUtf16(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF6B7280),
                            fontSize: context.responsive(12),
                            fontWeight: FontWeight.w500,
                          ),
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
            SizedBox(width: context.responsive(8)),
            Text(
              "${isCredit ? '+' : '-'} ₹${amount.abs()}",
              style: TextStyle(
                color: isCredit
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC62828),
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
        ? const Color(0xFF059669).withValues(alpha: 0.08)
        : const Color(0xFFD84315).withValues(alpha: 0.08);
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
