import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/widgets/constsize.dart';

class AppBarBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AppBarBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: context.responsive(20)),
      child: GestureDetector(
        onTap: onTap ?? () => Get.back(),
        child: Container(
          padding: EdgeInsets.all(context.responsive(8)),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color.fromRGBO(0, 0, 0, 0.05),
              width: 1.0,
            ),
            color: const Color.fromRGBO(255, 255, 255, 1),
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: context.responsive(16),
          ),
        ),
      ),
    );
  }
}
