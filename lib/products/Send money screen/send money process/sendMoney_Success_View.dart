import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendMoney_Success_Controller.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:intl/intl.dart';

class SendMoneySuccessView extends GetView<SendMoneySuccessController> {
  const SendMoneySuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => SendMoneySuccessController());

    // Fallback recipient if arguments not passed
    final recipientName = controller.recipient?['name'] ?? 'Ankit Saini';
    final amountStr = controller.amount.toStringAsFixed(0);
    final formattedDate = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(DateTime.now());

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: context.responsive(20)),

                      // Checkmark Icon
                      Container(
                        padding: EdgeInsets.all(context.responsive(20)),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2ECA71).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          padding: EdgeInsets.all(context.responsive(12)),
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

                      SizedBox(height: context.responsive(32)),

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

                      Text(
                        "Sent to $recipientName",
                        style: TextStyle(
                          fontSize: context.responsive(14),
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
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
                            borderRadius: BorderRadius.circular(
                              context.responsive(16),
                            ),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              _buildRow(
                                context,
                                "Transaction ID",
                                "TXN4HK31L7G",
                              ),
                              SizedBox(height: context.responsive(16)),
                              _buildRow(context, "Date & Time", formattedDate),
                              SizedBox(height: context.responsive(16)),
                              _buildRow(context, "Total Debit", "₹$amountStr"),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Done Button
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive(24),
                        ),
                        child: CustomButton(
                          text: "Done",
                          btncolor: primaryRed,
                          textColor: Colors.black,
                          height: context.responsive(54),
                          textsize: context.responsive(16),
                          borderRadius: context.responsive(24),
                          onPressed: () => controller.goToDashboard(),
                        ),
                      ),

                      SizedBox(height: context.responsive(16)),

                      // View receipt
                      GestureDetector(
                        onTap: () => controller.viewReceipt(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: context.responsive(8),
                          ),
                          child: Text(
                            "View receipt",
                            style: TextStyle(
                              fontSize: context.responsive(15),
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: context.responsive(24)),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: context.responsive(13),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.black,
            fontSize: context.responsive(13),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
