import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Profile%20screen/profilescreen_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/globalbottombar/Globalbottombar_View.dart';
import 'package:transwallet/utilities/string_extensions.dart';
import 'package:transwallet/widgets/user_avatar.dart';
import 'package:transwallet/products/Profile%20screen/change_pin/change_pin_view.dart';
import 'package:transwallet/products/Profile%20screen/widgets/profile_info_sheets.dart';

class ProfilescreenView extends GetView<ProfilescreenController> {
  const ProfilescreenView({super.key});

  @override
  ProfilescreenController get controller {
    if (!Get.isRegistered<ProfilescreenController>()) {
      return Get.put(ProfilescreenController());
    }
    return Get.find<ProfilescreenController>();
  }

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ProfilescreenController>()) {
      Get.put(ProfilescreenController());
    }

    final Color backgroundColor = const Color(0xFFF9FAFB);

    return Scaffold(
      extendBody: true,
      backgroundColor: backgroundColor,
      bottomNavigationBar: GlobalbottombarView(seletedIndex: 3.obs),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(
              height: context.responsive(248),
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ClipPath(
                      clipper: _HeaderClipper(),
                      child: Container(
                        height: context.responsive(200),
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage("assets/dashboardbg.png"),
                            fit: BoxFit.cover,
                          ),
                        ),
                        padding: EdgeInsets.only(top: context.responsive(60)),
                        alignment: Alignment.topCenter,
                        child: Text(
                          "My Profile",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: context.responsive(18),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: context.responsive(140),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      clipBehavior: Clip.none,
                      children: [
                        Obx(
                          () => GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            // onTap: controller.isUploadingImage.value
                            //     ? null
                            //     : () => controller.uploadProfilePicture(),
                            child: UserAvatar(
                              size: context.responsive(100),
                              name: controller.userName.value,
                              imageFile: controller.localImageFile.value,
                              imageUrl:
                                  controller.profilePictureUrl.value.isNotEmpty
                                  ? controller.profilePictureUrl.value
                                  : null,
                              isLoading: controller.isUploadingImage.value,
                            ),
                          ),
                        ),
                        // Obx(
                        //   () => GestureDetector(
                        //     behavior: HitTestBehavior.opaque,
                        //     onTap: controller.isUploadingImage.value
                        //         ? null
                        //         : () {
                        //             HapticFeedback.lightImpact();
                        //             controller.uploadProfilePicture();
                        //           },
                        //     child: Container(
                        //       padding: EdgeInsets.all(context.responsive(6)),
                        //       decoration: BoxDecoration(
                        //         color: controller.isUploadingImage.value
                        //             ? Colors.grey
                        //             : primaryRed,
                        //         shape: BoxShape.circle,
                        //         border: Border.all(color: Colors.white, width: 2),
                        //         boxShadow: [
                        //           BoxShadow(
                        //             color: primaryRed.withValues(alpha: 0.35),
                        //             blurRadius: 6,
                        //             offset: const Offset(0, 2),
                        //           ),
                        //         ],
                        //       ),
                        //       child: Icon(
                        //         Icons.camera_alt_rounded,
                        //         color: Colors.white,
                        //         size: context.responsive(13),
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.responsive(12)),
            Obx(
              () => Text(
                formatUserName(
                  controller.userName.value.isNotEmpty
                      ? controller.userName.value
                      : box.read('name'),
                ),
                style: TextStyle(
                  fontSize: context.responsive(18),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: context.responsive(4)),
            Obx(
              () => controller.userPhone.value.isNotEmpty
                  ? Text(
                      controller.userPhone.value,
                      style: TextStyle(
                        fontSize: context.responsive(14),
                        color: Colors.grey.shade600,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(height: context.responsive(24)),

            // // Cards Section
            // _buildSection(
            //   context,
            //   title: "Cards",
            //   children: [
            //     _buildRow(
            //       context,
            //       iconAsset: "assets/ordernewcard.svg",
            //       title: "Order New Card",
            //       onTap: () => Get.toNamed('/ordercard'),
            //     ),
            //   ],
            // ),

            // Account Section
            _buildSection(
              context,
              title: "Account",
              children: [
                _buildRow(
                  context,
                  iconAsset: "assets/personaldetails.svg",
                  title: "Personal Details",
                  onTap: () => Get.toNamed('/profiledetails'),
                ),
                _buildDivider(context),
                Obx(() {
                  final bool isVerified = controller.isKycVerified.value;
                  final bool isReview = controller.isKycUnderReview.value;

                  final String subtitle;
                  final Color accentColor;
                  final Color bgColor;
                  final Color borderColor;
                  final IconData statusIcon;
                  final String label;

                  if (isVerified) {
                    subtitle = "Account fully verified";
                    accentColor = const Color(0xFF16A34A);
                    bgColor = const Color(0xFFF0FDF4);
                    borderColor = const Color(0xFFBBF7D0);
                    statusIcon = Icons.verified_rounded;
                    label = "Verified";
                  } else if (isReview) {
                    subtitle = "Verification in progress • Allow 24–48h";
                    accentColor = const Color(0xFFD97706);
                    bgColor = const Color(0xFFFFFBEB);
                    borderColor = const Color(0xFFFDE68A);
                    statusIcon = Icons.schedule_rounded;
                    label = "Under Review";
                  } else {
                    subtitle = "Action required • Tap to complete Full KYC";
                    accentColor = const Color(0xFF0284C7);
                    bgColor = const Color(0xFFF0F9FF);
                    borderColor = const Color(0xFFBAE6FD);
                    statusIcon = Icons.shield_outlined;
                    label = "Min KYC";
                  }

                  return _buildRow(
                    context,
                    iconAsset: "assets/kyc.svg",
                    title: "KYC & Verification",
                    subtitle: subtitle,
                    trailingWidget: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsive(8),
                        vertical: context.responsive(3.5),
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(
                          context.responsive(14),
                        ),
                        border: Border.all(color: borderColor, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: context.responsive(12),
                            color: accentColor,
                          ),
                          SizedBox(width: context.responsive(4)),
                          Text(
                            label,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: context.responsive(11),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: controller.handleKycTap,
                  );
                }),
              ],
            ),

            // Security Section
            _buildSection(
              context,
              title: "Security",
              children: [
                _buildRow(
                  context,
                  iconAsset: "assets/changepin.svg",
                  title: "Change MPIN",
                  onTap: () {
                    Get.to(() => const ChangePinView());
                  },
                ),
              ],
            ),

            // Support Section
            _buildSection(
              context,
              title: "Support",
              children: [
                _buildRow(
                  context,
                  iconAsset: "assets/contactus.svg",
                  title: "Contact Support",
                  onTap: () => Get.toNamed('/contactsupport'),
                ),
                _buildDivider(context),
                _buildRow(
                  context,
                  iconAsset: "assets/help.svg",
                  title: "FAQs",
                  onTap: () => ProfileInfoSheets.openPolicyWebView(
                    title: "FAQs",
                    policyUrl: "https://transcorpint.com/ppi-faq-mobile",
                  ),
                ),
                _buildDivider(context),
                _buildRow(
                  context,
                  iconAsset: "assets/termsandpolicy.svg",
                  title: "Terms & Conditions",
                  onTap: () => ProfileInfoSheets.openPolicyWebView(
                    title: "Terms & Conditions",
                    policyUrl:
                        "https://transcorpint.com/ppi-policies-and-tc-mobile?search=terms",
                  ),
                ),
                _buildDivider(context),
                _buildRow(
                  context,
                  iconData: Icons.privacy_tip_outlined,
                  title: "Privacy Policy",
                  onTap: () => ProfileInfoSheets.openPolicyWebView(
                    title: "Privacy Policy",
                    policyUrl:
                        "https://transcorpint.com/ppi-policies-and-tc-mobile?search=privacy",
                  ),
                ),
              ],
            ),

            SizedBox(height: context.responsive(16)),

            // Logout Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.responsive(20)),
              child: ElevatedButton(
                onPressed: () => controller.showLuxuryLogoutDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFE94532,
                  ), // Match red from image
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(context.responsive(24)),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: context.responsive(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: context.responsive(18),
                    ),
                    SizedBox(width: context.responsive(8)),
                    Text(
                      "Logout",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.responsive(16),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: context.responsive(24)),

            Text(
              "Transcorp v2.4.1",
              style: TextStyle(
                color: Colors.grey,
                fontSize: context.responsive(12),
              ),
            ),

            SizedBox(height: context.responsive(140)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive(20),
        vertical: context.responsive(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: context.responsive(4),
              bottom: context.responsive(8),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.black,
                fontSize: context.responsive(14),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.responsive(16)),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(height: 1, color: const Color(0xFFF3F4F6));
  }

  Widget _buildRow(
    BuildContext context, {
    String? iconAsset,
    IconData? iconData,
    required String title,
    String? subtitle,
    Widget? trailingWidget,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.responsive(16)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.responsive(16),
          vertical: context.responsive(14),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(context.responsive(8)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lightprimaryred,
                border: Border.all(color: primaryYellow),
              ),
              child: Center(
                child: iconAsset != null && iconAsset.isNotEmpty
                    ? SvgPicture.asset(
                        iconAsset,
                        height: context.responsive(22),
                        width: context.responsive(22),
                        colorFilter: const ColorFilter.mode(
                          Colors.black87,
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(
                        iconData ?? Icons.circle,
                        size: context.responsive(22),
                        color: Colors.black87,
                      ),
              ),
            ),
            SizedBox(width: context.responsive(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: context.responsive(14),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: context.responsive(2)),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: context.responsive(11),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailingWidget != null) ...[
              trailingWidget,
              if (showChevron) SizedBox(width: context.responsive(8)),
            ],
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFF9CA3AF),
                size: context.responsive(20),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 40,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
