import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Wallet%20Screen/Add%20Money/addmoney_View.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/widgets/premium_visa_card.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/products/Dashboard screen/controllers/wallet_card_controller.dart';
import 'package:transwallet/utilities/string_extensions.dart';
import 'package:transwallet/modules/vkyc/widgets/vkyc_success_dialog.dart';
import 'package:transwallet/products/Dashboard screen/widgets/card_popups.dart';

class DashboardscreenController extends GetxController {
  RxBool isFlipped = false.obs;
  RxBool isVisible = false.obs;

  final ScrollController scrollController = ScrollController();
  final RxBool isScrolled = false.obs;

  void flipCard() {
    isFlipped.value = !isFlipped.value;
  }

  final RxNum totalBalance = RxNum(0);
  bool _isWalletBalanceLoading = false;

  Future<void> loadWalletBalance({bool force = false}) async {
    if (GetStorage().hasData('balance')) {
      final stored = GetStorage().read('balance');
      if (stored is num) {
        totalBalance.value = stored;
      }
    }
    if (_isWalletBalanceLoading && !force) return;
    _isWalletBalanceLoading = true;
    try {
      if (Get.isRegistered<ApiService>()) {
        final res = await ApiService.to.fetchWalletBalance(force: force);
        if (res != null && res['balance'] != null) {
          totalBalance.value = res['balance'] is num
              ? res['balance']
              : num.tryParse(res['balance'].toString()) ?? 0;
        }
      }
    } finally {
      _isWalletBalanceLoading = false;
    }
  }

  final RxList<Map<String, dynamic>> recentTransactions =
      <Map<String, dynamic>>[].obs;
  final RxBool isTransactionsLoading = false.obs;
  final RxBool isDashboardLoading = false.obs;

  final RxString userName = ''.obs;
  final RxString profilePictureUrl = ''.obs;
  final RxBool isFullKycCompleted = false.obs;
  final RxBool isKycUnderReview = false.obs;

  void loadUserData() {
    final box = GetStorage();
    final stored =
        box.read('name') ?? box.read('firstName') ?? box.read('userName');
    userName.value = formatUserName(stored);

    final pic = box.read('profilePictureUrl')?.toString() ?? '';
    profilePictureUrl.value = pic;

    final rawStatus = box.read('kyc_status')?.toString().toLowerCase() ?? '';
    final currentLevel =
        box.read('kyc_current_level')?.toString().toUpperCase() ?? '';

    final bool completed =
        box.read('full_kyc_completed') == true ||
        box.read('is_kyc_completed') == true ||
        currentLevel == 'FULL' ||
        rawStatus == 'verified' ||
        rawStatus == 'completed' ||
        rawStatus == 'approved';
    isFullKycCompleted.value = completed;
    isKycUnderReview.value = false;
  }

  Future<void> refreshDashboardData({bool force = false}) async {
    if (isDashboardLoading.value && !force) return;
    isDashboardLoading.value = true;
    loadUserData();
    try {
      final List<Future> futures = [];
      if (Get.isRegistered<ApiService>()) {
        futures.add(ApiService.to.fetchUserProfile(force: force));
      }
      futures.add(loadWalletBalance(force: force));
      futures.add(fetchRecentTransactions());
      futures.add(
        fetchTransactionAnalytics(
          month: selectedAnalyticsMonth.value.isNotEmpty
              ? selectedAnalyticsMonth.value
              : null,
        ),
      );
      if (Get.isRegistered<WalletCardController>()) {
        futures.add(Get.find<WalletCardController>().fetchCardsFromApi());
      }
      await Future.wait(futures);
      loadUserData();
    } catch (e) {
      log('Error refreshing dashboard data: $e');
    } finally {
      loadUserData();
      isDashboardLoading.value = false;
    }
  }

  final RxDouble totalIncome = 0.0.obs;
  final RxDouble totalExpenses = 0.0.obs;
  final RxDouble totalSavings = 0.0.obs;
  final RxString selectedAnalyticsMonth = ''.obs;
  final RxList<Map<String, dynamic>> weeklyAnalytics =
      <Map<String, dynamic>>[].obs;
  final RxBool isAnalyticsLoading = false.obs;

  final RxString selectedAnalyticsMetric = 'Expenses'.obs;

  // Selected week index on the Spending Analytics chart (0: W1, 1: W2, 2: W3, 3: W4, -1: none)
  final RxInt selectedAnalyticsWeek = (-1).obs;
  final RxBool isWeeklyTxLoading = false.obs;
  final RxList<Map<String, dynamic>> weeklyTransactionsList =
      <Map<String, dynamic>>[].obs;
  final RxDouble weekIncome = 0.0.obs;
  final RxDouble weekExpenses = 0.0.obs;
  final RxDouble weekSavings = 0.0.obs;

  Map<String, dynamic> getWeekDateRange(int weekIndex) {
    int year = DateTime.now().year;
    int month = DateTime.now().month;

    if (selectedAnalyticsMonth.value.isNotEmpty) {
      try {
        final parts = selectedAnalyticsMonth.value.split('-');
        if (parts.length == 2) {
          year = int.parse(parts[0]);
          month = int.parse(parts[1]);
        }
      } catch (_) {}
    }

    final int lastDay = DateTime(year, month + 1, 0).day;
    int startDay = 1;
    int endDay = 7;

    switch (weekIndex) {
      case 0:
        startDay = 1;
        endDay = 7;
        break;
      case 1:
        startDay = 8;
        endDay = 14;
        break;
      case 2:
        startDay = 15;
        endDay = 21;
        break;
      case 3:
      default:
        startDay = 22;
        endDay = lastDay;
        break;
    }

    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthName = monthNames[month - 1];

    final fromDateStr =
        "$year-${month.toString().padLeft(2, '0')}-${startDay.toString().padLeft(2, '0')}";
    final toDateStr =
        "$year-${month.toString().padLeft(2, '0')}-${endDay.toString().padLeft(2, '0')}";
    final displayRange =
        "${startDay.toString().padLeft(2, '0')} $monthName – ${endDay.toString().padLeft(2, '0')} $monthName $year";

    return {
      "year": year,
      "month": month,
      "startDay": startDay,
      "endDay": endDay,
      "fromDate": fromDateStr,
      "toDate": toDateStr,
      "displayRange": displayRange,
    };
  }

  Future<void> loadTransactionsForWeek(int weekIndex) async {
    isWeeklyTxLoading.value = true;
    weeklyTransactionsList.clear();

    final info = getWeekDateRange(weekIndex);
    final String fromDate = info['fromDate'];
    final String toDate = info['toDate'];
    final int year = info['year'];
    final int month = info['month'];
    final int startDay = info['startDay'];
    final int endDay = info['endDay'];

    // Read weekly summary stats from weeklyAnalytics if available
    if (weeklyAnalytics.isNotEmpty && weekIndex < weeklyAnalytics.length) {
      final w = weeklyAnalytics[weekIndex];
      final exp = (w['expenses'] is num)
          ? (w['expenses'] as num).toDouble()
          : 0.0;
      final inc = (w['income'] is num) ? (w['income'] as num).toDouble() : 0.0;
      final sav = (w['savings'] is num)
          ? (w['savings'] as num).toDouble()
          : (inc - exp > 0 ? inc - exp : 0.0);
      weekExpenses.value = exp;
      weekIncome.value = inc;
      weekSavings.value = sav;
    } else {
      weekExpenses.value = 0.0;
      weekIncome.value = 0.0;
      weekSavings.value = 0.0;
    }

    try {
      if (Get.isRegistered<ApiService>()) {
        final res = await ApiService.to.fetchTransactions(
          fromDate: fromDate,
          toDate: toDate,
          pageSize: 50,
        );

        if (res != null &&
            res['items'] is List &&
            (res['items'] as List).isNotEmpty) {
          final List items = res['items'];
          final List<Map<String, dynamic>> parsed = [];
          double calcInc = 0.0;
          double calcExp = 0.0;

          for (var item in items) {
            if (item is Map) {
              final type = item['type']?.toString().toUpperCase() ?? '';
              final isCredit = type == 'CREDIT';
              final status =
                  item['transactionStatus']?.toString().toUpperCase() ?? '';
              final isFailed =
                  status.contains('FAIL') || status.contains('REJECT');

              final num amt = (item['amount'] is num)
                  ? item['amount']
                  : num.tryParse(item['amount']?.toString() ?? '0') ?? 0;

              if (!isFailed) {
                if (isCredit)
                  calcInc += amt.toDouble();
                else
                  calcExp += amt.toDouble();
              }

              DateTime rawDate = DateTime.now();
              if (item['time'] != null) {
                try {
                  rawDate = DateTime.parse(item['time'].toString());
                } catch (_) {}
              }

              String title = "Transaction";
              if (item['otherPartyName'] != null &&
                  item['otherPartyName'] is String &&
                  (item['otherPartyName'] as String).isNotEmpty) {
                title = item['otherPartyName'];
              } else if (item['description'] != null &&
                  item['description'] is String &&
                  (item['description'] as String).isNotEmpty) {
                title = item['description'];
              } else if (item['yourWallet'] != null &&
                  item['yourWallet'].toString().isNotEmpty) {
                title = "${item['yourWallet']} Wallet";
              } else if (item['transactionType'] != null) {
                title = item['transactionType'].toString();
              }

              final String formattedAmount = isCredit ? "+₹$amt" : "-₹$amt";
              final String subtitle = _formatShortDate(rawDate);

              parsed.add({
                "title": title,
                "name": title,
                "subtitle": subtitle,
                "amount": formattedAmount,
                "rawAmount": amt.toDouble(),
                "rawDate": rawDate,
                "isCredit": isCredit,
                "isFailed": isFailed,
                "txRef": item['txRef'],
                "status": status,
                "yourWallet": item['yourWallet'],
                "time": item['time']?.toString() ?? rawDate.toIso8601String(),
              });
            }
          }

          if (parsed.isNotEmpty) {
            weeklyTransactionsList.value = parsed;
            if (weekExpenses.value == 0.0 && weekIncome.value == 0.0) {
              weekExpenses.value = calcExp;
              weekIncome.value = calcInc;
              weekSavings.value = (calcInc - calcExp) > 0
                  ? (calcInc - calcExp)
                  : 0.0;
            }
            return;
          }
        }
      }
    } catch (e) {
      log('Error fetching weekly transactions from API: $e');
    } finally {
      isWeeklyTxLoading.value = false;
    }

    // Fallback: Filter from locally loaded recentTransactions
    final filtered = recentTransactions.where((tx) {
      final DateTime dt = (tx['rawDate'] is DateTime)
          ? tx['rawDate'] as DateTime
          : DateTime.now();
      return dt.year == year &&
          dt.month == month &&
          dt.day >= startDay &&
          dt.day <= endDay;
    }).toList();

    weeklyTransactionsList.value = filtered;

    if (weekExpenses.value == 0.0 &&
        weekIncome.value == 0.0 &&
        filtered.isNotEmpty) {
      double calcInc = 0.0;
      double calcExp = 0.0;
      for (var tx in filtered) {
        if (tx['isFailed'] == true) continue;
        final double amt = (tx['rawAmount'] is num)
            ? (tx['rawAmount'] as num).toDouble()
            : 0.0;
        if (tx['isCredit'] == true)
          calcInc += amt;
        else
          calcExp += amt;
      }
      weekExpenses.value = calcExp;
      weekIncome.value = calcInc;
      weekSavings.value = (calcInc - calcExp) > 0 ? (calcInc - calcExp) : 0.0;
    }
  }

  String get selectedAnalyticsMonthDisplay {
    if (selectedAnalyticsMonth.value.isEmpty) return "This Month";
    try {
      final parts = selectedAnalyticsMonth.value.split('-');
      if (parts.length == 2) {
        final year = int.tryParse(parts[0]);
        final monthInt = int.tryParse(parts[1]) ?? 1;
        const monthNames = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        final now = DateTime.now();
        if (now.year == year && now.month == monthInt) {
          return "This Month";
        }
        return "${monthNames[monthInt - 1]} $year";
      }
    } catch (_) {}
    return selectedAnalyticsMonth.value;
  }

  Future<void> fetchTransactionAnalytics({String? month}) async {
    if (!Get.isRegistered<ApiService>()) return;
    isAnalyticsLoading.value = true;
    selectedAnalyticsWeek.value = -1;
    try {
      final res = await ApiService.to.fetchTransactionAnalytics(month: month);

      if (res != null) {
        if (res['month'] != null) {
          selectedAnalyticsMonth.value = res['month'].toString();
        }
        if (res['totals'] is Map) {
          final totals = Map<String, dynamic>.from(res['totals'] as Map);
          final num inc = (totals['income'] is num)
              ? totals['income']
              : num.tryParse(totals['income']?.toString() ?? '0') ?? 0;
          final num exp = (totals['expenses'] is num)
              ? totals['expenses']
              : num.tryParse(totals['expenses']?.toString() ?? '0') ?? 0;
          final num sav = (totals['savings'] is num)
              ? totals['savings']
              : num.tryParse(totals['savings']?.toString() ?? '0') ?? 0;

          totalIncome.value = inc.toDouble();
          totalExpenses.value = exp.toDouble();
          totalSavings.value = sav.toDouble();

          // Auto-select the metric that has data so user never sees a flat line when income exists
          if (totalExpenses.value == 0 && totalIncome.value > 0) {
            selectedAnalyticsMetric.value = 'Income';
          } else if (totalExpenses.value > 0) {
            selectedAnalyticsMetric.value = 'Expenses';
          }
        }

        if (res['weekly'] is List && (res['weekly'] as List).isNotEmpty) {
          final List weeklyList = res['weekly'];
          weeklyAnalytics.value = weeklyList
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        } else {
          weeklyAnalytics.clear();
        }
      } else {
        weeklyAnalytics.clear();
        totalIncome.value = 0.0;
        totalExpenses.value = 0.0;
        totalSavings.value = 0.0;
        if (recentTransactions.isNotEmpty) {
          _calculateFallbackAnalyticsFromTransactions(recentTransactions);
        }
      }
    } catch (e) {
      log('Error fetching transaction analytics: $e');
    } finally {
      isAnalyticsLoading.value = false;
    }
  }

  void _calculateFallbackAnalyticsFromTransactions(
    List<Map<String, dynamic>> items,
  ) {
    if (items.isEmpty) return;

    double w1Inc = 0.0, w1Exp = 0.0;
    double w2Inc = 0.0, w2Exp = 0.0;
    double w3Inc = 0.0, w3Exp = 0.0;
    double w4Inc = 0.0, w4Exp = 0.0;

    double sumInc = 0.0;
    double sumExp = 0.0;

    for (var item in items) {
      if (item['isFailed'] == true) continue;
      final bool isCredit = item['isCredit'] == true;
      final double amt = (item['rawAmount'] is num)
          ? (item['rawAmount'] as num).toDouble()
          : 0.0;
      final DateTime dt = (item['rawDate'] is DateTime)
          ? item['rawDate'] as DateTime
          : DateTime.now();

      final day = dt.day;
      if (day <= 7) {
        if (isCredit)
          w1Inc += amt;
        else
          w1Exp += amt;
      } else if (day <= 14) {
        if (isCredit)
          w2Inc += amt;
        else
          w2Exp += amt;
      } else if (day <= 21) {
        if (isCredit)
          w3Inc += amt;
        else
          w3Exp += amt;
      } else {
        if (isCredit)
          w4Inc += amt;
        else
          w4Exp += amt;
      }

      if (isCredit) {
        sumInc += amt;
      } else {
        sumExp += amt;
      }
    }

    if (totalIncome.value == 0.0 &&
        totalExpenses.value == 0.0 &&
        totalSavings.value == 0.0) {
      totalIncome.value = sumInc;
      totalExpenses.value = sumExp;
      totalSavings.value = (sumInc - sumExp) > 0 ? (sumInc - sumExp) : 0.0;
    }

    if (weeklyAnalytics.isEmpty) {
      weeklyAnalytics.value = [
        {
          "label": "W1",
          "expenses": w1Exp,
          "income": w1Inc,
          "savings": (w1Inc - w1Exp) > 0 ? (w1Inc - w1Exp) : 0.0,
        },
        {
          "label": "W2",
          "expenses": w2Exp,
          "income": w2Inc,
          "savings": (w2Inc - w2Exp) > 0 ? (w2Inc - w2Exp) : 0.0,
        },
        {
          "label": "W3",
          "expenses": w3Exp,
          "income": w3Inc,
          "savings": (w3Inc - w3Exp) > 0 ? (w3Inc - w3Exp) : 0.0,
        },
        {
          "label": "W4",
          "expenses": w4Exp,
          "income": w4Inc,
          "savings": (w4Inc - w4Exp) > 0 ? (w4Inc - w4Exp) : 0.0,
        },
      ];
    }
  }

  Future<void> fetchRecentTransactions() async {
    if (!Get.isRegistered<ApiService>()) return;
    isTransactionsLoading.value = true;
    try {
      final res = await ApiService.to.fetchTransactions(
        pageNumber: 0,
        pageSize: 20,
      );
      if (res != null && res['items'] is List) {
        final List items = res['items'];
        final List<Map<String, dynamic>> parsedList = [];

        double calcIncome = 0.0;
        double calcExpenses = 0.0;

        for (var item in items) {
          if (item is Map) {
            final type = item['type']?.toString().toUpperCase() ?? '';
            final isCredit = type == 'CREDIT';
            final status =
                item['transactionStatus']?.toString().toUpperCase() ?? '';
            final isFailed =
                status.contains('FAIL') || status.contains('REJECT');

            final num amt = (item['amount'] is num)
                ? item['amount']
                : num.tryParse(item['amount']?.toString() ?? '0') ?? 0;

            if (!isFailed) {
              if (isCredit) {
                calcIncome += amt.toDouble();
              } else {
                calcExpenses += amt.toDouble();
              }
            }

            DateTime rawDate = DateTime.now();
            if (item['time'] != null) {
              try {
                rawDate = DateTime.parse(item['time'].toString());
              } catch (_) {}
            }

            String title = "Transaction";
            if (item['otherPartyName'] != null &&
                item['otherPartyName'] is String &&
                (item['otherPartyName'] as String).isNotEmpty) {
              title = item['otherPartyName'];
            } else if (item['description'] != null &&
                item['description'] is String &&
                (item['description'] as String).isNotEmpty) {
              title = item['description'];
            } else if (item['yourWallet'] != null &&
                item['yourWallet'].toString().isNotEmpty) {
              title = "${item['yourWallet']} Wallet";
            } else if (item['transactionType'] != null) {
              title = item['transactionType'].toString();
            }

            final String formattedAmount = isCredit ? "+₹$amt" : "-₹$amt";
            final String subtitle = _formatShortDate(rawDate);

            parsedList.add({
              "title": title.safeUtf16(),
              "subtitle": subtitle.safeUtf16(),
              "amount": formattedAmount.safeUtf16(),
              "rawAmount": amt.toDouble(),
              "rawDate": rawDate,
              "isCredit": isCredit,
              "isFailed": isFailed,
              "txRef": item['txRef'],
              "status": status,
              "yourWallet": item['yourWallet'],
            });
          }
        }

        recentTransactions.value = parsedList;

        // Calculate fallback analytics from loaded transactions
        _calculateFallbackAnalyticsFromTransactions(parsedList);
      } else {
        recentTransactions.value = [];
      }
    } catch (e) {
      log(
        'Error fetching recent transactions in DashboardscreenController: $e',
      );
    } finally {
      isTransactionsLoading.value = false;
    }
  }

  String _formatShortDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $month, $hour:$minute $ampm';
  }

  @override
  void onInit() {
    super.onInit();
    loadUserData();
    refreshDashboardData();
  }

  @override
  void onReady() {
    super.onReady();
    _checkAppLockPrompt();
    _checkVkycSuccessPrompt();
  }

  void _checkVkycSuccessPrompt() {
    final box = GetStorage();
    final bool isVkycPending = box.read('pending_vkyc_success_dialog') == true;
    final bool isVkycArg =
        Get.arguments is Map && Get.arguments['showVkycSuccess'] == true;

    if (isVkycPending || isVkycArg) {
      box.remove('pending_vkyc_success_dialog');

      // 1. Immediately update local observable data so KYC verified badge & status show right away
      loadUserData();

      // 2. Fetch updated live user profile data and balance from backend
      if (Get.isRegistered<ApiService>()) {
        ApiService.to.fetchUserProfile(force: true).then((_) {
          loadUserData();
          refreshDashboardData(force: true);
        });
      } else {
        refreshDashboardData(force: true);
      }

      // 3. Show the VKYC success dialog popup on Dashboard after route settles
      Future.delayed(const Duration(milliseconds: 500), () {
        showVkycSuccessPopup();
      });
    }
  }

  void checkPendingVkycOnView() {
    _checkVkycSuccessPrompt();
  }

  void showVkycSuccessPopup() {
    if (Get.isDialogOpen ?? false) {
      Get.back(closeOverlays: true);
    }
    Get.dialog(
      const VkycSuccessDialog(),
      barrierDismissible: true,
      barrierColor: Colors.black54,
    );
  }

  Future<void> onVkycSuccessReturned() async {
    final box = GetStorage();
    box.remove('pending_vkyc_success_dialog');
    if (Get.isRegistered<ApiService>()) {
      await ApiService.to.fetchUserProfile(force: true);
    }
    loadUserData();
    refreshDashboardData(force: true);
    showVkycSuccessPopup();
  }

  void _checkAppLockPrompt() {
    final box = GetStorage();
    final bool shouldPrompt = box.read('pending_app_lock_prompt') ?? false;
    final bool isAppLockActive = box.read('app_lock_enabled') ?? false;

    if (shouldPrompt && !isAppLockActive) {
      // If VKYC success dialog is pending, let VKYC dialog take precedence
      final bool isVkycPending =
          box.read('pending_vkyc_success_dialog') == true ||
          (Get.arguments is Map && Get.arguments['showVkycSuccess'] == true);
      if (isVkycPending) return;

      // Add a 1.4s delay so login success message and dashboard transition settle cleanly
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!Get.isRegistered<AppLockService>()) return;
        final stillShouldPrompt = box.read('pending_app_lock_prompt') ?? false;
        final stillActive = box.read('app_lock_enabled') ?? false;
        if (!stillShouldPrompt || stillActive) return;

        // Ensure no other dialog is currently open
        if (Get.isDialogOpen ?? false) return;

        if (Get.context != null) {
          box.write('pending_app_lock_prompt', false);
          AppLockService.to.showEnableAppLockDialog(Get.context!);
        }
      });
    }
  }

  @override
  void onClose() {
    try {
      scrollController.dispose();
    } catch (_) {}
    super.onClose();
  }

  void toggleVisibility() {
    isVisible.value = !isVisible.value;
  }

  Widget actionBtn(String icon, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset("$icon", height: 25, color: Colors.black),

              const SizedBox(height: 6),

              Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget tile(String l, String t, String amt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFD64550).withOpacity(0.1),
            child: Text(
              l,
              style: const TextStyle(
                color: Color(0xFFD64550),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              t,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Text(
            amt,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: amt.contains("+") ? Colors.green.shade700 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFront({Key? key}) {
    final box = GetStorage();
    final storedCards = box.read('user_cards');
    String? cardBrand;
    String? cardBg;
    String cardExpiry = "--/--";
    String cardNumberFull = "";
    String cardNumberMasked = "•••• •••• •••• ••••";
    String cardCvv = "•••";
    bool isPermBlocked = false;
    bool isCardFrozen = false;
    if (storedCards is List && storedCards.isNotEmpty) {
      final first = storedCards.first;
      if (first is Map) {
        final rawStatus = first['status']?.toString().toUpperCase() ?? '';
        isPermBlocked = rawStatus == 'BLOCKED' ||
            rawStatus == 'PERMANENT_BLOCK' ||
            rawStatus == 'PERMANENTLY_BLOCKED' ||
            first['isPermanentlyBlocked'] == true;
        isCardFrozen = !isPermBlocked &&
            (rawStatus == 'LOCKED' || rawStatus == 'FROZEN' || first['isBlocked'] == true);
        cardBrand = first['network']?.toString() ?? first['brand']?.toString();
        cardBg = first['bgImage']?.toString();
        final rawExp =
            first['expiryMmYy']?.toString() ??
            first['expiry']?.toString() ??
            '';
        final digits = rawExp.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length == 4) {
          cardExpiry = '${digits.substring(0, 2)}/${digits.substring(2, 4)}';
        } else if (rawExp.contains('/')) {
          cardExpiry = rawExp;
        } else if (rawExp.isNotEmpty) {
          cardExpiry = rawExp;
        }

        final full = first['fullNumber']?.toString() ?? first['cardNumber']?.toString() ?? '';
        final masked = first['maskedNumber']?.toString() ?? '';
        final last4 = first['last4']?.toString() ?? '';
        cardNumberFull = full.isNotEmpty ? full : (masked.isNotEmpty ? masked : (last4.isNotEmpty ? '•••• •••• •••• $last4' : '•••• •••• •••• ••••'));
        cardNumberMasked = masked.isNotEmpty ? masked : (last4.isNotEmpty ? '•••• •••• •••• $last4' : '•••• •••• •••• ••••');
        if (first['cvv'] != null && first['cvv'].toString().isNotEmpty) {
          cardCvv = first['cvv'].toString();
        }
      }
    }
    final rawName = (box.read('name') ?? box.read('userName') ?? '').toString().trim();
    final String cardHolder = rawName.isNotEmpty ? rawName.toUpperCase() : "CARDHOLDER";
    final resolvedBg = PremiumVisaCard.resolveCardBgImage(
      brand: cardBrand,
      bgImage: cardBg,
    );

    return Obx(
      () => PremiumVisaCard(
        key: key,
        cardNumber: isVisible.value ? (cardNumberFull.isNotEmpty ? cardNumberFull : cardNumberMasked) : cardNumberMasked,
        cardHolder: cardHolder,
        expiryDate: cardExpiry,
        cvv: isVisible.value ? cardCvv : "•••",
        bgImage: resolvedBg,
        brand: cardBrand,
        isBlocked: isCardFrozen,
        isPermanentlyBlocked: isPermBlocked,
        onTap: flipCard,
        topRightAction: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: math.pi / 2,
              child: Icon(Icons.wifi, color: Colors.white70, size: 16),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: toggleVisibility,
              child: Icon(
                isVisible.value ? Icons.visibility : Icons.visibility_off,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBack({Key? key}) {
    final box = GetStorage();
    final storedCards = box.read('user_cards');
    String cardCvv = "•••";
    if (storedCards is List && storedCards.isNotEmpty) {
      final first = storedCards.first;
      if (first is Map && first['cvv'] != null && first['cvv'].toString().isNotEmpty) {
        cardCvv = first['cvv'].toString();
      }
    }

    return cardBase(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(height: 12, color: Colors.grey.shade300),
                ),

                const SizedBox(width: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Obx(
                    () => blurWrapper(
                      isVisible.value,
                      Text(
                        cardCvv,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Set PIN", style: TextStyle(fontSize: 12)),
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  Widget cardBase({required Widget child, Key? key}) {
    final box = GetStorage();
    final storedCards = box.read('user_cards');
    String? cardBrand;
    String? cardBg;
    if (storedCards is List && storedCards.isNotEmpty) {
      final first = storedCards.first;
      if (first is Map) {
        cardBrand = first['network']?.toString() ?? first['brand']?.toString();
        cardBg = first['bgImage']?.toString();
      }
    }
    final resolvedBg = PremiumVisaCard.resolveCardBgImage(
      brand: cardBrand,
      bgImage: cardBg,
    );

    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        image: DecorationImage(
          image: AssetImage(resolvedBg),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFCC00).withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(children: [child]),
    );
  }

  Widget topRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset('assets/WU.png', height: 22, fit: BoxFit.contain),
        Obx(
          () => GestureDetector(
            onTap: toggleVisibility,
            child: Icon(
              isVisible.value ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget blurWrapper(bool isVisible, Widget child) {
    return isVisible
        ? child
        : const Text(
            "•••",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.black,
            ),
          );
  }

  Widget walletCard({required showhide, BuildContext? context}) {
    final double buttonTextSize =
        (context ?? Get.context)?.responsive(14) ?? 14;
    final box = GetStorage();
    final storedCards = box.read('user_cards');
    String cardNumberText = "•••• •••• •••• ••••";
    if (storedCards is List && storedCards.isNotEmpty && storedCards.first is Map) {
      final first = storedCards.first;
      final masked = first['maskedNumber']?.toString() ?? '';
      final last4 = first['last4']?.toString() ?? '';
      if (masked.isNotEmpty) {
        cardNumberText = masked;
      } else if (last4.isNotEmpty) {
        cardNumberText = "•••• •••• •••• $last4";
      }
    }
    final rawName = (box.read('name') ?? box.read('userName') ?? '').toString().trim();
    final String holderName = rawName.isNotEmpty ? rawName.toUpperCase() : "CARDHOLDER";

    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF1C1C1E), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                Container(
                  width: 50,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                height12,

                Row(
                  children: [
                    Text(
                      showhide == true ? cardNumberText : " ",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 15,
            left: 20,
            child: Text(holderName, style: const TextStyle(color: Colors.white54)),
          ),

          Positioned(
            top: 10,
            right: 10,
            child: Visibility(
              visible: showhide,
              child: GestureDetector(
                onTap: openCardDetails,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.visibility,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 45,
            left: 0,
            right: 0,
            child: Visibility(
              visible: showhide,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(child: SizedBox(width: 5)),
                  Expanded(
                    child: CustomButton(
                      prefixIcon: Icon(Icons.send, color: Colors.black),
                      text: "Transfer",
                      height: 40,
                      textsize: buttonTextSize,
                      btncolor: Colors.white,
                      textColor: Colors.black,
                      onPressed: () {
                        Get.toNamed("/sendmoney");
                      },
                    ),
                  ),
                  width6,
                  Expanded(
                    child: CustomButton(
                      prefixIcon: const Icon(Icons.add, color: Colors.black),
                      text: "Top-up",
                      height: 40,
                      textsize: buttonTextSize,
                      btncolor: Colors.white,
                      textColor: Colors.black,
                      onPressed: () {
                        Get.bottomSheet(
                          const AddmoneyView(showGeneralWalletOption: false),
                          isScrollControlled: true,
                          isDismissible: false,
                          enableDrag: false,
                          backgroundColor: Colors.transparent,
                        );
                      },
                    ),
                  ),
                  width8,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void openCardDetails() {
    final box = GetStorage();
    final storedCards = box.read('user_cards');
    Map<String, dynamic> cardData = <String, dynamic>{};
    if (storedCards is List && storedCards.isNotEmpty && storedCards.first is Map) {
      cardData = Map<String, dynamic>.from(storedCards.first as Map);
    }
    Get.dialog(
      CardDetailsPopup(card: cardData),
      barrierDismissible: true,
    );
  }

  Widget copyIcon(String text) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        Get.snackbar(
          "Copied",
          text,
          backgroundColor: Colors.black,
          colorText: Colors.white,
        );
      },
      child: const Icon(Icons.copy, color: Colors.white70, size: 18),
    );
  }

  Widget overlayRow(String text, {bool copy = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),

        if (copy)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: text));
              Get.snackbar(
                "Copied",
                "Copied successfully",
                backgroundColor: Colors.black,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Icon(Icons.copy, color: Colors.white70, size: 18),
          ),
      ],
    );
  }

  Widget detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),

          Row(
            children: [
              Text(value, style: const TextStyle(color: Colors.white)),

              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));

                  Get.snackbar(
                    "Copied",
                    "$title copied",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.black,
                    colorText: Colors.white,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget actionButton(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (title == "Transfer") {
          print("Transfer clicked");
        }
        if (title == "Top Up") {
          print("TopUp clicked");
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
