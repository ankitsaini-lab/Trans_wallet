import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/notification_button.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendmoneyProcess_Controller.dart';
import 'package:transwallet/widgets/custombutton.dart';

class SendmoneyprocessView extends GetView<SendmoneyprocessController> {
  const SendmoneyprocessView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SendmoneyprocessController>()) {
      Get.put(SendmoneyprocessController());
    }

    final recipient = controller.recipient;
    final String name = recipient?['name']?.trim().isNotEmpty == true
        ? recipient!['name']!
        : 'Recipient';
    final String phone = recipient?['phone']?.trim() ?? '';
    final String avatar = recipient?['avatar']?.trim().isNotEmpty == true
        ? recipient!['avatar']!
        : (name.isNotEmpty && name != 'Recipient'
              ? name[0].toUpperCase()
              : 'C2C');

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        title: Text(
          "Send Money",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: context.responsive(20),
            letterSpacing: 0,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: context.responsive(18)),
            child: const Center(child: NotificationButton()),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: context.responsive(16)),

                      // Dynamic Recipient Card
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive(20),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(context.responsive(12)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              context.responsive(16),
                            ),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: context.responsive(21),
                                backgroundColor: primaryYellow.withValues(
                                  alpha: 0.2,
                                ),
                                child: Text(
                                  avatar,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontSize: context.responsive(14),
                                  ),
                                ),
                              ),
                              SizedBox(width: context.responsive(12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: context.responsive(14),
                                      ),
                                    ),
                                    if (phone.isNotEmpty) ...[
                                      SizedBox(height: context.responsive(2)),
                                      Text(
                                        phone,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: context.responsive(12),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(context.responsive(8)),
                                decoration: BoxDecoration(
                                  color: primaryYellow.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: SvgPicture.asset(
                                  "assets/reicon_bank.svg",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: context.responsive(14)),

                      Text(
                        "ENTER AMOUNT",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: context.responsive(12),
                        ),
                      ),

                      SizedBox(height: context.responsive(4)),

                      Obx(() {
                        final amountStr = controller.enteredAmount.value.isEmpty
                            ? "0"
                            : controller.enteredAmount.value;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: context.responsive(8),
                              ),
                              child: Text(
                                "₹",
                                style: TextStyle(
                                  fontSize: context.responsive(22),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            SizedBox(width: context.responsive(6)),
                            Text(
                              amountStr,
                              style: TextStyle(
                                fontSize: context.responsive(44),
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        );
                      }),

                      SizedBox(height: context.responsive(6)),

                      // Limit indicator / validation message
                      Obx(() {
                        final currentAmount = controller.amount;
                        final bool hasInput =
                            controller.enteredAmount.value.isNotEmpty;
                        final bool exceedsMax =
                            currentAmount >
                            SendmoneyprocessController.maxTransferAmount;
                        final bool belowMin =
                            hasInput &&
                            currentAmount <
                                SendmoneyprocessController.minTransferAmount;

                        if (exceedsMax) {
                          return Padding(
                            padding: EdgeInsets.only(
                              top: context.responsive(2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: context.responsive(14),
                                  color: primaryRed,
                                ),
                                SizedBox(width: context.responsive(4)),
                                Text(
                                  "Max limit ₹10,000 per transaction",
                                  style: TextStyle(
                                    color: primaryRed,
                                    fontSize: context.responsive(12),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (belowMin) {
                          return Padding(
                            padding: EdgeInsets.only(
                              top: context.responsive(2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: context.responsive(14),
                                  color: primaryRed,
                                ),
                                SizedBox(width: context.responsive(4)),
                                Text(
                                  "Min transfer amount is ₹1",
                                  style: TextStyle(
                                    color: primaryRed,
                                    fontSize: context.responsive(12),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Padding(
                          padding: EdgeInsets.only(top: context.responsive(2)),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.responsive(10),
                              vertical: context.responsive(4),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(
                                context.responsive(12),
                              ),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              "Min ₹1 • Max ₹10,000",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: context.responsive(11),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        );
                      }),

                      SizedBox(height: context.responsive(12)),

                      // Dynamic Presets
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: controller.presets.map((preset) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.responsive(4),
                              ),
                              child: _presetPill(context, preset, "₹$preset"),
                            );
                          }).toList(),
                        ),
                      ),

                      SizedBox(height: context.responsive(12)),

                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive(40),
                        ),
                        child: Container(
                          height: context.responsive(45),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              context.responsive(25),
                            ),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            controller: controller.noteController,
                            textAlign: TextAlign.center,
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) =>
                                FocusManager.instance.primaryFocus?.unfocus(),
                            scrollPadding: EdgeInsets.zero,
                            style: TextStyle(fontSize: context.responsive(14)),
                            decoration: InputDecoration(
                              hintText: "Add a note (optional)",
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: context.responsive(13),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: context.responsive(12)),
                    ],
                  ),
                ),
              ),

              // Responsive Dynamic Keypad
              _buildResponsiveKeypad(context),

              SizedBox(height: context.responsive(16)),

              // Send Button
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(20),
                  vertical: context.responsive(14),
                ),
                child: Obx(() {
                  final canSend = controller.canProceed;
                  return CustomButton(
                    text: "Send",
                    btncolor: canSend ? primaryRed : Colors.grey.shade300,
                    textColor: canSend ? Colors.black : Colors.grey.shade600,
                    textsize: context.responsive(14),
                    borderRadius: context.responsive(24),
                    onPressed: canSend
                        ? () => controller.proceedToPassword()
                        : () {},
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetPill(BuildContext context, int value, String label) {
    return Obx(() {
      final isSelected = controller.selectedPreset.value == value;
      return GestureDetector(
        onTap: () => controller.setPreset(value),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive(14),
            vertical: context.responsive(8),
          ),
          decoration: BoxDecoration(
            color: isSelected ? primaryLightYellow : Colors.white,
            borderRadius: BorderRadius.circular(context.responsive(20)),
            border: Border.all(
              color: isSelected ? primaryYellow : Colors.grey.shade200,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: context.responsive(13),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildResponsiveKeypad(BuildContext context) {
    const keypadKeys = [
      ["1", "2", "3"],
      ["4", "5", "6"],
      ["7", "8", "9"],
      [".", "0", "back"],
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.responsive(30)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: keypadKeys.map((row) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: context.responsive(4)),
            child: Row(
              children: row.map((key) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive(4),
                    ),
                    child: _keypadButton(context, key, isIcon: key == "back"),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _keypadButton(
    BuildContext context,
    String value, {
    bool isIcon = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (value == '.') return;
        controller.setAmount(value);
      },
      child: Container(
        height: context.responsive(48),
        alignment: Alignment.center,
        child: isIcon
            ? Icon(
                Icons.backspace_outlined,
                size: context.responsive(22),
                color: Colors.black,
              )
            : Text(
                value,
                style: TextStyle(
                  fontSize: context.responsive(22),
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
      ),
    );
  }
}
