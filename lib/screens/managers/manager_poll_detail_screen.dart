
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/manager_poll_service.dart';

class ManagerPollDetailScreen extends StatefulWidget {
final int pollId;

const ManagerPollDetailScreen({
super.key,
required this.pollId,
});

@override
State<ManagerPollDetailScreen> createState() =>
_ManagerPollDetailScreenState();
}

class _ManagerPollDetailScreenState
extends State<ManagerPollDetailScreen> {
late final ManagerPollService pollService;

bool isLoading = true;
String? errorMessage;

Map<String, dynamic>? poll;

static const Color primaryColor = Color(0xff00838F);

@override
void initState() {
super.initState();

pollService = ManagerPollService(
apiService: ApiService(),
);

loadPoll();
}

// =====================================================
// دریافت اطلاعات
// =====================================================

Future<void> loadPoll() async {
setState(() {
isLoading = true;
errorMessage = null;
});

try {
final result = await pollService.getPoll(
widget.pollId,
);

if (!mounted) return;

setState(() {
poll = result;
isLoading = false;
});
} catch (e) {
if (!mounted) return;

setState(() {
isLoading = false;
errorMessage = _cleanError(e);
});
}
}

// =====================================================
// پاک کردن Exception
// =====================================================

String _cleanError(Object error) {
String text = error.toString();

if (text.startsWith('Exception:')) {
text = text.substring(
'Exception:'.length,
);
}

return text.trim();
}

// =====================================================
// ارقام فارسی
// =====================================================

String _toPersianDigits(dynamic value) {
String text = value?.toString() ?? '';

const english = '0123456789';
const persian = '۰۱۲۳۴۵۶۷۸۹';

for (int i = 0; i < english.length; i++) {
text = text.replaceAll(
english[i],
persian[i],
);
}

return text;
}

// =====================================================
// عنوان
// =====================================================

String _pollTitle() {
final value = poll?['title'];

if (value == null ||
value.toString().trim().isEmpty) {
return 'بدون عنوان';
}

return value.toString();
}

// =====================================================
// وضعیت
// =====================================================

bool _isActive() {
final value = poll?['is_active'];

if (value is bool) {
return value;
}

if (value is String) {
return value.toLowerCase() == 'true' ||
value == '1';
}

return false;
}

// =====================================================
// نوع شرکت‌کنندگان
// =====================================================

String _participantType() {
final value =
poll?['participant_type']
    ?.toString()
    .trim()
    .toLowerCase();

switch (value) {
case 'owners':
return 'owners';

case 'renters':
return 'renters';

case 'all':
default:
return 'all';
}
}

// =====================================================
// عنوان نوع شرکت‌کنندگان
// =====================================================

String _participantTypeTitle() {
switch (_participantType()) {
case 'owners':
return 'فقط مالکین';

case 'renters':
return 'فقط مستأجرین';

case 'all':
default:
return 'همه مالکین و مستأجرین';
}
}

// =====================================================
// تعداد مالکین
// =====================================================

int _ownerCount() {
final value =
poll?['owner_count'] ??
poll?['owners_count'] ??
0;

return int.tryParse(
value.toString(),
) ??
0;
}

// =====================================================
// تعداد مستأجرین
// =====================================================

int _renterCount() {
final value =
poll?['renter_count'] ??
poll?['renters_count'] ??
0;

return int.tryParse(
value.toString(),
) ??
0;
}

// =====================================================
// تعداد افراد مجاز
// =====================================================

int _eligibleCount() {
final value =
poll?['eligible_user_count'] ??
poll?['eligible_count'] ??
0;

return int.tryParse(
value.toString(),
) ??
0;
}

// =====================================================
// تعداد شرکت‌کنندگان
// =====================================================

int _participantCount() {
final value =
poll?['participant_count'] ??
poll?['participants_count'] ??
poll?['vote_count'] ??
0;

return int.tryParse(
value.toString(),
) ??
0;
}

// =====================================================
// تعداد شرکت نکرده‌ها
// =====================================================

int _notParticipatedCount() {
final value =
poll?['not_participated_count'];

if (value != null) {
return int.tryParse(
value.toString(),
) ??
0;
}

final result =
_eligibleCount() -
_participantCount();

return result < 0 ? 0 : result;
}

// =====================================================
// درصد مشارکت
// =====================================================

double _participationPercentage() {
final value =
poll?['percentage'] ??
poll?['participation_percentage'] ??
poll?['participation_percent'];

if (value != null) {
return double.tryParse(
value.toString(),
) ??
0;
}

final eligible = _eligibleCount();
final participants = _participantCount();

if (eligible <= 0) {
return 0;
}

return (participants / eligible) * 100;
}

// =====================================================
// تاریخ
// =====================================================

String _formatDate(dynamic value) {
if (value == null) {
return '-';
}

final text = value.toString().trim();

if (text.isEmpty) {
return '-';
}

if (text.contains('T')) {
return text.split('T').first;
}

return text;
}

// =====================================================
// نوع سؤال
// =====================================================

String _questionType(dynamic value) {
switch (value?.toString()) {
case 'yesno':
return 'بله / خیر';

case 'single':
return 'تک انتخابی';

case 'multi':
return 'چند انتخابی';

default:
return value?.toString() ?? '-';
}
}

// =====================================================
// دریافت لیست سؤالات
// =====================================================

List<dynamic> _questions() {
final value = poll?['questions'];

if (value is List) {
return value;
}

return [];
}

// =====================================================
// دریافت گزینه‌ها
// =====================================================

List<dynamic> _choices(dynamic question) {
if (question is! Map) {
return [];
}

final value = question['choices'];

if (value is List) {
return value;
}

return [];
}

// =====================================================
// عنوان سؤال
// =====================================================

String _questionTitle(dynamic question) {
if (question is! Map) {
return '';
}

return (
question['title'] ??
question['question'] ??
''
).toString();
}

// =====================================================
// عنوان گزینه
// =====================================================

String _choiceTitle(dynamic choice) {
if (choice is Map) {
return (
choice['title'] ??
choice['choice'] ??
choice['text'] ??
choice['value'] ??
''
).toString();
}

return choice.toString();
}

// =====================================================
// تعداد رأی گزینه
// =====================================================

int _choiceVoteCount(dynamic choice) {
if (choice is! Map) {
return 0;
}

final value =
choice['vote_count'] ??
choice['votes'] ??
choice['count'] ??
0;

return int.tryParse(
value.toString(),
) ??
0;
}

// =====================================================
// درصد گزینه
// =====================================================

double _choicePercentage(dynamic choice) {
if (choice is! Map) {
return 0;
}

final value =
choice['percentage'] ??
choice['percent'] ??
0;

return double.tryParse(
value.toString(),
) ??
0;
}

// =====================================================
// کارت نوع شرکت‌کنندگان
// =====================================================

Widget _buildParticipantCard() {
final ownerCount = _ownerCount();
final renterCount = _renterCount();
final eligibleCount = _eligibleCount();

return Container(
width: double.infinity,
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.white,
borderRadius:
BorderRadius.circular(16),
border: Border.all(
color: Colors.grey.shade200,
),
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
width: 42,
height: 42,
decoration: BoxDecoration(
color:
primaryColor.withOpacity(0.10),
borderRadius:
BorderRadius.circular(12),
),
child: const Icon(
Icons.groups_outlined,
color: primaryColor,
size: 22,
),
),

const SizedBox(width: 12),

const Expanded(
child: Text(
'گروه شرکت‌کنندگان',
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.bold,
),
),
),
],
),

const SizedBox(height: 14),

Container(
width: double.infinity,
padding: const EdgeInsets.symmetric(
horizontal: 14,
vertical: 12,
),
decoration: BoxDecoration(
color:
primaryColor.withOpacity(0.06),
borderRadius:
BorderRadius.circular(12),
border: Border.all(
color:
primaryColor.withOpacity(0.12),
),
),
child: Row(
children: [
const Icon(
Icons.how_to_vote_outlined,
size: 20,
color: primaryColor,
),

const SizedBox(width: 9),

Expanded(
child: Text(
_participantTypeTitle(),
style: const TextStyle(
fontSize: 14,
fontWeight: FontWeight.bold,
color: primaryColor,
),
),
),
],
),
),

const SizedBox(height: 14),

_participantRow(
icon: Icons.person_outline,
title: 'مالکین فعال',
value: ownerCount,
),

const Divider(height: 22),

_participantRow(
icon: Icons.person_outline,
title: 'مستأجرین فعال',
value: renterCount,
),

const Divider(height: 22),

_participantRow(
icon: Icons.groups_outlined,
title: 'افراد مجاز به شرکت',
value: eligibleCount,
highlight: true,
),
],
),
);
}

// =====================================================
// ردیف نوع شرکت‌کنندگان
// =====================================================

Widget _participantRow({
required IconData icon,
required String title,
required int value,
bool highlight = false,
}) {
return Row(
children: [
Icon(
icon,
size: 20,
color: highlight
? primaryColor
    : Colors.grey.shade600,
),

const SizedBox(width: 10),

Expanded(
child: Text(
title,
style: TextStyle(
fontSize: 13,
color: Colors.grey.shade700,
fontWeight: highlight
? FontWeight.bold
    : FontWeight.normal,
),
),
),

Text(
_toPersianDigits(value),
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.bold,
color: highlight
? primaryColor
    : Colors.black87,
),
),
],
);
}

// =====================================================
// کارت آمار
// =====================================================

Widget _buildInfoCard() {
final eligible = _eligibleCount();
final participants = _participantCount();
final notParticipated =
_notParticipatedCount();
final percentage =
_participationPercentage();

return Container(
width: double.infinity,
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.white,
borderRadius:
BorderRadius.circular(16),
border: Border.all(
color: Colors.grey.shade200,
),
),
child: Column(
children: [
_infoRow(
icon: Icons.people_outline,
title: 'افراد مجاز',
value:
_toPersianDigits(eligible),
),

const Divider(height: 24),

_infoRow(
icon: Icons.how_to_vote_outlined,
title: 'شرکت‌کنندگان',
value:
_toPersianDigits(participants),
),

const Divider(height: 24),

_infoRow(
icon: Icons.person_off_outlined,
title: 'شرکت نکرده‌اند',
value:
_toPersianDigits(
notParticipated,
),
),

const Divider(height: 24),

_infoRow(
icon: Icons.percent_outlined,
title: 'درصد مشارکت',
value:
'${_toPersianDigits(
percentage.toStringAsFixed(1),
)}٪',
),
],
),
);
}

// =====================================================
// ردیف اطلاعات
// =====================================================

Widget _infoRow({
required IconData icon,
required String title,
required String value,
}) {
return Row(
children: [
Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color:
primaryColor.withOpacity(0.10),
borderRadius:
BorderRadius.circular(12),
),
child: Icon(
icon,
color: primaryColor,
size: 21,
),
),

const SizedBox(width: 12),

Expanded(
child: Text(
title,
style: const TextStyle(
fontSize: 14,
color: Colors.black87,
),
),
),

Text(
value,
style: const TextStyle(
fontSize: 14,
fontWeight: FontWeight.bold,
color: primaryColor,
),
),
],
);
}

// =====================================================
// کارت سؤال
// =====================================================

Widget _buildQuestionCard(
dynamic question,
int index,
) {
final title = _questionTitle(question);

final type = question is Map
? question['question_type'] ??
question['type']
    : null;

final choices = _choices(question);

return Container(
width: double.infinity,
margin: const EdgeInsets.only(
bottom: 14,
),
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: Colors.white,
borderRadius:
BorderRadius.circular(16),
border: Border.all(
color: Colors.grey.shade200,
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
Container(
width: 34,
height: 34,
alignment: Alignment.center,
decoration: BoxDecoration(
color: primaryColor,
borderRadius:
BorderRadius.circular(10),
),
child: Text(
_toPersianDigits(
index + 1,
),
style: const TextStyle(
color: Colors.white,
fontWeight:
FontWeight.bold,
),
),
),

const SizedBox(width: 10),

Expanded(
child: Text(
title.isEmpty
? 'بدون عنوان'
    : title,
style: const TextStyle(
fontSize: 15,
fontWeight:
FontWeight.bold,
height: 1.7,
),
),
),
],
),

const SizedBox(height: 10),

Container(
padding:
const EdgeInsets.symmetric(
horizontal: 10,
vertical: 6,
),
decoration: BoxDecoration(
color:
Colors.grey.shade100,
borderRadius:
BorderRadius.circular(8),
),
child: Text(
_questionType(type),
style: TextStyle(
fontSize: 12,
color: Colors.grey.shade700,
),
),
),

if (choices.isNotEmpty) ...[
const SizedBox(height: 14),

...List.generate(
choices.length,
(choiceIndex) {
return _buildChoice(
choices[choiceIndex],
choiceIndex,
);
},
),
],
],
),
);
}

// =====================================================
// گزینه
// =====================================================

Widget _buildChoice(
dynamic choice,
int index,
) {
final title = _choiceTitle(choice);

final votes = _choiceVoteCount(choice);

final percentage =
_choicePercentage(choice);

return Container(
width: double.infinity,
margin: const EdgeInsets.only(
bottom: 8,
),
padding:
const EdgeInsets.symmetric(
horizontal: 12,
vertical: 11,
),
decoration: BoxDecoration(
color: Colors.grey.shade50,
borderRadius:
BorderRadius.circular(10),
border: Border.all(
color: Colors.grey.shade200,
),
),
child: Row(
children: [
Container(
width: 28,
height: 28,
alignment: Alignment.center,
decoration: BoxDecoration(
color:
primaryColor.withOpacity(0.10),
shape: BoxShape.circle,
),
child: Text(
_toPersianDigits(
index + 1,
),
style: const TextStyle(
fontSize: 12,
color: primaryColor,
fontWeight:
FontWeight.bold,
),
),
),

const SizedBox(width: 10),

Expanded(
child: Text(
title,
style: const TextStyle(
fontSize: 13,
height: 1.5,
),
),
),

Column(
crossAxisAlignment:
CrossAxisAlignment.end,
children: [
Text(
'${_toPersianDigits(votes)} رأی',
style: const TextStyle(
fontSize: 12,
fontWeight:
FontWeight.bold,
color: primaryColor,
),
),

const SizedBox(height: 2),

Text(
'${_toPersianDigits(
percentage.toStringAsFixed(1),
)}٪',
style: TextStyle(
fontSize: 11,
color:
Colors.grey.shade600,
),
),
],
),
],
),
);
}

// =====================================================
// صفحه خطا
// =====================================================

Widget _buildError() {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisAlignment:
MainAxisAlignment.center,
children: [
Icon(
Icons.error_outline,
size: 60,
color: Colors.red.shade300,
),

const SizedBox(height: 16),

Text(
errorMessage ??
'خطایی رخ داده است.',
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 14,
height: 1.7,
),
),

const SizedBox(height: 20),

ElevatedButton.icon(
onPressed: loadPoll,
icon: const Icon(
Icons.refresh,
),
label: const Text(
'تلاش مجدد',
),
style:
ElevatedButton.styleFrom(
backgroundColor:
primaryColor,
foregroundColor:
Colors.white,
),
),
],
),
),
);
}

// =====================================================
// بدنه
// =====================================================

Widget _buildBody() {
if (isLoading) {
return const Center(
child: CircularProgressIndicator(
color: primaryColor,
),
);
}

if (errorMessage != null) {
return _buildError();
}

if (poll == null) {
return const Center(
child: Text(
'اطلاعات نظرسنجی پیدا نشد.',
),
);
}

final questions = _questions();

final description =
poll?['description']
    ?.toString()
    .trim();

return RefreshIndicator(
color: primaryColor,
onRefresh: loadPoll,
child: ListView(
padding: const EdgeInsets.all(16),
children: [
// =================================================
// عنوان و وضعیت
// =================================================

Container(
width: double.infinity,
padding:
const EdgeInsets.all(18),
decoration: BoxDecoration(
color: Colors.white,
borderRadius:
BorderRadius.circular(16),
border: Border.all(
color:
Colors.grey.shade200,
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
Container(
width: 46,
height: 46,
decoration:
BoxDecoration(
color: primaryColor,
borderRadius:
BorderRadius.circular(
14,
),
),
child: const Icon(
Icons.poll_outlined,
color: Colors.white,
size: 25,
),
),

const SizedBox(width: 12),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment
    .start,
children: [
Text(
_pollTitle(),
style:
const TextStyle(
fontSize: 17,
fontWeight:
FontWeight.bold,
height: 1.6,
),
),

const SizedBox(
height: 8,
),

Container(
padding:
const EdgeInsets
    .symmetric(
horizontal: 9,
vertical: 5,
),
decoration:
BoxDecoration(
color: _isActive()
? Colors.green
    .withOpacity(
0.10,
)
    : Colors.red
    .withOpacity(
0.10,
),
borderRadius:
BorderRadius
    .circular(
8,
),
),
child: Text(
_isActive()
? 'فعال'
    : 'غیرفعال',
style: TextStyle(
fontSize: 12,
fontWeight:
FontWeight.bold,
color: _isActive()
? Colors.green
    : Colors.red,
),
),
),
],
),
),
],
),

if (description != null &&
description.isNotEmpty) ...[
const SizedBox(height: 18),

const Divider(),

const SizedBox(height: 10),

Text(
description,
style: TextStyle(
fontSize: 13,
height: 1.8,
color:
Colors.grey.shade700,
),
),
],

const SizedBox(height: 16),

const Divider(),

const SizedBox(height: 10),

Row(
children: [
Expanded(
child: _dateItem(
icon: Icons
    .calendar_today_outlined,
title: 'تاریخ شروع',
value:
_formatDate(
poll?['start_date'],
),
),
),

const SizedBox(width: 12),

Expanded(
child: _dateItem(
icon: Icons
    .event_outlined,
title: 'تاریخ پایان',
value:
_formatDate(
poll?['end_date'],
),
),
),
],
),
],
),
),

const SizedBox(height: 14),

// =================================================
// نوع شرکت‌کنندگان
// =================================================

_buildParticipantCard(),

const SizedBox(height: 14),

// =================================================
// آمار
// =================================================

_buildInfoCard(),

const SizedBox(height: 20),

// =================================================
// سؤالات
// =================================================

const Text(
'سؤالات نظرسنجی',
style: TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 12),

if (questions.isEmpty)
Container(
padding:
const EdgeInsets.all(20),
decoration: BoxDecoration(
color: Colors.white,
borderRadius:
BorderRadius.circular(16),
),
child: const Center(
child: Text(
'سؤالی برای این نظرسنجی ثبت نشده است.',
textAlign:
TextAlign.center,
),
),
)
else
...List.generate(
questions.length,
(index) => _buildQuestionCard(
questions[index],
index,
),
),

const SizedBox(height: 20),
],
),
);
}

// =====================================================
// تاریخ
// =====================================================

Widget _dateItem({
required IconData icon,
required String title,
required String value,
}) {
return Container(
padding:
const EdgeInsets.all(10),
decoration: BoxDecoration(
color: Colors.grey.shade50,
borderRadius:
BorderRadius.circular(10),
),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Row(
children: [
Icon(
icon,
size: 16,
color: primaryColor,
),

const SizedBox(width: 5),

Text(
title,
style: TextStyle(
fontSize: 11,
color:
Colors.grey.shade600,
),
),
],
),

const SizedBox(height: 6),

Text(
_toPersianDigits(value),
style: const TextStyle(
fontSize: 12,
fontWeight:
FontWeight.bold,
),
),
],
),
);
}

// =====================================================
// Build
// =====================================================

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
backgroundColor:
const Color(0xffF5F7F8),
appBar: AppBar(
title: const Text(
'جزئیات نظرسنجی',
),
centerTitle: true,
backgroundColor:
primaryColor,
foregroundColor: Colors.white,
elevation: 0,
),
body: _buildBody(),
),
);
}
}

