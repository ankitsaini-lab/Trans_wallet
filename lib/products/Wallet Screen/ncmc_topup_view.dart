import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:transwallet/products/Dashboard%20screen/dashboardscreen_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/products/Wallet%20Screen/walletscreen_Controller.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/custom_numeric_keypad.dart';
import 'package:transwallet/widgets/custombutton.dart';

class NcmcTopupView extends StatefulWidget {
  const NcmcTopupView({super.key});

  @override
  State<NcmcTopupView> createState() => _NcmcTopupViewState();
}

class _NcmcTopupViewState extends State<NcmcTopupView> {
  late final WalletscreenController controller;

  // Step 0: Enter Amount, Step 1: Enter MPIN, Step 2: Success Receipt
  int _currentStep = 0;

  // Amount state
  String _enteredAmount = "0";
  int _selectedPreset = 0;

  // MPIN state
  String _mpin = "";
  bool _isVerifyingMpin = false;
  bool _hasMpinError = false;
  String _mpinErrorMessage = "";

  // Success state
  Map<String, dynamic>? _successResponse;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<WalletscreenController>()
        ? Get.find<WalletscreenController>()
        : Get.put(WalletscreenController());
  }

  double get generalBalance => controller.generalWalletBalance;
  double get ncmcBalance => controller.ncmcWalletBalance;

  double get enteredAmountDouble =>
      double.tryParse(_enteredAmount.isEmpty ? "0" : _enteredAmount) ?? 0.0;

  bool get isExceedingGeneralBalance => enteredAmountDouble > generalBalance;

  bool get canProceed =>
      enteredAmountDouble > 0 &&
      !isExceedingGeneralBalance &&
      generalBalance > 0 &&
      !controller.isToppingUpNcmc.value;

  String _formatAmount(String value) {
    if (value.isEmpty) return "0";
    if (value.contains('.')) {
      final parts = value.split('.');
      final intPart = int.tryParse(parts[0]) ?? 0;
      final formattedInt = intPart.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ",",
      );
      return "$formattedInt.${parts.length > 1 ? parts[1] : ''}";
    }
    final number = int.tryParse(value) ?? 0;
    return number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ",",
    );
  }

  // Amount Keypad handlers
  void _onAmountDigitTap(String digit) {
    HapticFeedback.selectionClick();
    setState(() {
      if (digit == '.') {
        if (_enteredAmount.contains('.')) return;
        if (_enteredAmount.isEmpty || _enteredAmount == '0') {
          _enteredAmount = '0.';
        } else {
          _enteredAmount += '.';
        }
      } else {
        if (_enteredAmount == '0') {
          _enteredAmount = digit;
        } else {
          if (_enteredAmount.contains('.')) {
            final parts = _enteredAmount.split('.');
            if (parts.length > 1 && parts[1].length >= 2) return;
            if (parts[0].length >= 6) return;
          } else {
            if (_enteredAmount.length >= 6) return; // 6 digits max
          }
          _enteredAmount += digit;
        }
      }
      _syncSelectedPreset();
    });
  }

  void _onAmountDeleteTap() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_enteredAmount.isNotEmpty) {
        _enteredAmount = _enteredAmount.substring(0, _enteredAmount.length - 1);
        if (_enteredAmount.isEmpty) {
          _enteredAmount = '0';
        }
      }
      _syncSelectedPreset();
    });
  }

  void _onAmountClear() {
    HapticFeedback.selectionClick();
    setState(() {
      _enteredAmount = '0';
      _selectedPreset = 0;
    });
  }

  void _setPreset(int val) {
    HapticFeedback.selectionClick();
    setState(() {
      _enteredAmount = val.toString();
      _selectedPreset = val;
    });
  }

  void _syncSelectedPreset() {
    final cur = int.tryParse(_enteredAmount) ?? 0;
    if (cur == 100 || cur == 200 || cur == 500 || cur == 1000) {
      _selectedPreset = cur;
    } else {
      _selectedPreset = 0;
    }
  }

  void _proceedToMpin() {
    if (!canProceed) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _currentStep = 1;
      _mpin = "";
      _hasMpinError = false;
      _mpinErrorMessage = "";
    });
  }

  // MPIN Keypad handlers
  void _onMpinDigitTap(String digit) {
    if (_isVerifyingMpin || controller.isToppingUpNcmc.value) return;
    HapticFeedback.selectionClick();

    setState(() {
      if (_hasMpinError) {
        _hasMpinError = false;
        _mpinErrorMessage = "";
        _mpin = "";
      }
      if (_mpin.length < 4) {
        _mpin += digit;
      }
    });

    if (_mpin.length == 4) {
      _verifyMpinAndExecute();
    }
  }

  void _onMpinDeleteTap() {
    if (_isVerifyingMpin || controller.isToppingUpNcmc.value) return;
    HapticFeedback.selectionClick();

    setState(() {
      _hasMpinError = false;
      _mpinErrorMessage = "";
      if (_mpin.isNotEmpty) {
        _mpin = _mpin.substring(0, _mpin.length - 1);
      }
    });
  }

  void _onMpinClear() {
    if (_isVerifyingMpin || controller.isToppingUpNcmc.value) return;
    HapticFeedback.selectionClick();

    setState(() {
      _hasMpinError = false;
      _mpinErrorMessage = "";
      _mpin = "";
    });
  }

  Future<void> _verifyMpinAndExecute() async {
    final pinToVerify = _mpin;

    setState(() {
      _isVerifyingMpin = true;
      _hasMpinError = false;
      _mpinErrorMessage = "";
    });

    MpinVerifyResponse res;
    if (Get.isRegistered<ApiService>()) {
      res = await ApiService.to.verifyMpin(pinToVerify);
    } else {
      final box = GetStorage();
      final savedMpin =
          box.read<String>('saved_mpin') ?? box.read('mpin')?.toString();
      final ok = savedMpin != null && savedMpin == pinToVerify;
      res = MpinVerifyResponse(
        isSuccess: ok,
        message: ok ? 'MPIN verified' : 'Invalid MPIN. Please try again.',
      );
    }

    if (!mounted) return;

    if (!res.isSuccess) {
      HapticFeedback.heavyImpact();
      setState(() {
        _isVerifyingMpin = false;
        _hasMpinError = true;
        _mpinErrorMessage = res.message.isNotEmpty
            ? res.message
            : "Invalid MPIN. Please try again.";
        _mpin = "";
      });
      return;
    }

    // MPIN is verified! Proceed with transfer
    HapticFeedback.mediumImpact();
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.clearMpinLockout();
    }

    final response = await controller.topupNcmcWallet(
      amount: enteredAmountDouble,
    );

    if (!mounted) return;

    if (response != null) {
      HapticFeedback.mediumImpact();
      setState(() {
        _isVerifyingMpin = false;
        _successResponse = response;
        _currentStep = 2; // Transition to Success Receipt screen
      });
    } else {
      setState(() {
        _isVerifyingMpin = false;
        _currentStep = 0; // Return to amount step on failure
      });
    }
  }

  void _handleBackAction() {
    if (_currentStep == 1) {
      setState(() {
        _currentStep = 0;
        _mpin = "";
        _hasMpinError = false;
        _mpinErrorMessage = "";
      });
    } else {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        Get.back();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle = "Top Up NCMC Card";
    if (_currentStep == 1) {
      appBarTitle = "Confirm with MPIN";
    } else if (_currentStep == 2) {
      appBarTitle = "Payment Receipt";
    }

    return PopScope(
      canPop: _currentStep == 0 || _currentStep == 2,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackAction();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: appBarGradient),
          ),
          elevation: 0,
          leadingWidth: context.responsive(60),
          leading: AppBarBackButton(onTap: _handleBackAction),
          title: Text(
            appBarTitle,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStep(context),
          ),
        ),
        bottomNavigationBar: _buildBottomBar(context),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_currentStep) {
      case 1:
        return _buildMpinView(context);
      case 2:
        return _buildSuccessReceiptView(context);
      case 0:
      default:
        return _buildAmountView(context);
    }
  }

  // ----------------------------------------------------
  // STEP 0: AMOUNT SELECTION VIEW
  // ----------------------------------------------------
  Widget _buildAmountView(BuildContext context) {
    return LayoutBuilder(
      key: const ValueKey("AmountView"),
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxWidth: 480,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsive(20),
                    vertical: context.responsive(16),
                  ),
                  child: Column(
                    children: [
                      // Source -> Destination Card
                      _buildTransferDirectionCard(context),

                      SizedBox(height: context.responsive(20)),

                      if (generalBalance <= 0) ...[
                        _buildZeroBalanceWarning(context),
                        const Spacer(),
                      ] else ...[
                        Text(
                          "ENTER TOP-UP AMOUNT",
                          style: TextStyle(
                            color: const Color(0xFF9E9E9E),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            fontSize: context.responsive(11),
                          ),
                        ),
                        SizedBox(height: context.responsive(8)),

                        // Amount Display
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "₹ ${_formatAmount(_enteredAmount)}",
                            style: TextStyle(
                              fontSize: context.responsive(42),
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: isExceedingGeneralBalance
                                  ? const Color(0xFFD32F2F)
                                  : Colors.black,
                            ),
                          ),
                        ),

                        SizedBox(height: context.responsive(6)),

                        // Validation pill or balance indicator
                        if (isExceedingGeneralBalance)
                          Container(
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: const Color(0xFFC62828),
                                  size: context.responsive(14),
                                ),
                                SizedBox(width: context.responsive(6)),
                                Flexible(
                                  child: Text(
                                    "Exceeds General Wallet (₹${generalBalance.toStringAsFixed(2)})",
                                    style: TextStyle(
                                      color: const Color(0xFFC62828),
                                      fontSize: context.responsive(11.5),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          // Text(
                          //   "Available in General Wallet: ₹${generalBalance.toStringAsFixed(2)}",
                          //   style: TextStyle(
                          //     color: const Color(0xFF757575),
                          //     fontSize: context.responsive(12),
                          //     fontWeight: FontWeight.w500,
                          //   ),
                          // ),
                          SizedBox(height: context.responsive(0)),
                        SizedBox(height: context.responsive(18)),

                        // // Quick Presets
                        // Row(
                        //   children: [
                        //     Expanded(child: _buildPresetChip(context, 100)),
                        //     SizedBox(width: context.responsive(8)),
                        //     Expanded(child: _buildPresetChip(context, 200)),
                        //     SizedBox(width: context.responsive(8)),
                        //     Expanded(child: _buildPresetChip(context, 500)),
                        //     SizedBox(width: context.responsive(8)),
                        //     Expanded(child: _buildPresetChip(context, 1000)),
                        //   ],
                        // ),

                        // height16,
                        Center(
                          child: CustomNumericKeypad(
                            leftActionText: '.',
                            onDigitTap: _onAmountDigitTap,
                            onDeleteTap: _onAmountDeleteTap,
                            onClear: _onAmountClear,
                          ),
                        ),

                        SizedBox(height: context.responsive(16)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMpinView(BuildContext context) {
    return LayoutBuilder(
      key: const ValueKey("MpinView"),
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxWidth: 480,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsive(24),
                    vertical: context.responsive(20),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: context.responsive(12)),

                      // Security Lock Icon
                      Container(
                        width: context.responsive(64),
                        height: context.responsive(64),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF8A3FFC).withOpacity(0.12),
                          border: Border.all(
                            color: const Color(0xFF8A3FFC).withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.shield_outlined,
                            color: const Color(0xFF8A3FFC),
                            size: context.responsive(30),
                          ),
                        ),
                      ),

                      SizedBox(height: context.responsive(16)),

                      Text(
                        "Enter 4-Digit MPIN",
                        style: TextStyle(
                          fontSize: context.responsive(19),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      SizedBox(height: context.responsive(4)),
                      Text(
                        "Authorize transfer of ₹${_formatAmount(_enteredAmount)} to NCMC Card",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.responsive(13),
                          color: const Color(0xFF6B7280),
                        ),
                      ),

                      SizedBox(height: context.responsive(28)),

                      // 4 PIN Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final bool isFilled = index < _mpin.length;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: EdgeInsets.symmetric(
                              horizontal: context.responsive(12),
                            ),
                            width: context.responsive(18),
                            height: context.responsive(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isFilled
                                  ? (_hasMpinError
                                        ? const Color(0xFFD32F2F)
                                        : (_isVerifyingMpin
                                              ? const Color(
                                                  0xFF8A3FFC,
                                                ).withOpacity(0.4)
                                              : const Color(0xFF8A3FFC)))
                                  : Colors.white,
                              border: Border.all(
                                color: isFilled
                                    ? (_hasMpinError
                                          ? const Color(0xFFD32F2F)
                                          : const Color(0xFF8A3FFC))
                                    : (_hasMpinError
                                          ? const Color(
                                              0xFFD32F2F,
                                            ).withOpacity(0.35)
                                          : Colors.black.withOpacity(0.2)),
                                width: 2,
                              ),
                              boxShadow: (isFilled && !_hasMpinError)
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF8A3FFC,
                                        ).withOpacity(0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),

                      SizedBox(height: context.responsive(22)),

                      // Status indicator or Error message
                      if (_isVerifyingMpin ||
                          controller.isToppingUpNcmc.value) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: context.responsive(18),
                              width: context.responsive(18),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF8A3FFC),
                                ),
                              ),
                            ),
                            SizedBox(width: context.responsive(10)),
                            Text(
                              "Authorizing & transferring...",
                              style: TextStyle(
                                color: const Color(0xFF8A3FFC),
                                fontSize: context.responsive(13),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ] else if (_hasMpinError) ...[
                        Text(
                          _mpinErrorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: primaryRed,
                            fontSize: context.responsive(12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        SizedBox(height: context.responsive(22)),
                      ],

                      const Spacer(),

                      // Numeric Keypad
                      Center(
                        child: CustomNumericKeypad(
                          onDigitTap: _onMpinDigitTap,
                          onDeleteTap: _onMpinDeleteTap,
                          onClear: _onMpinClear,
                        ),
                      ),

                      SizedBox(height: context.responsive(16)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // STEP 2: PAYMENT SUCCESS RECEIPT VIEW
  // ----------------------------------------------------
  Widget _buildSuccessReceiptView(BuildContext context) {
    final data = _successResponse?['data'] is Map
        ? _successResponse!['data'] as Map
        : null;
    final String txnId =
        data?['externalTransactionId']?.toString() ??
        data?['providerRef']?.toString() ??
        "W2W${DateTime.now().millisecondsSinceEpoch}";
    final String nowFormatted = DateFormat(
      'dd MMM yyyy, hh:mm a',
    ).format(DateTime.now());

    return LayoutBuilder(
      key: const ValueKey("SuccessView"),
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                maxWidth: 480,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsive(24),
                    vertical: context.responsive(24),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: context.responsive(16)),

                      // Animated Green Success Icon
                      Container(
                        width: context.responsive(80),
                        height: context.responsive(80),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE8F5E9),
                          border: Border.all(
                            color: const Color(0xFF81C784),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: const Color(0xFF2E7D32),
                            size: context.responsive(48),
                          ),
                        ),
                      ),

                      SizedBox(height: context.responsive(18)),

                      Text(
                        "Top-up Successful!",
                        style: TextStyle(
                          fontSize: context.responsive(22),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      SizedBox(height: context.responsive(6)),
                      Text(
                        "₹${_formatAmount(_enteredAmount)} added to NCMC Card",
                        style: TextStyle(
                          fontSize: context.responsive(15),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),

                      SizedBox(height: context.responsive(28)),

                      // Receipt Details Card
                      Container(
                        padding: EdgeInsets.all(context.responsive(18)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(
                            context.responsive(20),
                          ),
                          border: Border.all(
                            color: const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildReceiptRow(
                              "Amount",
                              "₹ ${_formatAmount(_enteredAmount)}",
                              isBold: true,
                            ),
                            const Divider(height: 24, color: Color(0xFFE5E7EB)),
                            _buildReceiptRow("From", "General Wallet"),
                            const SizedBox(height: 12),
                            _buildReceiptRow("To", "NCMC Card"),
                            const SizedBox(height: 12),
                            _buildReceiptRow("Transaction ID", txnId),
                            const SizedBox(height: 12),
                            _buildReceiptRow("Date & Time", nowFormatted),
                            const SizedBox(height: 12),
                            _buildReceiptRow(
                              "Status",
                              "Completed",
                              valueColor: const Color(0xFF2E7D32),
                              isBold: true,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Done Button
                      CustomButton(
                        text: "Done",
                        btncolor: const Color(0xFF111111),
                        textColor: Colors.white,
                        height: context.responsive(52),
                        textsize: context.responsive(14),
                        borderRadius: context.responsive(50),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            Get.back();
                          }
                        },
                      ),

                      SizedBox(height: context.responsive(12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.responsive(13),
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: context.responsive(13),
              color: valueColor ?? const Color(0xFF111111),
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // SUB-WIDGETS & HELPERS
  // ----------------------------------------------------
  Widget _buildTransferDirectionCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFE),
        borderRadius: BorderRadius.circular(context.responsive(18)),
        border: Border.all(color: const Color(0xFFEEEFF5), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // From General Wallet Box
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsive(10),
                    vertical: context.responsive(10),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(context.responsive(12)),
                    border: Border.all(
                      color: const Color(0xFFFFE5E5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/generalwallet.png",
                        height: context.responsive(32),
                        width: context.responsive(32),
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: context.responsive(8)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "From General",
                              style: TextStyle(
                                fontSize: context.responsive(10.5),
                                color: const Color(0xFF757575),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "₹${generalBalance.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: context.responsive(13.5),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
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

              // Transfer Arrow
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(8),
                ),
                child: Container(
                  padding: EdgeInsets.all(context.responsive(8)),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8A3FFC).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: context.responsive(16),
                    color: const Color(0xFF8A3FFC),
                  ),
                ),
              ),

              // To NCMC Wallet Box
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsive(10),
                    vertical: context.responsive(10),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F5FF),
                    borderRadius: BorderRadius.circular(context.responsive(12)),
                    border: Border.all(
                      color: const Color(0xFFEFE5FF),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/ncmcwallet.png",
                        height: context.responsive(32),
                        width: context.responsive(32),
                        fit: BoxFit.contain,
                      ),
                      SizedBox(width: context.responsive(8)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "To NCMC",
                              style: TextStyle(
                                fontSize: context.responsive(10.5),
                                color: const Color(0xFF757575),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "₹${ncmcBalance.toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: context.responsive(13.5),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black,
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
            ],
          ),

          // SizedBox(height: context.responsive(10)),
        ],
      ),
    );
  }

  Widget _buildZeroBalanceWarning(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.responsive(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(context.responsive(16)),
        border: Border.all(color: const Color(0xFFFFE082), width: 1.2),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: const Color(0xFFB78103),
            size: context.responsive(36),
          ),
          SizedBox(height: context.responsive(10)),
          Text(
            "Insufficient General Wallet Balance",
            style: TextStyle(
              fontSize: context.responsive(14.5),
              fontWeight: FontWeight.w800,
              color: const Color(0xFF4A3B00),
            ),
          ),
          SizedBox(height: context.responsive(6)),
          Text(
            "Your General Wallet balance is ₹0.00. NCMC Card can only be loaded using funds from your General Wallet. Please add money to your General Wallet first.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: context.responsive(12),
              color: const Color(0xFF6D5700),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(BuildContext context, int value) {
    final bool isExceeding = value > generalBalance;
    final bool isSelected = _selectedPreset == value;

    return GestureDetector(
      onTap: () {
        if (isExceeding) {
          AppSnackbar.error(
            "Preset ₹$value exceeds your General Wallet balance of ₹${generalBalance.toStringAsFixed(2)}.",
            title: "Insufficient Balance",
          );
          return;
        }
        _setPreset(value);
      },
      child: Opacity(
        opacity: isExceeding ? 0.45 : 1.0,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: context.responsive(9),
            horizontal: context.responsive(4),
          ),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF9F5FF) : Colors.white,
            borderRadius: BorderRadius.circular(context.responsive(16)),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF8A3FFC)
                  : const Color(0xFFE5E7EB),
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "₹$value",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: context.responsive(13),
                color: isExceeding
                    ? Colors.grey.shade600
                    : (isSelected ? const Color(0xFF8A3FFC) : Colors.black),
                decoration: isExceeding ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildBottomBar(BuildContext context) {
    if (_currentStep != 0)
      return null; // Steps 1 and 2 handle their own actions

    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
          context.responsive(20),
          context.responsive(8),
          context.responsive(20),
          context.responsive(14),
        ),
        child: Obx(() {
          final bool isToppingUp = controller.isToppingUpNcmc.value;

          if (generalBalance <= 0) {
            return CustomButton(
              text: "Add Money to General Wallet",
              btncolor: const Color(0xFF111111),
              textColor: Colors.white,
              height: context.responsive(52),
              textsize: context.responsive(14),
              borderRadius: context.responsive(50),
              onPressed: () {
                if (Get.isRegistered<DashboardscreenController>()) {
                  final dashCtrl = Get.find<DashboardscreenController>();
                  if (dashCtrl.isCardPermanentlyBlocked) {
                    dashCtrl.showPermanentlyBlockedAddMoneyNotice();
                    return;
                  }
                }
                Get.toNamed('/addmoney');
              },
            );
          }

          String buttonText = "Top Up NCMC Card";
          Color buttonColor = const Color(0xFF111111);

          if (isExceedingGeneralBalance) {
            buttonText = "Exceeds Available Balance";
            buttonColor = const Color(0xFFC62828);
          } else if (enteredAmountDouble > 0) {
            buttonText = "Proceed to Pay ₹${_formatAmount(_enteredAmount)}";
            buttonColor = const Color(0xFF8A3FFC);
          }

          return CustomButton(
            text: buttonText,
            btncolor: canProceed ? buttonColor : Colors.grey.shade400,
            textColor: Colors.white,
            isLoading: isToppingUp,
            height: context.responsive(52),
            textsize: context.responsive(14),
            borderRadius: context.responsive(50),
            onPressed: canProceed ? _proceedToMpin : () {},
          );
        }),
      ),
    );
  }
}
