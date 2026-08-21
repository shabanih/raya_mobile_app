import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../services/api_service.dart';

class ManualSewagePaymentScreen extends StatefulWidget {
  final int installmentId;

  const ManualSewagePaymentScreen({
    super.key,
    required this.installmentId,
  });

  @override
  State<ManualSewagePaymentScreen> createState() =>
      _ManualSewagePaymentScreenState();
}

class _ManualSewagePaymentScreenState
    extends State<ManualSewagePaymentScreen> {
  static const Color primaryColor = Color(0xff00ACC1);
  static const Color purpleColor = Color(0xff610db5);
  static const Color backgroundColor = Color(0xfff7f7f9);

  final ApiService _apiService = ApiService();

  final TextEditingController _transactionController =
  TextEditingController();

  Map<String, dynamic>? _paymentData;

  List<Map<String, dynamic>> _banks = [];

  int? _selectedBankId;

  /// تاریخ پرداخت به صورت شمسی
  Jalali? _paymentDate;

  bool _isLoading = true;
  bool _isSubmitting = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  // =====================================================
  // دریافت اطلاعات قسط و روش‌های پرداخت
  // =====================================================

  Future<void> _loadPaymentMethods() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data =
      await _apiService.getSewageInstallmentPaymentMethods(
        widget.installmentId,
      );

      if (!mounted) return;

      final banksData = data['payment_banks'];

      final List<Map<String, dynamic>> banks = [];

      if (banksData is List) {
        for (final item in banksData) {
          if (item is Map) {
            banks.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      int? defaultBankId;

      for (final bank in banks) {
        if (bank['is_default'] == true) {
          final id = bank['id'];

          if (id is int) {
            defaultBankId = id;
          } else if (id != null) {
            defaultBankId = int.tryParse(
              id.toString(),
            );
          }

          break;
        }
      }

      setState(() {
        _paymentData = data;
        _banks = banks;

        _selectedBankId =
            defaultBankId ??
                (banks.isNotEmpty
                    ? _parseInt(banks.first['id'])
                    : null);

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanErrorMessage(e);
      });
    }
  }

  // =====================================================
  // تبدیل عدد
  // =====================================================

  int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value == null) {
      return null;
    }

    return int.tryParse(value.toString());
  }

  // =====================================================
  // تبدیل اعداد انگلیسی به فارسی
  // =====================================================

  String _toPersianDigits(String value) {
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
// تبدیل تاریخ API به تاریخ شمسی برای نمایش
// =====================================================

  String _formatDueDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return '-';
    }

    try {
      // اگر تاریخ به صورت ISO باشد:
      // 2026-08-21
      final dateTime = DateTime.parse(text);

      final jalali = Jalali.fromDateTime(dateTime);

      return '${_toPersianDigits(jalali.year.toString())}/'
          '${_toPersianDigits(jalali.month.toString().padLeft(2, '0'))}/'
          '${_toPersianDigits(jalali.day.toString().padLeft(2, '0'))}';
    } catch (_) {
      return text;
    }
  }

  // =====================================================
  // انتخاب تاریخ پرداخت شمسی
  // مشابه صفحه شارژها
  // =====================================================

  Future<void> _selectPaymentDate() async {
    final now = Jalali.now();

    // اگر قبلاً تاریخ انتخاب شده، همان تاریخ باز شود
    final initialDate = _paymentDate ?? now;

    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;
    int selectedDay = initialDate.day;

    final result = await showDialog<Jalali>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            final daysInMonth = Jalali(
              selectedYear,
              selectedMonth,
              1,
            ).monthLength;

            if (selectedDay > daysInMonth) {
              selectedDay = daysInMonth;
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),

                title: const Text(
                  'انتخاب تاریخ پرداخت',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // =================================================
                      // سال
                      // =================================================

                      DropdownButtonFormField<int>(
                        value: selectedYear,
                        decoration: InputDecoration(
                          labelText: 'سال',
                          filled: true,
                          fillColor: const Color(0xffF7F9FA),
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: List.generate(
                          11,
                              (index) {
                            final year =
                                now.year - 5 + index;

                            return DropdownMenuItem<int>(
                              value: year,
                              child: Text(
                                _toPersianDigits(
                                  year.toString(),
                                ),
                              ),
                            );
                          },
                        ),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedYear = value;

                            final maxDay = Jalali(
                              selectedYear,
                              selectedMonth,
                              1,
                            ).monthLength;

                            if (selectedDay > maxDay) {
                              selectedDay = maxDay;
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      // =================================================
                      // ماه
                      // =================================================

                      DropdownButtonFormField<int>(
                        value: selectedMonth,
                        decoration: InputDecoration(
                          labelText: 'ماه',
                          filled: true,
                          fillColor: const Color(0xffF7F9FA),
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 1,
                            child: Text('۱ - فروردین'),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('۲ - اردیبهشت'),
                          ),
                          DropdownMenuItem(
                            value: 3,
                            child: Text('۳ - خرداد'),
                          ),
                          DropdownMenuItem(
                            value: 4,
                            child: Text('۴ - تیر'),
                          ),
                          DropdownMenuItem(
                            value: 5,
                            child: Text('۵ - مرداد'),
                          ),
                          DropdownMenuItem(
                            value: 6,
                            child: Text('۶ - شهریور'),
                          ),
                          DropdownMenuItem(
                            value: 7,
                            child: Text('۷ - مهر'),
                          ),
                          DropdownMenuItem(
                            value: 8,
                            child: Text('۸ - آبان'),
                          ),
                          DropdownMenuItem(
                            value: 9,
                            child: Text('۹ - آذر'),
                          ),
                          DropdownMenuItem(
                            value: 10,
                            child: Text('۱۰ - دی'),
                          ),
                          DropdownMenuItem(
                            value: 11,
                            child: Text('۱۱ - بهمن'),
                          ),
                          DropdownMenuItem(
                            value: 12,
                            child: Text('۱۲ - اسفند'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedMonth = value;

                            final maxDay = Jalali(
                              selectedYear,
                              selectedMonth,
                              1,
                            ).monthLength;

                            if (selectedDay > maxDay) {
                              selectedDay = maxDay;
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      // =================================================
                      // روز
                      // =================================================

                      DropdownButtonFormField<int>(
                        value: selectedDay,
                        decoration: InputDecoration(
                          labelText: 'روز',
                          filled: true,
                          fillColor: const Color(0xffF7F9FA),
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: List.generate(
                          daysInMonth,
                              (index) {
                            final day = index + 1;

                            return DropdownMenuItem<int>(
                              value: day,
                              child: Text(
                                _toPersianDigits(
                                  day.toString(),
                                ),
                              ),
                            );
                          },
                        ),
                        onChanged: (value) {
                          if (value == null) return;

                          setDialogState(() {
                            selectedDay = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // =================================================
                      // تاریخ انتخاب شده
                      // =================================================

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xfff4eaff),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'تاریخ انتخاب شده: '
                                    '${_toPersianDigits(selectedYear.toString())}/'
                                    '${_toPersianDigits(selectedMonth.toString().padLeft(2, '0'))}/'
                                    '${_toPersianDigits(selectedDay.toString().padLeft(2, '0'))}',
                                textDirection:
                                TextDirection.rtl,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: primaryColor,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                actionsPadding:
                const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  12,
                ),

                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text(
                      'انصراف',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
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
                      primaryColor,
                      foregroundColor:
                      Colors.white,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                    child: const Text(
                      'تأیید',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    // =====================================================
    // ذخیره تاریخ انتخاب شده
    // =====================================================

    if (result != null && mounted) {
      setState(() {
        _paymentDate = result;
      });
    }
  }

  // =====================================================
  // تبدیل تاریخ شمسی به میلادی برای API
  // =====================================================

  String _formatDateForApi(Jalali date) {
    final gregorian = date.toGregorian();

    final year =
    gregorian.year.toString().padLeft(4, '0');

    final month =
    gregorian.month.toString().padLeft(2, '0');

    final day =
    gregorian.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // =====================================================
  // نمایش تاریخ شمسی
  // =====================================================

  String _formatJalaliDate(Jalali date) {
    return '${_toPersianDigits(date.year.toString())}/'
        '${_toPersianDigits(date.month.toString().padLeft(2, '0'))}/'
        '${_toPersianDigits(date.day.toString().padLeft(2, '0'))}';
  }

  // =====================================================
  // ثبت پرداخت
  // =====================================================

  Future<void> _submitPayment() async {
    FocusScope.of(context).unfocus();

    if (_selectedBankId == null) {
      _showError(
        'لطفاً حساب مقصد را انتخاب کنید.',
      );
      return;
    }

    final transactionReference =
    _transactionController.text.trim();

    if (transactionReference.isEmpty) {
      _showError(
        'لطفاً کد پیگیری را وارد کنید.',
      );
      return;
    }

    if (_paymentDate == null) {
      _showError(
        'لطفاً تاریخ پرداخت را انتخاب کنید.',
      );
      return;
    }

    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result =
      await _apiService
          .submitManualSewageInstallmentPayment(
        installmentId:
        widget.installmentId,
        bankId:
        _selectedBankId!,
        transactionReference:
        transactionReference,
        paymentDate:
        _formatDateForApi(
          _paymentDate!,
        ),
      );

      if (!mounted) return;

      final success =
          result['success'] == true;

      if (success) {
        await _showSuccessDialog();

        if (!mounted) return;

        Navigator.of(context).pop(true);

        return;
      }

      throw Exception(
        result['message']?.toString() ??
            'ثبت پرداخت ناموفق بود.',
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        _cleanErrorMessage(e),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // =====================================================
  // دیالوگ موفقیت
  // =====================================================

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Directionality(
          textDirection:
          TextDirection.rtl,
          child: AlertDialog(
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 30,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'پرداخت ثبت شد',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'اطلاعات پرداخت شما با موفقیت ثبت شد و پس از تأیید مدیر ساختمان، پرداخت نهایی خواهد شد.',
              style: TextStyle(
                height: 1.8,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'متوجه شدم',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // نمایش خطا
  // =====================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection:
          TextDirection.rtl,
        ),
        behavior:
        SnackBarBehavior.floating,
        backgroundColor:
        Colors.red.shade700,
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(12),
        ),
      ),
    );
  }

  // =====================================================
  // تمیز کردن خطا
  // =====================================================

  String _cleanErrorMessage(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(
        'Exception: '.length,
      );
    }

    return text;
  }

  // =====================================================
  // فرمت مبلغ
  // =====================================================

  String _formatAmount(dynamic value) {
    final number =
        _parseInt(value) ?? 0;

    final text =
    number.toString();

    final buffer =
    StringBuffer();

    for (
    int i = 0;
    i < text.length;
    i++
    ) {
      if (i > 0 &&
          (text.length - i) % 3 == 0) {
        buffer.write('٬');
      }

      buffer.write(text[i]);
    }

    return _toPersianDigits(
      buffer.toString(),
    );
  }

  // =====================================================
  // عنوان قسط
  // =====================================================

  String _getInstallmentTitle(
      dynamic installmentNumber) {
    final number =
    _parseInt(installmentNumber);

    if (number == null ||
        number == 0) {
      return 'پیش‌پرداخت';
    }

    return 'قسط ${_toPersianDigits(number.toString())}';
  }

  // =====================================================
  // کارت اطلاعات قسط
  // =====================================================

  Widget _buildInstallmentCard() {
    final installment =
    _paymentData?['installment'];

    if (installment is! Map) {
      return const SizedBox.shrink();
    }

    final sewageName =
        installment['sewage_name']
            ?.toString() ??
            'هزینه فاضلاب';

    final installmentNumber =
    installment[
    'installment_number'];

    final amount =
    installment['amount'];

    final dueDate = _formatDueDate(
      installment['due_date'],
    );

    final installmentTitle =
    _getInstallmentTitle(
      installmentNumber,
    );

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        borderRadius:
        BorderRadius.circular(20),
        gradient:
        const LinearGradient(
          begin:
          Alignment.topRight,
          end:
          Alignment.bottomLeft,
          colors: [
            Color(0xff610db5),
            Color(0xff7b2ac8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color:
            const Color(0xff610db5)
                .withOpacity(0.20),
            blurRadius: 12,
            offset:
            const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration:
                BoxDecoration(
                  color:
                  Colors.white
                      .withOpacity(0.16),
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child: const Icon(
                  Icons
                      .construction_rounded,
                  color:
                  Colors.white,
                  size: 26,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  sewageName,
                  textDirection:
                  TextDirection.rtl,
                  style:
                  const TextStyle(
                    color:
                    Colors.white,
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child:
                _buildWhiteInfoItem(
                  title:
                  'شماره قسط',
                  value:
                  installmentTitle,
                ),
              ),

              Expanded(
                child:
                _buildWhiteInfoItem(
                  title:
                  'مبلغ',
                  value:
                  '${_formatAmount(amount)} تومان',
                ),
              ),
            ],
          ),

          if (dueDate != null &&
              dueDate.isNotEmpty) ...[
            const SizedBox(height: 12),

            _buildWhiteInfoItem(
              title:
              'تاریخ سررسید',
              value:
              dueDate,
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // اطلاعات سفید کارت
  // =====================================================

  Widget _buildWhiteInfoItem({
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          textDirection:
          TextDirection.rtl,
          style:
          TextStyle(
            color:
            Colors.white
                .withOpacity(0.75),
            fontSize: 12,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          value,
          textDirection:
          TextDirection.rtl,
          style:
          const TextStyle(
            color:
            Colors.white,
            fontSize: 15,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // کارت بانک
  // =====================================================

  Widget _buildBankCard(
      Map<String, dynamic> bank) {
    final bankId =
    _parseInt(bank['id']);

    final selected =
        bankId == _selectedBankId;

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
      BorderRadius.circular(18),
      onTap: () {
        if (bankId == null) {
          return;
        }

        setState(() {
          _selectedBankId =
              bankId;
        });
      },
      child: AnimatedContainer(
        duration:
        const Duration(
          milliseconds: 200,
        ),
        width: double.infinity,
        padding:
        const EdgeInsets.all(16),
        decoration:
        BoxDecoration(
          color: selected
              ? const Color(0xfff4eaff)
              : Colors.white,
          borderRadius:
          BorderRadius.circular(18),
          border:
          Border.all(
            color: selected
                ? primaryColor
                : Colors.grey.shade200,
            width:
            selected ? 1.6 : 1,
          ),
        ),
        child: Column(
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
                  child: Icon(
                    Icons.account_balance,
                    color: selected
                        ? Colors.white
                        : Colors.grey.shade700,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              bankName,
                              textDirection:
                              TextDirection.rtl,
                              style:
                              const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),

                          if (bank['is_default'] ==
                              true)
                            Container(
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal: 8,
                                vertical: 4,
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
                                  fontSize: 11,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      if (holder != null &&
                          holder.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          holder,
                          textDirection:
                          TextDirection.rtl,
                          style:
                          TextStyle(
                            color:
                            Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Radio<int>(
                  value:
                  bankId ?? -1,
                  groupValue:
                  _selectedBankId,
                  activeColor:
                  primaryColor,
                  onChanged:
                  bankId == null
                      ? null
                      : (value) {
                    setState(() {
                      _selectedBankId =
                          value;
                    });
                  },
                ),
              ],
            ),

            if ((cardNumber != null &&
                cardNumber.isNotEmpty) ||
                (accountNo != null &&
                    accountNo.isNotEmpty) ||
                (sheba != null &&
                    sheba.isNotEmpty)) ...[
              const SizedBox(height: 14),

              Divider(
                color:
                Colors.grey.shade200,
              ),

              const SizedBox(height: 10),

              if (cardNumber != null &&
                  cardNumber.isNotEmpty)
                _buildBankDetailRow(
                  icon:
                  Icons.credit_card,
                  title:
                  'شماره کارت',
                  value:
                  cardNumber,
                ),

              if (accountNo != null &&
                  accountNo.isNotEmpty)
                _buildBankDetailRow(
                  icon:
                  Icons
                      .account_balance_wallet_outlined,
                  title:
                  'شماره حساب',
                  value:
                  accountNo,
                ),

              if (sheba != null &&
                  sheba.isNotEmpty)
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

  // =====================================================
  // جزئیات بانک
  // =====================================================

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

          const SizedBox(width: 8),

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

          const SizedBox(width: 6),

          Expanded(
            child: Text(
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

  // =====================================================
  // فرم پرداخت
  // =====================================================

  Widget _buildPaymentForm() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        border:
        Border.all(
          color:
          Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'اطلاعات پرداخت',
            textDirection:
            TextDirection.rtl,
            style:
            TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'پس از واریز وجه، اطلاعات زیر را وارد کنید.',
            textDirection:
            TextDirection.rtl,
            style:
            TextStyle(
              color:
              Colors.grey.shade600,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'کد پیگیری / شماره تراکنش',
            textDirection:
            TextDirection.rtl,
            style:
            TextStyle(
              fontWeight:
              FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller:
            _transactionController,
            keyboardType:
            TextInputType.number,
            textDirection:
            TextDirection.ltr,
            textAlign:
            TextAlign.left,
            decoration:
            InputDecoration(
              hintText:
              'کد پیگیری را وارد کنید',
              hintTextDirection:
              TextDirection.rtl,
              prefixIcon:
              const Icon(
                Icons
                    .receipt_long_outlined,
              ),
              filled: true,
              fillColor:
              Colors.grey.shade50,
              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
                borderSide:
                BorderSide(
                  color:
                  Colors.grey.shade200,
                ),
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
                  Colors.grey.shade200,
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
                  primaryColor,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'تاریخ پرداخت',
            textDirection:
            TextDirection.rtl,
            style:
            TextStyle(
              fontWeight:
              FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          InkWell(
            borderRadius:
            BorderRadius.circular(14),
            onTap:
            _selectPaymentDate,
            child: Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 16,
              ),
              decoration:
              BoxDecoration(
                color:
                Colors.grey.shade50,
                borderRadius:
                BorderRadius.circular(14),
                border:
                Border.all(
                  color:
                  Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons
                        .calendar_month_outlined,
                    color:
                    primaryColor,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      _paymentDate == null
                          ? 'انتخاب تاریخ پرداخت'
                          : _formatJalaliDate(
                        _paymentDate!,
                      ),
                      textDirection:
                      TextDirection.rtl,
                      style:
                      TextStyle(
                        color:
                        _paymentDate == null
                            ? Colors.grey.shade600
                            : Colors.black87,
                        fontSize: 14,
                        fontWeight:
                        _paymentDate == null
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                  ),

                  Icon(
                    Icons
                        .keyboard_arrow_down_rounded,
                    color:
                    Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // دکمه ثبت
  // =====================================================

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed:
        _isSubmitting
            ? null
            : _submitPayment,
        style:
        ElevatedButton.styleFrom(
          backgroundColor:
          primaryColor,
          foregroundColor:
          Colors.white,
          disabledBackgroundColor:
          Colors.grey.shade400,
          elevation: 0,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
          width: 24,
          height: 24,
          child:
          CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor:
            AlwaysStoppedAnimation<
                Color>(
              Colors.white,
            ),
          ),
        )
            : const Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              Icons
                  .check_circle_outline,
            ),
            SizedBox(width: 8),
            Text(
              'ثبت اطلاعات پرداخت',
              style:
              TextStyle(
                fontSize: 15,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // محتوای صفحه
  // =====================================================

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding:
          const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                Icons
                    .error_outline_rounded,
                size: 60,
                color:
                Colors.red.shade400,
              ),

              const SizedBox(height: 16),

              Text(
                _errorMessage!,
                textDirection:
                TextDirection.rtl,
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed:
                _loadPaymentMethods,
                icon:
                const Icon(
                  Icons.refresh,
                ),
                label:
                const Text(
                  'تلاش مجدد',
                ),
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  primaryColor,
                  foregroundColor:
                  Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final installment =
    _paymentData?['installment'];

    if (installment is Map) {
      final isPaid =
          installment['is_paid'] == true;

      final paymentPending =
          installment[
          'payment_pending'] ==
              true;

      if (isPaid ||
          paymentPending) {
        return Center(
          child: Padding(
            padding:
            const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                Icon(
                  isPaid
                      ? Icons
                      .check_circle_rounded
                      : Icons
                      .hourglass_top_rounded,
                  size: 70,
                  color: isPaid
                      ? Colors.green
                      : Colors.orange,
                ),

                const SizedBox(height: 18),

                Text(
                  isPaid
                      ? 'این قسط قبلاً پرداخت شده است.'
                      : 'پرداخت این قسط در انتظار تأیید مدیر ساختمان است.',
                  textDirection:
                  TextDirection.rtl,
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                    height: 1.8,
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop();
                  },
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    primaryColor,
                    foregroundColor:
                    Colors.white,
                  ),
                  child:
                  const Text(
                    'بازگشت',
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh:
      _loadPaymentMethods,
      child: ListView(
        padding:
        const EdgeInsets.all(16),
        children: [
          _buildInstallmentCard(),

          const SizedBox(height: 18),

          // =================================================
          // حساب ساختمان
          // =================================================

          Row(
            children: [
              const Icon(
                Icons.account_balance,
                color:
                primaryColor,
              ),

              const SizedBox(width: 8),

              const Expanded(
                child: Text(
                  'حساب ساختمان',
                  textDirection:
                  TextDirection.rtl,
                  style:
                  TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'مبلغ قسط را به یکی از حساب‌های زیر واریز کنید.',
            textDirection:
            TextDirection.rtl,
            style:
            TextStyle(
              color:
              Colors.grey.shade600,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 12),

          if (_banks.isEmpty)
            Container(
              width: double.infinity,
              padding:
              const EdgeInsets.all(18),
              decoration:
              BoxDecoration(
                color:
                Colors.orange.shade50,
                borderRadius:
                BorderRadius.circular(16),
                border:
                Border.all(
                  color:
                  Colors.orange.shade200,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons
                        .warning_amber_rounded,
                    color:
                    Colors.orange,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'برای این ساختمان حساب بانکی فعالی ثبت نشده است.',
                      textDirection:
                      TextDirection.rtl,
                      style:
                      TextStyle(
                        height: 1.7,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._banks.map(
                  (bank) => Padding(
                padding:
                const EdgeInsets.only(
                  bottom: 10,
                ),
                child:
                _buildBankCard(
                  bank,
                ),
              ),
            ),

          const SizedBox(height: 12),

          _buildPaymentForm(),

          const SizedBox(height: 18),

          // =================================================
          // هشدار
          // =================================================

          Container(
            padding:
            const EdgeInsets.all(14),
            decoration:
            BoxDecoration(
              color:
              Colors.blue.shade50,
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons
                      .info_outline_rounded,
                  color:
                  Colors.blue.shade700,
                  size: 22,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'پس از ثبت اطلاعات، پرداخت شما در وضعیت «در انتظار تأیید» قرار می‌گیرد و پس از بررسی مدیر ساختمان نهایی خواهد شد.',
                    textDirection:
                    TextDirection.rtl,
                    style:
                    TextStyle(
                      color:
                      Colors.blue.shade800,
                      fontSize: 12,
                      height: 1.8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (_banks.isNotEmpty)
            _buildSubmitButton(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor:
          Colors.white,
          foregroundColor:
          Colors.black87,
          centerTitle: true,
          title: const Text(
            'پرداخت قسط عمرانی',
            style:
            TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),
        body:
        _buildContent(),
      ),
    );
  }
}