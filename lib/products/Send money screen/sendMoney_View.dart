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
    if (controller.phoneContacts.isEmpty &&
        !controller.isLoadingContacts.value) {
      controller.fetchPhoneContacts();
    }
    controller.contactSearchQuery.value = '';
    controller.contactSearchController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.78,
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
            const SizedBox(height: 14),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: lightprimaryred,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.contacts_rounded,
                      color: primaryRed,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Select Phone Contact",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Obx(
                          () => Text(
                            controller.hasContactPermission.value
                                ? "${controller.phoneContacts.length} Contacts available"
                                : "Permission required",
                            style: const TextStyle(
                              fontSize: 12,
                              color: secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: secondaryText,
                      size: 22,
                    ),
                    tooltip: "Refresh contacts",
                    onPressed: () =>
                        controller.fetchPhoneContacts(forceRefresh: true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            // const SizedBox(height: 10),

            // Native System Picker Action Button
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 20),
            //   child: InkWell(
            //     onTap: () {
            //       Navigator.pop(ctx);
            //       controller.pickFromNativeContacts();
            //     },
            //     borderRadius: BorderRadius.circular(12),
            //     child: Container(
            //       padding: const EdgeInsets.symmetric(
            //         horizontal: 14,
            //         vertical: 10,
            //       ),
            //       decoration: BoxDecoration(
            //         color: lightprimaryred.withValues(alpha: 0.5),
            //         borderRadius: BorderRadius.circular(12),
            //         border: Border.all(
            //           color: primaryRed.withValues(alpha: 0.2),
            //         ),
            //       ),
            //       child: const Row(
            //         children: [
            //           Icon(
            //             Icons.phone_iphone_rounded,
            //             color: primaryRed,
            //             size: 20,
            //           ),
            //           SizedBox(width: 10),
            //           Expanded(
            //             child: Text(
            //               "Open System Contact Picker",
            //               style: TextStyle(
            //                 color: primaryRed,
            //                 fontWeight: FontWeight.w600,
            //                 fontSize: 13,
            //               ),
            //             ),
            //           ),
            //           Icon(
            //             Icons.arrow_forward_ios_rounded,
            //             color: primaryRed,
            //             size: 14,
            //           ),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 10),

            // In-modal search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: controller.contactSearchController,
                onChanged: (val) => controller.contactSearchQuery.value = val,
                decoration: InputDecoration(
                  hintText: "Search contacts by name or phone",
                  hintStyle: const TextStyle(
                    color: secondaryText,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: secondaryText,
                    size: 20,
                  ),
                  suffixIcon: Obx(() {
                    if (controller.contactSearchQuery.value.isNotEmpty) {
                      return IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: secondaryText,
                        ),
                        onPressed: () {
                          controller.contactSearchController.clear();
                          controller.contactSearchQuery.value = '';
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  filled: true,
                  fillColor: backgroundColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryRed, width: 1.2),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            const Divider(height: 1, color: borderColor),

            // Contacts List / States
            Expanded(
              child: Obx(() {
                if (controller.isLoadingContacts.value) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: primaryRed,
                          strokeWidth: 2.5,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Loading phone contacts...",
                          style: TextStyle(color: secondaryText, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                if (!controller.hasContactPermission.value) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: lightprimaryred,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.no_accounts_rounded,
                              size: 44,
                              color: primaryRed,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Contacts Permission Required",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Please grant permission to view your phone contacts to quickly select recipients.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryText,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(Icons.settings_rounded, size: 18),
                            label: const Text("Allow in Settings"),
                            onPressed: () =>
                                controller.openSettingsForPermission(),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final contacts = controller.filteredPhoneContacts;
                if (contacts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            controller.contactSearchQuery.value.isNotEmpty
                                ? "No contacts match '${controller.contactSearchQuery.value}'"
                                : "No contacts found on this device",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: contacts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(ctx);
                        final raw = contact['rawPhone'] ?? '';
                        controller.mobileController.text = raw;
                        controller.mobileNumber.value = raw;
                        controller.selectRecipient(contact);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 42,
                              width: 42,
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
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact['name'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    contact['phone'] ?? '',
                                    style: const TextStyle(
                                      color: secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: secondaryText,
                            ),
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

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SendmoneyController>()) {
      Get.put(SendmoneyController());
    } else {
      Get.find<SendmoneyController>().checkKycStatus();
      Get.find<SendmoneyController>().checkCardStatus();
    }

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
      body: Obx(() {
        if (controller.isCardFrozen.value) {
          return _buildCardFrozenRestrictedView(context);
        }
        if (controller.isCardPermanentlyBlocked.value) {
          return _buildCardBlockedRestrictedView(context);
        }
        if (!controller.isFullKyc.value) {
          return _buildKycRestrictedView(context);
        }
        return SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top W2W Header Banner
                Container(
                  color: backgroundColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryLightYellow, primaryLightYellow],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color.fromRGBO(0, 0, 0, 0.05),
                              width: 1.0,
                            ),
                            color: const Color.fromRGBO(255, 255, 255, 1),
                          ),
                          child: const Icon(
                            Icons.swap_horiz_rounded,
                            color: primaryRed,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "C2C Transfer",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Customer to Customer Instant Money Transfer",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Input Card section (Manual Mobile Number or Pick from Phonebook)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
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
                          textsize: context.responsive(14),

                          isLoading: controller.isLoading.value,
                          onPressed: () => controller.proceedWithManualNumber(),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                Visibility(
                  visible: controller.filteredRecipients.isNotEmpty,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: controller.searchController,
                      onChanged: (value) =>
                          controller.searchQuery.value = value,
                      decoration: InputDecoration(
                        hintText: "Search recent payments or contacts",
                        hintStyle: const TextStyle(
                          color: secondaryText,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: secondaryText,
                        ),
                        suffixIcon: Obx(() {
                          if (controller.searchQuery.value.isNotEmpty) {
                            return IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: secondaryText,
                              ),
                              onPressed: () {
                                controller.searchController.clear();
                                controller.searchQuery.value = '';
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        }),
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
                          borderSide: const BorderSide(
                            color: primaryRed,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Recent Payments Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            size: 18,
                            color: textColor,
                          ),
                          const SizedBox(width: 6),
                          Obx(() {
                            final isSearching = controller.searchQuery.value
                                .trim()
                                .isNotEmpty;
                            return Text(
                              isSearching
                                  ? "Search Results"
                                  : "Recent Payments",
                              style: const TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            );
                          }),
                        ],
                      ),
                      Obx(() {
                        if (controller.recentRecipients.isNotEmpty &&
                            controller.searchQuery.value.isEmpty) {
                          return GestureDetector(
                            onTap: () => controller.clearRecentRecipients(),
                            child: const Text(
                              "Clear",
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Dynamic Recent Payments / Contacts Search List
                Obx(() {
                  final list = controller.filteredRecipients;
                  if (list.isEmpty) {
                    final isSearching = controller.searchQuery.value
                        .trim()
                        .isNotEmpty;
                    if (isSearching) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 36,
                          horizontal: 20,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "No payments or contacts found matching '${controller.searchQuery.value}'",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: secondaryText,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Empty state when there are no recent payments yet
                    return Container(
                      margin: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                              color: lightprimaryred,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.people_outline_rounded,
                              color: primaryRed,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "No Recent Payments Yet",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Pick a contact from your phonebook or enter a mobile number above to transfer money.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: list.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
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
                                  user['avatar'] ?? "W",
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
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKycRestrictedView(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                color: Color(0xFFD97706),
                size: 42,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Full KYC Required",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "In accordance with RBI regulations, Send Money (Wallet-to-Wallet transfer) is available exclusively for Full KYC verified accounts.\n\nPlease complete your Full KYC (Video KYC) to unlock money transfers.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Get.toNamed("/updateKyc"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Complete Full KYC",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  "Go Back to Dashboard",
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFrozenRestrictedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
              ),
              child: const Icon(
                Icons.ac_unit_rounded,
                size: 48,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Card is Frozen",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Your card is currently frozen. Send Money (Wallet-to-Wallet transfer) is temporarily disabled while your card is frozen.\n\nPlease unfreeze your card to resume money transfers.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Get.toNamed("/managecard"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Manage Card / Unfreeze",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  "Go Back to Dashboard",
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBlockedRestrictedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFECACA), width: 2),
              ),
              child: const Icon(
                Icons.block_rounded,
                size: 48,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Card Permanently Blocked",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Your card is permanently blocked. Send Money is disabled for this account.\n\nIf you need assistance, please contact customer support.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Get.toNamed("/contactsupport"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Contact Support",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  "Go Back to Dashboard",
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
