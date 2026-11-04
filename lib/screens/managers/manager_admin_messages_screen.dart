
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/api_service.dart';
import '../../services/manager_admin_message_service.dart';

class ManagerAdminMessagesScreen extends StatefulWidget {
  final bool embedded;

  const ManagerAdminMessagesScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<ManagerAdminMessagesScreen> createState() =>
      _ManagerAdminMessagesScreenState();
}

class _ManagerAdminMessagesScreenState
    extends State<ManagerAdminMessagesScreen> {
  static const Color primaryColor = Color(0xFF00ACC1);
  static const Color secondaryColor = Color(0xFF610DB5);

  late final ManagerAdminMessageService _service;

  bool _loading = false;
  String? _error;

  String _selectedFilter = 'all';

  List<Map<String, dynamic>> _messages = [];

  int _totalCount = 0;
  int _readCount = 0;
  int _unreadCount = 0;

  final Set<int> _expandedMessages = {};
  final Set<int> _markingAsRead = {};

  @override
  void initState() {
    super.initState();

    _service = ManagerAdminMessageService(
      apiService: ApiService(),
    );

    _loadMessages();
  }

  // دریافت پیام‌ها
  Future<void> _loadMessages() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.getMessages(
        status: _selectedFilter,
      );

      if (!mounted) return;

      final statistics = result['statistics'] is Map
          ? Map<String, dynamic>.from(result['statistics'])
          : <String, dynamic>{};

      final receivedMessages = result['messages'];

      final messages = receivedMessages is List
          ? receivedMessages
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _messages = messages;

        _totalCount = _toInt(
          statistics['total_count'] ?? messages.length,
        );

        _readCount = _toInt(
          statistics['read_count'],
        );

        _unreadCount = _toInt(
          statistics['unread_count'],
        );

        _expandedMessages.clear();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(
      _toEnglishDigits(value?.toString() ?? '').trim(),
    ) ??
        0;
  }

  String _toPersianDigits(String value) {
    const englishDigits = '0123456789';
    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';

    for (int i = 0; i < 10; i++) {
      value = value.replaceAll(
        englishDigits[i],
        persianDigits[i],
      );

      value = value.replaceAll(
        arabicDigits[i],
        persianDigits[i],
      );
    }

    return value;
  }

  String _toEnglishDigits(String value) {
    const englishDigits = '0123456789';
    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';

    for (int i = 0; i < 10; i++) {
      value = value.replaceAll(
        persianDigits[i],
        englishDigits[i],
      );

      value = value.replaceAll(
        arabicDigits[i],
        englishDigits[i],
      );
    }

    return value;
  }

  String _text(
      dynamic value, {
        String fallback = '-',
      }) {
    if (value == null) return fallback;

    final result = value.toString().trim();

    if (result.isEmpty || result == 'null') {
      return fallback;
    }

    return _toPersianDigits(result);
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '';
    }

    try {
      final date = DateTime.parse(
        value.toString(),
      ).toLocal();

      final jalali = Jalali.fromDateTime(date);

      final dateText =
          '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';

      final timeText =
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

      return _toPersianDigits('$dateText - $timeText');
    } catch (_) {
      return _toPersianDigits(value.toString());
    }
  }

  // تغییر فیلتر
  void _changeFilter(String filter) {
    if (_selectedFilter == filter) return;

    setState(() {
      _selectedFilter = filter;
      _messages = [];
      _expandedMessages.clear();
    });

    _loadMessages();
  }

  // باز کردن یا بستن پیام
  Future<void> _toggleMessage(
      Map<String, dynamic> message,
      ) async {
    final id = _toInt(message['id']);

    if (id <= 0) return;

    final isExpanded = _expandedMessages.contains(id);

    if (isExpanded) {
      setState(() {
        _expandedMessages.remove(id);
      });
      return;
    }

    setState(() {
      _expandedMessages.add(id);
    });

    final isRead = message['is_read'] == true;

    if (!isRead) {
      await _markAsRead(message);
    }
  }

  // ثبت خوانده‌شدن پیام
  Future<void> _markAsRead(
      Map<String, dynamic> message,
      ) async {
    final id = _toInt(message['id']);

    if (id <= 0 ||
        message['is_read'] == true ||
        _markingAsRead.contains(id)) {
      return;
    }

    setState(() {
      _markingAsRead.add(id);
    });

    try {
      final result = await _service.markMessageAsRead(id);

      if (!mounted) return;

      if (result['success'] == true) {
        setState(() {
          message['is_read'] = true;
          message['read_at'] = result['read_at'];

          if (_unreadCount > 0) {
            _unreadCount--;
          }

          _readCount++;
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ثبت وضعیت خوانده‌شدن پیام انجام نشد: '
                '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _markingAsRead.remove(id);
        });
      }
    }
  }

  // کارت آمار
  Widget _buildStatisticsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'پیام‌های مدیریت سامانه',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'بروزرسانی',
                onPressed: _loading ? null : _loadMessages,
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildStatisticItem(
                  'همه پیام‌ها',
                  _totalCount,
                  Icons.mail_outline,
                ),
              ),
              Container(
                height: 42,
                width: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatisticItem(
                  'خوانده‌شده',
                  _readCount,
                  Icons.mark_email_read_outlined,
                ),
              ),
              Container(
                height: 42,
                width: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildStatisticItem(
                  'خوانده‌نشده',
                  _unreadCount,
                  Icons.mark_email_unread_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticItem(
      String title,
      int count,
      IconData icon,
      ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 21,
        ),
        const SizedBox(height: 7),
        Text(
          _toPersianDigits(count.toString()),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // فیلتر پیام‌ها
  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: _buildFilterButton(
            title: 'همه',
            value: 'all',
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _buildFilterButton(
            title: 'خوانده‌نشده',
            value: 'unread',
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _buildFilterButton(
            title: 'خوانده‌شده',
            value: 'read',
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton({
    required String title,
    required String value,
  }) {
    final selected = _selectedFilter == value;

    return InkWell(
      onTap: () => _changeFilter(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 11,
          horizontal: 5,
        ),
        decoration: BoxDecoration(
          color: selected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? primaryColor
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: selected
                ? Colors.white
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // کارت پیام
  Widget _buildMessageCard(
      Map<String, dynamic> message,
      ) {
    final id = _toInt(message['id']);

    final title = _text(
      message['title'],
      fallback: 'بدون عنوان',
    );

    final body = _text(
      message['message'],
      fallback: 'متن پیام موجود نیست.',
    );

    final sender = _text(
      message['sender_name'],
      fallback: 'مدیریت سامانه',
    );

    final date = _formatDate(message['created_at']);

    final isRead = message['is_read'] == true;
    final isExpanded = _expandedMessages.contains(id);
    final isMarking = _markingAsRead.contains(id);

    final color = isRead ? Colors.blueGrey : primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isRead
              ? Colors.grey.shade200
              : primaryColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _toggleMessage(message),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isRead
                            ? Icons.mark_email_read_outlined
                            : Icons.mark_email_unread_outlined,
                        color: color,
                        size: 23,
                      ),
                    ),

                    const SizedBox(width: 11),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'مدیر سامانه',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 5),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isRead
                            ? Colors.grey.shade100
                            : primaryColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isRead ? 'خوانده‌شده' : 'جدید',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isRead
                              ? Colors.blueGrey
                              : primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 15,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        date,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    if (isMarking)
                      const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    else
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: color,
                      ),
                  ],
                ),

                AnimatedCrossFade(
                  firstChild: const SizedBox(
                    width: double.infinity,
                  ),
                  secondChild: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 24),

                      const Text(
                        'متن پیام',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      SelectableText(
                        body,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.9,
                          color: Colors.black87,
                        ),
                      ),

                      if (isRead && message['read_at'] != null) ...[
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Icon(
                              Icons.done_all,
                              size: 16,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'زمان مطالعه: '
                                  '${_formatDate(message['read_at'])}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // حالت بدون پیام
  Widget _buildEmpty() {
    String message;

    if (_selectedFilter == 'unread') {
      message = 'پیام خوانده‌نشده‌ای ندارید.';
    } else if (_selectedFilter == 'read') {
      message = 'هنوز پیامی را مطالعه نکرده‌اید.';
    } else {
      message = 'هنوز پیامی از مدیریت سامانه دریافت نکرده‌اید.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 65,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 15),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // خطا
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 45,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'خطا در دریافت پیام‌ها',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadMessages,
              child: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }

  // محتوای اصلی صفحه
  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatisticsCard(),

          const SizedBox(height: 20),

          _buildFilters(),

          const SizedBox(height: 18),

          if (_loading && _messages.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(
                  color: primaryColor,
                ),
              ),
            )
          else if (_error != null && _messages.isEmpty)
            SizedBox(
              height: 250,
              child: _buildError(),
            )
          else if (_messages.isEmpty)
              SizedBox(
                height: 250,
                child: _buildEmpty(),
              )
            else ...[
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'فهرست پیام‌ها',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${_toPersianDigits(_messages.length.toString())} پیام',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ..._messages.map(_buildMessageCard),
              ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: widget.embedded
          ? Container(
        color: const Color(0xFFF7F8FA),
        child: _buildContent(),
      )
          : Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: _buildContent(),
      ),
    );
  }
}
