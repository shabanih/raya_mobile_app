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
  // =====================================================
  // صفحه فعلی
  //
  // 0 = خانه
  // 1 = شارژها
  // 2 = امور مالی
  // 3 = اطلاعیه‌ها
  // 4 = نظرسنجی‌ها
  // 5 = پروفایل
  // =====================================================

  int currentIndex = 0;

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

  // =====================================================
  // وضعیت نظرسنجی
  // =====================================================

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

  // =====================================================
  // داشبورد
  // =====================================================

  Future<void> loadDashboard() async {
    try {
      debugPrint(
        '========== LOAD DASHBOARD ==========',
      );

      final data = await ApiService().getDashboard();

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

  // =====================================================
  // وضعیت اطلاعیه‌ها
  // =====================================================

  Future<void> loadAnnouncementStatus() async {
    try {
      final userId = int.tryParse(
        user['id']?.toString() ?? '',
      );

      if (userId == null) {
        debugPrint(
          'ANNOUNCEMENT: USER ID NOT FOUND',
        );
        return;
      }

      final hasNew =
      await AnnouncementService.hasNewAnnouncements(
        userId,
      );

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

    // تبدیل اعداد عنوان شارژ به فارسی
    return toPersianDigits(title);
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

  // =====================================================
  // مبلغ بدهی
  // =====================================================

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

    return toPersianDigits(
      buffer.toString(),
    );
  }

  // =====================================================
  // صفحه خانه
  // =====================================================

  Widget buildHomePage() {
    final totalAmount =
        paidAmount + unpaidAmount;

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
          30,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [

            // =================================================
            // اطلاعات ساختمان و واحد
            // =================================================

            Container(
              padding:
              const EdgeInsets.all(18),
              decoration:
              BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.055),
                    blurRadius: 14,
                    offset:
                    const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: const Color(
                    0xff00ACC1,
                  ).withOpacity(0.07),
                ),
              ),
              child: Row(
                children: [

                  Container(
                    width: 54,
                    height: 54,
                    decoration:
                    BoxDecoration(
                      color: const Color(
                        0xff00ACC1,
                      ).withOpacity(0.11),
                      shape:
                      BoxShape.circle,
                    ),
                    child:
                    const Icon(
                      Icons.apartment,
                      color:
                      Color(0xff00ACC1),
                      size: 29,
                    ),
                  ),

                  const SizedBox(
                    width: 14,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [

                        Text(
                          'مجتمع مسکونی $houseName',
                          style:
                          const TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold,
                            color:
                            Color(0xff263238),
                          ),
                        ),

                        const SizedBox(
                          height: 7,
                        ),

                        Text(
                          'واحد شماره $unitNumber',
                          style:
                          const TextStyle(
                            fontSize: 14,
                            color:
                            Colors.grey,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          '${unit['is_renter'] == true ? 'مستأجر' : 'مالک'}: $fullName',
                          style:
                          const TextStyle(
                            fontSize: 14,
                            color:
                            Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 17,
            ),

            // =================================================
            // کارت مجموع پرداختی
            // =================================================

            Container(
              padding:
              const EdgeInsets.symmetric(
                vertical: 22,
                horizontal: 18,
              ),
              decoration:
              BoxDecoration(
                // بنفش ملایم‌تر
                color:
                const Color(0xff7654A6),
                borderRadius:
                BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color:
                    const Color(
                      0xff7654A6,
                    ).withOpacity(0.18),
                    blurRadius: 14,
                    offset:
                    const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [

                  const Text(
                    'مجموع پرداختی',
                    style:
                    TextStyle(
                      color:
                      Colors.white,
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w500,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Center(
                    child: Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .baseline,
                      textBaseline:
                      TextBaseline
                          .alphabetic,
                      children: [

                        Text(
                          formatAmount(
                            paidAmount,
                          ),
                          style:
                          const TextStyle(
                            color:
                            Colors.white,
                            fontSize: 29,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        const Text(
                          'تومان',
                          style:
                          TextStyle(
                            color:
                            Colors.white,
                            fontSize: 14,
                            fontWeight:
                            FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 17,
            ),

            // =================================================
            // آخرین شارژ
            // =================================================

            InkWell(
              onTap: () {
                setState(() {
                  currentIndex = 1;
                });
              },
              borderRadius:
              BorderRadius.circular(22),
              child: Container(
                padding:
                const EdgeInsets.symmetric(
                  vertical: 17,
                  horizontal: 18,
                ),
                decoration:
                BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.055),
                      blurRadius: 13,
                      offset:
                      const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color:
                    const Color(
                      0xff00ACC1,
                    ).withOpacity(0.07),
                  ),
                ),
                child: Row(
                  children: [

                    Container(
                      width: 46,
                      height: 46,
                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                          0xff00ACC1,
                        ).withOpacity(0.10),
                        shape:
                        BoxShape.circle,
                      ),
                      child:
                      const Icon(
                        Icons.receipt_long_outlined,
                        color:
                        Color(0xff00ACC1),
                        size: 26,
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [

                          const Text(
                            'آخرین شارژ',
                            style:
                            TextStyle(
                              fontSize: 13,
                              color:
                              Colors.grey,
                            ),
                          ),

                          const SizedBox(
                            height: 5,
                          ),

                          Text(
                            latestChargeTitle,
                            style:
                            const TextStyle(
                              fontSize: 17,
                              fontWeight:
                              FontWeight.bold,
                              color:
                              Color(
                                0xff263238,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons
                          .chevron_left_rounded,
                      color:
                      Colors.grey,
                      size: 25,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height: 25,
            ),

            // =================================================
            // عنوان وضعیت شارژ
            // =================================================

            const Text(
              'وضعیت شارژ',
              style:
              TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
                color:
                Color(0xff263238),
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            // =================================================
            // کارت نمودار
            // =================================================

            Container(
              padding:
              const EdgeInsets.all(20),
              decoration:
              BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(0.055),
                    blurRadius: 14,
                    offset:
                    const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [

                  SizedBox(
                    width: 190,
                    height: 190,
                    child: CustomPaint(
                      painter:
                      _ChargeChartPainter(
                        paidPercent:
                        paidPercent,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize:
                          MainAxisSize.min,
                          children: [

                            Text(
                              '${toPersianDigits((paidPercent * 100).round().toString())}٪',
                              style:
                              const TextStyle(
                                fontSize: 28,
                                fontWeight:
                                FontWeight.bold,
                                color:
                                Color(
                                  0xff263238,
                                ),
                              ),
                            ),

                            const Text(
                              'پرداخت شده',
                              style:
                              TextStyle(
                                fontSize: 13,
                                color:
                                Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Row(
                    children: [

                      Expanded(
                        child:
                        _ChartLegend(
                          title:
                          'پرداخت شده',
                          amount:
                          paidAmount,
                          iconColor:
                          const Color(
                            0xff7654A6,
                          ),
                        ),
                      ),

                      Expanded(
                        child:
                        _ChartLegend(
                          title:
                          'پرداخت نشده',
                          amount:
                          unpaidAmount,
                          iconColor:
                          const Color(
                            0xffD9DDE1,
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
  // صفحه امور مالی
  // =====================================================

  Widget buildFinancialPage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding:
        const EdgeInsets.fromLTRB(
          18,
          20,
          18,
          30,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [

            const Text(
              'امور مالی',
              style:
              TextStyle(
                fontSize: 22,
                fontWeight:
                FontWeight.bold,
                color:
                Color(0xff263238),
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'خلاصه وضعیت مالی واحد',
              style:
              TextStyle(
                fontSize: 14,
                color:
                Colors.grey,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            _FinancialCard(
              icon:
              Icons.account_balance_wallet_outlined,
              title:
              'مجموع پرداختی',
              amount:
              formatAmount(
                paidAmount,
              ),
              color:
              const Color(
                0xff7654A6,
              ),
            ),

            _FinancialCard(
              icon:
              Icons.pending_actions_outlined,
              title:
              'بدهی فعلی',
              amount:
              formatAmount(
                unpaidAmount,
              ),
              color:
              const Color(
                0xffE58A3A,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Container(
              padding:
              const EdgeInsets.all(18),
              decoration:
              BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(20),
                border: Border.all(
                  color:
                  const Color(
                    0xff00ACC1,
                  ).withOpacity(0.08),
                ),
              ),
              child: Row(
                children: [

                  Container(
                    width: 45,
                    height: 45,
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xff00ACC1,
                      ).withOpacity(0.10),
                      shape:
                      BoxShape.circle,
                    ),
                    child:
                    const Icon(
                      Icons.info_outline_rounded,
                      color:
                      Color(
                        0xff00ACC1,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  const Expanded(
                    child: Text(
                      'تاریخچه پرداخت‌ها و جزئیات مالی در این بخش قرار خواهد گرفت.',
                      style:
                      TextStyle(
                        fontSize: 14,
                        height: 1.7,
                        color:
                        Color(
                          0xff455A64,
                        ),
                      ),
                    ),
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
  // صفحه اطلاعیه‌ها
  // =====================================================

  Widget buildAnnouncementsPage() {
    final userId = int.tryParse(
      user['id']?.toString() ?? '',
    );

    if (userId == null) {
      return const Center(
        child: Text(
          'اطلاعات کاربر پیدا نشد',
        ),
      );
    }

    return AnnouncementsScreen(
      userId: userId,
    );
  }

  // =====================================================
  // صفحه نظرسنجی‌ها
  // =====================================================

  Widget buildPollsPage() {
    return const PollsScreen();
  }

  // =====================================================
  // خروج
  // =====================================================

  Future<void> _showLogoutDialog() async {
    final shouldLogout =
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Directionality(
          textDirection:
          TextDirection.rtl,
          child: AlertDialog(
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(
                20,
              ),
            ),
            title: const Row(
              children: [

                Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                ),

                SizedBox(
                  width: 10,
                ),

                Text(
                  'خروج از حساب کاربری',
                  style:
                  TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'آیا مطمئن هستید که می‌خواهید از حساب کاربری خود خارج شوید؟',
              style:
              TextStyle(
                fontSize: 14,
                height: 1.7,
              ),
            ),
            actions: [

              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    false,
                  );
                },
                child: const Text(
                  'انصراف',
                  style:
                  TextStyle(
                    color: Colors.grey,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    true,
                  );
                },
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.red,
                  foregroundColor:
                  Colors.white,
                  elevation: 0,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                child: const Text(
                  'خروج',
                  style:
                  TextStyle(
                    fontWeight:
                    FontWeight.bold,
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

    await TokenStorage.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const LoginScreen(),
      ),
          (route) => false,
    );
  }

  // =====================================================
  // صفحه پروفایل
  // =====================================================

  Widget buildProfilePage() {
    return SafeArea(
      child:
      SingleChildScrollView(
        padding:
        const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(
              height: 30,
            ),

            const CircleAvatar(
              radius: 45,
              backgroundColor:
              Color(0xff00ACC1),
              child: Icon(
                Icons.person,
                size: 50,
                color:
                Colors.white,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            Text(
              fullName,
              style:
              const TextStyle(
                fontSize: 22,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              toPersianDigits(
                user['mobile']
                    ?.toString() ??
                    '-',
              ),
              style:
              const TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            _ProfileItem(
              icon:
              Icons.apartment,
              title:
              'ساختمان',
              value:
              houseName,
            ),

            _ProfileItem(
              icon:
              Icons.home,
              title:
              'شماره واحد',
              value:
              unitNumber,
            ),

            _ProfileItem(
              icon:
              Icons.layers_outlined,
              title:
              'طبقه',
              value:
              toPersianDigits(
                unit['floor_number']
                    ?.toString() ??
                    '-',
              ),
            ),

            _ProfileItem(
              icon:
              Icons.square_foot,
              title:
              'متراژ',
              value:
              '${toPersianDigits(unit['area']?.toString() ?? '-')} مترمربع',
            ),

            _ProfileItem(
              icon:
              Icons.bed_outlined,
              title:
              'تعداد خواب',
              value:
              toPersianDigits(
                unit['bedrooms_count']
                    ?.toString() ??
                    '-',
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              width:
              double.infinity,
              height: 52,
              child:
              OutlinedButton.icon(
                onPressed:
                _showLogoutDialog,
                icon:
                const Icon(
                  Icons.logout_rounded,
                  color:
                  Colors.red,
                ),
                label:
                const Text(
                  'خروج از حساب کاربری',
                  style:
                  TextStyle(
                    color:
                    Colors.red,
                    fontSize: 15,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                style:
                OutlinedButton.styleFrom(
                  backgroundColor:
                  Colors.white,
                  side:
                  BorderSide(
                    color:
                    Colors.red
                        .withOpacity(
                      0.25,
                    ),
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // تغییر صفحه
  // =====================================================

  void onNavigationTap(
      int index,
      ) {
    setState(() {
      currentIndex = index;
    });
  }

  // =====================================================
  // ساخت صفحات
  // =====================================================

  List<Widget> get pages {
    return [
      buildHomePage(),
      buildChargesPage(),
      buildFinancialPage(),
      buildAnnouncementsPage(),
      buildPollsPage(),
      buildProfilePage(),
    ];
  }

  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        const Color(0xffF5F8FA),

        // =================================================
        // AppBar
        // =================================================

        appBar: AppBar(
          backgroundColor:
          const Color(0xff00ACC1),
          foregroundColor:
          Colors.white,
          elevation: 0,
          centerTitle: false,

          actions: [

            // =================================================
            // نظرسنجی
            // =================================================

            Stack(
              clipBehavior:
              Clip.none,
              children: [

                IconButton(
                  tooltip:
                  'نظرسنجی',
                  onPressed:
                      () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const PollsScreen(),
                      ),
                    );

                    await loadPollStatus();
                  },
                  icon:
                  const Icon(
                    Icons.poll_outlined,
                    size: 25,
                  ),
                ),

                if (hasNewPolls)
                  Positioned(
                    top: 8,
                    right: 8,
                    child:
                    Container(
                      width: 9,
                      height: 9,
                      decoration:
                      const BoxDecoration(
                        color:
                        Colors.amber,
                        shape:
                        BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),

            // =================================================
            // اطلاعیه‌ها
            // =================================================

            Stack(
              clipBehavior:
              Clip.none,
              children: [

                IconButton(
                  tooltip:
                  'اطلاعیه‌ها',
                  onPressed:
                      () async {
                    final userId =
                    int.tryParse(
                      user['id']
                          ?.toString() ??
                          '',
                    );

                    if (userId ==
                        null) {
                      return;
                    }

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AnnouncementsScreen(
                              userId:
                              userId,
                            ),
                      ),
                    );

                    await loadAnnouncementStatus();
                  },
                  icon:
                  const Icon(
                    Icons
                        .notifications_none_rounded,
                    size: 27,
                  ),
                ),

                if (hasNewAnnouncements)
                  Positioned(
                    top: 8,
                    right: 8,
                    child:
                    Container(
                      width: 9,
                      height: 9,
                      decoration:
                      const BoxDecoration(
                        color:
                        Colors.red,
                        shape:
                        BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(
              width: 5,
            ),
          ],

          // =================================================
          // لوگو + عنوان
          // =================================================

          title: Row(
            mainAxisSize:
            MainAxisSize.min,
            children: [

              Container(
                width: 50,
                height: 50,
                padding:
                const EdgeInsets.all(
                  10,
                ),
                decoration:
                const BoxDecoration(
                  color:
                  Colors.white,
                  shape:
                  BoxShape.circle,
                ),
                child:
                Image.asset(
                  'assets/images/splash_logo.png',
                  fit:
                  BoxFit.contain,
                ),
              ),

              const SizedBox(
                width: 15,
              ),

              const Text(
                'رایا شارژ',
                overflow:
                TextOverflow.ellipsis,
                style:
                TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        body:
        IndexedStack(
          index:
          currentIndex,
          children:
          pages,
        ),

        // =================================================
        // Bottom Navigation
        //
        // RTL:
        //
        // راست:
        // خانه
        // شارژها
        // امور مالی
        // اطلاعیه‌ها
        // نظرسنجی‌ها
        // پروفایل
        // چپ
        // =================================================

        bottomNavigationBar:
        Container(
          decoration:
          const BoxDecoration(
            color:
            Colors.white,
            boxShadow: [
              BoxShadow(
                color:
                Colors.black12,
                blurRadius: 12,
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
            const Color(
              0xff90A4AE,
            ),

            selectedFontSize:
            11,

            unselectedFontSize:
            10,

            elevation: 0,

            items: [

              // ---------------------------------------------
              // خانه
              // ---------------------------------------------

              const BottomNavigationBarItem(
                icon: Icon(
                  Icons.home_outlined,
                ),
                activeIcon:
                Icon(
                  Icons.home,
                ),
                label:
                'خانه',
              ),

              // ---------------------------------------------
              // شارژها
              // ---------------------------------------------

              const BottomNavigationBarItem(
                icon: Icon(
                  Icons.receipt_long_outlined,
                ),
                activeIcon:
                Icon(
                  Icons.receipt_long,
                ),
                label:
                'شارژها',
              ),

              // ---------------------------------------------
              // امور مالی
              // ---------------------------------------------

              const BottomNavigationBarItem(
                icon: Icon(
                  Icons
                      .account_balance_wallet_outlined,
                ),
                activeIcon:
                Icon(
                  Icons
                      .account_balance_wallet,
                ),
                label:
                'امور مالی',
              ),

              // ---------------------------------------------
              // اطلاعیه‌ها
              // ---------------------------------------------

              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior:
                  Clip.none,
                  children: [

                    const Icon(
                      Icons
                          .notifications_none_outlined,
                    ),

                    if (hasNewAnnouncements)
                      Positioned(
                        top: -2,
                        right: -2,
                        child:
                        Container(
                          width: 8,
                          height: 8,
                          decoration:
                          const BoxDecoration(
                            color:
                            Colors.red,
                            shape:
                            BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: Stack(
                  clipBehavior:
                  Clip.none,
                  children: [

                    const Icon(
                      Icons.notifications,
                    ),

                    if (hasNewAnnouncements)
                      Positioned(
                        top: -2,
                        right: -2,
                        child:
                        Container(
                          width: 8,
                          height: 8,
                          decoration:
                          const BoxDecoration(
                            color:
                            Colors.red,
                            shape:
                            BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                label:
                'اطلاعیه‌ها',
              ),

              // ---------------------------------------------
              // نظرسنجی‌ها
              // ---------------------------------------------

              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior:
                  Clip.none,
                  children: [

                    const Icon(
                      Icons.poll_outlined,
                    ),

                    if (hasNewPolls)
                      Positioned(
                        top: -2,
                        right: -2,
                        child:
                        Container(
                          width: 8,
                          height: 8,
                          decoration:
                          const BoxDecoration(
                            color:
                            Colors.amber,
                            shape:
                            BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                activeIcon: Stack(
                  clipBehavior:
                  Clip.none,
                  children: [

                    const Icon(
                      Icons.poll,
                    ),

                    if (hasNewPolls)
                      Positioned(
                        top: -2,
                        right: -2,
                        child:
                        Container(
                          width: 8,
                          height: 8,
                          decoration:
                          const BoxDecoration(
                            color:
                            Colors.amber,
                            shape:
                            BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                label:
                'نظرسنجی‌ها',
              ),

              // ---------------------------------------------
              // پروفایل
              // ---------------------------------------------

              const BottomNavigationBarItem(
                icon: Icon(
                  Icons.person_outline,
                ),
                activeIcon:
                Icon(
                  Icons.person,
                ),
                label:
                'پروفایل',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// کارت امور مالی
// =====================================================

class _FinancialCard
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String amount;
  final Color color;

  const _FinancialCard({
    required this.icon,
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black
                .withOpacity(
              0.045,
            ),
            blurRadius: 12,
            offset:
            const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: Row(
        children: [

          Container(
            width: 48,
            height: 48,
            decoration:
            BoxDecoration(
              color:
              color.withOpacity(
                0.10,
              ),
              shape:
              BoxShape.circle,
            ),
            child:
            Icon(
              icon,
              color:
              color,
              size: 25,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Text(
              title,
              style:
              const TextStyle(
                fontSize: 14,
                color:
                Color(
                  0xff607D8B,
                ),
              ),
            ),
          ),

          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [

              Text(
                amount,
                style:
                const TextStyle(
                  fontSize: 17,
                  fontWeight:
                  FontWeight.bold,
                  color:
                  Color(
                    0xff263238,
                  ),
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              const Text(
                'تومان',
                style:
                TextStyle(
                  fontSize: 11,
                  color:
                  Colors.grey,
                ),
              ),
            ],
          ),
        ],
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

    const strokeWidth =
    25.0;

    final backgroundPaint =
    Paint()
      ..color =
      const Color(
        0xffE2E5E8,
      )
      ..style =
          PaintingStyle.stroke
      ..strokeWidth =
          strokeWidth
      ..strokeCap =
          StrokeCap.round;

    // رنگ نمودار ملایم‌تر
    final paidPaint =
    Paint()
      ..color =
      const Color(
        0xff7654A6,
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
      covariant
      _ChargeChartPainter
      oldDelegate,
      ) {
    return oldDelegate
        .paidPercent !=
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

  String toPersianDigits(
      String value,
      ) {
    const english =
        '0123456789';

    const persian =
        '۰۱۲۳۴۵۶۷۸۹';

    for (
    int i = 0;
    i < english.length;
    i++
    ) {
      value = value.replaceAll(
        english[i],
        persian[i],
      );
    }

    return value;
  }

  String formatAmount(
      int amount,
      ) {
    final text =
    amount.toString();

    final buffer =
    StringBuffer();

    for (
    int i = 0;
    i < text.length;
    i++
    ) {
      if (i > 0 &&
          (text.length - i) %
              3 ==
              0) {
        buffer.write(
          '٬',
        );
      }

      buffer.write(
        text[i],
      );
    }

    return toPersianDigits(
      buffer.toString(),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Column(
      children: [

        Row(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [

            Container(
              width: 11,
              height: 11,
              decoration:
              BoxDecoration(
                color:
                iconColor,
                shape:
                BoxShape.circle,
              ),
            ),

            const SizedBox(
              width: 6,
            ),

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

        const SizedBox(
          height: 6,
        ),

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
      const EdgeInsets.all(
        16,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black
                .withOpacity(
              0.025,
            ),
            blurRadius: 8,
            offset:
            const Offset(
              0,
              3,
            ),
          ),
        ],
      ),
      child: Row(
        children: [

          Icon(
            icon,
            color:
            const Color(
              0xff7654A6,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Text(
            '$title:',
            style:
            const TextStyle(
              color:
              Colors.grey,
            ),
          ),

          const SizedBox(
            width: 8,
          ),

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