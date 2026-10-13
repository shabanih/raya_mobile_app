
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_fixed_charge_service.dart';
import 'manager_fixed_charge_units_screen.dart';

const Color _primaryColor = Color(0xFF00ACC1);
const Color _purpleColor = Color(0xFF610DB5);

String _faDigits(String value) {
  const english = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';

  return value.split('').map((char) {
    final index = english.indexOf(char);
    return index < 0 ? char : persian[index];
  }).join();
}

String _enDigits(String value) {
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  const arabic = '٠١٢٣٤٥٦٧٨٩';

  for (int i = 0; i < 10; i++) {
    value = value.replaceAll(persian[i], '$i');
    value = value.replaceAll(arabic[i], '$i');
  }

  return value.trim();
}

String _formatMoney(dynamic value) {
  final amount = value is num
      ? value.toInt()
      : int.tryParse(_enDigits('$value')) ?? 0;

  final digits = amount.toString();
  final buffer = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);

    final remaining = digits.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) {
      buffer.write(',');
    }
  }

  return _faDigits(buffer.toString());
}

int _jalaliDaysInMonth(int year, int month) {
  if (month >= 1 && month <= 6) return 31;
  if (month >= 7 && month <= 11) return 30;
  return Jalali(year, 12, 1).isLeapYear() ? 30 : 29;
}

Jalali? _parseJalali(String value) {
  final text = _enDigits(value);
  final parts = text.split('/');

  if (parts.length == 3) {
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);

    if (year != null &&
        month != null &&
        day != null &&
        month >= 1 &&
        month <= 12 &&
        day >= 1 &&
        day <= _jalaliDaysInMonth(year, month)) {
      return Jalali(year, month, day);
    }
  }

  final gregorian = DateTime.tryParse(text);
  if (gregorian != null) return Jalali.fromDateTime(gregorian);

  return null;
}

String _jalaliString(dynamic value) {
  if (value == null || '$value'.trim().isEmpty) return '—';

  Jalali? date;

  if (value is Jalali) {
    date = value;
  } else {
    date = _parseJalali('$value');
  }

  if (date == null) return '—';

  return _faDigits(
    '${date.year}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}',
  );
}

class ManagerFixedChargesScreen extends StatefulWidget {
  const ManagerFixedChargesScreen({super.key});

  @override
  State<ManagerFixedChargesScreen> createState() =>
      _ManagerFixedChargesScreenState();
}

class _ManagerFixedChargesScreenState
    extends State<ManagerFixedChargesScreen> {
  final ManagerFixedChargeService _service =
  ManagerFixedChargeService();

  List<Map<String, dynamic>> _charges = [];
  bool _loading = true;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();
    _loadCharges();
  }

  Future<void> _loadCharges() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = false;
      });
    }

    try {
      final result = await _service.getCharges();

      if (!mounted) return;

      setState(() {
        _charges = List<Map<String, dynamic>>.from(result);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _loadError = true;
      });

      _showMessage('دریافت فهرست شارژها انجام نشد: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _notificationSent(Map<String, dynamic> charge) {
    return charge['notification_sent'] == true ||
        charge['send_notification'] == true;
  }

  bool _canEdit(Map<String, dynamic> charge) {
    if (_notificationSent(charge)) return false;
    return charge['can_edit'] != false;
  }

  bool _canDelete(Map<String, dynamic> charge) {
    if (_notificationSent(charge)) return false;
    return charge['can_delete'] != false;
  }

  int? _readCount(
      Map<String, dynamic> data,
      List<String> keys,
      ) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;

      if (value is List) return value.length;

      final count = int.tryParse(_enDigits('$value'));
      if (count != null && count >= 0) return count;
    }

    return null;
  }

  int? _sentUnitsCount(Map<String, dynamic> charge) {
    return _readCount(charge, [
      'sent_units_count',
      'units_sent_count',
      'notified_units_count',
      'notification_sent_count',
      'sent_count',
      'announced_units_count',
      'sent_units',
      'notified_units',
    ]);
  }

  int? _totalUnitsCount(Map<String, dynamic> charge) {
    return _readCount(charge, [
      'total_units_count',
      'total_units',
      'unit_count',
      'units_count',
      'house_units_count',
      'all_units_count',
    ]);
  }

  Future<void> _showChargeForm({
    Map<String, dynamic>? charge,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FixedChargeFormSheet(
        charge: charge,
        service: _service,
      ),
    );

    if (saved == true && mounted) {
      await _loadCharges();
    }
  }

  Future<void> _openChargeUnits(
      Map<String, dynamic> charge,
      ) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerFixedChargeUnitsScreen(
          charge: Map<String, dynamic>.from(charge),
          service: _service,
        ),
      ),
    );

    if (!mounted) return;
    await _loadCharges();
  }

  Future<void> _deleteCharge(
      Map<String, dynamic> charge,
      ) async {
    final id = int.tryParse('${charge['id']}');

    if (id == null) {
      _showMessage('شناسه شارژ معتبر نیست.');
      return;
    }

    if (!_canDelete(charge)) {
      _showMessage(
        'این شارژ به دلیل ارسال اعلان یا محدودیت ثبت‌شده قابل حذف نیست.',
      );
      return;
    }

    final name = _faDigits(
      '${charge['name'] ?? charge['title'] ?? 'شارژ واحدی'}',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف شارژ واحدی'),
          content: Text('آیا از حذف شارژ «$name» اطمینان دارید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteCharge(id);

      if (!mounted) return;

      _showMessage('شارژ با موفقیت حذف شد.');
      await _loadCharges();
    } catch (e) {
      _showMessage('حذف شارژ انجام نشد: $e');
    }
  }

  Widget _infoRow(
      IconData icon,
      String label,
      String value, {
        Color? valueColor,
      }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  void _showChargeDetails(Map<String, dynamic> charge) {
    final name = _faDigits(
      '${charge['name'] ?? charge['title'] ?? 'شارژ واحدی'}',
    );

    final amount = _formatMoney(
      charge['fix_amount'] ??
          charge['fixAmount'] ??
          charge['amount'] ??
          0,
    );

    final penalty = _formatMoney(
      charge['payment_penalty_amount'] ??
          charge['paymentPenaltyAmount'] ??
          0,
    );

    final otherCost = _formatMoney(
      charge['other_cost_amount'] ??
          charge['otherCostAmount'] ??
          0,
    );

    final details =
    '${charge['details'] ?? charge['description'] ?? ''}'.trim();

    final sentCount = _sentUnitsCount(charge);
    final totalCount = _totalUnitsCount(charge);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.receipt_long, color: _primaryColor),
              SizedBox(width: 10),
              Expanded(child: Text('جزئیات شارژ')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 18),
                _infoRow(
                  Icons.payments_outlined,
                  'مبلغ هر واحد',
                  '$amount تومان',
                ),
                const SizedBox(height: 12),
                _infoRow(
                  Icons.money_off_csred_outlined,
                  'جریمه دیرکرد',
                  '$penalty تومان',
                ),
                const SizedBox(height: 12),
                _infoRow(
                  Icons.add_card_outlined,
                  'هزینه متفرقه',
                  '$otherCost تومان',
                ),
                const SizedBox(height: 12),
                _infoRow(
                  Icons.calendar_month_outlined,
                  'مهلت پرداخت',
                  _jalaliString(
                    charge['payment_deadline'] ??
                        charge['payment_deadline_date'],
                  ),
                ),
                const SizedBox(height: 12),
                _infoRow(
                  Icons.apartment_outlined,
                  'واحدهای اعلام‌شده',
                  sentCount != null && totalCount != null
                      ? '${_faDigits('$sentCount')} از '
                      '${_faDigits('$totalCount')} واحد'
                      : 'اطلاعات کامل نیست',
                ),
                const SizedBox(height: 16),
                const Text(
                  'توضیحات',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    details.isEmpty
                        ? 'توضیحاتی ثبت نشده است.'
                        : details,
                    style: const TextStyle(height: 1.8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('بستن'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargeCard(Map<String, dynamic> charge) {
    final chargeName = _faDigits(
      '${charge['name'] ?? charge['title'] ?? 'شارژ واحدی'}',
    );

    final amount = _formatMoney(
      charge['fix_amount'] ??
          charge['fixAmount'] ??
          charge['amount'] ??
          0,
    );

    final notified = _notificationSent(charge);
    final canEdit = _canEdit(charge);
    final canDelete = _canDelete(charge);

    final sentCount = _sentUnitsCount(charge);
    final totalCount = _totalUnitsCount(charge);

    final sentUnitsText =
    sentCount != null && totalCount != null
        ? 'اعلام شارژ ${_faDigits('$sentCount')} از '
        '${_faDigits('$totalCount')} واحد'
        : 'تعداد واحدهای اعلام‌شده نامشخص';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _purpleColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: _purpleColor,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chargeName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'مبلغ شارژ: $amount تومان',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'عملیات شارژ',
                  onSelected: (value) {
                    switch (value) {
                      case 'send':
                        _openChargeUnits(charge);
                        break;
                      case 'details':
                        _showChargeDetails(charge);
                        break;
                      case 'edit':
                        if (canEdit) {
                          _showChargeForm(charge: charge);
                        }
                        break;
                      case 'delete':
                        if (canDelete) {
                          _deleteCharge(charge);
                        }
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'send',
                      child: Row(
                        children: [
                          Icon(
                            Icons.send_outlined,
                            color: _primaryColor,
                          ),
                          SizedBox(width: 10),
                          Text('مدیریت و ارسال به واحدها'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: _purpleColor,
                          ),
                          SizedBox(width: 10),
                          Text('مشاهده جزئیات'),
                        ],
                      ),
                    ),
                    if (canEdit)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              color: Colors.blue,
                            ),
                            SizedBox(width: 10),
                            Text('ویرایش شارژ'),
                          ],
                        ),
                      ),
                    if (canDelete)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            SizedBox(width: 10),
                            Text('حذف شارژ'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _infoRow(
              Icons.calendar_month_outlined,
              'مهلت پرداخت',
              _jalaliString(
                charge['payment_deadline'] ??
                    charge['payment_deadline_date'],
              ),
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.schedule_outlined,
              'وضعیت ارسال',
              notified ? 'ارسال‌شده' : 'ارسال‌نشده',
              valueColor: notified ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.apartment_outlined,
                  size: 19,
                  color: _purpleColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sentUnitsText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _purpleColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('شارژ واحدی'),
          centerTitle: true,
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showChargeForm(),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('افزودن شارژ'),
        ),
        body: RefreshIndicator(
          onRefresh: _loadCharges,
          child: _loading
              ? const Center(
            child: CircularProgressIndicator(
              color: _primaryColor,
            ),
          )
              : _loadError && _charges.isEmpty
              ? ListView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 100),
              const Icon(
                Icons.cloud_off,
                size: 54,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'دریافت اطلاعات ناموفق بود.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Center(
                child: FilledButton.icon(
                  onPressed: _loadCharges,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تلاش مجدد'),
                ),
              ),
            ],
          )
              : _charges.isEmpty
              ? ListView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 100),
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'هنوز شارژ واحدی ثبت نشده است.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Center(
                child: FilledButton.icon(
                  onPressed: () => _showChargeForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('ثبت اولین شارژ'),
                ),
              ),
            ],
          )
              : ListView.builder(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              100,
            ),
            itemCount: _charges.length,
            itemBuilder: (_, index) =>
                _buildChargeCard(_charges[index]),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// فرم ثبت و ویرایش شارژ
// ============================================================

class _FixedChargeFormSheet extends StatefulWidget {
  final Map<String, dynamic>? charge;
  final ManagerFixedChargeService service;

  const _FixedChargeFormSheet({
    required this.service,
    this.charge,
  });

  @override
  State<_FixedChargeFormSheet> createState() =>
      _FixedChargeFormSheetState();
}

class _FixedChargeFormSheetState
    extends State<_FixedChargeFormSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _penaltyController = TextEditingController();
  final _otherCostController = TextEditingController();
  final _detailsController = TextEditingController();

  bool _saving = false;

  bool get _isEditing => widget.charge != null;

  @override
  void initState() {
    super.initState();

    final charge = widget.charge;
    if (charge == null) return;

    _nameController.text =
    '${charge['name'] ?? charge['title'] ?? ''}';

    _amountController.text = _enDigits(
      '${charge['fix_amount'] ?? charge['fixAmount'] ?? ''}',
    );

    _penaltyController.text = _enDigits(
      '${charge['payment_penalty_amount'] ?? charge['paymentPenaltyAmount'] ?? 0}',
    );

    _otherCostController.text = _enDigits(
      '${charge['other_cost_amount'] ?? charge['otherCostAmount'] ?? 0}',
    );

    _detailsController.text =
    '${charge['details'] ?? charge['description'] ?? ''}';

    final deadline = _parseJalali(
      '${charge['payment_deadline'] ?? charge['payment_deadline_date'] ?? ''}',
    );

    if (deadline != null) {
      _deadlineController.text = _jalaliString(deadline);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _deadlineController.dispose();
    _penaltyController.dispose();
    _otherCostController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label را وارد کنید.';
    }
    return null;
  }

  String? _amountValidator(String? value) {
    final number = int.tryParse(_enDigits(value ?? ''));
    if (number == null || number < 0) {
      return 'مبلغ باید عدد صحیح و غیرمنفی باشد.';
    }
    return null;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _selectDeadline() async {
    final selected = await showDialog<Jalali>(
      context: context,
      builder: (_) => _ShamsiDateDialog(
        initialDate:
        _parseJalali(_deadlineController.text) ?? Jalali.now(),
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _deadlineController.text = _jalaliString(selected);
      });
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final amount = int.tryParse(
      _enDigits(_amountController.text),
    );

    final penalty = int.tryParse(
      _enDigits(_penaltyController.text),
    ) ??
        0;

    final otherCost = int.tryParse(
      _enDigits(_otherCostController.text),
    ) ??
        0;

    final deadline = _parseJalali(_deadlineController.text);

    if (amount == null || amount < 0) {
      _showMessage('مبلغ شارژ معتبر نیست.');
      return;
    }

    if (penalty < 0 || otherCost < 0) {
      _showMessage('مبالغ نباید منفی باشند.');
      return;
    }

    if (deadline == null) {
      _showMessage('تاریخ سررسید را از تقویم انتخاب کنید.');
      return;
    }

    final gregorian = deadline.toDateTime();

    final apiDeadline =
        '${gregorian.year}-'
        '${gregorian.month.toString().padLeft(2, '0')}-'
        '${gregorian.day.toString().padLeft(2, '0')}';

    final id = int.tryParse('${widget.charge?['id'] ?? ''}');

    if (_isEditing && id == null) {
      _showMessage('شناسه شارژ معتبر نیست.');
      return;
    }

    setState(() => _saving = true);

    try {
      if (_isEditing) {
        await widget.service.updateCharge(
          id!,
          name: _nameController.text.trim(),
          fixAmount: amount,
          paymentDeadline: apiDeadline,
          otherCostAmount: otherCost,
          paymentPenaltyAmount: penalty,
          details: _detailsController.text.trim(),
        );
      } else {
        await widget.service.createCharge(
          name: _nameController.text.trim(),
          fixAmount: amount,
          paymentDeadline: apiDeadline,
          otherCostAmount: otherCost,
          paymentPenaltyAmount: penalty,
          details: _detailsController.text.trim(),
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'شارژ با موفقیت ویرایش شد.'
                : 'شارژ با موفقیت ثبت شد.',
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      _showMessage(
        'ذخیره شارژ انجام نشد: '
            '${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      color: _primaryColor,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEditing
                            ? 'ویرایش شارژ واحدی'
                            : 'افزودن شارژ واحدی',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(20),
                    children: [
                      _field(
                        label: 'عنوان شارژ',
                        controller: _nameController,
                        hint: 'مثلاً مهر ۱۴۰۵',
                        validator: (v) =>
                            _requiredValidator(v, 'عنوان شارژ'),
                      ),
                      const SizedBox(height: 16),
                      _field(
                        label: 'مبلغ شارژ هر واحد (تومان)',
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        validator: _amountValidator,
                      ),
                      const SizedBox(height: 16),
                      _field(
                        label: 'مهلت پرداخت (شمسی)',
                        controller: _deadlineController,
                        readOnly: true,
                        onTap: _selectDeadline,
                        validator: (v) =>
                            _requiredValidator(v, 'تاریخ سررسید'),
                        suffixIcon: const Icon(
                          Icons.calendar_month,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _field(
                        label: 'جریمه دیرکرد',
                        controller: _penaltyController,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return null;
                          }

                          final n = int.tryParse(_enDigits(v));
                          if (n == null || n < 0) {
                            return 'مقدار جریمه معتبر نیست.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _field(
                        label: 'هزینه متفرقه (تومان)',
                        controller: _otherCostController,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return null;
                          }

                          final n = int.tryParse(_enDigits(v));
                          if (n == null || n < 0) {
                            return 'مبلغ معتبر نیست.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _field(
                        label: 'توضیحات',
                        controller: _detailsController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          icon: _saving
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.save),
                          label: Text(
                            _saving
                                ? 'در حال ذخیره...'
                                : _isEditing
                                ? 'ذخیره تغییرات'
                                : 'ثبت شارژ',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// انتخاب تاریخ شمسی
// ============================================================

class _ShamsiDateDialog extends StatefulWidget {
  final Jalali initialDate;

  const _ShamsiDateDialog({
    required this.initialDate,
  });

  @override
  State<_ShamsiDateDialog> createState() =>
      _ShamsiDateDialogState();
}

class _ShamsiDateDialogState extends State<_ShamsiDateDialog> {
  late int _year;
  late int _month;
  late int _day;

  @override
  void initState() {
    super.initState();

    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
    _day = widget.initialDate.day;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = Jalali.now().year;

    final years = List<int>.generate(
      81,
          (index) => currentYear - 40 + index,
    );

    final days = List<int>.generate(
      _jalaliDaysInMonth(_year, _month),
          (index) => index + 1,
    );

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
              DropdownButtonFormField<int>(
                value: _year,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'سال',
                  border: OutlineInputBorder(),
                ),
                items: years.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(_faDigits('$year')),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _year = value;
                    final max =
                    _jalaliDaysInMonth(_year, _month);
                    if (_day > max) _day = max;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _month,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'ماه',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(12, (index) {
                  final month = index + 1;
                  return DropdownMenuItem(
                    value: month,
                    child: Text(_faDigits('$month')),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _month = value;
                    final max =
                    _jalaliDaysInMonth(_year, _month);
                    if (_day > max) _day = max;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _day,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'روز',
                  border: OutlineInputBorder(),
                ),
                items: days.map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text(_faDigits('$day')),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _day = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              Text(
                _jalaliString(Jalali(_year, _month, _day)),
                style: const TextStyle(
                  color: _primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(
                context,
                Jalali(_year, _month, _day),
              );
            },
            child: const Text('تأیید'),
          ),
        ],
      ),
    );
  }
}
