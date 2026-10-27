
import 'package:flutter/material.dart';

import '../../services/manager_civil_charge_list_service.dart';
import 'manager_civil_charge_units_list_screen.dart';

String _faDigits(dynamic value) {
const english = '0123456789';
const arabic = '٠١٢٣٤٥٦٧٨٩';
const persian = '۰۱۲۳۴۵۶۷۸۹';

return value.toString().replaceAllMapped(
RegExp(r'[0-9٠-٩]'),
(match) {
final digit = match.group(0)!;
final index = english.indexOf(digit);

if (index >= 0) return persian[index];

final arabicIndex = arabic.indexOf(digit);
return arabicIndex >= 0 ? persian[arabicIndex] : digit;
},
);
}

class ManagerCivilChargesListScreen extends StatefulWidget {
const ManagerCivilChargesListScreen({super.key});

@override
State<ManagerCivilChargesListScreen> createState() =>
_ManagerCivilChargesListScreenState();
}

class _ManagerCivilChargesListScreenState
extends State<ManagerCivilChargesListScreen> {
static const Color _teal = Color(0xFF00ACC1);
static const Color _purple = Color(0xFF610DB5);

// final ApiService _apiService = ApiService();
final ManagerCivilChargeListService _civilService =
ManagerCivilChargeListService();

List<Map<String, dynamic>> _charges = [];
bool _loading = true;
String? _error;

@override
void initState() {
super.initState();
_loadCharges();
}

  Future<void> _loadCharges() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final result = await _civilService.getCharges();

      if (!mounted) return;

      setState(() {
        _charges = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  int _number(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = value?.toString().trim() ?? '';
    return int.tryParse(text.replaceAll(',', '')) ?? 0;
  }

String _money(dynamic value) {
final number = _number(value);
final digits = number.toString();
final buffer = StringBuffer();

for (var i = 0; i < digits.length; i++) {
buffer.write(digits[i]);

final remaining = digits.length - i - 1;
if (remaining > 0 && remaining % 3 == 0) {
buffer.write(',');
}
}

return _faDigits(buffer.toString());
}

String _date(dynamic value) {
if (value == null || value.toString().trim().isEmpty) {
return 'ثبت نشده';
}

try {
final raw = value.toString().trim().split('T').first;
final parts = raw.split('-');

if (parts.length != 3) return _faDigits(raw);

final year = int.parse(parts[0]);
final month = int.parse(parts[1]);
final day = int.parse(parts[2]);

if (year >= 1900 && year <= 2200) {
final date = DateTime(year, month, day);
final gregorian = date;
final jalaliYear = _gregorianToJalaliYear(
gregorian.year,
gregorian.month,
gregorian.day,
);

return _faDigits(
'${jalaliYear[0]}/${jalaliYear[1].toString().padLeft(2, '0')}/'
'${jalaliYear[2].toString().padLeft(2, '0')}',
);
}

return _faDigits(
'${year.toString().padLeft(4, '0')}/'
'${month.toString().padLeft(2, '0')}/'
'${day.toString().padLeft(2, '0')}',
);
} catch (_) {
return _faDigits(value);
}
}

List<int> _gregorianToJalaliYear(int gy, int gm, int gd) {
// الگوریتم تبدیل تاریخ میلادی به شمسی
const gDaysInMonth = [
31, 28, 31, 30, 31, 30,
31, 31, 30, 31, 30, 31,
];
const jDaysInMonth = [
31, 31, 31, 31, 31, 31,
30, 30, 30, 30, 30, 29,
];

var year = gy - 1600;
var month = gm - 1;
var day = gd - 1;

var gDayNo = 365 * year +
(year + 3) ~/ 4 -
(year + 99) ~/ 100 +
(year + 399) ~/ 400;

for (var i = 0; i < month; i++) {
gDayNo += gDaysInMonth[i];
}

if (month > 1 &&
((gy % 4 == 0 && gy % 100 != 0) || gy % 400 == 0)) {
gDayNo++;
}

gDayNo += day;

var jDayNo = gDayNo - 79;
final jNp = jDayNo ~/ 12053;
jDayNo %= 12053;

var jy = 979 + 33 * jNp + 4 * (jDayNo ~/ 1461);
jDayNo %= 1461;

if (jDayNo >= 366) {
jy += (jDayNo - 1) ~/ 365;
jDayNo = (jDayNo - 1) % 365;
}

var jm = 0;
while (jm < 11 && jDayNo >= jDaysInMonth[jm]) {
jDayNo -= jDaysInMonth[jm];
jm++;
}

return [jy, jm + 1, jDayNo + 1];
}

Future<void> _openUnits(Map<String, dynamic> charge) async {
  final id = _number(charge['id']);
  if (id <= 0) return;

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ManagerCivilChargeUnitsListScreen(
        civilId: id,
        civilName: (charge['name'] ?? 'شارژ عمرانی').toString(),
      ),
    ),
  );

  if (mounted) {
    await _loadCharges();
  }
}

void _showDetails(Map<String, dynamic> charge) {
  final rawDocuments =
      charge['documents'] ?? charge['civil_documents'];

  final List<Map<String, dynamic>> documents = rawDocuments is List
      ? rawDocuments
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList()
      : [];

showModalBottomSheet<void>(
context: context,
isScrollControlled: true,
useSafeArea: true,
builder: (sheetContext) {
return Directionality(
textDirection: TextDirection.rtl,
child: Padding(
padding: const EdgeInsets.all(20),
child: SingleChildScrollView(
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
mainAxisSize: MainAxisSize.min,
children: [
const Text(
'جزئیات شارژ عمرانی',
style: TextStyle(
fontSize: 19,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 20),
_detailRow('عنوان', charge['name'] ?? '-'),
_detailRow(
'مبلغ شارژ',
'${_money(charge['amount'])} تومان',
),
_detailRow(
'پیش‌پرداخت',
'${_money(charge['prepayment'] ?? 0)} تومان',
),
_detailRow(
'تعداد اقساط',
_faDigits(charge['installment_count'] ?? 0),
),
_detailRow(
'اولین سررسید',
_date(charge['first_due_date']),
),
_detailRow(
'تعداد واحدهای ارسالی',
_faDigits(
charge['sent_units_count'] ??
charge['unit_count'] ??
0,
),
),
_detailRow(
'توضیحات',
(charge['details'] ?? '').toString().isEmpty
? 'ندارد'
    : charge['details'],
),
const Divider(height: 28),
const Text(
'مدارک ثبت‌شده',
style: TextStyle(fontWeight: FontWeight.bold),
),
const SizedBox(height: 8),
if (documents.isEmpty)
const Text('مدرکی ثبت نشده است.')
else
...documents.map((document) {
final name = document['name'] ??
document['filename'] ??
document['document'] ??
'مدرک پیوست‌شده';

return ListTile(
contentPadding: EdgeInsets.zero,
leading: const Icon(
Icons.attach_file,
color: _purple,
),
title: Text(
_faDigits(name.toString().split('/').last),
maxLines: 2,
overflow: TextOverflow.ellipsis,
),
);
}),
const SizedBox(height: 12),
FilledButton(
onPressed: () => Navigator.pop(sheetContext),
child: const Text('بستن'),
),
],
),
),
),
);
},
);
}

Widget _detailRow(String title, dynamic value) {
return Padding(
padding: const EdgeInsets.symmetric(vertical: 7),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
SizedBox(
width: 125,
child: Text(
title,
style: const TextStyle(color: Colors.black54),
),
),
Expanded(
child: Text(
_faDigits(value),
style: const TextStyle(fontWeight: FontWeight.w500),
),
),
],
),
);
}

Widget _buildCard(Map<String, dynamic> charge) {
final name = (charge['name'] ?? 'شارژ عمرانی').toString();
final sentCount = _number(
charge['sent_units_count'] ?? charge['unit_count'] ?? 0,
);

return Card(
margin: const EdgeInsets.only(bottom: 12),
elevation: 2,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
child: Padding(
padding: const EdgeInsets.all(14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Row(
children: [
const CircleAvatar(
backgroundColor: Color(0xFFE0F7FA),
child: Icon(
Icons.construction,
color: _teal,
),
),
const SizedBox(width: 10),
Expanded(
child: Text(
_faDigits(name),
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 16,
),
),
),
  PopupMenuButton<String>(
    tooltip: 'عملیات',
    onSelected: (action) {
      if (action == 'units') {
        _openUnits(charge);
      } else if (action == 'details') {
        _showDetails(charge);
      }
    },
    itemBuilder: (_) => const [
      PopupMenuItem<String>(
        value: 'units',
        child: Row(
          children: [
            Icon(
              Icons.apartment_outlined,
              color: _teal,
            ),
            SizedBox(width: 10),
            Text('مشاهده واحدها و اقساط'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'details',
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: _purple,
            ),
            SizedBox(width: 10),
            Text('جزئیات شارژ'),
          ],
        ),
      ),
    ],
  )
],
),
const Divider(height: 24),
_detailRow(
'مبلغ شارژ عمرانی',
'${_money(charge['amount'])} تومان',
),
_detailRow(
'اولین سررسید',
_date(charge['first_due_date']),
),
const SizedBox(height: 12),
Container(
padding: const EdgeInsets.symmetric(
horizontal: 12,
vertical: 12,
),
decoration: BoxDecoration(
color: const Color(0xFFE0F7FA),
borderRadius: BorderRadius.circular(12),
),
child: Row(
children: [
Icon(
sentCount > 0
? Icons.mark_email_read_outlined
    : Icons.mark_email_unread_outlined,
size: 20,
color: sentCount > 0 ? Colors.green : Colors.grey,
),
const SizedBox(width: 8),
const Expanded(
child: Text(
'تعداد واحدهای ارسالی',
style: TextStyle(
color: Color(0xFF006064),
fontWeight: FontWeight.w600,
),
),
),
Text(
_faDigits(sentCount),
style: const TextStyle(
color: Color(0xFF006064),
fontSize: 17,
fontWeight: FontWeight.bold,
),
),
],
),
),
],
),
),
);
}

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
appBar: AppBar(
title: const Text('شارژهای عمرانی'),
backgroundColor: _teal,
foregroundColor: Colors.white,
actions: [
IconButton(
tooltip: 'به‌روزرسانی',
onPressed: _loadCharges,
icon: const Icon(Icons.refresh),
),
],
),
body: _loading
? const Center(child: CircularProgressIndicator())
    : _error != null && _charges.isEmpty
? Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.error_outline,
color: Colors.red,
size: 48,
),
const SizedBox(height: 12),
Text(
_faDigits(_error!),
textAlign: TextAlign.center,
),
const SizedBox(height: 16),
FilledButton.icon(
onPressed: _loadCharges,
icon: const Icon(Icons.refresh),
label: const Text('تلاش مجدد'),
),
],
),
),
)
    : _charges.isEmpty
? RefreshIndicator(
onRefresh: _loadCharges,
child: ListView(
physics: const AlwaysScrollableScrollPhysics(),
children: const [
SizedBox(height: 140),
Icon(
Icons.receipt_long_outlined,
size: 58,
color: Colors.grey,
),
SizedBox(height: 12),
Center(
child: Text('شارژ عمرانی‌ای پیدا نشد.'),
),
],
),
)
    : RefreshIndicator(
onRefresh: _loadCharges,
child: ListView.builder(
padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
itemCount: _charges.length,
itemBuilder: (context, index) =>
_buildCard(_charges[index]),
),
),
),
);
}
}
