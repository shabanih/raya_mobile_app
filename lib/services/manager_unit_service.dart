import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'api_service.dart';
import '../config/api_config.dart';

class ManagerUnitService {
  final ApiService _apiService = ApiService();

  // ============================================================
  // Helpers
  // ============================================================

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  Map<String, dynamic> _unwrapObject(
      dynamic value, {
        int depth = 0,
      }) {
    final map = _asMap(value);

    if (map == null) {
      return {};
    }

    if (depth > 5) {
      return map;
    }

    final unit = _asMap(map['unit']);

    if (unit != null) {
      return _unwrapObject(
        unit,
        depth: depth + 1,
      );
    }

    final data = _asMap(map['data']);

    if (data != null) {
      return _unwrapObject(
        data,
        depth: depth + 1,
      );
    }

    final result = _asMap(map['result']);

    if (result != null) {
      return _unwrapObject(
        result,
        depth: depth + 1,
      );
    }

    return map;
  }

  List<Map<String, dynamic>> _convertUnitList(
      dynamic value,
      ) {
    if (value is! List) {
      return [];
    }

    final result = <Map<String, dynamic>>[];

    for (final item in value) {
      final map = _asMap(item);

      if (map == null) {
        continue;
      }

      final unwrapped = _unwrapObject(map);

      if (unwrapped.isNotEmpty) {
        result.add(unwrapped);
      }
    }

    return result;
  }

  String _extractError(
      String body,
      String defaultMessage,
      ) {
    try {
      if (body.trim().isEmpty) {
        return defaultMessage;
      }

      final data = jsonDecode(body);

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

        final messages = <String>[];

        data.forEach((key, value) {
          if (value is List) {
            for (final item in value) {
              messages.add(item.toString());
            }
          } else if (value != null) {
            messages.add(value.toString());
          }
        });

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    } catch (_) {}

    return defaultMessage;
  }

  // ============================================================
  // Units
  // ============================================================

  Future<List<Map<String, dynamic>>> getUnits({
    String? search,
    String? residentType,
  }) async {
    try {
      String url = ApiConfig.managerUnits;

      final params = <String, String>{};

      if (search != null &&
          search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }

      if (residentType != null &&
          residentType.trim().isNotEmpty &&
          residentType.trim() != 'all') {
        params['resident_type'] =
            residentType.trim();
      }

      if (params.isNotEmpty) {
        url += '?${Uri(
          queryParameters: params,
        ).query}';
      }

      debugPrint(
        'ManagerUnitService GET: $url',
      );

      final response =
      await _apiService.get(url);

      debugPrint(
        'getUnits status: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(
            response.body,
            'خطا در دریافت لیست واحدها',
          ),
        );
      }

      if (response.body.trim().isEmpty) {
        return [];
      }

      final decoded =
      jsonDecode(response.body);

      if (decoded is List) {
        return _convertUnitList(decoded);
      }

      final map = _asMap(decoded);

      if (map == null) {
        return [];
      }

      if (map['results'] is List) {
        return _convertUnitList(
          map['results'],
        );
      }

      if (map['units'] is List) {
        return _convertUnitList(
          map['units'],
        );
      }

      if (map['data'] is List) {
        return _convertUnitList(
          map['data'],
        );
      }

      if (map['result'] is List) {
        return _convertUnitList(
          map['result'],
        );
      }

      final dataObject =
      _asMap(map['data']);

      if (dataObject != null) {
        return [
          _unwrapObject(dataObject),
        ];
      }

      return [];
    } catch (e) {
      debugPrint(
        'getUnits exception: $e',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUnit(
      int unitId,
      ) async {
    try {
      final url =
      ApiConfig.managerUnitDetail(
        unitId,
      );

      final response =
      await _apiService.get(url);

      debugPrint(
        'getUnit status: ${response.statusCode}',
      );

      debugPrint(
        'getUnit body: ${response.body}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(
            response.body,
            'خطا در دریافت اطلاعات واحد',
          ),
        );
      }

      if (response.body.trim().isEmpty) {
        throw Exception(
          'اطلاعات واحد خالی است.',
        );
      }

      final decoded =
      jsonDecode(response.body);

      final result =
      _unwrapObject(decoded);

      if (result.isEmpty) {
        throw Exception(
          'اطلاعات واحد نامعتبر است.',
        );
      }

      return result;
    } catch (e) {
      debugPrint(
        'getUnit exception: $e',
      );
      rethrow;
    }
  }

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
          return _unwrapObject(result);
        }

        return {
          'success': true,
          'data': result,
        };
      }

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
          return _unwrapObject(result);
        }

        return {
          'success': true,
          'data': result,
        };
      }

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

  // ============================================================
  // Owner
  // ============================================================

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

      debugPrint(
        'getOwner status: ${response.statusCode}',
      );

      debugPrint(
        'getOwner body: ${response.body}',
      );

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(
            response.body,
            'خطا در دریافت اطلاعات مالک',
          ),
        );
      }

      if (response.body.trim().isEmpty) {
        return null;
      }

      final decoded =
      jsonDecode(response.body);

      final result =
      _unwrapObject(decoded);

      if (result.isEmpty) {
        return null;
      }

      return result;
    } catch (e) {
      debugPrint(
        'getOwner exception: $e',
      );
      rethrow;
    }
  }

  // ============================================================
  // ایجاد مالک جدید
  // ============================================================

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

      debugPrint(
        'createOwner status: ${response.statusCode}',
      );

      debugPrint(
        'createOwner body: ${response.body}',
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
          return _unwrapObject(result);
        }

        return {
          'success': true,
          'data': result,
        };
      }

      throw Exception(
        _extractError(
          response.body,
          'خطا در ثبت مالک جدید',
        ),
      );
    } catch (e) {
      debugPrint(
        'createOwner exception: $e',
      );
      rethrow;
    }
  }

  // ============================================================
  // ویرایش مالک فعلی
  // ============================================================

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

      debugPrint(
        'updateOwner status: ${response.statusCode}',
      );

      debugPrint(
        'updateOwner body: ${response.body}',
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
          return _unwrapObject(result);
        }

        return {
          'success': true,
          'data': result,
        };
      }

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

      debugPrint(
        'deleteOwner status: ${response.statusCode}',
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        return true;
      }

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

  // ============================================================
  // Renter
  // ============================================================

  /// دریافت مستاجر فعال واحد
  ///
  /// توجه:
  /// API جدید Django برای مستاجر:
  ///
  /// GET
  /// /manager/units/<unit_id>/renters/
  ///
  /// بنابراین دیگر از /renter/ استفاده نمی‌کنیم.
  Future<Map<String, dynamic>?> getRenter(
      int unitId,
      ) async {
    try {
      final url =
      ApiConfig.managerUnitRenters(
        unitId,
      );

      final response =
      await _apiService.get(url);

      debugPrint(
        'getRenter status: ${response.statusCode}',
      );

      debugPrint(
        'getRenter body: ${response.body}',
      );

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(
            response.body,
            'خطا در دریافت اطلاعات مستاجر',
          ),
        );
      }

      if (response.body.trim().isEmpty) {
        return null;
      }

      final decoded =
      jsonDecode(response.body);

      // ----------------------------------------------------------
      // اگر API مستقیماً یک مستاجر برگرداند
      // ----------------------------------------------------------

      final directMap =
      _asMap(decoded);

      if (directMap != null) {
        final directRenter =
        _asMap(directMap['renter']);

        if (directRenter != null &&
            directRenter.isNotEmpty) {
          return directRenter;
        }

        final activeRenter =
        _asMap(directMap['active_renter']);

        if (activeRenter != null &&
            activeRenter.isNotEmpty) {
          return activeRenter;
        }

        final results =
        directMap['results'];

        if (results is List) {
          for (final item in results) {
            final renter =
            _asMap(item);

            if (renter == null) {
              continue;
            }

            final isActive =
            renter['renter_is_active'];

            if (isActive == true) {
              return renter;
            }
          }

          if (results.isNotEmpty) {
            final first =
            _asMap(results.first);

            if (first != null) {
              return first;
            }
          }
        }

        final renters =
        directMap['renters'];

        if (renters is List) {
          for (final item in renters) {
            final renter =
            _asMap(item);

            if (renter == null) {
              continue;
            }

            final isActive =
            renter['renter_is_active'];

            if (isActive == true) {
              return renter;
            }
          }

          if (renters.isNotEmpty) {
            final first =
            _asMap(renters.first);

            if (first != null) {
              return first;
            }
          }
        }

        final data =
        directMap['data'];

        if (data is List) {
          for (final item in data) {
            final renter =
            _asMap(item);

            if (renter == null) {
              continue;
            }

            if (renter['renter_is_active'] == true) {
              return renter;
            }
          }

          if (data.isNotEmpty) {
            final first =
            _asMap(data.first);

            if (first != null) {
              return first;
            }
          }
        }

        final result =
        directMap['result'];

        if (result is List) {
          for (final item in result) {
            final renter =
            _asMap(item);

            if (renter == null) {
              continue;
            }

            if (renter['renter_is_active'] == true) {
              return renter;
            }
          }

          if (result.isNotEmpty) {
            final first =
            _asMap(result.first);

            if (first != null) {
              return first;
            }
          }
        }

        // اگر خود map اطلاعات مستاجر باشد
        if (directMap.containsKey('renter_name') ||
            directMap.containsKey('renter_mobile') ||
            directMap.containsKey('renter_is_active')) {
          return directMap;
        }
      }

      // ----------------------------------------------------------
      // اگر پاسخ List باشد
      // ----------------------------------------------------------

      if (decoded is List) {
        Map<String, dynamic>? firstRenter;

        for (final item in decoded) {
          final renter =
          _asMap(item);

          if (renter == null) {
            continue;
          }

          firstRenter ??= renter;

          if (renter['renter_is_active'] == true) {
            return renter;
          }
        }

        return firstRenter;
      }

      return null;
    } catch (e) {
      debugPrint(
        'getRenter exception: $e',
      );
      rethrow;
    }
  }

  // ============================================================
  // ایجاد مستاجر جدید
  // ============================================================

  /// ثبت مستاجر جدید
  ///
  /// POST:
  /// /manager/units/<unit_id>/renters/
  ///
  /// Backend باید قبل از ایجاد مستاجر جدید،
  /// مستاجر فعال قبلی را غیرفعال کند.
  Future<Map<String, dynamic>> createRenter(
      int unitId,
      Map<String, dynamic> data,
      ) async {
    try {
      final url =
      ApiConfig.managerUnitRenters(
        unitId,
      );

      debugPrint(
        'createRenter URL: $url',
      );

      debugPrint(
        'createRenter data: $data',
      );

      final response =
      await _apiService.post(
        url,
        body: data,
      );

      debugPrint(
        'createRenter status: ${response.statusCode}',
      );

      debugPrint(
        'createRenter body: ${response.body}',
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
          return _unwrapObject(result);
        }

        return {
          'success': true,
          'data': result,
        };
      }

      throw Exception(
        _extractError(
          response.body,
          'خطا در ثبت مستاجر جدید',
        ),
      );
    } catch (e) {
      debugPrint(
        'createRenter exception: $e',
      );
      rethrow;
    }
  }

  // ============================================================
  // ویرایش مستاجر فعلی
  // ============================================================

  /// ویرایش مستاجر مشخص
  ///
  /// PATCH:
  /// /manager/units/<unit_id>/renters/<renter_id>/
  Future<Map<String, dynamic>> updateRenter(
      int unitId,
      int renterId,
      Map<String, dynamic> data,
      ) async {
    try {
      final url =
      ApiConfig.managerUnitRenterDetail(
        unitId,
        renterId,
      );

      debugPrint(
        'updateRenter URL: $url',
      );

      debugPrint(
        'updateRenter data: $data',
      );

      final response =
      await _apiService.patch(
        url,
        body: data,
      );

      debugPrint(
        'updateRenter status: ${response.statusCode}',
      );

      debugPrint(
        'updateRenter body: ${response.body}',
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
          return _unwrapObject(result);
        }

        return {
          'success': true,
          'data': result,
        };
      }

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

  // ============================================================
  // غیرفعال کردن / حذف مستاجر
  // ============================================================

  /// حذف یا غیرفعال کردن مستاجر مشخص
  ///
  /// DELETE:
  /// /manager/units/<unit_id>/renters/<renter_id>/
  Future<bool> deleteRenter(
      int unitId,
      int renterId,
      ) async {
    try {
      final url =
      ApiConfig.managerUnitRenterDetail(
        unitId,
        renterId,
      );

      debugPrint(
        'deleteRenter URL: $url',
      );

      final response =
      await _apiService.delete(url);

      debugPrint(
        'deleteRenter status: ${response.statusCode}',
      );

      debugPrint(
        'deleteRenter body: ${response.body}',
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        return true;
      }

      throw Exception(
        _extractError(
          response.body,
          'خطا در غیرفعال کردن مستاجر',
        ),
      );
    } catch (e) {
      debugPrint(
        'deleteRenter exception: $e',
      );
      rethrow;
    }
  }
}