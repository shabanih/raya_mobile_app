
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/api_service.dart';
import '../storage/token_storage.dart';

class ManagerPropertyService {
  ManagerPropertyService._();

  static final ManagerPropertyService instance =
  ManagerPropertyService._();

  final ApiService _api = ApiService();

  String get _baseUrl => ApiConfig.baseUrl;

  // ---------------------------------------------------------
  // تبدیل اعداد فارسی و عربی به انگلیسی
  // ---------------------------------------------------------

  String _normalizeDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const english = '0123456789';

    for (var i = 0; i < 10; i++) {
      value = value.replaceAll(persian[i], english[i]);
      value = value.replaceAll(arabic[i], english[i]);
    }

    return value.replaceAll(',', '').replaceAll('٬', '').trim();
  }

  // ---------------------------------------------------------
  // پردازش پاسخ سرور
  // ---------------------------------------------------------

  dynamic _decodeResponse(http.Response response) {
    final body = utf8.decode(response.bodyBytes);

    dynamic decoded;

    try {
      decoded = jsonDecode(body);
    } catch (_) {
      decoded = <String, dynamic>{
        'success': false,
        'message': 'پاسخ سرور قابل خواندن نیست.',
      };
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      final message = decoded is Map
          ? (decoded['message'] ??
          decoded['detail'] ??
          'خطا در ارتباط با سرور')
          : 'خطا در ارتباط با سرور';

      throw Exception(message.toString());
    }

    if (decoded is Map && decoded['success'] == false) {
      throw Exception(
        (decoded['message'] ?? 'عملیات انجام نشد.').toString(),
      );
    }

    return decoded;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;

    if (value is Map) {
      return value.map(
            (key, value) => MapEntry(key.toString(), value),
      );
    }

    throw Exception('ساختار پاسخ سرور معتبر نیست.');
  }

  List<Map<String, dynamic>> _extractList(dynamic response) {
    if (response is List) {
      return response.map(_asMap).toList();
    }

    if (response is Map) {
      final data = response['results'] ??
          response['data'] ??
          response['items'];

      if (data is List) {
        return data.map(_asMap).toList();
      }
    }

    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _extractObject(dynamic response) {
    final map = _asMap(response);
    final result = map['result'] ?? map['data'];

    if (result is Map) return _asMap(result);

    return map;
  }

  // ---------------------------------------------------------
  // هدر درخواست
  // ---------------------------------------------------------

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getAccessToken();

    return <String, String>{
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ---------------------------------------------------------
  // ساخت URL
  // ---------------------------------------------------------

  Uri _uri(
      String path, {
        Map<String, String>? queryParameters,
      }) {
    final base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;

    return Uri.parse('$base$path').replace(
      queryParameters:
      queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );
  }

  // ---------------------------------------------------------
  // درخواست عادی JSON
  // ---------------------------------------------------------

  Future<dynamic> _request(
      String method,
      String path, {
        Map<String, String>? queryParameters,
        Map<String, dynamic>? body,
      }) async {
    final uri = _uri(
      path,
      queryParameters: queryParameters,
    );

    final headers = await _headers();

    Future<http.Response> send() {
      switch (method) {
        case 'GET':
          return http.get(uri, headers: headers);

        case 'POST':
          return http.post(
            uri,
            headers: {
              ...headers,
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(body ?? <String, dynamic>{}),
          );

        case 'PATCH':
          return http.patch(
            uri,
            headers: {
              ...headers,
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(body ?? <String, dynamic>{}),
          );

        case 'DELETE':
          return http.delete(uri, headers: headers);

        default:
          throw Exception('متد درخواست پشتیبانی نمی‌شود.');
      }
    }

    var response = await send();

    if (response.statusCode == 401) {
      final refreshed = await _api.refreshAccessToken();

      if (refreshed == true) {
        response = await send();
      }
    }

    return _decodeResponse(response);
  }

  // ---------------------------------------------------------
  // درخواست Multipart برای ثبت و ویرایش و ارسال مدارک
  // ---------------------------------------------------------

  Future<dynamic> _multipartRequest({
    required String path,
    required String method,
    required Map<String, String> fields,
    required List<String> filePaths,
  }) async {
    if (filePaths.length > 2) {
      throw Exception('حداکثر دو مدرک برای هر مال مجاز است.');
    }

    final uri = _uri(path);
    final headers = await _headers();

    Future<http.Response> send() async {
      final request = http.MultipartRequest(method, uri);

      request.headers.addAll(headers);
      request.fields.addAll(fields);

      for (final filePath in filePaths) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'documents',
            filePath,
          ),
        );
      }

      final streamed = await request.send();

      return http.Response.fromStream(streamed);
    }

    var response = await send();

    if (response.statusCode == 401) {
      final refreshed = await _api.refreshAccessToken();

      if (refreshed == true) {
        response = await send();
      }
    }

    return _decodeResponse(response);
  }

  // ---------------------------------------------------------
  // دریافت فهرست اموال
  // ---------------------------------------------------------

  Future<List<Map<String, dynamic>>> getProperties({
    String paymentStatus = 'all',
  }) async {
    final query = <String, String>{};

    if (paymentStatus == 'paid' ||
        paymentStatus == 'unpaid') {
      query['payment_status'] = paymentStatus;
    }

    final response = await _request(
      'GET',
      '/manager/properties/',
      queryParameters: query,
    );

    return _extractList(response);
  }

  // ---------------------------------------------------------
  // دریافت حساب‌های بانکی
  // ---------------------------------------------------------

  Future<List<Map<String, dynamic>>> getBanks() async {
    final response = await _request(
      'GET',
      '/manager/properties/banks/',
    );

    return _extractList(response);
  }

  // ---------------------------------------------------------
  // ساخت فیلدهای مال
  // ---------------------------------------------------------

  Map<String, String> _buildFields({
    // required String receiverName,
    required String documentNumber,
    required String count,
    required String propertyName,
    required String propertyUnit,
    required String propertyLocation,
    required String propertyCode,
    required String propertyPrice,
    String companyName = '',
    String propertyPurchaseDate = '',
    String details = '',
  }) {
    return <String, String>{
      // 'receiver_name': receiverName.trim(),
      'company_name': companyName.trim(),
      'document_number': _normalizeDigits(documentNumber),
      'count': _normalizeDigits(count),
      'property_name': propertyName.trim(),
      'property_unit': propertyUnit.trim(),
      'property_location': propertyLocation.trim(),
      'property_code': propertyCode.trim(),
      'property_price': _normalizeDigits(propertyPrice),
      'property_purchase_date':
      _normalizeDigits(propertyPurchaseDate),
      'details': details.trim(),
    };
  }

  // ---------------------------------------------------------
  // ثبت مال جدید
  // ---------------------------------------------------------

  Future<Map<String, dynamic>> createProperty({
    // required String receiverName,
    required String documentNumber,
    required String count,
    required String propertyName,
    required String propertyUnit,
    required String propertyLocation,
    required String propertyCode,
    required String propertyPrice,
    String companyName = '',
    String propertyPurchaseDate = '',
    String details = '',
    List<String> filePaths = const [],
  }) async {
    final fields = _buildFields(
      // receiverName: receiverName,
      companyName: companyName,
      documentNumber: documentNumber,
      count: count,
      propertyName: propertyName,
      propertyUnit: propertyUnit,
      propertyLocation: propertyLocation,
      propertyCode: propertyCode,
      propertyPrice: propertyPrice,
      propertyPurchaseDate: propertyPurchaseDate,
      details: details,
    );

    final response = await _multipartRequest(
      path: '/manager/properties/',
      method: 'POST',
      fields: fields,
      filePaths: filePaths,
    );

    return _extractObject(response);
  }

  // ---------------------------------------------------------
  // ویرایش مال
  // ---------------------------------------------------------

  Future<Map<String, dynamic>> updateProperty({
    required int id,
    // required String receiverName,
    required String documentNumber,
    required String count,
    required String propertyName,
    required String propertyUnit,
    required String propertyLocation,
    required String propertyCode,
    required String propertyPrice,
    String companyName = '',
    String propertyPurchaseDate = '',
    String details = '',
    List<String> filePaths = const [],
  }) async {
    final fields = _buildFields(
      // receiverName: receiverName,
      companyName: companyName,
      documentNumber: documentNumber,
      count: count,
      propertyName: propertyName,
      propertyUnit: propertyUnit,
      propertyLocation: propertyLocation,
      propertyCode: propertyCode,
      propertyPrice: propertyPrice,
      propertyPurchaseDate: propertyPurchaseDate,
      details: details,
    );

    final response = await _multipartRequest(
      path: '/manager/properties/$id/',
      method: 'PATCH',
      fields: fields,
      filePaths: filePaths,
    );

    return _extractObject(response);
  }

  // ---------------------------------------------------------
  // حذف مال
  // ---------------------------------------------------------

  Future<void> deleteProperty(int id) async {
    await _request(
      'DELETE',
      '/manager/properties/$id/',
    );
  }

  // ---------------------------------------------------------
  // پرداخت مال
  // ---------------------------------------------------------

  Future<Map<String, dynamic>> payProperty({
    required int id,
    required int bankId,
    required String paymentDate,
    String transactionReference = '',
  }) async {
    final body = <String, dynamic>{
      'bank_id': bankId,
      'payment_date': _normalizeDigits(paymentDate),
      'transaction_reference':
      _normalizeDigits(transactionReference),
    };

    final response = await _request(
      'POST',
      '/manager/properties/$id/pay/',
      body: body,
    );

    return _extractObject(response);
  }

  // ---------------------------------------------------------
  // لغو پرداخت مال
  // ---------------------------------------------------------

  Future<Map<String, dynamic>> cancelPropertyPayment(
      int id,
      ) async {
    final response = await _request(
      'POST',
      '/manager/properties/$id/cancel-pay/',
    );

    return _extractObject(response);
  }
}
