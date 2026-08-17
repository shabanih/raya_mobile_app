import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class AnnouncementService {
  static const String _lastSeenAnnouncementIdKey =
      'last_seen_announcement_id';

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
  // بررسی وجود اطلاعیه جدید
  // =====================================================

  static Future<bool> hasNewAnnouncements() async {
    final announcements =
    await getAnnouncements();

    if (announcements.isEmpty) {
      return false;
    }

    final latestId =
    announcements.first['id'];

    if (latestId == null) {
      return false;
    }

    final prefs =
    await SharedPreferences.getInstance();

    final lastSeenId =
    prefs.getInt(
      _lastSeenAnnouncementIdKey,
    );

    // اولین بار ورود به برنامه
    if (lastSeenId == null) {
      return true;
    }

    return latestId > lastSeenId;
  }

  // =====================================================
  // اطلاعیه‌ها دیده شدند
  // =====================================================

  static Future<void> markAsRead(
      List<Map<String, dynamic>> announcements,
      ) async {
    if (announcements.isEmpty) {
      return;
    }

    final latestId =
    announcements.first['id'];

    if (latestId == null) {
      return;
    }

    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setInt(
      _lastSeenAnnouncementIdKey,
      latestId,
    );
  }

  // =====================================================
  // پاک کردن وضعیت اطلاعیه‌ها
  //
  // هنگام Logout استفاده می‌شود
  // =====================================================

  static Future<void> clearReadStatus() async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.remove(
      _lastSeenAnnouncementIdKey,
    );
  }
}