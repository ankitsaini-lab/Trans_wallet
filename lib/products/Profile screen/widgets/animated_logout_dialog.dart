import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/widgets/constsize.dart';

class AnimatedLogoutDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const AnimatedLogoutDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<AnimatedLogoutDialog> createState() => _AnimatedLogoutDialogState();
}

class _AnimatedLogoutDialogState extends State<AnimatedLogoutDialog>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;

  @override
  void initState() {
    super.initState();

    // Entry spring / bounce scale and fade animation
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeIn,
    );

    // Continuous ripple / pulse animation
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _rippleAnimation = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    );

    // Start animations
    _entryController.forward();
    _rippleController.repeat();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryRed = Color(0xFFED292A);
    const Color textColor = Color(0xFF111111);
    const Color secondaryText = Color(0xFF4B5563);
    const Color borderColor = Color(0xFFECECEC);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(horizontal: context.responsive(32)),
              child: Container(
                padding: EdgeInsets.all(context.responsive(28)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.responsive(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Concentric Animated Ripple Icon
                    AnimatedBuilder(
                      animation: _rippleAnimation,
                      builder: (context, child) {
                        final double baseRadius = context.responsive(74);
                        final double extraRadius = context.responsive(40) * _rippleAnimation.value;
                        final double innerExtraRadius = context.responsive(18) * _rippleAnimation.value;

                        return SizedBox(
                          height: context.responsive(120),
                          width: context.responsive(120),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ripple Outer
                              Container(
                                width: baseRadius + extraRadius,
                                height: baseRadius + extraRadius,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primaryRed.withOpacity(
                                    (1.0 - _rippleAnimation.value) * 0.20,
                                  ),
                                ),
                              ),
                              // Ripple Inner
                              Container(
                                width: baseRadius + innerExtraRadius,
                                height: baseRadius + innerExtraRadius,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primaryRed.withOpacity(
                                    (1.0 - _rippleAnimation.value) * 0.40,
                                  ),
                                ),
                              ),
                              // Centered Icon Button Container
                              Container(
                                height: baseRadius,
                                width: baseRadius,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFED292A),
                                      Color(0xFFC61A1A),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryRed.withOpacity(0.35),
                                      blurRadius: 15,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.logout_rounded,
                                  color: Colors.white,
                                  size: context.responsive(32),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: context.responsive(16)),

                    Text(
                      "Secure Sign Out",
                      style: TextStyle(
                        color: textColor,
                        fontSize: context.responsive(20),
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: context.responsive(10)),

                    Text(
                      "Are you sure you want to sign out of your account? You will need your credentials to sign back in.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: secondaryText,
                        fontSize: context.responsive(13),
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: context.responsive(20)),

                    Row(
                      children: [
                        // Cancel Button
                        Expanded(
                          child: _AnimatedButton(
                            text: "Cancel",
                            onTap: widget.onCancel,
                            backgroundColor: const Color(0xFFF3F4F6),
                            textColor: textColor,
                            isSecondary: true,
                          ),
                        ),
                        SizedBox(width: context.responsive(14)),

                        // Confirm / Sign Out Button
                        Expanded(
                          child: _AnimatedButton(
                            text: "Sign Out",
                            onTap: widget.onConfirm,
                            backgroundColor: primaryRed,
                            textColor: Colors.white,
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

class _AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final bool isSecondary;

  const _AnimatedButton({
    required this.text,
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
    this.isSecondary = false,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: context.responsive(48),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(context.responsive(16)),
            border: widget.isSecondary
                ? Border.all(color: const Color(0xFFECECEC), width: 1)
                : null,
            boxShadow: widget.isSecondary
                ? null
                : [
                    BoxShadow(
                      color: widget.backgroundColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              color: widget.textColor,
              fontWeight: FontWeight.bold,
              fontSize: context.responsive(14),
            ),
          ),
        ),
      ),
    );
  }
}
