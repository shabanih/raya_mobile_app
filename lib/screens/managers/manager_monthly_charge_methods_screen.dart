
import 'package:flutter/material.dart';

import '../../services/manager_charges_service.dart';

import 'manager_fixed_charges_screen.dart';
import 'manager_area_charges_screen.dart';
import 'manager_person_charges_screen.dart';
import 'manager_fix_area_charges_screen.dart';
import 'manager_fix_person_charges_screen.dart';
import 'manager_person_area_charges_screen.dart';
import 'manager_fix_person_area_charges_screen.dart';
import 'manager_fix_variable_charges_screen.dart';
import 'manager_charge_calculation_screen.dart';

class ManagerMonthlyChargeMethodsScreen extends StatefulWidget {
  const ManagerMonthlyChargeMethodsScreen({super.key});

  @override
  State<ManagerMonthlyChargeMethodsScreen> createState() =>
      _ManagerMonthlyChargeMethodsScreenState();
}

class _ManagerMonthlyChargeMethodsScreenState
    extends State<ManagerMonthlyChargeMethodsScreen> {
  static const Color primaryColor = Color(0xff00ACC1);

  final ManagerChargesService _service = ManagerChargesService();

  bool _loading = true;
  String? _error;

  Set<int> _allowedMethodIds = <int>{};

  // شناسه‌ها دقیقاً مطابق ChargeMethod در دیتابیس Django هستند.
  static const List<_ChargeMethod> methods = [
    _ChargeMethod(
      id: 1,
      title: 'شارژ واحدی',
      description: 'محاسبه شارژ بر اساس تعداد واحدها',
      icon: Icons.apartment_rounded,
      color: Color(0xff00838F),
    ),
    _ChargeMethod(
      id: 2,
      title: 'شارژ نفری',
      description: 'محاسبه شارژ بر اساس تعداد نفرات',
      icon: Icons.people_alt_rounded,
      color: Color(0xffEF6C00),
    ),
    _ChargeMethod(
      id: 3,
      title: 'شارژ واحدی - نفری',
      description: 'ترکیب سهم واحدی و نفری',
      icon: Icons.groups_rounded,
      color: Color(0xffF9A825),
    ),
    _ChargeMethod(
      id: 4,
      title: 'شارژ متراژی',
      description: 'محاسبه شارژ بر اساس متراژ واحدها',
      icon: Icons.square_foot_rounded,
      color: Color(0xff610DB5),
    ),
    _ChargeMethod(
      id: 5,
      title: 'شارژ واحدی - متراژی',
      description: 'ترکیب سهم واحدی و متراژی',
      icon: Icons.balance_rounded,
      color: Color(0xff2E7D32),
    ),
    _ChargeMethod(
      id: 6,
      title: 'شارژ واحدی - نفری - متراژی',
      description: 'ترکیب هر سه معیار محاسبه',
      icon: Icons.calculate_rounded,
      color: Color(0xff1565C0),
    ),
    _ChargeMethod(
      id: 7,
      title: 'شارژ نفری - متراژی',
      description: 'ترکیب سهم نفری و متراژی',
      icon: Icons.scale_rounded,
      color: Color(0xffC2185B),
    ),
    _ChargeMethod(
      id: 8,
      title: 'شارژ ثابت و متغیر',
      description: 'ترکیب مبلغ ثابت و سهم متغیر',
      icon: Icons.tune_rounded,
      color: Color(0xff7B1FA2),
    ),
    _ChargeMethod(
      id: 9,
      title: 'شارژ تسهیم هزینه',
      description: 'تخصیص هزینه‌ها بر اساس معیارهای تسهیم',
      icon: Icons.receipt_long_rounded,
      color: Color(0xff455A64),
    ),
  ];

  List<_ChargeMethod> get _visibleMethods {
    return methods
        .where((method) => _allowedMethodIds.contains(method.id))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await _service.getChargeMethods();

      final ids = results
          .map((item) => int.tryParse(item['id'].toString()))
          .whereType<int>()
          .toSet();

      debugPrint('ALLOWED CHARGE METHOD IDS: $ids');

      if (!mounted) return;

      setState(() {
        _allowedMethodIds = ids;
        _loading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('LOAD CHARGE METHODS ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onMethodTap(
      BuildContext context,
      _ChargeMethod method,
      ) {
    // بررسی دسترسی قبل از باز کردن صفحه.
    if (!_allowedMethodIds.contains(method.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('شما به این روش شارژ دسترسی ندارید.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final Widget page;

    switch (method.id) {
      case 1:
        page = const ManagerFixedChargesScreen();
        break;

      case 2:
        page = const ManagerPersonChargesScreen();
        break;

      case 3:
        page = const ManagerFixPersonChargesScreen();
        break;

      case 4:
        page = const ManagerAreaChargesScreen();
        break;

      case 5:
        page = const ManagerFixAreaChargesScreen();
        break;

      case 6:
        page = const ManagerFixPersonAreaChargesScreen();
        break;

      case 7:
        page = const ManagerPersonAreaChargesScreen();
        break;

      case 8:
        page = const ManagerFixVariableChargesScreen();
        break;

      case 9:
        page = const ManagerChargeCalculationScreen();
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('صفحه این روش شارژ تعریف نشده است.'),
          ),
        );
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleMethods = _visibleMethods;

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
          actions: [
            if (!_loading)
              IconButton(
                tooltip: 'به‌روزرسانی دسترسی‌ها',
                onPressed: _loadMethods,
                icon: const Icon(Icons.refresh_rounded),
              ),
          ],
        ),
        body: SafeArea(
          child: _buildBody(visibleMethods),
        ),
      ),
    );
  }

  Widget _buildBody(List<_ChargeMethod> visibleMethods) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
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
                Icons.error_outline_rounded,
                size: 44,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              const Text(
                'دریافت دسترسی‌های روش شارژ ناموفق بود.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadMethods,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }

    if (visibleMethods.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: Colors.black38,
              ),
              const SizedBox(height: 12),
              const Text(
                'هیچ روش شارژی برای شما فعال نشده است.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loadMethods,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('بررسی مجدد'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
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
          itemCount: visibleMethods.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 11,
            mainAxisSpacing: 11,
            mainAxisExtent: 158,
          ),
          itemBuilder: (context, index) {
            final method = visibleMethods[index];

            return _MethodCard(
              method: method,
              onTap: () => _onMethodTap(context, method),
            );
          },
        ),
      ],
    );
  }
}

class _ChargeMethod {
  final int id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _ChargeMethod({
    required this.id,
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
