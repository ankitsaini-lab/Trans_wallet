import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Contact%20Support%20screen/contact_Support_screen_Controller.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/app_snackbar.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactSupportScreenView extends GetView<ContactSupportScreenController> {
  const ContactSupportScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => ContactSupportScreenController());

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        title: Text(
          "Contact Support",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: context.responsive(18),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: context.responsive(20),
            vertical: context.responsive(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle intro text matching the reference
              Padding(
                padding: EdgeInsets.only(
                  left: context.responsive(4),
                  right: context.responsive(4),
                  bottom: context.responsive(16),
                ),
                child: Text(
                  "We're here to help you with any questions or concerns",
                  style: TextStyle(
                    fontSize: context.responsive(13.5),
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),

              // 1. Call Us Card
              _buildSupportCard(
                context,
                iconBgColor: const Color(0xFFE0F2FE),
                icon: Icons.phone_rounded,
                iconColor: const Color(0xFF0284C7),
                title: "Call us",
                subtitle: "+91 - 7597182222",
                note:
                    "Our support team is available from 10 AM to 7 PM to help you on call",
                copyValue: "+91 - 7597182222",
                onTap: () {
                  _copyText(context, "+917597182222", "Helpline number");
                },
              ),

              // 2. Email Us Card
              _buildSupportCard(
                context,
                iconBgColor: const Color(0xFFDCFCE7),
                icon: Icons.mail_rounded,
                iconColor: const Color(0xFF16A34A),
                title: "Email us",
                subtitle: "cards@transcorpint.com",
                note: "Send us an email and we'll respond within 24 hours",
                copyValue: "cards@transcorpint.com",
                onTap: () {
                  _copyText(
                    context,
                    "cards@transcorpint.com",
                    "Support email",
                  );
                },
              ),

              // 3. RBI CMS Portal Card
              _buildSupportCard(
                context,
                iconBgColor: const Color(0xFFFFEDD5),
                icon: Icons.public_rounded,
                iconColor: const Color(0xFFEA580C),
                title: "RBI CMS Portal",
                subtitle: "Register your complaint",
                note:
                    "If your query is not resolved in 30 days, register your complaint here",
                showExternalIcon: true,
                onTap: () => _launchExternalUrl(
                  "https://cms.rbi.org.in/cms/indexpage.html#eng",
                ),
              ),

              // 4. Card Closure Card
              _buildSupportCard(
                context,
                iconBgColor: lightprimaryred,
                icon: Icons.credit_card_off_rounded,
                iconColor: primaryRed,
                title: "Card Closure",
                subtitle: "Request card closure and refund",
                note:
                    "Send us an email to request for card closure and receive a refund.",
                showExternalIcon: true,
                onTap: () => _launchExternalUrl(
                  "https://ppi.transcorpint.com/card-closure",
                ),
              ),

              // 5. Need More Help Card
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(
                  top: context.responsive(4),
                  bottom: context.responsive(24),
                ),
                padding: EdgeInsets.all(context.responsive(16)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(context.responsive(16)),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: const Color(0xFF0284C7),
                          size: context.responsive(20),
                        ),
                        SizedBox(width: context.responsive(8)),
                        Text(
                          "Need more help?",
                          style: TextStyle(
                            fontSize: context.responsive(14.5),
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: context.responsive(8)),
                    Text(
                      "Our support team is dedicated to providing you with the best assistance. If you're experiencing any issues with your card or account, please don't hesitate to reach out.",
                      style: TextStyle(
                        fontSize: context.responsive(12.5),
                        color: const Color(0xFF64748B),
                        height: 1.45,
                      ),
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

  Widget _buildSupportCard(
    BuildContext context, {
    required Color iconBgColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String note,
    String? copyValue,
    VoidCallback? onTap,
    bool showExternalIcon = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: context.responsive(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.responsive(16)),
        border: Border.all(color: Colors.grey.shade200, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(context.responsive(16)),
          child: Padding(
            padding: EdgeInsets.all(context.responsive(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Rounded icon container
                    Container(
                      height: context.responsive(46),
                      width: context.responsive(46),
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(
                          context.responsive(14),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: context.responsive(22),
                      ),
                    ),
                    SizedBox(width: context.responsive(14)),
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: context.responsive(15.5),
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111111),
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: context.responsive(3)),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: context.responsive(13.5),
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (copyValue != null)
                      IconButton(
                        onPressed: () {
                          _copyText(context, copyValue, title);
                        },
                        icon: const Icon(
                          Icons.copy_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        splashRadius: 20,
                        tooltip: "Copy",
                      )
                    else if (showExternalIcon)
                      const Icon(
                        Icons.arrow_outward_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      )
                    else
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                  ],
                ),
                SizedBox(height: context.responsive(12)),
                Text(
                  note,
                  style: TextStyle(
                    fontSize: context.responsive(12.5),
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copyText(BuildContext context, String text, String label) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: text));
    AppSnackbar.success("Copied $label to clipboard: $text");
  }

  Future<void> _launchExternalUrl(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.startExternalFlow(ExternalFlowType.externalBrowser);
      }
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        if (Get.isRegistered<AppLockService>()) {
          AppLockService.to.finishExternalFlow(ExternalFlowType.externalBrowser);
        }
        AppSnackbar.error("Could not open browser for $urlString");
      }
    } catch (e) {
      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.finishExternalFlow(ExternalFlowType.externalBrowser);
      }
      AppSnackbar.error("Could not open link: $e");
    }
  }
}
