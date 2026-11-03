
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../services/manager_creditor_report_service.dart';

class ManagerCreditorUnitsScreen extends StatefulWidget {
const ManagerCreditorUnitsScreen({super.key});

@override
State<ManagerCreditorUnitsScreen> createState() =>
_ManagerCreditorUnitsScreenState();
}

class _ManagerCreditorUnitsScreenState
extends State<ManagerCreditorUnitsScreen> {

static const Color primaryColor = Color(0xFF00ACC1);
static const Color secondaryColor = Color(0xFF610DB5);

late final ManagerCreditorReportService _service;

final TextEditingController _searchController =
TextEditingController();

String _residentType = 'all';

bool _loading = false;
String? _error;

List<Map<String, dynamic>> _creditors = [];

int _totalCreditorAmount = 0;
int _count = 0;

@override
void initState() {
super.initState();

_service = ManagerCreditorReportService(
apiService: ApiService(),
);

_loadCreditors();
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

// =====================================================
// دریافت اطلاعات
// =====================================================

Future<void> _loadCreditors() async {
if (!mounted) return;

setState(() {
_loading = true;
_error = null;
});

try {
final result = await _service.getCreditorUnits(

query: _searchController.text.trim(),
residentType: _residentType,
limit: 100,
);

if (!mounted) return;

final receivedCreditors =
List<Map<String, dynamic>>.from(
result['results'] ?? [],
);

// فقط افراد دارای اعتبار مثبت
final filteredCreditors = receivedCreditors.where((creditor) {
return _toInt(creditor['creditor_amount']) > 0;
}).toList();

setState(() {
_creditors = filteredCreditors;

_totalCreditorAmount =
_toInt(result['total_creditor_amount']);

_count = filteredCreditors.length;
});
} catch (e) {
if (!mounted) return;

setState(() {
_error = e.toString().replaceFirst('Exception: ', '');
});
} finally {
if (mounted) {
setState(() {
_loading = false;
});
}
}
}

// =====================================================
// تبدیل عدد به int
// =====================================================

int _toInt(dynamic value) {
if (value is int) return value;
if (value is num) return value.toInt();

return int.tryParse(
value?.toString() ?? '',
) ??
0;
}

// =====================================================
// تبدیل اعداد به فارسی
// =====================================================

String _toPersianDigits(String value) {
const englishDigits = '0123456789';
const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
const arabicDigits = '٠١٢٣٤٥٦٧٨٩';

for (int i = 0; i < 10; i++) {
value = value.replaceAll(
englishDigits[i],
persianDigits[i],
);

value = value.replaceAll(
arabicDigits[i],
persianDigits[i],
);
}

return value;
}

// =====================================================
// فرمت مبلغ
// =====================================================

String _formatMoney(dynamic value) {
final amount = _toInt(value);

final formatted = NumberFormat('#,###').format(amount);

return '${_toPersianDigits(formatted)} تومان';
}

// =====================================================
// جستجو
// =====================================================

void _onSearchChanged(String value) {
_loadCreditors();
}

// =====================================================
// تغییر فیلتر
// =====================================================

void _changeResidentType(String value) {
if (_residentType == value) return;

setState(() {
_residentType = value;
});

_loadCreditors();
}

// =====================================================
// کارت خلاصه
// =====================================================

Widget _buildSummaryCard() {
return Container(
padding: const EdgeInsets.all(18),
decoration: BoxDecoration(
gradient: const LinearGradient(
colors: [
primaryColor,
secondaryColor,
],
begin: Alignment.topRight,
end: Alignment.bottomLeft,
),
borderRadius: BorderRadius.circular(18),
),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'مجموع اعتبار واحدها',
style: TextStyle(
color: Colors.white,
fontSize: 14,
),
),

const SizedBox(height: 10),

Text(
_formatMoney(_totalCreditorAmount),
style: const TextStyle(
color: Colors.white,
fontSize: 22,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 12),

Row(
children: [
const Icon(
Icons.people_alt_outlined,
color: Colors.white70,
size: 19,
),

const SizedBox(width: 7),

Text(
'تعداد بستانکاران: '
'${_toPersianDigits(_count.toString())}',
style: const TextStyle(
color: Colors.white,
fontSize: 13,
),
),
],
),
],
),
);
}

// =====================================================
// فیلترها
// =====================================================

Widget _buildFilters() {
return Container(
padding: const EdgeInsets.all(5),
decoration: BoxDecoration(
color: Colors.grey.shade100,
borderRadius: BorderRadius.circular(13),
),
child: Row(
children: [
_filterItem('all', 'همه'),
_filterItem('owner', 'مالک'),
_filterItem('renter', 'مستأجر'),
],
),
);
}

Widget _filterItem(String value, String title) {
final selected = _residentType == value;

return Expanded(
child: GestureDetector(
onTap: () => _changeResidentType(value),
child: AnimatedContainer(
duration: const Duration(milliseconds: 200),
padding: const EdgeInsets.symmetric(vertical: 11),
decoration: BoxDecoration(
color: selected ? Colors.white : Colors.transparent,
borderRadius: BorderRadius.circular(10),
boxShadow: selected
? [
BoxShadow(
color: Colors.black.withValues(alpha: 0.06),
blurRadius: 5,
),
]
    : [],
),
child: Center(
child: Text(
title,
style: TextStyle(
color: selected
? secondaryColor
    : Colors.grey.shade700,
fontWeight: selected
? FontWeight.bold
    : FontWeight.normal,
),
),
),
),
),
);
}

// =====================================================
// کارت بستانکار
// =====================================================

Widget _buildCreditorCard(Map<String, dynamic> creditor) {
final unitNumber = _toPersianDigits(
creditor['unit_number']?.toString() ?? '-',
);

final name = _toPersianDigits(
creditor['resident_name']?.toString() ?? '-',
);

final type = creditor['resident_type']?.toString() ?? '';

final isOwner = type == 'owner';

final creditorAmount = creditor['creditor_amount'];

return Container(
margin: const EdgeInsets.only(bottom: 12),
padding: const EdgeInsets.all(15),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(15),
border: Border.all(
color: Colors.grey.shade200,
),
boxShadow: [
BoxShadow(
color: Colors.black.withValues(alpha: 0.035),
blurRadius: 8,
offset: const Offset(0, 3),
),
],
),
child: Column(
children: [
Row(
children: [
Container(
width: 45,
height: 45,
decoration: BoxDecoration(
color: isOwner
? primaryColor.withValues(alpha: 0.12)
    : secondaryColor.withValues(alpha: 0.10),
borderRadius: BorderRadius.circular(12),
),
child: Icon(
isOwner
? Icons.person_outline
    : Icons.person_2_outlined,
color: isOwner
? primaryColor
    : secondaryColor,
),
),

const SizedBox(width: 12),

Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'واحد $unitNumber',
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
),

const SizedBox(height: 5),

Text(
name,
style: TextStyle(
fontSize: 13,
color: Colors.grey.shade700,
),
),
],
),
),

Container(
padding: const EdgeInsets.symmetric(
horizontal: 10,
vertical: 6,
),
decoration: BoxDecoration(
color: isOwner
? primaryColor.withValues(alpha: 0.10)
    : secondaryColor.withValues(alpha: 0.10),
borderRadius: BorderRadius.circular(8),
),
child: Text(
isOwner ? 'مالک' : 'مستأجر',
style: TextStyle(
color: isOwner
? primaryColor
    : secondaryColor,
fontSize: 12,
fontWeight: FontWeight.bold,
),
),
),
],
),

const Divider(height: 25),

Row(
children: [
Icon(
Icons.account_balance_wallet_outlined,
color: Colors.green.shade600,
size: 21,
),

const SizedBox(width: 8),

const Text(
'مبلغ بستانکاری',
style: TextStyle(
fontWeight: FontWeight.bold,
fontSize: 14,
),
),

const Spacer(),

Flexible(
child: Text(
_formatMoney(creditorAmount),
textAlign: TextAlign.end,
style: TextStyle(
color: Colors.green.shade700,
fontSize: 15,
fontWeight: FontWeight.bold,
),
),
),
],
),
],
),
);
}

// =====================================================
// وضعیت خالی
// =====================================================

Widget _buildEmpty() {
return Center(
child: Padding(
padding: const EdgeInsets.all(30),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.account_balance_wallet_outlined,
size: 65,
color: Colors.green.shade400,
),

const SizedBox(height: 15),

const Text(
'مورد بستانکاری پیدا نشد.',
style: TextStyle(
fontSize: 15,
fontWeight: FontWeight.bold,
),
),
],
),
),
);
}

// =====================================================
// رابط اصلی
// =====================================================

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: ui.TextDirection.rtl,
child: Scaffold(
backgroundColor: const Color(0xFFF7F8FA),

appBar: AppBar(
title: const Text(
'واحدهای بستانکار',
style: TextStyle(
fontWeight: FontWeight.bold,
),
),
centerTitle: true,
backgroundColor: primaryColor,
foregroundColor: Colors.white,
elevation: 0,
actions: [
IconButton(
onPressed: _loadCreditors,
icon: const Icon(Icons.refresh),
tooltip: 'بروزرسانی',
),
],
),

body: RefreshIndicator(
onRefresh: _loadCreditors,
child: ListView(
padding: const EdgeInsets.all(16),
children: [
_buildSummaryCard(),

const SizedBox(height: 20),

TextField(
controller: _searchController,
onChanged: _onSearchChanged,
textInputAction: TextInputAction.search,
decoration: InputDecoration(
hintText: 'جستجو بر اساس واحد یا نام ساکن',
prefixIcon: const Icon(Icons.search),
suffixIcon: _searchController.text.isNotEmpty
? IconButton(
onPressed: () {
_searchController.clear();
setState(() {});
_loadCreditors();
},
icon: const Icon(Icons.close),
)
    : null,
filled: true,
fillColor: Colors.white,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(13),
borderSide: BorderSide.none,
),
),
),

const SizedBox(height: 15),

_buildFilters(),

const SizedBox(height: 20),

if (_loading)
const Padding(
padding: EdgeInsets.all(35),
child: Center(
child: CircularProgressIndicator(
color: primaryColor,
),
),
)
else if (_error != null)
Center(
child: Column(
children: [
const Icon(
Icons.error_outline,
color: Colors.red,
size: 40,
),

const SizedBox(height: 10),

Text(
_error!,
textAlign: TextAlign.center,
),

const SizedBox(height: 12),

ElevatedButton(
onPressed: _loadCreditors,
child: const Text('تلاش مجدد'),
),
],
),
)
else if (_creditors.isEmpty)
SizedBox(
height: 250,
child: _buildEmpty(),
)
else ...[
Text(
'فهرست بستانکاران '
'(${_toPersianDigits(_creditors.length.toString())})',
style: const TextStyle(
fontWeight: FontWeight.bold,
fontSize: 15,
),
),

const SizedBox(height: 12),

..._creditors.map(_buildCreditorCard),
],
],
),
),
),
);
}
}
