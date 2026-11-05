import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';

/// Production-ready OTP input widget used across Transwallet (login + KYC).
///
/// Architecture: a single real-sized TextField overlaid by 6 decorative boxes.
///
/// ## Why this architecture is required for OS autofill
///
/// Both iOS QuickType ("From Messages: 123456") and Android SMS suggestion bar
/// require two things to work:
///
/// 1. The TextField must be inside an [AutofillGroup]. Flutter's text input
///    connection only attaches autofill configuration to the OS when an
///    AutofillGroup ancestor is present. Without it, [autofillHints] is stored
///    in metadata but never activated by the OS autofill service.
///
/// 2. The TextField must have a non-zero rendered Rect in the widget tree.
///    The OS autofill service queries the accessibility/semantics tree to
///    locate input fields. A SizedBox(width:1, height:1) reports a ~zero-area
///    rect and is silently skipped by both iOS and Android autofill engines.
///    This was the primary failure in the previous implementation.
///
/// ## Solution
///
/// The TextField is rendered at full width with height 0 and `clipBehavior:
/// Clip.none`, positioned behind the decorative boxes via a Stack. It is
/// invisible (transparent text, no borders) but occupies real layout space,
/// so the OS autofill engine finds it. Pointer events pass through
/// via the surrounding GestureDetector.
///
/// ## Platform behaviour
///
/// - **iOS**: When a matching SMS arrives, iOS shows "From Messages: 123456"
///   in the QuickType suggestion bar above the keyboard. Tapping it fills
///   the field, triggers onChanged, and auto-submits via onCompleted.
///
/// - **Android**: The OS shows the OTP in the suggestion strip above the
///   keyboard after an SMS arrives (User Consent flow — user taps the
///   suggestion). No READ_SMS permission needed.
class OtpInputField extends StatefulWidget {
  /// Number of OTP digits (default 6)
  final int length;

  /// Called each time the value changes
  final ValueChanged<String>? onChanged;

  /// Called when all [length] digits have been entered
  final ValueChanged<String>? onCompleted;

  /// Optional external controller; if null, an internal one is created
  final TextEditingController? controller;

  /// Optional external focus node
  final FocusNode? focusNode;

  /// Height of each visual box (default 48)
  final double boxHeight;

  /// Box border color when idle
  final Color idleColor;

  /// Box border color for the active (next-to-fill) cell
  final Color focusColor;

  /// Box border + background tint when filled
  final Color filledColor;

  const OtpInputField({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.controller,
    this.focusNode,
    this.boxHeight = 48,
    this.idleColor = const Color(0xFFE5E7EB),
    this.focusColor = primaryRed,
    this.filledColor = primaryRed,
  });

  @override
  State<OtpInputField> createState() => OtpInputFieldState();
}

class OtpInputFieldState extends State<OtpInputField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _ownsController = false;
  bool _ownsFocusNode = false;
  bool _isFocused = false;

  String _lastNotifiedText = '';

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController();
      _ownsController = true;
    } else {
      _controller = widget.controller!;
    }
    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    } else {
      _focusNode = widget.focusNode!;
    }
    _lastNotifiedText = _controller.text;
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onControllerChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
  }

  void _onControllerChange() {
    final text = _controller.text;
    if (text.length > widget.length) {
      final clamped = text.substring(0, widget.length);
      _controller.value = TextEditingValue(
        text: clamped,
        selection: TextSelection.collapsed(offset: clamped.length),
      );
      return;
    }

    if (text != _lastNotifiedText) {
      _lastNotifiedText = text;
      if (mounted) setState(() {});
      widget.onChanged?.call(text);
      if (text.length == widget.length) {
        _focusNode.unfocus();
        widget.onCompleted?.call(text);
      }
    }
  }

  @override
  void didUpdateWidget(covariant OtpInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_onControllerChange);
      if (_ownsController) _controller.dispose();
      if (widget.controller == null) {
        _controller = TextEditingController();
        _ownsController = true;
      } else {
        _controller = widget.controller!;
        _ownsController = false;
      }
      _lastNotifiedText = _controller.text;
      _controller.addListener(_onControllerChange);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (_ownsFocusNode) _focusNode.dispose();
      if (widget.focusNode == null) {
        _focusNode = FocusNode();
        _ownsFocusNode = true;
      } else {
        _focusNode = widget.focusNode!;
        _ownsFocusNode = false;
      }
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _focusNode.removeListener(_onFocusChange);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  /// Sets OTP digits programmatically, automatically updating all boxes and
  /// triggering completion callback.
  void setOtp(String code) {
    final clamped = code.length > widget.length
        ? code.substring(0, widget.length)
        : code;
    _controller.value = TextEditingValue(
      text: clamped,
      selection: TextSelection.collapsed(offset: clamped.length),
    );
  }

  /// Clears all digits. Can be called externally via `GlobalKey<OtpInputFieldState>`.
  void clear() {
    _controller.clear();
  }

  String get value => _controller.text;

  void _onChanged(String val) {
    // Managed via _onControllerChange for both typing and programmatic autofill
    _onControllerChange();
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      // AutofillGroup is required — without it Flutter's TextInputConnection
      // never activates the OS autofill service regardless of autofillHints.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _focusNode.requestFocus(),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // ── Real-sized invisible TextField ──────────────────────────────
            //
            // Positioned at the bottom of the stack so the decorative boxes
            // render on top. Height matches boxHeight with overflow allowed
            // (clipBehavior: Clip.none on the parent Stack), which means the
            // field occupies real non-zero WIDTH in the layout (full row width)
            // while being visually hidden. The OS autofill engine reads the
            // render object bounds, so this satisfies its non-zero-rect
            // requirement on both iOS and Android.
            //
            // Do NOT use SizedBox(width:1, height:1) — that reports an
            // essentially zero-area rect and is silently skipped by the OS.
            SizedBox(
              width: double.infinity,
              height: widget.boxHeight,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                maxLength: widget.length,
                // ── The two required autofill properties ──
                autofillHints: const [AutofillHints.oneTimeCode],
                textInputAction: TextInputAction.done,
                // ── Make the field invisible ──
                enableInteractiveSelection: false,
                showCursor: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  // Transparent text so digits don't bleed through the boxes
                  color: Colors.transparent,
                  fontSize: 1,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  // No fill — keep it fully invisible
                  filled: false,
                ),
                onChanged: _onChanged,
              ),
            ),

            // ── 6 purely decorative visual boxes ────────────────────────────
            //
            // These are Pointer-transparent (IgnorePointer) so all taps pass
            // through to the GestureDetector which focuses the real TextField.
            IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(widget.length, (i) {
                  final text = _controller.text;
                  final isCurrent = _isFocused && i == text.length;
                  final isFilled = i < text.length;

                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: widget.boxHeight,
                      decoration: BoxDecoration(
                        color: isFilled
                            ? widget.filledColor.withValues(alpha: 0.06)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent
                              ? widget.focusColor
                              : isFilled
                              ? widget.filledColor
                              : widget.idleColor,
                          width: isCurrent || isFilled ? 2.0 : 1.5,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: widget.focusColor.withValues(
                                    alpha: 0.20,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 120),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: isFilled
                              ? Text(
                                  text[i],
                                  key: ValueKey('otp-$i-${text[i]}'),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111111),
                                  ),
                                )
                              : isCurrent
                              ? _BlinkingCursor(color: widget.focusColor)
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Blinking cursor shown in the active (next-to-fill) cell ──────────────────

class _BlinkingCursor extends StatefulWidget {
  final Color color;
  const _BlinkingCursor({required this.color});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 2,
        height: 22,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
