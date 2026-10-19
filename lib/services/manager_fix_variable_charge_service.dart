
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerFixVariableChargeService {
  final ApiService _api = ApiService();

  String get _baseUrl => ApiConfig.managerFixVariableCharges;

  // --------------------------------------------------
  // تبدیل پاسخ API
  // --------------------------------------------------

  dynamic _decodeBody(dynamic response) {
    if (response == null) return null;

    try {
      final dynamic body = response.body;

      if (body is String) {
        if (body.trim().isEmpty) {
          return <String, dynamic>{};
        }

        return jsonDecode(body);
      }

      if (body != null) return body;
    } catch (_) {}

    if (response is String) {
      if (response.trim().isEmpty) {
        return <String, dynamic>{};
      }

      return jsonDecode(response);
    }

    return response;
  }

  Map<String, dynamic> _decodeMap(dynamic response) {
    final data = _decodeBody(response);

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _decodeList(
      dynamic response, {
        List<String> keys = const ['results', 'data', 'items'],
      }) {
    final data = _decodeBody(response);
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

      // خطاهای اختصاصی فیلدها
      final errors = data['errors'];

      if (errors is Map && errors.isNotEmpty) {
        final messages = <String>[];

        errors.forEach((key, value) {
          if (value is List) {
            messages.addAll(
              value.map((item) => item.toString()),
            );
          } else if (value != null) {
            messages.add(value.toString());
          }
        });

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }

      // پیام عمومی سرور
      final detail =
          data['detail'] ?? data['message'] ?? data['error'];

      if (detail != null &&
          detail.toString().trim().isNotEmpty) {
        return detail.toString();
      }

      // پشتیبانی از پاسخ‌های غیر استاندارد
      final messages = <String>[];

      data.forEach((key, value) {
        if (value is List) {
          messages.addAll(
            value.map((item) => item.toString()),
          );
        } else if (value is String && key != 'success') {
          messages.add(value);
        }
      });

      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    } catch (e) {
      debugPrint('ERROR PARSING API RESPONSE: $e');
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

  Map<String, dynamic> _unwrapCharge(dynamic response) {
    final data = _decodeMap(response);

    if (data['charge'] is Map) {
      return Map<String, dynamic>.from(
        data['charge'] as Map,
      );
    }

    return data;
  }

  // --------------------------------------------------
  // فهرست شارژها
  // GET manager/fix-variable-charges/
  // --------------------------------------------------

  Future<List<Map<String, dynamic>>> getCharges() async {
    final response = await _api.get(_baseUrl);

    debugPrint(
      'FIX VARIABLE STATUS: ${response.statusCode}',
    );

    if (!_isSuccess(response)) {
      _throwResponseError(
        response,
        fallback: 'دریافت فهرست شارژها ناموفق بود',
      );
    }

    return _decodeList(
      response,
      keys: const [
        'results',
        'charges',
        'data',
        'items',
      ],
    );
  }

  // --------------------------------------------------
  // جزئیات شارژ
  // GET manager/fix-variable-charges/{id}/
  // --------------------------------------------------

  Future<Map<String, dynamic>> getCharge(int id) async {
    final response = await _api.get('$_baseUrl$id/');

    if (!_isSuccess(response)) {
      _throwResponseError(
        response,
        fallback: 'دریافت اطلاعات شارژ ناموفق بود',
      );
    }

    return _unwrapCharge(response);
  }

  // --------------------------------------------------
  // ایجاد شارژ
  // POST manager/fix-variable-charges/
  // --------------------------------------------------

  Future<Map<String, dynamic>> createCharge({
    required String name,
    required dynamic unitFixAmount,
    required dynamic unitVariablePersonAmount,
    required dynamic unitVariableAreaAmount,
    required String paymentDeadline,
    dynamic extraParkingAmount = 0,
    dynamic otherCostAmount = 0,
    dynamic civil = 0,
    dynamic paymentPenaltyAmount = 0,
    String details = '',
  }) async {
    final response = await _api.post(
      _baseUrl,
      body: <String, dynamic>{
        'name': name,
        'unit_fix_amount': unitFixAmount,
        'unit_variable_person_amount':
        unitVariablePersonAmount,
        'unit_variable_area_amount':
        unitVariableAreaAmount,
        'extra_parking_amount': extraParkingAmount,
        'payment_deadline': paymentDeadline,
        'other_cost_amount': otherCostAmount,
        'civil': civil,
        'payment_penalty_amount': paymentPenaltyAmount,
        'details': details,
      },
    );

    if (!_isSuccess(response)) {
      debugPrint(
        'FIX VARIABLE CREATE: ${response.body}',
      );

      _throwResponseError(
        response,
        fallback: 'ایجاد شارژ ثابت و متغیر ناموفق بود',
      );
    }

    return _unwrapCharge(response);
  }

  // --------------------------------------------------
  // ویرایش شارژ
  // PATCH manager/fix-variable-charges/{id}/
  // --------------------------------------------------

  Future<Map<String, dynamic>> updateCharge(
      int id, {
        required String name,
        required dynamic unitFixAmount,
        required dynamic unitVariablePersonAmount,
        required dynamic unitVariableAreaAmount,
        required String paymentDeadline,
        dynamic extraParkingAmount = 0,
        dynamic otherCostAmount = 0,
        dynamic civil = 0,
        dynamic paymentPenaltyAmount = 0,
        String details = '',
      }) async {
    final response = await _api.patch(
      '$_baseUrl$id/',
      body: <String, dynamic>{
        'name': name,
        'unit_fix_amount': unitFixAmount,
        'unit_variable_person_amount':
        unitVariablePersonAmount,
        'unit_variable_area_amount':
        unitVariableAreaAmount,
        'extra_parking_amount': extraParkingAmount,
        'payment_deadline': paymentDeadline,
        'other_cost_amount': otherCostAmount,
        'civil': civil,
        'payment_penalty_amount': paymentPenaltyAmount,
        'details': details,
      },
    );

    if (!_isSuccess(response)) {
      debugPrint(
        'FIX VARIABLE UPDATE: ${response.body}',
      );

      _throwResponseError(
        response,
        fallback: 'ویرایش شارژ ثابت و متغیر ناموفق بود',
      );
    }

    return _unwrapCharge(response);
  }

  // --------------------------------------------------
  // حذف شارژ
  // DELETE manager/fix-variable-charges/{id}/
  // --------------------------------------------------

  Future<void> deleteCharge(int id) async {
    final response = await _api.delete('$_baseUrl$id/');

    if (!_isSuccess(response)) {
      _throwResponseError(
        response,
        fallback: 'حذف شارژ ثابت و متغیر ناموفق بود',
      );
    }
  }

  // --------------------------------------------------
  // دریافت اطلاعات کامل واحدهای شارژ
  // GET manager/fix-variable-charges/{id}/units/
  //
  // خروجی شامل اطلاعات کلی شارژ مانند:
  // payment_deadline
  // charge_name
  // total_area
  // total_people
  // و فهرست results است.
  // --------------------------------------------------

  Future<Map<String, dynamic>> getChargeUnitsData(
      int chargeId, {
        String? search,
        String? residentType,
      }) async {
    var url = '$_baseUrl$chargeId/units/';

    final queryParameters = <String, String>{};

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    if (residentType != null &&
        residentType.isNotEmpty &&
        residentType != 'all') {
      queryParameters['resident_type'] = residentType;
    }

    if (queryParameters.isNotEmpty) {
      url = '$url?${Uri(queryParameters: queryParameters).query}';
    }

    final response = await _api.get(url);

    debugPrint(
      'FIX VARIABLE UNITS STATUS: ${response.statusCode}',
    );

    if (!_isSuccess(response)) {
      debugPrint(
        'FIX VARIABLE UNITS ERROR: ${response.body}',
      );

      _throwResponseError(
        response,
        fallback: 'دریافت وضعیت واحدها ناموفق بود',
      );
    }

    final data = _decodeMap(response);

    if (data.isEmpty) {
      throw Exception('پاسخ سرور خالی یا نامعتبر است.');
    }

    debugPrint(
      'FIX VARIABLE PAYMENT DEADLINE: '
          '${data['payment_deadline']}',
    );

    return data;
  }

  // --------------------------------------------------
  // فهرست واحدهای شارژ
  // سازگار با کدهای قبلی
  // --------------------------------------------------

  Future<List<Map<String, dynamic>>> getChargeUnits(
      int chargeId, {
        String? search,
        String? residentType,
      }) async {
    final data = await getChargeUnitsData(
      chargeId,
      search: search,
      residentType: residentType,
    );

    return _decodeList(
      data,
      keys: const [
        'results',
        'units',
        'data',
        'items',
      ],
    );
  }

  // --------------------------------------------------
  // ارسال اعلان و پیامک
  // POST manager/fix-variable-charges/{id}/send/
  // --------------------------------------------------

  Future<Map<String, dynamic>> sendChargeToUnits(
      int chargeId,
      List<int> unitIds, {
        bool sendSms = false,
      }) async {
    if (unitIds.isEmpty) {
      throw Exception('حداقل یک واحد را انتخاب کنید.');
    }

    final response = await _api.post(
      '$_baseUrl$chargeId/send/',
      body: <String, dynamic>{
        'unit_ids': unitIds,
        'send_sms': sendSms,
      },
    );

    if (!_isSuccess(response)) {
      debugPrint(
        'FIX VARIABLE SEND: ${response.body}',
      );

      _throwResponseError(
        response,
        fallback: 'ارسال شارژ به واحدها ناموفق بود',
      );
    }

    return _decodeMap(response);
  }

  // --------------------------------------------------
  // لغو اعلان
  // POST manager/fix-variable-charges/{id}/cancel/
  // --------------------------------------------------

  Future<Map<String, dynamic>> cancelChargeForUnits(
      int chargeId,
      List<int> unitIds,
      ) async {
    if (unitIds.isEmpty) {
      throw Exception('واحدهای موردنظر را انتخاب کنید.');
    }

    final response = await _api.post(
      '$_baseUrl$chargeId/cancel/',
      body: <String, dynamic>{
        'unit_ids': unitIds,
      },
    );

    if (!_isSuccess(response)) {
      debugPrint(
        'FIX VARIABLE CANCEL: ${response.body}',
      );

      _throwResponseError(
        response,
        fallback: 'لغو اعلان شارژ ناموفق بود',
      );
    }

    return _decodeMap(response);
  }
}
