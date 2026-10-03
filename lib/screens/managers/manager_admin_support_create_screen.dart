
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import '../../services/manager_admin_support_service.dart';

class ManagerAdminSupportCreateScreen extends StatefulWidget {
const ManagerAdminSupportCreateScreen({
super.key,
});

@override
State<ManagerAdminSupportCreateScreen> createState() =>
_ManagerAdminSupportCreateScreenState();
}

class _ManagerAdminSupportCreateScreenState
extends State<ManagerAdminSupportCreateScreen> {
static const Color primaryColor = Color(0xff00ACC1);

late final ManagerAdminSupportService _service;

final ImagePicker _imagePicker = ImagePicker();

final TextEditingController _subjectController =
TextEditingController();

final TextEditingController _messageController =
TextEditingController();

final List<XFile> _selectedImages = [];

bool _sending = false;

@override
void initState() {
super.initState();

_service = ManagerAdminSupportService(
apiService: ApiService(),
);
}

@override
void dispose() {
_subjectController.dispose();
_messageController.dispose();
super.dispose();
}

// =========================================================
// انتخاب عکس از گالری
// =========================================================

Future<void> _pickFromGallery() async {
if (_sending) return;

try {
final images = await _imagePicker.pickMultiImage(
imageQuality: 85,
);

if (images.isEmpty) {
return;
}

for (final image in images) {
final alreadyExists = _selectedImages.any(
(item) => item.path == image.path,
);

if (!alreadyExists) {
_selectedImages.add(image);
}
}

if (!mounted) return;

setState(() {});
} catch (e) {
if (!mounted) return;

_showError(
'انتخاب تصویر با خطا مواجه شد.',
);
}
}

// =========================================================
// گرفتن عکس با دوربین
// =========================================================

Future<void> _takePhoto() async {
if (_sending) return;

try {
final image = await _imagePicker.pickImage(
source: ImageSource.camera,
imageQuality: 85,
);

if (image == null) {
return;
}

final alreadyExists = _selectedImages.any(
(item) => item.path == image.path,
);

if (alreadyExists) {
return;
}

if (!mounted) return;

setState(() {
_selectedImages.add(image);
});
} catch (e) {
if (!mounted) return;

_showError(
'گرفتن تصویر با دوربین با خطا مواجه شد.',
);
}
}

// =========================================================
// نمایش انتخاب منبع تصویر
// =========================================================

Future<void> _showImageSourceSheet() async {
if (_sending) return;

await showModalBottomSheet(
context: context,
backgroundColor: Colors.white,
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(
top: Radius.circular(20),
),
),
builder: (sheetContext) {
return Directionality(
textDirection: TextDirection.rtl,
child: SafeArea(
child: Padding(
padding: const EdgeInsets.fromLTRB(
16,
10,
16,
20,
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 45,
height: 5,
decoration: BoxDecoration(
color: Colors.grey.shade300,
borderRadius:
BorderRadius.circular(10),
),
),

const SizedBox(height: 18),

const Text(
'افزودن تصویر',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 18),

ListTile(
leading: Container(
width: 42,
height: 42,
decoration: BoxDecoration(
color: primaryColor.withValues(
alpha: 0.10,
),
borderRadius:
BorderRadius.circular(12),
),
child: const Icon(
Icons.photo_library_outlined,
color: primaryColor,
),
),
title: const Text(
'انتخاب از گالری',
),
subtitle: const Text(
'امکان انتخاب چند تصویر',
),
onTap: () async {
Navigator.pop(sheetContext);
await _pickFromGallery();
},
),

const SizedBox(height: 4),

ListTile(
leading: Container(
width: 42,
height: 42,
decoration: BoxDecoration(
color: Colors.orange.withValues(
alpha: 0.10,
),
borderRadius:
BorderRadius.circular(12),
),
child: const Icon(
Icons.camera_alt_outlined,
color: Colors.orange,
),
),
title: const Text(
'گرفتن عکس با دوربین',
),
subtitle: const Text(
'ثبت تصویر جدید',
),
onTap: () async {
Navigator.pop(sheetContext);
await _takePhoto();
},
),
],
),
),
),
);
},
);
}

// =========================================================
// حذف تصویر
// =========================================================

void _removeImage(int index) {
if (_sending) return;

if (index < 0 ||
index >= _selectedImages.length) {
return;
}

setState(() {
_selectedImages.removeAt(index);
});
}

// =========================================================
// ارسال تیکت
// =========================================================

Future<void> _submit() async {
if (_sending) return;

final subject =
_subjectController.text.trim();

final message =
_messageController.text.trim();

if (subject.isEmpty) {
_showError(
'عنوان تیکت را وارد کنید.',
);
return;
}

if (message.isEmpty) {
_showError(
'متن پیام را وارد کنید.',
);
return;
}

final filePaths = _selectedImages
    .map((image) => image.path.trim())
    .where(
(path) => path.isNotEmpty,
)
    .toList();

setState(() {
_sending = true;
});

try {
await _service.createTicket(
subject: subject,
message: message,
filePaths: filePaths,
);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'تیکت با موفقیت ایجاد شد.',
),
backgroundColor: Colors.green,
behavior: SnackBarBehavior.floating,
),
);

Navigator.pop(context, true);
} catch (e) {
if (!mounted) return;

String errorMessage = e
    .toString()
    .replaceFirst(
'Exception: ',
'',
);

if (errorMessage == 'NO_INTERNET') {
errorMessage =
'اتصال اینترنت برقرار نیست.';
} else if (errorMessage == 'TOKEN_EXPIRED') {
errorMessage =
'نشست شما منقضی شده است. لطفاً دوباره وارد شوید.';
}

_showError(errorMessage);
} finally {
if (!mounted) return;

setState(() {
_sending = false;
});
}
}

// =========================================================
// خطا
// =========================================================

void _showError(String message) {
if (!mounted) return;

ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(
message,
textAlign: TextAlign.right,
),
backgroundColor: Colors.red.shade600,
behavior: SnackBarBehavior.floating,
),
);
}

// =========================================================
// نمایش تصاویر
// =========================================================

Widget _buildSelectedImages() {
if (_selectedImages.isEmpty) {
return const SizedBox.shrink();
}

return Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const SizedBox(height: 14),

Row(
children: [
const Icon(
Icons.photo_library_outlined,
size: 18,
color: primaryColor,
),
const SizedBox(width: 6),
Text(
'تصاویر انتخاب شده',
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.bold,
color: Colors.grey.shade800,
),
),
const SizedBox(width: 6),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 7,
vertical: 3,
),
decoration: BoxDecoration(
color: primaryColor.withValues(
alpha: 0.10,
),
borderRadius:
BorderRadius.circular(20),
),
child: Text(
'${_selectedImages.length}',
style: const TextStyle(
color: primaryColor,
fontSize: 10,
fontWeight: FontWeight.bold,
),
),
),
],
),

const SizedBox(height: 10),

SizedBox(
height: 110,
child: ListView.separated(
scrollDirection: Axis.horizontal,
itemCount: _selectedImages.length,
separatorBuilder: (_, __) =>
const SizedBox(width: 10),
itemBuilder: (context, index) {
final image =
_selectedImages[index];

return Stack(
clipBehavior: Clip.none,
children: [
Container(
width: 110,
height: 110,
decoration: BoxDecoration(
borderRadius:
BorderRadius.circular(14),
border: Border.all(
color:
Colors.grey.shade300,
),
),
clipBehavior:
Clip.antiAlias,
child: Image.file(
File(image.path),
fit: BoxFit.cover,
errorBuilder:
(_, __, ___) {
return Container(
color:
Colors.grey.shade100,
child: const Icon(
Icons
    .broken_image_outlined,
color: Colors.grey,
size: 32,
),
);
},
),
),

Positioned(
top: -7,
right: -7,
child: GestureDetector(
onTap: _sending
? null
    : () =>
_removeImage(
index,
),
child: Container(
width: 26,
height: 26,
decoration:
const BoxDecoration(
color: Colors.red,
shape: BoxShape.circle,
),
child: const Icon(
Icons.close,
color: Colors.white,
size: 16,
),
),
),
),
],
);
},
),
),
],
);
}

// =========================================================
// ساخت صفحه
// =========================================================

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
appBar: AppBar(
title: const Text(
'ایجاد تیکت جدید',
),
centerTitle: true,
elevation: 0,
),
body: SafeArea(
child: SingleChildScrollView(
padding:
const EdgeInsets.all(16),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
// =================================================
// توضیحات
// =================================================

Container(
width: double.infinity,
padding:
const EdgeInsets.all(14),
decoration: BoxDecoration(
color:
primaryColor.withValues(
alpha: 0.07,
),
borderRadius:
BorderRadius.circular(14),
border: Border.all(
color:
primaryColor.withValues(
alpha: 0.15,
),
),
),
child: Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Icon(
Icons.support_agent_outlined,
color: primaryColor,
size: 25,
),
const SizedBox(width: 10),
Expanded(
child: Text(
'در این بخش می‌توانید درخواست یا مشکل خود را برای پشتیبانی سامانه ارسال کنید.',
style: TextStyle(
fontSize: 12,
height: 1.7,
color:
Colors.grey.shade800,
),
),
),
],
),
),

const SizedBox(height: 20),

// =================================================
// عنوان
// =================================================

const Text(
'عنوان تیکت',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

TextField(
controller:
_subjectController,
enabled: !_sending,
textInputAction:
TextInputAction.next,
decoration:
InputDecoration(
hintText:
'مثلاً مشکل در پرداخت شارژ',
prefixIcon:
const Icon(
Icons.title_outlined,
),
border:
OutlineInputBorder(
borderRadius:
BorderRadius.circular(
12,
),
),
enabledBorder:
OutlineInputBorder(
borderRadius:
BorderRadius.circular(
12,
),
borderSide:
BorderSide(
color:
Colors.grey.shade300,
),
),
focusedBorder:
OutlineInputBorder(
borderRadius:
BorderRadius.circular(
12,
),
borderSide:
const BorderSide(
color: primaryColor,
width: 1.5,
),
),
),
),

const SizedBox(height: 18),

// =================================================
// متن
// =================================================

const Text(
'متن پیام',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 8),

TextField(
controller:
_messageController,
enabled: !_sending,
minLines: 7,
maxLines: 12,
textInputAction:
TextInputAction.newline,
decoration:
InputDecoration(
hintText:
'مشکل یا درخواست خود را به طور کامل توضیح دهید...',
alignLabelWithHint: true,
border:
OutlineInputBorder(
borderRadius:
BorderRadius.circular(
12,
),
),
enabledBorder:
OutlineInputBorder(
borderRadius:
BorderRadius.circular(
12,
),
borderSide:
BorderSide(
color:
Colors.grey.shade300,
),
),
focusedBorder:
OutlineInputBorder(
borderRadius:
BorderRadius.circular(
12,
),
borderSide:
const BorderSide(
color: primaryColor,
width: 1.5,
),
),
),
),

const SizedBox(height: 18),

// =================================================
// افزودن تصویر
// =================================================

SizedBox(
width: double.infinity,
child: OutlinedButton.icon(
onPressed: _sending
? null
    : _showImageSourceSheet,
icon: const Icon(
Icons.add_photo_alternate_outlined,
),
label: const Text(
'افزودن تصویر',
),
style:
OutlinedButton.styleFrom(
foregroundColor:
primaryColor,
side: BorderSide(
color:
primaryColor.withValues(
alpha: 0.5,
),
),
padding:
const EdgeInsets.symmetric(
vertical: 13,
),
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(
12,
),
),
),
),
),

// =================================================
// تصاویر
// =================================================

_buildSelectedImages(),

const SizedBox(height: 28),

// =================================================
// ارسال
// =================================================

SizedBox(
width: double.infinity,
height: 52,
child: ElevatedButton.icon(
onPressed:
_sending
? null
    : _submit,
icon: _sending
? const SizedBox(
width: 20,
height: 20,
child:
CircularProgressIndicator(
strokeWidth: 2.2,
valueColor:
AlwaysStoppedAnimation<
Color>(
Colors.white,
),
),
)
    : const Icon(
Icons.send_outlined,
),
label: Text(
_sending
? 'در حال ارسال...'
    : 'ارسال تیکت',
),
style:
ElevatedButton.styleFrom(
backgroundColor:
primaryColor,
foregroundColor:
Colors.white,
disabledBackgroundColor:
primaryColor.withValues(
alpha: 0.55,
),
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(
14,
),
),
elevation: 0,
),
),
),

const SizedBox(height: 12),

Center(
child: Text(
'پس از ارسال، تیکت در بخش پشتیبانی قابل مشاهده خواهد بود.',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 10,
color:
Colors.grey.shade600,
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
}

