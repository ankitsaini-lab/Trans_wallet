import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/products/login_singupscreen/login_singupscreen_Controller.dart';
import 'package:transwallet/widgets/constsize.dart';

class LoginSingupscreenView extends GetView<LoginSingupscreenController> {
  const LoginSingupscreenView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(LoginSingupscreenController(), permanent: true);

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Pinned Top Illustration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.5,
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
              child: Column(
                children: [
                  // Transparent spacer so top illustration is visible
                  SizedBox(height: screenHeight * 0.46),

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

                              Obx(
                                () => Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(23),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () =>
                                              controller.setLoginMethod('OTP'),
                                          behavior: HitTestBehavior.opaque,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            curve: Curves.easeInOut,
                                            decoration: BoxDecoration(
                                              color: controller.isOtpLogin
                                                  ? primaryRed
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(19),
                                              boxShadow: controller.isOtpLogin
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha: 0.08,
                                                            ),
                                                        blurRadius: 6,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.sms_outlined,
                                                      size: 16,
                                                      color:
                                                          controller.isOtpLogin
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      "Login with OTP",
                                                      style: TextStyle(
                                                        fontSize: context
                                                            .responsive(13),
                                                        fontWeight:
                                                            controller
                                                                .isOtpLogin
                                                            ? FontWeight.w700
                                                            : FontWeight.w500,
                                                        color:
                                                            controller
                                                                .isOtpLogin
                                                            ? Colors.white
                                                            : Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // Option 2: Login with MPIN
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () =>
                                              controller.setLoginMethod('MPIN'),
                                          behavior: HitTestBehavior.opaque,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            curve: Curves.easeInOut,
                                            decoration: BoxDecoration(
                                              color: controller.isMpinLogin
                                                  ? primaryRed
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(19),
                                              boxShadow: controller.isMpinLogin
                                                  ? [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha: 0.08,
                                                            ),
                                                        blurRadius: 6,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(
                                                8.0,
                                              ),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .lock_outline_rounded,
                                                      size: 16,
                                                      color:
                                                          controller.isMpinLogin
                                                          ? Colors.white
                                                          : Colors.black,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      "Login with MPIN",
                                                      style: TextStyle(
                                                        fontSize: context
                                                            .responsive(13),
                                                        fontWeight:
                                                            controller
                                                                .isMpinLogin
                                                            ? FontWeight.w700
                                                            : FontWeight.w500,
                                                        color:
                                                            controller
                                                                .isMpinLogin
                                                            ? Colors.white
                                                            : Colors.black,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: context.responsive(18)),

                              // Phone Field
                              _buildPhoneInputField(
                                context,
                                controller,
                              ),

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

                              // MPIN Field (Shown only when controller.isMpinLogin is true)
                              Obx(() {
                                if (controller.isMpinLogin) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: context.responsive(16)),
                                      Container(
                                        height: 55,
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(
                                            249,
                                            249,
                                            249,
                                            1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border(
                                            bottom: BorderSide(
                                              color: primaryRed,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                              child: Icon(
                                                Icons.lock_outline_rounded,
                                                color: Colors.black87,
                                                size: 20,
                                              ),
                                            ),
                                            Container(
                                              width: 1.0,
                                              height: 24,
                                              color: Colors.grey.shade300,
                                            ),
                                            Expanded(
                                              child: Obx(
                                                () => TextField(
                                                  controller:
                                                      controller.mpinController,
                                                  focusNode:
                                                      controller.mpinFocusNode,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  obscureText: controller
                                                      .isMpinObscure
                                                      .value,
                                                  onChanged:
                                                      controller.updateMpin,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: context
                                                        .responsive(16),
                                                    letterSpacing:
                                                        controller
                                                            .isMpinObscure
                                                            .value
                                                        ? 6
                                                        : 2,
                                                    color: Colors.black,
                                                  ),
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                    LengthLimitingTextInputFormatter(
                                                      4,
                                                    ),
                                                  ],
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        "Enter 4-digit MPIN",
                                                    hintStyle: TextStyle(
                                                      color:
                                                          Colors.grey.shade400,
                                                      fontSize: context
                                                          .responsive(15),
                                                      letterSpacing: 0,
                                                    ),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: context
                                                              .responsive(16),
                                                          vertical: context
                                                              .responsive(15),
                                                        ),
                                                    border: InputBorder.none,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Obx(
                                              () => IconButton(
                                                icon: Icon(
                                                  controller.isMpinObscure.value
                                                      ? Icons
                                                            .visibility_off_outlined
                                                      : Icons
                                                            .visibility_outlined,
                                                  color: Colors.grey.shade600,
                                                  size: 20,
                                                ),
                                                onPressed: controller
                                                    .toggleMpinObscure,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // MPIN Error message if any
                                      Obx(() {
                                        if (controller
                                            .mpinError
                                            .value
                                            .isNotEmpty) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                              left: 16,
                                            ),
                                            child: Text(
                                              controller.mpinError.value,
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: context.responsive(
                                                  12,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      }),

                                      // Forgot MPIN link
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8,
                                          right: 8,
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: GestureDetector(
                                            onTap: () => controller
                                                .setLoginMethod('OTP'),
                                            child: Text(
                                              "Forgot MPIN?",
                                              style: TextStyle(
                                                fontSize: context.responsive(
                                                  13,
                                                ),
                                                fontWeight: FontWeight.w600,
                                                color: primaryRed,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
                                      onTap: () {},
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

                              SizedBox(height: context.responsive(18)),

                              // Send OTP or Login with MPIN Button
                              Obx(
                                () => GestureDetector(
                                  onTap: controller.onPrimaryActionPressed,
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      vertical: context.responsive(14),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Center(
                                      child: Text(
                                        controller.isOtpLogin
                                            ? "Send OTP"
                                            : "Login with MPIN",
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
                              SizedBox(height: context.responsive(16)),

                              // Biometric Login Option (Shown as per available device features)
                              Obx(() {
                                if (!controller.isBiometricAvailable.value) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey.shade300,
                                            thickness: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            "OR",
                                            style: TextStyle(
                                              fontSize: context.responsive(12),
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey.shade300,
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: context.responsive(12)),
                                    InkWell(
                                      onTap: controller.loginWithBiometrics,
                                      borderRadius: BorderRadius.circular(30),
                                      child: Container(
                                        width: double.infinity,
                                        padding: EdgeInsets.symmetric(
                                          vertical: context.responsive(12),
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          border: Border.all(
                                            color: primaryRed.withValues(
                                              alpha: 0.4,
                                            ),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryRed.withValues(
                                                alpha: 0.06,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: controller
                                                  .isBiometricLoading.value
                                              ? SizedBox(
                                                  height: context.responsive(20),
                                                  width: context.responsive(20),
                                                  child: const CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    color: primaryRed,
                                                  ),
                                                )
                                              : FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        controller
                                                            .biometricIcon
                                                            .value,
                                                        color: primaryRed,
                                                        size: context.responsive(
                                                          22,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        "Login with ${controller.biometricLabel.value}",
                                                        style: TextStyle(
                                                          color: Colors
                                                              .black87,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: context
                                                              .responsive(14),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                              SizedBox(height: context.responsive(24)),
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

          // OTP Verification Modal Overlay
          Obx(() {
            if (controller.isOtpSent.value) {
              return Positioned.fill(
                child: GestureDetector(
                  onTap: controller.changeNumber, // Tap outside to dismiss
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.65,
                    ), // Dim background
                    child: Center(
                      child: GestureDetector(
                        onTap: () {}, // Consume tap to prevent dismissing
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: context.responsive(24),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsive(24),
                            vertical: context.responsive(32),
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
                              controller.otpField(onCompleted: (otp) {}),

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
                                onTap: controller.sendOtp, // Calls _verifyOtp
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
              );
            }
            return const SizedBox.shrink();
          }),
        ],
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

