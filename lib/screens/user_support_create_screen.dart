
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import '../../services/user_support_service.dart';

class UserSupportCreateScreen extends StatefulWidget {
const UserSupportCreateScreen({
super.key,
});

@override
State<UserSupportCreateScreen> createState() =>
_UserSupportCreateScreenState();
}

class _UserSupportCreateScreenState
extends State<UserSupportCreateScreen> {
late final UserSupportService _supportService;

final _formKey = GlobalKey<FormState>();

final TextEditingController _subjectController =
TextEditingController();

final TextEditingController _messageController =
TextEditingController();

final ImagePicker _imagePicker = ImagePicker();

String? _selectedFilePath;

bool _isCall = false;
bool _sending = false;

@override
void initState() {
super.initState();

_supportService = UserSupportService(
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
// انتخاب تصویر
// =========================================================

Future<void> _pickImage() async {
if (_sending) return;

try {
final XFile? image = await _imagePicker.pickImage(
source: ImageSource.gallery,
imageQuality: 85,
maxWidth: 1600,
maxHeight: 1600,
);

if (image == null) {
return;
}

if (!mounted) return;

setState(() {
_selectedFilePath = image.path;
});
} catch (e) {
if (!mounted) return;

_showError(
'انتخاب تصویر انجام نشد.',
);
}
}

// =========================================================
// حذف تصویر
// =========================================================

void _removeImage() {
if (_sending) return;

setState(() {
_selectedFilePath = null;
});
}

// =========================================================
// ارسال تیکت
// =========================================================

Future<void> _submit() async {
FocusScope.of(context).unfocus();

if (!_formKey.currentState!.validate()) {
return;
}

if (_sending) {
return;
}

setState(() {
_sending = true;
});

try {
await _supportService.createTicket(
subject: _subjectController.text.trim(),
message: _messageController.text.trim(),
isCall: _isCall,
filePath: _selectedFilePath,
);

if (!mounted) return;

_showSuccess(
'تیکت شما با موفقیت ثبت شد.',
);

await Future.delayed(
const Duration(
milliseconds: 700,
),
);

if (!mounted) return;

Navigator.pop(
context,
true,
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

// =========================================================
// نمایش خطا
// =========================================================

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
textDirection: TextDirection.rtl,
),
backgroundColor: Colors.red.shade700,
behavior: SnackBarBehavior.floating,
margin: const EdgeInsets.all(12),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
);
}

// =========================================================
// نمایش موفقیت
// =========================================================

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
textDirection: TextDirection.rtl,
),
backgroundColor: Colors.green.shade700,
behavior: SnackBarBehavior.floating,
margin: const EdgeInsets.all(12),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
);
}

// =========================================================
// خطای سرویس
// =========================================================

String _cleanError(
Object error,
) {
var text = error.toString();

if (text.startsWith('Exception:')) {
text = text.substring(
'Exception:'.length,
);
}

text = text.trim();

if (text.isEmpty) {
return 'خطایی در ثبت تیکت رخ داد.';
}

return text;
}

// =========================================================
// نمایش نام فایل
// =========================================================

String _fileName(
String path,
) {
try {
return path.split(
Platform.pathSeparator,
).last;
} catch (_) {
return path.split('/').last;
}
}

// =========================================================
// اعتبارسنجی عنوان
// =========================================================

String? _validateSubject(
String? value,
) {
final text = value?.trim() ?? '';

if (text.isEmpty) {
return 'عنوان تیکت را وارد کنید.';
}

if (text.length > 200) {
return 'عنوان نمی‌تواند بیشتر از ۲۰۰ کاراکتر باشد.';
}

return null;
}

// =========================================================
// اعتبارسنجی پیام
// =========================================================

String? _validateMessage(
String? value,
) {
final text = value?.trim() ?? '';

if (text.isEmpty) {
return 'متن درخواست خود را وارد کنید.';
}

return null;
}

// =========================================================
// بخش عنوان
// =========================================================

Widget _buildSubjectField() {
return Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Text(
'عنوان تیکت',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w700,
color: Color(0xff263238),
),
),
const SizedBox(height: 8),
TextFormField(
controller: _subjectController,
enabled: !_sending,
textInputAction: TextInputAction.next,
maxLength: 200,
decoration: InputDecoration(
hintText: 'مثلاً: مشکل در پرداخت شارژ',
prefixIcon: const Icon(
Icons.title_rounded,
color: Color(0xff00ACC1),
),
filled: true,
fillColor: Colors.white,
counterText: '',
contentPadding:
const EdgeInsets.symmetric(
horizontal: 14,
vertical: 14,
),
border: OutlineInputBorder(
borderRadius:
BorderRadius.circular(13),
borderSide: BorderSide(
color: Colors.grey.shade200,
),
),
enabledBorder: OutlineInputBorder(
borderRadius:
BorderRadius.circular(13),
borderSide: BorderSide(
color: Colors.grey.shade200,
),
),
focusedBorder: OutlineInputBorder(
borderRadius:
BorderRadius.circular(13),
borderSide: const BorderSide(
color: Color(0xff00ACC1),
width: 1.5,
),
),
errorBorder: OutlineInputBorder(
borderRadius:
BorderRadius.circular(13),
borderSide: const BorderSide(
color: Colors.redAccent,
),
),
focusedErrorBorder:
OutlineInputBorder(
borderRadius:
BorderRadius.circular(13),
borderSide: const BorderSide(
color: Colors.redAccent,
width: 1.5,
),
),
),
validator: _validateSubject,
),
],
);
}

// =========================================================
// بخش متن
// =========================================================

Widget _buildMessageField() {
return Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Text(
'متن درخواست',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w700,
color: Color(0xff263238),
),
),
const SizedBox(height: 8),
TextFormField(
controller: _messageController,
enabled: !_sending,
maxLines: 7,
minLines: 5,
textInputAction: TextInputAction.newline,
textAlignVertical:
TextAlignVertical.top,
decoration: InputDecoration(
hintText:
'مشکل یا درخواست خود را به طور کامل توضیح دهید...',
alignLabelWithHint: true,
prefixIcon: const Padding(
padding: EdgeInsets.only(
top: 12,
),
child: Icon(
Icons.message_outlined,
color: Color(0xff00ACC1),
),
),
filled: true,
fillColor: Colors.white,
contentPadding:
const EdgeInsets.fromLTRB(
14,
14,
14,
14,
),
border: OutlineInputBorder(
borderRadius:
BorderRadius.circular(13),
borderSide: BorderSide(
color: Colors.grey.shade200,
),
),
enabledBorder: OutlineInputBorder(
borderRadius:
BorderRadius.circular(13),
borderSide: BorderSide(
color: Colors.grey.shade200,
),
),
focusedBorder: OutlineInputBorder(
borderRadius:
BorderRadius.circular(13),
borderSide: const BorderSide(
color: Color(0xff00ACC1),
width: 1.5,
),
),
errorBorder: OutlineInputBorder(
borderRadius:
BorderRadius.circular(13),
borderSide: const BorderSide(
color: Colors.redAccent,
),
),
focusedErrorBorder:
OutlineInputBorder(
borderRadius:
BorderRadius.circular(13),
borderSide: const BorderSide(
color: Colors.redAccent,
width: 1.5,
),
),
),
validator: _validateMessage,
),
],
);
}

// =========================================================
// درخواست تماس
// =========================================================

Widget _buildCallOption() {
return Container(
width: double.infinity,
margin: const EdgeInsets.only(
top: 14,
),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(13),
border: Border.all(
color: _isCall
? Colors.orange.withOpacity(0.35)
    : Colors.grey.shade200,
),
),
child: SwitchListTile(
value: _isCall,
onChanged: _sending
? null
    : (value) {
setState(() {
_isCall = value;
});
},
activeColor: Colors.orange,
contentPadding:
const EdgeInsets.symmetric(
horizontal: 12,
vertical: 2,
),
secondary: Container(
width: 38,
height: 38,
decoration: BoxDecoration(
color: Colors.orange.withOpacity(0.10),
borderRadius: BorderRadius.circular(10),
),
child: const Icon(
Icons.phone_in_talk_outlined,
color: Colors.orange,
size: 20,
),
),
title: const Text(
'درخواست تماس مدیر ساختمان',
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w700,
color: Color(0xff263238),
),
),
subtitle: const Text(
'در صورت نیاز، مدیر ساختمان با شما تماس خواهد گرفت.',
style: TextStyle(
fontSize: 10,
color: Colors.grey,
height: 1.5,
),
),
),
);
}

// =========================================================
// انتخاب فایل
// =========================================================

Widget _buildAttachment() {
if (_selectedFilePath == null) {
return Container(
width: double.infinity,
margin: const EdgeInsets.only(
top: 14,
),
child: OutlinedButton.icon(
onPressed: _sending
? null
    : _pickImage,
icon: const Icon(
Icons.image_outlined,
size: 21,
),
label: const Text(
'افزودن تصویر',
),
style: OutlinedButton.styleFrom(
foregroundColor:
const Color(0xff00ACC1),
side: BorderSide(
color: const Color(0xff00ACC1)
    .withOpacity(0.45),
),
backgroundColor: Colors.white,
padding:
const EdgeInsets.symmetric(
vertical: 13,
),
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(12),
),
),
),
);
}

return Container(
width: double.infinity,
margin: const EdgeInsets.only(
top: 14,
),
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(13),
border: Border.all(
color: const Color(0xff00ACC1)
    .withOpacity(0.25),
),
),
child: Row(
children: [
Container(
width: 42,
height: 42,
decoration: BoxDecoration(
color: const Color(0xff00ACC1)
    .withOpacity(0.10),
borderRadius:
BorderRadius.circular(10),
),
child: const Icon(
Icons.image_rounded,
color: Color(0xff00ACC1),
),
),
const SizedBox(width: 10),
Expanded(
child: Text(
_fileName(_selectedFilePath!),
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
),
),
),
IconButton(
onPressed:
_sending ? null : _removeImage,
tooltip: 'حذف تصویر',
icon: const Icon(
Icons.close_rounded,
color: Colors.redAccent,
),
),
],
),
);
}

// =========================================================
// راهنما
// =========================================================

Widget _buildInfo() {
return Container(
margin: const EdgeInsets.only(
top: 14,
),
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: const Color(0xff00ACC1)
    .withOpacity(0.07),
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: const Color(0xff00ACC1)
    .withOpacity(0.12),
),
),
child: const Row(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Icon(
Icons.info_outline_rounded,
color: Color(0xff00ACC1),
size: 19,
),
SizedBox(width: 8),
Expanded(
child: Text(
'پس از ثبت تیکت، پاسخ مدیر ساختمان در همین بخش نمایش داده می‌شود. '
'برای توضیح بهتر مشکل می‌توانید یک تصویر نیز پیوست کنید.',
style: TextStyle(
fontSize: 11,
color: Color(0xff546E7A),
height: 1.7,
),
),
),
],
),
);
}

// =========================================================
// دکمه ارسال
// =========================================================

Widget _buildSubmitButton() {
return SizedBox(
width: double.infinity,
height: 52,
child: ElevatedButton(
onPressed: _sending ? null : _submit,
style: ElevatedButton.styleFrom(
backgroundColor:
const Color(0xff00ACC1),
foregroundColor: Colors.white,
disabledBackgroundColor:
const Color(0xff80CBC4),
elevation: 1,
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(13),
),
),
child: _sending
? const Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
SizedBox(
width: 21,
height: 21,
child:
CircularProgressIndicator(
strokeWidth: 2.3,
color: Colors.white,
),
),
SizedBox(width: 10),
Text(
'در حال ارسال...',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w700,
),
),
],
)
    : const Row(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
Icon(
Icons.send_rounded,
size: 20,
),
SizedBox(width: 8),
Text(
'ثبت تیکت',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.w700,
),
),
],
),
),
);
}

// =========================================================
// صفحه
// =========================================================

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
backgroundColor:
const Color(0xffF5F7F8),
appBar: AppBar(
backgroundColor:
const Color(0xff00ACC1),
foregroundColor: Colors.white,
centerTitle: true,
elevation: 0,
title: const Text(
'ایجاد تیکت جدید',
style: TextStyle(
fontSize: 17,
fontWeight: FontWeight.w700,
),
),
),
body: SafeArea(
child: Form(
key: _formKey,
child: SingleChildScrollView(
padding: const EdgeInsets.fromLTRB(
14,
16,
14,
30,
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.stretch,
children: [
_buildSubjectField(),
const SizedBox(height: 16),
_buildMessageField(),
_buildCallOption(),
_buildAttachment(),
_buildInfo(),
const SizedBox(height: 22),
_buildSubmitButton(),
],
),
),
),
),
),
);
}
}

