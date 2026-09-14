import 'package:flutter/material.dart';
import 'package:transwallet/widgets/notification_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge and Bills/recharge_bills_screens.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

class PayBillScreen extends StatefulWidget {
  const PayBillScreen({super.key});

  @override
  State<PayBillScreen> createState() => _PayBillScreenState();
}

class _PayBillScreenState extends State<PayBillScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late final List<_BillingCategory> _categories = [
    _BillingCategory(
      title: "Recharge & Bills",
      items: [
        _BillingItem(
          label: "Recharge",
          assetPath: "assets/recharge.svg",
          targetScreen: const MobileRechargeScreen(),
        ),
        _BillingItem(
          label: "DTH",
          assetPath: "assets/controller.svg",
          targetScreen: const DthRechargeScreen(),
        ),
        _BillingItem(
          label: "Gas",
          assetPath: "assets/Gas.svg",
          targetScreen: const GasBillScreen(),
        ),
        _BillingItem(
          label: "Electricity",
          assetPath: "assets/Electricity.svg",
          targetScreen: const ElectricityBillScreen(),
        ),
        _BillingItem(
          label: "Broadband",
          assetPath: "assets/Broadband.svg",
          targetScreen: const BroadbandBillScreen(),
        ),
        _BillingItem(
          label: "Water",
          assetPath: "assets/water.svg",
          targetScreen: const WaterBillScreen(),
        ),
      ],
    ),
    _BillingCategory(
      title: "Travel & Transport",
      items: [
        _BillingItem(
          label: "Fastag",
          assetPath: "assets/fastag.svg",
          targetScreen: const FastagRechargeScreen(),
        ),
        _BillingItem(
          label: "Metro Recharge",
          assetPath: "assets/recharge.svg",
          targetScreen: const MobileRechargeScreen(),
        ),
        _BillingItem(
          label: "Bus Booking",
          fallbackIcon: Icons.directions_bus_outlined,
          targetScreen: const _ComingSoonScreen(),
        ),
        _BillingItem(
          label: "Flight Booking",
          fallbackIcon: Icons.flight_outlined,
          targetScreen: const _ComingSoonScreen(),
        ),
      ],
    ),
    _BillingCategory(
      title: "Education",
      items: [
        _BillingItem(
          label: "Tuition Fees",
          assetPath: "assets/tuition.svg",
          targetScreen: const TuitionFeesScreen(),
        ),
        _BillingItem(
          label: "School Fees",
          assetPath: "assets/tuition.svg",
          targetScreen: const TuitionFeesScreen(),
        ),
      ],
    ),
    _BillingCategory(
      title: "Financial Services",
      items: [
        _BillingItem(
          label: "Credit Card Bill",
          assetPath: "assets/credit-card-svgrepo-com.svg",
          targetScreen: const CreditCardBillScreen(),
        ),
        _BillingItem(
          label: "Loan Payment",
          fallbackIcon: Icons.account_balance_outlined,
          targetScreen: const LoanEmiPaymentScreen(),
        ),
        _BillingItem(
          label: "Insurance",
          fallbackIcon: Icons.health_and_safety_outlined,
          targetScreen: const InsurancePremiumScreen(),
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildCategoryHeader(String title) {
    return Row(
      children: [
        Container(
          height: 18,
          width: 4,
          decoration: BoxDecoration(
            color: primaryRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(List<_BillingItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 16,
        childAspectRatio: 0.76,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return CategoryItem(
          label: item.label,
          assetPath: item.assetPath,
          fallbackIcon: item.fallbackIcon,
          targetScreen: item.targetScreen,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter categories and their items based on search query
    final filteredCategories = _categories
        .map((category) {
          final filteredItems = category.items.where((item) {
            return item.label.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
          }).toList();
          return _BillingCategory(title: category.title, items: filteredItems);
        })
        .where((category) => category.items.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: appBarGradient,
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.black,
                  size: 16,
                ),
              ),
            ),
            const Text(
              'Utilities & Bills',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 20,
              ),
            ),
            const NotificationButton(),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search ...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.black54),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFD500),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // Content Area
            Expanded(
              child: filteredCategories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No services found for '$_searchQuery'",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      itemCount: filteredCategories.length,
                      itemBuilder: (context, catIndex) {
                        final category = filteredCategories[catIndex];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCategoryHeader(category.title),
                            const SizedBox(height: 16),
                            _buildGrid(category.items),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryItem extends StatelessWidget {
  final String label;
  final String? assetPath;
  final IconData? fallbackIcon;
  final Widget targetScreen;

  const CategoryItem({
    super.key,
    required this.label,
    this.assetPath,
    this.fallbackIcon,
    required this.targetScreen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (targetScreen is _ComingSoonScreen) {
          AppSnackbar.show(
            title: "Coming Soon",
            message:
                "$label booking feature will be available in the next release.",
            isSuccess: true,
          );
        } else {
          Get.to(() => targetScreen);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56,
            width: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryYellow, width: 1.2),
              color: primaryYellow.withOpacity(0.25),
            ),
            child: assetPath != null
                ? SvgPicture.asset(
                    assetPath!,
                    height: 24,
                    width: 24,
                    colorFilter: const ColorFilter.mode(
                      Colors.black87,
                      BlendMode.srcIn,
                    ),
                  )
                : Icon(
                    fallbackIcon ?? Icons.help_outline_rounded,
                    color: Colors.black87,
                    size: 24,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _BillingCategory {
  final String title;
  final List<_BillingItem> items;

  const _BillingCategory({required this.title, required this.items});
}

class _BillingItem {
  final String label;
  final String? assetPath;
  final IconData? fallbackIcon;
  final Widget targetScreen;

  const _BillingItem({
    required this.label,
    this.assetPath,
    this.fallbackIcon,
    required this.targetScreen,
  });
}
