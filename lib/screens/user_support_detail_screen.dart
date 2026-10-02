
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import '../services/user_support_service.dart';

class UserSupportDetailScreen extends StatefulWidget {
final int ticketId;

const UserSupportDetailScreen({
super.key,
required this.ticketId,
});

@override
State<UserSupportDetailScreen> createState() =>
_UserSupportDetailScreenState();
}

class _UserSupportDetailScreenState
extends State<UserSupportDetailScreen> {
static const Color primaryColor = Color(0xff00ACC1);

late final UserSupportService _supportService;

final TextEditingController _messageController =
TextEditingController();

final ImagePicker _imagePicker = ImagePicker();

Map<String, dynamic>? _ticket;

bool _loading = true;
bool _sending = false;
bool _closing = false;

String? _selectedFile;

@override
void initState() {
super.initState();

_supportService = UserSupportService(
apiService: ApiService(),
);

_loadTicket();
}

@override
void dispose() {
_messageController.dispose();
super.dispose();
}

// ============================================================
// دریافت تیکت
// ============================================================

Future<void> _loadTicket() async {
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

// --------------------------------------------------------
// علامت‌گذاری پیام‌های مدیر به عنوان خوانده شده
// --------------------------------------------------------

final unreadCount =
int.tryParse(
ticket['unread_count']?.toString() ?? '0',
) ??
0;

if (unreadCount > 0) {
try {
await _supportService.markAsRead(
widget.ticketId,
);
} catch (_) {}
}
} catch (e) {
if (!mounted) return;

setState(() {
_loading = false;
});

_showError(
_cleanException(e),
);
}
}

// ============================================================
// وضعیت تیکت
// ============================================================

bool _isClosed() {
return _ticket?['is_closed'] == true;
}

String _statusText() {
if (_isClosed()) {
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

Color _statusColor() {
if (_isClosed()) {
return Colors.red;
}

if (_ticket?['is_waiting'] == true) {
return Colors.orange;
}

if (_ticket?['is_answer'] == true) {
return Colors.green;
}

return primaryColor;
}

// ============================================================
// انتخاب فایل
// ============================================================

Future<void> _pickFile() async {
if (_sending || _isClosed()) {
return;
}

try {
final image = await _imagePicker.pickImage(
source: ImageSource.gallery,
imageQuality: 90,
);

if (image == null) {
return;
}

if (!mounted) return;

setState(() {
_selectedFile = image.path;
});
} catch (_) {
if (!mounted) return;

_showError(
'انتخاب فایل با خطا مواجه شد.',
);
}
}

void _removeSelectedFile() {
setState(() {
_selectedFile = null;
});
}

// ============================================================
// ارسال پیام
// ============================================================

Future<void> _sendMessage() async {
if (_sending || _isClosed()) {
return;
}

final message =
_messageController.text.trim();

if (message.isEmpty &&
(_selectedFile == null ||
_selectedFile!.trim().isEmpty)) {
_showError(
'متن پیام یا فایل پیوست را وارد کنید.',
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
filePath: _selectedFile,
);

if (!mounted) return;

_messageController.clear();

setState(() {
_selectedFile = null;
});

await _loadTicket();

if (!mounted) return;

_showSuccess(
'پیام با موفقیت ارسال شد.',
);
} catch (e) {
if (!mounted) return;

_showError(
_cleanException(e),
);
} finally {
if (!mounted) return;

setState(() {
_sending = false;
});
}
}

// ============================================================
// بستن تیکت
// ============================================================

Future<void> _closeTicket() async {
if (_closing || _isClosed()) {
return;
}

final confirm = await showDialog<bool>(
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
'آیا مطمئن هستید که می‌خواهید این تیکت را ببندید؟',
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

if (confirm != true) {
return;
}

setState(() {
_closing = true;
});

try {
await _supportService.closeTicket(
widget.ticketId,
);

if (!mounted) return;

await _loadTicket();

if (!mounted) return;

_showSuccess(
'تیکت با موفقیت بسته شد.',
);
} catch (e) {
if (!mounted) return;

_showError(
_cleanException(e),
);
} finally {
if (!mounted) return;

setState(() {
_closing = false;
});
}
}

// ============================================================
// خطا
// ============================================================

String _cleanException(
Object error,
) {
final text = error
    .toString()
    .replaceFirst(
'Exception: ',
'',
)
    .trim();

return text.isEmpty
? 'خطایی رخ داد.'
    : text;
}

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
textAlign: TextAlign.right,
),
backgroundColor: Colors.red,
),
);
}

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
textAlign: TextAlign.right,
),
backgroundColor: Colors.green,
),
);
}

// ============================================================
// اعداد فارسی
// ============================================================

String _persianDigits(
String value,
) {
const english = [
'0',
'1',
'2',
'3',
'4',
'5',
'6',
'7',
'8',
'9',
];

const persian = [
'۰',
'۱',
'۲',
'۳',
'۴',
'۵',
'۶',
'۷',
'۸',
'۹',
];

var result = value;

for (int i = 0;
i < english.length;
i++) {
result = result.replaceAll(
english[i],
persian[i],
);
}

return result;
}

// ============================================================
// تاریخ
// ============================================================

String _formatDateTime(
String? value,
) {
if (value == null ||
value.trim().isEmpty) {
return '';
}

try {
final date =
DateTime.parse(value).toLocal();

final jalali =
_gregorianToJalali(
date.year,
date.month,
date.day,
);

final dateText =
'${jalali[0]}/${jalali[1].toString().padLeft(2, '0')}/${jalali[2].toString().padLeft(2, '0')}';

final timeText =
'${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

return _persianDigits(
'$dateText - $timeText',
);
} catch (_) {
return value;
}
}

List<int> _gregorianToJalali(
int gy,
int gm,
int gd,
) {
const gdm = [
0,
31,
59,
90,
120,
151,
181,
212,
243,
273,
304,
334,
];

int gy2 = gy;

if (gm > 2) {
gy2++;
}

int days =
355666 +
(365 * gy) +
((gy2 + 3) ~/ 4) -
((gy2 + 99) ~/ 100) +
((gy2 + 399) ~/ 400) +
gd +
gdm[gm - 1];

int jy =
-1595 +
(33 * (days ~/ 12053));

days %= 12053;

jy +=
4 * (days ~/ 1461);

days %= 1461;

if (days > 365) {
jy +=
(days - 1) ~/ 365;

days =
(days - 1) % 365;
}

int jm;
int jd;

if (days < 186) {
jm =
1 + (days ~/ 31);

jd =
1 + (days % 31);
} else {
jm =
7 +
((days - 186) ~/ 30);

jd =
1 +
((days - 186) % 30);
}

return [
jy,
jm,
jd,
];
}

// ============================================================
// پاک کردن HTML
// ============================================================

String _cleanHtml(
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

// ============================================================
// باز کردن فایل
// ============================================================

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

// ============================================================
// نام فایل
// ============================================================

String _fileNameFromUrl(
String url,
) {
try {
final uri =
Uri.parse(url);

if (uri.pathSegments
    .isNotEmpty) {
return uri
    .pathSegments
    .last;
}
} catch (_) {}

return 'فایل پیوست';
}

// ============================================================
// نوع تصویر
// ============================================================

bool _isImageFile(
String url,
) {
final cleanUrl =
url
    .toLowerCase()
    .split('?')
    .first;

return cleanUrl.endsWith('.jpg') ||
cleanUrl.endsWith('.jpeg') ||
cleanUrl.endsWith('.png') ||
cleanUrl.endsWith('.gif') ||
cleanUrl.endsWith('.webp') ||
cleanUrl.endsWith('.bmp');
}

// ============================================================
// آیکون فایل
// ============================================================

IconData _fileIcon(
String url,
) {
final lower =
url.toLowerCase();

if (lower.endsWith('.pdf')) {
return Icons.picture_as_pdf;
}

if (lower.endsWith('.doc') ||
lower.endsWith('.docx')) {
return Icons.description;
}

if (lower.endsWith('.xls') ||
lower.endsWith('.xlsx')) {
return Icons.table_chart;
}

if (_isImageFile(url)) {
return Icons.image_outlined;
}

return Icons.insert_drive_file_outlined;
}

// ============================================================
// کارت فایل
// ============================================================

Widget _buildAttachment(
Map<String, dynamic> attachment,
) {
final url =
attachment['url']
    ?.toString() ??
'';

if (url.isEmpty) {
return const SizedBox.shrink();
}

final fileName =
_fileNameFromUrl(url);

final isImage =
_isImageFile(url);

return Container(
margin:
const EdgeInsets.only(
top: 8,
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
BorderRadius.circular(
10,
),
border: Border.all(
color:
Colors.grey.shade300,
),
),
child: Row(
children: [
Container(
width: 38,
height: 38,
decoration:
BoxDecoration(
color: isImage
? primaryColor
    .withOpacity(
0.10,
)
    : Colors.grey
    .withOpacity(
0.10,
),
borderRadius:
BorderRadius.circular(
8,
),
),
child: Icon(
_fileIcon(url),
color: isImage
? primaryColor
    : Colors.grey.shade700,
),
),
const SizedBox(
width: 10,
),
Expanded(
child: Text(
fileName,
textAlign:
TextAlign.right,
maxLines: 2,
overflow:
TextOverflow.ellipsis,
style:
const TextStyle(
fontSize: 13,
),
),
),
const SizedBox(
width: 8,
),
IconButton(
tooltip: 'مشاهده فایل',
onPressed: () {
_openFile(url);
},
icon: const Icon(
Icons.open_in_new,
),
color: primaryColor,
),
],
),
);
}

// ============================================================
// کارت پیام
// ============================================================

Widget _buildMessage(
Map<String, dynamic> message,
) {
final senderRole =
message['sender_role']
    ?.toString()
    .trim() ??
'';

final isManager =
senderRole ==
'مدیر ساختمان' ||
senderRole == 'ادمین';

final senderName =
message['sender_name']
    ?.toString()
    .trim()
    .isNotEmpty ==
true
? message['sender_name']
    .toString()
    : (isManager
? 'مدیر ساختمان'
    : 'ساکن');

final messageText =
_cleanHtml(
message['message']
    ?.toString() ??
'',
);

final createdAt =
message['created_at']
    ?.toString();

final attachments =
message['attachments'];

final List<
Map<String, dynamic>>
attachmentList = [];

if (attachments is List) {
for (final item
in attachments) {
if (item is Map) {
attachmentList.add(
Map<String, dynamic>
    .from(item),
);
}
}
}

final backgroundColor =
isManager
? primaryColor.withOpacity(
0.08,
)
    : Colors.green.withOpacity(
0.18,
);

final avatarColor =
isManager
? primaryColor
    : Colors.green;

return Container(
width: double.infinity,
margin: EdgeInsets.only(
bottom: 12,

// مدیر سمت راست
right: isManager
? 25
    : 0,

// ساکن سمت چپ
left: isManager
? 0
    : 25,
),
padding:
const EdgeInsets.all(12),
decoration: BoxDecoration(
color: backgroundColor,
borderRadius:
BorderRadius.circular(
14,
),
border: Border.all(
color: isManager
? primaryColor
    .withOpacity(
0.18,
)
    : Colors.green
    .withOpacity(
0.25,
),
),
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
CircleAvatar(
radius: 20,
backgroundColor:
avatarColor,
child: Icon(
isManager
? Icons
    .admin_panel_settings
    : Icons.person,
color: Colors.white,
size: 22,
),
),
const SizedBox(
width: 10,
),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
senderName,
textAlign:
TextAlign.right,
style:
const TextStyle(
fontWeight:
FontWeight.bold,
fontSize: 14,
),
),
const SizedBox(
height: 3,
),
Text(
isManager
? 'مدیر ساختمان'
    : 'ساکن',
textAlign:
TextAlign.right,
style: TextStyle(
fontSize: 12,
color:
avatarColor,
fontWeight:
FontWeight.w600,
),
),
],
),
),
if (createdAt != null)
Text(
_formatDateTime(
createdAt,
),
textAlign:
TextAlign.left,
style: TextStyle(
fontSize: 10,
color: Colors
    .grey
    .shade600,
),
),
],
),
if (messageText
    .isNotEmpty) ...[
const SizedBox(
height: 12,
),
Container(
width: double.infinity,
padding:
const EdgeInsets.all(
10,
),
decoration:
BoxDecoration(
color: Colors.white
    .withOpacity(
0.70,
),
borderRadius:
BorderRadius.circular(
10,
),
),
child: Text(
messageText,
textAlign:
TextAlign.right,
textDirection:
TextDirection.rtl,
style:
const TextStyle(
fontSize: 14,
height: 1.7,
),
),
),
],
if (attachmentList
    .isNotEmpty)
...attachmentList.map(
_buildAttachment,
),
],
),
);
}

// ============================================================
// اطلاعات تیکت
// ============================================================

Widget _buildTicketInfo() {
final ticket =
_ticket!;

final ticketNo =
ticket['ticket_no']
    ?.toString() ??
'-';

final subject =
ticket['subject']
    ?.toString() ??
'';

final isCall =
ticket['is_call'] == true;

return Container(
width: double.infinity,
padding:
const EdgeInsets.all(14),
decoration:
BoxDecoration(
color: Colors.white,
borderRadius:
BorderRadius.circular(
14,
),
boxShadow: [
BoxShadow(
color: Colors.black
    .withOpacity(
0.05,
),
blurRadius: 8,
offset:
const Offset(
0,
2,
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
const Icon(
Icons
    .confirmation_number_outlined,
color: primaryColor,
),
const SizedBox(
width: 8,
),
Expanded(
child: Text(
'تیکت ${_persianDigits(ticketNo)}',
textAlign:
TextAlign.right,
style:
const TextStyle(
fontWeight:
FontWeight.bold,
fontSize: 15,
),
),
),
Container(
padding:
const EdgeInsets
    .symmetric(
horizontal: 10,
vertical: 6,
),
decoration:
BoxDecoration(
color: _statusColor()
    .withOpacity(
0.12,
),
borderRadius:
BorderRadius.circular(
20,
),
),
child: Text(
_statusText(),
style:
TextStyle(
color:
_statusColor(),
fontSize: 12,
fontWeight:
FontWeight.bold,
),
),
),
],
),
if (subject.isNotEmpty) ...[
const SizedBox(
height: 12,
),
Text(
subject,
textAlign:
TextAlign.right,
style:
const TextStyle(
fontWeight:
FontWeight.bold,
fontSize: 16,
),
),
],
const SizedBox(
height: 10,
),
Text(
'تاریخ ثبت: ${_formatDateTime(ticket['created_at']?.toString())}',
textAlign:
TextAlign.right,
style: TextStyle(
fontSize: 12,
color:
Colors.grey.shade600,
),
),
if (isCall) ...[
const SizedBox(
height: 10,
),
Row(
children: const [
Icon(
Icons.phone_in_talk_outlined,
size: 19,
color: Colors.black,
),
SizedBox(
width: 6,
),
Text(
'درخواست تماس ثبت گردید',
style: TextStyle(
color: Colors.black,
fontWeight:
FontWeight.w600,
fontSize: 13,
),
),
],
),
],
],
),
);
}

// ============================================================
// دکمه بستن تیکت
// ============================================================

Widget _buildCloseButton() {
if (_isClosed()) {
return Container(
width: double.infinity,
padding:
const EdgeInsets.symmetric(
vertical: 12,
),
decoration:
BoxDecoration(
color:
Colors.red.withOpacity(
0.08,
),
borderRadius:
BorderRadius.circular(
12,
),
),
child: const Text(
'این تیکت بسته شده است.',
textAlign:
TextAlign.center,
style: TextStyle(
color: Colors.red,
fontWeight:
FontWeight.bold,
),
),
);
}

return SizedBox(
width: double.infinity,
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
minimumSize:
const Size(
0,
48,
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
),
label: const Text(
'بستن تیکت',
style: TextStyle(
fontWeight:
FontWeight.bold,
),
),
),
);
}

// ============================================================
// فایل انتخاب شده برای ارسال
// ============================================================

Widget _buildSelectedFile() {
if (_selectedFile == null) {
return const SizedBox.shrink();
}

final fileName =
_selectedFile!
    .split(
Platform
    .pathSeparator,
)
    .last;

return Container(
width: double.infinity,
margin:
const EdgeInsets.only(
bottom: 8,
),
padding:
const EdgeInsets.symmetric(
horizontal: 10,
vertical: 8,
),
decoration:
BoxDecoration(
color:
primaryColor.withOpacity(
0.08,
),
borderRadius:
BorderRadius.circular(
10,
),
),
child: Row(
children: [
const Icon(
Icons.attach_file,
color: primaryColor,
),
const SizedBox(
width: 8,
),
Expanded(
child: Text(
fileName,
textAlign:
TextAlign.right,
maxLines: 1,
overflow:
TextOverflow.ellipsis,
),
),
IconButton(
onPressed:
_removeSelectedFile,
icon: const Icon(
Icons.close,
),
),
],
),
);
}

// ============================================================
// کادر ارسال پیام
// ============================================================

Widget _buildReplyBox() {
if (_isClosed()) {
return const SizedBox.shrink();
}

return Container(
padding:
const EdgeInsets.fromLTRB(
10,
8,
10,
10,
),
decoration:
BoxDecoration(
color: Colors.white,
boxShadow: [
BoxShadow(
color: Colors.black
    .withOpacity(
0.08,
),
blurRadius: 10,
offset:
const Offset(
0,
-2,
),
),
],
),
child: Column(
children: [
_buildSelectedFile(),
Row(
crossAxisAlignment:
CrossAxisAlignment.end,
children: [
Expanded(
child: TextField(
controller:
_messageController,
enabled:
!_sending,
textDirection:
TextDirection.rtl,
textAlign:
TextAlign.right,
minLines: 1,
maxLines: 4,
decoration:
InputDecoration(
hintText:
'پیام خود را وارد کنید...',
hintTextDirection:
TextDirection.rtl,
border:
OutlineInputBorder(
borderRadius:
BorderRadius.circular(
12,
),
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
onPressed:
_sending
? null
    : _pickFile,
icon: const Icon(
Icons.attach_file,
),
color: primaryColor,
),
IconButton(
onPressed:
_sending
? null
    : _sendMessage,
icon: _sending
? const SizedBox(
width: 22,
height: 22,
child:
CircularProgressIndicator(
strokeWidth: 2,
color:
primaryColor,
),
)
    : const Icon(
Icons.send,
),
color: primaryColor,
),
],
),
],
),
);
}

// ============================================================
// صفحه
// ============================================================

@override
Widget build(
BuildContext context,
) {
return Directionality(
textDirection:
TextDirection.rtl,
child: Scaffold(
backgroundColor:
const Color(
0xffF5F7F8,
),
appBar: AppBar(
backgroundColor:
primaryColor,
foregroundColor:
Colors.white,
centerTitle: true,
title: const Text(
'جزئیات تیکت',
style:
TextStyle(
fontWeight:
FontWeight.bold,
),
),
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
child:
ElevatedButton(
onPressed:
_loadTicket,
child:
const Text(
'تلاش مجدد',
),
),
)
    : Column(
children: [
Expanded(
child:
RefreshIndicator(
color:
primaryColor,
onRefresh:
_loadTicket,
child:
ListView(
padding:
const EdgeInsets
    .all(
12,
),
children: [
// اطلاعات تیکت
_buildTicketInfo(),

const SizedBox(
height: 12,
),

// دکمه بستن
_buildCloseButton(),

const SizedBox(
height: 16,
),

// پیام‌ها
Builder(
builder:
(context) {
final messages =
_ticket![
'messages'];

if (messages
is! List ||
messages
    .isEmpty) {
return Container(
padding:
const EdgeInsets
    .all(
20,
),
decoration:
BoxDecoration(
color:
Colors.white,
borderRadius:
BorderRadius
    .circular(
12,
),
),
child:
const Text(
'هنوز پیامی ثبت نشده است.',
textAlign:
TextAlign
    .center,
),
);
}

return Column(
children:
messages
    .whereType<
Map>()
    .map(
(
item,
) =>
_buildMessage(
Map<String,
dynamic>.from(
item,
),
),
)
    .toList(),
);
},
),
],
),
),
),

// ارسال پیام
_buildReplyBox(),
],
),
),
);
}
}

