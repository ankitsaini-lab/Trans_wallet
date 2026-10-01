import 'package:flutter/material.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'addmoney_Controller.dart';
import 'package:transwallet/widgets/custombutton.dart';

class AddmoneyView extends StatelessWidget {
  final bool showGeneralWalletOption;
  const AddmoneyView({super.key, this.showGeneralWalletOption = false});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AddmoneyController());

    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(padding: EdgeInsets.only(top: Get.mediaQuery.padding.top)),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: appBarGradient),
          ),
          elevation: 0,
          leadingWidth: context.responsive(60),
          leading: const AppBarBackButton(),
          title: const Text(
            "Add Money",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
        ),
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
                        SizedBox(height: context.responsive(16)),

                        // Available Balance Card
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsive(20),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.responsive(16),
                              vertical: context.responsive(16),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                context.responsive(18),
                              ),
                              border: Border.all(
                                color: const Color(0xFFF0F0F0),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: context.responsive(16),
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: context.responsive(42),
                                  width: context.responsive(42),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF6EE),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFFD6C4),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: const Color(0xFF6B5850),
                                    size: context.responsive(18),
                                  ),
                                ),
                                SizedBox(width: context.responsive(12)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Available Balance",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                          fontSize: context.responsive(14),
                                        ),
                                      ),
                                      SizedBox(height: context.responsive(2)),
                                      Obx(
                                        () => Text(
                                          "₹${controller.balance.value.toStringAsFixed(2)}",
                                          style: TextStyle(
                                            color: const Color(0xFF8E8E93),
                                            fontSize: context.responsive(12),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: context.responsive(34)),

                        // ENTER AMOUNT text
                        Text(
                          "ENTER AMOUNT",
                          style: TextStyle(
                            color: const Color(0xFF9E9E9E),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            fontSize: context.responsive(11),
                          ),
                        ),

                        SizedBox(height: context.responsive(12)),

                        // Amount Display
                        Obx(() {
                          final amountStr =
                              controller.enteredAmount.value.isEmpty
                              ? "0"
                              : controller.formatAmount(
                                  controller.enteredAmount.value,
                                );
                          return Text(
                            "₹ $amountStr",
                            style: TextStyle(
                              fontSize: context.responsive(42),
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: Colors.black,
                            ),
                          );
                        }),

                        SizedBox(height: context.responsive(8)),

                        // Subtitle
                        Text(
                          "Minimum ₹1 · Maximum ₹1,00,000",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: context.responsive(11.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(height: context.responsive(28)),

                        // Presets
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsive(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _presetPill(
                                  context,
                                  controller,
                                  500,
                                  "₹500",
                                ),
                              ),
                              SizedBox(width: context.responsive(8)),
                              Expanded(
                                child: _presetPill(
                                  context,
                                  controller,
                                  1000,
                                  "₹1,000",
                                ),
                              ),
                              SizedBox(width: context.responsive(8)),
                              Expanded(
                                child: _presetPill(
                                  context,
                                  controller,
                                  2000,
                                  "₹2,000",
                                ),
                              ),
                              SizedBox(width: context.responsive(8)),
                              Expanded(
                                child: _presetPill(
                                  context,
                                  controller,
                                  5000,
                                  "₹5,000",
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Keypad
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsive(36),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _keypadButton(
                                      context,
                                      controller,
                                      "1",
                                    ),
                                  ),
                                  Expanded(
                                    child: _keypadButton(
                                      context,
                                      controller,
                                      "2",
                                    ),
                                  ),
                                  Expanded(
                                    child: _keypadButton(
                                      context,
                                      controller,
                                      "3",
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.responsive(16)),
                              Row(
                                children: [
                                  Expanded(
                                    child: _keypadButton(
                                      context,
                                      controller,
                                      "4",
                                    ),
                                  ),
                                  Expanded(
                                    child: _keypadButton(
                                      context,
                                      controller,
                                      "5",
                                    ),
                                  ),
                                  Expanded(
                                    child: _keypadButton(
                                      context,
                                      controller,
                                      "6",
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.responsive(16)),
                              Row(
                                children: [
                                  Expanded(
                                    child: _keypadButton(
                                      context,
                                      controller,
                                      "7",
                                    ),
                                  ),
                                  Expanded(
                                    child: _keypadButton(
                                      context,
                                      controller,
                                      "8",
                                    ),
                                  ),
                                  Expanded(
                                    child: _keypadButton(
                                      context,
                                      controller,
                                      "9",
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: context.responsive(16)),
                              Row(
                                children: [
                                  Expanded(
                                    child: _keypadButton(
                                      context,
                                      controller,
                                      ".",
                                    ),
                                  ),
                                  Expanded(
                                    child: _keypadButton(
                                      context,
                                      controller,
                                      "0",
                                    ),
                                  ),
                                  Expanded(
                                    child: _keypadButton(
                                      context,
                                      controller,
                                      "back",
                                      isIcon: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Submit Button
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsive(20),
                          ),
                          child: Obx(
                            () => CustomButton(
                              text: "Add Money",
                              btncolor: Colors.black,
                              textColor: Colors.white,
                              height: context.responsive(54),
                              textsize: context.responsive(16),
                              borderRadius: context.responsive(50),
                              onPressed: controller.amount > 0
                                  ? () => controller.payNow()
                                  : () {},
                            ),
                          ),
                        ),

                        SizedBox(height: context.responsive(20)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _presetPill(
    BuildContext context,
    AddmoneyController controller,
    int value,
    String label,
  ) {
    return Obx(() {
      final isSelected = controller.selectedPreset.value == value;
      return GestureDetector(
        onTap: () {
          controller.setPreset(value);
        },
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: context.responsive(9)),
          decoration: BoxDecoration(
            color: isSelected ? primaryRed : Colors.white,
            borderRadius: BorderRadius.circular(context.responsive(24)),
            border: Border.all(
              color: isSelected ? primaryRed : const Color(0xFFE5E7EB),
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: context.responsive(13.5),
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      );
    });
  }

  Widget _keypadButton(
    BuildContext context,
    AddmoneyController controller,
    String value, {
    bool isIcon = false,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (value == '.') return; // Ignore dot for now
        controller.setAmount(value);
      },
      child: Container(
        height: context.responsive(46),
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
                  fontSize: value == '.'
                      ? context.responsive(28)
                      : context.responsive(24),
                  fontWeight: value == '.' ? FontWeight.w900 : FontWeight.w700,
                  color: Colors.black,
                ),
              ),
      ),
    );
  }
}
