import 'package:flutter/material.dart';

import '../services/announcement_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  final int userId;

  const AnnouncementsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState
    extends State<AnnouncementsScreen> {
  bool isLoading = true;

  String? errorMessage;

  List<Map<String, dynamic>> announcements = [];

  @override
  void initState() {
    super.initState();

    loadAnnouncements();
  }

  // =====================================================
  // دریافت اطلاعیه‌ها
  // =====================================================

  Future<void> loadAnnouncements() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
      await AnnouncementService.getAnnouncements();

      // =====================================================
      // اطلاعیه‌ها دریافت شدند
      // فقط برای همین کاربر به عنوان دیده‌شده ثبت می‌شوند
      // =====================================================

      await AnnouncementService.markAsRead(
        widget.userId,
        result,
      );

      if (!mounted) return;

      setState(() {
        announcements = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
        'دریافت اطلاعیه‌ها با خطا مواجه شد.';
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF5F8FA),

        // =====================================================
        // AppBar
        // =====================================================

        appBar: AppBar(
          backgroundColor: const Color(0xff00ACC1),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,

          title: const Text(
            'اطلاعیه‌ها',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // =====================================================
        // Body
        // =====================================================

        body: _buildBody(),
      ),
    );
  }

  // =====================================================
  // Body
  // =====================================================

  Widget _buildBody() {
    // =====================================================
    // Loading
    // =====================================================

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xff00ACC1),
        ),
      );
    }

    // =====================================================
    // Error
    // =====================================================

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Colors.grey,
            ),

            const SizedBox(height: 15),

            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: loadAnnouncements,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xff00ACC1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'تلاش مجدد',
              ),
            ),
          ],
        ),
      );
    }

    // =====================================================
    // هیچ اطلاعیه‌ای وجود ندارد
    // =====================================================

    if (announcements.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xff00ACC1),
        onRefresh: loadAnnouncements,

        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),

          children: const [
            SizedBox(height: 180),

            Icon(
              Icons.notifications_none_rounded,
              size: 70,
              color: Colors.grey,
            ),

            SizedBox(height: 15),

            Center(
              child: Text(
                'اطلاعیه‌ای وجود ندارد.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // =====================================================
    // لیست اطلاعیه‌ها
    // =====================================================

    return RefreshIndicator(
      color: const Color(0xff00ACC1),
      onRefresh: loadAnnouncements,

      child: ListView.builder(
        physics:
        const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.fromLTRB(
          18,
          20,
          18,
          30,
        ),

        itemCount: announcements.length,

        itemBuilder: (context, index) {
          final announcement =
          announcements[index];

          final title =
              announcement['title']
                  ?.toString()
                  .trim() ??
                  'اطلاعیه ساختمان';

          return _AnnouncementCard(
            title: toPersianDigits(title),
          );
        },
      ),
    );
  }
}

// =====================================================
// کارت اطلاعیه
// =====================================================

class _AnnouncementCard extends StatelessWidget {
  final String title;

  const _AnnouncementCard({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),

      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset:
            const Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.center,

        children: [
          // =================================================
          // آیکن اطلاعیه
          // =================================================

          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color:
              const Color(0xff00ACC1)
                  .withOpacity(0.12),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.notifications_none_rounded,

              color:
              Color(0xff00ACC1),

              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          // =================================================
          // عنوان اطلاعیه
          // =================================================

          Expanded(
            child: Text(
              title,

              textAlign:
              TextAlign.right,

              maxLines: 3,

              overflow:
              TextOverflow.ellipsis,

              style: const TextStyle(
                fontSize: 16,

                fontWeight:
                FontWeight.bold,

                color:
                Color(0xff263238),

                height: 1.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}