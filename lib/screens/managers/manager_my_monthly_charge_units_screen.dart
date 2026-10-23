
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/manager_my_charge_service.dart';
class ManagerMonthlyChargeUnitsScreen extends StatefulWidget {
final int chargeId;
final String appLabel;
final String modelName;
final String chargeTitle;

const ManagerMonthlyChargeUnitsScreen({
super.key,
required this.chargeId,
required this.appLabel,
required this.modelName,
required this.chargeTitle,
});

@override
State<ManagerMonthlyChargeUnitsScreen> createState() =>
_ManagerMonthlyChargeUnitsScreenState();
}

class _ManagerMonthlyChargeUnitsScreenState
extends State<ManagerMonthlyChargeUnitsScreen> {
static const Color _teal = Color(0xFF00ACC1);
static const Color _purple = Color(0xFF610DB5);

final ManagerMyChargeService _service = ManagerMyChargeService();

List<Map<String, dynamic>> _units = [];
bool _loading = true;
String? _error;

@override
void initState() {
super.initState();
_loadUnits();
}

Future<void> _loadUnits() async {
setState(() {
_loading = true;
_error = null;
});

try {
  final rows = await _service.getMonthlyChargeUnits(
    chargeId: widget.chargeId,
    appLabel: widget.appLabel,
    modelName: widget.modelName,
  );

if (!mounted) return;

setState(() {
_units = rows;
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

String _text(
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

int? _amount(dynamic value) {
if (value is num) return value.toInt();
return int.tryParse(value?.toString() ?? '');
}

String _money(dynamic value) {
final number = _amount(value);
if (number == null) return '—';

final digits = number.abs().toString();
final buffer = StringBuffer();

for (var i = 0; i < digits.length; i++) {
if (i > 0 && (digits.length - i) % 3 == 0) {
buffer.write(',');
}
buffer.write(digits[i]);
}

return '${number < 0 ? '-' : ''}$buffer';
}

bool _bool(Map<String, dynamic> row, String key) {
final value = row[key];
return value == true ||
value == 1 ||
value?.toString().toLowerCase() == 'true';
}

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
backgroundColor: const Color(0xFFF6F8FB),
appBar: AppBar(
title: const Text(
'واحدهای شارژ',
style: TextStyle(fontWeight: FontWeight.bold),
),
centerTitle: true,
backgroundColor: _teal,
foregroundColor: Colors.white,
actions: [
IconButton(
onPressed: _loadUnits,
tooltip: 'بارگذاری مجدد',
icon: const Icon(Icons.refresh_rounded),
),
],
),
body: Column(
children: [
Container(
width: double.infinity,
color: Colors.white,
padding: const EdgeInsets.all(16),
child: Row(
children: [
const Icon(
Icons.receipt_long_rounded,
color: _purple,
size: 30,
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
widget.chargeTitle,
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
),
const SizedBox(height: 5),
Text(
'شناسه شارژ: ${widget.chargeId}',
style: TextStyle(
color: Colors.grey.shade600,
fontSize: 12,
),
),
],
),
),
],
),
),
Expanded(child: _buildBody()),
],
),
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
return _message(
_error!,
Icons.cloud_off_rounded,
'تلاش مجدد',
);
}

if (_units.isEmpty) {
return _message(
'برای این شارژ، واحد اعلان‌شده‌ای پیدا نشد.',
Icons.home_work_outlined,
'بارگذاری مجدد',
);
}

return RefreshIndicator(
onRefresh: _loadUnits,
color: _teal,
child: ListView.builder(
padding: const EdgeInsets.all(12),
itemCount: _units.length,
itemBuilder: (context, index) {
final unit = _units[index];

final unitNumber = _text(
unit,
['unit_number', 'unit_id'],
fallback: 'نامشخص',
);

final title = _text(
unit,
['title'],
fallback: 'شارژ واحد $unitNumber',
);

final amount = unit['total_charge_month'] ??
unit['amount'] ??
unit['base_charge'];

final isPaid = _bool(unit, 'is_paid');
final isSmsSent = _bool(unit, 'send_sms');

return Card(
margin: const EdgeInsets.only(bottom: 10),
elevation: 1,
color: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(14),
side: BorderSide(color: Colors.grey.shade200),
),
child: Padding(
padding: const EdgeInsets.all(14),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Container(
width: 44,
height: 44,
decoration: BoxDecoration(
color: _purple.withValues(alpha: 0.09),
borderRadius: BorderRadius.circular(12),
),
child: const Icon(
Icons.home_work_rounded,
color: _purple,
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
title,
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 14,
),
),
const SizedBox(height: 5),
Text(
'شماره واحد: $unitNumber',
style: TextStyle(
color: Colors.grey.shade600,
fontSize: 12,
),
),
],
),
),
Icon(
isSmsSent
? Icons.sms_rounded
    : Icons.sms_outlined,
color: isSmsSent ? Colors.green : Colors.grey,
size: 22,
),
],
),
const Divider(height: 24),
_detail(
'مبلغ شارژ',
'${_money(amount)} تومان',
),
if (unit['other_cost_amount'] != null)
_detail(
'هزینه‌های دیگر',
'${_money(unit['other_cost_amount'])} تومان',
),
if (unit['civil'] != null &&
unit['civil'].toString() != '0')
_detail(
'هزینه عمرانی',
'${_money(unit['civil'])} تومان',
),
if (unit['penalty_amount'] != null &&
unit['penalty_amount'].toString() != '0')
_detail(
'جریمه',
'${_money(unit['penalty_amount'])} تومان',
),
if (unit['payment_deadline_date'] != null)
_detail(
'مهلت پرداخت',
unit['payment_deadline_date'].toString(),
),
if (unit['financial_document_number'] != null)
_detail(
'شماره سند مالی',
unit['financial_document_number'].toString(),
),
const SizedBox(height: 12),
Wrap(
spacing: 8,
runSpacing: 8,
children: [
_status(
isPaid ? 'پرداخت شده' : 'پرداخت نشده',
isPaid ? Colors.green : Colors.orange,
),
_status(
isSmsSent ? 'پیامک ارسال شده' : 'پیامک ارسال نشده',
isSmsSent ? Colors.green : Colors.grey,
),
],
),
],
),
),
);
},
),
);
}

Widget _detail(String label, String value) {
return Padding(
padding: const EdgeInsets.only(bottom: 9),
child: Row(
children: [
Expanded(
child: Text(
label,
style: TextStyle(
color: Colors.grey.shade700,
fontSize: 12,
),
),
),
const SizedBox(width: 12),
Flexible(
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

Widget _status(String text, Color color) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 7,
),
decoration: BoxDecoration(
color: color.withValues(alpha: 0.10),
borderRadius: BorderRadius.circular(9),
),
child: Text(
text,
style: TextStyle(
color: color,
fontSize: 11,
fontWeight: FontWeight.bold,
),
),
);
}

Widget _message(
String message,
IconData icon,
String buttonText,
) {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(icon, size: 52, color: Colors.grey.shade400),
const SizedBox(height: 14),
Text(message, textAlign: TextAlign.center),
const SizedBox(height: 16),
FilledButton(
onPressed: _loadUnits,
child: Text(buttonText),
),
],
),
),
);
}
}
