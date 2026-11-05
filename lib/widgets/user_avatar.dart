import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Dashboard%20screen/dashboardscreen_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';

class UserAvatar extends StatelessWidget {
  final double size;
  final double? fontSize;
  final String? name;
  final String? imageUrl;
  final File? imageFile;
  final Color? backgroundColor;
  final Color? textColor;
  final BoxBorder? border;
  final bool isLoading;

  const UserAvatar({
    super.key,
    this.size = 48,
    this.fontSize,
    this.name,
    this.imageUrl,
    this.imageFile,
    this.backgroundColor,
    this.textColor,
    this.border,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if ((imageUrl == null || name == null) &&
        Get.isRegistered<DashboardscreenController>()) {
      avatar = Obx(() {
        final ctrl = Get.find<DashboardscreenController>();
        ctrl.profilePictureUrl.value;
        ctrl.userName.value;
        return _buildAvatar(context);
      });
    } else {
      avatar = _buildAvatar(context);
    }

    if (!isLoading) return avatar;

    return Stack(
      alignment: Alignment.center,
      children: [
        avatar,
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: SizedBox(
              width: size * 0.35,
              height: size * 0.35,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final box = GetStorage();
    String? currentImgUrl = imageUrl;
    String currentName = name ?? '';

    if (Get.isRegistered<DashboardscreenController>()) {
      final ctrl = Get.find<DashboardscreenController>();
      if (imageUrl == null) {
        currentImgUrl = ctrl.profilePictureUrl.value.isNotEmpty
            ? ctrl.profilePictureUrl.value
            : box.read('profilePictureUrl')?.toString();
      }
      if (name == null) {
        currentName = ctrl.userName.value.isNotEmpty
            ? ctrl.userName.value
            : (box.read('name')?.toString() ?? 'User');
      }
    } else {
      currentImgUrl ??= box.read('profilePictureUrl')?.toString();
      if (currentName.isEmpty) {
        currentName = box.read('name')?.toString() ?? 'User';
      }
    }

    final String? finalImgUrl = currentImgUrl?.trim();
    final String rawName = currentName.trim();

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
            border ??
            Border.all(color: primaryRed.withValues(alpha: 0.2), width: 2),
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

    if (imageFile != null) {
      return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: border ?? Border.all(color: Colors.white, width: 2),
        ),
        child: ClipOval(
          child: Image.file(
            imageFile!,
            key: ValueKey(imageFile!.path),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallbackInitials,
          ),
        ),
      );
    }

    if (finalImgUrl != null && finalImgUrl.isNotEmpty) {
      if (finalImgUrl.startsWith('data:image')) {
        try {
          final commaIdx = finalImgUrl.indexOf(',');
          final b64 = commaIdx != -1
              ? finalImgUrl.substring(commaIdx + 1)
              : finalImgUrl;
          final bytes = base64Decode(b64);
          return Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: border ?? Border.all(color: Colors.white, width: 2),
            ),
            child: ClipOval(
              child: Image.memory(
                bytes,
                key: ValueKey(b64.hashCode),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallbackInitials,
              ),
            ),
          );
        } catch (_) {
          return fallbackInitials;
        }
      }

      final bool isLocal =
          finalImgUrl.startsWith('/') || finalImgUrl.startsWith('file://');
      if (isLocal) {
        final filePath = finalImgUrl.replaceFirst('file://', '');
        return Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: border ?? Border.all(color: Colors.white, width: 2),
          ),
          child: ClipOval(
            child: Image.file(
              File(filePath),
              key: ValueKey(filePath),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => fallbackInitials,
            ),
          ),
        );
      }

      return Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: border ?? Border.all(color: Colors.white, width: 2),
        ),
        child: ClipOval(
          child: Image.network(
            finalImgUrl,
            key: ValueKey(finalImgUrl),
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
