
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerPersonAreaChargeService {
final ApiService _api = ApiService();

// ==================================================
// آدرس پایه API شارژ نفری متراژی
// ==================================================
String get _baseUrl => ApiConfig.managerPersonAreaCharges;

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

// ==================================================
// تبدیل بدنه پاسخ
// ==================================================
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
// دریافت فهرست شارژهای نفری متراژی
// GET /manager/person-area-charges/
// ==================================================
Future<List<Map<String, dynamic>>> getCharges() async {
final response = await _api.get(_baseUrl);

debugPrint(
'PERSON AREA CHARGE STATUS: ${response.statusCode}',
);
debugPrint(
'PERSON AREA CHARGE BODY: ${response.body}',
);

if (!_isSuccess(response)) {
_throwResponseError(
response,
fallback: 'دریافت فهرست شارژهای نفری متراژی ناموفق بود',
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
'PERSON AREA CHARGE: '
'id=${item['id']} | '
'name=${item['name']} | '
'area_amount=${item['area_amount']} | '
'person_amount=${item['person_amount']} | '
'payment_deadline=${item['payment_deadline']}',
);
}

return result;
}

// ==================================================
// دریافت جزئیات شارژ
// GET /manager/person-area-charges/{id}/
// ==================================================
Future<Map<String, dynamic>> getCharge(int id) async {
final response = await _api.get('$_baseUrl$id/');

if (!_isSuccess(response)) {
_throwResponseError(
response,
fallback: 'دریافت اطلاعات شارژ نفری متراژی ناموفق بود',
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
// ایجاد شارژ نفری متراژی
// POST /manager/person-area-charges/
// ==================================================
Future<Map<String, dynamic>> createCharge({
required String name,
required dynamic areaAmount,
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
'area_amount': areaAmount,
'person_amount': personAmount,
'payment_deadline': paymentDeadline,
'other_cost_amount': otherCostAmount,
'payment_penalty_amount': paymentPenaltyAmount,
'details': details,
},
);

if (!_isSuccess(response)) {
debugPrint(
'PERSON AREA CREATE ERROR: ${response.statusCode}',
);
debugPrint(
'PERSON AREA CREATE BODY: ${response.body}',
);

_throwResponseError(
response,
fallback: 'ایجاد شارژ نفری متراژی ناموفق بود',
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
// ویرایش شارژ نفری متراژی
// PATCH /manager/person-area-charges/{id}/
// ==================================================
Future<Map<String, dynamic>> updateCharge(
int id, {
required String name,
required dynamic areaAmount,
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
'area_amount': areaAmount,
'person_amount': personAmount,
'payment_deadline': paymentDeadline,
'other_cost_amount': otherCostAmount,
'payment_penalty_amount': paymentPenaltyAmount,
'details': details,
},
);

if (!_isSuccess(response)) {
debugPrint(
'PERSON AREA UPDATE ERROR: ${response.statusCode}',
);
debugPrint(
'PERSON AREA UPDATE BODY: ${response.body}',
);

_throwResponseError(
response,
fallback: 'ویرایش شارژ نفری متراژی ناموفق بود',
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
// حذف شارژ نفری متراژی
// DELETE /manager/person-area-charges/{id}/
// ==================================================
Future<void> deleteCharge(int id) async {
final response = await _api.delete(
'$_baseUrl$id/',
);

if (!_isSuccess(response)) {
_throwResponseError(
response,
fallback: 'حذف شارژ نفری متراژی ناموفق بود',
);
}
}

// ==================================================
// دریافت واحدهای یک شارژ
// GET /manager/person-area-charges/{id}/units/
// ==================================================
Future<List<Map<String, dynamic>>> getChargeUnits(
int chargeId, {
String? search,
String? residentType,
}) async {
var url = '$_baseUrl$chargeId/units/';
final queryParameters = <String, String>{};

if (search != null && search.trim().isNotEmpty) {
queryParameters['search'] = search.trim();
}

if (residentType != null &&
residentType.isNotEmpty &&
residentType != 'all') {
queryParameters['resident_type'] = residentType;
}

if (queryParameters.isNotEmpty) {
final query = Uri(
queryParameters: queryParameters,
).query;

url = '$url?$query';
}

final response = await _api.get(url);

if (!_isSuccess(response)) {
_throwResponseError(
response,
fallback: 'دریافت وضعیت واحدهای شارژ نفری متراژی ناموفق بود',
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
'PERSON AREA CHARGE UNITS COUNT: ${result.length}',
);

return result;
}

// ==================================================
// ارسال شارژ به واحدهای انتخاب‌شده
// POST /manager/person-area-charges/{id}/units/send/
//
// sendSms=false: فقط اعلان سیستمی
// sendSms=true : اعلان سیستمی و پیامک
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
'$_baseUrl$chargeId/send/',
body: <String, dynamic>{
'unit_ids': unitIds,
'send_sms': sendSms,
},
);

if (!_isSuccess(response)) {
debugPrint(
'PERSON AREA SEND ERROR: ${response.statusCode}',
);
debugPrint(
'PERSON AREA SEND BODY: ${response.body}',
);

_throwResponseError(
response,
fallback: 'ارسال شارژ نفری متراژی به واحدها ناموفق بود',
);
}

final data = _decodeMap(response);

debugPrint(
'PERSON AREA CHARGE SEND RESPONSE: $data',
);

return data;
}

// ==================================================
// لغو اعلان واحدهای انتخاب‌شده
// POST /manager/person-area-charges/{id}/units/cancel/
// ==================================================
Future<Map<String, dynamic>> cancelChargeForUnits(
int chargeId,
List<int> unitIds,
) async {
if (unitIds.isEmpty) {
throw Exception('حداقل یک واحد را انتخاب کنید.');
}

final response = await _api.post(
'$_baseUrl$chargeId/cancel/',
body: <String, dynamic>{
'unit_ids': unitIds,
},
);

if (!_isSuccess(response)) {
debugPrint(
'PERSON AREA CANCEL ERROR: ${response.statusCode}',
);
debugPrint(
'PERSON AREA CANCEL BODY: ${response.body}',
);

_throwResponseError(
response,
fallback: 'لغو اعلان شارژ نفری متراژی ناموفق بود',
);
}

final data = _decodeMap(response);

debugPrint(
'PERSON AREA CHARGE CANCEL RESPONSE: $data',
);

return data;
}
}
