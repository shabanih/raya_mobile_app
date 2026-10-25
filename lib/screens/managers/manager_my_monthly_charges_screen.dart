
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

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

return _persianDigits(
  '${number < 0 ? '-' : ''}$buffer',
);
}

String _persianDigits(String value) {
  const english = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';

  return value.split('').map((char) {
    final index = english.indexOf(char);
    return index >= 0 ? persian[index] : char;
  }).join();
}

String _jalaliDate(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) {
    return 'تعیین نشده';
  }

  final raw = value.toString().trim();
  final date = DateTime.tryParse(raw);

  if (date == null) {
    // اگر تاریخ از قبل شمسی یا با قالب دیگری آمده باشد،
    // آن را بدون تبدیل اشتباه نمایش می‌دهیم.
    return _persianDigits(raw);
  }

  final jalali = Jalali.fromDateTime(date);
  return _persianDigits(
    '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}',
  );
}


Future<void> _openCharge(Map<String, dynamic> charge) async {
  debugPrint('CHARGE DATA FOR DETAILS: $charge');

  final rawId = charge['id'] ?? charge['charge_id'];
  final id = rawId is num
      ? rawId.toInt()
      : int.tryParse(rawId?.toString() ?? '');

  final appLabel = charge['app_label']?.toString().trim();
  final modelName = charge['model_name']?.toString().trim();

  if (id == null ||
      appLabel == null ||
      appLabel.isEmpty ||
      modelName == null ||
      modelName.isEmpty) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'اطلاعات شارژ اصلی ناقص است؛ app_label و model_name باید از API دریافت شوند.',
        ),
      ),
    );
    return;
  }

  final title = _value(
    charge,
    ['name', 'title', 'details', 'charge_name'],
    fallback: 'شارژ شماره $id',
  );

  if (!mounted) return;

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ManagerMonthlyChargeUnitsScreen(
        chargeId: id,
        appLabel: appLabel,
        modelName: modelName.toLowerCase(),
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

  final deadline = _jalaliDate(charge['payment_deadline_date']);

  return Card(
  margin: const EdgeInsets.only(bottom: 14),
  elevation: 1,
  color: Colors.white,
  shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(16),
  side: BorderSide(color: Colors.grey.shade200),
  ),
  child: Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  // عنوان شارژ
  Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  Container(
  width: 44,
  height: 44,
  decoration: BoxDecoration(
  color: _teal.withValues(alpha: 0.12),
  borderRadius: BorderRadius.circular(12),
  ),
  child: const Icon(
  Icons.receipt_long_rounded,
  color: _teal,
  size: 25,
  ),
  ),
  const SizedBox(width: 12),
  Expanded(
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  const Text(
  'عنوان شارژ',
  style: TextStyle(
  color: Colors.grey,
  fontSize: 12,
  ),
  ),
  const SizedBox(height: 4),
  Text(
  _persianDigits(title),
  style: const TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.bold,
  ),
  ),
  ],
  ),
  ),
  ],
  ),

  const SizedBox(height: 18),
  const Divider(height: 1),
  const SizedBox(height: 15),

  // مهلت پرداخت
  Row(
  children: [
  const Icon(
  Icons.event_available_rounded,
  color: _purple,
  size: 21,
  ),
  const SizedBox(width: 9),
  const Expanded(
  child: Text(
  'مهلت پرداخت',
  style: TextStyle(fontSize: 13),
  ),
  ),
  Text(
  deadline,
  style: const TextStyle(
  fontWeight: FontWeight.bold,
  fontSize: 13,
  ),
  ),
  ],
  ),

  const SizedBox(height: 18),

  // اعلام شارژ
  _ChargeProgressRow(
  title: 'اعلام شارژ',
  icon: Icons.notifications_active_rounded,
  color: _teal,
  value: notified,
  total: total,
  ),

  const SizedBox(height: 16),

  // پرداخت شارژ
  _ChargeProgressRow(
  title: 'پرداخت شارژ',
  icon: Icons.payments_rounded,
  color: Colors.green,
  value: paid,
  total: total,
  ),

  const SizedBox(height: 20),

  // نمایش جزئیات و صورتحساب واحدها
  SizedBox(
  width: double.infinity,
  child: FilledButton.icon(
  onPressed: () => _openCharge(charge),
  icon: const Icon(Icons.receipt_long_rounded),
  label: const Text(
  'نمایش جزئیات و صورتحساب واحدها',
  style: TextStyle(fontWeight: FontWeight.bold),
  ),
  style: FilledButton.styleFrom(
  backgroundColor: _purple,
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 13),
  shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(12),
  ),
  ),
  ),
  ),
  ],
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

class _ChargeProgressRow extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int value;
  final int total;

  const _ChargeProgressRow({
    required this.title,
    required this.icon,
    required this.color,
    required this.value,
    required this.total,
  });

  String _persianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    return value.split('').map((char) {
      final index = english.indexOf(char);
      return index >= 0 ? persian[index] : char;
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    final progress = total > 0
        ? (value / total).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${_persianDigits(value.toString())} از '
                  '${_persianDigits(total.toString())} واحد',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: color.withValues(alpha: 0.12),
            color: color,
          ),
        ),
      ],
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
