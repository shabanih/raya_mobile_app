
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/api_service.dart';
import '../../services/manager_poll_service.dart';

class ManagerPollCreateScreen extends StatefulWidget {
final int? pollId;

const ManagerPollCreateScreen({
super.key,
this.pollId,
});

@override
State<ManagerPollCreateScreen> createState() =>
_ManagerPollCreateScreenState();
}

class _ManagerPollCreateScreenState
extends State<ManagerPollCreateScreen> {
// =====================================================
// Colors
// =====================================================

static const Color primaryColor =
Color(0xff00838F);

static const Color textColor =
Color(0xff263238);

static const Color backgroundColor =
Color(0xffEEF3F5);

static const Color fieldColor =
Color(0xffF5F8FA);

// =====================================================
// Service
// =====================================================

late final ManagerPollService pollService;

// =====================================================
// State
// =====================================================

bool isLoading = false;
bool isSaving = false;

String? errorMessage;

// =====================================================
// Controllers
// =====================================================

final TextEditingController _titleController =
TextEditingController();

final TextEditingController _descriptionController =
TextEditingController();

// =====================================================
// Dates
// =====================================================

DateTime? _startDate;
DateTime? _endDate;

// =====================================================
// Active
// =====================================================

bool _isActive = true;

// =====================================================
// Participant Type
//
// all     = همه مالکین و مستأجرین
// owners  = فقط مالکین
// renters = فقط مستأجرین
// =====================================================

String _participantType = 'all';

// =====================================================
// Questions
// =====================================================

final List<_PollQuestionData> _questions = [];

// =====================================================
// Init
// =====================================================

@override
void initState() {
super.initState();

pollService = ManagerPollService(
apiService: ApiService(),
);

if (widget.pollId != null) {
_loadPoll();
} else {
_questions.add(
_PollQuestionData(),
);
}
}

// =====================================================
// Dispose
// =====================================================

@override
void dispose() {
_titleController.dispose();
_descriptionController.dispose();

for (final question in _questions) {
question.dispose();
}

super.dispose();
}

// =====================================================
// Load Poll
// =====================================================

Future<void> _loadPoll() async {
if (widget.pollId == null) {
return;
}

if (mounted) {
setState(() {
isLoading = true;
errorMessage = null;
});
}

try {
final poll = await pollService.getPoll(
widget.pollId!,
);

if (!mounted) {
return;
}

_fillPollData(poll);

setState(() {
isLoading = false;
});
} catch (e) {
debugPrint(
'LOAD POLL ERROR: $e',
);

if (!mounted) {
return;
}

setState(() {
isLoading = false;
errorMessage = _errorMessage(e);
});
}
}

// =====================================================
// Fill Poll Data
// =====================================================

void _fillPollData(
Map<String, dynamic> poll,
) {
_titleController.text =
poll['title']?.toString() ??
poll['name']?.toString() ??
'';

_descriptionController.text =
poll['description']?.toString() ??
'';

_isActive =
poll['is_active'] == true;

// ===================================================
// Participant Type
// ===================================================

final participantType =
poll['participant_type']?.toString();

if (participantType == 'all' ||
participantType == 'owners' ||
participantType == 'renters') {
_participantType =
participantType!;
} else {
_participantType = 'all';
}

_startDate =
_parseDate(
poll['start_date'],
);

_endDate =
_parseDate(
poll['end_date'],
);

for (final question in _questions) {
question.dispose();
}

_questions.clear();

dynamic questionsData =
poll['questions'];

if (questionsData is List) {
for (final item in questionsData) {
if (item is! Map) {
continue;
}

final questionMap =
Map<String, dynamic>.from(item);

final questionText =
questionMap['title']
    ?.toString() ??
questionMap['question']
    ?.toString() ??
questionMap['text']
    ?.toString() ??
'';

final questionType =
questionMap['question_type']
    ?.toString() ??
questionMap['type']
    ?.toString() ??
'yesno';

final questionData =
_PollQuestionData(
question: questionText,
type: _normalizeQuestionType(
questionType,
),
);

dynamic choices =
questionMap['choices'];

if (choices is List) {
for (final choice in choices) {
if (choice is Map) {
final choiceMap =
Map<String, dynamic>.from(
choice,
);

final text =
choiceMap['title']
    ?.toString() ??
choiceMap['text']
    ?.toString() ??
choiceMap['choice']
    ?.toString() ??
'';

if (text.trim().isNotEmpty) {
questionData.choices.add(
text.trim(),
);
}
} else {
final text =
choice.toString().trim();

if (text.isNotEmpty) {
questionData.choices.add(
text,
);
}
}
}
}

_questions.add(
questionData,
);
}
}

if (_questions.isEmpty) {
_questions.add(
_PollQuestionData(),
);
}
}

// =====================================================
// Normalize Question Type
// =====================================================

String _normalizeQuestionType(
String value,
) {
final type =
value.trim().toLowerCase();

if (type == 'single' ||
type == 'multi' ||
type == 'yesno') {
return type;
}

return 'yesno';
}

// =====================================================
// Parse Date
// =====================================================

DateTime? _parseDate(
dynamic value,
) {
if (value == null) {
return null;
}

final text =
value.toString().trim();

if (text.isEmpty) {
return null;
}

return DateTime.tryParse(
text,
);
}

// =====================================================
// Persian Digits
// =====================================================

String toPersianDigits(
String value,
) {
const english =
'0123456789';

const persian =
'۰۱۲۳۴۵۶۷۸۹';

var result = value;

for (int i = 0;
i < english.length;
i++) {
result =
result.replaceAll(
english[i],
persian[i],
);
}

return result;
}

// =====================================================
// Jalali Month Name
// =====================================================

String _jalaliMonthName(
int month,
) {
const months = [
'فروردین',
'اردیبهشت',
'خرداد',
'تیر',
'مرداد',
'شهریور',
'مهر',
'آبان',
'آذر',
'دی',
'بهمن',
'اسفند',
];

if (month < 1 ||
month > 12) {
return '';
}

return months[month - 1];
}

// =====================================================
// Jalali Calendar
// =====================================================

Widget _buildJalaliCalendar({
required Jalali month,
required Jalali selectedDate,
required ValueChanged<Jalali> onSelected,
}) {
final firstDay =
Jalali(
month.year,
month.month,
1,
);

final int daysInMonth =
month.month <= 6
? 31
    : month.month <= 11
? 30
    : month.isLeapYear()
? 30
    : 29;

final int leadingDays =
firstDay.weekDay;

final int totalCells =
((leadingDays +
daysInMonth) /
7)
    .ceil() *
7;

return GridView.builder(
physics:
const NeverScrollableScrollPhysics(),
itemCount:
totalCells,
gridDelegate:
const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 7,
childAspectRatio: 1.15,
),
itemBuilder:
(context, index) {
final int dayNumber =
index -
leadingDays +
1;

if (dayNumber < 1 ||
dayNumber >
daysInMonth) {
return const SizedBox();
}

final date =
Jalali(
month.year,
month.month,
dayNumber,
);

final bool isSelected =
date.year ==
selectedDate.year &&
date.month ==
selectedDate.month &&
date.day ==
selectedDate.day;

return InkWell(
borderRadius:
BorderRadius.circular(
10,
),
onTap: () {
onSelected(
date,
);
},
child: Container(
margin:
const EdgeInsets.all(
3,
),
decoration:
BoxDecoration(
color: isSelected
? primaryColor
    : Colors.transparent,
borderRadius:
BorderRadius.circular(
10,
),
),
alignment:
Alignment.center,
child: Text(
toPersianDigits(
dayNumber.toString(),
),
style:
TextStyle(
fontSize: 13,
fontWeight:
isSelected
? FontWeight.bold
    : FontWeight.normal,
color: isSelected
? Colors.white
    : textColor,
),
),
),
);
},
);
}

// =====================================================
// Show Jalali Date Dialog
// =====================================================

Future<Jalali?> _showJalaliDateDialog({
required Jalali initialDate,
required String title,
}) async {
return showDialog<Jalali>(
context: context,
builder: (
dialogContext,
) {
Jalali selectedDate =
initialDate;

return StatefulBuilder(
builder: (
context,
setDialogState,
) {
return AlertDialog(
backgroundColor:
Colors.white,
surfaceTintColor:
Colors.transparent,
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(
20,
),
),
title: Text(
title,
textAlign:
TextAlign.right,
style:
const TextStyle(
fontSize: 17,
fontWeight:
FontWeight.bold,
color:
textColor,
),
),
content: SizedBox(
width: 350,
height: 385,
child:
Directionality(
textDirection:
TextDirection.rtl,
child: Column(
children: [
Row(
mainAxisAlignment:
MainAxisAlignment
    .spaceBetween,
children: [
IconButton(
onPressed: () {
setDialogState(
() {
selectedDate =
selectedDate
    .addMonths(
-1,
);
},
);
},
icon:
const Icon(
Icons
    .chevron_right,
color:
primaryColor,
),
),
Expanded(
child:
Center(
child:
Text(
'${_jalaliMonthName(selectedDate.month)} '
'${toPersianDigits(selectedDate.year.toString())}',
style:
const TextStyle(
fontSize:
16,
fontWeight:
FontWeight.bold,
color:
textColor,
),
),
),
),
IconButton(
onPressed: () {
setDialogState(
() {
selectedDate =
selectedDate
    .addMonths(
1,
);
},
);
},
icon:
const Icon(
Icons
    .chevron_left,
color:
primaryColor,
),
),
],
),
const SizedBox(
height: 8,
),
Row(
children: [
for (final day
in [
'ش',
'ی',
'د',
'س',
'چ',
'پ',
'ج',
])
Expanded(
child:
Center(
child:
Text(
day,
style:
const TextStyle(
fontSize:
12,
fontWeight:
FontWeight.bold,
color:
Colors.grey,
),
),
),
),
],
),
const SizedBox(
height: 8,
),
Expanded(
child:
_buildJalaliCalendar(
month:
selectedDate,
selectedDate:
selectedDate,
onSelected:
(date) {
setDialogState(
() {
selectedDate =
date;
},
);
},
),
),
],
),
),
),
actions: [
TextButton(
onPressed: () {
Navigator.pop(
dialogContext,
);
},
child:
const Text(
'انصراف',
style:
TextStyle(
color:
Colors.grey,
),
),
),
ElevatedButton(
onPressed: () {
Navigator.pop(
dialogContext,
selectedDate,
);
},
style:
ElevatedButton.styleFrom(
backgroundColor:
primaryColor,
foregroundColor:
Colors.white,
elevation: 0,
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(
12,
),
),
),
child:
const Text(
'تأیید',
),
),
],
);
},
);
},
);
}

// =====================================================
// Select Start Date
// =====================================================

Future<void> _selectStartDate() async {
final Jalali initialDate =
_startDate != null
? Jalali.fromDateTime(
_startDate!,
)
    : Jalali.now();

final Jalali? picked =
await _showJalaliDateDialog(
initialDate:
initialDate,
title:
'انتخاب تاریخ شروع',
);

if (picked == null) {
return;
}

setState(() {
_startDate =
picked.toDateTime();
});

if (_endDate != null) {
final endDate =
_endDate!;

if (endDate.isBefore(
picked.toDateTime(),
)) {
setState(() {
_endDate =
picked.toDateTime();
});
}
}
}

// =====================================================
// Select End Date
// =====================================================

Future<void> _selectEndDate() async {
final Jalali initialDate =
_endDate != null
? Jalali.fromDateTime(
_endDate!,
)
    : _startDate != null
? Jalali.fromDateTime(
_startDate!,
)
    : Jalali.now();

final Jalali? picked =
await _showJalaliDateDialog(
initialDate:
initialDate,
title:
'انتخاب تاریخ پایان',
);

if (picked == null) {
return;
}

if (_startDate != null) {
final startDate =
_startDate!;

if (picked
    .toDateTime()
    .isBefore(
startDate,
)) {
if (!mounted) {
return;
}

ScaffoldMessenger.of(
context,
)
..hideCurrentSnackBar()
..showSnackBar(
const SnackBar(
content: Text(
'تاریخ پایان نمی‌تواند قبل از تاریخ شروع باشد.',
textDirection:
TextDirection.rtl,
),
behavior:
SnackBarBehavior.floating,
),
);

return;
}
}

setState(() {
_endDate =
picked.toDateTime();
});
}

// =====================================================
// Format Jalali Date
// =====================================================

String _formatJalaliDate(
DateTime? value,
) {
if (value == null) {
return 'انتخاب تاریخ';
}

final Jalali jalali =
Jalali.fromDateTime(
value,
);

return toPersianDigits(
'${jalali.year}/'
'${jalali.month.toString().padLeft(2, '0')}/'
'${jalali.day.toString().padLeft(2, '0')}',
);
}

// =====================================================
// API Date
// =====================================================

String _formatDateForApi(
DateTime date,
) {
return '${date.year.toString().padLeft(4, '0')}-'
'${date.month.toString().padLeft(2, '0')}-'
'${date.day.toString().padLeft(2, '0')}';
}

// =====================================================
// Participant Type Title
// =====================================================

String _participantTypeTitle() {
switch (_participantType) {
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
// Participant Type Description
// =====================================================

String _participantTypeDescription() {
switch (_participantType) {
case 'owners':
return 'فقط مالکین فعال واحدها می‌توانند در این نظرسنجی شرکت کنند.';

case 'renters':
return 'فقط مستأجرین فعال واحدها می‌توانند در این نظرسنجی شرکت کنند.';

case 'all':
default:
return 'مالکین و مستأجرین فعال می‌توانند در این نظرسنجی شرکت کنند.';
}
}

// =====================================================
// Participant Type Card
// =====================================================

Widget _buildParticipantTypeCard() {
return Container(
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
18,
),
border:
Border.all(
color:
primaryColor.withOpacity(
0.12,
),
),
boxShadow: [
BoxShadow(
color:
Colors.black.withOpacity(
0.05,
),
blurRadius:
10,
offset:
const Offset(
0,
3,
),
),
],
),
child:
Column(
crossAxisAlignment:
CrossAxisAlignment.stretch,
children: [
Row(
textDirection:
TextDirection.rtl,
children: [
Container(
width: 42,
height: 42,
decoration:
BoxDecoration(
color:
primaryColor.withOpacity(
0.10,
),
borderRadius:
BorderRadius.circular(
12,
),
),
child:
const Icon(
Icons
    .groups_outlined,
color:
primaryColor,
size: 23,
),
),
const SizedBox(
width: 10,
),
const Expanded(
child: Text(
'شرکت‌کنندگان نظرسنجی',
textAlign:
TextAlign.right,
style:
TextStyle(
fontSize: 15,
fontWeight:
FontWeight.bold,
color:
textColor,
),
),
),
],
),

const SizedBox(
height: 12,
),

DropdownButtonFormField<String>(
value:
_participantType,
isExpanded:
true,
decoration:
_inputDecoration(
label:
'چه کسانی می‌توانند رأی بدهند؟',
),
dropdownColor:
Colors.white,
icon:
const Icon(
Icons
    .keyboard_arrow_down,
color:
primaryColor,
),
items: const [
DropdownMenuItem(
value:
'all',
child:
Text(
'همه مالکین و مستأجرین',
textAlign:
TextAlign.right,
),
),
DropdownMenuItem(
value:
'owners',
child:
Text(
'فقط مالکین',
textAlign:
TextAlign.right,
),
),
DropdownMenuItem(
value:
'renters',
child:
Text(
'فقط مستأجرین',
textAlign:
TextAlign.right,
),
),
],
onChanged:
(value) {
if (value == null) {
return;
}

setState(() {
_participantType =
value;
});
},
),

const SizedBox(
height: 10,
),

Container(
padding:
const EdgeInsets.symmetric(
horizontal: 12,
vertical: 10,
),
decoration:
BoxDecoration(
color:
primaryColor.withOpacity(
0.045,
),
borderRadius:
BorderRadius.circular(
12,
),
),
child:
Row(
textDirection:
TextDirection.rtl,
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
const Icon(
Icons
    .info_outline,
size: 18,
color:
primaryColor,
),
const SizedBox(
width: 7,
),
Expanded(
child:
Text(
_participantTypeDescription(),
textAlign:
TextAlign.right,
style:
const TextStyle(
fontSize: 11,
height: 1.7,
color:
Colors.grey,
),
),
),
],
),
),
],
),
);
}

// =====================================================
// Add Question
// =====================================================

void _addQuestion() {
setState(() {
_questions.add(
_PollQuestionData(),
);
});
}

// =====================================================
// Remove Question
// =====================================================

void _removeQuestion(
int index,
) {
if (_questions.length <= 1) {
return;
}

_questions[index].dispose();

setState(() {
_questions.removeAt(
index,
);
});
}

// =====================================================
// Add Choice
// =====================================================

void _addChoice(
_PollQuestionData question,
) {
setState(() {
question.choices.add('');
});
}

// =====================================================
// Remove Choice
// =====================================================

void _removeChoice(
_PollQuestionData question,
int index,
) {
if (question.choices.length <= 2) {
return;
}

setState(() {
question.choices.removeAt(
index,
);
});
}

// =====================================================
// Validate
// =====================================================

String? _validate() {
if (_titleController.text
    .trim()
    .isEmpty) {
return 'لطفاً عنوان نظرسنجی را وارد کنید.';
}

if (_startDate == null) {
return 'لطفاً تاریخ شروع نظرسنجی را انتخاب کنید.';
}

if (_endDate == null) {
return 'لطفاً تاریخ پایان نظرسنجی را انتخاب کنید.';
}

if (_endDate!
    .isBefore(
_startDate!,
)) {
return 'تاریخ پایان نمی‌تواند قبل از تاریخ شروع باشد.';
}

if (_participantType != 'all' &&
_participantType != 'owners' &&
_participantType != 'renters') {
return 'لطفاً نوع شرکت‌کنندگان نظرسنجی را انتخاب کنید.';
}

if (_questions.isEmpty) {
return 'حداقل یک سؤال برای نظرسنجی وارد کنید.';
}

for (int i = 0;
i < _questions.length;
i++) {
final question =
_questions[i];

if (question.controller.text
    .trim()
    .isEmpty) {
return 'لطفاً متن سؤال شماره ${toPersianDigits((i + 1).toString())} را وارد کنید.';
}

if (question.type ==
'single' ||
question.type ==
'multi') {
if (question.choices.length <
2) {
return 'برای سؤال شماره ${toPersianDigits((i + 1).toString())} حداقل دو گزینه لازم است.';
}

for (int j = 0;
j <
question
    .choices
    .length;
j++) {
if (question.choices[j]
    .trim()
    .isEmpty) {
return 'لطفاً گزینه ${toPersianDigits((j + 1).toString())} سؤال شماره ${toPersianDigits((i + 1).toString())} را تکمیل کنید.';
}
}
}
}

return null;
}

// =====================================================
// Save Poll
// =====================================================

Future<void> _savePoll() async {
if (isSaving) {
return;
}

final validation =
_validate();

if (validation != null) {
ScaffoldMessenger.of(
context,
)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(
validation,
textDirection:
TextDirection.rtl,
),
behavior:
SnackBarBehavior.floating,
),
);

return;
}

setState(() {
isSaving = true;
});

try {
final List<Map<String, dynamic>>
questions = [];

for (int i = 0;
i < _questions.length;
i++) {
final question =
_questions[i];

final Map<String, dynamic>
data = {
'title':
question.controller.text
    .trim(),
'question_type':
question.type,
'order':
i + 1,
};

if (question.type ==
'single' ||
question.type ==
'multi') {
final choices =
question.choices
    .map(
(choice) => {
'title':
choice.trim(),
},
)
    .where(
(choice) =>
(choice['title'] ??
'')
    .toString()
    .trim()
    .isNotEmpty,
)
    .toList();

data['choices'] =
choices;
}

questions.add(
data,
);
}

final String startDate =
_formatDateForApi(
_startDate!,
);

final String endDate =
_formatDateForApi(
_endDate!,
);

debugPrint(
'========================================',
);

debugPrint(
'POLL PARTICIPANT TYPE: $_participantType',
);

debugPrint(
'POLL PARTICIPANT TYPE TITLE: '
'${_participantTypeTitle()}',
);

debugPrint(
'POLL QUESTIONS: $questions',
);

debugPrint(
'START DATE: $startDate',
);

debugPrint(
'END DATE: $endDate',
);

debugPrint(
'========================================',
);

// =================================================
// Edit
// =================================================

if (widget.pollId != null) {
await pollService.updatePoll(
id:
widget.pollId!,
title:
_titleController.text
    .trim(),
description:
_descriptionController
    .text
    .trim(),
startDate:
startDate,
endDate:
endDate,
isActive:
_isActive,
participantType:
_participantType,
questions:
questions,
);
}

// =================================================
// Create
// =================================================

else {
await pollService.createPoll(
title:
_titleController.text
    .trim(),
description:
_descriptionController
    .text
    .trim(),
startDate:
startDate,
endDate:
endDate,
isActive:
_isActive,
participantType:
_participantType,
questions:
questions,
);
}

if (!mounted) {
return;
}

ScaffoldMessenger.of(
context,
)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(
widget.pollId != null
? 'نظرسنجی با موفقیت ویرایش شد.'
    : 'نظرسنجی با موفقیت ایجاد شد.',
textDirection:
TextDirection.rtl,
),
behavior:
SnackBarBehavior.floating,
),
);

Navigator.pop(
context,
true,
);
} catch (e) {
debugPrint(
'SAVE POLL ERROR: $e',
);

if (!mounted) {
return;
}

ScaffoldMessenger.of(
context,
)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(
_errorMessage(e),
textDirection:
TextDirection.rtl,
),
behavior:
SnackBarBehavior.floating,
),
);
} finally {
if (mounted) {
setState(() {
isSaving = false;
});
}
}
}

// =====================================================
// Error Message
// =====================================================

String _errorMessage(
Object error,
) {
final text =
error.toString();

if (text.startsWith(
'Exception: ',
)) {
return text.substring(
11,
);
}

return text;
}

// =====================================================
// Input Decoration
// =====================================================

InputDecoration _inputDecoration({
required String label,
String? hint,
bool alignLabelWithHint = false,
}) {
return InputDecoration(
labelText:
label,
hintText:
hint,
alignLabelWithHint:
alignLabelWithHint,
filled:
true,
fillColor:
fieldColor,
contentPadding:
const EdgeInsets.symmetric(
horizontal: 15,
vertical: 15,
),
border:
OutlineInputBorder(
borderRadius:
BorderRadius.circular(
14,
),
borderSide:
BorderSide(
color:
primaryColor.withOpacity(
0.12,
),
),
),
enabledBorder:
OutlineInputBorder(
borderRadius:
BorderRadius.circular(
14,
),
borderSide:
BorderSide(
color:
primaryColor.withOpacity(
0.12,
),
),
),
focusedBorder:
const OutlineInputBorder(
borderRadius:
BorderRadius.all(
Radius.circular(
14,
),
),
borderSide:
BorderSide(
color:
primaryColor,
width: 1.5,
),
),
);
}

// =====================================================
// Question Card
// =====================================================

Widget _buildQuestionCard(
int index,
_PollQuestionData question,
) {
return Container(
margin:
const EdgeInsets.only(
bottom: 14,
),
padding:
const EdgeInsets.all(
16,
),
decoration:
BoxDecoration(
color:
Colors.white,
borderRadius:
BorderRadius.circular(
18,
),
border:
Border.all(
color:
primaryColor.withOpacity(
0.18,
),
width: 1.2,
),
boxShadow: [
BoxShadow(
color:
Colors.black.withOpacity(
0.08,
),
blurRadius:
12,
spreadRadius:
0,
offset:
const Offset(
0,
4,
),
),
],
),
child:
Column(
crossAxisAlignment:
CrossAxisAlignment.stretch,
children: [
Row(
textDirection:
TextDirection.rtl,
children: [
Container(
width: 40,
height: 40,
decoration:
BoxDecoration(
color:
primaryColor.withOpacity(
0.12,
),
borderRadius:
BorderRadius.circular(
12,
),
),
alignment:
Alignment.center,
child: Text(
toPersianDigits(
'${index + 1}',
),
style:
const TextStyle(
color:
primaryColor,
fontWeight:
FontWeight.bold,
fontSize:
15,
),
),
),
const SizedBox(
width: 10,
),
const Expanded(
child: Text(
'سؤال نظرسنجی',
style:
TextStyle(
fontSize:
15,
fontWeight:
FontWeight.bold,
color:
textColor,
),
),
),
if (_questions.length >
1)
IconButton(
onPressed: () {
_removeQuestion(
index,
);
},
icon:
const Icon(
Icons
    .delete_outline,
color:
Colors.redAccent,
),
),
],
),
const SizedBox(
height: 14,
),
TextField(
controller:
question.controller,
textDirection:
TextDirection.rtl,
maxLines:
3,
decoration:
_inputDecoration(
label:
'متن سؤال',
hint:
'مثلاً آیا با تعمیر آسانسور موافق هستید؟',
alignLabelWithHint:
true,
),
),
const SizedBox(
height: 14,
),
DropdownButtonFormField<String>(
value:
question.type,
decoration:
_inputDecoration(
label:
'نوع سؤال',
),
dropdownColor:
Colors.white,
icon:
const Icon(
Icons
    .keyboard_arrow_down,
color:
primaryColor,
),
items: const [
DropdownMenuItem(
value:
'yesno',
child:
Text(
'بله / خیر',
),
),
DropdownMenuItem(
value:
'single',
child:
Text(
'انتخاب یک گزینه',
),
),
DropdownMenuItem(
value:
'multi',
child:
Text(
'انتخاب چند گزینه',
),
),
],
onChanged:
(value) {
if (value == null) {
return;
}

setState(() {
question.type =
value;

if (value ==
'single' ||
value ==
'multi') {
if (question
    .choices
    .length <
2) {
while (question
    .choices
    .length <
2) {
question.choices
    .add(
'',
);
}
}
}
});
},
),
if (question.type ==
'single' ||
question.type ==
'multi') ...[
const SizedBox(
height: 16,
),
Container(
padding:
const EdgeInsets.all(
12,
),
decoration:
BoxDecoration(
color:
primaryColor.withOpacity(
0.045,
),
borderRadius:
BorderRadius.circular(
14,
),
border:
Border.all(
color:
primaryColor.withOpacity(
0.10,
),
),
),
child:
Column(
crossAxisAlignment:
CrossAxisAlignment
    .stretch,
children: [
const Text(
'گزینه‌ها',
textAlign:
TextAlign.right,
style:
TextStyle(
fontSize:
13,
fontWeight:
FontWeight.bold,
color:
textColor,
),
),
const SizedBox(
height: 10,
),
for (int i = 0;
i <
question
    .choices
    .length;
i++)
Padding(
padding:
const EdgeInsets.only(
bottom: 8,
),
child:
Row(
textDirection:
TextDirection.rtl,
children: [
Expanded(
child:
TextFormField(
key:
ValueKey(
'choice_${question.hashCode}_$i',
),
initialValue:
question
    .choices[i],
textDirection:
TextDirection.rtl,
decoration:
_inputDecoration(
label:
'گزینه ${toPersianDigits((i + 1).toString())}',
),
onChanged:
(value) {
question
    .choices[i] =
value;
},
),
),
if (question
    .choices
    .length >
2)
IconButton(
onPressed:
() {
_removeChoice(
question,
i,
);
},
icon:
const Icon(
Icons
    .remove_circle_outline,
color:
Colors.redAccent,
),
),
],
),
),
const SizedBox(
height: 3,
),
OutlinedButton.icon(
onPressed:
() {
_addChoice(
question,
);
},
icon:
const Icon(
Icons.add,
size:
19,
),
label:
const Text(
'افزودن گزینه',
),
style:
OutlinedButton.styleFrom(
foregroundColor:
primaryColor,
side:
const BorderSide(
color:
primaryColor,
),
backgroundColor:
Colors.white,
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(
13,
),
),
),
),
],
),
),
],
],
),
);
}

// =====================================================
// Date Field
// =====================================================

Widget _buildDateField({
required String title,
required DateTime? value,
required VoidCallback onTap,
}) {
return Expanded(
child:
InkWell(
onTap:
onTap,
borderRadius:
BorderRadius.circular(
15,
),
child:
Container(
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
15,
),
border:
Border.all(
color:
primaryColor.withOpacity(
0.16,
),
width:
1.1,
),
boxShadow: [
BoxShadow(
color:
Colors.black.withOpacity(
0.05,
),
blurRadius:
8,
offset:
const Offset(
0,
3,
),
),
],
),
child:
Column(
crossAxisAlignment:
CrossAxisAlignment.stretch,
children: [
Row(
textDirection:
TextDirection.rtl,
children: [
const Icon(
Icons
    .calendar_month_outlined,
color:
primaryColor,
size:
19,
),
const SizedBox(
width:
6,
),
Text(
title,
style:
const TextStyle(
fontSize:
11,
color:
Colors.grey,
),
),
],
),
const SizedBox(
height:
8,
),
Text(
_formatJalaliDate(
value,
),
textAlign:
TextAlign.center,
style:
TextStyle(
fontSize:
14,
fontWeight:
FontWeight.bold,
color:
value == null
? Colors.grey
    : textColor,
),
),
],
),
),
),
);
}

// =====================================================
// Build
// =====================================================

@override
Widget build(
BuildContext context,
) {
final bool isEdit =
widget.pollId != null;

return Directionality(
textDirection:
TextDirection.rtl,
child:
Scaffold(
backgroundColor:
backgroundColor,
appBar:
AppBar(
backgroundColor:
primaryColor,
foregroundColor:
Colors.white,
elevation:
0,
centerTitle:
true,
title:
Text(
isEdit
? 'ویرایش نظرسنجی'
    : 'ثبت نظرسنجی جدید',
style:
const TextStyle(
fontSize:
18,
fontWeight:
FontWeight.bold,
),
),
),
body:
isLoading
? const Center(
child:
CircularProgressIndicator(
color:
primaryColor,
),
)
    : SafeArea(
child:
SingleChildScrollView(
padding:
const EdgeInsets.fromLTRB(
18,
14,
18,
30,
),
child:
Column(
crossAxisAlignment:
CrossAxisAlignment
    .stretch,
children: [
// ===================================
// Header Card
// ===================================

Container(
padding:
const EdgeInsets
    .all(
18,
),
decoration:
BoxDecoration(
color:
Colors.white,
borderRadius:
BorderRadius
    .circular(
18,
),
border:
Border.all(
color:
primaryColor
    .withOpacity(
0.15,
),
width:
1.2,
),
boxShadow: [
BoxShadow(
color:
Colors.black
    .withOpacity(
0.08,
),
blurRadius:
12,
offset:
const Offset(
0,
4,
),
),
],
),
child:
Row(
textDirection:
TextDirection.rtl,
children: [
Container(
width:
50,
height:
50,
decoration:
BoxDecoration(
color:
primaryColor,
borderRadius:
BorderRadius
    .circular(
15,
),
),
child:
const Icon(
Icons
    .poll_outlined,
color:
Colors.white,
size:
27,
),
),
const SizedBox(
width:
12,
),
Expanded(
child:
Text(
isEdit
? 'ویرایش اطلاعات نظرسنجی'
    : 'ایجاد یک نظرسنجی جدید برای ساکنین',
style:
const TextStyle(
fontSize:
15,
fontWeight:
FontWeight.bold,
color:
textColor,
),
),
),
],
),
),

const SizedBox(
height:
16,
),

// ===================================
// Title
// ===================================

Container(
padding:
const EdgeInsets
    .all(
14,
),
decoration:
BoxDecoration(
color:
Colors.white,
borderRadius:
BorderRadius
    .circular(
18,
),
border:
Border.all(
color:
primaryColor
    .withOpacity(
0.12,
),
),
boxShadow: [
BoxShadow(
color:
Colors.black
    .withOpacity(
0.05,
),
blurRadius:
10,
offset:
const Offset(
0,
3,
),
),
],
),
child:
TextField(
controller:
_titleController,
textDirection:
TextDirection.rtl,
decoration:
_inputDecoration(
label:
'عنوان نظرسنجی',
hint:
'مثلاً نظرسنجی تعمیر آسانسور',
),
),
),

const SizedBox(
height:
12,
),

// ===================================
// Description
// ===================================

Container(
padding:
const EdgeInsets
    .all(
14,
),
decoration:
BoxDecoration(
color:
Colors.white,
borderRadius:
BorderRadius
    .circular(
18,
),
border:
Border.all(
color:
primaryColor
    .withOpacity(
0.12,
),
),
boxShadow: [
BoxShadow(
color:
Colors.black
    .withOpacity(
0.05,
),
blurRadius:
10,
offset:
const Offset(
0,
3,
),
),
],
),
child:
TextField(
controller:
_descriptionController,
textDirection:
TextDirection.rtl,
maxLines:
3,
decoration:
_inputDecoration(
label:
'توضیحات',
hint:
'توضیحات تکمیلی نظرسنجی',
alignLabelWithHint:
true,
),
),
),

const SizedBox(
height:
12,
),

// ===================================
// Participant Type
// ===================================

_buildParticipantTypeCard(),

const SizedBox(
height:
12,
),

// ===================================
// Dates
// ===================================

Row(
textDirection:
TextDirection.rtl,
children: [
_buildDateField(
title:
'تاریخ شروع',
value:
_startDate,
onTap:
_selectStartDate,
),
const SizedBox(
width:
10,
),
_buildDateField(
title:
'تاریخ پایان',
value:
_endDate,
onTap:
_selectEndDate,
),
],
),

const SizedBox(
height:
12,
),

// ===================================
// Active
// ===================================

Container(
padding:
const EdgeInsets
    .symmetric(
horizontal:
14,
vertical:
4,
),
decoration:
BoxDecoration(
color:
Colors.white,
borderRadius:
BorderRadius
    .circular(
18,
),
border:
Border.all(
color:
primaryColor
    .withOpacity(
0.12,
),
),
boxShadow: [
BoxShadow(
color:
Colors.black
    .withOpacity(
0.05,
),
blurRadius:
10,
offset:
const Offset(
0,
3,
),
),
],
),
child:
SwitchListTile(
contentPadding:
EdgeInsets.zero,
title:
const Text(
'فعال بودن نظرسنجی',
style:
TextStyle(
fontSize:
14,
fontWeight:
FontWeight.w600,
color:
textColor,
),
),
subtitle:
Text(
_isActive
? 'افراد مجاز می‌توانند در نظرسنجی شرکت کنند.'
    : 'نظرسنجی برای شرکت‌کنندگان غیرفعال است.',
style:
const TextStyle(
fontSize:
11,
color:
Colors.grey,
),
),
value:
_isActive,
activeColor:
primaryColor,
onChanged:
(value) {
setState(() {
_isActive =
value;
});
},
),
),

const SizedBox(
height:
20,
),

// ===================================
// Questions Header
// ===================================

Row(
textDirection:
TextDirection.rtl,
children: [
const Expanded(
child:
Text(
'سؤالات',
style:
TextStyle(
fontSize:
17,
fontWeight:
FontWeight.bold,
color:
textColor,
),
),
),
OutlinedButton
    .icon(
onPressed:
_addQuestion,
icon:
const Icon(
Icons.add,
size:
19,
),
label:
const Text(
'سؤال جدید',
),
style:
OutlinedButton
    .styleFrom(
foregroundColor:
primaryColor,
backgroundColor:
Colors.white,
side:
const BorderSide(
color:
primaryColor,
),
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius
    .circular(
13,
),
),
),
),
],
),

const SizedBox(
height:
12,
),

// ===================================
// Questions
// ===================================

for (int i = 0;
i <
_questions
    .length;
i++)
_buildQuestionCard(
i,
_questions[i],
),

const SizedBox(
height:
8,
),

// ===================================
// Save
// ===================================

SizedBox(
height:
54,
child:
ElevatedButton.icon(
onPressed:
isSaving
? null
    : _savePoll,
icon:
isSaving
? const SizedBox(
width:
21,
height:
21,
child:
CircularProgressIndicator(
strokeWidth:
2.3,
color:
Colors.white,
),
)
    : Icon(
isEdit
? Icons
    .save_outlined
    : Icons
    .add_circle_outline,
size:
22,
),
label:
Text(
isSaving
? 'در حال ذخیره...'
    : isEdit
? 'ذخیره تغییرات'
    : 'ثبت نظرسنجی',
style:
const TextStyle(
fontSize:
14,
fontWeight:
FontWeight.bold,
),
),
style:
ElevatedButton
    .styleFrom(
backgroundColor:
primaryColor,
foregroundColor:
Colors.white,
disabledBackgroundColor:
primaryColor
    .withOpacity(
0.55,
),
elevation:
2,
shadowColor:
primaryColor
    .withOpacity(
0.30,
),
shape:
RoundedRectangleBorder(
borderRadius:
BorderRadius
    .circular(
17,
),
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
}

// =====================================================
// Poll Question Data
// =====================================================

class _PollQuestionData {
final TextEditingController controller;

String type;

final List<String> choices;

_PollQuestionData({
String question = '',
this.type = 'yesno',
List<String>? choices,
})  : controller =
TextEditingController(
text: question,
),
choices =
choices ??
<String>[];

void dispose() {
controller.dispose();
}
}
