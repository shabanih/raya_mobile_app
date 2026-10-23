import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_civil_charge_service.dart';
import 'manager_civil_charge_units_screen.dart';
// تبدیل اعداد انگلیسی و عربی به فارسی در تمام صفحه
String _faDigits(dynamic value) {
  const english = '0123456789';
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const persian = '۰۱۲۳۴۵۶۷۸۹';

  return value.toString().replaceAllMapped(
    RegExp(r'[0-9٠-٩]'),
        (match) {
      final digit = match.group(0)!;
      final index = english.indexOf(digit);

      if (index >= 0) return persian[index];

      final arabicIndex = arabic.indexOf(digit);
      return arabicIndex >= 0 ? persian[arabicIndex] : digit;
    },
  );
}

// تبدیل اعداد فارسی و عربی به انگلیسی برای ذخیره‌سازی
String _enDigits(String value) {
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  const english = '0123456789';

  return value.replaceAllMapped(
    RegExp(r'[۰-۹٠-٩]'),
        (match) {
      final digit = match.group(0)!;
      final p = persian.indexOf(digit);
      if (p >= 0) return english[p];

      final a = arabic.indexOf(digit);
      return a >= 0 ? english[a] : digit;
    },
  );
}

class _PersianDigitsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = _faDigits(newValue.text);

    return newValue.copyWith(
      text: text,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}

class ManagerCivilChargesScreen extends StatefulWidget {
  const ManagerCivilChargesScreen({super.key});

  @override
  State<ManagerCivilChargesScreen> createState() =>
      _ManagerCivilChargesScreenState();
}

class _ManagerCivilChargesScreenState
    extends State<ManagerCivilChargesScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  List<Map<String, dynamic>> _charges = [];
  bool _loading = true;
  String _search = '';

  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);

  @override
  void initState() {
    super.initState();
    _loadCharges();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCharges() async {
    if (mounted) setState(() => _loading = true);

    try {
      final result = await ManagerCivilChargeService.getCharges();

      if (!mounted) return;

      setState(() {
        _charges = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _message(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _faDigits(text),
          textDirection: TextDirection.rtl,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredCharges {
    final query = _search.trim().toLowerCase();

    if (query.isEmpty) return _charges;

    return _charges.where((charge) {
      final name = (charge['name'] ?? '').toString().toLowerCase();
      final details =
      (charge['details'] ?? '').toString().toLowerCase();

      return name.contains(query) || details.contains(query);
    }).toList();
  }

  String _unitScopeLabel(dynamic value) {
    switch ((value ?? 'all').toString()) {
      case 'occupied':
        return 'فقط واحدهای ساکن‌دار';
      case 'vacant':
        return 'فقط واحدهای خالی';
      case 'all':
      default:
        return 'همه واحدها';
    }
  }

  String _money(dynamic value) {
    final number = ManagerCivilChargeService.toInt(value);
    final digits = number.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);

      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    return _faDigits(buffer.toString());
  }

  String _dateText(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'ثبت نشده';
    }

    final raw = _enDigits(value.toString().trim());

    try {
      final parts = raw.split('T').first.split('-');

      if (parts.length != 3) return _faDigits(raw);

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      if (year >= 1900 && year <= 2200) {
        final jalali = Gregorian(year, month, day).toJalali();
        return _displayJalali(jalali);
      }

      return _displayJalali(Jalali(year, month, day));
    } catch (_) {
      return _faDigits(raw);
    }
  }

  String _displayJalali(Jalali date) {
    return _faDigits(
      '${date.year.toString().padLeft(4, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.day.toString().padLeft(2, '0')}',
    );
  }
  Future<void> _openCivilChargeUnits(
      Map<String, dynamic> charge,
      ) async {
    final id = ManagerCivilChargeService.toInt(charge['id']);

    if (id <= 0) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerCivilChargeUnitsScreen(
          chargeId: id,
          chargeName: (charge['name'] ?? 'شارژ عمرانی').toString(),
        ),
      ),
    );

    if (mounted) {
      await _loadCharges();
    }
  }
  Future<void> _openForm({
    Map<String, dynamic>? charge,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CivilChargeFormSheet(charge: charge),
    );

    if (saved == true && mounted) {
      await _loadCharges();
    }
  }

  Future<void> _deleteCharge(Map<String, dynamic> charge) async {
    final id = ManagerCivilChargeService.toInt(charge['id']);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'حذف شارژ عمرانی',
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'آیا از حذف «${charge['name'] ?? 'شارژ عمرانی'}» مطمئن هستید؟',
          textDirection: TextDirection.rtl,
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
      await ManagerCivilChargeService.deleteCharge(id);

      if (!mounted) return;

      _message('شارژ عمرانی حذف شد.');
      await _loadCharges();
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showDetails(Map<String, dynamic> charge) {
    final documents =
    ManagerCivilChargeService.getDocuments(charge);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'جزئیات شارژ عمرانی',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _detailRow('عنوان', charge['name'] ?? '-'),
                  _detailRow(
                    'مبلغ شارژ',
                    '${_money(charge['amount'])} تومان',
                  ),
                  _detailRow(
                    'پیش‌پرداخت',
                    ManagerCivilChargeService.toInt(charge['prepayment']) == 0
                        ? '۰'
                        : '${_money(charge['prepayment'])} تومان',
                  ),
                  _detailRow(
                    'تعداد اقساط',
                    _faDigits(charge['installment_count'] ?? 0),
                  ),
                  _detailRow(
                    'محدوده واحدها',
                    _unitScopeLabel(charge['unit_scope']),
                  ),
                  _detailRow(
                    'تعداد واحدهای مشمول',
                    charge['eligible_unit_count'] ??
                        charge['total_unit_count'] ??
                        0,
                  ),
                  _detailRow(
                    'اولین سررسید',
                    _dateText(charge['first_due_date']),
                  ),
                  _detailRow(
                    'توضیحات',
                    (charge['details'] ?? '').toString().isEmpty
                        ? 'ندارد'
                        : _faDigits(charge['details']),
                  ),
                  const Divider(height: 28),
                  const Text(
                    'مدارک ثبت‌شده',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (documents.isEmpty)
                    const Text('مدرکی ثبت نشده است.')
                  else
                    ...documents.map((document) {
                      final name = document['name'] ??
                          document['filename'] ??
                          document['document'] ??
                          'مدرک پیوست‌شده';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.attach_file,
                          color: _purple,
                        ),
                        title: Text(
                          _faDigits(name.toString().split('/').last),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('بستن'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              title,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              _faDigits(value),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredCharges;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('شارژ عمرانی'),
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'به‌روزرسانی',
              onPressed: _loadCharges,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('شارژ جدید'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                textDirection: TextDirection.rtl,
                onChanged: (value) {
                  setState(() => _search = value);
                },
                decoration: InputDecoration(
                  hintText: 'جست‌وجوی عنوان یا توضیحات',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.isEmpty
                      ? null
                      : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _search = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : items.isEmpty
                  ? RefreshIndicator(
                onRefresh: _loadCharges,
                child: ListView(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 140),
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 58,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Center(
                      child: Text('شارژ عمرانی‌ای پیدا نشد.'),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadCharges,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    100,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final charge = items[index];

                    return Card(
                      margin:
                      const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor:
                                  Color(0xFFE0F7FA),
                                  child: Icon(
                                    Icons.construction,
                                    color: _teal,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _faDigits(
                                      charge['name'] ??
                                          'شارژ عمرانی',
                                    ),
                                    style: const TextStyle(
                                      fontWeight:
                                      FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (action) {
                                    if (action == 'send') {
                                      _openCivilChargeUnits(charge);
                                    } else if (action == 'details') {
                                      _showDetails(charge);
                                    } else if (action == 'edit') {
                                      _openForm(charge: charge);
                                    } else if (action == 'delete') {
                                      _deleteCharge(charge);
                                    }
                                  },
                                  itemBuilder: (_) {
                                    final sentCount = ManagerCivilChargeService.toInt(
                                      charge['sent_units_count'],
                                    );

                                    final isSent = charge['is_sent'] == true || sentCount > 0;

                                    return [
                                      const PopupMenuItem(
                                        value: 'send',
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(Icons.send_rounded, color: Color(0xFF00ACC1)),
                                          title: Text('ارسال شارژ به واحدها'),
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'details',
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(Icons.info_outline),
                                          title: Text('جزئیات شارژ'),
                                        ),
                                      ),
                                      if (!isSent) ...[
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: Icon(Icons.edit_outlined),
                                            title: Text('ویرایش'),
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            leading: Icon(Icons.delete_outline, color: Colors.red),
                                            title: Text('حذف'),
                                          ),
                                        ),
                                      ],
                                    ];
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _detailRow(
                              'مبلغ شارژ عمرانی',
                              '${_money(charge['amount'])} تومان',
                            ),
                            // _detailRow(
                            //   'پیش‌پرداخت',
                            //   '${_money(charge['prepayment'])} تومان',
                            // ),
                            // _detailRow(
                            //   'تعداد اقساط',
                            //   charge['installment_count'] ?? 0,
                            // ),
                            // _detailRow(
                            //   'محدوده واحدها',
                            //   _unitScopeLabel(charge['unit_scope']),
                            // ),
                            // _detailRow(
                            //   'واحدهای مشمول',
                            //   charge['eligible_unit_count'] ??
                            //       charge['total_unit_count'] ??
                            //       0,
                            // ),
                            _detailRow(
                              'اولین سررسید',
                              _dateText(
                                charge['first_due_date'],
                              ),
                            ),
                            if ((charge['details'] ?? '')
                                .toString()
                                .trim()
                                .isNotEmpty)
                              Padding(
                                padding:
                                const EdgeInsets.only(top: 8),
                                child: Text(
                                  _faDigits(charge['details']),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Builder(
                              builder: (context) {
                                final sentCount = ManagerCivilChargeService.toInt(
                                  charge['sent_units_count'],
                                );

                                final totalCount = ManagerCivilChargeService.toInt(
                                  charge['total_unit_count'],
                                );

                                return Row(
                                  children: [
                                    Icon(
                                      sentCount > 0
                                          ? Icons.mark_email_read_outlined
                                          : Icons.mark_email_unread_outlined,
                                      size: 20,
                                      color: sentCount > 0 ? Colors.green : Colors.grey,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'ارسال‌شده: ${_faDigits(sentCount)} از ${_faDigits(totalCount)} واحد',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: sentCount > 0
                                            ? Colors.green.shade700
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            // OutlinedButton.icon(
                            //   onPressed: () =>
                            //       _showDetails(charge),
                            //   icon: const Icon(
                            //     Icons.visibility_outlined,
                            //   ),
                            //   label: const Text(
                            //     'مشاهده جزئیات و مدارک',
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CivilChargeFormSheet extends StatefulWidget {
  final Map<String, dynamic>? charge;

  const _CivilChargeFormSheet({this.charge});

  @override
  State<_CivilChargeFormSheet> createState() =>
      _CivilChargeFormSheetState();
}

class _CivilChargeFormSheetState
    extends State<_CivilChargeFormSheet> {
  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _prepaymentController;
  late final TextEditingController _installmentsController;
  late final TextEditingController _detailsController;

  Jalali? _firstDueDate;
  String _unitScope = 'all';
  final List<XFile> _newFiles = [];
  bool _saving = false;

  bool get _isEditing => widget.charge != null;

  @override
  void initState() {
    super.initState();

    final charge = widget.charge;

    _nameController = TextEditingController(
      text: (charge?['name'] ?? '').toString(),
    );
    _amountController = TextEditingController(
      text: _faDigits(charge?['amount'] ?? ''),
    );
    _prepaymentController = TextEditingController(
      text: _faDigits(charge?['prepayment'] ?? 0),
    );
    _installmentsController = TextEditingController(
      text: _faDigits(charge?['installment_count'] ?? 0),
    );
    _detailsController = TextEditingController(
      text: _faDigits(charge?['details'] ?? ''),
    );

    _firstDueDate = _parseJalali(charge?['first_due_date']);
    final savedScope = (charge?['unit_scope'] ?? 'all').toString();
    _unitScope = ['all', 'occupied', 'vacant'].contains(savedScope)
        ? savedScope
        : 'all';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _prepaymentController.dispose();
    _installmentsController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Jalali? _parseJalali(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }

    try {
      final raw = _enDigits(value.toString().trim());
      final parts = raw.split('T').first.split('-');

      if (parts.length != 3) return null;

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      if (year >= 1900 && year <= 2200) {
        return Gregorian(year, month, day).toJalali();
      }

      return Jalali(year, month, day);
    } catch (_) {
      return null;
    }
  }

  // تاریخ شمسی به میلادی تبدیل می‌شود تا API تاریخ استاندارد دریافت کند.
  String _formatApiDate(Jalali date) {
    final gregorian = date.toGregorian();

    return '${gregorian.year.toString().padLeft(4, '0')}-'
        '${gregorian.month.toString().padLeft(2, '0')}-'
        '${gregorian.day.toString().padLeft(2, '0')}';
  }

  String _displayJalali(Jalali date) {
    return _faDigits(
      '${date.year.toString().padLeft(4, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.day.toString().padLeft(2, '0')}',
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _faDigits(message),
          textDirection: TextDirection.rtl,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int _parseAmount(String value) {
    final normalized = _enDigits(value)
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('٫', '.')
        .replaceAll(' ', '')
        .replaceAll('،', '');

    return int.tryParse(normalized) ?? 0;
  }

  Future<void> _pickFiles() async {
    final remaining = 2 - _newFiles.length;

    if (remaining <= 0) {
      _showMessage('حداکثر دو تصویر جدید می‌توانید انتخاب کنید.');
      return;
    }

    try {
      final images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );

      if (!mounted || images.isEmpty) return;

      final available = images.take(remaining).toList();

      setState(() {
        _newFiles.addAll(available);
      });

      if (images.length > remaining) {
        _showMessage(
          'به دلیل محدودیت، فقط ${_faDigits(remaining)} تصویر اضافه شد.',
        );
      }
    } catch (e) {
      _showMessage('انتخاب تصویر ناموفق بود: $e');
    }
  }

  Future<void> _selectDueDate() async {
    final selected = await showModalBottomSheet<Jalali>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PersianCalendarSheet(
        initialDate: _firstDueDate ?? Jalali.now(),
      ),
    );

    if (selected == null || !mounted) return;

    setState(() => _firstDueDate = selected);
  }


  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final amount = _parseAmount(_amountController.text);
    final prepayment = _prepaymentController.text.trim().isEmpty
        ? amount
        : _parseAmount(_prepaymentController.text);

    final installments = _installmentsController.text.trim().isEmpty
        ? 0
        : _parseAmount(_installmentsController.text);
    final details = _detailsController.text.trim();

    if (name.isEmpty) {
      _showMessage('عنوان شارژ را وارد کنید.');
      return;
    }

    if (amount <= 0) {
      _showMessage('مبلغ شارژ باید بیشتر از صفر باشد.');
      return;
    }

    if (prepayment > amount) {
      _showMessage('پیش‌پرداخت نمی‌تواند بیشتر از مبلغ شارژ باشد.');
      return;
    }

    if (prepayment > 0 &&
        prepayment < amount &&
        installments <= 0) {
      _showMessage(
        'برای مبلغ باقی‌مانده، تعداد اقساط را وارد کنید.',
      );
      return;
    }

    if (_firstDueDate == null) {
      _showMessage('تاریخ اولین سررسید را انتخاب کنید.');
      return;
    }

    setState(() => _saving = true);

    try {
      final files = _newFiles.map((image) => File(image.path)).toList();
      final date = _formatApiDate(_firstDueDate!);

      if (_isEditing) {
        await ManagerCivilChargeService.updateCharge(
          id: ManagerCivilChargeService.toInt(widget.charge!['id']),
          name: name,
          amount: amount,
          prepayment: prepayment,
          installmentCount: installments,
          firstDueDate: date,
          unitScope: _unitScope,
          details: details,
          files: files,
        );
      } else {
        await ManagerCivilChargeService.createCharge(
          name: name,
          amount: amount,
          prepayment: prepayment,
          installmentCount: installments,
          firstDueDate: date,
          unitScope: _unitScope,
          details: details,
          files: files,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }


  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool requiredField = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final isNumeric = keyboardType == TextInputType.number;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        textDirection: TextDirection.rtl,
        keyboardType: keyboardType,
        inputFormatters:
        isNumeric ? [_PersianDigitsFormatter()] : null,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _purple),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';

          if (requiredField && text.isEmpty) {
            return 'این فیلد الزامی است.';
          }

          if (isNumeric && text.isNotEmpty) {
            final parsed = _parseAmount(text);

            if (parsed < 0) return 'مقدار معتبر وارد کنید.';
          }

          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existingDocuments =
    ManagerCivilChargeService.getDocuments(
      widget.charge ?? <String, dynamic>{},
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(22),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing
                            ? 'ویرایش شارژ عمرانی'
                            : 'ثبت شارژ عمرانی جدید',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.pop(context, false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _field(
                        label: 'عنوان شارژ عمرانی',
                        controller: _nameController,
                        icon: Icons.title,
                        requiredField: true,
                      ),
                      _field(
                        label: 'مبلغ شارژ (تومان)',
                        controller: _amountController,
                        icon: Icons.payments_outlined,
                        requiredField: true,
                        keyboardType: TextInputType.number,
                      ),
                      _field(
                        label: 'مبلغ پیش‌پرداخت (تومان)',
                        controller: _prepaymentController,
                        icon: Icons.account_balance_wallet_outlined,
                        requiredField: true,
                        keyboardType: TextInputType.number,
                      ),
                      _field(
                        label: 'تعداد اقساط',
                        controller: _installmentsController,
                        icon: Icons.calendar_month,
                        requiredField: true,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 2),
                      DropdownButtonFormField<String>(
                        value: _unitScope,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'محدوده واحدهای مشمول',
                          prefixIcon: const Icon(
                            Icons.apartment,
                            color: _purple,
                          ),
                          helperText:
                          'مبنای تشخیص سکونت، وضعیت سکونت ثبت‌شده برای واحد است.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('همه واحدها'),
                          ),
                          DropdownMenuItem(
                            value: 'occupied',
                            child: Text('فقط واحدهای ساکن‌دار'),
                          ),
                          DropdownMenuItem(
                            value: 'vacant',
                            child: Text('فقط واحدهای خالی'),
                          ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) {
                          if (value == null) return;
                          setState(() => _unitScope = value);
                        },
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _saving ? null : _selectDueDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'اولین سررسید شمسی *',
                            prefixIcon: const Icon(
                              Icons.event,
                              color: _purple,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorText: _firstDueDate == null
                                ? null
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _firstDueDate == null
                                      ? 'انتخاب تاریخ شمسی (الزامی)'
                                      : _displayJalali(_firstDueDate!),
                                  style: TextStyle(
                                    color: _firstDueDate == null
                                        ? Colors.grey.shade600
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: _purple,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _field(
                        label: 'توضیحات',
                        controller: _detailsController,
                        icon: Icons.notes,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'مدارک قبلی',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (existingDocuments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text('مدرکی ثبت نشده است.'),
                        )
                      else
                        ...existingDocuments.map((document) {
                          final name = document['name'] ??
                              document['filename'] ??
                              document['document'] ??
                              'مدرک ثبت‌شده';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.attach_file,
                              color: _purple,
                            ),
                            title: Text(
                              _faDigits(name.toString().split('/').last),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      const Divider(height: 28),
                      const Text(
                        'پیوست تصاویر (حداکثر ۲ تصویر جدید)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _saving ? null : _pickFiles,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: Text(
                          _newFiles.length >= 2
                              ? 'ظرفیت انتخاب تصویر تکمیل شده'
                              : 'انتخاب تصویر',
                        ),
                      ),
                      ..._newFiles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final image = entry.value;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.image_outlined,
                            color: _teal,
                          ),
                          title: Text(
                            _faDigits(image.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: 'حذف تصویر انتخاب‌شده',
                            onPressed: _saving
                                ? null
                                : () {
                              setState(() {
                                _newFiles.removeAt(index);
                              });
                            },
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _teal,
                          ),
                          onPressed: _saving ? null : _save,
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

// انتخاب‌گر تقویم شمسی با چیدمان عمودی و نمایش اعداد فارسی
class _PersianCalendarSheet extends StatefulWidget {
  final Jalali initialDate;

  const _PersianCalendarSheet({
    required this.initialDate,
  });

  @override
  State<_PersianCalendarSheet> createState() =>
      _PersianCalendarSheetState();
}

class _PersianCalendarSheetState
    extends State<_PersianCalendarSheet> {
  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);

  static const List<String> _months = [
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

  static const List<String> _weekdays = [
    'ش',
    'ی',
    'د',
    'س',
    'چ',
    'پ',
    'ج',
  ];

  late int _year;
  late int _month;
  late int _selectedDay;

  @override
  void initState() {
    super.initState();

    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;
  }

  int get _monthLength => Jalali(_year, _month, 1).monthLength;

  int get _firstWeekdayOffset {
    final firstDay = Jalali(_year, _month, 1).toGregorian();
    // هفته از شنبه شروع می‌شود.
    return (DateTime(firstDay.year, firstDay.month, firstDay.day).weekday +
        1) %
        7;
  }

  void _changeMonth(int difference) {
    var year = _year;
    var month = _month + difference;

    while (month < 1) {
      month += 12;
      year--;
    }

    while (month > 12) {
      month -= 12;
      year++;
    }

    setState(() {
      _year = year;
      _month = month;

      final maxDay = Jalali(_year, _month, 1).monthLength;
      if (_selectedDay > maxDay) _selectedDay = maxDay;
    });
  }

  void _changeYear(int difference) {
    final newYear = _year + difference;

    if (newYear < 1200 || newYear > 1600) return;

    setState(() {
      _year = newYear;

      final maxDay = Jalali(_year, _month, 1).monthLength;
      if (_selectedDay > maxDay) _selectedDay = maxDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = Jalali.now();
    final cells = <Widget>[];

    for (var i = 0; i < _firstWeekdayOffset; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var day = 1; day <= _monthLength; day++) {
      final selected = day == _selectedDay;
      final isToday = today.year == _year &&
          today.month == _month &&
          today.day == day;

      cells.add(
        InkWell(
          onTap: () => setState(() => _selectedDay = day),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? _purple : null,
              borderRadius: BorderRadius.circular(30),
              border: isToday && !selected
                  ? Border.all(color: _teal, width: 1.5)
                  : null,
            ),
            child: Text(
              _faDigits(day),
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight:
                selected || isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(22),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'انتخاب تاریخ شمسی',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'سال قبل',
                      onPressed: () => _changeYear(-1),
                      icon: const Icon(Icons.keyboard_double_arrow_right),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _faDigits(_year),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'سال بعد',
                      onPressed: () => _changeYear(1),
                      icon: const Icon(Icons.keyboard_double_arrow_left),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<int>(
                  value: _month,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'ماه شمسی',
                    prefixIcon: const Icon(
                      Icons.calendar_month,
                      color: _purple,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: List.generate(
                    12,
                        (index) => DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text(_months[index]),
                    ),
                  ),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      _month = value;
                      final maxDay =
                          Jalali(_year, _month, 1).monthLength;
                      if (_selectedDay > maxDay) {
                        _selectedDay = maxDay;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: _weekdays
                      .map(
                        (weekday) => Expanded(
                      child: Center(
                        child: Text(
                          weekday,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _purple,
                          ),
                        ),
                      ),
                    ),
                  )
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1.15,
                  children: cells,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('انصراف'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _teal,
                        ),
                        onPressed: () {
                          Navigator.pop(
                            context,
                            Jalali(_year, _month, _selectedDay),
                          );
                        },
                        child: const Text('تأیید تاریخ'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

