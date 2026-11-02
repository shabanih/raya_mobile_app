
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/api_service.dart';
import '../storage/token_storage.dart';

class ManagerThirdPartyService {
  ManagerThirdPartyService._();

  static final ManagerThirdPartyService instance =
  ManagerThirdPartyService._();

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

    final result = map['result'] ??
        map['data'] ??
        map['third_party'];

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
  // درخواست JSON با تمدید خودکار توکن
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

    Future<http.Response> send() async {
      final headers = await _headers();

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

        case 'PUT':
          return http.put(
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
  // دریافت لیست طرف حساب‌ها
  // ---------------------------------------------------------

  Future<List<Map<String, dynamic>>> getThirdParties({
    String personType = 'all',
    String search = '',
    String status = 'all',
  }) async {
    final query = <String, String>{};

    if (personType == 'person' ||
        personType == 'company') {
      query['person_type'] = personType;
    }

    if (search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }

    if (status == 'active' || status == 'inactive') {
      query['status'] = status;
    }

    final response = await _request(
      'GET',
      '/manager/third-parties/',
      queryParameters: query,
    );

    return _extractList(response);
  }

  // ---------------------------------------------------------
  // ساخت فیلدهای طرف حساب
  // ---------------------------------------------------------

  Map<String, dynamic> _buildFields({
    required String name,
    required String personType,
    String mobile = '',
    String nationalCode = '',
    String economicCode = '',
    String address = '',
    String description = '',
    bool isActive = true,
  }) {
    return <String, dynamic>{
      'name': name.trim(),
      'person_type': personType,
      'mobile': _normalizeDigits(mobile),
      'national_code': _normalizeDigits(nationalCode),
      'economic_code': _normalizeDigits(economicCode),
      'address': address.trim(),
      'description': description.trim(),
      'is_active': isActive,
    };
  }

  // ---------------------------------------------------------
  // ثبت طرف حساب جدید
  // ---------------------------------------------------------

  Future<Map<String, dynamic>> createThirdParty({
    required String name,
    required String personType,
    String mobile = '',
    String nationalCode = '',
    String economicCode = '',
    String address = '',
    String description = '',
    bool isActive = true,
  }) async {
    final body = _buildFields(
      name: name,
      personType: personType,
      mobile: mobile,
      nationalCode: nationalCode,
      economicCode: economicCode,
      address: address,
      description: description,
      isActive: isActive,
    );

    final response = await _request(
      'POST',
      '/manager/third-parties/',
      body: body,
    );

    return _extractObject(response);
  }

  // ---------------------------------------------------------
  // ویرایش طرف حساب
  // ---------------------------------------------------------

  Future<Map<String, dynamic>> updateThirdParty({
    required int id,
    required String name,
    required String personType,
    String mobile = '',
    String nationalCode = '',
    String economicCode = '',
    String address = '',
    String description = '',
    bool isActive = true,
  }) async {
    final body = _buildFields(
      name: name,
      personType: personType,
      mobile: mobile,
      nationalCode: nationalCode,
      economicCode: economicCode,
      address: address,
      description: description,
      isActive: isActive,
    );

    final response = await _request(
      'PUT',
      '/manager/third-parties/$id/',
      body: body,
    );

    return _extractObject(response);
  }

  // ---------------------------------------------------------
  // حذف طرف حساب
  // ---------------------------------------------------------

  Future<void> deleteThirdParty(int id) async {
    await _request(
      'DELETE',
      '/manager/third-parties/$id/',
    );
  }
}
