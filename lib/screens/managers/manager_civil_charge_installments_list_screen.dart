
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_civil_charge_list_service.dart';

class ManagerCivilChargeInstallmentsListScreen extends StatefulWidget {
  const ManagerCivilChargeInstallmentsListScreen({
    super.key,
    required this.civilId,
    required this.unitId,
    required this.unitName,
    this.ownerName = '',
    this.civilName = '',
  });

  final int civilId;
  final int unitId;
  final String unitName;
  final String ownerName;
  final String civilName;

  @override
  State<ManagerCivilChargeInstallmentsListScreen> createState() =>
      _ManagerCivilChargeInstallmentsListScreenState();
}

class _ManagerCivilChargeInstallmentsListScreenState
    extends State<ManagerCivilChargeInstallmentsListScreen> {
  static const Color teal = Color(0xFF00ACC1);
  static const Color purple = Color(0xFF610DB5);

  final ManagerCivilChargeListService _service =
  ManagerCivilChargeListService();

  List<Map<String, dynamic>> _installments = [];
  bool _loading = true;
  String? _error;
  int _paidCount = 0;
  int _unpaidCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInstallments();
  }

  String _fa(dynamic value) {
    const en = '0123456789';
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';

    return value.toString().replaceAllMapped(
      RegExp(r'[0-9٠-٩]'),
          (match) {
        final char = match.group(0)!;
        final i = en.indexOf(char);
        if (i >= 0) return fa[i];

        final j = ar.indexOf(char);
        return j >= 0 ? fa[j] : char;
      },
    );
  }

  int _number(dynamic value) {
    if (value is num) return value.toInt();

    var text = value?.toString().trim() ?? '';
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';

    for (var i = 0; i < 10; i++) {
      text = text.replaceAll(fa[i], '$i');
      text = text.replaceAll(ar[i], '$i');
    }

    return int.tryParse(
      text.replaceAll(',', '').replaceAll('٬', ''),
    ) ??
        0;
  }

  bool _bool(dynamic value) =>
      value == true ||
          value == 1 ||
          value.toString().toLowerCase() == 'true';

  String _money(dynamic value) {
    return _fa(
      _number(value).toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (match) => '٬',
      ),
    );
  }

  String _dateLabel(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'ثبت نشده';
    }

    final raw = value.toString().trim();
    final parsed = DateTime.tryParse(raw);

    if (parsed == null) return _fa(raw);

    final jalali = Jalali.fromDateTime(parsed);

    return _fa(
      '${jalali.year}/'
          '${jalali.month.toString().padLeft(2, '0')}/'
          '${jalali.day.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _loadInstallments({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final data = await _service.getInstallments(
        civilId: widget.civilId,
        unitId: widget.unitId,
      );

      if (!mounted) return;

      setState(() {
        _installments = data;
        _paidCount =
            data.where((item) => _bool(item['is_paid'])).length;
        _unpaidCount =
            data.where((item) => !_bool(item['is_paid'])).length;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _payInstallment(
      Map<String, dynamic> installment,
      ) async {
    if (_loading) return;

    final installmentId = _number(installment['id']);

    if (installmentId <= 0) {
      _message('شناسه قسط معتبر نیست.', isError: true);
      return;
    }

    try {
      final banks = await _service.getPaymentBanks(
        installmentId: installmentId,
      );

      if (!mounted) return;

      if (banks.isEmpty) {
        _message(
          'برای این ساختمان حساب بانکی فعالی ثبت نشده است.',
          isError: true,
        );
        return;
      }

      final form = await _showPaymentDialog(
        installment: installment,
        banks: banks,
      );

      if (!mounted || form == null) return;

      final bankId = _number(form['bank_id']);
      final paymentDate = form['payment_date']?.toString() ?? '';
      final reference =
      (form['transaction_reference'] ?? '').toString().trim();

      if (bankId <= 0) {
        _message('حساب بانکی معتبر انتخاب کنید.', isError: true);
        return;
      }

      if (paymentDate.isEmpty) {
        _message('تاریخ پرداخت معتبر نیست.', isError: true);
        return;
      }

      setState(() {
        _loading = true;
        _error = null;
      });

      final result = await _service.payInstallment(
        installmentId: installmentId,
        bankId: bankId,
        paymentDate: paymentDate,
        transactionReference: reference.isEmpty ? null : reference,
      );

      if (!mounted) return;

      _message(
        result['message']?.toString() ?? 'پرداخت با موفقیت ثبت شد.',
      );

      await _loadInstallments(showLoader: false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _message(
        'خطا: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    }
  }
  Future<void> _cancelInstallmentPayment(
      Map<String, dynamic> installment,
      ) async {
    if (_loading) return;

    final installmentId = _number(installment['id']);

    if (installmentId <= 0) {
      _message('شناسه قسط معتبر نیست.', isError: true);
      return;
    }

    final installmentNumber = _number(
      installment['installment_number'],
    );

    final title = installmentNumber == 0
        ? 'پیش‌پرداخت'
        : 'قسط شماره ${_fa(installmentNumber)}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text(
            'لغو پرداخت قسط',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'آیا از لغو پرداخت $title به مبلغ '
                '${_money(installment['amount'])} تومان مطمئن هستید؟\n\n'
                'سند مالی مرتبط نیز اصلاح خواهد شد.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('تأیید لغو پرداخت'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.cancelPayment(
        installmentId: installmentId,
      );

      if (!mounted) return;

      _message(
        result['message']?.toString() ??
            'پرداخت قسط با موفقیت لغو شد.',
      );

      // دریافت مجدد وضعیت اقساط و محاسبه مجدد آمار صفحه
      await _loadInstallments(showLoader: false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _message(
        'خطا در لغو پرداخت: '
            '${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    }
  }
  Future<Map<String, dynamic>?> _showPaymentDialog({
    required Map<String, dynamic> installment,
    required List<Map<String, dynamic>> banks,
  }) async {
    final referenceController = TextEditingController();

    int? selectedBankId;
    Jalali selectedDate = Jalali.now();

    for (final bank in banks) {
      if (_bool(bank['is_default'])) {
        selectedBankId = _number(bank['id']);
        break;
      }
    }

    selectedBankId ??= _number(banks.first['id']);

    Map<String, dynamic>? result;

    try {
      result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  title: const Text(
                    'ثبت پرداخت قسط',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _number(installment['installment_number']) == 0
                              ? 'پیش‌پرداخت'
                              : 'قسط شماره ${_fa(installment['installment_number'] ?? '—')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'مبلغ: ${_money(installment['amount'])} تومان',
                        ),
                        const SizedBox(height: 18),
                        const Text('حساب بانکی'),
                        const SizedBox(height: 7),
                        DropdownButtonFormField<int>(
                          value: selectedBankId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                          ),
                          items: banks.map((bank) {
                            final id = _number(bank['id']);
                            final name =
                                bank['bank_name']?.toString() ?? 'حساب $id';
                            final account =
                                bank['account_no']?.toString().trim() ?? '';

                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(
                                account.isEmpty ? name : '$name - $account',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedBankId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('تاریخ پرداخت شمسی'),
                        const SizedBox(height: 7),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 46),
                          ),
                          onPressed: () async {
                            final picked = await _showJalaliDatePicker(
                              dialogContext,
                              selectedDate,
                            );

                            if (picked != null && dialogContext.mounted) {
                              setDialogState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_month),
                          label: Text(_jalaliLabel(selectedDate)),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: referenceController,
                          maxLength: 20,
                          keyboardType: TextInputType.text,
                          textDirection: TextDirection.ltr,
                          decoration: const InputDecoration(
                            labelText: 'شماره پیگیری (اختیاری)',
                            border: OutlineInputBorder(),
                            counterText: '',
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: const Text('انصراف'),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: selectedBankId == null
                          ? null
                          : () {
                        final gregorian = selectedDate.toGregorian();

                        final date =
                            '${gregorian.year.toString().padLeft(4, '0')}-'
                            '${gregorian.month.toString().padLeft(2, '0')}-'
                            '${gregorian.day.toString().padLeft(2, '0')}';

                        Navigator.of(dialogContext).pop({
                          'bank_id': selectedBankId,
                          'payment_date': date,
                          'transaction_reference':
                          referenceController.text.trim(),
                        });
                      },
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('ثبت پرداخت'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      // کنترلر را هم‌زمان با بسته‌شدن Route و حذف TextField آزاد نکن.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        referenceController.dispose();
      });
    }

    return result;
  }

  String _jalaliLabel(Jalali date) {
    return _fa(
      '${date.year}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.day.toString().padLeft(2, '0')}',
    );
  }

  Future<Jalali?> _showJalaliDatePicker(
      BuildContext parentContext,
      Jalali initialDate,
      ) async {
    Jalali visibleMonth = Jalali(initialDate.year, initialDate.month, 1);
    Jalali? selectedDate = initialDate;
    final today = Jalali.now();

    return showDialog<Jalali>(
      context: parentContext,
      builder: (calendarContext) {
        return StatefulBuilder(
          builder: (calendarContext, setCalendarState) {
            final formatter = visibleMonth.formatter;
            final daysInMonth = visibleMonth.monthLength;
            final firstWeekday = visibleMonth.weekDay - 1;
            final previousMonth = visibleMonth.addMonths(-1);
            final nextMonth = visibleMonth.addMonths(1);

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text(
                  'انتخاب تاریخ شمسی',
                  textAlign: TextAlign.center,
                ),
                content: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            tooltip: 'ماه قبل',
                            onPressed: () {
                              setCalendarState(() {
                                visibleMonth = previousMonth;
                              });
                            },
                            icon: const Icon(Icons.chevron_right),
                          ),
                          Text(
                            '${formatter.mN} ${_fa(visibleMonth.year)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            tooltip: 'ماه بعد',
                            onPressed: () {
                              if (nextMonth.year < today.year ||
                                  (nextMonth.year == today.year &&
                                      nextMonth.month <= today.month)) {
                                setCalendarState(() {
                                  visibleMonth = nextMonth;
                                });
                              }
                            },
                            icon: const Icon(Icons.chevron_left),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج']
                            .map((day) {
                          return Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: day == 'ج'
                                      ? Colors.red.shade700
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(
                        (firstWeekday + daysInMonth + 6) ~/ 7,
                            (weekIndex) {
                          return Row(
                            children: List.generate(7, (dayIndex) {
                              final day = weekIndex * 7 +
                                  dayIndex -
                                  firstWeekday +
                                  1;

                              if (day < 1 || day > daysInMonth) {
                                return const Expanded(
                                  child: SizedBox(height: 42),
                                );
                              }

                              final date = Jalali(
                                visibleMonth.year,
                                visibleMonth.month,
                                day,
                              );

                              final isFuture =
                                  date.year > today.year ||
                                      (date.year == today.year &&
                                          date.month > today.month) ||
                                      (date.year == today.year &&
                                          date.month == today.month &&
                                          date.day > today.day);

                              final isSelected = selectedDate != null &&
                                  selectedDate!.year == date.year &&
                                  selectedDate!.month == date.month &&
                                  selectedDate!.day == date.day;

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(22),
                                    onTap: isFuture
                                        ? null
                                        : () {
                                      setCalendarState(() {
                                        selectedDate = date;
                                      });
                                    },
                                    child: Container(
                                      height: 38,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected ? purple : null,
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: Text(
                                        _fa(day),
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : isFuture
                                              ? Colors.grey.shade400
                                              : Colors.black87,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(calendarContext).pop();
                    },
                    child: const Text('انصراف'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: selectedDate == null
                        ? null
                        : () {
                      Navigator.of(calendarContext).pop(selectedDate);
                    },
                    child: const Text('انتخاب تاریخ'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _message(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          isError ? Colors.red.shade700 : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.civilName.trim().isEmpty
        ? 'اقساط شارژ عمرانی'
        : 'اقساط ${widget.civilName}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          title: Text(title),
          centerTitle: true,
          foregroundColor: Colors.white,
          backgroundColor: teal,
          actions: [
            IconButton(
              tooltip: 'بروزرسانی',
              onPressed: _loading ? null : () => _loadInstallments(),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: teal),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _loadInstallments(),
                icon: const Icon(Icons.refresh),
                label: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInstallments,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _summaryCard(),
          const SizedBox(height: 14),
          if (_installments.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 58,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text('قسطی برای این واحد پیدا نشد.'),
                ],
              ),
            )
          else
            ..._installments.map(_installmentCard),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final totalAmount = _installments.fold<int>(
      0,
          (sum, item) => sum + _number(item['amount']),
    );

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [teal, purple],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.apartment, color: Colors.white, size: 27),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  widget.unitName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (widget.ownerName.trim().isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              widget.ownerName,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            '${_money(totalAmount)} تومان',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'مجموع اقساط نمایش‌داده‌شده',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryItem('کل اقساط', _installments.length),
              _summaryItem('پرداخت‌شده', _paidCount),
              _summaryItem('پرداخت‌نشده', _unpaidCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, int value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            _fa(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }


  Widget _installmentCard(Map<String, dynamic> installment) {
    final number = _number(installment['installment_number']);
    final amount = _number(installment['amount']);
    final paid = _bool(installment['is_paid']);
    final pending = _bool(installment['payment_pending']);
    final canPay = _bool(installment['can_pay']);

    final dueDate = installment['due_date'];
    final paymentDate = installment['payment_date'];

    final Color statusColor = paid
        ? Colors.green
        : pending
        ? Colors.orange.shade800
        : canPay
        ? purple
        : Colors.grey.shade700;

    final String status = paid
        ? 'پرداخت‌شده'
        : pending
        ? 'در انتظار تأیید'
        : canPay
        ? 'قابل پرداخت'
        : 'در انتظار پرداخت قسط قبلی';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 1.2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    paid
                        ? Icons.check_circle_outline
                        : Icons.receipt_long,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    number == 0
                        ? 'پیش‌پرداخت'
                        : 'قسط شماره ${_fa(number)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  size: 19,
                  color: teal,
                ),
                const SizedBox(width: 7),
                const Text('مبلغ قسط:'),
                const Spacer(),
                Text(
                  '${_money(amount)} تومان',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                const Icon(
                  Icons.event_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 7),
                const Text('سررسید:'),
                const Spacer(),
                Text(_dateLabel(dueDate)),
              ],
            ),

            if (paid && paymentDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 7),
                  const Text('تاریخ پرداخت:'),
                  const Spacer(),
                  Text(_dateLabel(paymentDate)),
                ],
              ),
            ],

            // قسط پرداخت‌شده: امکان لغو پرداخت
            if (paid) ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading
                      ? null
                      : () => _cancelInstallmentPayment(installment),
                  icon: const Icon(Icons.undo_rounded),
                  label: const Text('لغو پرداخت قسط'),
                ),
              ),
            ],

            // قسط پرداخت‌نشده و قابل پرداخت
            if (!paid && canPay && !pending) ...[
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading
                      ? null
                      : () => _payInstallment(installment),
                  icon: const Icon(
                    Icons.account_balance_wallet_outlined,
                  ),
                  label: const Text('ثبت پرداخت قسط'),
                ),
              ),
            ],

            // پرداخت در انتظار تأیید
            if (!paid && pending) ...[
              const SizedBox(height: 10),
              const Text(
                'این قسط در انتظار تأیید پرداخت است و فعلاً امکان ثبت مجدد ندارد.',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}
