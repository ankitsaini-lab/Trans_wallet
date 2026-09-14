import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/products/minKYCScreen/minkycScreen_Controller.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/upercasetextformatter.dart';

class MinkycscreenView extends GetView<MinkycscreenController> {
  const MinkycscreenView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => MinkycscreenController());

    return Scaffold(
      backgroundColor: lightprimaryred, // Dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,

        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Image (Top Half)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              "assets/minkycbg.png",
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Custom Back Button in the top left
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight * 0.2,
            left: 20,
            child: GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 6,
                    ), // Align arrow aesthetically in circle
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // White Bottom Sheet Container
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.elliptical(400, 30),
              ),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(color: Colors.white),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive(24),
                      vertical: context.responsive(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // "Verify your identity" centered
                        Center(
                          child: Text(
                            "Verify your identity",
                            style: TextStyle(
                              fontSize: context.responsive(22),
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(height: context.responsive(12)),
                        Center(
                          child: Text(
                            "RBI requires a PAN check before we can open your\nwallet. It takes about 30 seconds and no documents\nare stored on your device.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: context.responsive(13),
                              color: Colors.grey,
                              height: 1.4,
                            ),
                          ),
                        ),
                        SizedBox(height: context.responsive(24)),

                        // "PAN Card Number"
                        Text(
                          "PAN Card Number",
                          style: TextStyle(
                            fontSize: context.responsive(13),
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: context.responsive(12)),

                        Obx(
                          () => TextField(
                            onChanged: controller.onPanChanged,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              fontSize: 14,
                            ),
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(10),
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[a-zA-Z0-9]'),
                              ),
                              UpperCaseTextFormatter(),
                            ],
                            decoration: InputDecoration(
                              hintText: 'ABCDE1234F',
                              hintStyle: TextStyle(
                                letterSpacing: 0,
                                color: Colors.grey.shade400,
                              ),
                              prefixIcon: Icon(
                                Icons.badge_outlined, // ID badge icon
                                color: Colors.grey.shade700,
                                size: 22,
                              ),
                              suffixIcon: controller.isPanVerified.value
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF22C55E),
                                      size: 22,
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xFFF9F9FB),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              errorText: controller.panError.value.isEmpty
                                  ? null
                                  : controller.panError.value,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1.2,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        height40,

                        Obx(
                          () => GestureDetector(
                            onTap: controller.isLoading.value
                                ? null
                                : () => controller.handleButtonAction(),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                vertical: context.responsive(18),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: controller.isLoading.value
                                    ? SizedBox(
                                        height: context.responsive(20),
                                        width: context.responsive(20),
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        controller.isPanVerified.value
                                            ? "Continue"
                                            : "Verify",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: context.responsive(16),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        height10,
                        // const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
