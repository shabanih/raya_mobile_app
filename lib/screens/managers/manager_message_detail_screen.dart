import 'package:flutter/material.dart';

import '../../services/manager_message_service.dart';

class ManagerMessageDetailScreen extends StatefulWidget {
  final int messageId;

  const ManagerMessageDetailScreen({
    super.key,
    required this.messageId,
  });

  @override
  State<ManagerMessageDetailScreen> createState() =>
      _ManagerMessageDetailScreenState();
}

class _ManagerMessageDetailScreenState
    extends State<ManagerMessageDetailScreen> {
  final ManagerMessageService _service =
  ManagerMessageService();

  Map<String, dynamic>? _message;

  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    _loadMessage();
  }

  // =====================================================
  // دریافت جزئیات پیام
  // =====================================================

  Future<void> _loadMessage({
    bool refresh = false,
  }) async {
    if (!mounted) {
      return;
    }

    setState(() {
      if (refresh) {
        _isRefreshing = true;
      } else {
        _isLoading = true;
      }
    });

    try {
      final result =
      await _service.getMessage(
        widget.messageId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _message =
        Map<String, dynamic>.from(
          result,
        );

        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });

      _showError(
        _cleanError(e),
      );
    }
  }

  // =====================================================
  // وضعیت ارسال
  // =====================================================

  bool _isSent() {
    final value =
    _message?['send_notification'];

    if (value is bool) {
      return value;
    }

    return value
        ?.toString()
        .toLowerCase() ==
        'true';
  }

  // =====================================================
  // تبدیل عدد
  // =====================================================

  int _toInt(
      dynamic value,
      ) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    ) ??
        0;
  }

  // =====================================================
  // اعداد فارسی
  // =====================================================

  String _toPersianDigits(
      String value,
      ) {
    return value
        .replaceAll('0', '۰')
        .replaceAll('1', '۱')
        .replaceAll('2', '۲')
        .replaceAll('3', '۳')
        .replaceAll('4', '۴')
        .replaceAll('5', '۵')
        .replaceAll('6', '۶')
        .replaceAll('7', '۷')
        .replaceAll('8', '۸')
        .replaceAll('9', '۹');
  }

  String _count(
      dynamic value,
      ) {
    return _toPersianDigits(
      _toInt(value).toString(),
    );
  }

  // =====================================================
  // پاک کردن Exception
  // =====================================================

  String _cleanError(
      Object error,
      ) {
    String text =
    error.toString();

    if (text.startsWith(
      'Exception: ',
    )) {
      text = text.substring(
        'Exception: '.length,
      );
    }

    return text;
  }

  // =====================================================
  // نمایش خطا
  // =====================================================

  void _showError(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign:
          TextAlign.right,
        ),
        backgroundColor:
        Colors.red.shade700,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // =====================================================
  // نمایش تاریخ
  // =====================================================

  String _formatDate(
      dynamic value,
      ) {
    if (value == null) {
      return '';
    }

    final text =
    value.toString().trim();

    if (text.isEmpty) {
      return '';
    }

    try {
      final date =
      DateTime.parse(text).toLocal();

      final year =
      _toPersianDigits(
        date.year.toString(),
      );

      final month =
      _toPersianDigits(
        date.month
            .toString()
            .padLeft(2, '0'),
      );

      final day =
      _toPersianDigits(
        date.day
            .toString()
            .padLeft(2, '0'),
      );

      final hour =
      _toPersianDigits(
        date.hour
            .toString()
            .padLeft(2, '0'),
      );

      final minute =
      _toPersianDigits(
        date.minute
            .toString()
            .padLeft(2, '0'),
      );

      return '$year/$month/$day - $hour:$minute';
    } catch (_) {
      return text;
    }
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
        const Color(0xffF7F8FC),

        appBar: AppBar(
          title: const Text(
            'جزئیات پیام',
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor:
          const Color(0xff00ACC1),
          foregroundColor:
          Colors.white,
          elevation: 0,
        ),

        body: _buildBody(),
      ),
    );
  }

  // =====================================================
  // Body
  // =====================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (_message == null) {
      return RefreshIndicator(
        onRefresh: () =>
            _loadMessage(
              refresh: true,
            ),
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 160,
            ),
            Center(
              child: Text(
                'اطلاعات پیام دریافت نشد.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          _loadMessage(
            refresh: true,
          ),
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.fromLTRB(
          14,
          14,
          14,
          30,
        ),
        children: [
          _buildMessageCard(),

          const SizedBox(
            height: 14,
          ),

          _buildStatisticsCard(),

          const SizedBox(
            height: 14,
          ),

          _buildRecipientsCard(),
        ],
      ),
    );
  }

  // =====================================================
  // کارت متن پیام
  // =====================================================

  Widget _buildMessageCard() {
    final title =
        _message?['title']
            ?.toString()
            .trim() ??
            '';

    final message =
        _message?['message']
            ?.toString()
            .trim() ??
            '';

    final createdAt =
    _formatDate(
      _message?['created_at'],
    );

    final sentAt =
    _formatDate(
      _message?[
      'send_notification_date'],
    );

    final sent =
    _isSent();

    return Container(
      padding:
      const EdgeInsets.all(16),
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
            Colors.black.withOpacity(
              0.04,
            ),
            blurRadius:
            10,
            offset:
            const Offset(
              0,
              3,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title.isEmpty
                      ? 'بدون عنوان'
                      : title,
                  style:
                  const TextStyle(
                    fontSize:
                    19,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              _buildStatusChip(
                sent,
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          Container(
            width:
            double.infinity,
            padding:
            const EdgeInsets.all(
              14,
            ),
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xffF7F8FC,
              ),
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child: Text(
              message.isEmpty
                  ? 'بدون متن'
                  : message,
              style:
              const TextStyle(
                fontSize:
                15,
                height:
                1.9,
              ),
            ),
          ),

          if (createdAt.isNotEmpty) ...[
            const SizedBox(
              height: 14,
            ),
            _buildDateRow(
              Icons.access_time,
              'تاریخ ایجاد',
              createdAt,
            ),
          ],

          if (sent &&
              sentAt.isNotEmpty) ...[
            const SizedBox(
              height: 8,
            ),
            _buildDateRow(
              Icons.send_outlined,
              'تاریخ ارسال',
              sentAt,
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // وضعیت
  // =====================================================

  Widget _buildStatusChip(
      bool sent,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color: sent
            ? Colors.green
            .withOpacity(
          0.10,
        )
            : Colors.orange
            .withOpacity(
          0.12,
        ),
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            sent
                ? Icons.check_circle_outline
                : Icons.schedule,
            size:
            17,
            color: sent
                ? Colors.green.shade700
                : Colors.orange.shade800,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            sent
                ? 'ارسال شده'
                : 'آماده ارسال',
            style:
            TextStyle(
              fontSize:
              12,
              fontWeight:
              FontWeight.bold,
              color: sent
                  ? Colors.green.shade700
                  : Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // تاریخ
  // =====================================================

  Widget _buildDateRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size:
          18,
          color:
          Colors.grey.shade600,
        ),
        const SizedBox(
          width:
          6,
        ),
        Text(
          '$title:',
          style:
          TextStyle(
            fontSize:
            12,
            color:
            Colors.grey.shade600,
          ),
        ),
        const SizedBox(
          width:
          5,
        ),
        Expanded(
          child: Text(
            value,
            style:
            const TextStyle(
              fontSize:
              12,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // آمار
  // =====================================================

  Widget _buildStatisticsCard() {
    return Container(
      padding:
      const EdgeInsets.all(
        14,
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
            Colors.black.withOpacity(
              0.04,
            ),
            blurRadius:
            10,
            offset:
            const Offset(
              0,
              3,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'وضعیت گیرندگان',
            style:
            TextStyle(
              fontSize:
              16,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height:
            14,
          ),

          Row(
            children: [
              Expanded(
                child:
                _buildStatisticBox(
                  icon:
                  Icons.people_outline,
                  title:
                  'گیرندگان',
                  value:
                  _count(
                    _message?[
                    'recipient_count'],
                  ),
                  iconColor:
                  const Color(
                    0xff5E35B1,
                  ),
                ),
              ),

              const SizedBox(
                width:
                8,
              ),

              Expanded(
                child:
                _buildStatisticBox(
                  icon:
                  Icons.mark_email_read_outlined,
                  title:
                  'خوانده شده',
                  value:
                  _count(
                    _message?[
                    'read_count'],
                  ),
                  iconColor:
                  Colors.green,
                ),
              ),

              const SizedBox(
                width:
                8,
              ),

              Expanded(
                child:
                _buildStatisticBox(
                  icon:
                  Icons.mark_email_unread_outlined,
                  title:
                  'نخوانده',
                  value:
                  _count(
                    _message?[
                    'unread_count'],
                  ),
                  iconColor:
                  Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticBox({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        vertical:
        12,
        horizontal:
        6,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.grey.shade50,
        borderRadius:
        BorderRadius.circular(
          12,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color:
            iconColor,
            size:
            23,
          ),

          const SizedBox(
            height:
            6,
          ),

          Text(
            value,
            style:
            const TextStyle(
              fontSize:
              18,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height:
            2,
          ),

          Text(
            title,
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              fontSize:
              10,
              color:
              Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // لیست گیرندگان
  // =====================================================

  Widget _buildRecipientsCard() {
    final recipients =
    _message?['recipients'];

    final List<Map<String, dynamic>>
    recipientList = [];

    if (recipients is List) {
      for (final item
      in recipients) {
        if (item is Map) {
          recipientList.add(
            Map<String, dynamic>.from(
              item,
            ),
          );
        }
      }
    }

    return Container(
      padding:
      const EdgeInsets.all(
        14,
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
            Colors.black.withOpacity(
              0.04,
            ),
            blurRadius:
            10,
            offset:
            const Offset(
              0,
              3,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'جزئیات گیرندگان',
                  style:
                  TextStyle(
                    fontSize:
                    16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal:
                  9,
                  vertical:
                  5,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xff5E35B1,
                  ).withOpacity(
                    0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child:
                Text(
                  _toPersianDigits(
                    recipientList.length
                        .toString(),
                  ),
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                    color:
                    Color(
                      0xff5E35B1,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
            12,
          ),

          if (recipientList.isEmpty)
            _buildEmptyRecipients()
          else
            ListView.separated(
              shrinkWrap:
              true,
              physics:
              const NeverScrollableScrollPhysics(),
              itemCount:
              recipientList.length,
              separatorBuilder:
                  (_, __) =>
              const Divider(
                height:
                1,
              ),
              itemBuilder:
                  (context, index) {
                return _buildRecipientItem(
                  recipientList[index],
                );
              },
            ),
        ],
      ),
    );
  }

  // =====================================================
  // گیرنده خالی
  // =====================================================

  Widget _buildEmptyRecipients() {
    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.symmetric(
        vertical:
        24,
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size:
            44,
            color:
            Colors.grey.shade400,
          ),
          const SizedBox(
            height:
            8,
          ),
          Text(
            _isSent()
                ? 'اطلاعات گیرندگان موجود نیست.'
                : 'هنوز گیرنده‌ای برای این پیام ثبت نشده است.',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              color:
              Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // یک گیرنده
  // =====================================================

  Widget _buildRecipientItem(
      Map<String, dynamic> recipient,
      ) {
    final unit =
    recipient['unit'];

    final unitId =
    recipient['unit_id'];

    final type =
        recipient['recipient_type'] ??
            recipient['type'] ??
            '';

    final name =
        recipient['name']
            ?.toString()
            .trim() ??
            '';

    final mobile =
        recipient['mobile']
            ?.toString()
            .trim() ??
            '';

    final isRead =
        recipient['is_read'] == true;

    final readAt =
    _formatDate(
      recipient['read_at'],
    );

    final bool isOwner =
        type.toString()
            .toLowerCase() ==
            'owner';

    final typeTitle =
    isOwner
        ? 'مالک'
        : 'مستأجر';

    final typeColor =
    isOwner
        ? const Color(
      0xff5E35B1,
    )
        : Colors.blue;

    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical:
        12,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // =============================================
          // آیکون
          // =============================================

          Container(
            width:
            44,
            height:
            44,
            decoration:
            BoxDecoration(
              color:
              typeColor.withOpacity(
                0.10,
              ),
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child:
            Icon(
              isOwner
                  ? Icons
                  .person_outline
                  : Icons
                  .person_pin_outlined,
              color:
              typeColor,
            ),
          ),

          const SizedBox(
            width:
            10,
          ),

          // =============================================
          // اطلاعات
          // =============================================

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'واحد ${_toPersianDigits(unit?.toString() ?? unitId?.toString() ?? '-') }',
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        fontSize:
                        14,
                      ),
                    ),

                    const SizedBox(
                      width:
                      7,
                    ),

                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal:
                        7,
                        vertical:
                        3,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        typeColor.withOpacity(
                          0.10,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                      ),
                      child:
                      Text(
                        typeTitle,
                        style:
                        TextStyle(
                          fontSize:
                          10,
                          fontWeight:
                          FontWeight.bold,
                          color:
                          typeColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height:
                  5,
                ),

                if (name.isNotEmpty)
                  Text(
                    name,
                    maxLines:
                    1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize:
                      13,
                    ),
                  ),

                if (mobile.isNotEmpty) ...[
                  const SizedBox(
                    height:
                    3,
                  ),
                  Text(
                    _toPersianDigits(
                      mobile,
                    ),
                    style:
                    TextStyle(
                      fontSize:
                      12,
                      color:
                      Colors.grey.shade600,
                    ),
                  ),
                ],

                if (isRead &&
                    readAt.isNotEmpty) ...[
                  const SizedBox(
                    height:
                    5,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons
                            .done_all,
                        size:
                        15,
                        color:
                        Colors.green.shade700,
                      ),
                      const SizedBox(
                        width:
                        4,
                      ),
                      Text(
                        'خوانده شده در $readAt',
                        style:
                        TextStyle(
                          fontSize:
                          10,
                          color:
                          Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(
            width:
            8,
          ),

          // =============================================
          // وضعیت خواندن
          // =============================================

          _buildReadStatus(
            isRead,
          ),
        ],
      ),
    );
  }

  // =====================================================
  // وضعیت خوانده شدن
  // =====================================================

  Widget _buildReadStatus(
      bool isRead,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal:
        7,
        vertical:
        5,
      ),
      decoration:
      BoxDecoration(
        color: isRead
            ? Colors.green
            .withOpacity(
          0.10,
        )
            : Colors.orange
            .withOpacity(
          0.10,
        ),
        borderRadius:
        BorderRadius.circular(
          10,
        ),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            isRead
                ? Icons
                .done_all
                : Icons
                .schedule,
            size:
            14,
            color: isRead
                ? Colors.green.shade700
                : Colors.orange.shade800,
          ),
          const SizedBox(
            width:
            3,
          ),
          Text(
            isRead
                ? 'خوانده'
                : 'نخوانده',
            style:
            TextStyle(
              fontSize:
              10,
              fontWeight:
              FontWeight.bold,
              color: isRead
                  ? Colors.green.shade700
                  : Colors.orange.shade800,
            ),
          ),
        ],
      ),
    );
  }
}