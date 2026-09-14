import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Order%20Card%20screen/order%20card%20screen/ordercard_Controller.dart';
import 'package:transwallet/products/Order%20Card%20screen/Review%20order%20Details/review_order_details_Controller.dart';
import 'package:transwallet/products/Wallet%20Screen/Add%20Money/addmoney_Controller.dart';
import 'package:transwallet/utilities/getStorage.dart';

class PaymentMethodController extends GetxController {
  final RxInt selectedMethod = 1.obs; // 1 = UPI, 2 = Credit/Debit Card, 3 = Net Banking, 4 = General Wallet
  var walletBalance = 0.obs;
  var amount = 897.obs;

  var cardGradient = <Color>[const Color(0xFF111111), const Color(0xFF2C2C2C)].obs;
  var cardStyleName = "Obsidian Black".obs;
  var cardBgImage = 'assets/unioncardblack.png'.obs;

  var deliveryAddress = "General Address".obs;
  var receiverName = "".obs;

  @override
  void onInit() {
    super.onInit();
    walletBalance.value = (box.read('balance') ?? 640).toInt();
    receiverName.value = box.read('name') ?? "User";

    if (Get.isRegistered<OrdercardController>()) {
      final orderCtrl = Get.find<OrdercardController>();
      final activeStyle = orderCtrl.cardStyles[orderCtrl.activeCardIndex.value];
      cardGradient.assignAll(activeStyle["colors"] ?? [const Color(0xFF111111), const Color(0xFF2C2C2C)]);
      cardStyleName.value = activeStyle["name"] ?? "Obsidian Black";
      cardBgImage.value = activeStyle["bgImage"] ?? 'assets/unioncardblack.png';
      amount.value = orderCtrl.amount.value;
    }
    if (Get.isRegistered<ReviewOrderDetailsController>()) {
      final reviewCtrl = Get.find<ReviewOrderDetailsController>();
      receiverName.value = reviewCtrl.name.value.isEmpty ? (box.read('name') ?? "User") : reviewCtrl.name.value;
      deliveryAddress.value = reviewCtrl.address1.value.isEmpty
          ? "General Address"
          : "${reviewCtrl.address1.value}, ${reviewCtrl.city.value}, ${reviewCtrl.state.value} - ${reviewCtrl.pincode.value}";
    }
  }

  String getSelectedMethodName() {
    switch (selectedMethod.value) {
      case 1:
        return "UPI";
      case 2:
        return "Credit / Debit Card";
      case 3:
        return "Net Banking";
      case 4:
        return "General Wallet";
      default:
        return "Payment Method";
    }
  }

  void processPayment() {

    Get.bottomSheet(
      MpinVerifySheetForPayment(
        onSuccess: () => _executePayment(),
        title: "Verify MPIN to Order Card",
        subtitle: "Enter MPIN to authorize ₹${amount.value}.00 from ${getSelectedMethodName()}",
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _executePayment() async {
    Get.toNamed('/payment_processing');

    await Future.delayed(const Duration(seconds: 2));

    if (selectedMethod.value == 4) {
      walletBalance.value -= amount.value;
      box.write('balance', walletBalance.value);
    }

    Get.offAllNamed('/orderdetails', arguments: {
      'amount': amount.value,
      'cardGradient': cardGradient,
      'cardStyleName': cardStyleName.value,
      'receiverName': receiverName.value,
      'deliveryAddress': deliveryAddress.value,
      'paymentMethod': getSelectedMethodName(),
      'cardBgImage': cardBgImage.value,
    });
  }
}