import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:transwallet/products/splashscreen/splashscreen_Controller.dart';

class SplashscreenView extends StatelessWidget {
  const SplashscreenView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    final controller = Get.isRegistered<SplashscreenController>()
        ? Get.find<SplashscreenController>()
        : Get.put(SplashscreenController());

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Static Brand Splash (Rendered immediately on Frame 1, zero wait/spinner)
          Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: Image.asset(
              'assets/WHITE TRANSCORP .png',
              width: 220,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),

          // 2. Video Player Layer (Smoothly fades in once decoded and playing)
          Obx(() {
            final isReady = controller.isVideoInitialized.value;
            final player = controller.videoController;

            if (!isReady || player == null || !player.value.isInitialized) {
              return const SizedBox.shrink();
            }

            return AnimatedOpacity(
              opacity: isReady ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeIn,
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: player.value.size.width,
                    height: player.value.size.height,
                    child: VideoPlayer(player),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
