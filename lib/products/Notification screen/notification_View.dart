import 'package:flutter/material.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Notification%20screen/notification_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/constsize.dart';

class NotificationView extends GetView<NotificationController> {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(NotificationController());

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        elevation: 0,
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        title: Text(
          "Notification",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: context.responsive(18),
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          height16,
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value && controller.notifications.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: primaryRed),
                );
              }

              if (controller.notifications.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () => controller.fetchNotifications(isRefresh: true),
                  color: primaryRed,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: context.responsive(120)),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(context.responsive(24)),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF9FAFB),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_off_outlined,
                                size: context.responsive(48),
                                color: Colors.black26,
                              ),
                            ),
                            SizedBox(height: context.responsive(24)),
                            Text(
                              "No new notifications",
                              style: TextStyle(
                                fontSize: context.responsive(18),
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: context.responsive(8)),
                            Text(
                              "You're all caught up! Check back later.",
                              style: TextStyle(
                                fontSize: context.responsive(14),
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.fetchNotifications(isRefresh: true),
                color: primaryRed,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: controller.notifications.length,
                  itemBuilder: (context, index) {
                    final item = controller.notifications[index];
                    final itemId = item["id"] ?? index.toString();
                    final itemTitle = item["title"] ?? "Title";
                    final itemTime = item["time"] ?? "";

                    return Dismissible(
                      key: ValueKey("$itemId-$itemTitle-$itemTime-$index"),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: context.responsive(20),
                          vertical: context.responsive(8),
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF34D399), Color(0xFF059669)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            context.responsive(20),
                          ),
                        ),
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsive(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                              size: context.responsive(24),
                            ),
                            SizedBox(width: context.responsive(8)),
                            Text(
                              "Mark as Read",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: context.responsive(14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      confirmDismiss: (_) async {
                        controller.markAsRead(index);
                        return false;
                      },
                      child: controller.notificationCard(context, item),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
