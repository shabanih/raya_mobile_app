import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerMessageService {
  final ApiService _apiService = ApiService();

  // =====================================================
  // دریافت تمام پیام‌های مدیر
  //
  // شامل:
  // - پیام‌های آماده ارسال
  // - پیام‌های ارسال شده
  //
  // GET /api/manager/messages/
  // =====================================================

  Future<Map<String, dynamic>> getMessages({
    String query = '',
  }) async {
    String url = ApiConfig.managerMessages;

    if (query.trim().isNotEmpty) {
      url =
      '$url?q=${Uri.encodeQueryComponent(query.trim())}';
    }

    final response = await _apiService.get(url);

    return _handleResponse(response);
  }

  // =====================================================
  // دریافت مالکین و مستأجرین قابل انتخاب
  //
  // GET /api/manager/messages/units/
  // =====================================================

  Future<Map<String, dynamic>> getUnits() async {
    final response = await _apiService.get(
      ApiConfig.managerMessageUnits,
    );

    return _handleResponse(response);
  }

  // =====================================================
  // ایجاد پیام جدید
  //
  // POST /api/manager/messages/
  // =====================================================

  Future<Map<String, dynamic>> createMessage({
    required String title,
    required String message,
  }) async {
    final response = await _apiService.post(
      ApiConfig.managerMessages,
      body: {
        'title': title,
        'message': message,
      },
    );

    return _handleResponse(response);
  }

  // =====================================================
  // دریافت جزئیات پیام
  //
  // GET /api/manager/messages/<id>/
  // =====================================================

  Future<Map<String, dynamic>> getMessage(
      int messageId,
      ) async {
    final response = await _apiService.get(
      ApiConfig.managerMessageDetail(messageId),
    );

    return _handleResponse(response);
  }

  // =====================================================
  // ویرایش پیام
  //
  // فقط پیام‌هایی که هنوز ارسال نشده‌اند.
  //
  // PATCH /api/manager/messages/<id>/
  // =====================================================

  Future<Map<String, dynamic>> updateMessage({
    required int messageId,
    required String title,
    required String message,
  }) async {
    final response = await _apiService.patch(
      ApiConfig.managerMessageDetail(messageId),
      body: {
        'title': title,
        'message': message,
      },
    );

    return _handleResponse(response);
  }

  // =====================================================
  // حذف پیام
  //
  // فقط پیام‌هایی که هنوز ارسال نشده‌اند.
  //
  // DELETE /api/manager/messages/<id>/
  // =====================================================

  Future<Map<String, dynamic>> deleteMessage(
      int messageId,
      ) async {
    final response = await _apiService.delete(
      ApiConfig.managerMessageDetail(messageId),
    );

    return _handleResponse(response);
  }

  // =====================================================
  // ارسال پیام
  //
  // POST /api/manager/messages/<id>/send/
  // =====================================================

  Future<Map<String, dynamic>> sendMessage({
    required int messageId,
    required bool sendToAll,
    required List<Map<String, dynamic>> recipients,
  }) async {
    final response = await _apiService.post(
      ApiConfig.managerMessageSend(messageId),
      body: {
        'all': sendToAll,
        'recipients': recipients,
      },
    );

    return _handleResponse(response);
  }

  // =====================================================
  // مدیریت پاسخ API
  // =====================================================

  Map<String, dynamic> _handleResponse(
      http.Response response,
      ) {
    dynamic data;

    try {
      data = jsonDecode(
        utf8.decode(
          response.bodyBytes,
        ),
      );
    } catch (_) {
      data = {
        'detail': utf8.decode(
          response.bodyBytes,
        ),
      };
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map<String, dynamic>) {
        return data;
      }

      return {
        'data': data,
      };
    }

    String message =
        'خطایی در ارتباط با سرور رخ داده است.';

    if (data is Map<String, dynamic>) {
      final detail = data['detail'];

      if (detail != null &&
          detail.toString().trim().isNotEmpty) {
        message = detail.toString();
      } else if (data['message'] != null) {
        message = data['message'].toString();
      }
    }

    throw Exception(message);
  }
}