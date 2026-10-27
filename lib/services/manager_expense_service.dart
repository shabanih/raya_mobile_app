
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_service.dart';

class ManagerExpenseService {
  ManagerExpenseService({ApiService? apiService})
      : _api = apiService ?? ApiService();

  final ApiService _api;

  String get _baseUrl => ApiConfig.baseUrl;

  String _url(String path) {
    final base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;

    final normalizedPath =
    path.startsWith('/') ? path : '/$path';

    return '$base$normalizedPath';
  }

  Map<String, dynamic> _decode(http.Response response) {
    dynamic decoded;

    try {
      decoded = jsonDecode(
        utf8.decode(response.bodyBytes),
      );
    } catch (_) {
      throw Exception(
        'پاسخ سرور قابل خواندن نیست. کد: ${response.statusCode}',
      );
    }

    if (decoded is! Map) {
      throw Exception('ساختار پاسخ سرور نامعتبر است.');
    }

    final data = Map<String, dynamic>.from(decoded);

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        data['message']?.toString() ??
            data['detail']?.toString() ??
            data['error']?.toString() ??
            'خطای سرور: ${response.statusCode}',
      );
    }

    if (data['success'] == false) {
      throw Exception(
        data['message']?.toString() ??
            'عملیات ناموفق بود.',
      );
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

  // =====================================================
  // سرفصل‌های هزینه
  // =====================================================

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _api.get(
      _url('/manager/expense-categories/'),
    );

    final data = _decode(response);
    return _extractList(data, 'results');
  }

  Future<Map<String, dynamic>> createCategory({
    required String title,
  }) async {
    final response = await _api.post(
      _url('/manager/expense-categories/'),
      body: {'title': title.trim()},
    );

    final data = _decode(response);
    return Map<String, dynamic>.from(
      data['category'] as Map? ?? data,
    );
  }

  Future<Map<String, dynamic>> updateCategory({
    required int categoryId,
    required String title,
  }) async {
    final response = await _api.patch(
      _url('/manager/expense-categories/$categoryId/'),
      body: {'title': title.trim()},
    );

    final data = _decode(response);
    return Map<String, dynamic>.from(
      data['category'] as Map? ?? data,
    );
  }

  Future<void> deleteCategory(int categoryId) async {
    final response = await _api.delete(
      _url('/manager/expense-categories/$categoryId/'),
    );

    _decode(response);
  }

  // =====================================================
  // فهرست هزینه‌ها
  // paymentStatus: all | paid | unpaid
  // =====================================================

  Future<List<Map<String, dynamic>>> getExpenses({
    String paymentStatus = 'all',
    int? categoryId,
  }) async {
    final query = <String, String>{};

    if (paymentStatus == 'paid' ||
        paymentStatus == 'unpaid') {
      query['payment_status'] = paymentStatus;
    }

    if (categoryId != null) {
      query['category_id'] = categoryId.toString();
    }

    final uri = Uri.parse(
      _url('/manager/expenses/'),
    ).replace(queryParameters: query.isEmpty ? null : query);

    final response = await _api.get(uri.toString());
    final data = _decode(response);

    return _extractList(data, 'results');
  }

  // =====================================================
  // ثبت هزینه بدون فایل
  // =====================================================

  Future<Map<String, dynamic>> createExpense({
    required int categoryId,
    required String amount,
    required String date,
    required String description,
    String details = '',
    String docNo = '',
  }) async {
    final response = await _api.post(
      _url('/manager/expenses/'),
      body: {
        'category_id': categoryId,
        'amount': _normalizeDigits(amount),
        'date': _normalizeDigits(date),
        'description': description.trim(),
        'details': details.trim(),
        'doc_no': docNo.trim(),
      },
    );

    final data = _decode(response);
    return Map<String, dynamic>.from(
      data['expense'] as Map? ?? data,
    );
  }

  // =====================================================
  // ویرایش هزینه بدون فایل
  // =====================================================

  Future<Map<String, dynamic>> updateExpense({
    required int expenseId,
    int? categoryId,
    String? amount,
    String? date,
    String? description,
    String? details,
    String? docNo,
  }) async {
    final body = <String, dynamic>{};

    if (categoryId != null) {
      body['category_id'] = categoryId;
    }
    if (amount != null) {
      body['amount'] = _normalizeDigits(amount);
    }
    if (date != null) {
      body['date'] = _normalizeDigits(date);
    }
    if (description != null) {
      body['description'] = description.trim();
    }
    if (details != null) {
      body['details'] = details.trim();
    }
    if (docNo != null) {
      body['doc_no'] = docNo.trim();
    }

    final response = await _api.patch(
      _url('/manager/expenses/$expenseId/'),
      body: body,
    );

    final data = _decode(response);
    return Map<String, dynamic>.from(
      data['expense'] as Map? ?? data,
    );
  }

  // =====================================================
  // حذف / غیرفعال‌سازی هزینه
  // =====================================================

  Future<void> deleteExpense(int expenseId) async {
    final response = await _api.delete(
      _url('/manager/expenses/$expenseId/'),
    );

    _decode(response);
  }

  // =====================================================
  // ثبت یا ویرایش هزینه همراه مدارک
  //
  // برای ثبت: expenseId = null
  // برای ویرایش: expenseId = شناسه هزینه
  //
  // files حداکثر دو فایل است.
  // =====================================================

  Future<Map<String, dynamic>> saveExpenseWithFiles({
    int? expenseId,
    required int categoryId,
    required String amount,
    required String date,
    required String description,
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
      'date': _normalizeDigits(date),
      'description': description.trim(),
      'details': details.trim(),
      'doc_no': docNo.trim(),
    };

    final isEdit = expenseId != null;
    final path = isEdit
        ? '/manager/expenses/$expenseId/'
        : '/manager/expenses/';

    final response = await _sendMultipart(
      url: _url(path),
      method: isEdit ? 'PATCH' : 'POST',
      fields: fields,
      files: files,
    );

    final data = _decode(response);

    return Map<String, dynamic>.from(
      data['expense'] as Map? ?? data,
    );
  }

  // =====================================================
  // Multipart با Refresh خودکار توکن
  // =====================================================

  Future<http.Response> _sendMultipart({
    required String url,
    required String method,
    required Map<String, String> fields,
    required List<File> files,
  }) async {
    Future<http.Response> send(String token) async {
      final request = http.MultipartRequest(
        method,
        Uri.parse(url),
      );

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
          await http.MultipartFile.fromPath(
            'documents',
            file.path,
          ),
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

      if (!refreshed) {
        throw Exception('TOKEN_EXPIRED');
      }

      token = await TokenStorage.getAccessToken();

      if (token == null || token.trim().isEmpty) {
        throw Exception('TOKEN_EXPIRED');
      }

      response = await send(token.trim());
    }

    return response;
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
}
