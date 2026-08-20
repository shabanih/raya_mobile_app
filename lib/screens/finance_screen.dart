import 'package:flutter/material.dart';

import '../services/api_service.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> transactions = [];

  static const Color primaryColor = Color(0xff00ACC1);
  static const Color textColor = Color(0xff263238);
  static const Color backgroundColor = Color(0xffF7F9FA);

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  // =====================================================
  // دریافت تراکنش‌ها
  // =====================================================

  Future<void> loadTransactions() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final result = await ApiService().getPaymentHistory();

      debugPrint('==========================================');
      debugPrint(
        'FINANCE RESULT COUNT: ${result.length}',
      );

      for (final item in result) {
        debugPrint(
          'FINANCE ITEM: $item',
        );
      }

      debugPrint(
        'TOTAL PAID AMOUNT: $totalPaidAmount',
      );

      debugPrint('==========================================');

      if (!mounted) return;

      setState(() {
        transactions = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'FINANCE LOAD ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
        'دریافت تراکنش‌ها با خطا مواجه شد.';
      });
    }
  }

  // =====================================================
  // اعداد فارسی
  // =====================================================

  String toPersianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    for (int i = 0; i < english.length; i++) {
      value = value.replaceAll(
        english[i],
        persian[i],
      );
    }

    return value;
  }

  // =====================================================
  // فرمت مبلغ
  // =====================================================

  String formatAmount(dynamic value) {
    if (value == null) {
      return '۰';
    }

    final text = value
        .toString()
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('.0', '')
        .trim();

    final number = int.tryParse(text) ?? 0;

    final numberText = number.toString();

    final buffer = StringBuffer();

    for (int i = 0; i < numberText.length; i++) {
      if (i > 0 &&
          (numberText.length - i) % 3 == 0) {
        buffer.write('٬');
      }

      buffer.write(numberText[i]);
    }

    return toPersianDigits(
      buffer.toString(),
    );
  }

  // =====================================================
  // تبدیل مبلغ به عدد
  // =====================================================

  int parseAmount(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toInt();
    }

    final text = value
        .toString()
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('.0', '')
        .trim();

    return int.tryParse(text) ?? 0;
  }

  // =====================================================
  // مجموع پرداختی
  // =====================================================

  int get totalPaidAmount {
    int total = 0;

    for (final item in transactions) {
      final amount =
          item['amount'] ??
              item['debtor_amount'] ??
              0;

      total += parseAmount(amount);
    }

    return total;
  }

  // =====================================================
  // تاریخ میلادی به شمسی
  // =====================================================

  String formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    final raw = value.toString().trim();

    if (raw.isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(raw);

      final jalali = _gregorianToJalali(
        date.year,
        date.month,
        date.day,
      );

      return toPersianDigits(
        '${jalali[0]}/'
            '${jalali[1].toString().padLeft(2, '0')}/'
            '${jalali[2].toString().padLeft(2, '0')}',
      );
    } catch (_) {
      return raw;
    }
  }

  // =====================================================
  // تبدیل میلادی به شمسی
  // =====================================================

  List<int> _gregorianToJalali(
      int gy,
      int gm,
      int gd,
      ) {
    final gDaysInMonth = <int>[
      31,
      28,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31,
    ];

    final jDaysInMonth = <int>[
      31,
      31,
      31,
      31,
      31,
      31,
      30,
      30,
      30,
      30,
      29,
    ];

    int gy2 = gy - 1600;
    int gm2 = gm - 1;
    int gd2 = gd - 1;

    int gDayNo =
        365 * gy2 +
            ((gy2 + 3) ~/ 4) -
            ((gy2 + 99) ~/ 100) +
            ((gy2 + 399) ~/ 400);

    for (int i = 0; i < gm2; i++) {
      gDayNo += gDaysInMonth[i];
    }

    if (gm2 > 1 &&
        ((gy % 4 == 0 && gy % 100 != 0) ||
            gy % 400 == 0)) {
      gDayNo++;
    }

    gDayNo += gd2;

    int jDayNo = gDayNo - 79;

    int jNp = jDayNo ~/ 12053;

    int jy = 979 + 33 * jNp;

    jDayNo %= 12053;

    jy += 4 * (jDayNo ~/ 1461);

    jDayNo %= 1461;

    if (jDayNo >= 366) {
      jy += (jDayNo - 1) ~/ 365;
      jDayNo = (jDayNo - 1) % 365;
    }

    int jm = 0;

    for (
    int i = 0;
    i < 11 &&
        jDayNo >= jDaysInMonth[i];
    i++
    ) {
      jDayNo -= jDaysInMonth[i];
      jm++;
    }

    return [
      jy,
      jm + 1,
      jDayNo + 1,
    ];
  }

  // =====================================================
  // کارت تراکنش
  // =====================================================

  Widget _buildTransactionCard(
      Map<String, dynamic> item,
      ) {
    final description =
    item['payment_description']
        ?.toString()
        .trim();

    final amount =
        item['amount'] ??
            item['debtor_amount'] ??
            0;

    final paymentDate =
    item['payment_date'];

    final transactionNo =
    item['transaction_no']
        ?.toString()
        .trim();

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withOpacity(0.035),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.045),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // =================================================
          // عنوان
          // =================================================

          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                  primaryColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: primaryColor,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  description != null &&
                      description.isNotEmpty
                      ? toPersianDigits(
                    description,
                  )
                      : 'تراکنش مالی',
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Divider(height: 1),

          const SizedBox(height: 12),

          // =================================================
          // مبلغ
          // =================================================

          _buildInfoRow(
            icon:
            Icons.payments_outlined,
            title: 'مبلغ',
            value:
            '${formatAmount(amount)} تومان',
            valueBold: true,
          ),

          const SizedBox(height: 10),

          // =================================================
          // تاریخ پرداخت
          // =================================================

          _buildInfoRow(
            icon:
            Icons.calendar_today_outlined,
            title: 'تاریخ پرداخت',
            value:
            formatDate(paymentDate),
          ),

          const SizedBox(height: 10),

          // =================================================
          // شماره تراکنش
          // =================================================

          _buildInfoRow(
            icon:
            Icons.confirmation_number_outlined,
            title: 'شماره تراکنش',
            value:
            transactionNo != null &&
                transactionNo.isNotEmpty
                ? toPersianDigits(
              transactionNo,
            )
                : '-',
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ردیف اطلاعات
  // =====================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool valueBold = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: primaryColor,
        ),

        const SizedBox(width: 8),

        Text(
          title,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),

        const Spacer(),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            overflow:
            TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: valueBold
                  ? FontWeight.bold
                  : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // Header
  // =====================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.045),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color:
              primaryColor.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: primaryColor,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'تراکنش‌های من',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                    color: textColor,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'سوابق تراکنش‌های مالی شما',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color:
              primaryColor.withOpacity(0.08),
              borderRadius:
              BorderRadius.circular(10),
            ),
            child: Text(
              toPersianDigits(
                transactions.length.toString(),
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // کارت مجموع پرداختی
  // =====================================================

  Widget _buildTotalPaidCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius:
        BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
            primaryColor.withOpacity(0.20),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
              Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: Colors.white,
              size: 25,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'مجموع پرداختی',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.baseline,
                  textBaseline:
                  TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        formatAmount(
                          totalPaidAmount,
                        ),
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight:
                          FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    const Text(
                      'تومان',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // بدون تراکنش
  // =====================================================

  Widget _buildEmpty() {
    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        30,
      ),
      children: [
        _buildHeader(),

        const SizedBox(height: 12),

        _buildTotalPaidCard(),

        SizedBox(
          height:
          MediaQuery.of(context).size.height *
              0.20,
        ),

        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color:
                  primaryColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: primaryColor,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'تراکنشی ثبت نشده است',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                  FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 7),

              const Text(
                'هنوز تراکنش مالی برای شما ثبت نشده است.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // خطا
  // =====================================================

  Widget _buildError() {
    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        30,
      ),
      children: [
        _buildHeader(),

        const SizedBox(height: 12),

        _buildTotalPaidCard(),

        SizedBox(
          height:
          MediaQuery.of(context).size.height *
              0.18,
        ),

        Center(
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 50,
                color: Colors.redAccent,
              ),

              const SizedBox(height: 12),

              Text(
                errorMessage ??
                    'خطا در دریافت اطلاعات',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 14),

              ElevatedButton(
                onPressed: loadTransactions,
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  primaryColor,
                  foregroundColor:
                  Colors.white,
                  elevation: 0,
                ),
                child: const Text(
                  'تلاش مجدد',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        backgroundColor: backgroundColor,

        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          centerTitle: true,

          iconTheme: const IconThemeData(
            color: textColor,
          ),

          title: const Text(
            'تراکنش‌های من',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        body: SafeArea(
          child: RefreshIndicator(
            color: primaryColor,
            backgroundColor: Colors.white,
            onRefresh: loadTransactions,

            child: isLoading
                ? const Center(
              child:
              CircularProgressIndicator(
                color: primaryColor,
              ),
            )

                : errorMessage != null
                ? _buildError()

                : transactions.isEmpty
                ? _buildEmpty()

                : ListView(
              physics:
              const AlwaysScrollableScrollPhysics(),

              padding:
              const EdgeInsets.fromLTRB(
                18,
                18,
                18,
                30,
              ),

              children: [
                _buildHeader(),

                const SizedBox(
                  height: 12,
                ),

                _buildTotalPaidCard(),

                const SizedBox(
                  height: 16,
                ),

                for (final item
                in transactions)
                  _buildTransactionCard(
                    item,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}