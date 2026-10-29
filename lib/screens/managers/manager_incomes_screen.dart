import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_income_service.dart';

class ManagerIncomesScreen extends StatefulWidget {
  const ManagerIncomesScreen({super.key});

  @override
  State<ManagerIncomesScreen> createState() => _ManagerIncomesScreenState();
}

class _ManagerIncomesScreenState extends State<ManagerIncomesScreen> {
  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);
  static const Color _background = Color(0xFFF6F7FB);

  final ManagerIncomeService _service = ManagerIncomeService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _incomes = [];
  List<Map<String, dynamic>> _categories = [];

  bool _loading = true;
  String _paymentFilter = 'all';
  String _search = '';
  int? _categoryFilter;

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

  String _cleanError(Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text, textDirection: TextDirection.rtl),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Colors.red.shade700 : _teal,
        ),
      );
  }

  String _normalizeDigits(String value) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < 10; i++) {
      value = value.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
    }
    return value;
  }

  String _fa(String value) {
    const digits = '۰۱۲۳۴۵۶۷۸۹';
    return value.replaceAllMapped(
      RegExp(r'[0-9]'),
          (m) => digits[int.parse(m.group(0)!)],
    );
  }

  int _int(dynamic value) =>
      int.tryParse(_normalizeDigits((value ?? '').toString())) ?? 0;

  double _number(dynamic value) {
    final text = _normalizeDigits((value ?? '').toString())
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('٫', '.');
    return double.tryParse(text) ?? 0;
  }

  String _money(dynamic value) {
    final text = _number(value).round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
    );
    return '${_fa(text)} تومان';
  }

  bool _paid(Map<String, dynamic> item) {
    final value = item['is_paid'];
    return value == true || value == 1 || value == 'true';
  }

  String _dateText(dynamic value) {
    if (value == null || value.toString().isEmpty) return 'بدون تاریخ';
    final date = DateTime.tryParse(value.toString());
    if (date == null) return _fa(value.toString());

    final j = Gregorian.fromDateTime(date).toJalali();
    return _fa(
      '${j.year}/${j.month.toString().padLeft(2, '0')}/'
          '${j.day.toString().padLeft(2, '0')}',
    );
  }

  String _categoryName(Map<String, dynamic> income) {
    final category = income['category'];

    if (category is Map) {
      final name = category['subject'] ?? category['subject'] ?? category['subject'];
      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString();
      }
    }

    if (category is String &&
        category.trim().isNotEmpty &&
        int.tryParse(category) == null) {
      return category;
    }

    final id = _int(
      income['category_id'] ??
          (category is num ? category : null),
    );

    for (final item in _categories) {
      if (_int(item['id']) == id && id > 0) {
        return (item['subject'] ?? item['title'] ?? item['name'] ?? 'بدون دسته‌بندی')
            .toString();
      }
    }

    return 'بدون دسته‌بندی';
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _loading = true);

    try {
      final results = await Future.wait<dynamic>([
        _service.getIncomes(paymentStatus: _paymentFilter),
        _service.getCategories(),
      ]);

      if (!mounted) return;
      setState(() {
        _incomes = List<Map<String, dynamic>>.from(results[0]);
        _categories = List<Map<String, dynamic>>.from(results[1]);
      });
    } catch (e) {
      _message(_cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final query = _normalizeDigits(_search.trim()).toLowerCase();

    return _incomes.where((income) {
      if (_categoryFilter != null &&
          _int(income['category_id']) != _categoryFilter) {
        return false;
      }

      if (query.isNotEmpty) {
        final searchable = [
          income['description'],
          income['details'],
          income['doc_number'],
          income['financial_document_number'],
          income['payer_name'],
          _categoryName(income),
        ].whereType<Object>().join(' ').toLowerCase();

        if (!searchable.contains(query)) return false;
      }

      return true;
    }).toList();
  }

  double get _total =>
      _filtered.fold(0, (sum, item) => sum + _number(item['amount']));

  Future<void> _changeFilter(String value) async {
    if (_paymentFilter == value) return;
    setState(() => _paymentFilter = value);
    await _loadData();
  }

  Future<void> _openForm({Map<String, dynamic>? income}) async {
    if (income != null && _paid(income)) {
      _message('درآمد پرداخت‌شده قابل ویرایش نیست.', error: true);
      return;
    }

    if (_categories.isEmpty) {
      _message('ابتدا یک دسته‌بندی درآمد ایجاد کنید.', error: true);
      await _openCategories();
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IncomeFormSheet(
        service: _service,
        categories: _categories,
        income: income,
      ),
    );

    if (result == true && mounted) {
      await _loadData();
      _message(income == null ? 'درآمد ثبت شد.' : 'درآمد ویرایش شد.');
    }
  }

  Future<void> _openCategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _IncomeCategoriesScreen(service: _service),
      ),
    );

    if (mounted) await _loadData();
  }

  Future<void> _openPayment(Map<String, dynamic> income) async {
    if (_paid(income)) {
      _message('این درآمد قبلاً پرداخت شده است.', error: true);
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IncomePaymentSheet(
        service: _service,
        income: income,
      ),
    );

    if (result == true && mounted) {
      await _loadData();
      _message('پرداخت درآمد ثبت شد.');
    }
  }

  Future<void> _cancelPayment(Map<String, dynamic> income) async {
    if (!_paid(income)) {
      _message('این درآمد پرداخت نشده است.', error: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('لغو پرداخت'),
          content: Text(
            'پرداخت درآمد ${_money(income['amount'])} لغو شود؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('لغو پرداخت'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await _service.cancelIncomePayment(_int(income['id']));
      if (!mounted) return;
      await _loadData();
      _message('پرداخت درآمد لغو شد.');
    } catch (e) {
      _message(_cleanError(e), error: true);
    }
  }

  Future<void> _deleteIncome(Map<String, dynamic> income) async {
    if (_paid(income)) {
      _message('درآمد پرداخت‌شده قابل حذف نیست.', error: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف درآمد'),
          content: const Text('آیا از حذف این درآمد مطمئن هستید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteIncome(_int(income['id']));
      if (!mounted) return;
      await _loadData();
      _message('درآمد حذف شد.');
    } catch (e) {
      _message(_cleanError(e), error: true);
    }
  }

  void _details(Map<String, dynamic> income) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('جزئیات درآمد'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detail('شرح', income['description']),
                _detail('دسته‌بندی', _categoryName(income)),
                _detail('مبلغ', _money(income['amount'])),
                _detail('تاریخ سند', _dateText(income['doc_date'])),
                _detail('شماره فاکتور', _fa('${income['doc_number'] ?? ''}')),
                _detail('شماره سند مالی', _fa('${income['financial_document_number'] ?? ''}')),
                _detail('پرداخت‌کننده', income['payer_name']),
                _detail('حساب بانکی', income['bank_name']),
                _detail('شماره حساب', _fa('${income['account_no'] ?? ''}')),
                _detail('وضعیت', _paid(income) ? 'پرداخت‌شده' : 'پرداخت‌نشده'),
                if (_paid(income)) ...[
                  _detail('تاریخ پرداخت', _dateText(income['payment_date'])),
                  _detail('شماره پیگیری', income['transaction_reference']),
                ],
                _detail('توضیحات', income['details']),
                if (income['documents'] is List)
                  ...((income['documents'] as List).asMap().entries.map(
                        (entry) => _detail(
                      'مدرک ${entry.key + 1}',
                      entry.value is Map
                          ? entry.value['url']
                          : entry.value,
                    ),
                  )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('بستن'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, dynamic value) {
    final text = value == null || value.toString().trim().isEmpty
        ? '—'
        : value.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text('$label: $text', style: const TextStyle(height: 1.6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: const Text(
            'مدیریت درآمدها',
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
          label: const Text('ثبت درآمد'),
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_teal, Color(0xFF00838F)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'جمع درآمدهای نمایش‌داده‌شده',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _money(_total),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${_fa(items.length.toString())} درآمد',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    textDirection: TextDirection.rtl,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'جست‌وجوی شرح، سند یا پرداخت‌کننده...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    _filterChip('همه', 'all'),
                    _filterChip('پرداخت‌نشده', 'unpaid'),
                    _filterChip('پرداخت‌شده', 'paid'),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DropdownButtonFormField<int?>(
                    value: _categoryFilter,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'دسته‌بندی درآمد',
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
                            (c) => DropdownMenuItem<int?>(
                          value: _int(c['id']),
                          child: Text(
                            (c['subject'] ?? c['title'] ?? c['subject'] ?? 'بدون عنوان')
                                .toString(),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _categoryFilter = v),
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: _teal.withValues(alpha: .6),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'درآمدی پیدا نشد',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'می‌توانید درآمد جدیدی ثبت کنید یا فیلترها را تغییر دهید.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, index) => _incomeCard(items[index]),
                      childCount: items.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _paymentFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: _teal.withValues(alpha: .15),
      checkmarkColor: _teal,
      onSelected: (_) => _changeFilter(value),
    );
  }

  Widget _incomeCard(Map<String, dynamic> income) {
    final paid = _paid(income);
    final description = (income['description'] ?? '').toString().trim();
    final title = description.isEmpty ? 'درآمد بدون شرح' : description;
    final docNo = income['financial_document_number'] ?? income['doc_number'];

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
                    color: paid ? Colors.green.shade700 : Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _categoryName(income),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    _money(income['amount']),
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      color: _purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _info(Icons.calendar_month_rounded, _dateText(income['doc_date'])),
                _info(
                  paid ? Icons.check_circle : Icons.schedule,
                  paid ? 'پرداخت‌شده' : 'پرداخت‌نشده',
                  color: paid ? Colors.green : Colors.orange.shade800,
                ),
                if (docNo != null && docNo.toString().isNotEmpty)
                  _info(Icons.numbers_rounded, 'سند ${_fa(docNo.toString())}'),
              ],
            ),
            if ((income['payer_name'] ?? '').toString().trim().isNotEmpty) ...[
              const SizedBox(height: 9),
              _info(
                Icons.person_outline_rounded,
                'پرداخت‌کننده: ${income['payer_name']}',
              ),
            ],
            if ((income['details'] ?? '').toString().trim().isNotEmpty) ...[
              const SizedBox(height: 9),
              Text(
                income['details'].toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                IconButton(
                  tooltip: paid ? 'لغو پرداخت' : 'ثبت پرداخت',
                  onPressed: () => paid
                      ? _cancelPayment(income)
                      : _openPayment(income),
                  icon: Icon(
                    paid ? Icons.cancel_outlined : Icons.payments_outlined,
                    color: paid ? Colors.red : Colors.green.shade700,
                  ),
                ),
                IconButton(
                  tooltip: 'جزئیات',
                  onPressed: () => _details(income),
                  icon: const Icon(Icons.visibility_outlined, color: _teal),
                ),
                if (!paid)
                  IconButton(
                    tooltip: 'ویرایش',
                    onPressed: () => _openForm(income: income),
                    icon: const Icon(Icons.edit_outlined, color: _purple),
                  ),
                if (!paid)
                  IconButton(
                    tooltip: 'حذف',
                    onPressed: () => _deleteIncome(income),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
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
}

// ------------------------------------------------------------
// فرم ایجاد و ویرایش درآمد
// ------------------------------------------------------------

class _IncomeFormSheet extends StatefulWidget {
  final ManagerIncomeService service;
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? income;

  const _IncomeFormSheet({
    required this.service,
    required this.categories,
    this.income,
  });

  @override
  State<_IncomeFormSheet> createState() => _IncomeFormSheetState();
}


class _IncomeFormSheetState extends State<_IncomeFormSheet> {
  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);

  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _details = TextEditingController();
  final _docNo = TextEditingController();

  DateTime _date = DateTime.now();
  int? _categoryId;
  bool _saving = false;

  bool get _editing => widget.income != null;

  @override
  void initState() {
    super.initState();

    final item = widget.income;
    if (item == null) return;

    _categoryId = int.tryParse(
      (item['category_id'] ?? '').toString(),
    );

    _amount.text = (item['amount'] ?? '').toString();
    _description.text = (item['description'] ?? '').toString();
    _details.text = (item['details'] ?? '').toString();
    _docNo.text = (item['doc_number'] ?? '').toString();

    final date = DateTime.tryParse(
      (item['doc_date'] ?? '').toString(),
    );

    if (date != null) {
      _date = date;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _details.dispose();
    _docNo.dispose();
    super.dispose();
  }

  String _normal(String value) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';

    for (var i = 0; i < 10; i++) {
      value = value
          .replaceAll(fa[i], '$i')
          .replaceAll(ar[i], '$i');
    }

    return value
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('٫', '.')
        .trim();
  }

  int _int(dynamic value) {
    return int.tryParse(
      _normal((value ?? '').toString()),
    ) ??
        0;
  }

  String _dateString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  String _dateText(DateTime d) {
    final j = Gregorian.fromDateTime(d).toJalali();

    return '${j.year}/'
        '${j.month.toString().padLeft(2, '0')}/'
        '${j.day.toString().padLeft(2, '0')}';
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            text,
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: error ? Colors.red.shade700 : _teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _chooseDate() async {
    final now = Gregorian.fromDateTime(DateTime.now()).toJalali();
    final initial = Gregorian.fromDateTime(_date).toJalali();

    final selected = await showDialog<Jalali>(
      context: context,
      builder: (ctx) => _IncomeJalaliPicker(
        initial: initial,
        first: Jalali(1300, 1, 1),
        last: Jalali(now.year + 20, 12, 29),
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _date = selected.toDateTime();
      });
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    if (_categoryId == null) {
      _message(
        'دسته‌بندی درآمد را انتخاب کنید.',
        error: true,
      );
      return;
    }

    final amount = _normal(_amount.text);
    final amountValue = double.tryParse(amount);

    if (amountValue == null || amountValue <= 0) {
      _message(
        'مبلغ باید بیشتر از صفر باشد.',
        error: true,
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await widget.service.saveIncomeWithFiles(
        incomeId: _editing
            ? _int(widget.income!['id'])
            : null,
        categoryId: _categoryId!,
        amount: amount,
        date: _dateString(_date),
        description: _description.text.trim(),

        // فرم ثبت درآمد دیگر پرداخت‌کننده ندارد.
        // پارامترها برای سازگاری با امضای فعلی سرویس null هستند.
        payerType: 'owner',
        unitId: null,
        renterId: null,
        thirdPartyId: null,

        details: _details.text.trim(),
        docNo: _normal(_docNo.text),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _message(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  InputDecoration _decoration(
      String label,
      IconData icon,
      ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: _teal,
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE8E8F0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * .92,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF6F7FB),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _editing
                            ? 'ویرایش درآمد'
                            : 'ثبت درآمد جدید',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
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
                          'دسته‌بندی درآمد *',
                          Icons.category_outlined,
                        ),
                        items: widget.categories.map((c) {
                          final id = int.tryParse(
                            (c['id'] ?? '').toString(),
                          );

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              (
                                  c['subject'] ??
                                      c['title'] ??
                                      c['name'] ??
                                      'بدون عنوان'
                              ).toString(),
                            ),
                          );
                        }).where((item) => item.value != null).toList(),
                        onChanged: _saving
                            ? null
                            : (value) {
                          setState(() {
                            _categoryId = value;
                          });
                        },
                        validator: (value) => value == null
                            ? 'دسته‌بندی را انتخاب کنید.'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _amount,
                        enabled: !_saving,
                        keyboardType:
                        const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9۰-۹٠-٩,.٬٫]'),
                          ),
                        ],
                        decoration: _decoration(
                          'مبلغ به تومان *',
                          Icons.payments,
                        ),
                        validator: (value) {
                          final amount = double.tryParse(
                            _normal(value ?? ''),
                          );

                          if (amount == null || amount <= 0) {
                            return 'مبلغ معتبر وارد کنید.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      InkWell(
                        onTap: _saving ? null : _chooseDate,
                        child: InputDecorator(
                          decoration: _decoration(
                            'تاریخ شمسی سند *',
                            Icons.calendar_month,
                          ),
                          child: Text(_dateText(_date)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _description,
                        enabled: !_saving,
                        maxLength: 200,
                        decoration: _decoration(
                          'شرح درآمد *',
                          Icons.short_text,
                        ),
                        validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? 'شرح درآمد را وارد کنید.'
                            : null,
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _docNo,
                        enabled: !_saving,
                        decoration: _decoration(
                          'شماره فاکتور (اختیاری)',
                          Icons.numbers,
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _details,
                        enabled: !_saving,
                        minLines: 2,
                        maxLines: 4,
                        decoration: _decoration(
                          'توضیحات تکمیلی',
                          Icons.notes,
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: _purple,
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
                                : _editing
                                ? 'ذخیره تغییرات'
                                : 'ثبت درآمد',
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


// ------------------------------------------------------------
// ثبت پرداخت درآمد
// ------------------------------------------------------------


class _IncomePaymentSheet extends StatefulWidget {
  final ManagerIncomeService service;
  final Map<String, dynamic> income;

  const _IncomePaymentSheet({
    required this.service,
    required this.income,
  });

  @override
  State<_IncomePaymentSheet> createState() =>
      _IncomePaymentSheetState();
}

class _IncomePaymentSheetState extends State<_IncomePaymentSheet> {
  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);

  final _reference = TextEditingController();
  final _payerSearch = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> _payers = [];

  int? _bankId;
  int? _payerId;

  String _payerType = 'owner';
  DateTime _date = DateTime.now();

  bool _loading = true;
  bool _loadingPayers = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    // اگر درآمد قبلاً پرداخت‌کننده داشته، همان را پیش‌فرض قرار بده.
    final income = widget.income;
    final type = income['payer_type']?.toString();

    if (['owner', 'renter', 'other'].contains(type)) {
      _payerType = type!;
    }

    switch (_payerType) {
      case 'owner':
        _payerId = _int(income['unit_id']);
        break;
      case 'renter':
        _payerId = _int(income['payer_renter_id']);
        break;
      case 'other':
        _payerId = _int(income['payer_third_party_id']);
        break;
    }

    _loadInitialData();
  }

  @override
  void dispose() {
    _reference.dispose();
    _payerSearch.dispose();
    super.dispose();
  }

  String _normal(String value) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';

    for (var i = 0; i < 10; i++) {
      value = value
          .replaceAll(fa[i], '$i')
          .replaceAll(ar[i], '$i');
    }

    return value
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .trim();
  }

  int _int(dynamic value) {
    return int.tryParse(_normal((value ?? '').toString())) ?? 0;
  }

  String _fa(String value) {
    const digits = '۰۱۲۳۴۵۶۷۸۹';

    return value.replaceAllMapped(
      RegExp(r'[0-9]'),
          (m) => digits[int.parse(m.group(0)!)],
    );
  }

  String _dateString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  String _dateText(DateTime d) {
    final j = Gregorian.fromDateTime(d).toJalali();

    return _fa(
      '${j.year}/${j.month.toString().padLeft(2, '0')}/'
          '${j.day.toString().padLeft(2, '0')}',
    );
  }

  String _payerLabel(Map<String, dynamic> payer) {
    final value = payer['label'] ??
        payer['name'] ??
        payer['unit'] ??
        payer['full_name'] ??
        payer['title'];

    return (value ?? 'شناسه ${payer['id']}').toString();
  }

  InputDecoration _decoration(
      String label,
      IconData icon,
      ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _teal),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EF)),
      ),
    );
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<dynamic>([
        widget.service.getIncomeBanks(),
        widget.service.getIncomePayers(type: _payerType),
      ]);

      if (!mounted) return;

      final banks = List<Map<String, dynamic>>.from(results[0]);
      final payers = List<Map<String, dynamic>>.from(results[1]);

      setState(() {
        _banks = banks;
        _payers = payers;

        // فقط در صورت وجود یک بانک، آن را خودکار انتخاب کن.
        if (_banks.length == 1) {
          _bankId = _int(_banks.first['id']);
        }

        // اگر پرداخت‌کننده قبلی در فهرست نبود، انتخاب را خالی کن.
        if (_payerId != null &&
            !_payers.any((p) => _int(p['id']) == _payerId)) {
          _payerId = null;
        }

        if (_payerId == null && _payers.length == 1) {
          _payerId = _int(_payers.first['id']);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPayers() async {
    setState(() {
      _loadingPayers = true;
      _error = null;
    });

    try {
      final values = await widget.service.getIncomePayers(
        type: _payerType,
        search: _payerSearch.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _payers = values;

        if (_payerId != null &&
            !_payers.any((p) => _int(p['id']) == _payerId)) {
          _payerId = null;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _loadingPayers = false);
    }
  }

  Future<void> _changePayerType(String? value) async {
    if (value == null || value == _payerType || _saving) return;

    setState(() {
      _payerType = value;
      _payerId = null;
      _payers = [];
      _payerSearch.clear();
    });

    await _loadPayers();
  }

  Future<void> _chooseDate() async {
    final now = Gregorian.fromDateTime(DateTime.now()).toJalali();
    final initial = Gregorian.fromDateTime(_date).toJalali();

    final selected = await showDialog<Jalali>(
      context: context,
      builder: (_) => _IncomeJalaliPicker(
        initial: initial,
        first: Jalali(1300, 1, 1),
        last: Jalali(now.year + 20, 12, 29),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _date = selected.toDateTime());
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    if (_bankId == null) {
      setState(() => _error = 'حساب بانکی را انتخاب کنید.');
      return;
    }

    if (_payerId == null || _payerId! <= 0) {
      setState(() => _error = 'پرداخت‌کننده را انتخاب کنید.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.service.payIncome(
        incomeId: _int(widget.income['id']),
        bankId: _bankId!,
        paymentDate: _dateString(_date),
        transactionReference: _normal(_reference.text),
        payerType: _payerType,
        unitId: _payerType == 'owner' ? _payerId : null,
        renterId: _payerType == 'renter' ? _payerId : null,
        thirdPartyId: _payerType == 'other' ? _payerId : null,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;

    final payerTitle = switch (_payerType) {
      'owner' => 'انتخاب واحد مالک *',
      'renter' => 'انتخاب مستأجر *',
      'other' => 'انتخاب شخص ثالث *',
      _ => 'انتخاب پرداخت‌کننده *',
    };

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * .92,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF6F7FB),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: _loading
              ? const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          )
              : Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ثبت پرداخت درآمد',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
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
              const Divider(height: 1),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      Text(
                        (widget.income['description'] ?? 'درآمد')
                            .toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'مبلغ: ${_fa('${widget.income['amount']}')} تومان',
                        style: const TextStyle(
                          color: _purple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: .07),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),

                      // حساب بانکی
                      DropdownButtonFormField<int>(
                        value: _banks.any(
                              (b) => _int(b['id']) == _bankId,
                        )
                            ? _bankId
                            : null,
                        isExpanded: true,
                        decoration: _decoration(
                          'حساب بانکی *',
                          Icons.account_balance,
                        ),
                        items: _banks.map((bank) {
                          final id = _int(bank['id']);
                          final name = bank['bank_name'] ??
                              bank['name'] ??
                              'حساب بانکی';
                          final account =
                          (bank['account_no'] ?? '').toString();

                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              '$name${account.isEmpty ? '' : ' - $account'}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _saving
                            ? null
                            : (value) {
                          setState(() {
                            _bankId = value;
                            _error = null;
                          });
                        },
                        validator: (value) => value == null
                            ? 'حساب بانکی را انتخاب کنید.'
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // نوع پرداخت‌کننده
                      DropdownButtonFormField<String>(
                        value: _payerType,
                        isExpanded: true,
                        decoration: _decoration(
                          'نوع پرداخت‌کننده *',
                          Icons.person_outline,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'owner',
                            child: Text('مالک / واحد'),
                          ),
                          DropdownMenuItem(
                            value: 'renter',
                            child: Text('مستأجر'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('شخص ثالث'),
                          ),
                        ],
                        onChanged: _saving ? null : _changePayerType,
                      ),
                      const SizedBox(height: 14),

                      // جست‌وجوی پرداخت‌کننده
                      TextFormField(
                        controller: _payerSearch,
                        enabled: !_saving,
                        textInputAction: TextInputAction.search,
                        decoration: _decoration(
                          'جست‌وجوی پرداخت‌کننده',
                          Icons.search,
                        ).copyWith(
                          suffixIcon: IconButton(
                            tooltip: 'جست‌وجو',
                            onPressed: _saving || _loadingPayers
                                ? null
                                : _loadPayers,
                            icon: const Icon(Icons.search),
                          ),
                        ),
                        onFieldSubmitted: (_) => _loadPayers(),
                      ),
                      const SizedBox(height: 14),

                      // فهرست پرداخت‌کنندگان
                      if (_loadingPayers)
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        DropdownButtonFormField<int>(
                          value: _payers.any(
                                (p) => _int(p['id']) == _payerId,
                          )
                              ? _payerId
                              : null,
                          isExpanded: true,
                          decoration: _decoration(
                            payerTitle,
                            Icons.person_search,
                          ),
                          items: _payers.map((payer) {
                            return DropdownMenuItem<int>(
                              value: _int(payer['id']),
                              child: Text(
                                _payerLabel(payer),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _saving
                              ? null
                              : (value) {
                            setState(() {
                              _payerId = value;
                              _error = null;
                            });
                          },
                          validator: (value) => value == null
                              ? 'پرداخت‌کننده را انتخاب کنید.'
                              : null,
                        ),

                      const SizedBox(height: 14),

                      // تاریخ پرداخت
                      InkWell(
                        onTap: _saving ? null : _chooseDate,
                        child: InputDecorator(
                          decoration: _decoration(
                            'تاریخ پرداخت شمسی *',
                            Icons.calendar_month,
                          ),
                          child: Text(_dateText(_date)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // شماره پیگیری
                      TextFormField(
                        controller: _reference,
                        enabled: !_saving,
                        decoration: _decoration(
                          'شماره پیگیری (اختیاری)',
                          Icons.numbers,
                        ),
                      ),
                      const SizedBox(height: 22),

                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: _purple,
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
                              : const Icon(
                            Icons.check_circle_outline,
                          ),
                          label: Text(
                            _saving
                                ? 'در حال ثبت...'
                                : 'ثبت پرداخت',
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


// ------------------------------------------------------------
// مدیریت دسته‌بندی درآمد
// ------------------------------------------------------------

class _IncomeCategoriesScreen extends StatefulWidget {
  final ManagerIncomeService service;

  const _IncomeCategoriesScreen({required this.service});

  @override
  State<_IncomeCategoriesScreen> createState() =>
      _IncomeCategoriesScreenState();
}

class _IncomeCategoriesScreenState extends State<_IncomeCategoriesScreen> {
  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);

  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _name(Map<String, dynamic> item) =>
      (item['subject'] ?? item['title'] ?? item['name'] ?? '').toString();

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await widget.service.getCategories();
      if (mounted) setState(() => _categories = result);
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, textDirection: TextDirection.rtl),
        backgroundColor: error ? Colors.red.shade700 : _teal,
      ),
    );
  }


  Future<void> _edit([Map<String, dynamic>? item]) async {
    final controller = TextEditingController(
      text: item == null ? '' : _name(item),
    );

    String? subject;

    try {
      subject = await showDialog<String>(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              item == null ? 'دسته‌بندی جدید' : 'ویرایش دسته‌بندی',
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'نام دسته‌بندی',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('انصراف'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _purple,
                ),
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isNotEmpty) {
                    Navigator.pop(ctx, value);
                  }
                },
                child: const Text('ذخیره'),
              ),
            ],
          ),
        ),
      );
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    }

    if (!mounted || subject == null || subject.trim().isEmpty) {
      return;
    }

    try {
      final id = int.tryParse(item?['id']?.toString() ?? '');

      if (id == null) {
        await widget.service.createCategory(title: subject.trim());
      } else {
        await widget.service.updateCategory(
          categoryId: id,
          title: subject.trim(),
        );
      }

      if (!mounted) return;

      await _load();

      if (!mounted) return;
      _message('دسته‌بندی ذخیره شد.');
    } catch (e) {
      if (!mounted) return;

      _message(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    }
  }


  Future<void> _delete(Map<String, dynamic> item) async {
    final id = int.tryParse(item['id']?.toString() ?? '');
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف دسته‌بندی'),
          content: Text('دسته‌بندی «${_name(item)}» حذف شود؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await widget.service.deleteCategory(id);
      if (!mounted) return;
      await _load();
      _message('درخواست حذف دسته‌بندی انجام شد.');
    } catch (e) {
      _message(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          title: const Text('دسته‌بندی درآمدها'),
          centerTitle: true,
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _edit(),
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('دسته‌بندی جدید'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _categories.isEmpty
            ? const Center(child: Text('دسته‌بندی درآمدی ثبت نشده است.'))
            : RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final item = _categories[index];
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
                    _name(item).isEmpty ? 'بدون عنوان' : _name(item),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _edit(item);
                      if (v == 'delete') _delete(item);
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

// ------------------------------------------------------------
// انتخابگر تاریخ شمسی
// ------------------------------------------------------------

class _IncomeJalaliPicker extends StatefulWidget {
  final Jalali initial;
  final Jalali first;
  final Jalali last;

  const _IncomeJalaliPicker({
    required this.initial,
    required this.first,
    required this.last,
  });

  @override
  State<_IncomeJalaliPicker> createState() => _IncomeJalaliPickerState();
}

class _IncomeJalaliPickerState extends State<_IncomeJalaliPicker> {
  late Jalali _selected;
  late Jalali _month;

  static const _teal = Color(0xFF00ACC1);
  static const _purple = Color(0xFF610DB5);

  static const _months = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر',
    'مرداد', 'شهریور', 'مهر', 'آبان',
    'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  static const _weekdays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _month = Jalali(widget.initial.year, widget.initial.month, 1);
  }

  String _fa(String text) {
    const digits = '۰۱۲۳۴۵۶۷۸۹';
    return text.replaceAllMapped(
      RegExp(r'[0-9]'),
          (m) => digits[int.parse(m.group(0)!)],
    );
  }

  Jalali _shift(int delta) {
    var y = _month.year;
    var m = _month.month + delta;
    while (m < 1) {
      m += 12;
      y--;
    }
    while (m > 12) {
      m -= 12;
      y++;
    }
    return Jalali(y, m, 1);
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday = _month.toDateTime().weekday;
    final leading = (firstWeekday + 1) % 7;
    final cells = <Widget>[];

    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var day = 1; day <= _month.monthLength; day++) {
      final date = Jalali(_month.year, _month.month, day);
      final enabled = date.compareTo(widget.first) >= 0 &&
          date.compareTo(widget.last) <= 0;
      final selected = date.year == _selected.year &&
          date.month == _selected.month &&
          date.day == _selected.day;

      cells.add(
        InkWell(
          onTap: enabled ? () => setState(() => _selected = date) : null,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? _purple : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              _fa('$day'),
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : enabled
                    ? Colors.black87
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Row(
          children: [
            IconButton(
              onPressed: _shift(-1).compareTo(widget.first) >= 0
                  ? () => setState(() => _month = _shift(-1))
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(_months[_month.month - 1]),
                  Text(_fa('${_month.year}')),
                ],
              ),
            ),
            IconButton(
              onPressed: _shift(1).compareTo(widget.last) <= 0
                  ? () => setState(() => _month = _shift(1))
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: _weekdays
                    .map(
                      (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: _teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 4,
                crossAxisSpacing: 2,
                childAspectRatio: 1.05,
                children: cells,
              ),
              const SizedBox(height: 8),
              Text(
                _fa(
                  '${_selected.year}/${_selected.month.toString().padLeft(2, '0')}/${_selected.day.toString().padLeft(2, '0')}',
                ),
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
            onPressed: () => Navigator.pop(context, _selected),
            child: const Text('تأیید'),
          ),
        ],
      ),
    );
  }
}