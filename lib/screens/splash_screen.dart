import 'dart:async';

import 'package:flutter/material.dart';

import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String appDescription = '';

  final String fullDescription = 'مدیریت مجتمع مسکونی رایا شارژ';

  int index = 0;

  // نگهداری تایمرها
  Timer? textTimer;
  Timer? navigationTimer;

  @override
  void initState() {
    super.initState();

    startTextAnimation();

    navigationTimer = Timer(
      const Duration(seconds: 3),
          () {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );
      },
    );
  }

  void startTextAnimation() {
    textTimer = Timer.periodic(
      const Duration(milliseconds: 120),
          (timer) {
        // اگر Splash دیگر روی صفحه نیست
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (index < fullDescription.length) {
          setState(() {
            appDescription += fullDescription[index];
            index++;
          });
        } else {
          timer.cancel();
        }
      },
    );
  }

  @override
  void dispose() {
    // متوقف کردن تایمرها هنگام خروج از Splash
    textTimer?.cancel();
    navigationTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff00ACC1),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // لوگو داخل دایره سفید
                    Container(
                      width: 160,
                      height: 160,

                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),

                      padding: const EdgeInsets.all(25),

                      child: Image.asset(
                        'assets/images/splash_logo.png',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // متن متحرک
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),

              child: Text(
                appDescription,

                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // نسخه
            const Padding(
              padding: EdgeInsets.only(bottom: 30),

              child: Text(
                'نسخه 5.2.0',

                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}