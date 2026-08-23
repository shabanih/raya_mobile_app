import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../services/api_service.dart';

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

  static const Color primaryColor =
  Color(0xff610DB5);

  bool isLoading = true;
  bool isSubmitting = false;

  String? errorMessage;

  List<Map<String, dynamic>> banks = [];

  int? selectedBankId;

  DateTime paymentDate =
  DateTime.now();

  Jalali selectedPaymentDate =
  Jalali.now();

  // ============================================================
  // تبدیل امن به int
  // ============================================================

  int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

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

  String toPersianDigits(
      String value,
      ) {
    const english =
        '0123456789';

    const persian =
        '۰۱۲۳۴۵۶۷۸۹';

    for (
    int i = 0;
    i < english.length;
    i++
    ) {
      value =
          value.replaceAll(
            english[i],
            persian[i],
          );
    }

    return value;
  }

  // ============================================================
  // فرمت مبلغ
  // ============================================================

  String formatAmount(
      dynamic value,
      ) {
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

      buffer.write(
        text[i],
      );
    }

    return toPersianDigits(
      buffer.toString(),
    );
  }

  // ============================================================
  // تاریخ شمسی
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
      await _apiService
          .getPaymentBanks(
        widget.chargeId,
      );

      if (!mounted) return;

      setState(() {
        banks = result;

        isLoading = false;

        // فقط یک حساب
        if (banks.length == 1) {
          selectedBankId =
              _parseInt(
                banks.first['id'],
              );
        }

        // حساب پیش‌فرض
        if (banks.length > 1) {
          for (
          final bank in banks
          ) {
            if (
            bank['is_default'] ==
                true
            ) {
              selectedBankId =
                  _parseInt(
                    bank['id'],
                  );

              break;
            }
          }
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
            _cleanError(e);
      });
    }
  }

  // ============================================================
  // پاک کردن خطا
  // ============================================================

  String _cleanError(
      Object error,
      ) {
    final text =
    error.toString();

    if (
    text.startsWith(
      'Exception: ',
    )
    ) {
      return text.substring(11);
    }

    return text;
  }

  // ============================================================
  // انتخاب تاریخ پرداخت
  // ============================================================

  Future<void>
  selectPaymentDate() async {
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

            if (
            selectedDay >
                daysInMonth
            ) {
              selectedDay =
                  daysInMonth;
            }

            return AlertDialog(
              title:
              const Text(
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
                    // ==========================
                    // سال
                    // ==========================

                    DropdownButtonFormField<int>(
                      value:
                      selectedYear,
                      decoration:
                      InputDecoration(
                        labelText:
                        'سال',
                        filled: true,
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

                          return DropdownMenuItem<
                              int>(
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
                        if (
                        value ==
                            null
                        ) {
                          return;
                        }

                        setDialogState(
                              () {
                            selectedYear =
                                value;

                            final maxDay =
                                Jalali(
                                  selectedYear,
                                  selectedMonth,
                                  1,
                                ).monthLength;

                            if (
                            selectedDay >
                                maxDay
                            ) {
                              selectedDay =
                                  maxDay;
                            }
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==========================
                    // ماه
                    // ==========================

                    DropdownButtonFormField<int>(
                      value:
                      selectedMonth,
                      decoration:
                      InputDecoration(
                        labelText:
                        'ماه',
                        filled: true,
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
                      const [
                        DropdownMenuItem(
                          value: 1,
                          child:
                          Text(
                            '۱ - فروردین',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 2,
                          child:
                          Text(
                            '۲ - اردیبهشت',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child:
                          Text(
                            '۳ - خرداد',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 4,
                          child:
                          Text(
                            '۴ - تیر',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 5,
                          child:
                          Text(
                            '۵ - مرداد',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 6,
                          child:
                          Text(
                            '۶ - شهریور',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 7,
                          child:
                          Text(
                            '۷ - مهر',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 8,
                          child:
                          Text(
                            '۸ - آبان',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 9,
                          child:
                          Text(
                            '۹ - آذر',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 10,
                          child:
                          Text(
                            '۱۰ - دی',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 11,
                          child:
                          Text(
                            '۱۱ - بهمن',
                          ),
                        ),
                        DropdownMenuItem(
                          value: 12,
                          child:
                          Text(
                            '۱۲ - اسفند',
                          ),
                        ),
                      ],
                      onChanged:
                          (value) {
                        if (
                        value ==
                            null
                        ) {
                          return;
                        }

                        setDialogState(
                              () {
                            selectedMonth =
                                value;

                            final maxDay =
                                Jalali(
                                  selectedYear,
                                  selectedMonth,
                                  1,
                                ).monthLength;

                            if (
                            selectedDay >
                                maxDay
                            ) {
                              selectedDay =
                                  maxDay;
                            }
                          },
                        );
                      },
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    // ==========================
                    // روز
                    // ==========================

                    DropdownButtonFormField<int>(
                      value:
                      selectedDay,
                      decoration:
                      InputDecoration(
                        labelText:
                        'روز',
                        filled: true,
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

                          return DropdownMenuItem<
                              int>(
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
                        if (
                        value ==
                            null
                        ) {
                          return;
                        }

                        setDialogState(
                              () {
                            selectedDay =
                                value;
                          },
                        );
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
                        primaryColor,
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
                    primaryColor,
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
          content: Text(
            message,
            textDirection:
            TextDirection.rtl,
            textAlign:
            TextAlign.right,
          ),
          behavior:
          SnackBarBehavior.floating,
          duration:
          const Duration(
            seconds: 3,
          ),
        ),
      );
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

    if (
    english != value
    ) {
      transactionController
          .value =
          transactionController
              .value
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
  // ثبت پرداخت
  // ============================================================

  Future<void>
  submitPayment() async {
    if (
    selectedBankId ==
        null
    ) {
      showMessage(
        'لطفاً حساب مقصد را انتخاب کنید.',
      );
      return;
    }

    final transactionReference =
    transactionController
        .text
        .trim();

    if (
    transactionReference
        .isEmpty
    ) {
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

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      showMessage(
        _cleanError(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting =
          false;
        });
      }
    }
  }

  // ============================================================
  // کارت بانک
  // ============================================================

  Widget _buildBankCard(
      Map<String, dynamic> bank,
      ) {
    final bankId =
    _parseInt(
      bank['id'],
    );

    final selected =
        bankId ==
            selectedBankId;

    final bankName =
        bank['bank_name']
            ?.toString() ??
            'بانک';

    final accountNo =
    bank['account_no']
        ?.toString();

    final cardNumber =
    bank['cart_number']
        ?.toString();

    final holder =
    bank['account_holder_name']
        ?.toString();

    final sheba =
    bank['sheba_number']
        ?.toString();

    return InkWell(
      borderRadius:
      BorderRadius.circular(
        18,
      ),
      onTap: () {
        if (bankId == null) {
          return;
        }

        setState(() {
          selectedBankId =
              bankId;
        });
      },
      child:
      AnimatedContainer(
        duration:
        const Duration(
          milliseconds: 200,
        ),
        width:
        double.infinity,
        padding:
        const EdgeInsets.all(
          16,
        ),
        decoration:
        BoxDecoration(
          color: selected
              ? const Color(
            0xfff4eaff,
          )
              : Colors.white,
          borderRadius:
          BorderRadius.circular(
            18,
          ),
          border:
          Border.all(
            color: selected
                ? primaryColor
                : Colors.grey.shade200,
            width:
            selected ? 1.6 : 1,
          ),
        ),
        child:
        Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration:
                  BoxDecoration(
                    color: selected
                        ? primaryColor
                        : Colors.grey.shade100,
                    borderRadius:
                    BorderRadius.circular(
                      13,
                    ),
                  ),
                  child:
                  Icon(
                    Icons.account_balance,
                    color: selected
                        ? Colors.white
                        : Colors.grey.shade700,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child:
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child:
                            Text(
                              bankName,
                              textDirection:
                              TextDirection.rtl,
                              style:
                              const TextStyle(
                                fontSize:
                                16,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),

                          if (
                          bank['is_default'] ==
                              true
                          )
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal:
                                8,
                                vertical:
                                4,
                              ),
                              decoration:
                              BoxDecoration(
                                color:
                                Colors.green.shade50,
                                borderRadius:
                                BorderRadius.circular(
                                  8,
                                ),
                              ),
                              child:
                              Text(
                                'پیش‌فرض',
                                style:
                                TextStyle(
                                  color:
                                  Colors.green.shade700,
                                  fontSize:
                                  11,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      if (
                      holder != null &&
                          holder.isNotEmpty
                      ) ...[
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          holder,
                          textDirection:
                          TextDirection.rtl,
                          style:
                          TextStyle(
                            color:
                            Colors.grey.shade600,
                            fontSize:
                            12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Radio<int>(
                  value:
                  bankId ?? -1,
                  groupValue:
                  selectedBankId,
                  activeColor:
                  primaryColor,
                  onChanged:
                  bankId == null
                      ? null
                      : (value) {
                    setState(() {
                      selectedBankId =
                          value;
                    });
                  },
                ),
              ],
            ),

            // ==================================================
            // اطلاعات حساب
            // ==================================================

            if (
            (cardNumber != null &&
                cardNumber.isNotEmpty) ||
                (accountNo != null &&
                    accountNo.isNotEmpty) ||
                (sheba != null &&
                    sheba.isNotEmpty)
            ) ...[
              const SizedBox(
                height: 14,
              ),

              Divider(
                color:
                Colors.grey.shade200,
              ),

              const SizedBox(
                height: 10,
              ),

              if (
              cardNumber !=
                  null &&
                  cardNumber.isNotEmpty
              )
                _buildBankDetailRow(
                  icon:
                  Icons.credit_card,
                  title:
                  'شماره کارت',
                  value:
                  cardNumber,
                ),

              if (
              accountNo !=
                  null &&
                  accountNo.isNotEmpty
              )
                _buildBankDetailRow(
                  icon:
                  Icons
                      .account_balance_wallet_outlined,
                  title:
                  'شماره حساب',
                  value:
                  accountNo,
                ),

              if (
              sheba !=
                  null &&
                  sheba.isNotEmpty
              )
                _buildBankDetailRow(
                  icon:
                  Icons.numbers,
                  title:
                  'شماره شبا',
                  value:
                  sheba,
                ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // جزئیات بانک
  // ============================================================

  Widget _buildBankDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color:
            Colors.grey.shade600,
          ),

          const SizedBox(
            width: 8,
          ),

          Text(
            '$title:',
            textDirection:
            TextDirection.rtl,
            style:
            TextStyle(
              color:
              Colors.grey.shade600,
              fontSize: 12,
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          Expanded(
            child:
            Text(
              value,
              textDirection:
              TextDirection.ltr,
              textAlign:
              TextAlign.left,
              style:
              const TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
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
    final amount =
        widget.charge?['amount'] ??
            0;

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
            'پرداخت کارت به کارت',
            style:
            TextStyle(
              color:
              Color(0xff263238),
              fontSize:
              18,
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
            primaryColor,
          ),
        )
            : errorMessage != null
            ? _buildError()
            : _buildContent(
          amount,
        ),
      ),
    );
  }

  // ============================================================
  // محتوا
  // ============================================================

  Widget _buildContent(
      dynamic amount,
      ) {
    return ListView(
      padding:
      const EdgeInsets.all(
        18,
      ),
      children: [
        // ========================================================
        // مبلغ
        // ========================================================

        Container(
          padding:
          const EdgeInsets.all(
            20,
          ),
          decoration:
          BoxDecoration(
            color:
            const Color(
              0xff00ACC1,
            ),
            borderRadius:
            BorderRadius.circular(
              20,
            ),
            boxShadow: [
              BoxShadow(
                color:
                const Color(
                  0xff00ACC1,
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
            CrossAxisAlignment.start,
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
                height: 8,
              ),

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
                      color:
                      Colors.white,
                      fontSize:
                      25,
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
          height: 25,
        ),

        // ========================================================
        // حساب مقصد
        // ========================================================

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
          height: 6,
        ),

        const Text(
          'مبلغ را به حساب زیر واریز کرده و سپس اطلاعات پرداخت را ثبت کنید.',
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
          height: 14,
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
              Colors.red.withOpacity(
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
            _buildBankCard,
          ),

        const SizedBox(
          height: 12,
        ),

        // ========================================================
        // کد پیگیری
        // ========================================================

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
          height: 8,
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
              Icons.receipt_long_outlined,
              color:
              primaryColor,
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
          height: 18,
        ),

        // ========================================================
        // تاریخ پرداخت
        // ========================================================

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
          height: 8,
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
            const EdgeInsets.symmetric(
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
                  primaryColor,
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
          height: 30,
        ),

        // ========================================================
        // ثبت پرداخت
        // ========================================================

        SizedBox(
          height: 52,
          child:
          ElevatedButton(
            onPressed:
            isSubmitting ||
                selectedBankId ==
                    null
                ? null
                : submitPayment,
            style:
            ElevatedButton.styleFrom(
              backgroundColor:
              primaryColor,
              disabledBackgroundColor:
              Colors.grey.shade300,
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
              width: 23,
              height: 23,
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
          height: 20,
        ),
      ],
    );
  }

  // ============================================================
  // خطا
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(
          25,
        ),
        child:
        Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons
                  .error_outline_rounded,
              color:
              Colors.red,
              size:
              55,
            ),

            const SizedBox(
              height: 15,
            ),

            const Text(
              'دریافت حساب‌های بانکی انجام نشد',
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                fontSize:
                16,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              errorMessage ??
                  '',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
                fontSize:
                12,
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
}