import 'dart:convert';

import 'api_service.dart';
import '../config/api_config.dart';

class ManagerBankService {
  final ApiService apiService;

  ManagerBankService({
    required this.apiService,
  });

  // =====================================================
  // دریافت لیست حساب‌های بانکی
  // =====================================================

  Future<List<Map<String, dynamic>>> getBanks() async {
    final response = await apiService.get(
      ApiConfig.managerBanks,
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      dynamic items;

      if (data is List) {
        items = data;
      } else if (data is Map) {
        items =
            data['results'] ??
                data['banks'] ??
                [];
      }

      if (items is List) {
        return items
            .whereType<Map>()
            .map(
              (item) =>
          Map<String, dynamic>.from(item),
        )
            .toList();
      }

      return [];
    }

    throw Exception(
      _extractErrorMessage(data),
    );
  }

  // =====================================================
  // دریافت جزئیات یک حساب بانکی
  // =====================================================

  Future<Map<String, dynamic>> getBank(
      int id,
      ) async {
    final response = await apiService.get(
      ApiConfig.managerBankDetail(id),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception(
        'اطلاعات حساب بانکی نامعتبر است.',
      );
    }

    throw Exception(
      _extractErrorMessage(data),
    );
  }

  // =====================================================
  // ایجاد حساب بانکی
  // =====================================================

  Future<Map<String, dynamic>> createBank({
    required int houseId,
    required String bankName,
    required String accountHolderName,
    required String accountNo,
    required String shebaNumber,
    required String cartNumber,
    required String createAt,
    required int initialFund,
    required bool isActive,
    required bool isDefault,
    required bool isGateway,
  }) async {
    final body = <String, dynamic>{
      'house': houseId,
      'bank_name': bankName,
      'account_holder_name':
      accountHolderName,
      'account_no': accountNo,
      'sheba_number': shebaNumber,
      'cart_number': cartNumber,
      'create_at': createAt,
      'initial_fund': initialFund,
      'is_active': isActive,
      'is_default': isDefault,
      'is_gateway': isGateway,
    };

    final response = await apiService.post(
      ApiConfig.managerBanks,
      body: body,
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception(
        'پاسخ سرور برای ایجاد حساب نامعتبر است.',
      );
    }

    throw Exception(
      _extractErrorMessage(data),
    );
  }

  // =====================================================
  // ویرایش حساب بانکی
  // =====================================================

  Future<Map<String, dynamic>> updateBank({
    required int id,
    required int houseId,
    required String bankName,
    required String accountHolderName,
    required String accountNo,
    required String shebaNumber,
    required String cartNumber,
    required String createAt,
    required int initialFund,
    required bool isActive,
    required bool isDefault,
    required bool isGateway,
  }) async {
    final body = <String, dynamic>{
      'house': houseId,
      'bank_name': bankName,
      'account_holder_name':
      accountHolderName,
      'account_no': accountNo,
      'sheba_number': shebaNumber,
      'cart_number': cartNumber,
      'create_at': createAt,
      'initial_fund': initialFund,
      'is_active': isActive,
      'is_default': isDefault,
      'is_gateway': isGateway,
    };

    final response = await apiService.patch(
      ApiConfig.managerBankDetail(id),
      body: body,
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception(
        'پاسخ سرور برای ویرایش حساب نامعتبر است.',
      );
    }

    throw Exception(
      _extractErrorMessage(data),
    );
  }

  // =====================================================
  // حذف حساب بانکی
  // =====================================================

  Future<void> deleteBank(
      int id,
      ) async {
    final response = await apiService.delete(
      ApiConfig.managerBankDetail(id),
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    dynamic data;

    try {
      data = _decodeResponse(response);
    } catch (_) {
      data = null;
    }

    throw Exception(
      _extractErrorMessage(data),
    );
  }

  // =====================================================
  // دریافت لیست انتقال‌های بین بانکی
  // =====================================================

  Future<List<Map<String, dynamic>>>
  getBankTransfers() async {
    final response = await apiService.get(
      ApiConfig.managerBankTransfers,
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      dynamic items;

      if (data is List) {
        items = data;
      } else if (data is Map) {
        items =
            data['results'] ??
                data['transfers'] ??
                [];
      }

      if (items is List) {
        return items
            .whereType<Map>()
            .map(
              (item) =>
          Map<String, dynamic>.from(item),
        )
            .toList();
      }

      return [];
    }

    throw Exception(
      _extractErrorMessage(data),
    );
  }

  // =====================================================
  // ایجاد انتقال بین بانکی
  // =====================================================

  Future<Map<String, dynamic>>
  createBankTransfer({
    required int fromBankId,
    required int toBankId,
    required int amount,
    String? transactionReference,
    required String paymentDate,
    String? paymentDescription,
  }) async {
    if (fromBankId == toBankId) {
      throw Exception(
        'حساب مبدأ و مقصد نمی‌توانند یکسان باشند.',
      );
    }

    if (amount <= 0) {
      throw Exception(
        'مبلغ انتقال باید بیشتر از صفر باشد.',
      );
    }

    final body = <String, dynamic>{
      'from_bank': fromBankId,
      'to_bank': toBankId,
      'amount': amount,
      'payment_date': paymentDate,
    };

    if (transactionReference != null &&
        transactionReference.trim().isNotEmpty) {
      body['transaction_reference'] =
          transactionReference.trim();
    }

    if (paymentDescription != null &&
        paymentDescription.trim().isNotEmpty) {
      body['payment_description'] =
          paymentDescription.trim();
    }

    final response = await apiService.post(
      ApiConfig.managerBankTransfers,
      body: body,
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return {
        'detail': 'انتقال وجه با موفقیت انجام شد.',
      };
    }

    throw Exception(
      _extractErrorMessage(data),
    );
  }

  // =====================================================
  // لغو انتقال بین بانکی
  // =====================================================

  Future<void> deleteBankTransfer(
      int id,
      ) async {
    final response = await apiService.delete(
      ApiConfig.managerBankTransferDetail(id),
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    dynamic data;

    try {
      data = _decodeResponse(response);
    } catch (_) {
      data = null;
    }

    throw Exception(
      _extractErrorMessage(data),
    );
  }

  // =====================================================
  // Decode پاسخ سرور
  // =====================================================

  dynamic _decodeResponse(
      dynamic response,
      ) {
    final bodyBytes = response.bodyBytes;

    if (bodyBytes.isEmpty) {
      return null;
    }

    final body =
    utf8.decode(
      bodyBytes,
      allowMalformed: true,
    ).trim();

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

  String _extractErrorMessage(
      dynamic data,
      ) {
    if (data == null) {
      return 'خطایی در ارتباط با سرور رخ داده است.';
    }

    if (data is String &&
        data.trim().isNotEmpty) {
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
              .map(
                (item) => item.toString(),
          )
              .join('\n');
        }

        if (message is Map) {
          return _formatMapErrors(
            message,
          );
        }

        return message.toString();
      }

      final errors = <String>[];

      data.forEach(
            (key, value) {
          final field =
          _fieldTitle(
            key.toString(),
          );

          if (value is List) {
            errors.add(
              '$field: '
                  '${value.map((e) => e.toString()).join('، ')}',
            );
          } else if (value is Map) {
            errors.add(
              '$field: '
                  '${_formatMapErrors(value)}',
            );
          } else {
            errors.add(
              '$field: $value',
            );
          }
        },
      );

      if (errors.isNotEmpty) {
        return errors.join('\n');
      }
    }

    return 'خطایی در ارتباط با سرور رخ داده است.';
  }

  // =====================================================
  // خطاهای Map تو در تو
  // =====================================================

  String _formatMapErrors(
      Map data,
      ) {
    final messages = <String>[];

    data.forEach(
          (key, value) {
        if (value is List) {
          messages.add(
            '${_fieldTitle(key.toString())}: '
                '${value.map((e) => e.toString()).join('، ')}',
          );
        } else {
          messages.add(
            '${_fieldTitle(key.toString())}: $value',
          );
        }
      },
    );

    return messages.join('\n');
  }

  // =====================================================
  // عنوان فارسی فیلدها
  // =====================================================

  String _fieldTitle(
      String field,
      ) {
    const titles = {
      'house': 'ساختمان',
      'house_id': 'ساختمان',
      'house_name': 'ساختمان',

      'bank_name': 'نام بانک',

      'account_holder_name':
      'نام صاحب حساب',

      'account_no':
      'شماره حساب',

      'sheba_number':
      'شماره شبا',

      'cart_number':
      'شماره کارت',

      'create_at':
      'تاریخ افتتاح حساب',

      'initial_fund':
      'موجودی اولیه',

      'current_balance':
      'موجودی فعلی',

      'is_active':
      'وضعیت حساب',

      'is_default':
      'حساب پیش‌فرض',

      'is_gateway':
      'حساب درگاه',

      'from_bank':
      'حساب مبدأ',

      'to_bank':
      'حساب مقصد',

      'amount':
      'مبلغ',

      'transaction_reference':
      'شماره تراکنش',

      'payment_date':
      'تاریخ انتقال',

      'payment_description':
      'شرح انتقال',

      'detail':
      'توضیحات',

      'non_field_errors':
      'خطا',
    };

    return titles[field] ?? field;
  }
}