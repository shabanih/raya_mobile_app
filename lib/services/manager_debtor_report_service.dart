
import 'dart:convert';

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerDebtorReportService {
  final ApiService apiService;

  ManagerDebtorReportService({
    required this.apiService,
  });

  // =====================================================
  // دریافت فهرست واحدهای بدهکار
  // =====================================================

  Future<Map<String, dynamic>> getDebtorUnits({
    String query = '',
    String residentType = 'all',
    int limit = 100,
  }) async {
    if (!['all', 'owner', 'renter'].contains(residentType)) {
      residentType = 'all';
    }

    if (limit < 1) {
      limit = 100;
    }

    final params = <String, String>{
      'limit': limit.toString(),
      'resident_type': residentType,
    };

    if (query.trim().isNotEmpty) {
      params['q'] = query.trim();
    }

    final queryString = Uri(queryParameters: params).query;

    final response = await apiService.get(
      '${ApiConfig.managerDebtorUnits}?$queryString',
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map) {
        final result = Map<String, dynamic>.from(data);

        final items = result['results'];

        return {
          'success': result['success'] ?? true,
          'count': result['count'] ?? 0,
          'limit': result['limit'] ?? limit,
          'total_debt': result['total_debt'] ?? 0,
          'results': items is List
              ? items
              .whereType<Map>()
              .map(
                (item) => Map<String, dynamic>.from(item),
          )
              .toList()
              : <Map<String, dynamic>>[],
        };
      }

      throw Exception(
        'اطلاعات گزارش واحدهای بدهکار نامعتبر است.',
      );
    }

    throw Exception(_extractErrorMessage(data));
  }

  // =====================================================
  // دریافت سوابق بدهی مالک یا مستأجر
  // =====================================================

  Future<Map<String, dynamic>> getDebtorHistory({
    required int unitId,
    required String debtorType,
    required int debtorId,
  }) async {
    if (!['owner', 'renter'].contains(debtorType)) {
      throw Exception('نوع ساکن معتبر نیست.');
    }

    final url =
        '${ApiConfig.managerDebtorUnits}'
        '$unitId/$debtorType/$debtorId/history/';

    final response = await apiService.get(url);

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map) {
        final result = Map<String, dynamic>.from(data);

        final unit = result['unit'];
        final debtor = result['debtor'];
        final summary = result['summary'];
        final history = result['history'];

        return {
          'success': result['success'] ?? true,

          'unit': unit is Map
              ? Map<String, dynamic>.from(unit)
              : <String, dynamic>{},

          'debtor': debtor is Map
              ? Map<String, dynamic>.from(debtor)
              : <String, dynamic>{},

          'summary': summary is Map
              ? Map<String, dynamic>.from(summary)
              : <String, dynamic>{},

          'history': history is Map
              ? {
            'monthly': _parseItems(history['monthly']),
            'civil': _parseItems(history['civil']),
            'sewage': _parseItems(history['sewage']),
          }
              : {
            'monthly': <Map<String, dynamic>>[],
            'civil': <Map<String, dynamic>>[],
            'sewage': <Map<String, dynamic>>[],
          },
        };
      }

      throw Exception(
        'اطلاعات سوابق بدهی نامعتبر است.',
      );
    }

    throw Exception(_extractErrorMessage(data));
  }

  // =====================================================
  // تبدیل لیست سوابق
  // =====================================================

  List<Map<String, dynamic>> _parseItems(dynamic items) {
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

  // =====================================================
  // Decode پاسخ سرور
  // =====================================================

  dynamic _decodeResponse(dynamic response) {
    final bodyBytes = response.bodyBytes;

    if (bodyBytes.isEmpty) {
      return null;
    }

    final body = utf8
        .decode(
      bodyBytes,
      allowMalformed: true,
    )
        .trim();

    if (body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      return body;
    }
  }

  // =====================================================
  // استخراج متن خطا
  // =====================================================

  String _extractErrorMessage(dynamic data) {
    if (data == null) {
      return 'خطایی در ارتباط با سرور رخ داده است.';
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    if (data is Map) {
      final message =
          data['message'] ??
              data['detail'] ??
              data['error'];

      if (message != null) {
        if (message is List) {
          return message
              .map((item) => item.toString())
              .join('\n');
        }

        return message.toString();
      }

      final errors = <String>[];

      data.forEach((key, value) {
        if (value is List) {
          errors.add(
            '${_fieldTitle(key.toString())}: '
                '${value.map((e) => e.toString()).join('، ')}',
          );
        } else {
          errors.add(
            '${_fieldTitle(key.toString())}: $value',
          );
        }
      });

      if (errors.isNotEmpty) {
        return errors.join('\n');
      }
    }

    return 'خطایی در دریافت گزارش بدهکاران رخ داده است.';
  }

  // =====================================================
  // عنوان فارسی فیلدها
  // =====================================================

  String _fieldTitle(String field) {
    const titles = {
      'q': 'جستجو',
      'limit': 'تعداد نمایش',
      'resident_type': 'نوع ساکن',
      'unit_id': 'شماره واحد',
      'debtor_id': 'شناسه بدهکار',
      'debtor_type': 'نوع بدهکار',
      'monthly_debt': 'بدهی شارژ ماهیانه',
      'civil_debt': 'بدهی شارژ عمرانی',
      'sewage_debt': 'بدهی فاضلاب',
      'total_debt': 'مجموع بدهی',
      'monthly': 'شارژ ماهیانه',
      'civil': 'شارژ عمرانی',
      'sewage': 'هزینه فاضلاب',
      'amount': 'مبلغ',
      'due_date': 'تاریخ سررسید',
      'payment_deadline_date': 'مهلت پرداخت',
      'financial_document_number': 'شماره سند مالی',
      'installment_number': 'شماره قسط',
      'non_field_errors': 'خطا',
    };

    return titles[field] ?? field;
  }
}
