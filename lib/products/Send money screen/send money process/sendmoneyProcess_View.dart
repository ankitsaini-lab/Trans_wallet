import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/notification_button.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendmoneyProcess_Controller.dart';
import 'package:transwallet/widgets/custom_numeric_keypad.dart';
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

    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.white,
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
                      SizedBox(height: context.responsive(12)),

                      // 1. Dynamic Recipient Card
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive(20),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsive(14),
                            vertical: context.responsive(10),
                          ),
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
                                radius: context.responsive(20),
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
                                        fontSize: context.responsive(14.5),
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
                                padding: EdgeInsets.all(context.responsive(7)),
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

                      // 2. ENTER AMOUNT Header
                      Text(
                        "ENTER AMOUNT",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          fontSize: context.responsive(11),
                        ),
                      ),

                      SizedBox(height: context.responsive(4)),

                      // 3. Amount Display
                      Obx(() {
                        final amountStr = controller.enteredAmount.value.isEmpty
                            ? "0"
                            : controller.enteredAmount.value;
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsive(20),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: context.responsive(4),
                                  ),
                                  child: Text(
                                    "₹",
                                    style: TextStyle(
                                      fontSize: context.responsive(24),
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                SizedBox(width: context.responsive(4)),
                                Text(
                                  amountStr,
                                  style: TextStyle(
                                    fontSize: context.responsive(44),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                      SizedBox(height: context.responsive(16)),

                      // 4. Dynamic Presets
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

                      // 6. Note Field
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive(20),
                        ),
                        child: Container(
                          height: context.responsive(42),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              context.responsive(21),
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
                            style: TextStyle(fontSize: context.responsive(13.5)),
                            decoration: InputDecoration(
                              hintText: "Add a note (optional)",
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: context.responsive(12.5),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              isCollapsed: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: context.responsive(10)),
                    ],
                  ),
                ),
              ),

              // 7. Responsive Numeric Keypad (Hidden while writing note on software keyboard)
              if (!isKeyboardOpen) ...[
                Center(
                  child: CustomNumericKeypad(
                    leftActionText: '.',
                    buttonSize: context.responsive(58).clamp(46.0, 68.0),
                    vGap: context.responsive(10).clamp(6.0, 16.0),
                    keypadWidth: context.responsive(260).clamp(230.0, 276.0),
                    onDigitTap: (val) => controller.setAmount(val),
                    onDeleteTap: () => controller.setAmount('back'),
                    onClear: () {
                      controller.enteredAmount.value = '';
                      controller.selectedPreset.value = 0;
                    },
                  ),
                ),
                SizedBox(height: context.responsive(10)),
              ],

              // 8. Send Button
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(20),
                  vertical: context.responsive(6),
                ),
                child: Obx(() {
                  final canSend = controller.canProceed;
                  return CustomButton(
                    text: "Send",
                    btncolor: canSend ? primaryRed : Colors.grey.shade300,
                    textColor: canSend ? Colors.black : Colors.grey.shade600,
                    textsize: context.responsive(14),
                    height: context.responsive(50),
                    borderRadius: context.responsive(25),
                    onPressed: canSend
                        ? () => controller.proceedToPassword()
                        : () {},
                  );
                }),
              ),

              SizedBox(height: context.responsive(8)),
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
        onTap: () {
          HapticFeedback.selectionClick();
          controller.setPreset(value);
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive(14),
            vertical: context.responsive(7),
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
}
