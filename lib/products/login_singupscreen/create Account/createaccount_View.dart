import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/products/login_singupscreen/create%20Account/createaccount_Controller.dart';

class CreateaccountView extends GetView<CreateaccountController> {
  const CreateaccountView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => CreateaccountController());
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: lightprimaryred,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.white,
              expandedHeight:
                  MediaQuery.of(context).size.height * 0.35 +
                  (222 + topPadding),
              collapsedHeight: 222 + topPadding,
              toolbarHeight: 0,
              pinned: true,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final collapsedHeight = 222 + topPadding;
                  final expandedHeight =
                      MediaQuery.of(context).size.height * 0.35 +
                      collapsedHeight;
                  double expansion = 1.0;
                  if (expandedHeight > collapsedHeight) {
                    expansion =
                        (constraints.maxHeight - collapsedHeight) /
                        (expandedHeight - collapsedHeight);
                    expansion = expansion.clamp(0.0, 1.0);
                  }
                  double curveRadius = 28 * expansion;

                  return Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: MediaQuery.of(context).size.height * 0.47,
                        child: Image.asset(
                          "assets/createaccountbg.png",
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.elliptical(300, curveRadius),
                          ),
                          child: Container(
                            width: double.infinity,
                            color: Colors.white,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: topPadding * (1.0 - expansion),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  "Create Account",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Step into simpler payments",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                // Custom Stepper
                                controller.buildCustomStepper(context),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Obx(
                  () => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: controller.step.value == 1
                        ? controller.buildStepOene(context)
                        : controller.buildStepTwo(context),
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
