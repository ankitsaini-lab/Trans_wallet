import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/common_webview_screen.dart';

class ProfileInfoSheets {
  // static const String policyUrl =
  //     "https://devtc.transcorpint.com/ppi-policies-and-tc-mobile";

  /// Opens the official policy / FAQs / Terms / Privacy WebView
  static void openPolicyWebView({
    required String title,
    required String policyUrl,
  }) {
    Get.to(() => CommonWebViewScreen(url: policyUrl, title: title));
  }

  /// Opens a modern modal bottom sheet for FAQs
  static void showFaqSheet(BuildContext context) {
    Get.bottomSheet(
      const _FaqBottomSheetContent(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// Opens a modern modal bottom sheet for Terms & Conditions
  static void showTermsSheet(BuildContext context) {
    Get.bottomSheet(
      const _TermsBottomSheetContent(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  /// Opens a modern modal bottom sheet for Privacy Policy
  static void showPrivacyPolicySheet(BuildContext context) {
    Get.bottomSheet(
      const _PrivacyPolicyBottomSheetContent(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAQ Bottom Sheet Content
// ─────────────────────────────────────────────────────────────────────────────
class _FaqBottomSheetContent extends StatelessWidget {
  const _FaqBottomSheetContent();

  static const List<Map<String, String>> _faqs = [
    {
      "q": "What is TransWallet and Transcorp Prepaid Card?",
      "a":
          "TransWallet is an authorized digital prepaid wallet and card solution powered by Transcorp. It enables secure online payments, in-store POS tap & pay, ATM withdrawals, and bill recharges across India.",
    },
    {
      "q": "How do I activate or manage my card?",
      "a":
          "You can manage your card from the 'Manage Card' section on your Dashboard. From there, you can view card details, set domestic/international limits, freeze or unfreeze your card, and set or reset your ATM PIN.",
    },
    {
      "q": "How do I complete my KYC verification?",
      "a":
          "Go to Profile > Account > KYC & Verification. You can complete your full KYC quickly using your Aadhaar OTP and PAN number in compliance with RBI regulations.",
    },
    {
      "q": "How does device SIM binding protect my account?",
      "a":
          "Under fintech and banking security regulations, your registered mobile number is bound to the SIM card in your phone. This prevents unauthorized access to your wallet from other devices.",
    },
    {
      "q": "How do I change or reset my 4-digit PIN?",
      "a":
          "Navigate to Profile > Security > Change PIN. Enter your current PIN to set a new one. If you have forgotten your current PIN, you can reset it via Contact Support.",
    },
    {
      "q": "What should I do if a transaction fails?",
      "a":
          "If money is debited for a failed transaction, it is usually refunded automatically within 2 to 5 business days. You can also tap 'Contact Support' to raise a ticket with our team.",
    },
    {
      "q": "How do I contact customer support?",
      "a":
          "You can reach our dedicated support team 24/7 directly from Profile > Support > Contact Support or raise an instant ticket inside the app.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.responsive(20)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: lightprimaryred,
                    border: Border.all(color: primaryYellow),
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    color: primaryRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "FAQs",
                        style: TextStyle(
                          fontSize: context.responsive(18),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      Text(
                        "Frequently asked questions & answers",
                        style: TextStyle(
                          fontSize: context.responsive(12),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded, color: Colors.black87),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF3F4F6)),

          // List of FAQs
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive(18),
                vertical: 8,
              ),
              itemCount: _faqs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _faqs[index];
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      childrenPadding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 14,
                      ),
                      iconColor: primaryRed,
                      collapsedIconColor: Colors.grey.shade600,
                      title: Text(
                        item["q"]!,
                        style: TextStyle(
                          fontSize: context.responsive(13.5),
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      children: [
                        Text(
                          item["a"]!,
                          style: TextStyle(
                            fontSize: context.responsive(12.5),
                            height: 1.45,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Action
          Padding(
            padding: EdgeInsets.all(context.responsive(16)),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Get.back();
                      Get.toNamed('/contactsupport');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryRed,
                      side: const BorderSide(color: primaryRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Need More Help? Contact Support",
                      style: TextStyle(fontWeight: FontWeight.w700),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Terms & Conditions Bottom Sheet Content
// ─────────────────────────────────────────────────────────────────────────────
class _TermsBottomSheetContent extends StatelessWidget {
  const _TermsBottomSheetContent();

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.responsive(20)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: lightprimaryred,
                    border: Border.all(color: primaryYellow),
                  ),
                  child: const Icon(
                    Icons.article_outlined,
                    color: primaryRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Terms & Conditions",
                        style: TextStyle(
                          fontSize: context.responsive(18),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      Text(
                        "Last updated: October 2026",
                        style: TextStyle(
                          fontSize: context.responsive(12),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded, color: Colors.black87),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF3F4F6)),

          // Terms Body
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive(20),
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: "1. Acceptance of Terms",
                    content:
                        "By downloading, accessing, or using TransWallet and associated prepaid card services provided by Transcorp International Ltd, you agree to be bound by these Terms and Conditions and all applicable Reserve Bank of India (RBI) regulations.",
                  ),
                  _buildSection(
                    title: "2. Account & Eligibility",
                    content:
                        "You must be at least 18 years of age and a resident of India to create an account. You agree to provide accurate identification data during onboarding and complete KYC requirements within specified timeframes.",
                  ),
                  _buildSection(
                    title: "3. Prepaid Card Usage & Limits",
                    content:
                        "The Transcorp Prepaid Card is issued pursuant to RBI guidelines for Prepaid Payment Instruments (PPI). Cards can be used across domestic POS terminals, e-commerce portals, and ATMs. Transaction limits and usage restrictions configured in the app apply to all card operations.",
                  ),
                  _buildSection(
                    title: "4. User Security & PIN",
                    content:
                        "You are solely responsible for maintaining confidentiality of your MPIN, card CVV, passwords, and OTPs. Transcorp representatives will never ask for your PIN or OTP. Immediately report any unauthorized access or lost card via the app.",
                  ),
                  _buildSection(
                    title: "5. Fees & Charges",
                    content:
                        "Transcorp reserves the right to charge nominal issuance, annual maintenance, or transaction fees as communicated in the schedule of charges within the application before initiating relevant transactions.",
                  ),
                  _buildSection(
                    title: "6. Prohibited Activities",
                    content:
                        "Users shall not utilize TransWallet for unlawful activities, unauthorized commercial reselling, money laundering, fraud, or actions violating Indian laws. Violations may result in immediate suspension and notification to law enforcement.",
                  ),
                  _buildSection(
                    title: "7. Governing Law & Jurisdiction",
                    content:
                        "These terms are governed by and construed in accordance with the laws of India. Any disputes arising out of these terms shall be subject to the exclusive jurisdiction of the competent courts of New Delhi, India.",
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom Action
          Padding(
            padding: EdgeInsets.all(context.responsive(16)),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text(
                  "I Understand",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Privacy Policy Bottom Sheet Content
// ─────────────────────────────────────────────────────────────────────────────
class _PrivacyPolicyBottomSheetContent extends StatelessWidget {
  const _PrivacyPolicyBottomSheetContent();

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.responsive(20)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: lightprimaryred,
                    border: Border.all(color: primaryYellow),
                  ),
                  child: const Icon(
                    Icons.privacy_tip_outlined,
                    color: primaryRed,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Privacy Policy",
                        style: TextStyle(
                          fontSize: context.responsive(18),
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      Text(
                        "How we protect and use your data",
                        style: TextStyle(
                          fontSize: context.responsive(12),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded, color: Colors.black87),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF3F4F6)),

          // Privacy Policy Body
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive(20),
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: "1. Information We Collect",
                    content:
                        "We collect personal information necessary to offer secure prepaid wallet services, including your name, verified phone number, email address, date of birth, PAN, and Aadhaar information for KYC verification, along with device and SIM identifiers for fraud protection.",
                  ),
                  _buildSection(
                    title: "2. How We Use Your Data",
                    content:
                        "Your information is utilized solely to provide wallet transactions, issue prepaid cards, prevent fraud, satisfy mandatory regulatory audits, authenticate logins (via MPIN/biometrics), and provide customer assistance.",
                  ),
                  _buildSection(
                    title: "3. Data Security & Storage",
                    content:
                        "We employ industry-leading 256-bit AES encryption for all stored data and TLS protocols for network communications. Your payment PIN and credentials are encrypted and never stored in plain text.",
                  ),
                  _buildSection(
                    title: "4. Information Sharing & Third Parties",
                    content:
                        "Transcorp does not sell or lease your personal information to third parties. Data is shared strictly with banking partners, payment networks (NPCI, RuPay, Visa), and authorized KYC agencies as mandated under Indian financial regulations.",
                  ),
                  _buildSection(
                    title: "5. Device Permissions",
                    content:
                        "The app requests camera and storage permissions strictly for profile pictures and KYC document uploads, and phone state permissions for mandatory SIM binding verification.",
                  ),
                  _buildSection(
                    title: "6. Your Rights & Retention",
                    content:
                        "You have the right to inspect, update, or correct your personal data. Regulatory records are retained in compliance with Prevention of Money Laundering Act (PMLA) and RBI directives.",
                  ),
                  _buildSection(
                    title: "7. Contact Grievance Officer",
                    content:
                        "If you have queries or concerns regarding this policy, you may contact our Grievance Officer through the 'Contact Support' section in the application.",
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom Action
          Padding(
            padding: EdgeInsets.all(context.responsive(16)),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text(
                  "I Understand",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
