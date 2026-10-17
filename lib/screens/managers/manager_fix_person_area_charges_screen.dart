
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_fix_person_area_charge_service.dart';
import 'manager_fix_person_area_charge_units_screen.dart';

const Color _primaryColor = Color(0xFF00ACC1);
const Color _purpleColor = Color(0xFF610DB5);

// ============================================================
// توابع کمکی
// ============================================================

String _faDigits(String value) {
const english = '0123456789';
const persian = '۰۱۲۳۴۵۶۷۸۹';

return value.split('').map((char) {
final index = english.indexOf(char);
return index < 0 ? char : persian[index];
}).join();
}

String _enDigits(String value) {
const persian = '۰۱۲۳۴۵۶۷۸۹';
const arabic = '٠١٢٣٤٥٦٧٨٩';

for (int i = 0; i < 10; i++) {
value = value.replaceAll(persian[i], '$i');
value = value.replaceAll(arabic[i], '$i');
}

return value.trim();
}

String _formatMoney(dynamic value) {
final raw = _enDigits('$value')
    .replaceAll(',', '')
    .replaceAll('٬', '');

final number = num.tryParse(raw) ?? 0;
final digits = number.toInt().toString();
final buffer = StringBuffer();

for (int i = 0; i < digits.length; i++) {
buffer.write(digits[i]);

final remaining = digits.length - i - 1;
if (remaining > 0 && remaining % 3 == 0) {
buffer.write(',');
}
}

return _faDigits(buffer.toString());
}

String _formatArea(dynamic value) {
if (value == null || '$value'.trim().isEmpty) return '—';

final normalized = _enDigits('$value')
    .replaceAll(',', '')
    .replaceAll('٬', '');

final number = num.tryParse(normalized);
if (number == null) return '$value';

return _faDigits(
number.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), ''),
);
}

int _jalaliDaysInMonth(int year, int month) {
if (month >= 1 && month <= 6) return 31;
if (month >= 7 && month <= 11) return 30;
return Jalali(year, 12, 1).isLeapYear() ? 30 : 29;
}

Jalali? _parseJalali(String value) {
final text = _enDigits(value.trim());
if (text.isEmpty) return null;

try {
final match = RegExp(
r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$',
).firstMatch(text);

if (match != null) {
final year = int.parse(match.group(1)!);
final month = int.parse(match.group(2)!);
final day = int.parse(match.group(3)!);

if (year >= 1200 && year <= 1600) {
if (month < 1 ||
month > 12 ||
day < 1 ||
day > _jalaliDaysInMonth(year, month)) {
return null;
}

return Jalali(year, month, day);
}

if (year >= 1900 && year <= 2200) {
final date = DateTime(year, month, day);

if (date.year != year ||
date.month != month ||
date.day != day) {
return null;
}

return Jalali.fromDateTime(date);
}
}

final date = DateTime.tryParse(text);
if (date != null) return Jalali.fromDateTime(date);
} catch (_) {
return null;
}

return null;
}

String _jalaliString(dynamic value) {
if (value == null || '$value'.trim().isEmpty) return '—';

final date = value is Jalali ? value : _parseJalali('$value');
if (date == null) return '—';

return _faDigits(
'${date.year}/'
'${date.month.toString().padLeft(2, '0')}/'
'${date.day.toString().padLeft(2, '0')}',
);
}

String _value(
Map<String, dynamic> item,
List<String> keys, {
String fallback = '',
}) {
for (final key in keys) {
final value = item[key];
if (value != null && '$value'.trim().isNotEmpty) return '$value';
}

return fallback;
}

int _intValue(Map<String, dynamic> item, List<String> keys) {
for (final key in keys) {
final value = item[key];

if (value is num) return value.toInt();

if (value != null) {
final parsed = int.tryParse(
_enDigits('$value').replaceAll(',', ''),
);
if (parsed != null) return parsed;
}
}

return 0;
}

int? _readCount(Map<String, dynamic> data, List<String> keys) {
for (final key in keys) {
final value = data[key];
if (value == null) continue;

if (value is List) return value.length;

final parsed = int.tryParse(
_enDigits('$value').replaceAll(',', ''),
);

if (parsed != null && parsed >= 0) return parsed;
}

return null;
}

// ============================================================
// صفحه فهرست شارژ ثابت + متراژی + نفری
// ============================================================

class ManagerFixPersonAreaChargesScreen extends StatefulWidget {
const ManagerFixPersonAreaChargesScreen({super.key});

@override
State<ManagerFixPersonAreaChargesScreen> createState() =>
_ManagerFixPersonAreaChargesScreenState();
}

class _ManagerFixPersonAreaChargesScreenState
extends State<ManagerFixPersonAreaChargesScreen> {
final ManagerFixPersonAreaChargeService _service =
ManagerFixPersonAreaChargeService();

List<Map<String, dynamic>> _charges = [];

bool _loading = true;
bool _loadError = false;

@override
void initState() {
super.initState();
_loadCharges();
}

Future<void> _loadCharges() async {
if (!mounted) return;

setState(() {
_loading = true;
_loadError = false;
});

try {
final result = await _service.getCharges();

if (!mounted) return;

setState(() {
_charges = result
    .map((item) => Map<String, dynamic>.from(item))
    .toList();
_loading = false;
});
} catch (e) {
if (!mounted) return;

setState(() {
_loading = false;
_loadError = true;
});

_showMessage('دریافت فهرست شارژها ناموفق بود: $e');
}
}

void _showMessage(String message) {
if (!mounted) return;

ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(message),
behavior: SnackBarBehavior.floating,
),
);
}

bool _notificationSent(Map<String, dynamic> charge) {
if (charge['send_notification'] == true ||
charge['notification_sent'] == true) {
return true;
}

return (_readCount(charge, [
'notified_units_count',
'sent_units_count',
'notification_sent_count',
'sent_count',
]) ??
0) > 0;
}

bool _canEdit(Map<String, dynamic> charge) {
return charge['can_edit'] != false &&
charge['can_delete'] != false &&
!_notificationSent(charge);
}

bool _canDelete(Map<String, dynamic> charge) {
return charge['can_delete'] != false &&
!_notificationSent(charge);
}

int? _sentUnitsCount(Map<String, dynamic> charge) {
return _readCount(charge, [
'notified_units_count',
'sent_units_count',
'units_sent_count',
'notification_sent_count',
'sent_count',
]);
}

int? _totalUnitsCount(Map<String, dynamic> charge) {
return _readCount(charge, [
'unit_count',
'units_count',
'total_units_count',
'total_units',
'all_units_count',
]);
}

Widget _infoRow(
IconData icon,
String label,
String value, {
Color? valueColor,
}) {
return Row(
children: [
Icon(icon, size: 19, color: _primaryColor),
const SizedBox(width: 8),
Expanded(
child: Text(
label,
style: TextStyle(
color: Colors.grey.shade700,
fontSize: 13,
),
),
),
const SizedBox(width: 8),
Flexible(
child: Text(
value,
textAlign: TextAlign.left,
style: TextStyle(
fontWeight: FontWeight.w600,
color: valueColor,
),
),
),
],
);
}

Future<void> _openUnits(Map<String, dynamic> charge) async {
final id = _intValue(charge, ['id', 'pk']);

if (id <= 0) {
_showMessage('شناسه شارژ معتبر نیست.');
return;
}

await Navigator.push(
context,
MaterialPageRoute(
builder: (_) => ManagerFixPersonAreaChargeUnitsScreen(
charge: Map<String, dynamic>.from(charge),
service: _service,
),
),
);

if (mounted) await _loadCharges();
}

Future<void> _showChargeForm({
Map<String, dynamic>? charge,
}) async {
if (charge != null && !_canEdit(charge)) {
_showMessage(
'به دلیل ارسال اعلان یا ثبت پرداخت، امکان ویرایش این شارژ وجود ندارد.',
);
return;
}

final saved = await showModalBottomSheet<bool>(
context: context,
isScrollControlled: true,
useSafeArea: true,
backgroundColor: Colors.transparent,
builder: (_) => _FixPersonAreaChargeFormSheet(
charge: charge,
service: _service,
),
);

if (saved == true && mounted) await _loadCharges();
}

Future<void> _deleteCharge(Map<String, dynamic> charge) async {
final id = _intValue(charge, ['id', 'pk']);

if (id <= 0) {
_showMessage('شناسه شارژ معتبر نیست.');
return;
}

if (!_canDelete(charge)) {
_showMessage(
'این شارژ به دلیل ارسال اعلان یا ثبت پرداخت قابل حذف نیست.',
);
return;
}

final name = _value(
charge,
['name', 'title'],
fallback: 'شارژ واحدی متراژی نفری',
);

final confirmed = await showDialog<bool>(
context: context,
builder: (dialogContext) => Directionality(
textDirection: TextDirection.rtl,
child: AlertDialog(
title: const Text('حذف شارژ'),
content: Text('آیا از حذف شارژ «$name» مطمئن هستید؟'),
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext, false),
child: const Text('انصراف'),
),
FilledButton(
style: FilledButton.styleFrom(
backgroundColor: Colors.red,
),
onPressed: () => Navigator.pop(dialogContext, true),
child: const Text('حذف'),
),
],
),
),
);

if (confirmed != true || !mounted) return;

try {
await _service.deleteCharge(id);
if (!mounted) return;

_showMessage('شارژ با موفقیت حذف شد.');
await _loadCharges();
} catch (e) {
_showMessage('حذف شارژ انجام نشد: $e');
}
}

void _showDetails(Map<String, dynamic> charge) {
final name = _value(
charge,
['name', 'title'],
fallback: 'شارژ واحدی متراژی نفری',
);

final fixAmount = _formatMoney(charge['fix_charge_amount'] ?? 0);
final areaAmount = _formatMoney(charge['area_amount'] ?? 0);
final personAmount = _formatMoney(charge['person_amount'] ?? 0);
final otherCost = _formatMoney(charge['other_cost_amount'] ?? 0);
final penalty = _formatMoney(charge['payment_penalty_amount'] ?? 0);

final totalArea = charge['total_area'];
final totalPeople = _readCount(charge, ['total_people']);
final sentCount = _sentUnitsCount(charge);
final totalCount = _totalUnitsCount(charge);

final details = _value(charge, ['details', 'description']).trim();

showDialog<void>(
context: context,
builder: (dialogContext) => Directionality(
textDirection: TextDirection.rtl,
child: AlertDialog(
title: const Row(
children: [
Icon(Icons.receipt_long, color: _primaryColor),
SizedBox(width: 10),
Expanded(child: Text('جزئیات شارژ')),
],
),
content: SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Text(
name,
style: const TextStyle(
fontSize: 17,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 18),
_infoRow(
Icons.apartment,
'مبلغ ثابت هر واحد',
'$fixAmount تومان',
),
const SizedBox(height: 12),
_infoRow(
Icons.square_foot,
'مبلغ هر متر مربع',
'$areaAmount تومان',
),
const SizedBox(height: 12),
_infoRow(
Icons.people_alt_outlined,
'مبلغ هر نفر',
'$personAmount تومان',
),
const SizedBox(height: 12),
_infoRow(
Icons.area_chart_outlined,
'مجموع متراژ',
totalArea == null
? 'ثبت نشده'
    : '${_formatArea(totalArea)} متر مربع',
),
const SizedBox(height: 12),
_infoRow(
Icons.groups_outlined,
'مجموع نفرات',
totalPeople == null ? 'ثبت نشده' : _faDigits('$totalPeople'),
),
const SizedBox(height: 12),
_infoRow(
Icons.add_card_outlined,
'هزینه متفرقه هر واحد',
'$otherCost تومان',
),
const SizedBox(height: 12),
_infoRow(
Icons.percent,
'جریمه دیرکرد',
'$penalty',
),
const SizedBox(height: 12),
_infoRow(
Icons.calendar_month_outlined,
'مهلت پرداخت',
_jalaliString(charge['payment_deadline']),
),
const SizedBox(height: 12),
_infoRow(
Icons.send_outlined,
'واحدهای اعلام‌شده',
sentCount != null && totalCount != null
? '${_faDigits('$sentCount')} از ${_faDigits('$totalCount')} واحد'
    : 'اطلاعات کامل نیست',
),
const SizedBox(height: 16),
const Align(
alignment: Alignment.centerRight,
child: Text(
'توضیحات',
style: TextStyle(fontWeight: FontWeight.bold),
),
),
const SizedBox(height: 6),
Container(
width: double.infinity,
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.grey.shade100,
borderRadius: BorderRadius.circular(12),
),
child: Text(
details.isEmpty ? 'توضیحاتی ثبت نشده است.' : details,
),
),
],
),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext),
child: const Text('بستن'),
),
],
),
),
);
}

Widget _buildChargeCard(Map<String, dynamic> charge) {
final name = _value(
charge,
['name', 'title'],
fallback: 'شارژ واحدی متراژی نفری',
);

final fixAmount = _formatMoney(charge['fix_charge_amount'] ?? 0);
final areaAmount = _formatMoney(charge['area_amount'] ?? 0);
final personAmount = _formatMoney(charge['person_amount'] ?? 0);
final otherCost = _formatMoney(charge['other_cost_amount'] ?? 0);

final sentCount = _sentUnitsCount(charge);
final totalCount = _totalUnitsCount(charge);
final totalPeople = _readCount(charge, ['total_people']);
final totalArea = charge['total_area'];

final notified = _notificationSent(charge);
final canEdit = _canEdit(charge);
final canDelete = _canDelete(charge);

return Card(
margin: const EdgeInsets.only(bottom: 12),
elevation: 1,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
),
child: Padding(
padding: const EdgeInsets.all(14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
width: 46,
height: 46,
decoration: BoxDecoration(
color: _purpleColor.withValues(alpha: 0.09),
borderRadius: BorderRadius.circular(13),
),
child: const Icon(
Icons.apartment,
color: _purpleColor,
size: 25,
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
name,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 6),
Text(
'ثابت هر واحد: $fixAmount تومان',
style: const TextStyle(
fontSize: 13,
fontWeight: FontWeight.w600,
color: _purpleColor,
),
),
const SizedBox(height: 4),
Text(
'هر متر: $areaAmount تومان | هر نفر: $personAmount تومان',
style: TextStyle(
color: Colors.grey.shade700,
fontSize: 12,
),
),
],
),
),
PopupMenuButton<String>(
tooltip: 'عملیات شارژ',
onSelected: (value) {
switch (value) {
case 'units':
_openUnits(charge);
break;
case 'details':
_showDetails(charge);
break;
case 'edit':
_showChargeForm(charge: charge);
break;
case 'delete':
_deleteCharge(charge);
break;
}
},
itemBuilder: (_) => [
const PopupMenuItem(
value: 'units',
child: Row(
children: [
Icon(Icons.send_outlined, color: _primaryColor),
SizedBox(width: 10),
Text('ارسال اطلاعیه شارژ'),
],
),
),
const PopupMenuItem(
value: 'details',
child: Row(
children: [
Icon(Icons.info_outline, color: _purpleColor),
SizedBox(width: 10),
Text('مشاهده جزئیات'),
],
),
),
if (canEdit)
const PopupMenuItem(
value: 'edit',
child: Row(
children: [
Icon(Icons.edit_outlined, color: Colors.blue),
SizedBox(width: 10),
Text('ویرایش شارژ'),
],
),
),
if (canDelete)
const PopupMenuItem(
value: 'delete',
child: Row(
children: [
Icon(Icons.delete_outline, color: Colors.red),
SizedBox(width: 10),
Text('حذف شارژ'),
],
),
),
],
),
],
),
const SizedBox(height: 12),
const Divider(height: 1),
const SizedBox(height: 12),
_infoRow(
Icons.square_foot,
'مبلغ هر متر مربع',
'$areaAmount تومان',
),
const SizedBox(height: 8),
_infoRow(
Icons.people_alt_outlined,
'مبلغ هر نفر',
'$personAmount تومان',
),
const SizedBox(height: 8),
_infoRow(
Icons.area_chart_outlined,
'مجموع متراژ',
totalArea == null
? 'ثبت نشده'
    : '${_formatArea(totalArea)} متر مربع',
),
const SizedBox(height: 8),
_infoRow(
Icons.groups_outlined,
'مجموع نفرات',
totalPeople == null ? 'ثبت نشده' : _faDigits('$totalPeople'),
),
const SizedBox(height: 8),
_infoRow(
Icons.add_card_outlined,
'هزینه متفرقه هر واحد',
'$otherCost تومان',
),
const SizedBox(height: 8),
_infoRow(
Icons.calendar_month_outlined,
'مهلت پرداخت',
_jalaliString(charge['payment_deadline']),
),
const SizedBox(height: 8),
_infoRow(
Icons.schedule_outlined,
'وضعیت ارسال',
notified ? 'ارسال‌شده' : 'ارسال‌نشده',
valueColor: notified ? Colors.green : Colors.orange,
),
const SizedBox(height: 8),
Row(
children: [
const Icon(
Icons.apartment_outlined,
size: 19,
color: _purpleColor,
),
const SizedBox(width: 8),
Expanded(
child: Text(
sentCount != null && totalCount != null
? 'اعلام شارژ ${_faDigits('$sentCount')} از ${_faDigits('$totalCount')} واحد'
    : 'تعداد واحدهای اعلام‌شده نامشخص',
style: const TextStyle(
fontSize: 13,
fontWeight: FontWeight.w600,
color: _purpleColor,
),
),
),
],
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
title: const Text('شارژ واحدی متراژی نفری'),
centerTitle: true,
backgroundColor: _primaryColor,
foregroundColor: Colors.white,
actions: [
IconButton(
tooltip: 'بارگذاری مجدد',
onPressed: _loading ? null : _loadCharges,
icon: const Icon(Icons.refresh),
),
],
),
floatingActionButton: FloatingActionButton.extended(
onPressed: () => _showChargeForm(),
backgroundColor: _primaryColor,
foregroundColor: Colors.white,
icon: const Icon(Icons.add),
label: const Text('افزودن شارژ'),
),
body: RefreshIndicator(
onRefresh: _loadCharges,
child: _loading
? const Center(
child: CircularProgressIndicator(color: _primaryColor),
)
    : _loadError && _charges.isEmpty
? ListView(
physics: const AlwaysScrollableScrollPhysics(),
padding: const EdgeInsets.all(24),
children: [
const SizedBox(height: 100),
const Icon(Icons.cloud_off, size: 54, color: Colors.grey),
const SizedBox(height: 16),
const Text(
'دریافت اطلاعات ناموفق بود.',
textAlign: TextAlign.center,
),
const SizedBox(height: 12),
Center(
child: FilledButton.icon(
onPressed: _loadCharges,
icon: const Icon(Icons.refresh),
label: const Text('تلاش مجدد'),
),
),
],
)
    : _charges.isEmpty
? ListView(
physics: const AlwaysScrollableScrollPhysics(),
padding: const EdgeInsets.all(24),
children: [
const SizedBox(height: 100),
Icon(
Icons.apartment,
size: 64,
color: Colors.grey.shade400,
),
const SizedBox(height: 16),
const Text(
'هنوز شارژ ثابتی ثبت نشده است.',
textAlign: TextAlign.center,
),
const SizedBox(height: 12),
Center(
child: FilledButton.icon(
onPressed: () => _showChargeForm(),
icon: const Icon(Icons.add),
label: const Text('ثبت اولین شارژ'),
),
),
],
)
    : ListView.builder(
physics: const AlwaysScrollableScrollPhysics(),
padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
itemCount: _charges.length,
itemBuilder: (_, index) =>
_buildChargeCard(_charges[index]),
),
),
),
);
}
}

// ============================================================
// فرم ثبت و ویرایش شارژ
// ============================================================

class _FixPersonAreaChargeFormSheet extends StatefulWidget {
final Map<String, dynamic>? charge;
final ManagerFixPersonAreaChargeService service;

const _FixPersonAreaChargeFormSheet({
required this.service,
this.charge,
});

@override
State<_FixPersonAreaChargeFormSheet> createState() =>
_FixPersonAreaChargeFormSheetState();
}

class _FixPersonAreaChargeFormSheetState
extends State<_FixPersonAreaChargeFormSheet> {
final _formKey = GlobalKey<FormState>();

final _nameController = TextEditingController();
final _fixAmountController = TextEditingController();
final _areaAmountController = TextEditingController();
final _personAmountController = TextEditingController();
final _deadlineController = TextEditingController();
final _penaltyController = TextEditingController();
final _otherCostController = TextEditingController();
final _detailsController = TextEditingController();

bool _saving = false;

bool get _isEditing => widget.charge != null;

@override
void initState() {
super.initState();

final charge = widget.charge;

if (charge == null) {
_fixAmountController.text = '0';
_areaAmountController.text = '0';
_personAmountController.text = '0';
_penaltyController.text = '0';
_otherCostController.text = '0';
return;
}

_nameController.text = '${charge['name'] ?? charge['title'] ?? ''}';
_fixAmountController.text =
_enDigits('${charge['fix_charge_amount'] ?? 0}');
_areaAmountController.text = _enDigits('${charge['area_amount'] ?? 0}');
_personAmountController.text =
_enDigits('${charge['person_amount'] ?? 0}');
_penaltyController.text =
_enDigits('${charge['payment_penalty_amount'] ?? 0}');
_otherCostController.text =
_enDigits('${charge['other_cost_amount'] ?? 0}');
_detailsController.text = '${charge['details'] ?? ''}';

final deadline = _parseJalali('${charge['payment_deadline'] ?? ''}');
if (deadline != null) {
_deadlineController.text = _jalaliString(deadline);
}
}

@override
void dispose() {
_nameController.dispose();
_fixAmountController.dispose();
_areaAmountController.dispose();
_personAmountController.dispose();
_deadlineController.dispose();
_penaltyController.dispose();
_otherCostController.dispose();
_detailsController.dispose();
super.dispose();
}

String? _requiredValidator(String? value, String label) {
if (value == null || value.trim().isEmpty) return '$label را وارد کنید.';
return null;
}

String? _amountValidator(String? value) {
final normalized = _enDigits(value ?? '')
    .replaceAll(',', '')
    .replaceAll('٬', '');
final number = num.tryParse(normalized);

if (number == null || number < 0) {
return 'مبلغ باید عدد غیرمنفی باشد.';
}

return null;
}

String? _optionalAmountValidator(String? value) {
if (value == null || value.trim().isEmpty) return null;

final normalized = _enDigits(value)
    .replaceAll(',', '')
    .replaceAll('٬', '');
final number = num.tryParse(normalized);

if (number == null || number < 0) {
return 'مبلغ معتبر و غیرمنفی وارد کنید.';
}

return null;
}

num? _parseAmount(String value) {
return num.tryParse(
_enDigits(value).replaceAll(',', '').replaceAll('٬', ''),
);
}

void _showMessage(String message) {
if (!mounted) return;
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text(message)),
);
}

Future<void> _selectDeadline() async {
final selected = await showDialog<Jalali>(
context: context,
builder: (_) => _FixPersonAreaShamsiDateDialog(
initialDate: _parseJalali(_deadlineController.text) ?? Jalali.now(),
),
);

if (selected != null && mounted) {
setState(() => _deadlineController.text = _jalaliString(selected));
}
}

Future<void> _save() async {
FocusScope.of(context).unfocus();

if (!_formKey.currentState!.validate()) return;

final fixAmount = _parseAmount(_fixAmountController.text);
final areaAmount = _parseAmount(_areaAmountController.text);
final personAmount = _parseAmount(_personAmountController.text);
final penalty = _parseAmount(_penaltyController.text) ?? 0;
final otherCost = _parseAmount(_otherCostController.text) ?? 0;
final deadline = _parseJalali(_deadlineController.text);

if (fixAmount == null || fixAmount < 0) {
_showMessage('مبلغ ثابت هر واحد معتبر نیست.');
return;
}
if (areaAmount == null || areaAmount < 0) {
_showMessage('مبلغ هر متر مربع معتبر نیست.');
return;
}
if (personAmount == null || personAmount < 0) {
_showMessage('مبلغ هر نفر معتبر نیست.');
return;
}
if (penalty < 0 || otherCost < 0) {
_showMessage('مبالغ نباید منفی باشند.');
return;
}
if (deadline == null) {
_showMessage('تاریخ سررسید را از تقویم انتخاب کنید.');
return;
}

// تاریخ شمسی مطابق قرارداد JalaliDateField در بک‌اند
final apiDeadline =
'${deadline.year.toString().padLeft(4, '0')}-'
'${deadline.month.toString().padLeft(2, '0')}-'
'${deadline.day.toString().padLeft(2, '0')}';

final id = int.tryParse('${widget.charge?['id'] ?? ''}');

if (_isEditing && (id == null || id <= 0)) {
_showMessage('شناسه شارژ معتبر نیست.');
return;
}

setState(() => _saving = true);

try {
if (_isEditing) {
await widget.service.updateCharge(
id!,
name: _nameController.text.trim(),
fixChargeAmount: fixAmount,
areaAmount: areaAmount,
personAmount: personAmount,
paymentDeadline: apiDeadline,
otherCostAmount: otherCost,
paymentPenaltyAmount: penalty,
details: _detailsController.text.trim(),
);
} else {
await widget.service.createCharge(
name: _nameController.text.trim(),
fixChargeAmount: fixAmount,
areaAmount: areaAmount,
personAmount: personAmount,
paymentDeadline: apiDeadline,
otherCostAmount: otherCost,
paymentPenaltyAmount: penalty,
details: _detailsController.text.trim(),
);
}

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
_isEditing
? 'شارژ با موفقیت ویرایش شد.'
    : 'شارژ با موفقیت ثبت شد.',
),
backgroundColor: Colors.green,
),
);

Navigator.of(context).pop(true);
} catch (e) {
_showMessage(
'ذخیره شارژ انجام نشد: '
'${e.toString().replaceFirst('Exception: ', '')}',
);
} finally {
if (mounted) setState(() => _saving = false);
}
}

Widget _field({
required String label,
required TextEditingController controller,
String? hint,
String? Function(String?)? validator,
TextInputType keyboardType = TextInputType.text,
int maxLines = 1,
bool readOnly = false,
VoidCallback? onTap,
Widget? suffixIcon,
}) {
return TextFormField(
controller: controller,
textDirection: TextDirection.rtl,
textAlign: TextAlign.right,
keyboardType: keyboardType,
maxLines: maxLines,
readOnly: readOnly,
onTap: onTap,
validator: validator,
decoration: InputDecoration(
labelText: label,
hintText: hint,
suffixIcon: suffixIcon,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
contentPadding: const EdgeInsets.symmetric(
horizontal: 14,
vertical: 14,
),
),
);
}

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: Container(
constraints: BoxConstraints(
maxHeight: MediaQuery.of(context).size.height * 0.92,
),
decoration: const BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
),
child: Padding(
padding: EdgeInsets.only(
bottom: MediaQuery.of(context).viewInsets.bottom,
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const SizedBox(height: 12),
Container(
width: 44,
height: 4,
decoration: BoxDecoration(
color: Colors.grey.shade300,
borderRadius: BorderRadius.circular(10),
),
),
Padding(
padding: const EdgeInsets.all(18),
child: Row(
children: [
const Icon(Icons.apartment, color: _primaryColor, size: 30),
const SizedBox(width: 12),
Expanded(
child: Text(
_isEditing ? 'ویرایش شارژ' : 'افزودن شارژ',
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
),
IconButton(
onPressed: _saving ? null : () => Navigator.pop(context),
icon: const Icon(Icons.close),
),
],
),
),
const Divider(height: 1),
Flexible(
child: Form(
key: _formKey,
child: ListView(
shrinkWrap: true,
padding: const EdgeInsets.all(20),
children: [
_field(
label: 'عنوان شارژ',
controller: _nameController,
hint: 'مثلاً شارژ واحدی متراژی نفری مهر ۱۴۰۵',
validator: (v) => _requiredValidator(v, 'عنوان شارژ'),
),
const SizedBox(height: 16),
_field(
label: 'مبلغ ثابت هر واحد (تومان)',
controller: _fixAmountController,
keyboardType: TextInputType.number,
validator: _amountValidator,
),
const SizedBox(height: 16),
_field(
label: 'مبلغ هر متر مربع (تومان)',
controller: _areaAmountController,
keyboardType:
const TextInputType.numberWithOptions(decimal: true),
validator: _amountValidator,
),
const SizedBox(height: 16),
_field(
label: 'مبلغ هر نفر (تومان)',
controller: _personAmountController,
keyboardType: TextInputType.number,
validator: _amountValidator,
),
const SizedBox(height: 16),
_field(
label: 'مهلت پرداخت (شمسی)',
controller: _deadlineController,
readOnly: true,
onTap: _selectDeadline,
validator: (v) => _requiredValidator(v, 'تاریخ سررسید'),
suffixIcon: const Icon(
Icons.calendar_month,
color: _primaryColor,
),
),
const SizedBox(height: 16),
_field(
label: 'جریمه دیرکرد',
controller: _penaltyController,
keyboardType: TextInputType.number,
validator: _optionalAmountValidator,
),
const SizedBox(height: 16),
_field(
label: 'هزینه متفرقه هر واحد (تومان)',
controller: _otherCostController,
keyboardType: TextInputType.number,
validator: _optionalAmountValidator,
),
const SizedBox(height: 16),
_field(
label: 'توضیحات',
controller: _detailsController,
maxLines: 3,
),
const SizedBox(height: 24),
SizedBox(
height: 50,
child: FilledButton.icon(
onPressed: _saving ? null : _save,
style: FilledButton.styleFrom(
backgroundColor: _primaryColor,
foregroundColor: Colors.white,
),
icon: _saving
? const SizedBox(
width: 20,
height: 20,
child: CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
)
    : const Icon(Icons.save),
label: Text(
_saving
? 'در حال ذخیره...'
    : _isEditing
? 'ذخیره تغییرات'
    : 'ثبت شارژ',
),
),
),
],
),
),
),
],
),
),
),
);
}
}

// ============================================================
// انتخاب تاریخ شمسی
// ============================================================

class _FixPersonAreaShamsiDateDialog extends StatefulWidget {
final Jalali initialDate;

const _FixPersonAreaShamsiDateDialog({required this.initialDate});

@override
State<_FixPersonAreaShamsiDateDialog> createState() =>
_FixPersonAreaShamsiDateDialogState();
}

class _FixPersonAreaShamsiDateDialogState
extends State<_FixPersonAreaShamsiDateDialog> {
late int _year;
late int _month;
late int _day;

@override
void initState() {
super.initState();
_year = widget.initialDate.year;
_month = widget.initialDate.month;
_day = widget.initialDate.day;
}

@override
Widget build(BuildContext context) {
final currentYear = Jalali.now().year;
final years = List<int>.generate(
81,
(index) => currentYear - 40 + index,
);

final days = List<int>.generate(
_jalaliDaysInMonth(_year, _month),
(index) => index + 1,
);

return Directionality(
textDirection: TextDirection.rtl,
child: AlertDialog(
title: const Text('انتخاب تاریخ شمسی', textAlign: TextAlign.center),
content: SizedBox(
width: 320,
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
DropdownButtonFormField<int>(
initialValue: _year,
isExpanded: true,
decoration: const InputDecoration(
labelText: 'سال',
border: OutlineInputBorder(),
),
items: years
    .map(
(year) => DropdownMenuItem(
value: year,
child: Text(_faDigits('$year')),
),
)
    .toList(),
onChanged: (value) {
if (value == null) return;
setState(() {
_year = value;
final max = _jalaliDaysInMonth(_year, _month);
if (_day > max) _day = max;
});
},
),
const SizedBox(height: 12),
DropdownButtonFormField<int>(
initialValue: _month,
isExpanded: true,
decoration: const InputDecoration(
labelText: 'ماه',
border: OutlineInputBorder(),
),
items: List.generate(
12,
(index) => DropdownMenuItem(
value: index + 1,
child: Text(_faDigits('${index + 1}')),
),
),
onChanged: (value) {
if (value == null) return;
setState(() {
_month = value;
final max = _jalaliDaysInMonth(_year, _month);
if (_day > max) _day = max;
});
},
),
const SizedBox(height: 12),
DropdownButtonFormField<int>(
key: ValueKey('$_year-$_month'),
initialValue: _day,
isExpanded: true,
decoration: const InputDecoration(
labelText: 'روز',
border: OutlineInputBorder(),
),
items: days
    .map(
(day) => DropdownMenuItem(
value: day,
child: Text(_faDigits('$day')),
),
)
    .toList(),
onChanged: (value) {
if (value != null) setState(() => _day = value);
},
),
const SizedBox(height: 12),
Text(
_jalaliString(Jalali(_year, _month, _day)),
style: const TextStyle(
color: _primaryColor,
fontWeight: FontWeight.bold,
fontSize: 16,
),
),
],
),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('انصراف'),
),
FilledButton(
style: FilledButton.styleFrom(
backgroundColor: _primaryColor,
foregroundColor: Colors.white,
),
onPressed: () => Navigator.pop(
context,
Jalali(_year, _month, _day),
),
child: const Text('تأیید'),
),
],
),
);
}
}
