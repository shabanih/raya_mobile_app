
import 'dart:convert';

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerFundTurnoverService {
  final ApiService apiService;

  ManagerFundTurnoverService({
    required this.apiService,
  });

  // =====================================================
  // دریافت گزارش گردش صندوق
  // =====================================================

  Future<Map<String, dynamic>> getFundTurnover({
    int limit = 20,
  }) async {
    if (![10, 20, 30].contains(limit)) {
      limit = 20;
    }

    final response = await apiService.get(
      '${ApiConfig.managerFundTurnover}?limit=$limit',
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map) {
        final result = Map<String, dynamic>.from(data);

        final summary = result['summary'];
        final items = result['results'];

        return {
          'success': result['success'] ?? true,
          'summary': summary is Map
              ? Map<String, dynamic>.from(summary)
              : <String, dynamic>{},
          'limit': result['limit'] ?? limit,
          'count': result['count'] ?? 0,
          'results': items is List
              ? items
              .whereType<Map>()
              .map(
                (item) =>
            Map<String, dynamic>.from(item),
          )
              .toList()
              : <Map<String, dynamic>>[],
        };
      }

      throw Exception(
        'اطلاعات گزارش گردش صندوق نامعتبر است.',
      );
    }

    throw Exception(
      _extractErrorMessage(data),
    );
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

    return 'خطایی در دریافت گزارش گردش صندوق رخ داده است.';
  }

  // =====================================================
  // عنوان فارسی فیلدها
  // =====================================================

  String _fieldTitle(String field) {
    const titles = {
      'limit': 'تعداد گردش‌ها',
      'summary': 'خلاصه گزارش',
      'total_debtor': 'جمع بدهکار',
      'total_creditor': 'جمع بستانکار',
      'balance': 'مانده صندوق',
      'payment_date': 'تاریخ پرداخت',
      'payment_description': 'شرح تراکنش',
      'payer': 'پرداخت‌کننده',
      'receiver': 'دریافت‌کننده',
      'amount': 'مبلغ',
      'debtor_amount': 'بدهکار',
      'creditor_amount': 'بستانکار',
      'bank_name': 'نام بانک',
      'transaction_no': 'شماره تراکنش',
      'detail': 'توضیحات',
      'non_field_errors': 'خطا',
    };

    return titles[field] ?? field;
  }
}
