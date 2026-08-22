import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../services/api_service.dart';

class AddUserPaymentScreen extends StatefulWidget {
  const AddUserPaymentScreen({super.key});

  @override
  State<AddUserPaymentScreen> createState() =>
      _AddUserPaymentScreenState();
}

class _AddUserPaymentScreenState
    extends State<AddUserPaymentScreen> {

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

  // =====================================================
  // API
  // =====================================================

  final ApiService _apiService = ApiService();

  // =====================================================
  // Controllers
  // =====================================================

  final TextEditingController amountController =
  TextEditingController();

  final TextEditingController descriptionController =
  TextEditingController();

  final TextEditingController detailsController =
  TextEditingController();

  final TextEditingController payerNameController =
  TextEditingController();

  // =====================================================
  // State
  // =====================================================

  Jalali? selectedDate;

  bool isSubmitting = false;

  // =====================================================
  // Dispose
  // =====================================================

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    detailsController.dispose();
    payerNameController.dispose();

    super.dispose();
  }

  // =====================================================
  // Persian digits
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
  // Persian -> English digits
  // =====================================================

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

  // =====================================================
  // Format amount
  // =====================================================

  String formatAmount(String value) {
    value = toEnglishDigits(value);

    value = value
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll(' ', '')
        .trim();

    if (value.isEmpty) {
      return '';
    }

    final number = int.tryParse(value);

    if (number == null) {
      return '';
    }

    final text = number.toString();

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

  // =====================================================
  // Format Jalali date
  // =====================================================

  String formatJalaliDate(Jalali date) {
    return toPersianDigits(
      '${date.year}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.day.toString().padLeft(2, '0')}',
    );
  }

  // =====================================================
  // Select Jalali date
  // =====================================================

  Future<void> selectDate() async {
    final now = Jalali.now();

    final initialDate =
        selectedDate ?? now;

    int selectedYear =
        initialDate.year;

    int selectedMonth =
        initialDate.month;

    int selectedDay =
        initialDate.day;

    final result = await showDialog<Jalali>(
      context: context,
      builder: (dialogContext) {
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

            if (selectedDay > daysInMonth) {
              selectedDay =
                  daysInMonth;
            }

            return Directionality(
              textDirection:
              TextDirection.rtl,
              child: AlertDialog(
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),

                title: const Text(
                  'انتخاب تاریخ ',
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

                      // ===================================
                      // سال
                      // ===================================

                      DropdownButtonFormField<int>(
                        value:
                        selectedYear,

                        decoration:
                        InputDecoration(
                          labelText:
                          'سال',
                          filled: true,
                          fillColor:
                          backgroundColor,
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
                                now.year -
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

                              if (selectedDay >
                                  maxDay) {
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

                      // ===================================
                      // ماه
                      // ===================================

                      DropdownButtonFormField<int>(
                        value:
                        selectedMonth,

                        decoration:
                        InputDecoration(
                          labelText:
                          'ماه',
                          filled: true,
                          fillColor:
                          backgroundColor,
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
                          if (value ==
                              null) {
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

                              if (selectedDay >
                                  maxDay) {
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

                      // ===================================
                      // روز
                      // ===================================

                      DropdownButtonFormField<int>(
                        value:
                        selectedDay,

                        decoration:
                        InputDecoration(
                          labelText:
                          'روز',
                          filled: true,
                          fillColor:
                          backgroundColor,
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

                          setDialogState(
                                () {
                              selectedDay =
                                  value;
                            },
                          );
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ===================================
                      // تاریخ انتخاب شده
                      // ===================================

                      Container(
                        width:
                        double.infinity,
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          primaryColor
                              .withOpacity(
                            0.08,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: Row(
                          children: [

                            const Icon(
                              Icons
                                  .calendar_month,
                              color:
                              primaryColor,
                              size: 20,
                            ),

                            const SizedBox(
                              width: 8,
                            ),

                            Expanded(
                              child:
                              Text(
                                'تاریخ انتخاب شده: '
                                    '${toPersianDigits(selectedYear.toString())}/'
                                    '${toPersianDigits(selectedMonth.toString().padLeft(2, '0'))}/'
                                    '${toPersianDigits(selectedDay.toString().padLeft(2, '0'))}',
                                style:
                                const TextStyle(
                                  fontSize:
                                  13,
                                  color:
                                  primaryColor,
                                  fontWeight:
                                  FontWeight
                                      .bold,
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
                const EdgeInsets
                    .fromLTRB(
                  16,
                  0,
                  16,
                  12,
                ),

                actions: [

                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
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
                        dialogContext,
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
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                    child:
                    const Text(
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

    if (result != null &&
        mounted) {
      setState(() {
        selectedDate =
            result;
      });
    }
  }

  // =====================================================
  // Submit
  // =====================================================

  Future<void> submitPayment() async {
    FocusScope.of(context).unfocus();

    // ===================================================
    // Amount
    // ===================================================

    final amountText =
    toEnglishDigits(
      amountController.text
          .replaceAll(',', '')
          .replaceAll('٬', '')
          .trim(),
    );

    if (amountText.isEmpty) {
      _showMessage(
        'لطفاً مبلغ را وارد کنید.',
      );
      return;
    }

    final amount =
    int.tryParse(
      amountText,
    );

    if (amount == null ||
        amount <= 0) {
      _showMessage(
        'مبلغ  واردشده صحیح نیست.',
      );
      return;
    }

    // ===================================================
    // Description
    // ===================================================

    final description =
    descriptionController.text.trim();

    if (description.isEmpty) {
      _showMessage(
        'لطفاً شرح  را وارد کنید.',
      );
      return;
    }

    // ===================================================
    // Date
    // ===================================================

    if (selectedDate == null) {
      _showMessage(
        'لطفاً تاریخ  را انتخاب کنید.',
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

      // =================================================
      // Jalali -> Gregorian
      // =================================================

      final gregorian =
      selectedDate!.toDateTime();

      final registerDate =
          '${gregorian.year}-'
          '${gregorian.month.toString().padLeft(2, '0')}-'
          '${gregorian.day.toString().padLeft(2, '0')}';

      // =================================================
      // API
      // =================================================

      final result =
      await _apiService.createUserPayment(
        amount: amount,
        description:
        description,
        registerDate:
        registerDate,

        details:
        detailsController.text
            .trim()
            .isEmpty
            ? null
            : detailsController.text
            .trim(),

        payerName:
        payerNameController.text
            .trim()
            .isEmpty
            ? null
            : payerNameController.text
            .trim(),
      );

      if (!mounted) {
        return;
      }

      if (result['success'] ==
          true) {

        await showDialog(
          context: context,
          barrierDismissible:
          false,
          builder: (_) {
            return Directionality(
              textDirection:
              TextDirection.rtl,
              child:
              AlertDialog(
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),

                title:
                const Row(
                  children: [

                    Icon(
                      Icons
                          .check_circle,
                      color:
                      Colors.green,
                      size: 28,
                    ),

                    SizedBox(
                      width: 8,
                    ),

                    Text(
                      'کمک ثبت شد',
                      style:
                      TextStyle(
                        fontSize:
                        17,
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),
                  ],
                ),

                content:
                const Text(
                  'کمک شما با موفقیت ثبت شد.',
                  style:
                  TextStyle(
                    fontSize: 13,
                    height: 1.8,
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
                      'باشه',
                    ),
                  ),
                ],
              ),
            );
          },
        );

        if (!mounted) {
          return;
        }

        Navigator.pop(
          context,
          true,
        );

        return;
      }

      _showMessage(
        result['message']
            ?.toString() ??
            'ثبت کمک انجام نشد.',
      );

    } catch (e) {

      if (!mounted) {
        return;
      }

      _showMessage(
        e.toString()
            .replaceFirst(
          'Exception: ',
          '',
        ),
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

  // =====================================================
  // Message
  // =====================================================

  void _showMessage(
      String message) {

    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        behavior:
        SnackBarBehavior.floating,

        content: Text(
          message,
          textDirection:
          TextDirection.rtl,
        ),

        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
        ),
      ),
    );
  }

  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(
      BuildContext context) {

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
          surfaceTintColor:
          Colors.transparent,

          iconTheme:
          const IconThemeData(
            color: textColor,
          ),

          title:
          const Text(
            'ثبت کمک به ساختمان',
            style:
            TextStyle(
              color:
              textColor,
              fontSize:
              18,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),

        // =================================================
        // Body
        // =================================================

        body:
        ListView(
          padding:
          const EdgeInsets
              .fromLTRB(
            18,
            10,
            18,
            30,
          ),

          children: [

            // =================================================
            // Header
            // =================================================

            _buildHeader(),

            const SizedBox(
              height: 22,
            ),

            // =================================================
            // مبلغ
            // =================================================

            const Text(
              'مبلغ ',
              style:
              TextStyle(
                fontSize: 14,
                fontWeight:
                FontWeight.bold,
                color:
                textColor,
              ),
            ),

            const SizedBox(
              height: 9,
            ),

            TextField(
              controller:
              amountController,

              keyboardType:
              TextInputType.number,

              textDirection:
              TextDirection.rtl,

              textAlign:
              TextAlign.right,

              onChanged:
                  (value) {

                final formatted =
                formatAmount(
                  value,
                );

                if (formatted !=
                    value) {

                  amountController
                      .value =
                      TextEditingValue(
                        text:
                        formatted,
                        selection:
                        TextSelection
                            .collapsed(
                          offset:
                          formatted
                              .length,
                        ),
                      );
                }
              },

              decoration:
              InputDecoration(
                hintText:
                '',

                hintTextDirection:
                TextDirection.rtl,

                suffixText:
                'تومان',

                prefixIcon:
                const Icon(
                  Icons
                      .payments_outlined,
                  color:
                  primaryColor,
                ),

                filled: true,
                fillColor:
                Colors.white,

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                  borderSide:
                  BorderSide.none,
                ),

                enabledBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                  borderSide:
                  BorderSide.none,
                ),

                focusedBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
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

            const SizedBox(
              height: 20,
            ),

            // =================================================
            // شرح
            // =================================================

            const Text(
              'شرح ',
              style:
              TextStyle(
                fontSize: 14,
                fontWeight:
                FontWeight.bold,
                color:
                textColor,
              ),
            ),

            const SizedBox(
              height: 9,
            ),

            TextField(
              controller:
              descriptionController,

              maxLines: 3,
              minLines: 3,

              keyboardType:
              TextInputType.multiline,

              textDirection:
              TextDirection.rtl,

              textAlign:
              TextAlign.right,

              textInputAction:
              TextInputAction.newline,

              decoration:
              InputDecoration(
                hintText:
                '',

                hintTextDirection:
                TextDirection.rtl,

                alignLabelWithHint:
                true,

                prefixIcon:
                const Padding(
                  padding:
                  EdgeInsets.only(
                    bottom: 42,
                  ),
                  child:
                  Icon(
                    Icons
                        .description_outlined,
                    color:
                    primaryColor,
                  ),
                ),

                filled: true,
                fillColor:
                Colors.white,

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                  borderSide:
                  BorderSide.none,
                ),

                enabledBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                  borderSide:
                  BorderSide.none,
                ),

                focusedBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
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

            const SizedBox(
              height: 20,
            ),

            // =================================================
            // تاریخ
            // =================================================

            const Text(
              'تاریخ ',
              style:
              TextStyle(
                fontSize: 14,
                fontWeight:
                FontWeight.bold,
                color:
                textColor,
              ),
            ),

            const SizedBox(
              height: 9,
            ),

            InkWell(
              onTap:
              selectDate,

              borderRadius:
              BorderRadius.circular(
                15,
              ),

              child:
              Container(
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
                    15,
                  ),

                  border:
                  Border.all(
                    color:
                    selectedDate ==
                        null
                        ? Colors
                        .transparent
                        : primaryColor
                        .withOpacity(
                      0.25,
                    ),
                  ),
                ),

                child:
                Row(
                  children: [

                    const Icon(
                      Icons
                          .calendar_month_outlined,
                      color:
                      primaryColor,
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child:
                      Text(
                        selectedDate ==
                            null
                            ? 'انتخاب تاریخ '
                            : formatJalaliDate(
                          selectedDate!,
                        ),

                        textDirection:
                        TextDirection.rtl,

                        style:
                        TextStyle(
                          color:
                          selectedDate ==
                              null
                              ? Colors
                              .grey
                              : textColor,

                          fontSize:
                          14,

                          fontWeight:
                          selectedDate ==
                              null
                              ? FontWeight
                              .normal
                              : FontWeight
                              .bold,
                        ),
                      ),
                    ),

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
              height: 20,
            ),

            // =================================================
            // توضیحات تکمیلی
            // =================================================

            const Text(
              'توضیحات تکمیلی',
              style:
              TextStyle(
                fontSize: 14,
                fontWeight:
                FontWeight.bold,
                color:
                textColor,
              ),
            ),

            const SizedBox(
              height: 9,
            ),

            TextField(
              controller:
              detailsController,

              maxLines: 3,
              minLines: 3,

              keyboardType:
              TextInputType.multiline,

              textDirection:
              TextDirection.rtl,

              textAlign:
              TextAlign.right,

              textInputAction:
              TextInputAction.newline,

              decoration:
              InputDecoration(
                hintText:
                'در صورت نیاز توضیحات بیشتری وارد کنید',

                hintTextDirection:
                TextDirection.rtl,

                alignLabelWithHint:
                true,

                prefixIcon:
                const Padding(
                  padding:
                  EdgeInsets.only(
                    bottom: 42,
                  ),
                  child:
                  Icon(
                    Icons.notes_outlined,
                    color:
                    primaryColor,
                  ),
                ),

                filled: true,
                fillColor:
                Colors.white,

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                  borderSide:
                  BorderSide.none,
                ),

                enabledBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                  borderSide:
                  BorderSide.none,
                ),

                focusedBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
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

            const SizedBox(
              height: 20,
            ),

            // =================================================
            // نام پرداخت کننده
            // =================================================

            const Text(
              'نام پرداخت‌ کننده',
              style:
              TextStyle(
                fontSize: 14,
                fontWeight:
                FontWeight.bold,
                color:
                textColor,
              ),
            ),

            const SizedBox(
              height: 9,
            ),

            TextField(
              controller:
              payerNameController,

              keyboardType:
              TextInputType.name,

              textDirection:
              TextDirection.rtl,

              textAlign:
              TextAlign.right,

              textInputAction:
              TextInputAction.done,

              decoration:
              InputDecoration(
                hintText:
                'در صورت نیاز نام پرداخت‌ کننده را وارد کنید',

                hintTextDirection:
                TextDirection.rtl,

                prefixIcon:
                const Icon(
                  Icons.person_outline,
                  color:
                  primaryColor,
                ),

                filled: true,
                fillColor:
                Colors.white,

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                  borderSide:
                  BorderSide.none,
                ),

                enabledBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
                  ),
                  borderSide:
                  BorderSide.none,
                ),

                focusedBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    15,
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

            const SizedBox(
              height: 30,
            ),

            // =================================================
            // Submit
            // =================================================

            SizedBox(
              height: 54,

              child:
              ElevatedButton.icon(
                onPressed:
                isSubmitting
                    ? null
                    : submitPayment,

                icon:
                isSubmitting
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                    Colors.white,
                  ),
                )
                    : const Icon(
                  Icons
                      .volunteer_activism_outlined,
                ),

                label:
                Text(
                  isSubmitting
                      ? 'در حال ثبت...'
                      : 'ثبت کمک',

                  style:
                  const TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                style:
                ElevatedButton
                    .styleFrom(
                  backgroundColor:
                  cyanColor,

                  foregroundColor:
                  Colors.white,

                  disabledBackgroundColor:
                  primaryColor
                      .withOpacity(
                    0.55,
                  ),

                  elevation: 0,

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      17,
                    ),
                  ),
                ),
              ),
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
      padding:
      const EdgeInsets.all(18),

      decoration:
      BoxDecoration(
        gradient:
        const LinearGradient(
          colors: [
            Color(0xff7541B5),
            Color(0xff5B2298),
          ],

          begin:
          Alignment.topRight,

          end:
          Alignment.bottomLeft,
        ),

        borderRadius:
        BorderRadius.circular(
          22,
        ),

        boxShadow: [
          BoxShadow(
            color:
            primaryColor
                .withOpacity(
              0.20,
            ),

            blurRadius:
            15,

            offset:
            const Offset(
              0,
              6,
            ),
          ),
        ],
      ),

      child:
      Row(
        textDirection:
        TextDirection.rtl,

        children: [

          Container(
            width: 54,
            height: 54,

            decoration:
            BoxDecoration(
              color:
              Colors.white
                  .withOpacity(
                0.15,
              ),

              shape:
              BoxShape.circle,
            ),

            child:
            const Icon(
              Icons
                  .volunteer_activism_outlined,

              color:
              Colors.white,

              size: 29,
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          const Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  'کمک به ساختمان',

                  style:
                  TextStyle(
                    color:
                    Colors.white,

                    fontSize:
                    18,

                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                SizedBox(
                  height: 5,
                ),

                Text(
                  'مشارکت مالی در هزینه‌های ساختمان',

                  style:
                  TextStyle(
                    color:
                    Colors.white70,

                    fontSize:
                    11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}