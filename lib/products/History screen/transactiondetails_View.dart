import 'package:flutter/material.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/custombutton.dart';

class TransactiondetailsView extends StatelessWidget {
  const TransactiondetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = Get.arguments ?? {};
    final tx = args["tx"] ?? {};

    final String name = tx["name"]?.toString() ?? "Payment Reference";
    final String date = tx["date"]?.toString() ?? "Today";
    final double amountValue = (tx["amount"] as num?)?.toDouble().abs() ?? 0.0;

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

    final String refId = "asd${tx.hashCode.abs()}-fd11-4f8d-9d9dfget5sd55sd";

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
                    _buildDetailRow(
                      context,
                      imageAsset: "assets/referenceid.png",
                      label: "Reference ID",
                      value: refId,
                      isRefId: true,
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey.shade100,
                      thickness: 1,
                    ),
                    _buildDetailRow(
                      context,
                      imageAsset: "assets/datetime.png",
                      label: "Date & Time",
                      value: date,
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey.shade100,
                      thickness: 1,
                    ),
                    _buildDetailRow(
                      context,
                      imageAsset: "assets/moneysent.png",
                      label: "Payment Source",
                      value: "Transcorp Wallet",
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey.shade100,
                      thickness: 1,
                    ),
                    _buildDetailRow(
                      context,
                      imageAsset: "assets/transactiontype.png",
                      label: "Transaction Type",
                      value: isCredit ? "Income Received" : "Money Spent",
                    ),
                    Divider(
                      height: 1,
                      color: Colors.grey.shade100,
                      thickness: 1,
                    ),
                    _buildDetailRow(
                      context,
                      imageAsset: "assets/standardfee.png",
                      label: "Standard Fee",
                      value: "-₹ 0.00",
                    ),

                    // Total Settled Footer
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive(20),
                        vertical: context.responsive(16),
                      ),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: primaryYellow.withOpacity(0.3),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Settled",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: context.responsive(14),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                "₹ ${amountValue.toStringAsFixed(2)}",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: context.responsive(14),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.responsive(32)),

              // Actions
              CustomButton(
                text: "Share Receipt",
                btncolor: Colors.black,
                textColor: Colors.white,
                prefixIcon: const Icon(
                  Icons.ios_share_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                borderRadius: 50,
                onPressed: () async {
                  final String text = '''
================================
   TRANSWALLET TRANSACTION  
================================
Title         : $name
Amount        : ${isCredit ? '+' : '-'}₹${amountValue.toStringAsFixed(2)}
Status        : $statusText
Txn Reference : $refId
Date & Time   : $date
Payment Source: Transcorp Wallet
================================
Thank you for using Transwallet!
'''.trim();
                  Clipboard.setData(ClipboardData(text: text));
                  HapticFeedback.lightImpact();
                  try {
                    await Share.share(text, subject: 'Transwallet Transaction Details');
                  } catch (_) {
                    Get.snackbar(
                      "Receipt Copied",
                      "Transaction details copied to clipboard!",
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.black87,
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(16),
                    );
                  }
                },
              ),
              SizedBox(height: context.responsive(16)),
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: context.responsive(16),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.responsive(50)),
                    border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Back to Transactions",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: context.responsive(14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required String imageAsset,
    required String label,
    required String value,
    bool isRefId = false,
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
            child: Image.asset(
              imageAsset,
              height: context.responsive(20),
              width: context.responsive(20),
              fit: BoxFit.contain,
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
                                color: Colors.black,
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
                            "Reference ID copied to clipboard",
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
                            color: Colors.black,
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
