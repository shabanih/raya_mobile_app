
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerPersonChargeService {
final ApiService _api = ApiService();

// ==================================================
// آدرس پایه API شارژ نفری
// ==================================================
String get _baseUrl => ApiConfig.managerPersonCharges;

// ==================================================
// تبدیل پاسخ JSON به Map
// ==================================================
Map<String, dynamic> _decodeMap(dynamic response) {
final dynamic data = _decodeBody(response);

if (data is Map<String, dynamic>) {
return data;
}

if (data is Map) {
return Map<String, dynamic>.from(data);
}

return <String, dynamic>{};
}

dynamic _decodeBody(dynamic response) {
if (response == null) return null;

try {
final dynamic body = response.body;

if (body is String) {
if (body.trim().isEmpty) {
return <String, dynamic>{};
}

return jsonDecode(body);
}

if (body != null) return body;
} catch (_) {
// پاسخ ممکن است از قبل Map یا List باشد.
}

if (response is String) {
if (response.trim().isEmpty) {
return <String, dynamic>{};
}

return jsonDecode(response);
}

return response;
}

// ==================================================
// بررسی موفق بودن پاسخ
// ==================================================
bool _isSuccess(dynamic response) {
try {
final int code = response.statusCode as int;
return code >= 200 && code < 300;
} catch (_) {
return false;
}
}

// ==================================================
// استخراج پیام خطا
// ==================================================
String _errorMessage(
dynamic response, {
String fallback = 'خطا در انجام عملیات',
}) {
try {
final data = _decodeMap(response);

final detail = data['detail'] ??
data['message'] ??
data['error'];

if (detail != null &&
detail.toString().trim().isNotEmpty) {
return detail.toString();
}

final errors = data['errors'];

if (errors is Map) {
final messages = <String>[];

errors.forEach((key, value) {
if (value is List) {
messages.addAll(
value.map((item) => item.toString()),
);
} else {
messages.add(value.toString());
}
});

if (messages.isNotEmpty) {
return messages.join('\n');
}
}
} catch (_) {
// استفاده از پیام پیش‌فرض
}

return fallback;
}

Never _throwResponseError(
dynamic response, {
String fallback = 'خطا در انجام عملیات',
}) {
throw Exception(
_errorMessage(
response,
fallback: fallback,
),
);
}

// ==================================================
// تبدیل پاسخ به List
// ==================================================
List<Map<String, dynamic>> _decodeList(
dynamic response, {
List<String> keys = const [
'results',
'data',
'items',
],
}) {
final dynamic data = _decodeBody(response);
dynamic items;

if (data is List) {
items = data;
} else if (data is Map) {
for (final key in keys) {
if (data[key] is List) {
items = data[key];
break;
}
}
}

if (items is! List) {
return <Map<String, dynamic>>[];
}

return items
    .whereType<Map>()
    .map(
(item) => Map<String, dynamic>.from(item),
)
    .toList();
}

// ==================================================
// دریافت فهرست شارژهای نفری
// GET /manager/charges/person/
// ==================================================
Future<List<Map<String, dynamic>>> getCharges() async {
final response = await _api.get(_baseUrl);

debugPrint('PERSON API STATUS: ${response.statusCode}');
debugPrint('PERSON API BODY: ${response.body}');

if (!_isSuccess(response)) {
_throwResponseError(
response,
fallback: 'دریافت فهرست شارژهای نفری ناموفق بود',
);
}

final result = _decodeList(
response,
keys: const [
'results',
'charges',
'data',
'items',
],
);

for (final item in result) {
debugPrint(
'PERSON ITEM: id=${item['id']} | '
'name=${item['name']} | '
'person_amount=${item['person_amount']} | '
'total_people=${item['total_people']} | '
'payment_deadline=${item['payment_deadline']}',
);
}

return result;
}

// ==================================================
// دریافت جزئیات یک شارژ نفری
// GET /manager/charges/person/{id}/
// ==================================================
Future<Map<String, dynamic>> getCharge(int id) async {
final response = await _api.get('$_baseUrl$id/');

if (!_isSuccess(response)) {
_throwResponseError(
response,
fallback: 'دریافت اطلاعات شارژ نفری ناموفق بود',
);
}

final data = _decodeMap(response);

if (data['charge'] is Map) {
return Map<String, dynamic>.from(
data['charge'] as Map,
);
}

return data;
}

// ==================================================
// ایجاد شارژ نفری
// POST /manager/charges/person/
// ==================================================
Future<Map<String, dynamic>> createCharge({
required String name,
required dynamic personAmount,
required String paymentDeadline,
dynamic otherCostAmount = 0,
dynamic paymentPenaltyAmount = 0,
String details = '',
}) async {
final response = await _api.post(
_baseUrl,
body: <String, dynamic>{
'name': name,
'person_amount': personAmount,
'payment_deadline': paymentDeadline,
'other_cost_amount': otherCostAmount,
'payment_penalty_amount': paymentPenaltyAmount,
'details': details,
},
);

if (!_isSuccess(response)) {
_throwResponseError(
response,
fallback: 'ایجاد شارژ نفری ناموفق بود',
);
}

final data = _decodeMap(response);

if (data['charge'] is Map) {
return Map<String, dynamic>.from(
data['charge'] as Map,
);
}

return data;
}

// ==================================================
// ویرایش شارژ نفری
// PATCH /manager/charges/person/{id}/
// ==================================================
Future<Map<String, dynamic>> updateCharge(
int id, {
required String name,
required dynamic personAmount,
required String paymentDeadline,
dynamic otherCostAmount = 0,
dynamic paymentPenaltyAmount = 0,
String details = '',
}) async {
final response = await _api.patch(
'$_baseUrl$id/',
body: <String, dynamic>{
'name': name,
'person_amount': personAmount,
'payment_deadline': paymentDeadline,
'other_cost_amount': otherCostAmount,
'payment_penalty_amount': paymentPenaltyAmount,
'details': details,
},
);

if (!_isSuccess(response)) {
_throwResponseError(
response,
fallback: 'ویرایش شارژ نفری ناموفق بود',
);
}

final data = _decodeMap(response);

if (data['charge'] is Map) {
return Map<String, dynamic>.from(
data['charge'] as Map,
);
}

return data;
}

// ==================================================
// حذف شارژ نفری
// DELETE /manager/charges/person/{id}/
// ==================================================
Future<void> deleteCharge(int id) async {
final response = await _api.delete(
'$_baseUrl$id/',
);

if (!_isSuccess(response)) {
_throwResponseError(
response,
fallback: 'حذف شارژ نفری ناموفق بود',
);
}
}

// ==================================================
// دریافت واحدهای یک شارژ نفری
// GET /manager/charges/person/{id}/units/
// ==================================================
Future<List<Map<String, dynamic>>> getChargeUnits(
int chargeId,
) async {
final response = await _api.get(
'$_baseUrl$chargeId/units/',
);

if (!_isSuccess(response)) {
_throwResponseError(
response,
fallback: 'دریافت وضعیت واحدهای شارژ نفری ناموفق بود',
);
}

final result = _decodeList(
response,
keys: const [
'results',
'units',
'data',
'items',
],
);

debugPrint(
'PERSON CHARGE UNITS COUNT: ${result.length}',
);

return result;
}

// ==================================================
// ارسال شارژ نفری به واحدهای انتخاب‌شده
// POST /manager/charges/person/{id}/units/send/
//
// sendSms=false : فقط اعلان سیستمی
// sendSms=true  : اعلان سیستمی و پیامک
// ==================================================
Future<Map<String, dynamic>> sendChargeToUnits(
int chargeId,
List<int> unitIds, {
bool sendSms = false,
}) async {
if (unitIds.isEmpty) {
throw Exception('حداقل یک واحد را انتخاب کنید.');
}

final response = await _api.post(
'$_baseUrl$chargeId/units/send/',
body: <String, dynamic>{
'unit_ids': unitIds,
'send_sms': sendSms,
},
);

if (!_isSuccess(response)) {
_throwResponseError(
response,
fallback: 'ارسال شارژ نفری به واحدها ناموفق بود',
);
}

final data = _decodeMap(response);

debugPrint('PERSON CHARGE SEND RESPONSE: $data');

return data;
}

// ==================================================
// لغو اعلان شارژ نفری برای واحدهای انتخاب‌شده
// POST /manager/charges/person/{id}/units/cancel/
// ==================================================
Future<Map<String, dynamic>> cancelChargeForUnits(
int chargeId,
List<int> unitIds,
) async {
if (unitIds.isEmpty) {
throw Exception('حداقل یک واحد را انتخاب کنید.');
}

final response = await _api.post(
'$_baseUrl$chargeId/units/cancel/',
body: <String, dynamic>{
'unit_ids': unitIds,
},
);

if (!_isSuccess(response)) {
_throwResponseError(
response,
fallback: 'لغو اعلان شارژ نفری ناموفق بود',
);
}

final data = _decodeMap(response);

debugPrint('PERSON CHARGE CANCEL RESPONSE: $data');

return data;
}
}
