import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';

class UserAvatar extends StatelessWidget {
  final double size;
  final double? fontSize;
  final String? name;
  final String? imageUrl;
  final Color? backgroundColor;
  final Color? textColor;
  final BoxBorder? border;

  const UserAvatar({
    super.key,
    this.size = 48,
    this.fontSize,
    this.name,
    this.imageUrl,
    this.backgroundColor,
    this.textColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    final String? imgUrl =
        (imageUrl ?? box.read('profilePictureUrl')?.toString())?.trim();
    final String rawName = (name ?? box.read('name')?.toString() ?? 'User')
        .trim();

    String initials = 'U';
    if (rawName.isNotEmpty) {
      final parts = rawName
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.length == 1) {
        initials = parts[0][0].toUpperCase();
      } else if (parts.length > 1) {
        initials = '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
      }
    }
    final double calculatedFontSize =
        fontSize ?? (size * (initials.length > 1 ? 0.36 : 0.42));

    final Widget fallbackInitials = Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: backgroundColor == null
            ? const LinearGradient(
                colors: [lightprimaryred, primaryYellow],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: backgroundColor,
        border:
            border ?? Border.all(color: primaryRed.withOpacity(0.2), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: textColor ?? primaryRed,
          fontSize: calculatedFontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
    );

    if (imgUrl != null && imgUrl.isNotEmpty) {
      return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: border ?? Border.all(color: Colors.white, width: 2),
        ),
        child: ClipOval(
          child: Image.network(
            imgUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallbackInitials,
          ),
        ),
      );
    }

    return fallbackInitials;
  }
}
