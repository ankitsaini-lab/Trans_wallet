import 'package:flutter/material.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Contact%20Support%20screen/contact_Support_screen_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:transwallet/widgets/textfieldwidget.dart';
import 'package:transwallet/widgets/constsize.dart';

class ContactSupportScreenView extends GetView<ContactSupportScreenController> {
  const ContactSupportScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => ContactSupportScreenController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        elevation: 0,
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        title: Text(
          "Customer Support",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: context.responsive(18),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.ticketCreated.value) {
            return _buildTicketSuccessScreen(context);
          }

          return _buildSupportFormScreen(context, primaryRed);
        }),
      ),
    );
  }

  Widget _buildSupportFormScreen(BuildContext context, Color primaryRed) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: context.responsive(20),
        vertical: context.responsive(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: context.responsive(20)),
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const _PulsingSupportRing(),
                    Container(
                      height: context.responsive(84),
                      width: context.responsive(84),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryRed.withOpacity(0.15),
                        border: Border.all(
                          color: primaryRed.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.support_agent_rounded,
                        color: const Color(0xFF111111),
                        size: context.responsive(42),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.responsive(20)),
                Text(
                  "Help Center",
                  style: TextStyle(
                    fontSize: context.responsive(22),
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF111111),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: context.responsive(4)),
                // const Text(
                //   "We typically reply within 5–15 minutes",
                //   style: TextStyle(
                //     fontSize: 13,
                //     color: Color(0xFF6B7280),
                //     fontWeight: FontWeight.w600,
                //   ),
                // ),
              ],
            ),
          ),
          SizedBox(height: context.responsive(32)),

          Text(
            "Quick Channels",
            style: TextStyle(
              fontSize: context.responsive(15),
              color: const Color(0xFF111111),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: context.responsive(12)),
          SizedBox(
            height: context.responsive(120),
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildChannelCard(
                  context,
                  Icons.email_outlined,
                  "Email Support",
                  "2 hour response",
                  Colors.blue,
                  () => _showQuickChannelSnackbar(
                    context,
                    "Email",
                    "Opening compose email draft...",
                  ),
                ),
                _buildChannelCard(
                  context,
                  Icons.phone_in_talk_outlined,
                  "Call Helpline",
                  "9 AM - 6 PM",
                  Colors.purple,
                  () => _showQuickChannelSnackbar(
                    context,
                    "Helpline",
                    "Dialing customer care helpline...",
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.responsive(32)),

          Text(
            "Create a Support Ticket",
            style: TextStyle(
              fontSize: context.responsive(15),
              color: const Color(0xFF111111),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: context.responsive(12)),

          Container(
            padding: EdgeInsets.all(context.responsive(20)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(context.responsive(24)),
              border: Border.all(color: const Color(0xFFECECEC)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SELECT CATEGORY",
                  style: TextStyle(
                    fontSize: context.responsive(10),
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: context.responsive(10)),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.categories.map((category) {
                    return Obx(() {
                      final bool isSelected =
                          controller.selectedCategory.value == category;
                      return GestureDetector(
                        onTap: () {
                          controller.selectedCategory.value = category;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: context.responsive(14),
                            vertical: context.responsive(8),
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryRed // primaryYellow
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(
                              context.responsive(30),
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? primaryRed
                                  : const Color(0xFFECECEC),
                              width: 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: primaryYellow,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF6B7280),
                              fontSize: context.responsive(12),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    });
                  }).toList(),
                ),
                SizedBox(height: context.responsive(24)),

                CustomTextField(
                  label: "EXPLAIN YOUR ISSUE",
                  controller: controller.messageController,
                  maxLines: 4,
                  hintText:
                      "Describe what went wrong or enter your question here...",
                ),
              ],
            ),
          ),
          SizedBox(height: context.responsive(40)),

          CustomButton(
            text: "Submit Support Ticket",
            btncolor: Colors.black,
            isLoading: controller.isSubmitting.value,
            onPressed: () {
              controller.sendTicket();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTicketSuccessScreen(BuildContext context) {
    return _TicketEntranceAnimation(
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive(24),
            vertical: context.responsive(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: context.responsive(85),
                width: context.responsive(85),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(context.responsive(50)),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: context.responsive(38),
                ),
              ),
              SizedBox(height: context.responsive(24)),

              Text(
                "Ticket Created Successfully!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.responsive(20),
                  color: const Color(0xFF111111),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: context.responsive(6)),
              Text(
                "Our team is investigating your query",
                style: TextStyle(
                  fontSize: context.responsive(13),
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: context.responsive(32)),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(context.responsive(24)),
                  border: Border.all(color: const Color(0xFFECECEC)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(context.responsive(20)),
                      child: Column(
                        children: [
                          _buildTicketRow(
                            context,
                            "Ticket ID",
                            controller.ticketId.value,
                            isPrimary: true,
                          ),
                          SizedBox(height: context.responsive(10)),
                          _buildTicketRow(
                            context,
                            "Category",
                            controller.selectedCategory.value,
                          ),
                          SizedBox(height: context.responsive(10)),
                          _buildTicketRow(
                            context,
                            "Status",
                            "Assigned • Processing",
                            isStatus: true,
                          ),
                        ],
                      ),
                    ),

                    Row(
                      children: [
                        Container(
                          height: context.responsive(16),
                          width: context.responsive(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(context.responsive(8)),
                              bottomRight: Radius.circular(
                                context.responsive(8),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.responsive(10),
                            ),
                            child: Row(
                              children: List.generate(
                                18,
                                (index) => Expanded(
                                  child: Container(
                                    height: 1.2,
                                    color: index % 2 == 0
                                        ? Colors.transparent
                                        : const Color(0xFFECECEC),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: context.responsive(16),
                          width: context.responsive(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(context.responsive(8)),
                              bottomLeft: Radius.circular(
                                context.responsive(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: EdgeInsets.all(context.responsive(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "YOUR MESSAGE SUMMARY",
                            style: TextStyle(
                              fontSize: context.responsive(9),
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: context.responsive(6)),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(context.responsive(12)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                context.responsive(12),
                              ),
                              border: Border.all(
                                color: const Color(0xFFECECEC),
                              ),
                            ),
                            child: Text(
                              controller.messageController.text,
                              style: TextStyle(
                                color: const Color(0xFF4B5563),
                                fontSize: context.responsive(12),
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: context.responsive(48)),

              CustomButton(
                text: "Back to Home",
                btncolor: Colors.white,
                onPressed: () {
                  Get.offAllNamed('/dashboard');
                },
              ),
              SizedBox(height: context.responsive(12)),
              GestureDetector(
                onTap: () {
                  controller.resetForm();
                },
                child: Text(
                  "Create New Ticket",
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: context.responsive(14),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: context.responsive(150),
        margin: EdgeInsets.only(
          right: context.responsive(16),
          bottom: context.responsive(8),
        ),
        padding: EdgeInsets.all(context.responsive(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.responsive(24)),
          border: Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.all(context.responsive(6)),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: context.responsive(20)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF111111),
                    fontSize: context.responsive(12),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: context.responsive(2)),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
                    fontSize: context.responsive(9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketRow(
    BuildContext context,
    String title,
    String value, {
    bool isPrimary = false,
    bool isStatus = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF6B7280),
            fontSize: context.responsive(12),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isStatus
                ? Colors.green.shade700
                : (isPrimary
                      ? const Color(0xFF111111)
                      : const Color(0xFF4B5563)),
            fontSize: context.responsive(12),
            fontWeight: (isPrimary || isStatus)
                ? FontWeight.bold
                : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showQuickChannelSnackbar(
    BuildContext context,
    String channel,
    String msg,
  ) {
    Get.snackbar(
      channel,
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF111111),
      colorText: Colors.white,
      borderRadius: context.responsive(16),
      margin: EdgeInsets.all(context.responsive(16)),
    );
  }
}

class _PulsingSupportRing extends StatefulWidget {
  const _PulsingSupportRing();

  @override
  State<_PulsingSupportRing> createState() => _PulsingSupportRingState();
}

class _PulsingSupportRingState extends State<_PulsingSupportRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 1.0 + (_controller.value * 0.7),
              child: Opacity(
                opacity: (1.0 - _controller.value).clamp(0.0, 1.0),
                child: Container(
                  width: context.responsive(90),
                  height: context.responsive(90),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryYellow, width: 2),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TicketEntranceAnimation extends StatefulWidget {
  final Widget child;
  const _TicketEntranceAnimation({required this.child});

  @override
  State<_TicketEntranceAnimation> createState() =>
      _TicketEntranceAnimationState();
}

class _TicketEntranceAnimationState extends State<_TicketEntranceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
