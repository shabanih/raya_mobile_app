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

      debugPrint(
        'LOGIN STATUS: ${response.statusCode}',
      );

      debugPrint(
        'LOGIN RESPONSE: ${response.body}',
      );

      if (response.statusCode != 200) {
        Map<String, dynamic> data = {};

        try {
          final decoded =
          jsonDecode(response.body);

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

      final decoded =
      jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'پاسخ نامعتبر از سرور دریافت شد.',
        );
      }

      return decoded;
    } catch (e) {
      debugPrint(
        'LOGIN ERROR: $e',
      );

      rethrow;
    }
  }

  // =====================================================
  // دریافت اطلاعات کاربر
  // =====================================================

  Future<Map<String, dynamic>> getMe() async {
    final token =
    await TokenStorage.getAccessToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception(
        'توکن ورود پیدا نشد',
      );
    }

    final response = await http.get(
      Uri.parse(ApiConfig.me),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
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

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception(
        'اطلاعات کاربر نامعتبر است.',
      );
    }

    if (response.statusCode == 401) {
      throw Exception(
        'TOKEN_EXPIRED',
      );
    }

    throw Exception(
      'خطا در دریافت اطلاعات کاربر: '
          '${response.statusCode}',
    );
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

      final data =
      jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        return false;
      }

      final newAccessToken =
      data['access'];

      if (newAccessToken == null ||
          newAccessToken
              .toString()
              .isEmpty) {
        return false;
      }

      await TokenStorage.saveTokens(
        newAccessToken.toString(),
        refreshToken,
      );

      return true;
    } catch (e) {
      debugPrint(
        'REFRESH ERROR: $e',
      );

      return false;
    }
  }

  // =====================================================
  // دریافت اطلاعات کاربر با Refresh خودکار
  // =====================================================

  Future<Map<String, dynamic>>
  getMeWithRefresh() async {
    try {
      return await getMe();
    } catch (e) {
      debugPrint(
        'GET ME FIRST ATTEMPT ERROR: $e',
      );

      final refreshed =
      await refreshAccessToken();

      if (!refreshed) {
        rethrow;
      }

      return await getMe();
    }
  }
}