import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/services/network_service.dart';
import 'package:transwallet/services/app_lock_service.dart';

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

    final box = GetStorage();
    final String? pendingCamera = box.read('pending_camera_upload');
    if (pendingCamera != null &&
        Get.isRegistered<AuthService>() &&
        AuthService.to.isLoggedIn) {
      _hasNavigated = true;
      _handleCameraRecreation(pendingCamera);
      return;
    }

    _initSplashVideo();

    if (Get.isRegistered<NetworkService>()) {
      _netWorker = ever<bool>(NetworkService.to.isConnected, (connected) {
        if (connected && !_hasNavigated && isVideoError.value) {
          _completeAndNavigate('network_reconnected');
        }
      });
    }
  }

  Future<void> _handleCameraRecreation(String pendingCamera) async {
    final box = GetStorage();
    box.remove('pending_camera_upload');
    debugPrint(
      '📸 [Splash] Camera activity recreation detected! Fast-restoring route to /$pendingCamera without splash video',
    );

    if (Platform.isAndroid) {
      try {
        final picker = ImagePicker();
        final LostDataResponse response = await picker.retrieveLostData();
        if (!response.isEmpty) {
          String? recoveredPath;
          if (response.file != null) {
            recoveredPath = response.file!.path;
          } else if (response.files != null && response.files!.isNotEmpty) {
            recoveredPath = response.files!.first.path;
          }
          if (recoveredPath != null && recoveredPath.isNotEmpty) {
            debugPrint(
              '📸 [Splash] Successfully recovered lost camera image: $recoveredPath',
            );
            box.write('recovered_camera_image', recoveredPath);
          }
        }
      } catch (e) {
        debugPrint('⚠️ [Splash] Error retrieving lost camera data: $e');
      }
    }

    // Skip the splash video entirely and navigate straight back to the previous screen directly
    if (pendingCamera == 'profile_details') {
      Get.offAllNamed('/dashboard');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.toNamed('/profile');
        Get.toNamed('/profiledetails');
      });
    } else if (pendingCamera == 'profile') {
      Get.offAllNamed('/dashboard');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.toNamed('/profile');
      });
    } else {
      Get.offAllNamed('/dashboard');
    }
  }

  Future<void> _initSplashVideo() async {
    final videoStopwatch = Stopwatch()..start();
    VideoPlayerController? tempController;
    try {
      tempController = VideoPlayerController.asset('assets/videomp_.mp4');

      await tempController.initialize();

      if (_isDisposed || _hasNavigated) {
        try {
          tempController.dispose();
        } catch (_) {}
        return;
      }

      tempController.setVolume(0.0);
      tempController.setLooping(false);
      tempController.addListener(_onVideoPlayerUpdate);

      await tempController.play();

      if (_isDisposed || _hasNavigated) {
        tempController.removeListener(_onVideoPlayerUpdate);
        try {
          tempController.dispose();
        } catch (_) {}
        return;
      }

      videoController = tempController;
      isVideoInitialized.value = true;

      debugPrint(
        '🎬 [Splash] Video player initialized in ${videoStopwatch.elapsedMilliseconds}ms. '
        'Duration: ${tempController.value.duration.inMilliseconds}ms (${tempController.value.size.width.toInt()}x${tempController.value.size.height.toInt()})',
      );

      final maxWait =
          tempController.value.duration + const Duration(milliseconds: 350);
      _videoSafetyTimer = Timer(maxWait, () {
        _completeAndNavigate('video_duration_timer');
      });
    } catch (e) {
      debugPrint('⚠️ [Splash] Video initialization failed or unsupported: $e');
      if (tempController != null && !_isDisposed) {
        try {
          tempController.dispose();
        } catch (_) {}
      }
      isVideoError.value = true;

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

    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 80)) {
      _completeAndNavigate('video_completed_naturally');
    }
  }

  void _completeAndNavigate(String triggerReason) {
    if (_hasNavigated || _isDisposed) return;
    _hasNavigated = true;

    _videoSafetyTimer?.cancel();
    _fallbackTimer?.cancel();
    _netWorker?.dispose();

    debugPrint('🚀 [Splash] Navigation triggered by: $triggerReason');

    // Unmount VideoPlayer widget cleanly before route transition
    isVideoInitialized.value = false;

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

      // 0. If user killed or closed the app during registration / create account,
      // do NOT redirect to dashboard; user must redirect to login screen when reopening the app.
      final bool isRegistrationPending =
          (box.read<bool>('registration_in_progress') == true) ||
          (box.read<String>('otpFlow') == 'REGISTER') ||
          (box.read<String>('registrationToken') != null &&
              (box.read<bool>('is_logged_in') != true));

      if (isRegistrationPending) {
        debugPrint(
          '[Splash] Incomplete registration/create account session -> Navigating to /login_singupview',
        );
        box.write('registration_in_progress', false);
        box.write('is_logged_in', false);
        box.remove('registrationToken');
        box.remove('accessToken');
        box.remove('auth_token');
        box.remove('token');
        box.remove('refreshToken');
        box.remove('refresh_token');
        box.remove('otpFlow');
        Get.offAllNamed('/login_singupview');
        return;
      }

      // Check if Activity was killed by Android LMK during camera photo capture
      final String? pendingCamera = box.read('pending_camera_upload');
      if (pendingCamera != null &&
          Get.isRegistered<AuthService>() &&
          AuthService.to.isLoggedIn) {
        box.remove('pending_camera_upload');
        debugPrint(
          '[Splash] Restoring route to /$pendingCamera after camera activity recreation',
        );
        if (pendingCamera == 'profile_details') {
          Get.offAllNamed('/dashboard');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.toNamed('/profile');
            Get.toNamed('/profiledetails');
          });
        } else if (pendingCamera == 'profile') {
          Get.offAllNamed('/dashboard');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.toNamed('/profile');
          });
        } else {
          Get.offAllNamed('/dashboard');
        }
        return;
      }

      // 1. Is there an active valid user session?
      final bool isExplicitlyLoggedIn =
          (Get.isRegistered<AuthService>() && AuthService.to.isLoggedIn) ||
          (box.read<bool>('is_logged_in') == true);

      final bool hasToken =
          (box.read<String>('accessToken') ??
                  box.read<String>('auth_token') ??
                  box.read<String>('token') ??
                  '')
              .isNotEmpty;

      final bool hasMpin =
          (box.read<bool>('has_mpin') == true) ||
          (box.read<bool>('mpin_set') == true);

      final bool isLoggedIn = isExplicitlyLoggedIn && hasToken && hasMpin;

      if (isLoggedIn) {
        debugPrint('[Splash] Session active -> /dashboard');
        if (Get.isRegistered<AppLockService>() &&
            AppLockService.to.canAppLock) {
          AppLockService.to.lockForColdStart();
        }
        Get.offAllNamed('/dashboard');
        return;
      }

      // 2. Brand new user who has never seen onboarding
      final bool hasSeenOnboarding = box.read('has_seen_onboarding') ?? false;
      if (!hasSeenOnboarding) {
        debugPrint('[Splash] First time user -> /onboarding');
        Get.offAllNamed('/onboarding');
        return;
      }

      // 4. Default fallback to standard login/signup screen
      debugPrint('[Splash] Navigating to /login_singupview');
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
    isVideoInitialized.value = false;

    final controllerToDispose = videoController;
    videoController = null;

    if (controllerToDispose != null) {
      try {
        controllerToDispose.removeListener(_onVideoPlayerUpdate);
        controllerToDispose.pause();
      } catch (_) {}

      // Defer dispose to post-frame so in-flight platform channel updates & widget unmount drain cleanly
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          controllerToDispose.dispose();
        } catch (_) {}
      });
    }

    super.onClose();
  }
}
