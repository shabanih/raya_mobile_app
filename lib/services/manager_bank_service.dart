import 'dart:convert';

import '../config/api_config.dart';
import 'api_service.dart';

class ManagerBankService {
  final ApiService apiService;

  ManagerBankService({
    required this.apiService,
  });

  // =====================================================
  // دریافت لیست حساب‌های بانکی مدیر
  // =====================================================

  Future<List<Map<String, dynamic>>> getBanks() async {
    final response = await apiService.get(
      ApiConfig.managerBanks,
    );

    if (response.statusCode == 200) {
      final data = jsonDecodeSafe(response.body);

      if (data is! List) {
        throw Exception(
          'ساختار پاسخ حساب‌های بانکی نامعتبر است.',
        );
      }

      return data
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList();
    }

    if (response.statusCode == 403) {
      throw Exception(
        'شما دسترسی به حساب‌های بانکی را ندارید.',
      );
    }

    throw Exception(
      'خطا در دریافت حساب‌های بانکی: '
          '${response.statusCode}',
    );
  }

  // =====================================================
  // دریافت جزئیات یک حساب
  // =====================================================

  Future<Map<String, dynamic>> getBank(int id) async {
    final response = await apiService.get(
      ApiConfig.managerBankDetail(id),
    );

    if (response.statusCode == 200) {
      final data = jsonDecodeSafe(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception(
        'اطلاعات حساب بانکی نامعتبر است.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'حساب بانکی مورد نظر پیدا نشد.',
      );
    }

    throw Exception(
      'خطا در دریافت اطلاعات حساب بانکی: '
          '${response.statusCode}',
    );
  }

  // =====================================================
  // ثبت حساب بانکی
  // =====================================================

  Future<Map<String, dynamic>> createBank({
    required int houseId,
    required String bankName,
    required String accountNo,
    required String accountHolderName,
    required String shebaNumber,
    required String cartNumber,
    required dynamic initialFund,
    required bool isDefault,
    required bool isGateway,
    required String createAt,
    required bool isActive,
  }) async {
    final response = await apiService.post(
      ApiConfig.managerBanks,
      body: {
        'house': houseId,
        'bank_name': bankName,
        'account_no': accountNo,
        'account_holder_name': accountHolderName,
        'sheba_number': shebaNumber,
        'cart_number': cartNumber,
        'initial_fund': initialFund,
        'is_default': isDefault,
        'is_gateway': isGateway,
        'create_at': createAt,
        'is_active': isActive,
      },
    );

    final data = jsonDecodeSafe(response.body);

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      if (data is Map<String, dynamic>) {
        return data;
      }

      throw Exception(
        'پاسخ ثبت حساب بانکی نامعتبر است.',
      );
    }

    throw Exception(
      extractErrorMessage(
        data,
        defaultMessage:
        'خطا در ثبت حساب بانکی.',
      ),
    );
  }

  // =====================================================
  // ویرایش حساب بانکی
  // =====================================================

  Future<Map<String, dynamic>> updateBank(
      int id,
      Map<String, dynamic> data,
      ) async {
    final response = await apiService.patch(
      ApiConfig.managerBankDetail(id),
      body: data,
    );

    final responseData =
    jsonDecodeSafe(response.body);

    if (response.statusCode == 200) {
      if (responseData is Map<String, dynamic>) {
        return responseData;
      }

      throw Exception(
        'پاسخ ویرایش حساب بانکی نامعتبر است.',
      );
    }

    throw Exception(
      extractErrorMessage(
        responseData,
        defaultMessage:
        'خطا در ویرایش حساب بانکی.',
      ),
    );
  }

  // =====================================================
  // حذف حساب بانکی
  // =====================================================

  Future<void> deleteBank(int id) async {
    final response = await apiService.delete(
      ApiConfig.managerBankDetail(id),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 204) {
      return;
    }

    final data = jsonDecodeSafe(response.body);

    throw Exception(
      extractErrorMessage(
        data,
        defaultMessage:
        'حذف حساب بانکی انجام نشد.',
      ),
    );
  }

  // =====================================================
  // دریافت لیست انتقال‌ها
  // =====================================================

  Future<List<Map<String, dynamic>>>
  getTransfers() async {
    final response = await apiService.get(
      ApiConfig.managerBankTransfers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecodeSafe(response.body);

      if (data is! List) {
        throw Exception(
          'ساختار پاسخ انتقال‌های بانکی نامعتبر است.',
        );
      }

      return data
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList();
    }

    throw Exception(
      'خطا در دریافت انتقال‌های بانکی: '
          '${response.statusCode}',
    );
  }

  // =====================================================
  // ثبت انتقال بین دو حساب
  // =====================================================

  Future<void> createTransfer({
    required int fromBankId,
    required int toBankId,
    required dynamic amount,
    required String paymentDate,
    String? transactionReference,
    String? paymentDescription,
  }) async {
    final response = await apiService.post(
      ApiConfig.managerBankTransfers,
      body: {
        'from_bank': fromBankId,
        'to_bank': toBankId,
        'amount': amount,
        'payment_date': paymentDate,
        'transaction_reference':
        transactionReference ?? '',
        'payment_description':
        paymentDescription ??
            'انتقال وجه داخلی',
      },
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return;
    }

    final data = jsonDecodeSafe(response.body);

    throw Exception(
      extractErrorMessage(
        data,
        defaultMessage:
        'ثبت انتقال وجه انجام نشد.',
      ),
    );
  }

  // =====================================================
  // لغو انتقال
  // =====================================================

  Future<void> deleteTransfer(int id) async {
    final response = await apiService.delete(
      ApiConfig.managerBankTransferDetail(id),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 204) {
      return;
    }

    final data = jsonDecodeSafe(response.body);

    throw Exception(
      extractErrorMessage(
        data,
        defaultMessage:
        'لغو انتقال انجام نشد.',
      ),
    );
  }

  // =====================================================
  // JSON امن
  // =====================================================

  dynamic jsonDecodeSafe(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  // =====================================================
  // استخراج پیام خطا
  // =====================================================

  String extractErrorMessage(
      dynamic data, {
        required String defaultMessage,
      }) {
    if (data is Map<String, dynamic>) {
      if (data['detail'] != null) {
        return data['detail'].toString();
      }

      if (data['message'] != null) {
        return data['message'].toString();
      }

      if (data['error'] != null) {
        return data['error'].toString();
      }

      final errors = data['errors'];

      if (errors is Map) {
        final messages = <String>[];

        errors.forEach((key, value) {
          if (value is List) {
            messages.addAll(
              value.map(
                    (item) => item.toString(),
              ),
            );
          } else {
            messages.add(value.toString());
          }
        });

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }

      // خطاهای validation خود DRF ممکن است مستقیماً
      // به شکل {"field": ["error"]} باشند.
      final messages = <String>[];

      data.forEach((key, value) {
        if (value is List) {
          messages.addAll(
            value.map(
                  (item) => item.toString(),
            ),
          );
        }
      });

      if (messages.isNotEmpty) {
        return messages.join('\n');
      }
    }

    return defaultMessage;
  }
}