import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/manager_admin_support_service.dart';
import 'manager_admin_support_detail_screen.dart';

class ManagerAdminSupportTicketsScreen extends StatefulWidget {
  const ManagerAdminSupportTicketsScreen({
    super.key,
  });

  @override
  State<ManagerAdminSupportTicketsScreen> createState() =>
      _ManagerAdminSupportTicketsScreenState();
}

class _ManagerAdminSupportTicketsScreenState
    extends State<ManagerAdminSupportTicketsScreen> {
  static const Color primaryColor = Color(0xff00ACC1);

  late final ManagerAdminSupportService _service;

  List<Map<String, dynamic>> _tickets = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    _service = ManagerAdminSupportService(
      apiService: ApiService(),
    );

    _loadTickets();
  }

  // =====================================================
  // دریافت تیکت‌ها
  // =====================================================

  Future<void> _loadTickets() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final tickets = await _service.getTickets();

      if (!mounted) return;

      setState(() {
        _tickets = tickets;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  // =====================================================
  // Refresh
  // =====================================================

  Future<void> _refresh() async {
    await _loadTickets();
  }

  // =====================================================
  // باز کردن تیکت
  // =====================================================

  Future<void> _openTicket(
      Map<String, dynamic> ticket,
      ) async {
    final ticketId = int.tryParse(
      ticket['id']?.toString() ?? '',
    );

    if (ticketId == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerAdminSupportDetailScreen(
          ticketId: ticketId,
        ),
      ),
    );

    if (!mounted) return;

    await _loadTickets();
  }

  // =====================================================
  // ایجاد تیکت جدید
  // =====================================================

  Future<void> _createTicket() async {
    /*
    این قسمت بعد از ساخت صفحه
    ManagerAdminSupportCreateScreen
    به آن متصل می‌شود.

    نمونه:

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ManagerAdminSupportCreateScreen(),
      ),
    );

    if (result == true && mounted) {
      await _loadTickets();
    }
    */
  }

  // =====================================================
  // وضعیت تیکت
  // =====================================================

  _TicketStatus _getTicketStatus(
      String status,
      ) {
    switch (status.trim()) {
      case 'در حال بررسی':
        return const _TicketStatus(
          text: 'در حال بررسی',
          color: Colors.orange,
        );

      case 'پاسخ داده شده':
        return const _TicketStatus(
          text: 'پاسخ داده شده',
          color: Colors.green,
        );

      case 'بسته شده':
        return const _TicketStatus(
          text: 'بسته شده',
          color: Colors.red,
        );

      case 'در انتظار پاسخ':
      default:
        return const _TicketStatus(
          text: 'در انتظار پاسخ',
          color: Colors.amber,
        );
    }
  }

  // =====================================================
  // تبدیل اعداد انگلیسی به فارسی
  // =====================================================

  String _persianNumber(
      dynamic value,
      ) {
    return value
        .toString()
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

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF5F7F8),
        appBar: AppBar(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'تیکت‌های من',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          onPressed: _createTicket,
          child: const Icon(
            Icons.add,
            size: 28,
          ),
        ),
      ),
    );
  }

  // =====================================================
  // Body
  // =====================================================

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    // ===================================================
    // خطا
    // ===================================================

    if (_error != null) {
      return RefreshIndicator(
        color: primaryColor,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 150),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 52,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadTickets,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'تلاش مجدد',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ===================================================
    // بدون تیکت
    // ===================================================

    if (_tickets.isEmpty) {
      return RefreshIndicator(
        color: primaryColor,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 180),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.support_agent_outlined,
                    size: 64,
                    color: primaryColor.withValues(
                      alpha: 0.65,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'هنوز تیکتی ایجاد نکرده‌اید.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'برای ارسال درخواست جدید روی + بزنید.',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ===================================================
    // لیست تیکت‌ها
    // ===================================================

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          12,
          14,
          12,
          90,
        ),
        itemCount: _tickets.length,
        itemBuilder: (
            context,
            index,
            ) {
          return _buildTicketCard(
            _tickets[index],
          );
        },
      ),
    );
  }

  // =====================================================
  // Ticket Card
  // =====================================================

  Widget _buildTicketCard(
      Map<String, dynamic> ticket,
      ) {
    final subject =
    ticket['subject']?.toString().trim().isNotEmpty == true
        ? ticket['subject'].toString()
        : 'بدون عنوان';

    final ticketNo =
        ticket['ticket_no']?.toString() ?? '-';

    final unreadCount =
        int.tryParse(
          ticket['unread_count']?.toString() ?? '0',
        ) ??
            0;

    final status =
        ticket['status']?.toString() ?? 'در انتظار پاسخ';

    final lastMessage =
    ticket['last_message'];

    String lastMessageText = '';

    if (lastMessage is Map) {
      lastMessageText =
          lastMessage['message']?.toString() ?? '';
    }

    final ticketStatus = _getTicketStatus(
      status,
    );

    debugPrint(
      'ADMIN SUPPORT TICKET DEBUG: '
          'id=${ticket['id']} '
          'ticket_no=${ticket['ticket_no']} '
          'status=${ticket['status']} '
          'unread_count=${ticket['unread_count']} '
          'type=${ticket['unread_count']?.runtimeType}',
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 11,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.055,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openTicket(ticket),
            splashColor: primaryColor.withValues(
              alpha: 0.08,
            ),
            highlightColor: primaryColor.withValues(
              alpha: 0.04,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                13,
                14,
                12,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // =====================================
                  // وضعیت + شماره تیکت
                  // =====================================

                  Row(
                    children: [
                      _statusChip(
                        ticketStatus,
                      ),

                      const Spacer(),

                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(
                            alpha: 0.08,
                          ),
                          borderRadius:
                          BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${_persianNumber(ticketNo)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 11),

                  // =====================================
                  // عنوان
                  // =====================================

                  Text(
                    subject,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.45,
                    ),
                  ),

                  // =====================================
                  // آخرین پیام
                  // =====================================

                  if (lastMessageText.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            lastMessageText,
                            maxLines: 2,
                            overflow:
                            TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 11),

                  // =====================================
                  // جداکننده
                  // =====================================

                  Divider(
                    height: 1,
                    thickness: 0.7,
                    color: Colors.grey.withValues(
                      alpha: 0.12,
                    ),
                  ),

                  const SizedBox(height: 9),

                  // =====================================
                  // پیام جدید + مشاهده
                  // =====================================

                  Row(
                    children: [
                      if (unreadCount > 0)
                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius:
                            BorderRadius.circular(20),
                            border: Border.all(
                              color:
                              Colors.red.withValues(
                                alpha: 0.15,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize:
                            MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons
                                    .mark_chat_unread_outlined,
                                size: 14,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                unreadCount == 1
                                    ? 'پیام جدید'
                                    : '${_persianNumber(unreadCount)} پیام جدید',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 10,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const Spacer(),

                      Text(
                        'مشاهده تیکت',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 3),

                      const Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // Status Chip
  // =====================================================

  Widget _statusChip(
      _TicketStatus status,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: status.color.withValues(
          alpha: 0.10,
        ),
        border: Border.all(
          color: status.color.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: status.color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// Ticket Status Model
// =========================================================

class _TicketStatus {
  final String text;
  final Color color;

  const _TicketStatus({
    required this.text,
    required this.color,
  });
}