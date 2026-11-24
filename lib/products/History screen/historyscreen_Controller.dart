import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'package:transwallet/services/api_service.dart';

import 'package:transwallet/utilities/string_extensions.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';

class HistoryscreenController extends GetxController {
  var transactions = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMore = false.obs;

  int currentPage = 0;
  static const int pageSize = 20;

  final ScrollController scrollController = ScrollController();

  var searchQuery = "".obs;
  var selectedFilter = "all".obs;
  var isSearchActive = false.obs;
  var isFilterActive = true.obs;

  /// Helper to calculate 1 month prior to a given date safely
  static DateTime _getOneMonthAgo(DateTime date) {
    final year = date.month == 1 ? date.year - 1 : date.year;
    final month = date.month == 1 ? 12 : date.month - 1;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final day = date.day > daysInMonth ? daysInMonth : date.day;
    return DateTime(year, month, day);
  }

  static DateTime get defaultToDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime get defaultFromDate => _getOneMonthAgo(defaultToDate);

  late final Rx<DateTime> fromDate = defaultFromDate.obs;
  late final Rx<DateTime> toDate = defaultToDate.obs;
  late final Rx<DateTimeRange?> selectedDateRange = Rx<DateTimeRange?>(
    DateTimeRange(start: defaultFromDate, end: defaultToDate),
  );

  bool get isCustomDateRange {
    final today = defaultToDate;
    final oneMonthAgo = _getOneMonthAgo(today);
    final f = fromDate.value;
    final t = toDate.value;
    return f.year != oneMonthAgo.year ||
        f.month != oneMonthAgo.month ||
        f.day != oneMonthAgo.day ||
        t.year != today.year ||
        t.month != today.month ||
        t.day != today.day;
  }

  String formatDateForDisplay(DateTime dt) {
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
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String formatApiDate(DateTime dt) {
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }

  @override
  void onInit() {
    super.onInit();
    final today = defaultToDate;
    final oneMonthAgo = defaultFromDate;
    fromDate.value = oneMonthAgo;
    toDate.value = today;
    selectedDateRange.value = DateTimeRange(start: oneMonthAgo, end: today);

    scrollController.addListener(_onScroll);
    loadData();
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  void clear() {
    transactions.clear();
    currentPage = 0;
    hasMore.value = false;
    searchQuery.value = "";
    selectedFilter.value = "all";
    isSearchActive.value = false;
    isLoading.value = false;
    isLoadingMore.value = false;
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.position.pixels;
    // Automatically trigger next page when within 200px of bottom
    if (maxScroll - currentScroll <= 200) {
      if (hasMore.value && !isLoadingMore.value && !isLoading.value) {
        loadMore();
      }
    }
  }

  List<Map<String, dynamic>> get filteredTransactions {
    return transactions.where((tx) {
      final name = tx["name"]?.toString().toLowerCase() ?? "";
      final matchesSearch = name.contains(searchQuery.value.toLowerCase());

      if (!matchesSearch) return false;

      // Date filtering
      if (selectedDateRange.value != null && tx["rawDate"] != null) {
        DateTime txDate = tx["rawDate"];
        DateTimeRange range = selectedDateRange.value!;
        DateTime start = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
          0,
          0,
          0,
        );
        DateTime end = DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
          23,
          59,
          59,
          999,
        );
        if (txDate.isBefore(start) || txDate.isAfter(end)) {
          return false;
        }
      }

      final isCredit = tx["isCredit"] == true;
      final isFailed = tx["isFailed"] == true;

      final filter = selectedFilter.value.toLowerCase().trim();
      switch (filter) {
        case "received":
        case "loaded":
        case "income":
        case "credit":
          return isCredit && !isFailed;
        case "spent":
        case "expense":
        case "debit":
          return !isCredit && !isFailed;
        // case "failed":
        //   return isFailed;
        case "all":
        default:
          return true;
      }
    }).toList();
  }

  DateTime _parseDateTime(dynamic timeVal) {
    if (timeVal == null) return DateTime.now();
    if (timeVal is DateTime) return timeVal.toLocal();

    final str = timeVal.toString().trim();
    if (str.isEmpty) return DateTime.now();

    final numVal = int.tryParse(str);
    if (numVal != null) {
      if (str.length == 10) {
        return DateTime.fromMillisecondsSinceEpoch(numVal * 1000).toLocal();
      }
      return DateTime.fromMillisecondsSinceEpoch(numVal).toLocal();
    }

    try {
      final parsed = DateTime.parse(str);
      DateTime localDate = parsed.toLocal();

      // If device is in UTC (e.g. emulator), but the string has an explicit offset (e.g. +05:30),
      // preserve Indian Standard Time (IST):
      if (DateTime.now().timeZoneOffset == Duration.zero) {
        final offsetRegex = RegExp(r'([+-])(\d{2}):?(\d{2})$');
        final match = offsetRegex.firstMatch(str);
        if (match != null) {
          final sign = match.group(1) == '-' ? -1 : 1;
          final hours = int.parse(match.group(2)!);
          final minutes = int.parse(match.group(3)!);
          final offset = Duration(hours: hours, minutes: minutes) * sign;
          localDate = parsed.add(offset);
        } else if (str.endsWith('Z')) {
          // If UTC ISO string and device is UTC, convert to IST (+05:30) for Transwallet
          localDate = parsed.add(const Duration(hours: 5, minutes: 30));
        }
      }

      return localDate;
    } catch (_) {
      return DateTime.now();
    }
  }

  Map<String, dynamic>? _parseTransactionItem(dynamic item) {
    if (item is! Map) return null;
    final type = item['type']?.toString().toUpperCase() ?? '';
    final isCredit = type == 'CREDIT';
    final status = item['transactionStatus']?.toString().toUpperCase() ?? '';
    final isFailed = status.contains('FAIL') || status.contains('REJECT');

    final timeRaw =
        item['time'] ??
        item['createdAt'] ??
        item['transactionDate'] ??
        item['timestamp'] ??
        item['date'];
    final DateTime rawDate = _parseDateTime(timeRaw);

    String name = "Transaction";
    if (item['otherPartyName'] != null &&
        item['otherPartyName'] is String &&
        (item['otherPartyName'] as String).isNotEmpty) {
      name = item['otherPartyName'];
    } else if (item['description'] != null &&
        item['description'] is String &&
        (item['description'] as String).isNotEmpty) {
      name = item['description'];
    } else if (item['yourWallet'] != null &&
        item['yourWallet'].toString().isNotEmpty) {
      name = "${item['yourWallet']} Wallet";
    } else if (item['transactionType'] != null) {
      name = item['transactionType'].toString();
    }

    final amount = (item['amount'] is num)
        ? (item['amount'] as num).toDouble()
        : double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;

    final String externalTxnId =
        (item['externalTransactionId'] ??
                item['externalTxnId'] ??
                item['txRef'] ??
                item['transactionId'] ??
                item['id'] ??
                '')
            .toString();

    final String desc =
        (item['description'] ?? item['narration'] ?? item['remarks'] ?? name)
            .toString();

    return {
      "name": name.safeUtf16(),
      "date": _formatDate(rawDate).safeUtf16(),
      "rawDate": rawDate,
      "amount": amount,
      "isCredit": isCredit,
      "isFailed": isFailed,
      "txRef": item['txRef'],
      "externalTransactionId": externalTxnId,
      "description": desc,
      "status": status,
      "yourWallet": item['yourWallet'],
      "transactionType": item['transactionType'],
      "rawItem": item,
    };
  }

  Future<void> loadData({bool isRefresh = false}) async {
    currentPage = 0;
    hasMore.value = false;
    if (!isRefresh) {
      isLoading.value = true;
    }

    if (Get.isRegistered<ApiService>()) {
      try {
        String? fromDateStr;
        String? toDateStr;

        if (selectedDateRange.value != null) {
          final range = selectedDateRange.value!;
          fromDateStr = formatApiDate(range.start);
          toDateStr = formatApiDate(range.end);
        }

        final res = await ApiService.to.fetchTransactions(
          fromDate: fromDateStr,
          toDate: toDateStr,
          pageNumber: 0,
          pageSize: pageSize,
        );

        final rawItems = res != null
            ? (res['items'] ??
                  res['transactions'] ??
                  res['content'] ??
                  (res is List ? res : null))
            : null;

        if (rawItems is List) {
          final List<Map<String, dynamic>> parsedList = [];
          for (var item in rawItems) {
            final parsed = _parseTransactionItem(item);
            if (parsed != null) parsedList.add(parsed);
          }

          transactions.value = parsedList;
          // If returned length is >= pageSize (20), show pagination to get all list
          hasMore.value = rawItems.length >= pageSize;
          isLoading.value = false;
          return;
        } else {
          transactions.value = [];
        }
      } catch (e) {
        log('Error fetching transactions in HistoryscreenController: $e');
      }
    }

    transactions.value = [];
    hasMore.value = false;
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value || isLoading.value) return;

    isLoadingMore.value = true;
    final nextPage = currentPage + 1;

    if (Get.isRegistered<ApiService>()) {
      try {
        String? fromDateStr;
        String? toDateStr;

        if (selectedDateRange.value != null) {
          final range = selectedDateRange.value!;
          fromDateStr = formatApiDate(range.start);
          toDateStr = formatApiDate(range.end);
        }

        final res = await ApiService.to.fetchTransactions(
          fromDate: fromDateStr,
          toDate: toDateStr,
          pageNumber: nextPage,
          pageSize: pageSize,
        );

        final rawItems = res != null
            ? (res['items'] ??
                  res['transactions'] ??
                  res['content'] ??
                  (res is List ? res : null))
            : null;

        if (rawItems is List && rawItems.isNotEmpty) {
          final List<Map<String, dynamic>> nextItems = [];
          for (var item in rawItems) {
            final parsed = _parseTransactionItem(item);
            if (parsed != null) nextItems.add(parsed);
          }

          transactions.addAll(nextItems);
          currentPage = nextPage;
          // If returned items count is >= pageSize (20), there may be another page
          hasMore.value = rawItems.length >= pageSize;
        } else {
          hasMore.value = false;
        }
      } catch (e) {
        log('Error loading more transactions in HistoryscreenController: $e');
        hasMore.value = false;
      } finally {
        isLoadingMore.value = false;
      }
    } else {
      hasMore.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Sets the From date, adjusting To date if necessary and reloading
  Future<void> setFromDate(DateTime newFrom) async {
    final normalizedFrom = DateTime(newFrom.year, newFrom.month, newFrom.day);
    fromDate.value = normalizedFrom;

    if (toDate.value.isBefore(normalizedFrom)) {
      toDate.value = normalizedFrom;
    }

    selectedDateRange.value = DateTimeRange(
      start: fromDate.value,
      end: toDate.value,
    );

    await loadData();
  }

  /// Sets the To date, adjusting From date if necessary and reloading
  Future<void> setToDate(DateTime newTo) async {
    final normalizedTo = DateTime(newTo.year, newTo.month, newTo.day);
    toDate.value = normalizedTo;

    if (fromDate.value.isAfter(normalizedTo)) {
      fromDate.value = normalizedTo;
    }

    selectedDateRange.value = DateTimeRange(
      start: fromDate.value,
      end: toDate.value,
    );

    await loadData();
  }

  /// Sets both dates simultaneously and reloads
  Future<void> setDateRange(DateTime start, DateTime end) async {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);

    fromDate.value = normalizedStart;
    toDate.value = normalizedEnd;
    selectedDateRange.value = DateTimeRange(
      start: normalizedStart,
      end: normalizedEnd,
    );

    await loadData();
  }

  /// Resets back to the default 1-month range
  Future<void> resetToDefaultMonth() async {
    final today = defaultToDate;
    final oneMonthAgo = defaultFromDate;

    fromDate.value = oneMonthAgo;
    toDate.value = today;
    selectedDateRange.value = DateTimeRange(start: oneMonthAgo, end: today);

    await loadData();
  }

  /// Interactive Date Picker for From Date
  Future<void> pickFromDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = fromDate.value.isAfter(today) ? today : fromDate.value;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: today,
      helpText: "SELECT FROM DATE",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryRed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF111111),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await setFromDate(picked);
    }
  }

  /// Interactive Date Picker for To Date
  Future<void> pickToDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = toDate.value.isAfter(today) ? today : toDate.value;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(fromDate.value) ? fromDate.value : initial,
      firstDate: fromDate.value,
      lastDate: today,
      helpText: "SELECT TO DATE",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryRed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF111111),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await setToDate(picked);
    }
  }

  /// Interactive Date Range Picker
  Future<void> pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final currentRange =
        selectedDateRange.value ??
        DateTimeRange(start: fromDate.value, end: toDate.value);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: currentRange.end.isAfter(today)
          ? DateTimeRange(start: currentRange.start, end: today)
          : currentRange,
      helpText: "SELECT DATE RANGE",
      saveText: "APPLY",
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryRed,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF111111),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await setDateRange(picked.start, picked.end);
    }
  }

  String _formatDate(DateTime dt) {
    final localDt = dt.toLocal();
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
    final month = months[localDt.month - 1];
    final hour = localDt.hour > 12
        ? localDt.hour - 12
        : (localDt.hour == 0 ? 12 : localDt.hour);
    final ampm = localDt.hour >= 12 ? 'PM' : 'AM';
    final minute = localDt.minute.toString().padLeft(2, '0');
    return '${localDt.day} $month • ${hour.toString().padLeft(2, '0')}:$minute $ampm';
  }
}
