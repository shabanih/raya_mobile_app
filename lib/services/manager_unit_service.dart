import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_service.dart';
import '../config/api_config.dart';

class ManagerUnitService {
  final ApiService _apiService = ApiService();

  // =========================================================
  // دریافت لیست واحدها
  // =========================================================

  Future<List<Map<String, dynamic>>> getUnits({
    String? search,
    String? residentType,
  }) async {
    try {
      String url = ApiConfig.managerUnits;

      final params = <String, String>{};

      // -------------------------------------------------------
      // جستجو
      // -------------------------------------------------------

      if (search != null &&
          search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }

      // -------------------------------------------------------
      // فیلتر نوع ساکن
      // all / owner / renter
      // -------------------------------------------------------

      if (residentType != null &&
          residentType.trim().isNotEmpty &&
          residentType.trim() != 'all') {
        params['resident_type'] =
            residentType.trim();
      }

      // -------------------------------------------------------
      // ساخت Query String
      // -------------------------------------------------------

      if (params.isNotEmpty) {
        url +=
        '?${Uri(queryParameters: params).query}';
      }

      debugPrint(
        'ManagerUnitService GET: $url',
      );

      final response =
      await _apiService.get(url);

      // =======================================================
      // موفق
      // =======================================================

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          return [];
        }

        final data =
        jsonDecode(response.body);

        // -----------------------------------------------------
        // اگر مستقیماً List برگشت
        // -----------------------------------------------------

        if (data is List) {
          return data
              .whereType<Map>()
              .map<Map<String, dynamic>>(
                (item) =>
            Map<String, dynamic>.from(
              item,
            ),
          )
              .toList();
        }

        // -----------------------------------------------------
        // اگر Map برگشت
        // -----------------------------------------------------

        if (data is Map<String, dynamic>) {

          // results
          if (data['results'] is List) {
            return _convertUnitList(
              data['results'],
            );
          }

          // units
          if (data['units'] is List) {
            return _convertUnitList(
              data['units'],
            );
          }

          // data
          if (data['data'] is List) {
            return _convertUnitList(
              data['data'],
            );
          }
        }

        return [];
      }

      // =======================================================
      // خطا
      // =======================================================

      debugPrint(
        'getUnits error: '
            '${response.statusCode} '
            '${response.body}',
      );

      throw Exception(
        _extractError(
          response.body,
          'خطا در دریافت لیست واحدها',
        ),
      );
    } catch (e) {
      debugPrint(
        'getUnits exception: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // تبدیل لیست واحدها
  // =========================================================

  List<Map<String, dynamic>> _convertUnitList(
      dynamic value,
      ) {
    if (value is! List) {
      return [];
    }

    return value
        .whereType<Map>()
        .map<Map<String, dynamic>>(
          (item) =>
      Map<String, dynamic>.from(
        item,
      ),
    )
        .toList();
  }

  // =========================================================
  // دریافت جزئیات یک واحد
  // =========================================================

  Future<Map<String, dynamic>> getUnit(
      int unitId,
      ) async {
    try {
      final response =
      await _apiService.get(
        ApiConfig.managerUnitDetail(
          unitId,
        ),
      );

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          throw Exception(
            'اطلاعات واحد خالی است.',
          );
        }

        final data =
        jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          return data;
        }

        throw Exception(
          'اطلاعات واحد نامعتبر است.',
        );
      }

      debugPrint(
        'getUnit error: '
            '${response.statusCode} '
            '${response.body}',
      );

      throw Exception(
        _extractError(
          response.body,
          'خطا در دریافت اطلاعات واحد',
        ),
      );
    } catch (e) {
      debugPrint(
        'getUnit exception: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // ایجاد واحد
  // =========================================================

  Future<Map<String, dynamic>> createUnit(
      Map<String, dynamic> data,
      ) async {
    try {
      final response =
      await _apiService.post(
        ApiConfig.managerUnits,
        body: data,
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        if (response.body.trim().isEmpty) {
          return {
            'success': true,
          };
        }

        final result =
        jsonDecode(response.body);

        if (result is Map<String, dynamic>) {
          return result;
        }

        return {
          'success': true,
          'data': result,
        };
      }

      debugPrint(
        'createUnit error: '
            '${response.statusCode} '
            '${response.body}',
      );

      throw Exception(
        _extractError(
          response.body,
          'خطا در ایجاد واحد',
        ),
      );
    } catch (e) {
      debugPrint(
        'createUnit exception: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // ویرایش واحد
  // =========================================================

  Future<Map<String, dynamic>> updateUnit(
      int unitId,
      Map<String, dynamic> data,
      ) async {
    try {
      final response =
      await _apiService.patch(
        ApiConfig.managerUnitDetail(
          unitId,
        ),
        body: data,
      );

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          return {
            'success': true,
          };
        }

        final result =
        jsonDecode(response.body);

        if (result is Map<String, dynamic>) {
          return result;
        }

        return {
          'success': true,
          'data': result,
        };
      }

      debugPrint(
        'updateUnit error: '
            '${response.statusCode} '
            '${response.body}',
      );

      throw Exception(
        _extractError(
          response.body,
          'خطا در ویرایش واحد',
        ),
      );
    } catch (e) {
      debugPrint(
        'updateUnit exception: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // حذف واحد
  // =========================================================

  Future<bool> deleteUnit(
      int unitId,
      ) async {
    try {
      final response =
      await _apiService.delete(
        ApiConfig.managerUnitDetail(
          unitId,
        ),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        return true;
      }

      debugPrint(
        'deleteUnit error: '
            '${response.statusCode} '
            '${response.body}',
      );

      throw Exception(
        _extractError(
          response.body,
          'خطا در حذف واحد',
        ),
      );
    } catch (e) {
      debugPrint(
        'deleteUnit exception: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // دریافت مالک فعلی واحد
  // =========================================================

  Future<Map<String, dynamic>?> getOwner(
      int unitId,
      ) async {
    try {
      final response =
      await _apiService.get(
        ApiConfig.managerUnitOwner(
          unitId,
        ),
      );

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          return null;
        }

        final data =
        jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          return data;
        }

        return null;
      }

      if (response.statusCode == 404) {
        return null;
      }

      debugPrint(
        'getOwner error: '
            '${response.statusCode} '
            '${response.body}',
      );

      throw Exception(
        _extractError(
          response.body,
          'خطا در دریافت اطلاعات مالک',
        ),
      );
    } catch (e) {
      debugPrint(
        'getOwner exception: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // افزودن مالک
  // =========================================================

  Future<Map<String, dynamic>> createOwner(
      int unitId,
      Map<String, dynamic> data,
      ) async {
    try {
      final response =
      await _apiService.post(
        ApiConfig.managerUnitOwner(
          unitId,
        ),
        body: data,
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        if (response.body.trim().isEmpty) {
          return {
            'success': true,
          };
        }

        final result =
        jsonDecode(response.body);

        if (result is Map<String, dynamic>) {
          return result;
        }

        return {
          'success': true,
          'data': result,
        };
      }

      debugPrint(
        'createOwner error: '
            '${response.statusCode} '
            '${response.body}',
      );

      throw Exception(
        _extractError(
          response.body,
          'خطا در ثبت مالک',
        ),
      );
    } catch (e) {
      debugPrint(
        'createOwner exception: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // ویرایش مالک
  // =========================================================

  Future<Map<String, dynamic>> updateOwner(
      int unitId,
      Map<String, dynamic> data,
      ) async {
    try {
      final response =
      await _apiService.patch(
        ApiConfig.managerUnitOwner(
          unitId,
        ),
        body: data,
      );

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          return {
            'success': true,
          };
        }

        final result =
        jsonDecode(response.body);

        if (result is Map<String, dynamic>) {
          return result;
        }

        return {
          'success': true,
          'data': result,
        };
      }

      debugPrint(
        'updateOwner error: '
            '${response.statusCode} '
            '${response.body}',
      );

      throw Exception(
        _extractError(
          response.body,
          'خطا در ویرایش مالک',
        ),
      );
    } catch (e) {
      debugPrint(
        'updateOwner exception: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // حذف مالک
  // =========================================================

  Future<bool> deleteOwner(
      int unitId,
      ) async {
    try {
      final response =
      await _apiService.delete(
        ApiConfig.managerUnitOwner(
          unitId,
        ),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        return true;
      }

      debugPrint(
        'deleteOwner error: '
            '${response.statusCode} '
            '${response.body}',
      );

      throw Exception(
        _extractError(
          response.body,
          'خطا در حذف مالک',
        ),
      );
    } catch (e) {
      debugPrint(
        'deleteOwner exception: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // دریافت مستاجر فعلی واحد
  // =========================================================

  Future<Map<String, dynamic>?> getRenter(
      int unitId,
      ) async {
    try {
      final response =
      await _apiService.get(
        ApiConfig.managerUnitRenter(
          unitId,
        ),
      );

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          return null;
        }

        final data =
        jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          return data;
        }

        return null;
      }

      if (response.statusCode == 404) {
        return null;
      }

      debugPrint(
        'getRenter error: '
            '${response.statusCode} '
            '${response.body}',
      );

      throw Exception(
        _extractError(
          response.body,
          'خطا در دریافت اطلاعات مستاجر',
        ),
      );
    } catch (e) {
      debugPrint(
        'getRenter exception: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // افزودن مستاجر
  // =========================================================

  Future<Map<String, dynamic>> createRenter(
      int unitId,
      Map<String, dynamic> data,
      ) async {
    try {
      final response =
      await _apiService.post(
        ApiConfig.managerUnitRenter(
          unitId,
        ),
        body: data,
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        if (response.body.trim().isEmpty) {
          return {
            'success': true,
          };
        }

        final result =
        jsonDecode(response.body);

        if (result is Map<String, dynamic>) {
          return result;
        }

        return {
          'success': true,
          'data': result,
        };
      }

      debugPrint(
        'createRenter error: '
            '${response.statusCode} '
            '${response.body}',
      );

      throw Exception(
        _extractError(
          response.body,
          'خطا در ثبت مستاجر',
        ),
      );
    } catch (e) {
      debugPrint(
        'createRenter exception: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // ویرایش مستاجر
  // =========================================================

  Future<Map<String, dynamic>> updateRenter(
      int unitId,
      Map<String, dynamic> data,
      ) async {
    try {
      final response =
      await _apiService.patch(
        ApiConfig.managerUnitRenter(
          unitId,
        ),
        body: data,
      );

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty) {
          return {
            'success': true,
          };
        }

        final result =
        jsonDecode(response.body);

        if (result is Map<String, dynamic>) {
          return result;
        }

        return {
          'success': true,
          'data': result,
        };
      }

      debugPrint(
        'updateRenter error: '
            '${response.statusCode} '
            '${response.body}',
      );

      throw Exception(
        _extractError(
          response.body,
          'خطا در ویرایش مستاجر',
        ),
      );
    } catch (e) {
      debugPrint(
        'updateRenter exception: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // حذف مستاجر
  // =========================================================

  Future<bool> deleteRenter(
      int unitId,
      ) async {
    try {
      final response =
      await _apiService.delete(
        ApiConfig.managerUnitRenter(
          unitId,
        ),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        return true;
      }

      debugPrint(
        'deleteRenter error: '
            '${response.statusCode} '
            '${response.body}',
      );

      throw Exception(
        _extractError(
          response.body,
          'خطا در حذف مستاجر',
        ),
      );
    } catch (e) {
      debugPrint(
        'deleteRenter exception: $e',
      );

      rethrow;
    }
  }

  // =========================================================
  // استخراج پیام خطای API
  // =========================================================

  String _extractError(
      String body,
      String defaultMessage,
      ) {
    try {
      if (body.trim().isEmpty) {
        return defaultMessage;
      }

      final data =
      jsonDecode(body);

      if (data is String &&
          data.trim().isNotEmpty) {
        return data;
      }

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

        final messages =
        <String>[];

        data.forEach(
              (key, value) {
            if (value is List) {
              for (final item in value) {
                messages.add(
                  item.toString(),
                );
              }
            } else if (value != null) {
              messages.add(
                value.toString(),
              );
            }
          },
        );

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    } catch (_) {}

    return defaultMessage;
  }
}