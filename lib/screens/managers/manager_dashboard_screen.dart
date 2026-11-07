import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../services/api_service.dart';
import '../../services/announcement_service.dart';
import '../../services/manager_support_service.dart';
import '../../services/manager_admin_support_service.dart';
import '../../services/manager_admin_message_service.dart';
import '../../services/manager_pending_payments_service.dart';
import '../../storage/token_storage.dart';

import '../announcements_screen.dart';
import '../login_screen.dart';
import '../messages_screen.dart';

import 'manager_announcements_screen.dart';
import 'manager_messages_screen.dart';
import 'manager_admin_messages_screen.dart';
import 'manager_banks_screen.dart';
import 'manager_polls_screen.dart';
import 'manager_support_tickets_screen.dart';
import 'manager_admin_support_tickets_screen.dart';
import 'manager_units_screen.dart';
import 'manager_charges_screen.dart';
import 'manager_operations_screen.dart';
import 'manager_reports_screen.dart';
import 'manager_admin_fund_screen.dart';
import 'manager_pending_payments_screen.dart';
import 'manager_profile_screen.dart';


// =====================================================
// صفحه اصلی مدیران
// =====================================================

class ManagerDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const ManagerDashboardScreen({
    super.key,
    required this.data,
  });

  @override
  State<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

// =====================================================
// State
// =====================================================

class _ManagerDashboardScreenState
    extends State<ManagerDashboardScreen> {

  // -----------------------------------------------------
  // Navigation
  // -----------------------------------------------------

  int currentIndex = 2;

  // -----------------------------------------------------
  // وضعیت پیام‌ها و اطلاعیه‌ها
  // -----------------------------------------------------

  bool hasNewAdminMessages = false;
  bool hasNewAnnouncements = false;
  bool hasNewMessages = false;

  int unreadAdminMessageCount = 0;
  int unreadMessageCount = 0;

  bool isLoadingAdminMessageStatus = false;
  bool isLoadingMessageStatus = false;

  bool isDashboardLoading = true;
  bool _adminMessagesPageOpened = false;

  // =====================================================
  // مدیریت تیکت‌ها
  // ساکن ← مدیر ساختمان
  // =====================================================

  int unreadTicketCount = 0;

  // =====================================================
  // پشتیبانی
  // مدیر ساختمان ← ادمین سامانه
  // =====================================================

  int unreadAdminSupportTicketCount = 0;

  // -----------------------------------------------------
  // Dashboard
  // -----------------------------------------------------

  Map<String, dynamic>? dashboardData;

  // -----------------------------------------------------
  // اطلاعیه
  // -----------------------------------------------------

  List<Map<String, dynamic>> announcements = [];

  PageController? _announcementController;
  Timer? _announcementTimer;
  int _announcementIndex = 0;

  // -----------------------------------------------------
  // اسلایدر آمار
  // -----------------------------------------------------

  late final PageController _statisticsController;

  Timer? _statisticsTimer;
  int _statisticsIndex = 0;

  // =====================================================
// پرداخت‌های در انتظار تأیید
// =====================================================

  int pendingPaymentCount = 0;
  bool isLoadingPendingPayments = false;

  // =====================================================
  // Init
  // =====================================================

  @override
  void initState() {
    super.initState();

    _statisticsController = PageController(
      viewportFraction: 1.0,
    );

    loadManagerDashboard();
    loadAnnouncementData();

    // پیام‌های مدیران ساختمان
    loadMessageStatus();

    // پیام‌های مدیریت سامانه به مدیر ساختمان
    loadAdminMessageStatus();

    // مدیریت تیکت‌ها
    loadSupportTicketStatus();

    // پشتیبانی مدیر ← ادمین
    loadAdminSupportTicketStatus();

    loadManagerSubscription();

    loadPendingPaymentStatus();

    _startStatisticsSlider();
  }

  // =====================================================
  // Dispose
  // =====================================================

  @override
  void dispose() {
    _announcementTimer?.cancel();
    _announcementController?.dispose();

    _statisticsTimer?.cancel();
    _statisticsController.dispose();

    super.dispose();
  }

  // =====================================================
  // اطلاعات کاربر
  // =====================================================

  Map<String, dynamic> get user {
    final dashboardUser = dashboardData?['user'];

    if (dashboardUser is Map) {
      return Map<String, dynamic>.from(dashboardUser);
    }

    final initialUser = widget.data['user'];

    if (initialUser is Map) {
      return Map<String, dynamic>.from(initialUser);
    }

    return {};
  }

  // =====================================================
  // اطلاعات ساختمان
  // =====================================================

  Map<String, dynamic> get house {
    final dashboardHouse = dashboardData?['house'];

    if (dashboardHouse is Map) {
      return Map<String, dynamic>.from(dashboardHouse);
    }

    final initialHouse = widget.data['house'];

    if (initialHouse is Map) {
      return Map<String, dynamic>.from(initialHouse);
    }

    return {};
  }

  // =====================================================
  // نام مدیر
  // =====================================================

  String get fullName {
    final name = user['full_name']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return 'مدیر';
  }

  // =====================================================
  // نام ساختمان
  // =====================================================

  String get houseName {
    final name = house['name']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return '-';
  }

  // =====================================================
  // آمار داشبورد
  // =====================================================

  Map<String, dynamic> get statistics {
    final value = dashboardData?['statistics'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }
  // =====================================================
// اطلاعات اشتراک مدیر
// =====================================================

  Map<String, dynamic>? subscriptionData;

  bool isSubscriptionLoading = false;
  String? subscriptionError;

  // =====================================================
  // مقدار آماری
  // =====================================================

  dynamic _dashboardValue(String key) {
    return statistics[key];
  }

  // =====================================================
  // تبدیل مقدار به int
  // =====================================================

  int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ?? 0;
  }

  // =====================================================
// دریافت تعداد پرداخت‌های در انتظار تأیید
// =====================================================

  Future<void> loadPendingPaymentStatus() async {
    if (isLoadingPendingPayments) return;

    isLoadingPendingPayments = true;

    try {
      final service = ManagerPendingPaymentsService(
        apiService: ApiService(),
      );

      final count = await service.getPendingPaymentsCount();

      if (!mounted) return;

      setState(() {
        pendingPaymentCount = count;
      });

      debugPrint('PENDING PAYMENT COUNT: $pendingPaymentCount');
    } catch (e, stackTrace) {
      debugPrint('PENDING PAYMENT STATUS ERROR: $e');
      debugPrint(stackTrace.toString());
    } finally {
      isLoadingPendingPayments = false;
    }
  }



  // =====================================================
  // موجودی صندوق
  // =====================================================

  int get cashBalance {
    return _toInt(_dashboardValue('fund_balance'));
  }

  // =====================================================
  // تعداد واحدها
  // =====================================================

  int get unitCount {
    return _toInt(_dashboardValue('units_count'));
  }

  // =====================================================
  // شارژهای پرداخت‌نشده
  // =====================================================

  int get unpaidCharges {
    return _toInt(_dashboardValue('unpaid_charges'));
  }

  // =====================================================
  // اعتبار حساب پیامکی
  // =====================================================

  int get smsBalance {
    return _toInt(_dashboardValue('sms_credit'));
  }

  // =====================================================
  // داشبورد مدیر
  // =====================================================

  Future<void> loadManagerDashboard() async {
    try {
      debugPrint('==========================================');
      debugPrint('START LOAD MANAGER DASHBOARD');

      final result = await ApiService().getManagerDashboard();

      debugPrint('MANAGER DASHBOARD RESULT:');
      debugPrint(result.toString());
      debugPrint('SUCCESS: ${result['success']}');
      debugPrint('USER: ${result['user']}');
      debugPrint('HOUSE: ${result['house']}');
      debugPrint('STATISTICS: ${result['statistics']}');
      debugPrint('==========================================');

      if (!mounted) return;

      if (result['success'] != true) {
        setState(() {
          isDashboardLoading = false;
        });

        debugPrint(
          'MANAGER DASHBOARD FAILED: ${result['message']}',
        );

        return;
      }

      setState(() {
        dashboardData = Map<String, dynamic>.from(result);
        isDashboardLoading = false;
      });

      debugPrint('MANAGER DASHBOARD LOADED');
      debugPrint('HOUSE: $houseName');
      debugPrint('UNIT COUNT: $unitCount');
      debugPrint('FUND BALANCE: $cashBalance');
      debugPrint('UNPAID CHARGES: $unpaidCharges');
      debugPrint('SMS CREDIT: $smsBalance');

    } catch (e, stackTrace) {
      debugPrint('==========================================');
      debugPrint('MANAGER DASHBOARD ERROR');
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
      debugPrint('==========================================');

      if (!mounted) return;

      setState(() {
        isDashboardLoading = false;
      });
    }
  }

  // =====================================================
  // ابزارهای نمایش اشتراک مدیر
  // =====================================================

  // تبدیل تاریخ میلادی به شمسی
  String _formatJalaliDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(value.toString()).toLocal();
      final jalali = Gregorian.fromDateTime(date).toJalali();

      return toPersianDigits(
        '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      debugPrint('JALALI DATE ERROR: $e');
      return value.toString();
    }
  }

  // دریافت مقدار عددی از چند نام احتمالی
  int _subscriptionInt(
      Map<String, dynamic> data,
      List<String> keys, {
        int defaultValue = 0,
      }) {
    for (final key in keys) {
      final value = data[key];

      if (value is num) {
        return value.toInt();
      }

      final parsed = int.tryParse(value?.toString() ?? '');

      if (parsed != null) {
        return parsed;
      }
    }

    return defaultValue;
  }

  // استخراج تاریخ از پاسخ API
  dynamic _subscriptionDate(
      Map<String, dynamic> data,
      List<String> keys,
      ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  // عنوان اشتراک
  String _subscriptionPlanTitle(Map<String, dynamic> data) {
    final dynamic planValue = data['plan'];

    Map<String, dynamic> plan = {};

    if (planValue is Map) {
      plan = Map<String, dynamic>.from(planValue);
    }

    // ابتدا نام آماده اشتراک بررسی می‌شود.
    final directTitle = [
      data['plan_title'],
      data['subscription_title'],
      data['plan_name'],
      plan['title'],
      plan['name'],
      plan['label'],
    ];

    for (final value in directTitle) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    // سپس مدت اشتراک بررسی می‌شود.
    final int months = _subscriptionInt(
      data,
      ['duration_months', 'plan_duration_months'],
      defaultValue: _subscriptionInt(
        plan,
        ['duration_months', 'months', 'duration'],
      ),
    );

    switch (months) {
      case 1:
        return 'اشتراک یک‌ماهه';
      case 3:
        return 'اشتراک سه‌ماهه';
      case 6:
        return 'اشتراک شش‌ماهه';
      case 12:
        return 'اشتراک یک‌ساله';
      case 24:
        return 'اشتراک دوساله';
    }

    return 'اشتراک فعال';
  }

  // ردیف اطلاعات اشتراک
  Widget _subscriptionInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xff00ACC1),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),

          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xff263238),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // کارت اشتراک
  // =====================================================

  Widget _buildSubscriptionCard() {
    if (isSubscriptionLoading && subscriptionData == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(25),
          child: CircularProgressIndicator(
            color: Color(0xff00ACC1),
          ),
        ),
      );
    }

    if (subscriptionError != null && subscriptionData == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Text('خطا در دریافت اطلاعات اشتراک'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: loadManagerSubscription,
                child: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }

    if (subscriptionData == null ||
        subscriptionData!['has_subscription'] != true) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.orange,
              size: 35,
            ),
            SizedBox(height: 10),
            Text(
              'برای این ساختمان اشتراک فعالی ثبت نشده است.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    // اطلاعات اصلی اشتراک داخل subscription قرار دارد.
    final dynamic subscriptionValue =
    subscriptionData!['subscription'];

    if (subscriptionValue is! Map) {
      return const Text('اطلاعات اشتراک قابل دریافت نیست.');
    }

    final Map<String, dynamic> subscription =
    Map<String, dynamic>.from(subscriptionValue);

    final Map<String, dynamic> plan =
    subscription['plan'] is Map
        ? Map<String, dynamic>.from(subscription['plan'])
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
        : const Color(0xFF610DB5);

    // عنوان اشتراک بر اساس مدت واقعی پلن
    final dynamic durationValue = plan['duration'];
    final int duration = _toInt(durationValue);

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
            ? 'اشتراک $duration ماهه'
            : 'اشتراک';
    }

    final String startDate =
    _formatJalaliDate(subscription['start_date']);

    final String endDate =
    _formatJalaliDate(subscription['end_date']);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffECEFF1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.card_membership_rounded,
                color: Color(0xff00ACC1),
              ),
              SizedBox(width: 9),
              Text(
                'اطلاعات اشتراک',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xff159c35).withOpacity(0.08),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                planTitle,
                style: const TextStyle(
                  color: Color(0xff37ac51),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          // نمودار دایره‌ای
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 170,
                    height: 170,
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 20,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey.shade200,
                      ),
                    ),
                  ),

                  SizedBox(
                    width: 170,
                    height: 170,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 20,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
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
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),

                      Container(
                        width: 55,
                        height: 2,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        color: Colors.grey.shade300,
                      ),

                      Text(
                        toPersianDigits(
                          totalDays.toString(),
                        ),
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff546E7A),
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'روز',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              expired
                  ? 'اشتراک به پایان رسیده است'
                  : 'روز باقی‌مانده از اشتراک',
              style: TextStyle(
                color: progressColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 18),

          Divider(color: Colors.grey.shade200),

          _subscriptionInfoRow(
            icon: Icons.calendar_today_outlined,
            title: 'تاریخ شروع',
            value: startDate,
          ),

          _subscriptionInfoRow(
            icon: Icons.event_available_outlined,
            title: 'تاریخ پایان',
            value: endDate,
          ),

          _subscriptionInfoRow(
            icon: Icons.info_outline,
            title: 'وضعیت اشتراک',
            value: subscription['status_label']?.toString() ?? '-',
          ),

          _subscriptionInfoRow(
            icon: Icons.apartment_outlined,
            title: 'تعداد واحدها',
            value: toPersianDigits(
              (subscription['units_count'] ?? 0).toString(),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
// دریافت اطلاعات اشتراک
// =====================================================

  Future<void> loadManagerSubscription() async {
    if (isSubscriptionLoading) return;

    if (mounted) {
      setState(() {
        isSubscriptionLoading = true;
        subscriptionError = null;
      });
    }

    try {
      final result = await ApiService().getManagerSubscription();

      if (!mounted) return;

      if (result is! Map) {
        throw Exception('پاسخ اشتراک معتبر نیست');
      }

      setState(() {
        subscriptionData = Map<String, dynamic>.from(result);
        isSubscriptionLoading = false;
      });

      debugPrint('MANAGER SUBSCRIPTION: $result');

    } catch (e, stackTrace) {
      debugPrint('MANAGER SUBSCRIPTION ERROR: $e');
      debugPrint(stackTrace.toString());

      if (!mounted) return;

      setState(() {
        isSubscriptionLoading = false;
        subscriptionError = e.toString();
      });
    }
  }

  // =====================================================
  // اطلاعیه‌ها
  // =====================================================

  Future<void> loadAnnouncementData() async {
    try {
      final result = await AnnouncementService.getAnnouncements();

      if (!mounted) return;

      final List<Map<String, dynamic>> items = [];

      if (result is List) {
        for (final item in result) {
          if (item is Map) {
            items.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      setState(() {
        announcements = items;
        hasNewAnnouncements = items.isNotEmpty;
      });

      _startAnnouncementSlider();

    } catch (e) {
      debugPrint('ANNOUNCEMENT ERROR: $e');
    }
  }

  // =====================================================
  // اسلایدر اطلاعیه
  // =====================================================

  void _startAnnouncementSlider() {
    _announcementTimer?.cancel();

    if (announcements.length <= 1) {
      return;
    }

    _announcementController ??= PageController(
      initialPage: 0,
    );

    _announcementTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) {
        if (!mounted) return;
        if (_announcementController == null) return;
        if (!_announcementController!.hasClients) return;

        _announcementIndex++;

        if (_announcementIndex >= announcements.length) {
          _announcementIndex = 0;
        }

        _announcementController!.animateToPage(
          _announcementIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  // =====================================================
  // باز کردن اطلاعیه‌ها
  // =====================================================

  Future<void> openAnnouncements() async {
    final int? userId = int.tryParse(
      user['id']?.toString() ?? '',
    );

    if (userId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnnouncementsScreen(
          userId: userId,
        ),
      ),
    );

    await loadAnnouncementData();
  }

  // =====================================================
  // وضعیت پیام‌های مدیران ساختمان
  // =====================================================

  Future<void> loadMessageStatus() async {
    if (isLoadingMessageStatus) return;

    isLoadingMessageStatus = true;

    try {
      final result = await ApiService().getMessages();

      final dynamic unreadData = result['unread_count'];

      final int count = unreadData is num
          ? unreadData.toInt()
          : int.tryParse(
        unreadData?.toString() ?? '',
      ) ??
          0;

      if (!mounted) return;

      setState(() {
        unreadMessageCount = count;
        hasNewMessages = count > 0;
      });

    } catch (e) {
      debugPrint('MESSAGE STATUS ERROR: $e');
    } finally {
      isLoadingMessageStatus = false;
    }
  }

  // =====================================================
  // وضعیت پیام‌های مدیریت سامانه به مدیر ساختمان
  // =====================================================

  Future<void> loadAdminMessageStatus() async {
    if (isLoadingAdminMessageStatus) return;

    isLoadingAdminMessageStatus = true;

    try {
      final service = ManagerAdminMessageService(
        apiService: ApiService(),
      );

      // دریافت پیام‌های خوانده‌نشده
      // آمار از پاسخ همین درخواست استخراج می‌شود.
      final result = await service.getMessages(
        status: 'unread',
      );

      final statistics = result['statistics'] is Map
          ? Map<String, dynamic>.from(result['statistics'])
          : <String, dynamic>{};

      final int count = _toInt(
        statistics['unread_count'],
      );

      if (!mounted) return;

      setState(() {
        unreadAdminMessageCount = count;
        hasNewAdminMessages = count > 0;
      });

      debugPrint(
        'ADMIN UNREAD MESSAGE COUNT: $unreadAdminMessageCount',
      );

    } catch (e, stackTrace) {
      debugPrint('ADMIN MESSAGE STATUS ERROR: $e');
      debugPrint(stackTrace.toString());
    } finally {
      isLoadingAdminMessageStatus = false;
    }
  }

  // =====================================================
// باز کردن پیام‌های مدیریت سامانه داخل داشبورد
// =====================================================

  void openAdminMessages() {
    setState(() {
      _adminMessagesPageOpened = true;

      // صفحه پیام‌های ادمین به‌عنوان صفحه داخلی داشبورد
      currentIndex = 5;
    });
  }
  // =====================================================
  // مدیریت تیکت‌ها
  //
  // ساکن ← مدیر ساختمان
  // =====================================================

  Future<void> loadSupportTicketStatus() async {
    try {
      debugPrint('==========================================');
      debugPrint('START LOAD MANAGER SUPPORT UNREAD COUNT');

      final service = ManagerSupportService(
        apiService: ApiService(),
      );

      final count = await service.getUnreadCount();

      debugPrint('MANAGER SUPPORT UNREAD COUNT: $count');

      if (!mounted) return;

      setState(() {
        unreadTicketCount = count;
      });

      debugPrint(
        'UNREAD TICKET COUNT UPDATED: $unreadTicketCount',
      );

      debugPrint('==========================================');

    } catch (e, stackTrace) {
      debugPrint('MANAGER SUPPORT STATUS ERROR: $e');
      debugPrint(stackTrace.toString());
    }
  }

  // =====================================================
  // پشتیبانی
  //
  // مدیر ساختمان ← ادمین سامانه
  // =====================================================

  Future<void> loadAdminSupportTicketStatus() async {
    try {
      debugPrint('==========================================');
      debugPrint('START LOAD MANAGER ADMIN SUPPORT UNREAD COUNT');

      final service = ManagerAdminSupportService(
        apiService: ApiService(),
      );

      final count = await service.getUnreadCount();

      debugPrint(
        'MANAGER ADMIN SUPPORT UNREAD COUNT: $count',
      );

      if (!mounted) return;

      setState(() {
        unreadAdminSupportTicketCount = count;
      });

      debugPrint(
        'UNREAD ADMIN SUPPORT COUNT UPDATED: '
            '$unreadAdminSupportTicketCount',
      );

      debugPrint('==========================================');

    } catch (e, stackTrace) {
      debugPrint('MANAGER ADMIN SUPPORT STATUS ERROR: $e');
      debugPrint(stackTrace.toString());
    }
  }

  // =====================================================
  // باز کردن پیام‌های قبلی مدیران
  // =====================================================

  Future<void> openMessages() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerMessagesScreen(),
      ),
    );

    await loadMessageStatus();
  }

  // =====================================================
  // تبدیل اعداد به فارسی
  // =====================================================

  String toPersianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    for (int i = 0; i < english.length; i++) {
      value = value.replaceAll(
        english[i],
        persian[i],
      );
    }

    return value;
  }

  // =====================================================
  // فرمت مبلغ
  // =====================================================

  String formatAmount(dynamic value) {
    final amount = _toInt(value);
    final text = amount.toString();

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('٬');
      }

      buffer.write(text[i]);
    }

    return toPersianDigits(buffer.toString());
  }

  // =====================================================
  // Navigation
  // =====================================================


  void onNavigationTap(int index) {
    final bool wasAdminMessagesPage = currentIndex == 5;

    setState(() {
      currentIndex = index;
    });

    if (index == 3) {
      loadPendingPaymentStatus();
    }

    if (wasAdminMessagesPage) {
      loadAdminMessageStatus();
    }
  }
  // =====================================================
  // هدر ساختمان و مدیر
  // =====================================================

  Widget _buildHouseHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffECEFF1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xff00ACC1).withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: Color(0xff00ACC1),
              size: 26,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ساختمان: $houseName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff263238),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'مدیر: $fullName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // صفحه خانه
  // =====================================================

  Widget buildHomePage() {
    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xff00ACC1),

        onRefresh: () async {
          await Future.wait([
            loadManagerDashboard(),
            loadAnnouncementData(),
            loadMessageStatus(),
            loadAdminMessageStatus(),
            loadSupportTicketStatus(),
            loadAdminSupportTicketStatus(),
            loadPendingPaymentStatus(),
          ]);
        },

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            12,
            16,
            12,
            28,
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // _buildHouseHeader(),
              //
              // const SizedBox(height: 16),

              // اسلایدر آمار
              _buildStatisticsSlider(),

              const SizedBox(height: 20),

              // =================================================
              // ردیف اول
              // =================================================

              Row(
                children: [
                  Expanded(
                    child: _ManagerTopMenuItem(
                      title: 'مدیریت اطلاعیه‌ها',
                      icon: Icons.notifications_none_rounded,
                      color: const Color(0xff00ACC1),

                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const ManagerAnnouncementsScreen(),
                          ),
                        );

                        await loadAnnouncementData();
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _ManagerTopMenuItem(
                      title: 'مدیریت پیام‌ها',
                      icon: Icons.mail_outline_rounded,
                      color: const Color(0xff5E35B1),
                      onTap: openMessages,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _ManagerTopMenuItem(
                      title: 'مدیریت تیکت‌ها',
                      icon: Icons.support_agent_outlined,
                      color: const Color(0xffEF6C00),

                      badge: unreadTicketCount > 0
                          ? unreadTicketCount
                          : null,

                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const ManagerSupportTicketsScreen(),
                          ),
                        );

                        await loadSupportTicketStatus();
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // =================================================
              // چهار کارت وسط
              // =================================================

              Row(
                children: [
                  Expanded(
                    child: _ManagerMiddleMenuCard(
                      title: 'مدیریت واحدها',
                      icon: Icons.apartment_rounded,
                      color: const Color(0xff00897B),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const ManagerUnitsScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 9),

                  Expanded(
                    child: _ManagerMiddleMenuCard(
                      title: 'مدیریت شارژها',
                      icon: Icons.receipt_long_outlined,
                      color: const Color(0xff00ACC1),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const ManagerChargesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _ManagerMiddleMenuCard(
                      title: 'مدیریت عملیات',
                      icon: Icons.settings_suggest_outlined,
                      color: const Color(0xff6D4C41),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const ManagerOperationsScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 9),

                  Expanded(
                    child: _ManagerMiddleMenuCard(
                      title: 'مدیریت گزارش‌',
                      icon: Icons.assessment_outlined,
                      color: const Color(0xFF00ACC1),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const ManagerReportsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // =================================================
              // ردیف پایین
              // =================================================

              Row(
                children: [
                  Expanded(
                    child: _ManagerTopMenuItem(
                      title: 'مدیریت بانک‌ها',
                      icon: Icons.account_balance_outlined,
                      color: const Color(0xff1565C0),

                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const ManagerBanksScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  // پشتیبانی مدیر ← ادمین
                  Expanded(
                    child: _ManagerTopMenuItem(
                      title: 'پشتیبانی سامانه',
                      icon: Icons.headset_mic_outlined,
                      color: const Color(0xff7B1FA2),

                      badge: unreadAdminSupportTicketCount > 0
                          ? unreadAdminSupportTicketCount
                          : null,

                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const ManagerAdminSupportTicketsScreen(),
                          ),
                        );

                        await loadAdminSupportTicketStatus();
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _ManagerTopMenuItem(
                      title: 'مدیریت نظرسنجی',
                      icon: Icons.poll_outlined,
                      color: const Color(0xffF9A825),

                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const ManagerPollsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // اسلایدر آمار
  // =====================================================

  void _startStatisticsSlider() {
    _statisticsTimer?.cancel();

    _statisticsTimer = Timer.periodic(
      const Duration(seconds: 4),
          (_) {
        if (!mounted) return;
        if (!_statisticsController.hasClients) return;

        _statisticsIndex++;

        if (_statisticsIndex >= 4) {
          _statisticsIndex = 0;
        }

        _statisticsController.animateToPage(
          _statisticsIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  // =====================================================
  // اسلایدر آمار
  // =====================================================

  Widget _buildStatisticsSlider() {
    final items = [
      // موجودی صندوق
      _StatisticItem(
        title: 'موجودی صندوق',
        value: cashBalance,
        icon: Icons.account_balance_wallet_outlined,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff20C997),
            Color(0xff198754),
          ],
        ),
        isAmount: true,
      ),

      // تعداد واحدها
      _StatisticItem(
        title: 'تعداد واحدها',
        value: unitCount,
        icon: Icons.apartment_rounded,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xfff3c582),
            Color(0xffFFC107),
          ],
        ),
      ),

      // شارژهای پرداخت‌نشده
      _StatisticItem(
        title: 'شارژهای پرداخت‌نشده',
        value: unpaidCharges,
        icon: Icons.receipt_long_outlined,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xffFF5C6C),
            Color(0xffDC3545),
          ],
        ),
      ),

      // موجودی حساب پیامکی
      _StatisticItem(
        title: 'موجودی حساب پیامکی',
        value: smsBalance,
        icon: Icons.sms_outlined,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xff3DD5F3),
            Color(0xff0DCAF0),
          ],
        ),
        isAmount: true,
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 118,
          width: double.infinity,

          child: PageView.builder(
            itemCount: items.length,
            controller: _statisticsController,

            onPageChanged: (index) {
              if (!mounted) return;

              setState(() {
                _statisticsIndex = index;
              });
            },

            itemBuilder: (context, index) {
              final item = items[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildStatisticCard(item),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: List.generate(
            items.length,
                (index) {
              final bool isActive = _statisticsIndex == index;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,

                width: isActive ? 18 : 6,
                height: 6,

                margin: const EdgeInsets.symmetric(horizontal: 3),

                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xff00ACC1)
                      : Colors.grey.shade300,

                  borderRadius: BorderRadius.circular(10),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // =====================================================
  // کارت آماری
  // =====================================================

  Widget _buildStatisticCard(_StatisticItem item) {
    final String value = item.isAmount
        ? formatAmount(item.value)
        : toPersianDigits(item.value.toString());

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 13,
      ),

      decoration: BoxDecoration(
        gradient: item.gradient,
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              shape: BoxShape.circle,
            ),

            child: Icon(
              item.icon,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,

                  children: [
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    if (item.isAmount)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),

                        child: Text(
                          'تومان',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // صفحات BottomNavigation
  // =====================================================

  Widget buildSmsPage() {
    return const _SimpleManagerPage(
      title: 'پیامک‌ها',
      icon: Icons.sms_outlined,
    );
  }

  Widget buildFinancePage() {
    return const ManagerAdminFundScreen();
  }

  Widget buildMessagesPage() {
    return const ManagerPendingPaymentsScreen();
  }

  Widget buildAdminMessagesPage() {
    return const ManagerAdminMessagesScreen(
      embedded: true,
    );
  }




  // =====================================================
// پروفایل مدیر
// =====================================================

  Widget buildProfilePage() {
    return ManagerProfileScreen(
      user: user,
      fullName: fullName,
      houseName: houseName,
      subscriptionData: subscriptionData,
      isSubscriptionLoading: isSubscriptionLoading,
      subscriptionError: subscriptionError,
      onRefresh: loadManagerSubscription,
      onLogout: _showLogoutDialog,
    );
  }

  // =====================================================
  // خروج
  // =====================================================


  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),

            title: const Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: Color(0xFFFFEBEE),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'خروج از حساب کاربری',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
              ],
            ),

            content: const Text(
              'آیا مطمئن هستید که می‌خواهید از حساب کاربری خود خارج شوید؟',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                height: 1.9,
                color: Color(0xFF546E7A),
              ),
            ),

            actionsAlignment: MainAxisAlignment.start,

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 11,
                  ),
                ),
                child: const Text('انصراف'),
              ),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                icon: const Icon(
                  Icons.logout_rounded,
                  size: 18,
                ),
                label: const Text('خروج از حساب'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (shouldLogout != true) return;

    await TokenStorage.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }


  // =====================================================
  // Coming Soon
  // =====================================================

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title در حال آماده‌سازی است.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final pages = [
      buildSmsPage(),
      buildFinancePage(),
      buildHomePage(),
      buildMessagesPage(),
      buildProfilePage(),

      // صفحه ششم: پیام‌های مدیریت سامانه
      _adminMessagesPageOpened
          ? buildAdminMessagesPage()
          : const SizedBox.shrink(),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        backgroundColor: const Color(0xffF5F8FA),

        // =================================================
        // AppBar
        // =================================================

        appBar: AppBar(
          toolbarHeight: 88,
          backgroundColor: const Color(0xff00ACC1),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,

          title: Row(
            mainAxisSize: MainAxisSize.min,

            children: [
              Container(
                width: 45,
                height: 45,
                padding: const EdgeInsets.all(8),

                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),

                child: Image.asset(
                  'assets/images/splash_logo.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(width: 20),

              const Text(
                'رایا شارژ',

                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          actions: [
            // ---------------------------------------------
            // پیام‌های مدیریت سامانه به مدیر ساختمان
            // ---------------------------------------------

            Stack(
              clipBehavior: Clip.none,

              children: [
                IconButton(
                  tooltip: 'پیام‌های مدیریت سامانه',
                  onPressed: openAdminMessages,

                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    size: 27,
                  ),
                ),

                if (hasNewAdminMessages)
                  Positioned(
                    top: 15,
                    right: 8,

                    child: Container(
                      width: 9,
                      height: 9,

                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),

            // ---------------------------------------------
            // پیام‌های قبلی مدیران
            // ---------------------------------------------

            // Stack(
            //   clipBehavior: Clip.none,
            //
            //   children: [
            //     IconButton(
            //       tooltip: 'پیام‌ها',
            //       onPressed: openMessages,
            //
            //       icon: const Icon(
            //         Icons.mail_outline_rounded,
            //         size: 27,
            //       ),
            //     ),
            //
            //     if (hasNewMessages)
            //       Positioned(
            //         top: 15,
            //         right: 8,
            //
            //         child: Container(
            //           width: 9,
            //           height: 9,
            //
            //           decoration: const BoxDecoration(
            //             color: Colors.red,
            //             shape: BoxShape.circle,
            //           ),
            //         ),
            //       ),
            //   ],
            // ),

            const SizedBox(width: 5),
          ],
        ),

        // =================================================
        // Body
        // =================================================

        body: IndexedStack(
          index: currentIndex,
          children: pages,
        ),

        // =================================================
        // Bottom Navigation
        // =================================================


        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: currentIndex == 5 ? 2 : currentIndex,
            onTap: onNavigationTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xff00ACC1),
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.sms_outlined),
                activeIcon: Icon(Icons.sms),
                label: 'پیامک‌ها',
              ),

              const BottomNavigationBarItem(
                icon: Icon(
                  Icons.account_balance_wallet_outlined,
                ),
                activeIcon: Icon(
                  Icons.account_balance_wallet,
                ),
                label: 'امور مالی',
              ),

              BottomNavigationBarItem(
                icon: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: currentIndex == 2 || currentIndex == 5
                        ? const Color(0xff00ACC1)
                        : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: currentIndex == 2 || currentIndex == 5
                        ? [
                      BoxShadow(
                        color: const Color(0xff00ACC1)
                            .withOpacity(0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                        : null,
                    border: currentIndex == 2 || currentIndex == 5
                        ? null
                        : Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    currentIndex == 2 || currentIndex == 5
                        ? Icons.home_rounded
                        : Icons.home_outlined,
                    color: currentIndex == 2 || currentIndex == 5
                        ? Colors.white
                        : Colors.grey,
                    size: 27,
                  ),
                ),
                label: 'خانه',
              ),

              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                    ),

                    if (pendingPaymentCount > 0)
                      Positioned(
                        top: -3,
                        right: -5,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                activeIcon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                    ),

                    if (pendingPaymentCount > 0)
                      Positioned(
                        top: -3,
                        right: -5,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.fromBorderSide(
                              BorderSide(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                label: 'پرداخت‌ها',
              ),

              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'پروفایل',
              ),
            ],
          ),
        ),

      ),
    );
  }
}

// =====================================================
// مدل کارت آماری
// =====================================================

class _StatisticItem {
  final String title;
  final int value;
  final IconData icon;
  final LinearGradient gradient;
  final bool isAmount;

  const _StatisticItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    this.isAmount = false,
  });
}

// =====================================================
// آیتم‌های ردیف بالا و پایین
// =====================================================

class _ManagerTopMenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int? badge;

  const _ManagerTopMenuItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(14),

        child: SizedBox(
          height: 92,

          child: Stack(
            clipBehavior: Clip.none,

            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Container(
                      width: 50,
                      height: 50,

                      decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),

                      child: Icon(
                        icon,
                        color: color,
                        size: 27,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,

                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff263238),
                      ),
                    ),
                  ],
                ),
              ),

              // Badge
              if (badge != null)
                Positioned(
                  top: 7,
                  right: 12,

                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),

                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                    ),

                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),

                    child: Center(
                      child: Text(
                        badge! > 99
                            ? '۹۹+'
                            : toPersianDigits(
                          badge!.toString(),
                        ),

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// کارت‌های چهارگانه وسط
// =====================================================

class _ManagerMiddleMenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ManagerMiddleMenuCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),

        child: Container(
          height: 94,

          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),

            border: Border.all(
              color: const Color(0xffECEFF1),
              width: 1,
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,

                decoration: BoxDecoration(
                  color: color.withOpacity(0.09),
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  icon,
                  color: color,
                  size: 23,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff263238),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              Icon(
                Icons.chevron_right_rounded,
                size: 25,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// صفحه ساده موقت
// =====================================================

class _SimpleManagerPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SimpleManagerPage({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 80,
              height: 80,

              decoration: BoxDecoration(
                color: const Color(0xff00ACC1).withOpacity(0.10),
                shape: BoxShape.circle,
              ),

              child: Icon(
                icon,
                color: const Color(0xff00ACC1),
                size: 42,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              title,

              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xff263238),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// آیتم پروفایل
// =====================================================

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),

        border: Border.all(
          color: const Color(0xffECEFF1),
        ),
      ),

      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xff00ACC1),
            size: 23,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,

              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),

          Text(
            value,

            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xff263238),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// تابع کمکی تبدیل اعداد برای Badge
// =====================================================

String toPersianDigits(String value) {
  const english = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';

  for (int i = 0; i < english.length; i++) {
    value = value.replaceAll(
      english[i],
      persian[i],
    );
  }

  return value;
}