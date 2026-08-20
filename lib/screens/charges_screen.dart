import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../services/api_service.dart';
import 'payment_method_screen.dart';

class ChargesScreen extends StatefulWidget {
  const ChargesScreen({super.key});

  @override
  State<ChargesScreen> createState() => _ChargesScreenState();
}

class _ChargesScreenState extends State<ChargesScreen> {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> charges = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadCharges();
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
    final amount =
        int.tryParse(value?.toString() ?? '0') ?? 0;

    final text = amount.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) {
        buffer.write('٬');
      }

      buffer.write(text[i]);
    }

    return toPersianDigits(
      buffer.toString(),
    );
  }

  // =====================================================
  // عنوان فارسی شارژ
  // =====================================================

  String getChargeTitle(
      Map<String, dynamic> charge,
      ) {
    final title =
    charge['title']?.toString().trim();

    if (title != null && title.isNotEmpty) {
      return toPersianDigits(title);
    }

    final type =
    charge['charge_type']?.toString();

    String result;

    switch (type) {
      case 'fix':
        result = 'شارژ ثابت';
        break;

      case 'area':
        result = 'شارژ متراژی';
        break;

      case 'person':
        result = 'شارژ نفری';
        break;

      case 'fix_person':
        result = 'شارژ ثابت + نفری';
        break;

      case 'fix_area':
        result = 'شارژ ثابت + متراژی';
        break;

      case 'person_area':
        result = 'شارژ نفری + متراژی';
        break;

      case 'fix_person_area':
        result = 'شارژ ثابت + نفری + متراژی';
        break;

      case 'fix_variable':
        result = 'شارژ ثابت و متغیر';
        break;

      case 'expense_charge':
        result = 'هزینه‌ها';
        break;

      default:
        result = 'شارژ';
    }

    return toPersianDigits(result);
  }

  // =====================================================
  // تاریخ شمسی
  // =====================================================

  String formatPersianDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(text);

      final jalali = Jalali.fromDateTime(date);

      final result =
          '${jalali.year}/'
          '${jalali.month.toString().padLeft(2, '0')}/'
          '${jalali.day.toString().padLeft(2, '0')}';

      return toPersianDigits(result);
    } catch (e) {
      return toPersianDigits(text);
    }
  }

  // =====================================================
  // دریافت شارژها
  // =====================================================

  Future<void> loadCharges() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
      await _apiService.getCharges();

      if (!mounted) return;

      setState(() {
        charges = result;
        isLoading = false;
      });

      debugPrint(
        'CHARGES COUNT = ${charges.length}',
      );

      for (final charge in charges) {
        debugPrint(
          '========================================',
        );

        debugPrint(
          'CHARGE ID = ${charge['id']}',
        );

        debugPrint(
          'is_paid = ${charge['is_paid']} '
              '| type = ${charge['is_paid'].runtimeType}',
        );

        debugPrint(
          'payment_pending = ${charge['payment_pending']} '
              '| type = ${charge['payment_pending'].runtimeType}',
        );

        debugPrint(
          'FULL CHARGE = $charge',
        );

        debugPrint(
          '========================================',
        );
      }
    } catch (e) {
      debugPrint(
        'LOAD CHARGES ERROR = $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // =====================================================
  // کارت شارژ
  // =====================================================

  Widget buildChargeCard(
      Map<String, dynamic> charge,
      ) {
    final title =
    getChargeTitle(charge);

    // =====================================================
// =====================================================
// وضعیت پرداخت
// =====================================================

    final bool isPaid =
        charge['is_paid'] == true ||
            charge['is_paid']?.toString().toLowerCase() == 'true';

    final bool paymentPending =
        charge['payment_pending'] == true ||
            charge['payment_pending']?.toString().toLowerCase() == 'true';

    final bool isUnpaid =
        !isPaid && !paymentPending;

// =====================================================
// مبلغ‌ها
// =====================================================

    final payableAmount =
        charge['payable_amount'] ?? 0;

    final baseCharge =
        charge['base_charge'] ?? 0;

    final penalty =
        charge['penalty_amount'] ?? 0;

    final paymentDeadline =
    charge['payment_deadline'];

    final paymentDate =
    charge['payment_date'];

// =====================================================
// رنگ و متن وضعیت
// =====================================================

    Color statusColor;
    Color statusBackground;
    IconData statusIcon;
    String statusText;

    if (isPaid) {
      // -----------------------------------------------------
      // پرداخت شده
      // -----------------------------------------------------

      statusColor = Colors.green;

      statusBackground =
          Colors.green.withValues(alpha: 0.10);

      statusIcon =
          Icons.check_circle_outline_rounded;

      statusText = 'پرداخت شده';

    } else if (paymentPending) {
      // -----------------------------------------------------
      // پرداخت انجام شده ولی هنوز مدیر تأیید نکرده
      // -----------------------------------------------------

      statusColor =
          Colors.orange.shade700;

      statusBackground =
          Colors.orange.withValues(alpha: 0.12);

      statusIcon =
          Icons.hourglass_top_rounded;

      statusText = 'در انتظار تأیید';

    } else {
      // -----------------------------------------------------
      // هنوز پرداخت نشده
      // -----------------------------------------------------

      statusColor = Colors.red;

      statusBackground =
          Colors.red.withValues(alpha: 0.10);

      statusIcon =
          Icons.receipt_long_outlined;

      statusText = 'پرداخت نشده';
    }

    // =====================================================
    // کارت
    // =====================================================

    return Card(
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      elevation: 0,
      color: Colors.white,
      shadowColor: Colors.black.withValues(
        alpha: 0.12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: const Color(0xff9c9e9f),
          width: 1,
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            // =================================================
            // عنوان + وضعیت
            // =================================================

            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: statusBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 26,
                  ),
                ),

                const SizedBox(
                  width: 13,
                ),

                Expanded(
                  child: Text(
                    title,
                    style:
                    const TextStyle(
                      fontSize: 17,
                      fontWeight:
                      FontWeight.bold,
                      color:
                      Color(0xff263238),
                    ),
                  ),
                ),

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                  BoxDecoration(
                    color: statusBackground,
                    borderRadius:
                    BorderRadius.circular(9),
                  ),
                  child: Text(
                    statusText,
                    style:
                    TextStyle(
                      fontSize: 10,
                      fontWeight:
                      FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            const Divider(
              height: 1,
            ),

            const SizedBox(
              height: 15,
            ),

            // =================================================
            // مبلغ شارژ
            // =================================================

            _ChargeInfoRow(
              title: 'مبلغ شارژ',
              value:
              '${formatAmount(baseCharge)} تومان',
            ),

            // =================================================
            // جریمه
            // =================================================

            if ((int.tryParse(
              penalty.toString(),
            ) ??
                0) >
                0)
              _ChargeInfoRow(
                title: 'جریمه',
                value:
                '${formatAmount(penalty)} تومان',
                valueColor:
                Colors.orange,
              ),

            const SizedBox(
              height: 5,
            ),

            // =================================================
            // مبلغ قابل پرداخت
            // =================================================

            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration:
              BoxDecoration(
                color:
                const Color(0xff610db5)
                    .withValues(alpha: 0.06),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'مبلغ قابل پرداخت',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Color(0xff263238),
                      ),
                    ),
                  ),

                  Text(
                    '${formatAmount(payableAmount)} تومان',
                    style:
                    const TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.bold,
                      color:
                      Color(0xff610db5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // =================================================
            // در انتظار تأیید
            // =================================================

            if (paymentPending && !isPaid)
              Container(
                width: double.infinity,
                margin:
                const EdgeInsets.only(
                  top: 5,
                  bottom: 5,
                ),
                padding:
                const EdgeInsets.all(12),
                decoration:
                BoxDecoration(
                  color:
                  Colors.orange.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons
                          .hourglass_top_rounded,
                      size: 21,
                      color:
                      Colors.orange.shade700,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    const Expanded(
                      child: Text(
                        'پرداخت شما ثبت شده و در انتظار تأیید مدیر است.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w600,
                          color:
                          Color(0xff8D5A00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // =================================================
            // تاریخ پرداخت / مهلت پرداخت
            // =================================================

            if (isPaid &&
                paymentDate != null)
              _ChargeInfoRow(
                title: 'تاریخ پرداخت',
                value:
                formatPersianDate(
                  paymentDate,
                ),
              )
            else if (isUnpaid &&
                paymentDeadline != null)
              _ChargeInfoRow(
                title: 'مهلت پرداخت',
                value:
                formatPersianDate(
                  paymentDeadline,
                ),
              ),

            // =================================================
            // دکمه پرداخت
            // =================================================

            if (isUnpaid) ...[
              const SizedBox(
                height: 15,
              ),

              SizedBox(
                width: double.infinity,
                height: 48,
                child:
                ElevatedButton.icon(
                  onPressed: () async {
                    final chargeId =
                    int.tryParse(
                      charge['id'].toString(),
                    );

                    if (chargeId == null) {
                      return;
                    }

                    final result =
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PaymentMethodScreen(
                              chargeId: chargeId,
                            ),
                      ),
                    );

                    // -----------------------------------------
                    // بعد از برگشت از صفحه پرداخت
                    // -----------------------------------------

                    if (result == true &&
                        mounted) {
                      await loadCharges();
                    }
                  },
                  icon: const Icon(
                    Icons.payment_rounded,
                    size: 21,
                  ),
                  label: const Text(
                    'پرداخت شارژ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(
                      0xff610db5,
                    ),
                    foregroundColor:
                    Colors.white,
                    elevation: 0,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =====================================================
  // صفحه
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadCharges,
          child: isLoading
              ? const Center(
            child:
            CircularProgressIndicator(
              color:
              Color(0xff00ACC1),
            ),
          )
              : errorMessage != null
              ? buildError()
              : charges.isEmpty
              ? buildEmpty()
              : ListView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding:
            const EdgeInsets.fromLTRB(
              18,
              20,
              18,
              100,
            ),
            children: [
              const Text(
                'شارژها',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                  FontWeight.bold,
                  color:
                  Color(0xff263238),
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                '${toPersianDigits(charges.length.toString())} شارژ ثبت شده',
                style:
                const TextStyle(
                  fontSize: 13,
                  color:
                  Colors.grey,
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              ...charges.map(
                buildChargeCard,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // حالت خالی
  // =====================================================

  Widget buildEmpty() {
    return RefreshIndicator(
      onRefresh: loadCharges,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(
            height: 160,
          ),

          const Icon(
            Icons.receipt_long_outlined,
            size: 65,
            color: Colors.grey,
          ),

          const SizedBox(
            height: 15,
          ),

          const Center(
            child: Text(
              'شارژی برای شما ثبت نشده است',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // خطا
  // =====================================================

  Widget buildError() {
    return RefreshIndicator(
      onRefresh: loadCharges,
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(
            height: 150,
          ),

          const Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: Colors.redAccent,
          ),

          const SizedBox(
            height: 15,
          ),

          const Center(
            child: Text(
              'دریافت اطلاعات شارژها انجام نشد',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Center(
            child: Text(
              errorMessage ?? '',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          Center(
            child:
            ElevatedButton.icon(
              onPressed: loadCharges,
              icon: const Icon(
                Icons.refresh,
              ),
              label: const Text(
                'تلاش مجدد',
              ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xff00ACC1,
                ),
                foregroundColor:
                Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// ردیف اطلاعات شارژ
// =====================================================

class _ChargeInfoRow
    extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _ChargeInfoRow({
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style:
              const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),

          Text(
            value,
            style:
            TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.bold,
              color:
              valueColor ??
                  const Color(
                    0xff263238,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}