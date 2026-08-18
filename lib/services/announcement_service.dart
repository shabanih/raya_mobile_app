import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class AnnouncementService {
  // =====================================================
  // کلید مخصوص هر کاربر
  // =====================================================

  static String _lastSeenAnnouncementIdKey(int userId) {
    return 'last_seen_announcement_id_user_$userId';
  }

  // =====================================================
  // دریافت 5 اطلاعیه آخر
  // =====================================================

  static Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final accessToken =
    await TokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('توکن ورود پیدا نشد.');
    }

    final response = await http.get(
      Uri.parse(ApiConfig.announcements),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );

      final List<dynamic> announcements =
          data['announcements'] ?? [];

      return announcements
          .take(5)
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList();
    }

    if (response.statusCode == 401) {
      throw Exception(
        'نشست کاربر منقضی شده است.',
      );
    }

    throw Exception(
      'خطا در دریافت اطلاعیه‌ها: ${response.statusCode}',
    );
  }

  // =====================================================
  // بررسی وجود اطلاعیه جدید برای کاربر مشخص
  // =====================================================

  static Future<bool> hasNewAnnouncements(
      int userId,
      ) async {
    final announcements =
    await getAnnouncements();

    if (announcements.isEmpty) {
      return false;
    }

    final latestId =
    int.tryParse(
      announcements.first['id']?.toString() ?? '',
    );

    if (latestId == null) {
      return false;
    }

    final prefs =
    await SharedPreferences.getInstance();

    final lastSeenId =
    prefs.getInt(
      _lastSeenAnnouncementIdKey(userId),
    );

    // اولین بار این کاربر اطلاعیه‌ها را بررسی می‌کند
    if (lastSeenId == null) {
      return true;
    }

    return latestId > lastSeenId;
  }

  // =====================================================
  // اطلاعیه‌ها دیده شدند
  // فقط برای همین کاربر
  // =====================================================

  static Future<void> markAsRead(
      int userId,
      List<Map<String, dynamic>> announcements,
      ) async {
    if (announcements.isEmpty) {
      return;
    }

    final latestId =
    int.tryParse(
      announcements.first['id']?.toString() ?? '',
    );

    if (latestId == null) {
      return;
    }

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setInt(
      _lastSeenAnnouncementIdKey(userId),
      latestId,
    );
  }

  // =====================================================
  // پاک کردن وضعیت اطلاعیه‌های همین کاربر
  // =====================================================

  static Future<void> clearReadStatus(
      int userId,
      ) async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.remove(
      _lastSeenAnnouncementIdKey(userId),
    );
  }
}