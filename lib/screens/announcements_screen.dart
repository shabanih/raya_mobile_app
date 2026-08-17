import 'package:flutter/material.dart';

import '../services/announcement_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

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
      // آخرین اطلاعیه به عنوان دیده‌شده ثبت می‌شود
      // =====================================================

      await AnnouncementService.markAsRead(result);

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

  String formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }

    try {
      final date = DateTime.parse(value).toLocal();

      final year = date.year.toString();
      final month =
      date.month.toString().padLeft(2, '0');
      final day =
      date.day.toString().padLeft(2, '0');

      return '$year/$month/$day';
    } catch (_) {
      return '';
    }
  }

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

        appBar: AppBar(
          backgroundColor:
          const Color(0xff00ACC1),
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

        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xff00ACC1),
        ),
      );
    }

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
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: loadAnnouncements,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xff00ACC1),
                foregroundColor: Colors.white,
              ),
              child: const Text('تلاش مجدد'),
            ),
          ],
        ),
      );
    }

    if (announcements.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xff00ACC1),
        onRefresh: loadAnnouncements,
        child: ListView(
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

    return RefreshIndicator(
      color: const Color(0xff00ACC1),
      onRefresh: loadAnnouncements,

      child: ListView.builder(
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

          return _AnnouncementCard(
            title:
            announcement['title']?.toString() ?? '-',
            date: formatDate(
              announcement['created_at']?.toString(),
            ),
            toPersianDigits:
            toPersianDigits,
          );
        },
      ),
    );
  }
}

class _AnnouncementCard
    extends StatelessWidget {

  final String title;
  final String date;

  final String Function(String)
  toPersianDigits;

  const _AnnouncementCard({
    required this.title,
    required this.date,
    required this.toPersianDigits,
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
        CrossAxisAlignment.start,

        children: [
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: const Color(
                0xff00ACC1,
              ).withOpacity(0.12),

              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xff00ACC1),
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    Color(0xff263238),
                    height: 1.7,
                  ),
                ),

                if (date.isNotEmpty) ...[
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 15,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        toPersianDigits(date),
                        style:
                        const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}