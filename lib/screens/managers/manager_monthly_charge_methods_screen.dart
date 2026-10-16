
import 'package:flutter/material.dart';

import 'manager_fixed_charges_screen.dart';
import 'manager_area_charges_screen.dart';
import 'manager_person_charges_screen.dart';

class ManagerMonthlyChargeMethodsScreen extends StatelessWidget {
  const ManagerMonthlyChargeMethodsScreen({super.key});

  static const Color primaryColor = Color(0xff00ACC1);
  static const Color purpleColor = Color(0xff610DB5);

  static const List<_ChargeMethod> methods = [
    _ChargeMethod(
      title: 'شارژ واحدی',
      description: 'محاسبه شارژ بر اساس تعداد واحدها',
      icon: Icons.apartment_rounded,
      color: Color(0xff00838F),
    ),
    _ChargeMethod(
      title: 'شارژ متراژی',
      description: 'محاسبه شارژ بر اساس متراژ واحدها',
      icon: Icons.square_foot_rounded,
      color: Color(0xff610DB5),
    ),
    _ChargeMethod(
      title: 'شارژ نفری',
      description: 'محاسبه شارژ بر اساس تعداد نفرات',
      icon: Icons.people_alt_rounded,
      color: Color(0xffEF6C00),
    ),
    _ChargeMethod(
      title: 'شارژ واحدی - متراژی',
      description: 'ترکیب سهم واحدی و متراژی',
      icon: Icons.balance_rounded,
      color: Color(0xff2E7D32),
    ),
    _ChargeMethod(
      title: 'شارژ واحدی - نفری',
      description: 'ترکیب سهم واحدی و نفری',
      icon: Icons.groups_rounded,
      color: Color(0xffF9A825),
    ),
    _ChargeMethod(
      title: 'شارژ نفری - متراژی',
      description: 'ترکیب سهم نفری و متراژی',
      icon: Icons.scale_rounded,
      color: Color(0xffC2185B),
    ),
    _ChargeMethod(
      title: 'شارژ واحدی - نفری - متراژی',
      description: 'ترکیب هر سه معیار محاسبه',
      icon: Icons.calculate_rounded,
      color: Color(0xff1565C0),
    ),
    _ChargeMethod(
      title: 'شارژ ثابت و متغیر',
      description: 'ترکیب مبلغ ثابت و سهم متغیر',
      icon: Icons.tune_rounded,
      color: Color(0xff7B1FA2),
    ),
    _ChargeMethod(
      title: 'شارژ تسهیم هزینه',
      description: 'تخصیص هزینه‌ها بر اساس معیارهای تسهیم',
      icon: Icons.receipt_long_rounded,
      color: Color(0xff455A64),
    ),
  ];

  void _onMethodTap(BuildContext context, int index) {
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ManagerFixedChargesScreen(),
        ),
      );
      return;
    }
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ManagerAreaChargesScreen(),
        ),
      );
      return;
    }

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ManagerPersonChargesScreen(),
        ),
      );
      return;
    }


    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'روش «${methods[index].title}» انتخاب شد.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF5F8FA),
        appBar: AppBar(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'روش‌های شارژ ماهانه',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              14,
              16,
              14,
              24,
            ),
            children: [
              const Text(
                'انتخاب روش محاسبه',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff263238),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'روش مناسب برای محاسبه شارژ ماهانه ساختمان را انتخاب کنید.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.8,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: methods.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 11,
                  mainAxisSpacing: 11,
                  mainAxisExtent: 158,
                ),
                itemBuilder: (context, index) {
                  final method = methods[index];

                  return _MethodCard(
                    method: method,
                    onTap: () => _onMethodTap(context, index),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChargeMethod {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _ChargeMethod({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _MethodCard extends StatelessWidget {
  final _ChargeMethod method;
  final VoidCallback onTap;

  const _MethodCard({
    super.key,
    required this.method,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xffECEFF1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: method.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  method.icon,
                  color: method.color,
                  size: 27,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                method.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff263238),
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Text(
                  method.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
