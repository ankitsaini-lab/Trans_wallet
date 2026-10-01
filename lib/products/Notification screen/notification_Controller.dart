import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/widgets/constsize.dart';

class NotificationController extends GetxController {
  var notifications = <Map<String, String>>[].obs;
  var isLoading = false.obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage.value = 1;
    }
    
    isLoading.value = true;
    try {
      final res = await ApiService.to.fetchNotifications(
        page: currentPage.value,
        pageSize: 20,
      );

      if (res != null && res['items'] != null && res['items'] is List) {
        final List rawItems = res['items'] as List;
        final List<Map<String, String>> parsed = rawItems.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return <String, String>{
            "id": map['id']?.toString() ?? '',
            "title": map['title']?.toString() ?? 'Notification',
            "message": map['body']?.toString() ?? map['message']?.toString() ?? '',
            "category": map['category']?.toString() ?? 'general',
            "eventType": map['eventType']?.toString() ?? '',
            "referenceType": map['referenceType']?.toString() ?? '',
            "referenceId": map['referenceId']?.toString() ?? '',
            "time": _formatTime(map['createdAt']?.toString()),
            "read": map['read']?.toString() ?? 'false',
          };
        }).toList();

        if (isRefresh) {
          notifications.value = parsed;
        } else {
          notifications.value = parsed;
        }

        if (res['pagination'] != null && res['pagination'] is Map) {
          totalPages.value = res['pagination']['totalPages'] ?? 1;
        }
      }
    } catch (e) {
      debugPrint("⚠️ [NotificationController] Error loading notifications: $e");
    } finally {
      isLoading.value = false;
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Just now';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      final difference = DateTime.now().difference(dateTime);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
      if (difference.inHours < 24) return '${difference.inHours} hr ago';
      if (difference.inDays < 7) return '${difference.inDays} days ago';
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (_) {
      return dateStr;
    }
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
