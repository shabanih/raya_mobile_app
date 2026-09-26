import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/announcement_service.dart';
// import '../../services/poll_service.dart';
import '../../storage/token_storage.dart';


import '../announcements_screen.dart';
import '../login_screen.dart';
import '../messages_screen.dart';
import '../finance_menu_screen.dart';
import 'manager_announcements_screen.dart';
import 'manager_messages_screen.dart';
import 'manager_banks_screen.dart';


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
  // وضعیت‌ها
  // -----------------------------------------------------

  bool hasNewAnnouncements = false;
  bool hasNewMessages = false;
  // bool hasNewPolls = false;

  int unreadMessageCount = 0;

  bool isLoadingMessageStatus = false;

  bool isDashboardLoading = true;

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

    // loadPollStatus();

    loadMessageStatus();

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
      return Map<String, dynamic>.from(
        dashboardUser,
      );
    }

    final initialUser = widget.data['user'];

    if (initialUser is Map) {
      return Map<String, dynamic>.from(
        initialUser,
      );
    }

    return {};
  }

  // =====================================================
  // اطلاعات ساختمان
  // =====================================================

  Map<String, dynamic> get house {
    final dashboardHouse = dashboardData?['house'];

    if (dashboardHouse is Map) {
      return Map<String, dynamic>.from(
        dashboardHouse,
      );
    }

    final initialHouse = widget.data['house'];

    if (initialHouse is Map) {
      return Map<String, dynamic>.from(
        initialHouse,
      );
    }

    return {};
  }

  // =====================================================
  // نام مدیر
  // =====================================================

  String get fullName {
    final name = user['full_name']
        ?.toString()
        .trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return 'مدیر';
  }

  // =====================================================
  // نام ساختمان
  // =====================================================

  String get houseName {
    final name = house['name']
        ?.toString()
        .trim();

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
      return Map<String, dynamic>.from(
        value,
      );
    }

    return {};
  }

  // =====================================================
  // مقدار آماری
  // =====================================================

  dynamic _dashboardValue(
      String key,
      ) {
    return statistics[key];
  }

  // =====================================================
  // تبدیل مقدار به int
  // =====================================================

  int _toInt(
      dynamic value,
      ) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  // =====================================================
  // موجودی صندوق
  // =====================================================

  int get cashBalance {
    return _toInt(
      _dashboardValue(
        'fund_balance',
      ),
    );
  }


  // =====================================================
  // تعداد واحدها
  // =====================================================

  int get unitCount {
    return _toInt(
      _dashboardValue(
        'units_count',
      ),
    );
  }


  // =====================================================
  // شارژهای پرداخت‌نشده
  // =====================================================

  int get unpaidCharges {
    return _toInt(
      _dashboardValue(
        'unpaid_charges',
      ),
    );
  }

  // =====================================================
  // اعتبار حساب پیامکی
  //
  // Backend:
  // 'sms_credit': middle_current_credit
  // =====================================================

  int get smsBalance {
    return _toInt(
      _dashboardValue(
        'sms_credit',
      ),
    );
  }

  // =====================================================
  // داشبورد مدیر
  // =====================================================

  Future<void> loadManagerDashboard() async {
    try {
      debugPrint(
        '==========================================',
      );

      debugPrint(
        'START LOAD MANAGER DASHBOARD',
      );

      final result =
      await ApiService().getManagerDashboard();

      debugPrint(
        'MANAGER DASHBOARD RESULT:',
      );

      debugPrint(
        result.toString(),
      );

      debugPrint(
        'SUCCESS: ${result['success']}',
      );

      debugPrint(
        'USER: ${result['user']}',
      );

      debugPrint(
        'HOUSE: ${result['house']}',
      );

      debugPrint(
        'STATISTICS: ${result['statistics']}',
      );

      debugPrint(
        '==========================================',
      );

      if (!mounted) {
        return;
      }

      if (result['success'] != true) {
        setState(() {
          isDashboardLoading = false;
        });

        debugPrint(
          'MANAGER DASHBOARD FAILED: '
              '${result['message']}',
        );

        return;
      }

      setState(() {
        dashboardData =
        Map<String, dynamic>.from(
          result,
        );

        isDashboardLoading = false;
      });

      debugPrint(
        'MANAGER DASHBOARD LOADED',
      );

      debugPrint(
        'HOUSE: $houseName',
      );

      debugPrint(
        'UNIT COUNT: $unitCount',
      );

      debugPrint(
        'FUND BALANCE: $cashBalance',
      );

      debugPrint(
        'UNPAID CHARGES: $unpaidCharges',
      );

      debugPrint(
        'SMS CREDIT: $smsBalance',
      );

    } catch (e, stackTrace) {
      debugPrint(
        '==========================================',
      );

      debugPrint(
        'MANAGER DASHBOARD ERROR',
      );

      debugPrint(
        e.toString(),
      );

      debugPrint(
        stackTrace.toString(),
      );

      debugPrint(
        '==========================================',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isDashboardLoading = false;
      });
    }
  }

  // =====================================================
  // اطلاعیه‌ها
  // =====================================================

  Future<void> loadAnnouncementData() async {
    try {
      final result =
      await AnnouncementService.getAnnouncements();

      if (!mounted) {
        return;
      }

      final List<Map<String, dynamic>> items = [];

      if (result is List) {
        for (final item in result) {
          if (item is Map) {
            items.add(
              Map<String, dynamic>.from(
                item,
              ),
            );
          }
        }
      }

      setState(() {
        announcements = items;

        hasNewAnnouncements =
            items.isNotEmpty;
      });

      _startAnnouncementSlider();

    } catch (e) {
      debugPrint(
        'ANNOUNCEMENT ERROR: $e',
      );
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

    _announcementController ??=
        PageController(
          initialPage: 0,
        );

    _announcementTimer =
        Timer.periodic(
          const Duration(
            seconds: 5,
          ),
              (_) {
            if (!mounted) {
              return;
            }

            if (_announcementController == null) {
              return;
            }

            if (!_announcementController!.hasClients) {
              return;
            }

            _announcementIndex++;

            if (_announcementIndex >=
                announcements.length) {
              _announcementIndex = 0;
            }

            _announcementController!.animateToPage(
              _announcementIndex,
              duration:
              const Duration(
                milliseconds: 500,
              ),
              curve:
              Curves.easeInOut,
            );
          },
        );
  }

  // =====================================================
  // باز کردن اطلاعیه‌ها
  // =====================================================

  Future<void> openAnnouncements() async {
    final int? userId =
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
  // پیام‌ها
  // =====================================================

  Future<void> loadMessageStatus() async {
    if (isLoadingMessageStatus) {
      return;
    }

    isLoadingMessageStatus = true;

    try {
      final result =
      await ApiService().getMessages();

      final dynamic unreadData =
      result['unread_count'];

      final int count =
      unreadData is num
          ? unreadData.toInt()
          : int.tryParse(
        unreadData?.toString() ?? '',
      ) ??
          0;

      if (!mounted) {
        return;
      }

      setState(() {
        unreadMessageCount = count;

        hasNewMessages =
            count > 0;
      });

    } catch (e) {
      debugPrint(
        'MESSAGE STATUS ERROR: $e',
      );

    } finally {
      isLoadingMessageStatus = false;
    }
  }

  // =====================================================
  // باز کردن پیام‌ها
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
  // نظرسنجی
  // =====================================================

  // Future<void> loadPollStatus() async {
  //   try {
  //     final result =
  //     await PollService.getPolls();
  //
  //     if (!mounted) {
  //       return;
  //     }
  //
  //     bool newPollExists = false;
  //
  //     for (final poll in result) {
  //       if (poll is Map<String, dynamic>) {
  //         final isActive =
  //             poll['is_active'] == true;
  //
  //         final hasVoted =
  //             poll['has_voted'] == true;
  //
  //         if (isActive && !hasVoted) {
  //           newPollExists = true;
  //           break;
  //         }
  //       }
  //     }
  //
  //     setState(() {
  //       hasNewPolls =
  //           newPollExists;
  //     });
  //
  //   } catch (e) {
  //     debugPrint(
  //       'POLL STATUS ERROR: $e',
  //     );
  //   }
  // }

  // =====================================================
  // تبدیل اعداد به فارسی
  // =====================================================

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

  // =====================================================
  // فرمت مبلغ
  // =====================================================

  String formatAmount(
      dynamic value,
      ) {
    final amount =
    _toInt(value);

    final text =
    amount.toString();

    final buffer =
    StringBuffer();

    for (
    int i = 0;
    i < text.length;
    i++
    ) {
      if (
      i > 0 &&
          (text.length - i) % 3 == 0
      ) {
        buffer.write('٬');
      }

      buffer.write(
        text[i],
      );
    }

    return toPersianDigits(
      buffer.toString(),
    );
  }

  // =====================================================
  // Navigation
  // =====================================================

  void onNavigationTap(
      int index,
      ) {
    setState(() {
      currentIndex = index;
    });

    if (index == 3) {
      loadMessageStatus();
    }
  }

  // =====================================================
  // هدر ساختمان و مدیر
  // =====================================================

  Widget _buildHouseHeader() {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border:
        Border.all(
          color:
          const Color(
            0xffECEFF1,
          ),
        ),
      ),
      child: Row(
        children: [

          Container(
            width: 48,
            height: 48,
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
              Icons.apartment_rounded,
              color:
              Color(
                0xff00ACC1,
              ),
              size: 26,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                Text(
                  'ساختمان: $houseName',
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    Color(
                      0xff263238,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  'مدیر: $fullName',
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 12,
                    color:
                    Colors.grey,
                    fontWeight:
                    FontWeight.w500,
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
        color:
        const Color(
          0xff00ACC1,
        ),
        onRefresh: () async {
          await Future.wait([
            loadManagerDashboard(),
            loadAnnouncementData(),
            // loadPollStatus(),
            loadMessageStatus(),
          ]);
        },
        child:
        SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          const EdgeInsets.fromLTRB(
            12,
            16,
            12,
            28,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [

              _buildHouseHeader(),

              const SizedBox(
                height: 16,
              ),

              // =================================================
              // اسلایدر آمار
              // =================================================

              _buildStatisticsSlider(),

              const SizedBox(
                height: 20,
              ),

              // =================================================
              // ردیف اول
              // =================================================

              Row(
                children: [

                  Expanded(
                    child:
                    _ManagerTopMenuItem(
                      title:
                      'مدیریت اطلاعیه‌ها',
                      icon:
                      Icons
                          .notifications_none_rounded,
                      color:
                      const Color(
                        0xff00ACC1,
                      ),
                      // badge:
                      // hasNewAnnouncements
                      //     ? 1
                      //     : null,
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

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                    _ManagerTopMenuItem(
                      title:
                      'مدیریت پیام‌ها',
                      icon:
                      Icons
                          .mail_outline_rounded,
                      color:
                      const Color(
                        0xff5E35B1,
                      ),
                      // badge:
                      // unreadMessageCount >
                      //     0
                      //     ? unreadMessageCount
                      //     : null,
                      onTap:
                      openMessages,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                    _ManagerTopMenuItem(
                      title:
                      'مدیریت تیکت‌ها',
                      icon:
                      Icons
                          .support_agent_outlined,
                      color:
                      const Color(
                        0xffEF6C00,
                      ),
                      onTap: () {
                        _showComingSoon(
                          'تیکت‌ها',
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 22,
              ),

              // =================================================
              // چهار کارت وسط
              // =================================================

              Row(
                children: [

                  Expanded(
                    child:
                    _ManagerMiddleMenuCard(
                      title:
                      'مدیریت واحدها',
                      icon:
                      Icons
                          .apartment_rounded,
                      color:
                      const Color(
                        0xff00897B,
                      ),
                      onTap: () {
                        _showComingSoon(
                          'مدیریت واحدها',
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                    width: 9,
                  ),

                  Expanded(
                    child:
                    _ManagerMiddleMenuCard(
                      title:
                      'مدیریت شارژها',
                      icon:
                      Icons
                          .receipt_long_outlined,
                      color:
                      const Color(
                        0xff00ACC1,
                      ),
                      onTap: () {
                        _showComingSoon(
                          'مدیریت شارژها',
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              Row(
                children: [

                  Expanded(
                    child:
                    _ManagerMiddleMenuCard(
                      title:
                      'مدیریت عملیات',
                      icon:
                      Icons
                          .settings_suggest_outlined,
                      color:
                      const Color(
                        0xff6D4C41,
                      ),
                      onTap: () {
                        _showComingSoon(
                          'مدیریت عملیات',
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                    width: 9,
                  ),

                  Expanded(
                    child:
                    _ManagerMiddleMenuCard(
                      title:
                      'مدیریت گزارش‌ها',
                      icon:
                      Icons
                          .assessment_outlined,
                      color:
                      const Color(
                        0xff3949AB,
                      ),
                      onTap: () {
                        _showComingSoon(
                          'مدیریت گزارش‌ها',
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 22,
              ),

              // =================================================
              // ردیف پایین
              // =================================================

              Row(
                children: [

                  Expanded(
                    child:
                    _ManagerTopMenuItem(
                      title:
                      'بانک‌ها',
                      icon:
                      Icons
                          .account_balance_outlined,
                      color:
                      const Color(
                        0xff1565C0,
                      ),
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

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                    _ManagerTopMenuItem(
                      title:
                      'پشتیبانی',
                      icon:
                      Icons
                          .headset_mic_outlined,
                      color:
                      const Color(
                        0xff7B1FA2,
                      ),
                      onTap: () {
                        _showComingSoon(
                          'پشتیبانی',
                        );
                      },
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child:
                    _ManagerTopMenuItem(
                      title:
                      'نظرسنجی',
                      icon:
                      Icons
                          .poll_outlined,
                      color:
                      const Color(
                        0xffF9A825,
                      ),
                      // badge:
                      // hasNewPolls
                      //     ? 1
                      //     : null,
                      onTap: () {
                        _showComingSoon(
                          'نظرسنجی',
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),
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

    _statisticsTimer =
        Timer.periodic(
          const Duration(
            seconds: 4,
          ),
              (_) {
            if (!mounted) {
              return;
            }

            if (!_statisticsController.hasClients) {
              return;
            }

            _statisticsIndex++;

            if (_statisticsIndex >= 4) {
              _statisticsIndex = 0;
            }

            _statisticsController.animateToPage(
              _statisticsIndex,
              duration:
              const Duration(
                milliseconds: 500,
              ),
              curve:
              Curves.easeInOut,
            );
          },
        );
  }

  // =====================================================
  // اسلایدر آمار
  // =====================================================

  Widget _buildStatisticsSlider() {
    final items = [

      // ---------------------------------------------
      // 1. تعداد واحدها
      // ---------------------------------------------

      _StatisticItem(
        title:
        'تعداد واحدها',
        value:
        unitCount,
        icon:
        Icons.apartment_rounded,
        gradient:
        const LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            Color(0xfff3c582),
            Color(0xffFFC107),
          ],
        ),
      ),

      // ---------------------------------------------
      // 2. موجودی صندوق
      // ---------------------------------------------

      _StatisticItem(
        title:
        'موجودی صندوق',
        value:
        cashBalance,
        icon:
        Icons
            .account_balance_wallet_outlined,
        gradient:
        const LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            Color(0xff20C997),
            Color(0xff198754),
          ],
        ),
        isAmount:
        true,
      ),

      // ---------------------------------------------
      // 3. شارژهای پرداخت‌نشده
      // ---------------------------------------------

      _StatisticItem(
        title:
        'شارژهای پرداخت‌نشده',
        value:
        unpaidCharges,
        icon:
        Icons.receipt_long_outlined,
        gradient:
        const LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            Color(0xffFF5C6C),
            Color(0xffDC3545),
          ],
        ),
      ),

      // ---------------------------------------------
      // 4. موجودی حساب پیامکی
      // ---------------------------------------------

      _StatisticItem(
        title:
        'موجودی حساب پیامکی',
        value:
        smsBalance,
        icon:
        Icons.sms_outlined,
        gradient:
        const LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            Color(0xff3DD5F3),
            Color(0xff0DCAF0),
          ],
        ),
        isAmount:
        true,
      ),
    ];

    return Column(
      children: [

        SizedBox(
          height: 118,
          width:
          double.infinity,
          child:
          PageView.builder(
            itemCount:
            items.length,
            controller:
            _statisticsController,
            onPageChanged:
                (index) {
              if (!mounted) {
                return;
              }

              setState(() {
                _statisticsIndex =
                    index;
              });
            },
            itemBuilder:
                (
                context,
                index,
                ) {
              final item =
              items[index];

              return Padding(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 2,
                ),
                child:
                _buildStatisticCard(
                  item,
                ),
              );
            },
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children:
          List.generate(
            items.length,
                (index) {

              final bool isActive =
                  _statisticsIndex ==
                      index;

              return AnimatedContainer(
                duration:
                const Duration(
                  milliseconds: 300,
                ),
                curve:
                Curves.easeInOut,
                width:
                isActive
                    ? 18
                    : 6,
                height: 6,
                margin:
                const EdgeInsets.symmetric(
                  horizontal: 3,
                ),
                decoration:
                BoxDecoration(
                  color:
                  isActive
                      ? const Color(
                    0xff00ACC1,
                  )
                      : Colors
                      .grey
                      .shade300,
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
  // کارت آماری
  // =====================================================

  Widget _buildStatisticCard(
      _StatisticItem item,
      ) {
    final String value =
    item.isAmount
        ? formatAmount(
      item.value,
    )
        : toPersianDigits(
      item.value.toString(),
    );

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 13,
      ),
      decoration:
      BoxDecoration(
        gradient:
        item.gradient,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(
              0.12,
            ),
            blurRadius: 12,
            offset:
            const Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child:
      Row(
        children: [

          Container(
            width: 52,
            height: 52,
            decoration:
            BoxDecoration(
              color:
              Colors.white.withOpacity(
                0.20,
              ),
              shape:
              BoxShape.circle,
            ),
            child:
            Icon(
              item.icon,
              color:
              Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child:
            Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                Text(
                  item.title,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 12,
                    color:
                    Colors.white,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.baseline,
                  textBaseline:
                  TextBaseline.alphabetic,
                  children: [

                    Flexible(
                      child:
                      Text(
                        value,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style:
                        const TextStyle(
                          fontSize: 23,
                          fontWeight:
                          FontWeight.bold,
                          color:
                          Colors.white,
                        ),
                      ),
                    ),

                    if (item.isAmount)
                      const Padding(
                        padding:
                        EdgeInsets.only(
                          right: 6,
                        ),
                        child:
                        Text(
                          'تومان',
                          style:
                          TextStyle(
                            fontSize: 9,
                            color:
                            Colors.white,
                            fontWeight:
                            FontWeight.w500,
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
      title:
      'پیامک‌ها',
      icon:
      Icons.sms_outlined,
    );
  }

  Widget buildFinancePage() {
    return const FinanceMenuScreen();
  }

  Widget buildMessagesPage() {
    return const MessagesScreen();
  }

  // =====================================================
  // پروفایل
  // =====================================================

  Widget buildProfilePage() {
    return SafeArea(
      child:
      SingleChildScrollView(
        padding:
        const EdgeInsets.all(
          20,
        ),
        child:
        Column(
          children: [

            const SizedBox(
              height: 20,
            ),

            const CircleAvatar(
              radius: 45,
              backgroundColor:
              Color(
                0xff00ACC1,
              ),
              child:
              Icon(
                Icons.person,
                size: 45,
                color:
                Colors.white,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              fullName,
              style:
              const TextStyle(
                fontSize: 18,
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
                color:
                Colors.grey,
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
              Icons
                  .manage_accounts_outlined,
              title:
              'نوع کاربر',
              value:
              'مدیر',
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
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
                style:
                OutlinedButton.styleFrom(
                  side:
                  const BorderSide(
                    color:
                    Colors.red,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
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
      builder:
          (context) {
        return AlertDialog(
          title:
          const Text(
            'خروج از حساب',
          ),
          content:
          const Text(
            'آیا مطمئن هستید که می‌خواهید از حساب کاربری خود خارج شوید؟',
          ),
          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
              const Text(
                'انصراف',
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
              ),
              child:
              const Text(
                'خروج',
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await TokenStorage.clear();

    if (!mounted) {
      return;
    }

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
  // Coming Soon
  // =====================================================

  void _showComingSoon(
      String title,
      ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
        Text(
          '$title در حال آماده‌سازی است.',
        ),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final pages = [
      buildSmsPage(),
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
                width: 20,
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

            // ---------------------------------------------
            // نظرسنجی
            // ---------------------------------------------
            //
            // Stack(
            //   clipBehavior:
            //   Clip.none,
            //   children: [
            //
            //     IconButton(
            //       tooltip:
            //       'نظرسنجی',
            //       onPressed: () {
            //         _showComingSoon(
            //           'نظرسنجی',
            //         );
            //       },
            //       icon:
            //       const Icon(
            //         Icons.poll_outlined,
            //         size: 25,
            //       ),
            //     ),
            //
            //     if (hasNewPolls)
            //       Positioned(
            //         top: 8,
            //         right: 8,
            //         child:
            //         Container(
            //           width: 9,
            //           height: 9,
            //           decoration:
            //           const BoxDecoration(
            //             color:
            //             Colors.amber,
            //             shape:
            //             BoxShape.circle,
            //           ),
            //         ),
            //       ),
            //   ],
            // ),

            // ---------------------------------------------
            // اطلاعیه
            // ---------------------------------------------

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

            // ---------------------------------------------
            // پیام
            // ---------------------------------------------

            Stack(
              clipBehavior:
              Clip.none,
              children: [

                IconButton(
                  tooltip:
                  'پیام‌ها',
                  onPressed:
                  openMessages,
                  icon:
                  const Icon(
                    Icons
                        .mail_outline_rounded,
                    size: 27,
                  ),
                ),

                if (hasNewMessages)
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

        // =================================================
        // Body
        // =================================================

        body:
        IndexedStack(
          index:
          currentIndex,
          children:
          pages,
        ),

        // =================================================
        // Bottom Navigation
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
                blurRadius:
                10,
                offset:
                Offset(
                  0,
                  -3,
                ),
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
            BottomNavigationBarType.fixed,
            backgroundColor:
            Colors.white,
            selectedItemColor:
            const Color(
              0xff00ACC1,
            ),
            unselectedItemColor:
            Colors.grey,
            selectedFontSize:
            12,
            unselectedFontSize:
            11,
            items: [

              // =========================================
              // پیامک‌ها
              // =========================================

              const BottomNavigationBarItem(
                icon:
                Icon(
                  Icons.sms_outlined,
                ),
                activeIcon:
                Icon(
                  Icons.sms,
                ),
                label:
                'پیامک‌ها',
              ),

              // =========================================
              // امور مالی
              // =========================================

              const BottomNavigationBarItem(
                icon:
                Icon(
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

              // =========================================
              // خانه
              // =========================================

              BottomNavigationBarItem(
                icon:
                Container(
                  width: 52,
                  height: 52,
                  decoration:
                  BoxDecoration(
                    color:
                    currentIndex == 2
                        ? const Color(
                      0xff00ACC1,
                    )
                        : Colors.white,
                    shape:
                    BoxShape.circle,
                    boxShadow:
                    currentIndex == 2
                        ? [
                      BoxShadow(
                        color:
                        const Color(
                          0xff00ACC1,
                        ).withOpacity(
                          0.30,
                        ),
                        blurRadius:
                        12,
                        offset:
                        const Offset(
                          0,
                          4,
                        ),
                      ),
                    ]
                        : null,
                    border:
                    currentIndex == 2
                        ? null
                        : Border.all(
                      color:
                      Colors.grey.shade300,
                      width:
                      1,
                    ),
                  ),
                  child:
                  Icon(
                    currentIndex == 2
                        ? Icons
                        .home_rounded
                        : Icons
                        .home_outlined,
                    color:
                    currentIndex == 2
                        ? Colors.white
                        : Colors.grey,
                    size:
                    27,
                  ),
                ),
                label:
                'خانه',
              ),

              // =========================================
              // پیام‌ها
              // =========================================

              BottomNavigationBarItem(
                icon:
                Stack(
                  clipBehavior:
                  Clip.none,
                  children: [

                    const Icon(
                      Icons
                          .mail_outline_rounded,
                    ),

                    if (hasNewMessages)
                      Positioned(
                        top: -3,
                        right: -4,
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
                activeIcon:
                Stack(
                  clipBehavior:
                  Clip.none,
                  children: [

                    const Icon(
                      Icons.mail_rounded,
                    ),

                    if (hasNewMessages)
                      Positioned(
                        top: -3,
                        right: -4,
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
                label:
                'پیام‌ها',
              ),

              // =========================================
              // پروفایل
              // =========================================

              const BottomNavigationBarItem(
                icon:
                Icon(
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

class _ManagerTopMenuItem
    extends StatelessWidget {

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
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color:
      Colors.transparent,
      child:
      InkWell(
        onTap:
        onTap,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        child:
        SizedBox(
          height: 92,
          child:
          Stack(
            clipBehavior:
            Clip.none,
            children: [

              Center(
                child:
                Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [

                    Container(
                      width: 50,
                      height: 50,
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
                        size: 27,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      title,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      textAlign:
                      TextAlign.center,
                      style:
                      const TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                        FontWeight.w600,
                        color:
                        Color(
                          0xff263238,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (badge != null)
                Positioned(
                  top: 7,
                  right: 12,
                  child:
                  Container(
                    constraints:
                    const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 4,
                    ),
                    decoration:
                    const BoxDecoration(
                      color:
                      Colors.red,
                      shape:
                      BoxShape.circle,
                    ),
                    child:
                    Center(
                      child:
                      Text(
                        badge! > 99
                            ? '۹۹+'
                            : toPersianDigits(
                          badge!
                              .toString(),
                        ),
                        style:
                        const TextStyle(
                          color:
                          Colors.white,
                          fontSize: 8,
                          fontWeight:
                          FontWeight.bold,
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

class _ManagerMiddleMenuCard
    extends StatelessWidget {

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
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(
        14,
      ),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          14,
        ),
        child: Container(
          height: 94,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: const Color(
                0xffECEFF1,
              ),
              width: 1,
            ),
          ),
          child: Row(
            children: [

              // -----------------------------------------
              // آیکون
              // -----------------------------------------

              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(
                    0.09,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 23,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              // -----------------------------------------
              // عنوان
              // -----------------------------------------

              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(
                      0xff263238,
                    ),
                  ),
                ),
              ),

              // -----------------------------------------
              // علامت <
              // نوک به سمت چپ
              // -----------------------------------------

              const SizedBox(
                width: 6,
              ),

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

class _SimpleManagerPage
    extends StatelessWidget {

  final String title;

  final IconData icon;

  const _SimpleManagerPage({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return SafeArea(
      child:
      Center(
        child:
        Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
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
                color:
                const Color(
                  0xff00ACC1,
                ),
                size: 42,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            Text(
              title,
              style:
              const TextStyle(
                fontSize: 20,
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
        bottom: 10,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border:
        Border.all(
          color:
          const Color(
            0xffECEFF1,
          ),
        ),
      ),
      child:
      Row(
        children: [

          Icon(
            icon,
            color:
            const Color(
              0xff00ACC1,
            ),
            size: 23,
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child:
            Text(
              title,
              style:
              const TextStyle(
                color:
                Colors.grey,
                fontSize: 13,
              ),
            ),
          ),

          Text(
            value,
            style:
            const TextStyle(
              fontWeight:
              FontWeight.w600,
              fontSize: 13,
              color:
              Color(
                0xff263238,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// تابع کمکی تبدیل اعداد برای badge
// =====================================================

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