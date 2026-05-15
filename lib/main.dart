import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/Dashboard%20screen/dashboardscreen_view.dart';
import 'package:transwallet/products/History%20screen/historyscreen_View.dart';
import 'package:transwallet/products/Manage%20Card/managecard_View.dart';
import 'package:transwallet/products/Notification%20screen/notification_View.dart';
import 'package:transwallet/products/Order%20Card%20screen/Order%20Details%20Screen/orderDetailsscreen_View.dart';
import 'package:transwallet/products/Order%20Card%20screen/Payment%20Method/payment_Method_View.dart';
import 'package:transwallet/products/Order%20Card%20screen/Review%20order%20Details/review_order_details_View.dart';
import 'package:transwallet/products/Order%20Card%20screen/order%20card%20screen/ordercard_View.dart';
import 'package:transwallet/products/Profile%20screen/Profilescreen_View.dart';
import 'package:transwallet/products/Profile%20screen/profile%20details/profile_details_view.dart';
import 'package:transwallet/products/Send%20money%20screen/send%20money%20process/sendmoneyProcess_View.dart';
import 'package:transwallet/products/Send%20money%20screen/sendMoney_View.dart';
import 'package:transwallet/products/Wallet%20Screen/Add%20Money/addmoney_View.dart';
import 'package:transwallet/products/Wallet%20Screen/Wallet%20details/walletdetails_View.dart';
import 'package:transwallet/products/Wallet%20Screen/walletscreen_View.dart';
import 'package:transwallet/products/login_singupscreen/create%20Account/createaccount_View.dart';
import 'package:transwallet/products/login_singupscreen/login_singupscreen_View.dart';
import 'package:transwallet/products/minKYCScreen/minkycScreen_View.dart';
import 'package:transwallet/products/splashscreen/splashscreen_view.dart';
import 'package:transwallet/products/update_KYC/update_KYC_View.dart';
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
Future<void> main() async {
  await GetStorage.init();
   HttpOverrides.global = MyHttpOverrides();
   WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Trans Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
      
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
       builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
          child: child!,
        );
      },
      initialRoute: '/',
   getPages: [
  GetPage(
    name: '/',
    page: () => const SplashscreenView(),
  ),
  GetPage(
    name: '/login_singupview',
    page: () => const LoginSingupscreenView(),
  ),
  GetPage(
    name: '/profiledetails',
    page: () => const ProfileDetailsView(),
  ),
  GetPage(
    name: '/notification',
    page: () => const NotificationView(),
  ),
  GetPage(
    name: '/minkyc_view',
    page: () => const MinkycscreenView(),
  ),
  GetPage(
    name: '/createaccountview',
    page: () => const CreateaccountView(),
  ),
  GetPage(
    name: '/dashboard',
    page: () => const DashboardscreenView(),
  ),
  GetPage(
    name: '/wallet',
    page: () => const WalletscreenView(),
  ),
  GetPage(
    name: '/walletdetails',
    page: () => const WalletdetailsView(),
  ),
  GetPage(
    name: '/sendmoney',
    page: () => const SendmoneyView(),
  ),
  GetPage(
    name: '/updateKyc',
    page: () => const UpdateKycView(),
  ),
  GetPage(
    name: '/history',
    page: () => const HistoryscreenView(),
  ),
  GetPage(
    name: '/profile',
    page: () => const ProfilescreenView(),
  ),
  GetPage(
    name: '/addmoney',
    page: () => const AddmoneyView(),
  ),
  GetPage(
    name: '/managecard',
    page: () => const ManagecardView(),
  ),
  GetPage(
    name: '/ordercard',
    page: () => const OrdercardView(),
  ),
  GetPage(
    name: '/orderdetails',
    page: () => const OrderdetailsscreenView(),
  ),
  GetPage(
    name: '/revieworderdetails',
    page: () => const ReviewOrderDetailsView(),
  ),
  GetPage(
    name: '/paymentmethod',
    page: () => const PaymentMethodView(),
  ),
  GetPage(
    name: '/sendmoneyprocess',
    page: () => const SendmoneyprocessView(),
  ),
],
      
    );
  }
}

//////git setup done