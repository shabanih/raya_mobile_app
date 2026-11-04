
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_service.dart';
import '../config/api_config.dart';

class ManagerAdminMessageService {
  final ApiService apiService;

  ManagerAdminMessageService({
    required this.apiService,
  });

  // تبدیل پاسخ API به Map
  Map<String, dynamic> _decodeResponse(dynamic response) {
    try {
      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      throw Exception('ساختار پاسخ سرور معتبر نیست.');
    } catch (e) {
      if (e is FormatException) {
        throw Exception('پاسخ سرور قابل خواندن نیست.');
      }
      rethrow;
    }
  }

  String _extractErrorMessage(Map<String, dynamic> data) {
    final message = data['message'] ??
        data['detail'] ??
        data['error'];

    if (message != null) {
      return message.toString();
    }

    final errors = data['errors'];

    if (errors is Map) {
      return errors.values
          .expand((value) => value is List ? value : [value])
          .join('\n');
    }

    return 'خطا در ارتباط با سرور';
  }

  // دریافت پیام‌ها
  // status: all | unread | read
  Future<Map<String, dynamic>> getMessages({
    String status = 'all',
  }) async {
    try {
      final url =
          '${ApiConfig.baseUrl}${ApiConfig.managerAdminMessages}?status=$status';

      final response = await apiService.get(url);

      final data = _decodeResponse(response);

      if (response.statusCode == 200 &&
          data['success'] == true) {
        return data;
      }

      throw Exception(_extractErrorMessage(data));
    } catch (e) {
      debugPrint('GET ADMIN MESSAGES ERROR: $e');
      rethrow;
    }
  }

  // ثبت پیام به عنوان خوانده‌شده
  Future<Map<String, dynamic>> markMessageAsRead(
      int messageId,
      ) async {
    try {
      final url =
          '${ApiConfig.baseUrl}${ApiConfig.managerAdminMessageRead(messageId)}';

      final response = await apiService.post(
        url,
        body: {},
      );

      final data = _decodeResponse(response);

      if (response.statusCode == 200 &&
          data['success'] == true) {
        return data;
      }

      throw Exception(_extractErrorMessage(data));
    } catch (e) {
      debugPrint('MARK ADMIN MESSAGE READ ERROR: $e');
      rethrow;
    }
  }
}
