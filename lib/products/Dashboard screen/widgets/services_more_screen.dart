import 'package:flutter/material.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Wallet%20Screen/Add%20Money/addmoney_View.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/pressable_scale.dart';
import 'package:transwallet/widgets/globalbottombar/Globalbottombar_View.dart';

class ServicesMoreScreen extends StatelessWidget {
  const ServicesMoreScreen({super.key});

  static const Color _primaryRed = Color(0xFFFFCC00);
  static const Color _textColor = Color(0xFF111111);
  static const Color _secondaryText = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = (screenWidth - 40 - 16) / 2;
    final double dynamicAspectRatio = itemWidth / 130;

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF9F9FB),
      bottomNavigationBar: GlobalbottombarView(seletedIndex: 2.obs),
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: appBarGradient)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Get.back(),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFECECEC), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: _textColor,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'More Services',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 20,
            letterSpacing: 0,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFCC00).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryRed.withOpacity(0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Financial Hub',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select from our premium range of wallet operations.',
                  style: TextStyle(
                    color: _secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: dynamicAspectRatio,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildServiceCard(
                        icon: Icons.send_rounded,
                        title: 'Send Money',
                        subtitle: 'Instant transfer to bank / wallet',
                        color: const Color(0xFF00C853),
                        onTap: () => Get.toNamed("/sendmoney"),
                      ),
                      _buildServiceCard(
                        icon: Icons.add_rounded,
                        title: 'Add Money',
                        subtitle: 'Top-up wallet via UPI / Card',
                        color: const Color(0xFF2979FF),
                        onTap: () {
                          Get.bottomSheet(
                            const AddmoneyView(showGeneralWalletOption: false),
                            isScrollControlled: true,
                            isDismissible: false,
                            enableDrag: false,
                            backgroundColor: Colors.transparent,
                          );
                        },
                      ),
                      _buildServiceCard(
                        icon: Icons.credit_card_rounded,
                        title: 'Forex Card',
                        subtitle: 'Multi-currency travel card',
                        color: const Color(0xFF651FFF),
                        isUpcoming: true,
                        onTap: () {},
                      ),
                      _buildServiceCard(
                        icon: Icons.swap_horizontal_circle_rounded,
                        title: 'Remittance',
                        subtitle: 'International money exchange',
                        color: const Color(0xFF00B0FF),
                        onTap: () => _openRemittanceBottomSheet(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isUpcoming = false,
  }) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUpcoming
                ? const Color(0xFFECECEC)
                : color.withOpacity(0.12),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isUpcoming
                  ? Colors.black.withOpacity(0.02)
                  : color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUpcoming
                        ? const Color(0xFFF0F0F2)
                        : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isUpcoming ? Colors.grey[500] : color,
                    size: 20,
                  ),
                ),
                if (isUpcoming)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'SOON',
                      style: TextStyle(
                        color: Color(0xFFC62828),
                        fontSize: 7,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isUpcoming ? Colors.grey[600] : _textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isUpcoming ? Colors.grey[400] : _secondaryText,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isUpcoming = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isUpcoming ? const Color(0xFFF9F9FB) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isUpcoming
                ? const Color(0xFFECECEC)
                : _primaryRed.withOpacity(0.12),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUpcoming
                    ? const Color(0xFFF0F0F2)
                    : _primaryRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isUpcoming ? Colors.grey[500] : _primaryRed,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isUpcoming ? Colors.grey[600] : _textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isUpcoming ? Colors.grey[400] : _secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!isUpcoming)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _secondaryText,
                size: 14,
              ),
          ],
        ),
      ),
    );
  }

  void _openRemittanceBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Remittance',
              style: TextStyle(
                color: _textColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select a remittance option',
              style: TextStyle(color: _secondaryText, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildBottomSheetItem(
              icon: Icons.send_rounded,
              title: 'Send Money (Upcoming)',
              subtitle: 'Send money to bank account or wallet',
              isUpcoming: true,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildBottomSheetItem(
              icon: Icons.call_received_rounded,
              title: 'Receive Money (Upcoming)',
              subtitle: 'Receive money directly into your account',
              isUpcoming: true,
              onTap: () {},
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
