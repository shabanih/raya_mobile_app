import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class ManagerCivilChargeService {
  static String get _baseUrl =>
      ApiConfig.managerCivilCharges;

  // =====================================================
  // دریافت توکن
  // =====================================================

  static Future<String> _getToken() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('توکن ورود پیدا نشد.');
    }

    return token.trim();
  }

  // =====================================================
  // هدر درخواست
  // =====================================================

  static Future<Map<String, String>> _headers() async {
    return {
      'Authorization': 'Bearer ${await _getToken()}',
      'Accept': 'application/json',
    };
  }

  // =====================================================
  // تبدیل پاسخ API
  // =====================================================

  static Map<String, dynamic> _decodeResponse(
      http.Response response,
      ) {
    final body = utf8.decode(response.bodyBytes);

    print('======================================');
    print('MANAGER CIVIL CHARGE API');
    print('STATUS: ${response.statusCode}');
    print(
      'CONTENT-TYPE: ${response.headers['content-type']}',
    );
    print('BODY: $body');
    print('======================================');

    if (body.trim().isEmpty) {
      return {
        'success': response.statusCode >= 200 &&
            response.statusCode < 300,
        'message': response.statusCode >= 200 &&
            response.statusCode < 300
            ? 'عملیات با موفقیت انجام شد.'
            : 'پاسخ سرور خالی است.',
      };
    }

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      if (decoded is List) {
        return {
          'success': true,
          'results': decoded,
        };
      }

      return {
        'success': false,
        'message': 'پاسخ سرور نامعتبر است.',
      };
    } catch (_) {
      return {
        'success': false,
        'message':
        'پاسخ سرور قابل پردازش نیست. '
            'HTTP ${response.statusCode}',
        'debug_body': body,
      };
    }
  }

  // =====================================================
  // بررسی پاسخ
  // =====================================================

  static void _checkResponse(
      http.Response response,
      Map<String, dynamic> data, {
        required List<int> successCodes,
        required String fallbackMessage,
      }) {
    final statusOk = successCodes.contains(
      response.statusCode,
    );

    if (statusOk && data['success'] != false) {
      return;
    }

    final message = data['message']?.toString();

    if (message != null && message.trim().isNotEmpty) {
      throw Exception(message);
    }

    final errors = data['errors'];

    if (errors != null) {
      throw Exception('$errors');
    }

    throw Exception(
      '$fallbackMessage (HTTP ${response.statusCode})',
    );
  }

  // =====================================================
  // تبدیل مقدار به عدد صحیح
  // =====================================================

  static int toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    final normalized = _normalizeDigits(
      value?.toString() ?? '',
    );

    return int.tryParse(normalized) ?? 0;
  }

  static String _normalizeDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';

    for (var i = 0; i < 10; i++) {
      value = value.replaceAll(
        persian[i],
        '$i',
      );
      value = value.replaceAll(
        arabic[i],
        '$i',
      );
    }

    return value.trim();
  }

  // =====================================================
  // دریافت فهرست شارژهای عمرانی
  // GET manager/civil-charges/
  // =====================================================

  static Future<List<Map<String, dynamic>>>
  getCharges() async {
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: await _headers(),
    );

    final data = _decodeResponse(response);

    _checkResponse(
      response,
      data,
      successCodes: [200],
      fallbackMessage:
      'دریافت فهرست شارژهای عمرانی ناموفق بود.',
    );

    final items = data['results'];

    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList();
  }

  // =====================================================
  // دریافت یک شارژ از فهرست
  // =====================================================

  static Future<Map<String, dynamic>?> getCharge(
      int id,
      ) async {
    final charges = await getCharges();

    for (final charge in charges) {
      if (toInt(charge['id']) == id) {
        return charge;
      }
    }

    return null;
  }

  // =====================================================
  // اعتبارسنجی اطلاعات شارژ
  // =====================================================

  static void _validateCharge({
    required String name,
    required int amount,
    required int prepayment,
    required int installmentCount,
    required String firstDueDate,
    required String unitScope,
    required List<File> files,
  }) {
    if (name.trim().isEmpty) {
      throw Exception('عنوان شارژ عمرانی را وارد کنید.');
    }

    if (!['all', 'occupied', 'vacant'].contains(unitScope)) {
      throw Exception('محدوده واحدهای مشمول معتبر نیست.');
    }

    if (amount <= 0) {
      throw Exception(
        'مبلغ شارژ باید بیشتر از صفر باشد.',
      );
    }

    if (prepayment < 0 || prepayment > amount) {
      throw Exception(
        'پیش‌پرداخت باید بین صفر و مبلغ شارژ باشد.',
      );
    }

    if (installmentCount < 0) {
      throw Exception(
        'تعداد اقساط نمی‌تواند منفی باشد.',
      );
    }

    // پرداخت یکجا:
    // پیش‌پرداخت برابر مبلغ کل و تعداد اقساط صفر است.
    //
    // پرداخت اقساطی:
    // مبلغ باقی‌مانده باید دارای تعداد اقساط باشد.
    if (prepayment < amount &&
        installmentCount == 0 &&
        prepayment != 0) {
      throw Exception(
        'برای مبلغ باقی‌مانده، تعداد اقساط را وارد کنید.',
      );
    }

    if (firstDueDate.trim().isEmpty) {
      throw Exception(
        'تاریخ اولین سررسید را وارد کنید.',
      );
    }

    if (files.length > 2) {
      throw Exception(
        'حداکثر دو فایل جدید مجاز است.',
      );
    }
  }

  // =====================================================
  // ایجاد درخواست Multipart
  // =====================================================

  static Future<http.MultipartRequest>
  _buildMultipartRequest({
    required String method,
    required Uri uri,
    required String name,
    required int amount,
    required int prepayment,
    required int installmentCount,
    required String firstDueDate,
    required String unitScope,
    required String details,
    required List<File> files,
  }) async {
    final request = http.MultipartRequest(
      method,
      uri,
    );

    request.headers.addAll(await _headers());

    request.fields['name'] = name.trim();
    request.fields['amount'] = amount.toString();
    request.fields['prepayment'] =
        prepayment.toString();
    request.fields['installment_count'] =
        installmentCount.toString();
    request.fields['first_due_date'] =
        firstDueDate.trim();
    request.fields['unit_scope'] = unitScope;
    request.fields['details'] = details;

    for (final file in files) {
      if (!await file.exists()) {
        throw Exception(
          'فایل انتخاب‌شده پیدا نشد.',
        );
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'document',
          file.path,
        ),
      );
    }

    return request;
  }

  // =====================================================
  // ایجاد شارژ عمرانی
  // POST manager/civil-charges/
  // =====================================================

  static Future<Map<String, dynamic>> createCharge({
    required String name,
    required int amount,
    int prepayment = 0,
    required int installmentCount,
    required String firstDueDate,
    String unitScope = 'all',
    String details = '',
    List<File> files = const [],
  }) async {
    _validateCharge(
      name: name,
      amount: amount,
      prepayment: prepayment,
      installmentCount: installmentCount,
      firstDueDate: firstDueDate,
      unitScope: unitScope,
      files: files,
    );

    final request = await _buildMultipartRequest(
      method: 'POST',
      uri: Uri.parse(_baseUrl),
      name: name,
      amount: amount,
      prepayment: prepayment,
      installmentCount: installmentCount,
      firstDueDate: firstDueDate,
      unitScope: unitScope,
      details: details,
      files: files,
    );

    final streamed = await request.send();

    final response = await http.Response.fromStream(
      streamed,
    );

    final data = _decodeResponse(response);

    _checkResponse(
      response,
      data,
      successCodes: [201],
      fallbackMessage: 'ثبت شارژ عمرانی انجام نشد.',
    );

    final result = data['result'];

    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }

    return data;
  }

  // =====================================================
  // ویرایش شارژ عمرانی
  // PUT manager/civil-charges/{id}/
  //
  // فایل‌های جدید به مدارک قبلی اضافه می‌شوند.
  // =====================================================

  static Future<Map<String, dynamic>> updateCharge({
    required int id,
    required String name,
    required int amount,
    int prepayment = 0,
    required int installmentCount,
    required String firstDueDate,
    String unitScope = 'all',
    String details = '',
    List<File> files = const [],
  }) async {
    _validateCharge(
      name: name,
      amount: amount,
      prepayment: prepayment,
      installmentCount: installmentCount,
      firstDueDate: firstDueDate,
      unitScope: unitScope,
      files: files,
    );

    final request = await _buildMultipartRequest(
      method: 'PUT',
      uri: Uri.parse('$_baseUrl$id/'),
      name: name,
      amount: amount,
      prepayment: prepayment,
      installmentCount: installmentCount,
      firstDueDate: firstDueDate,
      unitScope: unitScope,
      details: details,
      files: files,
    );

    final streamed = await request.send();

    final response = await http.Response.fromStream(
      streamed,
    );

    final data = _decodeResponse(response);

    _checkResponse(
      response,
      data,
      successCodes: [200],
      fallbackMessage: 'ویرایش شارژ عمرانی انجام نشد.',
    );

    final result = data['result'];

    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }

    return data;
  }

  // =====================================================
  // حذف شارژ عمرانی
  // DELETE manager/civil-charges/{id}/
  // =====================================================

  static Future<void> deleteCharge(int id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$id/'),
      headers: await _headers(),
    );

    final data = _decodeResponse(response);

    _checkResponse(
      response,
      data,
      successCodes: [200, 204],
      fallbackMessage: 'حذف شارژ عمرانی انجام نشد.',
    );
  }

  // =====================================================
  // دریافت واحدهای شارژ عمرانی
  // GET manager/civil-charges/{id}/units/
  // =====================================================

  static Future<List<Map<String, dynamic>>>
  getChargeUnits(int civilId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$civilId/units/'),
      headers: await _headers(),
    );

    final data = _decodeResponse(response);

    _checkResponse(
      response,
      data,
      successCodes: [200],
      fallbackMessage: 'دریافت واحدهای شارژ ناموفق بود.',
    );

    final items = data['results'];

    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList();
  }

  // =====================================================
  // دریافت اطلاعات کامل پاسخ واحدها
  // =====================================================

  static Future<Map<String, dynamic>>
  getChargeUnitsData(int civilId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$civilId/units/'),
      headers: await _headers(),
    );

    final data = _decodeResponse(response);

    _checkResponse(
      response,
      data,
      successCodes: [200],
      fallbackMessage: 'دریافت اطلاعات واحدها ناموفق بود.',
    );

    return data;
  }

  // =====================================================
  // ارسال شارژ به واحدهای انتخابی یا همه واحدها
  //
  // POST manager/civil-charges/{id}/send/
  //
  // unit_ids: [1, 2, 3]
  // all_units: true/false
  // =====================================================

  static Future<Map<String, dynamic>> sendChargeToUnits({
    required int civilId,
    List<int> unitIds = const [],
    bool allUnits = false,
  }) async {
    if (!allUnits && unitIds.isEmpty) {
      throw Exception(
        'حداقل یک واحد را برای ارسال انتخاب کنید.',
      );
    }

    final headers = await _headers();

    headers['Content-Type'] = 'application/json';

    final response = await http.post(
      Uri.parse('$_baseUrl$civilId/send/'),
      headers: headers,
      body: jsonEncode({
        'unit_ids': unitIds,
        'all_units': allUnits,
      }),
    );

    final data = _decodeResponse(response);

    _checkResponse(
      response,
      data,
      successCodes: [200, 201],
      fallbackMessage: 'ارسال شارژ عمرانی انجام نشد.',
    );

    return data;
  }
  // =====================================================
  // لغو اعلان شارژ عمرانی برای واحدهای انتخابی
  //
  // POST manager/civil-charges/{id}/cancel/
  //
  // unit_ids: [1, 2, 3]
  // all_units: true/false
  // =====================================================

  static Future<Map<String, dynamic>> cancelChargeForUnits({
    required int civilId,
    List<int> unitIds = const [],
    bool allUnits = false,
  }) async {
    if (!allUnits && unitIds.isEmpty) {
      throw Exception(
        'حداقل یک واحد را برای لغو اعلان انتخاب کنید.',
      );
    }

    final headers = await _headers();
    headers['Content-Type'] = 'application/json';

    final response = await http.post(
      Uri.parse('$_baseUrl$civilId/cancel/'),
      headers: headers,
      body: jsonEncode({
        'unit_ids': unitIds,
        'all_units': allUnits,
      }),
    );

    final data = _decodeResponse(response);

    _checkResponse(
      response,
      data,
      successCodes: [200, 201],
      fallbackMessage: 'لغو اعلان شارژ عمرانی انجام نشد.',
    );

    return data;
  }

  // =====================================================
  // استخراج مدارک یک شارژ
  // =====================================================

  static List<Map<String, dynamic>> getDocuments(
      Map<String, dynamic> charge,
      ) {
    final documents = charge['documents'];

    if (documents is! List) {
      return [];
    }

    return documents
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList();
  }

  // =====================================================
  // وضعیت ارسال و پرداخت واحد
  // =====================================================

  static bool isUnitSent(
      Map<String, dynamic> unit,
      ) {
    return unit['sent'] == true;
  }

  static bool hasUnitPaidInstallment(
      Map<String, dynamic> unit,
      ) {
    return unit['has_paid_installment'] == true;
  }
}

