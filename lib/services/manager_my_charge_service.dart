
import 'dart:convert';

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerMyChargeService {
ManagerMyChargeService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

final ApiService _apiService;

// --------------------------------------------------
// دریافت فهرست شارژهای ماهیانه اصلی
// --------------------------------------------------

Future<List<Map<String, dynamic>>> getMonthlyCharges({
int page = 1,
int pageSize = 20,
}) async {
final uri = Uri.parse(ApiConfig.managerMonthlyCharges).replace(
queryParameters: {
'page': page.toString(),
'page_size': pageSize.toString(),
},
);

final response = await _apiService.get(uri.toString());

return _parseResults(
response.bodyBytes,
response.statusCode,
'دریافت فهرست شارژهای ماهیانه',
);
}

// --------------------------------------------------
// دریافت واحدهای مربوط به یک شارژ اصلی
//
// chargeId در این متد:
// شناسه شارژ اصلی است، نه UnifiedCharge
// --------------------------------------------------

Future<List<Map<String, dynamic>>> getMonthlyChargeUnits({
required int chargeId,
required String appLabel,
required String modelName,
}) async {
final url = ApiConfig.managerMonthlyChargeUnits(
appLabel: appLabel,
modelName: modelName,
chargeId: chargeId,
);

final response = await _apiService.get(url);

return _parseResults(
response.bodyBytes,
response.statusCode,
'دریافت واحدهای شارژ',
);
}

// --------------------------------------------------
// دریافت حساب‌های بانکی برای پرداخت یک واحد
//
// chargeId در این متد:
// شناسه UnifiedCharge همان واحد است
// --------------------------------------------------

Future<List<Map<String, dynamic>>> getMonthlyChargePaymentBanks({
required int chargeId,
}) async {
final url =
'${ApiConfig.baseUrl}/manager/monthly-charges/units/$chargeId/pay/';

final response = await _apiService.get(url);

final body = _decodeResponse(
response.bodyBytes,
'دریافت حساب‌های بانکی',
);

_checkStatus(
body,
response.statusCode,
'دریافت حساب‌های بانکی',
);

if (body is! Map || body['success'] != true) {
throw Exception(
body is Map
? body['message']?.toString() ??
'دریافت حساب‌های بانکی ناموفق بود.'
    : 'پاسخ سرور معتبر نیست.',
);
}

final banks = body['banks'];

if (banks is! List) {
return [];
}

return banks
    .whereType<Map>()
    .map((item) => Map<String, dynamic>.from(item))
    .toList();
}

// --------------------------------------------------
// ثبت پرداخت یک واحد
//
// chargeId = شناسه UnifiedCharge
// --------------------------------------------------

Future<Map<String, dynamic>> payMonthlyCharge({
required int chargeId,
required int bankId,
required String paymentDate,
String? transactionReference,
}) async {
final url =
'${ApiConfig.baseUrl}/manager/monthly-charges/units/$chargeId/pay/';

final reference = transactionReference?.trim();

final response = await _apiService.post(
url,
body: {
'bank_id': bankId,
'payment_date': paymentDate,
if (reference != null && reference.isNotEmpty)
'transaction_reference': reference,
},
);

return _parseActionResponse(
response.bodyBytes,
response.statusCode,
'ثبت پرداخت شارژ',
);
}

// --------------------------------------------------
// لغو پرداخت یک واحد
//
// chargeId = شناسه UnifiedCharge
//
// توجه:
// مسیر زیر باید با URL واقعی ویوی لغو پرداخت
// در Django مطابقت داشته باشد.
// --------------------------------------------------

Future<Map<String, dynamic>> cancelMonthlyChargePayment({
required int chargeId,
}) async {
final url =
'${ApiConfig.baseUrl}/manager/monthly-charges/$chargeId/cancel-payment/';

final response = await _apiService.post(url);

return _parseActionResponse(
response.bodyBytes,
response.statusCode,
'لغو پرداخت شارژ',
);
}

// --------------------------------------------------
// تبدیل پاسخ HTTP به JSON
// --------------------------------------------------

dynamic _decodeResponse(
List<int> bodyBytes,
String operation,
) {
final body = utf8.decode(bodyBytes);

try {
return jsonDecode(body);
} catch (_) {
throw Exception(
'$operation ناموفق بود؛ پاسخ سرور معتبر نیست.',
);
}
}

// --------------------------------------------------
// بررسی کد وضعیت HTTP
// --------------------------------------------------

void _checkStatus(
dynamic decoded,
int statusCode,
String operation,
) {
if (statusCode >= 200 && statusCode < 300) {
return;
}

var message = 'خطای سرور ($statusCode)';

if (decoded is Map) {
message = decoded['message']?.toString() ??
decoded['detail']?.toString() ??
message;
}

throw Exception('$operation: $message');
}

// --------------------------------------------------
// پردازش پاسخ عملیات
// --------------------------------------------------

Map<String, dynamic> _parseActionResponse(
List<int> bodyBytes,
int statusCode,
String operation,
) {
final decoded = _decodeResponse(bodyBytes, operation);

_checkStatus(decoded, statusCode, operation);

if (decoded is! Map) {
throw Exception(
'$operation: ساختار پاسخ سرور معتبر نیست.',
);
}

if (decoded['success'] != true) {
throw Exception(
decoded['message']?.toString() ??
decoded['detail']?.toString() ??
'$operation ناموفق بود.',
);
}

return Map<String, dynamic>.from(decoded);
}

// --------------------------------------------------
// پردازش فهرست نتایج
// --------------------------------------------------

List<Map<String, dynamic>> _parseResults(
List<int> bodyBytes,
int statusCode,
String operation,
) {
final decoded = _decodeResponse(bodyBytes, operation);

_checkStatus(decoded, statusCode, operation);

if (decoded is! Map) {
throw Exception(
'$operation: ساختار پاسخ سرور معتبر نیست.',
);
}

if (decoded['success'] == false) {
throw Exception(
decoded['message']?.toString() ??
decoded['detail']?.toString() ??
'$operation ناموفق بود.',
);
}

final results = decoded['results'];

if (results is! List) {
throw Exception(
'$operation: فهرست results در پاسخ وجود ندارد.',
);
}

return results
    .whereType<Map>()
    .map((item) => Map<String, dynamic>.from(item))
    .toList();
}
}
