import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/widgets/constsize.dart';

class NotificationController extends GetxController {
  var notifications = <Map<String, String>>[].obs;
  var isLoading = false.obs;
  var isMarkingAllAsRead = false.obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;

  void clear() {
    notifications.clear();
    isLoading.value = false;
    isMarkingAllAsRead.value = false;
    currentPage.value = 1;
    totalPages.value = 1;
  }

  bool get _canFetchNotifications {
    final box = GetStorage();
    final bool loggedIn = (box.read<bool>('is_logged_in') ?? false) &&
        (box.read<String>('accessToken') != null ||
            box.read<String>('auth_token') != null);
    final bool isLoggingOut =
        (Get.isRegistered<AuthService>() && AuthService.to.isLoggingOut) ||
        (Get.isRegistered<ApiService>() && ApiService.to.isLoggingOut);
    return loggedIn && !isLoggingOut;
  }

  @override
  void onInit() {
    super.onInit();
    if (_canFetchNotifications) {
      fetchNotifications();
    }
  }

  Future<void> fetchNotifications({bool isRefresh = false}) async {
    if (!_canFetchNotifications) return;
    if (isRefresh) {
      currentPage.value = 1;
    }

    isLoading.value = true;
    try {
      final res = await ApiService.to.fetchNotifications(
        page: currentPage.value,
        pageSize: 20,
      );

      if (res != null) {
        List rawItems = [];
        if (res['items'] != null && res['items'] is List) {
          rawItems = res['items'] as List;
        } else if (res['notifications'] != null &&
            res['notifications'] is List) {
          rawItems = res['notifications'] as List;
        } else if (res['data'] != null && res['data'] is List) {
          rawItems = res['data'] as List;
        }

        final List<Map<String, String>> parsed = rawItems.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          final bool isRead = map['readAt'] != null ||
              map['read'] == true ||
              map['read'] == 'true' ||
              map['isRead'] == true ||
              map['isRead'] == 'true';

          return <String, String>{
            "id": map['id']?.toString() ?? '',
            "title": map['title']?.toString() ?? 'Notification',
            "message": map['body']?.toString() ??
                map['message']?.toString() ??
                map['description']?.toString() ??
                '',
            "category": map['category']?.toString() ?? 'general',
            "eventType": map['eventType']?.toString() ?? '',
            "referenceType": map['referenceType']?.toString() ?? '',
            "referenceId": map['referenceId']?.toString() ?? '',
            "time": _formatTime(map['createdAt']?.toString()),
            "read": isRead ? 'true' : 'false',
          };
        }).toList();

        notifications.value = parsed;

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

  Future<void> markAsRead(int index) async {
    if (index < 0 || index >= notifications.length) return;
    final item = notifications[index];
    if (item["read"] == "true") return;

    final String notifId = item["id"] ?? "";

    // Optimistically update in memory
    notifications[index]["read"] = "true";
    notifications.refresh();

    if (notifId.isNotEmpty) {
      try {
        await ApiService.to.markNotificationAsRead(notifId);
      } catch (e) {
        debugPrint(
          "⚠️ [NotificationController] Error marking notification $notifId as read: $e",
        );
      }
    }
  }

  Future<void> markAllAsRead() async {
    final hasUnread = notifications.any((item) => item["read"] != "true");
    if (!hasUnread) return;

    isMarkingAllAsRead.value = true;

    // Optimistically update all in memory
    for (int i = 0; i < notifications.length; i++) {
      notifications[i]["read"] = "true";
    }
    notifications.refresh();

    try {
      final res = await ApiService.to.markAllNotificationsAsRead();
      if (res != null) {
        debugPrint(
          "✅ [NotificationController] All notifications marked as read on server: $res",
        );
      }
    } catch (e) {
      debugPrint(
        "⚠️ [NotificationController] Error marking all notifications as read: $e",
      );
    } finally {
      isMarkingAllAsRead.value = false;
    }
  }

  void clearAll() {
    notifications.clear();
  }

  IconData _getCategoryIcon(String category, String eventType, bool isRead) {
    final cat = category.toLowerCase();
    final event = eventType.toLowerCase();

    if (cat.contains('transaction') ||
        cat.contains('wallet') ||
        event.contains('wallet') ||
        event.contains('transfer') ||
        event.contains('pay')) {
      return isRead
          ? Icons.account_balance_wallet_outlined
          : Icons.account_balance_wallet;
    }
    if (cat.contains('security') ||
        event.contains('security') ||
        event.contains('auth')) {
      return isRead ? Icons.security_outlined : Icons.security;
    }
    if (cat.contains('kyc') || event.contains('kyc')) {
      return isRead ? Icons.verified_user_outlined : Icons.verified_user;
    }
    if (cat.contains('card') || event.contains('card')) {
      return isRead ? Icons.credit_card_outlined : Icons.credit_card;
    }
    if (cat.contains('offer') ||
        cat.contains('promo') ||
        event.contains('offer')) {
      return isRead ? Icons.local_offer_outlined : Icons.local_offer;
    }
    return isRead
        ? Icons.notifications_none
        : Icons.notifications_active_outlined;
  }

  Widget notificationCard(
    BuildContext context,
    Map<String, String> item, {
    int? index,
    VoidCallback? onTap,
  }) {
    final bool isRead = item["read"] == "true";
    final category = item["category"] ?? "general";
    final eventType = item["eventType"] ?? "";

    return InkWell(
      onTap: onTap ??
          () {
            if (!isRead && index != null) {
              markAsRead(index);
            }
          },
      borderRadius: BorderRadius.circular(context.responsive(20)),
      child: Container(
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
                color: isRead ? Colors.grey.shade200 : lightprimaryred,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getCategoryIcon(category, eventType, isRead),
                color: isRead ? Colors.grey.shade500 : Colors.black,
                size: context.responsive(20),
              ),
            ),
            SizedBox(width: context.responsive(16)),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            color: isRead
                                ? Colors.grey.shade600
                                : Colors.black87,
                          ),
                        ),
                      ),
                      SizedBox(width: context.responsive(8)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                      if (!isRead) ...[
                        SizedBox(width: context.responsive(8)),
                        Container(
                          width: context.responsive(8),
                          height: context.responsive(8),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: context.responsive(4)),
                  Text(
                    item["message"] ?? "",
                    style: TextStyle(
                      fontSize: context.responsive(13),
                      height: 1.5,
                      color: isRead ? Colors.grey.shade500 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
