
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerFixedChargeService {
  final ApiService _api = ApiService();

  String get _baseUrl => ApiConfig.managerFixedCharges;

  // ==================================================
  // تبدیل پاسخ JSON به Map
  // ==================================================
  Map<String, dynamic> _decodeMap(dynamic response) {
    dynamic data = _decodeBody(response);

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{};
  }

  dynamic _decodeBody(dynamic response) {
    if (response == null) return null;

    // پاسخ معمول http.Response
    try {
      final dynamic body = response.body;

      if (body is String) {
        if (body.trim().isEmpty) return <String, dynamic>{};
        return jsonDecode(body);
      }

      if (body != null) return body;
    } catch (_) {
      // ممکن است پاسخ از قبل Map یا List باشد.
    }

    if (response is String) {
      if (response.trim().isEmpty) return <String, dynamic>{};
      return jsonDecode(response);
    }

    return response;
  }

  bool _isSuccess(dynamic response) {
    try {
      final int code = response.statusCode as int;
      return code >= 200 && code < 300;
    } catch (_) {
      return false;
    }
  }

  String _errorMessage(
      dynamic response, {
        String fallback = 'خطا در انجام عملیات',
      }) {
    try {
      final data = _decodeMap(response);

      final detail = data['detail'] ??
          data['message'] ??
          data['error'];

      if (detail != null && detail.toString().trim().isNotEmpty) {
        return detail.toString();
      }

      final errors = data['errors'];

      if (errors is Map) {
        final messages = <String>[];

        errors.forEach((key, value) {
          if (value is List) {
            messages.addAll(value.map((item) => item.toString()));
          } else {
            messages.add(value.toString());
          }
        });

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    } catch (_) {
      // استفاده از پیام پیش‌فرض
    }

    return fallback;
  }

  Never _throwResponseError(
      dynamic response, {
        String fallback = 'خطا در انجام عملیات',
      }) {
    throw Exception(
      _errorMessage(response, fallback: fallback),
    );
  }

  List<Map<String, dynamic>> _decodeList(
      dynamic response, {
        List<String> keys = const ['results', 'data', 'items'],
      }) {
    final dynamic data = _decodeBody(response);
    dynamic items;

    if (data is List) {
      items = data;
    } else if (data is Map) {
      for (final key in keys) {
        if (data[key] is List) {
          items = data[key];
          break;
        }
      }
    }

    if (items is! List) {
      return <Map<String, dynamic>>[];
    }

    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // ==================================================
  // دریافت فهرست شارژهای ثابت
  // GET /manager/charges/fixed/
  // ==================================================
  Future<List<Map<String, dynamic>>> getCharges() async {
    final response = await _api.get(_baseUrl);

    if (!_isSuccess(response)) {
      _throwResponseError(
        response,
        fallback: 'دریافت فهرست شارژهای ثابت ناموفق بود',
      );
    }

    final result = _decodeList(
      response,
      keys: const ['results', 'charges', 'data', 'items'],
    );

    debugPrint('FIXED CHARGES COUNT: ${result.length}');

    return result;
  }

  // ==================================================
  // دریافت جزئیات یک شارژ
  // GET /manager/charges/fixed/{id}/
  // ==================================================
  Future<Map<String, dynamic>> getCharge(int id) async {
    final response = await _api.get('$_baseUrl$id/');

    if (!_isSuccess(response)) {
      _throwResponseError(
        response,
        fallback: 'دریافت اطلاعات شارژ ناموفق بود',
      );
    }

    final data = _decodeMap(response);

    if (data['charge'] is Map) {
      return Map<String, dynamic>.from(data['charge'] as Map);
    }

    return data;
  }

  // ==================================================
  // ایجاد شارژ ثابت
  // ==================================================
  Future<Map<String, dynamic>> createCharge({
    required String name,
    required dynamic fixAmount,
    required String paymentDeadline,
    dynamic otherCostAmount = 0,
    dynamic paymentPenaltyAmount = 0,
    String details = '',
  }) async {
    final response = await _api.post(
      _baseUrl,
      body: <String, dynamic>{
        'name': name,
        'fix_amount': fixAmount,
        'payment_deadline': paymentDeadline,
        'other_cost_amount': otherCostAmount,
        'payment_penalty_amount': paymentPenaltyAmount,
        'details': details,
      },
    );

    if (!_isSuccess(response)) {
      _throwResponseError(
        response,
        fallback: 'ایجاد شارژ ثابت ناموفق بود',
      );
    }

    final data = _decodeMap(response);

    if (data['charge'] is Map) {
      return Map<String, dynamic>.from(data['charge'] as Map);
    }

    return data;
  }

  // ==================================================
  // ویرایش شارژ ثابت
  // توجه: شناسه شارژ باید آرگومان اول باشد.
  // ==================================================
  Future<Map<String, dynamic>> updateCharge(
      int id, {
        required String name,
        required dynamic fixAmount,
        required String paymentDeadline,
        dynamic otherCostAmount = 0,
        dynamic paymentPenaltyAmount = 0,
        String details = '',
      }) async {
    final response = await _api.patch(
      '$_baseUrl$id/',
      body: <String, dynamic>{
        'name': name,
        'fix_amount': fixAmount,
        'payment_deadline': paymentDeadline,
        'other_cost_amount': otherCostAmount,
        'payment_penalty_amount': paymentPenaltyAmount,
        'details': details,
      },
    );

    if (!_isSuccess(response)) {
      _throwResponseError(
        response,
        fallback: 'ویرایش شارژ ثابت ناموفق بود',
      );
    }

    final data = _decodeMap(response);

    if (data['charge'] is Map) {
      return Map<String, dynamic>.from(data['charge'] as Map);
    }

    return data;
  }

  // ==================================================
  // حذف شارژ ثابت
  // ==================================================
  Future<void> deleteCharge(int id) async {
    final response = await _api.delete('$_baseUrl$id/');

    if (!_isSuccess(response)) {
      _throwResponseError(
        response,
        fallback: 'حذف شارژ ثابت ناموفق بود',
      );
    }
  }

  // ==================================================
  // دریافت واحدهای مربوط به یک شارژ
  // GET /manager/charges/fixed/{id}/units/
  // ==================================================
  Future<List<Map<String, dynamic>>> getChargeUnits(
      int chargeId,
      ) async {
    final response = await _api.get(
      '$_baseUrl$chargeId/units/',
    );

    if (!_isSuccess(response)) {
      _throwResponseError(
        response,
        fallback: 'دریافت وضعیت واحدها ناموفق بود',
      );
    }

    final result = _decodeList(
      response,
      keys: const ['results', 'units', 'data', 'items'],
    );

    debugPrint('FIXED CHARGE UNITS COUNT: ${result.length}');

    return result;
  }

  // ==================================================
  // ارسال شارژ به واحدهای انتخاب‌شده
  // POST /manager/charges/fixed/{id}/units/send/
  //
  // sendSms=false : فقط ارسال سیستمی
  // sendSms=true  : ارسال سیستمی و پیامکی
  // ==================================================
  Future<Map<String, dynamic>> sendChargeToUnits(
      int chargeId,
      List<int> unitIds, {
        bool sendSms = false,
      }) async {
    if (unitIds.isEmpty) {
      throw Exception('حداقل یک واحد را انتخاب کنید.');
    }

    final response = await _api.post(
      '$_baseUrl$chargeId/units/send/',
      body: <String, dynamic>{
        'unit_ids': unitIds,
        'send_sms': sendSms,
      },
    );

    if (!_isSuccess(response)) {
      _throwResponseError(
        response,
        fallback: 'ارسال شارژ به واحدها ناموفق بود',
      );
    }

    final data = _decodeMap(response);

    debugPrint('FIXED CHARGE SEND RESPONSE: $data');

    return data;
  }

  // ==================================================
  // لغو شارژ برای واحدهای انتخاب‌شده
  // ==================================================
  Future<Map<String, dynamic>> cancelChargeForUnits(
      int chargeId,
      List<int> unitIds,
      ) async {
    if (unitIds.isEmpty) {
      throw Exception('حداقل یک واحد را انتخاب کنید.');
    }

    final response = await _api.post(
      '$_baseUrl$chargeId/units/cancel/',
      body: <String, dynamic>{
        'unit_ids': unitIds,
      },
    );

    if (!_isSuccess(response)) {
      _throwResponseError(
        response,
        fallback: 'لغو شارژ برای واحدها ناموفق بود',
      );
    }

    return _decodeMap(response);
  }
}
