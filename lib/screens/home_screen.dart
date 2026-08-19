import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'announcements_screen.dart';
import '../storage/token_storage.dart';
import 'login_screen.dart';
import 'polls_screen.dart';
import '../services/poll_service.dart';
import '../services/announcement_service.dart';
import '../services/api_service.dart';
import 'charges_screen.dart';


class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const HomeScreen({
    super.key,
    required this.data,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 1;

  bool hasNewAnnouncements = false;
  bool hasNewPolls = false;

  Map<String, dynamic>? dashboardData;
  bool isDashboardLoading = true;

  @override
  void initState() {
    super.initState();

    debugPrint(
      'HOME DATA = ${widget.data}',
    );

    loadDashboard();

    loadPollStatus();
    loadAnnouncementStatus();
  }

  Future<void> loadPollStatus() async {
    try {
      final result = await PollService.getPolls();

      if (!mounted) return;

      bool newPollExists = false;

      for (final poll in result) {
        if (poll is Map<String, dynamic>) {
          final isActive = poll['is_active'] == true;
          final hasVoted = poll['has_voted'] == true;

          if (isActive && !hasVoted) {
            newPollExists = true;
            break;
          }
        }
      }

      setState(() {
        hasNewPolls = newPollExists;
      });
    } catch (e) {
      debugPrint(
        'LOAD POLL STATUS ERROR: $e',
      );
    }
  }

  Future<void> loadDashboard() async {
    try {
      debugPrint(
          '========== LOAD DASHBOARD =========='
      );

      final data =
      await ApiService().getDashboard();

      debugPrint(
        'DASHBOARD DATA = $data',
      );

      if (!mounted) return;

      setState(() {
        dashboardData = data;
        isDashboardLoading = false;
      });
    } catch (e) {
      debugPrint(
        'LOAD DASHBOARD ERROR = $e',
      );

      if (!mounted) return;

      setState(() {
        isDashboardLoading = false;
      });
    }
  }

  Future<void> loadAnnouncementStatus() async {
    try {
      final userId = int.tryParse(
        user['id']?.toString() ?? '',
      );

      if (userId == null) {
        debugPrint('ANNOUNCEMENT: USER ID NOT FOUND');
        return;
      }

      final hasNew =
      await AnnouncementService.hasNewAnnouncements(userId);

      if (!mounted) return;

      setState(() {
        hasNewAnnouncements = hasNew;
      });

      debugPrint(
        'ANNOUNCEMENT STATUS: $hasNew | USER ID: $userId',
      );
    } catch (e) {
      debugPrint(
        'LOAD ANNOUNCEMENT STATUS ERROR: $e',
      );
    }
  }

// =====================================================
// آخرین شارژ
// =====================================================

  Map<String, dynamic> get latestCharge {
    return (dashboardData?['latest_charge']
    as Map<String, dynamic>?) ??
        {};
  }

  String get latestChargeTitle {
    final title = latestCharge['title']?.toString();

    if (title == null || title.isEmpty) {
      return 'شارژی ثبت نشده است';
    }

    return title;
  }
// =====================================================
// تبدیل اعداد انگلیسی به فارسی
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
  // اطلاعات کاربر
  // =====================================================

  Map<String, dynamic> get user {
    return (widget.data['user']
    as Map<String, dynamic>?) ??
        {};
  }

  Map<String, dynamic> get house {
    return (widget.data['house']
    as Map<String, dynamic>?) ??
        {};
  }

  List<dynamic> get units {
    return (widget.data['units'] as List?) ?? [];
  }

  Map<String, dynamic> get unit {
    if (units.isEmpty) {
      return {};
    }

    return (units.first
    as Map<String, dynamic>?) ??
        {};
  }

  // =====================================================
  // نام کاربر
  // =====================================================

  String get fullName {
    final name =
    user['full_name']?.toString();

    if (name == null || name.isEmpty) {
      return 'کاربر';
    }

    return name;
  }

  // =====================================================
  // نام ساختمان
  // =====================================================

  String get houseName {
    final name =
    house['name']?.toString();

    if (name == null || name.isEmpty) {
      return '-';
    }

    return name;
  }

  // =====================================================
  // شماره واحد
  // =====================================================

  String get unitNumber {
    final number =
    unit['unit']?.toString();

    if (number == null || number.isEmpty) {
      return '-';
    }

    return toPersianDigits(number);
  }

  // =====================================================
  // مبلغ پرداخت شده
  //
  // فعلاً نمونه
  // بعداً از API دریافت می‌شود.
  // =====================================================

  int get paidAmount {
    final statistics =
    dashboardData?['statistics']
    as Map<String, dynamic>?;

    return int.tryParse(
      statistics?['total_paid']?.toString() ?? '0',
    ) ??
        0;
  }
  int get unpaidAmount {
    final statistics =
    dashboardData?['statistics']
    as Map<String, dynamic>?;

    return int.tryParse(
      statistics?['total_debt']?.toString() ?? '0',
    ) ??
        0;
  }
  // =====================================================
  // فرمت مبلغ
  // =====================================================

  String formatAmount(int amount) {
    final text = amount.toString();

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 &&
          (text.length - i) % 3 == 0) {
        buffer.write('٬');
      }

      buffer.write(text[i]);
    }

    return toPersianDigits(buffer.toString());
  }

  // =====================================================
  // صفحه اصلی
  // =====================================================

  Widget buildHomePage() {
    final totalAmount = paidAmount + unpaidAmount;

    final double paidPercent =
    totalAmount == 0
        ? 0.0
        : paidAmount / totalAmount;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          18,
          20,
          18,
          100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =================================================
            // اطلاعات ساختمان و واحد
            // =================================================

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xff00ACC1).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.apartment,
                      color: Color(0xff00ACC1),
                      size: 29,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مجتمع مسکونی $houseName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff263238),
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          'واحد شماره $unitNumber',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '${unit['is_renter'] == true ? 'مستأجر' : 'مالک'}: $fullName',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 17),

            // =================================================
            // کارت مجموع پرداختی
            // =================================================

            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 22,
                horizontal: 18,
              ),
              decoration: BoxDecoration(
                color: const Color(0xff610db5),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff610db5).withOpacity(0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'مجموع پرداختی',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // مبلغ و تومان در یک سطر و وسط‌چین
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatAmount(paidAmount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 8),

                        const Text(
                          'تومان',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 17),

// =================================================
// آخرین شارژ
// =================================================

            InkWell(
              onTap: () {
                setState(() {
                  currentIndex = 0;
                });
              },
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 17,
                  horizontal: 18,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xff00ACC1).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: Color(0xff00ACC1),
                        size: 26,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'آخرین شارژ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            latestChargeTitle,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff263238),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.grey,
                      size: 25,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

// =================================================
// عنوان وضعیت شارژ
// =================================================

            const Text(
              'وضعیت شارژ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff263238),
              ),
            ),

            const SizedBox(height: 15),

            // =================================================
            // کارت نمودار
            // =================================================

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: CustomPaint(
                      painter: _ChargeChartPainter(
                        paidPercent: paidPercent,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${toPersianDigits((paidPercent * 100).round().toString())}٪',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff263238),
                              ),
                            ),

                            const Text(
                              'پرداخت شده',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _ChartLegend(
                          title: 'پرداخت شده',
                          amount: paidAmount,
                          iconColor: const Color(0xff610db5),
                        ),
                      ),

                      Expanded(
                        child: _ChartLegend(
                          title: 'پرداخت نشده',
                          amount: unpaidAmount,
                          iconColor: const Color(0xffE0E0E0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // صفحه شارژها
  // =====================================================

  Widget buildChargesPage() {
    return const ChargesScreen();
  }
  // =====================================================
  // صفحه پروفایل
  // =====================================================
  // =====================================================
  // =====================================================
  // خروج از حساب کاربری
  // =====================================================

  Future<void> _showLogoutDialog() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                ),
                SizedBox(width: 10),
                Text(
                  'خروج از حساب کاربری',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'آیا مطمئن هستید که می‌خواهید از حساب کاربری خود خارج شوید؟',
              style: TextStyle(
                fontSize: 14,
                height: 1.7,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text(
                  'انصراف',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'خروج',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    // -------------------------------------------------
    // پاک کردن تمام اطلاعات ورود
    // -------------------------------------------------

    await TokenStorage.clear();

    if (!mounted) return;

    // -------------------------------------------------
    // انتقال به صفحه ورود
    // -------------------------------------------------

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }
  Widget buildProfilePage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // =====================================================
            // تصویر کاربر
            // =====================================================

            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xff00ACC1),
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 15),

            // =====================================================
            // نام کاربر
            // =====================================================

            Text(
              fullName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // =====================================================
            // شماره موبایل
            // =====================================================

            Text(
              toPersianDigits(
                user['mobile']?.toString() ?? '-',
              ),
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 30),

            // =====================================================
            // اطلاعات ساختمان
            // =====================================================

            _ProfileItem(
              icon: Icons.apartment,
              title: 'ساختمان',
              value: houseName,
            ),

            _ProfileItem(
              icon: Icons.home,
              title: 'شماره واحد',
              value: unitNumber,
            ),

            _ProfileItem(
              icon: Icons.layers_outlined,
              title: 'طبقه',
              value: toPersianDigits(
                unit['floor_number']?.toString() ?? '-',
              ),
            ),

            _ProfileItem(
              icon: Icons.square_foot,
              title: 'متراژ',
              value:
              '${toPersianDigits(unit['area']?.toString() ?? '-')} مترمربع',
            ),

            _ProfileItem(
              icon: Icons.bed_outlined,
              title: 'تعداد خواب',
              value:
              '${toPersianDigits(unit['bedrooms_count']?.toString() ?? '-')} ',
            ),

            const SizedBox(height: 20),

            // =====================================================
            // خروج از حساب کاربری
            // =====================================================

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _showLogoutDialog,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                ),
                label: const Text(
                  'خروج از حساب کاربری',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.red.withOpacity(0.25),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  // =====================================================
  // تغییر صفحه
  // =====================================================

  void onNavigationTap(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      buildChargesPage(),
      buildHomePage(),
      buildProfilePage(),
    ];

    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        const Color(0xffF5F8FA),

        appBar: AppBar(
          backgroundColor: const Color(0xff00ACC1),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,

          // =====================================================
          // سمت چپ: نظرسنجی + اطلاعیه‌ها
          // =====================================================

          actions: [
            // =====================================================
            // نظرسنجی
            // =====================================================

            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'نظرسنجی',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PollsScreen(),
                      ),
                    );

                    // بعد از برگشت، وضعیت واقعی نظرسنجی‌ها را دوباره بگیر
                    await loadPollStatus();
                  },
                  icon: const Icon(
                    Icons.poll_outlined,
                    size: 25,
                  ),
                ),

                if (hasNewPolls)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),

            // =====================================================
            // اطلاعیه‌ها
            // =====================================================

            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'اطلاعیه‌ها',
                  onPressed: () async {
                    final userId = int.tryParse(
                      user['id']?.toString() ?? '',
                    );

                    if (userId == null) {
                      debugPrint(
                        'ANNOUNCEMENT: USER ID NOT FOUND',
                      );
                      return;
                    }

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnnouncementsScreen(
                          userId: userId,
                        ),
                      ),
                    );

                    // بعد از برگشت از صفحه اطلاعیه‌ها
                    // وضعیت نقطه قرمز را دوباره بررسی می‌کنیم
                    await loadAnnouncementStatus();
                  },
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    size: 27,
                  ),
                ),

                if (hasNewAnnouncements)
                  Positioned(
                    top: 8,
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

            const SizedBox(width: 5),
          ],

          // =====================================================
          // لوگو + عنوان
          // =====================================================

          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/splash_logo.png',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(width: 15),

              const Text(
                'رایا شارژ',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        body: pages[currentIndex],

        // =================================================
        // Bottom Navigation
        //
        // در RTL:
        // راست = شارژها
        // وسط = خانه
        // چپ = پروفایل
        // =================================================

        bottomNavigationBar:
        Container(
          decoration:
          const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color:
                Colors.black12,
                blurRadius: 10,
                offset:
                Offset(0, -3),
              ),
            ],
          ),
          child:
          BottomNavigationBar(
            currentIndex:
            currentIndex,
            onTap:
            onNavigationTap,
            type:
            BottomNavigationBarType
                .fixed,
            backgroundColor:
            Colors.white,
            selectedItemColor:
            const Color(
              0xff00ACC1,
            ),
            unselectedItemColor:
            Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.receipt_long_outlined,
                ),
                activeIcon: Icon(
                  Icons.receipt_long,
                ),
                label: 'شارژها',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.home_outlined,
                ),
                activeIcon: Icon(
                  Icons.home,
                ),
                label: 'خانه',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.person_outline,
                ),
                activeIcon: Icon(
                  Icons.person,
                ),
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
// نمودار دایره‌ای شارژ
// =====================================================

class _ChargeChartPainter
    extends CustomPainter {
  final double paidPercent;

  _ChargeChartPainter({
    required this.paidPercent,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        math.min(
          size.width,
          size.height,
        ) /
            2 -
            10;

    const strokeWidth = 25.0;

    final backgroundPaint =
    Paint()
      ..color = const Color(
        0xffE0E0E0,
      )
      ..style =
          PaintingStyle.stroke
      ..strokeWidth =
          strokeWidth
      ..strokeCap =
          StrokeCap.round;

    final paidPaint =
    Paint()
      ..color = const Color(
        0xff610db5,
      )
      ..style =
          PaintingStyle.stroke
      ..strokeWidth =
          strokeWidth
      ..strokeCap =
          StrokeCap.round;

    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );

    final paidAngle =
        2 *
            math.pi *
            paidPercent;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      -math.pi / 2,
      paidAngle,
      false,
      paidPaint,
    );
  }

  @override
  bool shouldRepaint(
      covariant _ChargeChartPainter oldDelegate,
      ) {
    return oldDelegate.paidPercent !=
        paidPercent;
  }
}

// =====================================================
// راهنمای نمودار
// =====================================================

class _ChartLegend
    extends StatelessWidget {
  final String title;
  final int amount;
  final Color iconColor;

  const _ChartLegend({
    required this.title,
    required this.amount,
    required this.iconColor,
  });

  String formatAmount(int amount) {
    final text = amount.toString();

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 &&
          (text.length - i) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(text[i]);
    }

    return buffer.toString();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: iconColor,
                shape:
                BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style:
              const TextStyle(
                fontSize: 12,
                color:
                Colors.grey,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          '${formatAmount(amount)} تومان',
          style:
          const TextStyle(
            fontSize: 13,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// =====================================================
// آیتم پروفایل
// =====================================================

class _ProfileItem
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
      const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color:
            const Color(
              0xff610db5,
            ),
          ),

          const SizedBox(width: 12),

          Text(
            '$title:',
            style:
            const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              value,
              textAlign:
              TextAlign.left,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}