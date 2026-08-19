import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../services/api_service.dart';

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

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  final ApiService _apiService = ApiService();

  bool isLoading = true;
  String? errorMessage;

  Map<String, dynamic>? charge;
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
  // فرمت مبلغ
  // ============================================================

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

  // ============================================================
  // نمایش پیام
  // ============================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textDirection: TextDirection.rtl,
          ),
          behavior: SnackBarBehavior.floating,
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
      await _apiService.getChargePaymentMethods(
        widget.chargeId,
      );

      if (!mounted) return;

      final methods = result['payment_methods'];
      final chargeData = result['charge'];

      setState(() {
        charge = chargeData is Map<String, dynamic>
            ? chargeData
            : null;

        paymentMethods = methods is List
            ? methods
            .whereType<Map<String, dynamic>>()
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
        errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // انتخاب روش پرداخت
  // ============================================================

  void selectPaymentMethod(
      Map<String, dynamic> method,
      ) {
    // پرداخت شده
    if (isPaid) {
      showMessage(
        'این شارژ قبلاً پرداخت شده است.',
      );
      return;
    }

    // در انتظار تأیید
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
      );
      return;
    }

    if (type == 'manual') {
      _openManualPayment();
      return;
    }

    if (type == 'online') {
      _openOnlinePayment();
      return;
    }
  }

  // ============================================================
  // پرداخت دستی
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

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ManualChargePaymentScreen(
          chargeId: widget.chargeId,
          charge: charge,
        ),
      ),
    );

    if (!mounted) return;

    // پرداخت با موفقیت ثبت شد
    if (result == true) {
      // به جای ماندن در صفحه روش پرداخت،
      // نتیجه را به صفحه لیست شارژها برمی‌گردانیم.
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
    if (isPaid) {
      return Container(
        margin: const EdgeInsets.only(
          bottom: 22,
        ),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.green.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
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
                      fontWeight: FontWeight.bold,
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

    if (isPaymentPending) {
      return Container(
        margin: const EdgeInsets.only(
          bottom: 22,
        ),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.orange.withOpacity(0.30),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
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
                      fontWeight: FontWeight.bold,
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

    final icon = isManual
        ? Icons.credit_card_rounded
        : Icons.language_rounded;

    final color = isManual
        ? const Color(0xff610db5)
        : const Color(0xff00ACC1);

    // وقتی شارژ پرداخت شده یا در انتظار تأیید است
    // روش پرداخت باید غیرفعال باشد.
    final canPay =
        available && isPaymentAvailable;

    return Opacity(
      opacity: canPay ? 1 : 0.45,
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
            onTap: canPay
                ? () {
              selectPaymentMethod(
                method,
              );
            }
                : () {
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
                      color:
                      color,
                      size: 28,
                    ),
                  ),

                  const SizedBox(
                    width: 15,
                  ),

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

                        const SizedBox(
                          height: 6,
                        ),

                        Text(
                          description,
                          style:
                          const TextStyle(
                            fontSize: 12,
                            color:
                            Colors.grey,
                            height: 1.5,
                          ),
                        ),

                        if (!available) ...[
                          const SizedBox(
                            height: 5,
                          ),
                          const Text(
                            'در دسترس نیست',
                            style:
                            TextStyle(
                              fontSize: 11,
                              color:
                              Colors.red,
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

                  const SizedBox(
                    width: 10,
                  ),

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
  // صفحه اصلی
  // ============================================================

  @override
  Widget build(BuildContext context) {
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

  // ============================================================
  // محتوا
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

      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),

        padding:
        const EdgeInsets.all(18),

        children: [
          // ======================================================
          // مبلغ
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
                    color:
                    Colors.white,
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.end,

                  children: [
                    Text(
                      formatAmount(amount),

                      style:
                      const TextStyle(
                        color:
                        Colors.white,
                        fontSize: 25,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      width: 6,
                    ),

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

          const SizedBox(
            height: 20,
          ),

          // ======================================================
          // وضعیت پرداخت
          // ======================================================

          buildPaymentStatusCard(),

          // ======================================================
          // اگر پرداخت نشده است
          // ======================================================

          if (isPaymentAvailable) ...[
            const Text(
              'روش پرداخت را انتخاب کنید',

              style:
              TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.bold,
                color:
                Color(0xff263238),
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            const Text(
              'روش مورد نظر خود را برای پرداخت شارژ انتخاب کنید.',

              style:
              TextStyle(
                fontSize: 12,
                color:
                Colors.grey,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

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

            const SizedBox(
              height: 15,
            ),

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

            const SizedBox(
              height: 10,
            ),

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

            const SizedBox(
              height: 20,
            ),

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
}

// ===================================================================
// صفحه ثبت پرداخت کارت به کارت
// ===================================================================

class ManualChargePaymentScreen
    extends StatefulWidget {
  final int chargeId;
  final Map<String, dynamic>? charge;

  const ManualChargePaymentScreen({
    super.key,
    required this.chargeId,
    this.charge,
  });

  @override
  State<ManualChargePaymentScreen>
  createState() =>
      _ManualChargePaymentScreenState();
}

class _ManualChargePaymentScreenState
    extends State<ManualChargePaymentScreen> {

  final ApiService _apiService =
  ApiService();

  final TextEditingController
  transactionController =
  TextEditingController();

  bool isLoading = true;
  bool isSubmitting = false;

  String? errorMessage;

  List<Map<String, dynamic>> banks = [];

  int? selectedBankId;

  DateTime paymentDate =
  DateTime.now();

  Jalali selectedPaymentDate =
  Jalali.now();

  @override
  void initState() {
    super.initState();
    loadBanks();
  }

  @override
  void dispose() {
    transactionController.dispose();
    super.dispose();
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

    final text =
    amount.toString();

    final buffer =
    StringBuffer();

    for (
    int i = 0;
    i < text.length;
    i++
    ) {
      if (
      i > 0 &&
          (text.length - i) % 3 == 0
      ) {
        buffer.write('٬');
      }

      buffer.write(text[i]);
    }

    return toPersianDigits(
      buffer.toString(),
    );
  }

  // ============================================================
  // نمایش تاریخ
  // ============================================================

  String formatJalaliDate(
      Jalali date,
      ) {
    return toPersianDigits(
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}',
    );
  }

  // ============================================================
  // دریافت بانک‌ها
  // ============================================================

  Future<void> loadBanks() async {
    try {
      final result =
      await _apiService
          .getPaymentBanks(
        widget.chargeId,
      );

      if (!mounted) return;

      setState(() {
        banks = result;
        isLoading = false;

        if (banks.length == 1) {
          selectedBankId =
              int.tryParse(
                banks.first['id'].toString(),
              );
        }
      });
    } catch (e) {
      debugPrint(
        'LOAD BANKS ERROR = $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            e.toString();
      });
    }
  }

  // ============================================================
  // انتخاب تاریخ
  // ============================================================

  Future<void> selectPaymentDate() async {
    Jalali selectedDate =
        selectedPaymentDate;

    final result =
    await showDialog<Jalali>(
      context: context,

      builder: (context) {
        int selectedYear =
            selectedDate.year;

        int selectedMonth =
            selectedDate.month;

        int selectedDay =
            selectedDate.day;

        return StatefulBuilder(
          builder:
              (
              context,
              setDialogState,
              ) {
            final daysInMonth =
                Jalali(
                  selectedYear,
                  selectedMonth,
                  1,
                ).monthLength;

            if (selectedDay >
                daysInMonth) {
              selectedDay =
                  daysInMonth;
            }

            return AlertDialog(
              title: const Text(
                'انتخاب تاریخ پرداخت',
                textAlign:
                TextAlign.center,
                style:
                TextStyle(
                  fontSize: 17,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              content:
              SizedBox(
                width:
                double.maxFinite,

                child:
                Column(
                  mainAxisSize:
                  MainAxisSize.min,

                  children: [
                    DropdownButtonFormField<int>(
                      value:
                      selectedYear,

                      decoration:
                      InputDecoration(
                        labelText:
                        'سال',
                        filled:
                        true,
                        fillColor:
                        const Color(
                          0xffF7F9FA,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                          borderSide:
                          BorderSide.none,
                        ),
                      ),

                      items:
                      List.generate(
                        11,
                            (index) {
                          final year =
                              Jalali.now()
                                  .year -
                                  5 +
                                  index;

                          return DropdownMenuItem<int>(
                            value:
                            year,
                            child:
                            Text(
                              toPersianDigits(
                                year.toString(),
                              ),
                            ),
                          );
                        },
                      ),

                      onChanged:
                          (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        setDialogState(() {
                          selectedYear =
                              value;

                          final maxDay =
                              Jalali(
                                selectedYear,
                                selectedMonth,
                                1,
                              ).monthLength;

                          if (selectedDay >
                              maxDay) {
                            selectedDay =
                                maxDay;
                          }
                        });
                      },
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    DropdownButtonFormField<int>(
                      value:
                      selectedMonth,

                      decoration:
                      InputDecoration(
                        labelText:
                        'ماه',
                        filled:
                        true,
                        fillColor:
                        const Color(
                          0xffF7F9FA,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                          borderSide:
                          BorderSide.none,
                        ),
                      ),

                      items: const [
                        DropdownMenuItem(
                          value: 1,
                          child:
                          Text('۱ - فروردین'),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child:
                          Text('۲ - اردیبهشت'),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child:
                          Text('۳ - خرداد'),
                        ),
                        DropdownMenuItem(
                          value: 4,
                          child:
                          Text('۴ - تیر'),
                        ),
                        DropdownMenuItem(
                          value: 5,
                          child:
                          Text('۵ - مرداد'),
                        ),
                        DropdownMenuItem(
                          value: 6,
                          child:
                          Text('۶ - شهریور'),
                        ),
                        DropdownMenuItem(
                          value: 7,
                          child:
                          Text('۷ - مهر'),
                        ),
                        DropdownMenuItem(
                          value: 8,
                          child:
                          Text('۸ - آبان'),
                        ),
                        DropdownMenuItem(
                          value: 9,
                          child:
                          Text('۹ - آذر'),
                        ),
                        DropdownMenuItem(
                          value: 10,
                          child:
                          Text('۱۰ - دی'),
                        ),
                        DropdownMenuItem(
                          value: 11,
                          child:
                          Text('۱۱ - بهمن'),
                        ),
                        DropdownMenuItem(
                          value: 12,
                          child:
                          Text('۱۲ - اسفند'),
                        ),
                      ],

                      onChanged:
                          (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        setDialogState(() {
                          selectedMonth =
                              value;

                          final maxDay =
                              Jalali(
                                selectedYear,
                                selectedMonth,
                                1,
                              ).monthLength;

                          if (selectedDay >
                              maxDay) {
                            selectedDay =
                                maxDay;
                          }
                        });
                      },
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    DropdownButtonFormField<int>(
                      value:
                      selectedDay,

                      decoration:
                      InputDecoration(
                        labelText:
                        'روز',
                        filled:
                        true,
                        fillColor:
                        const Color(
                          0xffF7F9FA,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                          borderSide:
                          BorderSide.none,
                        ),
                      ),

                      items:
                      List.generate(
                        daysInMonth,
                            (index) {
                          final day =
                              index + 1;

                          return DropdownMenuItem<int>(
                            value:
                            day,
                            child:
                            Text(
                              toPersianDigits(
                                day.toString(),
                              ),
                            ),
                          );
                        },
                      ),

                      onChanged:
                          (value) {
                        if (value ==
                            null) {
                          return;
                        }

                        setDialogState(() {
                          selectedDay =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    Text(
                      'تاریخ انتخاب شده: '
                          '${toPersianDigits(selectedYear.toString())}/'
                          '${toPersianDigits(selectedMonth.toString().padLeft(2, '0'))}/'
                          '${toPersianDigits(selectedDay.toString().padLeft(2, '0'))}',

                      style:
                      const TextStyle(
                        fontSize: 13,
                        color:
                        Color(0xff610db5),
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  child:
                  const Text(
                    'انصراف',
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,

                      Jalali(
                        selectedYear,
                        selectedMonth,
                        selectedDay,
                      ),
                    );
                  },

                  style:
                  ElevatedButton
                      .styleFrom(
                    backgroundColor:
                    const Color(
                      0xff610db5,
                    ),
                    foregroundColor:
                    Colors.white,
                  ),

                  child:
                  const Text(
                    'تأیید',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (
    result != null &&
        mounted
    ) {
      setState(() {
        selectedPaymentDate =
            result;

        paymentDate =
            result.toDateTime();
      });
    }
  }

  // ============================================================
  // تبدیل اعداد فارسی کد پیگیری
  // ============================================================

  void normalizeTransactionReference(
      String value,
      ) {
    final english =
    value
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9');

    if (english != value) {
      transactionController.value =
          transactionController.value
              .copyWith(
            text: english,
            selection:
            TextSelection.collapsed(
              offset:
              english.length,
            ),
          );
    }
  }

  // ============================================================
  // پیام
  // ============================================================

  void showMessage(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
          Text(message),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // ثبت پرداخت
  // ============================================================

  Future<void> submitPayment() async {
    if (selectedBankId == null) {
      showMessage(
        'لطفاً حساب مقصد را انتخاب کنید.',
      );
      return;
    }

    final transactionReference =
    transactionController.text.trim();

    if (transactionReference.isEmpty) {
      showMessage(
        'لطفاً کد پیگیری را وارد کنید.',
      );
      return;
    }

    if (isSubmitting) {
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await _apiService
          .submitManualChargePayment(
        chargeId:
        widget.chargeId,

        bankId:
        selectedBankId!,

        transactionReference:
        transactionReference,

        paymentDate:
        paymentDate
            .toIso8601String()
            .substring(
          0,
          10,
        ),
      );

      if (!mounted) return;

      // ========================================================
      // مهم:
      // اینجا پرداخت «پرداخت شده» نیست.
      // فقط درخواست پرداخت ثبت شده است.
      // ========================================================

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'درخواست پرداخت با موفقیت ثبت شد و در انتظار تأیید مدیر ساختمان است.',
              textDirection:
              TextDirection.rtl,
            ),
            backgroundColor:
            Colors.orange,
            behavior:
            SnackBarBehavior.floating,
          ),
        );

      // true به صفحه قبل برمی‌گردانیم
      // تا دوباره اطلاعات شارژ از API دریافت شود.
      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  // ============================================================
  // کارت بانک
  // ============================================================

  Widget buildBankCard(
      Map<String, dynamic> bank,
      ) {
    final id =
    int.tryParse(
      bank['id'].toString(),
    );

    final selected =
        selectedBankId == id;

    final cardNumber =
        bank['cart_number']
            ?.toString()
            .trim() ??
            '';

    final holder =
        bank['account_holder_name']
            ?.toString()
            .trim() ??
            '';

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBankId =
              id;
        });
      },

      child: Container(
        margin:
        const EdgeInsets.only(
          bottom: 12,
        ),

        padding:
        const EdgeInsets.all(
          18,
        ),

        decoration:
        BoxDecoration(
          color:
          Colors.white,

          borderRadius:
          BorderRadius.circular(
            18,
          ),

          border:
          Border.all(
            color: selected
                ? const Color(
              0xff610db5,
            )
                : Colors.grey
                .withOpacity(
              0.15,
            ),

            width:
            selected ? 2 : 1,
          ),

          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withOpacity(
                0.04,
              ),
              blurRadius: 8,
              offset:
              const Offset(
                0,
                3,
              ),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,

              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xff610db5,
                ).withOpacity(0.08),

                shape:
                BoxShape.circle,
              ),

              child: Icon(
                selected
                    ? Icons
                    .radio_button_checked
                    : Icons
                    .radio_button_off,

                color: selected
                    ? const Color(
                  0xff610db5,
                )
                    : Colors.grey,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [
                  const Text(
                    'شماره کارت',

                    style:
                    TextStyle(
                      fontSize: 11,
                      color:
                      Colors.grey,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    toPersianDigits(
                      cardNumber,
                    ),

                    style:
                    const TextStyle(
                      fontSize: 17,
                      fontWeight:
                      FontWeight.bold,
                      letterSpacing:
                      1.0,
                      color:
                      Color(0xff263238),
                    ),
                  ),

                  if (holder
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 8,
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .person_outline_rounded,
                          size: 17,
                          color:
                          Color(
                            0xff610db5,
                          ),
                        ),

                        const SizedBox(
                          width: 5,
                        ),

                        Expanded(
                          child:
                          Text(
                            holder,

                            style:
                            const TextStyle(
                              fontSize: 13,
                              fontWeight:
                              FontWeight.w600,
                              color:
                              Color(
                                0xff455A64,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // صفحه
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final amount =
        widget.charge?['amount'] ??
            0;

    return Directionality(
      textDirection:
      TextDirection.rtl,

      child: Scaffold(
        backgroundColor:
        const Color(0xffF7F9FA),

        appBar:
        AppBar(
          backgroundColor:
          Colors.white,
          elevation: 0,
          centerTitle: true,

          title:
          const Text(
            'پرداخت کارت به کارت',

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

        body:
        isLoading
            ? const Center(
          child:
          CircularProgressIndicator(
            color:
            Color(0xff610db5),
          ),
        )
            : errorMessage != null
            ? Center(
          child:
          Padding(
            padding:
            const EdgeInsets.all(
              25,
            ),
            child:
            Text(
              errorMessage!,
              textAlign:
              TextAlign.center,
            ),
          ),
        )
            : ListView(
          padding:
          const EdgeInsets.all(
            18,
          ),

          children: [
            // ==================================================
            // مبلغ
            // ==================================================

            Container(
              padding:
              const EdgeInsets.all(
                20,
              ),

              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xff610db5,
                ),

                borderRadius:
                BorderRadius.circular(
                  20,
                ),

                boxShadow: [
                  BoxShadow(
                    color:
                    const Color(
                      0xff610db5,
                    ).withOpacity(
                      0.20,
                    ),
                    blurRadius:
                    14,
                    offset:
                    const Offset(
                      0,
                      6,
                    ),
                  ),
                ],
              ),

              child:
              Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [
                  const Text(
                    'مبلغ قابل پرداخت',

                    style:
                    TextStyle(
                      color:
                      Colors.white70,
                      fontSize:
                      13,
                    ),
                  ),

                  const SizedBox(
                    height:
                    8,
                  ),

                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .end,

                    children: [
                      Text(
                        formatAmount(
                          amount,
                        ),

                        style:
                        const TextStyle(
                          color:
                          Colors.white,
                          fontSize:
                          25,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        width:
                        7,
                      ),

                      const Padding(
                        padding:
                        EdgeInsets.only(
                          bottom:
                          3,
                        ),

                        child:
                        Text(
                          'تومان',

                          style:
                          TextStyle(
                            color:
                            Colors.white,
                            fontSize:
                            13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(
              height:
              25,
            ),

            // ==================================================
            // حساب مقصد
            // ==================================================

            const Text(
              'حساب مقصد',

              style:
              TextStyle(
                fontSize:
                17,
                fontWeight:
                FontWeight.bold,
                color:
                Color(
                  0xff263238,
                ),
              ),
            ),

            const SizedBox(
              height:
              6,
            ),

            const Text(
              'مبلغ را به کارت زیر واریز کرده و سپس اطلاعات پرداخت را ثبت کنید.',

              style:
              TextStyle(
                fontSize:
                12,
                color:
                Colors.grey,
                height:
                1.6,
              ),
            ),

            const SizedBox(
              height:
              14,
            ),

            if (banks.isEmpty)
              Container(
                padding:
                const EdgeInsets.all(
                  15,
                ),

                decoration:
                BoxDecoration(
                  color:
                  Colors.red
                      .withOpacity(
                    0.06,
                  ),

                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),

                child:
                const Text(
                  'حساب بانکی فعالی برای پرداخت ثبت نشده است.',

                  style:
                  TextStyle(
                    color:
                    Colors.red,
                  ),
                ),
              )
            else
              ...banks.map(
                buildBankCard,
              ),

            const SizedBox(
              height:
              12,
            ),

            // ==================================================
            // کد پیگیری
            // ==================================================

            const Text(
              'کد پیگیری',

              style:
              TextStyle(
                fontSize:
                15,
                fontWeight:
                FontWeight.bold,
                color:
                Color(
                  0xff263238,
                ),
              ),
            ),

            const SizedBox(
              height:
              8,
            ),

            TextField(
              controller:
              transactionController,

              keyboardType:
              TextInputType.number,

              textDirection:
              TextDirection.rtl,

              onChanged:
              normalizeTransactionReference,

              decoration:
              InputDecoration(
                hintText:
                'کد پیگیری واریز را وارد کنید',

                prefixIcon:
                const Icon(
                  Icons
                      .receipt_long_outlined,
                  color:
                  Color(
                    0xff610db5,
                  ),
                ),

                filled:
                true,

                fillColor:
                Colors.white,

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                  borderSide:
                  BorderSide.none,
                ),
              ),
            ),

            const SizedBox(
              height:
              18,
            ),

            // ==================================================
            // تاریخ پرداخت
            // ==================================================

            const Text(
              'تاریخ پرداخت',

              style:
              TextStyle(
                fontSize:
                15,
                fontWeight:
                FontWeight.bold,
                color:
                Color(
                  0xff263238,
                ),
              ),
            ),

            const SizedBox(
              height:
              8,
            ),

            InkWell(
              onTap:
              selectPaymentDate,

              borderRadius:
              BorderRadius.circular(
                14,
              ),

              child:
              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal:
                  15,
                  vertical:
                  16,
                ),

                decoration:
                BoxDecoration(
                  color:
                  Colors.white,

                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),

                child:
                Row(
                  children: [
                    const Icon(
                      Icons
                          .calendar_month_rounded,
                      color:
                      Color(
                        0xff610db5,
                      ),
                    ),

                    const SizedBox(
                      width:
                      10,
                    ),

                    Text(
                      formatJalaliDate(
                        selectedPaymentDate,
                      ),

                      style:
                      const TextStyle(
                        fontSize:
                        15,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const Spacer(),

                    const Icon(
                      Icons
                          .keyboard_arrow_down_rounded,
                      color:
                      Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(
              height:
              30,
            ),

            // ==================================================
            // ثبت
            // ==================================================

            SizedBox(
              height:
              52,

              child:
              ElevatedButton(
                onPressed:
                isSubmitting ||
                    selectedBankId ==
                        null
                    ? null
                    : submitPayment,

                style:
                ElevatedButton
                    .styleFrom(
                  backgroundColor:
                  const Color(
                    0xff610db5,
                  ),

                  disabledBackgroundColor:
                  Colors.grey
                      .shade300,

                  foregroundColor:
                  Colors.white,

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      15,
                    ),
                  ),
                ),

                child:
                isSubmitting
                    ? const SizedBox(
                  width:
                  23,
                  height:
                  23,
                  child:
                  CircularProgressIndicator(
                    color:
                    Colors.white,
                    strokeWidth:
                    2,
                  ),
                )
                    : const Text(
                  'ثبت پرداخت',
                  style:
                  TextStyle(
                    fontSize:
                    15,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height:
              20,
            ),
          ],
        ),
      ),
    );
  }
}