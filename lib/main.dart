import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:transwallet/products/Dashboard%20screen/dashboardscreen_view.dart';
import 'package:transwallet/products/Dashboard%20screen/dashboardscreen_binding.dart';
import 'package:transwallet/products/History%20screen/historyscreen_View.dart';
import 'package:transwallet/products/History%20screen/historyscreen_binding.dart';
import 'package:transwallet/products/History%20screen/transactiondetails_View.dart';
import 'package:transwallet/products/Manage%20Card/managecard_View.dart';
import 'package:transwallet/products/Notification%20screen/notification_View.dart';
import 'package:transwallet/products/Order%20Card%20screen/Order%20Details%20Screen/orderDetailsscreen_View.dart';
import 'package:transwallet/products/Order%20Card%20screen/Order%20Details%20Screen/track_card_View.dart';
import 'package:transwallet/products/Order%20Card%20screen/Payment%20Method/payment_Method_View.dart';
import 'package:transwallet/products/Order%20Card%20screen/Review%20order%20Details/review_order_details_View.dart';
import 'package:transwallet/products/Order%20Card%20screen/order%20card%20screen/ordercard_View.dart';
import 'package:transwallet/products/Profile%20screen/Profilescreen_View.dart';
import 'package:transwallet/products/Profile%20screen/profilescreen_binding.dart';
import 'package:transwallet/products/Profile%20screen/change_pin/change_pin_view.dart';
import 'package:transwallet/products/Profile%20screen/change_pin/forgot_pin_view.dart';
import 'package:transwallet/products/Profile%20screen/profile%20details/profile_details_view.dart';
import 'package:transwallet/products/Recharge%20and%20Bills/recharge_bills_screens.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendmoneyProcess_View.dart';
import 'package:transwallet/products/Send%20money%20screen/sendMoney_View.dart';
import 'package:transwallet/products/Wallet%20Screen/Add%20Money/addmoney_View.dart';
import 'package:transwallet/products/Wallet%20Screen/Add%20Money/addmoney_Controller.dart';
import 'package:transwallet/products/Wallet%20Screen/ncmc_topup_view.dart';
import 'package:transwallet/products/Wallet%20Screen/Wallet%20details/walletdetails_View.dart';
import 'package:transwallet/products/Wallet%20Screen/walletscreen_View.dart';
import 'package:transwallet/products/login_singupscreen/create%20Account/createaccount_View.dart';
import 'package:transwallet/products/login_singupscreen/login_singupscreen_View.dart';
import 'package:transwallet/products/minKYCScreen/minkycScreen_View.dart';
import 'package:transwallet/products/splashscreen/splashscreen_view.dart';
import 'package:transwallet/products/update_KYC/update_KYC_View.dart';
import 'package:transwallet/products/Contact%20Support%20screen/contact_Support_screen_View.dart';
import 'package:transwallet/widgets/constsize.dart';
import 'package:transwallet/products/Onboarding Screen/onboardingscreen_View.dart';
import 'package:transwallet/products/Dashboard screen/widgets/services_more_screen.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendMoney_Password_View.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendMoney_Success_View.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendMoney_Receipt_View.dart';

import 'package:transwallet/products/Recharge%20and%20Bills/payment_success_screen.dart'
    as recharge_success;
import 'package:transwallet/products/Dashboard%20screen/widgets/pay_bill_screen.dart';
import 'package:transwallet/products/Dashboard%20screen/widgets/all_cards_screen.dart';
import 'package:transwallet/widgets/pdf_viewer_screen.dart';
import 'package:transwallet/products/minKYCScreen/minkycScreen_Controller.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendmoneyProcess_Controller.dart';
import 'package:transwallet/services/network_service.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/biometric_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/services/firebase_service.dart';
import 'package:transwallet/services/deep_link_service.dart';
import 'package:transwallet/modules/vkyc/bindings/vkyc_binding.dart';
import 'package:transwallet/modules/vkyc/views/vkyc_test_view.dart';
import 'package:transwallet/modules/vkyc/views/vkyc_webview_view.dart';
import 'package:transwallet/widgets/app_lock_overlay.dart';
import 'package:transwallet/widgets/no_internet_overlay.dart';
import 'package:transwallet/widgets/server_error_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:transwallet/products/auth/quick_biometric_login_view.dart';
import 'package:transwallet/products/developer/developer_screen.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(covariant SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  final bootstrapStopwatch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  // Core synchronous service registration (available immediately throughout app)
  Get.put(AuthService());
  Get.put(ApiService());
  final networkService = Get.put(NetworkService());
  final firebaseService = Get.put(FirebaseService());
  final deepLinkService = Get.put(DeepLinkService());
  final biometricService = Get.put(BiometricService());
  final appLockService = Get.put(AppLockService());

  // AppLockService & BiometricService MUST initialize before runApp()
  // so hardware availability, biometric enrollment, and lifecycle observers
  // are ready on frame 1 for cold-start and background protection.
  await appLockService.init();
  await biometricService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  if (kDebugMode) {
    HttpOverrides.global = MyHttpOverrides();
  }

  // Non-blocking concurrent background initialization of heavy network/cloud services
  // This allows the Flutter engine to mount the Splash UI immediately on frame 1
  _initAsyncServices(
    networkService: networkService,
    firebaseService: firebaseService,
    deepLinkService: deepLinkService,
  );

  debugPrint(
    '⚡ [Startup] Synchronous bootstrap finished in ${bootstrapStopwatch.elapsedMilliseconds}ms. Launching runApp()...',
  );
  runApp(const MyApp());
}

void _initAsyncServices({
  required NetworkService networkService,
  required FirebaseService firebaseService,
  required DeepLinkService deepLinkService,
}) {
  unawaited(
    Future.wait([
      networkService.init(),
      firebaseService.init(),
      deepLinkService.init(),
    ]).then((_) {
      debugPrint('✅ [Startup] All background services initialized successfully.');
    }).catchError((e, stack) {
      debugPrint('⚠️ [Startup] Non-blocking service initialization warning: $e');
      return null;
    }),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Transcorp Wallet',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        fontFamily: 'Roboto',
        textTheme: GoogleFonts.robotoTextTheme(),
        primaryTextTheme: GoogleFonts.robotoTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: primaryLightYellow),
        appBarTheme: AppBarTheme(
          toolbarHeight: context.responsive(80),
          backgroundColor: primaryYellow,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark, // Dark icons on Android
            statusBarBrightness: Brightness.light, // Dark text/icons on iOS
          ),
        ),
        datePickerTheme: DatePickerThemeData(
          backgroundColor: Colors.white,
          headerBackgroundColor: primaryRed,
          headerForegroundColor: Colors.white,
          dayForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.black;
            }
            return Colors.black87;
          }),
          dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.black.withValues(alpha: 0.1);
            }
            return null;
          }),
          todayForegroundColor: WidgetStateProperty.all(Colors.black),
          todayBackgroundColor: WidgetStateProperty.all(
            primaryYellow.withValues(alpha: 0.3),
          ),
          yearForegroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.black;
            }
            return Colors.black87;
          }),
          yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.black.withValues(alpha: 0.1);
            }
            return null;
          }),
          confirmButtonStyle: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(Colors.black),
          ),
          cancelButtonStyle: ButtonStyle(
            foregroundColor: WidgetStateProperty.all(Colors.black54),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.black),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: AppLockOverlay(
            child: NoInternetOverlay(
              child: ServerStatusBanner(child: child!),
            ),
          ),
        );
      },
      initialRoute: '/',
      getPages: [
        GetPage(name: '/', page: () => const SplashscreenView()),
        GetPage(
          name: '/onboarding',
          page: () => const OnboardingscreenView(),
          transition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 1000),
        ),
        GetPage(name: '/login', page: () => const LoginSingupscreenView()),
        GetPage(
          name: '/login_singupview',
          page: () => const LoginSingupscreenView(),
        ),
        GetPage(
          name: '/profiledetails',
          page: () => const ProfileDetailsView(),
        ),
        GetPage(name: '/notification', page: () => const NotificationView()),
        GetPage(name: '/minkyc_view', page: () => const MinkycscreenView()),
        GetPage(
          name: '/createaccountview',
          page: () => const CreateaccountView(),
        ),
        GetPage(
          name: '/dashboard',
          page: () => DashboardscreenView(),
          binding: DashboardscreenBinding(),
          transition: Transition.noTransition,
        ),
        GetPage(
          name: '/wallet',
          page: () => const WalletscreenView(),
          transition: Transition.noTransition,
        ),
        GetPage(name: '/walletdetails', page: () => const WalletdetailsView()),
        GetPage(name: '/sendmoney', page: () => const SendmoneyView()),
        GetPage(name: '/updateKyc', page: () => const UpdateKycView()),
        GetPage(
          name: '/history',
          page: () => const HistoryscreenView(),
          binding: HistoryscreenBinding(),
          transition: Transition.noTransition,
        ),
        GetPage(name: '/services', page: () => const ServicesMoreScreen()),
        GetPage(
          name: '/transactiondetails',
          page: () => const TransactiondetailsView(),
        ),
        GetPage(
          name: '/profile',
          page: () => const ProfilescreenView(),
          binding: ProfilescreenBinding(),
          transition: Transition.noTransition,
        ),
        GetPage(name: '/addmoney', page: () => const AddmoneyView()),
        GetPage(name: '/ncmctopup', page: () => const NcmcTopupView()),
        GetPage(name: '/managecard', page: () => const ManagecardView()),
        GetPage(name: '/ordercard', page: () => const OrdercardView()),
        GetPage(
          name: '/orderdetails',
          page: () => const OrderdetailsscreenView(),
        ),
        GetPage(
          name: '/revieworderdetails',
          page: () => const ReviewOrderDetailsView(),
        ),
        GetPage(name: '/paymentmethod', page: () => const PaymentMethodView()),
        GetPage(name: '/trackcard', page: () => const TrackCardView()),
        GetPage(
          name: '/sendmoneyprocess',
          page: () => const SendmoneyprocessView(),
        ),
        GetPage(
          name: '/SendMoneyPasswordView',
          page: () => const SendMoneyPasswordView(),
        ),
        GetPage(
          name: '/SendMoneySuccessView',
          page: () => const SendMoneySuccessView(),
        ),
        GetPage(
          name: '/SendMoneyReceiptView',
          page: () => const SendMoneyReceiptView(),
        ),
        GetPage(
          name: '/contactsupport',
          page: () => const ContactSupportScreenView(),
        ),
        GetPage(name: '/all_cards', page: () => const AllCardsScreen()),
        GetPage(
          name: '/pdf_viewer',
          page: () {
            final args = Get.arguments is Map ? (Get.arguments as Map) : const {};
            return PdfViewerScreen(
              pdfUrl: args['pdfUrl']?.toString() ?? '',
              title: args['title']?.toString() ?? 'Document',
            );
          },
        ),
        GetPage(name: '/create_mpin', page: () => const CreateMpinScreen()),
        GetPage(name: '/change_pin', page: () => const ChangePinView()),
        GetPage(name: '/forgot_pin', page: () => const ForgotPinView()),
        GetPage(
          name: '/payment_processing',
          page: () => const PaymentProcessingScreen(),
        ),
        GetPage(
          name: '/payment_details',
          page: () {
            final args =
                Get.arguments is Map ? (Get.arguments as Map) : const {};
            return PaymentDetailsScreen(
              amount: (args['amount'] as num?)?.toDouble() ??
                  double.tryParse(args['amount']?.toString() ?? '0') ??
                  0.0,
              referenceId: args['referenceId']?.toString(),
              creditedTo: args['creditedTo']?.toString(),
              paymentUsing: args['paymentUsing']?.toString(),
              dateTime: args['dateTime']?.toString(),
              title: args['title']?.toString(),
              isCredit: args['isCredit'] == true,
            );
          },
        ),
        GetPage(
          name: '/payment_after_success',
          page: () {
            final args = Get.arguments is Map ? (Get.arguments as Map) : const {};
            return PaymentafterSuccessScreen(
              amount: (args['amount'] as num?)?.toDouble() ??
                  double.tryParse(args['amount']?.toString() ?? '0') ??
                  0.0,
            );
          },
        ),
        GetPage(
          name: '/payment_success',
          page: () {
            final args = Get.arguments is Map ? (Get.arguments as Map) : const {};
            return recharge_success.PaymentSuccessScreen(
              title: args['title']?.toString() ?? 'Payment Successful',
              message: args['message']?.toString() ?? '',
              amount: (args['amount'] as num?)?.toDouble() ??
                  double.tryParse(args['amount']?.toString() ?? '0') ??
                  0.0,
            );
          },
        ),
        GetPage(
          name: '/payment_receipt',
          page: () {
            final args = Get.arguments is Map ? (Get.arguments as Map) : const {};
            return PaymentReceiptView(
              amount: (args['amount'] as num?)?.toDouble() ?? 0.0,
              balance: (args['balance'] as num?)?.toDouble() ?? 0.0,
              paymentMode: args['paymentMode']?.toString() ?? 'PayU PG',
              status: args['status']?.toString() ?? 'Success',
              txnId: args['txnId']?.toString(),
              transactionReference:
                  args['transactionReference']?.toString() ??
                  args['txnId']?.toString(),
              bankRefNo: args['bankRefNo']?.toString(),
              message: args['message']?.toString(),
            );
          },
        ),
        GetPage(name: '/pay_bill', page: () => const PayBillScreen()),
        GetPage(
          name: '/mobile_recharge',
          page: () => const MobileRechargeScreen(),
        ),
        GetPage(
          name: '/electricity_bill',
          page: () => const ElectricityBillScreen(),
        ),
        GetPage(
          name: '/fastag_recharge',
          page: () => const FastagRechargeScreen(),
        ),
        GetPage(name: '/gas_bill', page: () => const GasBillScreen()),
        GetPage(
          name: '/broadband_bill',
          page: () => const BroadbandBillScreen(),
        ),
        GetPage(name: '/water_bill', page: () => const WaterBillScreen()),
        GetPage(name: '/tuition_fees', page: () => const TuitionFeesScreen()),
        GetPage(
          name: '/profileview',
          page: () => const ProfilescreenView(),
          binding: ProfilescreenBinding(),
        ),
        GetPage(name: '/developer', page: () => const DeveloperScreen()),
        GetPage(
          name: '/vkyc_test',
          page: () => const VkycTestView(),
          binding: VkycBinding(),
        ),
        GetPage(
          name: '/vkyc_webview',
          page: () => const VkycWebviewView(),
          binding: VkycBinding(),
        ),
        GetPage(
          name: '/quick_biometric_login',
          page: () => const QuickBiometricLoginView(),
        ),
        GetPage(
          name: '/dashboardscreen',
          page: () => DashboardscreenView(),
          binding: DashboardscreenBinding(),
          transition: Transition.noTransition,
        ),
        GetPage(
          name: '/profilescreen',
          page: () => const ProfilescreenView(),
          binding: ProfilescreenBinding(),
          transition: Transition.noTransition,
        ),
        GetPage(
          name: '/loginsingup',
          page: () => const LoginSingupscreenView(),
        ),
      ],
    );
  }
}
