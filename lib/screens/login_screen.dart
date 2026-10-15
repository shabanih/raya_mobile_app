
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../services/api_service.dart';
import '../storage/token_storage.dart';
import 'home_screen.dart';
import 'managers/manager_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
const LoginScreen({super.key});

@override
State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
final TextEditingController mobileController =
TextEditingController();

final TextEditingController passwordController =
TextEditingController();

final LocalAuthentication auth = LocalAuthentication();

final ApiService apiService = ApiService();

bool loading = false;
bool biometricLoading = false;
bool biometricAvailable = false;
bool biometricEnabled = false;
bool firstLoginCompleted = false;
bool obscurePassword = true;

String error = '';

@override
void initState() {
super.initState();
testDns();
checkBiometric();
}

// =====================================================
// تبدیل اعداد فارسی و عربی به انگلیسی
// =====================================================

String normalizePersianDigits(String value) {
const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
const englishDigits = '0123456789';

for (int i = 0; i < 10; i++) {
value = value.replaceAll(
persianDigits[i],
englishDigits[i],
);

value = value.replaceAll(
arabicDigits[i],
englishDigits[i],
);
}

return value;
}

// =====================================================
// بررسی DNS
// =====================================================

Future<void> testDns() async {
try {
final result = await InternetAddress.lookup(
'rayacharge.ir',
);

for (final address in result) {
debugPrint('DNS RESULT: ${address.address}');
}
} catch (e) {
debugPrint('DNS ERROR: $e');
}
}

// =====================================================
// بررسی وضعیت بیومتریک
// =====================================================

Future<void> checkBiometric() async {
try {
final canCheck = await auth.canCheckBiometrics;
final supported = await auth.isDeviceSupported();
final enabled = await TokenStorage.isBiometricEnabled();
final firstLogin =
await TokenStorage.isFirstLoginCompleted();

debugPrint(
'BIOMETRIC DEBUG: '
'canCheck=$canCheck, '
'supported=$supported, '
'enabled=$enabled, '
'firstLogin=$firstLogin',
);

if (!mounted) return;

setState(() {
biometricAvailable = canCheck && supported;
biometricEnabled = enabled;
firstLoginCompleted = firstLogin;
});
} catch (e) {
debugPrint('BIOMETRIC CHECK ERROR: $e');

if (!mounted) return;

setState(() {
biometricAvailable = false;
biometricEnabled = false;
firstLoginCompleted = false;
});
}
}

// =====================================================
// انتقال به صفحه مناسب
// مدیر اولویت دارد
// =====================================================

void navigateAfterLogin(
Map<String, dynamic> userData,
) {
if (!mounted) return;

final Map<String, dynamic> user =
userData['user'] is Map
? Map<String, dynamic>.from(userData['user'])
    : <String, dynamic>{};

final bool isMiddleAdmin =
user['is_middle_admin'] == true ||
userData['is_middle_admin'] == true;

final bool isUnit =
user['is_unit'] == true ||
userData['is_unit'] == true;

final String? userType =
userData['user_type']?.toString() ??
user['user_type']?.toString();

debugPrint('==========================================');
debugPrint('USER TYPE: $userType');
debugPrint('IS MIDDLE ADMIN: $isMiddleAdmin');
debugPrint('IS UNIT: $isUnit');
debugPrint('==========================================');

if (isMiddleAdmin) {
debugPrint('NAVIGATING TO MANAGER DASHBOARD');

Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) => ManagerDashboardScreen(
data: userData,
),
),
);

return;
}

if (isUnit) {
debugPrint('NAVIGATING TO RESIDENT HOME');

Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (_) => HomeScreen(
data: userData,
),
),
);

return;
}

setState(() {
error = 'نوع کاربر از سرور مشخص نشد.';
});
}

// =====================================================
// ورود با شماره موبایل و رمز عبور
// =====================================================

Future<void> login() async {
if (loading || biometricLoading) return;

final mobile = normalizePersianDigits(
mobileController.text,
).trim();

// رمز عبور را trim نمی‌کنیم تا فاصله‌های احتمالی
// داخل یا ابتدا و انتهای رمز تغییر نکنند.
final password = normalizePersianDigits(
passwordController.text,
);

debugPrint('LOGIN MOBILE: $mobile');
debugPrint(
'LOGIN PASSWORD EXISTS: ${password.isNotEmpty}',
);

if (mobile.isEmpty || password.isEmpty) {
setState(() {
error = 'لطفاً شماره موبایل و رمز عبور را وارد کنید.';
});
return;
}

if (!mounted) return;

setState(() {
loading = true;
error = '';
});

try {
// ارسال شماره موبایل به API
final result = await apiService.login(
mobile: mobile,
password: password,
);

debugPrint('LOGIN RESULT: $result');

if (result['success'] != true) {
throw Exception(
result['message']?.toString() ??
result['detail']?.toString() ??
'اطلاعات ورود صحیح نیست.',
);
}

// دریافت توکن‌ها
final access = result['access'];
final refresh = result['refresh'];

if (access == null ||
refresh == null ||
access.toString().trim().isEmpty ||
refresh.toString().trim().isEmpty) {
throw Exception('توکن ورود از سرور دریافت نشد.');
}

// ذخیره توکن‌ها
await TokenStorage.saveTokens(
access.toString(),
refresh.toString(),
);

final savedAccess = await TokenStorage.getAccessToken();
final savedRefresh = await TokenStorage.getRefreshToken();

if (savedAccess == null ||
savedAccess.trim().isEmpty ||
savedRefresh == null ||
savedRefresh.trim().isEmpty) {
throw Exception('ذخیره اطلاعات ورود انجام نشد.');
}

debugPrint('TOKENS SAVED');

// ثبت اولین ورود موفق
await TokenStorage.setFirstLoginCompleted();

// دریافت اطلاعات کامل کاربر
final meResult = await apiService.getMeWithRefresh();

debugPrint('ME RESULT AFTER LOGIN: $meResult');

if (meResult.isEmpty) {
throw Exception('اطلاعات کاربر از سرور دریافت نشد.');
}

if (!mounted) return;

setState(() {
firstLoginCompleted = true;
});

// انتقال مدیر یا ساکن
navigateAfterLogin(meResult);
} catch (e) {
debugPrint('LOGIN SCREEN ERROR: $e');

if (!mounted) return;

final errorText = e.toString();

String message;

if (errorText.contains('NO_INTERNET') ||
errorText.contains('SocketException') ||
errorText.contains('ClientException')) {
message =
'اتصال به اینترنت برقرار نیست.\n'
'لطفاً اتصال اینترنت خود را بررسی کنید.';
} else if (errorText.contains('REQUEST_TIMEOUT') ||
errorText.contains('TimeoutException')) {
message =
'پاسخ سرور بیش از حد طول کشید.\n'
'لطفاً دوباره تلاش کنید.';
} else if (errorText.contains('TOKEN_EXPIRED')) {
message =
'اعتبار ورود شما تأیید نشد. دوباره وارد شوید.';
} else {
message = errorText.replaceFirst(
'Exception: ',
'',
);
}

setState(() {
error = message;
});
} finally {
if (mounted) {
setState(() {
loading = false;
});
}
}
}

// =====================================================
// احراز هویت بیومتریک
// =====================================================

Future<bool> authenticateBiometric() async {
try {
return await auth.authenticate(
localizedReason:
'برای ادامه، اثر انگشت خود را تأیید کنید',
biometricOnly: true,
persistAcrossBackgrounding: true,
);
} on PlatformException catch (e) {
debugPrint('BIOMETRIC PLATFORM ERROR: $e');
return false;
} catch (e) {
debugPrint('BIOMETRIC AUTH ERROR: $e');
return false;
}
}

// =====================================================
// فعال‌سازی ورود با اثر انگشت
// =====================================================

Future<void> enableBiometric() async {
if (loading || biometricLoading) return;

final firstLogin =
await TokenStorage.isFirstLoginCompleted();

if (!firstLogin) {
if (!mounted) return;

setState(() {
error =
'ابتدا یک بار با شماره موبایل و رمز عبور وارد شوید.';
});
return;
}

if (!biometricAvailable) {
if (!mounted) return;

setState(() {
error =
'قابلیت اثر انگشت در این دستگاه در دسترس نیست.';
});
return;
}

final accessToken = await TokenStorage.getAccessToken();
final refreshToken = await TokenStorage.getRefreshToken();

if (accessToken == null ||
accessToken.isEmpty ||
refreshToken == null ||
refreshToken.isEmpty) {
if (!mounted) return;

setState(() {
error = 'ابتدا با شماره موبایل و رمز عبور وارد شوید.';
});
return;
}

if (!mounted) return;

setState(() {
biometricLoading = true;
error = '';
});

try {
final authenticated = await authenticateBiometric();

if (!authenticated) {
if (!mounted) return;

setState(() {
error = 'احراز هویت با اثر انگشت انجام نشد.';
});
return;
}

await TokenStorage.enableBiometric();

if (!mounted) return;

setState(() {
biometricEnabled = true;
});

debugPrint('BIOMETRIC ENABLED SUCCESSFULLY');
} catch (e) {
debugPrint('ENABLE BIOMETRIC ERROR: $e');

if (!mounted) return;

setState(() {
error = 'فعال‌سازی ورود با اثر انگشت انجام نشد.';
});
} finally {
if (mounted) {
setState(() {
biometricLoading = false;
});
}
}
}

// =====================================================
// ورود با اثر انگشت
// =====================================================

Future<void> loginWithBiometric() async {
if (loading || biometricLoading) return;

final enabled = await TokenStorage.isBiometricEnabled();

if (!enabled) return;

if (!mounted) return;

setState(() {
biometricLoading = true;
error = '';
});

try {
final authenticated = await authenticateBiometric();

if (!authenticated) {
if (!mounted) return;

setState(() {
error = 'احراز هویت با اثر انگشت انجام نشد.';
});
return;
}

final accessToken = await TokenStorage.getAccessToken();
final refreshToken = await TokenStorage.getRefreshToken();

if (accessToken == null ||
accessToken.isEmpty ||
refreshToken == null ||
refreshToken.isEmpty) {
if (!mounted) return;

setState(() {
error =
'اطلاعات ورود پیدا نشد. لطفاً دوباره با رمز عبور وارد شوید.';
});
return;
}

// در صورت منقضی شدن Access، سرویس API آن را Refresh می‌کند.
final meResult = await apiService.getMeWithRefresh();

debugPrint('BIOMETRIC ME RESULT: $meResult');

if (meResult.isEmpty) {
throw Exception('اطلاعات کاربر از سرور دریافت نشد.');
}

if (!mounted) return;

navigateAfterLogin(meResult);
} catch (e) {
debugPrint('BIOMETRIC LOGIN ERROR: $e');

if (!mounted) return;

String message = e.toString().replaceFirst(
'Exception: ',
'',
);

if (message.contains('TOKEN_EXPIRED')) {
message =
'جلسه ورود شما منقضی شده است. دوباره با رمز عبور وارد شوید.';
} else if (message.contains('NO_INTERNET') ||
message.contains('SocketException') ||
message.contains('ClientException')) {
message = 'اتصال اینترنت را بررسی کنید.';
}

setState(() {
error = message;
});
} finally {
if (mounted) {
setState(() {
biometricLoading = false;
});
}
}
}

// =====================================================
// Dispose
// =====================================================

@override
void dispose() {
mobileController.dispose();
passwordController.dispose();
super.dispose();
}

// =====================================================
// UI
// =====================================================

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: Scaffold(
backgroundColor: const Color(0xff00ACC1),
body: Center(
child: SingleChildScrollView(
padding: const EdgeInsets.symmetric(
horizontal: 20,
vertical: 25,
),
child: ConstrainedBox(
constraints: const BoxConstraints(
maxWidth: 360,
),
child: Card(
elevation: 10,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(20),
),
child: Padding(
padding: const EdgeInsets.all(18),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
// لوگو
Image.asset(
'assets/images/logo.png',
width: 170,
height: 100,
fit: BoxFit.contain,
),

const Padding(
padding: EdgeInsets.only(bottom: 28),
child: Text(
'مدیریت مجتمع مسکونی رایا شارژ',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 13,
fontWeight: FontWeight.w500,
color: Colors.black87,
),
),
),

// شماره موبایل
TextField(
controller: mobileController,
keyboardType: TextInputType.phone,
textDirection: TextDirection.ltr,
textAlign: TextAlign.right,
inputFormatters: [
FilteringTextInputFormatter.allow(
RegExp(r'[0-9۰-۹٠-٩+]'),
),
],
decoration: InputDecoration(
labelText: 'شماره موبایل',
prefixIcon: const Icon(
Icons.phone,
size: 21,
),
contentPadding:
const EdgeInsets.symmetric(
horizontal: 14,
vertical: 14,
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(13),
),
),
onSubmitted: (_) {
if (!loading && !biometricLoading) {
FocusScope.of(context).nextFocus();
}
},
),

const SizedBox(height: 15),

// رمز عبور
TextField(
controller: passwordController,
obscureText: obscurePassword,
textDirection: TextDirection.ltr,
textAlign: TextAlign.right,
decoration: InputDecoration(
labelText: 'رمز عبور',
prefixIcon: const Icon(
Icons.lock,
size: 21,
),
suffixIcon: IconButton(
tooltip: obscurePassword
? 'نمایش رمز عبور'
    : 'پنهان کردن رمز عبور',
icon: Icon(
obscurePassword
? Icons.visibility
    : Icons.visibility_off,
),
onPressed: () {
setState(() {
obscurePassword = !obscurePassword;
});
},
),
contentPadding:
const EdgeInsets.symmetric(
horizontal: 14,
vertical: 14,
),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(13),
),
),
onSubmitted: (_) {
if (!loading && !biometricLoading) {
login();
}
},
),

const SizedBox(height: 15),

// پیام خطا
if (error.isNotEmpty) ...[
Text(
error,
textAlign: TextAlign.center,
style: const TextStyle(
color: Colors.red,
fontWeight: FontWeight.bold,
fontSize: 13,
),
),
const SizedBox(height: 15),
],

// دکمه ورود
SizedBox(
width: double.infinity,
height: 46,
child: ElevatedButton(
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xff00ACC1),
disabledBackgroundColor:
const Color(0xff80D5DF),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(13),
),
),
onPressed: loading || biometricLoading
? null
    : login,
child: loading
? const SizedBox(
width: 22,
height: 22,
child: CircularProgressIndicator(
color: Colors.white,
strokeWidth: 2,
),
)
    : const Text(
'ورود',
style: TextStyle(
color: Colors.white,
fontSize: 17,
fontWeight: FontWeight.w600,
),
),
),
),

// ورود بیومتریک
if (firstLoginCompleted &&
biometricAvailable) ...[
const SizedBox(height: 18),

const Row(
children: [
Expanded(child: Divider()),
Padding(
padding: EdgeInsets.symmetric(
horizontal: 10,
),
child: Text(
'یا',
style: TextStyle(
color: Colors.grey,
fontSize: 12,
),
),
),
Expanded(child: Divider()),
],
),

const SizedBox(height: 8),

InkWell(
borderRadius: BorderRadius.circular(15),
onTap: biometricLoading
? null
    : biometricEnabled
? loginWithBiometric
    : enableBiometric,
child: Padding(
padding: const EdgeInsets.symmetric(
vertical: 8,
horizontal: 15,
),
child: Column(
children: [
biometricLoading
? const SizedBox(
width: 42,
height: 42,
child: CircularProgressIndicator(
strokeWidth: 2,
color: Color(0xff00ACC1),
),
)
    : const Icon(
Icons.fingerprint,
size: 48,
color: Color(0xff00ACC1),
),
const SizedBox(height: 4),
Text(
biometricEnabled
? 'ورود با اثر انگشت'
    : 'فعال‌سازی ورود با اثر انگشت',
textAlign: TextAlign.center,
style: const TextStyle(
color: Color(0xff00ACC1),
fontSize: 14,
fontWeight: FontWeight.w600,
),
),
],
),
),
),
],
],
),
),
),
),
),
),
),
);
}
}
