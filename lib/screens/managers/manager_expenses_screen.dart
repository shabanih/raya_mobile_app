
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

import '../../services/manager_expense_service.dart';

class ManagerExpensesScreen extends StatefulWidget {
  const ManagerExpensesScreen({super.key});

  @override
  State<ManagerExpensesScreen> createState() =>
      _ManagerExpensesScreenState();
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
  bool _saving = false;
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

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

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
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    final text = (value ?? '')
        .toString()
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('٫', '.');

    return double.tryParse(text) ?? 0;
  }

  String _money(dynamic value) {
    final amount = _toDouble(value).round();
    return '${amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
    )} تومان';
  }

  String _dateText(dynamic value) {
    if (value == null || value.toString().isEmpty) return 'بدون تاریخ';

    final text = value.toString();
    final parts = text.split('-');

    if (parts.length != 3) return text;

    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  bool _isPaid(Map<String, dynamic> expense) {
    final value = expense['is_paid'];
    return value == true || value == 1 || value == 'true';
  }

  String _categoryName(Map<String, dynamic> expense) {
    final dynamic category = expense['category'];

    // نام دسته‌بندی به‌صورت مستقیم
    final directTitle =
        expense['category_title'] ?? expense['category_name'];

    if (directTitle != null &&
        directTitle.toString().trim().isNotEmpty) {
      return directTitle.toString();
    }

    // اگر category یک Map باشد
    if (category is Map) {
      final title = category['title'] ?? category['name'];

      if (title != null && title.toString().trim().isNotEmpty) {
        return title.toString();
      }
    }

    // استخراج شناسه دسته‌بندی
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

    // اگر category خودش نام متنی باشد
    if (category is String && category.trim().isNotEmpty) {
      return category;
    }

    return 'بدون دسته‌بندی';
  }

  List<Map<String, dynamic>> get _filteredExpenses {
    final query = _search.trim().toLowerCase();

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

  double get _filteredTotal {
    return _filteredExpenses.fold<double>(
      0,
          (sum, item) => sum + _toDouble(item['amount']),
    );
  }

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
      _showMessage(
        expense == null ? 'هزینه با موفقیت ثبت شد.' : 'هزینه ویرایش شد.',
      );
    }
  }

  Future<void> _openCategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManagerExpenseCategoriesScreen(
          service: _service,
        ),
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف هزینه'),
        content: const Text(
          'آیا از حذف این هزینه مطمئن هستید؟',
          textDirection: TextDirection.rtl,
        ),
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

  @override
  Widget build(BuildContext context) {
    final expenses = _filteredExpenses;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: const Text(
            'مدیریت هزینه‌ها',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
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
                child: SizedBox(
                  height: 56,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      _filterChip('همه', 'all'),
                      const SizedBox(width: 8),
                      _filterChip('پرداخت‌نشده', 'unpaid'),
                      const SizedBox(width: 8),
                      _filterChip('پرداخت‌شده', 'paid'),
                    ],
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
                            category['title']?.toString() ??
                                'بدون عنوان',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _categoryFilter = value);
                    },
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (expenses.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _emptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                          _expenseCard(expenses[index]),
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
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'جمع هزینه‌های نمایش‌داده‌شده',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  _money(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$count هزینه',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String title, String value) {
    final selected = _paymentFilter == value;

    return Center(
      child: ChoiceChip(
        label: Text(title),
        selected: selected,
        selectedColor: _teal.withValues(alpha: 0.16),
        checkmarkColor: _teal,
        labelStyle: TextStyle(
          color: selected ? _teal : Colors.black87,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => _changePaymentFilter(value),
      ),
    );
  }

  Widget _expenseCard(Map<String, dynamic> expense) {
    final paid = _isPaid(expense);
    final description =
        expense['description']?.toString().trim() ?? '';
    final title =
    description.isEmpty ? 'هزینه بدون شرح' : description;

    final docNo = expense['financial_document_number'] ??
        expense['doc_no'];

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
                    color: paid
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    paid
                        ? Icons.check_circle_outline_rounded
                        : Icons.pending_actions_rounded,
                    color: paid
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF303044),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _categoryName(expense),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _money(expense['amount']),
                  style: const TextStyle(
                    color: _purple,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _info(
                  Icons.calendar_month_rounded,
                  _dateText(expense['date']),
                ),
                _info(
                  paid
                      ? Icons.check_circle_rounded
                      : Icons.schedule_rounded,
                  paid ? 'پرداخت‌شده' : 'پرداخت‌نشده',
                  color: paid ? Colors.green : Colors.orange.shade800,
                ),
                if (docNo != null && docNo.toString().isNotEmpty)
                  _info(
                    Icons.numbers_rounded,
                    'سند $docNo',
                  ),
              ],
            ),
            if ((expense['details'] ?? '').toString().trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                expense['details'].toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!paid)
                  TextButton.icon(
                    onPressed: () => _openForm(expense: expense),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('ویرایش'),
                  ),
                if (!paid)
                  IconButton(
                    tooltip: 'حذف هزینه',
                    onPressed: () => _deleteExpense(expense),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
                  ),
                if (paid)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Text(
                      'هزینه قفل است',
                      style: TextStyle(
                        color: Colors.black45,
                        fontSize: 11,
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

  Widget _info(
      IconData icon,
      String text, {
        Color color = Colors.black54,
      }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: color),
        ),
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
            Icon(
              Icons.receipt_long_outlined,
              size: 68,
              color: _teal.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 16),
            const Text(
              'هزینه‌ای پیدا نشد',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'می‌توانید هزینه جدیدی ثبت کنید یا فیلترها را تغییر دهید.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, height: 1.8),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openForm(),
              style: FilledButton.styleFrom(
                backgroundColor: _purple,
              ),
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
    _amountController.text = (expense['amount'] ?? '').toString();
    _descriptionController.text =
        (expense['description'] ?? '').toString();
    _detailsController.text = (expense['details'] ?? '').toString();
    _docNoController.text = (expense['doc_no'] ?? '').toString();

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

  String _dateString(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'انتخاب تاریخ هزینه',
      cancelText: 'انصراف',
      confirmText: 'تأیید',
    );

    if (selected != null && mounted) {
      setState(() => _date = selected);
    }
  }

  final ImagePicker _imagePicker = ImagePicker();


  Future<void> _pickDocuments() async {
    try {
      final List<XFile> pickedFiles =
      await _imagePicker.pickMultipleMedia();

      if (pickedFiles.isEmpty || !mounted) return;

      setState(() {
        final int remaining = 2 - _files.length;

        if (remaining > 0) {
          _files.addAll(
            pickedFiles
                .take(remaining)
                .map((file) => File(file.path)),
          );
        }
      });

      if (pickedFiles.length > 2) {
        _message(
          'حداکثر دو فایل قابل انتخاب است؛ فایل‌های اضافی اضافه نشدند.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _message('خطا در انتخاب فایل: $e', error: true);
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
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

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
        date: _dateString(_date),
        description: _descriptionController.text.trim(),
        details: _detailsController.text.trim(),
        docNo: _docNoController.text.trim(),
        files: _files,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _message(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
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
                      decoration: _decoration(
                        'دسته‌بندی هزینه *',
                        Icons.category_outlined,
                      ),
                      items: widget.categories.map((category) {
                        final id = int.tryParse(
                          category['id']?.toString() ?? '',
                        );

                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(
                            category['title']?.toString() ??
                                'بدون عنوان',
                          ),
                        );
                      }).where((item) => item.value != null).toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _categoryId = value),
                      validator: (value) =>
                      value == null ? 'دسته‌بندی را انتخاب کنید.' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: _decoration(
                        'مبلغ به تومان *',
                        Icons.payments_outlined,
                      ),
                      validator: (value) {
                        final normalized =
                        _normalizeDigits(value ?? '');
                        final amount = double.tryParse(normalized);

                        if (normalized.isEmpty) return 'مبلغ را وارد کنید.';
                        if (amount == null || amount <= 0) {
                          return 'مبلغ معتبر و بیشتر از صفر وارد کنید.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _saving ? null : _chooseDate,
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: _decoration(
                          'تاریخ هزینه',
                          Icons.calendar_month_outlined,
                        ),
                        child: Text(_dateString(_date)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      maxLength: 200,
                      decoration: _decoration(
                        'شرح هزینه *',
                        Icons.short_text_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'شرح هزینه را وارد کنید.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _detailsController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: _decoration(
                        'توضیحات تکمیلی',
                        Icons.notes_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _docNoController,
                      decoration: _decoration(
                        'شماره سند (اختیاری)',
                        Icons.numbers_rounded,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'مدارک پیوست',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${_files.length}/2',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        IconButton(
                          onPressed: _saving ? null : _pickDocuments,
                          icon: const Icon(
                            Icons.attach_file_rounded,
                            color: _purple,
                          ),
                        ),
                      ],
                    ),
                    if (_files.isEmpty)
                      const Text(
                        'برای افزودن تصویر یا فایل سند، روی آیکون پیوست بزنید.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ..._files.asMap().entries.map((entry) {
                      final index = entry.key;
                      final file = entry.value;

                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.insert_drive_file_outlined,
                          ),
                          title: Text(
                            file.path.split(Platform.pathSeparator).last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            onPressed: _saving
                                ? null
                                : () => setState(
                                  () => _files.removeAt(index),
                            ),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.red,
                            ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _saving
                              ? 'در حال ذخیره...'
                              : _isEdit
                              ? 'ذخیره تغییرات'
                              : 'ثبت هزینه',
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

class ManagerExpenseCategoriesScreen extends StatefulWidget {
  final ManagerExpenseService service;

  const ManagerExpenseCategoriesScreen({
    super.key,
    required this.service,
  });

  @override
  State<ManagerExpenseCategoriesScreen> createState() =>
      _ManagerExpenseCategoriesScreenState();
}

class _ManagerExpenseCategoriesScreenState
    extends State<ManagerExpenseCategoriesScreen> {
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
    setState(() => _loading = true);

    try {
      final categories = await widget.service.getCategories();

      if (mounted) setState(() => _categories = categories);
    } catch (e) {
      if (mounted) _message(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
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

  Future<void> _editCategory([
    Map<String, dynamic>? category,
  ]) async {
    final controller = TextEditingController(
      text: category?['title']?.toString() ?? '',
    );

    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            category == null ? 'دسته‌بندی جدید' : 'ویرایش دسته‌بندی',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 100,
            decoration: const InputDecoration(
              labelText: 'عنوان دسته‌بندی',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _purple),
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(dialogContext, value);
                }
              },
              child: const Text('ذخیره'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();

    if (title == null || title.trim().isEmpty) return;

    try {
      final id = int.tryParse(category?['id']?.toString() ?? '');

      if (id == null) {
        await widget.service.createCategory(title: title);
      } else {
        if (category?['is_default'] == true) {
          _message('دسته‌بندی پیش‌فرض قابل ویرایش نیست.', error: true);
          return;
        }

        await widget.service.updateCategory(
          categoryId: id,
          title: title,
        );
      }

      if (!mounted) return;
      await _loadCategories();
      _message('دسته‌بندی ذخیره شد.');
    } catch (e) {
      if (mounted) _message(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }

  Future<void> _deleteCategory(
      Map<String, dynamic> category,
      ) async {
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
          content: Text(
            'دسته‌بندی «${category['title']}» حذف یا غیرفعال شود؟',
          ),
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
      await widget.service.deleteCategory(
        int.parse(category['id'].toString()),
      );

      if (!mounted) return;
      await _loadCategories();
      _message('درخواست حذف دسته‌بندی انجام شد.');
    } catch (e) {
      if (mounted) _message(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
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
            separatorBuilder: (_, __) =>
            const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isDefault =
                  category['is_default'] == true;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F7FA),
                    child: Icon(
                      Icons.category_rounded,
                      color: _teal,
                    ),
                  ),
                  title: Text(
                    category['title']?.toString() ??
                        'بدون عنوان',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    isDefault
                        ? 'دسته‌بندی پیش‌فرض'
                        : 'دسته‌بندی اختصاصی',
                  ),
                  trailing: isDefault
                      ? const Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.black38,
                  )
                      : PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editCategory(category);
                      } else if (value == 'delete') {
                        _deleteCategory(category);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('ویرایش'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('حذف'),
                      ),
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
