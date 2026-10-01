import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendMoney_Receipt_Controller.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:transwallet/widgets/custombutton.dart';

class SendMoneyReceiptView extends GetView<SendMoneyReceiptController> {
  const SendMoneyReceiptView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => SendMoneyReceiptController());
    const Color primaryYellow = Color(0xFFFFEA66);

    // Fallback recipient if arguments not passed
    final recipientName = controller.recipient?['name'] ?? 'Ankit Saini';
    final amountStr = controller.amount.toStringAsFixed(0);
    final formattedDate = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      // appBar: AppBar(
      //   flexibleSpace: Container(
      //     decoration: const BoxDecoration(gradient: appBarGradient),
      //   ),
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   surfaceTintColor: Colors.transparent,
      //   leadingWidth: context.responsive(60),
      //   leading: const AppBarBackButton(),
      // ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: context.responsive(20)),

              // Checkmark Icon
              Container(
                padding: EdgeInsets.all(context.responsive(18)),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECA71).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: EdgeInsets.all(context.responsive(10)),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2ECA71),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: context.responsive(40),
                  ),
                ),
              ),

              SizedBox(height: context.responsive(20)),

              Text(
                "Money Sent Successfully",
                style: TextStyle(
                  fontSize: context.responsive(20),
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: context.responsive(12)),

              Text(
                "₹ $amountStr",
                style: TextStyle(
                  fontSize: context.responsive(32),
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),

              SizedBox(height: context.responsive(8)),

              Container(
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(246, 246, 246, 1),
                  borderRadius: BorderRadius.circular(context.responsive(20)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsive(7),
                    vertical: context.responsive(3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(context.responsive(2)),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2ECA71),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: context.responsive(12),
                        ),
                      ),
                      SizedBox(width: context.responsive(6)),
                      Text(
                        "Sent to $recipientName",
                        style: TextStyle(
                          fontSize: context.responsive(12),
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: context.responsive(40)),

              // Details Card
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(24),
                ),
                child: Container(
                  padding: EdgeInsets.all(context.responsive(20)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: context.responsive(4),
                        offset: const Offset(0, 2),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(context.responsive(16)),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildReferenceRow(
                        context,
                        "Reference ID",
                        "asd65585-fd11-4f8d-9d9dfgd5ed55ed",
                        imageAsset: "assets/referenceid.png",
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: context.responsive(16),
                        ),
                        child: const Divider(
                          color: Color(0xFFF0F0F0),
                          height: 1,
                        ),
                      ),
                      _buildIconRow(
                        context,
                        "Credited To",
                        "General Wallet",
                        imageAsset: "assets/moneysent.png",
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: context.responsive(16),
                        ),
                        child: const Divider(
                          color: Color(0xFFF0F0F0),
                          height: 1,
                        ),
                      ),
                      _buildIconRow(
                        context,
                        "Payment Using\nUPI",
                        "ankit@upi",
                        imageAsset: "assets/bxl_upi.png",
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: context.responsive(16),
                        ),
                        child: const Divider(
                          color: Color(0xFFF0F0F0),
                          height: 1,
                        ),
                      ),
                      _buildIconRow(
                        context,
                        "Date & Time",
                        formattedDate,
                        imageAsset: "assets/datetime.png",
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: context.responsive(32)),

              // Actions
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(24),
                ),
                child: Column(
                  children: [
                    CustomButton(
                      text: "Share Receipt",
                      btncolor: Colors.black,
                      textColor: Colors.white,
                      height: context.responsive(54),
                      textsize: context.responsive(16),
                      prefixIcon: Icon(
                        Icons.ios_share_outlined,
                        color: Colors.white,
                        size: context.responsive(20),
                      ),
                      borderRadius: context.responsive(50),
                      onPressed: () async {
                        final String text =
                            '''
================================
   TRANSWALLET PAYMENT RECEIPT  
================================
Recipient     : $recipientName
Amount        : ₹$amountStr
Date & Time   : $formattedDate
Status        : Success
================================
Thank you for using Transwallet!
'''
                                .trim();
                        Clipboard.setData(ClipboardData(text: text));
                        HapticFeedback.lightImpact();
                        final marginPadding = EdgeInsets.all(
                          context.responsive(16),
                        );
                        try {
                          await Share.share(
                            text,
                            subject: 'Transwallet Payment Receipt',
                          );
                        } catch (_) {
                          Get.snackbar(
                            "Receipt Copied",
                            "Receipt details copied to clipboard!",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.black87,
                            colorText: Colors.white,
                            margin: marginPadding,
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
                          borderRadius: BorderRadius.circular(
                            context.responsive(50),
                          ),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
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

              SizedBox(height: context.responsive(18)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceRow(
    BuildContext context,
    String label,
    String value, {
    String imageAsset = "assets/referenceid.png",
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.responsive(8)),
          decoration: BoxDecoration(
            color: primaryLightYellow,
            border: Border.all(color: primaryYellow),
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            imageAsset,
            height: context.responsive(24),
            width: context.responsive(24),
            fit: BoxFit.contain,
          ),
        ),
        SizedBox(width: context.responsive(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: context.responsive(12),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: context.responsive(2)),
              Text(
                value,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: context.responsive(11),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            Get.snackbar(
              "Copied",
              "Reference ID copied to clipboard",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.black87,
              colorText: Colors.white,
              margin: EdgeInsets.all(context.responsive(16)),
              duration: const Duration(seconds: 2),
            );
          },
          child: Icon(
            Icons.copy,
            size: context.responsive(16),
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildIconRow(
    BuildContext context,
    String label,
    String value, {
    String? imageAsset,
    IconData? icon,
    Color iconColor = primaryLightYellow,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.responsive(8)),
          decoration: BoxDecoration(
            color: iconColor,
            border: Border.all(color: primaryYellow),
            shape: BoxShape.circle,
          ),
          child: imageAsset != null
              ? Image.asset(
                  imageAsset,
                  height: context.responsive(24),
                  width: context.responsive(24),
                  fit: BoxFit.contain,
                )
              : Icon(
                  icon ?? Icons.circle,
                  size: context.responsive(18),
                  color: Colors.black,
                ),
        ),
        SizedBox(width: context.responsive(12)),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: context.responsive(12),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: context.responsive(13),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
