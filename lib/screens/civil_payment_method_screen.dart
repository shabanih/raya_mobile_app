import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../services/api_service.dart';
import 'manual_civil_payment_screen.dart';

class CivilPaymentMethodScreen extends StatefulWidget {
  final int installmentId;

  const CivilPaymentMethodScreen({
    super.key,
    required this.installmentId,
  });

  @override
  State<CivilPaymentMethodScreen> createState() =>
      _CivilPaymentMethodScreenState();
}

class _CivilPaymentMethodScreenState
    extends State<CivilPaymentMethodScreen> {
  final ApiService _apiService = ApiService();

  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? data;
  Map<String, dynamic>? installment;

  List<Map<String, dynamic>> paymentMethods = [];

  @override
  void initState() {
    super.initState();
    loadPaymentMethods();
  }

  // ============================================================
  // اعداد فارسی
  // ============================================================

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

  // ============================================================
  // تاریخ شمسی
  // ============================================================

  String formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return '-';
    }

    try {
      final dateTime = DateTime.parse(text);

      final jalali = Jalali.fromDateTime(
        dateTime,
      );

      return toPersianDigits(
        '${jalali.year}/'
            '${jalali.month.toString().padLeft(2, '0')}/'
            '${jalali.day.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      debugPrint(
        'DATE CONVERSION ERROR: $e',
      );

      return toPersianDigits(
        text.length >= 10
            ? text.substring(0, 10)
            : text,
      );
    }
  }

  // ============================================================
  // فرمت مبلغ
  // ============================================================

  String formatAmount(dynamic value) {
    int amount = 0;

    if (value is num) {
      amount = value.toInt();
    } else {
      final text = value
          ?.toString()
          .replaceAll(',', '')
          .replaceAll('٬', '')
          .replaceAll('.0', '') ??
          '0';

      amount = int.tryParse(text) ?? 0;
    }

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

  // ============================================================
  // وضعیت پرداخت
  // ============================================================

  bool get isPaid {
    if (installment == null) {
      return false;
    }

    return installment!['is_paid'] == true ||
        installment!['paid'] == true ||
        installment!['status']?.toString() == 'paid';
  }

  // ============================================================
  // در انتظار تأیید
  // ============================================================

  bool get isPaymentPending {
    if (installment == null) {
      return false;
    }

    if (isPaid) {
      return false;
    }

    return installment!['payment_pending'] == true ||
        installment!['pending'] == true ||
        installment!['status']?.toString() == 'pending' ||
        installment!['status']?.toString() == 'waiting';
  }

  // ============================================================
  // امکان پرداخت
  // ============================================================

  bool get isPaymentAvailable {
    return !isPaid && !isPaymentPending;
  }

  // ============================================================
  // دریافت روش‌های پرداخت
  // ============================================================

  Future<void> loadPaymentMethods() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
      await _apiService.getCivilInstallmentPaymentMethods(
        widget.installmentId,
      );

      if (!mounted) return;

      final resultInstallment =
      result['installment'];

      final resultMethods =
      result['payment_methods'];

      List<Map<String, dynamic>> methods = [];

      if (resultMethods is List) {
        methods = resultMethods
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(
            item,
          ),
        )
            .toList();
      }

      // ==========================================================
      // کارت به کارت
      // ==========================================================

      final hasManual = methods.any(
            (method) =>
        method['type']?.toString() == 'manual',
      );

      if (!hasManual) {
        methods.add({
          'type': 'manual',
          'title': 'کارت به کارت',
          'description':
          'ثبت اطلاعات پرداخت و ارسال درخواست تأیید',
          'available': true,
        });
      }

      // ==========================================================
      // درگاه بانکی
      //
      // این روش همیشه نمایش داده می‌شود.
      // فعال بودن واقعی آن فعلاً اهمیتی ندارد.
      // با کلیک، پیام عدم فعال بودن نمایش داده می‌شود.
      // ==========================================================

      final hasOnline = methods.any(
            (method) =>
        method['type']?.toString() == 'online',
      );

      if (!hasOnline) {
        methods.add({
          'type': 'online',
          'title': 'درگاه بانکی',
          'description':
          'پرداخت مستقیم از طریق درگاه بانکی',
          'available': true,
        });
      }

      setState(() {
        data = result;

        installment = resultInstallment is Map
            ? Map<String, dynamic>.from(
          resultInstallment,
        )
            : null;

        paymentMethods = methods;

        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'CIVIL PAYMENT METHODS ERROR = $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = _cleanError(e);
      });
    }
  }

  // ============================================================
  // پاک کردن متن خطا
  // ============================================================

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(11);
    }

    return text;
  }

  // ============================================================
  // پیام
  // ============================================================

  void showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor:
          isError ? Colors.redAccent : null,
        ),
      );
  }

  // ============================================================
  // انتخاب روش پرداخت
  // ============================================================

  Future<void> selectPaymentMethod(
      Map<String, dynamic> method,
      ) async {
    // ==========================================================
    // قبلاً پرداخت شده
    // ==========================================================

    if (isPaid) {
      showMessage(
        'این قسط قبلاً پرداخت شده است.',
      );
      return;
    }

    // ==========================================================
    // در انتظار تأیید
    // ==========================================================

    if (isPaymentPending) {
      showMessage(
        'درخواست پرداخت شما در انتظار تأیید مدیر ساختمان است.',
      );
      return;
    }

    final type =
    method['type']?.toString();

    // ==========================================================
    // کارت به کارت
    // ==========================================================

    if (type == 'manual') {
      await _openManualPayment();
      return;
    }

    // ==========================================================
    // درگاه بانکی
    // ==========================================================

    if (type == 'online') {
      _openOnlinePayment();
      return;
    }

    showMessage(
      'این روش پرداخت پشتیبانی نمی‌شود.',
      isError: true,
    );
  }

  // ============================================================
  // پرداخت کارت به کارت
  // ============================================================

  Future<void> _openManualPayment() async {
    if (!isPaymentAvailable) {
      if (isPaid) {
        showMessage(
          'این قسط قبلاً پرداخت شده است.',
        );
      } else {
        showMessage(
          'درخواست پرداخت شما در انتظار تأیید مدیر ساختمان است.',
        );
      }

      return;
    }

    final result =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ManualCivilPaymentScreen(
              installmentId:
              widget.installmentId,
            ),
      ),
    );

    if (!mounted) return;

    // ==========================================================
    // ثبت موفق پرداخت
    // ==========================================================

    if (result == true) {
      Navigator.pop(
        context,
        true,
      );
    }
  }

  // ============================================================
  // درگاه بانکی
  // ============================================================

  void _openOnlinePayment() {
    if (!isPaymentAvailable) {
      if (isPaid) {
        showMessage(
          'این قسط قبلاً پرداخت شده است.',
        );
      } else {
        showMessage(
          'درخواست پرداخت شما در انتظار تأیید مدیر ساختمان است.',
        );
      }

      return;
    }

    // ==========================================================
    // فعلاً درگاه بانکی فعال نیست
    // ==========================================================

    showMessage(
      'درگاه بانکی برای ساختمان شما فعال نشده است.',
    );
  }

  // ============================================================
  // کارت وضعیت پرداخت
  // ============================================================

  Widget buildPaymentStatusCard() {
    // ==========================================================
    // پرداخت شده
    // ==========================================================

    if (isPaid) {
      return Container(
        margin: const EdgeInsets.only(
          bottom: 22,
        ),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:
          Colors.green.withOpacity(0.08),
          borderRadius:
          BorderRadius.circular(18),
          border: Border.all(
            color:
            Colors.green.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                Colors.green.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 28,
              ),
            ),

            const SizedBox(width: 14),

            const Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'پرداخت شده',
                    textAlign:
                    TextAlign.right,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'این قسط با موفقیت پرداخت شده است.',
                    textAlign:
                    TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                      Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // در انتظار تأیید
    // ==========================================================

    if (isPaymentPending) {
      return Container(
        margin: const EdgeInsets.only(
          bottom: 22,
        ),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color:
          Colors.orange.withOpacity(0.08),
          borderRadius:
          BorderRadius.circular(18),
          border: Border.all(
            color:
            Colors.orange.withOpacity(0.30),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                Colors.orange.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                color: Colors.orange,
                size: 28,
              ),
            ),

            const SizedBox(width: 14),

            const Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    'در انتظار تأیید',
                    textAlign:
                    TextAlign.right,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'درخواست پرداخت شما ثبت شده و منتظر تأیید مدیر ساختمان است.',
                    textAlign:
                    TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                      Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // ============================================================
  // کارت روش پرداخت
  // ============================================================

  Widget buildPaymentMethodCard(
      Map<String, dynamic> method,
      ) {
    final type =
    method['type']?.toString();

    final title =
        method['title']?.toString() ??
            'روش پرداخت';

    final description =
        method['description']?.toString() ??
            '';

    final isManual =
        type == 'manual';

    final isOnline =
        type == 'online';

    final icon = isManual
        ? Icons.credit_card_rounded
        : isOnline
        ? Icons.account_balance_rounded
        : Icons.payment_rounded;

    final color = isManual
        ? const Color(0xff610DB5)
        : isOnline
        ? const Color(0xff00ACC1)
        : Colors.grey;

    // ==========================================================
    // درگاه بانکی همیشه فعال ظاهری است تا قابل کلیک باشد.
    // اما داخل _openOnlinePayment پیام عدم فعال بودن نمایش داده
    // می‌شود.
    // ==========================================================

    final canPay = isOnline
        ? isPaymentAvailable
        : (method['available'] == true &&
        isPaymentAvailable);

    return Opacity(
      opacity: canPay ? 1.0 : 0.45,
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 15,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset:
              const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius:
            BorderRadius.circular(20),
            onTap: () {
              selectPaymentMethod(
                method,
              );
            },
            child: Padding(
              padding:
              const EdgeInsets.all(18),
              child: Row(
                children: [
                  // =================================================
                  // آیکون
                  // =================================================

                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color:
                      color.withOpacity(0.10),
                      shape:
                      BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 15),

                  // =================================================
                  // متن
                  // =================================================

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          textAlign:
                          TextAlign.right,
                          style:
                          const TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.bold,
                            color:
                            Color(0xff263238),
                          ),
                        ),

                        if (description
                            .isNotEmpty) ...[
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            description,
                            textAlign:
                            TextAlign.right,
                            style:
                            const TextStyle(
                              fontSize: 12,
                              color:
                              Colors.grey,
                              height: 1.5,
                            ),
                          ),
                        ],

                        if (isOnline) ...[
                          const SizedBox(
                            height: 5,
                          ),
                          const Text(
                            'فعلاً فعال نشده است',
                            style:
                            TextStyle(
                              fontSize: 11,
                              color:
                              Color(0xff00ACC1),
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],

                        if (isPaymentPending) ...[
                          const SizedBox(
                            height: 5,
                          ),
                          const Text(
                            'در انتظار تأیید مدیر',
                            style:
                            TextStyle(
                              fontSize: 11,
                              color:
                              Colors.orange,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],

                        if (isPaid) ...[
                          const SizedBox(
                            height: 5,
                          ),
                          const Text(
                            'پرداخت شده',
                            style:
                            TextStyle(
                              fontSize: 11,
                              color:
                              Colors.green,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  Icon(
                    Icons
                        .arrow_back_ios_new_rounded,
                    size: 17,
                    color: canPay
                        ? color
                        : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // کارت اطلاعات قسط
  // ============================================================

  Widget buildInstallmentCard() {
    if (installment == null) {
      return const SizedBox.shrink();
    }

    final amount =
        installment!['amount'] ?? 0;

    final description =
        installment!['description']
            ?.toString() ??
            '';

    final registerDate =
    formatDate(
      installment!['register_date'],
    );

    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 22,
      ),
      padding:
      const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
        const LinearGradient(
          begin:
          Alignment.centerRight,
          end:
          Alignment.centerLeft,
          colors: [
            Color(0xff00ACC1),
            Color(0xff00ACC1),
          ],
        ),
        borderRadius:
        BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
            const Color(0xff00ACC1)
                .withOpacity(0.20),
            blurRadius: 14,
            offset:
            const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          const Text(
            'مبلغ قسط',
            textAlign:
            TextAlign.right,
            style: TextStyle(
              color:
              Colors.white70,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.end,
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                formatAmount(amount),
                style:
                const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(width: 7),

              const Padding(
                padding:
                EdgeInsets.only(
                  bottom: 3,
                ),
                child: Text(
                  'تومان',
                  style:
                  TextStyle(
                    color:
                    Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          if (registerDate != '-') ...[
            const SizedBox(height: 14),
            Text(
              'تاریخ ثبت: $registerDate',
              textAlign:
              TextAlign.right,
              style:
              const TextStyle(
                color:
                Colors.white70,
                fontSize: 12,
              ),
            ),
          ],

          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              textAlign:
              TextAlign.justify,
              textDirection:
              TextDirection.rtl,
              style:
              const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // محتوا
  // ============================================================

  Widget buildContent() {
    return RefreshIndicator(
      onRefresh:
      loadPaymentMethods,
      color:
      const Color(0xff00ACC1),
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(18),
        children: [
          buildInstallmentCard(),

          buildPaymentStatusCard(),

          if (isPaymentAvailable) ...[
            const Text(
              'روش پرداخت را انتخاب کنید',
              textAlign:
              TextAlign.right,
              style:
              TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.bold,
                color:
                Color(0xff263238),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'روش مورد نظر خود را برای پرداخت قسط انتخاب کنید.',
              textAlign:
              TextAlign.right,
              style:
              TextStyle(
                fontSize: 12,
                color:
                Colors.grey,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 18),

            if (paymentMethods.isEmpty)
              Container(
                padding:
                const EdgeInsets.all(20),
                decoration:
                BoxDecoration(
                  color:
                  Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
                ),
                child:
                const Column(
                  children: [
                    Icon(
                      Icons
                          .payment_outlined,
                      size: 50,
                      color:
                      Colors.grey,
                    ),
                    SizedBox(
                        height: 12),
                    Text(
                      'روش پرداختی برای این قسط ثبت نشده است.',
                      textAlign:
                      TextAlign.center,
                      style:
                      TextStyle(
                        color:
                        Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...paymentMethods.map(
                buildPaymentMethodCard,
              ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // خطا
  // ============================================================

  Widget buildError() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color:
              Colors.redAccent,
            ),

            const SizedBox(height: 15),

            const Text(
              'دریافت روش‌های پرداخت انجام نشد',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              errorMessage ?? '',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                fontSize: 12,
                color:
                Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed:
              loadPaymentMethods,
              icon:
              const Icon(
                Icons.refresh,
              ),
              label:
              const Text(
                'تلاش مجدد',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        const Color(0xffF7F9FA),
        appBar: AppBar(
          backgroundColor:
          Colors.white,
          elevation: 0,
          centerTitle: true,
          title:
          const Text(
            'روش پرداخت قسط',
            style:
            TextStyle(
              color:
              Color(0xff263238),
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          iconTheme:
          const IconThemeData(
            color:
            Color(0xff263238),
          ),
        ),
        body: isLoading
            ? const Center(
          child:
          CircularProgressIndicator(
            color:
            Color(0xff00ACC1),
          ),
        )
            : errorMessage != null
            ? buildError()
            : buildContent(),
      ),
    );
  }
}