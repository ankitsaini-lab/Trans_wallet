import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';

class TrackCardView extends StatelessWidget {
  const TrackCardView({super.key});

  @override
  Widget build(BuildContext context) {
    // Read arguments passed from order confirmation screen
    String cardStyleName = "Premium Card";
    String referenceId = "#CRD-928481";
    String cardBgImage = "assets/unioncardblack.png";

    if (Get.arguments != null && Get.arguments is Map) {
      final args = Get.arguments as Map;
      if (args.containsKey('cardStyleName')) {
        cardStyleName = args['cardStyleName'].toString();
      }
      if (args.containsKey('referenceId')) {
        referenceId = args['referenceId'].toString();
      }
      if (args.containsKey('cardBgImage')) {
        cardBgImage = args['cardBgImage'].toString();
      }
    }

    // Format expected delivery date (normally 7 days from now)
    final deliveryDate = DateTime.now().add(const Duration(days: 7));
    final months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    final deliveryDateStr =
        "${deliveryDate.day} ${months[deliveryDate.month - 1]} ${deliveryDate.year}";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        title: const Text(
          "Track Your Card",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHorizontalCardTile(
                      cardStyleName,
                      referenceId,
                      cardBgImage,
                    ),
                    const SizedBox(height: 20),
                    _buildExpectedDeliveryCard(deliveryDateStr),
                    const SizedBox(height: 28),
                    const Text(
                      "SHIPMENT TIMELINE",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildShipmentTimeline(),
                  ],
                ),
              ),
            ),
            _buildNeedHelpCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCardTile(
    String cardStyleName,
    String referenceId,
    String cardBgImage,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightprimaryred,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryYellow, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              image: DecorationImage(
                image: AssetImage(cardBgImage),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cardStyleName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: primaryYellow.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Order ID $referenceId",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primaryRed,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpectedDeliveryCard(String deliveryDateStr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightprimaryred,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryYellow, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryRed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SvgPicture.asset("assets/tracktruck.svg"),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Expected Delivery",
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deliveryDateStr,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentTimeline() {
    return Column(
      children: [
        _buildTimelineItem(
          title: "Order Placed",
          subtitle: "19 Aug · 11:24 AM",
          isCompleted: true,
          isActive: false,
          isLast: false,
        ),
        _buildTimelineItem(
          title: "Order Confirmed",
          subtitle: "19 Aug · 11:25 AM",
          isCompleted: true,
          isActive: false,
          isLast: false,
        ),
        _buildTimelineItem(
          title: "Preparing Your Card",
          subtitle: "In progress",
          isCompleted: false,
          isActive: true,
          isLast: false,
          subtitleColor: const Color(0xFFD97706),
        ),
        _buildTimelineItem(
          title: "Shipped",
          subtitle: "Yet to start",
          isCompleted: false,
          isActive: false,
          isLast: false,
          subtitleColor: const Color(0xFF9CA3AF),
        ),
        _buildTimelineItem(
          title: "Out for Delivery",
          subtitle: "Yet to start",
          isCompleted: false,
          isActive: false,
          isLast: false,
          subtitleColor: const Color(0xFF9CA3AF),
        ),
        _buildTimelineItem(
          title: "Delivered",
          subtitle: "Yet to start",
          isCompleted: false,
          isActive: false,
          isLast: true,
          subtitleColor: const Color(0xFF9CA3AF),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
    Color? subtitleColor,
  }) {
    Widget dot;
    if (isCompleted) {
      dot = Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: primaryRed,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 13, color: Colors.white),
      );
    } else if (isActive) {
      dot = Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primaryRed,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(color: primaryRed.withOpacity(0.3), blurRadius: 4),
          ],
        ),
      );
    } else {
      dot = Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              dot,
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.5,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted ? primaryRed : const Color(0xFFE5E7EB),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: (isCompleted || isActive)
                          ? Colors.black
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: subtitleColor ?? const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedHelpCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: GestureDetector(
        onTap: () => Get.toNamed('/contactsupport'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.headset_mic_outlined,
                  color: Colors.black,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Need Help?",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Chat with our support team →",
                      style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
