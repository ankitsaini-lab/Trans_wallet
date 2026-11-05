import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

enum VkycStatus {
  notStarted,
  inProgress,
  underReview,
  approved,
  rejected,
  cancelled,
}

class VkycTestService extends GetxService {
  static VkycTestService get to => Get.find<VkycTestService>();

  final Rx<VkycStatus> status = VkycStatus.notStarted.obs;

  Future<VkycTestService> init() async {
    return this;
  }

  void startVkyc() {
    status.value = VkycStatus.inProgress;
    debugPrint("🎥 [VKYC Service] VKYC started. Status set to inProgress.");
  }

  /// e.g. GET /kyc/vkyc/status or /api/v1/kyc/vkyc/verify
  /// Do NOT rely on deep link alone as proof of approval in production.
  Future<VkycStatus> checkVkycStatus() async {
    debugPrint("🔍 [VKYC Service] Checking VKYC verification status...");
    await Future.delayed(const Duration(milliseconds: 600));

    if (status.value == VkycStatus.approved) {
      debugPrint("✅ [VKYC Service] Verification result: APPROVED");
      return VkycStatus.approved;
    } else if (status.value == VkycStatus.underReview) {
      debugPrint("⏳ [VKYC Service] Verification result: UNDER REVIEW");
      return VkycStatus.underReview;
    } else if (status.value == VkycStatus.rejected) {
      debugPrint("❌ [VKYC Service] Verification result: REJECTED");
      return VkycStatus.rejected;
    }
    return status.value;
  }

  Future<void> handleVkycSuccess() async {
    debugPrint(
      "🎯 [VKYC Service] Success deep link received: transwallet://vkyc/success",
    );
    status.value = VkycStatus.approved;
  }

  Future<void> handleVkycUnderReview() async {
    debugPrint(
      "⏳ [VKYC Service] Under review deep link received: transwallet://vkyc/under_review",
    );
    status.value = VkycStatus.underReview;
  }

  Future<void> handleVkycRejected() async {
    debugPrint(
      "❌ [VKYC Service] Rejected deep link received: transwallet://vkyc/rejected",
    );
    status.value = VkycStatus.rejected;
  }

  void handleVkycCancel() {
    debugPrint(
      "🚫 [VKYC Service] Cancel deep link received: transwallet://vkyc/cancel",
    );
    status.value = VkycStatus.cancelled;
  }
}
