import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../services/api_service.dart';
import '../storage/token_storage.dart';
import 'home_screen.dart';

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

  final LocalAuthentication auth = LocalAuthentication();

  final ApiService apiService = ApiService();

  bool loading = false;
  bool biometricLoading = false;

  bool biometricAvailable = false;
  bool biometricEnabled = false;
  bool firstLoginCompleted = false;

  String error = '';

  @override
  void initState() {
    super.initState();
    checkBiometric();
  }

  // =====================================================
  // بررسی وضعیت بیومتریک
  // =====================================================

  Future<void> checkBiometric() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      final supported = await auth.isDeviceSupported();

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
        biometricAvailable = canCheck && supported;
        biometricEnabled = enabled;
        firstLoginCompleted = firstLogin;
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
  // ورود با نام کاربری و رمز عبور
  // =====================================================

  Future<void> login() async {
    final username =
    usernameController.text.trim();

    final password =
    passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        error =
        'لطفاً شماره موبایل و رمز عبور را وارد کنید.';
      });

      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      final result = await apiService.login(
        username: username,
        password: password,
      );

      debugPrint(
        'LOGIN RESULT: $result',
      );

      if (result['success'] != true) {
        throw Exception(
          result['message'] ??
              'اطلاعات ورود صحیح نیست.',
        );
      }

      final access = result['access'];
      final refresh = result['refresh'];

      if (access == null ||
          refresh == null ||
          access.toString().isEmpty ||
          refresh.toString().isEmpty) {
        throw Exception(
          'توکن از سرور دریافت نشد.',
        );
      }

      // -------------------------------------------------
      // ذخیره توکن‌ها
      // -------------------------------------------------

      await TokenStorage.saveTokens(
        access.toString(),
        refresh.toString(),
      );

      // -------------------------------------------------
      // ثبت اینکه حداقل یک بار لاگین موفق انجام شده
      // -------------------------------------------------

      await TokenStorage.setFirstLoginCompleted();

      // -------------------------------------------------
      // اطلاعات کامل کاربر را از /me دریافت می‌کنیم
      // -------------------------------------------------

      final meResult =
      await apiService.getMeWithRefresh();

      debugPrint(
        'ME RESULT AFTER LOGIN: $meResult',
      );

      if (!mounted) return;

      setState(() {
        firstLoginCompleted = true;
      });

      // -------------------------------------------------
      // ورود به پنل
      //
      // کل پاسخ /me را ارسال می‌کنیم:
      //
      // {
      //   success
      //   user
      //   house
      //   units
      // }
      // -------------------------------------------------

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            data: meResult,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'LOGIN ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        error = e.toString().contains(
          'توکن',
        )
            ? e.toString().replaceFirst(
          'Exception: ',
          '',
        )
            : 'خطا در ارتباط با سرور';
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
  // فقط بعد از اولین لاگین امکان‌پذیر است.
  // =====================================================

  Future<void> enableBiometric() async {
    if (loading || biometricLoading) {
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

    // باید توکن داشته باشیم
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

      // فعال‌سازی
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
    if (loading || biometricLoading) {
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
      // -----------------------------------------------
      // فقط احراز هویت
      // -----------------------------------------------

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

      // -----------------------------------------------
      // بررسی وجود توکن‌ها
      // -----------------------------------------------

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

      // -----------------------------------------------
      // دریافت اطلاعات واقعی کاربر
      //
      // این قسمت مهم است.
      // دیگر user قبلی یا null را استفاده نمی‌کنیم.
      // -----------------------------------------------

      final meResult =
      await apiService.getMeWithRefresh();

      debugPrint(
        'BIOMETRIC ME RESULT: $meResult',
      );

      if (!mounted) return;

      // -----------------------------------------------
      // ورود مستقیم به پنل
      // -----------------------------------------------

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            data: meResult,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'BIOMETRIC LOGIN ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        error =
        'جلسه ورود شما منقضی شده است. دوباره با رمز عبور وارد شوید.';
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
      textDirection: TextDirection.rtl,
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
                maxWidth: 360,
              ),
              child: Card(
                elevation: 10,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    22,
                  ),
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      // =================================================
                      // لوگو
                      // =================================================

                      Image.asset(
                        'assets/images/logo.png',
                        width: 170,
                        height: 100,
                        fit: BoxFit.contain,
                      ),

                      const Padding(
                        padding:
                        EdgeInsets.only(
                          bottom: 30,
                        ),
                        child: Text(
                          'متفاوت، با رایا شارژ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                            FontWeight.w500,
                            color:
                            Colors.black87,
                          ),
                        ),
                      ),

                      // =================================================
                      // موبایل
                      // =================================================

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

                      // =================================================
                      // رمز عبور
                      // =================================================

                      TextField(
                        controller:
                        passwordController,
                        obscureText: true,
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

                      // =================================================
                      // خطا
                      // =================================================

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

                      // =================================================
                      // ورود با رمز
                      // =================================================

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
                          child: loading
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

                      // =================================================
                      // بیومتریک
                      //
                      // فقط بعد از اولین ورود
                      // =================================================

                      if (firstLoginCompleted &&
                          biometricAvailable) ...[
                        const SizedBox(
                          height: 18,
                        ),

                        const Row(
                          children: [
                            Expanded(
                              child: Divider(),
                            ),
                            Padding(
                              padding:
                              EdgeInsets
                                  .symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
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
                              child: Divider(),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        // =================================================
                        // فعال‌سازی
                        // =================================================

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
                            child: Padding(
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                vertical: 8,
                                horizontal: 15,
                              ),
                              child: Column(
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

                        // =================================================
                        // ورود با اثر انگشت
                        // =================================================

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
                            child: Padding(
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                vertical: 7,
                                horizontal: 15,
                              ),
                              child: Column(
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