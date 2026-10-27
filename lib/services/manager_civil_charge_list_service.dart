import 'dart:convert';

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerCivilChargeListService {
  ManagerCivilChargeListService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  String get _base => ApiConfig.baseUrl;

  dynamic _decode(List<int> bytes) {
    return jsonDecode(utf8.decode(bytes));
  }

  List<Map<String, dynamic>> _results(
      dynamic body,
      int statusCode,
      ) {
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(
        body is Map
            ? body['message']?.toString() ??
            body['detail']?.toString() ??
            'خطای سرور ($statusCode)'
            : 'خطای سرور ($statusCode)',
      );
    }

    if (body is! Map || body['success'] != true) {
      throw Exception(
        body is Map
            ? body['message']?.toString() ??
            'دریافت اطلاعات ناموفق بود.'
            : 'پاسخ سرور معتبر نیست.',
      );
    }

    final results = body['results'];

    if (results is! List) return [];

    return results
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getCharges({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    final uri = Uri.parse('$_base/manager/civil-charges/').replace(
      queryParameters: {
        'page': '$page',
        'page_size': '$pageSize',
        if (search != null && search.trim().isNotEmpty)
          'q': search.trim(),
      },
    );

    final response = await _apiService.get(uri.toString());
    return _results(_decode(response.bodyBytes), response.statusCode);
  }

  Future<List<Map<String, dynamic>>> getUnits({

    required int civilId,
    String? search,
  }) async {
    final uri = Uri.parse(
      '$_base/manager/list/civil-charges/$civilId/units/'
    ).replace(
      queryParameters: {
        if (search != null && search.trim().isNotEmpty)
          'q': search.trim(),
      },
    );

    final response = await _apiService.get(uri.toString());
    return _results(_decode(response.bodyBytes), response.statusCode);
  }

  Future<List<Map<String, dynamic>>> getInstallments({
    required int civilId,
    required int unitId,
  }) async {
    final url =
        '$_base/manager/civil-charges/$civilId/units/$unitId/installments/';

    final response = await _apiService.get(url);
    return _results(_decode(response.bodyBytes), response.statusCode);
  }

  Future<List<Map<String, dynamic>>> getPaymentBanks({
    required int installmentId,
  }) async {
    final url =
        '$_base/manager/civil-installments/$installmentId/pay/';

    final response = await _apiService.get(url);
    final body = _decode(response.bodyBytes);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body is Map
            ? body['message']?.toString() ?? 'دریافت حساب‌های بانکی ناموفق بود.'
            : 'دریافت حساب‌های بانکی ناموفق بود.',
      );
    }

    if (body is! Map || body['success'] != true) {
      throw Exception(
        body is Map
            ? body['message']?.toString() ?? 'پاسخ سرور معتبر نیست.'
            : 'پاسخ سرور معتبر نیست.',
      );
    }

    final banks = body['banks'];
    if (banks is! List) return [];

    return banks
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> payInstallment({
    required int installmentId,
    required int bankId,
    required String paymentDate,
    String? transactionReference,
  }) async {
    final reference = transactionReference?.trim();

    final response = await _apiService.post(
      '$_base/manager/civil-installments/$installmentId/pay/',
      body: {
        'bank_id': bankId,
        'payment_date': paymentDate,
        if (reference != null && reference.isNotEmpty)
          'transaction_reference': reference,
      },
    );

    final body = _decode(response.bodyBytes);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body is Map
            ? body['message']?.toString() ?? 'ثبت پرداخت ناموفق بود.'
            : 'ثبت پرداخت ناموفق بود.',
      );
    }

    if (body is! Map || body['success'] != true) {
      throw Exception(
        body is Map
            ? body['message']?.toString() ?? 'ثبت پرداخت ناموفق بود.'
            : 'ثبت پرداخت ناموفق بود.',
      );
    }

    return Map<String, dynamic>.from(body);
  }

  Future<Map<String, dynamic>> cancelPayment({
    required int installmentId,
  }) async {
    final response = await _apiService.post(
      '$_base/manager/civil-installments/$installmentId/cancel-payment/',
    );

    final body = _decode(response.bodyBytes);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body is Map
            ? body['message']?.toString() ?? 'لغو پرداخت ناموفق بود.'
            : 'لغو پرداخت ناموفق بود.',
      );
    }

    if (body is! Map || body['success'] != true) {
      throw Exception(
        body is Map
            ? body['message']?.toString() ?? 'لغو پرداخت ناموفق بود.'
            : 'لغو پرداخت ناموفق بود.',
      );
    }

    return Map<String, dynamic>.from(body);
  }
}