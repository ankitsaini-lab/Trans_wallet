import 'package:flutter/material.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/notification_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Notification%20screen/notification_View.dart';
import 'package:transwallet/products/Order%20Card%20screen/Review%20order%20Details/review_order_details_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/widgets/textfieldwidget.dart';

class ReviewOrderDetailsView extends GetView<ReviewOrderDetailsController> {
  const ReviewOrderDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => ReviewOrderDetailsController());

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
          "Delivery Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          const NotificationButton(),
          const SizedBox(width: 20),
        ],
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
                    _buildHorizontalCardTile(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      Icons.person_outline_rounded,
                      "Card Details",
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => CustomTextField(
                        label: "Name on Card",
                        controller: controller.nameController,
                        errorText: controller.nameError,
                        keyboardType: TextInputType.name,
                        hintText: "Enter First Name",
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(
                      Icons.location_on_outlined,
                      "Delivery Address",
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => CustomTextField(
                        label: "Address Line 1",
                        controller: controller.address1Controller,
                        errorText: controller.address1Error,
                        keyboardType: TextInputType.streetAddress,
                        hintText: "Enter Address",
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: "Address Line 2 (Optional)",
                      controller: controller.address2Controller,
                      keyboardType: TextInputType.streetAddress,
                      hintText: "Enter Address",
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Obx(
                            () => CustomTextField(
                              label: "Pincode",
                              controller: controller.pincodeController,
                              errorText: controller.pincodeError,
                              keyboardType: TextInputType.number,
                              hintText: "Enter Pincode",
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: CustomTextField(
                            label: "Country",
                            controller: controller.countryController,
                            enabled: false,
                            hintText: "India",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Obx(
                            () => _buildDropdownField(
                              label: "State",
                              value: controller.state.value,
                              onTap: _showStatePicker,
                              errorText: controller.stateError,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Obx(
                            () => _buildDropdownField(
                              label: "City",
                              value: controller.city.value,
                              onTap: _showCityPicker,
                              errorText: controller.cityError,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _buildProceedButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCardTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECECEC), width: 1.5),
      ),
      child: Row(
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
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Prepaid Card",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: primaryRed,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Selected",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: primaryRed,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryRed.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF111111)),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required VoidCallback onTap,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: errorText != null ? Colors.red : const Color(0xFFECECEC),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value.isEmpty ? "Select" : value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: value.isEmpty
                        ? FontWeight.normal
                        : FontWeight.bold,
                    color: value.isEmpty
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF111111),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  void _showStatePicker() {
    final states = [
      "Delhi",
      "Maharashtra",
      "Karnataka",
      "Rajasthan",
      "Uttar Pradesh",
      "Tamil Nadu",
      "Gujarat",
      "West Bengal",
      "Telangana",
      "Punjab",
    ];
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select State",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: states.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(states[index]),
                    onTap: () {
                      controller.stateController.text = states[index];
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCityPicker() {
    final cities = [
      "New Delhi",
      "Mumbai",
      "Bengaluru",
      "Jaipur",
      "Noida",
      "Chennai",
      "Pune",
      "Ahmedabad",
      "Kolkata",
      "Hyderabad",
    ];
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select City",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: cities.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(cities[index]),
                    onTap: () {
                      controller.cityController.text = cities[index];
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProceedButton() {
    return Obx(() {
      final isEnabled = controller.isFormValid;
      return CustomButton(
        text: "Continue to Review",
        btncolor: isEnabled ? primaryRed : Colors.grey.shade300,
        textColor: isEnabled ? Colors.white : Colors.grey.shade600,
        onPressed: () {
          if (isEnabled) {
            Get.toNamed('/paymentmethod');
          }
        },
      );
    });
  }
}
