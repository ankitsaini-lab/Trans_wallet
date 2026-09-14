import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/utilities/getStorage.dart';

import 'package:transwallet/widgets/constsize.dart';

import 'package:transwallet/services/api_service.dart';

class ProfileDetailsController extends GetxController {
  var profileImage = "assets/Vince Tallent.png".obs;

  RxString name = "".obs;
  RxString email = "".obs;
  RxString phone = "".obs;
  RxString accountverification = "Verified Account".obs;
  RxString address = "".obs;

  @override
  void onInit() {
    super.onInit();
    _loadProfileData();
    _fetchFromApi();
  }

  void _loadProfileData() {
    name.value = box.read('name') ?? "User";
    email.value = box.read('email') ?? "";
    final storedPhone = box.read('phone')?.toString() ?? '';
    phone.value = storedPhone.isNotEmpty ? (storedPhone.startsWith('+') ? storedPhone : "+91 $storedPhone") : "";
    address.value = box.read('address') ?? "";
  }

  Future<void> _fetchFromApi() async {
    if (Get.isRegistered<ApiService>()) {
      final profile = await ApiService.to.fetchUserProfile();
      if (profile != null) {
        _loadProfileData();
      }
    }
  }

  Widget buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: context.responsive(16)),
      padding: EdgeInsets.all(context.responsive(18)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.responsive(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: context.responsive(55),
            width: context.responsive(55),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryRed.withOpacity(.15),
                  primaryRed.withOpacity(.05),
                ],
              ),
              borderRadius: BorderRadius.circular(context.responsive(16)),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF111111),
              size: context.responsive(26),
            ),
          ),

          SizedBox(width: context.responsive(16)),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.responsive(13),
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                SizedBox(height: context.responsive(4)),

                Text(
                  value,
                  style: TextStyle(
                    fontSize: context.responsive(14),
                    fontWeight: FontWeight.w700,
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
