import 'dart:io';

import 'package:flutter/material.dart';
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
  final TextEditingController usernameController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  final LocalAuthentication auth =
  LocalAuthentication();

  final ApiService apiService =
  ApiService();

  bool loading = false;
  bool biometricLoading = false;

  bool biometricAvailable = false;
  bool biometricEnabled = false;
  bool firstLoginCompleted = false;

  String error = '';

  @override
  void initState() {
    super.initState();

    testDns();

    checkBiometric();
  }

  // =====================================================
  // بررسی وضعیت بیومتریک
  // =====================================================

  Future<void> checkBiometric() async {
    try {
      final canCheck =
      await auth.canCheckBiometrics;

      final supported =
      await auth.isDeviceSupported();

      final enabled =
      await TokenStorage.isBiometricEnabled();

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
        biometricAvailable =
            canCheck && supported;

        biometricEnabled =
            enabled;

        firstLoginCompleted =
            firstLogin;
      });
    } catch (e) {
      debugPrint(
        'BIOMETRIC CHECK ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        biometricAvailable = false;
        biometricEnabled = false;
        firstLoginCompleted = false;
      });
    }
  }

  // =====================================================
  // بررسی DNS
  // =====================================================

  Future<void> testDns() async {
    try {
      final result =
      await InternetAddress.lookup(
        'rayacharge.ir',
      );

      for (final address in result) {
        debugPrint(
          'DNS RESULT: ${address.address}',
        );
      }
    } catch (e) {
      debugPrint(
        'DNS ERROR: $e',
      );
    }
  }

  // =====================================================
  // تبدیل اعداد فارسی و عربی به انگلیسی
  // =====================================================

  String normalizePersianDigits(
      String value,
      ) {
    const persianDigits =
        '۰۱۲۳۴۵۶۷۸۹';

    const arabicDigits =
        '٠١٢٣٤٥٦٧٨٩';

    const englishDigits =
        '0123456789';

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
  // انتقال کاربر به صفحه مناسب
  //
  // اولویت:
  //
  // 1. مدیر ساختمان
  // 2. ساکن
  //
  // اگر:
  //
  // is_middle_admin = true
  // is_unit = true
  //
  // همیشه مدیر انتخاب می‌شود.
  // =====================================================

  void navigateAfterLogin(
      Map<String, dynamic> userData,
      ) {
    if (!mounted) return;

    // ===================================================
    // اطلاعات user
    // ===================================================

    final Map<String, dynamic> user =
    userData['user'] is Map
        ? Map<String, dynamic>.from(
      userData['user'],
    )
        : <String, dynamic>{};

    // ===================================================
    // وضعیت واقعی مدیر
    //
    // اولویت با is_middle_admin
    // ===================================================

    final bool isMiddleAdmin =
        user['is_middle_admin'] == true ||
            userData['is_middle_admin'] == true;

    // ===================================================
    // وضعیت ساکن
    // ===================================================

    final bool isUnit =
        user['is_unit'] == true ||
            userData['is_unit'] == true;

    // ===================================================
    // نوع کاربر ارسال‌شده از سرور
    // ===================================================

    final String? userType =
        userData['user_type']?.toString() ??
            user['user_type']?.toString();

    // ===================================================
    // Debug
    // ===================================================

    debugPrint(
      '==========================================',
    );

    debugPrint(
      'USER TYPE: $userType',
    );

    debugPrint(
      'ROOT IS MIDDLE ADMIN: '
          '${userData['is_middle_admin']}',
    );

    debugPrint(
      'USER IS MIDDLE ADMIN: '
          '${user['is_middle_admin']}',
    );

    debugPrint(
      'ROOT IS UNIT: '
          '${userData['is_unit']}',
    );

    debugPrint(
      'USER IS UNIT: '
          '${user['is_unit']}',
    );

    debugPrint(
      'IS MIDDLE ADMIN: $isMiddleAdmin',
    );

    debugPrint(
      'IS UNIT: $isUnit',
    );

    debugPrint(
      '==========================================',
    );

    // ===================================================
    // اولویت اول: مدیر ساختمان
    //
    // حتی اگر is_unit == true باشد
    // ===================================================

    if (isMiddleAdmin) {
      debugPrint(
        'NAVIGATING TO MANAGER DASHBOARD',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ManagerDashboardScreen(
                data: userData,
              ),
        ),
      );

      return;
    }

    // ===================================================
    // اولویت دوم: ساکن
    //
    // فقط اگر مدیر نباشد
    // ===================================================

    if (isUnit) {
      debugPrint(
        'NAVIGATING TO RESIDENT HOME',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              HomeScreen(
                data: userData,
              ),
        ),
      );

      return;
    }

    // ===================================================
    // نوع کاربر نامشخص
    // ===================================================

    debugPrint(
      'UNKNOWN USER TYPE',
    );

    setState(() {
      error =
      'نوع کاربر از سرور مشخص نشد.';
    });
  }

  // =====================================================
  // ورود با نام کاربری و رمز عبور
  // =====================================================

  Future<void> login() async {
    // ===================================================
    // دریافت اطلاعات
    // ===================================================

    final username =
    normalizePersianDigits(
      usernameController.text,
    ).trim();

    // رمز عبور trim نمی‌شود
    final password =
    normalizePersianDigits(
      passwordController.text,
    );

    debugPrint(
      'LOGIN USERNAME: $username',
    );

    debugPrint(
      'LOGIN PASSWORD EXISTS: '
          '${password.isNotEmpty}',
    );

    // ===================================================
    // بررسی خالی نبودن
    // ===================================================

    if (username.isEmpty ||
        password.isEmpty) {
      if (!mounted) return;

      setState(() {
        error =
        'لطفاً شماره موبایل و رمز عبور را وارد کنید.';
      });

      return;
    }

    // ===================================================
    // Loading
    // ===================================================

    if (!mounted) return;

    setState(() {
      loading = true;
      error = '';
    });

    try {
      // =================================================
      // ارسال درخواست Login
      // =================================================

      final result =
      await apiService.login(
        username: username,
        password: password,
      );

      debugPrint(
        '==========================================',
      );

      debugPrint(
        'LOGIN RESULT',
      );

      debugPrint(
        '$result',
      );

      debugPrint(
        '==========================================',
      );

      // =================================================
      // بررسی موفقیت
      // =================================================

      if (result['success'] != true) {
        throw Exception(
          result['message']?.toString() ??
              'اطلاعات ورود صحیح نیست.',
        );
      }

      // =================================================
      // دریافت توکن
      // =================================================

      final access =
      result['access'];

      final refresh =
      result['refresh'];

      if (access == null ||
          refresh == null ||
          access.toString().isEmpty ||
          refresh.toString().isEmpty) {
        throw Exception(
          'توکن از سرور دریافت نشد.',
        );
      }

      debugPrint(
        'ACCESS TOKEN RECEIVED: true',
      );

      debugPrint(
        'REFRESH TOKEN RECEIVED: true',
      );

      // =================================================
      // ذخیره توکن‌ها
      // =================================================

      await TokenStorage.saveTokens(
        access.toString(),
        refresh.toString(),
      );

      debugPrint(
        'TOKENS SAVED',
      );

      // =================================================
      // بررسی ذخیره واقعی توکن
      // =================================================

      final savedAccess =
      await TokenStorage.getAccessToken();

      final savedRefresh =
      await TokenStorage.getRefreshToken();

      debugPrint(
        'SAVED ACCESS EXISTS: '
            '${savedAccess != null && savedAccess.isNotEmpty}',
      );

      debugPrint(
        'SAVED REFRESH EXISTS: '
            '${savedRefresh != null && savedRefresh.isNotEmpty}',
      );

      if (savedAccess == null ||
          savedAccess.isEmpty ||
          savedRefresh == null ||
          savedRefresh.isEmpty) {
        throw Exception(
          'ذخیره اطلاعات ورود انجام نشد.',
        );
      }

      // =================================================
      // ثبت اولین ورود موفق
      // =================================================

      await TokenStorage.setFirstLoginCompleted();

      debugPrint(
        'FIRST LOGIN COMPLETED: true',
      );

      // =================================================
      // دریافت اطلاعات کامل کاربر
      // =================================================

      debugPrint(
        'GETTING USER INFO FROM /ME...',
      );

      final meResult =
      await apiService.getMeWithRefresh();

      debugPrint(
        '==========================================',
      );

      debugPrint(
        'ME RESULT AFTER LOGIN',
      );

      debugPrint(
        '$meResult',
      );

      debugPrint(
        '==========================================',
      );

      // =================================================
      // بررسی پاسخ /me
      // =================================================

      if (meResult.isEmpty) {
        throw Exception(
          'اطلاعات کاربر از سرور دریافت نشد.',
        );
      }

      // =================================================
      // اولین ورود موفق
      // =================================================

      if (!mounted) return;

      setState(() {
        firstLoginCompleted = true;
      });

      // =================================================
      // انتقال بر اساس نوع کاربر
      //
      // اولویت با مدیر
      // =================================================

      navigateAfterLogin(
        meResult,
      );
    } catch (e) {
      debugPrint(
        '==========================================',
      );

      debugPrint(
        'LOGIN SCREEN ERROR',
      );

      debugPrint(
        '$e',
      );

      debugPrint(
        '==========================================',
      );

      if (!mounted) return;

      String message;

      final errorText =
      e.toString();

      // =================================================
      // عدم اتصال اینترنت / DNS
      // =================================================

      if (errorText.contains(
        'NO_INTERNET',
      )) {
        message =
        'اتصال به اینترنت برقرار نیست.\n'
            'لطفاً اتصال اینترنت خود را بررسی کنید.';
      }

      // =================================================
      // Timeout
      // =================================================

      else if (errorText.contains(
        'TimeoutException',
      )) {
        message =
        'ارتباط با سرور برقرار نشد.\n'
            'لطفاً اتصال اینترنت خود را بررسی کنید.';
      }

      // =================================================
      // سایر خطاها
      // =================================================

      else {
        message = errorText;

        if (message.startsWith(
          'Exception: ',
        )) {
          message =
              message.replaceFirst(
                'Exception: ',
                '',
              );
        }
      }

      setState(() {
        error = message;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
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
    } catch (e) {
      debugPrint(
        'BIOMETRIC AUTH ERROR: $e',
      );

      return false;
    }
  }

  // =====================================================
  // فعال کردن ورود با اثر انگشت
  //
  // فقط بعد از اولین لاگین
  // =====================================================

  Future<void> enableBiometric() async {
    if (loading ||
        biometricLoading) {
      return;
    }

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

    // =================================================
    // بررسی وجود توکن
    // =================================================

    final accessToken =
    await TokenStorage.getAccessToken();

    final refreshToken =
    await TokenStorage.getRefreshToken();

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      if (!mounted) return;

      setState(() {
        error =
        'ابتدا با شماره موبایل و رمز عبور وارد شوید.';
      });

      return;
    }

    setState(() {
      biometricLoading = true;
      error = '';
    });

    try {
      final authenticated =
      await authenticateBiometric();

      if (!authenticated) {
        if (!mounted) return;

        setState(() {
          error =
          'احراز هویت با اثر انگشت انجام نشد.';
        });

        return;
      }

      // =================================================
      // فعال‌سازی
      // =================================================

      await TokenStorage.enableBiometric();

      if (!mounted) return;

      setState(() {
        biometricEnabled = true;
      });

      debugPrint(
        'BIOMETRIC ENABLED SUCCESSFULLY',
      );
    } catch (e) {
      debugPrint(
        'ENABLE BIOMETRIC ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        error =
        'فعال‌سازی ورود با اثر انگشت انجام نشد.';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        biometricLoading = false;
      });
    }
  }

  // =====================================================
  // ورود با اثر انگشت
  // =====================================================

  Future<void> loginWithBiometric() async {
    if (loading ||
        biometricLoading) {
      return;
    }

    final enabled =
    await TokenStorage.isBiometricEnabled();

    if (!enabled) {
      return;
    }

    setState(() {
      biometricLoading = true;
      error = '';
    });

    try {
      // =================================================
      // احراز هویت
      // =================================================

      final authenticated =
      await authenticateBiometric();

      if (!authenticated) {
        if (!mounted) return;

        setState(() {
          error =
          'احراز هویت با اثر انگشت انجام نشد.';
        });

        return;
      }

      // =================================================
      // بررسی توکن‌ها
      // =================================================

      final accessToken =
      await TokenStorage.getAccessToken();

      final refreshToken =
      await TokenStorage.getRefreshToken();

      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty) {
        if (!mounted) return;

        setState(() {
          error =
          'اطلاعات ورود پیدا نشد. لطفاً یک بار با رمز عبور وارد شوید.';
        });

        return;
      }

      // =================================================
      // دریافت اطلاعات واقعی کاربر
      // =================================================

      final meResult =
      await apiService.getMeWithRefresh();

      debugPrint(
        '==========================================',
      );

      debugPrint(
        'BIOMETRIC ME RESULT',
      );

      debugPrint(
        '$meResult',
      );

      debugPrint(
        '==========================================',
      );

      if (meResult.isEmpty) {
        throw Exception(
          'اطلاعات کاربر از سرور دریافت نشد.',
        );
      }

      if (!mounted) return;

      // =================================================
      // انتقال بر اساس نوع کاربر
      //
      // اولویت با مدیر
      // =================================================

      navigateAfterLogin(
        meResult,
      );
    } catch (e) {
      debugPrint(
        'BIOMETRIC LOGIN ERROR: $e',
      );

      if (!mounted) return;

      String message =
      e.toString();

      if (message.startsWith(
        'Exception: ',
      )) {
        message =
            message.replaceFirst(
              'Exception: ',
              '',
            );
      }

      setState(() {
        error = message.isNotEmpty
            ? message
            : 'جلسه ورود شما منقضی شده است. دوباره با رمز عبور وارد شوید.';
      });
    } finally {
      if (!mounted) return;

      setState(() {
        biometricLoading = false;
      });
    }
  }

  // =====================================================
  // Dispose
  // =====================================================

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
      TextDirection.rtl,

      child: Scaffold(
        backgroundColor:
        const Color(0xff00ACC1),

        body: Center(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 25,
            ),

            child: ConstrainedBox(
              constraints:
              const BoxConstraints(
                maxWidth: 320,
              ),

              child: Card(
                elevation: 10,

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),

                child: Padding(
                  padding:
                  const EdgeInsets.all(15),

                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,

                    children: [
                      // =================================
                      // لوگو
                      // =================================

                      Image.asset(
                        'assets/images/logo.png',

                        width: 170,
                        height: 100,

                        fit:
                        BoxFit.contain,
                      ),

                      const Padding(
                        padding:
                        EdgeInsets.only(
                          bottom: 30,
                        ),

                        child: Text(
                          'مدیریت مجتمع مسکونی رایا شارژ',

                          style:
                          TextStyle(
                            fontSize: 13,

                            fontWeight:
                            FontWeight.w500,

                            color:
                            Colors.black87,
                          ),
                        ),
                      ),

                      // =================================
                      // شماره موبایل
                      // =================================

                      TextField(
                        controller:
                        usernameController,

                        keyboardType:
                        TextInputType.phone,

                        decoration:
                        InputDecoration(
                          labelText:
                          'شماره موبایل',

                          prefixIcon:
                          const Icon(
                            Icons.phone,
                            size: 21,
                          ),

                          contentPadding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),

                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              13,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      // =================================
                      // رمز عبور
                      // =================================

                      TextField(
                        controller:
                        passwordController,

                        obscureText:
                        true,

                        decoration:
                        InputDecoration(
                          labelText:
                          'رمز عبور',

                          prefixIcon:
                          const Icon(
                            Icons.lock,
                            size: 21,
                          ),

                          contentPadding:
                          const EdgeInsets
                              .symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),

                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              13,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      // =================================
                      // خطا
                      // =================================

                      if (error.isNotEmpty)
                        Text(
                          error,

                          textAlign:
                          TextAlign.center,

                          style:
                          const TextStyle(
                            color: Colors.red,

                            fontWeight:
                            FontWeight.bold,

                            fontSize: 13,
                          ),
                        ),

                      if (error.isNotEmpty)
                        const SizedBox(
                          height: 15,
                        ),

                      // =================================
                      // ورود
                      // =================================

                      SizedBox(
                        width:
                        double.infinity,

                        height: 46,

                        child:
                        ElevatedButton(
                          style:
                          ElevatedButton
                              .styleFrom(
                            backgroundColor:
                            const Color(
                              0xff00ACC1,
                            ),

                            disabledBackgroundColor:
                            const Color(
                              0xff80D5DF,
                            ),

                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                13,
                              ),
                            ),
                          ),

                          onPressed:
                          loading ||
                              biometricLoading
                              ? null
                              : login,

                          child:
                          loading
                              ? const SizedBox(
                            width: 22,
                            height: 22,

                            child:
                            CircularProgressIndicator(
                              color:
                              Colors.white,
                              strokeWidth:
                              2,
                            ),
                          )
                              : const Text(
                            'ورود',

                            style:
                            TextStyle(
                              color:
                              Colors.white,

                              fontSize:
                              17,

                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // =================================
                      // بیومتریک
                      // =================================

                      if (firstLoginCompleted &&
                          biometricAvailable) ...[
                        const SizedBox(
                          height: 18,
                        ),

                        const Row(
                          children: [
                            Expanded(
                              child:
                              Divider(),
                            ),

                            Padding(
                              padding:
                              EdgeInsets
                                  .symmetric(
                                horizontal: 10,
                              ),

                              child:
                              Text(
                                'یا',

                                style:
                                TextStyle(
                                  color:
                                  Colors.grey,

                                  fontSize:
                                  12,
                                ),
                              ),
                            ),

                            Expanded(
                              child:
                              Divider(),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        // =================================
                        // فعال‌سازی بیومتریک
                        // =================================

                        if (!biometricEnabled)
                          InkWell(
                            borderRadius:
                            BorderRadius
                                .circular(
                              15,
                            ),

                            onTap:
                            biometricLoading
                                ? null
                                : enableBiometric,

                            child:
                            Padding(
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                vertical: 8,
                                horizontal: 15,
                              ),

                              child:
                              Column(
                                children: [
                                  biometricLoading
                                      ? const SizedBox(
                                    width: 42,
                                    height: 42,

                                    child:
                                    CircularProgressIndicator(
                                      strokeWidth:
                                      2,

                                      color:
                                      Color(
                                        0xff00ACC1,
                                      ),
                                    ),
                                  )
                                      : const Icon(
                                    Icons
                                        .fingerprint,

                                    size: 48,

                                    color:
                                    Color(
                                      0xff00ACC1,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 4,
                                  ),

                                  const Text(
                                    'فعال‌سازی ورود با اثر انگشت',

                                    textAlign:
                                    TextAlign
                                        .center,

                                    style:
                                    TextStyle(
                                      color:
                                      Color(
                                        0xff00ACC1,
                                      ),

                                      fontSize:
                                      14,

                                      fontWeight:
                                      FontWeight
                                          .w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )

                        // =================================
                        // ورود با بیومتریک
                        // =================================

                        else
                          InkWell(
                            borderRadius:
                            BorderRadius
                                .circular(
                              15,
                            ),

                            onTap:
                            biometricLoading
                                ? null
                                : loginWithBiometric,

                            child:
                            Padding(
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                vertical: 7,
                                horizontal: 15,
                              ),

                              child:
                              Column(
                                children: [
                                  biometricLoading
                                      ? const SizedBox(
                                    width: 42,
                                    height: 42,

                                    child:
                                    CircularProgressIndicator(
                                      strokeWidth:
                                      2,

                                      color:
                                      Color(
                                        0xff00ACC1,
                                      ),
                                    ),
                                  )
                                      : const Icon(
                                    Icons
                                        .fingerprint,

                                    size: 48,

                                    color:
                                    Color(
                                      0xff00ACC1,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 4,
                                  ),

                                  const Text(
                                    'ورود با اثر انگشت',

                                    style:
                                    TextStyle(
                                      color:
                                      Color(
                                        0xff00ACC1,
                                      ),

                                      fontSize:
                                      14,

                                      fontWeight:
                                      FontWeight
                                          .w600,
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