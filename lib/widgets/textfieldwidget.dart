import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/constsize.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? errorText;
  final TextInputType keyboardType;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final String? hintText;
  final Function(String)? onChanged;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.label,
    this.controller,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.inputFormatters,
    this.hintText,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.responsive(12),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: context.responsive(8)),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: context.responsive(14),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF111111),
          ),
          decoration: InputDecoration(
            hintText: hintText ?? "Enter $label",
            hintStyle: TextStyle(
              color: const Color(0xFF9CA3AF),
              fontSize: context.responsive(13),
              fontWeight: FontWeight.normal,
            ),
            errorText: errorText,
            errorStyle: TextStyle(
              fontSize: context.responsive(10),
              fontWeight: FontWeight.bold,
            ),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF3F4F6),
            contentPadding: EdgeInsets.symmetric(
              horizontal: context.responsive(16),
              vertical: context.responsive(14),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.responsive(30)),
              borderSide: const BorderSide(
                color: Color(0xFFECECEC),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.responsive(30)),
              borderSide: const BorderSide(
                color: Color(0xFFECECEC),
                width: 1.5,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderRadius: BorderRadius.circular(context.responsive(30)),
              borderSide: const BorderSide(color: primaryRed, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(context.responsive(30)),
              borderSide: const BorderSide(
                color: Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
