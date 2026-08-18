
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class PollService {

// =========================================================
// دریافت توکن
// =========================================================

static Future<String?> _getAccessToken() async {
return await TokenStorage.getAccessToken();
}

// =========================================================
// دریافت لیست نظرسنجی‌ها
// =========================================================

static Future<List<Map<String, dynamic>>> getPolls() async {

final accessToken =
await _getAccessToken();

if (accessToken == null ||
accessToken.isEmpty) {
throw Exception(
'توکن ورود پیدا نشد.',
);
}

final url =
ApiConfig.polls;

debugPrint(
'========== POLLS LIST REQUEST =========='
);

debugPrint(
'URL: $url',
);

final response = await http.get(
Uri.parse(url),
headers: {
'Authorization':
'Bearer $accessToken',
'Content-Type':
'application/json',
'Accept':
'application/json',
},
);

final data =
_decodeResponse(response);

debugPrint(
'POLL LIST STATUS: ${response.statusCode}',
);

debugPrint(
'POLL LIST BODY: ${response.body}',
);

if (response.statusCode == 200) {

final polls =
data['polls'];

if (polls is! List) {
return [];
}

return polls
    .map(
(item) =>
Map<String, dynamic>.from(item),
)
    .toList();
}

if (response.statusCode == 401) {
throw Exception(
data['detail'] ??
data['message'] ??
'نشست کاربر منقضی شده است.',
);
}

throw Exception(
data['message'] ??
data['detail'] ??
'خطا در دریافت نظرسنجی‌ها '
'(${response.statusCode})',
);
}

// =========================================================
// دریافت جزئیات یک نظرسنجی
// =========================================================

static Future<Map<String, dynamic>> getPoll(
int pollId,
) async {

final accessToken =
await _getAccessToken();

if (accessToken == null ||
accessToken.isEmpty) {
throw Exception(
'توکن ورود پیدا نشد.',
);
}

final url =
'${ApiConfig.polls}$pollId/';

debugPrint(
'========== POLL DETAIL REQUEST =========='
);

debugPrint(
'URL: $url',
);

debugPrint(
'POLL ID: $pollId',
);

final response = await http.get(
Uri.parse(url),
headers: {
'Authorization':
'Bearer $accessToken',
'Content-Type':
'application/json',
'Accept':
'application/json',
},
);

final responseBody =
utf8.decode(
response.bodyBytes,
);

debugPrint(
'POLL DETAIL STATUS: '
'${response.statusCode}',
);

debugPrint(
'POLL DETAIL BODY: '
'$responseBody',
);

Map<String, dynamic> data;

try {

final decoded =
jsonDecode(responseBody);

if (decoded is Map<String, dynamic>) {
data = decoded;
} else {
throw Exception(
'پاسخ سرور نامعتبر است.',
);
}

} catch (_) {

throw Exception(
'پاسخ سرور قابل پردازش نیست.',
);
}

// -------------------------------------------------------
// موفق
// -------------------------------------------------------

if (response.statusCode == 200) {

if (data['success'] != true) {
throw Exception(
data['message'] ??
'دریافت نظرسنجی انجام نشد.',
);
}

if (data['poll'] == null) {
throw Exception(
'اطلاعات نظرسنجی در پاسخ سرور وجود ندارد.',
);
}

return Map<String, dynamic>.from(
data['poll'],
);
}

// -------------------------------------------------------
// احراز هویت
// -------------------------------------------------------

if (response.statusCode == 401) {

throw Exception(
data['detail'] ??
data['message'] ??
'نشست کاربر منقضی شده است.',
);
}

// -------------------------------------------------------
// پیدا نشدن نظرسنجی
// -------------------------------------------------------

if (response.statusCode == 404) {

throw Exception(
data['message'] ??
'این نظرسنجی برای مجتمع شما فعال نیست.',
);
}

// -------------------------------------------------------
// خطای سرور
// -------------------------------------------------------

if (response.statusCode >= 500) {

throw Exception(
'خطای سرور هنگام دریافت نظرسنجی '
'(${response.statusCode})',
);
}

// -------------------------------------------------------
// سایر خطاها
// -------------------------------------------------------

throw Exception(
data['message'] ??
data['detail'] ??
'خطا در دریافت نظرسنجی '
'(${response.statusCode})',
);
}

// =========================================================
// ثبت رأی
// =========================================================

static Future<void> submitVote({
required int pollId,
required List<Map<String, dynamic>> answers,
}) async {

final accessToken =
await _getAccessToken();

if (accessToken == null ||
accessToken.isEmpty) {
throw Exception(
'توکن ورود پیدا نشد.',
);
}

final url =
'${ApiConfig.polls}$pollId/vote/';

debugPrint(
'========== POLL VOTE REQUEST =========='
);

debugPrint(
'URL: $url',
);

debugPrint(
'POLL ID: $pollId',
);

debugPrint(
'ANSWERS: ${jsonEncode(answers)}',
);

final response = await http.post(
Uri.parse(url),
headers: {
'Authorization':
'Bearer $accessToken',
'Content-Type':
'application/json',
'Accept':
'application/json',
},
body: jsonEncode({
'answers': answers,
}),
);

final responseBody =
utf8.decode(
response.bodyBytes,
);

debugPrint(
'POLL VOTE STATUS: '
'${response.statusCode}',
);

debugPrint(
'POLL VOTE BODY: '
'$responseBody',
);

Map<String, dynamic> data = {};

try {

final decoded =
jsonDecode(responseBody);

if (decoded is Map<String, dynamic>) {
data = decoded;
}

} catch (_) {
// اگر پاسخ JSON نبود،
// پایین‌تر بر اساس status code مدیریت می‌شود.
}

// -------------------------------------------------------
// موفق
// -------------------------------------------------------

if (response.statusCode == 200 ||
response.statusCode == 201) {

if (data['success'] == false) {

throw Exception(
data['message'] ??
'ثبت رأی انجام نشد.',
);
}

return;
}

// -------------------------------------------------------
// احراز هویت
// -------------------------------------------------------

if (response.statusCode == 401) {

throw Exception(
data['detail'] ??
data['message'] ??
'نشست کاربر منقضی شده است.',
);
}

// -------------------------------------------------------
// نظرسنجی پیدا نشد
// -------------------------------------------------------

if (response.statusCode == 404) {

throw Exception(
data['message'] ??
'این نظرسنجی برای مجتمع شما فعال نیست.',
);
}

// -------------------------------------------------------
// خطای اعتبارسنجی
// -------------------------------------------------------

if (response.statusCode == 400) {

throw Exception(
data['message'] ??
data['detail'] ??
'اطلاعات رأی نامعتبر است.',
);
}

// -------------------------------------------------------
// خطای سرور
// -------------------------------------------------------

if (response.statusCode >= 500) {

throw Exception(
'خطای سرور هنگام ثبت رأی '
'(${response.statusCode})',
);
}

// -------------------------------------------------------
// سایر خطاها
// -------------------------------------------------------

throw Exception(
data['message'] ??
data['detail'] ??
'ثبت رأی انجام نشد '
'(${response.statusCode})',
);
}

// =========================================================
// Decode عمومی پاسخ
// =========================================================

static Map<String, dynamic> _decodeResponse(
http.Response response,
) {

final body =
utf8.decode(
response.bodyBytes,
);

try {

final decoded =
jsonDecode(body);

if (decoded is Map<String, dynamic>) {
return decoded;
}

} catch (_) {
// پایین‌تر خطای مناسب برگردانده می‌شود.
}

return {
'success': false,
'message':
'پاسخ سرور نامعتبر است.',
};
}
}

