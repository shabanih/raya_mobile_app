
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerChargeCalculationService {
final ApiService _api = ApiService();

String get _baseUrl => ApiConfig.managerChargeCalculations;

// --------------------------------------------------
// تبدیل پاسخ API
// --------------------------------------------------

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
} catch (_) {}

if (response is String) {
if (response.trim().isEmpty) {
return <String, dynamic>{};
}

return jsonDecode(response);
}

return response;
}

Map<String, dynamic> _decodeMap(dynamic response) {
final data = _decodeBody(response);

if (data is Map<String, dynamic>) {
return data;
}

if (data is Map) {
return Map<String, dynamic>.from(data);
}

return <String, dynamic>{};
}

List<Map<String, dynamic>> _decodeList(
dynamic response, {
List<String> keys = const ['results', 'data', 'items'],
}) {
final data = _decodeBody(response);
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
    .map((item) => Map<String, dynamic>.from(item))
    .toList();
}

bool _isSuccess(dynamic response) {
try {
final int code = response.statusCode as int;
return code >= 200 && code < 300;
} catch (_) {
return false;
}
}

String _errorMessage(
dynamic response, {
String fallback = 'خطا در انجام عملیات',
}) {
try {
final data = _decodeMap(response);

final errors = data['errors'];

if (errors is Map && errors.isNotEmpty) {
final messages = <String>[];

errors.forEach((key, value) {
if (value is List) {
messages.addAll(
value.map((item) => item.toString()),
);
} else if (value != null) {
messages.add(value.toString());
}
});

if (messages.isNotEmpty) {
return messages.join('\n');
}
}

final detail =
data['detail'] ?? data['message'] ?? data['error'];

if (detail != null && detail.toString().trim().isNotEmpty) {
return detail.toString();
}

final messages = <String>[];

data.forEach((key, value) {
if (value is List) {
messages.addAll(
value.map((item) => item.toString()),
);
} else if (value is String && key != 'success') {
messages.add(value);
}
});

if (messages.isNotEmpty) {
return messages.join('\n');
}
} catch (e) {
debugPrint('CHARGE CALCULATION ERROR PARSING: $e');
}

return fallback;
}

Never _throwResponseError(
dynamic response, {
String fallback = 'خطا در انجام عملیات',
}) {
throw Exception(
_errorMessage(response, fallback: fallback),
);
}

Map<String, dynamic> _unwrapCalculation(dynamic response) {
final data = _decodeMap(response);

if (data['result'] is Map) {
return Map<String, dynamic>.from(data['result'] as Map);
}

if (data['calculation'] is Map) {
return Map<String, dynamic>.from(
data['calculation'] as Map,
);
}

return data;
}

String _idUrl(int id) => '$_baseUrl$id/';

// --------------------------------------------------
// فهرست محاسبات
// GET manager/charge-calculations/
// --------------------------------------------------

Future<List<Map<String, dynamic>>> getCalculations() async {
final response = await _api.get(_baseUrl);

debugPrint(
'CHARGE CALCULATION STATUS: ${response.statusCode}',
);

if (!_isSuccess(response)) {
_throwResponseError(
response,
fallback: 'دریافت فهرست محاسبات شارژ ناموفق بود',
);
}

return _decodeList(
response,
keys: const [
'results',
'calculations',
'data',
'items',
],
);
}

// --------------------------------------------------
// جزئیات محاسبه
// GET manager/charge-calculations/{id}/
// --------------------------------------------------

Future<Map<String, dynamic>> getCalculation(int id) async {
final response = await _api.get(_idUrl(id));

if (!_isSuccess(response)) {
_throwResponseError(
response,
fallback: 'دریافت اطلاعات محاسبه ناموفق بود',
);
}

return _unwrapCalculation(response);
}

// --------------------------------------------------
// ایجاد محاسبه
// POST manager/charge-calculations/
// --------------------------------------------------

Future<Map<String, dynamic>> createCalculation({
required String name,
required String startDate,
required String endDate,
dynamic otherCostAmount = 0,
String? paymentDeadline,
dynamic paymentPenaltyAmount = 0,
String details = '',
}) async {
final response = await _api.post(
_baseUrl,
body: <String, dynamic>{
'name': name,
'start_date': startDate,
'end_date': endDate,
'other_cost_amount': otherCostAmount,
'payment_deadline': paymentDeadline,
'payment_penalty_amount': paymentPenaltyAmount,
'details': details,
},
);

if (!_isSuccess(response)) {
debugPrint(
'CHARGE CALCULATION CREATE: ${response.body}',
);

_throwResponseError(
response,
fallback: 'ایجاد محاسبه شارژ ناموفق بود',
);
}

return _unwrapCalculation(response);
}

// --------------------------------------------------
// ویرایش محاسبه
// PATCH manager/charge-calculations/{id}/
// --------------------------------------------------

Future<Map<String, dynamic>> updateCalculation(
int id, {
required String name,
required String startDate,
required String endDate,
dynamic otherCostAmount = 0,
String? paymentDeadline,
dynamic paymentPenaltyAmount = 0,
String details = '',
}) async {
final response = await _api.patch(
_idUrl(id),
body: <String, dynamic>{
'name': name,
'start_date': startDate,
'end_date': endDate,
'other_cost_amount': otherCostAmount,
'payment_deadline': paymentDeadline,
'payment_penalty_amount': paymentPenaltyAmount,
'details': details,
},
);

if (!_isSuccess(response)) {
debugPrint(
'CHARGE CALCULATION UPDATE: ${response.body}',
);

_throwResponseError(
response,
fallback: 'ویرایش محاسبه شارژ ناموفق بود',
);
}

return _unwrapCalculation(response);
}

// --------------------------------------------------
// حذف محاسبه
// DELETE manager/charge-calculations/{id}/
// --------------------------------------------------

Future<void> deleteCalculation(int id) async {
final response = await _api.delete(_idUrl(id));

if (!_isSuccess(response)) {
_throwResponseError(
response,
fallback: 'حذف محاسبه شارژ ناموفق بود',
);
}
}

// --------------------------------------------------
// دریافت هزینه‌ها، گروه‌ها و واحدهای فعال
// GET manager/charge-calculations/{id}/items/
// --------------------------------------------------

Future<Map<String, dynamic>> getCalculationItems(
int calculationId,
) async {
final response = await _api.get(
'${_idUrl(calculationId)}items/',
);

debugPrint(
'CHARGE CALCULATION ITEMS STATUS: '
'${response.statusCode}',
);

if (!_isSuccess(response)) {
debugPrint(
'CHARGE CALCULATION ITEMS ERROR: ${response.body}',
);

_throwResponseError(
response,
fallback: 'دریافت هزینه‌های قابل تسهیم ناموفق بود',
);
}

final data = _decodeMap(response);

if (data.isEmpty) {
throw Exception('پاسخ سرور خالی یا نامعتبر است.');
}

return data;
}

// --------------------------------------------------
// ذخیره گروه‌های هزینه و روش تسهیم
// POST manager/charge-calculations/{id}/items/
//
// groups نمونه:
// [
//   {
//     "type": "expense",
//     "group_id": 3,
//     "selected": true,
//     "basis": "area",
//     "scope": "all",
//     "selected_unit_ids": []
//   }
// ]
// --------------------------------------------------

Future<Map<String, dynamic>> saveCalculationItems(
int calculationId, {
required List<Map<String, dynamic>> groups,
}) async {
final response = await _api.post(
'${_idUrl(calculationId)}items/',
body: <String, dynamic>{
'groups': groups,
},
);

if (!_isSuccess(response)) {
debugPrint(
'CHARGE CALCULATION SAVE ITEMS: ${response.body}',
);

_throwResponseError(
response,
fallback: 'ذخیره گروه‌های هزینه ناموفق بود',
);
}

return _decodeMap(response);
}

// --------------------------------------------------
// دریافت سهم واحدها
// GET manager/charge-calculations/{id}/units/
// --------------------------------------------------

Future<Map<String, dynamic>> getCalculationUnitsData(
int calculationId,
) async {
final response = await _api.get(
'${_idUrl(calculationId)}units/',
);

debugPrint(
'CHARGE CALCULATION UNITS STATUS: '
'${response.statusCode}',
);

if (!_isSuccess(response)) {
debugPrint(
'CHARGE CALCULATION UNITS ERROR: ${response.body}',
);

_throwResponseError(
response,
fallback: 'دریافت سهم واحدها ناموفق بود',
);
}

final data = _decodeMap(response);

if (data.isEmpty) {
throw Exception('پاسخ سرور خالی یا نامعتبر است.');
}

return data;
}

// --------------------------------------------------
// فهرست سهم واحدها
// --------------------------------------------------

Future<List<Map<String, dynamic>>> getCalculationUnits(
int calculationId,
) async {
final data = await getCalculationUnitsData(calculationId);

return _decodeList(
data,
keys: const [
'results',
'units',
'data',
'items',
],
);
}

// --------------------------------------------------
// ایجاد شارژ واحدها و ارسال اعلان / پیامک
// POST manager/charge-calculations/{id}/send/
// --------------------------------------------------

Future<Map<String, dynamic>> sendCalculationToUnits(
int calculationId,
List<int> unitIds, {
bool sendSms = false,
}) async {
if (unitIds.isEmpty) {
throw Exception('حداقل یک واحد را انتخاب کنید.');
}

final response = await _api.post(
'${_idUrl(calculationId)}send/',
body: <String, dynamic>{
'unit_ids': unitIds,
'send_sms': sendSms,
},
);

if (!_isSuccess(response)) {
debugPrint(
'CHARGE CALCULATION SEND: ${response.body}',
);

_throwResponseError(
response,
fallback: 'ایجاد و ارسال شارژ تسهیم هزینه ناموفق بود',
);
}

return _decodeMap(response);
}

// --------------------------------------------------
// لغو اعلان شارژهای پرداخت‌نشده
// POST manager/charge-calculations/{id}/cancel/
// --------------------------------------------------

Future<Map<String, dynamic>> cancelCalculationForUnits(
int calculationId,
List<int> unitIds, {
bool cancelAll = false,
}) async {
if (!cancelAll && unitIds.isEmpty) {
throw Exception('واحدهای موردنظر را انتخاب کنید.');
}

final response = await _api.post(
'${_idUrl(calculationId)}cancel/',
body: <String, dynamic>{
'unit_ids': cancelAll ? <String>['all'] : unitIds,
},
);

if (!_isSuccess(response)) {
debugPrint(
'CHARGE CALCULATION CANCEL: ${response.body}',
);

_throwResponseError(
response,
fallback: 'لغو اعلان شارژ ناموفق بود',
);
}

return _decodeMap(response);
}
}
