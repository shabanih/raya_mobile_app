import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_expense_service.dart';

class PersianDigitFormatter extends TextInputFormatter {
  static const String _englishDigits = '0123456789';
  static const String _persianDigits = '۰۱۲۳۴۵۶۷۸۹';

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final converted = newValue.text.replaceAllMapped(
      RegExp(r'[0-9]'),
          (match) => _persianDigits[_englishDigits.indexOf(match.group(0)!)],
    );
    return newValue.copyWith(
      text: converted,
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}

class ManagerExpensesScreen extends StatefulWidget {
  const ManagerExpensesScreen({super.key});

  @override
  State<ManagerExpensesScreen> createState() => _ManagerExpensesScreenState();
}

class _ManagerExpensesScreenState extends State<ManagerExpensesScreen> {
  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);
  static const Color _background = Color(0xFFF6F7FB);

  final ManagerExpenseService _service = ManagerExpenseService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _categories = [];

  bool _loading = true;
  String _paymentFilter = 'all';
  int? _categoryFilter;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _service.getExpenses(paymentStatus: _paymentFilter),
        _service.getCategories(),
      ]);

      if (!mounted) return;
      setState(() {
        _expenses = results[0];
        _categories = results[1];
      });
    } catch (e) {
      if (mounted) _showMessage(_cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, textDirection: TextDirection.rtl),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Colors.red.shade700 : _teal,
        ),
      );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(_normalizeDigits(value?.toString() ?? '')) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    final text = _normalizeDigits((value ?? '').toString())
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('٫', '.');
    return double.tryParse(text) ?? 0;
  }

  String _normalizeDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    var output = value;
    for (var i = 0; i < 10; i++) {
      output = output.replaceAll(persian[i], '$i');
      output = output.replaceAll(arabic[i], '$i');
    }
    return output;
  }

  String _persianDigits(String value) {
    const digits = '۰۱۲۳۴۵۶۷۸۹';
    return value.replaceAllMapped(
      RegExp(r'[0-9]'),
          (match) => digits[int.parse(match.group(0)!)],
    );
  }

  String _money(dynamic value) {
    final amount = _toDouble(value).round();
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
    );
    return '${_persianDigits(formatted)} تومان';
  }

  String _dateText(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'بدون تاریخ';
    }
    final date = DateTime.tryParse(value.toString());
    if (date == null) return _persianDigits(value.toString());
    final jalali = Gregorian.fromDateTime(date).toJalali();
    return _persianDigits(
      '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/'
          '${jalali.day.toString().padLeft(2, '0')}',
    );
  }

  bool _isPaid(Map<String, dynamic> expense) {
    final value = expense['is_paid'];
    return value == true || value == 1 || value == 'true';
  }

  Future<void> _openPaymentForm(Map<String, dynamic> expense) async {
    final expenseId = _toInt(expense['id']);
    if (expenseId <= 0) {
      _showMessage('شناسه هزینه معتبر نیست.', error: true);
      return;
    }
    if (_isPaid(expense)) {
      _showMessage('این هزینه قبلاً پرداخت شده است.', error: true);
      return;
    }
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpensePaymentSheet(expense: expense, service: _service),
    );
    if (result == true && mounted) {
      await _loadData();
      if (mounted) _showMessage('پرداخت هزینه با موفقیت ثبت شد.');
    }
  }

  Future<void> _cancelExpensePayment(Map<String, dynamic> expense) async {
    final expenseId = _toInt(expense['id']);
    if (expenseId <= 0) {
      _showMessage('شناسه هزینه معتبر نیست.', error: true);
      return;
    }
    if (!_isPaid(expense)) {
      _showMessage('این هزینه پرداخت نشده است.', error: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('لغو پرداخت'),
          content: Text('آیا از لغو پرداخت این هزینه به مبلغ ${_money(expense['amount'])} مطمئن هستید؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('انصراف')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('لغو پرداخت'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.cancelExpensePayment(expenseId);
      if (!mounted) return;
      await _loadData();
      if (mounted) _showMessage('پرداخت هزینه با موفقیت لغو شد.');
    } catch (e) {
      if (mounted) _showMessage(_cleanError(e), error: true);
    }
  }

  String _categoryName(Map<String, dynamic> expense) {
    final dynamic category = expense['category'];
    final directTitle = expense['category_title'] ?? expense['category_name'];
    if (directTitle != null && directTitle.toString().trim().isNotEmpty) {
      return directTitle.toString();
    }
    if (category is Map) {
      final title = category['title'] ?? category['name'];
      if (title != null && title.toString().trim().isNotEmpty) {
        return title.toString();
      }
    }

    dynamic rawId = expense['category_id'];
    if (rawId == null && category is num) {
      rawId = category;
    } else if (rawId == null && category is String) {
      rawId = int.tryParse(category);
    }
    final categoryId = _toInt(rawId);
    for (final item in _categories) {
      if (_toInt(item['id']) == categoryId && categoryId > 0) {
        return item['title']?.toString() ?? 'بدون دسته‌بندی';
      }
    }
    if (category is String && category.trim().isNotEmpty) return category;
    return 'بدون دسته‌بندی';
  }

  List<Map<String, dynamic>> get _filteredExpenses {
    final query = _normalizeDigits(_search.trim()).toLowerCase();
    return _expenses.where((expense) {
      if (_categoryFilter != null) {
        final categoryId = _toInt(
          expense['category_id'] ??
              (expense['category'] is num ? expense['category'] : null),
        );
        if (categoryId != _categoryFilter) return false;
      }
      if (query.isNotEmpty) {
        final searchable = [
          expense['description'],
          expense['details'],
          expense['doc_no'],
          expense['financial_document_number'],
          _categoryName(expense),
        ].whereType<Object>().join(' ').toLowerCase();
        if (!searchable.contains(query)) return false;
      }
      return true;
    }).toList();
  }

  double get _filteredTotal => _filteredExpenses.fold<double>(
    0,
        (sum, item) => sum + _toDouble(item['amount']),
  );

  Future<void> _changePaymentFilter(String value) async {
    if (_paymentFilter == value) return;
    setState(() => _paymentFilter = value);
    await _loadData();
  }

  Future<void> _openForm({Map<String, dynamic>? expense}) async {
    if (expense != null && _isPaid(expense)) {
      _showMessage('هزینه پرداخت‌شده قابل ویرایش نیست.', error: true);
      return;
    }
    if (_categories.isEmpty) {
      _showMessage('ابتدا یک دسته‌بندی هزینه ایجاد کنید.', error: true);
      await _openCategories();
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseFormSheet(
        categories: _categories,
        expense: expense,
        service: _service,
      ),
    );
    if (result == true && mounted) {
      await _loadData();
      _showMessage(expense == null ? 'هزینه با موفقیت ثبت شد.' : 'هزینه ویرایش شد.');
    }
  }

  Future<void> _openCategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManagerExpenseCategoriesScreen(service: _service),
      ),
    );
    if (mounted) await _loadData();
  }

  Future<void> _deleteExpense(Map<String, dynamic> expense) async {
    if (_isPaid(expense)) {
      _showMessage('هزینه پرداخت‌شده قابل حذف نیست.', error: true);
      return;
    }
    final id = _toInt(expense['id']);
    if (id <= 0) {
      _showMessage('شناسه هزینه معتبر نیست.', error: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف هزینه'),
          content: const Text('آیا از حذف این هزینه مطمئن هستید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.deleteExpense(id);
      if (!mounted) return;
      await _loadData();
      _showMessage('هزینه حذف شد.');
    } catch (e) {
      if (mounted) _showMessage(_cleanError(e), error: true);
    }
  }

  void _showExpenseDetails(Map<String, dynamic> expense) {
    final invoiceNo = expense['doc_no'];
    final financialDocNo = expense['financial_document_number'];
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('جزئیات هزینه'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailLine('شرح', expense['description']),
                _detailLine('دسته‌بندی', _categoryName(expense)),
                _detailLine('مبلغ', _money(expense['amount'])),
                _detailLine('تاریخ', _dateText(expense['date'])),
                _detailLine(
                  'شماره فاکتور',
                  invoiceNo == null || invoiceNo.toString().trim().isEmpty
                      ? '—'
                      : _persianDigits(invoiceNo.toString()),
                ),
                _detailLine(
                  'شماره سند مالی',
                  financialDocNo == null || financialDocNo.toString().trim().isEmpty
                      ? '—'
                      : _persianDigits(financialDocNo.toString()),
                ),
                _detailLine('وضعیت', _isPaid(expense) ? 'پرداخت‌شده' : 'پرداخت‌نشده'),
                if (_isPaid(expense)) ...[
                  _detailLine(
                    'بانک',
                    '${_paymentBankName(expense) ?? 'نامشخص'} - ${expense['account_no'] == null || expense['account_no'].toString().trim().isEmpty ? '---' : _persianDigits(expense['account_no'].toString())}',
                  ),
                  _detailLine('دریافت‌کننده', expense['receiver_name'] ?? expense['receiver_display_name']),
                  _detailLine('تاریخ پرداخت', _dateText(expense['payment_date'])),
                  _detailLine(
                    'کد پیگیری',
                    expense['transaction_reference'] == null || expense['transaction_reference'].toString().trim().isEmpty
                        ? '—'
                        : _persianDigits(expense['transaction_reference'].toString()),
                  ),
                ],
                _detailLine('توضیحات', expense['details']),
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

  dynamic _paymentBankName(Map<String, dynamic> expense) {
    final bank = expense['bank'];
    if (bank is Map) {
      return bank['bank_name'] ?? bank['name'] ?? bank['title'] ?? bank['account_name'];
    }
    return expense['bank_name'] ?? expense['bank_display'] ?? bank;
  }

  Widget _detailLine(String label, dynamic value) {
    final text = value == null || value.toString().trim().isEmpty
        ? '—'
        : value.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text('$label: $text', style: const TextStyle(height: 1.6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenses = _filteredExpenses;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: const Text('مدیریت هزینه‌ها',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'دسته‌بندی‌ها',
              onPressed: _openCategories,
              icon: const Icon(Icons.category_rounded),
            ),
            IconButton(
              tooltip: 'تازه‌سازی',
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(),
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('ثبت هزینه'),
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _summaryCard(expenses.length, _filteredTotal),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    textDirection: TextDirection.rtl,
                    onChanged: (value) => setState(() => _search = value),
                    decoration: InputDecoration(
                      hintText: 'جست‌وجوی شرح، سند یا دسته‌بندی...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _filterChip('همه', 'all'),
                        _filterChip('پرداخت‌نشده', 'unpaid'),
                        _filterChip('پرداخت‌شده', 'paid'),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: DropdownButtonFormField<int?>(
                    value: _categoryFilter,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'دسته‌بندی هزینه',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('همه دسته‌بندی‌ها'),
                      ),
                      ..._categories.map(
                            (category) => DropdownMenuItem<int?>(
                          value: _toInt(category['id']),
                          child: Text(
                            category['title']?.toString() ?? 'بدون عنوان',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _categoryFilter = value),
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (expenses.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _emptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => _expenseCard(expenses[index]),
                      childCount: expenses.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(int count, double total) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_teal, Color(0xFF00838F)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _teal.withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('جمع هزینه‌های نمایش‌داده‌شده',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 5),
                Text(_money(total),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
                const SizedBox(height: 5),
                Text('${_persianDigits(count.toString())} هزینه',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String title, String value) {
    final selected = _paymentFilter == value;
    return ChoiceChip(
      label: Text(title),
      selected: selected,
      selectedColor: _teal.withValues(alpha: 0.16),
      checkmarkColor: _teal,
      labelStyle: TextStyle(
        color: selected ? _teal : Colors.black87,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => _changePaymentFilter(value),
    );
  }

  Widget _expenseCard(Map<String, dynamic> expense) {
    final paid = _isPaid(expense);
    final description = expense['description']?.toString().trim() ?? '';
    final title = description.isEmpty ? 'هزینه بدون شرح' : description;
    final docNo = expense['financial_document_number'] ?? expense['doc_no'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDEDF3)),
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: paid ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    paid ? Icons.check_circle_outline_rounded : Icons.pending_actions_rounded,
                    color: paid ? Colors.green.shade700 : Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF303044))),
                      const SizedBox(height: 5),
                      Text(_categoryName(expense),
                          style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(_money(expense['amount']),
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                          color: _purple, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _info(Icons.calendar_month_rounded, _dateText(expense['date'])),
                _info(
                  paid ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  paid ? 'پرداخت‌شده' : 'پرداخت‌نشده',
                  color: paid ? Colors.green : Colors.orange.shade800,
                ),
                if (docNo != null && docNo.toString().isNotEmpty)
                  _info(Icons.numbers_rounded, 'فاکتور ${_persianDigits(docNo.toString())}'),
              ],
            ),
            if ((expense['details'] ?? '').toString().trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                expense['details'].toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54, fontSize: 12, height: 1.7),
              ),
            ],
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 2,
              children: [
                IconButton(
                  tooltip: paid ? 'لغو پرداخت' : 'پرداخت',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: () {
                    if (paid) {
                      _cancelExpensePayment(expense);
                    } else {
                      _openPaymentForm(expense);
                    }
                  },
                  icon: Icon(
                    paid ? Icons.cancel_outlined : Icons.payments_outlined,
                    size: 20,
                    color: paid
                        ? Colors.red.shade700
                        : Colors.green.shade700,
                  ),
                ),
                IconButton(
                  tooltip: 'جزئیات هزینه',
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: () => _showExpenseDetails(expense),
                  icon: const Icon(Icons.visibility_outlined, size: 20, color: _teal),
                ),
                if (!_isPaid(expense))
                  IconButton(
                    tooltip: 'ویرایش هزینه',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () => _openForm(expense: expense),
                    icon: const Icon(Icons.edit_outlined, size: 20, color: _purple),
                  ),
                if (!_isPaid(expense))
                  IconButton(
                    tooltip: 'حذف هزینه',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () => _deleteExpense(expense),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                  ),
                // if (_isPaid(expense))
                //   const Padding(
                //     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                //     child: Text('ثبت‌شده در سرور',
                //         style: TextStyle(color: Colors.black45, fontSize: 10)),
                //   ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text, {Color color = Colors.black54}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 68, color: _teal.withValues(alpha: 0.55)),
            const SizedBox(height: 16),
            const Text('هزینه‌ای پیدا نشد',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'می‌توانید هزینه جدیدی ثبت کنید یا فیلترها را تغییر دهید.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.8),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openForm(),
              style: FilledButton.styleFrom(backgroundColor: _purple),
              icon: const Icon(Icons.add_rounded),
              label: const Text('ثبت هزینه'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseFormSheet extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? expense;
  final ManagerExpenseService service;

  const _ExpenseFormSheet({
    required this.categories,
    required this.service,
    this.expense,
  });

  @override
  State<_ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<_ExpenseFormSheet> {
  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _detailsController = TextEditingController();
  final _docNoController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  int? _categoryId;
  DateTime _date = DateTime.now();
  final List<File> _files = [];
  bool _saving = false;

  bool get _isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    if (expense == null) return;

    final category = expense['category_id'] ??
        (expense['category'] is num ? expense['category'] : null);
    _categoryId = int.tryParse(category?.toString() ?? '');
    _amountController.text = _persianDigits((expense['amount'] ?? '').toString());
    _descriptionController.text = (expense['description'] ?? '').toString();
    _detailsController.text = (expense['details'] ?? '').toString();
    _docNoController.text = _persianDigits((expense['doc_no'] ?? '').toString());

    final dateText = expense['date']?.toString() ?? '';
    final parsedDate = DateTime.tryParse(dateText);
    if (parsedDate != null) _date = parsedDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _detailsController.dispose();
    _docNoController.dispose();
    super.dispose();
  }

  String _normalizeDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    var output = value;
    for (var i = 0; i < 10; i++) {
      output = output.replaceAll(persian[i], '$i');
      output = output.replaceAll(arabic[i], '$i');
    }
    return output.replaceAll(',', '').replaceAll('٬', '').trim();
  }

  String _persianDigits(String value) {
    const digits = '۰۱۲۳۴۵۶۷۸۹';
    return value.replaceAllMapped(
      RegExp(r'[0-9]'),
          (match) => digits[int.parse(match.group(0)!)],
    );
  }

  String _dateString(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _jalaliDateText(DateTime date) {
    final jalali = Gregorian.fromDateTime(date).toJalali();
    return _persianDigits(
      '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/'
          '${jalali.day.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _chooseDate() async {
    final initialJalali = Gregorian.fromDateTime(_date).toJalali();
    final nowJalali = Gregorian.fromDateTime(DateTime.now()).toJalali();

    final selected = await showDialog<Jalali>(
      context: context,
      builder: (dialogContext) => _JalaliDatePickerDialog(
        initialDate: initialJalali.year > nowJalali.year ||
            (initialJalali.year == nowJalali.year &&
                (initialJalali.month > nowJalali.month ||
                    (initialJalali.month == nowJalali.month &&
                        initialJalali.day > nowJalali.day)))
            ? nowJalali
            : initialJalali,
        firstDate: Jalali(1300, 1, 1),
        lastDate: nowJalali,
      ),
    );

    if (selected == null || !mounted) return;

    final selectedDate = selected.toDateTime();
    final today = DateTime.now();

    final selectedDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final todayDay = DateTime(today.year, today.month, today.day);

    if (selectedDay.isAfter(todayDay)) {
      _message('تاریخ پرداخت نمی‌تواند بعد از تاریخ امروز باشد.', error: true);
      return;
    }

    setState(() {
      _date = selectedDate;
    });
  }

  Future<void> _pickDocuments() async {
    try {
      final pickedFiles = await _imagePicker.pickMultipleMedia();
      if (pickedFiles.isEmpty || !mounted) return;

      final remaining = 2 - _files.length;
      if (remaining <= 0) {
        _message('حداکثر دو فایل قابل انتخاب است.', error: true);
        return;
      }
      setState(() {
        _files.addAll(
          pickedFiles.take(remaining).map((file) => File(file.path)),
        );
      });
      if (pickedFiles.length > remaining) {
        _message('حداکثر دو فایل قابل انتخاب است؛ فایل‌های اضافی اضافه نشدند.');
      }
    } catch (e) {
      if (mounted) _message('خطا در انتخاب فایل: $e', error: true);
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, textDirection: TextDirection.rtl),
        backgroundColor: error ? Colors.red.shade700 : _teal,
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      _message('دسته‌بندی هزینه را انتخاب کنید.', error: true);
      return;
    }

    final amount = _normalizeDigits(_amountController.text);
    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) {
      _message('مبلغ هزینه باید بیشتر از صفر باشد.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final expenseId = widget.expense?['id'];
      final parsedId = int.tryParse(expenseId?.toString() ?? '');
      await widget.service.saveExpenseWithFiles(
        expenseId: parsedId,
        categoryId: _categoryId!,
        amount: amount,
        // تاریخ انتخابی شمسی در اینجا به تاریخ میلادی API تبدیل می‌شود.
        date: _dateString(_date),
        description: _descriptionController.text.trim(),
        details: _detailsController.text.trim(),
        docNo: _normalizeDigits(_docNoController.text),
        files: _files,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        _message(e.toString().replaceFirst('Exception: ', ''), error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
          decoration: const BoxDecoration(
            color: Color(0xFFF6F7FB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEdit ? 'ویرایش هزینه' : 'ثبت هزینه جدید',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      DropdownButtonFormField<int>(
                        value: _categoryId,
                        isExpanded: true,
                        decoration: _decoration('دسته‌بندی هزینه *', Icons.category_outlined),
                        items: widget.categories.map((category) {
                          final id = int.tryParse(category['id']?.toString() ?? '');
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(category['title']?.toString() ?? 'بدون عنوان'),
                          );
                        }).where((item) => item.value != null).toList(),
                        onChanged: _saving ? null : (value) => setState(() => _categoryId = value),
                        validator: (value) => value == null ? 'دسته‌بندی را انتخاب کنید.' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [PersianDigitFormatter()],
                        textDirection: TextDirection.rtl,
                        decoration: _decoration('مبلغ به تومان *', Icons.payments_outlined),
                        validator: (value) {
                          final normalized = _normalizeDigits(value ?? '');
                          final amount = double.tryParse(normalized);
                          if (normalized.isEmpty) return 'مبلغ را وارد کنید.';
                          if (amount == null || amount <= 0) return 'مبلغ معتبر و بیشتر از صفر وارد کنید.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _saving ? null : _chooseDate,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: _decoration('تاریخ شمسی هزینه', Icons.calendar_month_outlined),
                          child: Text(_jalaliDateText(_date)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descriptionController,
                        maxLength: 200,
                        textDirection: TextDirection.rtl,
                        decoration: _decoration('شرح هزینه *', Icons.short_text_rounded),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'شرح هزینه را وارد کنید.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _detailsController,
                        minLines: 2,
                        maxLines: 4,
                        textDirection: TextDirection.rtl,
                        decoration: _decoration('توضیحات تکمیلی', Icons.notes_rounded),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _docNoController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [PersianDigitFormatter()],
                        textDirection: TextDirection.rtl,
                        decoration: _decoration('شماره فاکتور (اختیاری)', Icons.numbers_rounded),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Text('مدارک پیوست', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Text(_persianDigits('${_files.length}/2'),
                              style: const TextStyle(color: Colors.black54)),
                          IconButton(
                            onPressed: _saving ? null : _pickDocuments,
                            icon: const Icon(Icons.attach_file_rounded, color: _purple),
                          ),
                        ],
                      ),
                      if (_files.isEmpty)
                        const Text(
                          'برای افزودن تصویر یا فایل سند، روی آیکون پیوست بزنید.',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ..._files.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.insert_drive_file_outlined),
                            title: Text(
                              file.path.split(Platform.pathSeparator).last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              onPressed: _saving ? null : () => setState(() => _files.removeAt(index)),
                              icon: const Icon(Icons.close_rounded, color: Colors.red),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: _purple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: _saving
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                              : const Icon(Icons.save_rounded),
                          label: Text(
                            _saving ? 'در حال ذخیره...' : (_isEdit ? 'ذخیره تغییرات' : 'ثبت هزینه'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
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

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _teal),
      filled: true,
      fillColor: Colors.white,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _teal, width: 1.5),
      ),
    );
  }
}

class _ExpensePaymentSheet extends StatefulWidget {
  final Map<String, dynamic> expense;
  final ManagerExpenseService service;

  const _ExpensePaymentSheet({required this.expense, required this.service});

  @override
  State<_ExpensePaymentSheet> createState() => _ExpensePaymentSheetState();
}

class _ExpensePaymentSheetState extends State<_ExpensePaymentSheet> {
  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> _receivers = [];
  int? _bankId;
  int? _receiverId;
  String? _receiverType;
  DateTime _paymentDate = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int _intValue(dynamic value) => int.tryParse(_normalizeDigits(value?.toString() ?? '')) ?? 0;

  String _normalizeDigits(String value) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < 10; i++) {
      value = value.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
    }
    return value;
  }

  String _persianDigits(String value) {
    const digits = '۰۱۲۳۴۵۶۷۸۹';
    return value.replaceAllMapped(
      RegExp(r'[0-9]'),
          (match) => digits[int.parse(match.group(0)!)],
    );
  }

  String _money(dynamic value) {
    final normalized = _normalizeDigits((value ?? '').toString())
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('٫', '.');
    final amount = num.tryParse(normalized);
    if (amount == null) return '— تومان';
    final formatted = amount.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
    );
    return '${_persianDigits(formatted)} تومان';
  }

  String _dateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _jalaliText(DateTime date) {
    final j = Gregorian.fromDateTime(date).toJalali();
    return '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}';
  }

  void _message(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, textDirection: TextDirection.rtl),
      backgroundColor: error ? Colors.red.shade700 : _teal,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _loadBanks() async {
    try {
      final banks = await widget.service.getExpenseBanks();

      if (!mounted) return;

      setState(() {
        _banks = banks;
        _bankId = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadReceivers() async {
    if (_receiverType == null) {
      setState(() {
        _receiverId = null;
        _receivers = [];
      });
      return;
    }

    setState(() {
      _receiverId = null;
      _receivers = [];
      _errorMessage = null;
    });

    try {
      final values = await widget.service.getExpenseReceivers(
        type: _receiverType!,
        search: _searchController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _receivers = values;
        _receiverId = null;
      });

      if (values.isEmpty) {
        _message('برای این نوع دریافت‌کننده موردی پیدا نشد.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _chooseDate() async {
    final initial = Gregorian.fromDateTime(_paymentDate).toJalali();
    final now = Gregorian.fromDateTime(DateTime.now()).toJalali();
    final selected = await showDialog<Jalali>(
      context: context,
      builder: (_) => _JalaliDatePickerDialog(
        initialDate: initial,
        firstDate: Jalali(1300, 1, 1),
        lastDate: Jalali(now.year + 20, 12, 29),
      ),
    );
    if (selected != null && mounted) setState(() => _paymentDate = selected.toDateTime());
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_bankId == null) {
      setState(() => _errorMessage = 'حساب بانکی را انتخاب کنید.');
      return;
    }
    if (_receiverId == null) {
      setState(() => _errorMessage = 'دریافت‌کننده را انتخاب کنید.');
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    try {
      await widget.service.payExpense(
        expenseId: _intValue(widget.expense['id']),
        bankId: _bankId!,
        paymentDate: _dateString(_paymentDate),
        receiverType: _receiverType ?? '',
        transactionReference: _normalizeDigits(_referenceController.text.trim()),
        unitId: _receiverType == 'owner' ? _receiverId : null,
        renterId: _receiverType == 'renter' ? _receiverId : null,
        thirdPartyId: _receiverType == 'other' ? _receiverId : null,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '').trim();
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .9),
          decoration: const BoxDecoration(
            color: Color(0xFFF6F7FB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _loading
              ? const SizedBox(height: 280, child: Center(child: CircularProgressIndicator()))
              : Column(children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                const Expanded(child: Text('ثبت پرداخت هزینه', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(onPressed: _saving ? null : () => Navigator.pop(context, false), icon: const Icon(Icons.close)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Text(widget.expense['description']?.toString().trim().isNotEmpty == true
                        ? widget.expense['description'].toString() : 'هزینه بدون شرح',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('مبلغ: ${_money(widget.expense['amount'])}', style: const TextStyle(color: _purple)),
                    if (_errorMessage != null && _errorMessage!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(color: Colors.red.shade800, height: 1.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    DropdownButtonFormField<int>(
                      value: _bankId,
                      hint: const Text('انتخاب کنید'),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'حساب بانکی *',
                        border: OutlineInputBorder(),
                      ),
                      items: _banks.map((b) {
                        return DropdownMenuItem<int>(
                          value: _intValue(b['id']),
                          child: Text(
                            '${b['bank_name'] ?? b['name'] ?? b['title'] ?? b['account_name'] ?? 'حساب بانکی'}'
                                '${(b['account_no'] ?? '').toString().isEmpty ? '' : ' - ${_persianDigits((b['account_no'] ?? '').toString())}'}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _saving
                          ? null
                          : (v) {
                        setState(() {
                          _bankId = v;
                          _errorMessage = null;
                        });
                      },
                      validator: (v) =>
                      v == null ? 'لطفاً حساب بانکی را انتخاب کنید.' : null,
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      value: _receiverType,
                      decoration: const InputDecoration(
                        labelText: 'نوع دریافت‌کننده *',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('انتخاب کنید'),
                      items: const [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('انتخاب کنید'),
                        ),
                        DropdownMenuItem(value: 'owner', child: Text('مالک')),
                        DropdownMenuItem(value: 'renter', child: Text('مستأجر')),
                        DropdownMenuItem(value: 'other', child: Text('اشخاص ثالث ')),
                      ],
                      onChanged: _saving
                          ? null
                          : (v) async {
                        setState(() {
                          _receiverType = v;
                          _receiverId = null;
                          _receivers = [];
                          _searchController.clear();
                          _errorMessage = null;
                        });

                        if (v != null) {
                          await _loadReceivers();
                        }
                      },
                      validator: (v) =>
                      v == null ? 'لطفاً نوع دریافت‌کننده را انتخاب کنید.' : null,
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'جست‌وجوی دریافت‌کننده',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          onPressed: _saving ? null : _loadReceivers,
                          icon: const Icon(Icons.search),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _loadReceivers(),
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<int>(
                      value: _receiverId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'دریافت‌کننده *',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('انتخاب کنید'),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('انتخاب کنید'),
                        ),
                        ..._receivers.map((r) => DropdownMenuItem<int>(
                          value: _intValue(r['id']),
                          child: Text(
                            r['label']?.toString() ??
                                r['name']?.toString() ??
                                'بدون نام',
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                      ],
                      onChanged: _saving
                          ? null
                          : (v) => setState(() {
                        _receiverId = v;
                        _errorMessage = null;
                      }),
                      validator: (v) =>
                      v == null ? 'لطفاً دریافت‌کننده را انتخاب کنید.' : null,
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _saving ? null : _chooseDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'تاریخ پرداخت *',
                          prefixIcon: Icon(
                            Icons.calendar_month,
                            color: _teal,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            _jalaliText(_paymentDate)
                                .replaceAll('0', '۰')
                                .replaceAll('1', '۱')
                                .replaceAll('2', '۲')
                                .replaceAll('3', '۳')
                                .replaceAll('4', '۴')
                                .replaceAll('5', '۵')
                                .replaceAll('6', '۶')
                                .replaceAll('7', '۷')
                                .replaceAll('8', '۸')
                                .replaceAll('9', '۹'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _referenceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [PersianDigitFormatter(), LengthLimitingTextInputFormatter(20)],
                      textDirection: TextDirection.rtl,
                      maxLength: 20,
                      decoration: const InputDecoration(labelText: 'شماره پیگیری (اختیاری)', border: OutlineInputBorder(), counterText: ''),
                      validator: (v) => _normalizeDigits((v ?? '').trim()).length > 20 ? 'حداکثر ۲۰ کاراکتر وارد کنید.' : null,
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(backgroundColor: _purple),
                        icon: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline),
                        label: Text(_saving ? 'در حال ثبت پرداخت...' : 'ثبت پرداخت'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _JalaliDatePickerDialog extends StatefulWidget {
  final Jalali initialDate;
  final Jalali firstDate;
  final Jalali lastDate;

  const _JalaliDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_JalaliDatePickerDialog> createState() => _JalaliDatePickerDialogState();
}

class _JalaliDatePickerDialogState extends State<_JalaliDatePickerDialog> {
  late Jalali _displayedMonth;
  late Jalali _selectedDate;

  static const _teal = Color(0xFF00ACC1);
  static const _purple = Color(0xFF610DB5);
  static const _weekdays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
  static const _months = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = Jalali(widget.initialDate.year, widget.initialDate.month, 1);
  }

  String _digits(String value) {
    const digits = '۰۱۲۳۴۵۶۷۸۹';
    return value.replaceAllMapped(
      RegExp(r'[0-9]'),
          (match) => digits[int.parse(match.group(0)!)],
    );
  }

  Jalali _shiftMonth(int delta) {
    var year = _displayedMonth.year;
    var month = _displayedMonth.month + delta;
    while (month < 1) {
      month += 12;
      year--;
    }
    while (month > 12) {
      month -= 12;
      year++;
    }
    return Jalali(year, month, 1);
  }

  bool _isInRange(Jalali date) {
    return date.compareTo(widget.firstDate) >= 0 &&
        date.compareTo(widget.lastDate) <= 0;
  }

  @override
  Widget build(BuildContext context) {
    final monthLength = _displayedMonth.monthLength;
    // شنبه اولین ستون تقویم است؛ weekday در DateTime از دوشنبه شروع می‌شود.
    final firstWeekday = _displayedMonth.toDateTime().weekday;
    final leading = (firstWeekday + 1) % 7;
    final cells = <Widget>[];

    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= monthLength; day++) {
      final date = Jalali(_displayedMonth.year, _displayedMonth.month, day);
      final selected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final enabled = _isInRange(date);
      cells.add(
        InkWell(
          onTap: enabled ? () => setState(() => _selectedDate = date) : null,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? _purple : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              _digits('$day'),
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : enabled
                    ? const Color(0xFF303044)
                    : Colors.black26,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    while (cells.length < 42) {
      cells.add(const SizedBox.shrink());
    }

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Row(
        children: [
          IconButton(
            tooltip: 'ماه قبل',
            onPressed: _shiftMonth(-1).compareTo(widget.firstDate) >= 0
                ? () => setState(() => _displayedMonth = _shiftMonth(-1))
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Text(_months[_displayedMonth.month - 1],
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(_digits('${_displayedMonth.year}'),
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'ماه بعد',
            onPressed: _shiftMonth(1).compareTo(widget.lastDate) <= 0
                ? () => setState(() => _displayedMonth = _shiftMonth(1))
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: _weekdays
                    .map((day) => Expanded(
                  child: Center(
                    child: Text(day,
                        style: const TextStyle(
                            color: _teal, fontWeight: FontWeight.bold)),
                  ),
                ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.rtl,
              child: GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 4,
                crossAxisSpacing: 2,
                childAspectRatio: 1.05,
                children: cells,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _digits('${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}'),
              style: const TextStyle(fontWeight: FontWeight.bold),
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
          style: FilledButton.styleFrom(backgroundColor: _purple),
          onPressed: () => Navigator.pop(context, _selectedDate),
          child: const Text('تأیید'),
        ),
      ],
    );
  }
}

class ManagerExpenseCategoriesScreen extends StatefulWidget {
  final ManagerExpenseService service;

  const ManagerExpenseCategoriesScreen({super.key, required this.service});

  @override
  State<ManagerExpenseCategoriesScreen> createState() =>
      _ManagerExpenseCategoriesScreenState();
}

class _ManagerExpenseCategoriesScreenState extends State<ManagerExpenseCategoriesScreen> {
  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);

  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final categories = await widget.service.getCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (e) {
      if (mounted) _message(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, textDirection: TextDirection.rtl),
        backgroundColor: error ? Colors.red.shade700 : _teal,
      ),
    );
  }

  Future<void> _editCategory([Map<String, dynamic>? category]) async {
    if (!mounted) return;

    final controller = TextEditingController(
      text: category?['title']?.toString() ?? '',
    );

    String? title;

    try {
      title = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(
                category == null
                    ? 'دسته‌بندی جدید'
                    : 'ویرایش دسته‌بندی',
              ),
              content: TextField(
                controller: controller,
                autofocus: true,
                maxLength: 100,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  labelText: 'عنوان دسته‌بندی',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('انصراف'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                  ),
                  onPressed: () {
                    final value = controller.text.trim();

                    if (value.isEmpty) {
                      return;
                    }

                    Navigator.of(dialogContext).pop(value);
                  },
                  child: const Text('ذخیره'),
                ),
              ],
            ),
          );
        },
      );
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    }

    if (!mounted || title == null || title.trim().isEmpty) {
      return;
    }

    try {
      final id = int.tryParse(
        category?['id']?.toString() ?? '',
      );

      if (id == null) {
        await widget.service.createCategory(title: title.trim());
      } else {
        await widget.service.updateCategory(
          categoryId: id,
          title: title.trim(),
        );
      }

      if (!mounted) return;

      await _loadCategories();

      if (mounted) {
        _message('دسته‌بندی ذخیره شد.');
      }
    } catch (e) {
      if (mounted) {
        _message(
          e.toString().replaceFirst('Exception: ', ''),
          error: true,
        );
      }
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    if (category['is_default'] == true) {
      _message('دسته‌بندی پیش‌فرض قابل حذف نیست.', error: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف دسته‌بندی'),
          content: Text('دسته‌بندی «${category['title']}» حذف یا غیرفعال شود؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('تأیید'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    try {
      await widget.service.deleteCategory(int.parse(category['id'].toString()));
      if (!mounted) return;
      await _loadCategories();
      if (mounted) _message('درخواست حذف دسته‌بندی انجام شد.');
    } catch (e) {
      if (mounted) _message(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          title: const Text('مدیریت دسته‌بندی هزینه‌ها'),
          centerTitle: true,
          backgroundColor: _teal,
          foregroundColor: Colors.white,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _editCategory(),
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('دسته‌بندی جدید'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _categories.isEmpty
            ? const Center(child: Text('دسته‌بندی‌ای ثبت نشده است.'))
            : RefreshIndicator(
          onRefresh: _loadCategories,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isDefault = category['is_default'] == true;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F7FA),
                    child: Icon(Icons.category_rounded, color: _teal),
                  ),
                  title: Text(
                    category['title']?.toString() ?? 'بدون عنوان',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(isDefault ? 'دسته‌بندی پیش‌فرض' : 'دسته‌بندی اختصاصی'),
                  trailing: isDefault
                      ? const Icon(Icons.lock_outline_rounded, color: Colors.black38)
                      : PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editCategory(category);
                      } else if (value == 'delete') {
                        _deleteCategory(category);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                      PopupMenuItem(value: 'delete', child: Text('حذف')),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
