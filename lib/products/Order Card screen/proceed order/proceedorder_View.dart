import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Order%20Card%20screen/proceed%20order/proceedorder_Controller.dart';

class ProceedorderView extends GetView<ProceedorderController> {
  const ProceedorderView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ProceedorderController>()) {
      Get.put(ProceedorderController());
    } 
    return Scaffold(
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text("Proceed Order Screen"),
            ],
          ),
        ),
    );
  }
}