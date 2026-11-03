
import 'dart:convert';

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerSewageChargeListService {
  ManagerSewageChargeListService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  String get _base => ApiConfig.baseUrl;

  dynamic _decode(List<int> bytes) {
    return jsonDecode(utf8.decode(bytes));
  }

  String _errorMessage(dynamic body, String fallback) {
    if (body is Map) {
      return body['message']?.toString() ??
          body['detail']?.toString() ??
          fallback;
    }
    return fallback;
  }

  List<Map<String, dynamic>> _results(
      dynamic body,
      int statusCode,
      ) {
    if (statusCode < 200 || statusCode >= 300) {
      throw Exception(
        _errorMessage(body, 'خطای سرور ($statusCode)'),
      );
    }

    if (body is! Map || body['success'] != true) {
      throw Exception(
        _errorMessage(body, 'دریافت اطلاعات ناموفق بود.'),
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
    final uri = Uri.parse('$_base/manager/sewage-charges/')
        .replace(
      queryParameters: {
        'page': '$page',
        'page_size': '$pageSize',
        if (search != null && search.trim().isNotEmpty)
          'q': search.trim(),
      },
    );

    final response = await _apiService.get(uri.toString());

    return _results(
      _decode(response.bodyBytes),
      response.statusCode,
    );
  }

  Future<List<Map<String, dynamic>>> getUnits({
    required int sewageId,
    String? search,
  }) async {
    final uri = Uri.parse(
      '$_base/manager/sewage-charges/$sewageId/units/',
    ).replace(
      queryParameters: {
        if (search != null && search.trim().isNotEmpty)
          'q': search.trim(),
      },
    );

    final response = await _apiService.get(uri.toString());

    return _results(
      _decode(response.bodyBytes),
      response.statusCode,
    );
  }

  Future<List<Map<String, dynamic>>> getInstallments({
    required int sewageId,
    required int unitId,
  }) async {
    final url =
        '$_base/manager/sewage-charges/$sewageId/units/$unitId/installments/';

    final response = await _apiService.get(url);

    return _results(
      _decode(response.bodyBytes),
      response.statusCode,
    );
  }

  Future<List<Map<String, dynamic>>> getPaymentBanks({
    required int installmentId,
  }) async {
    final url =
        '$_base/manager/sewage-installments/$installmentId/payment/';

    final response = await _apiService.get(url);

    final body = _decode(response.bodyBytes);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        _errorMessage(body, 'دریافت حساب‌های بانکی ناموفق بود.'),
      );
    }

    if (body is! Map || body['success'] != true) {
      throw Exception(
        _errorMessage(body, 'پاسخ سرور معتبر نیست.'),
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
      '$_base/manager/sewage-installments/$installmentId/payment/',
      body: {
        'bank_id': bankId,
        'payment_date': paymentDate,
        if (reference != null && reference.isNotEmpty)
          'transaction_reference': reference,
      },
    );

    final body = _decode(response.bodyBytes);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        _errorMessage(body, 'ثبت پرداخت ناموفق بود.'),
      );
    }

    if (body is! Map || body['success'] != true) {
      throw Exception(
        _errorMessage(body, 'ثبت پرداخت ناموفق بود.'),
      );
    }

    return Map<String, dynamic>.from(body);
  }

  Future<Map<String, dynamic>> cancelPayment({
    required int installmentId,
  }) async {
    final response = await _apiService.post(
      '$_base/manager/sewage-installments/$installmentId/cancel-payment/',
    );

    final body = _decode(response.bodyBytes);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        _errorMessage(body, 'لغو پرداخت ناموفق بود.'),
      );
    }

    if (body is! Map || body['success'] != true) {
      throw Exception(
        _errorMessage(body, 'لغو پرداخت ناموفق بود.'),
      );
    }

    return Map<String, dynamic>.from(body);
  }
}
