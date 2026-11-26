import 'dart:async';
import 'dart:developer';
import 'package:transwallet/widgets/notification_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Wallet%20Screen/walletscreen_Controller.dart';
import 'package:transwallet/products/Wallet%20Screen/ncmc_topup_view.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/globalbottombar/Globalbottombar_View.dart';
import 'package:transwallet/products/Wallet%20Screen/Add%20Money/addmoney_View.dart';
import 'package:transwallet/products/Dashboard%20screen/dashboardscreen_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/widgets/user_avatar.dart';
import 'package:transwallet/utilities/string_extensions.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/widgets/custom_numeric_keypad.dart';

class WalletscreenView extends GetView<WalletscreenController> {
  const WalletscreenView({super.key});

  @override
  WalletscreenController get controller =>
      Get.isRegistered<WalletscreenController>()
      ? Get.find<WalletscreenController>()
      : Get.put(WalletscreenController());

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<WalletscreenController>()) {
      Get.put(WalletscreenController());
    }

    final box = GetStorage();
    final hour = DateTime.now().hour;
    String greeting = "Good Evening";
    if (hour < 12) {
      greeting = "Good Morning";
    } else if (hour < 17) {
      greeting = "Good Afternoon";
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: context.responsive(80),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  UserAvatar(size: context.responsive(48)),
                  SizedBox(width: context.responsive(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          greeting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF6B7280),
                            fontSize: context.responsive(13),
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1,
                          ),
                        ),
                        Text(
                          formatUserName(box.read('name')),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color.fromRGBO(0, 0, 0, 1),
                            fontWeight: FontWeight.w800,
                            fontSize: context.responsive(16),
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const NotificationButton(),
          ],
        ),
      ),
      bottomNavigationBar: GlobalbottombarView(seletedIndex: 1.obs),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: context.responsive(20),
        ),
        child: Column(
          children: [
            _buildTotalBalanceCard(context),
            height30,
            _buildWalletList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBalanceCard(BuildContext context) {
    return Obx(() {
      final isRevealed = controller.isBalanceRevealed.value;
      double totalBalance = 0;
      for (var w in controller.wallets) {
        totalBalance += (w["balance"] as num?)?.toDouble() ?? 0.0;
      }

      return GestureDetector(
        onTap: () async {
          if (isRevealed) {
            controller.hideBalance();
          } else {
            Get.bottomSheet(
              _MpinVerifySheet(
                onSuccess: () => controller.revealBalance(),
                title: "Enter MPIN to View Balance",
                subtitle: "For your security, enter your 4-digit MPIN",
              ),
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
            );
          }
        },
        child: Container(
          width: double.infinity,
          height: context.responsive(155),
          decoration: BoxDecoration(
            // gradient: topBackgroundGradient,
            borderRadius: BorderRadius.circular(context.responsive(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                bottom: 0,
                left: 0,

                top: 0,
                child: Image.asset(
                  "assets/bgimagewallet.png",
                  fit: BoxFit.contain,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(context.responsive(24)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Total Balance",
                          style: TextStyle(
                            color: const Color(0xFF111111),
                            fontSize: context.responsive(14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: context.responsive(8)),
                        Container(
                          padding: EdgeInsets.all(context.responsive(4)),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isRevealed
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            size: context.responsive(14),
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.responsive(8)),
                    if (controller.isLoadingBalance.value)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: context.responsive(4),
                        ),
                        child: SizedBox(
                          height: context.responsive(24),
                          width: context.responsive(24),
                          child: const CircularProgressIndicator(
                            color: primaryRed,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    else
                      Text(
                        isRevealed
                            ? "₹ ${totalBalance.toStringAsFixed(2)}"
                            : "₹ •••••••",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: context.responsive(28),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive(12),
                        vertical: context.responsive(6),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          context.responsive(20),
                        ),
                        border: Border.all(color: Colors.black87, width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pie_chart_outline_rounded,
                            size: context.responsive(14),
                            color: Colors.black,
                          ),
                          SizedBox(width: context.responsive(6)),
                          Text(
                            "Across ${controller.wallets.length} wallets",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: context.responsive(12),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildWalletList(BuildContext context) {
    return Obx(() {
      if (controller.wallets.isEmpty) return const SizedBox();

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.wallets.length,
        itemBuilder: (context, i) {
          final wallet = controller.wallets[i];

          return Obx(() {
            final isExpanded = controller.expandedIndex.value == i;
            final bool isGeneralWallet = wallet["title"]
                .toString()
                .toLowerCase()
                .contains("general");
            final bool isNcmcWallet = wallet["title"]
                .toString()
                .toLowerCase()
                .contains("ncmc wallet");

            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: GestureDetector(
                onTap: () =>
                    controller.expandedIndex.value = isExpanded ? -1 : i,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    color: // wallet["bgColor"] ??
                    isExpanded
                        ? wallet["bgColor"]
                        : Colors.white,
                    borderRadius: BorderRadius.circular(context.responsive(20)),
                    border: Border.all(
                      color: // wallet["borderColor"] ??
                      isExpanded
                          ? wallet["borderColor"]
                          : const Color(0xFFECECEC),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(context.responsive(16)),
                        child: Row(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              child: Image.asset(
                                wallet["icon"].toString(),
                                height: context.responsive(60),
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(width: context.responsive(16)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    wallet["title"].toString(),
                                    style: TextStyle(
                                      color: const Color(0xFF111111),
                                      fontSize: context.responsive(15),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: context.responsive(4)),
                                  Text(
                                    wallet["subtitle"]?.toString() ?? "",
                                    style: TextStyle(
                                      color: const Color(0xFF9E9E9E),
                                      fontSize: context.responsive(12),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                if (controller.isLoadingBalance.value &&
                                    controller.isBalanceRevealed.value)
                                  SizedBox(
                                    width: context.responsive(16),
                                    height: context.responsive(16),
                                    child: const CircularProgressIndicator(
                                      color: primaryRed,
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  Text(
                                    controller.isBalanceRevealed.value
                                        ? "₹ ${(wallet["balance"] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00'}"
                                        : "₹ •••••••",
                                    style: TextStyle(
                                      color: const Color(0xFF111111),
                                      fontSize: context.responsive(16),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                SizedBox(width: context.responsive(8)),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: Colors.black87,
                                  size: context.responsive(20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (isExpanded) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: List.generate(
                              40,
                              (index) => Expanded(
                                child: Container(
                                  height: 1,
                                  color: index % 2 == 0
                                      ? Colors.transparent
                                      : Colors.black12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              if (isGeneralWallet) ...[
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (Get.isRegistered<
                                        DashboardscreenController
                                      >()) {
                                        final dashCtrl =
                                            Get.find<
                                              DashboardscreenController
                                            >();
                                        if (dashCtrl.isCardPermanentlyBlocked) {
                                          dashCtrl
                                              .showPermanentlyBlockedAddMoneyNotice();
                                          return;
                                        }
                                      }
                                      Get.to(
                                        () => const AddmoneyView(
                                          showGeneralWalletOption: false,
                                        ),
                                        transition: Transition.rightToLeftWithFade,
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            wallet["buttonColor"] ??
                                            const Color(0xFFFFEA66),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons
                                                .account_balance_wallet_outlined,
                                            size: 16,
                                            color: Colors.black,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "Top Up",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ] else if (isNcmcWallet) ...[
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (Get.isRegistered<
                                        DashboardscreenController
                                      >()) {
                                        final dashCtrl =
                                            Get.find<
                                              DashboardscreenController
                                            >();
                                        if (dashCtrl.isCardPermanentlyBlocked) {
                                          dashCtrl
                                              .showPermanentlyBlockedAddMoneyNotice();
                                          return;
                                        }
                                      }
                                      controller.openNcmcTopupScreen();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            wallet["buttonColor"] ??
                                            const Color(0xFFE0CCFF),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.add_card_rounded,
                                            size: 16,
                                            color: Colors.black,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            "Top Up",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Get.toNamed(
                                      '/walletdetails',
                                      arguments: {'data': wallet},
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black26),
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.receipt_long_outlined,
                                          size: 16,
                                          color: Colors.black,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Transactions",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
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
                      ],
                    ],
                  ),
                ),
              ),
            );
          });
        },
      );
    });
  }
}

class _MpinVerifySheet extends StatefulWidget {
  final VoidCallback onSuccess;
  final String title;
  final String subtitle;

  const _MpinVerifySheet({
    required this.onSuccess,
    this.title = "Enter MPIN to View Balance",
    this.subtitle = "For your security, enter your 4-digit mobile PIN",
  });

  @override
  State<_MpinVerifySheet> createState() => _MpinVerifySheetState();
}

class _MpinVerifySheetState extends State<_MpinVerifySheet> {
  String _mpin = "";
  bool _isVerifying = false;
  bool _hasError = false;
  String _errorMessage = "";

  void _keypadPress(String value) {
    if (_isVerifying) return;

    setState(() {
      if (_hasError) {
        _hasError = false;
        _errorMessage = "";
        _mpin = "";
      }
      if (_mpin.length < 4) {
        _mpin += value;
      }
    });

    if (_mpin.length == 4) {
      _verifyMpin();
    }
  }

  void _deletePress() {
    if (_isVerifying) {
      _isVerifying = false;
    }
    setState(() {
      _hasError = false;
      _errorMessage = "";
      if (_mpin.isNotEmpty) {
        _mpin = _mpin.substring(0, _mpin.length - 1);
      }
    });
  }

  void _clearPress() {
    if (_isVerifying) {
      _isVerifying = false;
    }
    setState(() {
      _hasError = false;
      _errorMessage = "";
      _mpin = "";
    });
  }

  Future<void> _verifyMpin() async {
    final pinToVerify = _mpin;

    setState(() {
      _isVerifying = true;
      _hasError = false;
      _errorMessage = "";
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
        message: ok ? 'MPIN verified' : 'Invalid MPIN. Try again.',
      );
    }

    if (mounted) {
      if (res.isSuccess) {
        if (Get.isRegistered<AppLockService>()) {
          AppLockService.to.clearMpinLockout();
        }
        Get.back();
        widget.onSuccess();
      } else {
        setState(() {
          _mpin = pinToVerify;
          _isVerifying = false;
          _hasError = true;
          _errorMessage = res.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Color(0xFFED292A);
    const Color textColor = Color(0xFF111111);
    const Color secondaryText = Color(0xFF6B7280);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFECECEC),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryRed.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Color(0xFF111111),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
              style: const TextStyle(color: secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final bool isFilled = index < _mpin.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isVerifying
                        ? primaryRed.withOpacity(0.3)
                        : (isFilled
                              ? (_hasError ? primaryRed : primaryRed)
                              : const Color(0xFFECECEC)),
                    border: Border.all(
                      color: _hasError && isFilled
                          ? primaryRed
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            if (_isVerifying) ...[
              const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_hasError) ...[
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: primaryRed,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              const SizedBox(height: 36),
            ],
            CustomNumericKeypad(
              onDigitTap: _keypadPress,
              onDeleteTap: _deletePress,
              onClear: _clearPress,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: secondaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _PressableScale({
    required this.child,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
