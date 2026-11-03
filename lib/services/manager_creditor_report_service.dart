
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class ManagerCreditorReportService {
final ApiService apiService;

ManagerCreditorReportService({
required this.apiService,
});

// =====================================================
// دریافت فهرست واحدهای بستانکار
// =====================================================

Future<Map<String, dynamic>> getCreditorUnits({
String query = '',
String residentType = 'all',
int limit = 100,
}) async {
if (!['all', 'owner', 'renter'].contains(residentType)) {
residentType = 'all';
}

if (limit < 1) {
limit = 100;
}

final params = <String, String>{
'limit': limit.toString(),
'resident_type': residentType,
};

if (query.trim().isNotEmpty) {
params['q'] = query.trim();
}

final queryString = Uri(queryParameters: params).query;

final response = await apiService.get(
'${ApiConfig.managerCreditorUnits}?$queryString',
);

final data = _decodeResponse(response);

if (response.statusCode >= 200 &&
response.statusCode < 300) {
if (data is Map) {
final result = Map<String, dynamic>.from(data);
final items = result['results'];

return {
'success': result['success'] ?? true,
'total_creditors': result['total_creditors'] ?? 0,
'total_creditor_amount':
result['total_creditor_amount'] ?? 0,
'results': items is List
? items
    .whereType<Map>()
    .map(
(item) => Map<String, dynamic>.from(item),
)
    .toList()
    : <Map<String, dynamic>>[],
};
}

throw Exception(
'اطلاعات گزارش واحدهای بستانکار نامعتبر است.',
);
}

throw Exception(_extractErrorMessage(data));
}

// =====================================================
// Decode پاسخ سرور
// =====================================================

dynamic _decodeResponse(dynamic response) {
final bodyBytes = response.bodyBytes;

if (bodyBytes.isEmpty) {
return null;
}

final body = utf8
    .decode(
bodyBytes,
allowMalformed: true,
)
    .trim();

if (body.isEmpty) {
return null;
}

try {
return jsonDecode(body);
} catch (_) {
return body;
}
}

// =====================================================
// استخراج متن خطا
// =====================================================

String _extractErrorMessage(dynamic data) {
if (data == null) {
return 'خطایی در ارتباط با سرور رخ داده است.';
}

if (data is String && data.trim().isNotEmpty) {
return data.trim();
}

if (data is Map) {
final message =
data['message'] ??
data['detail'] ??
data['error'];

if (message != null) {
if (message is List) {
return message
    .map((item) => item.toString())
    .join('\n');
}

return message.toString();
}

final errors = <String>[];

data.forEach((key, value) {
errors.add(
'${_fieldTitle(key.toString())}: $value',
);
});

if (errors.isNotEmpty) {
return errors.join('\n');
}
}

return 'خطایی در دریافت گزارش بستانکاران رخ داده است.';
}

// =====================================================
// عنوان فارسی فیلدها
// =====================================================

String _fieldTitle(String key) {
const Map<String, String> titles = {
'unit_id': 'شناسه واحد',
'unit_number': 'شماره واحد',
'resident_id': 'شناسه ساکن',
'resident_name': 'نام ساکن',
'resident_type': 'نوع شخص',
'resident_label': 'نوع شخص',
'balance': 'مانده حساب',
'creditor_amount': 'مبلغ بستانکاری',
'total_creditors': 'تعداد بستانکاران',
'total_creditor_amount': 'مجموع بستانکاری',
'success': 'وضعیت درخواست',
'message': 'پیام',
'detail': 'جزئیات',
};

return titles[key] ?? key;
}
  }
