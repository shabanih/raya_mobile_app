import 'dart:convert';

import 'api_service.dart';
import '../config/api_config.dart';

class ManagerSupportService {
  final ApiService apiService;

  ManagerSupportService({
    required this.apiService,
  });

  // =====================================================
  // دریافت لیست تیکت‌ها
  // =====================================================

  Future<List<Map<String, dynamic>>> getTickets() async {
    final response = await apiService.get(
      ApiConfig.managerSupportTickets,
    );

    _debugResponse(
      'GET MANAGER SUPPORT TICKETS',
      response.statusCode,
      response.body,
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      if (data['success'] == false) {
        throw Exception(
          _extractError(
            data,
            'دریافت تیکت‌ها با خطا مواجه شد.',
          ),
        );
      }

      final tickets = data['tickets'];

      if (tickets is! List) {
        return [];
      }

      return tickets
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList();
    }

    throw Exception(
      _extractError(
        data,
        'خطا در دریافت تیکت‌ها: ${response.statusCode}',
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
      ApiConfig.managerSupportTicketDetail(ticketId),
    );

    _debugResponse(
      'GET MANAGER SUPPORT TICKET DETAIL',
      response.statusCode,
      response.body,
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200) {
      if (data['success'] == false) {
        throw Exception(
          _extractError(
            data,
            'دریافت جزئیات تیکت با خطا مواجه شد.',
          ),
        );
      }

      final ticket = data['ticket'];

      if (ticket is Map) {
        return Map<String, dynamic>.from(ticket);
      }

      throw Exception(
        'اطلاعات تیکت در پاسخ سرور وجود ندارد.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'تیکت مورد نظر پیدا نشد.',
      );
    }

    throw Exception(
      _extractError(
        data,
        'خطا در دریافت جزئیات تیکت: ${response.statusCode}',
      ),
    );
  }

  // =====================================================
  // ارسال پاسخ + فایل
  // =====================================================

  Future<int?> sendMessage({
    required int ticketId,
    String? message,
    String? filePath,
  }) async {
    final cleanMessage =
        message?.trim() ?? '';

    final hasMessage =
        cleanMessage.isNotEmpty;

    final hasFile =
        filePath != null &&
            filePath.trim().isNotEmpty;

    if (!hasMessage && !hasFile) {
      throw Exception(
        'متن پاسخ یا فایل پیوست را وارد کنید.',
      );
    }

    final fields = <String, String>{};

    if (hasMessage) {
      fields['message'] = cleanMessage;
    }

    final response =
    await apiService.postMultipart(
      url: ApiConfig.managerSupportTicketMessages(
        ticketId,
      ),
      fields: fields,
      filePath: filePath,
      fileField: 'file',
    );

    _debugResponse(
      'POST MANAGER SUPPORT MESSAGE',
      response.statusCode,
      response.body,
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      if (data['success'] == false) {
        throw Exception(
          _extractError(
            data,
            'ارسال پاسخ با خطا مواجه شد.',
          ),
        );
      }

      final messageId =
      data['message_id'];

      if (messageId == null) {
        return null;
      }

      return int.tryParse(
        messageId.toString(),
      );
    }

    if (response.statusCode == 400) {
      throw Exception(
        _extractError(
          data,
          'اطلاعات پاسخ صحیح نیست.',
        ),
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'شما اجازه پاسخ به این تیکت را ندارید.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'تیکت مورد نظر پیدا نشد.',
      );
    }

    throw Exception(
      _extractError(
        data,
        'خطا در ارسال پاسخ: ${response.statusCode}',
      ),
    );
  }

  // =====================================================
  // قرار دادن تیکت در حالت «در حال بررسی»
  // =====================================================

  Future<void> setWaiting(
      int ticketId,
      ) async {
    final response = await apiService.post(
      ApiConfig.managerSupportTicketWaiting(
        ticketId,
      ),
      body: {},
    );

    _debugResponse(
      'POST MANAGER SUPPORT TICKET WAITING',
      response.statusCode,
      response.body,
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      if (data['success'] == false) {
        throw Exception(
          _extractError(
            data,
            'قرار دادن تیکت در حالت بررسی با خطا مواجه شد.',
          ),
        );
      }

      return;
    }

    if (response.statusCode == 400) {
      throw Exception(
        _extractError(
          data,
          'امکان تغییر وضعیت تیکت وجود ندارد.',
        ),
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'شما اجازه تغییر وضعیت این تیکت را ندارید.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'تیکت مورد نظر پیدا نشد.',
      );
    }

    throw Exception(
      _extractError(
        data,
        'خطا در تغییر وضعیت تیکت: ${response.statusCode}',
      ),
    );
  }

  // =====================================================
  // بستن تیکت
  // =====================================================

  Future<void> closeTicket(
      int ticketId,
      ) async {
    final response = await apiService.post(
      ApiConfig.managerSupportTicketClose(
        ticketId,
      ),
      body: {},
    );

    _debugResponse(
      'POST CLOSE MANAGER SUPPORT TICKET',
      response.statusCode,
      response.body,
    );

    final data = _decodeResponse(response);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      if (data['success'] == false) {
        throw Exception(
          _extractError(
            data,
            'بستن تیکت با خطا مواجه شد.',
          ),
        );
      }

      return;
    }

    if (response.statusCode == 400) {
      throw Exception(
        _extractError(
          data,
          'امکان بستن تیکت وجود ندارد.',
        ),
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'شما اجازه بستن این تیکت را ندارید.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'تیکت مورد نظر پیدا نشد.',
      );
    }

    throw Exception(
      _extractError(
        data,
        'خطا در بستن تیکت: ${response.statusCode}',
      ),
    );
  }

  // =====================================================
  // Decode
  // =====================================================

  Map<String, dynamic> _decodeResponse(
      dynamic response,
      ) {
    final body =
        response.body?.toString() ?? '';

    if (body.trim().isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }

      return {};
    } catch (e) {
      throw Exception(
        'پاسخ دریافتی از سرور نامعتبر است.',
      );
    }
  }

  // =====================================================
  // Error
  // =====================================================

  String _extractError(
      Map<String, dynamic> data,
      String defaultMessage,
      ) {
    final message = data['message'];

    if (message != null &&
        message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    final detail = data['detail'];

    if (detail != null &&
        detail.toString().trim().isNotEmpty) {
      return detail.toString();
    }

    final error = data['error'];

    if (error != null &&
        error.toString().trim().isNotEmpty) {
      return error.toString();
    }

    final errors = data['errors'];

    if (errors != null) {
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
          return messages.join('\n');
        }
      }

      if (errors
          .toString()
          .trim()
          .isNotEmpty) {
        return errors.toString();
      }
    }

    return defaultMessage;
  }

  // =====================================================
  // Debug
  // =====================================================

  void _debugResponse(
      String title,
      int statusCode,
      String body,
      ) {
    print(
      '==========================================',
    );
    print(title);
    print('STATUS: $statusCode');
    print('BODY: $body');
    print(
      '==========================================',
    );
  }
}