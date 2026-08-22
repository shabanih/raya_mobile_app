import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/announcement_service.dart';
import '../services/api_service.dart';
import '../services/poll_service.dart';
import '../storage/token_storage.dart';

import 'announcements_screen.dart';
import 'charges_screen.dart';
import 'login_screen.dart';
import 'polls_screen.dart';
import 'finance_screen.dart';
import 'finance_menu_screen.dart';
import 'messages_screen.dart';

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
  int currentIndex = 2;

  bool hasNewAnnouncements = false;
  bool hasNewPolls = false;
  bool hasNewMessages = false;

  int unreadMessageCount = 0;
  bool showNewMessageBanner = false;
  bool isLoadingMessageStatus = false;

  Map<String, dynamic>? dashboardData;
  bool isDashboardLoading = true;

  List<Map<String, dynamic>> announcements = [];

  PageController? _announcementController;
  Timer? _announcementTimer;

  int _announcementIndex = 0;

  @override
  void initState() {
    super.initState();

    // debugPrint('HOME DATA = ${widget.data}');

    loadDashboard();
    loadPollStatus();
    loadAnnouncementData();
    loadMessageStatus();
  }

  @override
  void dispose() {
    _announcementTimer?.cancel();
    _announcementController?.dispose();
    super.dispose();
  }

  // =====================================================
  // اعلان پیام جدید
  // =====================================================
  Widget _buildNewMessageBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xffD32F2F),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffD32F2F)
                .withOpacity(0.20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_unread_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const MessagesScreen(),
                  ),
                );

                // بعد از برگشت، وضعیت واقعی پیام‌ها را بگیر
                await loadMessageStatus(
                  forceShow: true,
                );
              },
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text(
                    'پیام جدید از طرف مدیر',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    '${toPersianDigits(unreadMessageCount.toString())} پیام از طرف مدیر دارید',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // دکمه بستن
          IconButton(
            tooltip: 'بستن',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 36,
              minHeight: 36,
            ),
            onPressed: () {
              setState(() {
                // فقط نوار بسته می‌شود
                // تعداد پیام‌ها تغییر نمی‌کند
                showNewMessageBanner = false;
              });
            },
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // اعداد فارسی
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
    final amount = int.tryParse(
      value?.toString() ?? '0',
    ) ??
        0;

    final text = amount.toString();

    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('٬');
      }

      buffer.write(text[i]);
    }

    return toPersianDigits(
      buffer.toString(),
    );
  }

  // =====================================================
  // تاریخ شمسی
  //
  // بدون پکیج خارجی
  // =====================================================

  String formatPersianDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    final raw = value.toString();

    if (raw.isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(raw);

      final jalali = _gregorianToJalali(
        date.year,
        date.month,
        date.day,
      );

      return toPersianDigits(
        '${jalali[0]}/${jalali[1].toString().padLeft(2, '0')}/${jalali[2].toString().padLeft(2, '0')}',
      );
    } catch (_) {
      return raw;
    }
  }

  List<int> _gregorianToJalali(
      int gy,
      int gm,
      int gd,
      ) {
    final gDaysInMonth = <int>[
      31,
      28,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31,
    ];

    final jDaysInMonth = <int>[
      31,
      31,
      31,
      31,
      31,
      31,
      30,
      30,
      30,
      30,
      30,
      29,
    ];

    int gy2 = gy - 1600;
    int gm2 = gm - 1;
    int gd2 = gd - 1;

    int gDayNo =
        365 * gy2 +
            ((gy2 + 3) ~/ 4) -
            ((gy2 + 99) ~/ 100) +
            ((gy2 + 399) ~/ 400);

    for (int i = 0; i < gm2; i++) {
      gDayNo += gDaysInMonth[i];
    }

    if (gm2 > 1 &&
        ((gy % 4 == 0 && gy % 100 != 0) ||
            gy % 400 == 0)) {
      gDayNo++;
    }

    gDayNo += gd2;

    int jDayNo = gDayNo - 79;

    int jNp = jDayNo ~/ 12053;

    int jy = 979 + 33 * jNp;

    jDayNo %= 12053;

    jy += 4 * (jDayNo ~/ 1461);

    jDayNo %= 1461;

    if (jDayNo >= 366) {
      jy += (jDayNo - 1) ~/ 365;
      jDayNo = (jDayNo - 1) % 365;
    }

    int jm = 0;

    for (int i = 0; i < 11 && jDayNo >= jDaysInMonth[i]; i++) {
      jDayNo -= jDaysInMonth[i];
      jm++;
    }

    return [
      jy,
      jm + 1,
      jDayNo + 1,
    ];
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

  String get fullName {
    final name =
    user['full_name']?.toString();

    if (name == null || name.isEmpty) {
      return 'کاربر';
    }

    return name;
  }

  String get houseName {
    final name =
    house['name']?.toString();

    if (name == null || name.isEmpty) {
      return '-';
    }

    return name;
  }

  String get unitNumber {
    final number =
    unit['unit']?.toString();

    if (number == null || number.isEmpty) {
      return '-';
    }

    return toPersianDigits(number);
  }

  // =====================================================
  // داشبورد
  // =====================================================

  Future<void> loadDashboard() async {
    try {
      // debugPrint(
      //   '========== LOAD DASHBOARD ==========',
      // );

      final data =
      await ApiService().getDashboard();

      // debugPrint(
      //   'DASHBOARD DATA = $data',
      // );

      if (!mounted) return;

      setState(() {
        dashboardData = data;
        isDashboardLoading = false;
      });
    } catch (e) {
      // debugPrint(
      //   'LOAD DASHBOARD ERROR = $e',
      // );

      if (!mounted) return;

      setState(() {
        isDashboardLoading = false;
      });
    }
  }

  // =====================================================
  // نظرسنجی
  // =====================================================

  Future<void> loadPollStatus() async {
    try {
      final result =
      await PollService.getPolls();

      if (!mounted) return;

      bool newPollExists = false;

      for (final poll in result) {
        if (poll is Map<String, dynamic>) {
          final isActive =
              poll['is_active'] == true;

          final hasVoted =
              poll['has_voted'] == true;

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
      // debugPrint(
      //   'LOAD POLL STATUS ERROR: $e',
      // );
    }
  }

  // =====================================================
  // پیام ها
  // =====================================================
  Future<void> loadMessageStatus({
    bool forceShow = true,
  }) async {
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

        if (count > 0) {
          if (forceShow) {
            showNewMessageBanner = true;
          }
        } else {
          // هیچ پیام خوانده‌نشده‌ای باقی نمانده
          showNewMessageBanner = false;
        }
      });
    } catch (e) {
      debugPrint(
        'LOAD MESSAGE STATUS ERROR: $e',
      );
    } finally {
      isLoadingMessageStatus = false;
    }
  }

  Future<void> openMessages() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MessagesScreen(),
      ),
    );

    await loadMessageStatus();
  }

  // Future<void> loadMessageStatus({
  //   bool forceShow = true,
  // }) async {
  //   if (isLoadingMessageStatus) return;
  //
  //   isLoadingMessageStatus = true;
  //
  //   try {
  //     final result = await ApiService().getMessages();
  //
  //     final dynamic unreadData =
  //     result['unread_count'];
  //
  //     final int count = unreadData is num
  //         ? unreadData.toInt()
  //         : int.tryParse(
  //       unreadData?.toString() ?? '',
  //     ) ??
  //         0;
  //
  //     if (!mounted) return;
  //
  //     setState(() {
  //       unreadMessageCount = count;
  //
  //       if (count > 0) {
  //         // با هر بار ورود مجدد به Home
  //         // نوار دوباره نمایش داده شود.
  //         if (forceShow) {
  //           showNewMessageBanner = true;
  //         }
  //       } else {
  //         // وقتی همه پیام‌ها خوانده شده‌اند
  //         // نوار دیگر نمایش داده نمی‌شود.
  //         showNewMessageBanner = false;
  //       }
  //     });
  //   } catch (e) {
  //     debugPrint(
  //       'LOAD MESSAGE STATUS ERROR: $e',
  //     );
  //   } finally {
  //     isLoadingMessageStatus = false;
  //   }
  // }
  // =====================================================
  // اطلاعیه‌ها
  // =====================================================

  Future<void> loadAnnouncementData() async {
    try {
      final result =
      await AnnouncementService
          .getAnnouncements();

      if (!mounted) return;

      final userId =
      int.tryParse(
        user['id']?.toString() ?? '',
      );

      bool newAnnouncements = false;

      if (userId != null) {
        newAnnouncements =
        await AnnouncementService
            .hasNewAnnouncements(
          userId,
        );
      }

      setState(() {
        announcements = result;
        hasNewAnnouncements =
            newAnnouncements;
      });

      _setupAnnouncementSlider();
    } catch (e) {
      // debugPrint(
      //   'LOAD ANNOUNCEMENT ERROR: $e',
      // );
    }
  }

  void _setupAnnouncementSlider() {
    _announcementTimer?.cancel();

    if (announcements.length <= 1) {
      return;
    }

    _announcementController =
        PageController();

    _announcementTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) {
        if (!mounted ||
            _announcementController == null) {
          return;
        }

        if (!_announcementController!
            .hasClients) {
          return;
        }

        _announcementIndex++;

        if (_announcementIndex >=
            announcements.length) {
          _announcementIndex = 0;
        }

        _announcementController!
            .animateToPage(
          _announcementIndex,
          duration:
          const Duration(
            milliseconds: 500,
          ),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  // =====================================================
  // باز کردن اطلاعیه‌ها
  // =====================================================

  Future<void> openAnnouncements() async {
    final userId =
    int.tryParse(
      user['id']?.toString() ?? '',
    );

    if (userId == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AnnouncementsScreen(
              userId: userId,
            ),
      ),
    );

    await loadAnnouncementData();
  }

  // =====================================================
  // آخرین شارژ
  // =====================================================

  Map<String, dynamic> get latestCharge {
    return (dashboardData?[
    'latest_charge']
    as Map<String, dynamic>?) ??
        {};
  }

  String get latestChargeTitle {
    final title =
    latestCharge['title']
        ?.toString();

    if (title == null ||
        title.isEmpty) {
      return 'شارژی ثبت نشده است';
    }

    return toPersianDigits(title);
  }

  // =====================================================
  // آمار شارژ
  // =====================================================

  Map<String, dynamic> get statistics {
    return (dashboardData?[
    'statistics']
    as Map<String, dynamic>?) ??
        {};
  }

  int get paidCount {
    return int.tryParse(
      statistics['paid_count']
          ?.toString() ??
          '0',
    ) ??
        0;
  }

  int get unpaidCount {
    return int.tryParse(
      statistics['unpaid_count']
          ?.toString() ??
          '0',
    ) ??
        0;
  }

  int get pendingCount {
    return int.tryParse(
      statistics['pending_count']
          ?.toString() ??
          '0',
    ) ??
        0;
  }

  int get paidAmount {
    return int.tryParse(
      statistics['total_paid']
          ?.toString() ??
          '0',
    ) ??
        0;
  }

  int get unpaidAmount {
    return int.tryParse(
      statistics['total_debt']
          ?.toString() ??
          '0',
    ) ??
        0;
  }

  // =====================================================
  // صفحه اصلی
  // =====================================================
  Widget buildHomePage() {
    final totalCount =
        paidCount +
            unpaidCount +
            pendingCount;

    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xff00ACC1),

        onRefresh: () async {
          await Future.wait([
            loadDashboard(),
            loadAnnouncementData(),
            loadPollStatus(),
            loadMessageStatus(
              forceShow: true,
            ),
          ]);
        },

        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            30,
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,

            children: [
              // =========================================
              // پیام جدید
              // =========================================

              if (showNewMessageBanner &&
                  unreadMessageCount > 0)
                _buildNewMessageBanner(),

              // =========================================
              // مشخصات کاربر
              // =========================================

              _buildUserCard(),

              const SizedBox(height: 14),

              // =========================================
              // اطلاعیه‌ها
              // =========================================

              _buildAnnouncementSlider(),

              const SizedBox(height: 18),

              // =========================================
              // وضعیت شارژ
              // =========================================

              _buildChargeStatusCard(
                totalCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Widget buildHomePage() {
  //
  //   if (showNewMessageBanner && unreadMessageCount > 0)
  //     _buildNewMessageBanner(),
  //
  //
  //   const SizedBox(height: 12),
  //
  //   final totalCount =
  //       paidCount +
  //           unpaidCount +
  //           pendingCount;
  //
  //   return SafeArea(
  //     child: RefreshIndicator(
  //       color:
  //       const Color(0xff00ACC1),
  //       onRefresh: () async {
  //         await Future.wait([
  //           loadDashboard(),
  //           loadAnnouncementData(),
  //           loadPollStatus(),
  //         ]);
  //       },
  //       child: SingleChildScrollView(
  //         physics:
  //         const AlwaysScrollableScrollPhysics(),
  //         padding:
  //         const EdgeInsets.fromLTRB(
  //           18,
  //           18,
  //           18,
  //           30,
  //         ),
  //         child: Column(
  //           crossAxisAlignment:
  //           CrossAxisAlignment.stretch,
  //           children: [
  //             // =================================================
  //             // مشخصات کاربر و ساختمان
  //             // =================================================
  //
  //             _buildUserCard(),
  //
  //             const SizedBox(height: 14),
  //
  //             // =================================================
  //             // اطلاعیه‌ها
  //             // =================================================
  //
  //             _buildAnnouncementSlider(),
  //
  //             const SizedBox(height: 18),
  //
  //             // =================================================
  //             // وضعیت شارژ
  //             // =================================================
  //
  //             _buildChargeStatusCard(
  //               totalCount,
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // =====================================================
  // کارت مشخصات
  // =====================================================

  Widget _buildUserCard() {
    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color:
          const Color(0xff00ACC1)
              .withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(
              0.055,
            ),
            blurRadius: 14,
            offset:
            const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration:
            BoxDecoration(
              color:
              const Color(0xff00ACC1)
                  .withOpacity(
                0.10,
              ),
              shape:
              BoxShape.circle,
            ),
            child:
            const Icon(
              Icons.apartment_rounded,
              color:
              Color(0xff00ACC1),
              size: 29,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'مجتمع مسکونی $houseName',
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    Color(0xff263238),
                  ),
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    const Icon(
                      Icons.home_outlined,
                      size: 17,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'واحد شماره $unitNumber',
                      style:
                      const TextStyle(
                        fontSize: 13,
                        color:
                        Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 17,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${unit['is_renter'] == true ? 'مستأجر' : 'مالک'}: $fullName',
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style:
                        const TextStyle(
                          fontSize: 13,
                          color:
                          Colors.grey,
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
  // اسلایدر اطلاعیه
  // =====================================================

  Widget _buildAnnouncementSlider() {
    if (announcements.isEmpty) {
      return _buildEmptyAnnouncementCard();
    }

    if (announcements.length == 1) {
      return _buildAnnouncementItem(
        announcements.first,
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller:
            _announcementController,
            itemCount:
            announcements.length,
            onPageChanged: (index) {
              setState(() {
                _announcementIndex =
                    index;
              });
            },
            itemBuilder:
                (context, index) {
              return Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 2,
                ),
                child:
                _buildAnnouncementItem(
                  announcements[index],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: List.generate(
            announcements.length,
                (index) {
              final selected =
                  index ==
                      _announcementIndex;

              return AnimatedContainer(
                duration:
                const Duration(
                  milliseconds: 1000,
                ),
                margin:
                const EdgeInsets.symmetric(
                  horizontal: 3,
                ),
                width:
                selected ? 18 : 6,
                height: 6,
                decoration:
                BoxDecoration(
                  color: selected
                      ? const Color(
                    0xff610DB5,
                  )
                      : const Color(
                    0xffD8C7E8,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // =====================================================
  // کارت اطلاعیه
  // =====================================================

  Widget _buildAnnouncementItem(
      Map<String, dynamic> announcement,
      ) {
    final title =
        announcement['title']
            ?.toString()
            .trim() ??
            'اطلاعیه ساختمان';

    final content =
        announcement['content']
            ?.toString() ??
            announcement['description']
                ?.toString() ??
            '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: openAnnouncements,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xff7541B5),
                Color(0xff5B2298),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff610DB5).withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // فلش سمت چپ
              // const Positioned(
              //   left: 0,
              //   top: 0,
              //   bottom: 0,
              //   child: Center(
              //     child: Icon(
              //       Icons.chevron_left_rounded,
              //       color: Colors.white,
              //       size: 23,
              //     ),
              //   ),
              // ),

              // محتوای اطلاعیه
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // آیکن اطلاعیه
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // عنوان
                    Text(
                      toPersianDigits(title),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    // متن اطلاعیه
                    Text(
                      toPersianDigits(content),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.90),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyAnnouncementCard() {
    return Container(
      height: 110,
      width: double.infinity,
      decoration:
      BoxDecoration(
        color:
        const Color(0xff610DB5),
        borderRadius:
        BorderRadius.circular(22),
      ),
      child: const Center(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons.campaign_outlined,
              color: Colors.white,
              size: 30,
            ),
            SizedBox(height: 7),
            Text(
              'اطلاعیه‌ای وجود ندارد',
              style:
              TextStyle(
                color: Colors.white,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // کارت وضعیت شارژ
  // =====================================================

  Widget _buildChargeStatusCard(
      int totalCount,
      ) {
    final paidPercent =
    totalCount == 0
        ? 0.0
        : paidCount / totalCount;

    final unpaidPercent =
    totalCount == 0
        ? 0.0
        : unpaidCount / totalCount;

    final pendingPercent =
    totalCount == 0
        ? 0.0
        : pendingCount / totalCount;

    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(22),
        border: Border.all(
          color: Colors.black
              .withOpacity(0.035),
        ),
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
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xff00ACC1,
                  ).withOpacity(
                    0.10,
                  ),
                  shape:
                  BoxShape.circle,
                ),
                child:
                const Icon(
                  Icons.pie_chart_outline_rounded,
                  color:
                  Color(0xff00ACC1),
                  size: 21,
                ),
              ),

              const SizedBox(width: 10),

              const Text(
                'وضعیت شارژ',
                style:
                TextStyle(
                  fontSize: 17,
                  fontWeight:
                  FontWeight.bold,
                  color:
                  Color(0xff263238),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // =================================================
          // نمودار کوچک‌تر
          // =================================================

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 145,
                height: 145,
                child: CustomPaint(
                  painter:
                  _ChargeDonutPainter(
                    paidCount:
                    paidCount,
                    unpaidCount:
                    unpaidCount,
                    pendingCount:
                    pendingCount,
                  ),
                  child:
                  Center(
                    child: Column(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        Text(
                          toPersianDigits(
                            totalCount
                                .toString(),
                          ),
                          style:
                          const TextStyle(
                            fontSize: 27,
                            fontWeight:
                            FontWeight.bold,
                            color:
                            Color(
                              0xff263238,
                            ),
                          ),
                        ),
                        const Text(
                          'شارژ',
                          style:
                          TextStyle(
                            fontSize: 11,
                            color:
                            Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch,
                  children: [
                    _StatusCountRow(
                      title:
                      'پرداخت شده',
                      count:
                      paidCount,
                      color:
                      const Color(
                        0xff11c539,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _StatusCountRow(
                      title:
                      'پرداخت نشده',
                      count:
                      unpaidCount,
                      color:
                      const Color(
                        0xffff2600,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _StatusCountRow(
                      title:
                      'در انتظار تأیید',
                      count:
                      pendingCount,
                      color:
                      const Color(
                        0xfff6963e,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const Divider(
            height: 1,
          ),

          const SizedBox(height: 16),

          // =================================================
          // مبالغ زیر نمودار
          // =================================================

          Row(
            children: [
              Expanded(
                child:
                _AmountInfo(
                  title:
                  'مبلغ پرداخت شده',
                  amount:
                  paidAmount,
                  icon:
                  Icons.check_circle_outline,
                  color:
                  const Color(
                    0xff11c539,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child:
                _AmountInfo(
                  title:
                  'مبلغ پرداخت نشده',
                  amount:
                  unpaidAmount,
                  icon:
                  Icons
                      .error_outline_rounded,
                  color:
                  const Color(
                    0xfff87803,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // =================================================
          // آخرین شارژ
          // =================================================

          Material(
            color:
            const Color(
              0xffF5F8FA,
            ),
            borderRadius:
            BorderRadius.circular(
              16,
            ),
            child: InkWell(
              borderRadius:
              BorderRadius.circular(
                16,
              ),
              onTap: () {
                setState(() {
                  currentIndex = 0;
                });
              },
              child:
              Padding(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                          0xff00ACC1,
                        ).withOpacity(
                          0.10,
                        ),
                        shape:
                        BoxShape.circle,
                      ),
                      child:
                      const Icon(
                        Icons
                            .receipt_long_outlined,
                        color:
                        Color(
                          0xff00ACC1,
                        ),
                        size: 21,
                      ),
                    ),

                    const SizedBox(
                      width: 11,
                    ),

                    Expanded(
                      child:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          const Text(
                            'آخرین شارژ اعلام شده',
                            style:
                            TextStyle(
                              fontSize:
                              11,
                              color:
                              Colors.grey,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            latestChargeTitle,
                            maxLines:
                            1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              fontSize:
                              14,
                              fontWeight:
                              FontWeight
                                  .bold,
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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

  Widget buildFinancePage() {
    return const FinanceMenuScreen();
  }
  // =====================================================
  // صفحه پیام ها
  // =====================================================

  Widget buildMessagesPage() {
    return const MessagesScreen();
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
        child:
        Column(
          children: [
            const SizedBox(height: 25),

            const CircleAvatar(
              radius: 45,
              backgroundColor:
              Color(0xff00ACC1),
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              fullName,
              style:
              const TextStyle(
                fontSize: 22,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

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

            const SizedBox(height: 30),

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
                  color: Colors.red,
                ),
                label:
                const Text(
                  'خروج از حساب کاربری',
                  style:
                  TextStyle(
                    color: Colors.red,
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
                    color: Colors.red
                        .withOpacity(
                      0.25,
                    ),
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
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
          child:
          AlertDialog(
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(
                20,
              ),
            ),
            title:
            const Row(
              children: [
                Icon(
                  Icons
                      .logout_rounded,
                  color:
                  Colors.red,
                ),
                SizedBox(width: 10),
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
            content:
            const Text(
              'آیا مطمئن هستید که می‌خواهید از حساب کاربری خود خارج شوید؟',
              style:
              TextStyle(
                fontSize: 14,
                height: 1.7,
              ),
            ),
            actions: [
              TextButton(
                onPressed:
                    () {
                  Navigator.pop(
                    context,
                    false,
                  );
                },
                child:
                const Text(
                  'انصراف',
                  style:
                  TextStyle(
                    color:
                    Colors.grey,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed:
                    () {
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
                    BorderRadius
                        .circular(
                      12,
                    ),
                  ),
                ),
                child:
                const Text(
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
  // صفحات موقت
  // =====================================================

  Widget _buildComingSoonPage({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return SafeArea(
      child:
      Center(
        child:
        Padding(
          padding:
          const EdgeInsets.all(
            30,
          ),
          child:
          Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xff00ACC1,
                  ).withOpacity(
                    0.10,
                  ),
                  shape:
                  BoxShape.circle,
                ),
                child:
                Icon(
                  icon,
                  size: 40,
                  color:
                  const Color(
                    0xff00ACC1,
                  ),
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Text(
                title,
                style:
                const TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                description,
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  color:
                  Colors.grey,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // تغییر صفحه
  // =====================================================

  // void onNavigationTap(
  //     int index,
  //     ) {
  //   setState(() {
  //     currentIndex = index;
  //   });
  // }
  void onNavigationTap(int index) {
    setState(() {
      currentIndex = index;
    });

    // هر بار که وارد صفحه خانه می‌شویم
    // وضعیت پیام‌ها دوباره بررسی شود.
    if (index == 2) {
      loadMessageStatus(
        forceShow: true,
      );
    }
  }
  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final pages = [
      buildChargesPage(),
      buildFinancePage(),
      buildHomePage(),
      buildMessagesPage(),
      buildProfilePage(),
    ];

    return Directionality(
      textDirection:
      TextDirection.rtl,
      child:
      Scaffold(
        backgroundColor:
        const Color(
          0xffF5F8FA,
        ),

        // =================================================
        // AppBar
        // =================================================

        appBar:
        AppBar(
          backgroundColor:
          const Color(
            0xff00ACC1,
          ),
          foregroundColor:
          Colors.white,
          elevation: 0,
          centerTitle: false,

          title:
          Row(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 45,
                padding:
                const EdgeInsets.all(
                  8,
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
                width: 12,
              ),
              const Text(
                'رایا شارژ',
                style:
                TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),

          actions: [
            // =============================================
            // نظرسنجی
            // =============================================

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
                    Icons
                        .poll_outlined,
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

            // =============================================
            // اطلاعیه
            // =============================================

            Stack(
              clipBehavior:
              Clip.none,
              children: [
                IconButton(
                  tooltip:
                  'اطلاعیه‌ها',
                  onPressed:
                  openAnnouncements,
                  icon:
                  const Icon(
                    Icons
                        .notifications_none_rounded,
                    size: 27,
                  ),
                ),

                if (hasNewAnnouncements)
                  Positioned(
                    top: 15,
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
        ),

        body:
        IndexedStack(
          index:
          currentIndex,
          children:
          pages,
        ),

        // =================================================
        // نوار پایین
        //
        // راست به چپ:
        // خانه | شارژها | امور مالی | پروفایل
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
            currentIndex: currentIndex,
            onTap: onNavigationTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,

            selectedItemColor: const Color(0xff00ACC1),
            unselectedItemColor: Colors.grey,

            selectedFontSize: 12,
            unselectedFontSize: 11,

            items: [
              // =========================================
              // شارژها
              // =========================================

              const BottomNavigationBarItem(
                icon: Icon(
                  Icons.receipt_long_outlined,
                ),
                activeIcon: Icon(
                  Icons.receipt_long,
                ),
                label: 'شارژها',
              ),

              // =========================================
              // امور مالی
              // =========================================

              const BottomNavigationBarItem(
                icon: Icon(
                  Icons.account_balance_wallet_outlined,
                ),
                activeIcon: Icon(
                  Icons.account_balance_wallet,
                ),
                label: 'امور مالی',
              ),

              // =========================================
              // خانه - متمایز
              // =========================================

              BottomNavigationBarItem(
                icon: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: currentIndex == 2
                        ? const Color(0xff00ACC1)
                        : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: currentIndex == 2
                        ? [
                      BoxShadow(
                        color: const Color(0xff00ACC1)
                            .withOpacity(0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                        : null,
                    border: currentIndex == 2
                        ? null
                        : Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    currentIndex == 2
                        ? Icons.home_rounded
                        : Icons.home_outlined,
                    color: currentIndex == 2
                        ? Colors.white
                        : Colors.grey,
                    size: 27,
                  ),
                ),
                label: 'خانه',
              ),

              // =========================================
              // پیام‌ها
              // =========================================

              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                    ),

                    if (hasNewMessages)
                      Positioned(
                        top: -3,
                        right: -4,
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
                activeIcon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.mail_rounded,
                    ),

                    if (hasNewMessages)
                      Positioned(
                        top: -3,
                        right: -4,
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
                label: 'پیام‌ها',
              ),

              // =========================================
              // پروفایل
              // =========================================

              const BottomNavigationBarItem(
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
// نمودار Donut
// =====================================================

class _ChargeDonutPainter
    extends CustomPainter {
  final int paidCount;
  final int unpaidCount;
  final int pendingCount;

  _ChargeDonutPainter({
    required this.paidCount,
    required this.unpaidCount,
    required this.pendingCount,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final center =
    Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        math.min(
          size.width,
          size.height,
        ) /
            2 -
            12;

    const strokeWidth =
    19.0;

    final total =
        paidCount +
            unpaidCount +
            pendingCount;

    final backgroundPaint =
    Paint()
      ..color =
      const Color(
        0xffEEF1F3,
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

    if (total <= 0) {
      return;
    }

    final colors = [
      const Color(
        0xff159c35,
      ),
      const Color(
        0xffff2600,
      ),
      const Color(
        0xfff6963e,
      ),
    ];

    final counts = [
      paidCount,
      unpaidCount,
      pendingCount,
    ];

    double startAngle =
        -math.pi / 2;

    for (int i = 0;
    i < counts.length;
    i++) {
      if (counts[i] <= 0) {
        continue;
      }

      final sweepAngle =
          2 *
              math.pi *
              counts[i] /
              total;

      final paint =
      Paint()
        ..color =
        colors[i]
        ..style =
            PaintingStyle.stroke
        ..strokeWidth =
            strokeWidth
        ..strokeCap =
            StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle +=
          sweepAngle;
    }
  }

  @override
  bool shouldRepaint(
      covariant _ChargeDonutPainter
      oldDelegate,
      ) {
    return oldDelegate.paidCount !=
        paidCount ||
        oldDelegate.unpaidCount !=
            unpaidCount ||
        oldDelegate.pendingCount !=
            pendingCount;
  }
}

// =====================================================
// ردیف تعداد وضعیت
// =====================================================

class _StatusCountRow
    extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _StatusCountRow({
    required this.title,
    required this.count,
    required this.color,
  });

  String toPersianDigits(
      String value,
      ) {
    const english =
        '0123456789';

    const persian =
        '۰۱۲۳۴۵۶۷۸۹';

    for (int i = 0;
    i < english.length;
    i++) {
      value =
          value.replaceAll(
            english[i],
            persian[i],
          );
    }

    return value;
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
          BoxDecoration(
            color: color,
            shape:
            BoxShape.circle,
          ),
        ),

        const SizedBox(
          width: 7,
        ),

        Expanded(
          child: Text(
            title,
            style:
            const TextStyle(
              fontSize: 12,
              color:
              Colors.grey,
            ),
          ),
        ),

        Text(
          toPersianDigits(
            count.toString(),
          ),
          style:
          const TextStyle(
            fontSize: 15,
            fontWeight:
            FontWeight.bold,
            color:
            Color(0xff263238),
          ),
        ),
      ],
    );
  }
}

// =====================================================
// اطلاعات مبلغ
// =====================================================

class _AmountInfo
    extends StatelessWidget {
  final String title;
  final int amount;
  final IconData icon;
  final Color color;

  const _AmountInfo({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  String toPersianDigits(
      String value,
      ) {
    const english =
        '0123456789';

    const persian =
        '۰۱۲۳۴۵۶۷۸۹';

    for (int i = 0;
    i < english.length;
    i++) {
      value =
          value.replaceAll(
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

    for (int i = 0;
    i < text.length;
    i++) {
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
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 11,
      ),
      decoration:
      BoxDecoration(
        color:
        color.withOpacity(
          0.07,
        ),
        borderRadius:
        BorderRadius.circular(
          14,
        ),
      ),
      child:
      Column(
        children: [
          Row(
            mainAxisAlignment:
            MainAxisAlignment
                .center,
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(
                width: 5,
              ),
              Flexible(
                child:
                Text(
                  title,
                  maxLines:
                  1,
                  overflow:
                  TextOverflow
                      .ellipsis,
                  textAlign:
                  TextAlign.center,
                  style:
                  TextStyle(
                    fontSize: 10.5,
                    color:
                    color,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 5,
          ),

          FittedBox(
            fit:
            BoxFit.scaleDown,
            child:
            Text(
              '${formatAmount(amount)} تومان',
              style:
              const TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.bold,
                color:
                Color(
                  0xff263238,
                ),
              ),
            ),
          ),
        ],
      ),
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
      ),
      child:
      Row(
        children: [
          Icon(
            icon,
            color:
            const Color(
              0xff610DB5,
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
            child:
            Text(
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