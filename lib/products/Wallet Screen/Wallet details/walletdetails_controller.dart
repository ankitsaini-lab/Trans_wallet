import 'dart:developer';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/auth_service.dart';

class WalletdetailsController extends GetxController {
  RxMap<String, dynamic> wallet = <String, dynamic>{}.obs;
  final argument = Get.arguments ?? {};
  bool get _canFetchTransactions {
    final box = GetStorage();
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
    log("voice");
    if (argument["data"] != null) {
      wallet.value = Map<String, dynamic>.from(argument["data"]);
      log("✅ Wallet data received: $wallet");
    } else {
      log("⚠️ No wallet data received");
    }
    if (_canFetchTransactions) {
      fetchWalletTransactions();
    }
  }

  var searchQuery = "".obs;
  var selectedFilter = "all".obs;
  var isSearchActive = false.obs;
  var isFilterActive = false.obs;
  var isLoading = false.obs;

  List<Map<String, dynamic>> get filteredTransactions {
    return transactions.where((tx) {
      final name = tx["name"]?.toString().toLowerCase() ?? "";
      final desc = tx["description"]?.toString().toLowerCase() ?? "";
      final q = searchQuery.value.toLowerCase().trim();
      final matchesSearch = q.isEmpty || name.contains(q) || desc.contains(q);

      if (!matchesSearch) return false;

      final amount = (tx["amount"] as num).toDouble();
      final status = tx["status"]?.toString() ?? "";

      final filter = selectedFilter.value.toLowerCase().trim();
      switch (filter) {
        case "loaded":
        case "income":
        case "received":
        case "credit":
          return amount > 0;
        case "spent":
        case "expense":
        case "debit":
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

  static String _normalizeWallet(String raw) {
    String upper = raw.toUpperCase().trim();
    if (upper == 'FF01' || upper.contains('FF01') || upper == 'NCMC WALLET') {
      return 'FF01';
    }
    if (upper == 'FFFE' ||
        upper.contains('FFFE') ||
        upper == '9100' ||
        upper == 'NCMC CARD') {
      return 'FFFE';
    }
    String s = upper
        .replaceAll('WALLET', '')
        .replaceAll('CARD', '')
        .replaceAll('ACCOUNT', '')
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .trim();
    if (s == 'FF01') return 'FF01';
    if (s == 'FFFE' || s == '9100') return 'FFFE';
    if (s == 'NCMC') return 'FF01';
    if (s == 'TRANSIT') return 'FFFE';
    if (s == 'FOOD') return 'MEAL';
    if (s == 'HEALTH' || s == 'HEALTHCARE') return 'MEDICAL';
    if (s == 'PRIMARY') return 'GENERAL';
    return s;
  }

  static bool _matchesWallet(
    String selectedWalletTitle,
    dynamic itemOrWallet, {
    String? selectedProductId,
  }) {
    String target = '';
    if (selectedProductId != null && selectedProductId.trim().isNotEmpty) {
      target = _normalizeWallet(selectedProductId);
    }
    if (target.isEmpty) {
      target = _normalizeWallet(selectedWalletTitle);
    }
    if (target.isEmpty) return true;

    if (itemOrWallet is Map) {
      final rawCandidates = [
        itemOrWallet['productId'],
        itemOrWallet['yourWallet'],
        itemOrWallet['wallet'],
        itemOrWallet['walletType'],
        itemOrWallet['toProductId'],
        itemOrWallet['fromProductId'],
        itemOrWallet['productCode'],
      ];

      final normalizedCandidates = <String>{};
      for (var c in rawCandidates) {
        if (c != null && c.toString().trim().isNotEmpty) {
          normalizedCandidates.add(_normalizeWallet(c.toString()));
        }
      }

      if (target == 'FF01') {
        // NCMC Wallet (FF01)
        if (normalizedCandidates.contains('FF01')) {
          return true;
        }

        final desc = (itemOrWallet['description'] ??
                itemOrWallet['narration'] ??
                itemOrWallet['remarks'] ??
                itemOrWallet['otherPartyName'] ??
                '')
            .toString()
            .toUpperCase();
        if (desc.contains('FF01') || desc.contains('NCMC WALLET')) {
          return true;
        }
        return false;
      }

      if (target == 'FFFE') {
        // NCMC Card (FFFE)
        if (normalizedCandidates.contains('FFFE')) {
          return true;
        }

        final desc = (itemOrWallet['description'] ??
                itemOrWallet['narration'] ??
                itemOrWallet['remarks'] ??
                itemOrWallet['otherPartyName'] ??
                '')
            .toString()
            .toUpperCase();
        if (desc.contains('FFFE') ||
            desc.contains('9100') ||
            desc.contains('NCMC CARD') ||
            desc.contains('TRANSIT')) {
          return true;
        }
        return false;
      }

      if (target == 'GENERAL') {
        final specificSubwallets = {'FFFE', 'FF01', 'MEAL', 'FUEL', 'MEDICAL'};
        final hasSpecificSubwallet =
            normalizedCandidates.any((c) => specificSubwallets.contains(c));

        if (!hasSpecificSubwallet) {
          return true;
        }

        // Show debit transfer out of General wallet
        if (itemOrWallet['fromProductId']?.toString().toUpperCase() ==
            'GENERAL') {
          return true;
        }

        return normalizedCandidates.contains('GENERAL');
      }

      // Specific sub-wallets (Meal, Fuel, Medical)
      return normalizedCandidates.contains(target);
    }

    final txWallet = _normalizeWallet(itemOrWallet.toString());
    if (target == 'GENERAL') {
      return txWallet.isEmpty || txWallet == 'GENERAL';
    } else {
      return txWallet == target;
    }
  }

  Future<void> fetchWalletTransactions() async {
    if (!_canFetchTransactions || !Get.isRegistered<ApiService>()) return;
    isLoading.value = true;
    try {
      final List<Map<String, dynamic>> parsedList = [];
      final String selectedWalletTitle =
          (wallet['title'] ?? wallet['name'] ?? '').toString().trim();
      final String selectedProductId =
          (wallet['productId'] ?? '').toString().trim().toUpperCase();

      // Transcorp API allows max pageSize = 50. Fetch up to 2 pages (100 items max).
      for (int page = 0; page < 2; page++) {
        final res = await ApiService.to.fetchTransactions(
          pageNumber: page,
          pageSize: 50,
        );
        if (res != null && res['items'] is List) {
          final List items = res['items'];
          for (var item in items) {
            if (item is Map) {
              final rawYourWallet =
                  (item['productId'] ??
                          item['yourWallet'] ??
                          item['wallet'] ??
                          item['walletType'] ??
                          item['toProductId'] ??
                          item['fromProductId'] ??
                          '')
                      .toString()
                      .trim();

              // Filter by yourWallet / productId key
              if (!_matchesWallet(
                selectedWalletTitle,
                item,
                selectedProductId: selectedProductId,
              )) {
                continue;
              }

              final type = item['type']?.toString().toUpperCase() ?? '';
              final isCredit = type == 'CREDIT';
              final statusStr =
                  item['transactionStatus']?.toString().toUpperCase() ?? '';
              final isFailed =
                  statusStr.contains('FAIL') || statusStr.contains('REJECT');

              final num amt = (item['amount'] is num)
                  ? item['amount']
                  : num.tryParse(item['amount']?.toString() ?? '0') ?? 0;

              final double finalAmount = isCredit
                  ? amt.toDouble()
                  : -amt.toDouble();

              String name = "Transaction";
              if (item['otherPartyName'] != null &&
                  item['otherPartyName'] is String &&
                  (item['otherPartyName'] as String).isNotEmpty) {
                name = item['otherPartyName'];
              } else if (item['description'] != null &&
                  item['description'] is String &&
                  (item['description'] as String).isNotEmpty) {
                name = item['description'];
              } else if (rawYourWallet.isNotEmpty) {
                final norm = _normalizeWallet(rawYourWallet);
                name = (norm == 'FFFE')
                    ? "NCMC Card"
                    : (norm == 'FF01')
                        ? "NCMC Wallet"
                        : "$rawYourWallet Wallet";
              }

              final timeRaw =
                  item['time'] ??
                  item['createdAt'] ??
                  item['transactionDate'] ??
                  item['timestamp'] ??
                  item['date'];
              final DateTime rawDate = _parseDateTime(timeRaw);

              parsedList.add({
                "name": name,
                "date":
                    "${rawDate.day} ${_getMonth(rawDate.month)} • ${_formatTime(rawDate)}",
                "amount": finalAmount,
                "status": isFailed
                    ? "failed"
                    : (isCredit ? "credit" : "success"),
                "yourWallet": item['yourWallet'],
                "isCredit": isCredit,
                "isFailed": isFailed,
                "txRef": item['txRef'] ?? item['tx_ref'],
                "externalTransactionId":
                    item['externalTransactionId'] ??
                    item['externalTxnId'] ??
                    item['txRef'] ??
                    item['transactionId'] ??
                    item['id'] ??
                    '',
                "description":
                    item['description'] ??
                    item['narration'] ??
                    item['remarks'] ??
                    name,
                "rawItem": item,
              });
            }
          }

          // If the page has fewer than 50 items, there are no further pages
          if (items.length < 50) {
            break;
          }
        } else {
          break;
        }
      }

      transactions.value = parsedList;
    } catch (e) {
      log('Error fetching wallet details transactions: $e');
    } finally {
      isLoading.value = false;
    }
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
          localDate = parsed.add(const Duration(hours: 5, minutes: 30));
        }
      }

      return localDate;
    } catch (_) {
      return DateTime.now();
    }
  }

  String _getMonth(int month) {
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
    return months[month - 1];
  }

  String _formatTime(DateTime dt) {
    final localDt = dt.toLocal();
    final hour = localDt.hour > 12
        ? localDt.hour - 12
        : (localDt.hour == 0 ? 12 : localDt.hour);
    final ampm = localDt.hour >= 12 ? 'PM' : 'AM';
    final minute = localDt.minute.toString().padLeft(2, '0');
    return '${hour.toString().padLeft(2, '0')}:$minute $ampm';
  }
}
