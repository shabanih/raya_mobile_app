
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_charge_calculation_service.dart';
import 'manager_charge_calculation_items_screen.dart';
import 'manager_charge_calculation_units_screen.dart';

const Color _primaryColor = Color(0xFF00ACC1);
const Color _purpleColor = Color(0xFF610DB5);

class ManagerChargeCalculationScreen extends StatefulWidget {
  /// در صورت نیاز، صفحه انتخاب هزینه‌ها را از بیرون به این صفحه متصل کن.
  final ValueChanged<int>? onOpenItems;

  const ManagerChargeCalculationScreen({
    super.key,
    this.onOpenItems,
  });

  @override
  State<ManagerChargeCalculationScreen> createState() =>
      _ManagerChargeCalculationScreenState();
}

class _ManagerChargeCalculationScreenState
    extends State<ManagerChargeCalculationScreen> {
  final ManagerChargeCalculationService _service =
  ManagerChargeCalculationService();

  final TextEditingController _searchController =
  TextEditingController();

  List<Map<String, dynamic>> _calculations = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCalculations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

// --------------------------------------------------
// ابزارهای کمکی
// --------------------------------------------------

  String _text(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  String _persianDigits(dynamic value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    var result = value?.toString() ?? '';
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  bool _hasAmount(dynamic value) => _parseAmount(_text(value)) > 0;

  int _readCount(dynamic value) {
    if (value == null) return 0;
    final normalized = _normalizeNumber(value.toString())
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .trim();
    return int.tryParse(normalized) ??
        (double.tryParse(normalized)?.toInt() ?? 0);
  }

  int _notifiedUnitsCount(Map<String, dynamic> item) {
    const keys = [
      'notified_units_count',
      'announced_units_count',
      'sent_units_count',
      'units_notified_count',
      'notification_count',
      'notified_count',
      'sent_count',
    ];

    for (final key in keys) {
      if (item[key] != null) {
        return _readCount(item[key]).clamp(0, 1 << 31);
      }
    }
    return 0;
  }

  int _idOf(Map<String, dynamic> item) {
    return int.tryParse(
      _text(item['id'] ?? item['pk']),
    ) ??
        0;
  }

  String _statusLabel(dynamic value) {
    switch (_text(value).toLowerCase()) {
      case 'draft':
        return 'پیش‌نویس';
      case 'calculated':
        return 'محاسبه‌شده';
      case 'finalized':
        return 'نهایی‌شده';
      case 'cancelled':
        return 'لغوشده';
      default:
        return _text(value, fallback: 'نامشخص');
    }
  }

  Color _statusColor(dynamic value) {
    switch (_text(value).toLowerCase()) {
      case 'draft':
        return Colors.blueGrey;
      case 'calculated':
        return _primaryColor;
      case 'finalized':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _formatMoney(dynamic value) {
    final number = num.tryParse(
      _text(value).replaceAll(',', ''),
    ) ??
        0;

    final formatted = number.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < formatted.length; i++) {
      buffer.write(formatted[i]);

      final remaining = formatted.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    return _persianDigits(buffer.toString());
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '—';
    }

    final raw = value.toString().trim();

    try {
      final normalized = raw.replaceAll('/', '-');
      final parts = normalized.split('-');

      if (parts.length >= 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2].split('T').first);

// تاریخ شمسی ذخیره‌شده
        if (year >= 1200 && year <= 1600) {
          return _persianDigits('$year/${month.toString().padLeft(2, '0')}/'
              '${day.toString().padLeft(2, '0')}');
        }

// تاریخ میلادی دریافتی از API
        if (year >= 1900 && year <= 2200) {
          final jalali = Jalali.fromDateTime(
            DateTime(year, month, day),
          );

          return _persianDigits('${jalali.year}/'
              '${jalali.month.toString().padLeft(2, '0')}/'
              '${jalali.day.toString().padLeft(2, '0')}');
        }
      }

      final parsed = DateTime.tryParse(raw);

      if (parsed != null) {
        final jalali = Jalali.fromDateTime(parsed);

        return _persianDigits('${jalali.year}/'
            '${jalali.month.toString().padLeft(2, '0')}/'
            '${jalali.day.toString().padLeft(2, '0')}');
      }
    } catch (_) {}

    return _persianDigits(raw);
  }

  bool _isEditable(Map<String, dynamic> item) {
    // اگر API صراحتاً اجازه یا عدم اجازه را مشخص کرده، همان ملاک است.
    if (item['can_edit'] != null) {
      return item['can_edit'] == true;
    }

    // سازگاری با پاسخ‌های قدیمی API
    return _notifiedUnitsCount(item) == 0 &&
        item['send_notification'] != true &&
        item['is_finalized'] != true;
  }

  bool _isDeletable(Map<String, dynamic> item) {
    if (item['can_delete'] != null) {
      return item['can_delete'] == true;
    }

    return _notifiedUnitsCount(item) == 0 &&
        item['send_notification'] != true &&
        item['is_finalized'] != true;
  }

  List<Map<String, dynamic>> get _filteredCalculations {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return _calculations;

    return _calculations.where((item) {
      final name = _text(item['name']).toLowerCase();
      final status = _statusLabel(item['status']).toLowerCase();

      return name.contains(query) || status.contains(query);
    }).toList();
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.center,
          ),
          backgroundColor: error ? Colors.redAccent : _primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

// --------------------------------------------------
// دریافت محاسبات
// --------------------------------------------------

  Future<void> _loadCalculations() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await _service.getCalculations();

      if (!mounted) return;

      setState(() {
        _calculations = result;
      });
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

// --------------------------------------------------
// تبدیل تاریخ شمسی به میلادی برای API
// --------------------------------------------------

  String _toGregorianDate(Jalali date) {
    final gregorian = date.toGregorian();

    return '${gregorian.year}-'
        '${gregorian.month.toString().padLeft(2, '0')}-'
        '${gregorian.day.toString().padLeft(2, '0')}';
  }

// --------------------------------------------------
// انتخاب تاریخ شمسی
// این انتخابگر به پکیج اضافی نیاز ندارد.
// --------------------------------------------------

  Future<Jalali?> _pickJalaliDate({
    required Jalali initialDate,
    required String title,
  }) async {
    return showDialog<Jalali>(
      context: context,
      builder: (dialogContext) {
        int selectedYear = initialDate.year;
        int selectedMonth = initialDate.month;
        int selectedDay = initialDate.day;

        final currentYear =
            Jalali.fromDateTime(DateTime.now()).year;

        final years = List<int>.generate(
          15,
              (index) => currentYear - 10 + index,
        );

        return StatefulBuilder(
          builder: (context, setDialogState) {
            int daysInMonth(int year, int month) {
              if (month <= 6) return 31;
              if (month <= 11) return 30;
              return Jalali(year, month, 1).isLeapYear() ? 30 : 29;
            }

            final maxDay = daysInMonth(
              selectedYear,
              selectedMonth,
            );

            if (selectedDay > maxDay) {
              selectedDay = maxDay;
            }

            const monthNames = [
              'فروردین',
              'اردیبهشت',
              'خرداد',
              'تیر',
              'مرداد',
              'شهریور',
              'مهر',
              'آبان',
              'آذر',
              'دی',
              'بهمن',
              'اسفند',
            ];

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text(
                  title,
                  textAlign: TextAlign.center,
                ),
                content: SizedBox(
                  width: 340,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'تاریخ شمسی را انتخاب کنید',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<int>(
                            value: selectedYear,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'سال',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                            ),
                            items: years.map((year) {
                              return DropdownMenuItem<int>(
                                value: year,
                                child: Text(_persianDigits(year)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) return;

                              setDialogState(() {
                                selectedYear = value;
                                final newMax = daysInMonth(
                                  selectedYear,
                                  selectedMonth,
                                );

                                if (selectedDay > newMax) {
                                  selectedDay = newMax;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<int>(
                            value: selectedMonth,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'ماه',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                            ),
                            items: List.generate(12, (index) {
                              final month = index + 1;

                              return DropdownMenuItem<int>(
                                value: month,
                                child: Text(monthNames[index]),
                              );
                            }),
                            onChanged: (value) {
                              if (value == null) return;

                              setDialogState(() {
                                selectedMonth = value;
                                final newMax = daysInMonth(
                                  selectedYear,
                                  selectedMonth,
                                );

                                if (selectedDay > newMax) {
                                  selectedDay = newMax;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<int>(
                            value: selectedDay,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'روز',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                            ),
                            items: List.generate(maxDay, (index) {
                              final day = index + 1;

                              return DropdownMenuItem<int>(
                                value: day,
                                child: Text(_persianDigits(day)),
                              );
                            }),
                            onChanged: (value) {
                              if (value == null) return;

                              setDialogState(() {
                                selectedDay = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _persianDigits('$selectedYear/'
                            '${selectedMonth.toString().padLeft(2, '0')}/'
                            '${selectedDay.toString().padLeft(2, '0')}'),
                        style: const TextStyle(
                          color: _purpleColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('انصراف'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                    ),
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
                    child: const Text('تأیید تاریخ'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// --------------------------------------------------
// فرم ایجاد / ویرایش
// --------------------------------------------------

  Future<void> _showCalculationForm({
    Map<String, dynamic>? calculation,
  }) async {
    final isEditing = calculation != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: _text(calculation?['name']),
    );

    final otherCostController = TextEditingController(
      text: _text(
        calculation?['other_cost_amount'],
        fallback: '0',
      ),
    );

    final penaltyController = TextEditingController(
      text: _text(
        calculation?['payment_penalty_amount'],
        fallback: '0',
      ),
    );

    final detailsController = TextEditingController(
      text: _text(calculation?['details']),
    );

    Jalali? startDate = _parseInitialDate(
      calculation?['start_date'],
    );

    Jalali? endDate = _parseInitialDate(
      calculation?['end_date'],
    );

    Jalali? paymentDeadline = _parseInitialDate(
      calculation?['payment_deadline'],
    );

    bool saving = false;
    bool showDateErrors = false;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> chooseStartDate() async {
              final selected = await _pickJalaliDate(
                initialDate: startDate ??
                    Jalali.fromDateTime(DateTime.now()),
                title: 'تاریخ شروع محاسبه',
              );

              if (selected != null) {
                setDialogState(() => startDate = selected);
              }
            }

            Future<void> chooseEndDate() async {
              final selected = await _pickJalaliDate(
                initialDate: endDate ??
                    startDate ??
                    Jalali.fromDateTime(DateTime.now()),
                title: 'تاریخ پایان محاسبه',
              );

              if (selected != null) {
                setDialogState(() => endDate = selected);
              }
            }

            Future<void> choosePaymentDeadline() async {
              final selected = await _pickJalaliDate(
                initialDate: paymentDeadline ??
                    Jalali.fromDateTime(DateTime.now()),
                title: 'مهلت پرداخت',
              );

              if (selected != null) {
                setDialogState(
                      () => paymentDeadline = selected,
                );
              }
            }

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text(
                  isEditing
                      ? 'ویرایش شارژ'
                      : 'ایجاد شارژ',
                  textAlign: TextAlign.center,
                ),
                content: SizedBox(
                  width: 460,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: nameController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'عنوان شارژ *',
                              // hintText: 'مثلاً تسهیم هزینه‌های مهر',
                              prefixIcon: Icon(
                                Icons.receipt_long_outlined,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'عنوان شارژ را وارد کنید.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          _dateField(
                            title: 'تاریخ شروع *',
                            value: startDate == null
                                ? null
                                : _jalaliLabel(startDate!),
                            icon: Icons.event_available,
                            onTap: chooseStartDate,
                            errorText: showDateErrors && startDate == null
                                ? 'تاریخ شروع را انتخاب کنید.'
                                : null,
                          ),

                          const SizedBox(height: 12),

                          _dateField(
                            title: 'تاریخ پایان *',
                            value: endDate == null
                                ? null
                                : _jalaliLabel(endDate!),
                            icon: Icons.event,
                            onTap: chooseEndDate,
                            errorText: showDateErrors && endDate == null
                                ? 'تاریخ پایان را انتخاب کنید.'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          _dateField(
                            title: 'مهلت پرداخت *',
                            value: paymentDeadline == null
                                ? null
                                : _jalaliLabel(paymentDeadline!),
                            icon: Icons.payments_outlined,
                            onTap: choosePaymentDeadline,
                            errorText: showDateErrors && paymentDeadline == null
                                ? 'مهلت پرداخت را انتخاب کنید.'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: otherCostController,
                            keyboardType:
                            const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'هزینه اضافی هر واحد',
                              helperText:
                              'این مبلغ برای هر واحد در نظر گرفته می‌شود.',
                              prefixIcon: Icon(
                                Icons.add_card_outlined,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            validator: _validateNonNegativeNumber,
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: penaltyController,
                            keyboardType:
                            const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: ' جریمه دیرکرد به درصد',
                              prefixIcon: Icon(
                                Icons.money_off_csred_outlined,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            validator: _validateNonNegativeNumber,
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: detailsController,
                            minLines: 2,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              labelText: 'توضیحات',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(
                                Icons.notes_outlined,
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('انصراف'),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryColor,
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      if (startDate == null || endDate == null) {
                        _showMessage(
                          'تاریخ شروع و پایان را انتخاب کنید.',
                          error: true,
                        );
                        return;
                      }

                      if (_compareJalali(endDate!, startDate!) < 0) {
                        _showMessage(
                          'تاریخ پایان نباید قبل از تاریخ شروع باشد.',
                          error: true,
                        );
                        return;
                      }

                      setDialogState(() => saving = true);

                      String? errorMessage;
                      bool succeeded = false;

                      try {
                        final name = nameController.text.trim();
                        final otherCost = _parseAmount(otherCostController.text);
                        final penalty = _parseAmount(penaltyController.text);
                        final details = detailsController.text.trim();

                        if (isEditing) {
                          await _service.updateCalculation(
                            _idOf(calculation),
                            name: name,
                            startDate: _toGregorianDate(startDate!),
                            endDate: _toGregorianDate(endDate!),
                            otherCostAmount: otherCost,
                            paymentDeadline: paymentDeadline == null
                                ? null
                                : _toGregorianDate(paymentDeadline!),
                            paymentPenaltyAmount: penalty,
                            details: details,
                          );
                        } else {
                          await _service.createCalculation(
                            name: name,
                            startDate: _toGregorianDate(startDate!),
                            endDate: _toGregorianDate(endDate!),
                            otherCostAmount: otherCost,
                            paymentDeadline: paymentDeadline == null
                                ? null
                                : _toGregorianDate(paymentDeadline!),
                            paymentPenaltyAmount: penalty,
                            details: details,
                          );
                        }

                        succeeded = true;
                      } catch (e) {
                        errorMessage = e.toString().replaceFirst('Exception: ', '');
                      }

                      // اگر دیالوگ بسته شده باشد، دیگر setDialogState را صدا نمی‌زنیم.
                      if (dialogContext.mounted) {
                        setDialogState(() => saving = false);
                      }

                      if (!dialogContext.mounted) return;

                      if (!succeeded) {
                        _showMessage(
                          errorMessage ?? 'ذخیره اطلاعات ناموفق بود.',
                          error: true,
                        );
                        return;
                      }

                      // نتیجه را به صفحه اصلی برگردان؛ بعد از خروج کامل دیالوگ،
                      // پیام و بارگذاری مجدد در context صفحه اصلی انجام می‌شود.
                      Navigator.pop(dialogContext, true);
                    },
                    icon: saving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      saving ? 'در حال ذخیره...' : 'ذخیره',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

// showDialog پیش از پایان انیمیشن خروج برمی‌گردد؛ کنترلرها را
// تا پایان انیمیشن زنده نگه می‌داریم تا TextField هنوز از آن‌ها استفاده نکند.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    nameController.dispose();
    otherCostController.dispose();
    penaltyController.dispose();
    detailsController.dispose();

    if (saved == true && mounted) {
      _showMessage(
        isEditing
            ? 'شارژ با موفقیت ویرایش شد.'
            : 'شارژ جدید ایجاد شد.',
      );
      await _loadCalculations();
    }
  }

  Jalali? _parseInitialDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }

    final raw = value.toString().trim().replaceAll('/', '-');
    final parts = raw.split('-');

    try {
      if (parts.length >= 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2].split('T').first);

        if (year >= 1200 && year <= 1600) {
          return Jalali(year, month, day);
        }

        if (year >= 1900 && year <= 2200) {
          return Jalali.fromDateTime(
            DateTime(year, month, day),
          );
        }
      }

      final parsed = DateTime.tryParse(raw);

      if (parsed != null) {
        return Jalali.fromDateTime(parsed);
      }
    } catch (_) {}

    return null;
  }

  String? _validateNonNegativeNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final amount = _parseAmount(value);

    if (amount < 0) {
      return 'مبلغ نمی‌تواند منفی باشد.';
    }

    if (double.tryParse(
      _normalizeNumber(value).replaceAll(',', ''),
    ) ==
        null) {
      return 'مبلغ واردشده معتبر نیست.';
    }

    return null;
  }

  String _normalizeNumber(String value) {
    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';

    var result = value.trim();

    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(
        persianDigits[i],
        '$i',
      );

      result = result.replaceAll(
        arabicDigits[i],
        '$i',
      );
    }

    return result;
  }

  double _parseAmount(String value) {
    final normalized = _normalizeNumber(value)
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('٫', '.');

    return double.tryParse(normalized) ?? 0;
  }

  String _jalaliLabel(Jalali date) {
    return _persianDigits('${date.year}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}');
  }

  int _compareJalali(Jalali a, Jalali b) {
    final aValue = a.year * 10000 + a.month * 100 + a.day;
    final bValue = b.year * 10000 + b.month * 100 + b.day;

    return aValue.compareTo(bValue);
  }

  Widget _dateField({
    required String title,
    required String? value,
    required IconData icon,
    required VoidCallback onTap,
    String? errorText,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: title,
          prefixIcon: Icon(icon, color: _purpleColor),
          suffixIcon: const Icon(Icons.calendar_month),
          border: const OutlineInputBorder(),
          errorText: errorText,
        ),
        child: Text(
          value ?? 'انتخاب تاریخ',
          style: TextStyle(
            color: value == null ? Colors.grey : Colors.black87,
          ),
        ),
      ),
    );
  }
// --------------------------------------------------
// حذف محاسبه
// --------------------------------------------------

  Future<void> _confirmDelete(
      Map<String, dynamic> calculation,
      ) async {
    final id = _idOf(calculation);

    if (id <= 0) {
      _showMessage(
        'شناسه شارژ معتبر نیست.',
        error: true,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'حذف شارژ',
          textAlign: TextAlign.center,
        ),
        content: Text(
          'آیا از حذف شارژ «'
              '${_text(calculation['name'], fallback: 'بدون عنوان')}'
              '» مطمئن هستید؟',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteCalculation(id);

      _showMessage('شارژ حذف شد.');

      await _loadCalculations();
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

// --------------------------------------------------
// ورود به انتخاب هزینه‌ها
// --------------------------------------------------

  Future<void> _openItems(
      Map<String, dynamic> calculation,
      ) async {
    final id = _idOf(calculation);

    if (id <= 0) {
      _showMessage(
        'شناسه شارژ معتبر نیست.',
        error: true,
      );
      return;
    }

    final name = _text(calculation['name']);
    final status = _text(calculation['status']).toLowerCase();

    if (status == 'finalized') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ManagerChargeCalculationUnitsScreen(
            calculationId: id,
            calculationName: name,
          ),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ManagerChargeCalculationItemsScreen(
            calculationId: id,
            calculationName: name,
          ),
        ),
      );
    }

    // پس از بازگشت، وضعیت جدید شارژ را از سرور دریافت کن.
    if (!mounted) return;

    await _loadCalculations();
  }

// --------------------------------------------------
// کارت محاسبه
// --------------------------------------------------

  Widget _buildCalculationCard(
      Map<String, dynamic> item,
      ) {
    final status = item['status'];
    final editable = _isEditable(item);
    final deletable = _isDeletable(item);

    final isFinalized =
        _text(item['status']).toLowerCase() == 'finalized';

    final startDate = _formatDate(item['start_date']);
    final endDate = _formatDate(item['end_date']);

    final countValue = item['total_unit_count'] ??
        item['house_unit_count'] ??
        item['total_units'] ??
        item['units_count'] ??
        item['allocation_count'];

    final count = countValue == null
        ? null
        : _readCount(countValue);

    final notifiedCount = _notifiedUnitsCount(item);

    final amount = item['total_amount'] ??
        item['total_cost'] ??
        item['total_calculated_amount'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: _primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: InkWell(
        onTap: () => _openItems(item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calculate_outlined,
                      color: _primaryColor,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _persianDigits(_text(
                            item['name'],
                            fallback: 'شارژ بدون عنوان',
                          )),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          crossAxisAlignment:
                          WrapCrossAlignment.center,
                          children: [
                            _statusChip(status),
                            if (_idOf(item) > 0)
                              Text(
                                'شناسه: ${_persianDigits(_idOf(item))}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'عملیات',
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showCalculationForm(
                          calculation: item,
                        );
                      } else if (value == 'delete') {
                        _confirmDelete(item);
                      }
                    },
                    itemBuilder: (context) => [
                      if (editable)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: _purpleColor,
                              ),
                              SizedBox(width: 8),
                              Text('ویرایش'),
                            ],
                          ),
                        ),
                      if (deletable)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              SizedBox(width: 8),
                              Text('حذف'),
                            ],
                          ),
                        ),
                      if (!editable && !deletable)
                        const PopupMenuItem(
                          enabled: false,
                          child: Text('این شارژ قابل ویرایش نیست'),
                        ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              _infoRow(
                Icons.date_range_outlined,
                'بازه محاسبه',
                '$startDate تا $endDate',
              ),
              const SizedBox(height: 9),
              _infoRow(
                Icons.event_available_outlined,
                'مهلت پرداخت',
                _formatDate(item['payment_deadline']),
              ),
              if (_text(item['created_at'] ?? item['created'] ?? item['created_date']).isNotEmpty) ...[
                const SizedBox(height: 9),
                _infoRow(
                  Icons.history_outlined,
                  'تاریخ ثبت',
                  _formatDate(item['created_at'] ?? item['created'] ?? item['created_date']),
                ),
              ],
              if (_hasAmount(item['payment_penalty_amount'] ?? item['payment_penalty'])) ...[
                const SizedBox(height: 9),
                _infoRow(
                  Icons.money_off_csred_outlined,
                  'جریمه دیرکرد',
                  '${_formatMoney(item['payment_penalty_amount'] ?? item['payment_penalty'])} %',
                ),
              ],
              if (_hasAmount(item['other_cost_amount'] ?? item['other_cost'])) ...[
                const SizedBox(height: 9),
                _infoRow(
                  Icons.add_card_outlined,
                  'هزینه متفرقه',
                  '${_formatMoney(item['other_cost_amount'] ?? item['other_cost'])} تومان',
                ),
              ],
              if (count != null) ...[
                const SizedBox(height: 9),
                _infoRow(
                  Icons.notifications_active_outlined,
                  'اعلان شارژ به واحدها',
                  '${_persianDigits(notifiedCount)} از '
                      '${_persianDigits(count)} واحد',
                ),
              ],
              if (amount != null) ...[
                const SizedBox(height: 9),
                _infoRow(
                  Icons.payments_outlined,
                  'مجموع هزینه',
                  '${_formatMoney(amount)} تومان',
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                    isFinalized ? Colors.purple : _purpleColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _openItems(item),
                  icon: Icon(
                    isFinalized
                        ? Icons.notifications_active_outlined
                        : Icons.list_alt_outlined,
                    size: 20,
                  ),
                  label: Text(
                    isFinalized
                        ? 'مشاهده اعلان واحدها'
                        : 'مشاهده و انتخاب هزینه‌ها',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(dynamic status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: _primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          '$title: ',
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

// --------------------------------------------------
// رابط رابط؟ نه؛ بخش بالای صفحه
// --------------------------------------------------

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryColor,
            _purpleColor,
          ],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.all(
          Radius.circular(16),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate_outlined,
                color: Colors.white,
                size: 34,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  ' شارژ تسهیم هزینه',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'هزینه‌های ساختمان را در یک بازه زمانی جمع‌آوری کن '
                'و سهم هر واحد را بر اساس تعداد نفرات، متراژ یا '
                'تقسیم مساوی محاسبه کن.',
            style: TextStyle(
              color: Colors.white,
              height: 1.8,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 50,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 70,
              color: _primaryColor.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 16),
            const Text(
              'هنوز شارژی ثبت نشده است',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'برای شروع، یک شارژ جدید ایجاد کن و سپس '
                  'هزینه‌های موردنظر را انتخاب کن.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _primaryColor,
              ),
              onPressed: () => _showCalculationForm(),
              icon: const Icon(Icons.add),
              label: const Text('ایجاد شارژ جدید'),
            ),
          ],
        ),
      ),
    );
  }

// --------------------------------------------------
// صفحه اصلی
// --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final calculations = _filteredCalculations;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FA),
        appBar: AppBar(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'شارژ تسهیم هزینه',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'بارگذاری مجدد',
              onPressed: _isLoading ? null : _loadCalculations,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          onPressed: () => _showCalculationForm(),
          icon: const Icon(Icons.add),
          label: const Text('شارژ جدید'),
        ),
        body: RefreshIndicator(
          onRefresh: _loadCalculations,
          color: _primaryColor,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: 'جستجو بر اساس عنوان یا وضعیت...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: _primaryColor,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    icon: const Icon(Icons.close),
                  )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'فهرست شارژها',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${calculations.length} مورد',
                    style: const TextStyle(
                      color: _purpleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isLoading && _calculations.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: _primaryColor,
                    ),
                  ),
                )
              else if (_calculations.isEmpty)
                _buildEmptyState()
              else if (calculations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'موردی با این عبارت پیدا نشد.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  )
                else
                  ...calculations.map(_buildCalculationCard),
            ],
          ),
        ),
      ),
    );
  }
}

