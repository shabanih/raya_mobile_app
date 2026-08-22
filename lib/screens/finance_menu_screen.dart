import 'package:flutter/material.dart';

import 'finance_screen.dart';
import 'civil_charge_screen.dart';
import 'sewage_charge_screen.dart';
import 'user_payments_screen.dart';


class FinanceMenuScreen extends StatelessWidget {
  const FinanceMenuScreen({super.key});

  // =====================================================
  // Colors
  // =====================================================

  static const Color primaryColor = Color(0xff610DB5);
  static const Color headerColor = Color(0xff00ACC1);
  static const Color textColor = Color(0xff263238);
  static const Color backgroundColor = Color(0xffF7F9FA);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            30,
          ),
          children: [
            // =================================================
            // Header
            // =================================================

            _buildHeader(),

            const SizedBox(height: 20),

            // =================================================
            // شارژ عمرانی
            // =================================================

            _buildFinanceCard(
              context: context,
              icon: Icons.construction_outlined,
              title: 'شارژ عمرانی',
              subtitle: 'مشاهده و پرداخت شارژ عمرانی ساختمان',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const CivilChargeScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // =================================================
            // هزینه فاضلاب
            // =================================================

            _buildFinanceCard(
              context: context,
              icon: Icons.construction_outlined,
              title: 'هزینه فاضلاب',
              subtitle: 'مشاهده و پرداخت هزینه فاضلاب ساختمان',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const SewageChargeScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // =================================================
            // تراکنش‌های من
            // =================================================

            _buildFinanceCard(
              context: context,
              icon: Icons.receipt_long_outlined,
              title: 'تراکنش‌های من',
              subtitle: 'مشاهده سوابق تراکنش‌های مالی شما',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FinanceScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // =================================================
            // کمک به ساختمان
            // =================================================

            _buildFinanceCard(
              context: context,
              icon: Icons.volunteer_activism_outlined,
              title: 'کمک به ساختمان',
              subtitle: 'مشارکت و کمک مالی به ساختمان',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserPaymentsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Header
  // =====================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // =================================================
          // Header Icon
          // =================================================

          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          // =================================================
          // Header Text
          // =================================================

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'امور مالی',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'مدیریت امور مالی ساختمان',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Finance Card
  // =====================================================

  Widget _buildFinanceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 112,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.black.withOpacity(0.035),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.045),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // =================================================
              // Icon
              // =================================================

              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),

              const SizedBox(width: 16),

              // =================================================
              // Text
              // =================================================

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // =================================================
              // Arrow
              // =================================================

              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: primaryColor,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // Coming Soon
  // =====================================================

  void _showComingSoon(
      BuildContext context,
      String title,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$title به‌زودی فعال می‌شود.',
          textDirection: TextDirection.rtl,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}