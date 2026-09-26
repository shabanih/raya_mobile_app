
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class ManagerAnnouncementService {
// =====================================================
// دریافت توکن
// =====================================================

static Future<String> _getToken() async {
final token = await TokenStorage.getAccessToken();

if (token == null || token.trim().isEmpty) {
throw Exception('توکن ورود پیدا نشد.');
}

return token.trim();
}

// =====================================================
// دریافت لیست اطلاعیه‌های مدیر
// =====================================================

static Future<List<Map<String, dynamic>>> getAnnouncements() async {
final token = await _getToken();

final response = await http.get(
Uri.parse(ApiConfig.managerAnnouncements),
headers: {
'Authorization': 'Bearer $token',
'Accept': 'application/json',
},
);

final data = _decodeResponse(response);

if (response.statusCode == 200) {
final List<dynamic> items =
data['announcements'] ?? [];

return items
    .map(
(item) => Map<String, dynamic>.from(item),
)
    .toList();
}

throw Exception(
data['message']?.toString() ??
'خطا در دریافت اطلاعیه‌ها.',
);
}

// =====================================================
// ایجاد اطلاعیه
// =====================================================

static Future<Map<String, dynamic>> createAnnouncement({
required String title,
required bool showInMarquee,
List<File> files = const [],
}) async {
final token = await _getToken();

final request = http.MultipartRequest(
'POST',
Uri.parse(ApiConfig.managerAnnouncements),
);

request.headers.addAll({
'Authorization': 'Bearer $token',
'Accept': 'application/json',
});

request.fields['title'] = title;
request.fields['show_in_marquee'] =
showInMarquee ? 'true' : 'false';

for (final file in files) {
request.files.add(
await http.MultipartFile.fromPath(
'documents',
file.path,
),
);
}

final streamedResponse = await request.send();

final response = await http.Response.fromStream(
streamedResponse,
);

final data = _decodeResponse(response);

if (response.statusCode == 201) {
return data;
}

throw Exception(
data['message']?.toString() ??
'ثبت اطلاعیه انجام نشد.',
);
}

// =====================================================
// ویرایش اطلاعیه
// =====================================================

static Future<Map<String, dynamic>> updateAnnouncement({
required int id,
required String title,
required bool showInMarquee,
bool? isActive,
List<File> files = const [],
}) async {
final token = await _getToken();

final request = http.MultipartRequest(
'PUT',
Uri.parse(
'${ApiConfig.managerAnnouncements}$id/',
),
);

request.headers.addAll({
'Authorization': 'Bearer $token',
'Accept': 'application/json',
});

request.fields['title'] = title;
request.fields['show_in_marquee'] =
showInMarquee ? 'true' : 'false';

if (isActive != null) {
request.fields['is_active'] =
isActive ? 'true' : 'false';
}

for (final file in files) {
request.files.add(
await http.MultipartFile.fromPath(
'documents',
file.path,
),
);
}

final streamedResponse = await request.send();

final response = await http.Response.fromStream(
streamedResponse,
);

final data = _decodeResponse(response);

if (response.statusCode == 200) {
return data;
}

throw Exception(
data['message']?.toString() ??
'ویرایش اطلاعیه انجام نشد.',
);
}

// =====================================================
// حذف اطلاعیه
// =====================================================

static Future<void> deleteAnnouncement(
int id,
) async {
final token = await _getToken();

final response = await http.delete(
Uri.parse(
'${ApiConfig.managerAnnouncements}$id/',
),
headers: {
'Authorization': 'Bearer $token',
'Accept': 'application/json',
},
);

final data = _decodeResponse(response);

if (response.statusCode == 200) {
return;
}

throw Exception(
data['message']?.toString() ??
'حذف اطلاعیه انجام نشد.',
);
}

// =====================================================
// فعال / غیرفعال کردن اطلاعیه
// =====================================================

static Future<Map<String, dynamic>> changeStatus({
required int id,
required bool isActive,
required String title,
required bool showInMarquee,
}) async {
return updateAnnouncement(
id: id,
title: title,
showInMarquee: showInMarquee,
isActive: isActive,
);
}

// =====================================================
// تبدیل پاسخ API
// =====================================================

  static Map<String, dynamic> _decodeResponse(
      http.Response response,
      ) {
    final body = utf8.decode(response.bodyBytes);

    print('======================================');
    print('MANAGER ANNOUNCEMENT API');
    print('STATUS: ${response.statusCode}');
    print(
      'CONTENT-TYPE: ${response.headers['content-type']}',
    );
    print('BODY: $body');
    print('======================================');

    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'success': false,
        'message': 'پاسخ سرور نامعتبر است.',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
        'پاسخ سرور قابل پردازش نیست. HTTP ${response.statusCode}',
        'debug_body': body,
      };
    }
  }

}


