import 'dart:developer';

import 'package:get/get.dart';
import 'package:transwallet/services/api_service.dart';

class WalletdetailsController extends GetxController {
  RxMap<String, dynamic> wallet = <String, dynamic>{}.obs;
  final argument = Get.arguments ?? {};
  @override
  void onInit() {
    super.onInit();
    log("voice");
    if (argument["data"] != null) {
      wallet.value = Map<String, dynamic>.from(argument["data"]);
      log("✅ Wallet data received: $wallet");
    } else {
      log("⚠️ No wallet data received");
    }
    fetchWalletTransactions();
  }

  var searchQuery = "".obs;
  var selectedFilter = "all".obs;
  var isSearchActive = false.obs;
  var isFilterActive = false.obs;

  List<Map<String, dynamic>> get filteredTransactions {
    return transactions.where((tx) {
      final name = tx["name"]?.toString().toLowerCase() ?? "";
      final matchesSearch = name.contains(searchQuery.value.toLowerCase());

      if (!matchesSearch) return false;

      final amount = (tx["amount"] as num).toDouble();
      final status = tx["status"]?.toString() ?? "";

      switch (selectedFilter.value) {
        case "income":
          return amount > 0;
        case "expense":
          return amount < 0 && status != "failed";
        case "failed":
          return status == "failed";
        case "all":
        default:
          return true;
      }
    }).toList();
  }

  RxList<Map<String, dynamic>> transactions = <Map<String, dynamic>>[].obs;

  Future<void> fetchWalletTransactions() async {
    if (!Get.isRegistered<ApiService>()) return;
    try {
      final res = await ApiService.to.fetchTransactions(pageNumber: 0, pageSize: 20);
      if (res != null && res['items'] is List) {
        final List items = res['items'];
        final List<Map<String, dynamic>> parsedList = [];
        final String selectedWalletTitle = wallet['title']?.toString().toUpperCase() ?? '';

        for (var item in items) {
          if (item is Map) {
            final yourWallet = item['yourWallet']?.toString().toUpperCase() ?? '';
            // If wallet details screen is for a specific wallet, filter if yourWallet matches
            if (selectedWalletTitle.isNotEmpty &&
                yourWallet.isNotEmpty &&
                !selectedWalletTitle.contains(yourWallet) &&
                !yourWallet.contains(selectedWalletTitle.replaceAll(' WALLET', ''))) {
              // skip if not matching
            }

            final type = item['type']?.toString().toUpperCase() ?? '';
            final isCredit = type == 'CREDIT';
            final statusStr = item['transactionStatus']?.toString().toUpperCase() ?? '';
            final isFailed = statusStr.contains('FAIL') || statusStr.contains('REJECT');

            final num amt = (item['amount'] is num)
                ? item['amount']
                : num.tryParse(item['amount']?.toString() ?? '0') ?? 0;

            final double finalAmount = isCredit ? amt.toDouble() : -amt.toDouble();

            String name = "Transaction";
            if (item['otherPartyName'] != null &&
                item['otherPartyName'] is String &&
                (item['otherPartyName'] as String).isNotEmpty) {
              name = item['otherPartyName'];
            } else if (item['description'] != null &&
                item['description'] is String &&
                (item['description'] as String).isNotEmpty) {
              name = item['description'];
            }

            DateTime rawDate = DateTime.now();
            if (item['time'] != null) {
              try {
                rawDate = DateTime.parse(item['time'].toString());
              } catch (_) {}
            }

            parsedList.add({
              "name": name,
              "date": "${rawDate.day} ${_getMonth(rawDate.month)} • ${_formatTime(rawDate)}",
              "amount": finalAmount,
              "status": isFailed ? "failed" : (isCredit ? "credit" : "success"),
              "rawItem": item,
            });
          }
        }
        transactions.value = parsedList;
      }
    } catch (e) {
      log('Error fetching wallet details transactions: $e');
    }
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute $ampm';
  }
}
