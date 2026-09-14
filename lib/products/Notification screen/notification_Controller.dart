import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';

import 'package:transwallet/widgets/constsize.dart';

class NotificationController extends GetxController {
  var notifications = <Map<String, String>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  void loadNotifications() {
    notifications.addAll([
      {
        "title": "Order Confirmed",
        "message": "Your order has been placed successfully.",
        "time": "2 min ago",
        "read": "false",
      },
      {
        "title": "New Offer",
        "message": "Get 20% off on your next purchase.",
        "time": "10 min ago",
        "read": "false",
      },
      {
        "title": "Delivery Update",
        "message": "Your package is out for delivery.",
        "time": "1 hour ago",
        "read": "false",
      },
    ]);
  }

  void markAsRead(int index) {
    notifications[index]["read"] = "true";
    notifications.refresh();
  }

  void clearAll() {
    notifications.clear();
  }

  Widget notificationCard(BuildContext context, Map<String, String> item) {
    final bool isRead = item["read"] == "true";

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: context.responsive(20),
        vertical: context.responsive(8),
      ),
      padding: EdgeInsets.all(context.responsive(16)),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFFF9FAFB) : Colors.white,
        borderRadius: BorderRadius.circular(context.responsive(20)),
        border: Border.all(
          color: isRead ? Colors.transparent : const Color(0xFFF3F4F6),
          width: 1.5,
        ),
        boxShadow: isRead
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            padding: EdgeInsets.all(context.responsive(12)),
            decoration: BoxDecoration(
              gradient: isRead
                  ? null
                  : const LinearGradient(
                      colors: [lightprimaryred, lightprimaryred],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: isRead ? Colors.grey.shade200 : null,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRead
                  ? Icons.notifications_none
                  : Icons.notifications_active_outlined,
              color: isRead ? Colors.grey.shade500 : Colors.black,
              size: context.responsive(20),
            ),
          ),
          SizedBox(width: context.responsive(16)),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item["title"] ?? "",
                        style: TextStyle(
                          fontWeight: isRead
                              ? FontWeight.w600
                              : FontWeight.bold,
                          fontSize: context.responsive(15),
                          color: isRead ? Colors.grey.shade600 : Colors.black87,
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: context.responsive(8),
                        height: context.responsive(8),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ), 
                SizedBox(height: context.responsive(6)),
                Text(
                  item["message"] ?? "",
                  style: TextStyle(
                    fontSize: context.responsive(13),
                    height: 1.5,
                    color: isRead ? Colors.grey.shade500 : Colors.black54,
                  ),
                ),
                SizedBox(height: context.responsive(12)),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: context.responsive(14),
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(width: context.responsive(4)),
                    Text(
                      item["time"] ?? "",
                      style: TextStyle(
                        fontSize: context.responsive(12),
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
