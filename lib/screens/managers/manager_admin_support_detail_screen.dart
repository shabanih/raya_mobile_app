
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../services/manager_admin_support_service.dart';

class ManagerAdminSupportDetailScreen extends StatefulWidget {
final int ticketId;

const ManagerAdminSupportDetailScreen({
super.key,
required this.ticketId,
});

@override
State<ManagerAdminSupportDetailScreen> createState() =>
_ManagerAdminSupportDetailScreenState();
}

class _ManagerAdminSupportDetailScreenState
extends State<ManagerAdminSupportDetailScreen> {
static const Color primaryColor = Color(0xff00ACC1);

final ApiService _apiService = ApiService();

late final ManagerAdminSupportService _supportService;

final TextEditingController _messageController =
TextEditingController();

final ScrollController _scrollController =
ScrollController();

final ImagePicker _imagePicker = ImagePicker();

Map<String, dynamic>? _ticket;

bool _loading = true;
bool _sending = false;
bool _closing = false;

final List<String> _selectedFiles = [];

@override
void initState() {
super.initState();

_supportService = ManagerAdminSupportService(
apiService: _apiService,
);

_loadTicket();
}

@override
void dispose() {
_messageController.dispose();
_scrollController.dispose();
super.dispose();
}

// =====================================================
// دریافت جزئیات تیکت
// =====================================================

Future<void> _loadTicket({
bool scrollToBottom = false,
}) async {
if (!mounted) return;

setState(() {
_loading = true;
});

try {
final ticket = await _supportService.getTicket(
widget.ticketId,
);

if (!mounted) return;

setState(() {
_ticket = ticket;
_loading = false;
});

try {
await _supportService.markAsRead(
widget.ticketId,
);
} catch (_) {}

if (scrollToBottom) {
WidgetsBinding.instance.addPostFrameCallback((_) {
_scrollToBottom();
});
}
} catch (e) {
if (!mounted) return;

setState(() {
_loading = false;
});

_showError(
_cleanError(e),
);
}
}

// =====================================================
// انتخاب تصاویر
// =====================================================

Future<void> _pickFiles() async {
if (_sending || _isClosed) {
return;
}

try {
final images = await _imagePicker.pickMultiImage(
imageQuality: 90,
);

if (images.isEmpty) {
return;
}

final newFiles = <String>[];

for (final image in images) {
final path = image.path;

if (path.trim().isEmpty) {
continue;
}

if (!_selectedFiles.contains(path)) {
newFiles.add(path);
}
}

if (!mounted) return;

setState(() {
_selectedFiles.addAll(newFiles);
});
} catch (_) {
if (!mounted) return;

_showError(
'انتخاب تصویر انجام نشد.',
);
}
}

// =====================================================
// حذف فایل انتخاب شده
// =====================================================

void _removeSelectedFile(int index) {
if (_sending) {
return;
}

if (index < 0 ||
index >= _selectedFiles.length) {
return;
}

setState(() {
_selectedFiles.removeAt(index);
});
}

// =====================================================
// ارسال پیام
// =====================================================

Future<void> _sendMessage() async {
if (_sending || _isClosed) {
return;
}

final message =
_messageController.text.trim();

if (message.isEmpty &&
_selectedFiles.isEmpty) {
_showError(
'متن پیام یا تصویر پیوست را وارد کنید.',
);
return;
}

setState(() {
_sending = true;
});

try {
await _supportService.sendMessage(
ticketId: widget.ticketId,
message: message,
filePaths: List<String>.from(
_selectedFiles,
),
);

if (!mounted) return;

_messageController.clear();

setState(() {
_selectedFiles.clear();
_sending = false;
});

await _loadTicket(
scrollToBottom: true,
);

if (!mounted) return;

_showSuccess(
'پیام با موفقیت ارسال شد.',
);
} catch (e) {
if (!mounted) return;

setState(() {
_sending = false;
});

_showError(
_cleanError(e),
);
}
}

// =====================================================
// بستن تیکت
// =====================================================

Future<void> _closeTicket() async {
if (_closing || _isClosed) {
return;
}

final confirmed =
await _showCloseConfirmation();

if (!confirmed) {
return;
}

if (!mounted) return;

setState(() {
_closing = true;
});

try {
await _supportService.closeTicket(
widget.ticketId,
);

if (!mounted) return;

setState(() {
_closing = false;
});

await _loadTicket();

if (!mounted) return;

_showSuccess(
'تیکت با موفقیت بسته شد.',
);
} catch (e) {
if (!mounted) return;

setState(() {
_closing = false;
});

_showError(
_cleanError(e),
);
}
}

// =====================================================
// تأیید بستن تیکت
// =====================================================

Future<bool> _showCloseConfirmation() async {
final result = await showDialog<bool>(
context: context,
builder: (context) {
return Directionality(
textDirection: TextDirection.rtl,
child: AlertDialog(
title: const Text(
'بستن تیکت',
textAlign: TextAlign.right,
),
content: const Text(
'آیا از بستن این تیکت مطمئن هستید؟\n'
'پس از بسته شدن، امکان ارسال پیام جدید وجود ندارد.',
textAlign: TextAlign.right,
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
),
),
ElevatedButton(
style: ElevatedButton.styleFrom(
backgroundColor: Colors.red,
foregroundColor: Colors.white,
),
onPressed: () {
Navigator.pop(
context,
true,
);
},
child: const Text(
'بستن تیکت',
),
),
],
),
);
},
);

return result == true;
}

// =====================================================
// اسکرول
// =====================================================

void _scrollToBottom() {
if (!_scrollController.hasClients) {
return;
}

_scrollController.animateTo(
_scrollController.position.maxScrollExtent,
duration: const Duration(
milliseconds: 300,
),
curve: Curves.easeOut,
);
}

// =====================================================
// وضعیت
// =====================================================

String get _status {
final status =
_ticket?['status']
    ?.toString()
    .trim();

if (status == null ||
status.isEmpty) {
if (_ticket?['is_closed'] == true) {
return 'بسته شده';
}

if (_ticket?['is_waiting'] == true) {
return 'در حال بررسی';
}

if (_ticket?['is_answer'] == true) {
return 'پاسخ داده شده';
}

return 'در انتظار پاسخ';
}

return status;
}

bool get _isClosed {
return _ticket?['is_closed'] == true ||
_status == 'بسته شده';
}

Color _statusColor() {
switch (_status) {
case 'در حال بررسی':
return Colors.orange;

case 'پاسخ داده شده':
return Colors.green;

case 'بسته شده':
return Colors.red;

case 'در انتظار پاسخ':
case 'منتظر پاسخ':
default:
return Colors.amber.shade800;
}
}

// =====================================================
// پیام‌ها
// =====================================================

List<dynamic> get _messages {
final messages =
_ticket?['messages'];

if (messages is List) {
return messages;
}

return [];
}

// =====================================================
// ساخت پیام
// =====================================================

Widget _buildMessage(
Map<String, dynamic> message,
) {
final senderRole =
message['sender_role']
    ?.toString()
    .trim() ??
'';

final senderName =
message['sender_name']
    ?.toString()
    .trim() ??
'';

final text =
message['message']
    ?.toString() ??
'';

final createdAt =
message['created_at']
    ?.toString() ??
'';

final attachments =
message['attachments'];

final isManager =
senderRole == 'مدیر ساختمان' ||
senderRole == 'مدیر';

final displayName =
senderName.isNotEmpty
? senderName
    : (isManager
? 'مدیر ساختمان'
    : 'پشتیبانی سامانه');

return Align(
alignment: isManager
? Alignment.centerRight
    : Alignment.centerLeft,
child: Container(
width:
MediaQuery.of(context).size.width *
0.84,
margin:
const EdgeInsets.only(
bottom: 12,
),
padding:
const EdgeInsets.all(12),
decoration: BoxDecoration(
color: isManager
? primaryColor.withOpacity(0.14)
    : Colors.green.shade300,
borderRadius:
BorderRadius.circular(14),
border: Border.all(
color: isManager
? primaryColor.withOpacity(0.20)
    : Colors.green.shade300,
),
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
children: [
CircleAvatar(
radius: 18,
backgroundColor:
isManager
? primaryColor
    : Colors.deepPurple,
child: Icon(
isManager
? Icons
    .admin_panel_settings
    : Icons.support_agent,
color: Colors.white,
size: 20,
),
),

const SizedBox(
width: 8,
),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
displayName,
textDirection:
TextDirection.rtl,
style:
const TextStyle(
fontWeight:
FontWeight.bold,
fontSize: 13,
),
),
const SizedBox(
height: 2,
),
Text(
isManager
? 'مدیر ساختمان'
    : 'پشتیبانی سامانه',
textDirection:
TextDirection.rtl,
style: TextStyle(
fontSize: 11,
color: isManager
? primaryColor
    : Colors.deepPurple,
fontWeight:
FontWeight.w600,
),
),
],
),
),

if (createdAt.isNotEmpty)
Text(
_formatDate(
createdAt,
),
textDirection:
TextDirection.ltr,
style: TextStyle(
fontSize: 10,
color:
Colors.grey.shade600,
),
),
],
),

const SizedBox(
height: 10,
),

if (text.trim().isNotEmpty)
Container(
width:
double.infinity,
padding:
const EdgeInsets.all(10),
decoration:
BoxDecoration(
color: Colors.white
    .withOpacity(0.75),
borderRadius:
BorderRadius.circular(10),
),
child: Directionality(
textDirection:
TextDirection.rtl,
child: Text(
_stripHtml(text),
textAlign:
TextAlign.right,
style:
const TextStyle(
fontSize: 14,
height: 1.7,
),
),
),
),

if (attachments is List &&
attachments.isNotEmpty) ...[
const SizedBox(
height: 10,
),
_buildAttachments(
attachments,
),
],
],
),
),
);
}

// =====================================================
// فایل‌های پیام
// =====================================================

Widget _buildAttachments(
List attachments,
) {
return Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Divider(),

const Text(
'فایل‌های پیوست',
textDirection:
TextDirection.rtl,
style: TextStyle(
fontWeight:
FontWeight.bold,
fontSize: 12,
),
),

const SizedBox(
height: 6,
),

...attachments.map(
(item) {
if (item is! Map) {
return const SizedBox.shrink();
}

final file =
Map<String, dynamic>.from(
item,
);

final url =
file['file_url']
    ?.toString();

final rawName =
file['file']
    ?.toString() ??
file['name']
    ?.toString() ??
'فایل پیوست';

return InkWell(
onTap: () {
if (url != null &&
url.isNotEmpty) {
_openFile(url);
}
},
borderRadius:
BorderRadius.circular(9),
child: Container(
width:
double.infinity,
margin:
const EdgeInsets.only(
top: 5,
),
padding:
const EdgeInsets.symmetric(
horizontal: 10,
vertical: 8,
),
decoration:
BoxDecoration(
color: Colors.white,
borderRadius:
BorderRadius.circular(9),
border: Border.all(
color:
Colors.grey.shade300,
),
),
child: Row(
children: [
const Icon(
Icons.attach_file,
size: 18,
color: primaryColor,
),
const SizedBox(
width: 7,
),
Expanded(
child: Text(
_fileName(rawName),
maxLines: 1,
overflow:
TextOverflow.ellipsis,
textDirection:
TextDirection.rtl,
style:
const TextStyle(
fontSize: 12,
),
),
),
const Icon(
Icons.open_in_new,
size: 16,
color: primaryColor,
),
],
),
),
);
},
),
],
);
}

// =====================================================
// باز کردن فایل
// =====================================================

Future<void> _openFile(
String url,
) async {
try {
final uri =
Uri.tryParse(url);

if (uri == null) {
_showError(
'آدرس فایل نامعتبر است.',
);
return;
}

final launched =
await launchUrl(
uri,
mode:
LaunchMode.externalApplication,
);

if (!launched) {
_showError(
'امکان باز کردن فایل وجود ندارد.',
);
}
} catch (_) {
_showError(
'امکان باز کردن فایل وجود ندارد.',
);
}
}

// =====================================================
// فایل‌های انتخاب شده
// =====================================================

Widget _buildSelectedFiles() {
if (_selectedFiles.isEmpty) {
return const SizedBox.shrink();
}

return Container(
width:
double.infinity,
margin:
const EdgeInsets.only(
bottom: 8,
),
padding:
const EdgeInsets.symmetric(
horizontal: 10,
vertical: 7,
),
decoration:
BoxDecoration(
color: primaryColor
    .withOpacity(0.07),
borderRadius:
BorderRadius.circular(10),
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Text(
'تصاویر انتخاب شده',
textDirection:
TextDirection.rtl,
style: TextStyle(
fontWeight:
FontWeight.bold,
fontSize: 12,
),
),

const SizedBox(
height: 4,
),

...List.generate(
_selectedFiles.length,
(index) {
final path =
_selectedFiles[index];

return Container(
margin:
const EdgeInsets.only(
top: 3,
),
child: Row(
children: [
const Icon(
Icons.image_outlined,
size: 17,
color: primaryColor,
),

const SizedBox(
width: 6,
),

Expanded(
child: Text(
_fileName(path),
maxLines: 1,
overflow:
TextOverflow.ellipsis,
textDirection:
TextDirection.rtl,
style:
const TextStyle(
fontSize: 11,
),
),
),

IconButton(
visualDensity:
VisualDensity.compact,
padding:
EdgeInsets.zero,
icon:
const Icon(
Icons.close,
size: 18,
color: Colors.red,
),
onPressed:
() {
_removeSelectedFile(
index,
);
},
),
],
),
);
},
),
],
),
);
}

// =====================================================
// Header
// =====================================================

Widget _buildHeader() {
final ticketNo =
_ticket?['ticket_no']
    ?.toString() ??
'-';

final subject =
_ticket?['subject']
    ?.toString()
    .trim() ??
'';

final createdAt =
_ticket?['created_at']
    ?.toString();

final statusColor =
_statusColor();

return Container(
width:
double.infinity,
padding:
const EdgeInsets.all(14),
margin:
const EdgeInsets.fromLTRB(
12,
12,
12,
6,
),
decoration:
BoxDecoration(
color: Colors.white,
borderRadius:
BorderRadius.circular(14),
boxShadow: [
BoxShadow(
color:
Colors.black.withOpacity(
0.05,
),
blurRadius: 8,
offset:
const Offset(0, 2),
),
],
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
children: [
const Icon(
Icons
    .confirmation_number_outlined,
color: primaryColor,
),

const SizedBox(
width: 7,
),

Expanded(
child: Text(
'تیکت #${_persianNumber(ticketNo)}',
textDirection:
TextDirection.rtl,
style:
const TextStyle(
fontSize: 16,
fontWeight:
FontWeight.bold,
),
),
),

Container(
padding:
const EdgeInsets.symmetric(
horizontal: 9,
vertical: 5,
),
decoration:
BoxDecoration(
color:
statusColor.withOpacity(
0.12,
),
borderRadius:
BorderRadius.circular(
20,
),
),
child: Text(
_status,
textDirection:
TextDirection.rtl,
style:
TextStyle(
color:
statusColor,
fontWeight:
FontWeight.bold,
fontSize: 11,
),
),
),
],
),

if (subject.isNotEmpty) ...[
const SizedBox(
height: 10,
),
Text(
subject,
textDirection:
TextDirection.rtl,
textAlign:
TextAlign.right,
style:
const TextStyle(
fontSize: 14,
fontWeight:
FontWeight.w600,
),
),
],

if (createdAt != null &&
createdAt.trim().isNotEmpty) ...[
const SizedBox(
height: 7,
),
Text(
'تاریخ ثبت: ${_formatDate(createdAt)}',
textDirection:
TextDirection.rtl,
textAlign:
TextAlign.right,
style: TextStyle(
fontSize: 11,
color:
Colors.grey.shade600,
),
),
],
],
),
);
}

// =====================================================
// فقط دکمه بستن تیکت
// =====================================================

Widget _buildActionButtons() {
if (_isClosed) {
return Container(
width:
double.infinity,
margin:
const EdgeInsets.symmetric(
horizontal: 12,
vertical: 5,
),
padding:
const EdgeInsets.symmetric(
vertical: 11,
),
decoration:
BoxDecoration(
color: Colors.red
    .withOpacity(0.08),
borderRadius:
BorderRadius.circular(12),
border: Border.all(
color: Colors.red
    .withOpacity(0.15),
),
),
child: const Text(
'این تیکت بسته شده است.',
textAlign:
TextAlign.center,
textDirection:
TextDirection.rtl,
style: TextStyle(
color: Colors.red,
fontWeight:
FontWeight.bold,
),
),
);
}

return Padding(
padding:
const EdgeInsets.symmetric(
horizontal: 12,
vertical: 5,
),
child: SizedBox(
width:
double.infinity,
child: ElevatedButton.icon(
onPressed:
_closing
? null
    : _closeTicket,
style:
ElevatedButton.styleFrom(
backgroundColor:
Colors.red,
foregroundColor:
Colors.white,
disabledBackgroundColor:
Colors.red.withOpacity(
0.45,
),
disabledForegroundColor:
Colors.white,
padding:
const EdgeInsets.symmetric(
vertical: 12,
),
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(
10,
),
),
),
icon: _closing
? const SizedBox(
width: 18,
height: 18,
child:
CircularProgressIndicator(
strokeWidth: 2,
color:
Colors.white,
),
)
    : const Icon(
Icons.close,
size: 20,
),
label: const Text(
'بستن تیکت',
style: TextStyle(
fontWeight:
FontWeight.bold,
),
),
),
),
);
}

// =====================================================
// کادر ارسال پیام
// =====================================================

Widget _buildMessageComposer() {
if (_isClosed) {
return Container(
width:
double.infinity,
margin:
const EdgeInsets.fromLTRB(
12,
5,
12,
12,
),
padding:
const EdgeInsets.all(12),
decoration:
BoxDecoration(
color:
Colors.red.shade50,
borderRadius:
BorderRadius.circular(12),
border: Border.all(
color:
Colors.red.shade100,
),
),
child: const Text(
'این تیکت بسته شده است و امکان ارسال پیام جدید وجود ندارد.',
textDirection:
TextDirection.rtl,
textAlign:
TextAlign.center,
style: TextStyle(
color: Colors.red,
fontWeight:
FontWeight.w600,
),
),
);
}

return SafeArea(
top: false,
child: Container(
padding:
const EdgeInsets.fromLTRB(
10,
7,
10,
7,
),
decoration:
const BoxDecoration(
color: Colors.white,
boxShadow: [
BoxShadow(
color:
Color(0x22000000),
blurRadius: 8,
offset:
Offset(0, -2),
),
],
),
child: Column(
children: [
_buildSelectedFiles(),

Row(
crossAxisAlignment:
CrossAxisAlignment.end,
children: [
IconButton(
tooltip:
'افزودن تصویر',
onPressed:
_sending
? null
    : _pickFiles,
icon:
const Icon(
Icons.attach_file,
),
color:
primaryColor,
),

Expanded(
child: TextField(
controller:
_messageController,
minLines: 1,
maxLines: 5,
textDirection:
TextDirection.rtl,
textAlign:
TextAlign.right,
enabled:
!_sending,
decoration:
InputDecoration(
hintText:
'پیام خود را بنویسید...',
hintTextDirection:
TextDirection.rtl,
filled: true,
fillColor:
Colors.grey.shade100,
border:
OutlineInputBorder(
borderRadius:
BorderRadius.circular(
12,
),
borderSide:
BorderSide.none,
),
contentPadding:
const EdgeInsets
    .symmetric(
horizontal: 12,
vertical: 10,
),
),
),
),

const SizedBox(
width: 6,
),

IconButton(
tooltip: 'ارسال',
onPressed:
_sending
? null
    : _sendMessage,
color:
primaryColor,
icon: _sending
? const SizedBox(
width: 23,
height: 23,
child:
CircularProgressIndicator(
strokeWidth:
2.5,
color:
primaryColor,
),
)
    : const Icon(
Icons.send,
),
),
],
),
],
),
),
);
}

// =====================================================
// صفحه
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
const Color(0xffF5F7F8),
appBar: AppBar(
backgroundColor:
primaryColor,
foregroundColor:
Colors.white,
title:
const Text(
'جزئیات تیکت',
style: TextStyle(
fontWeight:
FontWeight.bold,
),
),
centerTitle: true,
actions: [
IconButton(
tooltip:
'بازخوانی',
onPressed:
_loading
? null
    : () {
_loadTicket();
},
icon:
const Icon(
Icons.refresh,
),
),
],
),
body: _loading
? const Center(
child:
CircularProgressIndicator(
color:
primaryColor,
),
)
    : _ticket == null
? Center(
child: Column(
mainAxisSize:
MainAxisSize.min,
children: [
const Icon(
Icons
    .error_outline,
size: 50,
color:
Colors.grey,
),
const SizedBox(
height: 10,
),
const Text(
'اطلاعات تیکت دریافت نشد.',
textDirection:
TextDirection.rtl,
),
const SizedBox(
height: 12,
),
ElevatedButton(
onPressed:
_loadTicket,
child:
const Text(
'تلاش مجدد',
),
),
],
),
)
    : Column(
children: [
_buildHeader(),

// فقط بستن تیکت
_buildActionButtons(),

Expanded(
child:
RefreshIndicator(
color:
primaryColor,
onRefresh:
() =>
_loadTicket(),
child:
ListView(
controller:
_scrollController,
padding:
const EdgeInsets
    .fromLTRB(
12,
8,
12,
12,
),
children: [
if (_messages
    .isEmpty)
Container(
padding:
const EdgeInsets
    .all(
20,
),
child:
const Text(
'هنوز پیامی در این تیکت ثبت نشده است.',
textDirection:
TextDirection.rtl,
textAlign:
TextAlign.center,
),
)
else
..._messages.map(
(item) {
if (item
is Map) {
return _buildMessage(
Map<String,
dynamic>.from(
item),
);
}

return const SizedBox
    .shrink();
},
),
],
),
),
),

_buildMessageComposer(),
],
),
),
);
}

// =====================================================
// خطا
// =====================================================

void _showError(
String message,
) {
if (!mounted) return;

ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(
message,
textDirection:
TextDirection.rtl,
),
backgroundColor:
Colors.red.shade700,
),
);
}

// =====================================================
// موفقیت
// =====================================================

void _showSuccess(
String message,
) {
if (!mounted) return;

ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(
message,
textDirection:
TextDirection.rtl,
),
backgroundColor:
Colors.green.shade700,
),
);
}

// =====================================================
// پاکسازی خطا
// =====================================================

String _cleanError(
Object error,
) {
var message =
error.toString();

if (message.startsWith(
'Exception: ',
)) {
message =
message.substring(11);
}

if (message ==
'NO_INTERNET') {
return 'اتصال اینترنت برقرار نیست.';
}

if (message ==
'REQUEST_TIMEOUT') {
return 'زمان درخواست به پایان رسید.';
}

if (message ==
'TOKEN_EXPIRED') {
return 'نشست کاربری شما منقضی شده است.';
}

return message.isEmpty
? 'خطایی رخ داد.'
    : message;
}

// =====================================================
// حذف HTML
// =====================================================

String _stripHtml(
String value,
) {
return value
    .replaceAll(
RegExp(
r'<br\s*/?>',
caseSensitive: false,
),
'\n',
)
    .replaceAll(
RegExp(
r'</p>',
caseSensitive: false,
),
'\n',
)
    .replaceAll(
RegExp(
r'<[^>]*>',
),
'',
)
    .replaceAll(
'&nbsp;',
' ',
)
    .replaceAll(
'&amp;',
'&',
)
    .replaceAll(
'&lt;',
'<',
)
    .replaceAll(
'&gt;',
'>',
)
    .replaceAll(
'&quot;',
'"',
)
    .replaceAll(
'&#39;',
"'",
)
    .trim();
}

// =====================================================
// نام فایل
// =====================================================

String _fileName(
String path,
) {
try {
return path
    .split(
Platform.pathSeparator,
)
    .last;
} catch (_) {
return path;
}
}

// =====================================================
// تاریخ
// =====================================================

String _formatDate(
String value,
) {
try {
final date =
DateTime.parse(value)
    .toLocal();

final year =
date.year.toString();

final month =
date.month
    .toString()
    .padLeft(
2,
'0',
);

final day =
date.day
    .toString()
    .padLeft(
2,
'0',
);

final hour =
date.hour
    .toString()
    .padLeft(
2,
'0',
);

final minute =
date.minute
    .toString()
    .padLeft(
2,
'0',
);

return _persianNumber(
'$year/$month/$day $hour:$minute',
);
} catch (_) {
return value;
}
}

// =====================================================
// اعداد فارسی
// =====================================================

String _persianNumber(
String value,
) {
return value
    .replaceAll(
'0',
'۰',
)
    .replaceAll(
'1',
'۱',
)
    .replaceAll(
'2',
'۲',
)
    .replaceAll(
'3',
'۳',
)
    .replaceAll(
'4',
'۴',
)
    .replaceAll(
'5',
'۵',
)
    .replaceAll(
'6',
'۶',
)
    .replaceAll(
'7',
'۷',
)
    .replaceAll(
'8',
'۸',
)
    .replaceAll(
'9',
'۹',
);
}
}

