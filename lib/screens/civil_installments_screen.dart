import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'manual_civil_payment_screen.dart';

class CivilInstallmentsScreen extends StatefulWidget {
  final int civilId;
  final String civilName;

  const CivilInstallmentsScreen({
    super.key,
    required this.civilId,
    required this.civilName,
  });

  @override
  State<CivilInstallmentsScreen> createState() =>
      _CivilInstallmentsScreenState();
}

class _CivilInstallmentsScreenState
    extends State<CivilInstallmentsScreen> {
  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? civil;
  Map<String, dynamic>? unit;

  List<Map<String, dynamic>> installments = [];

  static const Color primaryColor = Color(0xff00ACC1);
  static const Color purpleColor = Color(0xff610DB5);
  static const Color textColor = Color(0xff263238);
  static const Color backgroundColor = Color(0xffF7F9FA);

  @override
  void initState() {
    super.initState();
    loadInstallments();
  }

  // =====================================================
  // دریافت اقساط
  // =====================================================

  Future<void> loadInstallments() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final result = await ApiService().getCivilInstallments(
        widget.civilId,
      );

      debugPrint('==========================================');
      debugPrint('CIVIL INSTALLMENTS RESULT');
      debugPrint('CIVIL: ${result['civil']}');
      debugPrint('UNIT: ${result['unit']}');
      debugPrint('INSTALLMENTS: ${result['installments']}');
      debugPrint('==========================================');

      if (!mounted) return;

      final resultCivil = result['civil'];
      final resultUnit = result['unit'];
      final resultInstallments = result['installments'];

      final List<Map<String, dynamic>> newInstallments = [];

      if (resultInstallments is List) {
        for (final item in resultInstallments) {
          if (item is Map) {
            newInstallments.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      setState(() {
        if (resultCivil is Map) {
          civil = Map<String, dynamic>.from(
            resultCivil,
          );
        }

        if (resultUnit is Map) {
          unit = Map<String, dynamic>.from(
            resultUnit,
          );
        }

        installments = newInstallments;

        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'CIVIL INSTALLMENTS ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
        'دریافت اقساط شارژ عمرانی با خطا مواجه شد.';
      });
    }
  }

  // =====================================================
  // باز کردن صفحه پرداخت
  //
  // صفحه پرداخت باید در پایان موفقیت:
  //
  // Navigator.pop(context, true);
  //
  // داشته باشد.
  // =====================================================

  Future<void> _openPaymentScreen(
      Map<String, dynamic> item,
      ) async {
    final installmentId = item['id'];

    if (installmentId == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'شناسه قسط پیدا نشد.',
            textDirection: TextDirection.rtl,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    final int id;

    if (installmentId is num) {
      id = installmentId.toInt();
    } else {
      id = int.tryParse(
        installmentId.toString(),
      ) ??
          0;
    }

    if (id <= 0) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'شناسه قسط معتبر نیست.',
            textDirection: TextDirection.rtl,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // ===================================================
    // رفتن به صفحه ثبت پرداخت
    // ===================================================

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ManualCivilPaymentScreen(
              installmentId: id,
            ),
      ),
    );

    if (!mounted) return;

    // ===================================================
    // اگر پرداخت با موفقیت ثبت شده باشد
    // ===================================================

    if (result == true) {
      await _refreshAfterPayment();
    }
  }

  // =====================================================
  // بروزرسانی بعد از ثبت پرداخت
  // =====================================================

  Future<void> _refreshAfterPayment() async {
    if (!mounted) return;

    // ابتدا یک پیام کوتاه
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'در حال بروزرسانی وضعیت پرداخت...',
          textDirection: TextDirection.rtl,
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );

    // دریافت مجدد اطلاعات از سرور
    await loadInstallments();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'وضعیت اقساط بروزرسانی شد.',
          textDirection: TextDirection.rtl,
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
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

    if (value is num) {
      return _formatNumber(value.toInt());
    }

    final text = value
        .toString()
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('.0', '')
        .trim();

    final number = int.tryParse(text) ?? 0;

    return _formatNumber(number);
  }

  String _formatNumber(int number) {
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
  // وضعیت
  // =====================================================

  String installmentStatus(
      Map<String, dynamic> item,
      ) {
    final isPaid = item['is_paid'] == true;

    final paymentPending =
        item['payment_pending'] == true;

    if (isPaid) {
      return 'پرداخت شده';
    }

    if (paymentPending) {
      return 'در انتظار تأیید';
    }

    return 'پرداخت نشده';
  }

  // =====================================================
  // رنگ وضعیت
  // =====================================================

  Color statusColor(
      Map<String, dynamic> item,
      ) {
    final isPaid = item['is_paid'] == true;

    final paymentPending =
        item['payment_pending'] == true;

    if (isPaid) {
      return Colors.green;
    }

    if (paymentPending) {
      return Colors.orange;
    }

    return Colors.red;
  }

// =====================================================
// مبلغ پیش پرداخت سهم همین واحد
// =====================================================

  dynamic get unitPrepayment {
    if (installments.isEmpty) {
      return 0;
    }

    for (final item in installments) {
      final number = item['installment_number'];

      final isPrepayment =
      number is num
          ? number.toInt() == 0
          : number?.toString() == '0';

      if (isPrepayment) {
        return item['prepayment_per_unit'] ?? 0;
      }
    }

    return 0;
  }

  // =====================================================
  // هدر
  // =====================================================

  Widget _buildHeader() {
    final name =
        civil?['name']?.toString() ??
            widget.civilName;

    final unitNumber =
    unit?['unit_number']?.toString();

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
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color:
              primaryColor.withOpacity(0.10),
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.construction_outlined,
              color: primaryColor,
              size: 27,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 5),

                if (unitNumber != null)
                  Text(
                    'واحد ${toPersianDigits(unitNumber)}',
                    style: const TextStyle(
                      fontSize: 11,
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
  // کارت اطلاعات شارژ
  // =====================================================

  Widget _buildCivilInfo() {
    final amount =
        civil?['amount'] ?? 0;

    final installmentCount =
        civil?['installment_count'] ?? 0;

    final details =
        civil?['details']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: purpleColor,
        borderRadius:
        BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
            purpleColor.withOpacity(0.20),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'اطلاعات شارژ عمرانی',
            style: TextStyle(
              fontSize: 15,
              fontWeight:
              FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 15),

          _buildWhiteInfoRow(
            'مبلغ کل',
            '${formatAmount(amount)} تومان',
          ),

          const SizedBox(height: 9),

          _buildWhiteInfoRow(
            'پیش‌پرداخت سهم واحد',
            '${formatAmount(unitPrepayment)} تومان',
          ),

          const SizedBox(height: 9),

          _buildWhiteInfoRow(
            'تعداد اقساط',
            toPersianDigits(
              installmentCount.toString(),
            ),
          ),

          if (details.isNotEmpty) ...[
            const SizedBox(height: 14),

            const Divider(
              color: Colors.white24,
            ),

            const SizedBox(height: 10),

            const Text(
              'توضیحات',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              details,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // ردیف سفید کارت اطلاعات
  // =====================================================

  Widget _buildWhiteInfoRow(
      String title,
      String value,
      ) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),

        const Spacer(),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            overflow:
            TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // کارت قسط / پیش پرداخت
  // =====================================================

  Widget _buildInstallmentCard(
      Map<String, dynamic> item,
      ) {
    final installmentNumber =
        item['installment_number'] ?? 0;

    final amount =
        item['amount'] ?? 0;

    final dueDate =
    item['due_date'];

    final isPaid =
        item['is_paid'] == true;

    final paymentPending =
        item['payment_pending'] == true;

    final canPay =
        item['can_pay'] == true;

    final statusColorValue =
    statusColor(item);

    // ===================================================
    // تشخیص پیش پرداخت
    // ===================================================

    final isPrepayment =
    installmentNumber is num
        ? installmentNumber.toInt() == 0
        : installmentNumber
        .toString() ==
        '0';

    // ===================================================
    // عنوان کارت
    // ===================================================

    final String title;

    if (isPrepayment) {
      title = 'پیش‌پرداخت';
    } else {
      title =
      'قسط شماره ${toPersianDigits(
        installmentNumber.toString(),
      )}';
    }

    const Color iconColor =
        primaryColor;

    return Container(
      margin:
      const EdgeInsets.only(bottom: 12),
      padding:
      const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(18),

        border: Border.all(
          color: canPay
              ? primaryColor.withOpacity(0.35)
              : Colors.black.withOpacity(0.035),
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
          // عنوان و وضعیت
          // =================================================

          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color:
                  iconColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPaid
                      ? Icons
                      .check_circle_outline
                      : isPrepayment
                      ? Icons
                      .account_balance_wallet_outlined
                      : Icons
                      .receipt_long_outlined,
                  color: iconColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColorValue
                      .withOpacity(0.10),
                  borderRadius:
                  BorderRadius.circular(10),
                ),
                child: Text(
                  installmentStatus(item),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    statusColorValue,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Divider(
            height: 1,
          ),

          const SizedBox(height: 12),

          // =================================================
          // مبلغ
          // =================================================

          _buildInfoRow(
            Icons.payments_outlined,
            isPrepayment
                ? 'مبلغ پیش‌پرداخت'
                : 'مبلغ قسط',
            '${formatAmount(amount)} تومان',
          ),

          const SizedBox(height: 9),

          // =================================================
          // سررسید
          // =================================================

          _buildInfoRow(
            Icons.calendar_today_outlined,
            'سررسید',
            formatDate(dueDate),
          ),

          // =================================================
          // دکمه پرداخت
          // =================================================

          if (canPay &&
              !isPaid &&
              !paymentPending) ...[
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () =>
                    _openPaymentScreen(item),

                icon: const Icon(
                  Icons.payment,
                ),

                label: Text(
                  isPrepayment
                      ? 'پرداخت پیش‌پرداخت'
                      : 'پرداخت قسط',
                ),

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  primaryColor,
                  foregroundColor:
                  Colors.white,
                  elevation: 0,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // ردیف اطلاعات
  // =====================================================

  Widget _buildInfoRow(
      IconData icon,
      String title,
      String value,
      ) {
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
          style: const TextStyle(
            fontSize: 11,
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // خطا
  // =====================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 55,
              color: Colors.redAccent,
            ),

            const SizedBox(height: 14),

            Text(
              errorMessage ??
                  'خطا در دریافت اطلاعات',

              textAlign:
              TextAlign.center,

              style:
              const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed:
              loadInstallments,

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
    );
  }

  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Directionality(
      textDirection:
      TextDirection.rtl,

      child: Scaffold(
        backgroundColor:
        backgroundColor,

        // =================================================
        // AppBar
        // =================================================

        appBar: AppBar(
          backgroundColor:
          backgroundColor,

          elevation: 0,

          centerTitle: true,

          title: const Text(
            'شارژ عمرانی',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          iconTheme:
          const IconThemeData(
            color: textColor,
          ),
        ),

        // =================================================
        // Body
        // =================================================

        body: SafeArea(
          child: isLoading
              ? const Center(
            child:
            CircularProgressIndicator(
              color: primaryColor,
            ),
          )
              : errorMessage != null
              ? _buildError()
              : RefreshIndicator(
            color: primaryColor,

            onRefresh:
            loadInstallments,

            child: ListView(
              physics:
              const AlwaysScrollableScrollPhysics(),

              padding:
              const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                30,
              ),

              children: [
                // Header
                _buildHeader(),

                const SizedBox(
                  height: 14,
                ),

                // اطلاعات شارژ
                _buildCivilInfo(),

                const SizedBox(
                  height: 18,
                ),

                // =================================================
                // اقساط
                // =================================================

                if (installments
                    .isEmpty)
                  const Center(
                    child:
                    Padding(
                      padding:
                      EdgeInsets.all(
                        40,
                      ),
                      child:
                      Text(
                        'برای این شارژ هنوز قسطی ثبت نشده است.',
                        textAlign:
                        TextAlign.center,
                        style:
                        TextStyle(
                          color:
                          Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  for (final item
                  in installments)
                    _buildInstallmentCard(
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