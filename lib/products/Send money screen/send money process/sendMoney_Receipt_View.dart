import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendMoney_Receipt_Controller.dart';
import 'package:transwallet/widgets/custombutton.dart';

class SendMoneyReceiptView extends GetView<SendMoneyReceiptController> {
  const SendMoneyReceiptView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SendMoneyReceiptController>()) {
      Get.put(SendMoneyReceiptController());
    }

    final amountStr = controller.amount % 1 == 0
        ? controller.amount.toInt().toString()
        : controller.amount.toStringAsFixed(2);

    final details = controller.receiptDetails;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: context.responsive(20)),

              // Status Icon (Success / Failed / Pending)
              Container(
                padding: EdgeInsets.all(context.responsive(18)),
                decoration: BoxDecoration(
                  color: controller.isFailed
                      ? const Color(0xFFC62828).withOpacity(0.15)
                      : (controller.isPending
                          ? const Color(0xFFF57C00).withOpacity(0.15)
                          : const Color(0xFF2ECA71).withOpacity(0.15)),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: EdgeInsets.all(context.responsive(10)),
                  decoration: BoxDecoration(
                    color: controller.isFailed
                        ? const Color(0xFFC62828)
                        : (controller.isPending
                            ? const Color(0xFFF57C00)
                            : const Color(0xFF2ECA71)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    controller.isFailed
                        ? Icons.close_rounded
                        : (controller.isPending
                            ? Icons.hourglass_bottom_rounded
                            : Icons.check_rounded),
                    color: Colors.white,
                    size: context.responsive(40),
                  ),
                ),
              ),

              SizedBox(height: context.responsive(20)),

              Text(
                controller.statusTitle,
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

              if (controller.recipientDisplayName.isNotEmpty) ...[
                SizedBox(height: context.responsive(8)),
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(246, 246, 246, 1),
                    borderRadius: BorderRadius.circular(context.responsive(20)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive(10),
                      vertical: context.responsive(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(context.responsive(2)),
                          decoration: BoxDecoration(
                            color: controller.isFailed
                                ? const Color(0xFFC62828)
                                : const Color(0xFF2ECA71),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            controller.isFailed ? Icons.close : Icons.check,
                            color: Colors.white,
                            size: context.responsive(12),
                          ),
                        ),
                        SizedBox(width: context.responsive(6)),
                        Text(
                          "Sent to ${controller.recipientDisplayName}",
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
              ],

              // Details Card: Renders ONLY data returned by API
              if (details.isNotEmpty) ...[
                SizedBox(height: context.responsive(36)),
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
                      borderRadius:
                          BorderRadius.circular(context.responsive(16)),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < details.length; i++) ...[
                          if (details[i].isCopyable)
                            _buildReferenceRow(
                              context,
                              details[i].label,
                              details[i].value,
                              imageAsset: details[i].imageAsset ??
                                  "assets/referenceid.png",
                            )
                          else
                            _buildIconRow(
                              context,
                              details[i].label,
                              details[i].value,
                              imageAsset: details[i].imageAsset,
                              icon: details[i].icon,
                            ),
                          if (i < details.length - 1)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: context.responsive(16),
                              ),
                              child: const Divider(
                                color: Color(0xFFF0F0F0),
                                height: 1,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              SizedBox(height: context.responsive(32)),

              // Action button
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(24),
                ),
                child: CustomButton(
                  text: "Back to Transactions",
                  btncolor: Colors.black,
                  textColor: Colors.white,
                  height: context.responsive(54),
                  textsize: context.responsive(14),
                  borderRadius: context.responsive(50),
                  onPressed: () => Get.back(),
                ),
              ),

              SizedBox(
                height: context.responsive(20) +
                    MediaQuery.of(context).padding.bottom,
              ),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: context.responsive(12),
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
              "$label copied to clipboard",
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.black87,
              colorText: Colors.white,
              margin: EdgeInsets.all(context.responsive(16)),
              duration: const Duration(seconds: 2),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Icon(
              Icons.copy,
              size: context.responsive(16),
              color: Colors.grey,
            ),
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
                  size: context.responsive(20),
                  color: Colors.black87,
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
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: context.responsive(13),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
