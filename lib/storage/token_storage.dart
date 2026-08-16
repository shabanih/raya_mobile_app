import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _firstLoginCompletedKey =
      'first_login_completed';

  // =====================================================
  // ذخیره Token ها
  // =====================================================

  static Future<void> saveTokens(
      String accessToken,
      String refreshToken,
      ) async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setString(
      _accessTokenKey,
      accessToken,
    );

    await prefs.setString(
      _refreshTokenKey,
      refreshToken,
    );

    // بعد از اولین ورود موفق
    await prefs.setBool(
      _firstLoginCompletedKey,
      true,
    );
  }

  // =====================================================
  // Access Token
  // =====================================================

  static Future<String?> getAccessToken() async {
    final prefs =
    await SharedPreferences.getInstance();

    return prefs.getString(
      _accessTokenKey,
    );
  }

  // =====================================================
  // Refresh Token
  // =====================================================

  static Future<String?> getRefreshToken() async {
    final prefs =
    await SharedPreferences.getInstance();

    return prefs.getString(
      _refreshTokenKey,
    );
  }

  // =====================================================
  // ثبت اولین ورود موفق
  // =====================================================

  static Future<void> setFirstLoginCompleted() async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setBool(
      _firstLoginCompletedKey,
      true,
    );
  }

  // =====================================================
  // بررسی اینکه کاربر قبلاً لاگین کرده یا نه
  // =====================================================

  static Future<bool> isFirstLoginCompleted() async {
    final prefs =
    await SharedPreferences.getInstance();

    return prefs.getBool(
      _firstLoginCompletedKey,
    ) ??
        false;
  }

  // =====================================================
  // فعال کردن ورود با اثر انگشت
  // =====================================================

  static Future<void> enableBiometric() async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setBool(
      _biometricEnabledKey,
      true,
    );
  }

  // =====================================================
  // غیرفعال کردن ورود با اثر انگشت
  // =====================================================

  static Future<void> disableBiometric() async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setBool(
      _biometricEnabledKey,
      false,
    );
  }

  // =====================================================
  // بررسی فعال بودن اثر انگشت
  // =====================================================

  static Future<bool> isBiometricEnabled() async {
    final prefs =
    await SharedPreferences.getInstance();

    return prefs.getBool(
      _biometricEnabledKey,
    ) ??
        false;
  }

  // =====================================================
  // پاک کردن اطلاعات ورود
  // =====================================================

  static Future<void> clear() async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.remove(
      _accessTokenKey,
    );

    await prefs.remove(
      _refreshTokenKey,
    );

    await prefs.remove(
      _biometricEnabledKey,
    );

    await prefs.remove(
      _firstLoginCompletedKey,
    );
  }
}