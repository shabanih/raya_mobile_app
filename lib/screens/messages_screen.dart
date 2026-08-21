import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../services/api_service.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  // =====================================================
  // Colors
  // =====================================================

  static const Color primaryColor = Color(0xff00ACC1);
  static const Color textColor = Color(0xff263238);
  static const Color backgroundColor = Color(0xffF7F9FA);

  // =====================================================
  // State
  // =====================================================

  bool isLoading = true;

  String? errorMessage;

  List<Map<String, dynamic>> messages = [];

  int unreadCount = 0;

  // =====================================================
  // Init
  // =====================================================

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  // =====================================================
  // دریافت پیام‌ها
  // =====================================================

  Future<void> loadMessages() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final result = await ApiService().getMessages();

      debugPrint('====================================');
      debugPrint('MESSAGES RESPONSE: $result');

      final dynamic messagesData = result['messages'];

      final List<Map<String, dynamic>> loadedMessages = [];

      if (messagesData is List) {
        for (final item in messagesData) {
          if (item is Map) {
            loadedMessages.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      final dynamic unreadData = result['unread_count'];

      final int loadedUnreadCount = unreadData is num
          ? unreadData.toInt()
          : int.tryParse(
        unreadData?.toString() ?? '',
      ) ??
          0;

      debugPrint(
        'MESSAGES COUNT: ${loadedMessages.length}',
      );

      debugPrint(
        'UNREAD COUNT: $loadedUnreadCount',
      );

      debugPrint('====================================');

      if (!mounted) return;

      setState(() {
        messages = loadedMessages;
        unreadCount = loadedUnreadCount;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'GET MESSAGES ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
        'دریافت پیام‌ها با خطا مواجه شد.';
      });
    }
  }

  // =====================================================
  // تبدیل عدد انگلیسی به فارسی
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
  // تاریخ شمسی
  // =====================================================

  String formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return '-';
    }

    try {
      final dateTime = DateTime.parse(text);

      final jalali = Jalali.fromDateTime(
        dateTime,
      );

      return toPersianDigits(
        '${jalali.year}/'
            '${jalali.month.toString().padLeft(2, '0')}/'
            '${jalali.day.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      debugPrint(
        'DATE CONVERSION ERROR: $e',
      );

      return toPersianDigits(
        text.length >= 10
            ? text.substring(0, 10)
            : text,
      );
    }
  }

  // =====================================================
  // Header
  // =====================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.mail_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'پیام‌های مدیر',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'اطلاعیه‌ها و پیام‌های مدیریت ساختمان',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              toPersianDigits(
                messages.length.toString(),
              ),
              style: const TextStyle(
                color: primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Summary Card
  // =====================================================

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'پیام‌های خوانده نشده',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      toPersianDigits(
                        unreadCount.toString(),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 7),

                    const Text(
                      'پیام',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'جدید',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =====================================================
  // Message Card
  // =====================================================

  Widget _buildMessageCard(
      Map<String, dynamic> item,
      ) {
    final int? id = int.tryParse(
      item['id']?.toString() ?? '',
    );

    final String title =
    item['title']?.toString().trim().isNotEmpty == true
        ? item['title'].toString().trim()
        : 'پیام مدیر';

    final String message =
    item['message']?.toString().trim().isNotEmpty == true
        ? item['message'].toString().trim()
        : 'متن پیام موجود نیست.';

    final bool isRead = item['is_read'] == true;

    final dynamic createdAt = item['created_at'];

    // ===================================================
    // رنگ‌های پیام
    // ===================================================

    final Color cardColor = isRead
        ? Colors.white
        : primaryColor.withOpacity(0.055);

    final Color borderColor = isRead
        ? Colors.black.withOpacity(0.04)
        : primaryColor.withOpacity(0.30);

    final Color statusColor = isRead
        ? Colors.green
        : primaryColor;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: id == null
            ? null
            : () {
          _openMessage(
            item,
            id,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  isRead ? 0.035 : 0.06,
                ),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================================
              // متن پیام
              // =========================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        if (!isRead)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(
                              left: 7,
                            ),
                            decoration:
                            const BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),

                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow:
                            TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ===================================
                    // تاریخ + وضعیت
                    // ساعت حذف شده
                    // ===================================

                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),

                        const SizedBox(width: 5),

                        Text(
                          formatDate(createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),

                        const Spacer(),

                        // وضعیت پیام
                        Icon(
                          isRead
                              ? Icons
                              .check_circle_outline
                              : Icons
                              .mark_email_unread_outlined,
                          size: 14,
                          color: statusColor,
                        ),

                        const SizedBox(width: 5),

                        Text(
                          isRead
                              ? 'خوانده شده'
                              : 'خوانده نشده',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // =========================================
              // پاکت سمت چپ
              // =========================================

              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isRead
                      ? Colors.green.withOpacity(0.10)
                      : primaryColor.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isRead
                      ? Icons.mark_email_read_outlined
                      : Icons.mark_email_unread_outlined,
                  color: isRead
                      ? Colors.green
                      : primaryColor,
                  size: 27,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // باز کردن پیام
  // =====================================================

  Future<void> _openMessage(
      Map<String, dynamic> item,
      int messageId,
      ) async {
    final bool wasRead = item['is_read'] == true;

    if (!wasRead) {
      try {
        final result = await ApiService()
            .markMessageAsRead(messageId);

        debugPrint(
          'MESSAGE READ RESULT: $result',
        );

        if (!mounted) return;

        // ---------------------------------------------
        // تغییر وضعیت محلی
        // ---------------------------------------------

        setState(() {
          item['is_read'] = true;
          item['read_at'] = result['read_at'];

          if (unreadCount > 0) {
            unreadCount--;
          }
        });
      } catch (e) {
        debugPrint(
          'MARK MESSAGE READ ERROR: $e',
        );
      }
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _MessageDetailScreen(
          title:
          item['title']?.toString().trim().isNotEmpty ==
              true
              ? item['title'].toString().trim()
              : 'پیام مدیر',
          message:
          item['message']?.toString().trim() ?? '',
          createdAt: item['created_at'],
          isRead: true,
        ),
      ),
    );
  }

  // =====================================================
  // Empty
  // =====================================================

  Widget _buildEmpty() {
    return Center(
      child: SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 45,
                color: primaryColor,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'پیامی وجود ندارد',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'در حال حاضر پیام یا اطلاعیه‌ای برای شما ارسال نشده است.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: loadMessages,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'بروزرسانی',
              ),
              style:
              OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: const BorderSide(
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Error
  // =====================================================

  Widget _buildError() {
    return Center(
      child: SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 55,
              color: Colors.redAccent,
            ),

            const SizedBox(height: 16),

            Text(
              errorMessage ??
                  'خطا در دریافت اطلاعات',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed: loadMessages,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'تلاش مجدد',
              ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Loading
  // =====================================================

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: primaryColor,
      ),
    );
  }

  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,

        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,

          title: const Text(
            'پیام‌های مدیر',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          iconTheme: const IconThemeData(
            color: textColor,
          ),
        ),

        body: RefreshIndicator(
          color: primaryColor,
          onRefresh: loadMessages,

          child: isLoading
              ? _buildLoading()
              : errorMessage != null
              ? _buildError()
              : messages.isEmpty
              ? _buildEmpty()
              : ListView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding:
            const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              30,
            ),
            children: [
              _buildHeader(),

              const SizedBox(height: 14),

              _buildSummaryCard(),

              const SizedBox(height: 18),

              const Text(
                'لیست پیام‌ها',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 12),

              for (final item
              in messages) ...[
                _buildMessageCard(item),

                const SizedBox(
                  height: 12,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// Message Detail Screen
// =====================================================

class _MessageDetailScreen
    extends StatelessWidget {
  final String title;
  final String message;
  final dynamic createdAt;
  final bool isRead;

  const _MessageDetailScreen({
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  static const Color primaryColor =
  Color(0xff00ACC1);

  static const Color textColor =
  Color(0xff263238);

  static const Color backgroundColor =
  Color(0xffF7F9FA);

  // =====================================================
  // تبدیل عدد انگلیسی به فارسی
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
  // تاریخ
  // =====================================================

  String formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    try {
      final dateTime = DateTime.parse(
        value.toString(),
      );

      final jalali = Jalali.fromDateTime(
        dateTime,
      );

      return toPersianDigits(
        '${jalali.year}/'
            '${jalali.month.toString().padLeft(2, '0')}/'
            '${jalali.day.toString().padLeft(2, '0')}',
      );
    } catch (_) {
      return '-';
    }
  }

  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,

        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor:
          Colors.transparent,

          title: const Text(
            'متن پیام',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          iconTheme: const IconThemeData(
            color: textColor,
          ),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            18,
            10,
            18,
            30,
          ),

          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(0.045),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // =======================================
                // Header
                // =======================================

                Row(
                  textDirection:
                  TextDirection.rtl,
                  children: [
                    Container(
                      width: 52,
                      height: 52,

                      decoration: BoxDecoration(
                        color: primaryColor
                            .withOpacity(0.10),
                        borderRadius:
                        BorderRadius.circular(16),
                      ),

                      child: Icon(
                        isRead
                            ? Icons
                            .mark_email_read_outlined
                            : Icons
                            .mark_email_unread_outlined,
                        color: isRead
                            ? Colors.green
                            : primaryColor,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                const Divider(),

                const SizedBox(height: 16),

                // =======================================
                // متن
                // =======================================

                Text(
                  message,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 2,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 22),

                // =======================================
                // تاریخ و وضعیت
                // ساعت حذف شده
                // =======================================

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),

                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius:
                    BorderRadius.circular(12),
                  ),

                  child: Row(
                    textDirection:
                    TextDirection.rtl,
                    children: [
                      const Icon(
                        Icons
                            .calendar_today_outlined,
                        size: 16,
                        color: Colors.grey,
                      ),

                      const SizedBox(width: 7),

                      Text(
                        formatDate(createdAt),
                        style:
                        const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),

                      const Spacer(),

                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: isRead
                            ? Colors.green
                            : primaryColor,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        isRead
                            ? 'خوانده شده'
                            : 'خوانده نشده',
                        style: TextStyle(
                          fontSize: 10,
                          color: isRead
                              ? Colors.green
                              : primaryColor,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}