import 'package:flutter/material.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/products/update_KYC/update_KYC_controller.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/custombutton.dart';

class UpdateKycView extends GetView<UpdateKycController> {
  const UpdateKycView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => UpdateKycController());
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        title: Text(
          "Full KYC",
          style: TextStyle(
            color: Colors.black,
            fontSize: context.responsive(18),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset('assets/fullkycBG.png', fit: BoxFit.fitWidth),
          ),

          // Foreground Content
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    // Top Section (Text and Icon)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive(24),
                        vertical: context.responsive(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Complete your",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: context.responsive(24),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Full KYC",
                                  style: TextStyle(
                                    color: primaryRed,
                                    fontSize: context.responsive(24),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: context.responsive(10)),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.responsive(16),
                                    vertical: context.responsive(12),
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      context.responsive(12),
                                    ),
                                    border: Border.all(
                                      color: lightprimaryred,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color.fromRGBO(
                                          0,
                                          0,
                                          0,
                                          0.05,
                                        ),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    gradient: appBarGradient,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Maximum wallet limit",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: context.responsive(12),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "₹ 2,00,000",
                                        style: TextStyle(
                                          color: primaryRed,
                                          fontSize: context.responsive(22),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: context.responsive(10)),

                                Text(
                                  "Full KYC unlocks unrestricted access to wallet features.",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: context.responsive(11),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: context.responsive(10)),

                    // White Bottom Sheet
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive(24),
                          vertical: context.responsive(16),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(context.responsive(30)),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Required Steps for Verification",
                              style: TextStyle(
                                fontSize: context.responsive(18),
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: context.responsive(12)),
                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.zero,
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  _buildStepCard(
                                    context,
                                    "1",
                                    "Upload PAN card",
                                    "Scan your PAN card clearly for identity verification.",
                                  ),
                                  _buildStepCard(
                                    context,
                                    "2",
                                    "Validate Aadhaar OTP",
                                    "Verify the OTP sent to your Aadhaar-linked mobile number.",
                                  ),
                                  _buildStepCard(
                                    context,
                                    "3",
                                    "Video verification",
                                    "Complete a quick video call with a compliance officer.",
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: context.responsive(12)),
                            CustomButton(
                              text: "Get Started",
                              btncolor: primaryRed,
                              borderRadius: context.responsive(30),
                              onPressed: () {
                                controller.startBrowserRedirection();
                              },
                            ),
                            SizedBox(height: context.responsive(10)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Overlay for redirection
          Obx(() {
            if (controller.isRedirecting.value) {
              return _buildRedirectionOverlay(context, controller);
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context,
    String step,
    String title,
    String desc,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: context.responsive(12)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5),
        borderRadius: BorderRadius.circular(context.responsive(16)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.9),
            primaryYellow,
          ],
        ),
        border: Border.all(color: const Color.fromRGBO(0, 0, 0, 0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 5,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: context.responsive(16),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive(8),
                vertical: context.responsive(4),
              ),
              decoration: BoxDecoration(
                color: primaryRed,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(context.responsive(8)),
                  bottomRight: Radius.circular(context.responsive(8)),
                ),
              ),
              child: Text(
                "Step $step",
                style: TextStyle(
                  fontSize: context.responsive(10),
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive(16),
              vertical: context.responsive(10),
            ),
            child: Column(
              children: [
                SizedBox(height: context.responsive(12)),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: context.responsive(16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            desc,
                            style: TextStyle(
                              fontSize: context.responsive(12),
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: context.responsive(16)),
                    _buildIconForStep(context, step),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconForStep(BuildContext context, String step) {
    String iconData;
    if (step == "1") {
      iconData = "assets/uploadpan.png";
    } else if (step == "2") {
      iconData = "assets/validateaadharotp.png";
    } else {
      iconData = "assets/video verification.png";
    }

    return Container(
      width: context.responsive(90),
      height: context.responsive(72),
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Image.asset(iconData),
    );
  }

  Widget _buildRedirectionOverlay(
    BuildContext context,
    UpdateKycController controller,
  ) {
    return Container(
      color: Colors.black.withOpacity(0.88),
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: context.responsive(32)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.85, end: 1.05),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            builder: (context, val, child) {
              return Transform.scale(scale: val, child: child);
            },
            child: Container(
              height: context.responsive(80),
              width: context.responsive(80),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryYellow,
                border: Border.all(color: primaryRed, width: 2),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                color: primaryRed,
                size: context.responsive(36),
              ),
            ),
          ),
          SizedBox(height: context.responsive(32)),
          Text(
            "SECURE REDIRECTION",
            style: TextStyle(
              color: primaryYellow,
              fontSize: context.responsive(11),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: context.responsive(8)),
          Text(
            "Redirecting to KYC Portal...",
            style: TextStyle(
              color: Colors.white,
              fontSize: context.responsive(18),
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: context.responsive(12)),
          Text(
            controller.redirectionStatus.value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              fontSize: context.responsive(13),
              height: 1.4,
            ),
          ),
          SizedBox(height: context.responsive(36)),
          ClipRRect(
            borderRadius: BorderRadius.circular(context.responsive(10)),
            child: SizedBox(
              width: context.responsive(200),
              height: context.responsive(4),
              child: LinearProgressIndicator(
                value: controller.redirectionProgress.value,
                backgroundColor: Colors.white10,
                color: primaryRed,
              ),
            ),
          ),
          SizedBox(height: context.responsive(24)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security_rounded,
                color: const Color(0xFF4CAF50),
                size: context.responsive(14),
              ),
              SizedBox(width: context.responsive(6)),
              Text(
                "256-Bit SSL Secured Session",
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: context.responsive(10),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
