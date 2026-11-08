
import 'package:flutter/material.dart';

import 'manager_fund_turnover_screen.dart';
import 'manager_debtor_units_screen.dart';
import 'manager_creditor_units_screen.dart';
import 'manager_sewage_charges_list_screen.dart';
import 'manager_user_help_money_screen.dart';

const Color _primaryColor = Color(0xFF00ACC1);
const Color _secondaryColor = Color(0xFF610DB5);
const Color _pageBackground = Color(0xFFF5F7FA);
const Color _primaryText = Color(0xFF263238);

class ManagerReportsScreen extends StatelessWidget {
  const ManagerReportsScreen({super.key});

  static const List<_ReportItem> _reports = [
    _ReportItem(
      title: 'گردش صندوق',
      subtitle: 'گزارش دریافت‌ها و پرداخت‌های صندوق',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF00ACC1),
      background: Color(0xFFE0F7FA),
    ),
    _ReportItem(
      title: 'واحدهای بدهکار',
      subtitle: 'مشاهده واحدهای دارای بدهی',
      icon: Icons.trending_down_rounded,
      color: Color(0xFFD32F2F),
      background: Color(0xFFFFEBEE),
    ),
    _ReportItem(
      title: 'واحدهای بستانکار',
      subtitle: 'مشاهده واحدهای دارای اعتبار',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF610DB5),
      background: Color(0xFFEDE7F6),
    ),
    _ReportItem(
      title: 'هزینه فاضلاب',
      subtitle: 'گزارش هزینه‌ها و پرداخت‌های فاضلاب',
      icon: Icons.water_drop_rounded,
      color: Color(0xFFEF6C00),
      background: Color(0xFFFFF3E0),
    ),
    _ReportItem(
      title: 'کمک ساکنین',
      subtitle: 'گزارش مشارکت‌های مالی ساکنین',
      icon: Icons.volunteer_activism_rounded,
      color: Color(0xFF2E7D32),
      background: Color(0xFFE8F5E9),
    ),
    _ReportItem(
      title: 'گردش حساب بانک ها',
      subtitle: 'گزارش تراکنش حساب های بانکی',
      icon: Icons.account_balance_rounded,
      color: Color(0xFFF3C582),
      background: Color(0xFFEDE7F6),
    ),
  ];

  void _openReport(BuildContext context, _ReportItem report) {
    if (report.title == 'گردش صندوق') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ManagerFundTurnoverScreen(),
        ),
      );
      return;
    }
    if (report.title == 'واحدهای بدهکار') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ManagerDebtorUnitsScreen(),
        ),
      );
      return;
    }
    if (report.title == 'واحدهای بستانکار') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ManagerCreditorUnitsScreen(),
        ),
      );
      return;
    }
    if (report.title == 'هزینه فاضلاب') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ManagerSewageChargesListScreen(),
        ),
      );
      return;
    }
    if (report.title == 'کمک ساکنین') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ManagerUserHelpMoneyScreen(),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'گزارش ${report.title} به‌زودی قابل استفاده خواهد بود.',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: _secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        toolbarHeight: 88,
        title: const Text(
          'مدیریت گزارش‌ها',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _reports.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (context, index) {
                    final report = _reports[index];

                    return _ReportCard(
                      report: report,
                      onTap: () => _openReport(context, report),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, _secondaryColor],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // const Icon(
          //   Icons.analytics_rounded,
          //   color: Colors.white,
          //   size: 38,
          // ),
          // const SizedBox(width: 14),
          const Expanded(
            child: Center(
              child: Text(
                'برای مشاهده گزارش‌های بیشتر به صفحه وب رایا شارژ مراجعه کنید',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  height: 1.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;

  const _ReportItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
  });
}

class _ReportCard extends StatelessWidget {
  final _ReportItem report;
  final VoidCallback onTap;

  const _ReportCard({
    required this.report,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 1.5,
      shadowColor: Colors.black.withOpacity(0.06),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 5,
              color: report.color,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 45,
                      decoration: BoxDecoration(
                        color: report.background,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        report.icon,
                        color: report.color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      report.title,
                      maxLines: 2,
                      style: const TextStyle(
                        color: _primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      report.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.blueGrey.shade500,
                        fontSize: 10,
                        height: 1.6,
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
                        color: report.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
