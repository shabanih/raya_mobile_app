
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

  /// ساخت مسیرهای API با استفاده از base مسیر واحدها.
  ///
  /// ApiConfig.managerUnits باید به manager/units/ ختم شود.
  String _managerPath(String path) {
    final base = ApiConfig.managerUnits.trim();
    final marker = RegExp(r'manager/units/?$');

    if (!marker.hasMatch(base)) {
      throw StateError(
        'آدرس ApiConfig.managerUnits باید به '
            'manager/units/ ختم شود. مقدار فعلی: $base',
      );
    }

    return base.replaceFirst(marker, path);
  }

  /// استخراج شیء اصلی از پاسخ API.
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
      return _unwrapObject(unit, depth: depth + 1);
    }

    final data = _asMap(map['data']);

    if (data != null) {
      return _unwrapObject(data, depth: depth + 1);
    }

    final result = _asMap(map['result']);

    if (result != null) {
      return _unwrapObject(result, depth: depth + 1);
    }

    return map;
  }

  List<Map<String, dynamic>> _convertUnitList(dynamic value) {
    if (value is! List) {
      return [];
    }

    final result = <Map<String, dynamic>>[];

    for (final item in value) {
      final map = _asMap(item);

      if (map != null) {
        debugPrint(
          'UNIT ID: ${map['id']} | '
              'KEYS: ${map.keys.toList()} | '
              'is_active: ${map['is_active']}',
        );

        result.add(map);
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

      final decoded = jsonDecode(body);

      if (decoded is String && decoded.trim().isNotEmpty) {
        return decoded;
      }

      final data = _asMap(decoded);

      if (data != null) {
        for (final key in ['message', 'detail', 'error']) {
          final value = data[key];

          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString();
          }
        }

        final nestedData = _asMap(data['data']);

        if (nestedData != null &&
            nestedData['message'] != null) {
          return nestedData['message'].toString();
        }

        final errors = _asMap(data['errors']);

        if (errors != null) {
          final messages = <String>[];

          errors.forEach((key, value) {
            if (value is List) {
              messages.addAll(
                value.map((item) => item.toString()),
              );
            } else if (value != null) {
              messages.add(value.toString());
            }
          });

          if (messages.isNotEmpty) {
            return messages.join('\n');
          }
        }

        final messages = <String>[];

        data.forEach((key, value) {
          if (value is List) {
            messages.addAll(
              value.map((item) => item.toString()),
            );
          } else if (value != null && value is! Map) {
            messages.add(value.toString());
          }
        });

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }
    } catch (_) {
      // در صورت پاسخ غیر JSON، پیام پیش‌فرض نمایش داده می‌شود.
    }

    return defaultMessage;
  }

  Map<String, dynamic> _decodeObject(
      String body, {
        String defaultMessage = 'پاسخ سرور نامعتبر است.',
      }) {
    if (body.trim().isEmpty) {
      return {'success': true};
    }

    final decoded = jsonDecode(body);
    final map = _asMap(decoded);

    if (map == null) {
      throw Exception(defaultMessage);
    }

    return map;
  }

  Map<String, dynamic> _ensureSuccess(
      String body, {
        String defaultMessage = 'عملیات ناموفق بود.',
      }) {
    final result = _decodeObject(
      body,
      defaultMessage: defaultMessage,
    );

    if (result['success'] == false) {
      throw Exception(
        result['message']?.toString() ?? defaultMessage,
      );
    }

    return result;
  }

  Never _unsupportedDeleteUnit() {
    throw UnsupportedError(
      'حذف واحد از اپ مدیران غیرفعال است. '
          'برای واحد از قابلیت ویرایش استفاده کنید.',
    );
  }

  // ============================================================
  // Units: List
  // ============================================================

  Future<List<Map<String, dynamic>>> getUnits({
    String? search,
    String? residentType,
  }) async {
    try {
      final params = <String, String>{};

      if (search != null && search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }

      if (residentType != null &&
          residentType.trim().isNotEmpty &&
          residentType.trim().toLowerCase() != 'all') {
        params['resident_type'] = residentType.trim().toLowerCase();
      }

      var url = ApiConfig.managerUnits;

      if (params.isNotEmpty) {
        url += '?${Uri(queryParameters: params).query}';
      }

      debugPrint('ManagerUnitService GET: $url');

      final response = await _apiService.get(url);

      debugPrint('getUnits status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(
            response.body,
            'خطا در دریافت فهرست واحدها',
          ),
        );
      }

      if (response.body.trim().isEmpty) {
        return [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return _convertUnitList(decoded);
      }

      final responseMap = _asMap(decoded);

      if (responseMap == null) {
        return [];
      }

      if (responseMap['success'] == false) {
        throw Exception(
          responseMap['message']?.toString() ??
              'دریافت فهرست واحدها ناموفق بود.',
        );
      }

      final data = _asMap(responseMap['data']);

      if (data != null) {
        if (data['results'] is List) {
          return _convertUnitList(data['results']);
        }

        if (data['units'] is List) {
          return _convertUnitList(data['units']);
        }

        if (data['data'] is List) {
          return _convertUnitList(data['data']);
        }
      }

      if (responseMap['results'] is List) {
        return _convertUnitList(responseMap['results']);
      }

      if (responseMap['units'] is List) {
        return _convertUnitList(responseMap['units']);
      }

      if (responseMap['data'] is List) {
        return _convertUnitList(responseMap['data']);
      }

      if (responseMap['result'] is List) {
        return _convertUnitList(responseMap['result']);
      }

      return [];
    } catch (e) {
      debugPrint('getUnits exception: $e');
      rethrow;
    }
  }

  // ============================================================
  // Units: Detail
  // ============================================================

  Future<Map<String, dynamic>> getUnit(int unitId) async {
    try {
      final response = await _apiService.get(
        ApiConfig.managerUnitDetail(unitId),
      );

      debugPrint('getUnit status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(
            response.body,
            'خطا در دریافت اطلاعات واحد',
          ),
        );
      }

      if (response.body.trim().isEmpty) {
        throw Exception('اطلاعات واحد خالی است.');
      }

      final result = _unwrapObject(
        jsonDecode(response.body),
      );

      if (result.isEmpty) {
        throw Exception('اطلاعات واحد پیدا نشد.');
      }

      return result;
    } catch (e) {
      debugPrint('getUnit exception: $e');
      rethrow;
    }
  }

  // ============================================================
  // Units: Create
  // POST /api/manager/units/create/
  // ============================================================

  Future<Map<String, dynamic>> createUnit(
      Map<String, dynamic> data,
      ) async {
    try {
      final url = _managerPath('manager/units/create/');

      debugPrint('createUnit URL: $url');

      final response = await _apiService.post(
        url,
        body: data,
      );

      debugPrint('createUnit status: ${response.statusCode}');
      debugPrint('createUnit body: ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return _ensureSuccess(
          response.body,
          defaultMessage: 'ثبت واحد و مالک ناموفق بود.',
        );
      }

      throw Exception(
        _extractError(
          response.body,
          'خطا در ثبت واحد و مالک',
        ),
      );
    } catch (e) {
      debugPrint('createUnit exception: $e');
      rethrow;
    }
  }

  // ============================================================
  // Units: Update
  // PATCH /api/manager/units/<unit_id>/update/
  // ============================================================

  Future<Map<String, dynamic>> updateUnit(
      int unitId,
      Map<String, dynamic> data,
      ) async {
    try {
      final url = _managerPath(
        'manager/units/$unitId/update/',
      );

      debugPrint('updateUnit URL: $url');

      final response = await _apiService.patch(
        url,
        body: data,
      );

      debugPrint('updateUnit status: ${response.statusCode}');
      debugPrint('updateUnit body: ${response.body}');

      if (response.statusCode == 200) {
        return _ensureSuccess(
          response.body,
          defaultMessage: 'ویرایش واحد ناموفق بود.',
        );
      }

      throw Exception(
        _extractError(
          response.body,
          'خطا در ویرایش واحد و مالک',
        ),
      );
    } catch (e) {
      debugPrint('updateUnit exception: $e');
      rethrow;
    }
  }

  // حذف واحد عمداً غیرفعال است.
  // این متد فقط برای جلوگیری از خطای کامپایل صفحات قدیمی نگه داشته شده.
  // پس از حذف دکمه و فراخوانی حذف از صفحه، می‌توان این متد را هم حذف کرد.
  Future<Map<String, dynamic>> deleteUnit(int unitId) async {
    _unsupportedDeleteUnit();
  }

  // ============================================================
  // Owner: Get
  // ============================================================

  Future<Map<String, dynamic>?> getOwner(int unitId) async {
    try {
      final response = await _apiService.get(
        ApiConfig.managerUnitOwner(unitId),
      );

      debugPrint('getOwner status: ${response.statusCode}');

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

      final result = _unwrapObject(
        jsonDecode(response.body),
      );

      return result.isEmpty ? null : result;
    } catch (e) {
      debugPrint('getOwner exception: $e');
      rethrow;
    }
  }

  // ============================================================
  // Owner: Create
  // ============================================================

  Future<Map<String, dynamic>> createOwner(
      int unitId,
      Map<String, dynamic> data,
      ) async {
    try {
      final response = await _apiService.post(
        ApiConfig.managerUnitOwner(unitId),
        body: data,
      );

      debugPrint('createOwner status: ${response.statusCode}');

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return _ensureSuccess(
          response.body,
          defaultMessage: 'ثبت مالک ناموفق بود.',
        );
      }

      throw Exception(
        _extractError(
          response.body,
          'خطا در ثبت مالک',
        ),
      );
    } catch (e) {
      debugPrint('createOwner exception: $e');
      rethrow;
    }
  }

  // ============================================================
  // Owner: Update
  // ============================================================

  Future<Map<String, dynamic>> updateOwner(
      int unitId,
      Map<String, dynamic> data,
      ) async {
    try {
      final response = await _apiService.patch(
        ApiConfig.managerUnitOwner(unitId),
        body: data,
      );

      debugPrint('updateOwner status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return _ensureSuccess(
          response.body,
          defaultMessage: 'ویرایش مالک ناموفق بود.',
        );
      }

      throw Exception(
        _extractError(
          response.body,
          'خطا در ویرایش مالک',
        ),
      );
    } catch (e) {
      debugPrint('updateOwner exception: $e');
      rethrow;
    }
  }

// ============================================================
// Unit: Activate / Deactivate
// POST /api/manager/units/<unit_id>/status/
//
// فعال یا غیرفعال کردن خود واحد
// بدون حذف مالک، مستأجر یا سوابق مالی
// ============================================================

  Future<Map<String, dynamic>> updateUnitStatus(
      int unitId,
      bool isActive,
      ) async {
    try {
      final response = await _apiService.post(
        ApiConfig.managerUnitStatus(unitId),
        body: <String, dynamic>{
          'is_active': isActive,
        },
      );

      debugPrint(
        'updateUnitStatus status: ${response.statusCode}',
      );
      debugPrint(
        'updateUnitStatus body: ${response.body}',
      );

      if (response.statusCode == 200 ||
          response.statusCode == 202) {
        return _ensureSuccess(
          response.body,
          defaultMessage: isActive
              ? 'واحد با موفقیت فعال شد.'
              : 'واحد با موفقیت غیرفعال شد.',
        );
      }

      throw Exception(
        _extractError(
          response.body,
          'خطا در تغییر وضعیت واحد',
        ),
      );
    } catch (e) {
      debugPrint('updateUnitStatus exception: $e');
      rethrow;
    }
  }



  // ============================================================
  // Renter: Get active renter / renter list
  // GET /api/manager/units/<unit_id>/renters/
  // ============================================================

  Future<Map<String, dynamic>?> getRenter(int unitId) async {
    try {
      final url = ApiConfig.managerUnitRenters(unitId);
      final response = await _apiService.get(url);

      debugPrint('getRenter status: ${response.statusCode}');

      if (response.statusCode == 404) {
        return null;
      }

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(
            response.body,
            'خطا در دریافت اطلاعات مستأجر',
          ),
        );
      }

      if (response.body.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      final responseMap = _asMap(decoded);

      if (responseMap == null) {
        if (decoded is List) {
          for (final item in decoded) {
            final renter = _asMap(item);

            if (renter != null &&
                renter['renter_is_active'] == true &&
                renter['is_deleted'] != true) {
              return renter;
            }
          }
        }

        return null;
      }

      if (responseMap['success'] == false) {
        throw Exception(
          responseMap['message']?.toString() ??
              'دریافت اطلاعات مستأجر ناموفق بود.',
        );
      }

      final data = _asMap(responseMap['data']) ?? responseMap;
      final activeRenter = _asMap(data['active_renter']);

      if (activeRenter != null &&
          activeRenter['is_deleted'] != true) {
        return activeRenter;
      }

      final renter = _asMap(data['renter']);

      if (renter != null &&
          renter['is_deleted'] != true) {
        return renter;
      }

      final renters = data['renters'];

      if (renters is List) {
        for (final item in renters) {
          final current = _asMap(item);

          if (current != null &&
              current['renter_is_active'] == true &&
              current['is_deleted'] != true) {
            return current;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('getRenter exception: $e');
      rethrow;
    }
  }

  // ============================================================
  // Renter: Get all renters of a unit
  // GET /api/manager/units/<unit_id>/renters/
  // شامل مستأجر فعال و سوابق مستأجران غیرفعال
  // ============================================================

  Future<List<Map<String, dynamic>>> getRenters(int unitId) async {
    try {
      final url = ApiConfig.managerUnitRenters(unitId);
      final response = await _apiService.get(url);

      debugPrint('getRenters status: ${response.statusCode}');
      debugPrint('getRenters body: ${response.body}');

      if (response.statusCode == 404) {
        return [];
      }

      if (response.statusCode != 200) {
        throw Exception(
          _extractError(
            response.body,
            'خطا در دریافت فهرست مستأجران',
          ),
        );
      }

      if (response.body.trim().isEmpty) {
        return [];
      }

      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map(_asMap)
            .whereType<Map<String, dynamic>>()
            .where((renter) => renter['is_deleted'] != true)
            .toList();
      }

      final responseMap = _asMap(decoded);

      if (responseMap == null) {
        return [];
      }

      if (responseMap['success'] == false) {
        throw Exception(
          responseMap['message']?.toString() ??
              'دریافت فهرست مستأجران ناموفق بود.',
        );
      }

      final data = _asMap(responseMap['data']) ?? responseMap;

      final renters = data['renters'];

      if (renters is List) {
        return renters
            .map(_asMap)
            .whereType<Map<String, dynamic>>()
            .where((renter) => renter['is_deleted'] != true)
            .toList();
      }

      final activeRenter = _asMap(data['active_renter']);

      if (activeRenter != null &&
          activeRenter['is_deleted'] != true) {
        return [activeRenter];
      }

      final renter = _asMap(data['renter']);

      if (renter != null && renter['is_deleted'] != true) {
        return [renter];
      }

      return [];
    } catch (e) {
      debugPrint('getRenters exception: $e');
      rethrow;
    }
  }


  // ============================================================
  // Renter: Create
  // POST /api/manager/units/<unit_id>/renters/
  // ============================================================

  Future<Map<String, dynamic>> createRenter(
      int unitId,
      Map<String, dynamic> data,
      ) async {
    try {
      final url = ApiConfig.managerUnitRenters(unitId);

      debugPrint('createRenter URL: $url');
      debugPrint('createRenter data: $data');

      final response = await _apiService.post(
        url,
        body: data,
      );

      debugPrint('createRenter status: ${response.statusCode}');
      debugPrint('createRenter body: ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        return _ensureSuccess(
          response.body,
          defaultMessage: 'ثبت مستأجر ناموفق بود.',
        );
      }

      throw Exception(
        _extractError(
          response.body,
          'خطا در ثبت مستأجر',
        ),
      );
    } catch (e) {
      debugPrint('createRenter exception: $e');
      rethrow;
    }
  }

  // ============================================================
  // Renter: Update active renter
  // PATCH /api/manager/renters/<renter_id>/update/
  // ============================================================

  Future<Map<String, dynamic>> updateRenter(
      int unitId,
      int renterId,
      Map<String, dynamic> data,
      ) async {
    try {
      // unitId برای حفظ سازگاری صفحات قبلی نگه داشته شده است.
      final url = _managerPath(
        'manager/renters/$renterId/update/',
      );

      debugPrint('updateRenter URL: $url');
      debugPrint('updateRenter data: $data');

      final response = await _apiService.patch(
        url,
        body: data,
      );

      debugPrint('updateRenter status: ${response.statusCode}');
      debugPrint('updateRenter body: ${response.body}');

      if (response.statusCode == 200) {
        return _ensureSuccess(
          response.body,
          defaultMessage: 'ویرایش مستأجر ناموفق بود.',
        );
      }

      throw Exception(
        _extractError(
          response.body,
          'خطا در ویرایش مستأجر',
        ),
      );
    } catch (e) {
      debugPrint('updateRenter exception: $e');
      rethrow;
    }
  }

  // ============================================================
  // Renter: Activate
  // PATCH /api/manager/renters/<renter_id>/activate/
  // ============================================================

  Future<Map<String, dynamic>> activateRenter(
      int renterId,
      ) async {
    try {
      final url = _managerPath(
        'manager/renters/$renterId/activate/',
      );

      debugPrint('activateRenter URL: $url');

      final response = await _apiService.patch(
        url,
        body: <String, dynamic>{},
      );

      debugPrint(
        'activateRenter status: ${response.statusCode}',
      );
      debugPrint(
        'activateRenter body: ${response.body}',
      );

      if (response.statusCode == 200 ||
          response.statusCode == 202) {
        return _ensureSuccess(
          response.body,
          defaultMessage: 'فعال‌سازی مستأجر ناموفق بود.',
        );
      }

      throw Exception(
        _extractError(
          response.body,
          'خطا در فعال‌سازی مستأجر',
        ),
      );
    } catch (e) {
      debugPrint('activateRenter exception: $e');
      rethrow;
    }
  }

  // ============================================================
  // Renter: Deactivate
  // PATCH /api/manager/renters/<renter_id>/deactivate/
  // ============================================================

  Future<Map<String, dynamic>> deactivateRenter(
      int renterId,
      ) async {
    try {
      final url = _managerPath(
        'manager/renters/$renterId/deactivate/',
      );

      final response = await _apiService.patch(
        url,
        body: <String, dynamic>{},
      );

      debugPrint('deactivateRenter status: ${response.statusCode}');
      debugPrint('deactivateRenter body: ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 202 ||
          response.statusCode == 204) {
        return _ensureSuccess(
          response.body,
          defaultMessage: 'غیرفعال‌سازی مستأجر ناموفق بود.',
        );
      }

      throw Exception(
        _extractError(
          response.body,
          'خطا در غیرفعال‌سازی مستأجر',
        ),
      );
    } catch (e) {
      debugPrint('deactivateRenter exception: $e');
      rethrow;
    }
  }

  // ============================================================
  // Renter: Soft Delete
  // DELETE /api/manager/renters/<renter_id>/delete/
  // ============================================================

  Future<Map<String, dynamic>> deleteRenter(
      int unitId,
      int renterId,
      ) async {
    try {
      // unitId برای سازگاری با صفحه حفظ شده است.
      final url = _managerPath(
        'manager/renters/$renterId/delete/',
      );

      final response = await _apiService.delete(url);

      debugPrint('deleteRenter status: ${response.statusCode}');
      debugPrint('deleteRenter body: ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 202 ||
          response.statusCode == 204) {
        return _ensureSuccess(
          response.body,
          defaultMessage: 'حذف مستأجر ناموفق بود.',
        );
      }

      throw Exception(
        _extractError(
          response.body,
          'خطا در حذف مستأجر',
        ),
      );
    } catch (e) {
      debugPrint('deleteRenter exception: $e');
      rethrow;
    }
  }
}