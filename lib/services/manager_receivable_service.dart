
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_service.dart';
import 'manager_financial_common_service.dart';

class ManagerReceivableService {
ManagerReceivableService({ApiService? apiService})
    : _api = apiService ?? ApiService(),
_financialCommon = ManagerFinancialCommonService(
apiService: apiService,
);

final ApiService _api;
final ManagerFinancialCommonService _financialCommon;

String get _baseUrl => ApiConfig.baseUrl;

String _url(String path) {
final base = _baseUrl.endsWith('/')
? _baseUrl.substring(0, _baseUrl.length - 1)
    : _baseUrl;

return '$base${path.startsWith('/') ? path : '/$path'}';
}

// --------------------------------------------------
// پردازش پاسخ سرور
// --------------------------------------------------

Map<String, dynamic> _decode(http.Response response) {
dynamic decoded;

try {
decoded = jsonDecode(utf8.decode(response.bodyBytes));
} catch (_) {
throw Exception(
'پاسخ سرور قابل خواندن نیست. کد: ${response.statusCode}',
);
}

if (decoded is! Map) {
throw Exception('ساختار پاسخ سرور نامعتبر است.');
}

final data = Map<String, dynamic>.from(decoded);

if (response.statusCode < 200 || response.statusCode >= 300) {
throw Exception(
data['message']?.toString() ??
data['detail']?.toString() ??
data['error']?.toString() ??
'خطای سرور: ${response.statusCode}',
);
}

if (data['success'] == false) {
throw Exception(
data['message']?.toString() ?? 'عملیات ناموفق بود.',
);
}

return data;
}

List<Map<String, dynamic>> _extractList(
Map<String, dynamic> data,
String key,
) {
final value = data[key];

if (value is! List) return [];

return value
    .whereType<Map>()
    .map((item) => Map<String, dynamic>.from(item))
    .toList();
}

Map<String, dynamic> _extractObject(
Map<String, dynamic> data,
String key,
) {
final value = data[key] ?? data['result'] ?? data['data'] ?? data;

if (value is! Map) {
throw Exception('ساختار اطلاعات دریافتی نامعتبر است.');
}

return Map<String, dynamic>.from(value);
}

String _normalizeDigits(String value) {
return value
    .replaceAll('۰', '0')
    .replaceAll('۱', '1')
    .replaceAll('۲', '2')
    .replaceAll('۳', '3')
    .replaceAll('۴', '4')
    .replaceAll('۵', '5')
    .replaceAll('۶', '6')
    .replaceAll('۷', '7')
    .replaceAll('۸', '8')
    .replaceAll('۹', '9')
    .replaceAll('٠', '0')
    .replaceAll('١', '1')
    .replaceAll('٢', '2')
    .replaceAll('٣', '3')
    .replaceAll('٤', '4')
    .replaceAll('٥', '5')
    .replaceAll('٦', '6')
    .replaceAll('٧', '7')
    .replaceAll('٨', '8')
    .replaceAll('٩', '9')
    .replaceAll(',', '')
    .replaceAll('٬', '');
}

// --------------------------------------------------
// بانک‌ها و پرداخت‌کنندگان
// --------------------------------------------------

// دریافت حساب‌های بانکی فعال ساختمان
  Future<List<Map<String, dynamic>>> getReceivableBanks() async {
    final response = await _api.get(
      _url('/manager/receivables/banks/'),
    );

    final data = _decode(response);
    return _extractList(data, 'results');
  }

// دریافت مالک، مستأجر یا شخص ثالث
  Future<List<Map<String, dynamic>>> getReceivablePayers({
    required String type,
    String search = '',
  }) async {
    final uri = Uri.parse(
      _url('/manager/receivables/payers/'),
    ).replace(
      queryParameters: {
        'type': type,
        'search': search.trim(),
        'limit': '30',
      },
    );

    final response = await _api.get(uri.toString());
    final data = _decode(response);
    return _extractList(data, 'results');
  }

// --------------------------------------------------
// فهرست اسناد دریافتنی
// --------------------------------------------------

Future<List<Map<String, dynamic>>> getReceivables({
String paymentStatus = 'all',
}) async {
final query = <String, String>{};

if (paymentStatus == 'paid' || paymentStatus == 'unpaid') {
query['payment_status'] = paymentStatus;
}

final uri = Uri.parse(_url('/manager/receivables/')).replace(
queryParameters: query.isEmpty ? null : query,
);

final response = await _api.get(uri.toString());

return _extractList(_decode(response), 'results');
}

// --------------------------------------------------
// ایجاد سند دریافتنی
// --------------------------------------------------

Future<Map<String, dynamic>> createReceivable({
required String amount,
required String date,
required String description,
String payerType = '',
int? unitId,
int? renterId,
int? thirdPartyId,
String details = '',
String docNo = '',
int? bankId,
}) async {
final body = <String, dynamic>{
'amount': _normalizeDigits(amount),
'doc_date': _normalizeDigits(date),
'description': description.trim(),
'details': details.trim(),
'payer_type': payerType,
};

final normalizedDocNo = _normalizeDigits(docNo.trim());

if (normalizedDocNo.isNotEmpty) {
body['doc_number'] = normalizedDocNo;
}

if (bankId != null) {
body['bank_id'] = bankId;
}

if (payerType.isNotEmpty) {
_addPayerFields(
body: body,
payerType: payerType,
unitId: unitId,
renterId: renterId,
thirdPartyId: thirdPartyId,
);
}

final response = await _api.post(
_url('/manager/receivables/'),
body: body,
);

return _extractObject(_decode(response), 'receivable');
}

// --------------------------------------------------
// ویرایش سند دریافتنی
// --------------------------------------------------

Future<Map<String, dynamic>> updateReceivable({
required int receivableId,
String? amount,
String? date,
String? description,
String? payerType,
int? unitId,
int? renterId,
int? thirdPartyId,
String? details,
String? docNo,
int? bankId,
}) async {
final body = <String, dynamic>{};

if (amount != null) {
body['amount'] = _normalizeDigits(amount);
}

if (date != null) {
body['doc_date'] = _normalizeDigits(date);
}

if (description != null) {
body['description'] = description.trim();
}

if (details != null) {
body['details'] = details.trim();
}

if (docNo != null) {
final normalized = _normalizeDigits(docNo.trim());
body['doc_number'] = normalized.isEmpty ? null : normalized;
}

if (bankId != null) {
body['bank_id'] = bankId;
}

if (payerType != null) {
body['payer_type'] = payerType;

if (payerType.isNotEmpty) {
_addPayerFields(
body: body,
payerType: payerType,
unitId: unitId,
renterId: renterId,
thirdPartyId: thirdPartyId,
);
}
}

final response = await _api.patch(
_url('/manager/receivables/$receivableId/'),
body: body,
);

return _extractObject(_decode(response), 'receivable');
}

// --------------------------------------------------
// حذف سند دریافتنی
// --------------------------------------------------

Future<void> deleteReceivable(int receivableId) async {
final response = await _api.delete(
_url('/manager/receivables/$receivableId/'),
);

_decode(response);
}

// --------------------------------------------------
// ثبت دریافت واقعی وجه
// --------------------------------------------------

  Future<Map<String, dynamic>> receiveMoney({
    required int receivableId,
    required int bankId,
    required String paymentDate,
    String transactionReference = '',
    required String payerType,
    int? unitId,
    int? renterId,
    int? thirdPartyId,
  }) async {
    final body = <String, dynamic>{
      'bank_id': bankId,
      'payment_date': _normalizeDigits(paymentDate),
      'transaction_reference':
      _normalizeDigits(transactionReference.trim()),
      'payer_type': payerType,
    };

    _addPayerFields(
      body: body,
      payerType: payerType,
      unitId: unitId,
      renterId: renterId,
      thirdPartyId: thirdPartyId,
    );

    final response = await _api.post(
      _url('/manager/receivables/$receivableId/receive/'),
      body: body,
    );

    return _extractObject(_decode(response), 'receivable');
  }

// --------------------------------------------------
// لغو دریافت وجه
// --------------------------------------------------

Future<Map<String, dynamic>> cancelReceiveMoney(
int receivableId,
) async {
final response = await _api.post(
_url('/manager/receivables/$receivableId/cancel-receive/'),
body: <String, dynamic>{},
);

return _extractObject(_decode(response), 'receivable');
}

// --------------------------------------------------
// ایجاد یا ویرایش سند همراه با پیوست
// --------------------------------------------------

Future<Map<String, dynamic>> saveReceivableWithFiles({
int? receivableId,
required String amount,
required String date,
required String description,
String payerType = '',
int? unitId,
int? renterId,
int? thirdPartyId,
String details = '',
String docNo = '',
int? bankId,
List<File> files = const [],
}) async {
if (files.length > 2) {
throw Exception('حداکثر دو مدرک مجاز است.');
}

final fields = <String, String>{
'amount': _normalizeDigits(amount),
'doc_date': _normalizeDigits(date),
'description': description.trim(),
'details': details.trim(),
'payer_type': payerType,
};

final normalizedDocNo = _normalizeDigits(docNo.trim());

if (normalizedDocNo.isNotEmpty) {
fields['doc_number'] = normalizedDocNo;
}

if (bankId != null) {
fields['bank_id'] = bankId.toString();
}

if (payerType.isNotEmpty) {
_addPayerFields(
body: fields,
payerType: payerType,
unitId: unitId,
renterId: renterId,
thirdPartyId: thirdPartyId,
);
}

final isEdit = receivableId != null;

final response = await _sendMultipart(
url: _url(
isEdit
? '/manager/receivables/$receivableId/'
    : '/manager/receivables/',
),
method: isEdit ? 'PATCH' : 'POST',
fields: fields,
files: files,
);

return _extractObject(_decode(response), 'receivable');
}

// --------------------------------------------------
// ارسال Multipart همراه با تمدید خودکار توکن
// --------------------------------------------------

Future<http.Response> _sendMultipart({
required String url,
required String method,
required Map<String, String> fields,
required List<File> files,
}) async {
Future<http.Response> send(String token) async {
final request = http.MultipartRequest(
method,
Uri.parse(url),
);

request.headers.addAll({
'Authorization': 'Bearer $token',
'Accept': 'application/json',
});

request.fields.addAll(fields);

for (final file in files) {
if (!await file.exists()) {
throw Exception('فایل انتخاب‌شده پیدا نشد.');
}

request.files.add(
await http.MultipartFile.fromPath('documents', file.path),
);
}

final streamed = await request.send().timeout(
const Duration(seconds: 30),
);

return http.Response.fromStream(streamed);
}

var token = await TokenStorage.getAccessToken();

if (token == null || token.trim().isEmpty) {
throw Exception('نشست کاربری شما منقضی شده است.');
}

var response = await send(token.trim());

if (response.statusCode == 401) {
final refreshed = await _api.refreshAccessToken();

if (!refreshed) {
throw Exception('TOKEN_EXPIRED');
}

token = await TokenStorage.getAccessToken();

if (token == null || token.trim().isEmpty) {
throw Exception('TOKEN_EXPIRED');
}

response = await send(token.trim());
}

return response;
}

// --------------------------------------------------
// آماده‌سازی اطلاعات پرداخت‌کننده
// --------------------------------------------------

void _addPayerFields({
required Map<String, dynamic> body,
required String payerType,
int? unitId,
int? renterId,
int? thirdPartyId,
}) {
if (payerType == 'owner') {
if (unitId == null) {
throw Exception('لطفاً واحد مالک را انتخاب کنید.');
}

body['unit_id'] = unitId;
} else if (payerType == 'renter') {
if (renterId == null) {
throw Exception('لطفاً مستأجر را انتخاب کنید.');
}

body['payer_renter_id'] = renterId;
} else if (payerType == 'other') {
if (thirdPartyId == null) {
throw Exception('لطفاً شخص پرداخت‌کننده را انتخاب کنید.');
}

body['payer_third_party_id'] = thirdPartyId;
} else {
throw Exception('نوع پرداخت‌کننده معتبر نیست.');
}
}
}
