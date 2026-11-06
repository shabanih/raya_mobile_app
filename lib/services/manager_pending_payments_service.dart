
import 'dart:convert';

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerPendingPaymentsService {
  final ApiService apiService;

  ManagerPendingPaymentsService({
    required this.apiService,
  });

  // =====================================================
  // دریافت پرداخت‌های در انتظار تأیید
  // =====================================================

  Future<Map<String, dynamic>> getPendingPayments({
    String? type,
  }) async {
    String url = ApiConfig.managerPendingPayments;

    if (type != null && type.isNotEmpty) {
      url += '?type=${Uri.encodeQueryComponent(type)}';
    }

    final response = await apiService.get(url);

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map) {
        final result = Map<String, dynamic>.from(data);

        final statistics = result['statistics'];
        final payments = result['payments'];

        return {
          'success': result['success'] ?? true,

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
        'اطلاعات پرداخت‌های در انتظار تأیید نامعتبر است.',
      );
    }

    throw Exception(_extractErrorMessage(data));
  }

  // =====================================================
  // تأیید پرداخت
  // =====================================================

  Future<Map<String, dynamic>> approvePayment({
    required int paymentId,
    required String paymentType,
  }) async {
    final response = await apiService.post(
      ApiConfig.managerApprovePayment,
      body: {
        'payment_id': paymentId,
        'payment_type': paymentType,
      },
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map) {
        final result = Map<String, dynamic>.from(data);

        return {
          'success': result['success'] ?? true,
          'message': result['message'] ?? 'پرداخت با موفقیت تأیید شد.',
          'payment': result['payment'] is Map
              ? Map<String, dynamic>.from(result['payment'])
              : <String, dynamic>{},
        };
      }

      throw Exception(
        'پاسخ تأیید پرداخت از سرور نامعتبر است.',
      );
    }

    throw Exception(_extractErrorMessage(data));
  }

  // =====================================================
  // دریافت تعداد پرداخت‌های در انتظار تأیید
  // =====================================================

  Future<int> getPendingPaymentsCount() async {
    final result = await getPendingPayments();

    final statistics = result['statistics'];

    if (statistics is Map) {
      return int.tryParse(
        statistics['total']?.toString() ?? '0',
      ) ??
          0;
    }

    return 0;
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

    return 'خطایی در دریافت اطلاعات پرداخت‌ها رخ داده است.';
  }

  // =====================================================
  // عنوان فارسی فیلدها
  // =====================================================

  String _fieldTitle(String field) {
    const titles = {
      'success': 'وضعیت درخواست',
      'message': 'پیام',
      'detail': 'جزئیات',

      'statistics': 'آمار پرداخت‌ها',
      'payments': 'فهرست پرداخت‌ها',

      'total': 'تعداد کل پرداخت‌ها',
      'monthly': 'پرداخت شارژ ماهیانه',
      'civil': 'پرداخت شارژ عمرانی',
      'sewage': 'پرداخت هزینه فاضلاب',

      'payment_id': 'شناسه پرداخت',
      'payment_type': 'نوع پرداخت',
      'payment_type_display': 'عنوان نوع پرداخت',

      'title': 'عنوان پرداخت',
      'installment_number': 'شماره قسط',

      'unit_id': 'شناسه واحد',
      'unit_number': 'شماره واحد',
      'owner_name': 'نام مالک',

      'amount': 'مبلغ پرداخت',
      'bank_name': 'نام حساب بانکی',

      'transaction_reference': 'شماره پیگیری',
      'payment_submitted_at': 'تاریخ ارسال پرداخت',

      'financial_document_number': 'شماره سند مالی',
      'payer_type': 'نوع پرداخت‌کننده',
      'payer_name': 'نام پرداخت‌کننده',

      'non_field_errors': 'خطا',
    };

    return titles[field] ?? field;
  }
}
