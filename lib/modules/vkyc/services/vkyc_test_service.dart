import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

enum VkycStatus {
  notStarted,
  inProgress,
  approved,
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

  /// TODO (Production): Replace this mock verification with real backend API call:
  /// e.g. GET /kyc/vkyc/status or /api/v1/kyc/vkyc/verify
  /// Do NOT rely on deep link alone as proof of approval in production.
  Future<VkycStatus> checkVkycStatus() async {
    debugPrint("🔍 [VKYC Service] Checking VKYC verification status...");
    // Simulate network latency for backend verification
    await Future.delayed(const Duration(milliseconds: 600));

    // For test flow, return approved if currently inProgress/approved
    if (status.value == VkycStatus.inProgress || status.value == VkycStatus.approved) {
      status.value = VkycStatus.approved;
      debugPrint("✅ [VKYC Service] Verification result: APPROVED");
      return VkycStatus.approved;
    }
    return status.value;
  }

  Future<void> handleVkycSuccess() async {
    debugPrint("🎯 [VKYC Service] Success deep link received: transwallet://vkyc/success");
    startVkyc();
    await checkVkycStatus();
  }

  void handleVkycCancel() {
    debugPrint("🚫 [VKYC Service] Cancel deep link received: transwallet://vkyc/cancel");
    status.value = VkycStatus.cancelled;
  }
}
