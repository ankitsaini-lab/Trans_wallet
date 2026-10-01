import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/modules/vkyc/controllers/vkyc_controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/custombutton.dart';

class VkycTestView extends GetView<VkycController> {
  const VkycTestView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(VkycController());

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        elevation: 0,
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        title: Text(
          "Video KYC Test",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: context.responsive(18),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.responsive(24)),
          child: Column(
            children: [
              SizedBox(height: context.responsive(20)),
              Container(
                padding: EdgeInsets.all(context.responsive(24)),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryYellow.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.videocam_rounded,
                  size: context.responsive(64),
                  color: primaryYellow,
                ),
              ),
              SizedBox(height: context.responsive(32)),
              Text(
                "Complete Video KYC",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: context.responsive(22),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: context.responsive(12)),
              Text(
                "This is a test Video KYC flow designed to simulate provider redirection and deep-link verification.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: context.responsive(14),
                  height: 1.5,
                ),
              ),
              SizedBox(height: context.responsive(32)),
              Container(
                padding: EdgeInsets.all(context.responsive(16)),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(context.responsive(16)),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      Icons.shield_outlined,
                      "Simulated Provider Portal",
                      "Opens in-app webview testing environment",
                    ),
                    Divider(color: Colors.white.withValues(alpha: 0.1), height: 24),
                    _buildInfoRow(
                      context,
                      Icons.link_rounded,
                      "Deep Link Handling",
                      "Intercepts transwallet://vkyc/success & cancel",
                    ),
                  ],
                ),
              ),
              const Spacer(),
              CustomButton(
                text: "Start VKYC",
                btncolor: primaryRed,
                borderRadius: context.responsive(30),
                onPressed: () {
                  controller.startTestVkyc();
                },
              ),
              SizedBox(height: context.responsive(16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Icon(icon, color: primaryYellow, size: context.responsive(24)),
        SizedBox(width: context.responsive(16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: context.responsive(14),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: context.responsive(12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
