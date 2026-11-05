import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/models/send_otp_model.dart';
import 'package:transwallet/models/privacy_policy_model.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/services/biometric_service.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/widgets/otp_input_field.dart';
import 'package:transwallet/services/sms_user_consent_service.dart';

class LoginSingupscreenController extends GetxController {
  static LoginSingupscreenController get to =>
      Get.find<LoginSingupscreenController>();

  GetStorage get box => GetStorage();
  final phoneFocusNode = FocusNode();
  var isPhoneFocused = false.obs;

  /// Closes only the OTP popup overlay and resets OTP fields without clearing the mobile number
  void closeOtpPopupOnly() {
    SmsUserConsentService.stopListening();
    isOtpSent.value = false;
    isPressed.value = false;
    _timer?.cancel();
    clearOtp();
    otpError.value = '';
    seconds.value = 60;
    canResend.value = false;
  }

  /// Completely resets OTP popup overlay, input fields, errors, and timers
  void resetLoginState({bool clearPhone = false}) {
    closeOtpPopupOnly();
    phoneError.value = '';
    mpinError.value = '';
    mpinController.clear();
    mpin.value = '';
    isChecked.value = false;
    if (clearPhone) {
      phoneController.clear();
      phone.value = '';
    }
  }

  // Privacy Policy state (persisted in-memory so it only fetches on-demand when user opens sheet)
  static PrivacyPolicyData? _cachedPrivacyPolicyData;
  final Rxn<PrivacyPolicyData> privacyPolicyData = Rxn<PrivacyPolicyData>();
  final RxBool isPrivacyPolicyLoading = false.obs;

  Future<void> fetchPrivacyPolicy({bool force = false}) async {
    if (!force) {
      if (privacyPolicyData.value != null) return;
      if (_cachedPrivacyPolicyData != null) {
        privacyPolicyData.value = _cachedPrivacyPolicyData;
        return;
      }
    }
    if (isPrivacyPolicyLoading.value) return;
    isPrivacyPolicyLoading.value = true;
    try {
      final response = await ApiService.to.getPrivacyPolicy(force: force);
      if (response.isOk && response.body != null) {
        final policyResp = PrivacyPolicyResponse.fromJson(response.body!);
        if (policyResp.success && policyResp.data != null) {
          _cachedPrivacyPolicyData = policyResp.data;
          privacyPolicyData.value = policyResp.data;
          log(
            "[Privacy Policy] Successfully loaded policy from API: ${policyResp.data!.sections.length} sections",
          );
        }
      }
    } catch (e) {
      log("[Privacy Policy] Failed to fetch privacy policy: $e");
    } finally {
      isPrivacyPolicyLoading.value = false;
    }
  }

  // Reactive biometric state
  final RxBool isBiometricAvailable = false.obs;
  final RxBool canLoginWithBiometrics = false.obs;
  final RxBool isBiometricSetup = false.obs;
  final RxString biometricLabel =
      (Platform.isIOS ? 'Face ID' : 'Fingerprint').obs;
  final Rx<IconData> biometricIcon =
      (Platform.isIOS ? Icons.face_rounded : Icons.fingerprint_rounded).obs;
  void updateBiometricState() {
    if (Get.isRegistered<BiometricService>()) {
      final service = BiometricService.to;
      service.syncBiometricState();
      isBiometricAvailable.value = service.isBiometricAvailable;
      canLoginWithBiometrics.value = service.canLoginWithBiometrics;
      isBiometricSetup.value = service.isBiometricSetup;
      biometricLabel.value = service.biometricTypeLabel;
      biometricIcon.value = service.biometricIcon;
    }
  }

  @override
  void onInit() {
    super.onInit();
    if (_cachedPrivacyPolicyData != null) {
      privacyPolicyData.value = _cachedPrivacyPolicyData;
    }
    closeOtpPopupOnly();
    // Pre-fill phone if saved and not already set in phoneController
    if (phoneController.text.isEmpty) {
      final savedPhone =
          box.read<String>('remembered_phone') ?? box.read<String>('phone');
      if (savedPhone != null && savedPhone.isNotEmpty) {
        final cleanPhone = savedPhone.replaceAll(RegExp(r'\D'), '');
        final finalPhone = cleanPhone.length > 10
            ? cleanPhone.substring(cleanPhone.length - 10)
            : cleanPhone;
        phoneController.text = finalPhone;
        phone.value = finalPhone;
      }
    }
    phoneFocusNode.addListener(() {
      isPhoneFocused.value = phoneFocusNode.hasFocus;
      if (!phoneFocusNode.hasFocus && scrollController.hasClients) {
        if (scrollController.offset > 0) {
          scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });

    if (Get.isRegistered<BiometricService>()) {
      BiometricService.to.checkBiometricSupport().then((_) {
        updateBiometricState();
      });
    }
    updateBiometricState();
  }

  var isBiometricLoading = false.obs;

  Future<void> loginWithBiometrics() async {
    if (isBiometricLoading.value) return;

    if (!Get.isRegistered<BiometricService>()) {
      AppSnackbar.error("Biometric service is not initialized");
      return;
    }

    final service = BiometricService.to;
    if (!service.isBiometricAvailable) {
      AppSnackbar.error(
        "Biometric authentication is not available on this device.",
      );
      return;
    }

    if (!service.isBiometricSetup) {
      AppSnackbar.info(
        "Biometric login is not set up yet. Please log in using MPIN or OTP first.",
      );
      return;
    }

    final enteredPhone = phoneController.text.trim();
    final savedPhone = box.read('phone')?.toString();
    final phoneToUse = enteredPhone.isNotEmpty ? enteredPhone : savedPhone;

    if (phoneToUse != null && phoneToUse.isNotEmpty) {
      box.write('phone', phoneToUse);
    }

    isBiometricLoading.value = true;

    try {
      final success = await service.authenticateAndLogin(
        mobileNumber: phoneToUse,
      );
      if (!success) {
        log("[Login Biometrics] Biometric login canceled or failed.");
      }
    } catch (e) {
      log("[Login Biometrics] Error: $e");
    } finally {
      if (Get.isRegistered<LoginSingupscreenController>()) {
        isBiometricLoading.value = false;
      }
    }
  }

  var phone = ''.obs;
  var isChecked = false.obs;
  var isOtpSent = false.obs;
  var isPressed = false.obs;
  final phoneController = TextEditingController();

  // Login Method: 'OTP' (sole authentication method on login screen)
  var loginMethod = 'OTP'.obs;
  bool get isOtpLogin => true;
  bool get isMpinLogin => false;

  void setLoginMethod(String method) {
    loginMethod.value = method;
    phoneError.value = '';
    mpinError.value = '';
    otpError.value = '';
    _mpinVisibilityTimer?.cancel();
    isMpinObscure.value = true;
    if (method == 'OTP' && scrollController.hasClients) {
      if (scrollController.offset > 0) {
        scrollController.jumpTo(0.0);
      }
    }
  }

  final scrollController = ScrollController();

  // MPIN fields
  final mpinController = TextEditingController();
  final mpinFocusNode = FocusNode();
  var mpin = ''.obs;
  RxString mpinError = ''.obs;
  var isMpinObscure = true.obs;
  Timer? _mpinVisibilityTimer;

  bool get isValidMpin => mpin.value.length == 4;

  void updateMpin(String value) {
    mpin.value = value;
    if (mpinError.value.isNotEmpty) {
      mpinError.value = '';
    }
  }

  void toggleMpinObscure() {
    _mpinVisibilityTimer?.cancel();
    isMpinObscure.value = !isMpinObscure.value;

    // When made visible, automatically obscure after 2.5 seconds
    if (!isMpinObscure.value) {
      _mpinVisibilityTimer = Timer(const Duration(milliseconds: 2500), () {
        isMpinObscure.value = true;
      });
    }
  }

  void onPrimaryActionPressed() {
    if (!isChecked.value) {
      AppSnackbar.error("Please accept the Terms & Conditions to proceed");
      return;
    }

    _showPrivacyPolicyDialog();
  }

  /// Shows the User Data Privacy Policy bottom sheet before sending OTP.
  /// Only calls [sendOtp] if the user taps "Agree & Continue".
  void _showPrivacyPolicyDialog() {
    if (privacyPolicyData.value == null && !isPrivacyPolicyLoading.value) {
      fetchPrivacyPolicy();
    }
    Get.bottomSheet(
      _PrivacyPolicySheet(onAgreed: sendOtp, controller: this),
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      ignoreSafeArea: false,
    );
  }

  Future<void> loginWithMpin() async {
    final enteredPhone = phoneController.text.trim();
    final enteredMpin = mpinController.text.trim();

    if (enteredPhone.isEmpty) {
      phoneError.value = "Mobile number is required";
      return;
    }
    if (enteredPhone.length != 10) {
      phoneError.value = "Enter valid 10 digit number";
      return;
    }
    phoneError.value = "";

    if (enteredMpin.isEmpty) {
      mpinError.value = "MPIN is required";
      return;
    }
    if (enteredMpin.length != 4) {
      mpinError.value = "Enter 4-digit MPIN";
      return;
    }
    mpinError.value = "";

    if (!isChecked.value) {
      AppSnackbar.error("Please accept the Terms & Conditions");
      return;
    }

    // Show loading indicator
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: primaryRed)),
      barrierDismissible: false,
    );

    try {
      final requestBody = {"mobileNumber": enteredPhone, "mpin": enteredMpin};
      log(
        "[Login MPIN] Calling /api/v1/auth/mpin/login with body: $requestBody",
      );

      final response = await ApiService.to.postRequest<Map<String, dynamic>>(
        '/api/v1/auth/mpin/login',
        requestBody,
      );

      // Dismiss loading dialog as soon as response arrives
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (response.status.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess =
            (body['success'] == true ||
                body['status'] == true ||
                body['status'] == 'success' ||
                body['code'] == 'OK' ||
                body['code'] == 200) &&
            body['status'] != false &&
            body['success'] != false;

        if (isSuccess) {
          final data = body['data'];
          String? accessToken;
          String? refreshToken;
          String? tokenType;
          dynamic expiresIn;

          if (data is Map) {
            accessToken =
                data['accessToken']?.toString() ?? data['token']?.toString();
            refreshToken = data['refreshToken']?.toString();
            tokenType = data['tokenType']?.toString() ?? 'Bearer';
            expiresIn = data['expiresIn'];

            final Map userMap = (data['user'] is Map)
                ? (data['user'] as Map)
                : data;
            final String extractedName =
                userMap['name']?.toString() ??
                userMap['fullName']?.toString() ??
                '${userMap['firstName'] ?? ''} ${userMap['lastName'] ?? ''}'
                    .trim();
            if (extractedName.isNotEmpty) {
              box.write('name', extractedName);
            }
            if (userMap['email'] != null) box.write('email', userMap['email']);
            if (userMap['phone'] != null) box.write('phone', userMap['phone']);
            if (userMap['mobileNumber'] != null)
              box.write('phone', userMap['mobileNumber']);
          }

          if (accessToken != null && accessToken.isNotEmpty) {
            box.write('accessToken', accessToken);
            box.write('auth_token', accessToken);
            box.write('token', accessToken);
          }
          if (refreshToken != null && refreshToken.isNotEmpty) {
            box.write('refreshToken', refreshToken);
            box.write('refresh_token', refreshToken);
          }
          if (tokenType != null) box.write('tokenType', tokenType);
          if (expiresIn != null) {
            box.write('expiresIn', expiresIn);
          }

          if (Get.isRegistered<AuthService>()) {
            await AuthService.to.saveSession(
              token: accessToken ?? '',
              refreshToken: refreshToken,
              tokenType: tokenType,
              expiresIn: expiresIn,
              userId: enteredPhone,
              userData: {
                'phone': enteredPhone,
                'tokenType': tokenType ?? 'Bearer',
                'expiresIn': expiresIn,
              },
            );
          }

          box.write('has_mpin', true);
          box.write('mpin_set', true);
          box.write('saved_mpin', enteredMpin);
          box.write('remembered_mpin', enteredMpin);
          box.write('phone', enteredPhone);
          box.write('remembered_phone', enteredPhone);
          box.write('biometric_quick_login_enabled', true);
          box.write('biometric_enabled', true);
          box.write('is_logged_in', true);
          box.write('pending_app_lock_prompt', true);
          closeOtpPopupOnly();

          // Register device token with backend on successful login response
          if (Get.isRegistered<ApiService>()) {
            ApiService.to.registerDeviceToken();
          }

          AppSnackbar.success(
            body['message']?.toString() ?? "Login successful",
          );
          Get.offAllNamed('/dashboard');
        } else {
          final errorMsg =
              body['message']?.toString() ??
              body['exception']?.toString() ??
              "Invalid MPIN";
          mpinError.value = errorMsg;
          AppSnackbar.error(errorMsg);
        }
      } else {
        final String errorMsg =
            (response.body != null &&
                (response.body!['message'] != null ||
                    response.body!['error'] != null))
            ? (response.body!['message']?.toString() ??
                  response.body!['error']?.toString() ??
                  "Server error. Please try again after some time.")
            : "Server error. Please try again after some time.";
        mpinError.value = errorMsg;
        AppSnackbar.error(errorMsg);
      }
    } catch (e) {
      log("[Login MPIN] Error: $e");
      const errorMsg = "Server error. Please try again after some time.";
      mpinError.value = errorMsg;
      AppSnackbar.error(errorMsg);
    } finally {
      // Ensure any open loading dialog is always dismissed
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
  }

  RxString phoneError = ''.obs;
  RxString otpError = ''.obs;

  var otp = ''.obs;

  var seconds = 60.obs;
  var canResend = false.obs;
  Timer? _timer;

  bool get isValidPhone => phone.value.length == 10;
  bool get canSendOtp => isValidPhone && isChecked.value;
  bool get isOtpComplete => otp.value.length == 6;

  void updatePhone(String value) {
    phone.value = value;
  }

  void toggleCheck(bool? value) {
    isChecked.value = value ?? false;
  }

  void sendOtp() {
    if (!isOtpSent.value) {
      _sendOtp();
    } else {
      _verifyOtp();
    }
  }

  Future<void> _sendOtp() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      phoneError.value = "Mobile number is required";
      return;
    }

    if (phone.length != 10) {
      phoneError.value = "Enter valid 10 digit number";
      return;
    }

    phoneError.value = "";

    if (!isChecked.value) {
      AppSnackbar.error("Please accept the Terms & Conditions to proceed");
      return;
    }

    // Start listening for SMS User Consent BEFORE calling the OTP-send API
    _listenForSmsConsent();

    // Show loading indicator
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: primaryRed)),
      barrierDismissible: false,
    );

    try {
      final requestModel = SendOtpRequest(
        // entityId: "ANKIT9470",
        mobileNumber: phone,
      );
      log("check response>> $requestModel");
      final response = await ApiService.to.postRequest<dynamic>(
        '/api/v1/auth/otp/send',
        requestModel.toJson(),
      );

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (response.status.isOk && response.body != null) {
        final Map<String, dynamic>? body = _parseBody(response.body);
        if (body == null) {
          AppSnackbar.error("Unexpected server response. Please try again.");
          return;
        }
        final otpResponse = SendOtpResponse.fromJson(body);
        if (otpResponse.success && otpResponse.data != null) {
          final providerRef = otpResponse.data!.providerRef;
          final flow = otpResponse.data!.flow;
          box.write('entityId', providerRef);
          box.write('providerRef', providerRef);
          box.write('otpFlow', flow);
          log(
            "OTP Sent successfully. Stored providerRef: $providerRef, flow: $flow",
          );

          isOtpSent.value = true;
          startTimer();
          AppSnackbar.success("OTP has been sent successfully");
        } else {
          SmsUserConsentService.stopListening();
          final errorMsg = otpResponse.exception ?? "Failed to send OTP";
          AppSnackbar.error(errorMsg);
        }
      } else {
        SmsUserConsentService.stopListening();
        final Map<String, dynamic>? errBody = _parseBody(response.body);
        final String errorMsg =
            errBody?['message']?.toString() ??
            errBody?['error']?.toString() ??
            "Server error. Please try again after some time.";
        phoneError.value = errorMsg;
        AppSnackbar.error(errorMsg);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      log("[Send OTP] Error: $e");
      SmsUserConsentService.stopListening();
      const errorMsg = "Server error. Please try again after some time.";
      phoneError.value = errorMsg;
      AppSnackbar.error(errorMsg);
    }
  }

  bool _isVerifyingOtp = false;

  void _listenForSmsConsent() {
    SmsUserConsentService.listenForOtp().then((code) {
      if (code != null && code.length == 6) {
        if (isOtpSent.value && !_isVerifyingOtp) {
          log(
            "[SMS Autofill] Received 6-digit OTP from SMS User Consent: $code",
          );
          _otpController.text = code;
        }
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_isVerifyingOtp) return;

    if (!isChecked.value) {
      AppSnackbar.error("Please accept the Terms & Conditions to proceed");
      return;
    }

    if (!isOtpComplete) {
      otpError.value = "Please enter complete OTP";
      AppSnackbar.error("Please enter complete OTP");
      return;
    }
    otpError.value = '';

    _isVerifyingOtp = true;
    SmsUserConsentService.stopListening();

    final enteredPhone = phoneController.text.trim();

    // Show loading indicator
    if (Get.context != null) {
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: primaryRed)),
        barrierDismissible: false,
      );
    }

    try {
      final String flow = box.read('otpFlow') ?? 'REGISTER';
      final String providerRef =
          box.read('providerRef') ?? box.read('entityId') ?? '';

      final requestModel = VerifyOtpRequest(
        mobileNumber: enteredPhone,
        otp: otp.value,
        purpose: flow,
        providerRef: providerRef,
      );

      log("Verifying OTP with body: ${requestModel.toJson()}");

      final response = await ApiService.to.postRequest<dynamic>(
        '/api/v1/auth/otp/verify',
        requestModel.toJson(),
      );

      if (Get.isDialogOpen ?? false) {
        Get.back(); // Dismiss loading indicator
      }

      if (response.status.isOk && response.body != null) {
        final Map<String, dynamic>? parsedBody = _parseBody(response.body);
        if (parsedBody == null) {
          otpError.value = "Unexpected server response. Please try again.";
          AppSnackbar.error(otpError.value);
          return;
        }
        final verifyResponse = VerifyOtpResponse.fromJson(parsedBody);
        if (verifyResponse.success) {
          log("OTP Verified successfully: ${verifyResponse.data}");
          otpError.value = '';

          final data = verifyResponse.data;
          final responseBody = parsedBody;

          // Determine the flow: LOGIN vs REGISTER
          // Check response data/body first, then fallback to stored otpFlow from send OTP
          final flowCandidate =
              (data?['flow'] ??
                      responseBody['flow'] ??
                      data?['purpose'] ??
                      data?['type'] ??
                      data?['action'] ??
                      box.read('otpFlow') ??
                      flow)
                  ?.toString()
                  .trim()
                  .toUpperCase();

          bool isLoginFlow = false;
          if (flowCandidate != null && flowCandidate.isNotEmpty) {
            if (flowCandidate == 'LOGIN' || flowCandidate.contains('LOG')) {
              isLoginFlow = true;
            } else if (flowCandidate == 'REGISTER' ||
                flowCandidate.contains('REG') ||
                flowCandidate == 'SIGNUP') {
              isLoginFlow = false;
            }
          }

          // Check explicit user registration flags if present in response
          if (data != null) {
            if (data['isNewUser'] == true || data['newUser'] == true) {
              isLoginFlow = false;
            } else if (data['isRegistered'] == true ||
                data['registered'] == true ||
                data['isExistingUser'] == true) {
              isLoginFlow = true;
            } else if (data['isRegistered'] == false ||
                data['registered'] == false) {
              isLoginFlow = false;
            } else if (data['registrationToken'] != null &&
                data['registrationToken'].toString().isNotEmpty &&
                data['accessToken'] == null) {
              isLoginFlow = false;
            }
          }

          if (isLoginFlow) {
            log(
              "[OTP Verify] Flow is LOGIN -> Validating token and redirecting to /dashboard",
            );

            String? accessToken;
            String? refreshToken;
            String? tokenType;
            dynamic expiresIn;

            if (data != null) {
              accessToken =
                  data['accessToken']?.toString() ??
                  data['token']?.toString() ??
                  data['authToken']?.toString();
              refreshToken = data['refreshToken']?.toString();
              tokenType = data['tokenType']?.toString() ?? 'Bearer';
              expiresIn = data['expiresIn'];

              final Map userMap = (data['user'] is Map)
                  ? (data['user'] as Map)
                  : data;
              final String extractedName =
                  userMap['name']?.toString() ??
                  userMap['fullName']?.toString() ??
                  '${userMap['firstName'] ?? ''} ${userMap['lastName'] ?? ''}'
                      .trim();
              if (extractedName.isNotEmpty) {
                box.write('name', extractedName);
              }
              if (userMap['email'] != null)
                box.write('email', userMap['email']);
              if (userMap['phone'] != null)
                box.write('phone', userMap['phone']);
              if (userMap['mobileNumber'] != null)
                box.write('phone', userMap['mobileNumber']);
            }

            if (accessToken != null && accessToken.isNotEmpty) {
              box.write('accessToken', accessToken);
              box.write('auth_token', accessToken);
              box.write('token', accessToken);
            }

            if (refreshToken != null && refreshToken.isNotEmpty) {
              box.write('refreshToken', refreshToken);
              box.write('refresh_token', refreshToken);
            }
            if (tokenType != null) box.write('tokenType', tokenType);
            if (expiresIn != null) {
              box.write('expiresIn', expiresIn);
            }

            box.write('otpFlow', 'LOGIN');
            box.write('is_logged_in', true);
            box.write('has_mpin', true);
            box.write('mpin_set', true);
            box.write('phone', enteredPhone);

            if (Get.isRegistered<AuthService>()) {
              await AuthService.to.saveSession(
                token: accessToken ?? '',
                refreshToken: refreshToken,
                tokenType: tokenType,
                expiresIn: expiresIn,
                userId: enteredPhone,
                userData: {
                  'phone': enteredPhone,
                  'tokenType': tokenType ?? 'Bearer',
                  'expiresIn': expiresIn,
                },
              );
            }

            box.write('is_logged_in', true);
            box.write('pending_app_lock_prompt', true);
            closeOtpPopupOnly();

            // Register device token with backend on successful login response
            if (Get.isRegistered<ApiService>()) {
              ApiService.to.registerDeviceToken();
            }

            AppSnackbar.success(verifyResponse.message ?? "Login successful");
            Get.offAllNamed('/dashboard');
          } else {
            log(
              "[OTP Verify] Flow is REGISTER -> Saving registrationToken and redirecting to /createaccountview",
            );
            box.write('otpFlow', 'REGISTER');
            box.write('phone', enteredPhone);

            if (data != null) {
              final regToken =
                  data['registrationToken'] ??
                  data['token'] ??
                  data['authToken'];
              if (regToken != null && regToken.toString().isNotEmpty) {
                box.write('registrationToken', regToken.toString());
              }
            }

            closeOtpPopupOnly();

            AppSnackbar.success(
              verifyResponse.message ?? "OTP verified successfully",
            );
            Get.toNamed('/createaccountview')?.then((_) {
              closeOtpPopupOnly();
            });
          }
        } else {
          final errorMsg = verifyResponse.message ?? "OTP verification failed";
          otpError.value = errorMsg;
          AppSnackbar.error(errorMsg);
        }
      } else {
        final Map<String, dynamic>? errBody = _parseBody(response.body);
        final String errorMsg =
            errBody?['message']?.toString() ??
            errBody?['error']?.toString() ??
            "Server error. Please try again after some time.";
        otpError.value = errorMsg;
        AppSnackbar.error(errorMsg);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      log("[OTP Verify] Error: $e");
      const errorMsg = "Server error. Please try again after some time.";
      otpError.value = errorMsg;
      AppSnackbar.error(errorMsg);
    } finally {
      _isVerifyingOtp = false;
    }
  }

  void startTimer() {
    seconds.value = 60;
    canResend.value = false;

    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (seconds.value > 0) {
        seconds.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }

  void resendOtp() {
    if (!canResend.value) return;

    clearOtp();

    _sendOtp();
  }

  void changeNumber() {
    closeOtpPopupOnly();
  }

  void clearOtp() {
    otp.value = '';
    otpError.value = '';
    _otpController.clear();
  }

  /// Safely coerces a GetConnect response body to `Map<String, dynamic>`.
  ///
  /// GetConnect sometimes returns the body as a raw [String] instead of a
  /// decoded [Map] — particularly when the server sends `Content-Type: text/plain`
  /// or when the response decoder isn't triggered. This helper handles all cases:
  ///   - Already a Map  → returned as-is
  ///   - A JSON String  → decoded via jsonDecode
  ///   - Anything else  → returns null (caller shows a generic error)
  Map<String, dynamic>? _parseBody(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  @override
  void onClose() {
    SmsUserConsentService.stopListening();
    _mpinVisibilityTimer?.cancel();
    _timer?.cancel();
    phoneFocusNode.dispose();
    phoneController.dispose();
    mpinController.dispose();
    mpinFocusNode.dispose();
    scrollController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.onClose();
  }

  // Single controller + focus node backing the OtpInputField widget
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  /// Builds the OTP input field. [onCompleted] is called when all 6 digits
  /// are filled — either by manual typing or OS SMS autofill.
  Widget otpField({required Function(String otp) onCompleted}) {
    return OtpInputField(
      controller: _otpController,
      focusNode: _otpFocusNode,
      boxHeight: 40,
      onChanged: (val) {
        otpError.value = '';
        otp.value = val;
      },
      onCompleted: (val) {
        otp.value = val;
        onCompleted(val);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Privacy Policy Bottom Sheet
// Shown before the OTP is sent. User must tap "Agree & Continue" to proceed.
// "Decline" closes the sheet without doing anything.
// ─────────────────────────────────────────────────────────────────────────────

// Stateful because it owns the consent checkbox in the consent section.
class _PrivacyPolicySheet extends StatefulWidget {
  final VoidCallback onAgreed;
  final LoginSingupscreenController? controller;
  const _PrivacyPolicySheet({required this.onAgreed, this.controller});

  @override
  State<_PrivacyPolicySheet> createState() => _PrivacyPolicySheetState();
}

class _PrivacyPolicySheetState extends State<_PrivacyPolicySheet> {
  bool _consentChecked = false;

  LoginSingupscreenController get _controller =>
      widget.controller ?? Get.find<LoginSingupscreenController>();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final agreeEnabled = _consentChecked;

    return SafeArea(
      child: Container(
        height: screenHeight * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Drag handle ──────────────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryLightYellow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.privacy_tip_rounded,
                      color: primaryRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Obx(
                      () => Text(
                        _controller.privacyPolicyData.value?.title ??
                            'User Data Privacy Policy',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // ── Scrollable policy content ────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (_controller.isPrivacyPolicyLoading.value &&
                    _controller.privacyPolicyData.value == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final policyData = _controller.privacyPolicyData.value;
                if (policyData == null || policyData.sections.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 40,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No policy data available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () =>
                                _controller.fetchPrivacyPolicy(force: true),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final sections = policyData.sections;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...sections.asMap().entries.map((entry) {
                        final index = entry.key;
                        final section = entry.value;
                        final isConsent =
                            section.heading.trim().toLowerCase() == 'consent' ||
                            (index == sections.length - 1 &&
                                section.heading.toLowerCase().contains(
                                  'consent',
                                ));

                        if (isConsent) {
                          final consentText = section.paragraphs.join('\n\n');

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _PolicySection(
                              number: '${index + 1}',
                              title: section.heading,
                              customBody: GestureDetector(
                                onTap: () => setState(
                                  () => _consentChecked = !_consentChecked,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _consentChecked
                                        ? const Color(0xFFF8F8F8)
                                        : const Color(0xFFF8F8F8),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _consentChecked
                                          ? const Color(0xFFE7E7E7)
                                          : const Color(0xFFE7E7E7),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Checkbox
                                      Container(
                                        width: 20,
                                        height: 20,
                                        margin: const EdgeInsets.only(top: 1),
                                        decoration: BoxDecoration(
                                          color: _consentChecked
                                              ? primaryRed
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          border: Border.all(
                                            color: _consentChecked
                                                ? primaryRed
                                                : const Color(0xFF9CA3AF),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: _consentChecked
                                            ? const Icon(
                                                Icons.check,
                                                size: 13,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      // Consent text
                                      Expanded(
                                        child: Text(
                                          consentText,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            height: 1.6,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _PolicySection(
                            number: '${index + 1}',
                            title: section.heading,
                            paragraphs: section.paragraphs,
                            bullets: section.bullets,
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              }),
            ),

            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // ── Action buttons ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Row(
                children: [
                  // Decline
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFFFCA5A5),
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Decline',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Agree & Continue — active only when consent checkbox is ticked
                  Expanded(
                    child: GestureDetector(
                      onTap: agreeEnabled
                          ? () {
                              Get.back();
                              widget.onAgreed();
                            }
                          : null,
                      child: AnimatedContainer(
                        height: 50,
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: agreeEnabled
                              ? Colors.black
                              : const Color(0xFFD1D5DB),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            'Agree & Continue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: agreeEnabled
                                  ? Colors.white
                                  : const Color(0xFF9CA3AF),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a single numbered policy section.
/// If [customBody] is provided it is rendered instead of the plain [body] or [paragraphs]/[bullets].
class _PolicySection extends StatelessWidget {
  final String number;
  final String title;
  final List<String>? paragraphs;
  final List<String>? bullets;
  final Widget? customBody;

  const _PolicySection({
    required this.number,
    required this.title,
    this.paragraphs,
    this.bullets,
    this.customBody,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number. $title',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 8),
        if (customBody != null)
          customBody!
        else ...[
          if (paragraphs != null && paragraphs!.isNotEmpty)
            ...paragraphs!.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  p,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.65,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
            ),
          if (bullets != null && bullets!.isNotEmpty)
            ...bullets!.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B5563),
                        height: 1.65,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        b,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.65,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
