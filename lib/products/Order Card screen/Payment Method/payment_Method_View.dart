import 'package:flutter/material.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Notification%20screen/notification_View.dart';
import 'package:transwallet/products/Order%20Card%20screen/Payment%20Method/payment_Method_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/widgets/notification_button.dart';

class PaymentMethodView extends GetView<PaymentMethodController> {
  const PaymentMethodView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => PaymentMethodController());

    const Color primaryRed = Color(0xFFE53935);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),

        title: const Text(
          "Payment Method",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: const [NotificationButton(), SizedBox(width: 20)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildCombinedCardAndPricingTile(),
                    const SizedBox(height: 24),
                    _buildDeliveryAddressCard(),
                    const SizedBox(height: 24),
                    const Text(
                      "Payment Method",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPaymentOptions(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildBottomPaymentBar(primaryRed),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedCardAndPricingTile() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECECEC), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Obx(
                () => Container(
                  width: 60,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    image: DecorationImage(
                      image: AssetImage(controller.cardBgImage.value),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Prepaid Card",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "1 Card",
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFECECEC), height: 1, thickness: 1.5),
          ),
          _buildPricingRow("Card Fee", "₹499"),
          const SizedBox(height: 14),
          _buildPricingRow("Annual Maintenance", "₹299"),
          const SizedBox(height: 14),
          _buildPricingRow("Delivery", "₹99"),
          const SizedBox(height: 14),
          _buildPricingRow("GST", "₹0"),
          const SizedBox(height: 18),
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Amount",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "₹${controller.amount.value}",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryAddressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECEC), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: primaryYellow),
              color: primaryRed.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Delivery Address",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFECECEC),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Obx(
                  () => Text(
                    controller.receiverName.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Obx(
                  () => Text(
                    controller.deliveryAddress.value,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions() {
    return Column(
      children: [
        _buildPaymentOptionTile(
          value: 1,
          title: "UPI",
          subtitle: "Pay securely using UPI",
          logo: _buildLogoBox(
            const Text(
              "UPI",
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentOptionTile(
          value: 2,
          title: "Credit / Debit Card",
          subtitle: "Visa, Mastercard, RuPay",
          logo: _buildLogoBox(
            const Icon(
              Icons.credit_card_outlined,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentOptionTile(
          value: 3,
          title: "Net Banking",
          subtitle: "All major banks",
          logo: _buildLogoBox(
            const Icon(
              Icons.account_balance_outlined,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentOptionTile(
          value: 4,
          title: "General Wallet",
          subtitle: "Supported wallets",
          logo: _buildLogoBox(
            const Icon(
              Icons.wallet_outlined,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptionTile({
    required int value,
    required String title,
    required String subtitle,
    required Widget logo,
  }) {
    return Obx(() {
      final isSelected = controller.selectedMethod.value == value;

      return GestureDetector(
        onTap: () => controller.selectedMethod.value = value,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 04),
              ),
            ],
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECECEC), width: 1.5),
          ),
          child: Row(
            children: [
              logo,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? primaryRed : const Color(0xFFD1D5DB),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: isSelected
                    ? Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: primaryRed,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLogoBox(Widget child) {
    return Container(
      width: 36,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFECECEC), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: child,
    );
  }

  Widget _buildBottomPaymentBar(Color primaryRed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Payable",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Obx(
                () => Text(
                  "₹${controller.amount.value}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CustomButton(
            text: "Pay ₹897",
            btncolor: primaryRed,
            textColor: Colors.white,
            onPressed: () {
              controller.processPayment();
            },
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 12,
                color: Color(0xFF9CA3AF),
              ),
              SizedBox(width: 6),
              Text(
                "Secure payment",
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
