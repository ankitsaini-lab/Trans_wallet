import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Order%20Card%20screen/order%20card%20screen/ordercard_Controller.dart';

class ReviewOrderDetailsController extends GetxController {
  var amount = 150.obs;

  final nameController = TextEditingController();
  final address1Controller = TextEditingController();
  final address2Controller = TextEditingController();
  final pincodeController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final countryController = TextEditingController(text: "India");

  var name = ''.obs;
  var address1 = ''.obs;
  var address2 = ''.obs;
  var pincode = ''.obs;
  var city = ''.obs;
  var state = ''.obs;

  var cardGradient = <Color>[
    const Color(0xFF111111),
    const Color(0xFF2C2C2C),
  ].obs;
  var cardGlowColor = const Color(0xFFFFCC00).obs;
  var cardLabel = "Obsidian Limited".obs;
  var cardTextColor = Colors.white.obs;
  var cardSubColor = Colors.white70.obs;
  var cardBgImage = 'assets/unioncardblack.webp'.obs;
  var useBlackLogos = false.obs;

  @override
  void onInit() {
    super.onInit();

    if (Get.isRegistered<OrdercardController>()) {
      final orderCtrl = Get.find<OrdercardController>();
      final activeStyle = orderCtrl.cardStyles[orderCtrl.activeCardIndex.value];
      cardGradient.assignAll(activeStyle["colors"] ?? [const Color(0xFF111111), const Color(0xFF2C2C2C)]);
      cardGlowColor.value = activeStyle["glowColor"];
      cardLabel.value = activeStyle["label"];
      cardTextColor.value = activeStyle["textColor"] ?? Colors.white;
      cardSubColor.value = activeStyle["subColor"] ?? Colors.white70;
      cardBgImage.value =
          activeStyle["bgImage"] ?? 'assets/unioncardblack.webp';
      useBlackLogos.value = activeStyle["useBlackLogos"] ?? false;
      amount.value = orderCtrl.amount.value;
    }

    nameController.addListener(() => name.value = nameController.text);
    address1Controller.addListener(
      () => address1.value = address1Controller.text,
    );
    address2Controller.addListener(
      () => address2.value = address2Controller.text,
    );
    pincodeController.addListener(() => pincode.value = pincodeController.text);
    cityController.addListener(() => city.value = cityController.text);
    stateController.addListener(() => state.value = stateController.text);
  }

  String? get nameError {
    if (name.value.isEmpty) return null;
    if (name.value.trim().length < 3)
      return "Name must be at least 3 characters";
    return null;
  }

  String? get address1Error {
    if (address1.value.isEmpty) return null;
    if (address1.value.trim().length < 5)
      return "Address must be at least 5 characters";
    return null;
  }

  String? get pincodeError {
    if (pincode.value.isEmpty) return null;
    if (pincode.value.length != 6) return "Pincode must be exactly 6 digits";
    return null;
  }

  String? get cityError {
    if (city.value.isEmpty) return null;
    if (city.value.trim().length < 2)
      return "City must be at least 2 characters";
    return null;
  }

  String? get stateError {
    if (state.value.isEmpty) return null;
    if (state.value.trim().length < 2)
      return "State must be at least 2 characters";
    return null;
  }

  bool get isFormValid {
    return name.value.trim().length >= 3 &&
        address1.value.trim().length >= 5 &&
        pincode.value.length == 6 &&
        city.value.trim().length >= 2 &&
        state.value.trim().length >= 2;
  }

  @override
  void onClose() {
    nameController.dispose();
    address1Controller.dispose();
    address2Controller.dispose();
    pincodeController.dispose();
    cityController.dispose();
    stateController.dispose();
    countryController.dispose();
    super.onClose();
  }
}
