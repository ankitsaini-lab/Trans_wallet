import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class OnboardingscreenController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;
  Timer? _autoScrollTimer;

  static const int totalPages = 3;
  static const Duration pageDuration = Duration(seconds: 3);
  static const Duration transitionDuration = Duration(milliseconds: 600);
  static const Curve transitionCurve = Curves.easeInOutCubic;

  @override
  void onInit() {
    super.onInit();
    _startAutoScroll();
  }

  @override
  void onReady() {
    super.onReady();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    // Stop auto-scrolling once the end screen (last page) is reached
    if (currentPage.value >= totalPages - 1) return;

    _autoScrollTimer = Timer(pageDuration, () {
      if (currentPage.value < totalPages - 1) {
        if (pageController.hasClients) {
          final nextIndex = currentPage.value + 1;
          pageController.animateToPage(
            nextIndex,
            duration: transitionDuration,
            curve: transitionCurve,
          );
        }
      }
    });
  }

  void onPageChanged(int index) {
    currentPage.value = index;
    // If user or timer moved to the last screen, stop auto-scrolling
    if (index >= totalPages - 1) {
      _autoScrollTimer?.cancel();
    } else {
      // Otherwise, schedule the next auto-scroll
      _startAutoScroll();
    }
  }

  void nextPage() {
    if (currentPage.value < totalPages - 1) {
      pageController.nextPage(
        duration: transitionDuration,
        curve: transitionCurve,
      );
    } else {
      goToWelcome();
    }
  }

  void skip() {
    _autoScrollTimer?.cancel();
    goToWelcome();
  }

  void goToWelcome() {
    _autoScrollTimer?.cancel();
    GetStorage().write('has_seen_onboarding', true);
    Get.offAllNamed('/login_singupview');
  }

  @override
  void onClose() {
    _autoScrollTimer?.cancel();
    pageController.dispose();
    super.onClose();
  }
}
