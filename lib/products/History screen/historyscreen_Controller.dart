import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/utilities/string_extensions.dart';

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

  var selectedDateRange = Rx<DateTimeRange?>(null);

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    loadData();
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
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
        DateTime start = DateTime(range.start.year, range.start.month, range.start.day);
        DateTime end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
        if (txDate.isBefore(start) || txDate.isAfter(end)) {
          return false;
        }
      }

      final isCredit = tx["isCredit"] == true;
      final isFailed = tx["isFailed"] == true;

      switch (selectedFilter.value) {
        case "income":
          return isCredit && !isFailed;
        case "expense":
          return !isCredit && !isFailed;
        case "failed":
          return isFailed;
        case "all":
        default:
          return true;
      }
    }).toList();
  }

  Map<String, dynamic>? _parseTransactionItem(dynamic item) {
    if (item is! Map) return null;
    final type = item['type']?.toString().toUpperCase() ?? '';
    final isCredit = type == 'CREDIT';
    final status = item['transactionStatus']?.toString().toUpperCase() ?? '';
    final isFailed = status.contains('FAIL') || status.contains('REJECT');

    DateTime rawDate = DateTime.now();
    if (item['time'] != null) {
      try {
        rawDate = DateTime.parse(item['time'].toString());
      } catch (_) {}
    }

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

    return {
      "name": name.safeUtf16(),
      "date": _formatDate(rawDate).safeUtf16(),
      "rawDate": rawDate,
      "amount": amount,
      "isCredit": isCredit,
      "isFailed": isFailed,
      "txRef": item['txRef'],
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
        String? fromDate;
        String? toDate;

        if (selectedDateRange.value != null) {
          final range = selectedDateRange.value!;
          fromDate =
              "${range.start.year}-${range.start.month.toString().padLeft(2, '0')}-${range.start.day.toString().padLeft(2, '0')}";
          toDate =
              "${range.end.year}-${range.end.month.toString().padLeft(2, '0')}-${range.end.day.toString().padLeft(2, '0')}";
        }

        final res = await ApiService.to.fetchTransactions(
          fromDate: fromDate,
          toDate: toDate,
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
        String? fromDate;
        String? toDate;

        if (selectedDateRange.value != null) {
          final range = selectedDateRange.value!;
          fromDate =
              "${range.start.year}-${range.start.month.toString().padLeft(2, '0')}-${range.start.day.toString().padLeft(2, '0')}";
          toDate =
              "${range.end.year}-${range.end.month.toString().padLeft(2, '0')}-${range.end.day.toString().padLeft(2, '0')}";
        }

        final res = await ApiService.to.fetchTransactions(
          fromDate: fromDate,
          toDate: toDate,
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

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $month • ${hour.toString().padLeft(2, '0')}:$minute $ampm';
  }
}
