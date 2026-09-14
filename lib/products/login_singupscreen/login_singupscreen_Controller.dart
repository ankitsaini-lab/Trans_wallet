import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/utilities/getStorage.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/models/send_otp_model.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/services/biometric_service.dart';

class LoginSingupscreenController extends GetxController {
  final phoneFocusNode = FocusNode();
  var isPhoneFocused = false.obs;

  // Reactive biometric state
  final RxBool isBiometricAvailable = true.obs;
  final RxBool canLoginWithBiometrics = true.obs;
  final RxString biometricLabel =
      (Platform.isIOS ? 'Face ID' : 'Fingerprint').obs;
  final Rx<IconData> biometricIcon =
      (Platform.isIOS ? Icons.face_rounded : Icons.fingerprint_rounded).obs;
  void updateBiometricState() {
    if (Get.isRegistered<BiometricService>()) {
      final service = BiometricService.to;
      isBiometricAvailable.value = service.isBiometricAvailable;
      canLoginWithBiometrics.value = service.canLoginWithBiometrics;
      biometricLabel.value = service.biometricTypeLabel;
      biometricIcon.value = service.biometricIcon;
    }
  }

  @override
  void onInit() {
    super.onInit();
    phoneFocusNode.addListener(() {
      isPhoneFocused.value = phoneFocusNode.hasFocus;
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
    if (!service.isBiometricEnabled.value) {
      AppSnackbar.info("Biometric login is disabled in settings.");
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

  // Login Method: 'OTP' or 'MPIN'
  var loginMethod = 'OTP'.obs;
  bool get isOtpLogin => loginMethod.value == 'OTP';
  bool get isMpinLogin => loginMethod.value == 'MPIN';

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
    if (isOtpLogin) {
      sendOtp();
    } else {
      loginWithMpin();
    }
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

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (response.status.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';

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

            if (data['user'] is Map) {
              final user = data['user'] as Map;
              if (user['name'] != null) box.write('name', user['name']);
              if (user['email'] != null) box.write('email', user['email']);
              if (user['phone'] != null) box.write('phone', user['phone']);
            }
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
          box.write('phone', enteredPhone);
          box.write('is_logged_in', true);

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
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      log("[Login MPIN] Error: $e");
      const errorMsg = "Server error. Please try again after some time.";
      mpinError.value = errorMsg;
      AppSnackbar.error(errorMsg);
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
      final response = await ApiService.to.postRequest<Map<String, dynamic>>(
        '/api/v1/auth/otp/send',
        requestModel.toJson(),
      );

      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      if (response.status.isOk && response.body != null) {
        final otpResponse = SendOtpResponse.fromJson(response.body!);
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
          final errorMsg = otpResponse.exception ?? "Failed to send OTP";
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
        phoneError.value = errorMsg;
        AppSnackbar.error(errorMsg);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      log("[Send OTP] Error: $e");
      const errorMsg = "Server error. Please try again after some time.";
      phoneError.value = errorMsg;
      AppSnackbar.error(errorMsg);
    }
  }

  Future<void> _verifyOtp() async {
    if (!isOtpComplete) {
      otpError.value = "Please enter complete OTP";
      AppSnackbar.error("Please enter complete OTP");
      return;
    }
    otpError.value = '';

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

      final response = await ApiService.to.postRequest<Map<String, dynamic>>(
        '/api/v1/auth/otp/verify',
        requestModel.toJson(),
      );

      if (Get.isDialogOpen ?? false) {
        Get.back(); // Dismiss loading indicator
      }

      if (response.status.isOk && response.body != null) {
        final verifyResponse = VerifyOtpResponse.fromJson(response.body!);
        if (verifyResponse.success) {
          log("OTP Verified successfully: ${verifyResponse.data}");
          otpError.value = '';

          final data = verifyResponse.data;
          final responseBody = response.body!;

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

              if (data['user'] is Map) {
                final user = data['user'] as Map;
                if (user['name'] != null) box.write('name', user['name']);
                if (user['email'] != null) box.write('email', user['email']);
                if (user['phone'] != null) box.write('phone', user['phone']);
              }
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

            AppSnackbar.success(
              verifyResponse.message ?? "OTP verified successfully",
            );
            Get.toNamed('/createaccountview');
          }
        } else {
          final errorMsg = verifyResponse.message ?? "OTP verification failed";
          otpError.value = errorMsg;
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
    isOtpSent.value = false;
    _timer?.cancel();
    clearOtp();
  }

  void clearOtp() {
    otp.value = '';
    otpError.value = '';
    for (var c in otpControllers) {
      c.clear();
    }
  }

  @override
  void onClose() {
    _mpinVisibilityTimer?.cancel();
    _timer?.cancel();
    phoneFocusNode.dispose();
    phoneController.dispose();
    mpinController.dispose();
    mpinFocusNode.dispose();
    scrollController.dispose();
    super.onClose();
  }

  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());

  Widget otpField({required Function(String otp) onCompleted}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return Expanded(
          child: Container(
            height: 40,

            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: PremiumOtpCell(
                controller: otpControllers[index],
                focusNode: otpFocusNodes[index],
                index: index,
                onChanged: (value) {
                  otpError.value = '';
                  otp.value = otpControllers.map((e) => e.text).join();

                  if (value.isNotEmpty) {
                    if (index < 5) {
                      FocusScope.of(
                        Get.context!,
                      ).requestFocus(otpFocusNodes[index + 1]);
                    } else {
                      FocusScope.of(Get.context!).unfocus();
                      onCompleted(otp.value);
                    }
                  } else {
                    if (index > 0) {
                      FocusScope.of(
                        Get.context!,
                      ).requestFocus(otpFocusNodes[index - 1]);
                    }
                  }
                },
              ),
            ),
          ),
        );
      }),
    );
  }
}

class PremiumOtpCell extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int index;
  final Function(String) onChanged;

  const PremiumOtpCell({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.index,
    required this.onChanged,
  });

  @override
  State<PremiumOtpCell> createState() => _PremiumOtpCellState();
}

class _PremiumOtpCellState extends State<PremiumOtpCell> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isFocused ? 1.06 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isFocused ? primaryRed : const Color(0xFFE5E7EB),
            width: _isFocused ? 2.0 : 1.5,
          ),
        ),
        child: Center(
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color.fromARGB(255, 17, 17, 17),
              letterSpacing: 0,
            ),
            showCursor: false,
            decoration: const InputDecoration(
              counterText: "",
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (val) {
              setState(() {});
              widget.onChanged(val);
            },
          ),
        ),
      ),
    );
  }
}
