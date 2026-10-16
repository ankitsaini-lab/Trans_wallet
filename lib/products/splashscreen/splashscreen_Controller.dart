import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/services/biometric_service.dart';
import 'package:transwallet/services/deepid_service.dart';
import 'package:transwallet/services/network_service.dart';

class SplashscreenController extends GetxController {
  VideoPlayerController? videoController;
  final RxBool isVideoInitialized = false.obs;
  final RxBool isVideoError = false.obs;

  Worker? _netWorker;
  Timer? _videoSafetyTimer;
  Timer? _fallbackTimer;

  bool _hasNavigated = false;
  bool _isDisposed = false;

  @override
  void onInit() {
    super.onInit();

    // 1. Initialize splash video immediately
    _initSplashVideo();

    // 2. Listen for network reconnection if device starts offline
    if (Get.isRegistered<NetworkService>()) {
      _netWorker = ever<bool>(NetworkService.to.isConnected, (connected) {
        if (connected && !_hasNavigated && isVideoError.value) {
          _completeAndNavigate('network_reconnected');
        }
      });
    }
  }

  Future<void> _initSplashVideo() async {
    final videoStopwatch = Stopwatch()..start();
    try {
      final controller = VideoPlayerController.asset('assets/videomp_.mp4');
      videoController = controller;

      await controller.initialize();

      if (_isDisposed || _hasNavigated) {
        await controller.dispose();
        return;
      }

      controller.setVolume(0.0);
      controller.setLooping(false); // Play once to match splash sequence timing
      controller.addListener(_onVideoPlayerUpdate);

      await controller.play();
      isVideoInitialized.value = true;

      debugPrint(
        '🎬 [Splash] Video player initialized in ${videoStopwatch.elapsedMilliseconds}ms. '
        'Duration: ${controller.value.duration.inMilliseconds}ms (${controller.value.size.width.toInt()}x${controller.value.size.height.toInt()})',
      );

      // Maximum safety duration: video length + 350ms buffer
      final maxWait = controller.value.duration + const Duration(milliseconds: 350);
      _videoSafetyTimer = Timer(maxWait, () {
        _completeAndNavigate('video_duration_timer');
      });
    } catch (e) {
      debugPrint('⚠️ [Splash] Video initialization failed or unsupported: $e');
      isVideoError.value = true;

      // Graceful fallback: Show static branded splash logo for 2000ms then proceed
      _fallbackTimer = Timer(const Duration(milliseconds: 2000), () {
        _completeAndNavigate('video_fallback_timeout');
      });
    }
  }

  void _onVideoPlayerUpdate() {
    final controller = videoController;
    if (controller == null || !controller.value.isInitialized) return;

    final position = controller.value.position;
    final duration = controller.value.duration;

    // Detect natural end of playback
    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 80)) {
      _completeAndNavigate('video_completed_naturally');
    }
  }

  /// Single navigation gate guaranteed to execute exactly once
  void _completeAndNavigate(String triggerReason) {
    if (_hasNavigated || _isDisposed) return;
    _hasNavigated = true;

    _videoSafetyTimer?.cancel();
    _fallbackTimer?.cancel();
    _netWorker?.dispose();

    debugPrint('🚀 [Splash] Navigation triggered by: $triggerReason');

    // Cleanly stop video playback before page transition
    try {
      videoController?.removeListener(_onVideoPlayerUpdate);
      videoController?.pause();
    } catch (_) {}

    _executeNavigation();
  }

  void _executeNavigation() {
    try {
      final box = GetStorage();
      final bool isSkipped = box.read('sim_binding_skipped') == true;

      // 1. Is there an active valid user session?
      if (Get.isRegistered<AuthService>() && AuthService.to.isLoggedIn) {
        final phone = box.read('phone')?.toString() ??
            box.read('remembered_phone')?.toString() ??
            '';
        final isTrusted = isSkipped ||
            (Get.isRegistered<DeepIdService>() &&
                DeepIdService.to.isDeviceTrusted);

        if (!isTrusted && phone.isNotEmpty) {
          debugPrint('[Splash] Session active but device not trusted -> /sim_binding');
          Get.offAllNamed(
            '/sim_binding',
            arguments: {'phone': phone, 'returnRoute': '/dashboard'},
          );
        } else {
          debugPrint('[Splash] Session active and device trusted -> /dashboard');
          Get.offAllNamed('/dashboard');
        }
        return;
      }

      // 2. Is Biometric Quick Login enabled for a returning user?
      if (Get.isRegistered<BiometricService>() &&
          BiometricService.to.canQuickLogin) {
        final isTrusted = isSkipped ||
            (Get.isRegistered<DeepIdService>() &&
                DeepIdService.to.isDeviceTrusted);
        if (isTrusted) {
          debugPrint('[Splash] Biometric quick login available -> /quick_biometric_login');
          Get.offAllNamed('/quick_biometric_login');
          return;
        }
      }

      // 3. Brand new user who has never seen onboarding
      final bool hasSeenOnboarding = box.read('has_seen_onboarding') ?? false;
      if (!hasSeenOnboarding) {
        debugPrint('[Splash] First time user -> /onboarding');
        Get.offAllNamed('/onboarding');
        return;
      }

      // 4. SIM Binding is MANDATORY before user can login or register (SBI YONO reference)
      final isSimBound = isSkipped ||
          (Get.isRegistered<DeepIdService>() &&
              DeepIdService.to.isDeviceTrusted);

      if (!isSimBound) {
        debugPrint('[Splash] SIM binding mandatory before login/registration -> /sim_binding');
        Get.offAllNamed(
          '/sim_binding',
          arguments: {'returnRoute': '/login_singupview'},
        );
        return;
      }

      // 5. Default fallback to standard login/signup screen with bound SIM
      debugPrint('[Splash] Device SIM bound / skipped -> /login_singupview');
      Get.offAllNamed('/login_singupview');
    } catch (e) {
      debugPrint('⚠️ [Splash] Navigation error: $e -> Fallback to login');
      Get.offAllNamed('/login_singupview');
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    _videoSafetyTimer?.cancel();
    _fallbackTimer?.cancel();
    _netWorker?.dispose();

    try {
      videoController?.removeListener(_onVideoPlayerUpdate);
      videoController?.dispose();
      videoController = null;
    } catch (_) {}

    super.onClose();
  }
}
