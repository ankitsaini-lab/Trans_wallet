import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? color;
  final Color? textColor;
  final Color? btncolor;
  final double borderRadius;
  final double height;
  final double? width;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double textsize;

  const CustomButton({
    super.key,
    required this.text,
    required this.btncolor,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.borderRadius = 30,
    this.height = 54,
    this.width,
    this.prefixIcon,
    this.suffixIcon,
    this.textsize = 16,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  final isPressed = false.obs;

  @override
  Widget build(BuildContext context) {
    Color buttonColor =
        widget.color ?? widget.btncolor ?? const Color(0xFF111111);
    final isGrey =
        buttonColor == Colors.grey.shade300 ||
        buttonColor == Colors.grey ||
        buttonColor == Colors.grey.shade400 ||
        buttonColor == Colors.grey.shade200;

    if (!isGrey) {
      buttonColor = const Color(0xFF111111);
    }

    final Color textColorVal = isGrey
        ? (widget.textColor ?? Colors.grey.shade600)
        : Colors.white;

    return Obx(
      () => GestureDetector(
        onTapDown: (_) => isPressed.value = true,
        onTapUp: (_) => isPressed.value = false,
        onTapCancel: () => isPressed.value = false,
        onTap: widget.isLoading ? null : widget.onPressed,

        child: AnimatedScale(
          scale: isPressed.value ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),

          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: buttonColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: isGrey
                      ? Colors.transparent
                      : Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),

            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.prefixIcon != null) ...[
                          widget.prefixIcon!,
                          const SizedBox(width: 6),
                        ],

                        Text(
                          widget.text,
                          style: TextStyle(
                            color: textColorVal,
                            fontSize: widget.textsize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        if (widget.suffixIcon != null) ...[
                          const SizedBox(width: 6),
                          widget.suffixIcon!,
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
