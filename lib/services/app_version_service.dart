
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import 'api_service.dart';

class AppVersionService {
  static const MethodChannel _channel =
  MethodChannel('raya_charge/app_info');

  Future<Map<String, dynamic>> checkUpdate() async {
    try {
      // نسخه نصب شده روی گوشی
      final String installedVersion =
          await _channel.invokeMethod<String>('getAppVersion') ?? '0.0.0';

      // دریافت نسخه از سرور
      final response = await ApiService().get(ApiConfig.appVersion);

      if (response.statusCode != 200) {
        throw Exception(
          'خطا در دریافت نسخه از سرور: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw Exception('ساختار پاسخ سرور معتبر نیست.');
      }

      final data = Map<String, dynamic>.from(decoded);

      final String serverVersion =
          data['version']?.toString() ?? '0.0.0';

      // گزارش برای بررسی در Debug Console
      debugPrint('========== APP VERSION CHECK ==========');
      debugPrint('Installed Version: $installedVersion');
      debugPrint('Server Version: $serverVersion');
      debugPrint(
        'Has Update: ${_isNewer(serverVersion, installedVersion)}',
      );
      debugPrint('=======================================');

      return {
        ...data,
        'installed_version': installedVersion,
        'has_update': _isNewer(serverVersion, installedVersion),
      };
    } catch (e) {
      debugPrint('Version Check Error: $e');
      throw Exception('خطا در بررسی بروزرسانی: $e');
    }
  }

  bool _isNewer(String server, String installed) {
    final serverParts =
    server.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final installedParts =
    installed.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final length = serverParts.length > installedParts.length
        ? serverParts.length
        : installedParts.length;

    for (int i = 0; i < length; i++) {
      final s = i < serverParts.length ? serverParts[i] : 0;
      final c = i < installedParts.length ? installedParts[i] : 0;

      if (s > c) return true;
      if (s < c) return false;
    }

    return false;
  }
}
