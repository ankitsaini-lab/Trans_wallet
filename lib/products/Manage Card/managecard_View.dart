import 'package:flutter/material.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/notification_button.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:transwallet/products/Manage%20Card/managecard_Controller.dart';
import 'package:transwallet/products/Notification%20screen/notification_View.dart';
import 'package:transwallet/products/Contact%20Support%20screen/contact_Support_screen_View.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/custombutton.dart';

class ManagecardView extends GetView<ManagecardController> {
  const ManagecardView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => ManagecardController());
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        elevation: 0,
        centerTitle: true,
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        title: const Text(
          "Card Details",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 20,
            letterSpacing: 0,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(child: const NotificationButton()),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            children: [
              controller.cardPreview(),
              const SizedBox(height: 24),
              GetBuilder<ManagecardController>(
                builder: (controller) {
                  if (controller.isCardPermanentlyBlocked.value) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Card Permanently Blocked",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "This card has been blocked permanently and can no longer be used. Please contact support to request a new card.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: "Contact Support",
                            textsize: 16,
                            btncolor: Colors.red,
                            textColor: Colors.white,
                            height: 50,
                            borderRadius: 14,
                            onPressed: () {
                              Get.toNamed('/contactsupport');
                            },
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => Row(
                          children: [
                            Expanded(
                              child: actionButton(
                                icon: controller.isCardBlocked.value
                                    ? Icons.credit_card
                                    : Icons.credit_card_off_outlined,
                                label: controller.isCardBlocked.value
                                    ? "Unfreeze"
                                    : "Freeze card",
                                onTap: controller.showFreezeCardBottomSheet,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: actionButton(
                                icon: Icons.password_rounded,
                                label: "Reset PIN",
                                onTap: controller.showResetPinDialog,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        "Manage Card",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(
                        () => controller.isLoadingPreferences.value
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 32),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    featureTile(
                                      "ATM",
                                      controller.atm,
                                      Icons.credit_card,
                                      true,
                                      maxLimit: 10000,
                                    ),
                                    featureTile(
                                      "POS",
                                      controller.pos,
                                      Icons.point_of_sale,
                                      true,
                                      maxLimit: 200000,
                                    ),
                                    featureTile(
                                      "ECOM",
                                      controller.ecom,
                                      Icons.storefront_outlined,
                                      true,
                                      maxLimit: 200000,
                                    ),
                                    featureTile(
                                      "Contactless",
                                      controller.contactless,
                                      Icons.contactless_outlined,
                                      true,
                                      maxLimit: 200000,
                                      // isLast: true,
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      height20,
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          onPressed: controller.showPermanentBlockBottomSheet,

                          child: const Text(
                            "Permanent Block Card",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lightprimaryred,
                border: Border.all(color: primaryYellow, width: 1.5),
              ),
              child: Icon(icon, color: Colors.black, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
