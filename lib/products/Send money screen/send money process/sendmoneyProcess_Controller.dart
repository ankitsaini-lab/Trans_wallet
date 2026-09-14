import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/products/Send%20money%20screen/sendMoney_Controller.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/products/Wallet%20Screen/Add%20Money/addmoney_Controller.dart';
import 'package:transwallet/utilities/getStorage.dart';

class SendmoneyprocessController extends GetxController {
  var balance = 0.0.obs;
  var enteredAmount = ''.obs;
  var isLoading = false.obs;
  var selectedPreset = 0.obs;
  var noteController = TextEditingController();

  Map<String, String>? recipient;

  @override
  void onInit() {
    super.onInit();
    balance.value = (box.read('balance') ?? 1600).toDouble();
    if (Get.arguments != null) {
      recipient = Get.arguments as Map<String, String>;
    }
  }

  double get amount {
    String cleaned = enteredAmount.value.replaceAll(',', '');
    return double.tryParse(cleaned.isEmpty ? "0" : cleaned) ?? 0.0;
  }

  void setAmount(String value) {
    selectedPreset.value = 0; // Clear preset selection when typing manually
    String current = enteredAmount.value;

    if (value == "back") {
      if (current.isNotEmpty) {
        enteredAmount.value = current.substring(0, current.length - 1);
      }
      return;
    }

    if (value == "," && current.contains(",")) return;
    if (current == "0" && value == "0") return;

    if (current == "0" && value != ",") {
      enteredAmount.value = value;
      return;
    }

    if (enteredAmount.value.length < 8) {
      // basic limit
      enteredAmount.value += value;
    }
  }

  void setPreset(int value) {
    selectedPreset.value = value;
    enteredAmount.value = value.toString();
  }

  void proceedToPassword() {
    if (amount > 0) {
      // The design has a password screen instead of a bottom sheet
      Get.toNamed(
        '/SendMoneyPasswordView',
        arguments: {
          'amount': amount,
          'recipient': recipient,
          'note': noteController.text,
        },
      );
    }
  }

  // We will keep these existing methods so it doesn't break anything calling them
  Future<void> addMoney() async {
    proceedToPassword();
  }

  Future<void> _executeSendMoney() async {
    // Moved logic to password screen
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

  const PaymentSuccessScreen({super.key, required this.amount});

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
      Get.offNamed(
        '/payment_after_success',
        arguments: {'amount': widget.amount},
      );
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
            const Text(
              "Payment Successful!",
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "₹${widget.amount.toStringAsFixed(2)} added to wallet",
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

    final now = DateTime.now();
    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    final day = now.day;
    final month = months[now.month - 1];
    final year = now.year;
    final hour = now.hour > 12
        ? now.hour - 12
        : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? "PM" : "AM";
    formattedDateTime = "$day $month $year • $hour:$minute $period";

    final rand = DateTime.now().millisecondsSinceEpoch.toString();
    referenceId = "TXN${rand.substring(rand.length - 8)}";

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
      backgroundColor: Colors.white,
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
                            color: const Color(0xFF2E7D32).withOpacity(0.3),
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
                          color: Color(0xFF111111),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "₹${widget.amount.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 38,
                          color: Color(0xFF111111),
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
                      gradient: LinearGradient(
                        colors: [const Color(0xFFF9FBF9), Colors.white],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFECECEC)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
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
                          child: Divider(color: Color(0xFFECECEC), height: 1),
                        ),
                        rowItem("Payment Type", paymentMode),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Color(0xFFECECEC), height: 1),
                        ),
                        rowItem("Date & Time", formattedDateTime),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Color(0xFFECECEC), height: 1),
                        ),
                        GestureDetector(
                          onTap: () {
                            Get.toNamed('/payment_processing');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            color: Colors.transparent,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "View Details",
                                  style: TextStyle(
                                    color: Color(0xFF111111),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: Color(0xFF111111),
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
                  btncolor: const Color(0xFF111111),
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
            color: Color(0xFF6B7280),
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
              color: Color(0xFF111111),
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

  const PaymentDetailsScreen({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: appBarGradient)),
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
                          const Text(
                            "Wallet Deposit",
                            style: TextStyle(
                              color: Color(0xFF111111),
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "+ ₹${amount.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
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
                          detailRow(
                            "Reference ID",
                            "aec68852-f711-4b7d-9e8e-c44bu",
                          ),
                          detailRow("Credited To", "General Wallet"),
                          detailRow("Payment Using", "UPI (janedoe@upi)"),
                          detailRow("Date & Time", "30 Nov 2024 • 03:53 PM"),
                          const Divider(color: Color(0xFFECECEC), height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total Deposited",
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "₹${amount.toStringAsFixed(2)}",
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
                onTap: () {
                  Get.snackbar(
                    "Success",
                    "Receipt details shared successfully!",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFF111111),
                    colorText: Colors.white,
                    borderRadius: 16,
                    margin: const EdgeInsets.all(16),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Share Receipt",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Get.offAllNamed("/dashboard"),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFECECEC)),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Go to Dashboard",
                    style: TextStyle(
                      color: Color(0xFF111111),
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

  Widget detailRow(String title, String value) {
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
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
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
