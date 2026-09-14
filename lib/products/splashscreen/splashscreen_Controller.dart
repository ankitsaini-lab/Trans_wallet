import 'package:get/get.dart';
import 'package:transwallet/services/auth_service.dart';

class SplashscreenController extends GetxController {
  void splash() async {
    try {
      await Future.delayed(const Duration(seconds: 5));

      // Direct login: If session exists, navigate to dashboard, else onboarding
      if (Get.isRegistered<AuthService>() && AuthService.to.isLoggedIn) {
        Get.offAllNamed('/dashboard');
      } else {
        Get.offAllNamed('/onboarding');
      }
    } catch (e) {}
  }
}
