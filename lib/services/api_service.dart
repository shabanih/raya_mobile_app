import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class ApiService {
  // =====================================================
  // تنظیمات داخلی
  // =====================================================

  /// جلوگیری از Refresh شدن همزمان چند درخواست
  Future<bool>? _refreshFuture;

  // =====================================================
  // تبدیل اعداد فارسی و عربی به انگلیسی
  // =====================================================

  String normalizeDigits(String value) {
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
        .replaceAll('٩', '9');
  }

  // =====================================================
  // Login
  // =====================================================

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final normalizedUsername = normalizeDigits(username);
      final normalizedPassword = normalizeDigits(password);

      debugPrint(
        'LOGIN USERNAME: $normalizedUsername',
      );

      debugPrint(
        'LOGIN PASSWORD EXISTS: ${normalizedPassword.isNotEmpty}',
      );

      final response = await http
          .post(
        Uri.parse(ApiConfig.login),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': normalizedUsername,
          'password': normalizedPassword,
        }),
      )
          .timeout(
        const Duration(seconds: 20),
      );

      debugPrint(
        'LOGIN STATUS: ${response.statusCode}',
      );

      debugPrint(
        'LOGIN RESPONSE: ${response.body}',
      );

      if (response.statusCode != 200) {
        Map<String, dynamic> data = {};

        try {
          final decoded = jsonDecode(response.body);

          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (_) {}

        throw Exception(
          data['message'] ??
              data['detail'] ??
              'خطا در ورود به سامانه',
        );
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'پاسخ نامعتبر از سرور دریافت شد.',
        );
      }

      return decoded;
    } on SocketException catch (e) {
      debugPrint(
        'LOGIN SOCKET ERROR: $e',
      );

      throw Exception('NO_INTERNET');
    } on http.ClientException catch (e) {
      debugPrint(
        'LOGIN CLIENT ERROR: $e',
      );

      throw Exception('NO_INTERNET');
    } on FormatException catch (e) {
      debugPrint(
        'LOGIN FORMAT ERROR: $e',
      );

      throw Exception(
        'پاسخ دریافتی از سرور نامعتبر است.',
      );
    } on Exception catch (e) {
      debugPrint(
        'LOGIN ERROR: $e',
      );

      rethrow;
    } catch (e) {
      debugPrint(
        'LOGIN UNKNOWN ERROR: $e',
      );

      throw Exception(
        'خطا در برقراری ارتباط با سرور.',
      );
    }
  }

  // =====================================================
  // Refresh Token
  // =====================================================

  Future<bool> refreshAccessToken() async {
    if (_refreshFuture != null) {
      return await _refreshFuture!;
    }

    _refreshFuture = _performRefresh();

    try {
      return await _refreshFuture!;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<bool> _performRefresh() async {
    final refreshToken =
    await TokenStorage.getRefreshToken();

    if (refreshToken == null ||
        refreshToken.trim().isEmpty) {
      debugPrint(
        'REFRESH: refresh token not found',
      );

      return false;
    }

    final cleanRefreshToken =
    refreshToken.trim();

    try {
      final response = await http
          .post(
        Uri.parse(ApiConfig.refresh),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'refresh': cleanRefreshToken,
        }),
      )
          .timeout(
        const Duration(seconds: 20),
      );

      debugPrint(
        'REFRESH STATUS: ${response.statusCode}',
      );

      debugPrint(
        'REFRESH RESPONSE: ${response.body}',
      );

      if (response.statusCode != 200) {
        debugPrint(
          'REFRESH FAILED',
        );

        return false;
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        return false;
      }

      final newAccessToken =
      data['access']?.toString().trim();

      if (newAccessToken == null ||
          newAccessToken.isEmpty) {
        debugPrint(
          'REFRESH: new access token not found',
        );

        return false;
      }

      await TokenStorage.saveTokens(
        newAccessToken,
        cleanRefreshToken,
      );

      debugPrint(
        'REFRESH SUCCESS',
      );

      return true;
    } on SocketException catch (e) {
      debugPrint(
        'REFRESH SOCKET ERROR: $e',
      );

      return false;
    } on http.ClientException catch (e) {
      debugPrint(
        'REFRESH CLIENT ERROR: $e',
      );

      return false;
    } on TimeoutException catch (e) {
      debugPrint(
        'REFRESH TIMEOUT: $e',
      );

      return false;
    } catch (e) {
      debugPrint(
        'REFRESH ERROR: $e',
      );

      return false;
    }
  }

  // =====================================================
  // GET مرکزی با Refresh خودکار
  // =====================================================

  Future<http.Response> _getWithRefresh(
      String url,
      ) async {
    var token =
    await TokenStorage.getAccessToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'توکن ورود پیدا نشد',
      );
    }

    token = token.trim();

    debugPrint(
      'API GET URL: $url',
    );

    debugPrint(
      'API ACCESS TOKEN EXISTS: true',
    );

    http.Response response;

    try {
      response = await http
          .get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(
        const Duration(seconds: 20),
      );
    } on SocketException {
      throw Exception('NO_INTERNET');
    } on http.ClientException {
      throw Exception('NO_INTERNET');
    } on TimeoutException {
      throw Exception('REQUEST_TIMEOUT');
    }

    debugPrint(
      'API GET STATUS: ${response.statusCode}',
    );

    if (response.statusCode != 401) {
      return response;
    }

    debugPrint(
      'API GET 401 -> TRY REFRESH',
    );

    final refreshed =
    await refreshAccessToken();

    if (!refreshed) {
      throw Exception(
        'TOKEN_EXPIRED',
      );
    }

    token =
    await TokenStorage.getAccessToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'TOKEN_EXPIRED',
      );
    }

    token = token.trim();

    try {
      response = await http
          .get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(
        const Duration(seconds: 20),
      );
    } on SocketException {
      throw Exception('NO_INTERNET');
    } on http.ClientException {
      throw Exception('NO_INTERNET');
    } on TimeoutException {
      throw Exception('REQUEST_TIMEOUT');
    }

    debugPrint(
      'API GET RETRY STATUS: ${response.statusCode}',
    );

    if (response.statusCode == 401) {
      throw Exception(
        'TOKEN_EXPIRED',
      );
    }

    return response;
  }

  // =====================================================
  // POST مرکزی با Refresh خودکار
  // =====================================================

  Future<http.Response> _postWithRefresh(
      String url, {
        Map<String, dynamic>? body,
      }) async {
    var token =
    await TokenStorage.getAccessToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'توکن ورود پیدا نشد',
      );
    }

    token = token.trim();

    http.Response response;

    try {
      response = await http
          .post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body != null
            ? jsonEncode(body)
            : null,
      )
          .timeout(
        const Duration(seconds: 20),
      );
    } on SocketException {
      throw Exception('NO_INTERNET');
    } on http.ClientException {
      throw Exception('NO_INTERNET');
    } on TimeoutException {
      throw Exception('REQUEST_TIMEOUT');
    }

    if (response.statusCode != 401) {
      return response;
    }

    debugPrint(
      'API POST 401 -> TRY REFRESH',
    );

    final refreshed =
    await refreshAccessToken();

    if (!refreshed) {
      throw Exception(
        'TOKEN_EXPIRED',
      );
    }

    token =
    await TokenStorage.getAccessToken();

    if (token == null ||
        token.trim().isEmpty) {
      throw Exception(
        'TOKEN_EXPIRED',
      );
    }

    token = token.trim();

    try {
      response = await http
          .post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body != null
            ? jsonEncode(body)
            : null,
      )
          .timeout(
        const Duration(seconds: 20),
      );
    } on SocketException {
      throw Exception('NO_INTERNET');
    } on http.ClientException {
      throw Exception('NO_INTERNET');
    } on TimeoutException {
      throw Exception('REQUEST_TIMEOUT');
    }

    if (response.statusCode == 401) {
      throw Exception(
        'TOKEN_EXPIRED',
      );
    }

    return response;
  }

  // =====================================================
  // Dashboard مدیر ساختمان
  // =====================================================

  Future<Map<String, dynamic>>
  getManagerDashboard() async {
    final response =
    await _getWithRefresh(
      ApiConfig.managerDashboard,
    );

    debugPrint(
      '==========================================',
    );

    debugPrint(
      'GET MANAGER DASHBOARD',
    );

    debugPrint(
      'URL: ${ApiConfig.managerDashboard}',
    );

    debugPrint(
      'STATUS: ${response.statusCode}',
    );

    debugPrint(
      'BODY: ${response.body}',
    );

    debugPrint(
      '==========================================',
    );

    if (response.statusCode == 200) {
      final data =
      jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'اطلاعات داشبورد مدیر نامعتبر است.',
        );
      }

      if (data['success'] != true) {
        throw Exception(
          data['message']?.toString() ??
              'دریافت داشبورد مدیر ناموفق بود.',
        );
      }

      return data;
    }

    if (response.statusCode == 403) {
      throw Exception(
        'شما دسترسی به داشبورد مدیر ساختمان را ندارید.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'داشبورد مدیر ساختمان پیدا نشد.',
      );
    }

    throw Exception(
      'خطا در دریافت داشبورد مدیر: '
          '${response.statusCode}',
    );
  }

  // =====================================================
  // دریافت اطلاعات کاربر
  // =====================================================

  Future<Map<String, dynamic>> getMe() async {
    debugPrint(
      '==========================================',
    );

    debugPrint(
      'GET ME',
    );

    final accessToken =
    await TokenStorage.getAccessToken();

    debugPrint(
      'ACCESS TOKEN EXISTS: '
          '${accessToken != null && accessToken.trim().isNotEmpty}',
    );

    debugPrint(
      'URL: ${ApiConfig.me}',
    );

    debugPrint(
      '==========================================',
    );

    if (accessToken == null ||
        accessToken.trim().isEmpty) {
      throw Exception(
        'توکن دسترسی وجود ندارد.',
      );
    }

    /*
     * مهم:
     *
     * قبلاً getMe مستقیماً با http.get درخواست می‌فرستاد.
     * حالا از _getWithRefresh استفاده می‌کنیم تا:
     *
     * 1- Authorization همیشه ارسال شود
     * 2- توکن trim شود
     * 3- در صورت 401، refresh انجام شود
     * 4- درخواست مجدداً با access token جدید ارسال شود
     */

    final response =
    await _getWithRefresh(
      ApiConfig.me,
    );

    debugPrint(
      'ME STATUS: ${response.statusCode}',
    );

    debugPrint(
      'ME RESPONSE: ${response.body}',
    );

    if (response.statusCode == 200) {
      final data =
      jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'اطلاعات کاربر نامعتبر است.',
        );
      }

      return data;
    }

    if (response.statusCode == 401 ||
        response.statusCode == 403) {
      throw Exception(
        'احراز هویت کاربر ناموفق بود.',
      );
    }

    throw Exception(
      'خطا در دریافت اطلاعات کاربر: '
          '${response.statusCode}',
    );
  }

  // =====================================================
  // سازگاری با کد قبلی
  // =====================================================

  Future<Map<String, dynamic>>
  getMeWithRefresh() async {
    return await getMe();
  }

  // =====================================================
  // Dashboard ساکن
  // =====================================================

  Future<Map<String, dynamic>>
  getDashboard() async {
    final response =
    await _getWithRefresh(
      ApiConfig.dashboard,
    );

    debugPrint(
      '==========================================',
    );

    debugPrint(
      'GET RESIDENT DASHBOARD',
    );

    debugPrint(
      'URL: ${ApiConfig.dashboard}',
    );

    debugPrint(
      'STATUS: ${response.statusCode}',
    );

    debugPrint(
      'BODY: ${response.body}',
    );

    debugPrint(
      '==========================================',
    );

    if (response.statusCode == 200) {
      final data =
      jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'اطلاعات Dashboard نامعتبر است.',
        );
      }

      final statistics =
      data['statistics'];

      if (statistics is Map) {
        debugPrint(
          'DASHBOARD STATISTICS: '
              'paid=${statistics['paid_count']} | '
              'unpaid=${statistics['unpaid_count']} | '
              'pending=${statistics['pending_count']} | '
              'total_paid=${statistics['total_paid']} | '
              'total_debt=${statistics['total_debt']}',
        );
      }

      return data;
    }

    throw Exception(
      'خطا در دریافت Dashboard: '
          '${response.statusCode}',
    );
  }

  // =====================================================
  // دریافت لیست شارژها
  // =====================================================

  Future<List<Map<String, dynamic>>>
  getCharges() async {
    final response =
    await _getWithRefresh(
      ApiConfig.charges,
    );

    debugPrint(
      'CHARGES STATUS: ${response.statusCode}',
    );

    debugPrint(
      'CHARGES RESPONSE: ${response.body}',
    );

    if (response.statusCode == 200) {
      final data =
      jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        final charges =
        data['charges'];

        if (charges is List) {
          return charges
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      }

      throw Exception(
        'ساختار پاسخ لیست شارژها نامعتبر است.',
      );
    }

    throw Exception(
      'خطا در دریافت لیست شارژها: '
          '${response.statusCode}',
    );
  }

  // =====================================================
  // دریافت روش‌های پرداخت شارژ
  // =====================================================

  Future<Map<String, dynamic>>
  getChargePaymentMethods(
      int chargeId,
      ) async {
    final url =
    ApiConfig.chargePaymentMethods(
      chargeId,
    );

    final response =
    await _getWithRefresh(url);

    if (response.statusCode == 200) {
      final data =
      jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception(
        'ساختار پاسخ روش‌های پرداخت نامعتبر است.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'روش‌های پرداخت این شارژ پیدا نشد.',
      );
    }

    throw Exception(
      'خطا در دریافت روش‌های پرداخت: '
          '${response.statusCode}',
    );
  }

  // =====================================================
  // دریافت حساب‌های بانکی
  // =====================================================

  Future<List<Map<String, dynamic>>>
  getPaymentBanks(
      int chargeId,
      ) async {
    final url =
    ApiConfig.paymentBanks(
      chargeId,
    );

    final response =
    await _getWithRefresh(url);

    if (response.statusCode != 200) {
      throw Exception(
        'خطا در دریافت حساب‌های بانکی: '
            '${response.statusCode}',
      );
    }

    final data =
    jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception(
        'پاسخ حساب‌های بانکی نامعتبر است.',
      );
    }

    final banks =
    data['banks'];

    if (banks is! List) {
      return [];
    }

    return banks
        .whereType<Map>()
        .map(
          (bank) =>
      Map<String, dynamic>.from(bank),
    )
        .toList();
  }

  // =====================================================
  // ثبت پرداخت دستی شارژ
  // =====================================================

  Future<Map<String, dynamic>>
  submitManualChargePayment({
    required int chargeId,
    required int bankId,
    required String transactionReference,
    required String paymentDate,
  }) async {
    final response =
    await _postWithRefresh(
      ApiConfig.manualChargePayment(
        chargeId,
      ),
      body: {
        'bank_id': bankId,
        'transaction_reference':
        transactionReference,
        'payment_date': paymentDate,
      },
    );

    Map<String, dynamic> data = {};

    try {
      final decoded =
      jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {}

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return data;
    }

    if (response.statusCode == 400) {
      final errors =
      data['errors'];

      if (errors is Map) {
        final messages =
        <String>[];

        errors.forEach(
              (key, value) {
            if (value is List) {
              messages.addAll(
                value.map(
                      (item) => item.toString(),
                ),
              );
            } else {
              messages.add(
                value.toString(),
              );
            }
          },
        );

        if (messages.isNotEmpty) {
          throw Exception(
            messages.join('\n'),
          );
        }
      }

      throw Exception(
        data['message']?.toString() ??
            data['detail']?.toString() ??
            'اطلاعات پرداخت صحیح نیست.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'مسیر ثبت پرداخت دستی در سرور پیدا نشد.',
      );
    }

    throw Exception(
      data['message']?.toString() ??
          data['detail']?.toString() ??
          'خطا در ثبت پرداخت: '
              '${response.statusCode}',
    );
  }

  // =====================================================
  // دریافت تاریخچه پرداخت‌ها
  // =====================================================

  Future<List<Map<String, dynamic>>>
  getPaymentHistory() async {
    final response =
    await _getWithRefresh(
      ApiConfig.paymentHistory,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'خطا در دریافت تراکنش‌ها: '
            '${response.statusCode}',
      );
    }

    final decoded =
    jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'ساختار پاسخ تاریخچه تراکنش‌ها نامعتبر است.',
      );
    }

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message']?.toString() ??
            'دریافت تراکنش‌ها ناموفق بود.',
      );
    }

    final paymentsData =
    decoded['payments'];

    if (paymentsData is! List) {
      return [];
    }

    final List<Map<String, dynamic>>
    result = [];

    for (final item in paymentsData) {
      if (item is Map) {
        result.add(
          Map<String, dynamic>.from(item),
        );
      }
    }

    return result;
  }

  // =====================================================
  // شارژهای عمرانی
  // =====================================================

  Future<List<Map<String, dynamic>>>
  getCivilCharges() async {
    final response =
    await _getWithRefresh(
      ApiConfig.civilCharges,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'خطا در دریافت شارژهای عمرانی: '
            '${response.statusCode}',
      );
    }

    final data =
    jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception(
        'ساختار پاسخ شارژ عمرانی نامعتبر است.',
      );
    }

    final charges =
    data['charges'];

    if (charges is! List) {
      return [];
    }

    return charges
        .whereType<Map>()
        .map(
          (item) =>
      Map<String, dynamic>.from(item),
    )
        .toList();
  }

  // =====================================================
  // اقساط شارژ عمرانی
  // =====================================================

  Future<Map<String, dynamic>>
  getCivilInstallments(
      int civilId,
      ) async {
    final response =
    await _getWithRefresh(
      ApiConfig.civilInstallments(
        civilId,
      ),
    );

    if (response.statusCode == 200) {
      final decoded =
      jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'ساختار پاسخ اقساط شارژ عمرانی نامعتبر است.',
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'دریافت اقساط ناموفق بود.',
        );
      }

      return decoded;
    }

    if (response.statusCode == 404) {
      throw Exception(
        'شارژ عمرانی یا واحد پیدا نشد.',
      );
    }

    throw Exception(
      'خطا در دریافت اقساط شارژ عمرانی: '
          '${response.statusCode}',
    );
  }

  // =====================================================
  // روش‌های پرداخت قسط عمرانی
  // =====================================================

  Future<Map<String, dynamic>>
  getCivilInstallmentPaymentMethods(
      int installmentId,
      ) async {
    final response =
    await _getWithRefresh(
      ApiConfig.civilInstallmentPaymentMethods(
        installmentId,
      ),
    );

    if (response.statusCode == 200) {
      final data =
      jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception(
        'ساختار پاسخ روش‌های پرداخت شارژ عمرانی نامعتبر است.',
      );
    }

    throw Exception(
      'خطا در دریافت روش‌های پرداخت شارژ عمرانی: '
          '${response.statusCode}',
    );
  }

  // =====================================================
  // ثبت پرداخت دستی قسط عمرانی
  // =====================================================

  Future<Map<String, dynamic>>
  submitManualCivilInstallmentPayment({
    required int installmentId,
    required int bankId,
    required String transactionReference,
    required String paymentDate,
  }) async {
    final response =
    await _postWithRefresh(
      ApiConfig.manualCivilInstallmentPayment(
        installmentId,
      ),
      body: {
        'bank_id': bankId,
        'transaction_reference':
        transactionReference,
        'payment_date': paymentDate,
      },
    );

    Map<String, dynamic> data = {};

    try {
      final decoded =
      jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {}

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return data;
    }

    if (response.statusCode == 400) {
      throw Exception(
        data['message']?.toString() ??
            data['detail']?.toString() ??
            'اطلاعات پرداخت صحیح نیست.',
      );
    }

    throw Exception(
      data['message']?.toString() ??
          data['detail']?.toString() ??
          'خطا در ثبت پرداخت شارژ عمرانی: '
              '${response.statusCode}',
    );
  }

  // =====================================================
  // هزینه‌های فاضلاب
  // =====================================================

  Future<List<Map<String, dynamic>>>
  getSewageCharges() async {
    final response =
    await _getWithRefresh(
      ApiConfig.sewageCharges,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'خطا در دریافت هزینه فاضلاب: '
            '${response.statusCode}',
      );
    }

    final data =
    jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception(
        'ساختار پاسخ هزینه فاضلاب نامعتبر است.',
      );
    }

    final charges =
    data['charges'];

    if (charges is! List) {
      return [];
    }

    return charges
        .whereType<Map>()
        .map(
          (item) =>
      Map<String, dynamic>.from(item),
    )
        .toList();
  }

  // =====================================================
  // اقساط فاضلاب
  // =====================================================

  Future<Map<String, dynamic>>
  getSewageInstallments(
      int sewageId,
      ) async {
    final response =
    await _getWithRefresh(
      ApiConfig.sewageInstallments(
        sewageId,
      ),
    );

    if (response.statusCode == 200) {
      final decoded =
      jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'ساختار پاسخ اقساط هزینه فاضلاب نامعتبر است.',
        );
      }

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'دریافت اقساط ناموفق بود.',
        );
      }

      return decoded;
    }

    if (response.statusCode == 404) {
      throw Exception(
        'هزینه فاضلاب یا واحد پیدا نشد.',
      );
    }

    throw Exception(
      'خطا در دریافت اقساط هزینه فاضلاب: '
          '${response.statusCode}',
    );
  }

  // =====================================================
  // روش‌های پرداخت قسط فاضلاب
  // =====================================================

  Future<Map<String, dynamic>>
  getSewageInstallmentPaymentMethods(
      int installmentId,
      ) async {
    final response =
    await _getWithRefresh(
      ApiConfig.sewageInstallmentPaymentMethods(
        installmentId,
      ),
    );

    if (response.statusCode == 200) {
      final data =
      jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception(
        'ساختار پاسخ روش‌های پرداخت هزینه فاضلاب نامعتبر است.',
      );
    }

    throw Exception(
      'خطا در دریافت روش‌های پرداخت هزینه فاضلاب: '
          '${response.statusCode}',
    );
  }

  // =====================================================
  // ثبت پرداخت دستی قسط فاضلاب
  // =====================================================

  Future<Map<String, dynamic>>
  submitManualSewageInstallmentPayment({
    required int installmentId,
    required int bankId,
    required String transactionReference,
    required String paymentDate,
  }) async {
    final response =
    await _postWithRefresh(
      ApiConfig.manualSewageInstallmentPayment(
        installmentId,
      ),
      body: {
        'bank_id': bankId,
        'transaction_reference':
        transactionReference,
        'payment_date': paymentDate,
      },
    );

    Map<String, dynamic> data = {};

    try {
      final decoded =
      jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {}

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return data;
    }

    if (response.statusCode == 400) {
      throw Exception(
        data['message']?.toString() ??
            data['detail']?.toString() ??
            'اطلاعات پرداخت صحیح نیست.',
      );
    }

    throw Exception(
      data['message']?.toString() ??
          data['detail']?.toString() ??
          'خطا در ثبت پرداخت هزینه فاضلاب: '
              '${response.statusCode}',
    );
  }

  // =====================================================
  // جزئیات شارژ
  // =====================================================

  Future<Map<String, dynamic>>
  getChargeDetail(
      int chargeId,
      ) async {
    final response =
    await _getWithRefresh(
      ApiConfig.chargeDetail(
        chargeId,
      ),
    );

    if (response.statusCode == 200) {
      final data =
      jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        final charge =
        data['charge'];

        if (charge is Map<String, dynamic>) {
          return charge;
        }
      }

      throw Exception(
        'ساختار پاسخ جزئیات شارژ نامعتبر است.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'شارژ مورد نظر پیدا نشد.',
      );
    }

    throw Exception(
      'خطا در دریافت جزئیات شارژ: '
          '${response.statusCode}',
    );
  }

  // =====================================================
  // لیست کمک‌های من به ساختمان
  // =====================================================

  Future<List<Map<String, dynamic>>>
  getUserPayments() async {
    final response =
    await _getWithRefresh(
      ApiConfig.userPayments,
    );

    if (response.statusCode == 200) {
      final data =
      jsonDecode(response.body);

      if (data is Map &&
          data['success'] == true) {
        final payments =
        data['payments'];

        if (payments is List) {
          return payments
              .map<Map<String, dynamic>>(
                (item) =>
            Map<String, dynamic>.from(
              item,
            ),
          )
              .toList();
        }
      }

      return [];
    }

    throw Exception(
      'خطا در دریافت کمک‌های ساختمان '
          '(${response.statusCode})',
    );
  }

  // =====================================================
  // ثبت کمک جدید به ساختمان
  // =====================================================

  Future<Map<String, dynamic>>
  createUserPayment({
    required dynamic amount,
    required String description,
    required String registerDate,
    String? details,
    String? payerName,
  }) async {
    final body =
    <String, dynamic>{
      'amount': amount,
      'description': description,
      'register_date': registerDate,
    };

    if (details != null &&
        details.trim().isNotEmpty) {
      body['details'] =
          details.trim();
    }

    if (payerName != null &&
        payerName.trim().isNotEmpty) {
      body['payer_name'] =
          payerName.trim();
    }

    final response =
    await _postWithRefresh(
      ApiConfig.userPayments,
      body: body,
    );

    Map<String, dynamic> data = {};

    try {
      final decoded =
      jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {}

    if (response.statusCode == 201) {
      return data;
    }

    String message =
        'ثبت کمک با خطا مواجه شد.';

    if (data['message'] != null) {
      message =
          data['message'].toString();
    } else if (data['errors'] != null) {
      message =
          data['errors'].toString();
    }

    throw Exception(message);
  }

  // =====================================================
  // دریافت روش‌های پرداخت کمک
  // =====================================================

  Future<Map<String, dynamic>>
  getUserPaymentPaymentMethods(
      int paymentId,
      ) async {
    final response =
    await _getWithRefresh(
      ApiConfig.userPaymentPaymentMethods(
        paymentId,
      ),
    );

    if (response.statusCode == 200) {
      final data =
      jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception(
        'ساختار پاسخ روش‌های پرداخت کمک نامعتبر است.',
      );
    }

    Map<String, dynamic> data = {};

    try {
      final decoded =
      jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {}

    throw Exception(
      data['message']?.toString() ??
          data['detail']?.toString() ??
          'خطا در دریافت روش‌های پرداخت کمک: '
              '${response.statusCode}',
    );
  }

  // =====================================================
  // ثبت پرداخت دستی کمک
  // =====================================================

  Future<Map<String, dynamic>>
  submitManualUserPayment({
    required int paymentId,
    required int bankId,
    required String transactionReference,
    required String paymentDate,
  }) async {
    final response =
    await _postWithRefresh(
      ApiConfig.manualUserPayment(
        paymentId,
      ),
      body: {
        'bank_id': bankId,
        'transaction_reference':
        transactionReference,
        'payment_date': paymentDate,
      },
    );

    Map<String, dynamic> data = {};

    try {
      final decoded =
      jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {}

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return data;
    }

    if (response.statusCode == 400) {
      final errors =
      data['errors'];

      if (errors is Map) {
        final messages =
        <String>[];

        errors.forEach(
              (key, value) {
            if (value is List) {
              messages.addAll(
                value.map(
                      (item) => item.toString(),
                ),
              );
            } else {
              messages.add(
                value.toString(),
              );
            }
          },
        );

        if (messages.isNotEmpty) {
          throw Exception(
            messages.join('\n'),
          );
        }
      }

      throw Exception(
        data['message']?.toString() ??
            data['detail']?.toString() ??
            'اطلاعات پرداخت صحیح نیست.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'مسیر ثبت پرداخت کمک پیدا نشد.',
      );
    }

    throw Exception(
      data['message']?.toString() ??
          data['detail']?.toString() ??
          'خطا در ثبت پرداخت کمک: '
              '${response.statusCode}',
    );
  }

  // =====================================================
  // دریافت پیام‌های مدیر
  // =====================================================

  Future<Map<String, dynamic>>
  getMessages() async {
    final response =
    await _getWithRefresh(
      ApiConfig.messages,
    );

    if (response.statusCode == 200) {
      final data =
      jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception(
        'ساختار پاسخ پیام‌ها نامعتبر است.',
      );
    }

    Map<String, dynamic> data = {};

    try {
      final decoded =
      jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {}

    throw Exception(
      data['message']?.toString() ??
          data['detail']?.toString() ??
          'خطا در دریافت پیام‌ها: '
              '${response.statusCode}',
    );
  }

  // =====================================================
  // علامت‌گذاری پیام به عنوان خوانده شده
  // =====================================================

  Future<Map<String, dynamic>>
  markMessageAsRead(
      int messageId,
      ) async {
    final response =
    await _postWithRefresh(
      ApiConfig.messageRead(
        messageId,
      ),
    );

    Map<String, dynamic> data = {};

    try {
      final decoded =
      jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    } catch (_) {}

    if (response.statusCode == 200) {
      return data;
    }

    if (response.statusCode == 404) {
      throw Exception(
        data['message']?.toString() ??
            'پیام مورد نظر پیدا نشد.',
      );
    }

    throw Exception(
      data['message']?.toString() ??
          data['detail']?.toString() ??
          'خطا در ثبت وضعیت خوانده شدن پیام: '
              '${response.statusCode}',
    );
  }
}