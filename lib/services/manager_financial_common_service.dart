
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerFinancialCommonService {
  ManagerFinancialCommonService({ApiService? apiService})
      : _api = apiService ?? ApiService();

  final ApiService _api;

  // =====================================================
  // تبدیل پاسخ سرور به لیست
  // =====================================================

  List<Map<String, dynamic>> _extractList(dynamic data) {
    dynamic items;

    if (data is List) {
      items = data;
    } else if (data is Map) {
      items = data['results'] ??
          data['data'] ??
          data['banks'] ??
          data['receivers'] ??
          data['payers'];
    }

    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // =====================================================
  // بررسی پاسخ HTTP
  // =====================================================

  dynamic _decodeResponse(http.Response response) {
    dynamic data;

    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      data = null;
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map && data['success'] == false) {
        throw Exception(
          data['message']?.toString() ??
              'دریافت اطلاعات ناموفق بود.',
        );
      }

      return data;
    }

    if (data is Map) {
      throw Exception(
        data['message']?.toString() ??
            data['detail']?.toString() ??
            data['error']?.toString() ??
            'خطا در ارتباط با سرور '
                '(${response.statusCode})',
      );
    }

    throw Exception(
      'خطا در ارتباط با سرور (${response.statusCode})',
    );
  }

  // =====================================================
  // اعتبارسنجی نوع عملیات مالی
  // =====================================================

  String _normalizeFinancialType(String type) {
    final value = type.trim().toLowerCase();

    if (value != 'expense' && value != 'income') {
      throw ArgumentError(
        'نوع عملیات مالی باید expense یا income باشد.',
      );
    }

    return value;
  }

  // =====================================================
  // دریافت حساب‌های بانکی هزینه و درآمد
  // =====================================================

  Future<List<Map<String, dynamic>>> getBanks({
    required String type,
  }) async {
    final financialType = _normalizeFinancialType(type);

    final url =
        '${ApiConfig.baseUrl}/manager/$financialType-banks/';

    final response = await _api.get(url);
    final data = _decodeResponse(response);

    return _extractList(data);
  }

  // =====================================================
  // دریافت اشخاص هزینه یا درآمد
  //
  // financialType:
  //   expense => دریافت‌کنندگان هزینه
  //   income  => پرداخت‌کنندگان درآمد
  //
  // payerType:
  //   owner / renter / other
  // =====================================================

  Future<List<Map<String, dynamic>>> getPayers({
    required String financialType,
    required String payerType,
    String search = '',
  }) async {
    final normalizedFinancialType =
    _normalizeFinancialType(financialType);

    final normalizedPayerType =
    payerType.trim().toLowerCase();

    const validPayerTypes = {
      'owner',
      'renter',
      'other',
    };

    if (!validPayerTypes.contains(normalizedPayerType)) {
      throw ArgumentError(
        'نوع شخص باید owner، renter یا other باشد.',
      );
    }

    final endpoint = normalizedFinancialType == 'expense'
        ? 'expense-receivers'
        : 'income-payers';

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/manager/$endpoint/',
    ).replace(
      queryParameters: {
        'type': normalizedPayerType,
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );

    final response = await _api.get(url.toString());
    final data = _decodeResponse(response);

    return _extractList(data);
  }
}
