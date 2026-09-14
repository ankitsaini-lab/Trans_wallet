import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    Get.offAllNamed('/login_singupview');
  }
}