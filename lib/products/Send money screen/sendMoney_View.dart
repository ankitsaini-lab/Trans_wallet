import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/theme.dart';
import 'package:transwallet/products/Send%20money%20screen/sendMoney_Controller.dart';
import 'package:transwallet/widgets/app_bar_back_button.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/widgets/custombutton.dart';

class SendmoneyView extends GetView<SendmoneyController> {
  const SendmoneyView({super.key});

  void _showPhonebookModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.contacts_rounded, color: primaryRed),
                  const SizedBox(width: 8),
                  const Text(
                    "Select Phonebook Contact",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: borderColor),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.phonebookContacts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final contact = controller.phonebookContacts[index];
                  return ListTile(
                    leading: Container(
                      height: 44,
                      width: 44,
                      decoration: const BoxDecoration(
                        color: lightprimaryred,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        contact['avatar'] ?? 'C',
                        style: const TextStyle(
                          color: primaryRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    title: Text(
                      contact['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      contact['phone'] ?? '',
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 13,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: secondaryText,
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      controller.mobileController.text = contact['phone'] ?? '';
                      controller.selectRecipient({
                        "name": contact['name'] ?? 'Contact',
                        "phone": "+91 ${contact['phone']}",
                        "avatar": contact['avatar'] ?? 'W2W',
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => SendmoneyController());

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appBarGradient),
        ),
        elevation: 0,
        centerTitle: true,
        leadingWidth: context.responsive(60),
        leading: const AppBarBackButton(),
        title: const Text(
          "Send Money",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top W2W Header Banner
            Container(
              color: backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [textColor, Colors.grey.shade900],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: lightprimaryred,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: primaryRed,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "W2W Transfer",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Wallet to Wallet Instant Money Transfer",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Input Card section (Manual Mobile Number or Pick from Phonebook)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Enter Mobile Number",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showPhonebookModal(context),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.perm_contact_calendar_rounded,
                              size: 16,
                              color: primaryRed,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Pick from Phonebook",
                              style: TextStyle(
                                color: primaryRed,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller.mobileController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: (val) => controller.mobileNumber.value = val,
                    decoration: InputDecoration(
                      hintText: "Enter 10-digit mobile number",
                      hintStyle: const TextStyle(
                        color: secondaryText,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.phone_android_rounded,
                        color: primaryRed,
                      ),
                      prefixText: "+91  ",
                      prefixStyle: const TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.contacts_rounded,
                          color: primaryRed,
                        ),
                        tooltip: "Pick from Phonebook",
                        onPressed: () => _showPhonebookModal(context),
                      ),
                      filled: true,
                      fillColor: backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: primaryRed,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Obx(() {
                    return CustomButton(
                      text: "Proceed to Pay",
                      btncolor: primaryRed,

                      isLoading: controller.isLoading.value,
                      onPressed: () => controller.proceedWithManualNumber(),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Search Bar for Recent Payments
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: controller.searchController,
                onChanged: (value) => controller.searchQuery.value = value,
                decoration: InputDecoration(
                  hintText: "Search recent payments by name or number",
                  hintStyle: const TextStyle(
                    color: secondaryText,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(Icons.search, color: secondaryText),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: primaryRed, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Recent Payments Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, size: 18, color: textColor),
                  const SizedBox(width: 6),
                  const Text(
                    "Recent Payments",
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Obx(() {
                    final count = controller.filteredRecipients.length;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: lightprimaryred,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "$count",
                        style: const TextStyle(
                          color: primaryRed,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Recent Payments Name List
            Expanded(
              child: Obx(() {
                final list = controller.filteredRecipients;
                if (list.isEmpty) {
                  return const Center(
                    child: Text(
                      "No recent payments found",
                      style: TextStyle(color: secondaryText, fontSize: 14),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = list[index];
                    return GestureDetector(
                      onTap: () => controller.selectRecipient(user),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 46,
                              width: 46,
                              decoration: const BoxDecoration(
                                color: lightprimaryred,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                user['avatar'] ?? "",
                                style: const TextStyle(
                                  color: primaryRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['name'] ?? "",
                                    style: const TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    user['phone'] ?? "",
                                    style: const TextStyle(
                                      color: secondaryText,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Obx(() {
                              final rawPhone = user['phone'] ?? '';
                              final cleanedPhone = rawPhone.replaceAll(
                                RegExp(r'\D'),
                                '',
                              );
                              final phoneToVerify = cleanedPhone.length > 10
                                  ? cleanedPhone.substring(
                                      cleanedPhone.length - 10,
                                    )
                                  : cleanedPhone;
                              final isChecking =
                                  controller.isLoading.value &&
                                  controller.checkingPhone.value ==
                                      phoneToVerify;

                              if (isChecking) {
                                return const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: primaryRed,
                                  ),
                                );
                              }
                              return const Icon(
                                Icons.chevron_right_rounded,
                                color: secondaryText,
                                size: 22,
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
