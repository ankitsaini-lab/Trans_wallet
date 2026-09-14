import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:transwallet/widgets/custombutton.dart';
import 'package:confetti/confetti.dart';

class UpdateKycController extends GetxController {
  var isRedirecting = false.obs;
  var redirectionStatus = "Initializing secure connection...".obs;
  var redirectionProgress = 0.0.obs;
  Timer? _redirectTimer;

  void startBrowserRedirection() {
    isRedirecting.value = true;
    redirectionProgress.value = 0.0;
    redirectionStatus.value = "Opening secure browser session...";

    _redirectTimer?.cancel();

    int elapsed = 0;
    _redirectTimer = Timer.periodic(const Duration(milliseconds: 1000), (
      timer,
    ) {
      elapsed++;
      redirectionProgress.value = (elapsed / 6) * 1.0;

      if (elapsed == 1) {
        redirectionStatus.value = "Launching secure KYC partner portal...";
      } else if (elapsed == 3) {
        redirectionStatus.value =
            "Awaiting verification completion on browser...";
      } else if (elapsed == 5) {
        redirectionStatus.value =
            "Biometric check & document signatures verified!";
      } else if (elapsed >= 6) {
        timer.cancel();
        isRedirecting.value = false;
        showKycSuccessPopup();
      }
    });
  }

  late ConfettiController confettiController = ConfettiController(
    duration: const Duration(seconds: 10),
  );

  void playAnimation() {
    confettiController.play();
  }

  @override
  void onClose() {
    _redirectTimer?.cancel();
    confettiController.dispose();
    super.onClose();
  }

  void showKycSuccessPopup() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: true,
                  numberOfParticles: 40,
                  emissionFrequency: 0.08,
                  maxBlastForce: 25,
                  minBlastForce: 10,
                  gravity: 0.2,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.orange,
                    Colors.purple,
                    Colors.red,
                    Colors.yellow,
                    Colors.pink,
                    Colors.cyan,
                    Colors.teal,
                    Colors.amber,
                    Colors.indigo,
                    Colors.lime,
                    Color(0xFF00E5FF),
                    Color(0xFFFF4081),
                    Color(0xFFFFD740),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: Colors.green, size: 60),
                  const SizedBox(height: 10),
                  const Text(
                    "Congratulations 🎉",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Your Full KYC is Successfully Completed.\nYou can now enjoy all features!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: "Go to Dashboard",
                    btncolor: Colors.black,
                    onPressed: () {
                      Get.back();
                      Get.offAllNamed("/dashboard");
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
    playAnimation();
  }
}
