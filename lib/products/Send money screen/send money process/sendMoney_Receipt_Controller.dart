import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:transwallet/utilities/getStorage.dart';

class ReceiptDetailItem {
  final String label;
  final String value;
  final String? imageAsset;
  final IconData? icon;
  final bool isCopyable;

  const ReceiptDetailItem({
    required this.label,
    required this.value,
    this.imageAsset,
    this.icon,
    this.isCopyable = false,
  });
}

class SendMoneyReceiptController extends GetxController {
  double amount = 0.0;
  Map<String, String>? recipient;
  String note = '';
  String? providerRef;
  String? externalTransactionId;
  String? transactionType;
  String? paymentMethod;
  String? paymentSource;
  String? senderUpi;
  double? balance;
  String? status;
  String? timestamp;
  Map<String, dynamic>? apiData;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map) {
      if (args['apiData'] != null && args['apiData'] is Map) {
        apiData = Map<String, dynamic>.from(args['apiData'] as Map);
      }

      if (apiData != null && apiData!['amount'] != null) {
        amount = (apiData!['amount'] as num).toDouble();
      } else if (args['amount'] != null) {
        amount = (args['amount'] as num).toDouble();
      }

      if (args['recipient'] != null && args['recipient'] is Map) {
        recipient = Map<String, String>.from(
          (args['recipient'] as Map).map(
            (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
          ),
        );
      }

      note =
          (apiData?['description'] ??
                  apiData?['narration'] ??
                  apiData?['remarks'] ??
                  args['description'] ??
                  args['note'] ??
                  '')
              .toString()
              .trim();

      providerRef =
          (apiData?['providerRef'] ??
                  apiData?['referenceId'] ??
                  apiData?['txRef'] ??
                  args['providerRef'])
              ?.toString()
              ?.trim();

      externalTransactionId =
          (apiData?['externalTransactionId'] ??
                  apiData?['transactionId'] ??
                  args['externalTransactionId'])
              ?.toString()
              ?.trim();

      transactionType = (apiData?['transactionType'] ?? args['transactionType'])
          ?.toString()
          ?.trim();

      status = (apiData?['status'] ?? args['status'])?.toString()?.trim();

      timestamp =
          (apiData?['timestamp'] ??
                  apiData?['createdAt'] ??
                  apiData?['date'] ??
                  apiData?['transactionDate'] ??
                  args['timestamp'])
              ?.toString()
              ?.trim();

      if (apiData != null && apiData!['balance'] != null) {
        balance = (apiData!['balance'] as num).toDouble();
      } else if (args['balance'] != null) {
        balance = (args['balance'] as num).toDouble();
      }

      paymentMethod =
          (apiData?['paymentMethod'] ??
                  apiData?['fromProductId'] ??
                  args['paymentMethod'])
              ?.toString()
              ?.trim();

      paymentSource =
          (apiData?['paymentSource'] ??
                  apiData?['paymentMode'] ??
                  args['paymentSource'])
              ?.toString()
              ?.trim();

      senderUpi = (apiData?['senderUpi'] ?? args['senderUpi'])
          ?.toString()
          ?.trim();
    }
  }

  bool get isFailed {
    if (status == null) return false;
    final s = status!.toUpperCase();
    return s == 'FAILED' || s == 'FAILURE' || s == 'PAYMENT_FAILED';
  }

  bool get isPending {
    if (status == null) return false;
    final s = status!.toUpperCase();
    return s == 'PENDING' || s == 'PROCESSING';
  }

  String get statusTitle {
    if (isFailed) return "Money Transfer Failed";
    if (isPending) return "Money Transfer Pending";
    return "Money Sent Successfully";
  }

  String get recipientDisplayName {
    final rawName = recipient?['name']?.trim();
    if (rawName != null &&
        rawName.isNotEmpty &&
        rawName != 'null' &&
        rawName.toLowerCase() != 'recipient') {
      return rawName;
    }

    final toMobile =
        apiData?['toMobileNumber']?.toString().trim() ??
        recipient?['phone']?.trim();
    if (toMobile != null && toMobile.isNotEmpty && toMobile != 'null') {
      final digits = toMobile.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 10) {
        return "+91 ${digits.substring(digits.length - 10)}";
      }
      return toMobile;
    }

    final toEntity = apiData?['toEntityId']?.toString().trim();
    if (toEntity != null && toEntity.isNotEmpty && toEntity != 'null') {
      return toEntity;
    }

    return '';
  }

  String? _resolveCreditedTo() {
    final apiToMobile = apiData?['toMobileNumber']?.toString().trim();
    final apiToEntity = apiData?['toEntityId']?.toString().trim();
    final recipientName = recipient?['name']?.trim();
    final recipientPhone = recipient?['phone']?.trim();
    final recipientAccount =
        (recipient?['accountNumber'] ??
                recipient?['account_number'] ??
                recipient?['accountNo'])
            ?.trim();

    final phone =
        (apiToMobile != null && apiToMobile.isNotEmpty && apiToMobile != 'null')
        ? apiToMobile
        : recipientPhone;

    // Account Number case
    if (recipientAccount != null &&
        recipientAccount.isNotEmpty &&
        recipientAccount != 'null') {
      final clean = recipientAccount.replaceAll(RegExp(r'\s+'), '');
      final masked = clean.length > 4
          ? "A/c •••• ${clean.substring(clean.length - 4)}"
          : "A/c $clean";
      if (recipientName != null &&
          recipientName.isNotEmpty &&
          recipientName != 'null') {
        return "$recipientName ($masked)";
      }
      return masked;
    }

    // Phone & Name case
    if (phone != null && phone.isNotEmpty && phone != 'null') {
      final digits = phone.replaceAll(RegExp(r'\D'), '');
      final formattedPhone = digits.length >= 10
          ? "+91 ${digits.substring(digits.length - 10)}"
          : phone;

      if (recipientName != null &&
          recipientName.isNotEmpty &&
          recipientName != 'null' &&
          recipientName.toLowerCase() != 'recipient') {
        return "$recipientName ($formattedPhone)";
      }
      return formattedPhone;
    }

    // Name only
    if (recipientName != null &&
        recipientName.isNotEmpty &&
        recipientName != 'null' &&
        recipientName.toLowerCase() != 'recipient') {
      return recipientName;
    }

    // Entity ID from API
    if (apiToEntity != null &&
        apiToEntity.isNotEmpty &&
        apiToEntity != 'null') {
      return apiToEntity;
    }

    return null;
  }

  String? _resolveDebitedFrom() {
    final fromProductId = apiData?['fromProductId']?.toString().trim();
    final fromEntityId = apiData?['fromEntityId']?.toString().trim();

    if (fromProductId != null &&
        fromProductId.isNotEmpty &&
        fromProductId != 'null') {
      if (fromProductId.toUpperCase() == 'GENERAL') {
        return 'Transcorp Wallet';
      }
      return fromProductId;
    }

    if (paymentSource != null &&
        paymentSource!.isNotEmpty &&
        paymentSource != 'null') {
      return paymentSource!;
    }

    if (paymentMethod != null &&
        paymentMethod!.isNotEmpty &&
        paymentMethod != 'null') {
      if (paymentMethod!.toUpperCase() == 'WALLET' ||
          paymentMethod!.toUpperCase() == 'C2C') {
        return 'Transcorp Wallet';
      }
      return paymentMethod!;
    }

    if (senderUpi != null && senderUpi!.isNotEmpty && senderUpi != 'null') {
      return senderUpi!;
    }

    if (fromEntityId != null &&
        fromEntityId.isNotEmpty &&
        fromEntityId != 'null') {
      return fromEntityId;
    }

    return null;
  }

  String? _resolveFormattedDate() {
    if (timestamp != null && timestamp!.isNotEmpty && timestamp != 'null') {
      try {
        DateTime parsed;
        if (RegExp(r'^\d+$').hasMatch(timestamp!)) {
          final ms = int.parse(timestamp!);
          parsed = DateTime.fromMillisecondsSinceEpoch(ms);
        } else {
          parsed = DateTime.parse(timestamp!);
        }
        return DateFormat('dd MMM yyyy, hh:mm a').format(parsed.toLocal());
      } catch (_) {
        return timestamp;
      }
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
  }

  /// Dynamically build receipt rows containing ONLY valid data present from API or transaction
  List<ReceiptDetailItem> get receiptDetails {
    final List<ReceiptDetailItem> items = [];

    // 1. Reference ID (from API providerRef / referenceId)
    if (providerRef != null &&
        providerRef!.isNotEmpty &&
        providerRef != 'null' &&
        providerRef != '{}') {
      items.add(
        ReceiptDetailItem(
          label: "Reference ID",
          value: providerRef!,
          imageAsset: "assets/referenceid.png",
          isCopyable: true,
        ),
      );
    }

    // 2. Transaction ID (from API externalTransactionId)
    if (externalTransactionId != null &&
        externalTransactionId!.isNotEmpty &&
        externalTransactionId != 'null' &&
        externalTransactionId != '{}' &&
        externalTransactionId != providerRef) {
      items.add(
        ReceiptDetailItem(
          label: "Transaction ID",
          value: externalTransactionId!,
          imageAsset: "assets/referenceid.png",
          isCopyable: true,
        ),
      );
    }

    // 3. Credited To (from API toMobileNumber / toEntityId or recipient)
    final creditedTo = _resolveCreditedTo();
    if (creditedTo != null && creditedTo.isNotEmpty) {
      items.add(
        ReceiptDetailItem(
          label: "Credited To",
          value: creditedTo,
          imageAsset: "assets/moneysent.png",
        ),
      );
    }

    // 4. Debited From (from API fromProductId / fromEntityId / paymentSource)
    final debitedFrom = _resolveDebitedFrom();
    if (debitedFrom != null && debitedFrom.isNotEmpty) {
      items.add(
        ReceiptDetailItem(
          label: "Debited From",
          value: debitedFrom,
          imageAsset: "assets/moneysent.png",
        ),
      );
    }

    // // 5. Transfer Type (from API transactionType)
    // if (transactionType != null &&
    //     transactionType!.isNotEmpty &&
    //     transactionType != 'null') {
    //   final String typeDisplay = transactionType!.toUpperCase() == 'C2C'
    //       ? 'Wallet to Wallet (C2C)'
    //       : transactionType!;
    //   items.add(
    //     ReceiptDetailItem(
    //       label: "Transfer Type",
    //       value: typeDisplay,
    //       icon: Icons.swap_horiz_rounded,
    //     ),
    //   );
    // }

    // 6. Status (from API status)
    if (status != null && status!.isNotEmpty && status != 'null') {
      final String statusDisplay =
          (status!.toUpperCase() == 'PAYMENT_SUCCESS' ||
              status!.toUpperCase() == 'SUCCESS')
          ? 'Successful'
          : status!;
      items.add(
        ReceiptDetailItem(
          label: "Transfer Status",
          value: statusDisplay,
          icon: Icons.check_circle_outline_rounded,
        ),
      );
    }

    // 7. Date & Time (from API timestamp / createdAt / date)
    final formattedDate = _resolveFormattedDate();
    if (formattedDate != null && formattedDate.isNotEmpty) {
      items.add(
        ReceiptDetailItem(
          label: "Date & Time",
          value: formattedDate,
          imageAsset: "assets/datetime.png",
        ),
      );
    }

    // 8. Description / Note (from API description / narration / note)
    if (note.isNotEmpty &&
        note != 'null' &&
        note.toLowerCase() != 'customer to customer transfer') {
      items.add(
        ReceiptDetailItem(
          label: "Note",
          value: note,
          icon: Icons.notes_rounded,
        ),
      );
    }

    return items;
  }

  String get paymentMethodTitle => "Payment Using";
  String get paymentMethodDetail => _resolveDebitedFrom() ?? "Transcorp Wallet";
  String get paymentMethodAsset => "assets/moneysent.png";
  String get creditedToDetail => _resolveCreditedTo() ?? "Recipient";
}
