
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class UserSupportService {
final ApiService apiService;

UserSupportService({
required this.apiService,
});

// =====================================================
// دریافت لیست تیکت‌های ساکن
// GET
// =====================================================


  Future<List<Map<String, dynamic>>> getTickets() async {
    final response = await apiService.get(
      ApiConfig.userSupportTickets,
    );

    print('USER SUPPORT DETAIL STATUS: ${response.statusCode}');
    print('USER SUPPORT DETAIL BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        _extractError(response),
      );
    }

    final data = jsonDecode(response.body);

    // ---------------------------------------------
    // پاسخ اصلی API:
    // {
    //   "success": true,
    //   "tickets": [...]
    // }
    // ---------------------------------------------
    if (data is Map &&
        data['tickets'] is List) {
      return (data['tickets'] as List)
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList();
    }

    // ---------------------------------------------
    // پشتیبانی از پاسخ مستقیم List
    // ---------------------------------------------
    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList();
    }

    // ---------------------------------------------
    // پشتیبانی از DRF pagination
    // ---------------------------------------------
    if (data is Map &&
        data['results'] is List) {
      return (data['results'] as List)
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList();
    }

    return [];
  }



// =====================================================
// ایجاد تیکت جدید
// POST Multipart
// =====================================================

Future<Map<String, dynamic>> createTicket({
required String subject,
required String message,
bool isCall = false,
String? filePath,
}) async {
final fields = <String, String>{
'subject': subject.trim(),
'message': message,
'is_call': isCall.toString(),
};

final response =
await apiService.postMultipart(
url: ApiConfig.userSupportTickets,
fields: fields,
filePath: filePath,
fileField: 'file',
);

if (response.statusCode != 200 &&
response.statusCode != 201) {
throw Exception(
_extractError(response),
);
}

final data = jsonDecode(response.body);

if (data is Map<String, dynamic>) {
return data;
}

if (data is Map) {
return Map<String, dynamic>.from(data);
}

throw Exception(
'پاسخ ایجاد تیکت نامعتبر است.',
);
}



// =====================================================
// دریافت جزئیات تیکت
// GET
// =====================================================


  Future<Map<String, dynamic>> getTicket(
      int ticketId,
      ) async {
    final response = await apiService.get(
      '${ApiConfig.userSupportTickets}'
          '$ticketId/',
    );

    print(
      'USER SUPPORT DETAIL STATUS: ${response.statusCode}',
    );

    print(
      'USER SUPPORT DETAIL BODY: ${response.body}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractError(response),
      );
    }

    final data = jsonDecode(response.body);

    // =====================================================
    // پاسخ صحیح Backend:
    //
    // {
    //   "success": true,
    //   "ticket": {
    //      ...
    //   }
    // }
    // =====================================================

    if (data is Map &&
        data['ticket'] is Map) {
      return Map<String, dynamic>.from(
        data['ticket'] as Map,
      );
    }

    // =====================================================
    // حالت fallback
    // =====================================================

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      'اطلاعات تیکت نامعتبر است.',
    );
  }




  Future<int> getUnreadCount() async {
    final url = ApiConfig.userSupportUnreadCount;

    debugPrint(
      'SUPPORT NOTIFICATION COUNT URL: $url',
    );

    final response = await apiService.get(url);

    debugPrint(
      'SUPPORT NOTIFICATION COUNT STATUS: '
          '${response.statusCode}',
    );

    debugPrint(
      'SUPPORT NOTIFICATION COUNT BODY: '
          '${response.body}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        _extractError(response),
      );
    }

    try {
      final data = jsonDecode(response.body);

      if (data is Map) {
        final value =
            data['unread_count'] ??
                data['count'];

        if (value is num) {
          return value.toInt();
        }

        return int.tryParse(
          value?.toString() ?? '',
        ) ??
            0;
      }
    } catch (e) {
      debugPrint(
        'SUPPORT NOTIFICATION COUNT PARSE ERROR: $e',
      );
    }

    return 0;
  }
// =====================================================
// ارسال پیام جدید
// POST Multipart
// =====================================================

Future<Map<String, dynamic>> sendMessage({
required int ticketId,
String? message,
String? filePath,
}) async {
final fields = <String, String>{};

if (message != null &&
message.trim().isNotEmpty) {
fields['message'] = message.trim();
}

final response =
await apiService.postMultipart(
url:
'${ApiConfig.userSupportTickets}'
'$ticketId/messages/',
fields: fields,
filePath: filePath,
fileField: 'file',
);

if (response.statusCode != 200 &&
response.statusCode != 201) {
throw Exception(
_extractError(response),
);
}

final data = jsonDecode(response.body);

if (data is Map<String, dynamic>) {
return data;
}

if (data is Map) {
return Map<String, dynamic>.from(data);
}

throw Exception(
'پاسخ ارسال پیام نامعتبر است.',
);
}

// =====================================================
// بستن تیکت
// POST
// =====================================================

Future<bool> closeTicket(
int ticketId,
) async {
final response = await apiService.post(
'${ApiConfig.userSupportTickets}'
'$ticketId/close/',
);

if (response.statusCode != 200) {
throw Exception(
_extractError(response),
);
}

return true;
}

// =====================================================
// خوانده شدن پیام‌های مدیر
// POST
// =====================================================

Future<bool> markAsRead(
int ticketId,
) async {
final response = await apiService.post(
'${ApiConfig.userSupportTickets}'
'$ticketId/read/',
);

if (response.statusCode != 200) {
throw Exception(
_extractError(response),
);
}

return true;
}

// =====================================================
// استخراج خطای API
// =====================================================

String _extractError(
dynamic response,
) {
try {
final data = jsonDecode(
response.body,
);

if (data is Map) {
if (data['detail'] != null) {
return data['detail'].toString();
}

if (data['message'] != null) {
return data['message'].toString();
}

if (data['error'] != null) {
return data['error'].toString();
}

final errors = <String>[];

data.forEach(
(key, value) {
if (value is List) {
errors.add(
value
    .map(
(item) => item.toString(),
)
    .join(' '),
);
} else {
errors.add(
value.toString(),
);
}
},
);

if (errors.isNotEmpty) {
return errors.join('\n');
}
}

if (response.body
    .toString()
    .trim()
    .isNotEmpty) {
return response.body.toString();
}
} catch (_) {}

return 'خطایی در ارتباط با سرور رخ داد.';
}
}

