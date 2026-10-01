import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:transwallet/services/auth_service.dart';
import 'package:transwallet/widgets/app_snackbar.dart';

/// Service to handle all HTTP API network requests using GetConnect
class ApiService extends GetConnect {
  static ApiService get to => Get.find<ApiService>();

  // Default config
  final String _defaultBaseUrl = 'http://192.168.1.202:3001';
  final Duration _defaultTimeout = const Duration(seconds: 30);

  // Mutex to prevent multiple concurrent token refresh calls
  Completer<bool>? _refreshCompleter;

  @override
  void onInit() {
    // Read saved custom base URL if configured, otherwise fallback to default
    final savedBaseUrl = GetStorage().read<String>('api_base_url');
    httpClient.baseUrl =
        (savedBaseUrl != null && savedBaseUrl.trim().isNotEmpty)
        ? savedBaseUrl.trim()
        : _defaultBaseUrl;
    httpClient.timeout = _defaultTimeout;

    // 1. Request Interceptor
    httpClient.addRequestModifier<dynamic>((request) {
      final path = request.url.path;
      final isMultipart =
          path.contains('/profile-picture') ||
          (request.headers['Content-Type']?.contains('multipart') ?? false);

      if (isMultipart) {
        // Remove application/json if set so GetConnect generates multipart/form-data with boundary
        request.headers.remove('Content-Type');
      } else {
        request.headers['Content-Type'] ??= 'application/json';
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
        }
      }
      return response;
    });

    super.onInit();
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

  /// Fetch user profile details from GET /api/v1/users/me
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
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
          final box = GetStorage();

          final String name =
              data['name']?.toString() ??
              '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
          if (name.isNotEmpty) {
            box.write('name', name);
          }
          if (data['title'] != null) box.write('title', data['title']);
          if (data['firstName'] != null)
            box.write('firstName', data['firstName']);
          if (data['middleName'] != null)
            box.write('middleName', data['middleName']);
          if (data['lastName'] != null) box.write('lastName', data['lastName']);
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
          if (data['mobileNumber'] != null)
            box.write('phone', data['mobileNumber']);
          if (data['profilePictureUrl'] != null &&
              data['profilePictureUrl'].toString().isNotEmpty) {
            box.write('profilePictureUrl', data['profilePictureUrl']);
          } else {
            box.remove('profilePictureUrl');
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
            if (name.isNotEmpty)
              await AuthService.to.updateUserDataField('name', name);
            if (data['email'] != null)
              await AuthService.to.updateUserDataField('email', data['email']);
            if (data['mobileNumber'] != null)
              await AuthService.to.updateUserDataField(
                'phone',
                data['mobileNumber'],
              );
          }

          return data;
        }
      }
    } catch (e) {
      developer.log('[API Exception] Error fetching user profile: $e');
    }
    return null;
  }

  /// Upload profile picture via POST /api/v1/users/me/profile-picture
  Future<String?> uploadProfilePicture(
    dynamic fileOrBytes, {
    String filename = 'profile.jpg',
  }) async {
    try {
      final FormData formData;
      if (fileOrBytes is FormData) {
        formData = fileOrBytes;
      } else if (fileOrBytes is XFile) {
        final bytes = await fileOrBytes.readAsBytes();
        final fname = fileOrBytes.name.isNotEmpty ? fileOrBytes.name : filename;
        formData = FormData({'file': MultipartFile(bytes, filename: fname)});
      } else if (fileOrBytes is List<int>) {
        formData = FormData({
          'file': MultipartFile(fileOrBytes, filename: filename),
        });
      } else {
        formData = FormData({
          'file': MultipartFile(fileOrBytes, filename: filename),
        });
      }

      final response = await postRequest<Map<String, dynamic>>(
        '/api/v1/users/me/profile-picture',
        formData,
      );

      developer.log(
        '[API Upload Profile Picture] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.isOk && response.body != null) {
        final body = response.body!;
        final bool isSuccess = body['success'] == true || body['code'] == 'OK';
        if (isSuccess && body['data'] != null && body['data'] is Map) {
          final data = body['data'] as Map;
          final url = data['profilePictureUrl']?.toString();
          if (url != null && url.isNotEmpty) {
            final box = GetStorage();
            await box.write('profilePictureUrl', url);
            if (Get.isRegistered<AuthService>()) {
              await AuthService.to.updateUserDataField(
                'profilePictureUrl',
                url,
              );
            }
            return url;
          }
        }
      }
    } catch (e) {
      developer.log('[API Exception] Error uploading profile picture: $e');
    }
    return null;
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

  /// Fetch user wallet balance from GET /api/v1/wallet/balance
  Future<Map<String, dynamic>?> fetchWalletBalance() async {
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

      final response = await getRequest<Map<String, dynamic>>(
        '/api/v1/transactions',
        query: queryParams,
      );
      developer.log(
        '[API Fetch Transactions] Status: ${response.statusCode}, Body: ${response.body}',
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
      print(
        '[API PayU Hash Response] Status: ${response.statusCode}, Body: ${response.body}',
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

  /// Check W2W recipient status via POST /api/v1/wallet/transfer/w2w/check
  Future<Map<String, dynamic>?> checkW2WRecipient({
    required String toMobileNumber,
  }) async {
    try {
      final payload = {'toMobileNumber': toMobileNumber};

      developer.log('[API /wallet/transfer/w2w/check Request] $payload');

      final response = await postRequest<Map<String, dynamic>>(
        '/api/v1/wallet/transfer/w2w/check',
        payload,
      );

      developer.log(
        '[API /wallet/transfer/w2w/check Response] Status: ${response.statusCode}, Body: ${response.body}',
      );

      if (response.body != null && response.body is Map) {
        final body = Map<String, dynamic>.from(response.body!);
        if (body['data'] != null && body['data'] is Map) {
          final data = Map<String, dynamic>.from(body['data'] as Map);
          if (!data.containsKey('apiSuccess')) {
            data['apiSuccess'] =
                body['success'] == true || body['code'] == 'OK';
          }
          return data;
        }
        return body;
      }
    } catch (e) {
      developer.log('[API Exception] Error in checkW2WRecipient: $e');
    }
    return null;
  }

  /// Execute W2W wallet transfer via POST /api/v1/wallet/transfer/w2w
  Future<Map<String, dynamic>?> transferW2W({
    required String toMobileNumber,
    required double amount,
    required String idempotencyKey,
    String fromProductId = 'GENERAL',
    String productId = 'GENERAL',
    String description = 'Wallet to wallet transfer',
  }) async {
    try {
      final payload = {
        'toMobileNumber': toMobileNumber,
        'amount': amount,
        'idempotencyKey': idempotencyKey,
        'fromProductId': fromProductId,
        'productId': productId,
        'description': description,
      };

      developer.log('[API /wallet/transfer/w2w Request] $payload');

      final response = await postRequest<Map<String, dynamic>>(
        '/api/v1/wallet/transfer/w2w',
        payload,
      );

      developer.log(
        '[API /wallet/transfer/w2w Response] Status: ${response.statusCode}, Body: ${response.body}',
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
      developer.log('[API Exception] Error in transferW2W: $e');
    }
    return null;
  }

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
  Future<Map<String, dynamic>?> registerDeviceToken(String fcmToken) async {
    try {
      final token = fcmToken.trim();
      if (token.isEmpty) {
        developer.log(
          '[API /api/v1/devices] fcmToken is empty. Skipping registration.',
        );
        return null;
      }

      final platform = GetPlatform.isIOS ? 'ios' : 'android';
      final payload = {'platform': platform, 'fcmToken': token};

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
      final query = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

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
}

