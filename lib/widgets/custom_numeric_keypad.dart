import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transwallet/widgets/constsize.dart';

class CustomNumericKeypad extends StatelessWidget {
  final void Function(String digit) onDigitTap;
  final VoidCallback onDeleteTap;
  final VoidCallback? onClear;
  final String? leftActionText;
  final VoidCallback? onLeftActionTap;
  final double? buttonSize;
  final double? vGap;
  final double? keypadWidth;

  const CustomNumericKeypad({
    super.key,
    required this.onDigitTap,
    required this.onDeleteTap,
    this.onClear,
    this.leftActionText,
    this.onLeftActionTap,
    this.buttonSize,
    this.vGap,
    this.keypadWidth,
  });

  @override
  Widget build(BuildContext context) {
    final double availableHeight = MediaQuery.of(context).size.height;
    final bool isVeryCompact = availableHeight < 620;
    final bool isCompact = availableHeight < 760;

    final double resolvedButtonSize = buttonSize ??
        context.responsive(isVeryCompact ? 56 : (isCompact ? 62 : 68));
    final double resolvedVGap =
        vGap ?? context.responsive(isVeryCompact ? 14 : (isCompact ? 18 : 22));
    final double resolvedKeypadWidth = keypadWidth ??
        context.responsive(isVeryCompact ? 236 : (isCompact ? 254 : 268));

    Widget keyRow(List<String> digits) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: digits
            .map(
              (d) => KeypadButton(
                label: d,
                onTap: () => onDigitTap(d),
                size: resolvedButtonSize,
              ),
            )
            .toList(),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: resolvedKeypadWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          keyRow(['1', '2', '3']),
          SizedBox(height: resolvedVGap),
          keyRow(['4', '5', '6']),
          SizedBox(height: resolvedVGap),
          keyRow(['7', '8', '9']),
          SizedBox(height: resolvedVGap),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (leftActionText != null)
                KeypadButton(
                  label: leftActionText,
                  onTap: () {
                    if (onLeftActionTap != null) {
                      onLeftActionTap!();
                    } else {
                      onDigitTap(leftActionText!);
                    }
                  },
                  size: resolvedButtonSize,
                )
              else
                SizedBox(
                  width: resolvedButtonSize,
                  height: resolvedButtonSize,
                ),
              KeypadButton(
                label: '0',
                onTap: () => onDigitTap('0'),
                size: resolvedButtonSize,
              ),
              KeypadButton(
                icon: Icons.backspace_outlined,
                iconColor: const Color(0xFF222222),
                onTap: onDeleteTap,
                onLongPress: onClear,
                size: resolvedButtonSize,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class KeypadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double size;

  const KeypadButton({
    super.key,
    this.label,
    this.icon,
    this.iconColor,
    required this.onTap,
    this.onLongPress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: const Color(0xFFF4F6F7),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          onLongPress: onLongPress != null
              ? () {
                  HapticFeedback.mediumImpact();
                  onLongPress!();
                }
              : null,
          customBorder: const CircleBorder(),
          splashColor: Colors.black.withValues(alpha: 0.08),
          highlightColor: Colors.black.withValues(alpha: 0.04),
          child: Center(
            child: label != null
                ? Text(
                    label!,
                    style: TextStyle(
                      fontSize: label == '.'
                          ? context.responsive(30)
                          : context.responsive(26),
                      fontWeight:
                          label == '.' ? FontWeight.w700 : FontWeight.w400,
                      color: const Color(0xFF222222),
                    ),
                  )
                : Icon(
                    icon,
                    color: iconColor ?? const Color(0xFF222222),
                    size: context.responsive(23),
                  ),
          ),
        ),
      ),
    );
  }
}

