import 'dart:developer' as developer;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service wrapping Google's SMS User Consent API on Android.
///
/// Features:
/// - Zero SMS permissions required (neither READ_SMS nor RECEIVE_SMS).
/// - Displays native Google Play Services bottom-sheet consent dialog on eligible OTP SMS.
/// - Android-only: On iOS, immediately returns `null` so the native iOS
///   `AutofillHints.oneTimeCode` QuickType keyboard workflow remains completely untouched.
/// - Automatically handles timeout (5 mins), user denial, cancellation, and clean disposal.
class SmsUserConsentService {
  static const MethodChannel _channel = MethodChannel(
    'com.trans.wallet/sms_user_consent',
  );

  static bool _isListening = false;
  static bool get isListening => _isListening;

  /// Starts listening for an incoming OTP SMS using Google's SMS User Consent API.
  ///
  /// MUST be invoked BEFORE triggering the OTP-send API call to ensure Google Play
  /// Services captures the SMS broadcast promptly when it arrives.
  ///
  /// [senderPhoneNumber] is optional; if null, it listens for SMS from any sender
  /// that is NOT in the user's contacts.
  ///
  /// Returns the extracted 6-digit OTP string if user approves the consent dialog,
  /// or `null` if user denies, dismisses, times out, or when running on iOS/Web.
  static Future<String?> listenForOtp({String? senderPhoneNumber}) async {
    if (kIsWeb || !Platform.isAndroid) {
      // SMS User Consent API is Android-only.
      return null;
    }

    try {
      _isListening = true;
      developer.log(
        '[SmsUserConsentService] Starting SMS User Consent listener...',
      );

      final result = await _channel.invokeMapMethod<String, dynamic>(
        'startListening',
        senderPhoneNumber != null
            ? {'senderPhoneNumber': senderPhoneNumber}
            : null,
      );

      _isListening = false;
      developer.log('[SmsUserConsentService] Result received: $result');

      if (result == null) return null;

      final status = result['status']?.toString();
      if (status == 'success') {
        final code = result['code']?.toString();
        if (code != null && code.length == 6) {
          return code;
        }

        // Fallback: extract 6-digit number from message body if code wasn't parsed in native
        final sms = result['sms']?.toString() ?? '';
        final match = RegExp(r'\b\d{6}\b').firstMatch(sms);
        return match?.group(0);
      }

      // Denied, timeout, stopped, or cancelled
      return null;
    } on PlatformException catch (e) {
      _isListening = false;
      developer.log(
        '[SmsUserConsentService] PlatformException: ${e.code} - ${e.message}',
      );
      return null;
    } catch (e) {
      _isListening = false;
      developer.log('[SmsUserConsentService] Unexpected error: $e');
      return null;
    }
  }

  /// Cancels any active SMS listener and unregisters receiver cleanly.
  static Future<void> stopListening() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      _isListening = false;
      await _channel.invokeMethod('stopListening');
      developer.log(
        '[SmsUserConsentService] Stopped SMS User Consent listener',
      );
    } catch (e) {
      developer.log('[SmsUserConsentService] Error stopping listener: $e');
    }
  }
}
