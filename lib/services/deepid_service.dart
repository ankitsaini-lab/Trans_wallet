import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:deepidsdk_flutter/deepidsdk_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

/// Physical SIM card detected on the handset
class DetectedSimCard {
  final int slotIndex;
  final int subscriptionId;
  final String carrierName;
  final String displayName;
  final String countryIso;
  final String number;

  DetectedSimCard({
    required this.slotIndex,
    required this.subscriptionId,
    required this.carrierName,
    required this.displayName,
    required this.countryIso,
    required this.number,
  });

  bool get hasNumber => number.trim().length >= 10;
  String get slotLabel => 'SIM ${slotIndex + 1}';

  factory DetectedSimCard.fromMap(Map<dynamic, dynamic> map) {
    return DetectedSimCard(
      slotIndex: map['slotIndex'] is int ? map['slotIndex'] as int : 0,
      subscriptionId: map['subscriptionId'] is int
          ? map['subscriptionId'] as int
          : -1,
      carrierName: map['carrierName']?.toString() ?? 'SIM',
      displayName: map['displayName']?.toString() ?? 'SIM',
      countryIso: map['countryIso']?.toString() ?? 'in',
      number: map['number']?.toString() ?? '',
    );
  }
}

/// Authoritative status of SIM binding verification
enum DeepIdBindingStatus {
  notStarted,
  inProgress,
  enrolling,
  verified,
  cancelled,
  permissionDenied,
  abandoned,
  failed,
  backendUnavailable,
}

/// Dedicated service for DeepID device enrollment, SIM binding, and backend verification.
class DeepIdService extends GetxService {
  static DeepIdService get to => Get.find<DeepIdService>();

  final GetStorage _storage = GetStorage();

  // Storage keys
  static const String _keyDeepId = 'deepid_device_id';
  static const String _keySessionId = 'deepid_session_id';
  static const String _keyBoundMobile = 'deepid_bound_mobile';
  static const String _keySimBindingVerified = 'deepid_sim_binding_verified';
  static const String _keyDeviceTrusted = 'deepid_device_trusted';

  // Config credentials (DeepID live credentials for SIM binding)
  static const String _defaultAppKey = 'key_044358d6e1f94d35ba3267cf8265c040';
  static const String _defaultAppSecret = 'sk_007bb86ce05944e593f329425cdaaf17';

  // State observables
  final RxBool isInitialized = false.obs;
  final RxBool isEnrolled = false.obs;
  final RxBool isBindingInProgress = false.obs;
  final RxString currentDeepId = ''.obs;
  final RxString currentSessionId = ''.obs;
  final Rx<DeepIdBindingStatus> bindingStatus =
      DeepIdBindingStatus.notStarted.obs;

  // SIM detection observables
  static const MethodChannel _simChannel = MethodChannel(
    'com.trans.wallet/sim_service',
  );
  final RxList<DetectedSimCard> availableSimCards = <DetectedSimCard>[].obs;
  final Rx<DetectedSimCard?> selectedSimCard = Rx<DetectedSimCard?>(null);
  final RxBool isDetectingSims = false.obs;

  EnrollmentResult? _enrollmentResult;
  Completer<bool>? _initCompleter;
  Completer<EnrollmentResult>? _enrollmentCompleter;

  // Mid-flow correlation from native SDK
  String? _lastAttemptClientId;
  SimBindingResult? _lastSimBindingResult;
  SmsSentCheckResult? _lastSmsSentCheck;

  /// Latest raw result from DeepID native SIM binding
  SimBindingResult? get lastSimBindingResult => _lastSimBindingResult;

  /// Latest UPI SMS Sent Check telemetry (Android)
  SmsSentCheckResult? get lastSmsSentCheck => _lastSmsSentCheck;

  /// Get stored DeepID if available
  String? get storedDeepId => _storage.read<String>(_keyDeepId);

  /// Get stored verified mobile
  String? get boundMobile => _storage.read<String>(_keyBoundMobile);

  /// Authoritative backend trust state (read from server verification result or temporary dev/skip bypass)
  bool get isDeviceTrusted =>
      _storage.read<bool>('sim_binding_skipped') == true ||
      (_storage.read<bool>(_keyDeviceTrusted) == true &&
          _storage.read<bool>(_keySimBindingVerified) == true);

  /// Scans physical SIM cards on this handset via native SubscriptionManager
  Future<List<DetectedSimCard>> detectDeviceSimCards() async {
    if (!Platform.isAndroid) {
      return [];
    }

    isDetectingSims.value = true;
    try {
      final phoneStatus = await Permission.phone.status;
      if (!phoneStatus.isGranted) {
        final res = await Permission.phone.request();
        if (!res.isGranted) {
          developer.log(
            '[DeepIdService] Phone permission denied when scanning SIMs',
          );
          isDetectingSims.value = false;
          return [];
        }
      }

      final List<dynamic>? rawList = await _simChannel.invokeMethod(
        'getAvailableSimCards',
      );
      if (rawList != null) {
        final cards = rawList
            .map(
              (item) => DetectedSimCard.fromMap(
                Map<dynamic, dynamic>.from(item as Map),
              ),
            )
            .toList();
        availableSimCards.assignAll(cards);
        if (cards.isNotEmpty && selectedSimCard.value == null) {
          selectedSimCard.value = cards.first;
        }
        developer.log(
          '[DeepIdService] Successfully detected ${cards.length} SIM card(s): ${cards.map((c) => "${c.slotLabel}: ${c.carrierName} [${c.number}]").toList()}',
        );
        return cards;
      }
    } catch (e) {
      developer.log('[DeepIdService] Error detecting SIM cards: $e');
    } finally {
      isDetectingSims.value = false;
    }
    return [];
  }

  /// Request Google Phone Number Hint dialog to auto-pick the handset's mobile number
  Future<String?> requestPhoneNumberHint() async {
    if (!Platform.isAndroid) return null;
    try {
      final String? picked = await _simChannel.invokeMethod(
        'requestPhoneNumberHint',
      );
      if (picked != null && picked.trim().isNotEmpty) {
        developer.log('[DeepIdService] Phone Number Hint picked: $picked');
        return picked.trim();
      }
    } catch (e) {
      developer.log('[DeepIdService] Phone Number Hint canceled or failed: $e');
    }
    return null;
  }

  /// Initialize DeepID Service
  Future<DeepIdService> init() async {
    // Purge outdated/placeholder credentials if previously stored in GetStorage
    final storedKey = _storage.read<String>('deepid_app_key');
    if (storedKey == null ||
        storedKey.isEmpty ||
        storedKey.startsWith('tc_deepid_')) {
      _storage.write('deepid_app_key', _defaultAppKey);
      _storage.write('deepid_app_secret', _defaultAppSecret);
    }

    // Restore cached deepId from previous sessions if any
    final cachedDeepId = storedDeepId;
    if (cachedDeepId != null && cachedDeepId.isNotEmpty) {
      currentDeepId.value = cachedDeepId;
    }

    // Pre-initialize and enroll with DeepID in background for instantaneous SIM binding
    unawaited(
      initializeAndEnroll().catchError((e) {
        developer.log(
          '[DeepIdService] Startup background enrollment notice: $e',
        );
        return false;
      }),
    );

    return this;
  }

  static String _maskCredential(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '[EMPTY]';
    if (trimmed.length <= 8) return '*** (len: ${trimmed.length})';
    return '${trimmed.substring(0, 4)}...${trimmed.substring(trimmed.length - 4)} (len: ${trimmed.length})';
  }

  /// App Key from storage or default (trimmed)
  String get appKey {
    final stored = _storage.read<String>('deepid_app_key');
    if (stored == null || stored.isEmpty || stored.startsWith('tc_deepid_')) {
      return _defaultAppKey;
    }
    return stored.trim();
  }

  /// App Secret from storage or default (trimmed)
  String get appSecret {
    final stored = _storage.read<String>('deepid_app_secret');
    if (stored == null || stored.isEmpty || stored.startsWith('tc_deepid_')) {
      return _defaultAppSecret;
    }
    return stored.trim();
  }

  /// Update DeepID credentials dynamically (e.g. from remote config)
  void configureCredentials({required String key, required String secret}) {
    final cleanKey = key.trim();
    final cleanSecret = secret.trim();
    _storage.write('deepid_app_key', cleanKey);
    _storage.write('deepid_app_secret', cleanSecret);
    developer.log(
      '[DeepIdService] DeepID credentials updated: appKey=${_maskCredential(cleanKey)}, appSecret=${_maskCredential(cleanSecret)}',
    );
  }

  /// Initialize and enroll with DeepID Protect SDK.
  /// Idempotent and thread-safe.
  Future<bool> initializeAndEnroll({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    // Return immediately if already initialized and enrolled
    if (isInitialized.value && isEnrolled.value && _enrollmentResult != null) {
      return true;
    }

    if (_initCompleter != null) {
      return _initCompleter!.future;
    }

    _initCompleter = Completer<bool>();
    _enrollmentCompleter = Completer<EnrollmentResult>();

    try {
      bindingStatus.value = DeepIdBindingStatus.enrolling;
      developer.log(
        '[DeepIdService] Initializing DeepID Protect SDK with appKey: ${_maskCredential(appKey)}...',
      );

      await DeepId.initialize(
        appKey: appKey,
        appSecret: appSecret,
        onEnrollment: (result) {
          developer.log(
            '[DeepIdService] Enrollment successful. DeepId: ${result.deepId}, SessionId: ${result.sessionId}',
          );
          _enrollmentResult = result;
          currentDeepId.value = result.deepId;
          currentSessionId.value = result.sessionId;
          isEnrolled.value = true;
          _storage.write(_keyDeepId, result.deepId);
          _storage.write(_keySessionId, result.sessionId);

          if (_enrollmentCompleter != null &&
              !_enrollmentCompleter!.isCompleted) {
            _enrollmentCompleter!.complete(result);
          }
        },
        onEnrollmentError: (error) {
          developer.log(
            '[DeepIdService] Enrollment error (${error.code}): ${error.message}',
          );
          if (_enrollmentCompleter != null &&
              !_enrollmentCompleter!.isCompleted) {
            _enrollmentCompleter!.completeError(error);
          }
        },
        enrollmentTimeout: timeout,
      );

      isInitialized.value = true;

      // Wait for enrollment to complete
      await _enrollmentCompleter!.future.timeout(
        timeout,
        onTimeout: () {
          throw const DeepIdException(
            DeepIdErrorCode.enrollmentTimeout,
            'Device enrollment timed out before receiving deepId',
          );
        },
      );

      _initCompleter!.complete(true);
      return true;
    } on DeepIdException catch (e) {
      final lastApiError = await DeepId.getLastApiError();
      developer.log(
        '[DeepIdService] DeepId initialization exception: ${e.code} - ${e.message} (LastApiError: $lastApiError)',
      );
      isInitialized.value = false;
      isEnrolled.value = false;
      _initCompleter!.complete(false);
      return false;
    } catch (e) {
      final lastApiError = await DeepId.getLastApiError();
      developer.log(
        '[DeepIdService] Unexpected error during initialization: $e (LastApiError: $lastApiError)',
      );
      isInitialized.value = false;
      isEnrolled.value = false;
      _initCompleter!.complete(false);
      return false;
    } finally {
      _initCompleter = null;
    }
  }

  /// Request platform runtime permissions required before SIM binding.
  /// Only prompts immediately before SIM binding, never at launch.
  Future<bool> requestSimBindingPermissions() async {
    if (Platform.isAndroid) {
      developer.log(
        '[DeepIdService] Requesting Android Phone & SMS permissions...',
      );
      final statuses = await [Permission.phone, Permission.sms].request();

      final phoneGranted = statuses[Permission.phone]?.isGranted ?? false;
      final smsGranted = statuses[Permission.sms]?.isGranted ?? false;

      if (!phoneGranted || !smsGranted) {
        developer.log(
          '[DeepIdService] Permissions not granted. Phone: $phoneGranted, SMS: $smsGranted',
        );
        bindingStatus.value = DeepIdBindingStatus.permissionDenied;
        return false;
      }
      return true;
    }
    // iOS handles SMS presentation inside MFMessageComposeViewController; no runtime permission required
    return true;
  }

  /// Start the complete SIM binding flow and backend verification.
  ///
  /// 1. Ensures DeepID initialization & enrollment.
  /// 2. Requests telephony/SMS runtime permissions on Android.
  /// 3. Launches native silent verification SMS flow.
  /// 4. Submits tokens to backend for authoritative verification.
  Future<DeepIdBindingStatus> startSimBindingFlow({
    String? phoneNumber,
  }) async {
    if (isBindingInProgress.value) {
      developer.log(
        '[DeepIdService] SIM binding is already in flight. Skipping.',
      );
      return DeepIdBindingStatus.inProgress;
    }

    isBindingInProgress.value = true;
    bindingStatus.value = DeepIdBindingStatus.inProgress;
    _lastAttemptClientId = null;

    // Notify AppLockService that an external system flow is active
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.startExternalFlow(ExternalFlowType.simBinding);
    }

    try {
      // 1. Ensure initialization and background enrollment
      if (!isEnrolled.value || _enrollmentResult == null) {
        final initialized = await initializeAndEnroll();
        if (!initialized) {
          final lastError = await DeepId.getLastApiError();
          bindingStatus.value = DeepIdBindingStatus.failed;
          final errorText = lastError != null && lastError.isNotEmpty
              ? "DeepID enrollment failed: $lastError"
              : "DeepID device enrollment timed out. Please check DeepID App Key & Secret.";
          AppSnackbar.error(errorText);
          developer.log(
            '[DeepIdService] Initialization failed. LastApiError: $lastError',
          );
          return DeepIdBindingStatus.failed;
        }
      }

      // 2. Request runtime permissions
      final hasPermissions = await requestSimBindingPermissions();
      if (!hasPermissions) {
        AppSnackbar.error(
          "Phone and SMS permissions are required to bind your SIM card.",
        );
        return DeepIdBindingStatus.permissionDenied;
      }

      // Normalize phone number to E.164 (+91...) if provided
      String? formattedPhone;
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        final clean = phoneNumber.trim();
        if (!clean.startsWith('+')) {
          if (clean.length == 10) {
            formattedPhone = '+91$clean';
          } else if (clean.startsWith('91') && clean.length == 12) {
            formattedPhone = '+$clean';
          } else {
            formattedPhone = clean;
          }
        } else {
          formattedPhone = clean;
        }
      }

      developer.log(
        '[DeepIdService] Launching native DeepID SIM binding ${formattedPhone != null ? "for $formattedPhone" : "(auto-carrier silent SMS)"}...',
      );

      // 3. Launch native SIM binding sheet
      final SimBindingResult result = await DeepId.startSimBinding(
        phoneNumber: formattedPhone,
        onSimBindingInit: (init) {
          // SECURITY NOTE: Only record clientId. NEVER log bindingHash or smsContent.
          if (init.clientId != null) {
            _lastAttemptClientId = init.clientId;
            developer.log(
              '[DeepIdService] SIM binding attempt initialized with clientId: ${init.clientId}',
            );
          }
        },
        onSmsSentCheck: (smsCheck) {
          _lastSmsSentCheck = smsCheck;
          developer.log(
            '[DeepIdService] UPI SMS Sent Check: validated=${smsCheck.validated}, checked=${smsCheck.checked}, reason=${smsCheck.reason}',
          );
        },
      );

      if (!result.success) {
        developer.log(
          '[DeepIdService] Native binding reported non-success: ${result.message}',
        );
        bindingStatus.value = DeepIdBindingStatus.failed;
        AppSnackbar.error(
          "SIM binding could not be completed: ${result.message}",
        );
        return DeepIdBindingStatus.failed;
      }

      // Persist latest native result and tokens in state
      _lastSimBindingResult = result;
      currentDeepId.value = result.deepId;
      currentSessionId.value = result.sessionId;

      // =========================================================================
      // 📱 DEEPID SDK: SIM BINDING SUCCESSFUL - ACTUAL DATA LOGGING
      // =========================================================================
      final Map<String, dynamic> actualBindingData = {
        'success': result.success,
        'mobile': result.mobile,
        'deepId': result.deepId,
        'sessionId': result.sessionId,
        'message': result.message,
        'clientId': _lastAttemptClientId ?? 'N/A',
        if (_lastSmsSentCheck != null)
          'smsSentCheck': {
            'checked': _lastSmsSentCheck?.checked,
            'validated': _lastSmsSentCheck?.validated,
            'reason': _lastSmsSentCheck?.reason,
            'matchedAtEpochMillis': _lastSmsSentCheck?.matchedAtEpochMillis,
          },
        'rawResultMap': result.toMap(),
      };

      String formattedJson;
      try {
        formattedJson =
            const JsonEncoder.withIndent('  ').convert(actualBindingData);
      } catch (_) {
        formattedJson = actualBindingData.toString();
      }

      debugPrint('╔════════════════════════════════════════════════════════════════╗');
      debugPrint('║         🎉 [DeepID SDK] SIM BINDING SUCCESSFUL!                ║');
      debugPrint('╠════════════════════════════════════════════════════════════════╣');
      debugPrint('║ • Mobile:     ${result.mobile}');
      debugPrint('║ • DeepID:     ${result.deepId}');
      debugPrint('║ • SessionID:  ${result.sessionId}');
      debugPrint('║ • Message:    ${result.message}');
      debugPrint('║ • ClientID:   ${_lastAttemptClientId ?? "N/A"}');
      debugPrint('║ • Full Data Payload (JSON):');
      debugPrint(formattedJson);
      debugPrint('╚════════════════════════════════════════════════════════════════╝');

      developer.log(
        '🎉 [DeepIdService] NATIVE SIM BINDING SUCCESSFUL DATA:\n$formattedJson',
        name: 'DeepIdService',
      );

      // 4. Critical Step: Backend Authoritative Verification
      final verificationStatus = await _verifyWithBackend(
        result: result,
        clientId: _lastAttemptClientId,
      );

      bindingStatus.value = verificationStatus;
      return verificationStatus;
    } on DeepIdException catch (e) {
      developer.log(
        '[DeepIdService] DeepIdException caught: [${e.code}] ${e.message}',
      );
      if (e.code == DeepIdErrorCode.userCancelled) {
        bindingStatus.value = DeepIdBindingStatus.cancelled;
        AppSnackbar.info("SIM binding verification was cancelled.");
        return DeepIdBindingStatus.cancelled;
      } else if (e.code == DeepIdErrorCode.bindingAbandoned) {
        bindingStatus.value = DeepIdBindingStatus.abandoned;
        AppSnackbar.error(
          "Verification was interrupted because you left the app. Please stay inside the app during SIM binding.",
        );
        return DeepIdBindingStatus.abandoned;
      } else {
        bindingStatus.value = DeepIdBindingStatus.failed;
        AppSnackbar.error("SIM binding failed: ${e.message}");
        return DeepIdBindingStatus.failed;
      }
    } catch (e) {
      developer.log('[DeepIdService] Unexpected SIM binding error: $e');
      bindingStatus.value = DeepIdBindingStatus.failed;
      AppSnackbar.error(
        "An unexpected error occurred during SIM verification.",
      );
      return DeepIdBindingStatus.failed;
    } finally {
      isBindingInProgress.value = false;
      // Finish external flow so AppLockService resumes normal lifecycle tracking
      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.finishExternalFlow(ExternalFlowType.simBinding);
      }
    }
  }

  /// Submit native tokens to backend API for authoritative server-to-server verification.
  Future<DeepIdBindingStatus> _verifyWithBackend({
    required SimBindingResult result,
    String? clientId,
  }) async {
    if (!Get.isRegistered<ApiService>()) {
      developer.log('[DeepIdService] ApiService not registered.');
      return DeepIdBindingStatus.failed;
    }

    try {
      final backendResponse = await ApiService.to.verifySimBinding(
        deepId: result.deepId,
        sessionId: result.sessionId,
        mobile: result.mobile,
        clientId: clientId,
        deviceIntelligence: _enrollmentResult?.deviceIntelligence,
      );

      if (backendResponse != null) {
        final statusStr = backendResponse['simBindingStatus']
            ?.toString()
            .toLowerCase();
        final isTrusted =
            backendResponse['deviceTrusted'] == true ||
            statusStr == 'verified' ||
            backendResponse['success'] == true;

        if (isTrusted || statusStr == 'verified') {
          developer.log(
            '✅ [DeepIdService] Backend authoritative verification SUCCEEDED.',
          );
          await _storage.remove('sim_binding_skipped');
          await _storage.write(_keySimBindingVerified, true);
          await _storage.write(_keyDeviceTrusted, true);
          await _storage.write(_keyBoundMobile, result.mobile);
          return DeepIdBindingStatus.verified;
        } else {
          developer.log(
            '❌ [DeepIdService] Backend verification rejected or revoked. Status: $statusStr',
          );
          await _clearBindingState();
          final msg =
              backendResponse['message']?.toString() ??
              "Backend verification rejected this SIM binding.";
          AppSnackbar.error(msg);
          return DeepIdBindingStatus.failed;
        }
      } else {
        // Backend verification endpoint missing or network failure
        developer.log(
          '⚠️ [DeepIdService] Backend verification returned null. Server endpoint /api/v1/auth/sim-binding/verify may be pending implementation.',
        );
        return DeepIdBindingStatus.backendUnavailable;
      }
    } catch (e) {
      developer.log('[DeepIdService] Backend verification exception: $e');
      return DeepIdBindingStatus.failed;
    }
  }

  /// Check authoritative backend status for the device/user.
  Future<bool> checkAuthoritativeDeviceTrust({String? mobile}) async {
    if (!Get.isRegistered<ApiService>()) return false;

    try {
      final res = await ApiService.to.getSimBindingStatus(mobile: mobile);
      if (res != null) {
        final isTrusted =
            res['deviceTrusted'] == true ||
            res['simBindingStatus']?.toString().toLowerCase() == 'verified';
        await _storage.write(_keyDeviceTrusted, isTrusted);
        await _storage.write(_keySimBindingVerified, isTrusted);
        return isTrusted;
      }
    } catch (e) {
      developer.log('[DeepIdService] Error checking device trust: $e');
    }
    return false;
  }

  /// Clear session on logout
  Future<void> logout() async {
    try {
      await DeepId.logout();
    } catch (e) {
      developer.log('[DeepIdService] Error during DeepId.logout: $e');
    }
    isInitialized.value = false;
    isEnrolled.value = false;
    currentDeepId.value = '';
    currentSessionId.value = '';
    _enrollmentResult = null;
    _initCompleter = null;
    _enrollmentCompleter = null;
    _lastAttemptClientId = null;
    _lastSimBindingResult = null;
    _lastSmsSentCheck = null;
    await _clearBindingState();
  }

  Future<void> _clearBindingState() async {
    await _storage.remove(_keySimBindingVerified);
    await _storage.remove(_keyDeviceTrusted);
    await _storage.remove(_keyBoundMobile);
    bindingStatus.value = DeepIdBindingStatus.notStarted;
  }
}
