import 'package:flutter/material.dart';

import 'manager_my_monthly_charges_screen.dart';
import 'manager_civil_charges_list_screen.dart';

class ManagerMyChargesScreen extends StatelessWidget {
  final VoidCallback? onMonthlyChargesTap;
  final VoidCallback? onCivilChargesTap;

  const ManagerMyChargesScreen({
    super.key,
    this.onMonthlyChargesTap,
    this.onCivilChargesTap,
  });

  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(
          title: const Text(
            ' شارژهای من',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'نوع شارژ را انتخاب کنید',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 18),
              _ChargeTypeCard(
                title: 'شارژهای ماهیانه',
                subtitle: 'مدیریت شارژهای ماهیانه ساختمان',
                icon: Icons.calendar_month_rounded,
                color: _teal,
                onTap: onMonthlyChargesTap ??
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManagerMonthlyChargesScreen(),
                        ),
                      );
                    },
              ),
              const SizedBox(height: 14),
              _ChargeTypeCard(
                title: 'شارژهای عمرانی',
                subtitle: 'مدیریت شارژهای عمرانی ساختمان',
                icon: Icons.apartment_rounded,
                color: _purple,
                onTap: onCivilChargesTap ??
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManagerCivilChargesListScreen(),
                        ),
                      );
                    },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotConnectedMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ChargeTypeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ChargeTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: color.withValues(alpha: 0.16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 31),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF202733),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.7,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_back_ios_new_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
