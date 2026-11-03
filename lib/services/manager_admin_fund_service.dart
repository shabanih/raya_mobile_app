
import 'dart:convert';

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerAdminFundService {
  final ApiService apiService;

  ManagerAdminFundService({
    required this.apiService,
  });

  // =====================================================
  // دریافت فهرست تراکنش‌های مالی مدیر
  // =====================================================

  Future<Map<String, dynamic>> getAdminFunds() async {
    final response = await apiService.get(
      ApiConfig.managerAdminFunds,
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map) {
        final result = Map<String, dynamic>.from(data);

        final statistics = result['statistics'];
        final transactions = result['transactions'];

        return {
          'success': result['success'] ?? true,

          'house_id': result['house_id'],
          'house_name': result['house_name'],

          'statistics': statistics is Map
              ? Map<String, dynamic>.from(statistics)
              : <String, dynamic>{},

          'transactions': transactions is List
              ? transactions
              .whereType<Map>()
              .map(
                (item) => Map<String, dynamic>.from(item),
          )
              .toList()
              : <Map<String, dynamic>>[],
        };
      }

      throw Exception(
        'اطلاعات امور مالی مدیر نامعتبر است.',
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

    return 'خطایی در دریافت اطلاعات امور مالی رخ داده است.';
  }

  // =====================================================
  // عنوان فارسی فیلدها
  // =====================================================

  String _fieldTitle(String field) {
    const titles = {
      'house_id': 'شناسه ساختمان',
      'house_name': 'نام ساختمان',

      'statistics': 'آمار تراکنش‌ها',
      'transactions': 'فهرست تراکنش‌ها',

      'total_count': 'تعداد کل تراکنش‌ها',
      'paid_count': 'تعداد پرداخت‌شده',
      'unpaid_count': 'تعداد پرداخت‌نشده',
      'total_amount': 'مجموع مبالغ',

      'sms_credit': 'شارژ پیامک',
      'subscription': 'اشتراک',
      'count': 'تعداد',
      'amount': 'مبلغ',

      'id': 'شناسه تراکنش',
      'transaction_type': 'نوع تراکنش',
      'payment_gateway': 'درگاه پرداخت',
      'payment_date': 'تاریخ پرداخت',
      'transaction_no': 'شماره پیگیری',
      'payment_description': 'شرح پرداخت',
      'is_paid': 'وضعیت پرداخت',
      'created_at': 'تاریخ ثبت',

      'details': 'جزئیات تراکنش',
      'title': 'عنوان',
      'credit_amount': 'مبلغ شارژ پیامک',
      'amount_with_tax': 'مبلغ با مالیات',
      'res_num': 'شناسه سفارش',

      'plan_name': 'نام پلن اشتراک',
      'units_count': 'تعداد واحد',

      'discount_amount': 'مبلغ تخفیف',
      'final_amount': 'مبلغ نهایی',
      'start_date': 'تاریخ شروع اشتراک',
      'end_date': 'تاریخ پایان اشتراک',
      'is_trial': 'اشتراک آزمایشی',

      'non_field_errors': 'خطا',
    };

    return titles[field] ?? field;
  }
}
