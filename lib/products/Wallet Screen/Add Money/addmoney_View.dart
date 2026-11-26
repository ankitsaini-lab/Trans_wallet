import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/widgets/custom_numeric_keypad.dart';
import 'addmoney_Controller.dart';
import 'package:transwallet/widgets/custombutton.dart';

class AddmoneyView extends StatefulWidget {
  final bool showGeneralWalletOption;
  const AddmoneyView({super.key, this.showGeneralWalletOption = false});

  @override
  State<AddmoneyView> createState() => _AddmoneyViewState();
}

class _AddmoneyViewState extends State<AddmoneyView> {
  late final AddmoneyController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AddmoneyController>()
        ? Get.find<AddmoneyController>()
        : Get.put(AddmoneyController());
    controller.checkKycStatus();
    controller.fetchWalletBalance();
    controller.resetInput();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top > 0
        ? MediaQuery.of(context).padding.top
        : Get.mediaQuery.padding.top;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: MediaQuery.of(context).padding.copyWith(top: topPadding),
      ),
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
          title: Text(
            "Add Money",
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                      maxWidth:
                          480, // Caps content width cleanly on tablets / iPads
                    ),
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
                                horizontal: context.responsive(14),
                                vertical: context.responsive(14),
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
                                  SizedBox(width: context.responsive(10)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            "Available Balance",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w700,
                                              fontSize: context.responsive(14),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: context.responsive(2)),
                                        Obx(
                                          () => FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              "₹${controller.balance.value.toStringAsFixed(2)}",
                                              style: TextStyle(
                                                color: const Color(0xFF8E8E93),
                                                fontSize: context.responsive(
                                                  12,
                                                ),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: context.responsive(8)),

                                  // KYC Status Badge Pill
                                  Obx(() {
                                    final isFull = controller.isFullKyc.value;
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: context.responsive(8),
                                        vertical: context.responsive(4),
                                      ),
                                      decoration: BoxDecoration(
                                        color: isFull
                                            ? const Color(0xFFE8F5E9)
                                            : const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(
                                          context.responsive(20),
                                        ),
                                        border: Border.all(
                                          color: isFull
                                              ? const Color(0xFFA5D6A7)
                                              : const Color(0xFFFFCC80),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isFull
                                                ? Icons.check_circle_rounded
                                                : Icons.info_outline_rounded,
                                            size: context.responsive(12),
                                            color: isFull
                                                ? const Color(0xFF2E7D32)
                                                : const Color(0xFFE65100),
                                          ),
                                          SizedBox(
                                            width: context.responsive(4),
                                          ),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              isFull
                                                  ? "Full KYC (₹2L)"
                                                  : "Min KYC (₹10K)",
                                              style: TextStyle(
                                                fontSize: context.responsive(
                                                  10.5,
                                                ),
                                                fontWeight: FontWeight.w700,
                                                color: isFull
                                                    ? const Color(0xFF2E7D32)
                                                    : const Color(0xFFE65100),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),

                          // Blocked Card Notice Banner
                          Obx(() {
                            if (!controller.isPermanentlyBlocked.value) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: EdgeInsets.only(
                                top: context.responsive(10),
                                left: context.responsive(20),
                                right: context.responsive(20),
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.responsive(14),
                                  vertical: context.responsive(11),
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(
                                    context.responsive(14),
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFFFCDD2),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.block_rounded,
                                      color: const Color(0xFFD32F2F),
                                      size: context.responsive(20),
                                    ),
                                    SizedBox(width: context.responsive(10)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Card Permanently Blocked",
                                            style: TextStyle(
                                              color: const Color(0xFFC62828),
                                              fontWeight: FontWeight.w700,
                                              fontSize: context.responsive(13),
                                            ),
                                          ),
                                          SizedBox(
                                            height: context.responsive(2),
                                          ),
                                          Text(
                                            "Adding money is disabled for this wallet because your card has been permanently blocked.",
                                            style: TextStyle(
                                              color: const Color(0xFFD32F2F),
                                              fontSize: context.responsive(
                                                11.5,
                                              ),
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          SizedBox(height: context.responsive(22)),

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

                          SizedBox(height: context.responsive(10)),

                          // Amount Display with FittedBox and Red Highlight on Limit Violation
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.responsive(24),
                            ),
                            child: Obx(() {
                              final amountStr =
                                  controller.enteredAmount.value.isEmpty
                                  ? "0"
                                  : controller.formatAmount(
                                      controller.enteredAmount.value,
                                    );
                              final isExceeding =
                                  controller.isAmountExceedingLimit;
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "₹ $amountStr",
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: context.responsive(42),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: isExceeding
                                        ? const Color(0xFFD32F2F)
                                        : Colors.black,
                                  ),
                                ),
                              );
                            }),
                          ),

                          SizedBox(height: context.responsive(6)),

                          // Dynamic Guidance / Subtitle Pill
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.responsive(20),
                            ),
                            child: Obx(() {
                              final isLimitReached = controller.isLimitReached;
                              final isExceeding =
                                  controller.isAmountExceedingLimit;
                              final maxAddable = controller.maxAddableAmount;
                              final isFull = controller.isFullKyc.value;

                              if (controller.isPermanentlyBlocked.value) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.responsive(12),
                                    vertical: context.responsive(5),
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(
                                      context.responsive(16),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "🚫 Adding money is disabled (Card permanently blocked)",
                                      style: TextStyle(
                                        color: const Color(0xFFC62828),
                                        fontSize: context.responsive(11.5),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              if (isLimitReached) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.responsive(12),
                                    vertical: context.responsive(5),
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(
                                      context.responsive(16),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      isFull
                                          ? "Wallet limit of ₹2,00,000 reached"
                                          : "Min KYC wallet limit of ₹10,000 reached",
                                      style: TextStyle(
                                        color: const Color(0xFFC62828),
                                        fontSize: context.responsive(11.5),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              if (isExceeding) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.responsive(12),
                                    vertical: context.responsive(5),
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(
                                      context.responsive(16),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      "⚠️ Exceeds limit: You can add up to ₹${controller.formatCurrency(maxAddable)}",
                                      style: TextStyle(
                                        color: const Color(0xFFC62828),
                                        fontSize: context.responsive(11.5),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  "Minimum ₹1 · Maximum you can add: ₹${controller.formatCurrency(maxAddable)}",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: context.responsive(11.5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }),
                          ),

                          SizedBox(height: context.responsive(24)),

                          // // Presets Row
                          // Padding(
                          //   padding: EdgeInsets.symmetric(
                          //     horizontal: context.responsive(20),
                          //   ),
                          //   child: Row(
                          //     mainAxisAlignment: MainAxisAlignment.center,
                          //     children: [
                          //       Expanded(
                          //         child: _presetPill(
                          //           context,
                          //           controller,
                          //           500,
                          //           "₹500",
                          //         ),
                          //       ),
                          //       SizedBox(width: context.responsive(8)),
                          //       Expanded(
                          //         child: _presetPill(
                          //           context,
                          //           controller,
                          //           1000,
                          //           "₹1,000",
                          //         ),
                          //       ),
                          //       SizedBox(width: context.responsive(8)),
                          //       Expanded(
                          //         child: _presetPill(
                          //           context,
                          //           controller,
                          //           2000,
                          //           "₹2,000",
                          //         ),
                          //       ),
                          //       SizedBox(width: context.responsive(8)),
                          //       Expanded(
                          //         child: _presetPill(
                          //           context,
                          //           controller,
                          //           5000,
                          //           "₹5,000",
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),

                          // SizedBox(height: context.responsive(14)),
                          const Spacer(flex: 1),

                          // Keypad
                          Center(
                            child: CustomNumericKeypad(
                              leftActionText: '.',
                              onDigitTap: (digit) {
                                if (controller.isPermanentlyBlocked.value) {
                                  AppSnackbar.error(
                                    "Card is permanently blocked. Adding money is disabled.",
                                    title: "Card Blocked",
                                  );
                                  return;
                                }
                                controller.setAmount(digit);
                              },
                              onDeleteTap: () {
                                if (controller.isPermanentlyBlocked.value) {
                                  AppSnackbar.error(
                                    "Card is permanently blocked. Adding money is disabled.",
                                    title: "Card Blocked",
                                  );
                                  return;
                                }
                                controller.setAmount('back');
                              },
                              onClear: () {
                                if (controller.isPermanentlyBlocked.value)
                                  return;
                                controller.enteredAmount.value = '0';
                              },
                            ),
                          ),

                          SizedBox(height: context.responsive(24)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              context.responsive(20),
              context.responsive(8),
              context.responsive(20),
              context.responsive(12),
            ),
            child: Obx(() {
              final bool isBlocked = controller.isPermanentlyBlocked.value;
              final bool limitReached = controller.isLimitReached;
              final bool exceeding = controller.isAmountExceedingLimit;

              String buttonText = "Add Money";
              Color buttonColor = Colors.black;

              if (isBlocked) {
                buttonText = "Card Permanently Blocked";
                buttonColor = Colors.grey.shade600;
              } else if (limitReached) {
                buttonText = controller.isFullKyc.value
                    ? "Wallet Limit Reached (₹2,00,000)"
                    : "Limit Reached · Upgrade to Full KYC";
                buttonColor = controller.isFullKyc.value
                    ? Colors.grey.shade700
                    : const Color(0xFFB78103);
              } else if (exceeding) {
                buttonText =
                    "Exceeds Limit (Max ₹${controller.formatCurrency(controller.maxAddableAmount)})";
                buttonColor = const Color(0xFFC62828);
              }

              return CustomButton(
                text: buttonText,
                btncolor: buttonColor,
                textColor: Colors.white,
                height: context.responsive(54),
                textsize: context.responsive(14),
                borderRadius: context.responsive(50),
                onPressed: isBlocked
                    ? () => AppSnackbar.error(
                        "Card is permanently blocked. Adding money is disabled.",
                        title: "Card Blocked",
                      )
                    : (limitReached && !controller.isFullKyc.value
                          ? () => Get.toNamed('/updateKyc')
                          : (controller.canProceed
                                ? () => controller.payNow()
                                : () {})),
              );
            }),
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
      final isPermBlocked = controller.isPermanentlyBlocked.value;
      final isExceeding = value > controller.maxAddableAmount;
      final isDisabled = isPermBlocked || isExceeding;
      final isSelected = controller.selectedPreset.value == value;
      return GestureDetector(
        onTap: () {
          if (isPermBlocked) {
            AppSnackbar.error(
              "Card is permanently blocked. Adding money is disabled.",
              title: "Card Blocked",
            );
            return;
          }
          HapticFeedback.selectionClick();
          controller.setPreset(value);
        },
        child: Opacity(
          opacity: isDisabled ? 0.45 : 1.0,
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(
              vertical: context.responsive(9),
              horizontal: context.responsive(4),
            ),
            decoration: BoxDecoration(
              color: isSelected ? primaryLightYellow : Colors.white,
              borderRadius: BorderRadius.circular(context.responsive(24)),
              border: Border.all(
                color: isSelected ? primaryYellow : const Color(0xFFE5E7EB),
                width: 1.2,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: context.responsive(13.5),
                  color: isDisabled ? Colors.grey.shade600 : Colors.black,
                  decoration: isExceeding ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
