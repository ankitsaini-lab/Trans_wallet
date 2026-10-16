import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:transwallet/services/deepid_service.dart';

class OnboardingscreenController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void nextPage() {
    if (currentPage.value < 2) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      goToWelcome();
    }
  }

  void skip() {
    goToWelcome();
  }

  void goToWelcome() {
    GetStorage().write('has_seen_onboarding', true);
    final bool isSkipped = GetStorage().read('sim_binding_skipped') == true;
    final isTrusted = isSkipped ||
        (Get.isRegistered<DeepIdService>() && DeepIdService.to.isDeviceTrusted);
    if (!isTrusted) {
      Get.offAllNamed('/sim_binding', arguments: {'returnRoute': '/login_singupview'});
    } else {
      Get.offAllNamed('/login_singupview');
    }
  }
}