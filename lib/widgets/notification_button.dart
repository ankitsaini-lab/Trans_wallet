import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Notification%20screen/notification_View.dart';
import 'package:transwallet/widgets/constsize.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => const NotificationView());
      },
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(context.responsive(10)),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color.fromRGBO(0, 0, 0, 0.05),
                width: 1.0,
              ),
              color: const Color.fromRGBO(255, 255, 255, 1),
            ),
            child: SvgPicture.asset(
              'assets/noun-notification-2182044 1.svg',
              height: context.responsive(20),
              width: context.responsive(20),
            ),
          ),
        ],
      ),
    );
  }
}
