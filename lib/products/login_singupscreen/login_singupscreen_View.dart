import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/products/login_singupscreen/login_singupscreen_Controller.dart';
import 'package:transwallet/widgets/common_webview_screen.dart';
import 'package:transwallet/widgets/constsize.dart';

class LoginSingupscreenView extends GetView<LoginSingupscreenController> {
  const LoginSingupscreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<LoginSingupscreenController>()
        ? Get.find<LoginSingupscreenController>()
        : Get.put(LoginSingupscreenController());

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: lightprimaryred,
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
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Pinned Top Illustration
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.52,
              child: Image.asset(
                "assets/loginBG.png",
                fit: BoxFit.fill,
                alignment: Alignment.topCenter,
              ),
            ),

            // Scrollable White Card Layer
            Positioned.fill(
              child: SingleChildScrollView(
                controller: controller.scrollController,
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    // Transparent spacer so top illustration is visible
                    SizedBox(height: screenHeight * 0.44),

                    // White curved card that scrolls together with all its content
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.elliptical(450, 40),
                      ),
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          minHeight: screenHeight * 0.72,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 10,
                              offset: Offset(0, -4),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.responsive(24),
                              vertical: context.responsive(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      "Welcome",
                                      style: TextStyle(
                                        fontSize: context.responsive(23),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    SizedBox(height: context.responsive(4)),
                                    Text(
                                      "Step into simpler payments",
                                      style: TextStyle(
                                        fontSize: context.responsive(13.5),
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: context.responsive(18)),

                                // Phone Field
                                _buildPhoneInputField(context, controller),

                                // Error message if any
                                Obx(() {
                                  if (controller.phoneError.value.isNotEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        top: 8,
                                        left: 16,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          controller.phoneError.value,
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: context.responsive(12),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),

                                SizedBox(height: context.responsive(16)),

                                // Terms & Conditions Checkbox
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: Obx(
                                        () => Checkbox(
                                          value: controller.isChecked.value,
                                          onChanged: controller.toggleCheck,
                                          activeColor: primaryRed,
                                          checkColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          side: BorderSide(
                                            color: controller.isChecked.value
                                                ? primaryRed
                                                : Colors.grey.shade700,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => controller.toggleCheck,
                                        child: Text.rich(
                                          TextSpan(
                                            text: "I agree to ",
                                            style: TextStyle(
                                              fontSize: context.responsive(14),
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: "Terms & Conditions",
                                                recognizer: TapGestureRecognizer()
                                                  ..onTap = () {
                                                    Get.to(
                                                      () => const CommonWebViewScreen(
                                                        url:
                                                            "https://transcorpint.com/ppi-policies-and-tc-mobile?search=terms",
                                                        title:
                                                            "Terms & Conditions",
                                                      ),
                                                    );
                                                  },
                                                style: TextStyle(
                                                  fontSize: context.responsive(
                                                    14,
                                                  ),
                                                  fontWeight: FontWeight.w600,
                                                  color: primaryRed,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: context.responsive(22)),

                                // Send OTP Button
                                GestureDetector(
                                  onTap: controller.onPrimaryActionPressed,
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      vertical: context.responsive(16),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Send OTP",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: context.responsive(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height:
                                      context.responsive(24) +
                                      MediaQuery.of(context).padding.bottom,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Obx(() {
              if (controller.isOtpSent.value) {
                return Positioned.fill(
                  child: GestureDetector(
                    onTap: controller.closeOtpPopupOnly,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.65),
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {},
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: context.responsive(24),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: context.responsive(24),
                                vertical: context.responsive(24),
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.elliptical(
                                    context.responsive(500),
                                    context.responsive(50),
                                  ),
                                  topRight: Radius.elliptical(
                                    context.responsive(500),
                                    context.responsive(50),
                                  ),
                                  bottomLeft: Radius.circular(
                                    context.responsive(30),
                                  ),
                                  bottomRight: Radius.circular(
                                    context.responsive(30),
                                  ),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: GestureDetector(
                                      onTap: controller.closeOtpPopupOnly,
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        padding: EdgeInsets.all(
                                          context.responsive(6),
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey.shade100,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 20,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "Verify Code",
                                    style: TextStyle(
                                      fontSize: context.responsive(22),
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: context.responsive(16)),
                                  Text(
                                    "We have sent 6- digit verification code to\n+91 ******${controller.phone.value.length >= 4 ? controller.phone.value.substring(controller.phone.value.length - 4) : controller.phone.value}",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: context.responsive(14),
                                      color: Colors.grey,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // OTP Field
                                  controller.otpField(
                                    onCompleted: (_) => controller.sendOtp(),
                                  ),

                                  Obx(() {
                                    if (controller.otpError.value.isNotEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          controller.otpError.value,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontSize: context.responsive(12),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  }),

                                  const SizedBox(height: 20),

                                  // Resend Code
                                  GestureDetector(
                                    onTap: () {
                                      if (controller.canResend.value) {
                                        controller.resendOtp();
                                      }
                                    },
                                    child: Text.rich(
                                      TextSpan(
                                        text: controller.canResend.value
                                            ? "Didn't receive? "
                                            : "Resend code in ",
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: context.responsive(14),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: controller.canResend.value
                                                ? "Resend OTP"
                                                : "${controller.seconds.value}s",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: controller.canResend.value
                                                  ? Colors.blueAccent
                                                  : primaryRed,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: context.responsive(32)),

                                  // Verify & Proceed Button
                                  GestureDetector(
                                    onTap:
                                        controller.sendOtp, // Calls _verifyOtp
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
                                        child: Text(
                                          "Verify & Proceed",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            fontSize: context.responsive(16),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInputField(
    BuildContext context,
    LoginSingupscreenController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 55,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(249, 249, 249, 1),
            borderRadius: BorderRadius.circular(20),
            border: Border(bottom: BorderSide(color: primaryRed, width: 1.5)),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      "+91",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: context.responsive(15),
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1.0, height: 24, color: Colors.grey.shade300),
              Expanded(
                child: TextField(
                  controller: controller.phoneController,
                  focusNode: controller.phoneFocusNode,
                  keyboardType: TextInputType.phone,
                  autofocus: false,
                  scrollPadding: EdgeInsets.only(
                    bottom: context.responsive(120),
                  ),
                  onChanged: controller.updatePhone,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: context.responsive(15),
                    color: Colors.black,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: "Enter Phone Number",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: context.responsive(15),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.responsive(16),
                      vertical: context.responsive(15),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
