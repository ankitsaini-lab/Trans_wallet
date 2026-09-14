import 'dart:async';
import 'package:transwallet/widgets/notification_button.dart';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/widgets/user_avatar.dart';
import 'package:transwallet/products/Dashboard%20screen/dashboardscreen_Controller.dart';
import 'package:transwallet/products/Notification%20screen/notification_View.dart';
import 'package:transwallet/products/Wallet%20Screen/Add%20Money/addmoney_View.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/globalbottombar/Globalbottombar_View.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/widgets/premium_visa_card.dart';
import 'package:transwallet/products/Recharge and Bills/recharge_bills_screens.dart';

import 'package:transwallet/products/Dashboard%20screen/widgets/pressable_scale.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/bezier_chart_painter.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/mpin_verify_sheet.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/card_popups.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/premium_balance_section.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/premium_cards_section.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/quick_action_button.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/all_cards_screen.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/pay_bill_screen.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/services_more_screen.dart';

class DashboardscreenView extends StatefulWidget {
  const DashboardscreenView({super.key});

  @override
  State<DashboardscreenView> createState() => _DashboardscreenViewState();
}

class _DashboardscreenViewState extends State<DashboardscreenView> {
  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardscreenController());
    final String greeting = _getGreeting();
    final box = GetStorage();

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      bottomNavigationBar: GlobalbottombarView(seletedIndex: 0.obs),
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
        flexibleSpace: Obx(
          () => AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              gradient: controller.isScrolled.value
                  ? appBarGradient
                  : headerGradient,
            ),
          ),
        ),
        title: _animateWidget(
          delayIndex: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const UserAvatar(size: 48),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          color: secondaryText,
                          fontSize: context.responsive(13),
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.1,
                        ),
                      ),
                      Text(
                        box.read('name') ?? "User",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: context.responsive(20),
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(children: [const NotificationButton()]),
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          controller: controller.scrollController,
          physics: const BouncingScrollPhysics(),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 180,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.elliptical(400, 50),
                  ),
                  child: Image.asset(
                    "assets/dashboardbg.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: Color.fromRGBO(0, 0, 0, 0.1), height: 1),
                    height40,

                    _animateWidget(
                      delayIndex: 1,
                      child: const PremiumCardsSection(),
                    ),

                    _animateWidget(delayIndex: 4, child: _buildKycBanner()),
                    height30,

                    _animateWidget(delayIndex: 2, child: _buildQuickActions()),

                    height30,

                    _animateWidget(
                      delayIndex: 3,
                      child: _buildRechargeAndBillsSection(),
                    ),

                    height30,

                    _animateWidget(
                      delayIndex: 5,
                      child: _buildAnalyticsSection(),
                    ),

                    height30,

                    _animateWidget(
                      delayIndex: 6,
                      child: _buildRecentTransactionsSection(),
                    ),

                    height30,

                    _animateWidget(delayIndex: 7, child: _buildOffersSection()),
                    SizedBox(height: context.responsive(140)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: QuickActionButton(
                icon: Image.asset(
                  "assets/sendmoney.png",
                  height: 50,
                  width: 44,
                ),
                label: "Send Money",
                onTap: () => Get.toNamed("/sendmoney"),
              ),
            ),

            const SizedBox(width: 12),
            Expanded(
              child: QuickActionButton(
                icon: Image.asset("assets/addmoney.png", height: 50, width: 44),
                label: "Add Money",
                onTap: _openTopUpSheet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: QuickActionButton(
                icon: Image.asset(
                  "assets/transaction.png",
                  height: 50,
                  width: 44,
                ),
                label: "Transactions",
                onTap: () => Get.toNamed("/history"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRechargeAndBillsSection() {
    final items = [
      {
        "icon": "assets/recharge.svg",
        "label": "Recharge",
        "color": utilitiesFillColor,
        "route": "/mobile_recharge",
      },
      {
        "icon": "assets/Electricity.svg",
        "label": "Electricity",
        "color": utilitiesFillColor,
        "route": "/electricity_bill",
      },
      {
        "icon": "assets/fastag.svg",
        "label": "Fastag",
        "color": utilitiesFillColor,
        "route": "/fastag_recharge", //fastag screen
      },
      {
        "icon": "assets/Gas.svg",
        "label": "Gas",
        "color": utilitiesFillColor,
        "route": "/gas_bill",
      },
      {
        "icon": "assets/Broadband.svg",
        "label": "Broadband",
        "color": utilitiesFillColor,
        "route": "/broadband_bill",
      },
      {
        "icon": "assets/water.svg",
        "label": "Water",
        "color": utilitiesFillColor,
        "route": "/water_bill",
      },
      {
        "icon": "assets/tuition.svg",
        "label": "Tuition",
        "color": utilitiesFillColor,
        "route": "/tuition_fees",
      },
      {
        "icon": "assets/more.svg",
        "label": "More",
        "color": utilitiesFillColor,
        "route": "/pay_bill",
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = (width / 380.0).clamp(0.85, 1.15);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.elliptical(150, 23),
              topRight: Radius.elliptical(150, 23),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.13),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                height14,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Utilities & Bills",
                      style: TextStyle(
                        color: textColor,
                        fontSize: context.responsive(18),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                    // GestureDetector(
                    //   onTap: () => Get.to(
                    //     () => const PayBillScreen(),
                    //     transition: Transition.cupertino,
                    //   ),
                    //   child: const Row(
                    //     children: [
                    //       Text(
                    //         'View More',
                    //         style: TextStyle(
                    //           color: Colors.black,
                    //           fontSize: 14,
                    //           fontWeight: FontWeight.bold,
                    //         ),
                    //       ),
                    //       SizedBox(width: 4),
                    //       Icon(
                    //         Icons.arrow_forward_ios_rounded,
                    //         color: Colors.black,
                    //         size: 14,
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
                height14,
                Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: items
                          .take(4)
                          .map((item) => _buildGridItem(item, scale))
                          .toList(),
                    ),
                    SizedBox(height: 16 * scale),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: items
                          .skip(4)
                          .take(4)
                          .map((item) => _buildGridItem(item, scale))
                          .toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridItem(Map<String, dynamic> item, double scale) {
    final color = item["color"] as Color;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: PressableScale(
          onTap: () {
            final route = item["route"];
            if (route != null) {
              Get.toNamed(route as String);
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 56 * scale,
                width: 56 * scale,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: utilitiesBorderColor, width: 1),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    item["icon"] as String,
                    height: 24 * scale,
                    width: 24 * scale,
                  ),
                ),
              ),
              SizedBox(height: 8 * scale),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  item["label"] as String,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillersSection() {
    final billers = [
      {
        "icon": Icons.bolt_rounded,
        "label": "Electricity",
        "color": const Color(0xFFFFA726),
      },
      {
        "icon": Icons.phone_android_rounded,
        "label": "Mobile",
        "color": const Color(0xFF42A5F5),
      },
      {
        "icon": Icons.tv_rounded,
        "label": "DTH",
        "color": const Color(0xFF7E57C2),
      },
      {
        "icon": Icons.water_drop_rounded,
        "label": "Water",
        "color": const Color(0xFF26C6DA),
      },
      {
        "icon": Icons.local_gas_station_rounded,
        "label": "Gas",
        "color": const Color(0xFF66BB6A),
      },
      {
        "icon": Icons.wifi_rounded,
        "label": "Broadband",
        "color": const Color(0xFFEF5350),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Pay Bills",
              style: TextStyle(
                color: textColor,
                fontSize: context.responsive(18),
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            TextButton(
              onPressed: () => _showComingSoonBottomSheet("All Billers"),
              child: Text(
                "See All",
                style: TextStyle(
                  color: primaryRed,
                  fontWeight: FontWeight.bold,
                  fontSize: context.responsive(14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: billers.map((b) {
              final color = b["color"] as Color;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _showComingSoonBottomSheet(b["label"] as String),
                  child: Column(
                    children: [
                      Container(
                        height: 58,
                        width: 58,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: color.withOpacity(0.18),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          b["icon"] as IconData,
                          color: color,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        b["label"] as String,
                        style: TextStyle(
                          color: textColor,
                          fontSize: context.responsive(11),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildKycBanner() {
    return PressableScale(
      onTap: () => Get.toNamed("/updateKyc"),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
          image: const DecorationImage(
            image: AssetImage("assets/fullKyc.png"),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.09),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Complete your Full KYC",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsive(16),
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Unlock higher wallet limits and \npremium benefits.",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsive(12),
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  height10,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primaryRed,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: primaryRed.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Verify",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.responsive(13),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Spending Analytics",
              style: TextStyle(
                color: textColor,
                fontSize: context.responsive(18),
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: textColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "This Month",
                    style: TextStyle(
                      color: textColor,
                      fontSize: context.responsive(12),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(0, 32, 0, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.08),
                blurRadius: 5,
                spreadRadius: 0,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: CustomPaint(painter: BezierChartPainter()),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "W1",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: context.responsive(13),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "W2",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: context.responsive(13),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "W3",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: context.responsive(13),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "W4",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: context.responsive(13),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Divider(
                  color: Colors.grey.shade200,
                  thickness: 1,
                  height: 1,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Obx(() {
                  final controller = Get.find<DashboardscreenController>();
                  final incomeStr =
                      "₹${controller.totalIncome.value.toStringAsFixed(0)}";
                  final expenseStr =
                      "₹${controller.totalExpenses.value.toStringAsFixed(0)}";
                  final savingsStr =
                      "₹${controller.totalSavings.value.toStringAsFixed(0)}";

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(
                        "Income",
                        incomeStr,
                        const Color(0xFF10B981),
                      ),
                      _buildStatItem(
                        "Expenses",
                        expenseStr,
                        const Color(0xFFFF4500),
                      ),
                      _buildStatItem(
                        "Savings",
                        savingsStr,
                        const Color(0xFF2196F3),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color indicatorColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: indicatorColor,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey,
                fontSize: context.responsive(14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: context.responsive(16),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Transactions",
              style: TextStyle(
                color: textColor,
                fontSize: context.responsive(18),
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
            GestureDetector(
              onTap: () {
                Get.toNamed("/history");
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(12),
                  vertical: context.responsive(6),
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Text(
                      "All",
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: context.responsive(13),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: context.responsive(12),
                      color: textColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.08),
                blurRadius: 5,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Obx(() {
            final controller = Get.find<DashboardscreenController>();
            final txList = controller.recentTransactions;

            if (txList.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        size: 26,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "No Transactions Yet",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Your recent transactions will appear here",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: List.generate(txList.length, (index) {
                final tx = txList[index];
                final bool isCredit = tx['isCredit'] == true;
                return _buildTransactionItem(
                  icon: isCredit
                      ? Icons.south_west_rounded
                      : Icons.arrow_outward_rounded,
                  iconColor: isCredit
                      ? const Color(0xFF059669)
                      : const Color(0xFFD84315),
                  iconBgColor: isCredit
                      ? const Color(0xFF059669).withOpacity(0.08)
                      : const Color(0xFFD84315).withOpacity(0.08),
                  title: tx['title']?.toString() ?? "Transaction",
                  subtitle: tx['subtitle']?.toString() ?? "",
                  amount: tx['amount']?.toString() ?? "",
                  amountColor: isCredit
                      ? const Color(0xFF059669)
                      : const Color(0xFFD84315),
                  isFailed: tx['isFailed'] == true,
                  isLast: index == txList.length - 1,
                );
              }),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required String amount,
    required Color amountColor,
    bool isFailed = false,
    required bool isLast,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: context.responsive(48),
                width: context.responsive(48),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: iconColor,
                  size: context.responsive(20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: context.responsive(16),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: context.responsive(13),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.w800,
                      fontSize: context.responsive(16),
                    ),
                  ),
                  if (isFailed) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD84315).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Failed",
                        style: TextStyle(
                          color: const Color(0xFFD84315),
                          fontSize: context.responsive(11),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              color: Colors.grey.shade100,
              height: 1,
              thickness: 1.5,
            ),
          ),
      ],
    );
  }

  Widget _buildOffersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Offers & Insights",
              style: TextStyle(
                color: textColor,
                fontSize: context.responsive(18),
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
            // GestureDetector(
            //   onTap: () {
            //     Get.toNamed("/history");
            //   },
            //   child: Container(
            //     padding: EdgeInsets.symmetric(
            //       horizontal: context.responsive(12),
            //       vertical: context.responsive(6),
            //     ),
            //     decoration: BoxDecoration(
            //       color: Colors.grey.shade100,
            //       borderRadius: BorderRadius.circular(16),
            //     ),
            //     child: Row(
            //       children: [
            //         Text(
            //           "All",
            //           style: TextStyle(
            //             color: textColor,
            //             fontWeight: FontWeight.w600,
            //             fontSize: context.responsive(13),
            //           ),
            //         ),
            //         const SizedBox(width: 4),
            //         Icon(
            //           Icons.arrow_forward_ios_rounded,
            //           size: context.responsive(12),
            //           color: textColor,
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
        height14,
        const _AutoScrollOffersWidget(
          offerImages: ["assets/offer1.png", "assets/offer2.png"],
        ),
      ],
    );
  }

  void _openTopUpSheet() {
    Get.bottomSheet(
      const AddmoneyView(showGeneralWalletOption: false),
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
    );
  }

  void _showComingSoonBottomSheet(String feature) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: primaryRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty_rounded,
                color: primaryRed,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "$feature Coming Soon",
              style: const TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We are working hard to bring this feature to your wallet app very soon. Stay tuned!",
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryText, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: textColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Awesome",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _animateWidget({required int delayIndex, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (delayIndex * 80)),
      curve: Curves.easeOutQuad,
      builder: (context, value, childWidget) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: childWidget,
          ),
        );
      },
      child: child,
    );
  }
}

class _AutoScrollOffersWidget extends StatefulWidget {
  final List<String> offerImages;
  const _AutoScrollOffersWidget({required this.offerImages});

  @override
  State<_AutoScrollOffersWidget> createState() =>
      _AutoScrollOffersWidgetState();
}

class _AutoScrollOffersWidgetState extends State<_AutoScrollOffersWidget> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < widget.offerImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final pageViewWidth = screenWidth - 32; // Column has horizontal 16 padding
    final pageWidth = pageViewWidth * 0.92;
    final rightPadding = context.responsive(8.0);
    final cardHeight = (pageWidth - rightPadding) / 2.7;

    return SizedBox(
      height: cardHeight,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.offerImages.length,
        padEnds: false,
        onPageChanged: (int page) {
          _currentPage = page;
        },
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: rightPadding),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.responsive(20)),
              child: AspectRatio(
                aspectRatio: 2.7,
                child: Image.asset(
                  widget.offerImages[index],

                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
