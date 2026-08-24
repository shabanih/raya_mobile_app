import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'manual_payment_screen.dart';

class PaymentMethodScreen extends StatefulWidget {
  final int chargeId;

  const PaymentMethodScreen({
    super.key,
    required this.chargeId,
  });

  @override
  State<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState
    extends State<PaymentMethodScreen> {
  final ApiService _apiService = ApiService();

  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? charge;

  List<Map<String, dynamic>> paymentMethods = [];

  // ============================================================
  // شروع صفحه
  // ============================================================

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
  // فرمت مبلغ
  // ============================================================

  String formatAmount(dynamic value) {
    final amount =
        int.tryParse(
          value?.toString() ?? '0',
        ) ??
            0;

    final text = amount.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 &&
          (text.length - i) % 3 == 0) {
        buffer.write('٬');
      }

      buffer.write(text[i]);
    }

    return toPersianDigits(
      buffer.toString(),
    );
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
  // وضعیت پرداخت
  // ============================================================

  bool get isPaid {
    return charge?['is_paid'] == true;
  }

  bool get isPaymentPending {
    return charge?['payment_pending'] == true &&
        charge?['is_paid'] != true;
  }

  bool get isPaymentAvailable {
    return !isPaid && !isPaymentPending;
  }

  // ============================================================
  // دریافت اطلاعات شارژ و روش‌های پرداخت
  // ============================================================

  Future<void> loadPaymentMethods() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
      await _apiService.getChargePaymentMethods(
        widget.chargeId,
      );

      if (!mounted) return;

      final methods = result['payment_methods'];
      final chargeData = result['charge'];

      setState(() {
        charge =
        chargeData is Map
            ? Map<String, dynamic>.from(
          chargeData,
        )
            : null;

        paymentMethods =
        methods is List
            ? methods
            .whereType<Map>()
            .map(
              (item) =>
          Map<String, dynamic>.from(
            item,
          ),
        )
            .toList()
            : [];

        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'LOAD PAYMENT METHODS ERROR = $e',
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
  // انتخاب روش پرداخت
  // ============================================================

  Future<void> selectPaymentMethod(
      Map<String, dynamic> method,
      ) async {
    if (isPaid) {
      showMessage(
        'این شارژ قبلاً پرداخت شده است.',
      );
      return;
    }

    if (isPaymentPending) {
      showMessage(
        'درخواست پرداخت شما در انتظار تأیید مدیر ساختمان است.',
      );
      return;
    }

    final type =
    method['type']?.toString();

    final available =
        method['available'] == true;

    if (!available) {
      showMessage(
        'این روش پرداخت در حال حاضر فعال نیست.',
        isError: true,
      );
      return;
    }

    // ==========================================================
    // کارت به کارت
    // ==========================================================

    if (type == 'manual') {
      await _openManualPayment();
      return;
    }

    // ==========================================================
    // پرداخت آنلاین
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
  // ورود به صفحه پرداخت کارت به کارت
  // ============================================================

  Future<void> _openManualPayment() async {
    if (!isPaymentAvailable) {
      if (isPaid) {
        showMessage(
          'این شارژ قبلاً پرداخت شده است.',
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
            ManualChargePaymentScreen(
              chargeId: widget.chargeId,
              charge: charge,
            ),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      Navigator.pop(
        context,
        true,
      );
    }
  }

  // ============================================================
  // پرداخت آنلاین
  // ============================================================

  void _openOnlinePayment() {
    if (!isPaymentAvailable) {
      if (isPaid) {
        showMessage(
          'این شارژ قبلاً پرداخت شده است.',
        );
      } else {
        showMessage(
          'درخواست پرداخت شما در انتظار تأیید مدیر ساختمان است.',
        );
      }

      return;
    }

    showMessage(
      'پرداخت آنلاین در مرحله بعد فعال می‌شود.',
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    'این شارژ با موفقیت پرداخت شده است.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
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

    final available =
        method['available'] == true;

    final isManual =
        type == 'manual';

    final isOnline =
        type == 'online';

    final icon =
    isManual
        ? Icons.credit_card_rounded
        : isOnline
        ? Icons.language_rounded
        : Icons.payment_rounded;

    final color =
    isManual
        ? const Color(0xff610DB5)
        : isOnline
        ? const Color(0xff00ACC1)
        : Colors.grey;

    final canPay =
        available &&
            isPaymentAvailable;

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
                  Container(
                    width: 54,
                    height: 54,
                    decoration:
                    BoxDecoration(
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

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                          const TextStyle(
                            fontSize: 16,
                            fontWeight:
                            FontWeight.bold,
                            color:
                            Color(0xff263238),
                          ),
                        ),

                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 6),

                          Text(
                            description,
                            style:
                            const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              height: 1.5,
                            ),
                          ),
                        ],

                        if (!available) ...[
                          const SizedBox(height: 5),

                          const Text(
                            'در دسترس نیست',
                            style:
                            TextStyle(
                              fontSize: 11,
                              color: Colors.red,
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
                    color:
                    canPay
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
  // محتوای صفحه
  // ============================================================

  Widget buildContent() {
    final title =
        charge?['title']?.toString() ??
            'شارژ';

    final amount =
        charge?['amount'] ?? 0;

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
          // ======================================================
          // کارت شارژ
          // ======================================================

          Container(
            padding:
            const EdgeInsets.all(20),
            decoration:
            BoxDecoration(
              gradient:
              const LinearGradient(
                colors: [
                  Color(0xff00ACC1),
                  Color(0xff008FA0),
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
              CrossAxisAlignment.start,
              children: [
                Text(
                  toPersianDigits(title),
                  style:
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatAmount(
                        amount,
                      ),
                      style:
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 6),

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
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ======================================================
          // وضعیت
          // ======================================================

          buildPaymentStatusCard(),

          // ======================================================
          // روش پرداخت
          // ======================================================

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
              'روش مورد نظر خود را برای پرداخت شارژ انتخاب کنید.',
              textAlign:
              TextAlign.right,
              style:
              TextStyle(
                fontSize: 12,
                color: Colors.grey,
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
                      Icons.payment_outlined,
                      size: 50,
                      color: Colors.grey,
                    ),

                    SizedBox(height: 12),

                    Text(
                      'روش پرداختی برای این شارژ ثبت نشده است.',
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
              color: Colors.redAccent,
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
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed:
              loadPaymentMethods,
              icon:
              const Icon(Icons.refresh),
              label:
              const Text('تلاش مجدد'),
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
          title: const Text(
            'روش پرداخت',
            style: TextStyle(
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