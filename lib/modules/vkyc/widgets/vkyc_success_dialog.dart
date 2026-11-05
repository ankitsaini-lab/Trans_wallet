import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/constsize.dart';

/// Premium Success Modal Dialog displayed on Dashboard after successful Video KYC (VKYC).
class VkycSuccessDialog extends StatefulWidget {
  final VoidCallback? onDismiss;

  const VkycSuccessDialog({super.key, this.onDismiss});

  @override
  State<VkycSuccessDialog> createState() => _VkycSuccessDialogState();
}

class _VkycSuccessDialogState extends State<VkycSuccessDialog>
    with SingleTickerProviderStateMixin {
  static const Color _emeraldGreen = Color(0xFF10B981);
  static const Color _softGreenBg = Color(0xFFECFDF5);

  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
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

  void _handleClose() {
    try {
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      } else if (Get.isDialogOpen ?? false) {
        Get.until((route) => !Get.isDialogOpen!);
      }
    } catch (_) {
      if (Get.isDialogOpen ?? false) {
        Get.back(closeOverlays: true);
      }
    }
    widget.onDismiss?.call();
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
            constraints: const BoxConstraints(maxWidth: 360),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Row with Badge and Close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _softGreenBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _emeraldGreen.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              color: _emeraldGreen,
                              size: 14,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "VKYC APPROVED",
                              style: TextStyle(
                                fontSize: context.responsive(11),
                                fontWeight: FontWeight.w700,
                                color: _emeraldGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _handleClose,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Animated Circular Success Graphic
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 96,
                        width: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _emeraldGreen.withValues(alpha: 0.08),
                        ),
                      ),
                      Container(
                        height: 74,
                        width: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _emeraldGreen.withValues(alpha: 0.16),
                        ),
                      ),
                      Container(
                        height: 54,
                        width: 54,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF34D399), _emeraldGreen],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x4D10B981),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Full KYC Verified!',
                    style: TextStyle(
                      fontSize: context.responsive(22),
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111111),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Your Video KYC has been approved successfully. Your Transwallet account is now fully active with maximum limits.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.responsive(13),
                      color: const Color(0xFF6B7280),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Highlights Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryRed.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: primaryRed,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Maximum Wallet Limit",
                                    style: TextStyle(
                                      fontSize: context.responsive(11),
                                      color: const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    "₹ 2,00,000",
                                    style: TextStyle(
                                      fontSize: context.responsive(15),
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF111111),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _softGreenBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "UNLOCKED",
                                style: TextStyle(
                                  fontSize: context.responsive(10),
                                  fontWeight: FontWeight.w800,
                                  color: _emeraldGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Color(0xFFE5E7EB), height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _featureItem(
                              context,
                              icon: Icons.credit_card_rounded,
                              label: "All Cards",
                            ),
                            _featureItem(
                              context,
                              icon: Icons.send_rounded,
                              label: "Fast Transfers",
                            ),
                            _featureItem(
                              context,
                              icon: Icons.receipt_long_rounded,
                              label: "Bill Payments",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Action Button
                  GestureDetector(
                    onTap: _handleClose,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "Done",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: context.responsive(15),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureItem(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: context.responsive(11),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}
