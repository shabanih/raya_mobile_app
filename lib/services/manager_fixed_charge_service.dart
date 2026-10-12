
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerFixedChargeService {
  final ApiService _api = ApiService();

  // =====================================================
  // تبدیل پاسخ JSON به Map
  // =====================================================

  Map<String, dynamic> _decodeMap(String body) {
    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('پاسخ سرور معتبر نیست.');
  }

  // =====================================================
  // استخراج پیام خطای سرور
  // =====================================================

  String _errorMessage(
      int statusCode,
      String body,
      ) {
    try {
      final data = _decodeMap(body);

      final detail = data['detail']?.toString();
      if (detail != null && detail.isNotEmpty) {
        return detail;
      }

      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return message;
      }

      final errors = data['errors'];
      if (errors is Map) {
        final messages = <String>[];

        errors.forEach((key, value) {
          if (value is List) {
            messages.addAll(
              value.map((item) => item.toString()),
            );
          } else {
            messages.add(value.toString());
          }
        });

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    } catch (_) {}

    switch (statusCode) {
      case 400:
        return 'اطلاعات ارسالی صحیح نیست.';
      case 401:
        return 'نشست شما منقضی شده است؛ دوباره وارد شوید.';
      case 403:
        return 'شما اجازه انجام این عملیات را ندارید.';
      case 404:
        return 'شارژ موردنظر پیدا نشد.';
      case 409:
        return 'این شارژ به دلیل وضعیت مالی یا ارسال اطلاعیه قابل تغییر نیست.';
      default:
        return 'خطای سرور: $statusCode';
    }
  }

  Never _throwResponseError(
      int statusCode,
      String body,
      ) {
    final message = _errorMessage(statusCode, body);

    debugPrint('FIXED CHARGE ERROR: $statusCode');
    debugPrint('FIXED CHARGE ERROR BODY: $body');

    throw Exception(message);
  }

  // =====================================================
  // دریافت فهرست شارژهای واحدی
  // GET /api/manager/charges/fixed/
  // =====================================================

  Future<List<Map<String, dynamic>>> getCharges() async {
    final response = await _api.get(
      ApiConfig.managerFixedCharges,
    );

    debugPrint('FIXED CHARGES STATUS: ${response.statusCode}');

    if (response.statusCode != 200) {
      _throwResponseError(
        response.statusCode,
        response.body,
      );
    }

    final data = _decodeMap(response.body);
    final results = data['results'];

    if (results is! List) {
      throw Exception('ساختار فهرست شارژهای واحدی معتبر نیست.');
    }

    return results
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList();
  }

  // =====================================================
  // دریافت جزئیات یک شارژ
  // GET /api/manager/charges/fixed/{id}/
  // =====================================================

  Future<Map<String, dynamic>> getCharge(int id) async {
    final response = await _api.get(
      '${ApiConfig.managerFixedCharges}$id/',
    );

    if (response.statusCode != 200) {
      _throwResponseError(
        response.statusCode,
        response.body,
      );
    }

    final data = _decodeMap(response.body);

    // API فعلی جزئیات را مستقیماً برمی‌گرداند.
    // پشتیبانی از پاسخ دارای کلید charge نیز اضافه شده است.
    final charge = data['charge'];

    if (charge is Map) {
      return Map<String, dynamic>.from(charge);
    }

    return data;
  }

  // =====================================================
  // افزودن شارژ واحدی
  // POST /api/manager/charges/fixed/
  // =====================================================

  Future<Map<String, dynamic>> createCharge({
    required String name,
    required int fixAmount,
    required String paymentDeadline,
    int otherCostAmount = 0,
    int paymentPenaltyAmount = 0,
    String details = '',
  }) async {
    final response = await _api.post(
      ApiConfig.managerFixedCharges,
      body: {
        'name': name.trim(),
        'fix_amount': fixAmount,
        'payment_deadline': paymentDeadline,
        'other_cost_amount': otherCostAmount,
        'payment_penalty_amount': paymentPenaltyAmount,
        'details': details.trim(),
      },
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      _throwResponseError(
        response.statusCode,
        response.body,
      );
    }

    final data = _decodeMap(response.body);
    final charge = data['charge'];

    if (charge is Map) {
      return Map<String, dynamic>.from(charge);
    }

    return data;
  }

  // =====================================================
  // ویرایش شارژ واحدی
  // PATCH /api/manager/charges/fixed/{id}/
  // =====================================================

  Future<Map<String, dynamic>> updateCharge({
    required int id,
    required String name,
    required int fixAmount,
    required String paymentDeadline,
    int otherCostAmount = 0,
    int paymentPenaltyAmount = 0,
    String details = '',
  }) async {
    final response = await _api.patch(
      '${ApiConfig.managerFixedCharges}$id/',
      body: {
        'name': name.trim(),
        'fix_amount': fixAmount,
        'payment_deadline': paymentDeadline,
        'other_cost_amount': otherCostAmount,
        'payment_penalty_amount': paymentPenaltyAmount,
        'details': details.trim(),
      },
    );

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      _throwResponseError(
        response.statusCode,
        response.body,
      );
    }

    final data = _decodeMap(response.body);
    final charge = data['charge'];

    if (charge is Map) {
      return Map<String, dynamic>.from(charge);
    }

    return data;
  }

  // =====================================================
  // حذف شارژ واحدی
  // DELETE /api/manager/charges/fixed/{id}/
  // =====================================================

  Future<void> deleteCharge(int id) async {
    final response = await _api.delete(
      '${ApiConfig.managerFixedCharges}$id/',
    );

    if (response.statusCode == 200 ||
        response.statusCode == 202 ||
        response.statusCode == 204) {
      return;
    }

    // خطای 409 با پیام دقیق سرور به صفحه منتقل می‌شود.
    _throwResponseError(
      response.statusCode,
      response.body,
    );
  }
}
