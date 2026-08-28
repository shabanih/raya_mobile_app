
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/manager_announcement_service.dart';

class ManagerAnnouncementsScreen extends StatefulWidget {
const ManagerAnnouncementsScreen({
super.key,
});

@override
State<ManagerAnnouncementsScreen> createState() =>
_ManagerAnnouncementsScreenState();
}

class _ManagerAnnouncementsScreenState
extends State<ManagerAnnouncementsScreen> {
bool isLoading = true;
bool isRefreshing = false;

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
if (!mounted) return;

setState(() {
isLoading = true;
});

try {
final result =
await ManagerAnnouncementService.getAnnouncements();

if (!mounted) return;

setState(() {
announcements = result;
isLoading = false;
});
} catch (e) {
if (!mounted) return;

setState(() {
isLoading = false;
});

_showError(_cleanError(e));
}
}

// =====================================================
// Refresh
// =====================================================

Future<void> refreshAnnouncements() async {
if (mounted) {
setState(() {
isRefreshing = true;
});
}

try {
final result =
await ManagerAnnouncementService.getAnnouncements();

if (!mounted) return;

setState(() {
announcements = result;
});
} catch (e) {
if (mounted) {
_showError(_cleanError(e));
}
} finally {
if (mounted) {
setState(() {
isRefreshing = false;
});
}
}
}

// =====================================================
// ایجاد
// =====================================================

Future<void> createAnnouncement() async {
final result = await Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
const ManagerAnnouncementFormScreen(),
),
);

if (result == true) {
await loadAnnouncements();
}
}

// =====================================================
// ویرایش
// =====================================================

Future<void> editAnnouncement(
Map<String, dynamic> announcement,
) async {
final result = await Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
ManagerAnnouncementFormScreen(
announcement: announcement,
),
),
);

if (result == true) {
await loadAnnouncements();
}
}

// =====================================================
// حذف
// =====================================================

Future<void> deleteAnnouncement(
Map<String, dynamic> announcement,
) async {
final id = int.tryParse(
announcement['id']?.toString() ?? '',
);

if (id == null) return;

final confirmed = await showDialog<bool>(
context: context,
builder: (context) {
return AlertDialog(
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(18),
),
title: const Text(
'حذف اطلاعیه',
textAlign: TextAlign.right,
),
content: const Text(
'آیا از حذف این اطلاعیه مطمئن هستید؟',
textAlign: TextAlign.right,
),
actionsAlignment:
MainAxisAlignment.spaceBetween,
actions: [
TextButton(
onPressed: () {
Navigator.pop(context, false);
},
child: const Text('انصراف'),
),
ElevatedButton(
style: ElevatedButton.styleFrom(
backgroundColor: Colors.red,
foregroundColor: Colors.white,
),
onPressed: () {
Navigator.pop(context, true);
},
child: const Text('حذف'),
),
],
);
},
);

if (confirmed != true) return;

try {
_showLoading();

await ManagerAnnouncementService
    .deleteAnnouncement(id);

if (!mounted) return;

Navigator.pop(context);

setState(() {
announcements.removeWhere(
(item) =>
item['id'].toString() == id.toString(),
);
});

_showSuccess(
'اطلاعیه با موفقیت حذف شد.',
);
} catch (e) {
if (!mounted) return;

Navigator.pop(context);

_showError(_cleanError(e));
}
}

// =====================================================
// فعال / غیرفعال
// =====================================================

Future<void> toggleAnnouncementStatus(
Map<String, dynamic> announcement,
) async {
final id = int.tryParse(
announcement['id']?.toString() ?? '',
);

if (id == null) return;

final currentStatus =
announcement['is_active'] == true;

final title =
announcement['title']?.toString() ?? '';

final showInMarquee =
announcement['show_in_marquee'] == true;

try {
_showLoading();

await ManagerAnnouncementService.changeStatus(
id: id,
isActive: !currentStatus,
title: title,
showInMarquee: showInMarquee,
);

if (!mounted) return;

Navigator.pop(context);

setState(() {
announcement['is_active'] =
!currentStatus;
});

_showSuccess(
!currentStatus
? 'اطلاعیه فعال شد.'
    : 'اطلاعیه غیرفعال شد.',
);
} catch (e) {
if (!mounted) return;

Navigator.pop(context);

_showError(_cleanError(e));
}
}

// =====================================================
// نمایش Loading
// =====================================================

void _showLoading() {
showDialog(
context: context,
barrierDismissible: false,
builder: (_) {
return const Center(
child: CircularProgressIndicator(
color: Color(0xff00ACC1),
),
);
},
);
}

// =====================================================
// پیام موفقیت
// =====================================================

void _showSuccess(String message) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
message,
textAlign: TextAlign.right,
),
backgroundColor: Colors.green,
behavior: SnackBarBehavior.floating,
),
);
}

// =====================================================
// پیام خطا
// =====================================================

void _showError(String message) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
message,
textAlign: TextAlign.right,
),
backgroundColor: Colors.red,
behavior: SnackBarBehavior.floating,
),
);
}

String _cleanError(Object error) {
final text = error.toString();

if (text.startsWith('Exception: ')) {
return text.substring(11);
}

return text;
}

// =====================================================
// تعداد فایل‌ها
// =====================================================

int _documentCount(
Map<String, dynamic> announcement,
) {
final documents =
announcement['documents'];

if (documents is List) {
return documents.length;
}

return 0;
}

// =====================================================
// تاریخ
// =====================================================

String _formatDate(String? value) {
if (value == null || value.isEmpty) {
return '';
}

try {
final date =
DateTime.parse(value).toLocal();

final year = date.year
    .toString()
    .padLeft(4, '0');

final month = date.month
    .toString()
    .padLeft(2, '0');

final day = date.day
    .toString()
    .padLeft(2, '0');

return '$year/$month/$day';
} catch (_) {
return value;
}
}

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
backgroundColor:
const Color(0xffF5F7FA),
appBar: AppBar(
elevation: 0,
backgroundColor: Colors.white,
foregroundColor:
const Color(0xff263238),
centerTitle: true,
title: const Text(
'مدیریت اطلاعیه‌ها',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.bold,
),
),
),
floatingActionButton:
FloatingActionButton.extended(
backgroundColor:
const Color(0xff00ACC1),
foregroundColor: Colors.white,
onPressed: createAnnouncement,
icon: const Icon(
Icons.add_rounded,
),
label: const Text(
'ایجاد اطلاعیه',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
),
body: isLoading
? const Center(
child:
CircularProgressIndicator(
color: Color(0xff00ACC1),
),
)
    : RefreshIndicator(
color:
const Color(0xff00ACC1),
onRefresh:
refreshAnnouncements,
child: announcements.isEmpty
? ListView(
physics:
const AlwaysScrollableScrollPhysics(),
children: [
SizedBox(
height:
MediaQuery.of(context)
    .size
    .height *
0.28,
),
Icon(
Icons
    .campaign_outlined,
size: 70,
color:
Colors.grey.shade400,
),
const SizedBox(
height: 16,
),
Text(
'هنوز اطلاعیه‌ای ثبت نشده است.',
textAlign:
TextAlign.center,
style: TextStyle(
color: Colors
    .grey
    .shade600,
fontSize: 15,
),
),
const SizedBox(
height: 8,
),
Text(
'برای ایجاد اطلاعیه روی دکمه پایین صفحه بزنید.',
textAlign:
TextAlign.center,
style: TextStyle(
color: Colors
    .grey
    .shade500,
fontSize: 13,
),
),
],
)
    : ListView.builder(
padding:
const EdgeInsets
    .fromLTRB(
12,
14,
12,
100,
),
itemCount:
announcements.length,
itemBuilder:
(context, index) {
return
_buildAnnouncementCard(
announcements[index],
);
},
),
),
),
);
}

// =====================================================
// کارت اطلاعیه
// =====================================================

Widget _buildAnnouncementCard(
Map<String, dynamic> announcement,
) {
final isActive =
announcement['is_active'] == true;

final showInMarquee =
announcement['show_in_marquee'] == true;

final title =
announcement['title']?.toString() ?? '';

final date = _formatDate(
announcement['created_at']?.toString(),
);

final documentsCount =
_documentCount(announcement);

return Container(
margin:
const EdgeInsets.only(bottom: 12),
decoration: BoxDecoration(
color: Colors.white,
borderRadius:
BorderRadius.circular(18),
boxShadow: [
BoxShadow(
color:
Colors.black.withOpacity(0.05),
blurRadius: 12,
offset: const Offset(0, 4),
),
],
),
child: Padding(
padding:
const EdgeInsets.all(15),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
width: 44,
height: 44,
decoration: BoxDecoration(
color:
const Color(0xff00ACC1)
    .withOpacity(0.10),
borderRadius:
BorderRadius.circular(13),
),
child: const Icon(
Icons.campaign_outlined,
color:
Color(0xff00ACC1),
),
),
const SizedBox(width: 11),
Expanded(
child: Text(
title.isEmpty
? 'بدون متن'
    : title,
maxLines: 2,
overflow:
TextOverflow.ellipsis,
style:
const TextStyle(
fontSize: 15,
fontWeight:
FontWeight.bold,
color:
Color(0xff263238),
height: 1.6,
),
),
),
PopupMenuButton<String>(
onSelected: (value) {
if (value == 'edit') {
editAnnouncement(
announcement,
);
} else if (value ==
'delete') {
deleteAnnouncement(
announcement,
);
} else if (value ==
'status') {
toggleAnnouncementStatus(
announcement,
);
}
},
itemBuilder: (_) => [
const PopupMenuItem(
value: 'edit',
child: Row(
children: [
Icon(
Icons.edit_outlined,
size: 20,
),
SizedBox(width: 8),
Text('ویرایش'),
],
),
),
PopupMenuItem(
value: 'status',
child: Row(
children: [
Icon(
isActive
? Icons
    .visibility_off_outlined
    : Icons
    .visibility_outlined,
size: 20,
),
const SizedBox(
width: 8,
),
Text(
isActive
? 'غیرفعال کردن'
    : 'فعال کردن',
),
],
),
),
const PopupMenuItem(
value: 'delete',
child: Row(
children: [
Icon(
Icons
    .delete_outline,
color: Colors.red,
size: 20,
),
SizedBox(width: 8),
Text(
'حذف',
style: TextStyle(
color:
Colors.red,
),
),
],
),
),
],
),
],
),
const SizedBox(height: 13),
Wrap(
spacing: 7,
runSpacing: 7,
children: [
_buildInfoChip(
icon: Icons
    .calendar_today_outlined,
text: date,
),
_buildStatusChip(
isActive,
),
if (showInMarquee)
_buildInfoChip(
icon: Icons
    .view_headline_rounded,
text:
'نمایش در نوار اطلاعیه',
),
if (documentsCount > 0)
_buildInfoChip(
icon: Icons
    .attach_file_rounded,
text:
'$documentsCount فایل',
),
],
),
const SizedBox(height: 14),
Row(
children: [
Expanded(
child:
OutlinedButton.icon(
onPressed: () {
editAnnouncement(
announcement,
);
},
style: OutlinedButton
    .styleFrom(
foregroundColor:
const Color(
0xff00ACC1),
side: const BorderSide(
color:
Color(0xff00ACC1),
),
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius
    .circular(12),
),
),
icon: const Icon(
Icons.edit_outlined,
size: 18,
),
label:
const Text('ویرایش'),
),
),
const SizedBox(width: 8),
Expanded(
child:
OutlinedButton.icon(
onPressed: () {
deleteAnnouncement(
announcement,
);
},
style: OutlinedButton
    .styleFrom(
foregroundColor:
Colors.red,
side: const BorderSide(
color: Colors.red,
),
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius
    .circular(12),
),
),
icon: const Icon(
Icons.delete_outline,
size: 18,
),
label:
const Text('حذف'),
),
),
],
),
],
),
),
);
}

Widget _buildStatusChip(
bool isActive,
) {
return Container(
padding:
const EdgeInsets.symmetric(
horizontal: 10,
vertical: 6,
),
decoration: BoxDecoration(
color: isActive
? Colors.green
    .withOpacity(0.10)
    : Colors.red
    .withOpacity(0.10),
borderRadius:
BorderRadius.circular(20),
),
child: Row(
mainAxisSize:
MainAxisSize.min,
children: [
Icon(
isActive
? Icons
    .check_circle_outline
    : Icons.cancel_outlined,
size: 15,
color: isActive
? Colors.green
    : Colors.red,
),
const SizedBox(width: 5),
Text(
isActive ? 'فعال' : 'غیرفعال',
style: TextStyle(
fontSize: 12,
fontWeight:
FontWeight.bold,
color: isActive
? Colors.green
    : Colors.red,
),
),
],
),
);
}

Widget _buildInfoChip({
required IconData icon,
required String text,
}) {
return Container(
padding:
const EdgeInsets.symmetric(
horizontal: 10,
vertical: 6,
),
decoration: BoxDecoration(
color:
const Color(0xffF1F4F6),
borderRadius:
BorderRadius.circular(20),
),
child: Row(
mainAxisSize:
MainAxisSize.min,
children: [
Icon(
icon,
size: 15,
color:
const Color(0xff607D8B),
),
const SizedBox(width: 5),
Text(
text,
style: const TextStyle(
fontSize: 12,
color:
Color(0xff546E7A),
),
),
],
),
);
}
}

// =======================================================
// فرم ایجاد / ویرایش اطلاعیه
// =======================================================

class ManagerAnnouncementFormScreen
extends StatefulWidget {
final Map<String, dynamic>? announcement;

const ManagerAnnouncementFormScreen({
super.key,
this.announcement,
});

bool get isEdit =>
announcement != null;

@override
State<ManagerAnnouncementFormScreen>
createState() =>
_ManagerAnnouncementFormScreenState();
}

class _ManagerAnnouncementFormScreenState
extends State<
ManagerAnnouncementFormScreen> {
final TextEditingController
titleController =
TextEditingController();

final FocusNode titleFocusNode =
FocusNode();

final ImagePicker _imagePicker =
ImagePicker();

bool showInMarquee = false;
bool isActive = true;
bool isSaving = false;

List<File> selectedFiles = [];

List<Map<String, dynamic>>
existingDocuments = [];

@override
void initState() {
super.initState();

if (widget.announcement != null) {
final data =
widget.announcement!;

titleController.text =
data['title']?.toString() ?? '';

showInMarquee =
data['show_in_marquee'] ==
true;

isActive =
data['is_active'] != false;

final documents =
data['documents'];

if (documents is List) {
existingDocuments =
documents
    .whereType<Map>()
    .map(
(item) =>
Map<String, dynamic>
    .from(item),
)
    .toList();
}
}
}

@override
void dispose() {
titleController.dispose();
titleFocusNode.dispose();
super.dispose();
}

// =====================================================
// انتخاب تصاویر
// =====================================================

Future<void> pickFiles() async {
try {
final List<XFile> pickedImages =
await _imagePicker.pickMultiImage(
imageQuality: 85,
);

if (pickedImages.isEmpty) {
return;
}

if (!mounted) return;

setState(() {
selectedFiles.addAll(
pickedImages.map(
(image) => File(image.path),
),
);
});
} catch (e) {
if (!mounted) return;

_showError(
'انتخاب تصاویر انجام نشد.',
);
}
}

// =====================================================
// حذف تصویر انتخاب شده
// =====================================================

void removeSelectedFile(
int index,
) {
if (index < 0 ||
index >= selectedFiles.length) {
return;
}

setState(() {
selectedFiles.removeAt(index);
});
}

// =====================================================
// ثبت
// =====================================================

Future<void> saveAnnouncement() async {
final title =
titleController.text.trim();

if (title.isEmpty) {
_showError(
'متن اطلاعیه را وارد کنید.',
);

titleFocusNode.requestFocus();

return;
}

if (isSaving) return;

setState(() {
isSaving = true;
});

try {
if (widget.isEdit) {
final id = int.tryParse(
widget.announcement!['id']
    ?.toString() ??
'',
);

if (id == null) {
throw Exception(
'شناسه اطلاعیه نامعتبر است.',
);
}

await ManagerAnnouncementService
    .updateAnnouncement(
id: id,
title: title,
showInMarquee:
showInMarquee,
isActive: isActive,
files: selectedFiles,
);
} else {
await ManagerAnnouncementService
    .createAnnouncement(
title: title,
showInMarquee:
showInMarquee,
files: selectedFiles,
);
}

if (!mounted) return;

Navigator.pop(context, true);
} catch (e) {
if (!mounted) return;

_showError(
_cleanError(e),
);
} finally {
if (mounted) {
setState(() {
isSaving = false;
});
}
}
}

String _cleanError(Object error) {
final text = error.toString();

if (text.startsWith(
'Exception: ',
)) {
return text.substring(11);
}

return text;
}

void _showError(
String message,
) {
ScaffoldMessenger.of(context)
    .showSnackBar(
SnackBar(
content: Text(
message,
textAlign:
TextAlign.right,
),
backgroundColor:
Colors.red,
behavior:
SnackBarBehavior.floating,
),
);
}

// =====================================================
// نام تصویر
// =====================================================

String _fileName(File file) {
final path = file.path;

final index = path.lastIndexOf(
Platform.pathSeparator,
);

if (index == -1) {
return path;
}

return path.substring(
index + 1,
);
}

// =====================================================
// ساخت فرم
// =====================================================

@override
Widget build(
BuildContext context,
) {
final isEdit =
widget.isEdit;

return Directionality(
textDirection:
TextDirection.rtl,
child: Scaffold(
backgroundColor:
const Color(0xffF5F7FA),
appBar: AppBar(
elevation: 0,
backgroundColor:
Colors.white,
foregroundColor:
const Color(0xff263238),
centerTitle: true,
title: Text(
isEdit
? 'ویرایش اطلاعیه'
    : 'ایجاد اطلاعیه',
style:
const TextStyle(
fontSize: 17,
fontWeight:
FontWeight.bold,
),
),
),
body: SafeArea(
child:
SingleChildScrollView(
padding:
const EdgeInsets.fromLTRB(
16,
18,
16,
30,
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,
children: [
// =========================================
// متن اطلاعیه
// =========================================

_buildSectionTitle(
'متن اطلاعیه',
Icons.campaign_outlined,
),

const SizedBox(
height: 10,
),

Container(
decoration:
BoxDecoration(
color:
Colors.white,
borderRadius:
BorderRadius
    .circular(
16,
),
boxShadow: [
BoxShadow(
color: Colors
    .black
    .withOpacity(
0.04,
),
blurRadius: 10,
offset:
const Offset(
0,
3,
),
),
],
),
child: TextField(
controller:
titleController,
focusNode:
titleFocusNode,
minLines: 6,
maxLines: 12,
textAlign:
TextAlign.right,
textDirection:
TextDirection.rtl,
decoration:
const InputDecoration(
hintText:
'متن اطلاعیه را وارد کنید...',
hintStyle:
TextStyle(
color:
Color(
0xff9E9E9E,
),
fontSize: 14,
),
border:
InputBorder.none,
contentPadding:
EdgeInsets.all(
16,
),
),
),
),

const SizedBox(
height: 18,
),

// =========================================
// نوار اطلاعیه
// =========================================

Container(
decoration:
BoxDecoration(
color:
Colors.white,
borderRadius:
BorderRadius
    .circular(
16,
),
),
child:
SwitchListTile(
contentPadding:
const EdgeInsets
    .symmetric(
horizontal: 12,
vertical: 2,
),
value:
showInMarquee,
activeColor:
const Color(
0xff00ACC1),
title:
const Text(
'نمایش در نوار اطلاعیه',
style:
TextStyle(
fontSize: 14,
fontWeight:
FontWeight
    .bold,
),
),
subtitle:
const Text(
'اطلاعیه در نوار اطلاعیه ساختمان نمایش داده شود.',
style:
TextStyle(
fontSize: 12,
color:
Color(
0xff78909C,
),
),
),
secondary:
Container(
width: 40,
height: 40,
decoration:
BoxDecoration(
color:
const Color(
0xff00ACC1,
).withOpacity(
0.10,
),
borderRadius:
BorderRadius
    .circular(
12,
),
),
child:
const Icon(
Icons
    .view_headline_rounded,
color:
Color(
0xff00ACC1,
),
),
),
onChanged:
(value) {
setState(() {
showInMarquee =
value;
});
},
),
),

if (isEdit) ...[
const SizedBox(
height: 10,
),
Container(
decoration:
BoxDecoration(
color:
Colors.white,
borderRadius:
BorderRadius
    .circular(
16,
),
),
child:
SwitchListTile(
contentPadding:
const EdgeInsets
    .symmetric(
horizontal: 12,
vertical: 2,
),
value:
isActive,
activeColor:
Colors.green,
title:
const Text(
'فعال بودن اطلاعیه',
style:
TextStyle(
fontSize: 14,
fontWeight:
FontWeight
    .bold,
),
),
subtitle:
const Text(
'اطلاعیه‌های غیرفعال برای ساکنین نمایش داده نمی‌شوند.',
style:
TextStyle(
fontSize: 12,
color:
Color(
0xff78909C,
),
),
),
secondary:
Icon(
isActive
? Icons
    .check_circle_outline
    : Icons
    .cancel_outlined,
color:
isActive
? Colors.green
    : Colors.red,
),
onChanged:
(value) {
setState(() {
isActive =
value;
});
},
),
),
],

const SizedBox(
height: 20,
),

// =========================================
// تصاویر
// =========================================

_buildSectionTitle(
'تصاویر اطلاعیه',
Icons
    .attach_file_rounded,
),

const SizedBox(
height: 10,
),

InkWell(
onTap: pickFiles,
borderRadius:
BorderRadius
    .circular(
16,
),
child:
Container(
width:
double.infinity,
padding:
const EdgeInsets
    .symmetric(
vertical: 20,
horizontal: 15,
),
decoration:
BoxDecoration(
color:
Colors.white,
borderRadius:
BorderRadius
    .circular(
16,
),
border:
Border.all(
color:
const Color(
0xff00ACC1,
).withOpacity(
0.30,
),
),
),
child:
const Column(
children: [
Icon(
Icons
    .add_photo_alternate_outlined,
size: 38,
color:
Color(
0xff00ACC1,
),
),
SizedBox(
height: 8,
),
Text(
'انتخاب تصاویر',
style:
TextStyle(
fontSize: 14,
fontWeight:
FontWeight
    .bold,
color:
Color(
0xff263238,
),
),
),
SizedBox(
height: 4,
),
Text(
'امکان انتخاب چند تصویر وجود دارد',
style:
TextStyle(
fontSize: 12,
color:
Color(
0xff78909C,
),
),
),
],
),
),
),

// =========================================
// تصاویر قبلی
// =========================================

if (existingDocuments
    .isNotEmpty) ...[
const SizedBox(
height: 15,
),
const Text(
'تصاویر قبلی',
style:
TextStyle(
fontSize: 13,
fontWeight:
FontWeight
    .bold,
color:
Color(
0xff455A64,
),
),
),
const SizedBox(
height: 8,
),
...existingDocuments
    .map(
(document) {
final url =
document[
'url']
    ?.toString() ??
'';

return Container(
margin:
const EdgeInsets
    .only(
bottom: 8,
),
padding:
const EdgeInsets
    .all(
10,
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
child: Row(
children: [
ClipRRect(
borderRadius:
BorderRadius
    .circular(
8,
),
child:
url.isNotEmpty
? Image.network(
url,
width:
55,
height:
55,
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
color:
const Color(
0xffECEFF1,
),
child:
const Icon(
Icons
    .image_not_supported_outlined,
),
);
},
)
    : Container(
width:
55,
height:
55,
color:
const Color(
0xffECEFF1,
),
child:
const Icon(
Icons
    .image_outlined,
),
),
),
const SizedBox(
width: 10,
),
const Expanded(
child: Text(
'تصویر ثبت شده',
style:
TextStyle(
fontSize:
13,
),
),
),
],
),
);
},
),
],

// =========================================
// تصاویر جدید
// =========================================

if (selectedFiles
    .isNotEmpty) ...[
const SizedBox(
height: 15,
),
const Text(
'تصاویر جدید',
style:
TextStyle(
fontSize: 13,
fontWeight:
FontWeight
    .bold,
color:
Color(
0xff455A64,
),
),
),
const SizedBox(
height: 8,
),
...List.generate(
selectedFiles.length,
(index) {
final file =
selectedFiles[
index];

return Container(
margin:
const EdgeInsets
    .only(
bottom: 8,
),
padding:
const EdgeInsets
    .all(
10,
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
child: Row(
children: [
ClipRRect(
borderRadius:
BorderRadius
    .circular(
8,
),
child:
Image.file(
file,
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
color:
const Color(
0xffECEFF1,
),
child:
const Icon(
Icons
    .image_not_supported_outlined,
),
);
},
),
),
const SizedBox(
width: 10,
),
Expanded(
child: Text(
_fileName(
file,
),
maxLines:
2,
overflow:
TextOverflow
    .ellipsis,
style:
const TextStyle(
fontSize:
12,
color:
Color(
0xff455A64,
),
),
),
),
IconButton(
onPressed:
() {
removeSelectedFile(
index,
);
},
icon:
const Icon(
Icons
    .close_rounded,
color:
Colors.red,
),
),
],
),
);
},
),
],

const SizedBox(
height: 28,
),

// =========================================
// دکمه ثبت
// =========================================

SizedBox(
width:
double.infinity,
height: 52,
child:
ElevatedButton.icon(
onPressed:
isSaving
? null
    : saveAnnouncement,
style:
ElevatedButton
    .styleFrom(
backgroundColor:
const Color(
0xff00ACC1,
),
foregroundColor:
Colors.white,
disabledBackgroundColor:
const Color(
0xffB0BEC5,
),
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius
    .circular(
15,
),
),
),
icon: isSaving
? const SizedBox(
width: 20,
height: 20,
child:
CircularProgressIndicator(
strokeWidth:
2,
color:
Colors.white,
),
)
    : Icon(
isEdit
? Icons
    .save_outlined
    : Icons
    .add_rounded,
),
label: Text(
isSaving
? 'در حال ثبت...'
    : isEdit
? 'ذخیره تغییرات'
    : 'ثبت اطلاعیه',
style:
const TextStyle(
fontSize: 15,
fontWeight:
FontWeight
    .bold,
),
),
),
),
],
),
),
),
),
);
}

Widget _buildSectionTitle(
String title,
IconData icon,
) {
return Row(
children: [
Icon(
icon,
size: 20,
color:
const Color(0xff00ACC1),
),
const SizedBox(width: 7),
Text(
title,
style:
const TextStyle(
fontSize: 14,
fontWeight:
FontWeight.bold,
color:
Color(0xff37474F),
),
),
],
);
}
}

