import 'package:flutter/material.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/notification_button.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Order%20Card%20screen/order%20card%20screen/ordercard_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/widgets/premium_visa_card.dart';
import 'package:get_storage/get_storage.dart';

class OrdercardView extends GetView<OrdercardController> {
  const OrdercardView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => OrdercardController());

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container( 
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        title: Text(
          "Order Your Card",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: context.responsive(18),
          ),
        ),
        centerTitle: true,
        actions: [
          const NotificationButton(),
          SizedBox(width: context.responsive(16)),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: context.responsive(16)),
            // Main Content Area
            Transform.translate(
              offset: const Offset(0, -5),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsive(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      final activeStyle = controller
                          .cardStyles[controller.activeCardIndex.value];
                      final Color glowColor = activeStyle["glowColor"];
                      final String bgImg =
                          activeStyle["bgImage"] ?? 'assets/unioncardblack.png';
                      final bool useBlackLogos =
                          activeStyle["useBlackLogos"] ?? false;
                      final bool isPopular = activeStyle["isPopular"] ?? false;

                      return Container(
                        padding: EdgeInsets.all(context.responsive(1)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          gradient: ordercardGradient,
                          borderRadius: BorderRadius.circular(
                            context.responsive(18),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                context.responsive(14),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                context.responsive(22),
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(
                                      context.responsive(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        PremiumVisaCard(
                                          cardNumber: "",
                                          cardHolder:
                                              GetStorage().read('name') ??
                                              "Ankit Saini",
                                          expiryDate: "12/28",
                                          cvv: "•••",
                                          bgImage: bgImg,
                                          useBlackLogos: useBlackLogos,
                                          shadowColor: glowColor,
                                        ),
                                        SizedBox(
                                          height: context.responsive(24),
                                        ),

                                        // Exclusive Benefits
                                        Text(
                                          "Exclusive Benefits",
                                          style: TextStyle(
                                            fontSize: context.responsive(16),
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(
                                          height: context.responsive(16),
                                        ),

                                        GridView.count(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          crossAxisCount: 2,
                                          crossAxisSpacing: context.responsive(
                                            12,
                                          ),
                                          mainAxisSpacing: context.responsive(
                                            12,
                                          ),
                                          childAspectRatio: 2.8,
                                          children: [
                                            _buildBenefitCard(
                                              context,
                                              Icons.credit_card_outlined,
                                              "Lifetime Free",
                                            ),
                                            _buildBenefitCard(
                                              context,
                                              Icons.verified_user_outlined,
                                              "EMV secure",
                                            ),
                                            _buildBenefitCard(
                                              context,
                                              Icons.contactless_outlined,
                                              "Contactless\npayments",
                                            ),
                                            _buildBenefitCard(
                                              context,
                                              Icons.credit_card,
                                              "Instant virtual\ncard",
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isPopular)
                                    Positioned(
                                      top: context.responsive(14),
                                      left: context.responsive(-26),
                                      child: Transform.rotate(
                                        angle: -0.785398, // -45 degrees
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: context.responsive(30),
                                            vertical: context.responsive(4),
                                          ),
                                          color: primaryRed,
                                          child: Text(
                                            "POPULAR",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: context.responsive(8),
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1,
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
                      );
                    }),

                    SizedBox(height: context.responsive(24)),

                    // Pricing Summary
                    Container(
                      padding: EdgeInsets.all(context.responsive(20)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          context.responsive(16),
                        ),
                        border: Border.all(
                          color: const Color(0xFFF3F4F6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildPricingRow(context, "Card Fee", "₹499"),
                          SizedBox(height: context.responsive(16)),
                          _buildPricingRow(
                            context,
                            "Annual Maintenance",
                            "₹299",
                          ),
                          SizedBox(height: context.responsive(16)),
                          _buildPricingRow(context, "Delivery", "₹99"),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: context.responsive(16),
                            ),
                            child: const Divider(
                              color: Color(0xFFF3F4F6),
                              height: 1,
                              thickness: 1.5,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: context.responsive(15),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "₹897",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: context.responsive(15),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.responsive(32)),
                    CustomButton(
                      text: "Continue to Delivery",
                      btncolor: primaryRed,
                      borderRadius: context.responsive(40),
                      textColor: Colors.white,
                      onPressed: () {
                        Get.toNamed('/revieworderdetails');
                      },
                    ),
                    SizedBox(height: context.responsive(32)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitCard(BuildContext context, IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: context.responsive(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.responsive(12)),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(context.responsive(6)),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
              borderRadius: BorderRadius.circular(context.responsive(8)),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4B5563),
              size: context.responsive(16),
            ),
          ),
          SizedBox(width: context.responsive(10)),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              style: TextStyle(
                color: Colors.black,
                fontSize: context.responsive(11),
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingRow(BuildContext context, String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF9CA3AF),
            fontSize: context.responsive(13),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.black,
            fontSize: context.responsive(13),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
