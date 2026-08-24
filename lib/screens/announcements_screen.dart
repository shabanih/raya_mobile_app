
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
// برای همین کاربر دیده‌شده ثبت می‌شوند
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
debugPrint(
'ANNOUNCEMENT ERROR: $e',
);

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
backgroundColor:
const Color(0xffF5F8FA),

// =================================================
// AppBar
// =================================================

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

// =================================================
// Body
// =================================================

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

style:
ElevatedButton.styleFrom(
backgroundColor:
const Color(0xff00ACC1),

foregroundColor:
Colors.white,

elevation: 0,

shape:
RoundedRectangleBorder(
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
color:
const Color(0xff00ACC1),

onRefresh:
loadAnnouncements,

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
color:
const Color(0xff00ACC1),

onRefresh:
loadAnnouncements,

child: ListView.builder(
physics:
const AlwaysScrollableScrollPhysics(),

padding:
const EdgeInsets.fromLTRB(
18,
20,
18,
30,
),

itemCount:
announcements.length,

itemBuilder:
(context, index) {
final announcement =
announcements[index];

// =================================================
// عنوان
// =================================================

final title =
announcement['title']
    ?.toString()
    .trim()
    .isNotEmpty ==
true
? announcement['title']
    .toString()
    .trim()
    : 'اطلاعیه ساختمان';

// =================================================
// اسناد
//
// توجه:
// documents الان List<Map<String,dynamic>> است
// =================================================

final documents =
announcement['documents']
is List
? List<
Map<String,
dynamic>
>.from(
(announcement[
'documents']
as List)
    .whereType<Map>()
    .map(
(item) =>
Map<String,
dynamic>.from(
item,
),
),
)
    : <Map<String,
dynamic>>[];

return _AnnouncementCard(
title:
toPersianDigits(title),

documents:
documents,
);
},
),
);
}
}

// =========================================================
// کارت اطلاعیه
// =========================================================

class _AnnouncementCard
extends StatelessWidget {
final String title;

final List<
Map<String, dynamic>> documents;

const _AnnouncementCard({
required this.title,
required this.documents,
});

// =======================================================
// تبدیل اعداد انگلیسی به فارسی
// =======================================================

String toPersianDigits(
String value) {
const english =
'0123456789';

const persian =
'۰۱۲۳۴۵۶۷۸۹';

for (int i = 0;
i < english.length;
i++) {
value = value.replaceAll(
english[i],
persian[i],
);
}

return value;
}

// =======================================================
// باز کردن سند
// =======================================================

Future<void> openDocument(
BuildContext context,
String url) async {
if (url.isEmpty) {
return;
}

try {
final uri =
Uri.tryParse(url);

if (uri == null) {
return;
}

final launched =
await launchUrl(
uri,
mode:
LaunchMode.externalApplication,
);

if (!launched &&
context.mounted) {
ScaffoldMessenger.of(
context,
).showSnackBar(
const SnackBar(
content: Text(
'امکان باز کردن فایل وجود ندارد.',
),
),
);
}
} catch (e) {
debugPrint(
'DOCUMENT OPEN ERROR: $e',
);

if (context.mounted) {
ScaffoldMessenger.of(
context,
).showSnackBar(
const SnackBar(
content: Text(
'خطا در باز کردن سند.',
),
),
);
}
}
}

// =======================================================
// تشخیص تصویر
// =======================================================

bool isImageFile(
String url) {
final cleanUrl =
url.toLowerCase();

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
'.webp',
) ||
cleanUrl.endsWith(
'.gif',
);
}

// =======================================================
// نام فایل
// =======================================================

String getFileName(
String url) {
try {
final uri =
Uri.parse(url);

if (uri.pathSegments.isNotEmpty) {
return uri
    .pathSegments
    .last;
}
} catch (_) {}

return 'سند';
}

// =======================================================
// آیکن نوع فایل
// =======================================================

IconData getFileIcon(
String url) {
final lower =
url.toLowerCase();

if (lower.endsWith(
'.pdf',
)) {
return Icons
    .picture_as_pdf_rounded;
}

if (lower.endsWith(
'.doc',
) ||
lower.endsWith(
'.docx',
)) {
return Icons
    .description_rounded;
}

if (lower.endsWith(
'.xls',
) ||
lower.endsWith(
'.xlsx',
)) {
return Icons
    .table_chart_rounded;
}

if (lower.endsWith(
'.zip',
) ||
lower.endsWith(
'.rar',
)) {
return Icons
    .folder_zip_rounded;
}

return Icons
    .insert_drive_file_rounded;
}

@override
Widget build(
BuildContext context) {
return Container(
margin:
const EdgeInsets.only(
bottom: 14,
),

padding:
const EdgeInsets.all(17),

decoration:
BoxDecoration(
color: Colors.white,

borderRadius:
BorderRadius.circular(
20,
),

boxShadow: [
BoxShadow(
color: Colors.black
    .withOpacity(0.05),

blurRadius: 10,

offset:
const Offset(0, 4),
),
],
),

child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .stretch,

children: [
// =================================================
// عنوان اطلاعیه
// =================================================

Row(
crossAxisAlignment:
CrossAxisAlignment
    .center,

children: [
// =============================================
// آیکن اطلاعیه
// =============================================

Container(
width: 48,
height: 48,

decoration:
BoxDecoration(
color:
const Color(
0xff00ACC1,
).withOpacity(
0.12,
),

shape:
BoxShape.circle,
),

child:
const Icon(
Icons
    .notifications_none_rounded,

color:
Color(0xff00ACC1),

size: 27,
),
),

const SizedBox(
width: 14,
),

// =============================================
// عنوان
// =============================================

Expanded(
child: Text(
title,

textAlign:
TextAlign.right,

maxLines: 3,

overflow:
TextOverflow
    .ellipsis,

style:
const TextStyle(
fontSize: 16,

fontWeight:
FontWeight
    .bold,

color:
Color(
0xff263238,
),

height: 1.7,
),
),
),
],
),

// =================================================
// اسناد
// فقط اگر سند وجود داشته باشد
// =================================================

if (documents.isNotEmpty) ...[
const SizedBox(
height: 16,
),

Container(
height: 1,

color:
const Color(
0xffECEFF1,
),
),

const SizedBox(
height: 14,
),

// ===============================================
// عنوان اسناد
// ===============================================

Row(
children: [
const Icon(
Icons
    .attach_file_rounded,

size: 21,

color:
Color(
0xff37ac51,
),
),

const SizedBox(
width: 6,
),

Text(
'اسناد',

style:
const TextStyle(
fontSize: 14,

fontWeight:
FontWeight
    .bold,

color:
Color(
0xff455A64,
),
),
),
],
),

const SizedBox(
height: 10,
),

// ===============================================
// لیست اسناد
// ===============================================

...List.generate(
documents.length,
(index) {
final document =
documents[index];

final url =
document['url']
    ?.toString() ??
'';

if (url.isEmpty) {
return const SizedBox
    .shrink();
}

final fileName =
getFileName(url);

final isImage =
isImageFile(url);

return Container(
margin:
const EdgeInsets
    .only(
bottom: 8,
),

decoration:
BoxDecoration(
color:
const Color(
0xffF7FAFB,
),

borderRadius:
BorderRadius
    .circular(
12,
),

border:
Border.all(
color:
const Color(
0xffE0E7EA,
),
),
),

child:
InkWell(
borderRadius:
BorderRadius
    .circular(
12,
),

onTap: () {
openDocument(
context,
url,
);
},

child:
Padding(
padding:
const EdgeInsets
    .all(
9,
),

child:
Row(
children: [
// =================================
// پیش‌نمایش تصویر
// =================================

if (isImage)
ClipRRect(
borderRadius:
BorderRadius
    .circular(
8,
),

child:
Image.network(
url,

width: 55,

height: 55,

fit: BoxFit
    .cover,

errorBuilder:
(
context,
error,
stackTrace,
) {
return Container(
width:
55,

height:
55,

decoration:
BoxDecoration(
color:
const Color(
0xffE0F7FA,
),

borderRadius:
BorderRadius
    .circular(
8,
),
),

child:
const Icon(
Icons
    .broken_image_outlined,

color:
Color(
0xff33a34e,
),
),
);
},
),
)
else
Container(
width:
55,

height:
55,

decoration:
BoxDecoration(
color:
const Color(
0xffE0F7FA,
),

borderRadius:
BorderRadius
    .circular(
8,
),
),

child:
Icon(
getFileIcon(
url,
),

color:
const Color(
0xff37ac51,
),

size: 29,
),
),

const SizedBox(
width: 11,
),

// =================================
// اطلاعات فایل
// =================================

Expanded(
child:
Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,

children: [
Text(
'سند ${toPersianDigits((index + 1).toString())}',

style:
const TextStyle(
fontSize:
14,

fontWeight:
FontWeight
    .bold,

color:
Color(
0xff263238,
),
),
),

const SizedBox(
height: 4,
),

Text(
fileName,

maxLines:
1,

overflow:
TextOverflow
    .ellipsis,

textDirection:
TextDirection
    .ltr,

style:
const TextStyle(
fontSize:
11,

color:
Color(
0xff78909C,
),
),
),
],
),
),

// =================================
// دکمه باز کردن
// =================================

const Icon(
Icons
    .open_in_new_rounded,

size: 20,

color:
Color(
0xff33a34e,
),
),
],
),
),
),
);
},
),
],
],
),
);
}
}

