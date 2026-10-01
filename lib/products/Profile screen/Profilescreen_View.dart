import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Profile%20screen/profilescreen_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/globalbottombar/Globalbottombar_View.dart';
import 'package:transwallet/utilities/string_extensions.dart';
import 'package:transwallet/widgets/user_avatar.dart';

class ProfilescreenView extends GetView<ProfilescreenController> {
  const ProfilescreenView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(ProfilescreenController());

    final Color backgroundColor = const Color(0xFFF9FAFB);

    return Scaffold(
      extendBody: true,
      backgroundColor: backgroundColor,
      bottomNavigationBar: GlobalbottombarView(seletedIndex: 3.obs),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                ClipPath(
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

                Positioned(
                  bottom: context.responsive(-40),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Obx(
                        () => GestureDetector(
                          onTap: () => controller.uploadProfilePicture(),
                          child: UserAvatar(
                            size: context.responsive(100),

                            imageUrl:
                                controller.profilePictureUrl.value.isNotEmpty
                                ? controller.profilePictureUrl.value
                                : null,
                            // border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => controller.uploadProfilePicture(),
                        child: Container(
                          padding: EdgeInsets.all(context.responsive(4)),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: context.responsive(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.responsive(50)),
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
                Obx(
                  () => _buildRow(
                    context,
                    iconAsset: "assets/kyc.svg",
                    title: "KYC & Verification",
                    trailingWidget: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          controller.isKycVerified.value
                              ? Icons.verified
                              : Icons.pending_actions,
                          color: controller.isKycVerified.value
                              ? Colors.green.shade600
                              : Colors.orange.shade600,
                          size: context.responsive(16),
                        ),
                        SizedBox(width: context.responsive(4)),
                        Text(
                          controller.isKycVerified.value
                              ? "Verified"
                              : "Pending",
                          style: TextStyle(
                            color: controller.isKycVerified.value
                                ? Colors.green.shade600
                                : Colors.orange.shade600,
                            fontSize: context.responsive(12),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    onTap: controller.handleKycTap,
                  ),
                ),
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
                  title: "Change PIN",
                  onTap: () => Get.toNamed('/create_mpin'),
                ),
                _buildDivider(context),
                Obx(
                  () => _buildRow(
                    context,
                    iconAsset: "assets/biomatrics.svg",
                    title: "Face Lock / Biometrics",
                    subtitle: "Unlock with Face Lock or Fingerprint",
                    trailingWidget: Transform.scale(
                      scale: 0.8,
                      child: CupertinoSwitch(
                        value: controller.biometricEnabled.value,
                        activeColor: primaryRed,
                        trackColor: Colors.grey.shade300,
                        onChanged: controller.toggleBiometric,
                      ),
                    ),
                    showChevron: false,
                  ),
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
                  iconAsset: "assets/help.svg",
                  title: "Help Center",
                  onTap: () => Get.toNamed('/contactsupport'),
                ),
                _buildDivider(context),
                _buildRow(
                  context,
                  iconAsset: "assets/contactus.svg",
                  title: "Contact Us",
                  onTap: () => Get.toNamed('/contactsupport'),
                ),
                _buildDivider(context),
                _buildRow(
                  context,
                  iconAsset: "assets/termsandpolicy.svg",
                  title: "Terms & Privacy Policy",
                  onTap: () => Get.snackbar(
                    "Terms & Privacy",
                    "Terms and Privacy Policy will be available soon.",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: const Color(0xFF111111),
                    colorText: Colors.white,
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
                  color: Colors.black.withOpacity(0.02),
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
    return Divider(
      height: 1,
      color: const Color(0xFFF3F4F6),
      indent: context.responsive(56),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    String? iconAsset,
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
                child: SvgPicture.asset(
                  iconAsset ?? "",
                  height: context.responsive(22),
                  width: context.responsive(22),
                  colorFilter: const ColorFilter.mode(
                    Colors.black87,
                    BlendMode.srcIn,
                  ),
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
              SizedBox(width: context.responsive(8)),
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
