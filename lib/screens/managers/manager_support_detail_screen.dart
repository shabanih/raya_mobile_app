
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../services/manager_support_service.dart';

class ManagerSupportDetailScreen extends StatefulWidget {
final int ticketId;

const ManagerSupportDetailScreen({
super.key,
required this.ticketId,
});

@override
State<ManagerSupportDetailScreen> createState() =>
_ManagerSupportDetailScreenState();
}

class _ManagerSupportDetailScreenState
extends State<ManagerSupportDetailScreen> {
static const Color primaryColor = Color(0xff00ACC1);

late final ManagerSupportService _supportService;

final TextEditingController _messageController =
TextEditingController();

final ImagePicker _imagePicker = ImagePicker();

Map<String, dynamic>? _ticket;

bool _loading = true;
bool _sending = false;
bool _changingStatus = false;
bool _closing = false;

String? _selectedFile;

// ------------------------------------------------------------
// حالت پاسخ
//
// وقتی تیکت در حالت is_waiting است:
//
// false = کادر پاسخ قفل است
// true  = مدیر روی «ارسال پاسخ» زده و کادر فعال است
// ------------------------------------------------------------

bool _replyMode = false;

@override
void initState() {
super.initState();

_supportService = ManagerSupportService(
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
final ticket =
await _supportService.getTicket(widget.ticketId);

if (!mounted) return;

setState(() {
_ticket = ticket;
_loading = false;

// اگر تیکت از سرور دیگر در حالت بررسی نیست،
// حالت پاسخ نیز از ابتدا فعال باشد.
if (ticket['is_waiting'] != true) {
_replyMode = false;
}
});
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

bool _isWaiting() {
return _ticket?['is_waiting'] == true;
}

bool _isAnswered() {
return _ticket?['is_answer'] == true;
}

String _statusText() {
if (_isClosed()) {
return 'بسته شده';
}

if (_isWaiting()) {
return 'در حال بررسی';
}

if (_isAnswered()) {
return 'پاسخ داده شده';
}

return 'در انتظار پاسخ';
}

Color _statusColor() {
if (_isClosed()) {
return Colors.red;
}

if (_isWaiting()) {
return Colors.orange;
}

if (_isAnswered()) {
return Colors.green;
}

return primaryColor;
}

// ============================================================
// قرار دادن تیکت در حالت بررسی
// ============================================================

Future<void> _setWaiting() async {
if (_changingStatus || _isClosed()) {
return;
}

setState(() {
_changingStatus = true;
});

try {
await _supportService.setWaiting(
widget.ticketId,
);

if (!mounted) return;

// بعد از قرار گرفتن در حالت بررسی،
// کادر پاسخ باید قفل باشد.
setState(() {
_replyMode = false;
});

await _loadTicket();
} catch (e) {
if (!mounted) return;

_showError(
_cleanException(e),
);
} finally {
if (!mounted) return;

setState(() {
_changingStatus = false;
});
}
}

// ============================================================
// فعال کردن حالت ارسال پاسخ
// ============================================================

void _setReplyMode() {
if (_isClosed()) {
return;
}

if (!_isWaiting()) {
return;
}

setState(() {
_replyMode = true;
});
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
style:
ElevatedButton.styleFrom(
backgroundColor:
Colors.red,
foregroundColor:
Colors.white,
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

_replyMode = false;

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
// انتخاب فایل
// ============================================================

Future<void> _pickFile() async {
if (_sending ||
_isClosed() ||
!_canReply()) {
return;
}

try {
final image =
await _imagePicker.pickImage(
source:
ImageSource.gallery,
imageQuality: 90,
);

if (image == null) {
return;
}

if (!mounted) return;

setState(() {
_selectedFile = image.path;
});
} catch (e) {
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
// آیا امکان ارسال پاسخ وجود دارد؟
// ============================================================

bool _canReply() {
if (_isClosed()) {
return false;
}

// اگر تیکت در حالت بررسی است،
// فقط بعد از زدن «ارسال پاسخ» اجازه ارسال داریم.
if (_isWaiting()) {
return _replyMode;
}

return true;
}

// ============================================================
// ارسال پاسخ
// ============================================================

Future<void> _sendMessage() async {
if (_sending ||
_isClosed() ||
!_canReply()) {
return;
}

final message =
_messageController.text.trim();

if (message.isEmpty &&
(_selectedFile == null ||
_selectedFile!
    .trim()
    .isEmpty)) {
_showError(
'متن پاسخ یا فایل پیوست را وارد کنید.',
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
_replyMode = false;
});

await _loadTicket();

if (!mounted) return;

_showSuccess(
'پاسخ با موفقیت ارسال شد.',
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
// پیام خطا
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
textAlign:
TextAlign.right,
),
backgroundColor:
Colors.red,
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
textAlign:
TextAlign.right,
),
backgroundColor:
Colors.green,
),
);
}

// ============================================================
// تبدیل اعداد انگلیسی به فارسی
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
// تبدیل تاریخ میلادی به شمسی
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
DateTime.parse(value)
    .toLocal();

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
// HTML ساده پیام
// ============================================================

String _cleanHtml(
String value,
) {
return value
    .replaceAll(
RegExp(
r'<br\s*/?>',
),
'\n',
)
    .replaceAll(
RegExp(
r'</p>',
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
    .trim();
}

// ============================================================
// دانلود / باز کردن فایل
// ============================================================

Future<void> _downloadFile(
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
'امکان دریافت فایل وجود ندارد.',
);
}
} catch (_) {
_showError(
'امکان دریافت فایل وجود ندارد.',
);
}
}

// ============================================================
// ساخت کارت فایل
// ============================================================

Widget _buildAttachment(
Map<String, dynamic>
attachment,
) {
final url =
attachment['url']
    ?.toString() ??
'';

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
isImage
? Icons
    .image_outlined
    : Icons
    .insert_drive_file_outlined,
color: isImage
? primaryColor
    : Colors.grey
    .shade700,
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
tooltip: 'دانلود',
onPressed:
url.isEmpty
? null
    : () {
_downloadFile(
url,
);
},
icon:
const Icon(
Icons.download,
),
color:
primaryColor,
),
],
),
);
}

String _fileNameFromUrl(
String url,
) {
try {
final uri =
Uri.parse(url);

if (uri.pathSegments
    .isNotEmpty) {
return uri
    .pathSegments.last;
}
} catch (_) {}

return 'فایل پیوست';
}

bool _isImageFile(
String url,
) {
final cleanUrl =
url
    .toLowerCase()
    .split('?')
    .first;

return cleanUrl.endsWith(
'.jpg',
) ||
cleanUrl.endsWith(
'.jpeg',
) ||
cleanUrl.endsWith(
'.png',
) ||
cleanUrl.endsWith(
'.gif',
) ||
cleanUrl.endsWith(
'.webp',
) ||
cleanUrl.endsWith(
'.bmp',
);
}

// ============================================================
// کارت پیام
// ============================================================

Widget _buildMessage(
Map<String, dynamic>
message,
) {

final senderRole =
message['sender_role']
    ?.toString()
    .trim() ??
'';

final isManager =
senderRole == 'مدیر ساختمان';

final senderName =
message['sender_name']
    ?.toString()
    .trim()
    .isNotEmpty ==
true
? message[
'sender_name']
    .toString()
    : (isManager
? 'مدیر ساختمان'
    : 'ساکن');

final rawMessage =
message['message']
    ?.toString() ??
'';

final messageText =
_cleanHtml(
rawMessage,
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
Map<String, dynamic>.from(
item,
),
);
}
}
}

// ----------------------------------------------------------
// رنگ کارت
// ----------------------------------------------------------

final backgroundColor =
isManager
? primaryColor
    .withOpacity(
0.08,
)
    : Colors.green
    .withOpacity(
0.18,
);

final avatarColor =
isManager
? primaryColor
    : Colors.green;

return Container(
width:
double.infinity,
margin: EdgeInsets.only(
bottom: 12,

// مدیر از راست فاصله دارد
right:
isManager ? 25 : 0,

// ساکن از چپ فاصله دارد
left:
isManager ? 0 : 25,
),
padding:
const EdgeInsets.all(
12,
),
decoration:
BoxDecoration(
color:
backgroundColor,
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
color:
Colors.white,
size: 22,
),
),
const SizedBox(
width: 10,
),
Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,
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
style:
TextStyle(
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
if (createdAt !=
null)
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
width:
double.infinity,
padding:
const EdgeInsets.all(
10,
),
decoration:
BoxDecoration(
color: Colors
    .white
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

final userName =
ticket['user_name']
    ?.toString() ??
'';

final userMobile =
ticket['user_mobile']
    ?.toString() ??
'';

return Container(
width:
double.infinity,
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
color:
primaryColor,
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
color:
_statusColor()
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

if (subject
    .isNotEmpty) ...[
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

if (userName
    .isNotEmpty) ...[
const SizedBox(
height: 12,
),
Row(
children: [
const Icon(
Icons
    .person_outline,
size: 19,
color:
Colors.grey,
),
const SizedBox(
width: 6,
),
Expanded(
child: Text(
userName,
textAlign:
TextAlign.right,
style:
const TextStyle(
fontSize: 13,
),
),
),
],
),
],

if (userMobile
    .isNotEmpty) ...[
const SizedBox(
height: 6,
),
Row(
children: [
const Icon(
Icons
    .phone_outlined,
size: 19,
color:
Colors.grey,
),
const SizedBox(
width: 6,
),
Expanded(
child: Text(
_persianDigits(
userMobile,
),
textAlign:
TextAlign.right,
style:
const TextStyle(
fontSize: 13,
),
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
// دکمه‌های وضعیت
// ============================================================

Widget _buildActionButtons() {
if (_isClosed()) {
return Container(
width:
double.infinity,
padding:
const EdgeInsets
    .symmetric(
vertical: 12,
),
decoration:
BoxDecoration(
color:
Colors.red
    .withOpacity(
0.08,
),
borderRadius:
BorderRadius.circular(
12,
),
),
child:
const Text(
'این تیکت بسته شده است.',
textAlign:
TextAlign.center,
style:
TextStyle(
color:
Colors.red,
fontWeight:
FontWeight.bold,
),
),
);
}

return Row(
children: [
// ------------------------------------------------------
// دکمه در حال بررسی / ارسال پاسخ
// ------------------------------------------------------

Expanded(
child:
ElevatedButton.icon(
onPressed:
_changingStatus ||
_closing
? null
    : (_isWaiting()
? _setReplyMode
    : _setWaiting),
style:
ElevatedButton
    .styleFrom(
backgroundColor:
_isWaiting()
? primaryColor
    : Colors.orange,
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
BorderRadius
    .circular(
10,
),
),
),
icon:
_changingStatus
? const SizedBox(
width: 18,
height: 18,
child:
CircularProgressIndicator(
strokeWidth:
2,
color:
Colors.white,
),
)
    : Icon(
_isWaiting()
? Icons.reply
    : Icons.search,
),
label:
Text(
_isWaiting()
? 'ارسال پاسخ'
    : 'در حال بررسی',
style:
const TextStyle(
fontWeight:
FontWeight.bold,
),
),
),
),

const SizedBox(
width: 10,
),

// ------------------------------------------------------
// بستن تیکت
// ------------------------------------------------------

Expanded(
child:
ElevatedButton.icon(
onPressed:
_closing ||
_changingStatus
? null
    : _closeTicket,
style:
ElevatedButton
    .styleFrom(
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
BorderRadius
    .circular(
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
strokeWidth:
2,
color:
Colors.white,
),
)
    : const Icon(
Icons.close,
),
label:
const Text(
'بستن تیکت',
style:
TextStyle(
fontWeight:
FontWeight.bold,
),
),
),
),
],
);
}

// ============================================================
// ورودی پاسخ
// ============================================================

Widget _buildReplyBox() {
final locked =
!_canReply();

return Container(
padding:
const EdgeInsets.all(
10,
),
decoration:
BoxDecoration(
color:
Colors.white,
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
child:
Column(
children: [
// ----------------------------------------------------
// فایل انتخاب شده
// ----------------------------------------------------

if (_selectedFile !=
null) ...[
Container(
width:
double.infinity,
margin:
const EdgeInsets
    .only(
bottom: 8,
),
padding:
const EdgeInsets
    .symmetric(
horizontal: 10,
vertical: 8,
),
decoration:
BoxDecoration(
color:
primaryColor
    .withOpacity(
0.08,
),
borderRadius:
BorderRadius
    .circular(
10,
),
),
child:
Row(
children: [
const Icon(
Icons.attach_file,
color:
primaryColor,
),
const SizedBox(
width: 8,
),
Expanded(
child:
Text(
_selectedFile!
    .split(
Platform
    .pathSeparator,
)
    .last,
textAlign:
TextAlign
    .right,
maxLines: 1,
overflow:
TextOverflow
    .ellipsis,
),
),
IconButton(
onPressed:
_removeSelectedFile,
icon:
const Icon(
Icons.close,
),
),
],
),
),
],

// ----------------------------------------------------
// ورودی متن
// ----------------------------------------------------

Row(
crossAxisAlignment:
CrossAxisAlignment.end,
children: [
Expanded(
child:
TextField(
controller:
_messageController,
enabled:
!locked &&
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
locked
? (_isClosed()
? 'این تیکت بسته شده است.'
    : 'برای ارسال پاسخ، ابتدا روی «ارسال پاسخ» بزنید.')
    : 'متن پاسخ را وارد کنید...',
hintTextDirection:
TextDirection
    .rtl,
border:
OutlineInputBorder(
borderRadius:
BorderRadius
    .circular(
12,
),
),
contentPadding:
const EdgeInsets
    .symmetric(
horizontal:
12,
vertical: 10,
),
),
),
),

const SizedBox(
width: 6,
),

// ------------------------------------------------
// پیوست
// ------------------------------------------------

IconButton(
onPressed:
locked ||
_sending
? null
    : _pickFile,
icon:
const Icon(
Icons.attach_file,
),
color:
primaryColor,
),

// ------------------------------------------------
// ارسال
// ------------------------------------------------

IconButton(
onPressed:
locked ||
_sending
? null
    : _sendMessage,
icon: _sending
? const SizedBox(
width: 22,
height: 22,
child:
CircularProgressIndicator(
strokeWidth:
2,
color:
primaryColor,
),
)
    : const Icon(
Icons.send,
),
color:
primaryColor,
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
child:
Scaffold(
backgroundColor:
const Color(
0xffF5F7F8,
),
appBar:
AppBar(
backgroundColor:
primaryColor,
foregroundColor:
Colors.white,
centerTitle:
true,
title:
const Text(
'جزئیات تیکت',
style:
TextStyle(
fontWeight:
FontWeight.bold,
),
),
),
body:
_loading
? const Center(
child:
CircularProgressIndicator(
color:
primaryColor,
),
)
    : _ticket ==
null
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

// دکمه‌ها
_buildActionButtons(),

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
const EdgeInsets.all(
20,
),
decoration:
BoxDecoration(
color:
Colors.white,
borderRadius:
BorderRadius.circular(
12,
),
),
child:
const Text(
'هنوز پیامی ثبت نشده است.',
textAlign:
TextAlign.center,
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

// کادر پاسخ
_buildReplyBox(),
],
),
),
);
}
}
