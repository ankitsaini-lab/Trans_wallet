import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:transwallet/products/login_singupscreen/login_singupscreen_Controller.dart';
import 'package:transwallet/services/api_service.dart';
import 'package:transwallet/services/app_lock_service.dart';
import 'package:transwallet/products/Dashboard screen/dashboardscreen_Controller.dart';
import 'package:transwallet/products/Dashboard screen/controllers/wallet_card_controller.dart';
import 'package:transwallet/products/Wallet Screen/walletscreen_Controller.dart';
import 'package:transwallet/products/Notification screen/notification_Controller.dart';
import 'package:transwallet/products/History screen/historyscreen_Controller.dart';
import 'package:transwallet/products/Profile screen/profile details/profile_details_Controller.dart';
import 'package:transwallet/products/Profile screen/profilescreen_Controller.dart';
import 'package:transwallet/products/Send money screen/sendMoney_Controller.dart';
import 'package:transwallet/products/Send money screen/send money process/sendmoneyProcess_Controller.dart';
import 'package:transwallet/products/Send money screen/send money process/sendMoney_Receipt_Controller.dart';
import 'package:transwallet/products/Send money screen/send money process/sendMoney_Success_Controller.dart';
import 'package:transwallet/products/Manage Card/managecard_Controller.dart';
import 'package:transwallet/products/update_KYC/update_KYC_controller.dart';
import 'package:transwallet/products/minKYCScreen/minkycScreen_Controller.dart';
import 'package:transwallet/modules/vkyc/controllers/vkyc_controller.dart';
import 'package:transwallet/products/Wallet Screen/Wallet details/walletdetails_controller.dart';
import 'package:transwallet/products/Wallet Screen/Add Money/addmoney_Controller.dart';
import 'package:transwallet/products/Wallet Screen/addmoneysuccess_Screen/addmoneysuccess_Screen_Controller.dart';
import 'package:transwallet/products/Order Card screen/order card screen/ordercard_Controller.dart';
import 'package:transwallet/products/Order Card screen/Order Details Screen/orderDetailsscreen_Controller.dart';
import 'package:transwallet/products/Order Card screen/proceed order/proceedorder_Controller.dart';
import 'package:transwallet/products/Order Card screen/Review order Details/review_order_details_Controller.dart';
import 'package:transwallet/widgets/globalbottombar/GlobalbottomBar_Controller.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find<AuthService>();

  final GetStorage _storage = GetStorage();

  // Storage Keys
  static const String _keyToken = 'auth_token';
  static const String _keyRefreshToken = 'refreshToken';
  static const String _keyTokenType = 'tokenType';
  static const String _keyExpiresIn = 'expiresIn';
  static const String _keyUserId = 'user_id';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserData = 'user_data';

  /// Complete registry of all user/account specific storage keys that must be wiped
  /// when logging out, session expiring, or switching accounts.
  static const List<String> _userAccountKeys = [
    // Tokens & session authentication
    'auth_token',
    'accessToken',
    'token',
    'refreshToken',
    'refresh_token',
    'tokenType',
    'expiresIn',
    'is_logged_in',
    'user_id',
    'userId',
    'uuid',
    'entityId',
    'providerRef',
    'debugOtp',
    'otpFlow',
    'registrationToken',
    'registration_token',
    'registration_in_progress',
    'registration_flow',
    'pan_verify_registration_token',
    'remember_me',

    // User profile & personal details
    'user_data',
    'name',
    'userName',
    'user_full_name',
    'remembered_name',
    'registeredName',
    'pan_name',
    'title',
    'firstName',
    'middleName',
    'lastName',
    'dob',
    'gender',
    'email',
    'profilePictureUrl',
    'address',
    'addressData',
    'pan',
    'panNumber',
    'document_number',
    'user_mobile',
    'mobileNumber',

    // Registration drafts / wizard steps
    'reg_title',
    'reg_firstName',
    'reg_middleName',
    'reg_lastName',
    'reg_gender',
    'reg_email',
    'reg_dob',
    'reg_hasActivationCode',
    'reg_kitNumber',
    'reg_cardNumber',
    'reg_addressLine1',
    'reg_addressLine2',
    'reg_pincode',
    'reg_country',
    'reg_state',
    'reg_city',
    'kitNumber',
    'hasActivationCode',

    // Financial balances & cards
    'balance',
    'wallet_balance',
    'lienBalance',
    'currency',
    'user_cards',
    'wallet_products',
    'user_status',
    'is_blocked',
    'is_permanently_blocked',
    'is_card_permanently_blocked',
    'is_temporarily_blocked',
    'block_reason',
    'card_activation_date',
    'm2pOtpRequired',
    'upi_id',
    'user_vpa',
    'vpa',
    'upiId',

    // Security & MPIN credentials
    'saved_mpin',
    'remembered_mpin',
    'mpin',
    'tx_pin',
    'has_mpin',
    'mpin_set',
    'mpin_locked_until',
    'mpin_lock_message',
    'app_lock_enabled',
    'app_lock_disabled',
    'pending_app_lock_prompt',
    'pending_biometric_app_lock_prompt',
    'biometric_enabled',
    'biometric_quick_login_enabled',

    // KYC details & status
    'kyc_status',
    'kyc_current_level',
    'full_kyc_completed',
    'is_kyc_completed',
    'min_kyc_completed',
    'is_min_kyc_completed',
    'kyc_data',
    'vkyc_application_id',
    'pending_vkyc_success_dialog',
    'is_vkyc_completed',
    'kyc_reference_id',
    'kyc_entity_id',
    'kyc_document_type',
    'kyc_document_number',

    // Caches, recents & transient upload data
    'recent_w2w_recipients',
    'recent_recipients',
    'recent_transactions',
    'transactions_cache',
    'notifications_cache',
    'notification_unread_count',
    'recovered_camera_image',
    'pending_camera_upload',
    'is_picking_media',
  ];

  /// Initialize the service
  Future<AuthService> init() async {
    return this;
  }

  /// Get the current auth token
  String? get token =>
      _storage.read<String>(_keyToken) ?? _storage.read<String>('accessToken');

  /// Convenience getter for accessToken
  String? get accessToken => token;

  /// Get the current refresh token
  String? get refreshToken =>
      _storage.read<String>(_keyRefreshToken) ??
      _storage.read<String>('refreshToken') ??
      _storage.read<String>('refresh_token');

  /// Get token type (defaults to Bearer)
  String get tokenType =>
      _storage.read<String>(_keyTokenType) ??
      _storage.read<String>('tokenType') ??
      'Bearer';

  /// Get token expiration in seconds
  dynamic get expiresIn =>
      _storage.read(_keyExpiresIn) ?? _storage.read('expiresIn');

  /// Get the current user ID
  String? get userId => _storage.read<String>(_keyUserId);

  /// Check if user is logged in
  bool get isLoggedIn => _storage.read<bool>(_keyIsLoggedIn) ?? false;

  /// Global lock flag preventing duplicate or trailing calls during logout
  bool _isLoggingOut = false;
  bool get isLoggingOut => _isLoggingOut;
  set isLoggingOut(bool value) => _isLoggingOut = value;

  /// Save session details
  Future<void> saveSession({
    required String token,
    String? refreshToken,
    String? tokenType,
    dynamic expiresIn,
    required String userId,
    Map<String, dynamic>? userData,
  }) async {
    _isLoggingOut = false;
    if (Get.isRegistered<ApiService>()) {
      ApiService.to.setLoggingOut(false);
    }
    await _storage.write(_keyToken, token);
    await _storage.write('accessToken', token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(_keyRefreshToken, refreshToken);
      await _storage.write('refreshToken', refreshToken);
    }
    if (tokenType != null && tokenType.isNotEmpty) {
      await _storage.write(_keyTokenType, tokenType);
    }
    if (expiresIn != null) {
      await _storage.write(_keyExpiresIn, expiresIn);
    }
    await _storage.write(_keyUserId, userId);
    await _storage.write(_keyIsLoggedIn, true);
    final bool wasAppLockActive =
        (_storage.read<bool>('app_lock_enabled') == true) &&
        (_storage.read<bool>('app_lock_disabled') != true);
    await _storage.write('app_lock_enabled', wasAppLockActive);
    if (!wasAppLockActive) {
      await _storage.write('app_lock_disabled', true);
    }
    if (userData != null) {
      await _storage.write(_keyUserData, userData);
      if (userData['name'] != null && userData['name'].toString().isNotEmpty) {
        await _storage.write('name', userData['name']);
        await _storage.write('remembered_name', userData['name']);
      }
      if (userData['phone'] != null && userData['phone'].toString().isNotEmpty) {
        await _storage.write('phone', userData['phone']);
        await _storage.write('remembered_phone', userData['phone']);
      }
    }
    if (userId.isNotEmpty) {
      await _storage.write('remembered_phone', userId);
    }
    if (Get.isRegistered<ApiService>()) {
      ApiService.to.resetLogoutState();
    }
  }

  /// Update tokens after refresh
  Future<void> updateTokens({
    required String accessToken,
    String? refreshToken,
    String? tokenType,
    dynamic expiresIn,
  }) async {
    await _storage.write(_keyToken, accessToken);
    await _storage.write('accessToken', accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(_keyRefreshToken, refreshToken);
      await _storage.write('refreshToken', refreshToken);
    }
    if (tokenType != null && tokenType.isNotEmpty) {
      await _storage.write(_keyTokenType, tokenType);
    }
    if (expiresIn != null) {
      await _storage.write(_keyExpiresIn, expiresIn);
    }
  }

  /// Retrieve saved user data
  Map<String, dynamic>? get userData {
    final data = _storage.read(_keyUserData);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  /// Update single user data field
  Future<void> updateUserDataField(String key, dynamic value) async {
    final current = userData ?? {};
    current[key] = value;
    await _storage.write(_keyUserData, current);
  }

  /// Completely clears all user-specific data from storage, resets in-memory API caches,
  /// resets AppLock, and deletes all active GetX controllers so no cross-account state leaks.
  Future<void> clearAllUserDataAndCache({bool keepRememberedPhone = false}) async {
    final String? preservedPhone = keepRememberedPhone
        ? (_storage.read<String>('remembered_phone') ??
           _storage.read<String>('phone') ??
           _storage.read<String>('mobileNumber'))
        : null;

    developer.log(
      '[AuthService] Purging all user data & cache (keepRememberedPhone: $keepRememberedPhone)',
    );

    // 1. Wipe all user account keys from GetStorage
    for (final key in _userAccountKeys) {
      await _storage.remove(key);
    }

    // 2. Handle remembered phone
    if (keepRememberedPhone &&
        preservedPhone != null &&
        preservedPhone.trim().isNotEmpty) {
      await _storage.write('remembered_phone', preservedPhone.trim());
      await _storage.write('phone', preservedPhone.trim());
    } else {
      await _storage.remove('phone');
      await _storage.remove('remembered_phone');
    }

    // Explicitly record logged out state and disable app lock
    await _storage.write(_keyIsLoggedIn, false);
    await _storage.write('app_lock_enabled', false);
    await _storage.write('app_lock_disabled', true);

    // 3. Reset in-memory API service caches
    if (Get.isRegistered<ApiService>()) {
      ApiService.to.clearAllCaches();
    }

    // 4. Reset AppLockService
    if (Get.isRegistered<AppLockService>()) {
      AppLockService.to.resetForLogout();
    }

    // 5. Purge and delete all user-related GetX controllers
    _purgeInMemoryControllers();
  }

  /// Purges in-memory state and force deletes registered GetX controllers
  void _purgeInMemoryControllers() {
    try {
      if (Get.isRegistered<DashboardscreenController>()) {
        Get.find<DashboardscreenController>().clearAllDashboardState();
        Get.delete<DashboardscreenController>(force: true);
      }
      if (Get.isRegistered<WalletCardController>()) {
        Get.find<WalletCardController>().clear();
        Get.delete<WalletCardController>(force: true);
      }
      if (Get.isRegistered<WalletscreenController>()) {
        Get.find<WalletscreenController>().clear();
        Get.delete<WalletscreenController>(force: true);
      }
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().clear();
        Get.delete<NotificationController>(force: true);
      }
      if (Get.isRegistered<HistoryscreenController>()) {
        Get.find<HistoryscreenController>().clear();
        Get.delete<HistoryscreenController>(force: true);
      }
      if (Get.isRegistered<ProfileDetailsController>()) {
        Get.find<ProfileDetailsController>().clear();
        Get.delete<ProfileDetailsController>(force: true);
      }
      if (Get.isRegistered<ProfilescreenController>()) {
        Get.find<ProfilescreenController>().clear();
        Get.delete<ProfilescreenController>(force: true);
      }
      if (Get.isRegistered<SendmoneyController>()) {
        Get.delete<SendmoneyController>(force: true);
      }
      if (Get.isRegistered<SendmoneyprocessController>()) {
        Get.delete<SendmoneyprocessController>(force: true);
      }
      if (Get.isRegistered<SendMoneyReceiptController>()) {
        Get.delete<SendMoneyReceiptController>(force: true);
      }
      if (Get.isRegistered<SendMoneySuccessController>()) {
        Get.delete<SendMoneySuccessController>(force: true);
      }
      if (Get.isRegistered<ManagecardController>()) {
        Get.delete<ManagecardController>(force: true);
      }
      if (Get.isRegistered<UpdateKycController>()) {
        Get.delete<UpdateKycController>(force: true);
      }
      if (Get.isRegistered<MinkycscreenController>()) {
        Get.delete<MinkycscreenController>(force: true);
      }
      if (Get.isRegistered<VkycController>()) {
        Get.delete<VkycController>(force: true);
      }
      if (Get.isRegistered<WalletdetailsController>()) {
        Get.delete<WalletdetailsController>(force: true);
      }
      if (Get.isRegistered<AddmoneyController>()) {
        Get.delete<AddmoneyController>(force: true);
      }
      if (Get.isRegistered<AddmoneysuccessScreenController>()) {
        Get.delete<AddmoneysuccessScreenController>(force: true);
      }
      if (Get.isRegistered<OrdercardController>()) {
        Get.delete<OrdercardController>(force: true);
      }
      if (Get.isRegistered<OrderdetailsscreenController>()) {
        Get.delete<OrderdetailsscreenController>(force: true);
      }
      if (Get.isRegistered<ProceedorderController>()) {
        Get.delete<ProceedorderController>(force: true);
      }
      if (Get.isRegistered<ReviewOrderDetailsController>()) {
        Get.delete<ReviewOrderDetailsController>(force: true);
      }
      if (Get.isRegistered<GlobalbottombarController>()) {
        Get.delete<GlobalbottombarController>(force: true);
      }
    } catch (e) {
      developer.log('[AuthService] Error purging in-memory controllers: $e');
    }
  }

  /// Clear session / Logout.
  Future<void> logout({bool navigateToLogin = true}) async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    developer.log('[AuthService] logout initiated (navigateToLogin: $navigateToLogin)');

    if (Get.isRegistered<ApiService>()) {
      ApiService.to.setLoggingOut(true);
    }

    try {
      // 1. Close any overlays, popups, dialogs, bottom sheets
      if (Get.isDialogOpen ?? false) {
        Get.until((route) => !(Get.isDialogOpen ?? false));
      }
      if (Get.isBottomSheetOpen ?? false) {
        Get.until((route) => !(Get.isBottomSheetOpen ?? false));
      }
      if (Get.isOverlaysOpen) {
        Get.back(closeOverlays: true);
      }
      if (Get.isRegistered<LoginSingupscreenController>()) {
        Get.find<LoginSingupscreenController>().closeOtpPopupOnly();
      }

      // 2. Persist logged out state in storage
      await _storage.write('app_lock_enabled', false);
      await _storage.write('app_lock_disabled', true);
      await _storage.write(_keyIsLoggedIn, false);

      // 3. Navigate to login view immediately so underlying screens unmount before dismissing lock overlay
      if (navigateToLogin) {
        final currentRoute = Get.currentRoute;
        if (currentRoute != '/login_singupview') {
          Get.offAllNamed('/login_singupview');
        }
      }

      // 4. Reset AppLock state so lock overlay is dismissed after navigating
      if (Get.isRegistered<AppLockService>()) {
        AppLockService.to.resetForLogout();
        AppLockService.to.setAppLockEnabled(false);
      }

      // 5. Clear all user data, storage keys, API caches, and purge in-memory controllers
      await clearAllUserDataAndCache(keepRememberedPhone: true);
    } catch (e) {
      developer.log('[AuthService] Error during logout: $e');
    } finally {
      // Keep isLoggingOut true for 1.5s to absorb trailing unmounting frames, then reset
      Future.delayed(const Duration(milliseconds: 1500), () {
        _isLoggingOut = false;
        if (Get.isRegistered<ApiService>()) {
          ApiService.to.setLoggingOut(false);
        }
        developer.log('[AuthService] Logout completed, isLoggingOut reset to false');
      });
    }
  }
}
