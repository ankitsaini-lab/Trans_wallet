import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Profile%20screen/profile%20details/profile_details_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/utilities/string_extensions.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/user_avatar.dart';

class ProfileDetailsView extends StatelessWidget {
  const ProfileDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileDetailsController());

    const Color backgroundColor = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        title: Text(
          "Profile Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: context.responsive(18),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: primaryRed,
          backgroundColor: Colors.white,
          onRefresh: () => controller.refreshProfile(showSnackbar: false),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: context.responsive(20),
              vertical: context.responsive(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Profile Hero Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: context.responsive(22),
                    horizontal: context.responsive(16),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.responsive(22)),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.025),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar with edit photo button
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: lightprimaryred,
                                width: 2.5,
                              ),
                            ),
                            child: Obx(
                              () => UserAvatar(
                                size: context.responsive(84),
                                name: controller.name.value,
                                imageUrl:
                                    controller.profilePictureUrl.value.isNotEmpty
                                        ? controller.profilePictureUrl.value
                                        : null,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              controller.uploadProfilePicture();
                            },
                            child: Container(
                              padding: EdgeInsets.all(context.responsive(6)),
                              decoration: BoxDecoration(
                                color: primaryRed,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryRed.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: context.responsive(13),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: context.responsive(12)),

                      // User Name
                      Obx(
                        () => Text(
                          formatUserName(controller.name.value),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF111111),
                            fontSize: context.responsive(18),
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      SizedBox(height: context.responsive(4)),

                      // Subtitle (Phone or Email)
                      Obx(
                        () => Text(
                          controller.phone.value.isNotEmpty
                              ? controller.phone.value
                              : (controller.email.value.isNotEmpty
                                  ? controller.email.value
                                  : "TransWallet Customer"),
                          style: TextStyle(
                            color: const Color(0xFF64748B),
                            fontSize: context.responsive(13),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: context.responsive(12)),

                      // Verification Status Badge
                      Obx(() {
                        final bool isFull = controller.isKycCompleted.value;
                        final bool isMin = controller.isMinKycCompleted.value;

                        final Color bgColor;
                        final Color borderColor;
                        final Color textColor;
                        final IconData icon;
                        final String label;

                        if (isFull) {
                          bgColor = const Color(0xFFDCFCE7);
                          borderColor = const Color(0xFFBBF7D0);
                          textColor = const Color(0xFF16A34A);
                          icon = Icons.verified_rounded;
                          label = "Full KYC Verified";
                        } else if (isMin) {
                          bgColor = const Color(0xFFE0F2FE);
                          borderColor = const Color(0xFFBAE6FD);
                          textColor = const Color(0xFF0284C7);
                          icon = Icons.shield_outlined;
                          label = "Min KYC Verified • Upgrade";
                        } else {
                          // KYC Pending
                          bgColor = const Color(0xFFFEF3C7);
                          borderColor = const Color(0xFFFDE68A);
                          textColor = const Color(0xFFD97706);
                          icon = Icons.access_time_filled_rounded;
                          label = "KYC Pending • Tap to Verify";
                        }

                        return InkWell(
                          onTap: isFull ? null : controller.handleKycAction,
                          borderRadius: BorderRadius.circular(
                            context.responsive(20),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.responsive(12),
                              vertical: context.responsive(5),
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(
                                context.responsive(20),
                              ),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icon,
                                  size: context.responsive(14),
                                  color: textColor,
                                ),
                                SizedBox(width: context.responsive(5)),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: context.responsive(11.5),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                SizedBox(height: context.responsive(22)),

                // 2. Section: Personal Information
                Text(
                  "Personal Information",
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: context.responsive(15),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: context.responsive(10)),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.responsive(20)),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Full Name
                      Obx(
                        () => _buildDetailRow(
                          context,
                          icon: Icons.person_outline_rounded,
                          iconColor: const Color(0xFF0284C7),
                          iconBgColor: const Color(0xFFE0F2FE),
                          label: "Full Name",
                          value: formatUserName(controller.name.value),
                          copyValue: controller.name.value,
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // Phone Number
                      Obx(
                        () => _buildDetailRow(
                          context,
                          icon: Icons.phone_android_rounded,
                          iconColor: const Color(0xFF16A34A),
                          iconBgColor: const Color(0xFFDCFCE7),
                          label: "Phone Number",
                          value: controller.phone.value.isNotEmpty
                              ? controller.phone.value
                              : "Not provided",
                          copyValue: controller.phone.value,
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // Email Address
                      Obx(
                        () => _buildDetailRow(
                          context,
                          icon: Icons.mail_outline_rounded,
                          iconColor: const Color(0xFFD97706),
                          iconBgColor: const Color(0xFFFEF3C7),
                          label: "Email Address",
                          value: controller.email.value.isNotEmpty
                              ? controller.email.value
                              : "Not provided",
                          copyValue: controller.email.value.isNotEmpty
                              ? controller.email.value
                              : null,
                        ),
                      ),

                      // Date of birth (only if available)
                      Obx(() {
                        if (controller.formattedDob.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            _buildDetailRow(
                              context,
                              icon: Icons.cake_outlined,
                              iconColor: const Color(0xFF7C3AED),
                              iconBgColor: const Color(0xFFEDE9FE),
                              label: "Date of Birth",
                              value: controller.formattedDob,
                            ),
                          ],
                        );
                      }),

                      // Address (only if available)
                      Obx(() {
                        if (controller.address.value.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            _buildDetailRow(
                              context,
                              icon: Icons.location_on_outlined,
                              iconColor: primaryRed,
                              iconBgColor: lightprimaryred,
                              label: "Address",
                              value: controller.address.value,
                              copyValue: controller.address.value,
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

                SizedBox(height: context.responsive(22)),

                // 3. Need Help? Card (Redirects to Contact Support)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(context.responsive(20)),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.025),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Get.toNamed('/contactsupport');
                      },
                      borderRadius: BorderRadius.circular(
                        context.responsive(20),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(context.responsive(16)),
                        child: Row(
                          children: [
                            Container(
                              height: context.responsive(48),
                              width: context.responsive(48),
                              decoration: BoxDecoration(
                                color: lightprimaryred,
                                borderRadius: BorderRadius.circular(
                                  context.responsive(14),
                                ),
                              ),
                              child: const Icon(
                                Icons.support_agent_rounded,
                                color: primaryRed,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: context.responsive(14)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Need Help?",
                                    style: TextStyle(
                                      fontSize: context.responsive(15.5),
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF111111),
                                    ),
                                  ),
                                  SizedBox(height: context.responsive(3)),
                                  Text(
                                    "Contact our support team for quick help.",
                                    style: TextStyle(
                                      fontSize: context.responsive(12),
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: context.responsive(8)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: context.responsive(14),
                                vertical: context.responsive(8),
                              ),
                              decoration: BoxDecoration(
                                color: primaryRed,
                                borderRadius: BorderRadius.circular(
                                  context.responsive(12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryRed.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Contact",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: context.responsive(12.5),
                                    ),
                                  ),
                                  SizedBox(width: context.responsive(4)),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Colors.white,
                                    size: context.responsive(10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: context.responsive(24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    String? copyValue,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive(16),
        vertical: context.responsive(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: context.responsive(38),
            width: context.responsive(38),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(context.responsive(12)),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: iconColor,
              size: context.responsive(19),
            ),
          ),
          SizedBox(width: context.responsive(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.responsive(11.5),
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: context.responsive(2)),
                Text(
                  value.isNotEmpty ? value : "—",
                  style: TextStyle(
                    fontSize: context.responsive(14),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          if (copyValue != null && copyValue.trim().isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.copy_rounded,
                color: Color(0xFF94A3B8),
                size: 18,
              ),
              splashRadius: 18,
              tooltip: "Copy",
              onPressed: () {
                final controller = Get.find<ProfileDetailsController>();
                controller.copyText(context, copyValue, label);
              },
            ),
        ],
      ),
    );
  }
}
