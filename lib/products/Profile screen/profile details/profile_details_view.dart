import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Profile%20screen/profile%20details/profile_details_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/user_avatar.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

class ProfileDetailsView extends GetView<ProfileDetailsController> {
  const ProfileDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => ProfileDetailsController());

    final Color backgroundColor = const Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: backgroundColor,
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
                    padding: EdgeInsets.only(
                      top: context.responsive(50),
                      left: context.responsive(16),
                      right: context.responsive(16),
                    ),
                    alignment: Alignment.topCenter,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            padding: EdgeInsets.all(context.responsive(8)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                context.responsive(25),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.black,
                              size: context.responsive(18),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "Profile Detail",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: context.responsive(18),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: context.responsive(40)),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  bottom: context.responsive(-45),
                  child: Obx(
                    () => Container(
                      padding: EdgeInsets.all(context.responsive(0)),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.07),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: UserAvatar(
                        size: context.responsive(100),
                        name: controller.name.value,
                        // border: Border.all(color: primaryYellow, width: 3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.responsive(55)),
            Obx(
              () => Text(
                controller.name.value,
                style: TextStyle(
                  color: const Color(0xFF111111),
                  fontSize: context.responsive(22),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: context.responsive(6)),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified,
                    size: context.responsive(18),
                    color: Colors.green.shade600,
                  ),
                  width4,
                  Text(
                    controller.accountverification.value,
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: context.responsive(14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.responsive(30)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.responsive(20)),
              child: Column(
                children: [
                  Obx(
                    () => controller.buildTile(
                      context,
                      icon: Icons.email_outlined,
                      title: "Email Address",
                      value: controller.email.value,
                    ),
                  ),
                  Obx(
                    () => controller.buildTile(
                      context,
                      icon: Icons.call_outlined,
                      title: "Phone Number",
                      value: controller.phone.value,
                    ),
                  ),
                  Obx(
                    () => controller.buildTile(
                      context,
                      icon: Icons.location_on_outlined,
                      title: "Address",
                      value: controller.address.value,
                    ),
                  ),
                  SizedBox(height: context.responsive(15)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsive(18),
                      vertical: context.responsive(18),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        context.responsive(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.04),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(context.responsive(12)),
                          decoration: BoxDecoration(
                            color: primaryRed.withOpacity(.15),
                            borderRadius: BorderRadius.circular(
                              context.responsive(14),
                            ),
                          ),
                          child: const Icon(
                            Icons.support_agent,
                            color: Color(0xFF111111),
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
                                  fontSize: context.responsive(16),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: context.responsive(4)),
                              Text(
                                "Contact our support team for quick help.",
                                style: TextStyle(
                                  fontSize: context.responsive(12),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            AppSnackbar.info(
                              "Contact Support Clicked",
                              title: "Support",
                              position: SnackPosition.BOTTOM,
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.responsive(16),
                              vertical: context.responsive(10),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(
                                context.responsive(12),
                              ),
                            ),
                            child: const Text(
                              "Contact",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: context.responsive(40)),
                ],
              ),
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
