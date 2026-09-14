import 'dart:developer';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Wallet%20Screen/Add%20Money/addmoney_View.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/widgets/premium_visa_card.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/services/api_service.dart';

class DashboardscreenController extends GetxController {
  RxBool isFlipped = false.obs;
  RxBool isVisible = false.obs;

  final ScrollController scrollController = ScrollController();
  final RxBool isScrolled = false.obs;

  void flipCard() {
    isFlipped.value = !isFlipped.value;
  }

  final RxNum totalBalance = RxNum(0);

  Future<void> loadWalletBalance() async {
    if (GetStorage().hasData('balance')) {
      final stored = GetStorage().read('balance');
      if (stored is num) {
        totalBalance.value = stored;
      }
    }
    if (Get.isRegistered<ApiService>()) {
      final res = await ApiService.to.fetchWalletBalance();
      if (res != null && res['balance'] != null) {
        totalBalance.value = res['balance'] is num
            ? res['balance']
            : num.tryParse(res['balance'].toString()) ?? 0;
      }
    }
  }

  final RxList<Map<String, dynamic>> recentTransactions = <Map<String, dynamic>>[].obs;
  final RxBool isTransactionsLoading = false.obs;

  final RxDouble totalIncome = 0.0.obs;
  final RxDouble totalExpenses = 0.0.obs;
  final RxDouble totalSavings = 0.0.obs;

  Future<void> fetchRecentTransactions() async {
    if (!Get.isRegistered<ApiService>()) return;
    isTransactionsLoading.value = true;
    try {
      final res = await ApiService.to.fetchTransactions(pageNumber: 0, pageSize: 20);
      if (res != null && res['items'] is List) {
        final List items = res['items'];
        final List<Map<String, dynamic>> parsedList = [];

        double calcIncome = 0.0;
        double calcExpenses = 0.0;

        for (var item in items) {
          if (item is Map) {
            final type = item['type']?.toString().toUpperCase() ?? '';
            final isCredit = type == 'CREDIT';
            final status = item['transactionStatus']?.toString().toUpperCase() ?? '';
            final isFailed = status.contains('FAIL') || status.contains('REJECT');

            final num amt = (item['amount'] is num)
                ? item['amount']
                : num.tryParse(item['amount']?.toString() ?? '0') ?? 0;

            if (!isFailed) {
              if (isCredit) {
                calcIncome += amt.toDouble();
              } else {
                calcExpenses += amt.toDouble();
              }
            }

            DateTime rawDate = DateTime.now();
            if (item['time'] != null) {
              try {
                rawDate = DateTime.parse(item['time'].toString());
              } catch (_) {}
            }

            String title = "Transaction";
            if (item['otherPartyName'] != null &&
                item['otherPartyName'] is String &&
                (item['otherPartyName'] as String).isNotEmpty) {
              title = item['otherPartyName'];
            } else if (item['description'] != null &&
                item['description'] is String &&
                (item['description'] as String).isNotEmpty) {
              title = item['description'];
            } else if (item['yourWallet'] != null &&
                item['yourWallet'].toString().isNotEmpty) {
              title = "${item['yourWallet']} Wallet";
            } else if (item['transactionType'] != null) {
              title = item['transactionType'].toString();
            }

            final String formattedAmount = isCredit ? "+₹$amt" : "-₹$amt";
            final String subtitle = _formatShortDate(rawDate);

            parsedList.add({
              "title": title,
              "subtitle": subtitle,
              "amount": formattedAmount,
              "isCredit": isCredit,
              "isFailed": isFailed,
              "txRef": item['txRef'],
              "status": status,
              "yourWallet": item['yourWallet'],
            });
          }
        }

        recentTransactions.value = parsedList;
        totalIncome.value = calcIncome;
        totalExpenses.value = calcExpenses;
        totalSavings.value = (calcIncome - calcExpenses) > 0 ? (calcIncome - calcExpenses) : 0.0;
      } else {
        recentTransactions.value = [];
        totalIncome.value = 0.0;
        totalExpenses.value = 0.0;
        totalSavings.value = 0.0;
      }
    } catch (e) {
      log('Error fetching recent transactions in DashboardscreenController: $e');
    } finally {
      isTransactionsLoading.value = false;
    }
  }

  String _formatShortDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $month, $hour:$minute $ampm';
  }

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(() {
      if (scrollController.hasClients) {
        final offset = scrollController.offset;
        if (offset > 10) {
          if (!isScrolled.value) {
            isScrolled.value = true;
          }
        } else {
          if (isScrolled.value) {
            isScrolled.value = false;
          }
        }
      }
    });

    if (Get.isRegistered<ApiService>()) {
      ApiService.to.fetchUserProfile();
      fetchRecentTransactions();
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void toggleVisibility() {
    isVisible.value = !isVisible.value;
  }

  Widget actionBtn(String icon, String text, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset("$icon", height: 25, color: Colors.black),

              const SizedBox(height: 6),

              Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget tile(String l, String t, String amt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFD64550).withOpacity(0.1),
            child: Text(
              l,
              style: const TextStyle(
                color: Color(0xFFD64550),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              t,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Text(
            amt,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: amt.contains("+") ? Colors.green.shade700 : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFront({Key? key}) {
    final box = GetStorage();
    return Obx(
      () => PremiumVisaCard(
        key: key,
        cardNumber: isVisible.value ? "1234567890123456" : "••••••••••••3456",
        cardHolder: box.read('name') ?? "Vince Tallent",
        expiryDate: "12/28",
        cvv: isVisible.value ? "123" : "•••",
        onTap: flipCard,
        topRightAction: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: math.pi / 2,
              child: Icon(Icons.wifi, color: Colors.white70, size: 16),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: toggleVisibility,
              child: Icon(
                isVisible.value ? Icons.visibility : Icons.visibility_off,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBack({Key? key}) {
    return cardBase(
      key: key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 38,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(height: 12),

          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(height: 12, color: Colors.grey.shade300),
                ),

                const SizedBox(width: 10),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: blurWrapper(
                    true,
                    const Text(
                      "123",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Set PIN", style: TextStyle(fontSize: 12)),
              ),
            ),
          ),

          const Spacer(),

          Align(
            alignment: Alignment.bottomRight,
            child: Image.asset(
              'assets/VisaFree.png',
              height: 20,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget cardBase({required Widget child, Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        image: const DecorationImage(
          image: AssetImage('assets/unioncardblack.webp'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFCC00).withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(children: [child]),
    );
  }

  Widget topRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset('assets/WU.png', height: 22, fit: BoxFit.contain),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/WHITE TRANSCORP .png',
              height: 14,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Obx(
              () => GestureDetector(
                onTap: toggleVisibility,
                child: Icon(
                  isVisible.value ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget blurWrapper(bool isVisible, Widget child) {
    print("ert>> isVisible: $isVisible");
    return isVisible
        ? child
        : Text(
            "**** **** **** 3456",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 2,
            ),
          );
  }

  Widget walletCard({required showhide}) {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 200,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF1C1C1E), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                Container(
                  width: 50,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                height12,

                Row(
                  children: [
                    Text(
                      showhide == true ? "**** **** **** 1234" : " ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 15,
            left: 20,
            child: Text("CARD HOLDER", style: TextStyle(color: Colors.white54)),
          ),

          Positioned(
            top: 10,
            right: 10,
            child: Visibility(
              visible: showhide,
              child: GestureDetector(
                onTap: openCardDetails,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.visibility,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 45,
            left: 0,
            right: 0,
            child: Visibility(
              visible: showhide,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(child: SizedBox(width: 5)),
                  Expanded(
                    child: CustomButton(
                      prefixIcon: Icon(Icons.send, color: Colors.black),
                      text: "Transfer",
                      height: 40,
                      btncolor: Colors.white,
                      textColor: Colors.black,
                      onPressed: () {
                        Get.toNamed("/sendmoney");
                      },
                    ),
                  ),
                  width6,
                  Expanded(
                    child: CustomButton(
                      prefixIcon: const Icon(Icons.add, color: Colors.black),
                      text: "Top-up",
                      height: 40,
                      btncolor: Colors.white,
                      textColor: Colors.black,
                      onPressed: () {
                        Get.bottomSheet(
                          const AddmoneyView(showGeneralWalletOption: false),
                          isScrollControlled: true,
                          isDismissible: false,
                          enableDrag: false,
                          backgroundColor: Colors.transparent,
                        );
                      },
                    ),
                  ),
                  width8,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void openCardDetails() {
    Get.dialog(
      Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),

            Center(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Container(
                      height: 240,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1C1C1E), Colors.black],
                        ),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          height30,
                          Container(
                            width: 45,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          height16,

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "1234 5678 9012 3456",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  letterSpacing: 2,
                                ),
                              ),
                              copyIcon("1234 5678 9012 3456"),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Expiry",
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    "12/28",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    "CARD HOLDER",
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    "CVV",
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                  const SizedBox(height: 2),

                                  Row(
                                    children: [
                                      const Text(
                                        "123",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      const SizedBox(width: 6),
                                      copyIcon("123"),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  Positioned(
                    top: 8,
                    right: 20,
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget copyIcon(String text) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: text));
        Get.snackbar(
          "Copied",
          text,
          backgroundColor: Colors.black,
          colorText: Colors.white,
        );
      },
      child: const Icon(Icons.copy, color: Colors.white70, size: 18),
    );
  }

  Widget overlayRow(String text, {bool copy = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),

        if (copy)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: text));
              Get.snackbar(
                "Copied",
                "Copied successfully",
                backgroundColor: Colors.black,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Icon(Icons.copy, color: Colors.white70, size: 18),
          ),
      ],
    );
  }

  Widget detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),

          Row(
            children: [
              Text(value, style: const TextStyle(color: Colors.white)),

              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));

                  Get.snackbar(
                    "Copied",
                    "$title copied",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.black,
                    colorText: Colors.white,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget actionButton(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (title == "Transfer") {
          print("Transfer clicked");
        }
        if (title == "Top Up") {
          print("TopUp clicked");
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
