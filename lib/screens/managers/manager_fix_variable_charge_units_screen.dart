
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_fix_variable_charge_service.dart';

const Color _primaryColor = Color(0xFF00ACC1);
const Color _purpleColor = Color(0xFF610DB5);

class ManagerFixVariableChargeUnitsScreen extends StatefulWidget {
final int chargeId;
final String chargeName;

const ManagerFixVariableChargeUnitsScreen({
super.key,
required this.chargeId,
required this.chargeName,
});

@override
State<ManagerFixVariableChargeUnitsScreen> createState() =>
_ManagerFixVariableChargeUnitsScreenState();
}

class _ManagerFixVariableChargeUnitsScreenState
extends State<ManagerFixVariableChargeUnitsScreen> {
final ManagerFixVariableChargeService _service =
ManagerFixVariableChargeService();

bool _loading = true;
bool _sending = false;

List<Map<String, dynamic>> _units = [];
final Set<int> _selectedIds = {};
final TextEditingController _searchController = TextEditingController();

String _residentFilter = 'all';

int _intValue(dynamic value) {
if (value is int) return value;
if (value is num) return value.toInt();

return int.tryParse(_latinDigits(value?.toString() ?? '')) ?? 0;
}

String _latinDigits(String input) {
const persian = '۰۱۲۳۴۵۶۷۸۹';
const arabic = '٠١٢٣٤٥٦٧٨٩';

var result = input;

for (var i = 0; i < 10; i++) {
result = result.replaceAll(persian[i], '$i');
result = result.replaceAll(arabic[i], '$i');
}

return result;
}

String _persianDigits(dynamic value) {
const english = '0123456789';
const persian = '۰۱۲۳۴۵۶۷۸۹';

var result = value?.toString() ?? '';

for (var i = 0; i < 10; i++) {
result = result.replaceAll(english[i], persian[i]);
}

return result;
}

double _number(dynamic value) {
if (value is num) return value.toDouble();
if (value == null) return 0;

return double.tryParse(
_latinDigits(value.toString())
    .replaceAll(',', '')
    .replaceAll('٬', '')
    .replaceAll('٫', '.')
    .trim(),
) ??
0;
}

String _money(dynamic value) {
final amount = _number(value).round();
final digits = amount.abs().toString();
final buffer = StringBuffer();

for (var i = 0; i < digits.length; i++) {
buffer.write(digits[i]);

final remaining = digits.length - i - 1;
if (remaining > 0 && remaining % 3 == 0) {
buffer.write(',');
}
}

final result = '${amount < 0 ? '-' : ''}${buffer.toString()}';
return _persianDigits(result);
}

String _formatCount(dynamic value) {
final number = _number(value);
final result = number == number.roundToDouble()
? number.toInt().toString()
    : number.toStringAsFixed(2);

return _persianDigits(result);
}

bool _boolValue(dynamic value) {
if (value is bool) return value;
if (value is num) return value != 0;

final text = _latinDigits(value?.toString().toLowerCase() ?? '')
    .trim();

return const [
'true',
'1',
'yes',
'بله',
'ارسال شده',
'ارسال‌شده',
'موفق',
].contains(text);
}

@override
void initState() {
super.initState();
_searchController.addListener(_onSearchChanged);
_loadUnits();
}

void _onSearchChanged() {
if (mounted) setState(() {});
}

@override
void dispose() {
_searchController.removeListener(_onSearchChanged);
_searchController.dispose();
super.dispose();
}

Future<void> _loadUnits() async {
if (_loading && _units.isNotEmpty) return;

setState(() {
_loading = true;
});

try {
final result = await _service.getChargeUnits(
widget.chargeId,
search: _searchController.text.trim(),
residentType: _residentFilter,
);

if (!mounted) return;

setState(() {
_units = result
    .map<Map<String, dynamic>>(
(item) => Map<String, dynamic>.from(item as Map),
)
    .toList();
_selectedIds.clear();
});
} catch (e) {
if (mounted) {
_showMessage(
e.toString().replaceFirst('Exception: ', ''),
);
}
} finally {
if (mounted) {
setState(() => _loading = false);
}
}
}

int _unitId(Map<String, dynamic> unit) {
return _intValue(
unit['id'] ?? unit['unit_id'] ?? unit['unit_pk'],
);
}

String _unitNumber(Map<String, dynamic> unit) {
final value = unit['unit'] ??
unit['unit_number'] ??
unit['unit_name'] ??
unit['unit_display'];

if (value == null || value.toString().trim().isEmpty) {
return 'نامشخص';
}

return value.toString().trim();
}

double _unitArea(Map<String, dynamic> unit) =>
_number(unit['area']);

double _unitPeople(Map<String, dynamic> unit) =>
_number(unit['people_count']);

bool _isRenter(Map<String, dynamic> unit) =>
unit['resident_type']?.toString() == 'renter';

bool _isVacant(Map<String, dynamic> unit) =>
unit['resident_type']?.toString() == 'empty';

bool _isPaid(Map<String, dynamic> unit) =>
_boolValue(unit['is_paid']);

bool _isSystemSent(Map<String, dynamic> unit) =>
_boolValue(
unit['is_notified'] ?? unit['send_notification'],
);

bool _isSmsSent(Map<String, dynamic> unit) =>
_boolValue(unit['send_sms']);

String _residentName(Map<String, dynamic> unit) {
if (_isRenter(unit)) {
final renter = (unit['renter_name'] ?? '').toString().trim();
return renter.isEmpty ? 'نام مستأجر ثبت نشده' : renter;
}

final owner = (unit['owner_name'] ?? '').toString().trim();
return owner.isEmpty ? 'نام مالک ثبت نشده' : owner;
}

String _jalaliDate(dynamic value) {
if (value == null || value.toString().trim().isEmpty) {
return '—';
}

final raw = _latinDigits(value.toString().trim());

if (RegExp(r'^(13|14)\d{2}[-/]\d{1,2}[-/]\d{1,2}')
    .hasMatch(raw)) {
return _persianDigits(raw.replaceAll('-', '/'));
}

try {
final datePart =
raw.length >= 10 ? raw.substring(0, 10) : raw;
final date = DateTime.parse(datePart);
final jalali = Jalali.fromDateTime(date);

return _persianDigits(
'${jalali.year}/'
'${jalali.month.toString().padLeft(2, '0')}/'
'${jalali.day.toString().padLeft(2, '0')}',
);
} catch (_) {
return _persianDigits(raw);
}
}

double _unitChargeAmount(Map<String, dynamic> unit) {
final amount = unit['current_charge'] ??
unit['charge_amount'] ??
unit['amount'] ??
unit['base_amount'];

if (amount != null) return _number(amount);

// در صورت نبود مبلغ محاسبه‌شده در پاسخ API،
// فرمول محاسبه باید با فیلدهای واقعی بک‌اند هماهنگ شود.
return 0;
}

List<Map<String, dynamic>> get _filteredUnits {
final query = _latinDigits(
_searchController.text.trim().toLowerCase(),
);

return _units.where((unit) {
if (_residentFilter == 'owner' &&
(_isRenter(unit) || _isVacant(unit))) {
return false;
}

if (_residentFilter == 'renter' && !_isRenter(unit)) {
return false;
}

if (_residentFilter == 'empty' && !_isVacant(unit)) {
return false;
}

if (query.isNotEmpty) {
final searchable = _latinDigits(
'${_unitNumber(unit)} '
'${_residentName(unit)} '
'${_unitId(unit)}',
).toLowerCase();

if (!searchable.contains(query)) return false;
}

return true;
}).toList();
}

bool get _allFilteredSelected {
final ids = _filteredUnits.map(_unitId).where((id) => id > 0).toSet();

return ids.isNotEmpty && ids.every(_selectedIds.contains);
}

void _toggleUnit(int id, bool selected) {
if (id <= 0) return;

setState(() {
if (selected) {
_selectedIds.add(id);
} else {
_selectedIds.remove(id);
}
});
}

void _toggleSelectAll() {
final ids = _filteredUnits.map(_unitId).where((id) => id > 0).toSet();

setState(() {
if (ids.isNotEmpty && ids.every(_selectedIds.contains)) {
_selectedIds.removeAll(ids);
} else {
_selectedIds.addAll(ids);
}
});
}

Future<void> _showSendOptions() async {
if (_selectedIds.isEmpty) {
_showMessage('ابتدا واحدهای موردنظر را انتخاب کنید.');
return;
}

final sendSms = await showDialog<bool>(
context: context,
builder: (dialogContext) {
bool selectedOption = false;

return StatefulBuilder(
builder: (context, setDialogState) {
return AlertDialog(
title: const Text('روش ارسال شارژ'),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
Text(
'شارژ برای '
'${_persianDigits(_selectedIds.length)} واحد ارسال می‌شود.',
),
const SizedBox(height: 8),
RadioListTile<bool>(
value: false,
groupValue: selectedOption,
activeColor: _primaryColor,
contentPadding: EdgeInsets.zero,
title: const Text('ارسال سیستمی'),
subtitle: const Text('ثبت اعلان داخل اپلیکیشن'),
onChanged: (value) {
setDialogState(() => selectedOption = value!);
},
),
RadioListTile<bool>(
value: true,
groupValue: selectedOption,
activeColor: _primaryColor,
contentPadding: EdgeInsets.zero,
title: const Text('ارسال سیستمی و پیامکی'),
subtitle: const Text('ثبت اعلان و تلاش برای ارسال پیامک'),
onChanged: (value) {
setDialogState(() => selectedOption = value!);
},
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.pop(dialogContext),
child: const Text('انصراف'),
),
FilledButton(
style: FilledButton.styleFrom(
backgroundColor: _primaryColor,
),
onPressed: () {
Navigator.pop(dialogContext, selectedOption);
},
child: const Text('ادامه'),
),
],
);
},
);
},
);

if (sendSms == null || !mounted) return;

await _sendSelected(sendSms: sendSms);
}

Future<void> _sendSelected({required bool sendSms}) async {
if (_selectedIds.isEmpty || _sending) return;

setState(() => _sending = true);

try {
final result = await _service.sendChargeToUnits(
widget.chargeId,
_selectedIds.toList(),
sendSms: sendSms,
);

if (!mounted) return;

_showMessage(
result['detail']?.toString() ?? 'درخواست ارسال شارژ ثبت شد.',
);

await _loadUnits();
} catch (e) {
if (mounted) {
_showMessage(
e.toString().replaceFirst('Exception: ', ''),
);
}
} finally {
if (mounted) setState(() => _sending = false);
}
}

Future<void> _cancelSelected() async {
if (_selectedIds.isEmpty || _sending) return;

final confirmed = await showDialog<bool>(
context: context,
builder: (dialogContext) => AlertDialog(
title: const Text('لغو اعلان شارژ'),
content: Text(
'اعلان شارژ برای '
'${_persianDigits(_selectedIds.length)} واحد لغو شود؟',
),
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
child: const Text('لغو اعلان'),
),
],
),
);

if (confirmed != true || !mounted) return;

setState(() => _sending = true);

try {
final result = await _service.cancelChargeForUnits(
widget.chargeId,
_selectedIds.toList(),
);

if (!mounted) return;

_showMessage(
result['detail']?.toString() ?? 'درخواست لغو اعلان ثبت شد.',
);

await _loadUnits();
} catch (e) {
if (mounted) {
_showMessage(
e.toString().replaceFirst('Exception: ', ''),
);
}
} finally {
if (mounted) setState(() => _sending = false);
}
}

void _showMessage(String message) {
if (!mounted) return;

ScaffoldMessenger.of(context)
..hideCurrentSnackBar()
..showSnackBar(
SnackBar(
content: Text(message, textAlign: TextAlign.right),
behavior: SnackBarBehavior.floating,
),
);
}

Widget _residentChip(String label, String value) {
final selected = _residentFilter == value;

return Padding(
padding: const EdgeInsets.symmetric(horizontal: 4),
child: ChoiceChip(
label: Text(label),
selected: selected,
showCheckmark: false,
selectedColor: _primaryColor,
labelStyle: TextStyle(
color: selected ? Colors.white : Colors.black87,
fontSize: 12,
),
onSelected: (_) async {
setState(() {
_residentFilter = value;
_selectedIds.clear();
});
await _loadUnits();
},
),
);
}

Widget _buildHeader() {
return Card(
color: _purpleColor,
margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
),
child: Padding(
padding: const EdgeInsets.all(14),
child: Row(
children: [
const Icon(
Icons.apartment_rounded,
color: Colors.white,
size: 27,
),
const SizedBox(width: 10),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
widget.chargeName,
style: const TextStyle(
color: Colors.white,
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 5),
Text(
'شناسه شارژ: ${_persianDigits(widget.chargeId)}',
style: const TextStyle(
color: Colors.white70,
fontSize: 12,
),
),
const SizedBox(height: 4),
Text(
'تعداد واحدها: ${_persianDigits(_units.length)}',
style: const TextStyle(
color: Colors.white,
fontSize: 12,
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

Widget _buildUnitCard(Map<String, dynamic> unit) {
final id = _unitId(unit);
final selected = _selectedIds.contains(id);
final vacant = _isVacant(unit);
final renter = _isRenter(unit);
final paid = _isPaid(unit);
final systemSent = _isSystemSent(unit);
final smsSent = _isSmsSent(unit);

final amount = _unitChargeAmount(unit);
final smsDate = (unit['send_sms_date'] ?? '').toString().trim();
final paymentDate = unit['payment_date'] ?? unit['paid_at'];

final residentName = _residentName(unit);

final cardColor = vacant
? const Color(0xFFFFF0F0)
    : paid
? const Color(0xFFE5F5E9)
    : systemSent
? const Color(0xFFFFF4E5)
    : Colors.white;

final borderColor = selected
? _purpleColor
    : vacant
? Colors.red
    : paid
? const Color(0xFF81C784)
    : systemSent
? const Color(0xFFFFCC80)
    : Colors.grey.shade300;

return Card(
color: cardColor,
elevation: selected ? 2 : 0.5,
margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
side: BorderSide(
color: borderColor,
width: selected ? 1.5 : 0.8,
),
),
child: InkWell(
borderRadius: BorderRadius.circular(12),
onTap: id <= 0 ? null : () => _toggleUnit(id, !selected),
child: Padding(
padding: const EdgeInsets.all(10),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Checkbox(
value: selected,
activeColor: _purpleColor,
onChanged: id <= 0
? null
    : (value) => _toggleUnit(id, value ?? false),
),
const SizedBox(width: 5),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Expanded(
child: Text(
'واحد ${_persianDigits(_unitNumber(unit))}',
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 14,
),
),
),
if (vacant)
const Icon(
Icons.error_outline,
color: Colors.red,
size: 19,
),
if (paid)
const Icon(
Icons.check_circle,
color: Color(0xFF2E7D32),
size: 19,
),
],
),
const SizedBox(height: 5),
Text(
vacant
? 'وضعیت: خالی'
    : '${renter ? 'مستأجر' : 'مالک'}: $residentName',
style: TextStyle(
fontSize: 12,
color: vacant ? Colors.red.shade800 : Colors.grey.shade800,
fontWeight:
vacant ? FontWeight.bold : FontWeight.normal,
),
),
const SizedBox(height: 8),
Wrap(
spacing: 12,
runSpacing: 6,
children: [
Text(
'متراژ: ${_formatCount(_unitArea(unit))} متر',
style: const TextStyle(fontSize: 12),
),
Text(
'تعداد نفرات: ${_formatCount(_unitPeople(unit))}',
style: const TextStyle(fontSize: 12),
),
if (unit['financial_document_number'] != null)
Text(
'سند: ${_persianDigits(unit['financial_document_number'])}',
style: const TextStyle(fontSize: 12),
),
],
),
const SizedBox(height: 8),
Row(
children: [
Expanded(
child: Text(
'${_money(amount)} تومان',
style: TextStyle(
fontSize: 14,
fontWeight: FontWeight.bold,
color: paid ? Colors.green.shade800 : _purpleColor,
),
),
),
if (systemSent)
const Tooltip(
message: 'اعلان سیستمی ثبت شده',
child: Icon(
Icons.notifications_active_rounded,
color: Colors.deepOrange,
size: 19,
),
),
if (smsSent)
const Padding(
padding: EdgeInsets.only(right: 5),
child: Tooltip(
message: 'وضعیت پیامک: ارسال‌شده',
child: Icon(
Icons.sms_rounded,
color: Colors.blue,
size: 19,
),
),
),
],
),
if (paid && paymentDate != null) ...[
const SizedBox(height: 5),
Text(
'تاریخ پرداخت: ${_jalaliDate(paymentDate)}',
style: TextStyle(
color: Colors.green.shade800,
fontSize: 11,
),
),
],
if (smsDate.isNotEmpty) ...[
const SizedBox(height: 4),
Text(
'تاریخ پیامک: ${_jalaliDate(smsDate)}',
style: const TextStyle(
color: Colors.blue,
fontSize: 11,
),
),
],
],
),
),
],
),
),
),
);
}

Widget _buildBottomActions() {
return SafeArea(
top: false,
child: Container(
padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
decoration: BoxDecoration(
color: Theme.of(context).scaffoldBackgroundColor,
boxShadow: [
BoxShadow(
color: Colors.black.withValues(alpha: 0.06),
blurRadius: 8,
offset: const Offset(0, -2),
),
],
),
child: Row(
children: [
Expanded(
child: OutlinedButton.icon(
onPressed: _sending || _selectedIds.isEmpty
? null
    : _cancelSelected,
icon: const Icon(Icons.cancel_outlined),
label: const Text('لغو اعلان'),
style: OutlinedButton.styleFrom(
foregroundColor: Colors.red.shade700,
minimumSize: const Size(0, 45),
),
),
),
const SizedBox(width: 8),
Expanded(
flex: 2,
child: FilledButton.icon(
onPressed: _sending || _selectedIds.isEmpty
? null
    : _showSendOptions,
icon: _sending
? const SizedBox(
width: 17,
height: 17,
child: CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
)
    : const Icon(Icons.send_rounded),
label: Text(
_sending
? 'لطفاً صبر کنید'
    : 'ارسال (${_persianDigits(_selectedIds.length)})',
),
style: FilledButton.styleFrom(
backgroundColor: _primaryColor,
foregroundColor: Colors.white,
minimumSize: const Size(0, 45),
),
),
),
],
),
),
);
}

@override
Widget build(BuildContext context) {
final filteredUnits = _filteredUnits;

return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
backgroundColor: const Color(0xFFF5F7FA),
appBar: AppBar(
backgroundColor: _primaryColor,
foregroundColor: Colors.white,
title: const Text(
'واحدهای شارژ ثابت و متغیر',
style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),
actions: [
IconButton(
tooltip: 'به‌روزرسانی',
onPressed: _loading || _sending ? null : _loadUnits,
icon: const Icon(Icons.refresh_rounded),
),
],
),
body: Column(
children: [
_buildHeader(),
Padding(
padding: const EdgeInsets.fromLTRB(12, 8, 12, 5),
child: TextField(
controller: _searchController,
textDirection: TextDirection.rtl,
decoration: InputDecoration(
hintText: 'جست‌وجوی شماره واحد یا نام ساکن',
hintStyle: const TextStyle(fontSize: 12),
prefixIcon: const Icon(Icons.search_rounded),
suffixIcon: _searchController.text.isEmpty
? null
    : IconButton(
tooltip: 'پاک کردن جست‌وجو',
onPressed: () async {
_searchController.clear();
await _loadUnits();
},
icon: const Icon(Icons.close_rounded),
),
isDense: true,
filled: true,
fillColor: Colors.white,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide.none,
),
),
onSubmitted: (_) => _loadUnits(),
),
),
SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(
children: [
_residentChip('همه ساکنان', 'all'),
_residentChip('مالکین', 'owner'),
_residentChip('مستأجرین', 'renter'),
_residentChip('واحدهای خالی', 'empty'),
],
),
),
Padding(
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
child: Row(
children: [
Checkbox(
value: _allFilteredSelected,
activeColor: _primaryColor,
onChanged: filteredUnits.isEmpty
? null
    : (_) => _toggleSelectAll(),
),
const Expanded(
child: Text(
'انتخاب واحدهای نمایش‌داده‌شده',
style: TextStyle(fontSize: 12),
),
),
Text(
'${_persianDigits(_selectedIds.length)} انتخاب',
style: const TextStyle(
color: _purpleColor,
fontWeight: FontWeight.bold,
fontSize: 12,
),
),
const SizedBox(width: 8),
Text(
'از ${_persianDigits(filteredUnits.length)}',
style: TextStyle(
color: Colors.grey.shade600,
fontSize: 11,
),
),
],
),
),
const Divider(height: 1),
Expanded(
child: _loading
? const Center(child: CircularProgressIndicator())
    : filteredUnits.isEmpty
? Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.apartment_outlined,
size: 48,
color: Colors.grey.shade400,
),
const SizedBox(height: 12),
const Text(
'واحدی با این مشخصات پیدا نشد.',
textAlign: TextAlign.center,
),
TextButton.icon(
onPressed: () async {
_searchController.clear();
setState(() => _residentFilter = 'all');
await _loadUnits();
},
icon: const Icon(Icons.refresh),
label: const Text('نمایش همه واحدها'),
),
],
),
),
)
    : RefreshIndicator(
onRefresh: _loadUnits,
child: ListView.builder(
physics: const AlwaysScrollableScrollPhysics(),
padding: const EdgeInsets.only(bottom: 12, top: 5),
itemCount: filteredUnits.length,
itemBuilder: (context, index) =>
_buildUnitCard(filteredUnits[index]),
),
),
),
],
),
bottomNavigationBar: _loading ? null : _buildBottomActions(),
),
);
}
}
