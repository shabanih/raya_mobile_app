
import 'package:flutter/material.dart';
import 'manager_monthly_charge_methods_screen.dart';
class ManagerChargesScreen extends StatelessWidget {
  const ManagerChargesScreen({super.key});

  static const Color primaryColor = Color(0xff00ACC1);
  static const Color purpleColor = Color(0xff610DB5);

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildChargeCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xffECEFF1),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff263238),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.8,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: 28,
              ),
            ],
          ),
        ),
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
            'مدیریت شارژها',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Container(
                //   padding: const EdgeInsets.all(18),
                //   decoration: BoxDecoration(
                //     gradient: const LinearGradient(
                //       begin: Alignment.topRight,
                //       end: Alignment.bottomLeft,
                //       colors: [
                //         Color(0xff00ACC1),
                //         Color(0xff00838F),
                //       ],
                //     ),
                //     borderRadius: BorderRadius.circular(20),
                //   ),
                //   child: const Row(
                //     children: [
                //       Icon(
                //         Icons.receipt_long_rounded,
                //         color: Colors.white,
                //         size: 38,
                //       ),
                //       SizedBox(width: 14),
                //       // Expanded(
                //       //   child: Column(
                //       //     crossAxisAlignment: CrossAxisAlignment.start,
                //       //     children: [
                //       //       Text(
                //       //         'مدیریت مالی ساختمان',
                //       //         style: TextStyle(
                //       //           color: Colors.white,
                //       //           fontSize: 17,
                //       //           fontWeight: FontWeight.bold,
                //       //         ),
                //       //       ),
                //       //       SizedBox(height: 7),
                //       //       Text(
                //       //         'نوع شارژ موردنظر را انتخاب کنید.',
                //       //         style: TextStyle(
                //       //           color: Colors.white,
                //       //           fontSize: 12,
                //       //           height: 1.7,
                //       //         ),
                //       //       ),
                //       //     ],
                //       //   ),
                //       // ),
                //     ],
                //   ),
                // ),
                // const SizedBox(height: 22),
                // const Text(
                //   'انتخاب نوع شارژ',
                //   style: TextStyle(
                //     fontSize: 16,
                //     fontWeight: FontWeight.bold,
                //     color: Color(0xff263238),
                //   ),
                // ),
                const SizedBox(height: 16),

                _buildChargeCard(
                  context: context,
                  title: 'شارژ ماهانه',
                  description:
                  'محاسبه و ثبت شارژ ماهانه واحدهای ساختمان',
                  icon: Icons.calendar_month_rounded,
                  color: primaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const ManagerMonthlyChargeMethodsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _buildChargeCard(
                  context: context,
                  title: 'شارژ عمرانی',
                  description:
                  'مدیریت هزینه‌ها و شارژهای عمرانی ساختمان',
                  icon: Icons.construction_rounded,
                  color: purpleColor,
                  onTap: () {
                    _showMessage(
                      context,
                      'بخش شارژ عمرانی در مرحله بعد تکمیل می‌شود.',
                    );
                  },
                ),
                const SizedBox(height: 12),

                _buildChargeCard(
                  context: context,
                  title: 'شارژهای من',
                  description:
                  'مشاهده و پیگیری شارژهای ثبت‌شده توسط مدیر',
                  icon: Icons.receipt_long_rounded,
                  color: const Color(0xffEF6C00),
                  onTap: () {
                    _showMessage(
                      context,
                      'صفحه شارژهای من در مرحله بعد تکمیل می‌شود.',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
