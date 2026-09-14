import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:transwallet/services/api_service.dart';

class HistoryscreenController extends GetxController {
  var transactions = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;

  var searchQuery = "".obs;
  var selectedFilter = "all".obs;
  var isSearchActive = false.obs;
  var isFilterActive = true.obs;

  var selectedDateRange = Rx<DateTimeRange?>(null);

  @override
  void onInit() {
    super.onInit();
    loadData();
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

  Future<void> loadData() async {
    isLoading.value = true;
    if (Get.isRegistered<ApiService>()) {
      try {
        String? fromDate;
        String? toDate;

        if (selectedDateRange.value != null) {
          final range = selectedDateRange.value!;
          fromDate = "${range.start.year}-${range.start.month.toString().padLeft(2, '0')}-${range.start.day.toString().padLeft(2, '0')}";
          toDate = "${range.end.year}-${range.end.month.toString().padLeft(2, '0')}-${range.end.day.toString().padLeft(2, '0')}";
        }

        final res = await ApiService.to.fetchTransactions(
          fromDate: fromDate,
          toDate: toDate,
        );

        if (res != null && res['items'] is List) {
          final List items = res['items'];
          final List<Map<String, dynamic>> parsedList = [];

          for (var item in items) {
            if (item is Map) {
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

              parsedList.add({
                "name": name,
                "date": _formatDate(rawDate),
                "rawDate": rawDate,
                "amount": amount,
                "isCredit": isCredit,
                "isFailed": isFailed,
                "txRef": item['txRef'],
                "status": status,
                "yourWallet": item['yourWallet'],
                "transactionType": item['transactionType'],
                "rawItem": item,
              });
            }
          }

          transactions.value = parsedList;
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
    isLoading.value = false;
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
