import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/products/Send%20money%20screen/sendMoney_Controller.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/utilities/getStorage.dart';

class SendmoneyprocessController extends GetxController {
  static const double minTransferAmount = 0.0;
  static const double maxTransferAmount = double.infinity;

  var balance = 0.0.obs;
  var enteredAmount = ''.obs;
  var isLoading = false.obs;
  var selectedPreset = 0.obs;
  var noteController = TextEditingController();

  Map<String, String>? recipient;

  final List<int> presets = const [500, 1000, 2000, 5000];

  @override
  void onInit() {
    super.onInit();
    final rawBalance = box.read('balance');
    if (rawBalance is num) {
      balance.value = rawBalance.toDouble();
    } else if (rawBalance is String) {
      balance.value = double.tryParse(rawBalance) ?? 0.0;
    } else {
      balance.value = 0.0;
    }

    if (Get.arguments != null && Get.arguments is Map) {
      recipient = (Get.arguments as Map).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    }
  }

  double get amount {
    String cleaned = enteredAmount.value.replaceAll(',', '');
    return double.tryParse(cleaned.isEmpty ? "0" : cleaned) ?? 0.0;
  }

  bool get canProceed => amount > 0 && !enteredAmount.value.endsWith('.');

  void setAmount(String value) {
    selectedPreset.value = 0; // Clear preset selection when typing manually
    String current = enteredAmount.value;

    if (value == "back") {
      if (current.isNotEmpty) {
        enteredAmount.value = current.substring(0, current.length - 1);
      }
      return;
    }

    // Support decimal point (.) and comma (,)
    if (value == "." || value == ",") {
      if (current.contains(".")) return;
      if (current.isEmpty || current == "0") {
        enteredAmount.value = "0.";
      } else {
        enteredAmount.value = "$current.";
      }
      return;
    }

    // Limit decimal precision to 2 decimal places (Paise)
    if (current.contains(".")) {
      final parts = current.split(".");
      if (parts.length > 1 && parts[1].length >= 2) {
        return;
      }
    }

    if (current == "0" && value == "0") return;

    String candidate = (current == "0") ? value : current + value;

    // Limit amount to at most 6 digits before the decimal
    final String integerPart = candidate.contains(".")
        ? candidate.split(".")[0]
        : candidate;
    final String digitsOnly = integerPart.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length > 6) {
      return;
    }

    enteredAmount.value = candidate;
  }

  void setPreset(int value) {
    if (value.toString().length > 6) return;
    selectedPreset.value = value;
    enteredAmount.value = value.toString();
  }

  void proceedToPassword() {
    final box = GetStorage();
    if (box.read('is_blocked') == true ||
        box.read('is_card_blocked') == true ||
        box.read('is_frozen') == true) {
      AppSnackbar.error(
        "Your card is currently frozen. Transfers are disabled while the card is frozen.",
        title: "Card Frozen",
      );
      return;
    }
    if (box.read('is_permanently_blocked') == true ||
        box.read('is_card_permanently_blocked') == true) {
      AppSnackbar.error(
        "Your card is permanently blocked. Send Money is disabled.",
        title: "Card Blocked",
      );
      return;
    }

    if (enteredAmount.value.endsWith('.')) {
      enteredAmount.value = enteredAmount.value.substring(
        0,
        enteredAmount.value.length - 1,
      );
    }
    if (amount <= 0) {
      AppSnackbar.error("Please enter a valid amount to send");
      return;
    }
    final String integerPart = enteredAmount.value.contains(".")
        ? enteredAmount.value.split(".")[0]
        : enteredAmount.value;
    if (integerPart.replaceAll(RegExp(r'\D'), '').length > 6) {
      AppSnackbar.error("Amount cannot exceed 6 digits");
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    // The design has a password screen instead of a bottom sheet
    Get.toNamed(
      '/SendMoneyPasswordView',
      arguments: {
        'amount': amount,
        'recipient': recipient,
        'note': noteController.text,
        'paymentMethod': recipient?['paymentMethod'] ?? 'UPI',
        'paymentSource': recipient?['paymentSource'],
        'senderUpi': recipient?['senderUpi'],
      },
    );
  }

  // We will keep these existing methods so it doesn't break anything calling them
  Future<void> addMoney() async {
    proceedToPassword();
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }
}

class PaymentProcessingScreen extends StatelessWidget {
  const PaymentProcessingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF111111),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryRed, strokeWidth: 3),
            SizedBox(height: 24),
            Text(
              "Processing Payment...",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Please don’t press back or close the app",
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentSuccessScreen extends StatefulWidget {
  final double amount;
  final String? message;
  final String? title;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    this.message,
    this.title,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _animController.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      final args = Get.arguments is Map
          ? Map<String, dynamic>.from(Get.arguments as Map)
          : <String, dynamic>{};
      args['amount'] = widget.amount;
      Get.offNamed('/payment_after_success', arguments: args);
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                height: 110,
                width: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.45),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 54,
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              widget.title ?? "Payment Successful!",
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.message ??
                  "₹${widget.amount.toStringAsFixed(2)} transferred successfully",
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF9E9E9E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentafterSuccessScreen extends StatefulWidget {
  final double amount;

  const PaymentafterSuccessScreen({super.key, required this.amount});

  @override
  State<PaymentafterSuccessScreen> createState() =>
      _PaymentafterSuccessScreenState();
}

class _PaymentafterSuccessScreenState extends State<PaymentafterSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _confettiAnim;
  late Animation<double> _textFadeAnim;
  late Animation<Offset> _textSlideAnim;
  late Animation<double> _cardFadeAnim;
  late Animation<Offset> _cardSlideAnim;
  late Animation<double> _btnFadeAnim;

  late String formattedDateTime;
  late String referenceId;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments is Map ? (Get.arguments as Map) : null;
    final now = DateTime.now();
    formattedDateTime = DateFormat('dd MMM yyyy • hh:mm a').format(now);

    final explicitRef =
        args?['referenceId'] ??
        args?['providerRef'] ??
        args?['externalTransactionId'] ??
        args?['txnId'];
    if (explicitRef != null && explicitRef.toString().isNotEmpty) {
      referenceId = explicitRef.toString();
    } else {
      final rand = DateTime.now().millisecondsSinceEpoch.toString();
      referenceId = "TXN${rand.substring(rand.length - 8)}";
    }

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _scaleAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.45, curve: Curves.elasticOut),
    );

    _confettiAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutQuad),
    );

    _textFadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.35, 0.65, curve: Curves.easeIn),
    );

    _textSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animCtrl,
            curve: const Interval(0.35, 0.65, curve: Curves.easeOutBack),
          ),
        );

    _cardFadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.55, 0.85, curve: Curves.easeIn),
    );

    _cardSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animCtrl,
            curve: const Interval(0.55, 0.85, curve: Curves.easeOutBack),
          ),
        );

    _btnFadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
    );

    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sendMoneyController = Get.isRegistered<SendmoneyController>()
        ? Get.find<SendmoneyController>()
        : null;
    final processController = Get.isRegistered<SendmoneyprocessController>()
        ? Get.find<SendmoneyprocessController>()
        : null;

    String recipient = "Beneficiary";
    String paymentMode = "General Wallet";

    if (processController != null && processController.recipient != null) {
      final rec = processController.recipient!;
      String name = rec["name"] ?? "";
      String phone = rec["phone"] ?? "";
      String acc = rec["accountNumber"] ?? "";

      if (phone.isNotEmpty) {
        recipient = name.isNotEmpty ? "$name ($phone)" : phone;
      } else if (acc.isNotEmpty) {
        String lastFour = acc.length > 4 ? acc.substring(acc.length - 4) : acc;
        recipient = name.isNotEmpty
            ? "$name (A/C ...$lastFour)"
            : "(A/C ...$lastFour)";
      } else if (name.isNotEmpty) {
        recipient = name;
      }
    }

    if (sendMoneyController != null) {
      if (sendMoneyController.isP2PTransfer.value) {
        paymentMode = "P2P Mobile Transfer";
      } else {
        paymentMode = "Bank Transfer";
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),

              Stack(
                alignment: Alignment.center,
                children: [
                  const PulsingBackgroundCircles(),

                  ConfettiEffect(progress: _confettiAnim),

                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Container(
                      height: 84,
                      width: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2E7D32,
                            ).withValues(alpha: 0.3),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              FadeTransition(
                opacity: _textFadeAnim,
                child: SlideTransition(
                  position: _textSlideAnim,
                  child: Column(
                    children: [
                      const Text(
                        "Transfer Successful!",
                        style: TextStyle(
                          fontSize: 22,
                          color: textColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "₹${widget.amount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 38,
                          color: textColor,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              FadeTransition(
                opacity: _cardFadeAnim,
                child: SlideTransition(
                  position: _cardSlideAnim,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        rowItem("Recipient", recipient),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: borderColor, height: 1),
                        ),
                        rowItem("Payment Type", paymentMode),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: borderColor, height: 1),
                        ),
                        rowItem("Date & Time", formattedDateTime),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: borderColor, height: 1),
                        ),
                        GestureDetector(
                          onTap: () {
                            Get.to(
                              () => PaymentDetailsScreen(
                                amount: widget.amount,
                                referenceId: referenceId,
                                creditedTo: recipient,
                                paymentUsing: paymentMode,
                                dateTime: formattedDateTime,
                                isCredit: false,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            color: Colors.transparent,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "View Details",
                                  style: TextStyle(
                                    color: primaryRed,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: primaryRed,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              FadeTransition(
                opacity: _btnFadeAnim,
                child: CustomButton(
                  text: "Go to Dashboard",
                  textsize: context.responsive(14),
                  btncolor: primaryRed,
                  onPressed: () {
                    Get.offAllNamed("/dashboard");
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget rowItem(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: secondaryText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class PaymentDetailsScreen extends StatelessWidget {
  final double amount;
  final String? referenceId;
  final String? creditedTo;
  final String? paymentUsing;
  final String? dateTime;
  final String? title;
  final bool isCredit;

  const PaymentDetailsScreen({
    super.key,
    required this.amount,
    this.referenceId,
    this.creditedTo,
    this.paymentUsing,
    this.dateTime,
    this.title,
    this.isCredit = false,
  });

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments is Map ? (Get.arguments as Map) : null;

    final double resolvedAmount = amount > 0
        ? amount
        : (args?['amount'] as num?)?.toDouble() ?? 0.0;

    final String refId =
        referenceId ??
        args?['referenceId']?.toString() ??
        args?['providerRef']?.toString() ??
        args?['externalTransactionId']?.toString() ??
        args?['txnId']?.toString() ??
        "C2C${DateTime.now().millisecondsSinceEpoch}";

    final String creditedToStr =
        creditedTo ??
        args?['creditedTo']?.toString() ??
        args?['recipientName']?.toString() ??
        (args?['recipient'] is Map
            ? args?['recipient']?['name']?.toString()
            : null) ??
        "General Wallet";

    String paymentUsingStr =
        paymentUsing ??
        args?['paymentUsing']?.toString() ??
        args?['paymentMethod']?.toString() ??
        '';

    if (paymentUsingStr.isEmpty) {
      final savedUpi =
          box.read<String>('upi_id') ??
          box.read<String>('user_vpa') ??
          box.read<String>('vpa');
      final name = (box.read<String>('name') ?? '')
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      final phone =
          (box.read<String>('phone') ??
                  box.read<String>('mobileNumber') ??
                  box.read<String>('remembered_phone') ??
                  '')
              .replaceAll(RegExp(r'\D'), '');

      if (savedUpi != null && savedUpi.isNotEmpty) {
        paymentUsingStr = "UPI ($savedUpi)";
      } else if (name.isNotEmpty) {
        paymentUsingStr = "UPI ($name@upi)";
      } else if (phone.isNotEmpty) {
        final p10 = phone.length > 10
            ? phone.substring(phone.length - 10)
            : phone;
        paymentUsingStr = "UPI ($p10@upi)";
      } else {
        paymentUsingStr = "Transcorp Wallet";
      }
    }

    final String dateTimeStr =
        dateTime ??
        args?['dateTime']?.toString() ??
        args?['formattedDateTime']?.toString() ??
        DateFormat('dd MMM yyyy • hh:mm a').format(DateTime.now());

    final bool resolvedIsCredit = isCredit || (args?['isCredit'] == true);
    final String displayTitle =
        title ??
        args?['title']?.toString() ??
        (resolvedIsCredit ? "Wallet Deposit" : "Money Sent");

    final amountFormatted = resolvedAmount.truncateToDouble() == resolvedAmount
        ? resolvedAmount.toInt().toString()
        : resolvedAmount.toStringAsFixed(2);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Payment Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 20,
            letterSpacing: 0,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFECECEC)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 28,
                        left: 24,
                        right: 24,
                        bottom: 20,
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            displayTitle,
                            style: const TextStyle(
                              color: Color(0xFF111111),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${resolvedIsCredit ? '+' : '-'} ₹$amountFormatted",
                            style: TextStyle(
                              color: resolvedIsCredit
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFF111111),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Row(
                      children: [
                        Container(
                          height: 20,
                          width: 10,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: List.generate(
                                20,
                                (index) => Expanded(
                                  child: Container(
                                    height: 1.5,
                                    color: index % 2 == 0
                                        ? Colors.transparent
                                        : const Color(0xFFECECEC),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 20,
                          width: 10,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          detailRow("Reference ID", refId, copyable: true),
                          detailRow("Credited To", creditedToStr),
                          detailRow("Payment Using", paymentUsingStr),
                          detailRow("Date & Time", dateTimeStr),
                          const Divider(color: Color(0xFFECECEC), height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                resolvedIsCredit
                                    ? "Total Deposited"
                                    : "Total Amount Sent",
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "₹$amountFormatted",
                                style: const TextStyle(
                                  color: Color(0xFF111111),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              GestureDetector(
                onTap: () => Get.offAllNamed("/dashboard"),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Go to Dashboard",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  Widget detailRow(String title, String value, {bool copyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (copyable) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      HapticFeedback.lightImpact();
                      Get.snackbar(
                        "Copied",
                        "$title copied to clipboard",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: const Color(0xFF111111),
                        colorText: Colors.white,
                        borderRadius: 16,
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                      );
                    },
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PulsingBackgroundCircles extends StatefulWidget {
  const PulsingBackgroundCircles({super.key});

  @override
  State<PulsingBackgroundCircles> createState() =>
      _PulsingBackgroundCirclesState();
}

class _PulsingBackgroundCirclesState extends State<PulsingBackgroundCircles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 1.0 + (_controller.value * 0.9),
              child: Opacity(
                opacity: (1.0 - _controller.value).clamp(0.0, 1.0),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2E7D32).withOpacity(0.4),
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ),

            Transform.scale(
              scale: 1.0 + (((_controller.value + 0.5) % 1.0) * 0.9),
              child: Opacity(
                opacity: (1.0 - ((_controller.value + 0.5) % 1.0)).clamp(
                  0.0,
                  1.0,
                ),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF2E7D32).withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ConfettiEffect extends StatelessWidget {
  final Animation<double> progress;
  const ConfettiEffect({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) {
        final val = progress.value;
        if (val == 0.0) return const SizedBox();

        return Stack(
          children: [
            _buildConfetti(val, const Offset(-45, -45), Colors.amber, 11, true),
            _buildConfetti(
              val,
              const Offset(50, -40),
              Colors.blueAccent,
              9,
              false,
            ),
            _buildConfetti(
              val,
              const Offset(-55, 30),
              Colors.redAccent,
              10,
              false,
            ),
            _buildConfetti(
              val,
              const Offset(45, 50),
              Colors.purpleAccent,
              13,
              true,
            ),
            _buildConfetti(val, const Offset(-65, -10), Colors.green, 9, true),
            _buildConfetti(
              val,
              const Offset(60, 15),
              Colors.pinkAccent,
              10,
              false,
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfetti(
    double val,
    Offset target,
    Color color,
    double size,
    bool isCircle,
  ) {
    final currentOffset = Offset(target.dx * val, target.dy * val);
    return Transform.translate(
      offset: currentOffset,
      child: Opacity(
        opacity: (1.0 - val).clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: val * 5.0,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: isCircle ? null : BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
