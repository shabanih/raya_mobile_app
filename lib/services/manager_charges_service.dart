
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerChargesService {
final ApiService _apiService;

ManagerChargesService({
ApiService? apiService,
}) : _apiService = apiService ?? ApiService();

// =====================================================
// دریافت اطلاعات صفحه اصلی مدیریت شارژها
// GET /api/manager/charges/
// =====================================================
  Future<List<Map<String, dynamic>>> getChargeMethods() async {

    final url = ApiConfig.managerChargeMethods;

    try {
      final response = await _apiService.get(url);

      debugPrint(
        'MANAGER CHARGE METHODS STATUS: ${response.statusCode}',
      );
      debugPrint('CHARGE METHODS RESPONSE: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is! Map<String, dynamic> ||
            decoded['success'] != true) {
          throw Exception('پاسخ روش‌های شارژ نامعتبر است.');
        }

        final results = decoded['results'];

        if (results is! List) {
          throw Exception('فهرست روش‌های شارژ نامعتبر است.');
        }

        return results
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      if (response.statusCode == 403) {
        throw Exception('شما مجاز به دریافت روش‌های شارژ نیستید.');
      }

      throw Exception(
        'خطا در دریافت روش‌های شارژ: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('MANAGER CHARGE METHODS ERROR: $e');
      rethrow;
    }
  }

Future<Map<String, dynamic>> getHome() async {
final url = ApiConfig.managerCharges;

try {
final response = await _apiService.get(url);

debugPrint('MANAGER CHARGES HOME STATUS: ${response.statusCode}');

if (response.statusCode == 200) {
final decoded = jsonDecode(response.body);

if (decoded is! Map<String, dynamic>) {
throw Exception(
'ساختار پاسخ مدیریت شارژها نامعتبر است.',
);
}

if (decoded['success'] != true) {
throw Exception(
decoded['message']?.toString() ??
'دریافت اطلاعات مدیریت شارژها ناموفق بود.',
);
}

return decoded;
}

if (response.statusCode == 403) {
throw Exception(
'شما مجاز به دسترسی به مدیریت شارژها نیستید.',
);
}

if (response.statusCode == 404) {
throw Exception(
'مسیر مدیریت شارژها در سرور پیدا نشد.',
);
}

throw Exception(
'خطا در دریافت اطلاعات مدیریت شارژها: '
'${response.statusCode}',
);
} catch (e) {
debugPrint('MANAGER CHARGES HOME ERROR: $e');
rethrow;
}
}
}
