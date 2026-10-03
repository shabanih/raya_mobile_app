
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/manager_support_service.dart';
import 'manager_support_detail_screen.dart';

class ManagerSupportTicketsScreen extends StatefulWidget {
const ManagerSupportTicketsScreen({
super.key,
});

@override
State<ManagerSupportTicketsScreen> createState() =>
_ManagerSupportTicketsScreenState();
}

class _ManagerSupportTicketsScreenState
extends State<ManagerSupportTicketsScreen> {
static const Color primaryColor = Color(0xff00ACC1);

late final ManagerSupportService _service;

List<Map<String, dynamic>> _tickets = [];

bool _loading = true;
String? _error;

@override
void initState() {
super.initState();

_service = ManagerSupportService(
apiService: ApiService(),
);

_loadTickets();
}

// =====================================================
// دریافت تیکت‌ها
// =====================================================

Future<void> _loadTickets() async {
setState(() {
_loading = true;
_error = null;
});

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
builder: (_) => ManagerSupportDetailScreen(
ticketId: ticketId,
),
),
);

if (!mounted) return;

await _loadTickets();
}

// =====================================================
// Refresh
// =====================================================

Future<void> _refresh() async {
await _loadTickets();
}

// =====================================================
// UI
// =====================================================

@override
Widget build(BuildContext context) {
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
'تیکت‌های ساکنین',
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
'تیکتی وجود ندارد.',
style: TextStyle(
color: Colors.grey.shade700,
fontSize: 15,
fontWeight: FontWeight.w600,
),
),
],
),
),
],
),
);
}

return RefreshIndicator(
color: primaryColor,
onRefresh: _refresh,
child: ListView.builder(
padding: const EdgeInsets.fromLTRB(
12,
14,
12,
20,
),
itemCount: _tickets.length,
itemBuilder: (context, index) {
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

final userName =
ticket['user_name']?.toString() ?? '-';

final userMobile =
ticket['user_mobile']?.toString();

final isCall =
ticket['is_call'] == true;

final isClosed =
ticket['is_closed'] == true;

final isWaiting =
ticket['is_waiting'] == true;

final isAnswer =
ticket['is_answer'] == true;

final unreadCount =
int.tryParse(
ticket['unread_count']?.toString() ?? '0',
) ??
0;
debugPrint(
  'MANAGER TICKET DEBUG: '
      'id=${ticket['id']} '
      'ticket_no=${ticket['ticket_no']} '
      'unread_count=${ticket['unread_count']} '
      'type=${ticket['unread_count']?.runtimeType}',
);

final lastMessage =
ticket['last_message'];

String lastMessageText = '';

if (lastMessage is Map) {
lastMessageText =
lastMessage['message']?.toString() ?? '';
}

// ===================================================
// وضعیت
// ===================================================

final status = _getTicketStatus(
isClosed: isClosed,
isWaiting: isWaiting,
isAnswer: isAnswer,
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

// =================================================
// ردیف اول
// وضعیت + شماره تیکت
// =================================================

Row(
children: [
_statusChip(status),

const Spacer(),

Container(
padding: const EdgeInsets.symmetric(
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
'#$ticketNo',
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

// =================================================
// عنوان
// =================================================

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

const SizedBox(height: 9),

// =================================================
// اطلاعات ساکن
// =================================================

Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 8,
),
decoration: BoxDecoration(
color: const Color(0xffF7F9FA),
borderRadius: BorderRadius.circular(10),
),
child: Row(
children: [
Container(
width: 32,
height: 32,
decoration: BoxDecoration(
color: primaryColor.withValues(
alpha: 0.10,
),
shape: BoxShape.circle,
),
child: const Icon(
Icons.person_outline,
size: 18,
color: primaryColor,
),
),
const SizedBox(width: 8),
Expanded(
child: Text(
userName,
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 13,
fontWeight: FontWeight.w600,
),
),
),
],
),
),

// =================================================
// درخواست تماس
// =================================================

if (isCall) ...[
const SizedBox(height: 8),

Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 8,
),
decoration: BoxDecoration(
color: Colors.orange.withValues(
alpha: 0.10,
),
borderRadius:
BorderRadius.circular(10),
border: Border.all(
color: Colors.orange.withValues(
alpha: 0.18,
),
),
),
child: Row(
children: [
const Icon(
Icons.phone_outlined,
size: 18,
color: Colors.orange,
),
const SizedBox(width: 7),
const Text(
'درخواست تماس',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.bold,
color: Colors.orange,
),
),
if (userMobile != null &&
userMobile.isNotEmpty) ...[
const Spacer(),
Text(
userMobile,
textDirection:
TextDirection.ltr,
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
),
),
],
],
),
),
],

// =================================================
// آخرین پیام
// =================================================

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
overflow: TextOverflow.ellipsis,
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

// =================================================
// خط جداکننده
// =================================================

Divider(
height: 1,
thickness: 0.7,
color: Colors.grey.withValues(
alpha: 0.12,
),
),

const SizedBox(height: 9),

// =================================================
// پیام جدید + ورود
// =================================================

Row(
children: [

  if (unreadCount > 0)
    Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.red.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red.withValues(
            alpha: 0.15,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.mark_chat_unread_outlined,
            size: 14,
            color: Colors.red,
          ),
          const SizedBox(width: 5),
          Text(
            unreadCount == 1
                ? 'پیام جدید'
                : '$unreadCount پیام جدید',
            style: const TextStyle(
              color: Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
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
// وضعیت تیکت
// =====================================================

_TicketStatus _getTicketStatus({
required bool isClosed,
required bool isWaiting,
required bool isAnswer,
}) {
if (isClosed) {
return const _TicketStatus(
text: 'بسته شده',
color: Colors.red,
);
}

if (isWaiting) {
return const _TicketStatus(
text: 'در حال بررسی',
color: Colors.orange,
);
}

if (isAnswer) {
return const _TicketStatus(
text: 'پاسخ داده شده',
color: Colors.green,
);
}

return const _TicketStatus(
text: 'در انتظار پاسخ',
color: primaryColor,
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
