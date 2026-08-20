import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class ApiService {
  // =====================================================
  // Login
  // =====================================================

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      debugPrint('LOGIN STATUS: ${response.statusCode}');
      debugPrint('LOGIN RESPONSE: ${response.body}');

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
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      rethrow;
    }
  }

  // =====================================================
  // دریافت اطلاعات کاربر
  // =====================================================

  Future<Map<String, dynamic>> getMe() async {
    final token = await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('توکن ورود پیدا نشد');
    }

    final response = await http.get(
      Uri.parse(ApiConfig.me),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('ME STATUS: ${response.statusCode}');
    debugPrint('ME RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception(
        'اطلاعات کاربر نامعتبر است.',
      );
    }

    if (response.statusCode == 401) {
      throw Exception('TOKEN_EXPIRED');
    }

    throw Exception(
      'خطا در دریافت اطلاعات کاربر: '
          '${response.statusCode}',
    );
  }

  // =====================================================
  // دریافت اطلاعات Dashboard
  // =====================================================

  Future<Map<String, dynamic>> getDashboard() async {
    Future<Map<String, dynamic>> request() async {
      final token = await TokenStorage.getAccessToken();

      if (token == null || token.isEmpty) {
        throw Exception('توکن ورود پیدا نشد');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.dashboard),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('==========================================');
      debugPrint('GET DASHBOARD');
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');
      debugPrint('==========================================');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is! Map<String, dynamic>) {
          throw Exception(
            'اطلاعات Dashboard نامعتبر است.',
          );
        }

        final statistics = data['statistics'];

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

      if (response.statusCode == 401) {
        throw Exception('TOKEN_EXPIRED');
      }

      throw Exception(
        'خطا در دریافت Dashboard: '
            '${response.statusCode}',
      );
    }

    try {
      return await request();
    } catch (e) {
      debugPrint(
        'GET DASHBOARD FIRST ATTEMPT ERROR: $e',
      );

      if (e.toString().contains('TOKEN_EXPIRED')) {
        final refreshed = await refreshAccessToken();

        if (!refreshed) {
          rethrow;
        }

        return await request();
      }

      rethrow;
    }
  }

  // =====================================================
  // Refresh Token
  // =====================================================

  Future<bool> refreshAccessToken() async {
    final refreshToken =
    await TokenStorage.getRefreshToken();

    if (refreshToken == null ||
        refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.refresh),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'refresh': refreshToken,
        }),
      );

      debugPrint(
        'REFRESH STATUS: ${response.statusCode}',
      );

      debugPrint(
        'REFRESH RESPONSE: ${response.body}',
      );

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        return false;
      }

      final newAccessToken = data['access'];

      if (newAccessToken == null ||
          newAccessToken.toString().isEmpty) {
        return false;
      }

      await TokenStorage.saveTokens(
        newAccessToken.toString(),
        refreshToken,
      );

      return true;
    } catch (e) {
      debugPrint('REFRESH ERROR: $e');
      return false;
    }
  }

  // =====================================================
  // دریافت اطلاعات کاربر با Refresh خودکار
  // =====================================================

  Future<Map<String, dynamic>> getMeWithRefresh() async {
    try {
      return await getMe();
    } catch (e) {
      debugPrint(
        'GET ME FIRST ATTEMPT ERROR: $e',
      );

      if (e.toString().contains('TOKEN_EXPIRED')) {
        final refreshed =
        await refreshAccessToken();

        if (!refreshed) {
          rethrow;
        }

        return await getMe();
      }

      rethrow;
    }
  }

  // =====================================================
  // دریافت لیست شارژها
  // =====================================================

  Future<List<Map<String, dynamic>>> getCharges() async {
    final token =
    await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('توکن ورود پیدا نشد');
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.charges),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        'CHARGES STATUS: ${response.statusCode}',
      );

      debugPrint(
        'CHARGES RESPONSE: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          final charges = data['charges'];

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

      if (response.statusCode == 401) {
        throw Exception('TOKEN_EXPIRED');
      }

      throw Exception(
        'خطا در دریافت لیست شارژها: '
            '${response.statusCode}',
      );
    } catch (e) {
      debugPrint(
        'GET CHARGES ERROR: $e',
      );

      rethrow;
    }
  }

  // =====================================================
  // دریافت روش‌های پرداخت شارژ
  // =====================================================

  Future<Map<String, dynamic>>
  getChargePaymentMethods(
      int chargeId,
      ) async {
    final token =
    await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('توکن ورود پیدا نشد');
    }

    try {
      final url =
      ApiConfig.chargePaymentMethods(
        chargeId,
      );

      debugPrint(
        'PAYMENT METHODS URL: $url',
      );

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        'PAYMENT METHODS STATUS: '
            '${response.statusCode}',
      );

      debugPrint(
        'PAYMENT METHODS RESPONSE: '
            '${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          return data;
        }

        throw Exception(
          'ساختار پاسخ روش‌های پرداخت نامعتبر است.',
        );
      }

      if (response.statusCode == 401) {
        throw Exception('TOKEN_EXPIRED');
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
    } catch (e) {
      debugPrint(
        'GET PAYMENT METHODS ERROR: $e',
      );

      rethrow;
    }
  }

  // =====================================================
  // دریافت حساب‌های بانکی
  // =====================================================

  Future<List<Map<String, dynamic>>>
  getPaymentBanks(
      int chargeId,
      ) async {
    final token =
    await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('توکن ورود پیدا نشد');
    }

    try {
      final url =
      ApiConfig.paymentBanks(chargeId);

      debugPrint(
        'PAYMENT BANKS URL: $url',
      );

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        'PAYMENT BANKS STATUS: '
            '${response.statusCode}',
      );

      debugPrint(
        'PAYMENT BANKS RESPONSE: '
            '${response.body}',
      );

      if (response.statusCode == 401) {
        throw Exception('TOKEN_EXPIRED');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'خطا در دریافت حساب‌های بانکی: '
              '${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'پاسخ حساب‌های بانکی نامعتبر است.',
        );
      }

      final banks = data['banks'];

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
    } catch (e) {
      debugPrint(
        'GET PAYMENT BANKS ERROR: $e',
      );

      rethrow;
    }
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
    final token =
    await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('توکن ورود پیدا نشد');
    }

    try {
      final url =
      ApiConfig.manualChargePayment(
        chargeId,
      );

      debugPrint(
        'MANUAL PAYMENT URL: $url',
      );

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'bank_id': bankId,
          'transaction_reference':
          transactionReference,
          'payment_date': paymentDate,
        }),
      );

      debugPrint(
        'MANUAL PAYMENT STATUS: '
            '${response.statusCode}',
      );

      debugPrint(
        'MANUAL PAYMENT RESPONSE: '
            '${response.body}',
      );

      Map<String, dynamic> data = {};

      try {
        final decoded =
        jsonDecode(response.body);

        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {}

      // موفق
      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return data;
      }

      // خطای اعتبارسنجی
      if (response.statusCode == 400) {
        final errors = data['errors'];

        if (errors is Map) {
          final messages = <String>[];

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

      if (response.statusCode == 401) {
        throw Exception('TOKEN_EXPIRED');
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
    } catch (e) {
      debugPrint(
        'MANUAL PAYMENT ERROR: $e',
      );

      rethrow;
    }
  }

  // =====================================================
  // دریافت تاریخچه پرداخت‌ها
  // =====================================================

  Future<List<Map<String, dynamic>>>
  getPaymentHistory() async {
    final token =
    await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('توکن ورود پیدا نشد');
    }

    final uri =
    Uri.parse(ApiConfig.paymentHistory);

    debugPrint(
      '==========================================',
    );
    debugPrint('GET PAYMENT HISTORY');
    debugPrint('URL: $uri');
    debugPrint('TOKEN EXISTS: true');
    debugPrint(
      '==========================================',
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        'PAYMENT HISTORY STATUS: '
            '${response.statusCode}',
      );

      debugPrint(
        'PAYMENT HISTORY BODY: '
            '${response.body}',
      );

      // ================================================
      // توکن منقضی شده
      // ================================================

      if (response.statusCode == 401) {
        throw Exception('TOKEN_EXPIRED');
      }

      // ================================================
      // سایر خطاها
      // ================================================

      if (response.statusCode != 200) {
        throw Exception(
          'خطا در دریافت تراکنش‌ها: '
              '${response.statusCode}',
        );
      }

      // ================================================
      // Decode
      // ================================================

      final decoded =
      jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'ساختار پاسخ تاریخچه تراکنش‌ها نامعتبر است.',
        );
      }

      // ================================================
      // بررسی success
      // ================================================

      if (decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'دریافت تراکنش‌ها ناموفق بود.',
        );
      }

      // ================================================
      // دریافت payments
      // ================================================

      final dynamic paymentsData =
      decoded['payments'];

      if (paymentsData is! List) {
        debugPrint(
          'PAYMENT HISTORY: payments is not List',
        );

        return [];
      }

      // ================================================
      // تبدیل به List<Map>
      // ================================================

      final List<Map<String, dynamic>>
      result = [];

      for (final item in paymentsData) {
        if (item is Map) {
          final payment =
          Map<String, dynamic>.from(item);

          debugPrint(
            'PAYMENT ITEM: '
                'id=${payment['id']} | '
                'description=${payment['payment_description']} | '
                'amount=${payment['amount']} | '
                'unit=${payment['unit_number']} | '
                'payer=${payment['payer_name']}',
          );

          result.add(payment);
        }
      }

      debugPrint(
        'TOTAL PAYMENT HISTORY ITEMS: '
            '${result.length}',
      );

      return result;
    } catch (e) {
      debugPrint(
        'GET PAYMENT HISTORY ERROR: $e',
      );

      rethrow;
    }
  }

  // =====================================================
  // دریافت جزئیات یک شارژ
  // =====================================================

  Future<Map<String, dynamic>>
  getChargeDetail(
      int chargeId,
      ) async {
    final token =
    await TokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('توکن ورود پیدا نشد');
    }

    try {
      final response = await http.get(
        Uri.parse(
          ApiConfig.chargeDetail(
            chargeId,
          ),
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(
        'CHARGE DETAIL STATUS: '
            '${response.statusCode}',
      );

      debugPrint(
        'CHARGE DETAIL RESPONSE: '
            '${response.body}',
      );

      if (response.statusCode == 200) {
        final data =
        jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          final charge = data['charge'];

          if (charge is Map<String, dynamic>) {
            return charge;
          }
        }

        throw Exception(
          'ساختار پاسخ جزئیات شارژ نامعتبر است.',
        );
      }

      if (response.statusCode == 401) {
        throw Exception('TOKEN_EXPIRED');
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
    } catch (e) {
      debugPrint(
        'GET CHARGE DETAIL ERROR: $e',
      );

      rethrow;
    }
  }
}