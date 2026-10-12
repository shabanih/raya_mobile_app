
import 'package:flutter/material.dart';

import '../../services/manager_fixed_charge_service.dart';

class ManagerFixedChargesScreen extends StatefulWidget {
  const ManagerFixedChargesScreen({super.key});

  @override
  State<ManagerFixedChargesScreen> createState() =>
      _ManagerFixedChargesScreenState();
}

class _ManagerFixedChargesScreenState
    extends State<ManagerFixedChargesScreen> {
  static const Color primaryColor = Color(0xFF00ACC1);
  static const Color purpleColor = Color(0xFF610DB5);

  final ManagerFixedChargeService _service =
  ManagerFixedChargeService();

  List<Map<String, dynamic>> _charges = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCharges();
  }

  Future<void> _loadCharges() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.getCharges();

      if (!mounted) return;

      setState(() {
        _charges = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _errorText(e);
        _loading = false;
      });
    }
  }

  String _errorText(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  bool _flag(dynamic value) {
    return value == true ||
        value == 1 ||
        value?.toString().toLowerCase() == 'true';
  }

  int _intValue(dynamic value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _text(dynamic value, {String fallback = '—'}) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }
    return value.toString();
  }

  String _digits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    return value.split('').map((char) {
      final index = english.indexOf(char);
      return index < 0 ? char : persian[index];
    }).join();
  }

  String _money(dynamic value) {
    final amount = _intValue(value);
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
    );

    return '${_digits(formatted)} تومان';
  }

  bool _notificationSent(Map<String, dynamic> charge) {
    return _flag(charge['notification_sent']) ||
        _flag(charge['send_notification']);
  }

  bool _canEdit(Map<String, dynamic> charge) {
    if (_notificationSent(charge)) return false;

    return charge['can_edit'] == null ||
        _flag(charge['can_edit']);
  }

  bool _canDelete(Map<String, dynamic> charge) {
    if (_notificationSent(charge)) return false;

    return charge['can_delete'] == null ||
        _flag(charge['can_delete']);
  }

  void _showMessage(
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
            textAlign: TextAlign.right,
          ),
          backgroundColor:
          isError ? Colors.red.shade700 : primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _showChargeForm({
    Map<String, dynamic>? charge,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FixedChargeFormSheet(
        charge: charge,
        service: _service,
      ),
    );

    if (result == true && mounted) {
      await _loadCharges();
    }
  }

  void _editCharge(Map<String, dynamic> charge) {
    if (!_canEdit(charge)) {
      _showMessage(
        'این شارژ قابل ویرایش نیست؛ اعلان آن ارسال شده است.',
        isError: true,
      );
      return;
    }

    _showChargeForm(charge: charge);
  }

  Future<void> _deleteCharge(
      Map<String, dynamic> charge,
      ) async {
    if (!_canDelete(charge)) {
      _showMessage(
        'این شارژ قابل حذف نیست؛ اعلان آن ارسال شده است.',
        isError: true,
      );
      return;
    }

    final id = int.tryParse(charge['id']?.toString() ?? '');

    if (id == null) {
      _showMessage('شناسه شارژ معتبر نیست.', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'حذف شارژ واحدی',
          textAlign: TextAlign.right,
        ),
        content: Text(
          'آیا از حذف شارژ «${_text(charge['name'])}» مطمئن هستید؟',
          textAlign: TextAlign.right,
        ),
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
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteCharge(id);

      if (!mounted) return;

      _showMessage('شارژ با موفقیت حذف شد.');
      await _loadCharges();
    } catch (e) {
      if (!mounted) return;

      _showMessage(_errorText(e), isError: true);
      await _loadCharges();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          title: const Text(
            'شارژ واحدی',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'بارگذاری مجدد',
              onPressed: _loading ? null : _loadCharges,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showChargeForm(),
          backgroundColor: purpleColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('ثبت شارژ جدید'),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
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
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadCharges,
                icon: const Icon(Icons.refresh),
                label: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }

    if (_charges.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCharges,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 110),
            Icon(
              Icons.receipt_long_outlined,
              size: 76,
              color: primaryColor,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'هنوز شارژ واحدی ثبت نشده است.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text('برای شروع، شارژ جدید ثبت کنید.'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCharges,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _charges.length,
        itemBuilder: (context, index) {
          final charge = _charges[index];
          final canEdit = _canEdit(charge);
          final canDelete = _canDelete(charge);
          final notificationSent = _notificationSent(charge);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: notificationSent
                    ? Colors.orange.shade200
                    : Colors.grey.shade200,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: purpleColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: purpleColor,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              _text(charge['name']),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'تعداد واحد: ${_digits(_text(charge['unit_count'], fallback: '۰'))}',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _infoRow(
                    Icons.payments_outlined,
                    'مبلغ شارژ هر واحد',
                    _money(charge['fix_amount']),
                  ),
                  const SizedBox(height: 9),
                  _infoRow(
                    Icons.event_outlined,
                    'مهلت پرداخت',
                    _text(charge['payment_deadline']),
                  ),
                  if (_intValue(charge['other_cost_amount']) != 0) ...[
                    const SizedBox(height: 9),
                    _infoRow(
                      Icons.add_card,
                      'سایر هزینه‌ها',
                      _money(charge['other_cost_amount']),
                    ),
                  ],
                  if (notificationSent) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: Colors.deepOrange,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'اعلان این شارژ ارسال شده است؛ ویرایش و حذف مجاز نیست.',
                              style: TextStyle(
                                color: Colors.deepOrange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editCharge(charge),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('ویرایش'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                            canEdit ? primaryColor : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteCharge(charge),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('حذف'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                            canDelete ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
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
        Icon(icon, size: 19, color: primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// فرم ثبت و ویرایش شارژ واحدی در همین فایل
// ---------------------------------------------------------

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
  static const Color primaryColor = Color(0xFF00ACC1);
  static const Color purpleColor = Color(0xFF610DB5);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _deadlineController;
  late final TextEditingController _penaltyController;
  late final TextEditingController _otherCostController;
  late final TextEditingController _detailsController;

  bool _saving = false;

  bool get _isEditing => widget.charge != null;

  @override
  void initState() {
    super.initState();

    final charge = widget.charge;

    _nameController = TextEditingController(
      text: charge?['name']?.toString() ?? '',
    );
    _amountController = TextEditingController(
      text: charge?['fix_amount']?.toString() ?? '',
    );
    _deadlineController = TextEditingController(
      text: charge?['payment_deadline']?.toString() ?? '',
    );
    _penaltyController = TextEditingController(
      text: charge?['payment_penalty_amount']?.toString() ?? '0',
    );
    _otherCostController = TextEditingController(
      text: charge?['other_cost_amount']?.toString() ?? '0',
    );
    _detailsController = TextEditingController(
      text: charge?['details']?.toString() ?? '',
    );
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

  int? _number(String value) {
    final normalized = value
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll(' ', '')
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9')
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');

    return int.tryParse(normalized);
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label را وارد کنید.';
    }

    return null;
  }

  String? _validateAmount(
      String? value, {
        required String label,
        bool allowZero = true,
      }) {
    if (value == null || value.trim().isEmpty) {
      return '$label را وارد کنید.';
    }

    final amount = _number(value);

    if (amount == null) {
      return '$label باید عدد صحیح باشد.';
    }

    if (allowZero ? amount < 0 : amount <= 0) {
      return allowZero
          ? '$label نمی‌تواند منفی باشد.'
          : '$label باید بیشتر از صفر باشد.';
    }

    return null;
  }

  String? _validateDeadline(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'مهلت پرداخت را وارد کنید.';
    }

    final normalized = value.trim().replaceAll('-', '/');

    if (!RegExp(r'^\d{4}/\d{1,2}/\d{1,2}$')
        .hasMatch(normalized)) {
      return 'قالب تاریخ باید مانند 1405/07/20 باشد.';
    }

    final parts = normalized.split('/');
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);

    if (month == null ||
        day == null ||
        month < 1 ||
        month > 12 ||
        day < 1 ||
        day > 31) {
      return 'تاریخ واردشده معتبر نیست.';
    }

    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final amount = _number(_amountController.text);
    final penalty = _number(_penaltyController.text) ?? 0;
    final otherCost = _number(_otherCostController.text) ?? 0;

    if (amount == null) return;

    setState(() => _saving = true);

    try {
      final deadline =
      _deadlineController.text.trim().replaceAll('-', '/');

      if (_isEditing) {
        final id = int.tryParse(
          widget.charge!['id']?.toString() ?? '',
        );

        if (id == null) {
          throw Exception('شناسه شارژ معتبر نیست.');
        }

        await widget.service.updateCharge(
          id: id,
          name: _nameController.text.trim(),
          fixAmount: amount,
          paymentDeadline: deadline,
          otherCostAmount: otherCost,
          paymentPenaltyAmount: penalty,
          details: _detailsController.text.trim(),
        );
      } else {
        await widget.service.createCharge(
          name: _nameController.text.trim(),
          fixAmount: amount,
          paymentDeadline: deadline,
          otherCostAmount: otherCost,
          paymentPenaltyAmount: penalty,
          details: _detailsController.text.trim(),
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
            textAlign: TextAlign.right,
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8FC),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(22),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + bottomInset,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _isEditing
                      ? 'ویرایش شارژ واحدی'
                      : 'ثبت شارژ واحدی',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _field(
                  controller: _nameController,
                  label: 'ماه و سال شارژ',
                  hint: 'مثلاً مهر ۱۴۰۵',
                  validator: (v) => _required(v, 'ماه و سال شارژ'),
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _amountController,
                  label: 'مبلغ شارژ هر واحد (تومان)',
                  hint: 'مثلاً ۱۵۰۰۰۰۰',
                  keyboardType: TextInputType.number,
                  validator: (v) => _validateAmount(
                    v,
                    label: 'مبلغ شارژ',
                    allowZero: false,
                  ),
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _deadlineController,
                  label: 'مهلت پرداخت شمسی',
                  hint: '1405/07/20',
                  validator: _validateDeadline,
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _otherCostController,
                  label: 'سایر هزینه‌ها (تومان)',
                  keyboardType: TextInputType.number,
                  validator: (v) => _validateAmount(
                    v,
                    label: 'سایر هزینه‌ها',
                  ),
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _penaltyController,
                  label: 'جریمه دیرکرد (درصد)',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final error = _validateAmount(
                      v,
                      label: 'درصد جریمه',
                    );

                    if (error != null) return error;

                    if ((_number(v ?? '') ?? 0) > 100) {
                      return 'درصد جریمه نمی‌تواند بیشتر از ۱۰۰ باشد.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _detailsController,
                  label: 'توضیحات',
                  hint: 'اختیاری',
                  maxLines: 3,
                  requiredField: false,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: purpleColor,
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
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _saving
                          ? 'در حال ذخیره...'
                          : (_isEditing
                          ? 'ذخیره تغییرات'
                          : 'ثبت شارژ'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool requiredField = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: requiredField ? validator : null,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
