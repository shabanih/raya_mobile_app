
import 'package:flutter/material.dart';
import 'manager_expenses_screen.dart';
import 'manager_incomes_screen.dart';
import 'manager_receivables_screen.dart';
import 'manager_payables_screen.dart';

class ManagerOperationsScreen extends StatelessWidget {
  const ManagerOperationsScreen({super.key});

  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);
  static const Color _background = Color(0xFFF6F7FB);

  static const List<_OperationItem> _operations = [
    _OperationItem(
      title: 'ثبت هزینه',
      subtitle: 'ثبت و مدیریت هزینه‌های ساختمان',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF00838F),
      background: Color(0xFFE0F7FA),
    ),
    _OperationItem(
      title: 'ثبت درآمد',
      subtitle: 'ثبت و مدیریت درآمدهای ساختمان',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF2E7D32),
      background: Color(0xFFE8F5E9),
    ),
    _OperationItem(
      title: 'ثبت اسناد دریافتنی',
      subtitle: 'مدیریت چک‌ها و مطالبات دریافتی',
      icon: Icons.move_to_inbox_rounded,
      color: Color(0xFF610DB5),
      background: Color(0xFFEDE7F6),
    ),
    _OperationItem(
      title: 'ثبت اسناد پرداختنی',
      subtitle: 'مدیریت چک‌ها و تعهدات پرداختی',
      icon: Icons.outbox_rounded,
      color: Color(0xFFEF6C00),
      background: Color(0xFFFFF3E0),
    ),
    _OperationItem(
      title: 'ثبت هزینه تعمیر و نگهداری',
      subtitle: 'ثبت تعمیرات و هزینه‌های نگهداری ساختمان',
      icon: Icons.home_repair_service_rounded,
      color: Color(0xFFAD1457),
      background: Color(0xFFFCE4EC),
    ),
    _OperationItem(
      title: 'ثبت اموال',
      subtitle: 'ثبت و مدیریت دارایی‌های ساختمان',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF1565C0),
      background: Color(0xFFE3F2FD),
    ),
    _OperationItem(
      title: 'ثبت هزینه فاضلاب',
      subtitle: 'ثبت و پیگیری هزینه‌های فاضلاب',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF7B1FA2),
      background: Color(0xFFF3E5F5),
    ),
    _OperationItem(
      title: 'ثبت اشخاص ثالث',
      subtitle: 'ثبت و مدیریت اشخاص و طرف‌حساب‌ها',
      icon: Icons.people_alt_rounded,
      color: Color(0xFFF3C582),
      background: Color(0xFFEDE7F6),
    ),
  ];

  void _openOperation(BuildContext context, _OperationItem operation) {
    if (operation.title == 'ثبت هزینه') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ManagerExpensesScreen(),
        ),
      );
      return;
    }

    if (operation.title == 'ثبت درآمد') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ManagerIncomesScreen(),
        ),
      );
      return;
    }
    if (operation.title == 'ثبت اسناد دریافتنی') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ManagerReceivablesScreen(),
        ),
      );
      return;
    }
    if (operation.title == 'ثبت اسناد پرداختنی') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ManagerPayablesScreen(),
        ),
      );
      return;
    }



    _showComingSoon(context, operation.title);
  }

  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'صفحه $title هنوز فعال نشده است.',
            textDirection: TextDirection.rtl,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _purple,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: const Text(
            'مدیریت عملیات',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
          centerTitle: true,
          foregroundColor: Colors.white,
          backgroundColor: _teal,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final operation = _operations[index];

                      return _OperationCard(
                        operation: operation,
                        onTap: () => _openOperation(context, operation),
                      );
                    },
                    childCount: _operations.length,
                  ),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 174,
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

class _OperationItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;

  const _OperationItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
  });
}

class _OperationCard extends StatelessWidget {
  final _OperationItem operation;
  final VoidCallback onTap;

  const _OperationCard({
    required this.operation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: operation.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  operation.icon,
                  color: operation.color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                operation.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF303044),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  operation.subtitle,
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
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: operation.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
