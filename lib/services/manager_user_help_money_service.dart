import 'dart:convert';

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerUserHelpMoneyService {
  final ApiService apiService;

  ManagerUserHelpMoneyService({
    required this.apiService,
  });

  // =====================================================
  // دریافت فهرست کمک‌های ساکنین
  // =====================================================

  Future<Map<String, dynamic>> getUserHelpMoney() async {
    final response = await apiService.get(
      ApiConfig.managerUserHelpMoney,
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map) {
        final result = Map<String, dynamic>.from(data);

        final statistics = result['statistics'];
        final payments = result['payments'];

        return {
          'success': result['success'] ?? true,

          'house_id': result['house_id'],

          'statistics': statistics is Map
              ? Map<String, dynamic>.from(statistics)
              : <String, dynamic>{},

          'payments': payments is List
              ? payments
              .whereType<Map>()
              .map(
                (item) => Map<String, dynamic>.from(item),
          )
              .toList()
              : <Map<String, dynamic>>[],
        };
      }

      throw Exception(
        'اطلاعات کمک‌های ساکنین نامعتبر است.',
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

    return 'خطایی در دریافت کمک‌های ساکنین رخ داده است.';
  }

  // =====================================================
  // عنوان فارسی فیلدها
  // =====================================================

  String _fieldTitle(String field) {
    const titles = {
      'house_id': 'شناسه ساختمان',
      'statistics': 'آمار کمک‌ها',
      'payments': 'فهرست کمک‌ها',
      'total_count': 'تعداد کل کمک‌ها',
      'paid_count': 'تعداد پرداخت‌شده',
      'unpaid_count': 'تعداد پرداخت‌نشده',
      'total_amount': 'مجموع مبالغ',
      'amount': 'مبلغ',
      'description': 'شرح کمک',
      'details': 'توضیحات',
      'payer_name': 'نام پرداخت‌کننده',
      'payment_gateway': 'درگاه پرداخت',
      'is_paid': 'وضعیت پرداخت',
      'register_date': 'تاریخ ثبت',
      'payment_date': 'تاریخ پرداخت',
      'transaction_reference': 'شماره پیگیری',
      'financial_document_number': 'شماره سند مالی',
      'unit': 'واحد',
      'bank': 'بانک',
      'documents': 'مدارک',
      'created_at': 'تاریخ ایجاد',
      'non_field_errors': 'خطا',
    };

    return titles[field] ?? field;
  }
}