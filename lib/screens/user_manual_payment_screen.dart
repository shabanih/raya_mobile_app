import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../services/api_service.dart';

class UserManualPaymentScreen
    extends StatefulWidget {
  final int paymentId;
  final Map<String, dynamic>? payment;

  const UserManualPaymentScreen({
    super.key,
    required this.paymentId,
    this.payment,
  });

  @override
  State<UserManualPaymentScreen>
  createState() =>
      _UserManualPaymentScreenState();
}

class _UserManualPaymentScreenState
    extends State<UserManualPaymentScreen> {
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

  Jalali selectedPaymentDate =
  Jalali.now();

  DateTime paymentDate =
  DateTime.now();

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
  // =====================================================
  // Colors
  // =====================================================

  static const Color primaryColor =
  Color(0xff610DB5);

  static const Color cyanColor =
  Color(0xff00ACC1);

  static const Color textColor =
  Color(0xff263238);

  static const Color backgroundColor =
  Color(0xffF7F9FA);
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
  // تبدیل اعداد فارسی به انگلیسی
  // ============================================================

  String toEnglishDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const english = '0123456789';

    for (int i = 0; i < persian.length; i++) {
      value = value.replaceAll(
        persian[i],
        english[i],
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

    for (int i = 0;
    i < text.length;
    i++) {
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
  // تاریخ جلالی
  // ============================================================

  String formatJalaliDate(
      Jalali date,
      ) {
    return toPersianDigits(
      '${date.year}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.day.toString().padLeft(2, '0')}',
    );
  }

  // ============================================================
  // دریافت حساب‌های بانکی
  // ============================================================

  Future<void> loadBanks() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
      await _apiService.getUserPaymentPaymentMethods(
        widget.paymentId,
      );

      if (!mounted) return;

      final resultBanks =
      result['payment_banks'];

      final loadedBanks =
      resultBanks is List
          ? resultBanks
          .whereType<Map>()
          .map(
            (item) =>
        Map<String, dynamic>.from(
          item,
        ),
      )
          .toList()
          : <Map<String, dynamic>>[];

      setState(() {
        banks = loadedBanks;
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
        'LOAD USER PAYMENT BANKS ERROR = $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            _cleanError(e);
      });
    }
  }

  // ============================================================
  // پاک کردن خطا
  // ============================================================

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(11);
    }

    return text;
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
          builder: (
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
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              content: SizedBox(
                width:
                double.maxFinite,
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    // سال
                    DropdownButtonFormField<int>(
                      value:
                      selectedYear,
                      decoration:
                      InputDecoration(
                        labelText: 'سال',
                        filled: true,
                        fillColor:
                        const Color(
                          0xffF7F9FA,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
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

                          return DropdownMenuItem<
                              int>(
                            value: year,
                            child: Text(
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

                    // ماه
                    DropdownButtonFormField<int>(
                      value:
                      selectedMonth,
                      decoration:
                      InputDecoration(
                        labelText: 'ماه',
                        filled: true,
                        fillColor:
                        const Color(
                          0xffF7F9FA,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
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

                    // روز
                    DropdownButtonFormField<int>(
                      value:
                      selectedDay,
                      decoration:
                      InputDecoration(
                        labelText: 'روز',
                        filled: true,
                        fillColor:
                        const Color(
                          0xffF7F9FA,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
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

                          return DropdownMenuItem<
                              int>(
                            value: day,
                            child: Text(
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
                        Color(0xff610DB5),
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
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(
                      0xff610DB5,
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

    if (result != null &&
        mounted) {
      setState(() {
        selectedPaymentDate =
            result;

        paymentDate =
            result.toDateTime();
      });
    }
  }

  // ============================================================
  // نرمال‌سازی کد پیگیری
  // ============================================================

  void normalizeTransactionReference(
      String value,
      ) {
    final english =
    toEnglishDigits(value);

    if (english != value) {
      transactionController.value =
          transactionController.value
              .copyWith(
            text: english,
            selection:
            TextSelection.collapsed(
              offset: english.length,
            ),
          );
    }
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
            textDirection:
            TextDirection.rtl,
            textAlign:
            TextAlign.right,
          ),
          behavior:
          SnackBarBehavior.floating,
          backgroundColor:
          isError
              ? Colors.redAccent
              : null,
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
        isError: true,
      );
      return;
    }

    final transactionReference =
    toEnglishDigits(
      transactionController.text.trim(),
    );

    if (transactionReference.isEmpty) {
      showMessage(
        'لطفاً کد پیگیری واریز را وارد کنید.',
        isError: true,
      );
      return;
    }

    if (isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isSubmitting = true;
    });

    try {
      final result =
      await _apiService
          .submitManualUserPayment(
        paymentId:
        widget.paymentId,
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

      setState(() {
        isSubmitting = false;
      });

      final message =
          result['message']?.toString() ??
              'درخواست پرداخت با موفقیت ثبت شد و در انتظار تأیید مدیر ساختمان است.';

      // --------------------------------------------------------
      // پیام موفقیت
      // --------------------------------------------------------

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(
                20,
              ),
            ),
            title: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.orange
                        .withOpacity(
                      0.10,
                    ),
                    shape:
                    BoxShape.circle,
                  ),
                  child:
                  const Icon(
                    Icons
                        .hourglass_top_rounded,
                    color:
                    Colors.orange,
                    size: 25,
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                const Expanded(
                  child: Text(
                    'درخواست ثبت شد',
                    textAlign:
                    TextAlign.right,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              textAlign:
              TextAlign.right,
              textDirection:
              TextDirection.rtl,
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
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
                  'متوجه شدم',
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      // --------------------------------------------------------
      // true یعنی درخواست پرداخت ثبت شده
      // صفحه قبلی باید دوباره اطلاعات را دریافت کند.
      // --------------------------------------------------------

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      showMessage(
        _cleanError(e),
        isError: true,
      );
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

    final bankName =
        bank['bank_name']
            ?.toString()
            .trim() ??
            '';

    final cardNumber =
        bank['cart_number']
            ?.toString()
            .trim() ??
            '';

    final accountNumber =
        bank['account_no']
            ?.toString()
            .trim() ??
            '';

    final sheba =
        bank['sheba_number']
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
        if (id == null) return;

        setState(() {
          selectedBankId = id;
        });
      },
      child: Container(
        margin:
        const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
        const EdgeInsets.all(18),
        decoration:
        BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: selected
                ? const Color(
              0xff610DB5,
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
              color: Colors.black
                  .withOpacity(
                0.04,
              ),
              blurRadius: 8,
              offset:
              const Offset(0, 3),
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
                  0xff610DB5,
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
                  0xff610DB5,
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
                    .stretch,
                children: [
                  if (bankName
                      .isNotEmpty)
                    Text(
                      bankName,
                      textAlign:
                      TextAlign.right,
                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Color(
                          0xff263238,
                        ),
                      ),
                    ),

                  if (cardNumber
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      'شماره کارت',
                      textAlign:
                      TextAlign.right,
                      style:
                      TextStyle(
                        fontSize: 11,
                        color:
                        Colors.grey,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      toPersianDigits(
                        cardNumber,
                      ),
                      textAlign:
                      TextAlign.left,
                      textDirection:
                      TextDirection.ltr,
                      style:
                      const TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.bold,
                        letterSpacing:
                        1.0,
                        color:
                        Color(
                          0xff263238,
                        ),
                      ),
                    ),
                  ],

                  if (holder
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 9,
                    ),
                    _buildBankInfoRow(
                      icon: Icons
                          .person_outline_rounded,
                      title:
                      'صاحب حساب',
                      value:
                      holder,
                    ),
                  ],

                  if (accountNumber
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 7,
                    ),
                    _buildBankInfoRow(
                      icon: Icons
                          .account_balance_outlined,
                      title:
                      'شماره حساب',
                      value:
                      accountNumber,
                      ltr: true,
                    ),
                  ],

                  if (sheba
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 7,
                    ),
                    _buildBankInfoRow(
                      icon: Icons
                          .account_balance_rounded,
                      title:
                      'شماره شبا',
                      value:
                      sheba,
                      ltr: true,
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
  // اطلاعات بانک
  // ============================================================

  Widget _buildBankInfoRow({
    required IconData icon,
    required String title,
    required String value,
    bool ltr = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color:
          const Color(0xff610DB5),
        ),

        const SizedBox(width: 6),

        Text(
          '$title:',
          style:
          const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),

        const SizedBox(width: 5),

        Expanded(
          child: Text(
            toPersianDigits(value),
            textAlign:
            TextAlign.right,
            textDirection: ltr
                ? TextDirection.ltr
                : TextDirection.rtl,
            style:
            const TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.w600,
              color:
              Color(0xff455A64),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // کارت مبلغ
  // ============================================================

  Widget buildAmountCard() {
    final amount =
        widget.payment?['amount'] ??
            0;

    return Container(
      padding:
      const EdgeInsets.all(20),
      decoration:
      BoxDecoration(
        color:
        const Color(0xff00ACC1),
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        boxShadow: [
          BoxShadow(
            color:
            const Color(
              0xff00ACC1,
            ).withOpacity(0.20),
            blurRadius: 14,
            offset:
            const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .stretch,
        children: [
          const Text(
            'مبلغ قابل پرداخت',
            textAlign:
            TextAlign.right,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.end,
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

              const SizedBox(
                width: 7,
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
    );
  }

  // ============================================================
  // خطای بارگذاری
  // ============================================================

  Widget buildError() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          25,
        ),
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
              'دریافت اطلاعات پرداخت انجام نشد',
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
              loadBanks,
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
  // Body
  // ============================================================

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(
          color:
          Color(0xff610DB5),
        ),
      );
    }

    if (errorMessage != null) {
      return buildError();
    }

    return ListView(
      padding:
      const EdgeInsets.all(18),
      children: [
        // ------------------------------------------------------
        // مبلغ
        // ------------------------------------------------------

        buildAmountCard(),

        const SizedBox(
          height: 25,
        ),

        // ------------------------------------------------------
        // توضیحات
        // ------------------------------------------------------

        const Text(
          'حساب مقصد',
          textAlign:
          TextAlign.right,
          style: TextStyle(
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
          'مبلغ کمک را به یکی از حساب‌های زیر واریز کرده و سپس اطلاعات پرداخت را ثبت کنید.',
          textAlign:
          TextAlign.right,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            height: 1.6,
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        // ------------------------------------------------------
        // بانک‌ها
        // ------------------------------------------------------

        if (banks.isEmpty)
          Container(
            padding:
            const EdgeInsets.all(
              18,
            ),
            decoration:
            BoxDecoration(
              color:
              Colors.red.withOpacity(
                0.06,
              ),
              borderRadius:
              BorderRadius.circular(
                16,
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons
                      .account_balance_outlined,
                  size: 45,
                  color:
                  Colors.redAccent,
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  'حساب بانکی فعالی برای دریافت این کمک ثبت نشده است.',
                  textAlign:
                  TextAlign.center,
                  style: TextStyle(
                    color:
                    Colors.redAccent,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          )
        else
          ...banks.map(
            buildBankCard,
          ),

        const SizedBox(
          height: 14,
        ),

        // ------------------------------------------------------
        // کد پیگیری
        // ------------------------------------------------------

        const Text(
          'کد پیگیری',
          textAlign:
          TextAlign.right,
          style: TextStyle(
            fontSize: 15,
            fontWeight:
            FontWeight.bold,
            color:
            Color(0xff263238),
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        TextField(
          controller:
          transactionController,
          keyboardType:
          TextInputType.number,
          textDirection:
          TextDirection.ltr,
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
              Color(0xff610DB5),
            ),
            filled: true,
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
            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                14,
              ),
              borderSide:
              BorderSide(
                color:
                Colors.grey
                    .withOpacity(
                  0.10,
                ),
              ),
            ),
            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(
                14,
              ),
              borderSide:
              const BorderSide(
                color:
                Color(0xff610DB5),
                width: 1.5,
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 18,
        ),

        // ------------------------------------------------------
        // تاریخ پرداخت
        // ------------------------------------------------------

        const Text(
          'تاریخ پرداخت',
          textAlign:
          TextAlign.right,
          style: TextStyle(
            fontSize: 15,
            fontWeight:
            FontWeight.bold,
            color:
            Color(0xff263238),
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        InkWell(
          onTap:
          selectPaymentDate,
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          child: Container(
            padding:
            const EdgeInsets
                .symmetric(
              horizontal: 15,
              vertical: 16,
            ),
            decoration:
            BoxDecoration(
              color:
              Colors.white,
              borderRadius:
              BorderRadius.circular(
                14,
              ),
              border:
              Border.all(
                color:
                Colors.grey
                    .withOpacity(
                  0.10,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons
                      .calendar_month_rounded,
                  color:
                  Color(0xff610DB5),
                ),

                const SizedBox(
                  width: 10,
                ),

                Text(
                  formatJalaliDate(
                    selectedPaymentDate,
                  ),
                  style:
                  const TextStyle(
                    fontSize: 15,
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
          height: 30,
        ),

        // ------------------------------------------------------
        // ثبت پرداخت
        // ------------------------------------------------------

        SizedBox(
          height: 52,
          child:
          ElevatedButton(
            onPressed:
            isSubmitting ||
                selectedBankId ==
                    null ||
                banks.isEmpty
                ? null
                : submitPayment,
            style:
            ElevatedButton.styleFrom(
              backgroundColor:
              const Color(
                0xff610DB5,
              ),
              disabledBackgroundColor:
              Colors.grey.shade300,
              foregroundColor:
              Colors.white,
              elevation: 0,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  15,
                ),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
              width: 23,
              height: 23,
              child:
              CircularProgressIndicator(
                color:
                Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Text(
              'ثبت پرداخت',
              style:
              TextStyle(
                fontSize: 15,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 20,
        ),
      ],
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
            'پرداخت کارت به کارت',
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
        body: buildBody(),
      ),
    );
  }
}