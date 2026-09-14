import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

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

  /// Save session details
  Future<void> saveSession({
    required String token,
    String? refreshToken,
    String? tokenType,
    dynamic expiresIn,
    required String userId,
    Map<String, dynamic>? userData,
  }) async {
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
    if (userData != null) {
      await _storage.write(_keyUserData, userData);
      if (userData['name'] != null && userData['name'].toString().isNotEmpty) {
        await _storage.write('name', userData['name']);
      }
      if (userData['phone'] != null && userData['phone'].toString().isNotEmpty) {
        await _storage.write('phone', userData['phone']);
      }
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

  /// Clear session/Logout completely
  Future<void> logout() async {
    await _storage.remove('remember_me');
    await _storage.remove('remembered_name');
    await _storage.remove('remembered_phone');

    await _storage.remove(_keyToken);
    await _storage.remove('accessToken');
    await _storage.remove(_keyRefreshToken);
    await _storage.remove('refreshToken');
    await _storage.remove('refresh_token');
    await _storage.remove(_keyTokenType);
    await _storage.remove('tokenType');
    await _storage.remove(_keyExpiresIn);
    await _storage.remove('expiresIn');
    await _storage.remove(_keyUserId);
    await _storage.write(_keyIsLoggedIn, false);
    await _storage.remove(_keyUserData);
    await _storage.remove('name');
    await _storage.remove('email');
    await _storage.remove('phone');
    await _storage.remove('profilePictureUrl');
    await _storage.remove('address');
    await _storage.remove('pan');
    await _storage.remove('balance');
    await _storage.remove('entityId');
    await _storage.remove('registrationToken');
  }
}
