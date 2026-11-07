import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class AppInstallationService {
  static const String _installationIdKey = 'app_installation_id';

  static const Uuid _uuid = Uuid();

  static const MethodChannel _channel =
  MethodChannel('raya_charge/app_info');

  // =====================================================
  // دریافت نسخه نصب‌شده روی گوشی
  // =====================================================

  static Future<String> _getInstalledVersion() async {
    try {
      final version =
      await _channel.invokeMethod<String>('getAppVersion');

      return version ?? '';
    } catch (e) {
      debugPrint('Get installed app version error: $e');
      return '';
    }
  }

  // =====================================================
  // شناسه یکتای نصب
  // =====================================================

  static Future<String> _getInstallationId() async {
    final prefs = await SharedPreferences.getInstance();

    String? installationId =
    prefs.getString(_installationIdKey);

    if (installationId != null && installationId.isNotEmpty) {
      return installationId;
    }

    installationId = _uuid.v4();

    await prefs.setString(
      _installationIdKey,
      installationId,
    );

    return installationId;
  }

  // =====================================================
  // ثبت یا به‌روزرسانی نصب
  // =====================================================

  static Future<void> registerInstallation() async {
    try {
      final installationId = await _getInstallationId();

      // نسخه واقعی نصب‌شده روی گوشی
      final appVersion = await _getInstalledVersion();

      // توکن کاربر در صورت ورود
      final token = await TokenStorage.getAccessToken();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/app/installation/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'installation_id': installationId,
          'app_version': appVersion,
          'platform': Platform.isAndroid ? 'Android' : 'iOS',
          'device_name': 'Flutter Device',
        }),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'App installation error: ${response.statusCode} '
              '${response.body}',
        );
      } else {
        debugPrint('========== APP INSTALLATION ==========');
        debugPrint('Installation ID: $installationId');
        debugPrint('App Version: $appVersion');
        debugPrint('Platform: ${Platform.isAndroid ? 'Android' : 'iOS'}');
        debugPrint('Response: ${response.body}');
        debugPrint('======================================');
      }
    } catch (e) {
      debugPrint('App installation exception: $e');
    }
  }
}