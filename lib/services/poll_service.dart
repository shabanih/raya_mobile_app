import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class PollService {
  // =====================================================
  // دریافت لیست نظرسنجی‌ها
  // =====================================================

  static Future<List<Map<String, dynamic>>> getPolls() async {
    final accessToken =
    await TokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('توکن ورود پیدا نشد.');
    }

    final response = await http.get(
      Uri.parse(ApiConfig.polls),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      final List<dynamic> polls =
          data['polls'] ?? [];

      return polls
          .map(
            (item) =>
        Map<String, dynamic>.from(item),
      )
          .toList();
    }

    if (response.statusCode == 401) {
      throw Exception(
        'نشست کاربر منقضی شده است.',
      );
    }

    try {
      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      throw Exception(
        data['message'] ??
            data['detail'] ??
            'خطا در دریافت نظرسنجی‌ها.',
      );
    } catch (_) {
      throw Exception(
        'خطا در دریافت نظرسنجی‌ها: '
            '${response.statusCode}',
      );
    }
  }

  // =====================================================
  // دریافت جزئیات یک نظرسنجی
  // =====================================================

  static Future<Map<String, dynamic>> getPoll(
      int id,
      ) async {
    final accessToken =
    await TokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception(
        'توکن ورود پیدا نشد.',
      );
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.polls}$id/',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      return Map<String, dynamic>.from(
        data['poll'],
      );
    }

    if (response.statusCode == 401) {
      throw Exception(
        'نشست کاربر منقضی شده است.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'این نظرسنجی پیدا نشد یا زمان آن به پایان رسیده است.',
      );
    }

    try {
      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      throw Exception(
        data['message'] ??
            data['detail'] ??
            'خطا در دریافت نظرسنجی.',
      );
    } catch (_) {
      throw Exception(
        'خطا در دریافت نظرسنجی: '
            '${response.statusCode}',
      );
    }
  }

  // =====================================================
  // ثبت رأی
  // =====================================================

  static Future<void> submitVote({
    required int pollId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final accessToken =
    await TokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception(
        'توکن ورود پیدا نشد.',
      );
    }

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.polls}$pollId/vote/',
      ),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'answers': answers,
      }),
    );

    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 401) {
      throw Exception(
        'نشست کاربر منقضی شده است.',
      );
    }

    try {
      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      throw Exception(
        data['message'] ??
            data['detail'] ??
            'ثبت رأی انجام نشد.',
      );
    } catch (_) {
      throw Exception(
        'ثبت رأی انجام نشد: '
            '${response.statusCode}',
      );
    }
  }
}