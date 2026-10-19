
import 'package:flutter/material.dart';

import '../../services/manager_charge_calculation_service.dart';
import 'manager_charge_calculation_units_screen.dart';

const Color _primaryColor = Color(0xFF00ACC1);
const Color _purpleColor = Color(0xFF610DB5);

class ManagerChargeCalculationItemsScreen extends StatefulWidget {
final int calculationId;
final String? calculationName;

const ManagerChargeCalculationItemsScreen({
super.key,
required this.calculationId,
this.calculationName,
});

@override
State<ManagerChargeCalculationItemsScreen> createState() =>
_ManagerChargeCalculationItemsScreenState();
}

class _ManagerChargeCalculationItemsScreenState
extends State<ManagerChargeCalculationItemsScreen> {
final ManagerChargeCalculationService _service =
ManagerChargeCalculationService();

bool _loading = true;
bool _saving = false;

Map<String, dynamic> _response = {};
List<Map<String, dynamic>> _groups = [];
List<Map<String, dynamic>> _units = [];

@override
void initState() {
super.initState();
_loadItems();
}

@override
void dispose() {
super.dispose();
}

// --------------------------------------------------
// ابزارهای عمومی
// --------------------------------------------------

String _string(dynamic value, {String fallback = ''}) {
if (value == null) return fallback;

final result = value.toString().trim();

return result.isEmpty ? fallback : result;
}

int _int(dynamic value, {int fallback = 0}) {
if (value is int) return value;

return int.tryParse(_string(value)) ?? fallback;
}

bool _bool(dynamic value, {bool fallback = false}) {
if (value is bool) return value;

if (value is num) return value != 0;

final text = _string(value).toLowerCase();

if (['true', '1', 'yes', 'بله'].contains(text)) {
return true;
}

if (['false', '0', 'no', 'خیر'].contains(text)) {
return false;
}

return fallback;
}

List<Map<String, dynamic>> _mapList(dynamic value) {
if (value is! List) {
return <Map<String, dynamic>>[];
}

return value
    .whereType<Map>()
    .map((item) => Map<String, dynamic>.from(item))
    .toList();
}

List<Map<String, dynamic>> _firstList(
Map<String, dynamic> data,
List<String> keys,
) {
for (final key in keys) {
final value = data[key];

if (value is List) {
return _mapList(value);
}
}

return <Map<String, dynamic>>[];
}

String _money(dynamic value) {
final number = num.tryParse(
_string(value).replaceAll(',', ''),
) ??
0;

final raw = number.round().toString();
final buffer = StringBuffer();

for (int i = 0; i < raw.length; i++) {
buffer.write(raw[i]);

final remaining = raw.length - i - 1;

if (remaining > 0 && remaining % 3 == 0) {
buffer.write(',');
}
}

return buffer.toString();
}

  void _message(String text, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            text,
            textAlign: TextAlign.center,
          ),
          backgroundColor: error ? Colors.redAccent : _primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

// --------------------------------------------------
// بارگذاری هزینه‌ها و واحدها
// --------------------------------------------------

Future<void> _loadItems() async {
setState(() => _loading = true);

try {
final data = await _service.getCalculationItems(
widget.calculationId,
);

if (!mounted) return;

final loadedUnits = _firstList(
data,
const [
'units',
'all_units',
'available_units',
],
);

final loadedGroups = _extractGroups(data);

setState(() {
_response = data;
_units = loadedUnits;
_groups = loadedGroups;
});
} catch (e) {
_message(
e.toString().replaceFirst('Exception: ', ''),
error: true,
);
} finally {
if (mounted) {
setState(() => _loading = false);
}
}
}

List<Map<String, dynamic>> _extractGroups(
Map<String, dynamic> data,
) {
// اگر API مستقیماً فهرست گروه‌ها را برگرداند.
final directGroups = _firstList(
data,
const [
'groups',
'expense_groups',
'items',
],
);

if (directGroups.isNotEmpty) {
return directGroups.map((original) {
final group = Map<String, dynamic>.from(original);

group['type'] = _normalizeType(
group['type'] ??
group['source_type'] ??
group['content_type'],
);

_prepareGroup(group);

return group;
}).toList();
}

// سازگاری با پاسخ‌هایی که هزینه‌ها را جداگانه برمی‌گردانند.
final result = <Map<String, dynamic>>[];

final expenses = _firstList(
data,
const ['expenses', 'expense_list'],
);

for (final original in expenses) {
final group = Map<String, dynamic>.from(original);

group['type'] = 'expense';
group['group_id'] ??= group['id'] ?? group['pk'];

_prepareGroup(group);

result.add(group);
}

final maintenance = _firstList(
data,
const [
'maintenance',
'maintenances',
'maintenance_list',
],
);

for (final original in maintenance) {
final group = Map<String, dynamic>.from(original);

group['type'] = 'maintenance';
group['group_id'] ??= group['id'] ?? group['pk'];

_prepareGroup(group);

result.add(group);
}

return result;
}

String _normalizeType(dynamic value) {
final type = _string(value).toLowerCase();

if (type.contains('maintenance') ||
type.contains('تعمیر') ||
type.contains('نگهداری')) {
return 'maintenance';
}

return 'expense';
}

void _prepareGroup(Map<String, dynamic> group) {
group['selected'] = _bool(
group['selected'] ?? group['is_selected'],
fallback: true,
);

group['basis'] = _normalizeBasis(
group['basis'] ??
group['allocation_basis'] ??
group['allocation_type'],
);

group['scope'] = _normalizeScope(
group['scope'] ?? group['allocation_scope'],
);

final rawIds = group['selected_unit_ids'] ??
group['unit_ids'] ??
group['selected_units'];

if (rawIds is List) {
group['selected_unit_ids'] = rawIds
    .map((value) {
if (value is Map) {
return _int(value['id'] ?? value['pk']);
}

return _int(value);
})
    .where((id) => id > 0)
    .toSet()
    .toList();
} else {
group['selected_unit_ids'] = <int>[];
}
}

String _normalizeBasis(dynamic value) {
switch (_string(value).toLowerCase()) {
case 'area':
case 'metrage':
case 'متراژ':
return 'area';

case 'person':
case 'people':
case 'نفر':
case 'نفرات':
return 'person';

default:
return 'equal';
}
}

String _normalizeScope(dynamic value) {
switch (_string(value).toLowerCase()) {
case 'occupied':
case 'resident':
case 'ساکن':
return 'occupied';

case 'vacant':
case 'empty':
case 'خالی':
return 'vacant';

case 'selected':
case 'custom':
case 'انتخابی':
return 'selected';

default:
return 'all';
}
}

// --------------------------------------------------
// تغییر انتخاب هزینه
// --------------------------------------------------

void _toggleSelected(int index, bool value) {
setState(() {
_groups[index]['selected'] = value;
});
}

void _changeBasis(int index, String value) {
setState(() {
_groups[index]['basis'] = value;
});
}

void _changeScope(int index, String value) {
setState(() {
_groups[index]['scope'] = value;

if (value != 'selected') {
_groups[index]['selected_unit_ids'] = <int>[];
}
});
}

// --------------------------------------------------
// انتخاب واحدهای دلخواه
// --------------------------------------------------

Future<void> _selectUnits(int groupIndex) async {
if (_units.isEmpty) {
_message(
'فهرست واحدها در پاسخ API موجود نیست. '
'ابتدا باید API اقلام، واحدهای ساختمان را برگرداند.',
error: true,
);
return;
}

final group = _groups[groupIndex];

final selected = <int>{
...((group['selected_unit_ids'] as List?) ?? [])
    .map((value) => _int(value))
    .where((id) => id > 0),
};

final searchController = TextEditingController();
var localSelected = Set<int>.from(selected);

final result = await showDialog<Set<int>>(
context: context,
builder: (dialogContext) {
return StatefulBuilder(
builder: (context, setDialogState) {
final query =
searchController.text.trim().toLowerCase();

final filtered = _units.where((unit) {
final title = _unitLabel(unit).toLowerCase();

return query.isEmpty || title.contains(query);
}).toList();

return AlertDialog(
title: const Text(
'انتخاب واحدها',
textAlign: TextAlign.center,
),
content: SizedBox(
width: 420,
height: 440,
child: Column(
children: [
TextField(
controller: searchController,
onChanged: (_) => setDialogState(() {}),
decoration: const InputDecoration(
hintText: 'جستجوی شماره واحد...',
prefixIcon: Icon(Icons.search),
border: OutlineInputBorder(),
),
),
const SizedBox(height: 8),
Row(
children: [
Expanded(
child: Text(
'${localSelected.length} واحد انتخاب شده',
style: const TextStyle(
color: _purpleColor,
fontWeight: FontWeight.bold,
),
),
),
TextButton(
onPressed: () {
setDialogState(() {
if (localSelected.length ==
filtered.length) {
for (final unit in filtered) {
localSelected.remove(
_unitId(unit),
);
}
} else {
for (final unit in filtered) {
final id = _unitId(unit);

if (id > 0) {
localSelected.add(id);
}
}
}
});
},
child: const Text('انتخاب همه نتایج'),
),
],
),
const Divider(),
Expanded(
child: filtered.isEmpty
? const Center(
child: Text('واحدی پیدا نشد.'),
)
    : ListView.builder(
itemCount: filtered.length,
itemBuilder: (context, index) {
final unit = filtered[index];
final id = _unitId(unit);

if (id <= 0) {
return const SizedBox.shrink();
}

return CheckboxListTile(
value: localSelected.contains(id),
activeColor: _primaryColor,
controlAffinity:
ListTileControlAffinity.leading,
title: Text(_unitLabel(unit)),
subtitle: Text(
'شناسه: $id',
style: const TextStyle(
fontSize: 11,
),
),
onChanged: (checked) {
setDialogState(() {
if (checked == true) {
localSelected.add(id);
} else {
localSelected.remove(id);
}
});
},
);
},
),
),
],
),
),
actions: [
TextButton(
onPressed: () =>
Navigator.pop(dialogContext),
child: const Text('انصراف'),
),
FilledButton(
style: FilledButton.styleFrom(
backgroundColor: _primaryColor,
),
onPressed: () => Navigator.pop(
dialogContext,
localSelected,
),
child: const Text('تأیید انتخاب'),
),
],
);
},
);
},
);

searchController.dispose();

if (result != null && mounted) {
setState(() {
_groups[groupIndex]['selected_unit_ids'] =
result.toList()..sort();
});
}
}

int _unitId(Map<String, dynamic> unit) {
return _int(unit['id'] ?? unit['pk'] ?? unit['unit_id']);
}

String _unitLabel(Map<String, dynamic> unit) {
final number = _string(
unit['unit_number'] ??
unit['number'] ??
unit['name'] ??
unit['unit_name'],
fallback: 'واحد',
);

final floor = _string(unit['floor'] ?? unit['floor_number']);

if (floor.isEmpty) return number;

return '$number - طبقه $floor';
}

// --------------------------------------------------
// ذخیره گروه‌ها
// --------------------------------------------------

Future<void> _saveItems() async {
final selectedGroups = _groups.where((group) {
return _bool(group['selected']);
}).toList();

if (selectedGroups.isEmpty) {
_message(
'حداقل یک هزینه را برای محاسبه انتخاب کن.',
error: true,
);
return;
}

for (final group in selectedGroups) {
final scope = _string(group['scope']);

if (scope == 'selected') {
final ids = group['selected_unit_ids'];

if (ids is! List || ids.isEmpty) {
_message(
'برای هزینه «${_groupTitle(group)}» '
'حداقل یک واحد انتخاب کن.',
error: true,
);
return;
}
}

final groupId = _groupId(group);

if (groupId <= 0) {
_message(
'شناسه هزینه «${_groupTitle(group)}» معتبر نیست.',
error: true,
);
return;
}
}

final payload = <Map<String, dynamic>>[];

for (final group in _groups) {
payload.add({
'type': _string(group['type'], fallback: 'expense'),
'group_id': _groupId(group),
'selected': _bool(group['selected']),
'basis': _string(group['basis'], fallback: 'equal'),
'scope': _string(group['scope'], fallback: 'all'),
'selected_unit_ids':
(group['selected_unit_ids'] as List? ?? [])
    .map((id) => _int(id))
    .where((id) => id > 0)
    .toList(),
});
}

setState(() => _saving = true);

try {
  await _service.saveCalculationItems(
    widget.calculationId,
    groups: payload,
  );

  if (!mounted) return;

  _message('تنظیمات تسهیم هزینه ذخیره شد.');

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ManagerChargeCalculationUnitsScreen(
        calculationId: widget.calculationId,
        calculationName: widget.calculationName,
      ),
    ),
  );
} catch (e) {
_message(
e.toString().replaceFirst('Exception: ', ''),
error: true,
);
} finally {
if (mounted) {
setState(() => _saving = false);
}
}
}

int _groupId(Map<String, dynamic> group) {
return _int(
group['group_id'] ??
group['id'] ??
group['pk'] ??
group['source_id'],
);
}

String _groupTitle(Map<String, dynamic> group) {
return _string(
group['title'] ??
group['name'] ??
group['description'] ??
group['maintenance_description'] ??
group['category_name'],
fallback: 'هزینه بدون عنوان',
);
}

String _groupTypeLabel(Map<String, dynamic> group) {
return _string(group['type']) == 'maintenance'
? 'تعمیر و نگهداری'
    : 'هزینه';
}

dynamic _groupAmount(Map<String, dynamic> group) {
return group['amount'] ??
group['total_amount'] ??
group['maintenance_price'] ??
group['expense_amount'] ??
group['price'];
}

// --------------------------------------------------
// کارت هزینه
// --------------------------------------------------

Widget _buildGroupCard(
Map<String, dynamic> group,
int index,
) {
final selected = _bool(group['selected']);
final basis = _string(group['basis'], fallback: 'equal');
final scope = _string(group['scope'], fallback: 'all');

final selectedIds =
(group['selected_unit_ids'] as List? ?? [])
    .map((value) => _int(value))
    .where((id) => id > 0)
    .toSet();

final amount = _groupAmount(group);

return Card(
margin: const EdgeInsets.only(bottom: 12),
elevation: 1,
color: selected ? Colors.white : Colors.grey.shade100,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
side: BorderSide(
color: selected
? _primaryColor.withValues(alpha: 0.35)
    : Colors.black12,
),
),
child: Padding(
padding: const EdgeInsets.all(14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Checkbox(
value: selected,
activeColor: _primaryColor,
onChanged: (value) {
_toggleSelected(index, value ?? false);
},
),
Expanded(
child: Padding(
padding: const EdgeInsets.only(top: 10),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
_groupTitle(group),
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 14,
color: selected
? Colors.black87
    : Colors.black45,
),
),
const SizedBox(height: 5),
Text(
'${_groupTypeLabel(group)}'
' • شناسه: ${_groupId(group)}',
style: const TextStyle(
fontSize: 11,
color: Colors.black54,
),
),
],
),
),
),
if (amount != null)
Padding(
padding: const EdgeInsets.only(top: 10),
child: Text(
'${_money(amount)} تومان',
style: const TextStyle(
color: _purpleColor,
fontSize: 12,
fontWeight: FontWeight.bold,
),
),
),
],
),
if (selected) ...[
const Divider(height: 24),
const Text(
'روش محاسبه سهم هر واحد',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 12,
),
),
const SizedBox(height: 8),
DropdownButtonFormField<String>(
value: basis,
isExpanded: true,
decoration: const InputDecoration(
border: OutlineInputBorder(),
contentPadding: EdgeInsets.symmetric(
horizontal: 12,
vertical: 10,
),
prefixIcon: Icon(
Icons.calculate_outlined,
color: _purpleColor,
),
),
items: const [
DropdownMenuItem(
value: 'equal',
child: Text('تقسیم مساوی بین واحدها'),
),
DropdownMenuItem(
value: 'area',
child: Text('بر اساس متراژ واحد'),
),
DropdownMenuItem(
value: 'person',
child: Text('بر اساس تعداد نفرات'),
),
],
onChanged: (value) {
if (value != null) {
_changeBasis(index, value);
}
},
),
const SizedBox(height: 14),
const Text(
'واحدهای مشمول هزینه',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 12,
),
),
const SizedBox(height: 8),
DropdownButtonFormField<String>(
value: scope,
isExpanded: true,
decoration: const InputDecoration(
border: OutlineInputBorder(),
contentPadding: EdgeInsets.symmetric(
horizontal: 12,
vertical: 10,
),
prefixIcon: Icon(
Icons.apartment_outlined,
color: _primaryColor,
),
),
items: const [
DropdownMenuItem(
value: 'all',
child: Text('تمام واحدها'),
),
DropdownMenuItem(
value: 'occupied',
child: Text('فقط واحدهای ساکن'),
),
DropdownMenuItem(
value: 'vacant',
child: Text('فقط واحدهای خالی'),
),
DropdownMenuItem(
value: 'selected',
child: Text('واحدهای انتخاب‌شده'),
),
],
onChanged: (value) {
if (value != null) {
_changeScope(index, value);
}
},
),
if (scope == 'selected') ...[
const SizedBox(height: 10),
OutlinedButton.icon(
style: OutlinedButton.styleFrom(
foregroundColor: _purpleColor,
),
onPressed: () => _selectUnits(index),
icon: const Icon(Icons.checklist),
label: Text(
selectedIds.isEmpty
? 'انتخاب واحدها'
    : '${selectedIds.length} واحد انتخاب شده '
'• تغییر انتخاب',
),
),
],
],
],
),
),
);
}

// --------------------------------------------------
// خلاصه
// --------------------------------------------------

Widget _buildSummary() {
final selectedCount = _groups.where(
(group) => _bool(group['selected']),
).length;

return Container(
padding: const EdgeInsets.all(14),
decoration: BoxDecoration(
color: _primaryColor.withValues(alpha: 0.08),
borderRadius: BorderRadius.circular(12),
border: Border.all(
color: _primaryColor.withValues(alpha: 0.2),
),
),
child: Row(
children: [
const Icon(
Icons.check_circle_outline,
color: _primaryColor,
size: 28,
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'هزینه‌های انتخاب‌شده',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 4),
Text(
'$selectedCount از ${_groups.length} هزینه',
style: const TextStyle(
color: Colors.black54,
fontSize: 12,
),
),
],
),
),
Text(
'${_units.length} واحد',
style: const TextStyle(
color: _purpleColor,
fontWeight: FontWeight.bold,
),
),
],
),
);
}

// --------------------------------------------------
// رابط کاربری
// --------------------------------------------------

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFF6F8FA),
appBar: AppBar(
backgroundColor: _primaryColor,
foregroundColor: Colors.white,
title: const Text(
'انتخاب هزینه‌ها و تسهیم',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 16,
),
),
centerTitle: true,
actions: [
IconButton(
tooltip: 'بارگذاری مجدد',
onPressed: _loading ? null : _loadItems,
icon: const Icon(Icons.refresh),
),
],
),
bottomNavigationBar: SafeArea(
minimum: const EdgeInsets.all(14),
child: FilledButton.icon(
style: FilledButton.styleFrom(
backgroundColor: _purpleColor,
minimumSize: const Size.fromHeight(52),
),
onPressed: _loading || _saving || _groups.isEmpty
? null
    : _saveItems,
icon: _saving
? const SizedBox(
width: 20,
height: 20,
child: CircularProgressIndicator(
color: Colors.white,
strokeWidth: 2,
),
)
    : const Icon(Icons.save_outlined),
label: Text(
_saving ? 'در حال ذخیره...' : 'ذخیره تنظیمات تسهیم',
),
),
),
body: _loading && _groups.isEmpty
? const Center(
child: CircularProgressIndicator(
color: _primaryColor,
),
)
    : RefreshIndicator(
onRefresh: _loadItems,
color: _primaryColor,
child: ListView(
physics: const AlwaysScrollableScrollPhysics(),
padding: const EdgeInsets.fromLTRB(
14,
14,
14,
24,
),
children: [
Container(
padding: const EdgeInsets.all(16),
decoration: const BoxDecoration(
gradient: LinearGradient(
colors: [_primaryColor, _purpleColor],
begin: Alignment.centerRight,
end: Alignment.centerLeft,
),
borderRadius: BorderRadius.all(
Radius.circular(14),
),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Row(
children: [
Icon(
Icons.tune,
color: Colors.white,
size: 30,
),
SizedBox(width: 10),
Expanded(
child: Text(
'تنظیم روش تسهیم هزینه‌ها',
style: TextStyle(
color: Colors.white,
fontWeight: FontWeight.bold,
fontSize: 16,
),
),
),
],
),
const SizedBox(height: 10),
Text(
widget.calculationName ??
'محاسبه شماره ${widget.calculationId}',
style: const TextStyle(
color: Colors.white,
fontSize: 13,
),
),
const SizedBox(height: 8),
const Text(
'هزینه‌های موردنظر را انتخاب کن، '
'روش محاسبه سهم را تعیین کن و مشخص کن '
'کدام واحدها مشمول هر هزینه باشند.',
style: TextStyle(
color: Colors.white,
height: 1.8,
fontSize: 12,
),
),
],
),
),
const SizedBox(height: 16),
if (_groups.isNotEmpty) _buildSummary(),
const SizedBox(height: 16),
if (_groups.isEmpty)
Container(
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(14),
),
child: Column(
children: [
const Icon(
Icons.inbox_outlined,
color: _primaryColor,
size: 54,
),
const SizedBox(height: 12),
const Text(
'هزینه‌ای برای نمایش دریافت نشد.',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 8),
const Text(
'بررسی کن که API اقلام محاسبه، '
'هزینه‌ها و تعمیرات را در پاسخ برگرداند.',
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.black54,
height: 1.8,
),
),
const SizedBox(height: 12),
OutlinedButton.icon(
onPressed: _loadItems,
icon: const Icon(Icons.refresh),
label: const Text('تلاش مجدد'),
),
],
),
)
else ...[
const Text(
'هزینه‌ها و تعمیرات',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 16,
),
),
const SizedBox(height: 10),
...List.generate(
_groups.length,
(index) => _buildGroupCard(
_groups[index],
index,
),
),
],
if (_response['message'] != null) ...[
const SizedBox(height: 8),
Text(
_string(_response['message']),
style: const TextStyle(
color: Colors.black54,
fontSize: 12,
),
),
],
],
),
),
);
}
}
