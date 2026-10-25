
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

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
bool _paymentActionLoading = false;
String? _error;

@override
void initState() {
super.initState();
_loadUnits();
}

Future<void> _loadUnits() async {
if (mounted) {
setState(() {
_loading = true;
_error = null;
});
}

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
return value.toString().trim();
}
}

return fallback;
}

num _number(dynamic value) {
if (value is num) return value;

final normalized = _toEnglishDigits(value?.toString() ?? '')
    .replaceAll(',', '')
    .replaceAll('٬', '')
    .trim();

return num.tryParse(normalized) ?? 0;
}

String _toEnglishDigits(String input) {
const persian = '۰۱۲۳۴۵۶۷۸۹';
const arabic = '٠١٢٣٤٥٦٧٨٩';

var result = input;

for (var i = 0; i < 10; i++) {
result = result.replaceAll(persian[i], '$i');
result = result.replaceAll(arabic[i], '$i');
}

return result;
}

String _fa(String input) {
const english = '0123456789';
const persian = '۰۱۲۳۴۵۶۷۸۹';

var result = input;

for (var i = 0; i < 10; i++) {
result = result.replaceAll(english[i], persian[i]);
}

return result;
}

String _money(dynamic value) {
final number = _number(value).round();
final digits = number.abs().toString();
final buffer = StringBuffer();

for (var i = 0; i < digits.length; i++) {
if (i > 0 && (digits.length - i) % 3 == 0) {
buffer.write(',');
}

buffer.write(digits[i]);
}

final formatted = '${number < 0 ? '-' : ''}$buffer';
return _fa(formatted);
}

String _jalaliDate(dynamic value) {
if (value == null || value.toString().trim().isEmpty) {
return 'تعیین نشده';
}

final raw = _toEnglishDigits(value.toString().trim());

try {
final datePart = raw.split('T').first.split(' ').first;
final parts = datePart.split('-');

if (parts.length != 3) return _fa(raw);

final year = int.parse(parts[0]);
final month = int.parse(parts[1]);
final day = int.parse(parts[2]);

// اگر تاریخ از قبل شمسی باشد، همان را نمایش می‌دهیم.
if (year < 1700) {
return _fa(
'${year.toString().padLeft(4, '0')}/'
'${month.toString().padLeft(2, '0')}/'
'${day.toString().padLeft(2, '0')}',
);
}

final date = DateTime(year, month, day);
final jalali = Jalali.fromDateTime(date);

return _fa(
'${jalali.year.toString().padLeft(4, '0')}/'
'${jalali.month.toString().padLeft(2, '0')}/'
'${jalali.day.toString().padLeft(2, '0')}',
);
} catch (_) {
return _fa(raw);
}
}

bool _bool(Map<String, dynamic> row, String key) {
final value = row[key];

return value == true ||
value == 1 ||
value?.toString().toLowerCase() == 'true';
}

String _unitDisplay(Map<String, dynamic> unit) {
final apiDisplay = unit['unit_display']?.toString().trim();

if (apiDisplay != null && apiDisplay.isNotEmpty) {
return _fa(apiDisplay);
}

final number = _fa(
_text(unit, ['unit_number', 'unit_id'], fallback: 'نامشخص'),
);

final residentType = _text(
unit,
['resident_type_display'],
fallback: '',
);

final residentName = _text(
unit,
['resident_name'],
fallback: '',
);

if (residentType.isNotEmpty && residentName.isNotEmpty) {
return 'واحد $number - $residentType: $residentName';
}

return 'واحد $number';
}

num _chargeAmount(Map<String, dynamic> unit) {
if (unit['total_charge_month'] != null) {
return _number(unit['total_charge_month']);
}

return _number(unit['amount'] ?? unit['base_charge']);
}

num _payableAmount(Map<String, dynamic> unit) {
if (unit['payable_amount'] != null) {
return _number(unit['payable_amount']);
}

return _chargeAmount(unit) + _number(unit['penalty_amount']);
}

void _showChargeDetails(Map<String, dynamic> unit) {
final documentNumber = _text(
unit,
['financial_document_number'],
fallback: 'ثبت نشده',
);

final title = _text(
unit,
['title'],
fallback: widget.chargeTitle,
);

showDialog<void>(
context: context,
builder: (dialogContext) {
return Directionality(
textDirection: TextDirection.rtl,
child: AlertDialog(
title: const Row(
children: [
Icon(Icons.receipt_long_rounded, color: _purple),
SizedBox(width: 8),
Expanded(child: Text('جزئیات شارژ')),
],
),
content: SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
_detail('عنوان شارژ', title),
_detail('شماره سند', _fa(documentNumber)),
_detail(
'مبلغ شارژ',
'${_money(_chargeAmount(unit))} تومان',
),
_detail(
'هزینه‌های دیگر',
'${_money(unit['other_cost_amount'])} تومان',
),
_detail(
'هزینه عمرانی',
'${_money(unit['civil'])} تومان',
),
_detail(
'جریمه دیرکرد',
'${_money(unit['penalty_amount'])} تومان',
),
_detail(
'مبلغ قابل پرداخت',
'${_money(_payableAmount(unit))} تومان',
),
_detail(
'مهلت پرداخت',
_jalaliDate(unit['payment_deadline_date']),
),
_detail(
'وضعیت پرداخت',
_bool(unit, 'is_paid')
? 'پرداخت شده'
    : 'پرداخت نشده',
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
);
},
);
}

Future<void> _onPayPressed(Map<String, dynamic> unit) async {
if (_paymentActionLoading) return;

if (_bool(unit, 'is_paid')) {
await _cancelPayment();
return;
}

await _showPaymentDialog();
}

Future<void> _cancelPayment() async {
final confirmed = await showDialog<bool>(
context: context,
builder: (dialogContext) => Directionality(
textDirection: TextDirection.rtl,
child: AlertDialog(
title: const Text('لغو پرداخت'),
content: const Text(
'آیا از لغو پرداخت این شارژ مطمئن هستید؟\n'
'اسناد مالی مرتبط نیز اصلاح خواهند شد.',
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
child: const Text('بله، لغو پرداخت'),
),
],
),
),
);

if (confirmed != true || !mounted) return;

setState(() => _paymentActionLoading = true);

try {
await _service.cancelMonthlyChargePayment(
chargeId: widget.chargeId,
);

if (!mounted) return;

await _loadUnits();

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('پرداخت با موفقیت لغو شد.'),
),
);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
e.toString().replaceFirst('Exception: ', ''),
),
),
);
} finally {
if (mounted) {
setState(() => _paymentActionLoading = false);
}
}
}

Future<void> _showPaymentDialog() async {
List<Map<String, dynamic>> banks;

try {
banks = await _service.getMonthlyChargePaymentBanks(
chargeId: widget.chargeId,
);
} catch (e) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(
e.toString().replaceFirst('Exception: ', ''),
),
),
);

return;
}

if (!mounted) return;

if (banks.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'هیچ حساب بانکی فعالی برای این ساختمان وجود ندارد.',
),
),
);

return;
}

int? selectedBankId;

final defaultBanks = banks.where(
(bank) => bank['is_default'] == true,
);

if (defaultBanks.isNotEmpty) {
selectedBankId = (defaultBanks.first['id'] as num).toInt();
} else {
selectedBankId = (banks.first['id'] as num).toInt();
}

DateTime selectedDate = DateTime.now();
final referenceController = TextEditingController();
bool submitting = false;

try {
final result = await showDialog<bool>(
context: context,
barrierDismissible: false,
builder: (dialogContext) => Directionality(
textDirection: TextDirection.rtl,
child: StatefulBuilder(
builder: (ctx, setDialogState) => AlertDialog(
title: const Text('ثبت پرداخت شارژ'),
content: SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
DropdownButtonFormField<int>(
value: selectedBankId,
isExpanded: true,
decoration: const InputDecoration(
labelText: 'حساب بانکی',
border: OutlineInputBorder(),
),
items: banks.map((bank) {
final id = (bank['id'] as num).toInt();

return DropdownMenuItem<int>(
value: id,
child: Text(
bank['label']?.toString() ??
bank['bank_name']?.toString() ??
'حساب $id',
overflow: TextOverflow.ellipsis,
),
);
}).toList(),
onChanged: submitting
? null
    : (value) {
if (value != null) {
setDialogState(() {
selectedBankId = value;
});
}
},
),
const SizedBox(height: 16),
OutlinedButton.icon(
icon: const Icon(Icons.calendar_month),
label: Text(
'تاریخ پرداخت: '
'${selectedDate.year.toString().padLeft(4, '0')}-'
'${selectedDate.month.toString().padLeft(2, '0')}-'
'${selectedDate.day.toString().padLeft(2, '0')}',
),
onPressed: submitting
? null
    : () async {
final picked = await showDatePicker(
context: ctx,
initialDate: selectedDate,
firstDate: DateTime(2000),
lastDate: DateTime.now(),
);

if (picked != null) {
setDialogState(() {
selectedDate = picked;
});
}
},
),
const SizedBox(height: 16),
TextField(
controller: referenceController,
keyboardType: TextInputType.number,
decoration: const InputDecoration(
labelText: 'کد پیگیری (اختیاری)',
border: OutlineInputBorder(),
),
),
],
),
),
actions: [
TextButton(
onPressed: submitting
? null
    : () => Navigator.pop(ctx, false),
child: const Text('انصراف'),
),
FilledButton(
onPressed: submitting
? null
    : () async {
if (selectedBankId == null) {
ScaffoldMessenger.of(ctx).showSnackBar(
const SnackBar(
content: Text(
'لطفاً حساب بانکی را انتخاب کنید.',
),
),
);
return;
}

setDialogState(() => submitting = true);

try {
await _service.payMonthlyCharge(
chargeId: widget.chargeId,
bankId: selectedBankId!,
paymentDate:
'${selectedDate.year.toString().padLeft(4, '0')}-'
'${selectedDate.month.toString().padLeft(2, '0')}-'
'${selectedDate.day.toString().padLeft(2, '0')}',
transactionReference:
referenceController.text.trim(),
);

if (ctx.mounted) {
Navigator.pop(ctx, true);
}
} catch (e) {
setDialogState(() => submitting = false);

ScaffoldMessenger.of(ctx).showSnackBar(
SnackBar(
content: Text(
e.toString().replaceFirst(
'Exception: ',
'',
),
),
),
);
}
},
child: submitting
? const SizedBox(
width: 18,
height: 18,
child: CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
)
    : const Text('ثبت پرداخت'),
),
],
),
),
),
);

if (result == true && mounted) {
setState(() => _paymentActionLoading = true);

try {
await _loadUnits();

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('پرداخت با موفقیت ثبت شد.'),
),
);
} finally {
if (mounted) {
setState(() => _paymentActionLoading = false);
}
}
}
} finally {
referenceController.dispose();
}
}

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
backgroundColor: const Color(0xFFF6F8FB),
appBar: AppBar(
title: const Text(
'صورتحساب واحدها',
style: TextStyle(fontWeight: FontWeight.bold),
),
centerTitle: true,
backgroundColor: _teal,
foregroundColor: Colors.white,
actions: [
IconButton(
onPressed: _paymentActionLoading ? null : _loadUnits,
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
child: Text(
widget.chargeTitle,
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
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

final unitDisplay = _unitDisplay(unit);
final title = _text(
unit,
['title'],
fallback: widget.chargeTitle,
);

final documentNumber = _text(
unit,
['financial_document_number'],
fallback: '',
);

final isPaid = _bool(unit, 'is_paid');
final penalty = _number(unit['penalty_amount']);
final chargeAmount = _chargeAmount(unit);
final payableAmount = _payableAmount(unit);

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
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
unitDisplay,
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 14,
),
),
const SizedBox(height: 7),
Row(
children: [
if (documentNumber.isNotEmpty) ...[
Flexible(
child: Text(
'سند ${_fa(documentNumber)}',
style: const TextStyle(
color: _purple,
fontSize: 12,
fontWeight: FontWeight.bold,
),
),
),
const SizedBox(width: 6),
Text(
'•',
style: TextStyle(
color: Colors.grey.shade500,
),
),
const SizedBox(width: 6),
],
Expanded(
child: Text(
title,
style: TextStyle(
color: Colors.grey.shade700,
fontSize: 12,
),
),
),
],
),
],
),
),
const SizedBox(width: 4),
IconButton(
onPressed: () => _showChargeDetails(unit),
tooltip: 'مشاهده جزئیات شارژ',
visualDensity: VisualDensity.compact,
icon: const Icon(
Icons.visibility_outlined,
color: _purple,
),
),
],
),
const Divider(height: 24),
_detail(
'مبلغ شارژ',
'${_money(chargeAmount)} تومان',
),
_detail(
'مبلغ جریمه دیرکرد',
'${_money(penalty)} تومان',
),
_detail(
'مبلغ قابل پرداخت',
'${_money(payableAmount)} تومان',
),
_detail(
'مهلت پرداخت',
_jalaliDate(unit['payment_deadline_date']),
),
const SizedBox(height: 8),
Row(
children: [
_status(
isPaid ? 'پرداخت شده' : 'پرداخت نشده',
isPaid ? Colors.green : Colors.orange,
),
const Spacer(),
FilledButton.icon(
onPressed: _paymentActionLoading
? null
    : () => _onPayPressed(unit),
style: FilledButton.styleFrom(
backgroundColor: isPaid ? Colors.red : _teal,
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(
horizontal: 16,
vertical: 10,
),
),
icon: _paymentActionLoading
? const SizedBox(
width: 18,
height: 18,
child: CircularProgressIndicator(
strokeWidth: 2,
color: Colors.white,
),
)
    : Icon(
isPaid
? Icons.cancel_outlined
    : Icons.payment_rounded,
size: 18,
),
label: Text(
_paymentActionLoading
? 'لطفاً صبر کنید'
    : isPaid
? 'لغو پرداخت'
    : 'پرداخت',
),
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
padding: const EdgeInsets.only(bottom: 10),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
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
