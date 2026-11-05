import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Profile%20screen/change_pin/forgot_pin_view.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/widgets/constsize.dart';

class ChangePinView extends StatefulWidget {
  const ChangePinView({super.key});

  @override
  State<ChangePinView> createState() => _ChangePinViewState();
}

class _ChangePinViewState extends State<ChangePinView> {
  static const Color _primaryRed = Color(0xFFED292A);
  static const Color _textColor = Color(0xFF111111);
  static const Color _secondaryText = Color(0xFF6B7280);
  static const Color _successGreen = Color(0xFF22C55E);

  // Steps:
  // 1 = Enter Current PIN (Always verified first)
  // 2 = Enter New PIN (Unlocked only after current PIN verification succeeds)
  // 3 = Confirm New PIN
  int _step = 1;
  String _currentPin = '';
  String _verifiedCurrentPin = '';
  String _newPin = '';
  String _confirmPin = '';

  bool _isVerifying = false;
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _step = 1; // Always start by asking for existing PIN
  }

  String get _activePin {
    switch (_step) {
      case 1:
        return _currentPin;
      case 2:
        return _newPin;
      case 3:
      default:
        return _confirmPin;
    }
  }

  void _onKeyTap(String digit) {
    if (_activePin.length >= 4 || _isSuccess || _isLoading || _isVerifying) {
      return;
    }

    setState(() {
      _hasError = false;
      _errorMessage = '';
      if (_step == 1) {
        _currentPin += digit;
        if (_currentPin.length == 4) {
          _verifyCurrentPin();
        }
      } else if (_step == 2) {
        _newPin += digit;
        if (_newPin.length == 4) {
          _validateNewPin();
        }
      } else if (_step == 3) {
        _confirmPin += digit;
        if (_confirmPin.length == 4) {
          _validateAndSubmitNewPin();
        }
      }
    });
  }

  void _onDelete() {
    if (_isSuccess || _isLoading || _isVerifying) return;

    setState(() {
      _hasError = false;
      _errorMessage = '';
      if (_step == 1 && _currentPin.isNotEmpty) {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      } else if (_step == 2 && _newPin.isNotEmpty) {
        _newPin = _newPin.substring(0, _newPin.length - 1);
      } else if (_step == 3 && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      }
    });
  }

  Future<void> _verifyCurrentPin() async {
    setState(() {
      _isVerifying = true;
      _hasError = false;
    });

    bool isCorrect = false;
    String errorMsg = 'Incorrect current PIN. Please try again.';

    if (Get.isRegistered<ApiService>()) {
      final res = await ApiService.to.verifyMpin(_currentPin);
      isCorrect = res.isSuccess;
      if (!isCorrect && res.message.isNotEmpty) {
        errorMsg = res.message;
      }
    } else {
      final box = GetStorage();
      final String? savedMpin =
          box.read<String>('saved_mpin') ??
          box.read('mpin')?.toString() ??
          box.read('tx_pin')?.toString();
      isCorrect = (savedMpin != null && savedMpin == _currentPin);
    }

    if (!mounted) return;

    if (isCorrect) {
      setState(() {
        _isVerifying = false;
        _verifiedCurrentPin = _currentPin;
        _step = 2;
      });
    } else {
      setState(() {
        _isVerifying = false;
        _hasError = true;
        _errorMessage = errorMsg;
        _currentPin = '';
      });
    }
  }

  void _validateNewPin() {
    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;

      if (_verifiedCurrentPin.isNotEmpty && _newPin == _verifiedCurrentPin) {
        setState(() {
          _hasError = true;
          _errorMessage = 'New PIN cannot be the same as your current PIN.';
          _newPin = '';
        });
        return;
      }

      setState(() {
        _step = 3;
      });
    });
  }

  Future<void> _validateAndSubmitNewPin() async {
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    if (_confirmPin != _newPin) {
      setState(() {
        _hasError = true;
        _errorMessage = 'PINs do not match. Please try again.';
        _confirmPin = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final box = GetStorage();
      final token =
          box.read<String>('accessToken') ??
          box.read<String>('auth_token') ??
          box.read<String>('token') ??
          box.read<String>('registrationToken') ??
          (Get.isRegistered<AuthService>() ? AuthService.to.token : null);

      final headers = (token != null && token.trim().isNotEmpty)
          ? {'Authorization': 'Bearer ${token.trim()}'}
          : null;

      final requestBody = {"mpin": _confirmPin};

      developer.log(
        "[Change PIN] Calling /api/v1/auth/mpin/set with body:\n${const JsonEncoder.withIndent('  ').convert(requestBody)}",
      );

      final response = await ApiService.to.postRequest<Map<String, dynamic>>(
        '/api/v1/auth/mpin/set',
        requestBody,
        headers: headers,
      );

      developer.log(
        "[Change PIN] Status: ${response.statusCode}, Body: ${response.body}",
      );

      if (!mounted) return;

      if (response.status.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';

        if (isSuccess) {
          box.write('has_mpin', true);
          box.write('mpin_set', true);
          box.write('saved_mpin', _confirmPin);
          box.write('remembered_mpin', _confirmPin);

          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });

          final message =
              body['message']?.toString() ?? "PIN changed successfully";
          AppSnackbar.success(message);

          // Return cleanly to Profile screen after brief success feedback
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Get.back();
              }
            }
          });
        } else {
          final errorMsg =
              body['message']?.toString() ?? "Failed to update PIN";
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = errorMsg;
            _confirmPin = '';
          });
          AppSnackbar.error(errorMsg);
        }
      } else {
        String errorMsg = "Failed to update PIN";
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
          _confirmPin = '';
        });
        AppSnackbar.error(errorMsg);
      }
    } catch (e) {
      if (!mounted) return;
      developer.log("[Change PIN] Exception: $e");
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = "Something went wrong: $e";
        _confirmPin = '';
      });
      AppSnackbar.error("Something went wrong: $e");
    }
  }

  String get _title {
    if (_isSuccess) return "PIN Changed Successfully!";
    switch (_step) {
      case 1:
        return "Enter Current PIN";
      case 2:
        return "Enter New PIN";
      case 3:
      default:
        return "Confirm New PIN";
    }
  }

  String get _subtitle {
    if (_isSuccess) {
      return "Your 4-digit security PIN has been updated.\nReturning to profile...";
    }
    switch (_step) {
      case 1:
        return "Enter your existing 4-digit PIN to verify your identity";
      case 2:
        return "Set a new 4-digit PIN for securing your transactions";
      case 3:
      default:
        return "Re-enter your new 4-digit PIN to confirm";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        elevation: 0,
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        title: const Text(
          "Change Pin",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
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
            final double keySize = (constraints.maxWidth * 0.18).clamp(
              52.0,
              68.0,
            );
            final double keypadSpacing = isCompact ? 8.0 : 12.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      isCompact ? 8.0 : 16.0,
                      horizontalPadding,
                      bottomSafePadding,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: isCompact ? 8 : 16),

                        // Header Icon
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: _isSuccess
                              ? Container(
                                  key: const ValueKey('success_icon'),
                                  padding: EdgeInsets.all(isCompact ? 14 : 18),
                                  decoration: BoxDecoration(
                                    color: _successGreen.withValues(
                                      alpha: 0.12,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: _successGreen,
                                    size: isCompact ? 38 : 46,
                                  ),
                                )
                              : Container(
                                  key: ValueKey('lock_icon_$_step'),
                                  padding: EdgeInsets.all(isCompact ? 14 : 18),
                                  decoration: BoxDecoration(
                                    color: _primaryRed.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.lock_rounded,
                                    color: _primaryRed,
                                    size: isCompact ? 32 : 38,
                                  ),
                                ),
                        ),

                        SizedBox(height: isCompact ? 12 : 20),

                        // Title Text
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            _title,
                            key: ValueKey('title_${_isSuccess ? 's' : _step}'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isCompact ? 20 : 22,
                              fontWeight: FontWeight.w800,
                              color: _isSuccess ? _successGreen : _textColor,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Subtitle Text
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            _subtitle,
                            key: ValueKey(
                              'subtitle_${_isSuccess ? 's' : _step}',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _secondaryText,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ),

                        SizedBox(height: isCompact ? 16 : 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (i) {
                            final filled = i < _activePin.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isSuccess
                                    ? _successGreen
                                    : _hasError
                                    ? Colors.red
                                    : filled
                                    ? _primaryRed
                                    : const Color(0xFFECECEC),
                                border: Border.all(
                                  color: _hasError
                                      ? Colors.red.withValues(alpha: 0.3)
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

                        // Step 1: Forgot PIN link
                        if (_step == 1 && !_isSuccess && !_isLoading) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () =>
                                Get.to(() => const ForgotPinView()),
                            child: const Text(
                              "Forgot Current PIN?",
                              style: TextStyle(
                                color: _primaryRed,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Loading / Verifying or Keypad
                        if (_isLoading || _isVerifying) ...[
                          const SizedBox(
                            height: 28,
                            width: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _primaryRed,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _isVerifying
                                ? 'Verifying current PIN...'
                                : 'Updating your PIN...',
                            style: const TextStyle(
                              color: _secondaryText,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 16),
                        ] else if (!_isSuccess) ...[
                          _buildKeypad(keySize, keypadSpacing),
                          const SizedBox(height: 16),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  Get.back();
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
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildKeypad(double keySize, double spacing) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _keyRow(['1', '2', '3'], keySize),
        SizedBox(height: spacing),
        _keyRow(['4', '5', '6'], keySize),
        SizedBox(height: spacing),
        _keyRow(['7', '8', '9'], keySize),
        SizedBox(height: spacing),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(width: keySize, height: keySize),
            _KeyButton(label: '0', size: keySize, onTap: () => _onKeyTap('0')),
            _DeleteButton(size: keySize, onTap: _onDelete),
          ],
        ),
      ],
    );
  }

  Widget _keyRow(List<String> digits, double keySize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map(
            (d) =>
                _KeyButton(label: d, size: keySize, onTap: () => _onKeyTap(d)),
          )
          .toList(),
    );
  }
}

class _KeyButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double size;

  const _KeyButton({required this.label, required this.onTap, this.size = 66});

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final double fontSize = (widget.size * 0.35).clamp(19.0, 24.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 70),
        child: Container(
          height: widget.size,
          width: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _pressed ? const Color(0xFFECECEC) : const Color(0xFFF7F7F8),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111111),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size;

  const _DeleteButton({required this.onTap, this.size = 66});

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final double iconSize = (widget.size * 0.35).clamp(20.0, 24.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 70),
        child: SizedBox(
          height: widget.size,
          width: widget.size,
          child: Icon(
            Icons.backspace_outlined,
            color: const Color(0xFF6B7280),
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
