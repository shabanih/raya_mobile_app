
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_sewage_charge_list_service.dart';

class ManagerSewageChargeInstallmentsListScreen extends StatefulWidget {
  final int sewageId;
  final int unitId;
  final String unitName;
  final String ownerName;
  final String sewageName;

  const ManagerSewageChargeInstallmentsListScreen({
    super.key,
    required this.sewageId,
    required this.unitId,
    required this.unitName,
    required this.ownerName,
    required this.sewageName,
  });

  @override
  State<ManagerSewageChargeInstallmentsListScreen> createState() =>
      _ManagerSewageChargeInstallmentsListScreenState();
}

class _ManagerSewageChargeInstallmentsListScreenState
    extends State<ManagerSewageChargeInstallmentsListScreen> {
  static const Color teal = Color(0xFF00ACC1);
  static const Color purple = Color(0xFF610DB5);

  final ManagerSewageChargeListService _service =
  ManagerSewageChargeListService();

  List<Map<String, dynamic>> _installments = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInstallments();
  }

  int _int(dynamic value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _fa(String value) {
    const en = '0123456789';
    const fa = '۰۱۲۳۴۵۶۷۸۹';

    for (int i = 0; i < 10; i++) {
      value = value.replaceAll(en[i], fa[i]);
    }

    return value;
  }

  String _money(dynamic value) {
    final number = _int(value);

    return _fa(
      number.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (_) => ',',
      ),
    );
  }

  String _date(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'ثبت نشده';
    }

    try {
      final date = DateTime.parse(value.toString());
      final jalali = Jalali.fromDateTime(date);

      return _jalaliLabel(jalali);
    } catch (_) {
      return _fa(value.toString());
    }
  }

  String _jalaliLabel(Jalali date) {
    return _fa(
      '${date.year}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.day.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _loadInstallments() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.getInstallments(
        sewageId: widget.sewageId,
        unitId: widget.unitId,
      );

      if (!mounted) return;

      setState(() {
        _installments = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  int get _totalAmount {
    return _installments.fold(
      0,
          (sum, item) => sum + _int(item['amount']),
    );
  }

  int get _paidAmount {
    return _installments.fold(
      0,
          (sum, item) =>
      sum + (item['is_paid'] == true ? _int(item['amount']) : 0),
    );
  }

  int get _paidCount {
    return _installments.where((item) {
      return item['is_paid'] == true &&
          _int(item['installment_number']) > 0;
    }).length;
  }

  int get _periodicCount {
    return _installments.where((item) {
      return _int(item['installment_number']) > 0;
    }).length;
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // ثبت پرداخت
  // =========================================================

  Future<void> _pay(Map<String, dynamic> installment) async {
    final installmentId = _int(installment['id']);

    if (installmentId <= 0) return;

    final referenceController = TextEditingController();

    try {
      final banks = await _service.getPaymentBanks(
        installmentId: installmentId,
      );

      if (!mounted) return;

      if (banks.isEmpty) {
        _message('حساب بانکی فعالی برای ثبت پرداخت وجود ندارد.');
        return;
      }

      int? selectedBank = _int(banks.first['id']);
      Jalali selectedDate = Jalali.now();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text(
                    'ثبت پرداخت قسط فاضلاب',
                    textAlign: TextAlign.right,
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مبلغ: ${_money(installment['amount'])} ریال',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 18),

                        const Text(
                          'انتخاب حساب بانکی',
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 7),

                        DropdownButtonFormField<int>(
                          value: selectedBank,
                          isExpanded: true,
                          alignment: AlignmentDirectional.centerStart,
                          items: banks.map((bank) {
                            final id = _int(bank['id']);

                            final bankName = bank['bank_name'] ??
                                bank['name'] ??
                                'حساب بانکی $id';

                            final accountNo = (
                                bank['account_no'] ??
                                    bank['account_number'] ??
                                    ''
                            ).toString().trim();

                            final name = accountNo.isNotEmpty
                                ? '$bankName - $accountNo'
                                : bankName;

                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(
                                name.toString(),
                                textAlign: TextAlign.right,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedBank = value;
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          'تاریخ پرداخت',
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(height: 7),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await _showJalaliDatePicker(
                                dialogContext,
                                selectedDate,
                              );

                              if (picked != null &&
                                  dialogContext.mounted) {
                                setDialogState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_month),
                            label: Text(_jalaliLabel(selectedDate)),
                          ),
                        ),

                        const SizedBox(height: 15),

                        TextField(
                          controller: referenceController,
                          maxLength: 20,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          decoration: InputDecoration(
                            labelText: 'شماره پیگیری (اختیاری)',
                            labelStyle: const TextStyle(fontSize: 13),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext, false);
                      },
                      child: const Text('انصراف'),
                    ),
                    ElevatedButton(
                      onPressed: selectedBank == null
                          ? null
                          : () {
                        Navigator.pop(dialogContext, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('ثبت پرداخت'),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );

      if (confirmed != true || selectedBank == null) {
        return;
      }

      // تبدیل تاریخ شمسی به میلادی برای API
      final gregorian = selectedDate.toGregorian();

      final paymentDate =
          '${gregorian.year.toString().padLeft(4, '0')}-'
          '${gregorian.month.toString().padLeft(2, '0')}-'
          '${gregorian.day.toString().padLeft(2, '0')}';

      await _service.payInstallment(
        installmentId: installmentId,
        bankId: selectedBank!,
        paymentDate: paymentDate,
        transactionReference: referenceController.text.trim(),
      );

      if (!mounted) return;

      _message('پرداخت با موفقیت ثبت شد.');

      await _loadInstallments();
    } catch (e) {
      if (!mounted) return;

      _message(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      referenceController.dispose();
    }
  }

  // =========================================================
  // تقویم شمسی
  // =========================================================

  Future<Jalali?> _showJalaliDatePicker(
      BuildContext context,
      Jalali initialDate,
      ) async {
    Jalali visibleMonth = Jalali(
      initialDate.year,
      initialDate.month,
      1,
    );

    Jalali? selectedDate = initialDate;
    final today = Jalali.now();

    return showDialog<Jalali>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              final formatter = visibleMonth.formatter;

              final firstDayOffset = visibleMonth.weekDay - 1;
              final monthLength = visibleMonth.monthLength;

              final totalCells = firstDayOffset + monthLength;
              final rowCount = (totalCells / 7).ceil();

              return AlertDialog(
                title: const Text(
                  'انتخاب تاریخ پرداخت',
                  textAlign: TextAlign.center,
                ),
                content: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // عنوان ماه و دکمه‌های جابه‌جایی
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            tooltip: 'ماه قبل',
                            onPressed: () {
                              setStateDialog(() {
                                visibleMonth =
                                    visibleMonth.addMonths(-1);
                              });
                            },
                            icon: const Icon(Icons.chevron_right),
                          ),
                          Expanded(
                            child: Text(
                              '${formatter.mN} ${_fa(visibleMonth.year.toString())}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: purple,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'ماه بعد',
                            onPressed: () {
                              final nextMonth =
                              visibleMonth.addMonths(1);

                              final nextMonthIsFuture =
                                  nextMonth.year > today.year ||
                                      (nextMonth.year == today.year &&
                                          nextMonth.month > today.month);

                              if (nextMonthIsFuture) return;

                              setStateDialog(() {
                                visibleMonth = nextMonth;
                              });
                            },
                            icon: Icon(
                              Icons.chevron_left,
                              color: (visibleMonth.year == today.year &&
                                  visibleMonth.month == today.month)
                                  ? Colors.grey
                                  : purple,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // روزهای هفته
                      Row(
                        children: ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج']
                            .map(
                              (day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        )
                            .toList(),
                      ),

                      const SizedBox(height: 8),

                      // روزهای ماه
                      ...List.generate(rowCount, (row) {
                        return Row(
                          children: List.generate(7, (column) {
                            final day =
                                row * 7 + column - firstDayOffset + 1;

                            if (day < 1 || day > monthLength) {
                              return const Expanded(
                                child: SizedBox(height: 40),
                              );
                            }

                            final candidate = Jalali(
                              visibleMonth.year,
                              visibleMonth.month,
                              day,
                            );

                            final isFuture =
                                candidate.year > today.year ||
                                    (candidate.year == today.year &&
                                        (candidate.month > today.month ||
                                            (candidate.month == today.month &&
                                                candidate.day > today.day)));

                            final isSelected =
                                selectedDate != null &&
                                    selectedDate!.year == candidate.year &&
                                    selectedDate!.month == candidate.month &&
                                    selectedDate!.day == candidate.day;

                            final isToday =
                                candidate.year == today.year &&
                                    candidate.month == today.month &&
                                    candidate.day == today.day;

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: InkWell(
                                  onTap: isFuture
                                      ? null
                                      : () {
                                    setStateDialog(() {
                                      selectedDate = candidate;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(25),
                                  child: Container(
                                    height: 36,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? purple
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(25),
                                      border: isToday && !isSelected
                                          ? Border.all(
                                        color: purple,
                                        width: 1,
                                      )
                                          : null,
                                    ),
                                    child: Text(
                                      _fa(day.toString()),
                                      style: TextStyle(
                                        color: isFuture
                                            ? Colors.grey.shade300
                                            : isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: isSelected || isToday
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      }),

                      const SizedBox(height: 10),

                      if (selectedDate != null)
                        Text(
                          'تاریخ انتخاب‌شده: ${_jalaliLabel(selectedDate!)}',
                          style: const TextStyle(
                            color: purple,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('انصراف'),
                  ),
                  ElevatedButton(
                    onPressed: selectedDate == null
                        ? null
                        : () {
                      Navigator.pop(
                        dialogContext,
                        selectedDate,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('تأیید'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // =========================================================
  // لغو پرداخت
  // =========================================================

  Future<void> _cancelPayment(Map<String, dynamic> installment) async {
    final installmentId = _int(installment['id']);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'لغو پرداخت',
              textAlign: TextAlign.right,
            ),
            content: const Text(
              'آیا از لغو این پرداخت اطمینان دارید؟',
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('انصراف'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('لغو پرداخت'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.cancelPayment(
        installmentId: installmentId,
      );

      if (!mounted) return;

      _message('پرداخت با موفقیت لغو شد.');

      await _loadInstallments();
    } catch (e) {
      if (!mounted) return;

      _message(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // =========================================================
  // ردیف‌های خلاصه
  // =========================================================

  Widget _summaryRow(String title, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            '${_money(amount)} ریال',
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _whiteSummaryRow(String title, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
          Text(
            '${_money(amount)} ریال',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // خلاصه وضعیت واحد
  // =========================================================

  Widget _summary() {
    final remaining = (_totalAmount - _paidAmount)
        .clamp(0, _totalAmount)
        .toInt();

    final progress = _totalAmount > 0
        ? (_paidAmount / _totalAmount).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.all(12),
      color: purple,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.apartment_rounded,
                  color: Colors.white,
                  size: 23,
                ),
                const SizedBox(width: 9),
                Text(
                  'واحد ${_fa(widget.unitName)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 9),

            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    widget.ownerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(
              color: Colors.white38,
              height: 28,
            ),

            _whiteSummaryRow(
              'مجموع اقساط و پیش‌پرداخت',
              _totalAmount,
            ),
            _whiteSummaryRow(
              'مبلغ پرداخت‌شده',
              _paidAmount,
            ),
            _whiteSummaryRow(
              'مانده',
              remaining,
            ),

            const Divider(
              color: Colors.white38,
              height: 24,
            ),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'اقساط پرداخت‌شده',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '${_fa(_paidCount.toString())} از '
                      '${_fa(_periodicCount.toString())}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white30,
                color: const Color(0xFF4ADE80),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // کارت هر قسط
  // =========================================================

  Widget _installmentCard(Map<String, dynamic> item) {
    final number = _int(item['installment_number']);

    final paid = item['is_paid'] == true;
    final pending = item['payment_pending'] == true;
    final canPay = item['can_pay'] == true;

    final isPrepayment = number == 0;

    Color statusColor;
    String status;

    if (paid) {
      statusColor = Colors.green;
      status = 'پرداخت‌شده';
    } else if (pending) {
      statusColor = Colors.orange;
      status = 'در انتظار تأیید';
    } else if (canPay) {
      statusColor = teal;
      status = 'قابل پرداخت';
    } else {
      statusColor = Colors.grey;
      status = 'در انتظار قسط قبلی';
    }

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isPrepayment
                        ? 'پیش‌پرداخت'
                        : 'قسط ${_fa(number.toString())}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 22),

            _summaryRow(
              'مبلغ قسط',
              _int(item['amount']),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'تاریخ سررسید',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    _date(item['due_date']),
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            if (item['payment_date'] != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'تاریخ پرداخت',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      _date(item['payment_date']),
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            if (paid)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelPayment(item),
                  icon: const Icon(
                    Icons.undo,
                    color: Colors.red,
                  ),
                  label: const Text(
                    'لغو پرداخت',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              )
            else if (!pending && canPay)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _pay(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.payment),
                  label: const Text('ثبت پرداخت'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // صفحه اصلی
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 88,
          title: const Text('اقساط شارژ فاضلاب'),
          backgroundColor: teal,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _loadInstallments,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            if (!_loading &&
                _error == null &&
                _installments.isNotEmpty)
              _summary(),

            Expanded(
              child: _loading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : _error != null
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadInstallments,
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                ),
              )
                  : _installments.isEmpty
                  ? const Center(
                child: Text(
                  'قسطی برای این واحد ارسال نشده است.',
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadInstallments,
                child: ListView.builder(
                  padding: const EdgeInsets.only(
                    bottom: 20,
                  ),
                  itemCount: _installments.length,
                  itemBuilder: (_, index) =>
                      _installmentCard(
                        _installments[index],
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
