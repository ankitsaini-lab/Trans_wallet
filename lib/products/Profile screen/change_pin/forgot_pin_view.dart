import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/sms_user_consent_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/custom_numeric_keypad.dart';
import 'package:transwallet/widgets/dob_picker.dart';
import 'package:transwallet/widgets/otp_input_field.dart';

class ForgotPinView extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;

  const ForgotPinView({super.key, this.onSuccess, this.onCancel});

  @override
  State<ForgotPinView> createState() => _ForgotPinViewState();
}

class _ForgotPinViewState extends State<ForgotPinView> {
  static const Color _primaryRed = Color(0xFFED292A);
  static const Color _textColor = Color(0xFF111111);
  static const Color _secondaryText = Color(0xFF6B7280);
  static const Color _successGreen = Color(0xFF22C55E);
  static const Color _borderGrey = Color(0xFFE5E7EB);

  // 4 Main Steps:
  // 1 = Enter Mobile & Send OTP (/api/v1/auth/mpin/forgot/otp/send)
  // 2 = Verify OTP (/api/v1/auth/mpin/forgot/otp/verify)
  // 3 = Security Verification: PAN & DOB (/api/v1/auth/mpin/forgot/verify)
  // 4 = Set & Confirm New MPIN (/api/v1/auth/mpin/reset)
  int _stage = 1;
  int _mpinSubStage = 1; // 1 = Enter New MPIN, 2 = Confirm New MPIN

  // Controllers & Form State
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _panController = TextEditingController();
  DateTime? _selectedDob;
  String _dobDisplay = '';

  // API Tokens & References
  String _providerRef = '';
  String _resetToken = '';
  String _enteredOtp = '';

  // MPIN State
  String _newMpin = '';
  String _confirmMpin = '';

  // Error States
  String _phoneError = '';
  String _otpError = '';
  String _panError = '';
  String _dobError = '';
  String _mpinError = '';

  bool _isLoading = false;
  bool _isSuccess = false;

  // Resend OTP Timer
  Timer? _timer;
  int _timerSeconds = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _prefillUserData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _panController.dispose();
    SmsUserConsentService.stopListening();
    super.dispose();
  }

  void _prefillUserData() {
    final box = GetStorage();
    final String storedPhone =
        box.read('phone')?.toString() ??
        box.read('mobileNumber')?.toString() ??
        box.read('remembered_phone')?.toString() ??
        '';

    if (storedPhone.isNotEmpty) {
      String clean = storedPhone.replaceAll(RegExp(r'\D'), '');
      if (clean.length > 10) clean = clean.substring(clean.length - 10);
      _phoneController.text = clean;
    }

    final String storedPan =
        box.read('pan')?.toString() ?? box.read('panNumber')?.toString() ?? '';
    if (storedPan.isNotEmpty) {
      final clean = storedPan.trim().toUpperCase().replaceAll(
        RegExp(r'\s+'),
        '',
      );
      _panController.text = clean.length >= 4
          ? clean.substring(clean.length - 4)
          : clean;
    }

    // Do not auto-fill DOB - user must manually enter/select their Date of Birth
  }

  void _parseStoredDob(String val) {
    try {
      if (val.contains('-')) {
        // YYYY-MM-DD
        final parts = val.split('-');
        if (parts.length == 3) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) {
            _selectedDob = DateTime(y, m, d);
            _dobDisplay =
                '${d.toString().padLeft(2, '0')}/${m.toString().padLeft(2, '0')}/$y';
          }
        }
      } else if (val.contains('/')) {
        // DD/MM/YYYY
        final parts = val.split('/');
        if (parts.length == 3) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (d != null && m != null && y != null) {
            _selectedDob = DateTime(y, m, d);
            _dobDisplay = val;
          }
        }
      }
    } catch (_) {}
  }

  String _getDobIso() {
    if (_selectedDob != null) {
      final y = _selectedDob!.year.toString().padLeft(4, '0');
      final m = _selectedDob!.month.toString().padLeft(2, '0');
      final d = _selectedDob!.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }
    return '';
  }

  String _getPanLast4() {
    final clean = _panController.text.trim().toUpperCase().replaceAll(
      RegExp(r'\s+'),
      '',
    );
    if (clean.length >= 4) {
      return clean.substring(clean.length - 4);
    }
    return clean;
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _timerSeconds = 30;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timerSeconds > 1) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  Map<String, dynamic>? _parseResponse(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  String _extractErrorMessage(
    dynamic body, {
    String fallback = "Request failed",
  }) {
    final map = _parseResponse(body);
    if (map != null) {
      final msg =
          map['message'] ??
          map['error'] ??
          map['msg'] ??
          map['description'] ??
          map['desc'] ??
          map['response'] ??
          map['exception'] ??
          map['errorMessage'] ??
          (map['data'] is Map
              ? (map['data']['message'] ??
                    map['data']['error'] ??
                    map['data']['msg'])
              : null);
      if (msg != null && msg.toString().trim().isNotEmpty) {
        return msg.toString().trim();
      }
    } else if (body is String && body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map) {
          return _extractErrorMessage(decoded, fallback: fallback);
        }
      } catch (_) {
        return body.trim();
      }
    }
    return fallback;
  }

  // ==========================================
  // STEP 1: Send OTP to Mobile
  // POST /api/v1/auth/mpin/forgot/otp/send
  // ==========================================
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    setState(() {
      _phoneError = '';
    });

    if (phone.isEmpty) {
      setState(() => _phoneError = 'Please enter mobile number');
      return;
    }
    if (phone.length != 10 || !RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      setState(() => _phoneError = 'Enter a valid 10-digit mobile number');
      return;
    }

    setState(() {
      _isLoading = true;
      _otpError = '';
    });

    try {
      developer.log("[Forgot MPIN Step 1] Sending OTP for: $phone");
      final response = await ApiService.to.postRequest<dynamic>(
        '/api/v1/auth/mpin/forgot/otp/send',
        {"mobileNumber": phone},
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      final Map<String, dynamic>? body = _parseResponse(response.body);
      if (response.status.isOk && body != null) {
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (isSuccess && body['data'] != null) {
          final data = Map<String, dynamic>.from(body['data'] as Map);
          _providerRef = data['providerRef']?.toString() ?? '';

          final debugOtp = data['debugOtp'];
          if (debugOtp != null) {
            developer.log("[Forgot MPIN Step 1] debugOtp: $debugOtp");
          }

          final box = GetStorage();
          box.write('phone', phone);
          box.write('mobileNumber', phone);
          box.write('providerRef', _providerRef);

          AppSnackbar.success("OTP sent successfully to +91 $phone");
          setState(() {
            _stage = 2;
            _enteredOtp = '';
          });
          _startResendTimer();
          return;
        }
      }

      final errorMsg = _extractErrorMessage(
        response.body,
        fallback: "Failed to send OTP. Please try again.",
      );
      setState(() => _phoneError = errorMsg);
      AppSnackbar.error(errorMsg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      developer.log("[Forgot MPIN Step 1] Exception: $e");
      AppSnackbar.error("Network error: $e");
    }
  }

  // ==========================================
  // STEP 2: Verify OTP
  // POST /api/v1/auth/mpin/forgot/otp/verify
  // ==========================================
  Future<void> _verifyOtp() async {
    if (_enteredOtp.length != 6) {
      setState(() => _otpError = 'Please enter complete 6-digit OTP');
      return;
    }

    setState(() {
      _isLoading = true;
      _otpError = '';
    });

    final phone = _phoneController.text.trim();

    try {
      developer.log(
        "[Forgot MPIN Step 2] Verifying OTP: $phone, ref: $_providerRef",
      );

      final response = await ApiService.to.postRequest<dynamic>(
        '/api/v1/auth/mpin/forgot/otp/verify',
        {
          "mobileNumber": phone,
          "otp": _enteredOtp,
          "providerRef": _providerRef,
        },
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      final Map<String, dynamic>? body = _parseResponse(response.body);
      if (response.status.isOk && body != null) {
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (isSuccess && body['data'] != null) {
          final data = Map<String, dynamic>.from(body['data'] as Map);
          _resetToken = data['resetToken']?.toString() ?? '';

          AppSnackbar.success("OTP verified successfully");
          setState(() {
            _stage = 3;
          });
          return;
        }
      }

      final errorMsg = _extractErrorMessage(
        response.body,
        fallback: "Invalid OTP. Please try again.",
      );
      setState(() => _otpError = errorMsg);
      AppSnackbar.error(errorMsg);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpError = "Verification failed: $e";
      });
      AppSnackbar.error("Verification failed: $e");
    }
  }

  // ==========================================
  // STEP 3: Verify PAN & Date of Birth
  // POST /api/v1/auth/mpin/forgot/verify
  // ==========================================
  Future<void> _verifyIdentity() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _panError = '';
      _dobError = '';
    });

    bool valid = true;
    final pan = _panController.text.trim().toUpperCase();
    if (pan.isEmpty) {
      setState(() => _panError = 'Please enter last 4 characters of PAN');
      valid = false;
    } else if (pan.length != 4) {
      setState(
        () => _panError = 'Please enter exactly 4 characters of your PAN',
      );
      valid = false;
    }

    if (_selectedDob == null || _dobDisplay.isEmpty) {
      setState(() => _dobError = 'Please select Date of Birth');
      valid = false;
    } else if (isUnderAge(_selectedDob!)) {
      setState(() => _dobError = 'You must be at least 18 years old');
      valid = false;
    }

    if (!valid) return;

    setState(() {
      _isLoading = true;
    });

    final panLast4 = _getPanLast4();
    final dobIso = _getDobIso();

    try {
      developer.log(
        "[Forgot MPIN Step 3] Verifying Identity: dob=$dobIso, panLast4=$panLast4",
      );

      final response = await ApiService.to.postRequest<dynamic>(
        '/api/v1/auth/mpin/forgot/verify',
        {
          "resetToken": _resetToken,
          "dateOfBirth": dobIso,
          "panLast4": panLast4,
        },
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      final Map<String, dynamic>? body = _parseResponse(response.body);
      if (response.status.isOk && body != null) {
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (isSuccess && body['data'] != null) {
          final data = Map<String, dynamic>.from(body['data'] as Map);
          final String? updatedToken = data['resetToken']?.toString();
          if (updatedToken != null && updatedToken.isNotEmpty) {
            _resetToken = updatedToken;
          }

          // Save PAN and DOB to storage for convenience
          final box = GetStorage();
          box.write('pan', pan);
          box.write('dob', dobIso);

          AppSnackbar.success("Identity verified successfully");
          setState(() {
            _stage = 4;
            _mpinSubStage = 1;
            _newMpin = '';
            _confirmMpin = '';
            _mpinError = '';
          });
          return;
        }
      }

      final Map<String, dynamic>? bodyMap = _parseResponse(response.body);
      String? backendDobError;
      String? backendPanError;

      if (bodyMap != null) {
        final dynamic errorsObj =
            bodyMap['errors'] ?? bodyMap['error'] ?? bodyMap['data'];
        if (errorsObj is Map) {
          backendDobError = (errorsObj['dateOfBirth'] ?? errorsObj['dob'])
              ?.toString();
          backendPanError =
              (errorsObj['panLast4'] ??
                      errorsObj['pan'] ??
                      errorsObj['panNumber'])
                  ?.toString();
        }
      }

      final errorMsg = _extractErrorMessage(
        response.body,
        fallback: "PAN or Date of Birth verification failed.",
      );

      final lowerError = errorMsg.toLowerCase();
      final isDobError =
          backendDobError != null ||
          lowerError.contains('dob') ||
          lowerError.contains('birth') ||
          lowerError.contains('date');
      final isPanError = backendPanError != null || lowerError.contains('pan');

      setState(() {
        if (isDobError && !isPanError) {
          _dobError = backendDobError ?? errorMsg;
          _panError = '';
        } else if (isPanError && !isDobError) {
          _panError = backendPanError ?? errorMsg;
          _dobError = '';
        } else if (isDobError && isPanError) {
          _dobError = backendDobError ?? errorMsg;
          _panError = backendPanError ?? errorMsg;
        } else {
          // General verification failure without specific field indicator
          _panError = errorMsg;
        }
      });
      AppSnackbar.error(errorMsg);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      developer.log("[Forgot MPIN Step 3] Exception: $e");
      AppSnackbar.error("Verification error: $e");
    }
  }

  // ==========================================
  // STEP 4: Set & Confirm New MPIN
  // POST /api/v1/auth/mpin/reset
  // ==========================================
  void _onKeypadTap(String digit) {
    if (_isLoading || _isSuccess) return;

    setState(() {
      if (_mpinError.isNotEmpty) {
        _mpinError = '';
        if (_mpinSubStage == 1) {
          _newMpin = '';
        } else {
          _confirmMpin = '';
        }
      }

      if (_mpinSubStage == 1) {
        if (_newMpin.length < 4) {
          _newMpin += digit;
          if (_newMpin.length == 4) {
            Future.delayed(const Duration(milliseconds: 180), () {
              if (mounted) {
                setState(() {
                  _mpinSubStage = 2;
                  _confirmMpin = '';
                });
              }
            });
          }
        }
      } else {
        if (_confirmMpin.length < 4) {
          _confirmMpin += digit;
          if (_confirmMpin.length == 4) {
            _resetMpin();
          }
        }
      }
    });
  }

  void _onKeypadDelete() {
    if (_isLoading || _isSuccess) return;

    setState(() {
      _mpinError = '';
      if (_mpinSubStage == 1 && _newMpin.isNotEmpty) {
        _newMpin = _newMpin.substring(0, _newMpin.length - 1);
      } else if (_mpinSubStage == 2) {
        if (_confirmMpin.isNotEmpty) {
          _confirmMpin = _confirmMpin.substring(0, _confirmMpin.length - 1);
        } else {
          _mpinSubStage = 1;
          if (_newMpin.isNotEmpty) {
            _newMpin = _newMpin.substring(0, _newMpin.length - 1);
          }
        }
      }
    });
  }

  void _onKeypadClear() {
    if (_isLoading || _isSuccess) return;
    setState(() {
      _mpinError = '';
      if (_mpinSubStage == 1) {
        _newMpin = '';
      } else {
        _confirmMpin = '';
      }
    });
  }

  Future<void> _resetMpin() async {
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    if (_confirmMpin != _newMpin) {
      setState(() {
        _mpinError = 'MPINs do not match. Please re-enter.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _mpinError = '';
    });

    try {
      developer.log(
        "[Forgot MPIN Step 4] Resetting MPIN via /api/v1/auth/mpin/reset",
      );

      final response = await ApiService.to.postRequest<dynamic>(
        '/api/v1/auth/mpin/reset',
        {
          "resetToken": _resetToken,
          "newMpin": _newMpin,
          "confirmMpin": _confirmMpin,
        },
      );

      if (!mounted) return;

      final Map<String, dynamic>? body = _parseResponse(response.body);
      if (response.status.isOk && body != null) {
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        final data = body['data'];
        final bool isUpdated =
            data is Map && (data['status'] == 'UPDATED' || isSuccess);

        if (isSuccess || isUpdated) {
          final box = GetStorage();
          box.write('has_mpin', true);
          box.write('mpin_set', true);
          box.write('saved_mpin', _confirmMpin);
          box.write('remembered_mpin', _confirmMpin);

          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });

          final successMsg = _extractErrorMessage(
            response.body,
            fallback: "MPIN reset successfully!",
          );
          AppSnackbar.success(successMsg);

          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              if (widget.onSuccess != null) {
                widget.onSuccess!();
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(true);
                }
                return;
              }
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop(true);
              } else {
                Get.back(result: true);
              }
            }
          });
          return;
        }
      }

      final errorMsg = _extractErrorMessage(
        response.body,
        fallback: "Failed to reset MPIN. Please try again.",
      );
      setState(() {
        _isLoading = false;
        _mpinError = errorMsg;
      });
      AppSnackbar.error(errorMsg);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _mpinError = "Error resetting MPIN: $e";
      });
      AppSnackbar.error("Error: $e");
    }
  }

  Future<void> _pickDob() async {
    FocusScope.of(context).unfocus();
    final maxAllowed = getMaxAllowedDob();
    final initial = (_selectedDob != null && !_selectedDob!.isAfter(maxAllowed))
        ? _selectedDob
        : maxAllowed;
    final picked = await showDobPicker(
      context,
      initialDate: initial,
    );
    if (picked != null) {
      if (isUnderAge(picked)) {
        setState(() {
          _selectedDob = null;
          _dobDisplay = '';
          _dobError = 'You must be at least 18 years old';
        });
        AppSnackbar.error('You must be at least 18 years old');
      } else {
        setState(() {
          _selectedDob = picked;
          _dobDisplay =
              '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
          _dobError = '';
        });
      }
    }
  }

  void _handleBackNavigation() {
    if (_isLoading) return;
    if (_isSuccess) {
      if (widget.onSuccess != null) {
        widget.onSuccess!();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        }
        return;
      }
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        Get.back(result: true);
      }
      return;
    }

    if (_stage == 4) {
      if (_mpinSubStage == 2) {
        setState(() {
          _mpinSubStage = 1;
          _confirmMpin = '';
          _mpinError = '';
        });
      } else {
        setState(() {
          _stage = 3;
        });
      }
    } else if (_stage == 3) {
      setState(() => _stage = 2);
    } else if (_stage == 2) {
      setState(() => _stage = 1);
    } else {
      if (widget.onCancel != null) {
        widget.onCancel!();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(false);
        }
        return;
      }
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(false);
      } else {
        Get.back(result: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stage == 1 || _isSuccess,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          if (_isSuccess) {
            widget.onSuccess?.call();
          } else {
            widget.onCancel?.call();
          }
        } else {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: appBarGradient),
          ),
          elevation: 0,
          leadingWidth: context.responsive(60),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Colors.black,
            ),
            onPressed: _handleBackNavigation,
          ),
          title: const Text(
            "Forgot MPIN",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
          centerTitle: true,
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            bottom: true,
            maintainBottomViewPadding: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mediaQuery = MediaQuery.of(context);
                final double bottomInset = mediaQuery.padding.bottom;
                final double bottomSafePadding = bottomInset > 0
                    ? (bottomInset + 12.0)
                    : 24.0;
                final bool isCompact = constraints.maxHeight < 680;
                final double horizontalPadding = (constraints.maxWidth * 0.07)
                    .clamp(16.0, 32.0);

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          isCompact ? 10.0 : 16.0,
                          horizontalPadding,
                          bottomSafePadding,
                        ),
                        child: Column(
                          children: [
                            if (!_isSuccess) ...[
                              _buildStepIndicator(isCompact),
                              SizedBox(height: isCompact ? 16 : 24),
                            ],
                            Expanded(
                              child: _buildCurrentStageView(
                                constraints,
                                isCompact,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Modern 4-step horizontal progress indicator
  Widget _buildStepIndicator(bool isCompact) {
    const steps = [
      {"num": "1", "label": "Mobile"},
      {"num": "2", "label": "OTP"},
      {"num": "3", "label": "Identity"},
      {"num": "4", "label": "MPIN"},
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIndex = (index - 1) ~/ 2;
          final isCompleted = _stage > stepIndex + 1;
          return Expanded(
            child: Container(
              height: 2.5,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isCompleted ? _successGreen : _borderGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final stepNum = stepIndex + 1;
        final isCompleted = _stage > stepNum;
        final isCurrent = _stage == stepNum;

        return Container(
          width: isCompact ? 24 : 28,
          height: isCompact ? 24 : 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? _successGreen
                : isCurrent
                ? _primaryRed
                : const Color(0xFFF3F4F6),
            border: Border.all(
              color: isCurrent
                  ? _primaryRed
                  : isCompleted
                  ? _successGreen
                  : _borderGrey,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                : Text(
                    steps[stepIndex]["num"]!,
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 12,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? Colors.white : _secondaryText,
                    ),
                  ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStageView(BoxConstraints constraints, bool isCompact) {
    if (_isSuccess) {
      return _buildSuccessView(isCompact);
    }

    switch (_stage) {
      case 1:
        return _buildStage1Mobile(isCompact);
      case 2:
        return _buildStage2Otp(isCompact);
      case 3:
        return _buildStage3Identity(isCompact);
      case 4:
      default:
        return _buildStage4Mpin(constraints, isCompact);
    }
  }

  // ==========================================
  // VIEW: Step 1 - Enter Mobile & Send OTP
  // ==========================================
  Widget _buildStage1Mobile(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            decoration: BoxDecoration(
              color: _primaryRed.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_iphone_rounded,
              color: _primaryRed,
              size: isCompact ? 34 : 40,
            ),
          ),
        ),
        SizedBox(height: isCompact ? 12 : 18),
        const Center(
          child: Text(
            "Enter Registered Mobile",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _textColor,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Center(
          child: Text(
            "Enter your 10-digit mobile number linked to Transwallet to receive a verification code",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _secondaryText, height: 1.4),
          ),
        ),
        SizedBox(height: isCompact ? 20 : 28),

        const Text(
          "Mobile Number",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _phoneError.isNotEmpty ? Colors.red : _borderGrey,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Text(
                "+91",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
              const SizedBox(width: 8),
              Container(height: 20, width: 1, color: _borderGrey),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    hintText: "Enter 10-digit mobile number",
                    hintStyle: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    counterText: "",
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_phoneError.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _phoneError,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],

        const Spacer(),
        SizedBox(height: isCompact ? 16 : 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    "Send OTP",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VIEW: Step 2 - Verify OTP
  // ==========================================
  Widget _buildStage2Otp(bool isCompact) {
    final phone = _phoneController.text.trim();
    final maskedPhone = phone.length == 10
        ? "${phone.substring(0, 2)}******${phone.substring(8)}"
        : phone;

    return Column(
      children: [
        Center(
          child: Container(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            decoration: BoxDecoration(
              color: _primaryRed.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              color: _primaryRed,
              size: isCompact ? 34 : 40,
            ),
          ),
        ),
        SizedBox(height: isCompact ? 14 : 20),
        const Text(
          "Enter Verification Code",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _textColor,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "We sent a 6-digit OTP code to +91 $maskedPhone",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: _secondaryText,
            height: 1.4,
          ),
        ),
        SizedBox(height: isCompact ? 20 : 32),

        // 6-digit OTP Input
        OtpInputField(
          length: 6,
          onChanged: (val) {
            _enteredOtp = val;
            if (_otpError.isNotEmpty) {
              setState(() => _otpError = '');
            }
          },
          onCompleted: (val) {
            _enteredOtp = val;
            _verifyOtp();
          },
        ),

        if (_otpError.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _otpError,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        SizedBox(height: isCompact ? 16 : 24),

        // Resend Timer Row
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              "Didn't receive code? ",
              style: TextStyle(fontSize: 13, color: _secondaryText),
            ),
            if (_canResend)
              GestureDetector(
                onTap: _sendOtp,
                child: const Text(
                  "Resend OTP",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _primaryRed,
                  ),
                ),
              )
            else
              Text(
                "Resend in ${_timerSeconds}s",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _primaryRed,
                ),
              ),
          ],
        ),

        const Spacer(),
        SizedBox(height: isCompact ? 16 : 24),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    "Verify OTP",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStage3Identity(bool isCompact) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              decoration: BoxDecoration(
                color: _primaryRed.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_user_rounded,
                color: _primaryRed,
                size: isCompact ? 34 : 40,
              ),
            ),
          ),
          SizedBox(height: isCompact ? 12 : 18),
          const Center(
            child: Text(
              "Security Verification",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _textColor,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              "Enter your PAN and Date of Birth details linked to your account to authorize MPIN reset",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: _secondaryText,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: isCompact ? 20 : 28),

          // PAN Number field
          const Text(
            "PAN Number (Last 4 characters)",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _panError.isNotEmpty ? Colors.red : _borderGrey,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: _panController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 4,
              autofocus: false,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                LengthLimitingTextInputFormatter(4),
              ],
              onChanged: (val) {
                if (_panError.isNotEmpty) {
                  setState(() => _panError = '');
                }
              },
              decoration: const InputDecoration(
                hintText: "e.g. 234F",
                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                border: InputBorder.none,
                counterText: "",
              ),
            ),
          ),
          if (_panError.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _panError,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],

          SizedBox(height: isCompact ? 14 : 18),

          // Date of Birth field
          Row(
            children: const [
              Text(
                "Date of Birth (as per PAN)",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                ),
              ),
               
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDob,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _dobError.isNotEmpty ? Colors.red : _borderGrey,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dobDisplay.isNotEmpty
                          ? _dobDisplay
                          : "Select Date of Birth  ",
                      style: TextStyle(
                        fontSize: 14,
                        color: _dobDisplay.isNotEmpty
                            ? _textColor
                            : const Color(0xFF9CA3AF),
                        fontWeight: _dobDisplay.isNotEmpty
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: _secondaryText,
                  ),
                ],
              ),
            ),
          ),
          if (_dobError.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _dobError,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],

          const Spacer(),
          SizedBox(height: isCompact ? 16 : 24),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyIdentity,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      "Verify Identity",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW: Step 4 - Enter New MPIN & Confirm New MPIN
  // ==========================================
  Widget _buildStage4Mpin(BoxConstraints constraints, bool isCompact) {
    final bool isConfirm = _mpinSubStage == 2;
    final String activePin = isConfirm ? _confirmMpin : _newMpin;
    final double keySize = (constraints.maxWidth * 0.18).clamp(52.0, 68.0);
    final double keypadSpacing = isCompact ? 8.0 : 12.0;

    return Column(
      children: [
        Center(
          child: Container(
            padding: EdgeInsets.all(isCompact ? 12 : 16),
            decoration: BoxDecoration(
              color: _primaryRed.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_reset_rounded,
              color: _primaryRed,
              size: isCompact ? 34 : 40,
            ),
          ),
        ),
        SizedBox(height: isCompact ? 14 : 20),
        Text(
          isConfirm ? "Confirm New MPIN" : "Enter New MPIN",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _textColor,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isConfirm
              ? "Re-enter your 4-digit MPIN to confirm"
              : "Set a new 4-digit security PIN for your wallet",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            color: _secondaryText,
            height: 1.4,
          ),
        ),
        SizedBox(height: isCompact ? 16 : 24),

        // 4 PIN Circles
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < activePin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? (_mpinError.isNotEmpty ? Colors.red : _primaryRed)
                    : const Color(0xFFECECEC),
                border: Border.all(
                  color: _mpinError.isNotEmpty && filled
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
            );
          }),
        ),

        if (_mpinError.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _mpinError,
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
              valueColor: AlwaysStoppedAnimation<Color>(_primaryRed),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Updating your new MPIN...",
            style: TextStyle(
              color: _secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 16),
        ] else ...[
          _buildNumericKeypad(keySize, keypadSpacing),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // ==========================================
  // VIEW: Success State
  // ==========================================
  Widget _buildSuccessView(bool isCompact) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          padding: EdgeInsets.all(isCompact ? 16 : 22),
          decoration: BoxDecoration(
            color: _successGreen.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: _successGreen,
            size: isCompact ? 48 : 56,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "MPIN Reset Successfully!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _successGreen,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Your new security PIN is ready to use.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: _secondaryText, height: 1.45),
        ),
        const SizedBox(height: 24),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              if (widget.onSuccess != null) {
                widget.onSuccess!();
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(true);
                }
                return;
              }
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop(true);
              } else {
                Get.back(result: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _successGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: const Text(
              "Done",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Keypad
  Widget _buildNumericKeypad(double keySize, double spacing) {
    return Center(
      child: CustomNumericKeypad(
        onDigitTap: _onKeypadTap,
        onDeleteTap: _onKeypadDelete,
        onClear: _onKeypadClear,
      ),
    );
  }
}
