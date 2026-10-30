
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/api_service.dart';
import '../storage/token_storage.dart';

class ManagerMaintenanceService {
  ManagerMaintenanceService._();

  static final ManagerMaintenanceService instance =
  ManagerMaintenanceService._();

  final ApiService _api = ApiService();

  String get _baseUrl => ApiConfig.baseUrl;

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

    if (response.statusCode < 200 || response.statusCode >= 300) {
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

  Future<Map<String, String>> _headers() async {
    final token = await TokenStorage.getAccessToken();

    return <String, String>{
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

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

  Future<dynamic> _request(
      String method,
      String path, {
        Map<String, String>? queryParameters,
        Map<String, dynamic>? body,
      }) async {
    final uri = _uri(path, queryParameters: queryParameters);
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

  Future<dynamic> _multipartRequest({
    required String path,
    required String method,
    required Map<String, String> fields,
    required List<String> filePaths,
  }) async {
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
  // دریافت فهرست تعمیر و نگهداری
  // ---------------------------------------------------------

  Future<List<Map<String, dynamic>>> getMaintenances({
    String paymentStatus = 'all',
  }) async {
    final query = <String, String>{};

    if (paymentStatus == 'paid' ||
        paymentStatus == 'unpaid') {
      query['payment_status'] = paymentStatus;
    }

    final response = await _request(
      'GET',
      '/manager/maintenances/',
      queryParameters: query,
    );

    return _extractList(response);
  }

  // ---------------------------------------------------------
  // حساب‌های بانکی
  // ---------------------------------------------------------

  Future<List<Map<String, dynamic>>> getBanks() async {
    final response = await _request(
      'GET',
      '/manager/maintenances/banks/',
    );

    return _extractList(response);
  }

  // ---------------------------------------------------------
  // دریافت‌کنندگان
  // ---------------------------------------------------------

  Future<List<Map<String, dynamic>>> getReceivers({
    required String type,
    String search = '',
  }) async {
    final response = await _request(
      'GET',
      '/manager/maintenances/receivers/',
      queryParameters: {
        'type': type,
        'search': search,
        'limit': '30',
      },
    );

    return _extractList(response);
  }

  // ---------------------------------------------------------
  // ثبت تعمیر و نگهداری
  // ---------------------------------------------------------

  Future<Map<String, dynamic>> createMaintenance({
    required String expertName,
    required String description,
    required String startDate,
    required String endDate,
    required String amount,
    required String maintenanceStatus,
    required String serviceCompany,
    String maintenanceDocumentNo = '',
    String details = '',
    String receiverType = '',
    int? unitId,
    int? receiverRenterId,
    int? receiverThirdPartyId,
    List<String> filePaths = const [],
  }) async {
    final fields = _buildFields(
      expertName: expertName,
      description: description,
      startDate: startDate,
      endDate: endDate,
      amount: amount,
      maintenanceStatus: maintenanceStatus,
      serviceCompany: serviceCompany,
      maintenanceDocumentNo: maintenanceDocumentNo,
      details: details,
      receiverType: receiverType,
      unitId: unitId,
      receiverRenterId: receiverRenterId,
      receiverThirdPartyId: receiverThirdPartyId,
    );

    final response = await _multipartRequest(
      path: '/manager/maintenances/',
      method: 'POST',
      fields: fields,
      filePaths: filePaths,
    );

    return _extractObject(response);
  }

  // ---------------------------------------------------------
  // ویرایش تعمیر و نگهداری
  // ---------------------------------------------------------

  Future<Map<String, dynamic>> updateMaintenance({
    required int id,
    required String expertName,
    required String description,
    required String startDate,
    required String endDate,
    required String amount,
    required String maintenanceStatus,
    required String serviceCompany,
    String maintenanceDocumentNo = '',
    String details = '',
    String receiverType = '',
    int? unitId,
    int? receiverRenterId,
    int? receiverThirdPartyId,
    List<String> filePaths = const [],
  }) async {
    final fields = _buildFields(
      expertName: expertName,
      description: description,
      startDate: startDate,
      endDate: endDate,
      amount: amount,
      maintenanceStatus: maintenanceStatus,
      serviceCompany: serviceCompany,
      maintenanceDocumentNo: maintenanceDocumentNo,
      details: details,
      receiverType: receiverType,
      unitId: unitId,
      receiverRenterId: receiverRenterId,
      receiverThirdPartyId: receiverThirdPartyId,
    );

    final response = await _multipartRequest(
      path: '/manager/maintenances/$id/',
      method: 'PATCH',
      fields: fields,
      filePaths: filePaths,
    );

    return _extractObject(response);
  }

  Map<String, String> _buildFields({
    required String expertName,
    required String description,
    required String startDate,
    required String endDate,
    required String amount,
    required String maintenanceStatus,
    required String serviceCompany,
    required String maintenanceDocumentNo,
    required String details,
    required String receiverType,
    required int? unitId,
    required int? receiverRenterId,
    required int? receiverThirdPartyId,
  }) {
    final fields = <String, String>{
      'expert_name': expertName.trim(),
      'maintenance_description': description.trim(),
      'maintenance_start_date': _normalizeDigits(startDate),
      'maintenance_end_date': _normalizeDigits(endDate),
      'maintenance_price': _normalizeDigits(amount),
      'maintenance_status': maintenanceStatus.trim(),
      'service_company': serviceCompany.trim(),
      'maintenance_document_no':
      _normalizeDigits(maintenanceDocumentNo),
      'details': details.trim(),
      'receiver_type': receiverType,
    };

    if (receiverType == 'owner' && unitId != null) {
      fields['unit_id'] = unitId.toString();
    } else if (receiverType == 'renter' &&
        receiverRenterId != null) {
      fields['receiver_renter_id'] =
          receiverRenterId.toString();
    } else if (receiverType == 'other' &&
        receiverThirdPartyId != null) {
      fields['receiver_third_party_id'] =
          receiverThirdPartyId.toString();
    }

    return fields;
  }

  // ---------------------------------------------------------
  // حذف تعمیر و نگهداری
  // ---------------------------------------------------------

  Future<void> deleteMaintenance(int id) async {
    await _request(
      'DELETE',
      '/manager/maintenances/$id/',
    );
  }

  // ---------------------------------------------------------
  // پرداخت تعمیر و نگهداری
  // ---------------------------------------------------------

  Future<Map<String, dynamic>> payMaintenance({
    required int id,
    required int bankId,
    required String paymentDate,
    String transactionReference = '',
    required String receiverType,
    int? unitId,
    int? receiverRenterId,
    int? receiverThirdPartyId,
  }) async {
    final body = <String, dynamic>{
      'bank_id': bankId,
      'payment_date': _normalizeDigits(paymentDate),
      'transaction_reference': transactionReference.trim(),
      'receiver_type': receiverType,
    };

    if (receiverType == 'owner' && unitId != null) {
      body['unit_id'] = unitId;
    } else if (receiverType == 'renter' &&
        receiverRenterId != null) {
      body['receiver_renter_id'] = receiverRenterId;
    } else if (receiverType == 'other' &&
        receiverThirdPartyId != null) {
      body['receiver_third_party_id'] =
          receiverThirdPartyId;
    }

    final response = await _request(
      'POST',
      '/manager/maintenances/$id/pay/',
      body: body,
    );

    return _extractObject(response);
  }

  // ---------------------------------------------------------
  // لغو پرداخت
  // ---------------------------------------------------------

  Future<Map<String, dynamic>> cancelMaintenancePayment(
      int id,
      ) async {
    final response = await _request(
      'POST',
      '/manager/maintenances/$id/cancel-pay/',
    );

    return _extractObject(response);
  }
}
