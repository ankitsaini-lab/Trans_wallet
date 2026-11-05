import 'package:flutter/material.dart';
import 'package:get/get.dart';
 
import 'package:transwallet/products/Payment%20Details/payment_details_Controller.dart';

class PaymentDetailsView extends GetView<PaymentDetailsController> {
  const PaymentDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<PaymentDetailsController>()) {
      Get.put(PaymentDetailsController());
    }
    return Scaffold(
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text("Payment Details Screen"),
            ],
          ),
        ),
    );
  }
}