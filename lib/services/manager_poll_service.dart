import 'dart:convert';

import 'api_service.dart';
import '../config/api_config.dart';

class ManagerPollService {
  final ApiService apiService;

  ManagerPollService({
    required this.apiService,
  });

  // =====================================================
  // دریافت لیست نظرسنجی‌ها
  // =====================================================

  Future<List<Map<String, dynamic>>> getPolls({
    String? search,
  }) async {
    String url = ApiConfig.managerPolls;

    if (search != null &&
        search.trim().isNotEmpty) {
      url +=
      '?search=${Uri.encodeQueryComponent(search.trim())}';
    }

    final response = await apiService.get(url);

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      dynamic items;

      if (data is List) {
        items = data;
      } else if (data is Map) {
        items =
            data['results'] ??
                data['polls'] ??
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
  // دریافت جزئیات یک نظرسنجی
  // =====================================================

  Future<Map<String, dynamic>> getPoll(
      int id,
      ) async {
    final response = await apiService.get(
      ApiConfig.managerPollDetail(id),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception(
        'اطلاعات نظرسنجی نامعتبر است.',
      );
    }

    throw Exception(
      _extractErrorMessage(data),
    );
  }

  // =====================================================
  // ایجاد نظرسنجی
  // =====================================================

  Future<Map<String, dynamic>> createPoll({
    required String title,
    String? description,
    required String startDate,
    required String endDate,
    required bool isActive,
    required List<Map<String, dynamic>> questions,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description ?? '',
      'start_date': startDate,
      'end_date': endDate,
      'is_active': isActive,
      'questions': questions,
    };

    final response = await apiService.post(
      ApiConfig.managerPolls,
      body: body,
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception(
        'پاسخ سرور برای ایجاد نظرسنجی نامعتبر است.',
      );
    }

    throw Exception(
      _extractErrorMessage(data),
    );
  }

  // =====================================================
  // ویرایش نظرسنجی
  //
  // فقط زمانی مجاز است که Vote وجود نداشته باشد.
  // =====================================================

  Future<Map<String, dynamic>> updatePoll({
    required int id,
    required String title,
    String? description,
    required String startDate,
    required String endDate,
    required bool isActive,
    required List<Map<String, dynamic>> questions,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description ?? '',
      'start_date': startDate,
      'end_date': endDate,
      'is_active': isActive,
      'questions': questions,
    };

    final response = await apiService.patch(
      ApiConfig.managerPollDetail(id),
      body: body,
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception(
        'پاسخ سرور برای ویرایش نظرسنجی نامعتبر است.',
      );
    }

    throw Exception(
      _extractErrorMessage(data),
    );
  }

  // =====================================================
  // حذف نظرسنجی
  //
  // فقط زمانی مجاز است که هیچ Vote نداشته باشد.
  // =====================================================

  Future<void> deletePoll(
      int id,
      ) async {
    final response = await apiService.delete(
      ApiConfig.managerPollDetail(id),
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
  // فعال / غیرفعال کردن نظرسنجی
  // =====================================================

  Future<Map<String, dynamic>> togglePollActive({
    required int id,
    required bool isActive,
  }) async {
    final body = <String, dynamic>{
      'is_active': isActive,
    };

    final response = await apiService.patch(
      ApiConfig.managerPollToggleActive(id),
      body: body,
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      return {
        'detail': isActive
            ? 'نظرسنجی فعال شد.'
            : 'نظرسنجی غیرفعال شد.',
        'is_active': isActive,
      };
    }

    throw Exception(
      _extractErrorMessage(data),
    );
  }

  // =====================================================
  // دریافت نتایج نظرسنجی
  // =====================================================

  Future<Map<String, dynamic>> getPollResults(
      int id,
      ) async {
    final response = await apiService.get(
      ApiConfig.managerPollResults(id),
    );

    final data = _decodeResponse(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }

      throw Exception(
        'اطلاعات نتایج نظرسنجی نامعتبر است.',
      );
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
    utf8
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
      'title': 'عنوان نظرسنجی',
      'description': 'توضیحات',

      'start_date': 'تاریخ شروع',
      'end_date': 'تاریخ پایان',

      'is_active': 'وضعیت نظرسنجی',

      'questions': 'سؤالات',

      'question_type': 'نوع سؤال',
      'question': 'سؤال',

      'choices': 'گزینه‌ها',
      'choice': 'گزینه',

      'order': 'ترتیب',

      'poll': 'نظرسنجی',

      'detail': 'توضیحات',

      'has_votes': 'وضعیت پاسخ‌ها',

      'can_edit': 'امکان ویرایش',
      'can_delete': 'امکان حذف',
      'can_deactivate': 'امکان غیرفعال کردن',

      'eligible_count':
      'تعداد افراد مجاز',

      'participant_count':
      'تعداد شرکت‌کنندگان',

      'not_participated_count':
      'تعداد شرکت‌نکرده‌ها',

      'percentage':
      'درصد مشارکت',

      'vote_count':
      'تعداد رأی',

      'non_field_errors':
      'خطا',
    };

    return titles[field] ?? field;
  }
}