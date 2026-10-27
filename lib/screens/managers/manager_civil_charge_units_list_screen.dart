
import 'package:flutter/material.dart';

import '../../services/manager_civil_charge_list_service.dart';
import 'manager_civil_charge_installments_list_screen.dart';

class ManagerCivilChargeUnitsListScreen extends StatefulWidget {
const ManagerCivilChargeUnitsListScreen({
super.key,
required this.civilId,
this.civilName = '',
});

final int civilId;
final String civilName;

@override
State<ManagerCivilChargeUnitsListScreen> createState() =>
_ManagerCivilChargeUnitsListScreenState();
}

class _ManagerCivilChargeUnitsListScreenState
extends State<ManagerCivilChargeUnitsListScreen> {
static const Color teal = Color(0xFF00ACC1);
static const Color purple = Color(0xFF610DB5);

final ManagerCivilChargeListService _service =
ManagerCivilChargeListService();

final TextEditingController _searchController =
TextEditingController();

List<Map<String, dynamic>> _units = [];
bool _loading = true;
String? _error;
String _search = '';

@override
void initState() {
super.initState();
_loadUnits();
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

String _fa(dynamic value) {
const en = '0123456789';
const fa = '۰۱۲۳۴۵۶۷۸۹';
const ar = '٠١٢٣٤٥٦٧٨٩';

return value.toString().replaceAllMapped(
RegExp(r'[0-9٠-٩]'),
(match) {
final char = match.group(0)!;
final i = en.indexOf(char);

if (i >= 0) return fa[i];

final j = ar.indexOf(char);
return j >= 0 ? fa[j] : char;
},
);
}

int _number(dynamic value) {
if (value is num) return value.toInt();

var text = value?.toString().trim() ?? '';

const fa = '۰۱۲۳۴۵۶۷۸۹';
const ar = '٠١٢٣٤٥٦٧٨٩';

for (var i = 0; i < 10; i++) {
text = text.replaceAll(fa[i], '$i');
text = text.replaceAll(ar[i], '$i');
}

text = text
    .replaceAll(',', '')
    .replaceAll('٬', '')
    .replaceAll('،', '')
    .replaceAll('تومان', '')
    .trim();

return int.tryParse(text) ?? 0;
}

String _money(dynamic value) {
final number = _number(value);

return _fa(
number.toString().replaceAllMapped(
RegExp(r'\B(?=(\d{3})+(?!\d))'),
(match) => '٬',
),
);
}

List<Map<String, dynamic>> _installmentMaps(dynamic value) {
if (value is! List) return [];

return value
    .whereType<Map>()
    .map((item) => Map<String, dynamic>.from(item))
    .toList();
}

bool _isPaid(Map<String, dynamic> installment) {
final value = installment['is_paid'];

return value == true ||
value == 1 ||
value.toString().toLowerCase() == 'true';
}

String _residentName(Map<String, dynamic> unit) {
  String firstValue(List<String> keys) {
    for (final key in keys) {
      final value = unit[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value != 'null') {
        return value;
      }
    }
    return '';
  }

  final tenantName = firstValue([
    'active_tenant_name',
    'tenant_name',
    'renter_name',
    'resident_tenant_name',
  ]);

  final ownerName = firstValue([
    'owner_name',
    'property_owner_name',
  ]);

  final residentName = firstValue([
    'resident_name',
    'full_name',
    'name',
  ]);

  final isTenant = unit['is_renter'] == true ||
      unit['is_tenant'] == true ||
      unit['resident_type']?.toString().toLowerCase() == 'tenant' ||
      unit['resident_type']?.toString() == 'مستأجر';

  if (isTenant && tenantName.isNotEmpty) {
    return 'مستأجر: $tenantName';
  }

  if (ownerName.isNotEmpty) {
    return 'مالک: $ownerName';
  }

  if (tenantName.isNotEmpty) {
    return 'مستأجر: $tenantName';
  }

  if (residentName.isNotEmpty) {
    return '$residentName';
  }

  return 'ساکن فعالی ثبت نشده';
}

Map<String, dynamic> _calculateUnit(Map<String, dynamic> unit) {
final installments = _installmentMaps(unit['installments']);

// مجموع کل اقساط این واحد
final calculatedInstallmentsTotal = installments.fold<int>(
0,
(sum, item) => sum + _number(item['amount']),
);

// مبلغ اقساط پرداخت‌شده
final calculatedPaidAmount = installments.fold<int>(
0,
(sum, item) =>
sum + (_isPaid(item) ? _number(item['amount']) : 0),
);

// مبلغ اقساط پرداخت‌نشده
final calculatedRemainingAmount = installments.fold<int>(
0,
(sum, item) =>
sum + (!_isPaid(item) ? _number(item['amount']) : 0),
);

// تعداد اقساط
final calculatedPaidCount =
installments.where(_isPaid).length;

final calculatedUnpaidCount =
installments.where((item) => !_isPaid(item)).length;

// پیش‌پرداخت اختصاصی واحد
  int prepayment = _number(
    unit['prepayment'] ??
        unit['prepayment_per_unit'] ??
        unit['prepayment_amount'] ??
        unit['initial_payment'] ??
        unit['advance_payment'],
  );

  if (prepayment == 0 && installments.isNotEmpty) {
    prepayment = _number(
      installments.first['prepayment_per_unit'] ??
          installments.first['prepayment'] ??
          installments.first['prepayment_amount'],
    );
  }

// فیلدهای مالی API؛ در نبود آن‌ها از خود اقساط محاسبه می‌کنیم.
final apiInstallmentsTotal =
_number(unit['installments_total_amount']);

final installmentsTotal = unit.containsKey(
'installments_total_amount',
)
? apiInstallmentsTotal
    : calculatedInstallmentsTotal;

final apiTotal = _number(
unit['total_charge_amount'] ?? unit['amount'],
);

final totalAmount =
(unit.containsKey('total_charge_amount') ||
unit.containsKey('amount'))
? apiTotal
    : prepayment + installmentsTotal;

final paidAmount = unit.containsKey('paid_amount')
? _number(unit['paid_amount'])
    : calculatedPaidAmount;

final remainingAmount =
unit.containsKey('remaining_installments_amount')
? _number(unit['remaining_installments_amount'])
    : unit.containsKey('unpaid_amount')
? _number(unit['unpaid_amount'])
    : calculatedRemainingAmount;

final totalCount = unit.containsKey('total_installments')
? _number(unit['total_installments'])
    : installments.length;

final paidCount = unit.containsKey('paid_count')
? _number(unit['paid_count'])
    : calculatedPaidCount;

final unpaidCount = unit.containsKey('unpaid_count')
? _number(unit['unpaid_count'])
    : calculatedUnpaidCount;

return {
'installments': installments,
'prepayment': prepayment,
'installments_total_amount': installmentsTotal,
'total_charge_amount': totalAmount,
'paid_amount': paidAmount,
'remaining_amount': remainingAmount,
'total_installments': totalCount,
'paid_count': paidCount,
'unpaid_count': unpaidCount,
};
}

Future<void> _loadUnits({bool showLoader = true}) async {
if (showLoader && mounted) {
setState(() {
_loading = true;
_error = null;
});
}

try {
final units = await _service.getUnits(
civilId: widget.civilId,
search: _search,
);

if (!mounted) return;

final filteredUnits = units.where((unit) {
final installments = _installmentMaps(unit['installments']);
final total = _number(unit['total_installments']);

return total > 0 || installments.isNotEmpty;
}).toList();

setState(() {
_units = filteredUnits;
_loading = false;
_error = null;
});
} catch (e) {
if (!mounted) return;

setState(() {
_loading = false;
_error = e.toString().replaceFirst('Exception: ', '');
});
}
}

Future<void> _searchUnits(String value) async {
_search = value.trim();
await _loadUnits();
}

@override
Widget build(BuildContext context) {
final title = widget.civilName.trim().isEmpty
? 'لیست واحدها'
    : 'لیست واحدها';

return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
backgroundColor: const Color(0xFFF6F7FB),
appBar: AppBar(
title: Text(title),
centerTitle: true,
foregroundColor: Colors.white,
backgroundColor: teal,
actions: [
IconButton(
tooltip: 'بروزرسانی',
onPressed: () => _loadUnits(),
icon: const Icon(Icons.refresh),
),
],
),
body: Column(
children: [
Padding(
padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
child: TextField(
controller: _searchController,
textInputAction: TextInputAction.search,
onSubmitted: _searchUnits,
decoration: InputDecoration(
hintText: 'جست‌وجوی شماره واحد یا نام ساکن',
prefixIcon: const Icon(Icons.search, color: teal),
suffixIcon: IconButton(
onPressed: () {
_searchController.clear();
_searchUnits('');
},
icon: const Icon(Icons.close),
),
filled: true,
fillColor: Colors.white,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(14),
borderSide: BorderSide.none,
),
),
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
child: CircularProgressIndicator(color: teal),
);
}

if (_error != null) {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.error_outline,
color: Colors.red,
size: 42,
),
const SizedBox(height: 12),
Text(_error!, textAlign: TextAlign.center),
const SizedBox(height: 12),
ElevatedButton.icon(
onPressed: () => _loadUnits(),
icon: const Icon(Icons.refresh),
label: const Text('تلاش مجدد'),
),
],
),
),
);
}

if (_units.isEmpty) {
return RefreshIndicator(
onRefresh: _loadUnits,
child: ListView(
physics: const AlwaysScrollableScrollPhysics(),
children: const [
SizedBox(height: 110),
Icon(
Icons.apartment_outlined,
size: 60,
color: Colors.grey,
),
SizedBox(height: 14),
Center(
child: Text(
'واحد ارسال‌شده‌ای برای این شارژ پیدا نشد.',
),
),
],
),
);
}

return RefreshIndicator(
onRefresh: _loadUnits,
child: ListView.builder(
padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
physics: const AlwaysScrollableScrollPhysics(),
itemCount: _units.length,
itemBuilder: (context, index) {
final unit = _units[index];
final calculated = _calculateUnit(unit);

final unitId = _number(unit['id']);
final unitNumber = unit['unit']?.toString() ?? '—';
final resident = _residentName(unit);

final total = calculated['total_installments'] as int;
final paid = calculated['paid_count'] as int;
final unpaid = calculated['unpaid_count'] as int;

final totalAmount =
calculated['total_charge_amount'] as int;
final prepayment = calculated['prepayment'] as int;
final installmentsTotal =
calculated['installments_total_amount'] as int;
final paidAmount = calculated['paid_amount'] as int;
final remainingAmount =
calculated['remaining_amount'] as int;

final progress = total > 0
? (paid / total).clamp(0.0, 1.0)
    : 0.0;

return Card(
margin: const EdgeInsets.only(bottom: 12),
elevation: 1.5,
color: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(18),
),
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
color: teal.withValues(alpha: 0.12),
borderRadius: BorderRadius.circular(13),
),
child: const Icon(
Icons.apartment,
color: teal,
size: 27,
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'واحد ${_fa(unitNumber)}',
style: const TextStyle(
fontSize: 17,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 4),
Text(
resident,
style: TextStyle(
fontSize: 13,
color: Colors.grey.shade700,
),
),
],
),
),
if (paid > 0)
Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 6,
),
decoration: BoxDecoration(
color: paid >= total
? Colors.green.withValues(alpha: 0.10)
    : purple.withValues(alpha: 0.09),
borderRadius: BorderRadius.circular(10),
),
child: Text(
paid >= total ? 'اقساط تسویه' : '${_fa(paid)} از ${_fa(total)}',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.bold,
color: paid >= total ? Colors.green : purple,
),
),
),
],
),

const SizedBox(height: 16),

// مبلغ کل شامل پیش‌پرداخت و مجموع اقساط
_totalAmountBox(
totalAmount: totalAmount,
prepayment: prepayment,
installmentsTotal: installmentsTotal,
),

const SizedBox(height: 10),

Row(
children: [
Expanded(
child: _infoBox(
title: 'مبلغ پرداخت‌شده',
value: '${_money(paidAmount)} تومان',
subtitle: '${_fa(paid)} قسط',
icon: Icons.check_circle_outline,
color: Colors.green,
),
),
const SizedBox(width: 8),
Expanded(
child: _infoBox(
title: 'مانده اقساط',
value: '${_money(remainingAmount)} تومان',
subtitle: '${_fa(unpaid)} قسط',
icon: Icons.pending_actions,
color: Colors.deepOrange,
),
),
],
),

const SizedBox(height: 13),

ClipRRect(
borderRadius: BorderRadius.circular(10),
child: LinearProgressIndicator(
value: progress,
minHeight: 6,
backgroundColor: Colors.grey.shade200,
color: total > 0 && paid >= total
? Colors.green
    : teal,
),
),

const SizedBox(height: 14),

SizedBox(
width: double.infinity,
child: ElevatedButton.icon(
style: ElevatedButton.styleFrom(
backgroundColor: purple,
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(vertical: 12),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
onPressed: () async {
await Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
ManagerCivilChargeInstallmentsListScreen(
civilId: widget.civilId,
unitId: unitId,
unitName: 'واحد $unitNumber',
ownerName: resident,
civilName: widget.civilName,
),
),
);

if (mounted) {
_loadUnits();
}
},
icon: const Icon(Icons.receipt_long),
label: const Text('نمایش اقساط'),
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

Widget _totalAmountBox({
required int totalAmount,
required int prepayment,
required int installmentsTotal,
}) {
return Container(
width: double.infinity,
padding: const EdgeInsets.all(13),
decoration: BoxDecoration(
color: teal.withValues(alpha: 0.07),
borderRadius: BorderRadius.circular(13),
border: Border.all(color: teal.withValues(alpha: 0.18)),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Row(
children: [
Icon(
Icons.account_balance_wallet_outlined,
size: 19,
color: teal,
),
SizedBox(width: 7),
Text(
'مبلغ کل سهم واحد',
style: TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
),
),
],
),
const SizedBox(height: 7),
Text(
'${_money(totalAmount)} تومان',
style: const TextStyle(
fontSize: 19,
fontWeight: FontWeight.bold,
color: teal,
),
),
const Divider(height: 18),
_amountLine('پیش‌پرداخت', prepayment),
const SizedBox(height: 5),
_amountLine('مجموع کل اقساط', installmentsTotal),
],
),
);
}

Widget _amountLine(String title, int amount) {
return Row(
children: [
Expanded(
child: Text(
title,
style: TextStyle(
fontSize: 12,
color: Colors.grey.shade700,
),
),
),
Text(
'${_money(amount)} تومان',
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.w600,
),
),
],
);
}

Widget _infoBox({
required String title,
required String value,
required String subtitle,
required IconData icon,
required Color color,
}) {
return Container(
padding: const EdgeInsets.symmetric(
horizontal: 8,
vertical: 11,
),
decoration: BoxDecoration(
color: color.withValues(alpha: 0.07),
borderRadius: BorderRadius.circular(12),
),
child: Column(
children: [
Icon(icon, size: 19, color: color),
const SizedBox(height: 6),
Text(
title,
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 11,
color: Colors.grey.shade700,
),
),
const SizedBox(height: 5),
Text(
value,
textAlign: TextAlign.center,
style: const TextStyle(
fontSize: 12,
fontWeight: FontWeight.bold,
),
),
const SizedBox(height: 3),
Text(
subtitle,
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 10,
color: Colors.grey.shade600,
),
),
],
),
);
}
}
