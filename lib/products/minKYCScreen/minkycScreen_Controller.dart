import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/products/login_singupscreen/create%20Account/createaccount_Controller.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/services/biometric_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/widgets/constsize.dart';

class MinkycscreenController extends GetxController {
  var pan = ''.obs;
  var isButtonEnabled = false.obs;
  var isLoading = false.obs;
  var isPanVerified = false.obs;
  var otp = ''.obs;
  var panError = ''.obs;
  var debugOtp = ''.obs;
  var panVerifyRegistrationToken = ''.obs;

  bool _isValidPan(String value) {
    return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value);
  }

  void onPanChanged(String value) {
    pan.value = value;
    isPanVerified.value = false;
    if (value.isEmpty) {
      panError.value = '';
    } else if (!_isValidPan(value)) {
      panError.value = 'Invalid PAN format (e.g. ABCDE1234F)';
    } else {
      panError.value = '';
    }
    isButtonEnabled.value = _isValidPan(value);
  }

  void handleButtonAction() {
    if (isPanVerified.value) {
      completeRegistration();
    } else {
      verifyPan();
    }
  }

  String _resolveParam(String? fromCtrl, List<String> storageKeys) {
    if (fromCtrl != null && fromCtrl.trim().isNotEmpty) {
      return fromCtrl.trim();
    }
    final box = GetStorage();
    for (final key in storageKeys) {
      final val = box.read(key);
      if (val != null) {
        final str = val.toString().trim();
        if (str.isNotEmpty && str != 'null') {
          return str;
        }
      }
    }
    return '';
  }

  String _formatDob(String rawDob) {
    final trimmed = rawDob.trim();
    if (trimmed.isEmpty || trimmed == 'null') return "";
    try {
      if (trimmed.contains('/')) {
        final parts = trimmed.split('/');
        if (parts.length == 3) {
          final p0 = parts[0].trim();
          final p1 = parts[1].trim().padLeft(2, '0');
          final p2 = parts[2].trim();
          if (p0.length == 4) {
            return "$p0-$p1-${p2.padLeft(2, '0')}";
          } else {
            return "${p2.padLeft(4, '0')}-$p1-${p0.padLeft(2, '0')}";
          }
        }
      } else if (trimmed.contains('-')) {
        final parts = trimmed.split('-');
        if (parts.length == 3) {
          final p0 = parts[0].trim();
          final p1 = parts[1].trim().padLeft(2, '0');
          final p2 = parts[2].trim();
          if (p0.length == 4) {
            return "$p0-$p1-${p2.padLeft(2, '0')}";
          } else {
            return "${p2.padLeft(4, '0')}-$p1-${p0.padLeft(2, '0')}";
          }
        }
      }
    } catch (_) {}
    return trimmed;
  }

  Future<void> completeRegistration() async {
    isLoading.value = true;
    panError.value = '';

    try {
      final box = GetStorage();

      // Priority 1: Registration token from PAN verify API response
      String registrationToken = panVerifyRegistrationToken.value.trim();

      if (registrationToken.isEmpty) {
        registrationToken = (box.read('pan_verify_registration_token') ?? '')
            .toString()
            .trim();
      }

      if (registrationToken.isEmpty) {
        registrationToken = (box.read('registrationToken') ?? '')
            .toString()
            .trim();
      }

      // Priority 2: Fallback to Get.arguments
      if (registrationToken.isEmpty &&
          Get.arguments is Map &&
          Get.arguments['registrationToken'] != null) {
        registrationToken = Get.arguments['registrationToken']
            .toString()
            .trim();
      }

      // Priority 3: Fallback to other stored keys
      if (registrationToken.isEmpty) {
        registrationToken = _resolveParam(null, [
          'registration_token',
          'auth_token',
          'token',
        ]);
      }

      if (registrationToken.isEmpty && Get.isRegistered<AuthService>()) {
        registrationToken = AuthService.to.token?.trim() ?? '';
      }

      CreateaccountController? createCtrl;
      if (Get.isRegistered<CreateaccountController>()) {
        createCtrl = Get.find<CreateaccountController>();
      }

      // 1. Title: parse as blank if not provided
      String rawTitle = '';
      if (createCtrl != null &&
          createCtrl.title.value.isNotEmpty &&
          createCtrl.title.value.trim() != 'Select') {
        rawTitle = createCtrl.title.value;
      }
      if (rawTitle.isEmpty &&
          Get.arguments is Map &&
          Get.arguments['title'] != null) {
        rawTitle = Get.arguments['title'].toString();
      }
      if (rawTitle.isEmpty) {
        rawTitle = _resolveParam(null, [
          'reg_title',
          'title',
          'selected_title',
        ]);
      }
      rawTitle = rawTitle.replaceAll('.', '').trim();
      if (rawTitle == 'Select' || rawTitle == 'null') {
        rawTitle = '';
      }

      // 2. First Name: parse as blank if empty
      String firstName = _resolveParam(createCtrl?.firstName.value, [
        'reg_firstName',
        'firstName',
        'first_name',
      ]);
      if (firstName.isEmpty) {
        final storedName = (box.read('name') ?? '').toString().trim();
        if (storedName.isNotEmpty && storedName != 'null') {
          final parts = storedName.split(RegExp(r'\s+'));
          if (parts.isNotEmpty) firstName = parts.first.trim();
        }
      }

      // 3. Middle Name: parse as blank if empty
      String middleName = _resolveParam(createCtrl?.midName.value, [
        'reg_middleName',
        'middleName',
        'midName',
        'middle_name',
      ]);

      // 4. Last Name: parse as blank if empty
      String lastName = _resolveParam(createCtrl?.lastName.value, [
        'reg_lastName',
        'lastName',
        'last_name',
      ]);
      if (lastName.isEmpty) {
        final storedName = (box.read('name') ?? '').toString().trim();
        if (storedName.isNotEmpty && storedName != 'null') {
          final parts = storedName.split(RegExp(r'\s+'));
          if (parts.length > 1) {
            lastName = parts.sublist(1).join(' ').trim();
          }
        }
      }

      // 5. Gender: parse as blank if empty
      String rawGender = _resolveParam(createCtrl?.gender.value, [
        'reg_gender',
        'gender',
      ]).toUpperCase();
      if (rawGender == 'OTHERS') {
        rawGender = 'OTHER';
      }

      // 6. Email: parse as blank if empty
      String emailVal = _resolveParam(createCtrl?.email.value, [
        'reg_email',
        'email',
      ]);

      // 7. DOB: parse as blank if empty
      String rawDob = _resolveParam(createCtrl?.dob.value, ['reg_dob', 'dob']);
      String dobVal = _formatDob(rawDob);

      // 8. Has Activation Code: boolean
      bool hasCodeVal = true;
      if (createCtrl != null) {
        hasCodeVal = createCtrl.hasCode.value;
      } else {
        final rawCode =
            box.read('reg_hasActivationCode') ?? box.read('hasActivationCode');
        if (rawCode is bool) {
          hasCodeVal = rawCode;
        } else if (rawCode is String) {
          hasCodeVal = rawCode.toLowerCase() == 'true';
        }
      }

      // 9. Kit Number: parse as blank if empty
      String kitVal = _resolveParam(createCtrl?.kitNumber.value, [
        'reg_kitNumber',
        'kitNumber',
        'kit_number',
      ]);

      // 10. Address Line 1: parse as blank if empty
      String addr1 = _resolveParam(createCtrl?.address1.value, [
        'reg_addressLine1',
        'addressLine1',
        'address1',
        'address',
      ]);

      // 11. Address Line 2: parse as blank if empty
      String addr2 = _resolveParam(createCtrl?.address2.value, [
        'reg_addressLine2',
        'addressLine2',
        'address2',
      ]);

      // 12. Pincode: parse as blank if empty
      String pincodeVal = _resolveParam(createCtrl?.pincode.value, [
        'reg_pincode',
        'pincode',
        'pinCode',
        'pin_code',
      ]);

      // 13. Country: parse as blank if empty, or IN if India
      String countryVal = _resolveParam(createCtrl?.country.value, [
        'reg_country',
        'country',
      ]);
      if (countryVal.toLowerCase() == 'india') {
        countryVal = 'IN';
      }

      // 14. State: parse as blank if empty
      String stateVal = _resolveParam(createCtrl?.state.value, [
        'reg_state',
        'state',
      ]);

      // 15. City: parse as blank if empty
      String cityVal = _resolveParam(createCtrl?.city.value, [
        'reg_city',
        'city',
      ]);

      // 16. PAN Number: parse as blank if empty
      String panVal = pan.value.trim().toUpperCase();
      if (panVal.isEmpty) {
        panVal = _resolveParam(null, [
          'pan',
          'panNumber',
          'pan_number',
        ]).toUpperCase();
      }

      // Construct request body with all verified parameters
      final requestBody = <String, dynamic>{
        "registrationToken": registrationToken,
        "title": rawTitle,
        "firstName": firstName,
        "middleName": middleName,
        "lastName": lastName,
        "gender": rawGender,
        "email": emailVal,
        "dob": dobVal,
        "hasActivationCode": hasCodeVal,
        "kitNumber": kitVal,
        "addressLine1": addr1,
        "addressLine2": addr2,
        "pincode": pincodeVal,
        "country": countryVal,
        "state": stateVal,
        "city": cityVal,
        "panNumber": panVal,
      };

      final headers = registrationToken.isNotEmpty
          ? {'Authorization': 'Bearer $registrationToken'}
          : null;

      developer.log(
        "[Register Complete] Calling /api/v1/auth/register/complete with body:\n${const JsonEncoder.withIndent('  ').convert(requestBody)}",
      );

      final response = await ApiService.to.postRequest<Map<String, dynamic>>(
        '/api/v1/auth/register/complete',
        requestBody,
        headers: headers,
      );

      developer.log(
        "[Register Complete] Status: ${response.statusCode}, Body: ${response.body}",
      );

      isLoading.value = false;

      if (response.status.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';

        if (isSuccess) {
          if (body['data'] != null && body['data'] is Map) {
            final data = body['data'] as Map;
            final rawAccess = data['accessToken'];
            final rawRefresh = data['refreshToken'];
            final rawRegToken = data['registrationToken'];
            final rawDebugOtp = data['debugOtp'];

            String? accessToken;
            if (rawAccess is String &&
                rawAccess.trim().isNotEmpty &&
                rawAccess.trim() != '{}') {
              accessToken = rawAccess.trim();
              box.write('auth_token', accessToken);
              box.write('accessToken', accessToken);
              box.write('token', accessToken);
            }

            String? refreshToken;
            if (rawRefresh is String &&
                rawRefresh.trim().isNotEmpty &&
                rawRefresh.trim() != '{}') {
              refreshToken = rawRefresh.trim();
              box.write('refreshToken', refreshToken);
              box.write('refresh_token', refreshToken);
            }

            if (rawRegToken is String &&
                rawRegToken.trim().isNotEmpty &&
                rawRegToken.trim() != '{}') {
              box.write('registrationToken', rawRegToken.trim());
            }

            // Save flow and m2pOtpRequired if present
            final flow = data['flow']?.toString();
            if (flow != null && flow.isNotEmpty && flow != '{}') {
              box.write('registration_flow', flow);
            }
            final m2pRequired = data['m2pOtpRequired'];
            if (m2pRequired is bool) {
              box.write('m2pOtpRequired', m2pRequired);
            }

            if (rawDebugOtp != null) {
              String debugOtpStr = '';
              if (rawDebugOtp is String) {
                debugOtpStr = rawDebugOtp.trim();
              } else if (rawDebugOtp is num) {
                debugOtpStr = rawDebugOtp.toString();
              }
              if (debugOtpStr.isNotEmpty && debugOtpStr != '{}') {
                debugOtp.value = debugOtpStr;
                box.write('debugOtp', debugOtpStr);
              }
            }

            if (Get.isRegistered<AuthService>() &&
                accessToken != null &&
                accessToken.isNotEmpty &&
                accessToken != '{}') {
              Get.find<AuthService>().saveSession(
                token: accessToken,
                refreshToken: refreshToken,
                userId: box.read('user_id') ?? 'user',
                userData: {
                  'name': '$firstName $lastName'.trim(),
                  'email': emailVal,
                  'phone': box.read('phone') ?? '',
                },
              );
            }
          }

          final message =
              body['message']?.toString() ??
              "Registration details submitted successfully";
          AppSnackbar.success(message);

          // After api success open otp popup
          showOtpBottomSheet();
        } else {
          final errorMsg = body['message']?.toString() ?? "Registration failed";
          panError.value = errorMsg;
          AppSnackbar.error(errorMsg);
        }
      } else {
        String errorMsg = "Registration failed";
        if (response.body != null && response.body is Map) {
          final b = response.body as Map;
          errorMsg =
              b['message']?.toString() ??
              b['error']?.toString() ??
              b['errors']?.toString() ??
              b['exception']?.toString() ??
              errorMsg;
        } else if (response.statusText != null &&
            response.statusText!.isNotEmpty) {
          errorMsg = response.statusText!;
        }
        panError.value = errorMsg;
        AppSnackbar.error(errorMsg);
      }
    } catch (e) {
      isLoading.value = false;
      panError.value = "Something went wrong: $e";
      AppSnackbar.error("Something went wrong: $e");
    }
  }

  Future<void> verifyPan() async {
    final panValue = pan.value.trim().toUpperCase();

    if (panValue.isEmpty) {
      panError.value = 'PAN number is required';
      return;
    }
    if (!_isValidPan(panValue)) {
      panError.value = 'Invalid PAN format (e.g. ABCDE1234F)';
      return;
    }

    panError.value = '';

    // Direct bypass for test PAN: ABCDE1234Z
    if (panValue == "ABCDE1234Z") {
      developer.log(
        "[PAN Verify] Direct test bypass: skipping API call for $panValue",
      );
      final box = GetStorage();
      box.write('pan', panValue);
      isPanVerified.value = true;
      AppSnackbar.success("PAN verified successfully");
      return;
    }

    isLoading.value = true;

    try {
      String registrationToken = '';

      if (Get.arguments is Map && Get.arguments['registrationToken'] != null) {
        registrationToken = Get.arguments['registrationToken']
            .toString()
            .trim();
      }

      if (registrationToken.isEmpty) {
        registrationToken = _resolveParam(null, [
          'registrationToken',
          'registration_token',
          'auth_token',
          'token',
        ]);
      }

      if (registrationToken.isEmpty && Get.isRegistered<AuthService>()) {
        registrationToken = AuthService.to.token?.trim() ?? '';
      }

      final requestBody = {
        "registrationToken": registrationToken,
        "panNumber": panValue,
      };

      final headers = registrationToken.isNotEmpty
          ? {'Authorization': 'Bearer $registrationToken'}
          : null;

      developer.log(
        "[PAN Verify] Calling /api/v1/auth/pan/verify with body:\n${const JsonEncoder.withIndent('  ').convert(requestBody)}",
      );

      final response = await ApiService.to.postRequest<Map<String, dynamic>>(
        '/api/v1/auth/pan/verify',
        requestBody,
        headers: headers,
      );

      developer.log(
        "[PAN Verify] Status: ${response.statusCode}, Body: ${response.body}",
      );

      isLoading.value = false;

      if (response.status.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';

        // Check if PAN validation status is valid
        bool isPanValid = isSuccess;
        Map? dataMap;
        if (body['data'] != null && body['data'] is Map) {
          dataMap = body['data'] as Map;
          if (dataMap.containsKey('valid') && dataMap['valid'] == false) {
            isPanValid = false;
          }
          if (dataMap.containsKey('status') && dataMap['status'] == 'FAILED') {
            isPanValid = false;
          }
          if (dataMap.containsKey('panStatus') &&
              dataMap['panStatus'] == 'INVALID') {
            isPanValid = false;
          }
        }

        if (isPanValid) {
          isPanVerified.value = true;
          final box = GetStorage();
          box.write('pan', panValue);

          if (dataMap != null) {
            // Extract registered name from registeredName or nameOnPanCard
            final verifiedName =
                dataMap['registeredName']?.toString().trim() ??
                dataMap['nameOnPanCard']?.toString().trim() ??
                dataMap['name']?.toString().trim() ??
                '';
            if (verifiedName.isNotEmpty && verifiedName != 'null') {
              box.write('name', verifiedName);
              box.write('pan_name', verifiedName);
              box.write('registeredName', verifiedName);
              developer.log(
                "[PAN Verify] Extracted verified name: $verifiedName",
              );
            }

            // Save new registrationToken from PAN verify API response
            String extractedToken = '';
            final rawToken = dataMap['registrationToken'];
            if (rawToken is String &&
                rawToken.trim().isNotEmpty &&
                rawToken.trim() != '{}') {
              extractedToken = rawToken.trim();
            } else if (rawToken is Map) {
              final inner =
                  rawToken['token'] ??
                  rawToken['registrationToken'] ??
                  rawToken['accessToken'];
              if (inner != null &&
                  inner.toString().trim().isNotEmpty &&
                  inner.toString().trim() != '{}') {
                extractedToken = inner.toString().trim();
              }
            }

            // Check root body if not found in dataMap
            if (extractedToken.isEmpty && body['registrationToken'] != null) {
              final rootToken = body['registrationToken'];
              if (rootToken is String &&
                  rootToken.trim().isNotEmpty &&
                  rootToken.trim() != '{}') {
                extractedToken = rootToken.trim();
              } else if (rootToken is Map) {
                final inner =
                    rootToken['token'] ??
                    rootToken['registrationToken'] ??
                    rootToken['accessToken'];
                if (inner != null &&
                    inner.toString().trim().isNotEmpty &&
                    inner.toString().trim() != '{}') {
                  extractedToken = inner.toString().trim();
                }
              }
            }

            if (extractedToken.isNotEmpty) {
              panVerifyRegistrationToken.value = extractedToken;
              box.write('pan_verify_registration_token', extractedToken);
              box.write('registrationToken', extractedToken);
              developer.log(
                "[PAN Verify] Stored new registrationToken from PAN verify API: $extractedToken",
              );
            }
          }

          final message =
              dataMap?['message']?.toString() ??
              body['message']?.toString() ??
              "PAN verified successfully";
          AppSnackbar.success(message);
        } else {
          isPanVerified.value = false;
          final errorMsg =
              dataMap?['message']?.toString() ??
              dataMap?['panStatusDesc']?.toString() ??
              body['message']?.toString() ??
              "PAN verification failed";
          panError.value = errorMsg;
          AppSnackbar.error(errorMsg);
        }
      } else {
        isPanVerified.value = false;
        String errorMsg = "Verification failed";
        if (response.body != null && response.body is Map) {
          final b = response.body as Map;
          errorMsg =
              b['message']?.toString() ??
              b['error']?.toString() ??
              b['errors']?.toString() ??
              b['exception']?.toString() ??
              errorMsg;
        } else if (response.statusText != null &&
            response.statusText!.isNotEmpty) {
          errorMsg = response.statusText!;
        }
        panError.value = errorMsg;
        AppSnackbar.error(errorMsg);
      }
    } catch (e) {
      isLoading.value = false;
      isPanVerified.value = false;
      panError.value = "Something went wrong: $e";
      AppSnackbar.error("Something went wrong: $e");
    }
  }

  Future<bool> verifyPpiOtp(String otpValue) async {
    isLoading.value = true;

    try {
      final box = GetStorage();

      // Priority 1: Registration token from storage or PAN verify response
      String registrationToken = (box.read('registrationToken') ?? '')
          .toString()
          .trim();

      if (registrationToken.isEmpty) {
        registrationToken = panVerifyRegistrationToken.value.trim();
      }

      if (registrationToken.isEmpty) {
        registrationToken = (box.read('pan_verify_registration_token') ?? '')
            .toString()
            .trim();
      }

      // Priority 2: Fallback to Get.arguments
      if (registrationToken.isEmpty &&
          Get.arguments is Map &&
          Get.arguments['registrationToken'] != null) {
        registrationToken = Get.arguments['registrationToken']
            .toString()
            .trim();
      }

      // Priority 3: Fallback to other stored keys
      if (registrationToken.isEmpty) {
        registrationToken = _resolveParam(null, [
          'registration_token',
          'auth_token',
          'token',
        ]);
      }

      if (registrationToken.isEmpty && Get.isRegistered<AuthService>()) {
        registrationToken = AuthService.to.token?.trim() ?? '';
      }

      final requestBody = {
        "registrationToken": registrationToken,
        "otp": otpValue.trim(),
      };

      final headers = registrationToken.isNotEmpty
          ? {'Authorization': 'Bearer $registrationToken'}
          : null;

      developer.log(
        "[PPI OTP Verify] Calling /api/v1/auth/register/ppi-otp with body:\n${const JsonEncoder.withIndent('  ').convert(requestBody)}",
      );

      final response = await ApiService.to.postRequest<Map<String, dynamic>>(
        '/api/v1/auth/register/ppi-otp',
        requestBody,
        headers: headers,
      );

      developer.log(
        "[PPI OTP Verify] Status: ${response.statusCode}, Body: ${response.body}",
      );

      isLoading.value = false;

      if (response.status.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';

        if (isSuccess) {
          if (body['data'] != null && body['data'] is Map) {
            final data = body['data'] as Map;

            // 1. registrationToken
            final rawRegToken = data['registrationToken'];
            if (rawRegToken is String && rawRegToken.trim().isNotEmpty) {
              box.write('registrationToken', rawRegToken.trim());
            }

            // 2. accessToken
            final rawAccess = data['accessToken'];
            String? accessToken;
            if (rawAccess is String && rawAccess.trim().isNotEmpty) {
              accessToken = rawAccess.trim();
              box.write('auth_token', accessToken);
              box.write('accessToken', accessToken);
              box.write('token', accessToken);
            }

            // 3. refreshToken
            final rawRefresh = data['refreshToken'];
            String? refreshToken;
            if (rawRefresh is String && rawRefresh.trim().isNotEmpty) {
              refreshToken = rawRefresh.trim();
              box.write('refreshToken', refreshToken);
              box.write('refresh_token', refreshToken);
            }

            // 4. debugOtp
            final rawDebugOtp = data['debugOtp'];
            if (rawDebugOtp != null) {
              final debugOtpStr = rawDebugOtp.toString().trim();
              if (debugOtpStr.isNotEmpty && debugOtpStr != '{}') {
                debugOtp.value = debugOtpStr;
                box.write('debugOtp', debugOtpStr);
              }
            }

            if (Get.isRegistered<AuthService>() &&
                accessToken != null &&
                accessToken.isNotEmpty &&
                accessToken != '{}') {
              Get.find<AuthService>().saveSession(
                token: accessToken,
                refreshToken: refreshToken,
                userId: box.read('user_id') ?? 'user',
                userData: {
                  'name': box.read('name') ?? '',
                  'email': box.read('email') ?? '',
                  'phone': box.read('phone') ?? '',
                },
              );
            }
          }

          final message =
              body['message']?.toString() ?? "OTP verified successfully";
          AppSnackbar.success(message);

          if (Get.isDialogOpen ?? false) {
            Get.back();
          }

          showSuccessDialog();
          return true;
        } else {
          final errorMsg =
              body['message']?.toString() ?? "OTP verification failed";
          AppSnackbar.error(errorMsg);
          return false;
        }
      } else {
        String errorMsg = "OTP verification failed";
        if (response.body != null && response.body is Map) {
          final b = response.body as Map;
          errorMsg =
              b['message']?.toString() ?? b['error']?.toString() ?? errorMsg;
        } else if (response.statusText != null &&
            response.statusText!.isNotEmpty) {
          errorMsg = response.statusText!;
        }
        AppSnackbar.error(errorMsg);
        return false;
      }
    } catch (e) {
      isLoading.value = false;
      developer.log("[PPI OTP Verify] Exception: $e");
      AppSnackbar.error("Something went wrong: $e");
      return false;
    }
  }

  void showOtpBottomSheet([BuildContext? context]) {
    if (Get.testMode || Get.context == null) return;
    Get.dialog(
      _OtpDialog(controller: this),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    );
  }

  void showSuccessDialog() {
    if (Get.testMode || Get.context == null) return;
    Get.dialog(
      const _KycSuccessDialog(),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.offNamed('/create_mpin');
    });
  }
}

class _OtpDialog extends StatefulWidget {
  final MinkycscreenController controller;
  const _OtpDialog({required this.controller});

  @override
  State<_OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<_OtpDialog> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  String _otp = '';
  int _secondsLeft = 60;
  bool _canResend = false;
  bool _isSubmitting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    final serverOtp = widget.controller.debugOtp.value.trim();
    if (serverOtp.isNotEmpty) {
      _fillOtp(serverOtp);
    } else {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted && _otp.isEmpty) {
          _simulateAutoFetch();
        }
      });
    }
  }

  void _fillOtp(String code) {
    for (int i = 0; i < code.length && i < 6; i++) {
      _controllers[i].text = code[i];
    }
    setState(() {
      _otp = _controllers.map((c) => c.text).join();
    });
  }

  void _simulateAutoFetch() {
    final serverOtp = widget.controller.debugOtp.value.trim();
    final code = serverOtp.isNotEmpty ? serverOtp : "482617";
    for (int i = 0; i < code.length && i < 6; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].text = code[i];
          if (i == code.length - 1 || i == 5) {
            setState(() {
              _otp = _controllers.map((c) => c.text).join();
            });
            _focusNodes[i].unfocus();
          } else {
            _focusNodes[i + 1].requestFocus();
          }
        }
      });
    }

    Get.snackbar(
      'Auto-Fill Success',
      'Securely fetched OTP code $code',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF22C55E),
      colorText: Colors.white,
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
    );
  }

  Future<void> _handleVerifyProceed() async {
    if (_otp.length != 6 || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    await widget.controller.verifyPpiOtp(_otp);
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 1) {
        t.cancel();
        setState(() {
          _secondsLeft = 0;
          _canResend = true;
        });
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _resend() {
    for (final c in _controllers) {
      c.clear();
    }
    setState(() => _otp = '');
    _startTimer();
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 35),
            padding: const EdgeInsets.fromLTRB(24, 45, 24, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.elliptical(400, 50),
                bottom: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  height40,
                  height40,

                  const Text(
                    'Security Verification',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'We have sent 6- digit verification code to your secure mobile number.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // OTP Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 48,
                          child: TextField(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: const Color(0xFFF9F9F9),
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1.0,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                  width: 1.0,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: primaryRed,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (val) {
                              if (val.isNotEmpty && i < 5) {
                                FocusScope.of(
                                  context,
                                ).requestFocus(_focusNodes[i + 1]);
                              } else if (val.isEmpty && i > 0) {
                                FocusScope.of(
                                  context,
                                ).requestFocus(_focusNodes[i - 1]);
                              }
                              setState(() {
                                _otp = _controllers.map((c) => c.text).join();
                              });
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Timer / Resend
                  GestureDetector(
                    onTap: _canResend ? _resend : null,
                    child: RichText(
                      text: TextSpan(
                        text: _canResend ? 'Resend code' : 'Resend code in ',
                        style: TextStyle(
                          color: _canResend ? primaryRed : Colors.black87,
                          fontSize: 13,
                          fontWeight: _canResend
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                        children: [
                          if (!_canResend)
                            TextSpan(
                              text: _timerLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Verify Button
                  GestureDetector(
                    onTap: (_otp.length == 6 && !_isSubmitting)
                        ? _handleVerifyProceed
                        : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: (_otp.length == 6 && !_isSubmitting)
                            ? Colors.black
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                "Verify & Proceed",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 50,
            child: Image.asset(
              'assets/security verification.png',
              width: 80,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 45,
            right: 12,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black54, size: 22),
              onPressed: () {
                if (Get.isDialogOpen ?? false) {
                  Get.back();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KycSuccessDialog extends StatefulWidget {
  const _KycSuccessDialog();

  @override
  State<_KycSuccessDialog> createState() => _KycSuccessDialogState();
}

class _KycSuccessDialogState extends State<_KycSuccessDialog>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF22C55E);

  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 5,
                      width: 48,
                      decoration: BoxDecoration(
                        color: primaryRed,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 28),

                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 90,
                          width: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _green.withOpacity(0.08),
                          ),
                        ),
                        Container(
                          height: 68,
                          width: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _green.withOpacity(0.15),
                          ),
                        ),
                        Container(
                          height: 52,
                          width: 52,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _green,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'KYC Verified!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your identity has been successfully\nverified.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          icon: Icons.wallet_rounded,
                          label: 'Wallet Active',
                        ),
                        _Chip(icon: Icons.send_rounded, label: 'Transfers On'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Divider(color: Color(0xFFF0F0F0), height: 1),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              primaryRed,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Setting up your MPIN...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF22C55E).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF22C55E)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateMpinScreen extends StatefulWidget {
  const CreateMpinScreen({super.key});

  @override
  State<CreateMpinScreen> createState() => _CreateMpinScreenState();
}

class _CreateMpinScreenState extends State<CreateMpinScreen> {
  static const _textColor = Color(0xFF111111);
  static const _secondaryText = Color(0xFF6B7280);

  int _step = 1;
  String _mpin = '';
  String _confirmMpin = '';
  bool _hasError = false;
  bool _isLoading = false;
  bool _isSuccess = false;
  String _errorMessage = 'MPINs do not match. Try again.';

  String get _currentPin => _step == 1 ? _mpin : _confirmMpin;

  void _onKeyTap(String digit) {
    if (_currentPin.length >= 4 || _isSuccess || _isLoading) return;
    setState(() {
      _hasError = false;
      if (_step == 1) {
        _mpin += digit;
        if (_mpin.length == 4) _onMpinComplete();
      } else {
        _confirmMpin += digit;
        if (_confirmMpin.length == 4) _onConfirmComplete();
      }
    });
  }

  void _onDelete() {
    if (_isSuccess || _isLoading) return;
    setState(() {
      _hasError = false;
      if (_step == 1 && _mpin.isNotEmpty) {
        _mpin = _mpin.substring(0, _mpin.length - 1);
      } else if (_step == 2 && _confirmMpin.isNotEmpty) {
        _confirmMpin = _confirmMpin.substring(0, _confirmMpin.length - 1);
      }
    });
  }

  void _onMpinComplete() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _step = 2);
    });
  }

  Future<void> _onConfirmComplete() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    if (_mpin != _confirmMpin) {
      setState(() {
        _hasError = true;
        _errorMessage = 'MPINs do not match. Try again.';
        _confirmMpin = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final box = GetStorage();
      final token = box.read<String>('accessToken') ??
          box.read<String>('auth_token') ??
          box.read<String>('token') ??
          box.read<String>('registrationToken') ??
          (Get.isRegistered<AuthService>() ? AuthService.to.token : null);

      final headers = (token != null && token.trim().isNotEmpty)
          ? {'Authorization': 'Bearer ${token.trim()}'}
          : null;

      final requestBody = {
        "mpin": _confirmMpin,
      };

      developer.log(
        "[Set MPIN] Calling /api/v1/auth/mpin/set with body:\n${const JsonEncoder.withIndent('  ').convert(requestBody)}",
      );

      final response = await ApiService.to.postRequest<Map<String, dynamic>>(
        '/api/v1/auth/mpin/set',
        requestBody,
        headers: headers,
      );

      developer.log(
        "[Set MPIN] Status: ${response.statusCode}, Body: ${response.body}",
      );

      if (!mounted) return;

      if (response.status.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';

        if (isSuccess) {
          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });

          box.write('has_mpin', true);
          box.write('mpin_set', true);
          box.write('saved_mpin', _confirmMpin);

          final message =
              body['message']?.toString() ?? "MPIN set successfully";
          AppSnackbar.success(message);

          Future.delayed(const Duration(milliseconds: 600), () async {
            if (!mounted) return;
            if (Get.isRegistered<BiometricService>()) {
              final biometricService = BiometricService.to;
              await biometricService.checkBiometricSupport();
              if (mounted && biometricService.isBiometricAvailable) {
                await biometricService.promptBiometricPermission(
                  context,
                  onComplete: () {
                    Get.offAllNamed('/dashboard');
                  },
                );
              } else {
                Get.offAllNamed('/dashboard');
              }
            } else {
              Get.offAllNamed('/dashboard');
            }
          });
        } else {
          final errorMsg =
              body['message']?.toString() ?? "Failed to set MPIN";
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = errorMsg;
            _confirmMpin = '';
          });
          AppSnackbar.error(errorMsg);
        }
      } else {
        String errorMsg = "Failed to set MPIN";
        if (response.body != null && response.body is Map) {
          final b = response.body as Map;
          errorMsg =
              b['message']?.toString() ?? b['error']?.toString() ?? errorMsg;
        } else if (response.statusText != null &&
            response.statusText!.isNotEmpty) {
          errorMsg = response.statusText!;
        }
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = errorMsg;
          _confirmMpin = '';
        });
        AppSnackbar.error(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      developer.log("[Set MPIN] Exception: $e");
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = "Something went wrong: $e";
        _confirmMpin = '';
      });
      AppSnackbar.error("Something went wrong: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 32),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _isSuccess
                    ? Container(
                        key: const ValueKey('success'),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF22C55E),
                          size: 48,
                        ),
                      )
                    : Container(
                        key: const ValueKey('lock'),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: primaryRed.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: primaryRed,
                          size: 40,
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isSuccess
                    ? const Text(
                        'MPIN Created!',
                        key: ValueKey('t_success'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF22C55E),
                          letterSpacing: -0.4,
                        ),
                      )
                    : Text(
                        _step == 1 ? 'Create MPIN' : 'Confirm MPIN',
                        key: ValueKey('t_$_step'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _textColor,
                          letterSpacing: -0.4,
                        ),
                      ),
              ),

              const SizedBox(height: 8),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isSuccess
                    ? const Text(
                        'Your MPIN has been set.\nRedirecting to dashboard...',
                        key: ValueKey('s_success'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _secondaryText,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      )
                    : Text(
                        _step == 1
                            ? 'Set a 4-digit MPIN to secure\nyour transactions'
                            : 'Re-enter your MPIN to confirm',
                        key: ValueKey('s_$_step'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _secondaryText,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
              ),

              const SizedBox(height: 40),

              if (!_isSuccess)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StepDot(active: _step == 1, done: _step > 1),
                    const SizedBox(width: 8),
                    _StepDot(active: _step == 2),
                  ],
                ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _currentPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isSuccess
                          ? const Color(0xFF22C55E)
                          : _hasError
                          ? Colors.red
                          : filled
                          ? primaryRed
                          : const Color(0xFFECECEC),
                      border: Border.all(
                        color: _hasError
                            ? Colors.red.withOpacity(0.3)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),

              if (_hasError) ...[
                const SizedBox(height: 14),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const Spacer(),

              if (_isLoading) ...[
                const SizedBox(
                  height: 28,
                  width: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryRed),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Setting MPIN...',
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 40),
              ] else if (!_isSuccess) ...[
                _buildKeypad(),
                const SizedBox(height: 32),
              ] else ...[
                SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF22C55E),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _keyRow(['1', '2', '3']),
        const SizedBox(height: 14),
        _keyRow(['4', '5', '6']),
        const SizedBox(height: 14),
        _keyRow(['7', '8', '9']),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72),
            _KeyButton(label: '0', onTap: () => _onKeyTap('0')),
            _DeleteButton(onTap: _onDelete),
          ],
        ),
      ],
    );
  }

  Widget _keyRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map((d) => _KeyButton(label: d, onTap: () => _onKeyTap(d)))
          .toList(),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  final bool done;
  const _StepDot({this.active = false, this.done = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active || done ? primaryRed : const Color(0xFFECECEC),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _KeyButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _KeyButton({required this.label, required this.onTap});

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _pressed ? primaryYellow : const Color(0xFFF5F5F5),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatefulWidget {
  final VoidCallback onTap;
  const _DeleteButton({required this.onTap});

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: SizedBox(
          height: 72,
          width: 72,
          child: Icon(
            Icons.backspace_outlined,
            color: const Color(0xFF6B7280),
            size: 24,
          ),
        ),
      ),
    );
  }
}
