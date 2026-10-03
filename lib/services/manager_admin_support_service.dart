import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_service.dart';

class ManagerAdminSupportService {
  final ApiService apiService;

  ManagerAdminSupportService({
    required this.apiService,
  });

  // =====================================================
  // Decode Response
  // =====================================================

  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    return {};
  }

  // =====================================================
  // استخراج پیام خطا
  // =====================================================

  String _extractError(
      http.Response response, {
        String defaultMessage = 'خطایی در ارتباط با سرور رخ داد.',
      }) {
    final data = _decodeResponse(response);

    if (data['message'] != null) {
      return data['message'].toString();
    }

    if (data['detail'] != null) {
      return data['detail'].toString();
    }

    final errors = data['errors'];

    if (errors is Map) {
      final messages = <String>[];

      errors.forEach((key, value) {
        if (value is List) {
          for (final item in value) {
            messages.add(item.toString());
          }
        } else {
          messages.add(value.toString());
        }
      });

      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }

    return defaultMessage;
  }

  // =====================================================
  // GET
  // =====================================================

  Future<List<Map<String, dynamic>>> getTickets() async {
    final response = await apiService.get(
      ApiConfig.managerAdminSupportTickets,
    );

    debugPrint(
      'ADMIN SUPPORT LIST STATUS: ${response.statusCode}',
    );

    debugPrint(
      'ADMIN SUPPORT LIST BODY: ${response.body}',
    );

    if (response.statusCode == 200) {
      final data = _decodeResponse(response);

      final tickets = data['tickets'];

      if (tickets is List) {
        return tickets
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
        )
            .toList();
      }

      return [];
    }

    if (response.statusCode == 403) {
      throw Exception('دسترسی به پشتیبانی سامانه ندارید.');
    }

    throw Exception(
      _extractError(
        response,
        defaultMessage:
        'خطا در دریافت تیکت‌های پشتیبانی.',
      ),
    );
  }

  // =====================================================
  // جزئیات تیکت
  // =====================================================

  Future<Map<String, dynamic>> getTicket(
      int ticketId,
      ) async {
    final response = await apiService.get(
      ApiConfig.managerAdminSupportTicketDetail(
        ticketId,
      ),
    );

    debugPrint(
      'ADMIN SUPPORT DETAIL STATUS: ${response.statusCode}',
    );

    debugPrint(
      'ADMIN SUPPORT DETAIL BODY: ${response.body}',
    );

    if (response.statusCode == 200) {
      final data = _decodeResponse(response);

      final ticket = data['ticket'];

      if (ticket is Map) {
        return Map<String, dynamic>.from(ticket);
      }

      throw Exception(
        'ساختار اطلاعات تیکت نامعتبر است.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'تیکت مورد نظر پیدا نشد.',
      );
    }

    throw Exception(
      _extractError(
        response,
        defaultMessage:
        'خطا در دریافت جزئیات تیکت.',
      ),
    );
  }

  // =====================================================
  // تعداد پیام‌های خوانده نشده
  // =====================================================

  Future<int> getUnreadCount() async {
    final response = await apiService.get(
      ApiConfig.managerAdminSupportUnreadCount,
    );

    debugPrint(
      'ADMIN SUPPORT UNREAD STATUS: ${response.statusCode}',
    );

    if (response.statusCode == 200) {
      final data = _decodeResponse(response);

      final count = data['unread_count'];

      if (count is int) {
        return count;
      }

      if (count is num) {
        return count.toInt();
      }

      return 0;
    }

    if (response.statusCode == 403) {
      return 0;
    }

    throw Exception(
      _extractError(
        response,
        defaultMessage:
        'خطا در دریافت تعداد پیام‌های جدید.',
      ),
    );
  }

  // =====================================================
  // Multipart داخلی با چند فایل
  // =====================================================

  Future<http.Response> _postMultipartMultiple({
    required String url,
    Map<String, String>? fields,
    List<String> filePaths = const [],
    String fileFieldName = 'files',
  }) async {
    var accessToken =
    await TokenStorage.getAccessToken();

    if (accessToken == null ||
        accessToken.trim().isEmpty) {
      throw Exception(
        'توکن ورود پیدا نشد.',
      );
    }

    accessToken = accessToken.trim();

    Future<http.Response> sendRequest(
        String token,
        ) async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(url),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (fields != null && fields.isNotEmpty) {
        request.fields.addAll(fields);
      }

      for (final filePath in filePaths) {
        if (filePath.trim().isEmpty) {
          continue;
        }

        final file = File(filePath);

        if (!await file.exists()) {
          continue;
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            fileFieldName,
            file.path,
          ),
        );
      }

      debugPrint(
        'ADMIN SUPPORT MULTIPART URL: $url',
      );

      debugPrint(
        'ADMIN SUPPORT MULTIPART FILE COUNT: '
            '${request.files.length}',
      );

      final streamedResponse =
      await request.send();

      return http.Response.fromStream(
        streamedResponse,
      );
    }

    http.Response response;

    try {
      response = await sendRequest(
        accessToken,
      );
    } on SocketException {
      throw Exception('NO_INTERNET');
    } on http.ClientException {
      throw Exception('NO_INTERNET');
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }

      throw Exception(
        'خطا در ارسال اطلاعات.',
      );
    }

    // =====================================================
    // Refresh Token
    // =====================================================

    if (response.statusCode == 401) {
      debugPrint(
        'ADMIN SUPPORT MULTIPART 401 -> TRY REFRESH',
      );

      final refreshed =
      await apiService.refreshAccessToken();

      if (!refreshed) {
        throw Exception(
          'TOKEN_EXPIRED',
        );
      }

      final newToken =
      await TokenStorage.getAccessToken();

      if (newToken == null ||
          newToken.trim().isEmpty) {
        throw Exception(
          'TOKEN_EXPIRED',
        );
      }

      try {
        response = await sendRequest(
          newToken.trim(),
        );
      } on SocketException {
        throw Exception('NO_INTERNET');
      } on http.ClientException {
        throw Exception('NO_INTERNET');
      }
    }

    return response;
  }

  // =====================================================
  // ایجاد تیکت جدید
  // =====================================================

  Future<Map<String, dynamic>> createTicket({
    String? subject,
    required String message,
    List<String> filePaths = const [],
  }) async {
    final cleanMessage = message.trim();

    if (cleanMessage.isEmpty) {
      throw Exception(
        'متن تیکت را وارد کنید.',
      );
    }

    final fields = <String, String>{
      'message': cleanMessage,
    };

    if (subject != null &&
        subject.trim().isNotEmpty) {
      fields['subject'] = subject.trim();
    }

    final response =
    await _postMultipartMultiple(
      url:
      ApiConfig.managerAdminSupportCreateTicket,
      fields: fields,
      filePaths: filePaths,
      fileFieldName: 'files',
    );

    debugPrint(
      'CREATE ADMIN SUPPORT STATUS: '
          '${response.statusCode}',
    );

    debugPrint(
      'CREATE ADMIN SUPPORT BODY: '
          '${response.body}',
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return data;
    }

    throw Exception(
      _extractError(
        response,
        defaultMessage:
        'ایجاد تیکت با خطا مواجه شد.',
      ),
    );
  }

  // =====================================================
  // ارسال پیام در تیکت
  // =====================================================

  Future<Map<String, dynamic>> sendMessage({
    required int ticketId,
    String message = '',
    List<String> filePaths = const [],
  }) async {
    final cleanMessage = message.trim();

    if (cleanMessage.isEmpty &&
        filePaths.isEmpty) {
      throw Exception(
        'متن پیام یا فایل را وارد کنید.',
      );
    }

    final response =
    await _postMultipartMultiple(
      url:
      ApiConfig.managerAdminSupportTicketMessage(
        ticketId,
      ),
      fields: {
        'message': cleanMessage,
      },
      filePaths: filePaths,
      fileFieldName: 'files',
    );

    debugPrint(
      'SEND ADMIN SUPPORT MESSAGE STATUS: '
          '${response.statusCode}',
    );

    debugPrint(
      'SEND ADMIN SUPPORT MESSAGE BODY: '
          '${response.body}',
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return data;
    }

    if (response.statusCode == 400) {
      throw Exception(
        _extractError(
          response,
          defaultMessage:
          'ارسال پیام امکان‌پذیر نیست.',
        ),
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'تیکت مورد نظر پیدا نشد.',
      );
    }

    throw Exception(
      _extractError(
        response,
        defaultMessage:
        'ارسال پیام با خطا مواجه شد.',
      ),
    );
  }

  // =====================================================
  // بستن تیکت
  // =====================================================

  Future<Map<String, dynamic>> closeTicket(
      int ticketId,
      ) async {
    final response = await apiService.post(
      ApiConfig.managerAdminSupportTicketClose(
        ticketId,
      ),
    );

    debugPrint(
      'CLOSE ADMIN SUPPORT STATUS: '
          '${response.statusCode}',
    );

    debugPrint(
      'CLOSE ADMIN SUPPORT BODY: '
          '${response.body}',
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return data;
    }

    if (response.statusCode == 404) {
      throw Exception(
        'تیکت مورد نظر پیدا نشد.',
      );
    }

    throw Exception(
      _extractError(
        response,
        defaultMessage:
        'بستن تیکت با خطا مواجه شد.',
      ),
    );
  }

  // =====================================================
  // علامت‌گذاری تیکت به عنوان خوانده شده
  // =====================================================

  Future<Map<String, dynamic>> markAsRead(
      int ticketId,
      ) async {
    final response = await apiService.post(
      ApiConfig.managerAdminSupportTicketRead(
        ticketId,
      ),
    );

    debugPrint(
      'MARK ADMIN SUPPORT READ STATUS: '
          '${response.statusCode}',
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      return data;
    }

    if (response.statusCode == 404) {
      throw Exception(
        'تیکت مورد نظر پیدا نشد.',
      );
    }

    throw Exception(
      _extractError(
        response,
        defaultMessage:
        'تغییر وضعیت خوانده شدن تیکت ناموفق بود.',
      ),
    );
  }
}