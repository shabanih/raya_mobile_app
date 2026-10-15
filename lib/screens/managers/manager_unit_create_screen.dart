
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_unit_service.dart';

class ManagerUnitCreateScreen extends StatefulWidget {
const ManagerUnitCreateScreen({super.key});

@override
State<ManagerUnitCreateScreen> createState() =>
_ManagerUnitCreateScreenState();
}

class _ManagerUnitCreateScreenState
extends State<ManagerUnitCreateScreen> {
static const Color primaryColor = Color(0xFF00ACC1);

final _formKey = GlobalKey<FormState>();
final ManagerUnitService _unitService = ManagerUnitService();

final _unitController = TextEditingController();
final _floorController = TextEditingController();
final _areaController = TextEditingController();
final _bedroomsController = TextEditingController();

final _ownerNameController = TextEditingController();
final _ownerMobileController = TextEditingController();
final _ownerNationalCodeController = TextEditingController();
final _ownerPeopleCountController = TextEditingController();
final _ownerDetailsController = TextEditingController();

final _purchaseDateController = TextEditingController();

final _parkingCountController = TextEditingController();
final _parkingNumberController = TextEditingController();
final _unitPhoneController = TextEditingController();
final _unitDetailsController = TextEditingController();

final _ownerPasswordController = TextEditingController();
final _ownerConfirmPasswordController = TextEditingController();

bool _hasParking = false;
bool _hasResident = true;
bool _isSaving = false;
bool _obscurePassword = true;
bool _obscureConfirmPassword = true;

@override
void dispose() {
_unitController.dispose();
_floorController.dispose();
_areaController.dispose();
_bedroomsController.dispose();

_ownerNameController.dispose();
_ownerMobileController.dispose();
_ownerNationalCodeController.dispose();
_ownerPeopleCountController.dispose();
_ownerDetailsController.dispose();

_purchaseDateController.dispose();

_parkingCountController.dispose();
_parkingNumberController.dispose();
_unitPhoneController.dispose();
_unitDetailsController.dispose();

_ownerPasswordController.dispose();
_ownerConfirmPasswordController.dispose();

super.dispose();
}

// تبدیل اعداد فارسی و عربی به انگلیسی برای پردازش و ارسال به API
String _digitsToEnglish(String value) {
const persian = '۰۱۲۳۴۵۶۷۸۹';
const arabic = '٠١٢٣٤٥٦٧٨٩';

for (int i = 0; i < 10; i++) {
value = value.replaceAll(persian[i], '$i');
value = value.replaceAll(arabic[i], '$i');
}

return value.trim();
}

// تبدیل اعداد انگلیسی و عربی به فارسی برای نمایش
String _digitsToPersian(String value) {
const english = '0123456789';
const persian = '۰۱۲۳۴۵۶۷۸۹';
const arabic = '٠١٢٣٤٥٦٧٨٩';

return value.split('').map((char) {
final englishIndex = english.indexOf(char);
if (englishIndex >= 0) {
return persian[englishIndex];
}

final arabicIndex = arabic.indexOf(char);
if (arabicIndex >= 0) {
return persian[arabicIndex];
}

return char;
}).join();
}

// تبدیل تاریخ شمسی به تاریخ میلادی برای Django
String _dateToApi(Jalali date) {
final gregorian = date.toGregorian();

final year = gregorian.year.toString().padLeft(4, '0');
final month = gregorian.month.toString().padLeft(2, '0');
final day = gregorian.day.toString().padLeft(2, '0');

return '$year-$month-$day';
}

String _dateToDisplay(Jalali date) {
final year = date.year.toString();
final month = date.month.toString().padLeft(2, '0');
final day = date.day.toString().padLeft(2, '0');

return _digitsToPersian('$year/$month/$day');
}

// تبدیل خودکار اعداد ورودی به فارسی و حفظ مکان نشانگر تایپ
void _handleDigitsChanged(
TextEditingController controller,
String value,
) {
final converted = _digitsToPersian(value);

if (converted == value) return;

final oldOffset = controller.selection.extentOffset;
final newOffset = oldOffset < 0
? converted.length
    : oldOffset.clamp(0, converted.length);

controller.value = TextEditingValue(
text: converted,
selection: TextSelection.collapsed(offset: newOffset),
composing: TextRange.empty,
);
}

Future<void> _selectPurchaseDate() async {
final now = Jalali.now();
Jalali initialDate = now;

final text = _digitsToEnglish(
_purchaseDateController.text,
);

if (text.isNotEmpty) {
final parts = text.split('/');

if (parts.length == 3) {
final year = int.tryParse(parts[0]);
final month = int.tryParse(parts[1]);
final day = int.tryParse(parts[2]);

if (year != null && month != null && day != null) {
try {
final candidate = Jalali(year, month, day);

if (candidate.month >= 1 &&
candidate.month <= 12 &&
candidate.day >= 1 &&
candidate.day <= _daysInMonth(
candidate.year,
candidate.month,
)) {
initialDate = candidate;
}
} catch (_) {
initialDate = now;
}
}
}
}

final selectedDate = await showDialog<Jalali>(
context: context,
builder: (context) {
return _ShamsiDateDialog(initialDate: initialDate);
},
);

if (selectedDate != null && mounted) {
setState(() {
_purchaseDateController.text =
_dateToDisplay(selectedDate);
});
}
}

int _daysInMonth(int year, int month) {
if (month >= 1 && month <= 6) return 31;
if (month >= 7 && month <= 11) return 30;
if (month == 12) {
return Jalali(year, 12, 1).isLeapYear() ? 30 : 29;
}
return 0;
}

String? _requiredValidator(String? value, String label) {
if (value == null || value.trim().isEmpty) {
return '$label را وارد کنید.';
}
return null;
}

String? _mobileValidator(String? value) {
final mobile = _digitsToEnglish(value ?? '');

if (mobile.isEmpty) {
return 'شماره موبایل مالک را وارد کنید.';
}

if (!RegExp(r'^09\d{9}$').hasMatch(mobile)) {
return 'شماره موبایل باید ۱۱ رقم و با ۰۹ شروع شود.';
}

return null;
}

String? _passwordValidator(String? value) {
if (value == null || value.isEmpty) {
return 'رمز عبور مالک را وارد کنید.';
}

if (value.length < 8) {
return 'رمز عبور باید حداقل ۸ کاراکتر باشد.';
}

return null;
}

String? _confirmPasswordValidator(String? value) {
if (value == null || value.isEmpty) {
return 'تکرار رمز عبور را وارد کنید.';
}

if (value != _ownerPasswordController.text) {
return 'رمز عبور و تکرار آن یکسان نیستند.';
}

return null;
}

Widget _buildTextField({
required String label,
required TextEditingController controller,
String? Function(String?)? validator,
TextInputType keyboardType = TextInputType.text,
int maxLines = 1,
bool readOnly = false,
VoidCallback? onTap,
Widget? suffixIcon,
String? hintText,
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
onChanged: (value) {
if (!readOnly) {
_handleDigitsChanged(controller, value);
}
},
decoration: InputDecoration(
labelText: label,
hintText: hintText,
suffixIcon: suffixIcon,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
enabledBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: BorderSide(color: Colors.grey.shade400),
),
focusedBorder: const OutlineInputBorder(
borderRadius: BorderRadius.all(Radius.circular(12)),
borderSide: BorderSide(
color: primaryColor,
width: 1.8,
),
),
contentPadding: const EdgeInsets.symmetric(
horizontal: 14,
vertical: 14,
),
),
);
}

Widget _buildPasswordField({
required String label,
required TextEditingController controller,
required bool obscureText,
required VoidCallback toggleObscure,
String? Function(String?)? validator,
}) {
// رمز عبور عمداً تغییر داده نمی‌شود.
return TextFormField(
controller: controller,
textDirection: TextDirection.ltr,
textAlign: TextAlign.left,
obscureText: obscureText,
validator: validator,
decoration: InputDecoration(
labelText: label,
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
),
focusedBorder: const OutlineInputBorder(
borderRadius: BorderRadius.all(Radius.circular(12)),
borderSide: BorderSide(
color: primaryColor,
width: 1.8,
),
),
suffixIcon: IconButton(
tooltip: obscureText ? 'نمایش رمز' : 'مخفی کردن رمز',
onPressed: toggleObscure,
icon: Icon(
obscureText ? Icons.visibility_off : Icons.visibility,
),
),
contentPadding: const EdgeInsets.symmetric(
horizontal: 14,
vertical: 14,
),
),
);
}

Widget _buildSection({
required String title,
required IconData icon,
required List<Widget> children,
}) {
return Card(
elevation: 1,
margin: const EdgeInsets.only(bottom: 16),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Row(
children: [
Icon(icon, color: primaryColor),
const SizedBox(width: 8),
Expanded(
child: Text(
title,
textAlign: TextAlign.right,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.bold,
),
),
),
],
),
const SizedBox(height: 16),
...children.map(
(widget) => Padding(
padding: const EdgeInsets.only(bottom: 14),
child: widget,
),
),
],
),
),
);
}

void _showMessage(String message) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
SnackBar(content: Text(message)),
);
}

Future<void> _saveUnit() async {
FocusScope.of(context).unfocus();

if (!_formKey.currentState!.validate()) return;

final unitNumber = int.tryParse(
_digitsToEnglish(_unitController.text),
);

final floorNumber = int.tryParse(
_digitsToEnglish(_floorController.text),
);

final area = double.tryParse(
_digitsToEnglish(_areaController.text),
);

final bedroomsCount = int.tryParse(
_digitsToEnglish(_bedroomsController.text),
) ?? 0;

final peopleCount = int.tryParse(
_digitsToEnglish(_ownerPeopleCountController.text),
) ?? 1;

if (unitNumber == null || unitNumber < 1) {
_showMessage('شماره واحد باید عددی معتبر باشد.');
return;
}

if (floorNumber == null) {
_showMessage('شماره طبقه را به‌درستی وارد کنید.');
return;
}

if (area == null || area <= 0) {
_showMessage('متراژ باید عددی بزرگ‌تر از صفر باشد.');
return;
}

int parkingCount = 0;

if (_hasParking) {
final parsedParkingCount = int.tryParse(
_digitsToEnglish(_parkingCountController.text),
);

if (parsedParkingCount == null || parsedParkingCount < 1) {
_showMessage('تعداد پارکینگ را به‌درستی وارد کنید.');
return;
}

parkingCount = parsedParkingCount;
}

setState(() => _isSaving = true);

try {
final data = <String, dynamic>{
// کلیدهای مورد انتظار API جنگو
'unit': unitNumber,
'floor_number': floorNumber,
'area': area,
'bedrooms_count': bedroomsCount,
'owner_name': _ownerNameController.text.trim(),
'owner_mobile': _digitsToEnglish(
_ownerMobileController.text,
),
'owner_national_code': _digitsToEnglish(
_ownerNationalCodeController.text,
),
'owner_people_count': peopleCount,
'owner_details': _ownerDetailsController.text.trim(),
'status_residence': _hasResident ? 'occupied' : 'vacant',
'is_renter': false,
'unit_phone': _digitsToEnglish(
_unitPhoneController.text,
),
'unit_details': _unitDetailsController.text.trim(),
'has_parking': _hasParking,
'parking_count': parkingCount,
'parking_number': _hasParking
? _digitsToEnglish(_parkingNumberController.text)
    : '',
};

final purchaseDateText = _digitsToEnglish(
_purchaseDateController.text,
);

if (purchaseDateText.isNotEmpty) {
final parts = purchaseDateText.split('/');

if (parts.length != 3) {
_showMessage('تاریخ خرید معتبر نیست.');
return;
}

final year = int.tryParse(parts[0]);
final month = int.tryParse(parts[1]);
final day = int.tryParse(parts[2]);

if (year == null || month == null || day == null) {
_showMessage('تاریخ خرید معتبر نیست.');
return;
}

if (month < 1 ||
month > 12 ||
day < 1 ||
day > _daysInMonth(year, month)) {
_showMessage('تاریخ خرید معتبر نیست.');
return;
}

data['purchase_date'] = _dateToApi(
Jalali(year, month, day),
);
}

// این دو کلید تنها در صورتی اثر دارند که بک‌اند آن‌ها را
// برای ساخت حساب مالک پردازش کند.

  data['owner_password'] =
      _ownerPasswordController.text;

  data['owner_password_confirm'] =
      _ownerConfirmPasswordController.text;


await _unitService.createUnit(data);

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('واحد با موفقیت ثبت شد.'),
backgroundColor: Colors.green,
),
);

Navigator.of(context).pop(true);
} catch (e) {
_showMessage('ثبت واحد انجام نشد: $e');
} finally {
if (mounted) {
setState(() => _isSaving = false);
}
}
}

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
appBar: AppBar(
title: const Text('افزودن واحد'),
centerTitle: true,
backgroundColor: primaryColor,
foregroundColor: Colors.white,
),
body: SafeArea(
child: Form(
key: _formKey,
child: ListView(
padding: const EdgeInsets.all(16),
children: [
_buildSection(
title: 'اطلاعات واحد',
icon: Icons.apartment,
children: [
_buildTextField(
label: 'شماره واحد',
controller: _unitController,
keyboardType: TextInputType.number,
validator: (v) =>
_requiredValidator(v, 'شماره واحد'),
),
_buildTextField(
label: 'شماره طبقه',
controller: _floorController,
keyboardType:
const TextInputType.numberWithOptions(
signed: true,
),
validator: (v) =>
_requiredValidator(v, 'شماره طبقه'),
),
_buildTextField(
label: 'متراژ (متر مربع)',
controller: _areaController,
keyboardType:
const TextInputType.numberWithOptions(
decimal: true,
),
validator: (v) =>
_requiredValidator(v, 'متراژ'),
),
_buildTextField(
label: 'تعداد اتاق خواب',
controller: _bedroomsController,
keyboardType: TextInputType.number,
),
_buildTextField(
label: 'تلفن واحد',
controller: _unitPhoneController,
keyboardType: TextInputType.phone,
),
_buildTextField(
label: 'تاریخ خرید (شمسی)',
controller: _purchaseDateController,
readOnly: true,
onTap: _selectPurchaseDate,
suffixIcon: const Icon(
Icons.calendar_month,
color: primaryColor,
),
hintText: 'مثلاً ۱۴۰۵/۰۷/۱۹',
),
_buildTextField(
label: 'توضیحات واحد',
controller: _unitDetailsController,
maxLines: 3,
),
],
),
_buildSection(
title: 'اطلاعات مالک',
icon: Icons.person,
children: [
_buildTextField(
label: 'نام و نام خانوادگی مالک',
controller: _ownerNameController,
validator: (v) =>
_requiredValidator(v, 'نام مالک'),
),
_buildTextField(
label: 'شماره موبایل مالک',
controller: _ownerMobileController,
keyboardType: TextInputType.phone,
validator: _mobileValidator,
),
_buildTextField(
label: 'کد ملی مالک',
controller: _ownerNationalCodeController,
keyboardType: TextInputType.number,
),
_buildTextField(
label: 'تعداد نفرات مالک',
controller: _ownerPeopleCountController,
keyboardType: TextInputType.number,
validator: (value) {
if (value == null || value.trim().isEmpty) {
return null;
}

final count = int.tryParse(
_digitsToEnglish(value),
);

if (count == null || count < 0) {
return 'تعداد نفرات را صحیح وارد کنید.';
}

return null;
},
),
_buildTextField(
label: 'توضیحات مالک',
controller: _ownerDetailsController,
maxLines: 3,
),
_buildPasswordField(
label: 'رمز عبور حساب مالک',
controller: _ownerPasswordController,
obscureText: _obscurePassword,
toggleObscure: () {
setState(() {
_obscurePassword = !_obscurePassword;
});
},
validator: _passwordValidator,
),
_buildPasswordField(
label: 'تکرار رمز عبور',
controller: _ownerConfirmPasswordController,
obscureText: _obscureConfirmPassword,
toggleObscure: () {
setState(() {
_obscureConfirmPassword =
!_obscureConfirmPassword;
});
},
validator: _confirmPasswordValidator,
),
],
),
_buildSection(
title: 'وضعیت سکونت و پارکینگ',
icon: Icons.home_work,
children: [
SwitchListTile(
contentPadding: EdgeInsets.zero,
title: const Text('واحد دارای ساکن است'),
value: _hasResident,
activeThumbColor: primaryColor,
onChanged: (value) {
setState(() => _hasResident = value);
},
),
SwitchListTile(
contentPadding: EdgeInsets.zero,
title: const Text('واحد دارای پارکینگ است'),
value: _hasParking,
activeThumbColor: primaryColor,
onChanged: (value) {
setState(() => _hasParking = value);
},
),
if (_hasParking) ...[
_buildTextField(
label: 'تعداد پارکینگ',
controller: _parkingCountController,
keyboardType: TextInputType.number,
validator: (v) =>
_requiredValidator(v, 'تعداد پارکینگ'),
),
_buildTextField(
label: 'شماره پارکینگ',
controller: _parkingNumberController,
keyboardType: TextInputType.number,
),
],
],
),
const SizedBox(height: 8),
SizedBox(
height: 52,
child: FilledButton.icon(
onPressed: _isSaving ? null : _saveUnit,
icon: _isSaving
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
_isSaving ? 'در حال ثبت...' : 'ثبت واحد',
),
style: FilledButton.styleFrom(
backgroundColor: primaryColor,
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
),
),
const SizedBox(height: 24),
],
),
),
),
),
);
}
}

class _ShamsiDateDialog extends StatefulWidget {
final Jalali initialDate;

const _ShamsiDateDialog({
required this.initialDate,
});

@override
State<_ShamsiDateDialog> createState() =>
_ShamsiDateDialogState();
}

class _ShamsiDateDialogState extends State<_ShamsiDateDialog> {
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

int _daysInMonth(int year, int month) {
if (month >= 1 && month <= 6) return 31;
if (month >= 7 && month <= 11) return 30;
return Jalali(year, 12, 1).isLeapYear() ? 30 : 29;
}

void _updateMonth(int month) {
setState(() {
_month = month;
final maxDay = _daysInMonth(_year, _month);

if (_day > maxDay) {
_day = maxDay;
}
});
}

void _updateYear(int year) {
setState(() {
_year = year;
final maxDay = _daysInMonth(_year, _month);

if (_day > maxDay) {
_day = maxDay;
}
});
}

String _digitsToPersian(String value) {
const english = '0123456789';

const persian = '۰۱۲۳۴۵۶۷۸۹';

return value.split('').map((char) {
final index = english.indexOf(char);
return index >= 0 ? persian[index] : char;
}).join();
}

@override
Widget build(BuildContext context) {
final currentYear = Jalali.now().year;

final years = List<int>.generate(
81,
(index) => currentYear - 40 + index,
);

final days = List<int>.generate(
_daysInMonth(_year, _month),
(index) => index + 1,
);

return Directionality(
textDirection: TextDirection.rtl,
child: AlertDialog(
title: const Text(
'انتخاب تاریخ شمسی',
textAlign: TextAlign.center,
),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
DropdownButtonFormField<int>(
value: _year,
isExpanded: true,
decoration: const InputDecoration(
labelText: 'سال',
border: OutlineInputBorder(),
),
items: years.map((year) {
return DropdownMenuItem<int>(
value: year,
child: Text(_digitsToPersian('$year')),
);
}).toList(),
onChanged: (value) {
if (value != null) _updateYear(value);
},
),
const SizedBox(height: 12),
DropdownButtonFormField<int>(
value: _month,
isExpanded: true,
decoration: const InputDecoration(
labelText: 'ماه',
border: OutlineInputBorder(),
),
items: List.generate(12, (index) {
final month = index + 1;

return DropdownMenuItem<int>(
value: month,
child: Text(
_digitsToPersian(
month.toString().padLeft(2, '0'),
),
),
);
}),
onChanged: (value) {
if (value != null) _updateMonth(value);
},
),
const SizedBox(height: 12),
DropdownButtonFormField<int>(
value: _day,
isExpanded: true,
decoration: const InputDecoration(
labelText: 'روز',
border: OutlineInputBorder(),
),
items: days.map((day) {
return DropdownMenuItem<int>(
value: day,
child: Text(
_digitsToPersian(
day.toString().padLeft(2, '0'),
),
),
);
}).toList(),
onChanged: (value) {
if (value != null) {
setState(() => _day = value);
}
},
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.of(context).pop(),
child: const Text('انصراف'),
),
FilledButton(
style: FilledButton.styleFrom(
backgroundColor: const Color(0xFF00ACC1),
foregroundColor: Colors.white,
),
onPressed: () {
Navigator.of(context).pop(
Jalali(_year, _month, _day),
);
},
child: const Text('تأیید'),
),
],
),
);
}
}
