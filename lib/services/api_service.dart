import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/services/firebase_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

/// Result object for profile picture upload operations
class ProfilePictureUploadResult {
  final bool isSuccess;
  final String? url;
  final String? errorMessage;

  ProfilePictureUploadResult({
    required this.isSuccess,
    this.url,
    this.errorMessage,
  });
}

/// Result object for MPIN verification operations against the backend API
class MpinVerifyResponse {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic>? data;

  const MpinVerifyResponse({
    required this.isSuccess,
    this.message = '',
    this.data,
  });
}

/// Service to handle all HTTP API network requests using GetConnect
class ApiService extends GetConnect {
  static ApiService get to => Get.find<ApiService>();

  // Default config
  final String _defaultBaseUrl = 'https://devapitcapp.transcorpint.com';
  // final String _defaultBaseUrl = 'http://192.168.1.202:3001';
  final Duration _defaultTimeout = const Duration(seconds: 30);

  // Mutex to prevent multiple concurrent token refresh calls
  Completer<bool>? _refreshCompleter;

  // Global Server Health Observables
  final RxBool isServerDown = false.obs;
  final RxBool isCheckingServerHealth = false.obs;
  final RxString serverErrorMessage = ''.obs;
  final RxInt lastServerErrorCode = 200.obs;
  final RxBool isBannerDismissed = false.obs;

  int _consecutiveServerFailures = 0;
  DateTime? _lastServerErrorAlertTime;

  @override
  void onInit() {
    // Read saved custom base URL if configured, otherwise fallback to default
    final savedBaseUrl = GetStorage().read<String>('api_base_url');
    if (savedBaseUrl == null ||
        savedBaseUrl.trim().isEmpty ||
        savedBaseUrl.contains('192.168.') ||
        savedBaseUrl.contains('localhost')) {
      GetStorage().write('api_base_url', _defaultBaseUrl);
      httpClient.baseUrl = _defaultBaseUrl;
    } else {
      httpClient.baseUrl = savedBaseUrl.trim();
    }
    httpClient.timeout = _defaultTimeout;

    // 1. Request Interceptor
    httpClient.addRequestModifier<dynamic>((request) {
      final path = request.url.path;
      final hasMultipart = request.headers.entries.any(
        (e) =>
            e.key.toLowerCase() == 'content-type' &&
            e.value.contains('multipart'),
      );

      if (hasMultipart) {
        // Keep the multipart/form-data boundary header intact
        request.headers.removeWhere(
          (k, v) =>
              k.toLowerCase() == 'content-type' && !v.contains('multipart'),
        );
      } else {
        final hasContentType = request.headers.keys.any(
          (k) => k.toLowerCase() == 'content-type',
        );
        if (!hasContentType) {
          request.headers['Content-Type'] = 'application/json';
        }
      }
      request.headers['Accept'] ??= '*/*';

      final isAuthRefresh =
          path.endsWith('/auth/refresh') || path.contains('/auth/refresh');

      // Automatically attach Bearer token if available and not already provided
      // Skip attaching expired token for refresh requests
      if (!isAuthRefresh && !request.headers.containsKey('Authorization')) {
        String? token;
        if (Get.isRegistered<AuthService>()) {
          token = AuthService.to.token;
        }
        token ??=
            GetStorage().read<String>('accessToken') ??
            GetStorage().read<String>('auth_token') ??
            GetStorage().read<String>('token') ??
            GetStorage().read<String>('registrationToken');
        if (token != null && token.isNotEmpty) {
          final tokenType =
              (Get.isRegistered<AuthService>()
                  ? AuthService.to.tokenType
                  : null) ??
              GetStorage().read<String>('tokenType') ??
              'Bearer';
          request.headers['Authorization'] = '$tokenType $token';
        }
      }

      // Logging request details
      developer.log('[API Request] ${request.method} -> ${request.url}');
      developer.log('[API Request Headers] ${request.headers}');
      return request;
    });

    // 2. Response Interceptor
    httpClient.addResponseModifier<dynamic>((request, response) {
      developer.log('[API Response] ${response.statusCode} <- ${request.url}');

      if (response.hasError) {
        developer.log(
          '[API Error] Status: ${response.statusCode}, Body: ${response.body}',
        );

        final path = request.url.path;
        final isAuthRefresh =
            path.endsWith('/auth/refresh') || path.contains('/auth/refresh');

        // If 401 on refresh request itself, refresh token is invalid/expired
        if (response.statusCode == 401 && isAuthRefresh) {
          developer.log(
            '[API Refresh Rejected] Refresh token expired or rejected. Terminating session...',
          );
          _handleSessionExpired();
        } else {
          // Track and manage server side errors (5xx, connection issues)
          final int? statusCode = response.statusCode;
          final bool is5xx =
              statusCode != null && statusCode >= 500 && statusCode <= 599;
          final bool isConnectionIssue =
              statusCode == null ||
              statusCode == 0 ||
              response.status.connectionError;

          if (is5xx || isConnectionIssue) {
            _handleServerError(request, response);
          }
        }
      } else {
        // Successful response: reset server error state
        _handleServerSuccess();
      }
      return response;
    });

    super.onInit();
  }

  void _handleServerError(dynamic request, Response response) {
    final int? statusCode = response.statusCode;
    final bool is5xx =
        statusCode != null && statusCode >= 500 && statusCode <= 599;

    _consecutiveServerFailures++;
    lastServerErrorCode.value = statusCode ?? 0;

    String msg;
    if (statusCode == 503) {
      msg = "Server is under maintenance. Please try again shortly.";
    } else if (statusCode == 502 || statusCode == 504) {
      msg = "Server gateway timeout. Please try again in a few moments.";
    } else if (is5xx) {
      msg = "Server error ($statusCode). Our team is working on it.";
    } else {
      msg = "Unable to connect to server. Please check connection.";
    }

    serverErrorMessage.value = msg;

    // If 2 or more consecutive failures (or immediate 503/502), mark server as down
    if (_consecutiveServerFailures >= 2 ||
        statusCode == 503 ||
        statusCode == 502) {
      if (!isServerDown.value) {
        isServerDown.value = true;
        isBannerDismissed.value = false;
      }
    }

    // Debounce snackbar alert so user is not spammed by parallel requests
    final now = DateTime.now();
    if (_lastServerErrorAlertTime == null ||
        now.difference(_lastServerErrorAlertTime!) >
            const Duration(seconds: 8)) {
      _lastServerErrorAlertTime = now;
      AppSnackbar.serverError(message: msg, statusCode: statusCode);
    }
  }

  void _handleServerException(String path, dynamic exception) {
    _consecutiveServerFailures++;
    final String errorStr = exception.toString().toLowerCase();
    String msg = "Unable to connect to server.";
    if (errorStr.contains('timeout')) {
      msg = "Connection timed out while reaching server.";
    } else if (errorStr.contains('socket') ||
        errorStr.contains('connection refused')) {
      msg = "Server is unreachable. Please try again shortly.";
    }
    serverErrorMessage.value = msg;

    if (_consecutiveServerFailures >= 2) {
      if (!isServerDown.value) {
        isServerDown.value = true;
        isBannerDismissed.value = false;
      }
    }

    final now = DateTime.now();
    if (_lastServerErrorAlertTime == null ||
        now.difference(_lastServerErrorAlertTime!) >
            const Duration(seconds: 8)) {
      _lastServerErrorAlertTime = now;
      AppSnackbar.serverError(message: msg);
    }
  }

  void _handleServerSuccess() {
    _consecutiveServerFailures = 0;
    if (isServerDown.value) {
      isServerDown.value = false;
      serverErrorMessage.value = '';
      lastServerErrorCode.value = 200;
      isBannerDismissed.value = false;
    }
  }

  /// Active ping check to verify if the server is back online
  Future<bool> checkServerHealth() async {
    if (isCheckingServerHealth.value) return !isServerDown.value;
    isCheckingServerHealth.value = true;
    try {
      final response = await get('/').timeout(const Duration(seconds: 6));
      final int? code = response.statusCode;
      if (code != null && code < 500) {
        _handleServerSuccess();
        AppSnackbar.success("Server connection restored!");
        return true;
      }
    } catch (_) {
      try {
        final response = await get(
          '/api/v1/health',
        ).timeout(const Duration(seconds: 6));
        final int? code = response.statusCode;
        if (code != null && code < 500) {
          _handleServerSuccess();
          AppSnackbar.success("Server connection restored!");
          return true;
        }
      } catch (_) {}
    } finally {
      isCheckingServerHealth.value = false;
    }

    AppSnackbar.serverError(
      message: "Server is still unreachable. Please try again later.",
      statusCode: lastServerErrorCode.value > 0
          ? lastServerErrorCode.value
          : null,
    );
    return false;
  }

  /// Update the base URL dynamically if needed and persist in storage
  void updateBaseUrl(String newUrl) {
    httpClient.baseUrl = newUrl.trim();
    GetStorage().write('api_base_url', newUrl.trim());
  }

  /// Refreshes the auth token by calling POST /api/v1/auth/refresh
  /// with { "refreshToken": string }.
  /// Returns true if refreshed successfully, false otherwise.
  Future<bool> refreshToken({String? customRefreshToken}) async {
    // If a refresh is already underway, wait for it to finish
    if (_refreshCompleter != null) {
      developer.log(
        '[Auth Refresh] Refresh already in progress. Awaiting existing request...',
      );
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final success = await _performRefreshToken(
        customRefreshToken: customRefreshToken,
      );
      _refreshCompleter!.complete(success);
      return success;
    } catch (e) {
      developer.log('[Auth Refresh] Exception in refreshToken(): $e');
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<bool> _performRefreshToken({String? customRefreshToken}) async {
    final box = GetStorage();
    String? tokenToUse = customRefreshToken;

    if (tokenToUse == null || tokenToUse.trim().isEmpty) {
      if (Get.isRegistered<AuthService>()) {
        tokenToUse = AuthService.to.refreshToken;
      }
      tokenToUse ??=
          box.read<String>('refreshToken') ?? box.read<String>('refresh_token');
    }

    if (tokenToUse == null || tokenToUse.trim().isEmpty) {
      developer.log(
        '[Auth Refresh] No refreshToken available in storage or arguments.',
      );
      _handleSessionExpired();
      return false;
    }

    developer.log(
      '[Auth Refresh] Calling /api/v1/auth/refresh with refreshToken: $tokenToUse',
    );

    try {
      final response = await post<Map<String, dynamic>>(
        '/api/v1/auth/refresh',
        {"refreshToken": tokenToUse.trim()},
        headers: {'Content-Type': 'application/json', 'Accept': '*/*'},
      );

      developer.log(
        '[Auth Refresh] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';

        if (isSuccess && body['data'] != null && body['data'] is Map) {
          final data = body['data'] as Map;
          final newAccessToken = data['accessToken']?.toString();
          final newRefreshToken = data['refreshToken']?.toString();
          final tokenType = data['tokenType']?.toString() ?? 'Bearer';
          final expiresIn = data['expiresIn'];

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            // Persist fresh tokens
            box.write('auth_token', newAccessToken);
            box.write('accessToken', newAccessToken);
            box.write('token', newAccessToken);

            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              box.write('refreshToken', newRefreshToken);
              box.write('refresh_token', newRefreshToken);
            }

            if (expiresIn != null) {
              box.write('expiresIn', expiresIn);
            }
            box.write('tokenType', tokenType);

            if (Get.isRegistered<AuthService>()) {
              await AuthService.to.updateTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
                tokenType: tokenType,
                expiresIn: expiresIn,
              );
            }

            developer.log(
              '[Auth Refresh] Tokens refreshed successfully. Fresh accessToken and refreshToken saved.',
            );
            return true;
          }
        }
      }

      developer.log(
        '[Auth Refresh] Refresh endpoint returned unsuccessful response: ${response.body}',
      );
      _handleSessionExpired();
      return false;
    } catch (e) {
      developer.log(
        '[Auth Refresh] Error during token refresh network call: $e',
      );
      _handleSessionExpired();
      return false;
    }
  }

  void _handleSessionExpired() {
    if (Get.isRegistered<AuthService>() && AuthService.to.isLoggedIn) {
      final currentRoute = Get.currentRoute;
      final isAuthOrKycFlow =
          currentRoute.contains('login') ||
          currentRoute.contains('kyc') ||
          currentRoute.contains('otp') ||
          currentRoute.contains('createaccount');

      AuthService.to.logout();
      if (!isAuthOrKycFlow) {
        Get.offAllNamed('/login_singupview');
        AppSnackbar.error('Session expired. Please login again.');
      }
    }
  }

  bool _isUnauthorized(
    Response response,
    String path,
    Map<String, String>? headers,
  ) {
    // Avoid refreshing on authentication/registration endpoints
    if (path.contains('/auth/refresh') ||
        path.contains('/auth/otp') ||
        path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/pan')) {
      return false;
    }

    // If retry already attempted, do not enter infinite loop
    if (headers?['X-Retry-Attempted'] == 'true' ||
        response.request?.headers.containsKey('X-Retry-Attempted') == true) {
      return false;
    }

    if (response.statusCode == 401) {
      return true;
    }

    if (response.body is Map) {
      final body = response.body as Map;
      final code = body['code']?.toString().toUpperCase();
      final message = body['message']?.toString().toLowerCase() ?? '';
      if (code == 'UNAUTHORIZED' ||
          (code == 'HTTP_ERROR' && message.contains('unauthorized')) ||
          message.contains('token expired') ||
          message.contains('jwt expired')) {
        return true;
      }
    }
    return false;
  }

  Future<Response<T>> _executeWithRetry<T>(
    String path,
    Future<Response<T>> Function(Map<String, String>? activeHeaders) call, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await call(headers);

      if (_isUnauthorized(response, path, headers)) {
        developer.log(
          '[API Retry] Received 401 for $path. Triggering token refresh...',
        );
        final refreshed = await refreshToken();
        if (refreshed) {
          final freshToken =
              AuthService.to.token ??
              GetStorage().read<String>('accessToken') ??
              GetStorage().read<String>('auth_token');

          final tokenType =
              (Get.isRegistered<AuthService>()
                  ? AuthService.to.tokenType
                  : null) ??
              GetStorage().read<String>('tokenType') ??
              'Bearer';

          final retryHeaders = Map<String, String>.from(headers ?? {});
          if (freshToken != null && freshToken.isNotEmpty) {
            retryHeaders['Authorization'] = '$tokenType $freshToken';
          }
          retryHeaders['X-Retry-Attempted'] = 'true';

          developer.log(
            '[API Retry] Retrying $path with fresh access token...',
          );
          return await call(retryHeaders);
        }
      }

      return response;
    } catch (e) {
      developer.log('[API Exception] Error executing $path: $e');
      _handleServerException(path, e);
      return Response<T>(statusCode: 500, statusText: 'Internal exception: $e');
    }
  }

  /// Overridden request method to handle 401 token refresh for any direct request calls
  @override
  Future<Response<T>> request<T>(
    String url,
    String method, {
    dynamic body,
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) async {
    final response = await super.request<T>(
      url,
      method,
      body: body,
      contentType: contentType,
      headers: headers,
      query: query,
      decoder: decoder,
      uploadProgress: uploadProgress,
    );

    if (_isUnauthorized(response, url, headers)) {
      developer.log(
        '[API Retry] Received 401 in request() for $url. Triggering refreshToken()...',
      );
      final refreshed = await refreshToken();
      if (refreshed) {
        final freshToken =
            AuthService.to.token ??
            GetStorage().read<String>('accessToken') ??
            GetStorage().read<String>('auth_token');

        final tokenType =
            (Get.isRegistered<AuthService>()
                ? AuthService.to.tokenType
                : null) ??
            GetStorage().read<String>('tokenType') ??
            'Bearer';

        final retryHeaders = Map<String, String>.from(headers ?? {});
        if (freshToken != null && freshToken.isNotEmpty) {
          retryHeaders['Authorization'] = '$tokenType $freshToken';
        }
        retryHeaders['X-Retry-Attempted'] = 'true';

        return super.request<T>(
          url,
          method,
          body: body,
          contentType: contentType,
          headers: retryHeaders,
          query: query,
          decoder: decoder,
          uploadProgress: uploadProgress,
        );
      }
    }
    return response;
  }

  /// Core HTTP Methods wrapped with automatic token refresh on 401

  /// GET Request
  Future<Response<T>> getRequest<T>(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) {
    return _executeWithRetry<T>(
      path,
      (activeHeaders) => get<T>(path, headers: activeHeaders, query: query),
      headers: headers,
    );
  }

  /// POST Request
  Future<Response<T>> postRequest<T>(
    String path,
    dynamic body, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) {
    return _executeWithRetry<T>(
      path,
      (activeHeaders) =>
          post<T>(path, body, headers: activeHeaders, query: query),
      headers: headers,
    );
  }

  /// PUT Request
  Future<Response<T>> putRequest<T>(
    String path,
    dynamic body, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) {
    return _executeWithRetry<T>(
      path,
      (activeHeaders) =>
          put<T>(path, body, headers: activeHeaders, query: query),
      headers: headers,
    );
  }

  /// DELETE Request
  Future<Response<T>> deleteRequest<T>(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) {
    return _executeWithRetry<T>(
      path,
      (activeHeaders) => delete<T>(path, headers: activeHeaders, query: query),
      headers: headers,
    );
  }

  /// PATCH Request
  Future<Response<T>> patchRequest<T>(
    String path,
    dynamic body, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) {
    return _executeWithRetry<T>(
      path,
      (activeHeaders) =>
          patch<T>(path, body, headers: activeHeaders, query: query),
      headers: headers,
    );
  }

  Future<Map<String, dynamic>?>? _pendingUserProfileFuture;
  DateTime? _lastUserProfileFetchTime;
  Map<String, dynamic>? _cachedUserProfileData;

  /// Clear in-memory user profile cache (e.g. upon logout or session switch)
  void clearUserProfileCache() {
    _cachedUserProfileData = null;
    _lastUserProfileFetchTime = null;
    _pendingUserProfileFuture = null;
  }

  /// Invalidate or update profile cache (e.g. after profile update/picture upload)
  void updateUserProfileCache(Map<String, dynamic> updatedData) {
    if (_cachedUserProfileData != null) {
      _cachedUserProfileData!.addAll(updatedData);
    } else {
      _cachedUserProfileData = Map<String, dynamic>.from(updatedData);
    }
  }

  /// Fetch user profile details from GET /api/v1/users/me
  /// Automatically deduplicates concurrent in-flight requests and caches response for 60 seconds
  /// to eliminate unusual and repeated calls while navigating between screens.
  Future<Map<String, dynamic>?> fetchUserProfile({bool force = false}) async {
    // 1. If an identical request is currently in-flight, return the existing future
    if (_pendingUserProfileFuture != null) {
      developer.log(
        '[API User Profile] Reusing in-flight request to /api/v1/users/me',
      );
      return _pendingUserProfileFuture;
    }

    // 2. Cache & Throttle: If fetched within the last 60 seconds and not forced, return cached data
    if (!force &&
        _cachedUserProfileData != null &&
        _lastUserProfileFetchTime != null &&
        DateTime.now().difference(_lastUserProfileFetchTime!) <
            const Duration(seconds: 60)) {
      developer.log(
        '[API User Profile] Serving cached profile (age: ${DateTime.now().difference(_lastUserProfileFetchTime!).inSeconds}s)',
      );
      return _cachedUserProfileData;
    }

    _pendingUserProfileFuture = _executeFetchUserProfile();
    try {
      final result = await _pendingUserProfileFuture;
      return result;
    } finally {
      _pendingUserProfileFuture = null;
    }
  }

  Future<Map<String, dynamic>?> _executeFetchUserProfile() async {
    try {
      developer.log('[API User Profile] Request: GET /api/v1/users/me');
      final response = await getRequest<Map<String, dynamic>>(
        '/api/v1/users/me',
      );
      developer.log(
        '[API User Profile] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (isSuccess && body['data'] != null && body['data'] is Map) {
          final Map<String, dynamic> data = Map<String, dynamic>.from(
            body['data'] as Map,
          );
          _cachedUserProfileData = data;
          _lastUserProfileFetchTime = DateTime.now();

          final box = GetStorage();

          final String name =
              data['name']?.toString() ??
              '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
          if (name.isNotEmpty) {
            box.write('name', name);
          }
          if (data['title'] != null) box.write('title', data['title']);
          if (data['firstName'] != null) {
            box.write('firstName', data['firstName']);
          }
          if (data['middleName'] != null) {
            box.write('middleName', data['middleName']);
          }
          if (data['lastName'] != null) {
            box.write('lastName', data['lastName']);
          }
          if (data['id'] != null) {
            box.write('userId', data['id']);
            box.write('user_id', data['id']);
            box.write('uuid', data['id']);
          }
          if (data['userId'] != null) {
            box.write('userId', data['userId']);
            box.write('user_id', data['userId']);
          }
          if (data['uuid'] != null) {
            box.write('uuid', data['uuid']);
            box.write('userId', data['uuid']);
          }
          if (data['dob'] != null) box.write('dob', data['dob']);
          if (data['email'] != null) box.write('email', data['email']);
          if (data['mobileNumber'] != null) {
            box.write('phone', data['mobileNumber']);
          }
          if (data['profilePictureUrl'] != null &&
              data['profilePictureUrl'].toString().isNotEmpty) {
            box.write('profilePictureUrl', data['profilePictureUrl']);
          } else {
            box.remove('profilePictureUrl');
          }

          // Persist KYC status from data['kyc'] or legacy flat fields
          bool fullKycCompleted = false;
          bool minKycCompleted = false;
          String kycStatus = 'pending';
          String currentLevel = '';

          if (data['kyc'] != null && data['kyc'] is Map) {
            final kycMap = Map<String, dynamic>.from(data['kyc'] as Map);
            box.write('kyc_data', kycMap);

            currentLevel =
                kycMap['currentLevel']?.toString().toUpperCase() ?? '';
            box.write('kyc_current_level', currentLevel);

            // 1. Check Full KYC: Check 'fullKycCompleted' key
            final bool rawFullCompleted = kycMap['fullKycCompleted'] == true;
            final fullKycSubMap = kycMap['fullKyc'] is Map
                ? Map<String, dynamic>.from(kycMap['fullKyc'] as Map)
                : null;
            final String fullStatus =
                (fullKycSubMap?['status']?.toString() ?? '').toUpperCase();
            final bool fullSubCompleted = fullKycSubMap?['completed'] == true;

            final bool isFullSuccessStatus =
                fullStatus == 'UPGRADE_SUCCESS' ||
                fullStatus == 'COMPLETED' ||
                fullStatus == 'VERIFIED' ||
                fullStatus == 'APPROVED' ||
                fullStatus == 'SUCCESS';

            if (rawFullCompleted ||
                fullSubCompleted ||
                isFullSuccessStatus ||
                currentLevel == 'FULL') {
              fullKycCompleted = true;
              kycStatus = 'verified';
            } else {
              // If fullKycCompleted is false, keep as pending so KYC option is always available to do
              fullKycCompleted = false;
              kycStatus = 'pending';
            }

            // 2. Check Min KYC
            final bool rawMinCompleted = kycMap['minKycCompleted'] == true;
            final minKycSubMap = kycMap['minKyc'] is Map
                ? Map<String, dynamic>.from(kycMap['minKyc'] as Map)
                : null;
            final String minStatus = (minKycSubMap?['status']?.toString() ?? '')
                .toUpperCase();
            final bool minSubCompleted = minKycSubMap?['completed'] == true;

            final bool isMinSuccessStatus =
                minStatus == 'UPGRADE_SUCCESS' ||
                minStatus == 'COMPLETED' ||
                minStatus == 'VERIFIED' ||
                minStatus == 'APPROVED' ||
                minStatus == 'SUCCESS';

            minKycCompleted =
                rawMinCompleted ||
                minSubCompleted ||
                isMinSuccessStatus ||
                currentLevel == 'MIN' ||
                fullKycCompleted;
          } else {
            // Backward compatibility for flat fields
            if (data['isKycCompleted'] != null) {
              fullKycCompleted = data['isKycCompleted'] == true;
              kycStatus = fullKycCompleted ? 'verified' : 'pending';
            } else if (data['kycStatus'] != null) {
              final st = data['kycStatus'].toString().toLowerCase();
              final isV =
                  (st == 'verified' || st == 'completed' || st == 'approved');
              fullKycCompleted = isV;
              kycStatus = isV ? 'verified' : st;
            }
            if (data['isMinKycCompleted'] != null) {
              minKycCompleted = data['isMinKycCompleted'] == true;
            } else if (data['minKycCompleted'] != null) {
              minKycCompleted = data['minKycCompleted'] == true;
            }
          }

          // Persist calculated statuses into GetStorage
          box.write('is_kyc_completed', fullKycCompleted);
          box.write('full_kyc_completed', fullKycCompleted);
          box.write('min_kyc_completed', minKycCompleted);
          box.write('is_min_kyc_completed', minKycCompleted);
          box.write('kyc_status', kycStatus);
          if (data['hasMpin'] == true ||
              data['isMpinSet'] == true ||
              data['mpinSet'] == true) {
            box.write('has_mpin', true);
            box.write('mpin_set', true);
          }

          if (data['address'] != null && data['address'] is Map) {
            final addr = Map<String, dynamic>.from(data['address'] as Map);
            box.write('addressData', addr);
            final parts =
                [
                      addr['addressLine1'],
                      addr['addressLine2'],
                      addr['city'],
                      addr['state'],
                      addr['pincode'],
                      addr['country'],
                    ]
                    .where((p) => p != null && p.toString().trim().isNotEmpty)
                    .join(', ');
            if (parts.isNotEmpty) {
              box.write('address', parts);
            }
          }

          if (Get.isRegistered<AuthService>()) {
            await AuthService.to.updateUserDataField('profile', data);
            if (name.isNotEmpty) {
              await AuthService.to.updateUserDataField('name', name);
            }
            if (data['email'] != null) {
              await AuthService.to.updateUserDataField('email', data['email']);
            }
            if (data['mobileNumber'] != null) {
              await AuthService.to.updateUserDataField(
                'phone',
                data['mobileNumber'],
              );
            }
          }

          return data;
        }
      }
    } catch (e) {
      developer.log('[API Exception] Error fetching user profile: $e');
    }
    return _cachedUserProfileData;
  }

  /// Upload profile picture via POST /api/v1/users/me/profile-picture
  /// Sends proper image MIME type (JPEG/PNG/WebP) and automatically retries with Base64 JSON
  /// if multipart FormData is rejected by the backend server.
  Future<ProfilePictureUploadResult> uploadProfilePicture(
    dynamic fileOrBytes, {
    String filename = 'profile.jpg',
  }) async {
    try {
      final List<int> bytes;
      final String fname;
      if (fileOrBytes is XFile) {
        bytes = await fileOrBytes.readAsBytes();
        fname = fileOrBytes.name.isNotEmpty ? fileOrBytes.name : filename;
      } else if (fileOrBytes is File) {
        bytes = await fileOrBytes.readAsBytes();
        fname = fileOrBytes.path.split('/').last;
      } else if (fileOrBytes is List<int>) {
        bytes = fileOrBytes;
        fname = filename;
      } else {
        bytes = [];
        fname = filename;
      }

      if (bytes.isEmpty) {
        return ProfilePictureUploadResult(
          isSuccess: false,
          errorMessage: "No image data found to upload",
        );
      }

      // Determine correct MIME type
      String mimeType = 'image/jpeg';
      final lowerName = fname.toLowerCase();
      if (lowerName.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (lowerName.endsWith('.webp')) {
        mimeType = 'image/webp';
      } else {
        mimeType = 'image/jpeg';
      }
      final safeFname = fname.contains('.') ? fname : '$fname.jpg';

      // 1. Attempt 1: FormData with proper MIME type and both 'file' and 'image' field names
      final formData = FormData({
        'file': MultipartFile(
          bytes,
          filename: safeFname,
          contentType: mimeType,
        ),
        'image': MultipartFile(
          bytes,
          filename: safeFname,
          contentType: mimeType,
        ),
      });

      developer.log(
        '[API Upload Profile Picture] Attempting FormData upload (MIME: $mimeType, File: $safeFname)...',
      );
      Response<Map<String, dynamic>> response =
          await postRequest<Map<String, dynamic>>(
            '/api/v1/users/me/profile-picture',
            formData,
          );

      developer.log(
        '[API Upload Profile Picture] FormData Status: ${response.statusCode}, Body: ${response.body}',
      );

      // 2. Attempt 2: If FormData returned 400 or FILE_REQUIRED, retry with Base64 JSON payload
      if (!response.isOk &&
          (response.statusCode == 400 ||
              response.body?['code'] == 'FILE_REQUIRED' ||
              response.body?['message']?.toString().contains('base64') ==
                  true)) {
        developer.log(
          '[API Upload Profile Picture] FormData rejected. Retrying with Base64 JSON payload as instructed by server...',
        );
        final base64Str = base64Encode(bytes);
        final dataUri = 'data:$mimeType;base64,$base64Str';

        response = await postRequest<Map<String, dynamic>>(
          '/api/v1/users/me/profile-picture',
          {'image': dataUri, 'base64': base64Str},
        );

        developer.log(
          '[API Upload Profile Picture] Base64 Status: ${response.statusCode}, Body: ${response.body}',
        );
      }

      if (response.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess =
            body['success'] == true ||
            body['code'] == 'OK' ||
            response.statusCode == 200 ||
            response.statusCode == 201;

        if (isSuccess) {
          String? url;
          if (body['data'] is String) {
            url = body['data'] as String;
          } else if (body['data'] is Map) {
            final data = body['data'] as Map;
            url =
                data['profilePictureUrl']?.toString() ??
                data['profile_picture_url']?.toString() ??
                data['url']?.toString() ??
                data['imageUrl']?.toString() ??
                data['image_url']?.toString() ??
                data['avatarUrl']?.toString() ??
                (data['user'] is Map
                    ? data['user']['profilePictureUrl']?.toString()
                    : null);
          } else {
            url =
                body['profilePictureUrl']?.toString() ??
                body['url']?.toString() ??
                body['imageUrl']?.toString();
          }

          // Invalidate cache so subsequent profile calls receive fresh data
          _cachedUserProfileData = null;
          _lastUserProfileFetchTime = null;

          if (url == null || url.isEmpty) {
            final freshProfile = await fetchUserProfile(force: true);
            if (freshProfile != null) {
              url = freshProfile['profilePictureUrl']?.toString();
            }
          }

          if (url != null && url.isNotEmpty) {
            final box = GetStorage();
            await box.write('profilePictureUrl', url);
            if (Get.isRegistered<AuthService>()) {
              await AuthService.to.updateUserDataField(
                'profilePictureUrl',
                url,
              );
            }
            return ProfilePictureUploadResult(isSuccess: true, url: url);
          }
        }
      }

      final errorMsg =
          response.body?['message']?.toString() ??
          "Failed to upload profile picture (${response.statusCode})";
      return ProfilePictureUploadResult(
        isSuccess: false,
        errorMessage: errorMsg,
      );
    } catch (e) {
      developer.log('[API Exception] Error uploading profile picture: $e');
      return ProfilePictureUploadResult(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Fetch user cards from GET /api/v1/cards
  Future<Map<String, dynamic>?> fetchUserCards() async {
    try {
      final response = await getRequest<Map<String, dynamic>>('/api/v1/cards');
      developer.log(
        '[API Fetch Cards] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (isSuccess && body['data'] != null && body['data'] is Map) {
          final data = Map<String, dynamic>.from(body['data'] as Map);
          final box = GetStorage();
          if (data['entityId'] != null) {
            box.write('entityId', data['entityId']);
          }
          if (data['cards'] != null && data['cards'] is List) {
            box.write('user_cards', data['cards']);
          }
          return data;
        }
      }
    } catch (e) {
      developer.log('[API Exception] Error fetching cards: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?>? _pendingWalletBalanceFuture;
  DateTime? _lastWalletBalanceFetchTime;
  Map<String, dynamic>? _cachedWalletBalanceData;

  /// Fetch user wallet balance from GET /api/v1/wallet/balance
  /// Automatically deduplicates concurrent in-flight requests and throttles redundant rapid calls.
  Future<Map<String, dynamic>?> fetchWalletBalance({bool force = false}) async {
    // 1. If an identical request is currently in-flight, return the existing future to prevent duplicate network calls
    if (_pendingWalletBalanceFuture != null) {
      developer.log(
        '[API Fetch Balance] Reusing in-flight request to /api/v1/wallet/balance',
      );
      return _pendingWalletBalanceFuture;
    }

    // 2. Throttle: If fetched within the last 3 seconds and not forced, return cached data
    if (!force &&
        _cachedWalletBalanceData != null &&
        _lastWalletBalanceFetchTime != null &&
        DateTime.now().difference(_lastWalletBalanceFetchTime!) <
            const Duration(seconds: 3)) {
      developer.log(
        '[API Fetch Balance] Serving cached balance within throttle window',
      );
      return _cachedWalletBalanceData;
    }

    _pendingWalletBalanceFuture = _executeFetchWalletBalance();
    try {
      final result = await _pendingWalletBalanceFuture;
      return result;
    } finally {
      _pendingWalletBalanceFuture = null;
    }
  }

  Future<Map<String, dynamic>?> _executeFetchWalletBalance() async {
    try {
      final response = await getRequest<Map<String, dynamic>>(
        '/api/v1/wallet/balance',
      );
      developer.log(
        '[API Fetch Balance] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (isSuccess && body['data'] != null && body['data'] is Map) {
          final data = Map<String, dynamic>.from(body['data'] as Map);
          final box = GetStorage();
          if (data['balance'] != null) {
            final num balNum = data['balance'] is num
                ? data['balance']
                : num.tryParse(data['balance'].toString()) ?? 0;
            box.write('balance', balNum);
            box.write('wallet_balance', balNum);
          }
          if (data['currency'] != null) {
            box.write('currency', data['currency']);
          }
          if (data['lienBalance'] != null) {
            box.write('lienBalance', data['lienBalance']);
          }
          if (data['products'] != null) {
            box.write('wallet_products', data['products']);
          }
          _cachedWalletBalanceData = data;
          _lastWalletBalanceFetchTime = DateTime.now();
          return data;
        }
      }
    } catch (e) {
      developer.log('[API Exception] Error fetching wallet balance: $e');
    }
    return null;
  }

  /// Fetch transactions list from GET /api/v1/transactions
  /// Accepts optional parameters: [fromDate] (YYYY-MM-DD), [toDate] (YYYY-MM-DD), [pageNumber], [pageSize]
  Future<Map<String, dynamic>?> fetchTransactions({
    String? fromDate,
    String? toDate,
    int pageNumber = 0,
    int pageSize = 20,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
      };
      if (fromDate != null && fromDate.isNotEmpty) {
        queryParams['fromDate'] = fromDate;
      }
      if (toDate != null && toDate.isNotEmpty) {
        queryParams['toDate'] = toDate;
      }

      final response = await getRequest<dynamic>(
        '/api/v1/transactions',
        query: queryParams,
      );
      developer.log(
        '[API Fetch Transactions] Status: ${response.statusCode}, Body: ${response.body}',
      );

      Map<String, dynamic>? body;
      if (response.body is Map) {
        body = Map<String, dynamic>.from(response.body as Map);
      } else if (response.body is String) {
        try {
          final decoded = jsonDecode(response.body as String);
          if (decoded is Map) body = Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }

      if (response.isOk && body != null) {
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (isSuccess && body['data'] != null) {
          if (body['data'] is Map) {
            return Map<String, dynamic>.from(body['data'] as Map);
          } else if (body['data'] is List) {
            return {'items': body['data']};
          }
        }
      }
    } catch (e) {
      developer.log('[API Exception] Error fetching transactions: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> manageCardLock({
    required String kitNumber,
    required String action,
    String reason = "card status change",
  }) async {
    try {
      String parsedAction = action.trim().toUpperCase();
      if (parsedAction == 'PERMANENT_BLOCK' ||
          parsedAction == 'BLOCK' ||
          parsedAction == 'BL') {
        parsedAction = 'PERMANENT_BLOCK';
      } else if (parsedAction == 'LOCK' ||
          parsedAction == 'L' ||
          parsedAction == 'FREEZE') {
        parsedAction = 'LOCK';
      } else if (parsedAction == 'UNLOCK' ||
          parsedAction == 'UL' ||
          parsedAction == 'UNFREEZE') {
        parsedAction = 'UNLOCK';
      }

      final response = await postRequest<Map<String, dynamic>>(
        '/api/v1/cards/lock',
        {"action": parsedAction, "kitNumber": kitNumber, "reason": reason},
      );
      developer.log(
        '[API Manage Card Lock] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (isSuccess) {
          if (body['data'] != null && body['data'] is Map) {
            return Map<String, dynamic>.from(body['data'] as Map);
          }
          return Map<String, dynamic>.from(body);
        }
      }
    } catch (e) {
      developer.log('[API Exception] Error in manageCardLock: $e');
    }
    return null;
  }

  /// Fetch card preferences from GET /api/v1/cards/preferences
  Future<Map<String, dynamic>?> fetchCardPreferences() async {
    try {
      final response = await getRequest<Map<String, dynamic>>(
        '/api/v1/cards/preferences',
      );
      developer.log(
        '[API Fetch Card Preferences] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (isSuccess && body['data'] != null && body['data'] is Map) {
          final data = Map<String, dynamic>.from(body['data'] as Map);
          return data;
        }
      }
    } catch (e) {
      developer.log('[API Exception] Error fetching card preferences: $e');
    }
    return null;
  }

  /// Update card preferences via POST /api/v1/cards/preferences
  Future<Map<String, dynamic>?> updateCardPreferences(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await postRequest<Map<String, dynamic>>(
        '/api/v1/cards/preferences',
        payload,
      );
      developer.log(
        '[API Update Card Preferences] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (isSuccess) {
          if (body['data'] != null && body['data'] is Map) {
            return Map<String, dynamic>.from(body['data'] as Map);
          }
          return Map<String, dynamic>.from(body);
        }
      }
    } catch (e) {
      developer.log('[API Exception] Error updating card preferences: $e');
    }
    return null;
  }

  /// Set card daily limit via POST /api/v1/cards/daily-limit
  Future<Map<String, dynamic>?> setCardDailyLimit(
    Map<String, dynamic> payload,
  ) async {
    try {
      print('[API Daily Limit Request Body] $payload');
      debugPrint('[API Daily Limit Request Body] $payload');
      developer.log('[API Daily Limit Request Body] $payload');
      final response = await postRequest<Map<String, dynamic>>(
        '/api/v1/cards/daily-limit',
        payload,
      );
      developer.log(
        '[API Set Daily Limit] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (isSuccess) {
          if (body['data'] != null && body['data'] is Map) {
            return Map<String, dynamic>.from(body['data'] as Map);
          }
          return Map<String, dynamic>.from(body);
        }
      }
    } catch (e) {
      developer.log('[API Exception] Error setting daily limit: $e');
    }
    return null;
  }

  /// Initiate VKYC Upgrade via POST /api/v1/kyc/vkyc/upgrade
  Future<Map<String, dynamic>?> upgradeVkyc({
    Map<String, dynamic>? payload,
  }) async {
    try {
      final reqPayload = payload ?? {};
      developer.log('[API Upgrade VKYC Request] Payload: $reqPayload');
      final response = await postRequest<Map<String, dynamic>>(
        '/api/v1/kyc/vkyc/upgrade',
        reqPayload,
      );
      developer.log(
        '[API Upgrade VKYC Response] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.isOk && response.body != null) {
        final Map<String, dynamic> mapBody = response.body!;
        if (mapBody['data'] != null && mapBody['data'] is Map) {
          return Map<String, dynamic>.from(mapBody['data'] as Map);
        }
        return mapBody;
      } else {
        final errorMsg =
            response.body?['message']?.toString() ??
            "Failed to initiate VKYC upgrade (${response.statusCode})";
        AppSnackbar.error(errorMsg);
      }
    } catch (e) {
      developer.log('[API Exception] Error in upgradeVkyc: $e');
      AppSnackbar.error("Network error while upgrading VKYC: $e");
    }
    return null;
  }

  /// Fetch card widget session via POST /api/v1/cards/widget-session
  Future<Map<String, dynamic>?> fetchCardWidgetSession({
    String widgetType = "CARD_DETAILS",
    String? callbackUrl,
    String? kitNumber,
    String? entityId,
    String? cardId,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        "widgetType": widgetType,
        "callbackUrl": callbackUrl ?? "ppiapp://card-widget/return",
      };

      final effectiveKit =
          kitNumber ?? GetStorage().read('kitNumber')?.toString();
      if (effectiveKit != null && effectiveKit.isNotEmpty) {
        payload['kitNumber'] = effectiveKit;
      }
      // Note: entityId and cardId are not permitted in /api/v1/cards/widget-session
      // and will cause VALIDATION_ERROR if sent.

      developer.log('[API Widget Session Request Body] $payload');
      final response = await postRequest<Map<String, dynamic>>(
        '/api/v1/cards/widget-session',
        payload,
      );
      developer.log(
        '[API Fetch Widget Session] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.body != null) {
        final body = response.body!;

        if (!response.isOk || body['success'] == false) {
          String errorMessage =
              body['message']?.toString() ??
              'Validation or server error occurred.';
          if (body['data'] is Map && (body['data'] as Map)['errors'] is List) {
            final errs = (body['data'] as Map)['errors'] as List;
            if (errs.isNotEmpty) {
              errorMessage = errs.map((e) => e.toString()).join('; ');
            }
          }
          return {
            'success': false,
            'hasError': true,
            'message': errorMessage,
            'code': body['code']?.toString(),
            'statusCode': response.statusCode,
            'data': body['data'],
          };
        }

        String? extractedUrl;
        if (body['result'] != null && body['result'] is String) {
          extractedUrl = body['result'] as String;
        } else if (body['widgetUrl'] != null && body['widgetUrl'] is String) {
          extractedUrl = body['widgetUrl'] as String;
        } else if (body['url'] != null && body['url'] is String) {
          extractedUrl = body['url'] as String;
        } else if (body['sessionUrl'] != null && body['sessionUrl'] is String) {
          extractedUrl = body['sessionUrl'] as String;
        } else if (body['redirectUrl'] != null &&
            body['redirectUrl'] is String) {
          extractedUrl = body['redirectUrl'] as String;
        } else if (body['data'] != null) {
          if (body['data'] is String) {
            extractedUrl = body['data'] as String;
          } else if (body['data'] is Map) {
            final dataMap = body['data'] as Map;
            extractedUrl =
                dataMap['widgetUrl']?.toString() ??
                dataMap['result']?.toString() ??
                dataMap['url']?.toString() ??
                dataMap['sessionUrl']?.toString() ??
                dataMap['redirectUrl']?.toString() ??
                dataMap['link']?.toString() ??
                dataMap['widget']?.toString();
          }
        }

        Map<String, dynamic> resMap = {};
        if (body['data'] != null && body['data'] is Map) {
          resMap = Map<String, dynamic>.from(body['data'] as Map);
        } else {
          resMap = Map<String, dynamic>.from(body);
        }

        if (extractedUrl != null && extractedUrl.isNotEmpty) {
          resMap['success'] = true;
          resMap['hasError'] = false;
          resMap['widgetUrl'] = extractedUrl;
          resMap['result'] = extractedUrl;
          return resMap;
        }

        return {
          'success': false,
          'hasError': true,
          'message':
              body['message']?.toString() ??
              'No valid widget URL received in server response.',
          'code': body['code']?.toString(),
          'statusCode': response.statusCode,
          'data': body['data'],
        };
      }

      return {
        'success': false,
        'hasError': true,
        'message':
            response.statusText ??
            'Server returned status ${response.statusCode}',
        'statusCode': response.statusCode,
      };
    } catch (e) {
      developer.log('[API Exception] Error fetching card widget session: $e');
      return {'success': false, 'hasError': true, 'message': e.toString()};
    }
  }

  /// Initiate wallet load via POST /api/v1/wallet/loads
  Future<Map<String, dynamic>?> initiateWalletLoad({
    required double amount,
    required String idempotencyKey,
  }) async {
    try {
      final payload = {'amount': amount, 'idempotencyKey': idempotencyKey};
      print('[API Wallet Load Request] $payload');
      debugPrint('[API Wallet Load Request] $payload');
      developer.log('[API Wallet Load Request] $payload');
      final response = await postRequest<Map<String, dynamic>>(
        '/api/v1/wallet/loads',
        payload,
      );
      print(
        '[API Wallet Load Response] Status: ${response.statusCode}, Body: ${response.body}',
      );
      debugPrint(
        '[API Wallet Load Response] Status: ${response.statusCode}, Body: ${response.body}',
      );
      developer.log(
        '[API Wallet Load Response] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (isSuccess) {
          if (body['data'] != null && body['data'] is Map) {
            return Map<String, dynamic>.from(body['data'] as Map);
          }
          return Map<String, dynamic>.from(body);
        } else if (body['message'] != null) {
          AppSnackbar.error(body['message'].toString());
        }
      } else if (response.body != null && response.body is Map) {
        final body = response.body!;
        if (body['message'] != null) {
          AppSnackbar.error(body['message'].toString());
        }
      }
    } catch (e) {
      developer.log('[API Exception] Error initiating wallet load: $e');
    }
    return null;
  }

  /// Generate PayU hash via POST /api/v1/wallet/loads/payu/hash
  Future<Map<String, dynamic>?> generatePayUHash({
    required String hashName,
    required String hashString,
    String hashType = "V1",
    String? postSalt,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        'hashName': hashName,
        'hashString': hashString,
        'hashType': hashType,
      };
      if (postSalt != null && postSalt.isNotEmpty) {
        payload['postSalt'] = postSalt;
      }
      print('[API PayU Hash Request] $payload');
      debugPrint('[API PayU Hash Request] $payload');
      developer.log('[API PayU Hash Request] $payload');

      final response = await postRequest<Map<String, dynamic>>(
        '/api/v1/wallet/loads/payu/hash',
        payload,
      );

      debugPrint(
        '[API PayU Hash Response] Status: ${response.statusCode}, Body: ${response.body}',
      );
      developer.log(
        '[API PayU Hash Response] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (isSuccess && body['data'] != null && body['data'] is Map) {
          return Map<String, dynamic>.from(body['data'] as Map);
        }
      }
    } catch (e) {
      developer.log('[API Exception] Error generating PayU hash: $e');
    }
    return null;
  }

  /// Fetch wallet load details by transaction reference via GET /api/v1/wallet/loads/{transactionReference}
  Future<Map<String, dynamic>?> fetchWalletLoadDetails(
    String transactionReference,
  ) async {
    try {
      print(
        '[API Fetch Load Details Request] transactionReference: $transactionReference',
      );
      debugPrint(
        '[API Fetch Load Details Request] transactionReference: $transactionReference',
      );
      developer.log(
        '[API Fetch Load Details Request] transactionReference: $transactionReference',
      );

      final response = await getRequest<Map<String, dynamic>>(
        '/api/v1/wallet/loads/$transactionReference',
      );

      print(
        '[API Fetch Load Details Response] Status: ${response.statusCode}, Body: ${response.body}',
      );
      debugPrint(
        '[API Fetch Load Details Response] Status: ${response.statusCode}, Body: ${response.body}',
      );
      developer.log(
        '[API Fetch Load Details Response] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (isSuccess && body['data'] != null && body['data'] is Map) {
          return Map<String, dynamic>.from(body['data'] as Map);
        }
      }
    } catch (e) {
      developer.log('[API Exception] Error fetching wallet load details: $e');
    }
    return null;
  }

  /// Load money to wallet via POST /api/v1/wallet/load after payment success
  Future<Map<String, dynamic>?> loadWallet({
    required double amount,
    required String idempotencyKey,
  }) async {
    try {
      final payload = {'amount': amount, 'idempotencyKey': idempotencyKey};

      print('[API /wallet/load Request] $payload');
      debugPrint('[API /wallet/load Request] $payload');
      developer.log('[API /wallet/load Request] $payload');

      final response = await postRequest<Map<String, dynamic>>(
        '/api/v1/wallet/load',
        payload,
      );

      print(
        '[API /wallet/load Response] Status: ${response.statusCode}, Body: ${response.body}',
      );
      debugPrint(
        '[API /wallet/load Response] Status: ${response.statusCode}, Body: ${response.body}',
      );
      developer.log(
        '[API /wallet/load Response] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (isSuccess) {
          if (body['data'] != null && body['data'] is Map) {
            return Map<String, dynamic>.from(body['data'] as Map);
          }
          return Map<String, dynamic>.from(body);
        }
      }
    } catch (e) {
      developer.log('[API Exception] Error in loadWallet: $e');
    }
    return null;
  }

  /// Check C2C recipient status via POST /api/v1/wallet/transfer/c2c/check
  Future<Map<String, dynamic>?> checkC2CRecipient({
    required String toMobileNumber,
  }) async {
    try {
      final payload = {'toMobileNumber': toMobileNumber};

      developer.log('[API /wallet/transfer/c2c/check Request] $payload');

      final response = await postRequest<Map<String, dynamic>>(
        '/api/v1/wallet/transfer/c2c/check',
        payload,
      );

      developer.log(
        '[API /wallet/transfer/c2c/check Response] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.body != null && response.body is Map) {
        final body = Map<String, dynamic>.from(response.body!);
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (body['data'] != null && body['data'] is Map) {
          final data = Map<String, dynamic>.from(body['data'] as Map);
          data['apiSuccess'] = isSuccess;
          data['apiMessage'] = body['message'];
          return data;
        }
        body['apiSuccess'] = isSuccess;
        return body;
      }
    } catch (e) {
      developer.log('[API Exception] Error in checkC2CRecipient: $e');
    }
    return null;
  }

  /// Backward compatibility wrapper for checkC2CRecipient
  Future<Map<String, dynamic>?> checkW2WRecipient({
    required String toMobileNumber,
  }) => checkC2CRecipient(toMobileNumber: toMobileNumber);

  /// Execute C2C wallet transfer via POST /api/v1/wallet/transfer/c2c
  Future<Map<String, dynamic>?> transferC2C({
    required String toMobileNumber,
    required double amount,
    required String idempotencyKey,
    String description = 'Customer to customer transfer',
    String? fromProductId,
    String? productId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'toMobileNumber': toMobileNumber,
        'amount': amount % 1 == 0 ? amount.toInt() : amount,
        'idempotencyKey': idempotencyKey,
        'description': description,
      };

      if (fromProductId != null && fromProductId.isNotEmpty) {
        payload['fromProductId'] = fromProductId;
      }
      if (productId != null && productId.isNotEmpty) {
        payload['productId'] = productId;
      }

      developer.log('[API /wallet/transfer/c2c Request] $payload');

      final response = await postRequest<Map<String, dynamic>>(
        '/api/v1/wallet/transfer/c2c',
        payload,
      );

      developer.log(
        '[API /wallet/transfer/c2c Response] Status: ${response.statusCode}, Body: ${response.body}',
      );

      Map<String, dynamic>? body;
      if (response.body is Map) {
        body = Map<String, dynamic>.from(response.body as Map);
      } else if (response.body is String) {
        try {
          final decoded = jsonDecode(response.body as String);
          if (decoded is Map) body = Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }

      if (body != null) {
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (body['data'] != null && body['data'] is Map) {
          final data = Map<String, dynamic>.from(body['data'] as Map);
          data['apiSuccess'] = isSuccess;
          data['apiMessage'] = body['message'];
          return data;
        }
        body['apiSuccess'] = isSuccess;
        return body;
      }

      if (!response.status.isOk) {
        return {
          'apiSuccess': false,
          'message':
              response.statusText ??
              'Transfer failed with status ${response.statusCode}',
        };
      }
    } catch (e) {
      developer.log('[API Exception] Error in transferC2C: $e');
    }
    return null;
  }

  /// Backward compatibility wrapper for transferC2C
  Future<Map<String, dynamic>?> transferW2W({
    required String toMobileNumber,
    required double amount,
    required String idempotencyKey,
    String fromProductId = 'GENERAL',
    String productId = 'GENERAL',
    String description = 'Customer to customer transfer',
  }) => transferC2C(
    toMobileNumber: toMobileNumber,
    amount: amount,
    idempotencyKey: idempotencyKey,
    fromProductId: fromProductId,
    productId: productId,
    description: description,
  );

  /// Fetch pincode details via GET /api/v1/pincode/{pincode}
  Future<Map<String, dynamic>?> fetchPincodeDetails(String pincode) async {
    try {
      final cleanPincode = pincode.trim();
      if (cleanPincode.isEmpty) return null;

      developer.log('[API GET /api/v1/pincode/$cleanPincode Request]');

      final response = await getRequest<Map<String, dynamic>>(
        '/api/v1/pincode/$cleanPincode',
      );

      developer.log(
        '[API GET /api/v1/pincode/$cleanPincode Response] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.body != null && response.body is Map) {
        final body = Map<String, dynamic>.from(response.body!);
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (body['data'] != null && body['data'] is Map) {
          final data = Map<String, dynamic>.from(body['data'] as Map);
          data['apiSuccess'] = isSuccess;
          return data;
        }
        body['apiSuccess'] = isSuccess;
        return body;
      }
    } catch (e) {
      developer.log('[API Exception] Error in fetchPincodeDetails: $e');
    }
    return null;
  }

  /// Fetch spending transaction analytics via GET /api/v1/transactions/analytics
  Future<Map<String, dynamic>?> fetchTransactionAnalytics({
    String? month,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (month != null && month.trim().isNotEmpty) {
        queryParams['month'] = month.trim();
      }

      developer.log(
        '[API GET /api/v1/transactions/analytics Request] Query: $queryParams',
      );

      final response = await getRequest<Map<String, dynamic>>(
        '/api/v1/transactions/analytics',
        query: queryParams.isNotEmpty ? queryParams : null,
      );

      developer.log(
        '[API GET /api/v1/transactions/analytics Response] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.body != null && response.body is Map) {
        final body = Map<String, dynamic>.from(response.body!);
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (body['data'] != null && body['data'] is Map) {
          final data = Map<String, dynamic>.from(body['data'] as Map);
          data['apiSuccess'] = isSuccess;
          return data;
        }
        body['apiSuccess'] = isSuccess;
        return body;
      }
    } catch (e) {
      developer.log('[API Exception] Error in fetchTransactionAnalytics: $e');
    }
    return null;
  }

  /// Register device FCM token via POST /api/v1/devices
  /// Called ONLY at the time of successful user login or registration from response.
  Future<Map<String, dynamic>?> registerDeviceToken([
    String? explicitFcmToken,
  ]) async {
    try {
      String? token = explicitFcmToken?.trim();
      if (token == null || token.isEmpty) {
        if (Get.isRegistered<FirebaseService>()) {
          token = FirebaseService.to.fcmToken.value;
        }
        if (token == null || token.isEmpty) {
          token = GetStorage().read<String>('fcm_token');
        }
        if (token == null || token.isEmpty) {
          try {
            token = await FirebaseMessaging.instance.getToken();
            if (token != null && token.isNotEmpty) {
              GetStorage().write('fcm_token', token);
            }
          } catch (e) {
            developer.log('[API /api/v1/devices] Error fetching FCM token: $e');
          }
        }
      }

      final cleanToken = token?.trim() ?? '';
      if (cleanToken.isEmpty) {
        developer.log(
          '[API /api/v1/devices] fcmToken is empty. Skipping registration.',
        );
        return null;
      }

      final platform = GetPlatform.isIOS ? 'ios' : 'android';
      final payload = {'platform': platform, 'fcmToken': cleanToken};

      developer.log('[API POST /api/v1/devices Request] Payload: $payload');

      final response = await postRequest<Map<String, dynamic>>(
        '/api/v1/devices',
        payload,
      );

      developer.log(
        '[API POST /api/v1/devices Response] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.body != null && response.body is Map) {
        final body = Map<String, dynamic>.from(response.body!);
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        body['apiSuccess'] = isSuccess;
        return body;
      }
    } catch (e, stackTrace) {
      developer.log(
        '[API Exception] Error in registerDeviceToken: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  /// Fetch user notifications from GET /api/v1/notifications
  Future<Map<String, dynamic>?> fetchNotifications({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final query = {'page': page.toString(), 'pageSize': pageSize.toString()};

      developer.log('[API GET /api/v1/notifications Request] Query: $query');

      final response = await getRequest<Map<String, dynamic>>(
        '/api/v1/notifications',
        query: query,
      );

      developer.log(
        '[API GET /api/v1/notifications Response] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (isSuccess && body['data'] != null && body['data'] is Map) {
          return Map<String, dynamic>.from(body['data'] as Map);
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        '[API Exception] Error in fetchNotifications: $e',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  Response<Map<String, dynamic>>? _cachedPrivacyPolicy;
  Future<Response<Map<String, dynamic>>>? _inFlightPrivacyPolicy;

  /// Fetch user data privacy policy from GET /api/v1/legal/privacy-policy
  /// Caches response in memory and deduplicates in-flight requests to avoid unnecessary repeated calls.
  Future<Response<Map<String, dynamic>>> getPrivacyPolicy({
    bool force = false,
  }) async {
    if (!force && _cachedPrivacyPolicy != null) {
      developer.log(
        '[API GET /api/v1/legal/privacy-policy] Returning cached response.',
      );
      return _cachedPrivacyPolicy!;
    }

    if (_inFlightPrivacyPolicy != null) {
      developer.log(
        '[API GET /api/v1/legal/privacy-policy] Joining in-flight request.',
      );
      return _inFlightPrivacyPolicy!;
    }

    final future = _fetchPrivacyPolicyInternal();
    _inFlightPrivacyPolicy = future;
    try {
      final response = await future;
      if (response.isOk && response.body != null) {
        _cachedPrivacyPolicy = response;
      }
      return response;
    } finally {
      _inFlightPrivacyPolicy = null;
    }
  }

  Future<Response<Map<String, dynamic>>> _fetchPrivacyPolicyInternal() async {
    try {
      developer.log('[API GET /api/v1/legal/privacy-policy Request]');
      final response = await getRequest<Map<String, dynamic>>(
        '/api/v1/legal/privacy-policy',
      );
      developer.log(
        '[API GET /api/v1/legal/privacy-policy Response] Status: ${response.statusCode}',
      );
      return response;
    } catch (e, stackTrace) {
      developer.log(
        '[API Exception] Error in getPrivacyPolicy: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Verifies MPIN against the live backend API /api/v1/auth/mpin/login.
  /// Automatically resolves registered phone number if not supplied.
  /// On successful verification, updates auth tokens, saves MPIN and returns success.
  Future<MpinVerifyResponse> verifyMpin(
    String mpin, {
    String? mobileNumber,
  }) async {
    final cleanPin = mpin.trim();
    if (cleanPin.isEmpty || cleanPin.length != 4) {
      return const MpinVerifyResponse(
        isSuccess: false,
        message: 'Please enter a valid 4-digit MPIN.',
      );
    }

    final box = GetStorage();

    // Resolve registered mobile number from provided or storage
    String userPhone = '';
    if (mobileNumber != null && mobileNumber.trim().isNotEmpty) {
      final clean = mobileNumber.replaceAll(RegExp(r'\D'), '');
      userPhone = clean.length > 10
          ? clean.substring(clean.length - 10)
          : clean;
    }
    if (userPhone.isEmpty) {
      final raw =
          box.read<String>('mobileNumber') ??
          box.read<String>('phone') ??
          box.read<String>('remembered_phone') ??
          box.read<String>('user_mobile');
      if (raw != null && raw.toString().isNotEmpty) {
        final clean = raw.toString().replaceAll(RegExp(r'\D'), '');
        userPhone = clean.length > 10
            ? clean.substring(clean.length - 10)
            : clean;
      }
    }

    if (userPhone.isEmpty) {
      final savedMpin =
          box.read<String>('saved_mpin') ?? box.read('mpin')?.toString();
      if (savedMpin != null && savedMpin == cleanPin) {
        return const MpinVerifyResponse(
          isSuccess: true,
          message: 'MPIN verified successfully.',
        );
      }
      return const MpinVerifyResponse(
        isSuccess: false,
        message: 'Registered mobile number not found. Please log in again.',
      );
    }

    try {
      developer.log(
        '[ApiService] Verifying MPIN via /api/v1/auth/mpin/login for $userPhone',
      );
      final response = await postRequest<Map<String, dynamic>>(
        '/api/v1/auth/mpin/login',
        {"mobileNumber": userPhone, "mpin": cleanPin},
      );

      final body = response.body;
      final bool isSuccess =
          response.status.isOk &&
          body != null &&
          (body['success'] == true ||
              body['status'] == true ||
              body['status'] == 'success' ||
              body['code'] == 'OK' ||
              body['code'] == 200) &&
          body['status'] != false &&
          body['success'] != false;

      if (isSuccess) {
        // Persist verified MPIN in storage
        box.write('saved_mpin', cleanPin);
        box.write('has_mpin', true);
        box.write('mpin_set', true);

        // Update tokens if present for maximum performance and up-to-date session
        if (body['data'] is Map) {
          final data = body['data'] as Map;
          final token =
              data['accessToken']?.toString() ?? data['token']?.toString();
          final refreshToken = data['refreshToken']?.toString();
          if (token != null && token.isNotEmpty) {
            box.write('accessToken', token);
            box.write('auth_token', token);
            box.write('token', token);
            if (Get.isRegistered<AuthService>()) {
              await AuthService.to.saveSession(
                token: token,
                refreshToken: refreshToken,
                userId: userPhone,
              );
            }
          }
          if (refreshToken != null && refreshToken.isNotEmpty) {
            box.write('refreshToken', refreshToken);
            box.write('refresh_token', refreshToken);
          }
        }

        return MpinVerifyResponse(
          isSuccess: true,
          message: body['message']?.toString() ?? 'MPIN verified successfully.',
          data: body['data'] is Map
              ? Map<String, dynamic>.from(body['data'])
              : null,
        );
      } else {
        final errorMsg =
            (body != null &&
                body['message'] != null &&
                body['message'].toString().trim().isNotEmpty)
            ? body['message'].toString()
            : 'Incorrect MPIN. Please try again.';
        return MpinVerifyResponse(isSuccess: false, message: errorMsg);
      }
    } catch (e) {
      developer.log('[ApiService] Exception verifying MPIN: $e');
      final savedMpin =
          box.read<String>('saved_mpin') ?? box.read('mpin')?.toString();
      if (savedMpin != null && savedMpin == cleanPin) {
        return const MpinVerifyResponse(
          isSuccess: true,
          message: 'MPIN verified (offline fallback).',
        );
      }
      return const MpinVerifyResponse(
        isSuccess: false,
        message:
            'Failed to verify MPIN with server. Please check your network connection.',
      );
    }
  }
}
