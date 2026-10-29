
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_service.dart';
import 'manager_financial_common_service.dart';

class ManagerIncomeService {
  ManagerIncomeService({ApiService? apiService})
      : _api = apiService ?? ApiService(),
        _financialCommon = ManagerFinancialCommonService(
          apiService: apiService,
        );

  final ApiService _api;
  final ManagerFinancialCommonService _financialCommon;

  String get _baseUrl => ApiConfig.baseUrl;

  String _url(String path) {
    final base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    return '$base${path.startsWith('/') ? path : '/$path'}';
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw Exception(
        'پاسخ سرور قابل خواندن نیست. کد: ${response.statusCode}',
      );
    }

    if (decoded is! Map) {
      throw Exception('ساختار پاسخ سرور نامعتبر است.');
    }

    final data = Map<String, dynamic>.from(decoded);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message']?.toString() ??
            data['detail']?.toString() ??
            data['error']?.toString() ??
            'خطای سرور: ${response.statusCode}',
      );
    }

    if (data['success'] == false) {
      throw Exception(data['message']?.toString() ?? 'عملیات ناموفق بود.');
    }

    return data;
  }

  List<Map<String, dynamic>> _extractList(
      Map<String, dynamic> data,
      String key,
      ) {
    final value = data[key];
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> _extractObject(
      Map<String, dynamic> data,
      String key,
      ) {
    final value = data[key] ?? data['result'] ?? data['data'] ?? data;
    if (value is! Map) {
      throw Exception('ساختار اطلاعات دریافتی نامعتبر است.');
    }
    return Map<String, dynamic>.from(value);
  }

  String _normalizeDigits(String value) {
    return value
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9')
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9')
        .replaceAll(',', '')
        .replaceAll('٬', '');
  }

  // بانک‌ها و پرداخت‌کنندگان درآمد

  Future<List<Map<String, dynamic>>> getIncomeBanks() {
    return _financialCommon.getBanks(type: 'income');
  }

  Future<List<Map<String, dynamic>>> getIncomePayers({
    required String type,
    String search = '',
  }) {
    return _financialCommon.getPayers(
      financialType: 'income',
      payerType: type,
      search: search,
    );
  }

  // دسته‌بندی درآمدها

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _api.get(_url('/manager/income-categories/'));
    return _extractList(_decode(response), 'results');
  }

  Future<Map<String, dynamic>> createCategory({
    required String title,
  }) async {
    final response = await _api.post(
      _url('/manager/income-categories/'),
      body: {'subject': title.trim()},
    );
    return _extractObject(_decode(response), 'category');
  }

  Future<Map<String, dynamic>> updateCategory({
    required int categoryId,
    required String title,
  }) async {
    final response = await _api.patch(
      _url('/manager/income-categories/$categoryId/'),
      body: {'subject': title.trim()},
    );
    return _extractObject(_decode(response), 'category');
  }

  Future<void> deleteCategory(int categoryId) async {
    final response = await _api.delete(
      _url('/manager/income-categories/$categoryId/'),
    );
    _decode(response);
  }

  // فهرست درآمدها

  Future<List<Map<String, dynamic>>> getIncomes({
    String paymentStatus = 'all',
    int? categoryId,
  }) async {
    final query = <String, String>{};

    if (paymentStatus == 'paid' || paymentStatus == 'unpaid') {
      query['payment_status'] = paymentStatus;
    }
    if (categoryId != null) {
      query['category_id'] = categoryId.toString();
    }

    final uri = Uri.parse(_url('/manager/incomes/')).replace(
      queryParameters: query.isEmpty ? null : query,
    );

    final response = await _api.get(uri.toString());
    return _extractList(_decode(response), 'results');
  }

  // ثبت درآمد

  Future<Map<String, dynamic>> createIncome({
    required int categoryId,
    required String amount,
    required String date,
    required String description,
    required String payerType,
    int? unitId,
    int? renterId,
    int? thirdPartyId,
    String payerName = '',
    String details = '',
    String docNo = '',
  }) async {
    final body = <String, dynamic>{
      'category_id': categoryId,
      'amount': _normalizeDigits(amount),
      'doc_date': _normalizeDigits(date),
      'description': description.trim(),
      'payer_type': payerType,
      'details': details.trim(),
    };

    final normalizedDocNo = _normalizeDigits(docNo.trim());
    if (normalizedDocNo.isNotEmpty) {
      body['doc_number'] = normalizedDocNo;
    }

    _addPayerFields(
      body: body,
      payerType: payerType,
      unitId: unitId,
      renterId: renterId,
      thirdPartyId: thirdPartyId,
    );

    final response = await _api.post(
      _url('/manager/incomes/'),
      body: body,
    );
    return _extractObject(_decode(response), 'income');
  }

  // ویرایش درآمد

  Future<Map<String, dynamic>> updateIncome({
    required int incomeId,
    int? categoryId,
    String? amount,
    String? date,
    String? description,
    String? payerType,
    int? unitId,
    int? renterId,
    int? thirdPartyId,
    String? payerName,
    String? details,
    String? docNo,
  }) async {
    final body = <String, dynamic>{};

    if (categoryId != null) body['category_id'] = categoryId;
    if (amount != null) body['amount'] = _normalizeDigits(amount);
    if (date != null) body['doc_date'] = _normalizeDigits(date);
    if (description != null) body['description'] = description.trim();
    if (details != null) body['details'] = details.trim();

    if (docNo != null) {
      final normalizedDocNo = _normalizeDigits(docNo.trim());
      body['doc_number'] =
      normalizedDocNo.isEmpty ? null : normalizedDocNo;
    }

    if (payerType != null) {
      body['payer_type'] = payerType;
      _addPayerFields(
        body: body,
        payerType: payerType,
        unitId: unitId,
        renterId: renterId,
        thirdPartyId: thirdPartyId,
      );
    }

    final response = await _api.patch(
      _url('/manager/incomes/$incomeId/'),
      body: body,
    );
    return _extractObject(_decode(response), 'income');
  }

  // حذف درآمد

  Future<void> deleteIncome(int incomeId) async {
    final response = await _api.delete(
      _url('/manager/incomes/$incomeId/'),
    );
    _decode(response);
  }

  // ثبت دریافت درآمد

// ثبت دریافت درآمد همراه با اطلاعات پرداخت‌کننده
  Future<Map<String, dynamic>> payIncome({
    required int incomeId,
    required int bankId,
    required String paymentDate,
    required String transactionReference,
    required String payerType,
    int? unitId,
    int? renterId,
    int? thirdPartyId,
  }) async {
    final body = <String, dynamic>{
      'bank_id': bankId,
      'payment_date': _normalizeDigits(paymentDate),
      'transaction_reference':
      _normalizeDigits(transactionReference.trim()),
      'payer_type': payerType,
    };

    _addPayerFields(
      body: body,
      payerType: payerType,
      unitId: unitId,
      renterId: renterId,
      thirdPartyId: thirdPartyId,
    );

    final response = await _api.post(
      _url('/manager/incomes/$incomeId/pay/'),
      body: body,
    );

    return _extractObject(_decode(response), 'income');
  }

  // لغو دریافت درآمد

  Future<Map<String, dynamic>> cancelIncomePayment(int incomeId) async {
    final response = await _api.post(
      _url('/manager/incomes/$incomeId/cancel-pay/'),
      body: <String, dynamic>{},
    );
    return _extractObject(_decode(response), 'income');
  }

  // فیلدهای پرداخت‌کننده

  void _addPayerFields({
    required Map<String, dynamic> body,
    required String payerType,
    int? unitId,
    int? renterId,
    int? thirdPartyId,
  }) {
    if (payerType == 'owner') {
      if (unitId == null) {
        throw Exception('لطفاً واحد مالک را انتخاب کنید.');
      }
      body['unit_id'] = unitId;
    } else if (payerType == 'renter') {
      if (renterId == null) {
        throw Exception('لطفاً مستأجر را انتخاب کنید.');
      }
      body['payer_renter_id'] = renterId;
    } else if (payerType == 'other') {
      if (thirdPartyId == null) {
        throw Exception('لطفاً شخص پرداخت‌کننده را انتخاب کنید.');
      }
      body['payer_third_party_id'] = thirdPartyId;
    } else {
      throw Exception('نوع پرداخت‌کننده معتبر نیست.');
    }
  }

  // ثبت یا ویرایش درآمد همراه مدارک

  Future<Map<String, dynamic>> saveIncomeWithFiles({
    int? incomeId,
    required int categoryId,
    required String amount,
    required String date,
    required String description,
    required String payerType,
    int? unitId,
    int? renterId,
    int? thirdPartyId,
    String payerName = '',
    String details = '',
    String docNo = '',
    List<File> files = const [],
  }) async {
    if (files.length > 2) {
      throw Exception('حداکثر دو مدرک مجاز است.');
    }

    final fields = <String, String>{
      'category_id': categoryId.toString(),
      'amount': _normalizeDigits(amount),
      'doc_date': _normalizeDigits(date),
      'description': description.trim(),
      'details': details.trim(),
    };

    final normalizedDocNo = _normalizeDigits(docNo.trim());
    if (normalizedDocNo.isNotEmpty) {
      fields['doc_number'] = normalizedDocNo;
    }

    final isEdit = incomeId != null;
    final path = isEdit
        ? '/manager/incomes/$incomeId/'
        : '/manager/incomes/';

    final response = await _sendMultipart(
      url: _url(path),
      method: isEdit ? 'PATCH' : 'POST',
      fields: fields,
      files: files,
    );

    return _extractObject(_decode(response), 'income');
  }

  // Multipart با تمدید خودکار توکن

  Future<http.Response> _sendMultipart({
    required String url,
    required String method,
    required Map<String, String> fields,
    required List<File> files,
  }) async {
    Future<http.Response> send(String token) async {
      final request = http.MultipartRequest(method, Uri.parse(url));

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields.addAll(fields);

      for (final file in files) {
        if (!await file.exists()) {
          throw Exception('فایل انتخاب‌شده پیدا نشد.');
        }
        request.files.add(
          await http.MultipartFile.fromPath('documents', file.path),
        );
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      return http.Response.fromStream(streamed);
    }

    var token = await TokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      throw Exception('نشست کاربری شما منقضی شده است.');
    }

    var response = await send(token.trim());

    if (response.statusCode == 401) {
      final refreshed = await _api.refreshAccessToken();
      if (!refreshed) throw Exception('TOKEN_EXPIRED');

      token = await TokenStorage.getAccessToken();
      if (token == null || token.trim().isEmpty) {
        throw Exception('TOKEN_EXPIRED');
      }
      response = await send(token.trim());
    }

    return response;
  }

}
