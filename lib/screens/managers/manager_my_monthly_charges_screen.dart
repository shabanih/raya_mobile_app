
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/manager_my_charge_service.dart';
import 'manager_my_monthly_charge_units_screen.dart';

class ManagerMonthlyChargesScreen extends StatefulWidget {
const ManagerMonthlyChargesScreen({super.key});

@override
State<ManagerMonthlyChargesScreen> createState() =>
_ManagerMonthlyChargesScreenState();
}

class _ManagerMonthlyChargesScreenState
extends State<ManagerMonthlyChargesScreen> {
static const Color _teal = Color(0xFF00ACC1);
static const Color _purple = Color(0xFF610DB5);

final ManagerMyChargeService _service = ManagerMyChargeService();

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
  final rows = await _service.getMonthlyCharges();

if (!mounted) return;

setState(() {
_charges = rows;
_loading = false;
});
} catch (e) {
if (!mounted) return;

setState(() {
_error = _cleanError(e);
_loading = false;
});
}
}

String _cleanError(Object error) {
return error.toString().replaceFirst('Exception: ', '');
}

String _value(
Map<String, dynamic> row,
List<String> keys, {
String fallback = '—',
}) {
for (final key in keys) {
final value = row[key];
if (value != null && value.toString().trim().isNotEmpty) {
return value.toString();
}
}
return fallback;
}

int _number(Map<String, dynamic> row, String key) {
final value = row[key];
if (value is num) return value.toInt();
return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _money(dynamic value) {
final number = value is num
? value.toInt()
    : int.tryParse(value?.toString() ?? '');

if (number == null) return '—';

final text = number.abs().toString();
final buffer = StringBuffer();

for (var i = 0; i < text.length; i++) {
if (i > 0 && (text.length - i) % 3 == 0) {
buffer.write(',');
}
buffer.write(text[i]);
}

return '${number < 0 ? '-' : ''}$buffer';
}

Future<void> _openCharge(Map<String, dynamic> charge) async {
final idValue = charge['id'];
final id = idValue is num
? idValue.toInt()
    : int.tryParse(idValue?.toString() ?? '');

final appLabel = charge['app_label']?.toString();
final modelName = charge['model_name']?.toString();

if (id == null ||
appLabel == null ||
appLabel.isEmpty ||
modelName == null ||
modelName.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('اطلاعات شناسایی این شارژ کامل نیست.'),
),
);
return;
}

final title = _value(
charge,
['name', 'title', 'details'],
fallback: 'شارژ شماره $id',
);

await Navigator.push(
context,
MaterialPageRoute(
builder: (_) => ManagerMonthlyChargeUnitsScreen(
chargeId: id,
appLabel: appLabel,
modelName: modelName,
chargeTitle: title,
),
),
);
}

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
backgroundColor: const Color(0xFFF6F8FB),
appBar: AppBar(
title: const Text(
'شارژهای ماهیانه',
style: TextStyle(fontWeight: FontWeight.bold),
),
centerTitle: true,
backgroundColor: _teal,
foregroundColor: Colors.white,
actions: [
IconButton(
tooltip: 'بارگذاری مجدد',
onPressed: _loadCharges,
icon: const Icon(Icons.refresh_rounded),
),
],
),
body: _buildBody(),
),
);
}

Widget _buildBody() {
if (_loading) {
return const Center(
child: CircularProgressIndicator(color: _teal),
);
}

if (_error != null) {
return _MessageView(
icon: Icons.cloud_off_rounded,
message: _error!,
buttonText: 'تلاش مجدد',
onPressed: _loadCharges,
);
}

if (_charges.isEmpty) {
return _MessageView(
icon: Icons.receipt_long_rounded,
message: 'هنوز شارژی برای نمایش وجود ندارد.',
buttonText: 'بارگذاری مجدد',
onPressed: _loadCharges,
);
}

return RefreshIndicator(
onRefresh: _loadCharges,
color: _teal,
child: ListView.builder(
padding: const EdgeInsets.all(14),
itemCount: _charges.length,
itemBuilder: (context, index) {
final charge = _charges[index];

final title = _value(
charge,
['name', 'title', 'details'],
fallback: 'شارژ شماره ${charge['id'] ?? ''}',
);

final total = _number(charge, 'total_count');
final notified = _number(charge, 'notified_count');
final paid = _number(charge, 'paid_count');

final isCalculation =
charge['is_charge_calculation'] == true;

final date = _value(
charge,
['created_at', 'created_date'],
);

final status = _value(
charge,
['status_display', 'status'],
fallback: isCalculation ? 'محاسبه شارژ' : 'شارژ ماهیانه',
);

return Card(
margin: const EdgeInsets.only(bottom: 12),
elevation: 1,
color: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
side: BorderSide(color: Colors.grey.shade200),
),
clipBehavior: Clip.antiAlias,
child: InkWell(
onTap: () => _openCharge(charge),
child: Padding(
padding: const EdgeInsets.all(15),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
width: 46,
height: 46,
decoration: BoxDecoration(
color: _teal.withValues(alpha: 0.12),
borderRadius: BorderRadius.circular(13),
),
child: Icon(
isCalculation
? Icons.calculate_rounded
    : Icons.receipt_long_rounded,
color: _teal,
size: 26,
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
maxLines: 2,
overflow: TextOverflow.ellipsis,
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
),
const SizedBox(height: 5),
Text(
status,
style: TextStyle(
color: Colors.grey.shade600,
fontSize: 12,
),
),
],
),
),
const Icon(
Icons.chevron_left_rounded,
color: _purple,
),
],
),
const SizedBox(height: 14),
if (date != '—')
_InfoLine(
icon: Icons.calendar_today_rounded,
label: 'تاریخ ثبت',
value: date,
),
if (charge['start_date'] != null ||
charge['end_date'] != null)
_InfoLine(
icon: Icons.date_range_rounded,
label: 'دوره شارژ',
value:
'${charge['start_date'] ?? '—'} تا ${charge['end_date'] ?? '—'}',
),
if (charge['payment_deadline'] != null)
_InfoLine(
icon: Icons.event_available_rounded,
label: 'مهلت پرداخت',
value: charge['payment_deadline'].toString(),
),
if (charge['other_cost_amount'] != null)
_InfoLine(
icon: Icons.payments_outlined,
label: 'هزینه‌های دیگر',
value:
'${_money(charge['other_cost_amount'])} تومان',
),
const Divider(height: 22),
Row(
children: [
Expanded(
child: _CountBox(
label: 'کل واحدها',
count: total,
color: _purple,
),
),
const SizedBox(width: 7),
Expanded(
child: _CountBox(
label: 'اعلان‌شده',
count: notified,
color: _teal,
),
),
const SizedBox(width: 7),
Expanded(
child: _CountBox(
label: 'پرداخت‌شده',
count: paid,
color: Colors.green,
),
),
],
),
const SizedBox(height: 10),
Align(
alignment: Alignment.centerLeft,
child: Text(
'مشاهده واحدها',
style: TextStyle(
color: _purple,
fontWeight: FontWeight.bold,
fontSize: 12,
),
),
),
],
),
),
),
);
},
),
);
}
}

class _InfoLine extends StatelessWidget {
final IconData icon;
final String label;
final String value;

const _InfoLine({
required this.icon,
required this.label,
required this.value,
});

@override
Widget build(BuildContext context) {
return Padding(
padding: const EdgeInsets.only(top: 7),
child: Row(
children: [
Icon(icon, size: 17, color: Colors.grey.shade600),
const SizedBox(width: 7),
Text(
'$label: ',
style: TextStyle(
fontSize: 12,
color: Colors.grey.shade700,
),
),
Expanded(
child: Text(
value,
textAlign: TextAlign.start,
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
),
),
),
],
),
);
}
}

class _CountBox extends StatelessWidget {
final String label;
final int count;
final Color color;

const _CountBox({
required this.label,
required this.count,
required this.color,
});

@override
Widget build(BuildContext context) {
return Container(
padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
decoration: BoxDecoration(
color: color.withValues(alpha: 0.08),
borderRadius: BorderRadius.circular(10),
),
child: Column(
children: [
Text(
count.toString(),
style: TextStyle(
color: color,
fontWeight: FontWeight.bold,
fontSize: 17,
),
),
const SizedBox(height: 4),
Text(
label,
textAlign: TextAlign.center,
style: const TextStyle(fontSize: 10),
),
],
),
);
}
}

class _MessageView extends StatelessWidget {
final IconData icon;
final String message;
final String buttonText;
final VoidCallback onPressed;

const _MessageView({
required this.icon,
required this.message,
required this.buttonText,
required this.onPressed,
});

@override
Widget build(BuildContext context) {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(icon, size: 54, color: Colors.grey.shade400),
const SizedBox(height: 14),
Text(message, textAlign: TextAlign.center),
const SizedBox(height: 16),
FilledButton(
onPressed: onPressed,
child: Text(buttonText),
),
],
),
),
);
}
}
