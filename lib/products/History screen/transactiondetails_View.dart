import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/utilities/string_extensions.dart';

class TransactiondetailsView extends StatelessWidget {
  const TransactiondetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments as Map)
        : {};
    final tx = args["tx"] is Map ? args["tx"] as Map : {};

    final String name = (tx["name"]?.toString() ?? "Payment Reference")
        .safeUtf16();
    final String date = (tx["date"]?.toString() ?? "Today").safeUtf16();
    // final double amountValue = (tx["amount"] as num?)?.toDouble().abs() ?? 0.0;
    final double amountValue =
        (double.tryParse(
                  tx["amount"]?.toString().replaceAll(
                        RegExp(r'[^0-9.-]'),
                        '',
                      ) ??
                      "0",
                ) ??
                0.0)
            .abs();
    log("sdf>> ${tx["amount"]}");
    bool isCredit = false;
    if (tx.containsKey("isCredit")) {
      isCredit = tx["isCredit"] == true;
    } else if (tx.containsKey("amount")) {
      isCredit = (tx["amount"] as num) > 0;
    }

    String status = "success";
    if (tx.containsKey("isFailed")) {
      status = (tx["isFailed"] == true) ? "failed" : "success";
    } else if (tx.containsKey("status")) {
      status = tx["status"]?.toString().toLowerCase() ?? "success";
    }

    Color statusColor;
    IconData statusIcon;
    String statusText;
    Color statusBgColor;

    Color mainCircleColor;
    IconData mainCircleIcon;

    if (status == "failed") {
      statusColor = const Color(0xFFC62828);
      statusIcon = Icons.cancel_rounded;
      statusText = "Failed";
      statusBgColor = const Color(0xFFFFEBEE);
      mainCircleColor = const Color(0xFFE53935);
      mainCircleIcon = Icons.close_rounded;
    } else if (status == "pending" || status == "processing") {
      statusColor = const Color(0xFFF57C00);
      statusIcon = Icons.watch_later_rounded;
      statusText = "Pending";
      statusBgColor = const Color(0xFFFFF3E0);
      mainCircleColor = const Color(0xFFFFB300);
      mainCircleIcon = Icons.hourglass_bottom_rounded;
    } else {
      statusColor = const Color(0xFF059669);
      statusIcon = Icons.check_circle_rounded;
      statusText = "Successful";
      statusBgColor = const Color(0xFF059669).withOpacity(0.1);
      mainCircleColor = const Color.fromARGB(226, 76, 175, 79);
      mainCircleIcon = Icons.check_rounded;
    }

    final rawItem = tx["rawItem"] is Map ? tx["rawItem"] as Map : {};

    // 1. Reference ID (use txRef key)
    final String refId =
        (tx["txRef"] ??
                rawItem["txRef"] ??
                tx["tx_ref"] ??
                rawItem["tx_ref"] ??
                "")
            .toString()
            .trim();
    final String displayRefId = refId.isNotEmpty
        ? refId
        : (tx["externalTransactionId"] ??
                  rawItem["externalTransactionId"] ??
                  "TXN-${tx.hashCode.abs()}")
              .toString()
              .trim();

    // 2. Transaction type
    final String rawTxnType = (tx["type"] ?? rawItem["type"] ?? "")
        .toString()
        .trim();
    final String displayTxnType = rawTxnType.isNotEmpty
        ? (rawTxnType.toUpperCase() == "CREDIT"
              ? "Credit"
              : (rawTxnType.toUpperCase() == "DEBIT" ? "Debit" : rawTxnType))
        : (isCredit ? "Credit" : "Debit");

    // 3. description
    final String rawDescription =
        (tx["description"] ??
                rawItem["description"] ??
                rawItem["narration"] ??
                rawItem["remarks"] ??
                "")
            .toString()
            .trim();
    final String displayDescription = rawDescription.isNotEmpty
        ? rawDescription
        : name;

    // 4. status
    final String displayStatus = statusText;

    // 5. credited to
    final String rawCreditedTo =
        (tx["yourWallet"] ??
                rawItem["yourWallet"] ??
                rawItem["yourWallet"] ??
                (isCredit
                    ? (tx["yourWallet"] != null &&
                              tx["yourWallet"].toString().isNotEmpty
                          ? "${tx["yourWallet"]} Wallet"
                          : "")
                    : (rawItem["otherPartyName"] ?? tx["name"] ?? "Recipient")))
            .toString()
            .trim();
    final String displayCreditedTo = rawCreditedTo.isNotEmpty
        ? (rawCreditedTo.toUpperCase().contains('FF01')
              ? 'NCMC Transit Wallet'
              : rawCreditedTo)
        : "";

    // 6. source
    final String rawSource =
        (tx["source"] ??
                rawItem["source"] ??
                tx["paymentSource"] ??
                rawItem["paymentSource"] ??
                (!isCredit
                    ? (tx["yourWallet"] != null &&
                              tx["yourWallet"].toString().isNotEmpty
                          ? "${tx["yourWallet"]} Wallet"
                          : "Transcorp Wallet")
                    : (rawItem["otherPartyName"] ?? "Bank / UPI")))
            .toString()
            .trim();
    final String displaySource = rawSource.isNotEmpty
        ? (rawSource.toUpperCase().contains('FF01')
              ? 'NCMC Transit Wallet'
              : rawSource)
        : "Transcorp Wallet";

    // 7. Date & time
    final String displayDate = date;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        elevation: 0,
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        title: Text(
          "Transactions Receipt",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: context.responsive(18),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive(24),
            vertical: context.responsive(32),
          ),
          child: Column(
            children: [
              // Concentric Status Circle
              Container(
                height: context.responsive(100),
                width: context.responsive(100),
                decoration: BoxDecoration(
                  color: mainCircleColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  height: context.responsive(76),
                  width: context.responsive(76),
                  decoration: BoxDecoration(
                    color: mainCircleColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    mainCircleIcon,
                    color: Colors.white,
                    size: context.responsive(44),
                  ),
                ),
              ),
              SizedBox(height: context.responsive(24)),

              // Name
              Text(
                name,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: context.responsive(22),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: context.responsive(8)),

              // Amount
              Text(
                "${isCredit ? '+' : '-'}₹ ${amountValue.toStringAsFixed(2)}",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: context.responsive(32),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: context.responsive(12)),

              // Status Pill
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(14),
                  vertical: context.responsive(6),
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: statusColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      color: statusColor,
                      size: context.responsive(14),
                    ),
                    SizedBox(width: context.responsive(6)),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: context.responsive(12),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.responsive(32)), // Details Receipt Card
              Container(
                padding: EdgeInsets.symmetric(vertical: context.responsive(8)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade100, width: 1.5),
                ),
                child: Column(
                  children: [
                    // 1. Reference ID (use txRef key)
                    _buildDetailRow(
                      context,
                      imageAsset: "assets/trans_rerence.svg",
                      label: "Reference ID",
                      value: displayRefId,
                      isRefId: true,
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey.shade100,
                      thickness: 1,
                    ),

                    // 2. Transaction type
                    _buildDetailRow(
                      context,
                      imageAsset: "assets/receipt_transactiontype.svg",
                      label: "Transaction Type",
                      value: displayTxnType,
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey.shade100,
                      thickness: 1,
                    ),

                    // 3. description
                    _buildDetailRow(
                      context,
                      imageAsset: "assets/receipt_description.svg",
                      label: "Description",
                      value: displayDescription,
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey.shade100,
                      thickness: 1,
                    ),

                    // 4. status
                    _buildDetailRow(
                      context,
                      imageAsset: "assets/receipt_status.svg",
                      label: "Status",
                      value: displayStatus,
                      valueColor: statusColor,
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey.shade100,
                      thickness: 1,
                    ),

                    // 5. credited to
                    // _buildDetailRow(
                    //   context,
                    //   imageAsset: "assets/receipt_creditedto.svg",
                    //   label: "Credited To",
                    //   value: displayCreditedTo,
                    // ),
                    // Divider(
                    //   height: 1,
                    //   color: Colors.grey.shade100,
                    //   thickness: 1,
                    // ),

                    // 6. source
                    _buildDetailRow(
                      context,
                      imageAsset: "assets/receipt_source.svg",
                      label: "Source",
                      value: displaySource,
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey.shade100,
                      thickness: 1,
                    ),

                    // 7. Date & time
                    _buildDetailRow(
                      context,
                      imageAsset: "assets/recipt_datetime.svg",
                      label: "Date & Time",
                      value: displayDate,
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.responsive(32)),

              // Actions
              CustomButton(
                text: "Back to Transactions",
                btncolor: Colors.black,
                textColor: Colors.white,
                textsize: context.responsive(14),
                borderRadius: 50,
                onPressed: () => Get.back(),
              ),
              SizedBox(
                height:
                    context.responsive(24) +
                    MediaQuery.of(context).padding.bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    String? imageAsset,
    IconData? icon,
    required String label,
    required String value,
    bool isRefId = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive(16),
        vertical: context.responsive(12),
      ),
      child: Row(
        crossAxisAlignment: isRefId
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(context.responsive(6)),
            decoration: BoxDecoration(
              color: lightprimaryred,
              shape: BoxShape.circle,
              border: Border.all(color: primaryYellow, width: 1.5),
            ),
            child: imageAsset != null
                ? SvgPicture.asset(
                    imageAsset,
                    height: context.responsive(20),
                    width: context.responsive(20),
                    fit: BoxFit.contain,
                  )
                : Icon(
                    icon ?? Icons.info_outline_rounded,
                    size: context.responsive(20),
                    color: valueColor ?? Colors.black87,
                  ),
          ),
          SizedBox(width: context.responsive(12)),
          Expanded(
            child: isRefId
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: context.responsive(12),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              value,
                              style: TextStyle(
                                color: valueColor ?? Colors.black,
                                fontSize: context.responsive(13),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: context.responsive(8)),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: value));
                          Get.snackbar(
                            "Copied",
                            "$label copied to clipboard",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.black87,
                            colorText: Colors.white,
                            margin: const EdgeInsets.all(16),
                            duration: const Duration(seconds: 2),
                          );
                        },
                        child: Icon(
                          Icons.copy_rounded,
                          size: context.responsive(18),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: context.responsive(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: context.responsive(12)),
                      Flexible(
                        child: Text(
                          value,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: valueColor ?? Colors.black,
                            fontSize: context.responsive(14),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
