
import 'dart:convert';

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_service.dart';

class ManagerMyChargeService {
ManagerMyChargeService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

final ApiService _apiService;

/// دریافت فهرست شارژهای ماهیانه
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

/// دریافت واحدهای مربوط به یک شارژ
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

/// تبدیل پاسخ سرور به فهرست نتایج
List<Map<String, dynamic>> _parseResults(
List<int> bodyBytes,
int statusCode,
String operation,
) {
final body = utf8.decode(bodyBytes);

dynamic decoded;

try {
decoded = jsonDecode(body);
} catch (_) {
throw Exception('$operation ناموفق بود؛ پاسخ سرور معتبر نیست.');
}

if (statusCode < 200 || statusCode >= 300) {
String message = 'خطای سرور ($statusCode)';

if (decoded is Map) {
message = decoded['message']?.toString() ??
decoded['detail']?.toString() ??
message;
}

throw Exception('$operation: $message');
}

if (decoded is! Map) {
throw Exception('$operation: ساختار پاسخ سرور معتبر نیست.');
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
throw Exception('$operation: فهرست results در پاسخ وجود ندارد.');
}

return results
    .whereType<Map>()
    .map((item) => Map<String, dynamic>.from(item))
    .toList();
}
}
