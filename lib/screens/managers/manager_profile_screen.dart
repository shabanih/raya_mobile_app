
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/app_version_service.dart';
import 'manager_suggestion_screen.dart';

class ManagerProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String fullName;
  final String houseName;
  final Map<String, dynamic>? subscriptionData;
  final bool isSubscriptionLoading;
  final String? subscriptionError;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLogout;

  const ManagerProfileScreen({
    super.key,
    required this.user,
    required this.fullName,
    required this.houseName,
    required this.subscriptionData,
    required this.isSubscriptionLoading,
    required this.subscriptionError,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  State<ManagerProfileScreen> createState() =>
      _ManagerProfileScreenState();
}

class _ManagerProfileScreenState
    extends State<ManagerProfileScreen> {
  final AppVersionService _versionService = AppVersionService();

  Map<String, dynamic>? _versionInfo;
  bool _checkingVersion = true;

  static const Color primaryColor = Color(0xFF00ACC1);
  static const Color secondaryColor = Color(0xFF610DB5);
  static const Color textColor = Color(0xFF263238);
  static const Color mutedColor = Color(0xFF78909C);

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  // =====================================================
  // تبدیل اعداد به فارسی
  // =====================================================

  String toPersianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    for (int i = 0; i < 10; i++) {
      value = value.replaceAll(english[i], persian[i]);
    }

    return value;
  }

  String _toEnglishDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';

    for (int i = 0; i < 10; i++) {
      value = value.replaceAll(persian[i], '$i');
      value = value.replaceAll(arabic[i], '$i');
    }

    return value;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(
      _toEnglishDigits(value?.toString() ?? ''),
    ) ??
        0;
  }

  // =====================================================
  // تبدیل تاریخ میلادی به شمسی
  // =====================================================

  String _formatJalaliDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '-';
    }

    try {
      final raw = _toEnglishDigits(value.toString().trim());

      final match = RegExp(
        r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})',
      ).firstMatch(raw);

      if (match == null) {
        return toPersianDigits(raw);
      }

      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);

      // تاریخ شمسی را دوباره تبدیل نکن
      if (year >= 1300 && year < 1500) {
        return toPersianDigits(
          '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}',
        );
      }

      final date = DateTime(year, month, day);
      final jalali = Gregorian.fromDateTime(date).toJalali();

      return toPersianDigits(
        '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}',
      );
    } catch (_) {
      return toPersianDigits(value.toString());
    }
  }

  // =====================================================
  // بررسی نسخه
  // =====================================================

  Future<void> _checkVersion() async {
    try {
      final result = await _versionService.checkUpdate();

      debugPrint('PROFILE VERSION INFO: $result');
      debugPrint('PROFILE HAS UPDATE: ${result['has_update']}');

      if (!mounted) return;

      setState(() {
        _versionInfo = result;
        _checkingVersion = false;
      });
    } catch (e) {
      debugPrint('VERSION ERROR: $e');

      if (!mounted) return;

      setState(() {
        _versionInfo = null;
        _checkingVersion = false;
      });
    }
  }

  Future<void> _openDownload() async {
    final url = _versionInfo?['download_url']?.toString() ?? '';

    if (url.isEmpty) {
      _showMessage('لینک دانلود موجود نیست.');
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      _showMessage('لینک دانلود معتبر نیست.');
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _showMessage('امکان بازکردن لینک دانلود وجود ندارد.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('خطا در بازکردن لینک دانلود.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =====================================================
  // اطلاعات اشتراک
  // =====================================================

  void _showSubscription() {
    if (widget.isSubscriptionLoading) {
      showModalBottomSheet(
        context: context,
        builder: (_) => const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(35),
            child: Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            ),
          ),
        ),
      );
      return;
    }

    final data = widget.subscriptionData;

    if (data == null) {
      _showMessage(
        widget.subscriptionError ??
            'اطلاعات اشتراک دریافت نشده است.',
      );
      return;
    }

    if (data['has_subscription'] != true) {
      _showMessage(
        'برای این ساختمان اشتراک فعالی ثبت نشده است.',
      );
      return;
    }

    final dynamic subscriptionValue = data['subscription'];

    if (subscriptionValue is! Map) {
      _showMessage('اطلاعات اشتراک قابل دریافت نیست.');
      return;
    }

    final Map<String, dynamic> subscription =
    Map<String, dynamic>.from(subscriptionValue);

    final dynamic planValue = subscription['plan'];

    final Map<String, dynamic> plan = planValue is Map
        ? Map<String, dynamic>.from(planValue)
        : {};

    final int remainingDays =
    _toInt(subscription['days_remaining']);

    final int totalDays =
    _toInt(subscription['total_days']);

    final double progress = totalDays > 0
        ? (remainingDays / totalDays).clamp(0.0, 1.0)
        : 0.0;

    final bool expired = remainingDays <= 0;

    final Color progressColor = expired
        ? Colors.red
        : remainingDays <= 7
        ? Colors.orange
        : secondaryColor;

    final int duration = _toInt(plan['duration']);

    String planTitle;

    switch (duration) {
      case 3:
        planTitle = 'اشتراک سه‌ماهه';
        break;
      case 6:
        planTitle = 'اشتراک شش‌ماهه';
        break;
      case 12:
        planTitle = 'اشتراک یک‌ساله';
        break;
      case 24:
        planTitle = 'اشتراک دوساله';
        break;
      default:
        planTitle = duration > 0
            ? 'اشتراک ${toPersianDigits(duration.toString())} ماهه'
            : 'اشتراک';
    }

    final String startDate =
    _formatJalaliDate(subscription['start_date']);

    final String endDate =
    _formatJalaliDate(subscription['end_date']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            constraints: BoxConstraints(
              maxHeight:
              MediaQuery.of(context).size.height * 0.9,
            ),
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'اطلاعات اشتراک',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          planTitle,
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Center(
                      child: SizedBox(
                        width: 165,
                        height: 165,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 165,
                              height: 165,
                              child: CircularProgressIndicator(
                                value: 1,
                                strokeWidth: 18,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                  Colors.grey.shade200,
                                ),
                              ),
                            ),

                            SizedBox(
                              width: 165,
                              height: 165,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 18,
                                strokeCap: StrokeCap.round,
                                backgroundColor: Colors.transparent,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(
                                  progressColor,
                                ),
                              ),
                            ),

                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  toPersianDigits(
                                    remainingDays.toString(),
                                  ),
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: progressColor,
                                  ),
                                ),

                                Container(
                                  width: 50,
                                  height: 2,
                                  margin:
                                  const EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                  color: Colors.grey.shade300,
                                ),

                                Text(
                                  toPersianDigits(
                                    totalDays.toString(),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff546E7A),
                                  ),
                                ),

                                const Text(
                                  'روز',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: mutedColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 13),

                    Text(
                      expired
                          ? 'اشتراک به پایان رسیده است'
                          : 'روز باقی‌مانده از اشتراک',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: progressColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 22),

                    Divider(color: Colors.grey.shade200),

                    _infoRow('تاریخ شروع', startDate),
                    _infoRow('تاریخ پایان', endDate),
                    _infoRow(
                      'وضعیت اشتراک',
                      subscription['status_label']?.toString() ?? '-',
                    ),
                    _infoRow(
                      'تعداد واحدها',
                      toPersianDigits(
                        (subscription['units_count'] ?? 0).toString(),
                      ),
                    ),

                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: mutedColor,
                fontSize: 13,
              ),
            ),
          ),
          Flexible(
            child: Text(
              toPersianDigits(value),
              textAlign: TextAlign.left,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // پیشنهاد و درباره ما
  // =====================================================

  void _openSuggestion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerSuggestionScreen(
          fullName: widget.fullName,
          mobile: widget.user['mobile']?.toString() ?? '',
        ),
      ),
    );
  }

  void _openAbout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ManagerAboutScreen(),
      ),
    );
  }

  // =====================================================
  // کارت عمومی پروفایل
  // =====================================================

  Widget _profileCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color? iconColor,
    Widget? trailing,
  }) {
    final Color color = iconColor ?? primaryColor;

    return Card(
      elevation: 2,
      shadowColor: color.withOpacity(0.09),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(
          color: color.withOpacity(0.09),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 16,
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),

                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        toPersianDigits(subtitle),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xff90A4AE),
                    size: 23,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // کارت بروزرسانی
  // =====================================================

  Widget _buildUpdateCard() {
    if (_checkingVersion ||
        _versionInfo == null ||
        _versionInfo!['has_update'] != true) {
      return const SizedBox.shrink();
    }

    final current = toPersianDigits(
      _versionInfo!['installed_version']?.toString() ?? '',
    );

    final latest = toPersianDigits(
      _versionInfo!['version']?.toString() ?? '',
    );

    final forceUpdate = _versionInfo!['force_update'] == true;
    final releaseNotes =
        _versionInfo!['release_notes']?.toString().trim() ?? '';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFEAF5FF),
            Color(0xFFD9ECFF),
            Color(0xFFF3F9FF),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFB8D9FF),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: _openDownload,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان کارت
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.system_update_alt_rounded,
                          color: Colors.white,
                          size: 23,
                        ),
                      ),

                      const SizedBox(width: 11),

                      const Expanded(
                        child: Text(
                          'به‌روزرسانی رایا شارژ',
                          style: TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF123D73),
                          ),
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          forceUpdate ? 'ضروری' : 'نسخه جدید',
                          style: const TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 17),

                  // اطلاعات نسخه
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'نسخه جدید آماده دریافت است',
                              style: TextStyle(
                                fontFamily: 'Vazir',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF174A85),
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              children: [
                                const Text(
                                  'نسخه فعلی: ',
                                  style: TextStyle(
                                    fontFamily: 'Vazir',
                                    fontSize: 11,
                                    color: Color(0xFF647B96),
                                  ),
                                ),
                                Text(
                                  current,
                                  style: const TextStyle(
                                    fontFamily: 'Vazir',
                                    fontSize: 11,
                                    color: Color(0xFF647B96),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // شماره نسخه جدید
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF42A5F5),
                              Color(0xFF1565C0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1976D2)
                                  .withOpacity(0.22),
                              blurRadius: 9,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'نسخه جدید',
                              style: TextStyle(
                                fontFamily: 'Vazir',
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              latest,
                              style: const TextStyle(
                                fontFamily: 'Vazir',
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // توضیحات و دکمه
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF1976D2),
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _versionInfo!['release_notes']?.toString().trim().isNotEmpty == true
                                ? _versionInfo!['release_notes'].toString().trim()
                                : 'به‌روزرسانی جدید رایا شارژ آماده دریافت است.',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: 'Vazir',
                              fontSize: 11,
                              color: Color(0xFF45617F),
                              height: 1.9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // دکمه دریافت
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1976D2),
                          Color(0xFF0D47A1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 9),
                        Text(
                          'دریافت و به‌روزرسانی',
                          style: TextStyle(
                            fontFamily: 'Vazir',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // صفحه اصلی پروفایل
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final mobile = widget.user['mobile']?.toString() ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        onRefresh: () async {
          await widget.onRefresh();
          await _checkVersion();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 25),
          children: [
            // اطلاعات مدیر
            // اطلاعات مدیر و ساختمان
            Card(
              elevation: 2,
              shadowColor: primaryColor.withOpacity(0.10),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.07),
                      secondaryColor.withOpacity(0.04),
                    ],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // نام و شماره همراه مدیر
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        CircleAvatar(
                          radius: 23,
                          backgroundColor: primaryColor.withOpacity(0.13),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: primaryColor,
                            size: 27,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            widget.fullName,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                        ),

                        Text(
                          toPersianDigits(mobile),
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Divider(
                      height: 1,
                      color: primaryColor.withOpacity(0.12),
                    ),

                    const SizedBox(height: 14),

                    // نام ساختمان
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: secondaryColor.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.apartment_rounded,
                            color: secondaryColor,
                            size: 23,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ساختمان تحت مدیریت',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: mutedColor,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                widget.houseName.isNotEmpty
                                    ? widget.houseName
                                    : '-',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // بروزرسانی
            _buildUpdateCard(),

            // اشتراک
            _profileCard(
              icon: Icons.credit_card_outlined,
              title: 'مشاهده اطلاعات اشتراک',
              onTap: _showSubscription,
              subtitle: widget.isSubscriptionLoading
                  ? 'در حال دریافت اطلاعات...'
                  : null,
              trailing: widget.isSubscriptionLoading
                  ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryColor,
                ),
              )
                  : null,
            ),

            // پیشنهاد
            _profileCard(
              icon: Icons.message_outlined,
              title: 'ارسال پیشنهاد',
              onTap: _openSuggestion,
              iconColor: secondaryColor,
            ),

            // درباره ما
            _profileCard(
              icon: Icons.info_outline,
              title: 'درباره ما',
              onTap: _openAbout,
            ),

            // خروج
            _profileCard(
              icon: Icons.logout,
              title: 'خروج از حساب کاربری',
              iconColor: Colors.red,
              onTap: () => widget.onLogout(),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// درباره ما
// =====================================================

class ManagerAboutScreen extends StatelessWidget {
  const ManagerAboutScreen({super.key});

  @override

  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(
          toolbarHeight: 88,
          title: const Text(
            'درباره رایا شارژ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF263238),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const SizedBox(height: 15),

              Container(
                width: 110,
                height: 110,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/splash_logo.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'رایا شارژ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'مدیریت هوشمند ساختمان‌ها و مجتمع‌های مسکونی',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.035),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // const Row(
                    //   children: [
                    //     Icon(
                    //       Icons.info_outline_rounded,
                    //       color: Color(0xFF00ACC1),
                    //       size: 23,
                    //     ),
                    //     SizedBox(width: 9),
                    //     // Text(
                    //     //   'معرفی رایا شارژ',
                    //     //   style: TextStyle(
                    //     //     fontSize: 16,
                    //     //     fontWeight: FontWeight.bold,
                    //     //     color: Color(0xFF263238),
                    //     //   ),
                    //     // ),
                    //   ],
                    // ),

                    // const SizedBox(height: 17),

                    const Text(
                      'رایا شارژ یک سامانه جامع برای مدیریت ساختمان‌ها، مجتمع‌های مسکونی و شهرک‌ها است که تمامی نیازهای مدیران و ساکنین را در یک بستر یکپارچه فراهم می‌کند. با استفاده از این سامانه می‌توانید شارژ ساختمان را محاسبه و ثبت کنید، درآمدها و هزینه‌ها را مدیریت نمایید و گزارش‌های مالی دقیق دریافت کنید.\n\n'
                          'از امکانات رایا شارژ می‌توان به ارسال اعلان و پیامک شارژ، تابلو اعلانات، سیستم تیکت و درخواست‌ها، مدیریت اموال و تعمیرات، گزارش‌گیری حرفه‌ای و ایجاد درگاه پرداخت اختصاصی مجتمع اشاره کرد. هدف ما ایجاد شفافیت مالی، کاهش هزینه‌های مدیریتی و تسهیل ارتباط میان مدیران و ساکنین است.',
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontSize: 14,
                        height: 2.1,
                        color: Color(0xFF455A64),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE0F7FA),
                      Color(0xFFF3E5F5),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFF610DB5),
                      size: 30,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'مدیریت آسان‌تر، شفافیت بیشتر، ارتباط بهتر',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF37474F),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

}
