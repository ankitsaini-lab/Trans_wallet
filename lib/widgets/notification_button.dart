import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Notification%20screen/notification_Controller.dart';
import 'package:transwallet/products/Notification%20screen/notification_View.dart';
import 'package:transwallet/widgets/constsize.dart';

class NotificationButton extends StatelessWidget {
  final bool? hasNotification;

  const NotificationButton({super.key, this.hasNotification});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController(), permanent: true);

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
            child: Obx(() {
              final bool isNotifPresent =
                  hasNotification ??
                  (controller.notifications.isNotEmpty &&
                      controller.notifications.any(
                        (item) => item['read'] != 'true',
                      ));

              return SvgPicture.asset(
                isNotifPresent
                    ? 'assets/withNotification .svg'
                    : 'assets/No_Notification.svg',
                height: context.responsive(20),
                width: context.responsive(20),
              );
            }),
          ),
        ],
      ),
    );
  }
}
