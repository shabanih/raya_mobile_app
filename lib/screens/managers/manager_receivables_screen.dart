import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/manager_receivable_service.dart';

class ManagerReceivablesScreen extends StatefulWidget {
  const ManagerReceivablesScreen({super.key});

  @override
  State<ManagerReceivablesScreen> createState() =>
      _ManagerReceivablesScreenState();
}

class _ManagerReceivablesScreenState
    extends State<ManagerReceivablesScreen> {
  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);
  static const Color _background = Color(0xFFF6F7FB);

  final ManagerReceivableService _service = ManagerReceivableService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _items = [];

  bool _loading = true;
  String _paymentFilter = 'all';
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

  String _normalize(String value) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';

    for (var i = 0; i < 10; i++) {
      value = value.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
    }

    return value
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('٫', '.')
        .trim();
  }

  String _fa(String value) {
    const digits = '۰۱۲۳۴۵۶۷۸۹';

    return value.replaceAllMapped(
      RegExp(r'[0-9]'),
          (m) => digits[int.parse(m.group(0)!)],
    );
  }

  int _int(dynamic value) =>
      int.tryParse(_normalize('${value ?? ''}')) ?? 0;

  double _number(dynamic value) =>
      double.tryParse(_normalize('${value ?? ''}')) ?? 0;

  String _money(dynamic value) {
    final amount = _number(value).round().toString();

    final formatted = amount.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
    );

    return '${_fa(formatted)} تومان';
  }

  bool _received(Map<String, dynamic> item) {
    return item['is_received_money'] == true ||
        item['is_received_money'] == 1 ||
        item['is_received_money'] == 'true' ||
        item['is_paid'] == true ||
        item['is_paid'] == 1 ||
        item['is_paid'] == 'true';
  }

  String _dateText(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '-';
    }

    final date = DateTime.tryParse(value.toString());
    if (date == null) return _fa(value.toString());

    final j = Gregorian.fromDateTime(date).toJalali();

    return _fa(
      '${j.year}/'
          '${j.month.toString().padLeft(2, '0')}/'
          '${j.day.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _loading = true);

    try {
      final result = await _service.getReceivables(
        paymentStatus: _paymentFilter,
      );

      if (!mounted) return;

      setState(() => _items = result);
    } catch (e) {
      _message(_cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final query = _normalize(_search).toLowerCase();

    return _items.where((item) {
      if (query.isEmpty) return true;

      final searchable = [
        item['description'],
        item['details'],
        item['doc_number'],
        item['financial_document_number'],
        item['transaction_reference'],
      ].whereType<Object>().join(' ').toLowerCase();

      return _normalize(searchable).toLowerCase().contains(query);
    }).toList();
  }

  double get _total =>
      _filtered.fold(0, (sum, item) => sum + _number(item['amount']));

  Future<void> _changeFilter(String value) async {
    if (_paymentFilter == value) return;

    setState(() => _paymentFilter = value);
    await _loadData();
  }

  Future<void> _openForm({Map<String, dynamic>? item}) async {
    if (item != null && _received(item)) {
      _message('سند دریافت‌شده قابل ویرایش نیست.', error: true);
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReceivableFormSheet(
        service: _service,
        item: item,
      ),
    );

    if (result == true && mounted) {
      await _loadData();
      _message(item == null ? 'سند ثبت شد.' : 'سند ویرایش شد.');
    }
  }

  Future<void> _receive(Map<String, dynamic> item) async {
    if (_received(item)) {
      _message('این سند قبلاً دریافت شده است.', error: true);
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReceiveMoneySheet(
        service: _service,
        item: item,
      ),
    );

    if (result == true && mounted) {
      await _loadData();
      _message('دریافت وجه ثبت شد.');
    }
  }

  Future<void> _cancelReceive(Map<String, dynamic> item) async {
    if (!_received(item)) {
      _message('این سند هنوز دریافت نشده است.', error: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('لغو دریافت وجه'),
          content: Text(
            'دریافت مبلغ ${_money(item['amount'])} لغو شود؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('لغو دریافت'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await _service.cancelReceiveMoney(_int(item['id']));

      if (!mounted) return;

      await _loadData();
      _message('دریافت وجه لغو شد.');
    } catch (e) {
      _message(_cleanError(e), error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    if (_received(item)) {
      _message('سند دریافت‌شده قابل حذف نیست.', error: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف سند دریافتنی'),
          content: const Text('آیا از حذف این سند مطمئن هستید؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteReceivable(_int(item['id']));

      if (!mounted) return;

      await _loadData();
      _message('سند حذف شد.');
    } catch (e) {
      _message(_cleanError(e), error: true);
    }
  }

  void _showDetails(Map<String, dynamic> item) {
    final docs = item['documents'];

    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('جزئیات سند دریافتنی'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detail('شرح', item['description']),
                _detail('مبلغ', _money(item['amount'])),
                _detail('تاریخ سند', _dateText(item['doc_date'])),
                _detail(
                  'شماره فاکتور',
                  _fa('${item['doc_number'] ?? '—'}'),
                ),
                _detail(
                  'شماره سند مالی',
                  _fa('${item['financial_document_number'] ?? '—'}'),
                ),
                _detail(
                  'وضعیت',
                  _received(item) ? 'دریافت‌شده' : 'دریافت‌نشده',
                ),
                _detail('حساب بانکی', item['bank_name']),
                _detail('تاریخ دریافت', _dateText(item['payment_date'])),
                _detail(
                  'شماره پیگیری',
                  _fa('${item['transaction_reference'] ?? '—'}'),
                ),
                _detail('توضیحات', item['details']),
                if (docs is List)
                  ...docs.asMap().entries.map((entry) {
                    final doc = entry.value;
                    return _detail(
                      'مدرک ${entry.key + 1}',
                      doc is Map ? doc['url'] : doc,
                    );
                  }),
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
      child: Text(
        '$label: $text',
        style: const TextStyle(height: 1.7),
      ),
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
            'مدیریت اسناد دریافتنی',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          actions: [
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
          label: const Text('ثبت سند'),
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
                                'مجموع اسناد نمایش‌داده‌شده',
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
                                '${_fa(items.length.toString())} سند',
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
                    onChanged: (value) => setState(() => _search = value),
                    decoration: InputDecoration(
                      hintText: 'جست‌وجوی شرح یا شماره سند...',
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
                    _filterChip('دریافت‌نشده', 'unpaid'),
                    _filterChip('دریافت‌شده', 'paid'),
                  ],
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: _teal,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'سند دریافتنی پیدا نشد',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'می‌توانید سند جدیدی ثبت کنید یا فیلتر را تغییر دهید.',
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
                          (_, index) => _receivableCard(items[index]),
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

  Widget _receivableCard(Map<String, dynamic> item) {
    final received = _received(item);
    final description = (item['description'] ?? '').toString().trim();
    final title = description.isEmpty ? 'سند بدون شرح' : description;
    final docNo =
        item['financial_document_number'] ?? item['doc_number'];

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
                    color: received
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    received
                        ? Icons.check_circle_outline_rounded
                        : Icons.pending_actions_rounded,
                    color: received
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _money(item['amount']),
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
                _info(
                  Icons.calendar_month_rounded,
                  _dateText(item['doc_date']),
                ),
                _info(
                  received ? Icons.check_circle : Icons.schedule,
                  received ? 'دریافت‌شده' : 'دریافت‌نشده',
                  color: received ? Colors.green : Colors.orange.shade800,
                ),
                if (docNo != null && docNo.toString().isNotEmpty)
                  _info(
                    Icons.numbers_rounded,
                    'سند ${_fa(docNo.toString())}',
                  ),
              ],
            ),
            if ((item['details'] ?? '').toString().trim().isNotEmpty) ...[
              const SizedBox(height: 9),
              Text(
                item['details'].toString(),
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
                  tooltip: received ? 'لغو دریافت' : 'ثبت دریافت وجه',
                  onPressed: () => received
                      ? _cancelReceive(item)
                      : _receive(item),
                  icon: Icon(
                    received
                        ? Icons.cancel_outlined
                        : Icons.payments_outlined,
                    color: received ? Colors.red : Colors.green.shade700,
                  ),
                ),
                IconButton(
                  tooltip: 'جزئیات',
                  onPressed: () => _showDetails(item),
                  icon: const Icon(
                    Icons.visibility_outlined,
                    color: _teal,
                  ),
                ),
                if (!received)
                  IconButton(
                    tooltip: 'ویرایش',
                    onPressed: () => _openForm(item: item),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: _purple,
                    ),
                  ),
                if (!received)
                  IconButton(
                    tooltip: 'حذف',
                    onPressed: () => _delete(item),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
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
}

// ------------------------------------------------------------
// فرم ایجاد و ویرایش سند دریافتنی
// بانک و پرداخت‌کننده در این فرم انتخاب نمی‌شوند.
// ------------------------------------------------------------


class _ReceivableFormSheet extends StatefulWidget {
  final ManagerReceivableService service;
  final Map<String, dynamic>? item;

  const _ReceivableFormSheet({
    required this.service,
    this.item,
  });

  @override
  State<_ReceivableFormSheet> createState() =>
      _ReceivableFormSheetState();
}

class _ReceivableFormSheetState extends State<_ReceivableFormSheet> {
  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);

  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _details = TextEditingController();
  final _docNo = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedFiles = [];

  DateTime _date = DateTime.now();
  bool _saving = false;

  bool get _editing => widget.item != null;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    if (item != null) {
      _amount.text = '${item['amount'] ?? ''}';
      _description.text = '${item['description'] ?? ''}';
      _details.text = '${item['details'] ?? ''}';
      _docNo.text = '${item['doc_number'] ?? ''}';

      final parsed = DateTime.tryParse('${item['doc_date'] ?? ''}');
      if (parsed != null) {
        _date = parsed;
      }
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
      value = value.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
    }

    return value
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('٫', '.')
        .trim();
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
          content: Text(text, textDirection: TextDirection.rtl),
          backgroundColor: error ? Colors.red.shade700 : _teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _pickImages() async {
    if (_saving) return;

    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (!mounted || images.isEmpty) return;

      var limitReached = false;

      setState(() {
        for (final image in images) {
          if (_selectedFiles.any((f) => f.path == image.path)) {
            continue;
          }

          if (_selectedFiles.length >= 2) {
            limitReached = true;
            break;
          }

          _selectedFiles.add(File(image.path));
        }
      });

      if (limitReached) {
        _message('حداکثر دو تصویر قابل پیوست است.', error: true);
      }
    } catch (e) {
      _message('انتخاب تصویر ناموفق بود: $e', error: true);
    }
  }

  void _removeFile(int index) {
    if (_saving) return;

    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  Future<void> _chooseDate() async {
    final now = Gregorian.fromDateTime(DateTime.now()).toJalali();
    final initial = Gregorian.fromDateTime(_date).toJalali();

    final selected = await showDialog<Jalali>(
      context: context,
      builder: (ctx) => _ReceivableJalaliPicker(
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

    final amount = _normal(_amount.text);
    final value = double.tryParse(amount);

    if (value == null || value <= 0 || value % 1 != 0) {
      _message('مبلغ معتبر و صحیح وارد کنید.', error: true);
      return;
    }

    if (_selectedFiles.length > 2) {
      _message('حداکثر دو تصویر قابل پیوست است.', error: true);
      return;
    }

    setState(() => _saving = true);

    try {
      await widget.service.saveReceivableWithFiles(
        receivableId: _editing
            ? int.tryParse('${widget.item!['id'] ?? ''}')
            : null,
        amount: amount,
        date: _dateString(_date),
        description: _description.text.trim(),
        details: _details.text.trim(),
        docNo: _normal(_docNo.text),
        files: _selectedFiles,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
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

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _teal),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * .9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _editing
                          ? 'ویرایش سند دریافتنی'
                          : 'ثبت سند دریافتنی',
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
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    TextFormField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      decoration: _decoration(
                        'مبلغ به تومان *',
                        Icons.payments_outlined,
                      ),
                      validator: (value) {
                        final number =
                        double.tryParse(_normal(value ?? ''));

                        if (number == null || number <= 0) {
                          return 'مبلغ معتبر وارد کنید.';
                        }

                        if (number % 1 != 0) {
                          return 'مبلغ باید عدد صحیح باشد.';
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
                      maxLength: 400,
                      decoration: _decoration(
                        'شرح سند *',
                        Icons.short_text,
                      ),
                      validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'شرح سند را وارد کنید.'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _docNo,
                      keyboardType: TextInputType.number,
                      decoration: _decoration(
                        'شماره فاکتور (اختیاری)',
                        Icons.numbers,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _details,
                      minLines: 2,
                      maxLines: 4,
                      decoration: _decoration(
                        'توضیحات تکمیلی',
                        Icons.notes,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // پیوست تصاویر
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _pickImages,
                        icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                        ),
                        label: const Text('افزودن تصویر پیوست'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'حداکثر دو تصویر قابل انتخاب است.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    if (_selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ..._selectedFiles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;
                        final fileName =
                            file.path.split(Platform.pathSeparator).last;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(
                              Icons.image_outlined,
                              color: _teal,
                              size: 30,
                            ),
                            title: Text(
                              fileName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              tooltip: 'حذف تصویر',
                              onPressed: _saving
                                  ? null
                                  : () => _removeFile(index),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],

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
                              : 'ثبت سند',
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
    );
  }
}


// ------------------------------------------------------------
// ثبت دریافت واقعی وجه
// انتخاب حساب بانکی فقط در این فرم انجام می‌شود.
// ------------------------------------------------------------


class _ReceiveMoneySheet extends StatefulWidget {
  final ManagerReceivableService service;
  final Map<String, dynamic> item;

  const _ReceiveMoneySheet({
    required this.service,
    required this.item,
  });

  @override
  State<_ReceiveMoneySheet> createState() => _ReceiveMoneySheetState();
}

class _ReceiveMoneySheetState extends State<_ReceiveMoneySheet> {
  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);

  final _formKey = GlobalKey<FormState>();
  final _reference = TextEditingController();
  final _payerSearch = TextEditingController();

  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> _payers = [];

  int? _bankId;
  int? _payerId;

  String _payerType = 'owner';
  DateTime _date = DateTime.now();

  bool _loading = true;
  bool _loadingPayers = false;
  bool _saving = false;


  @override
  void initState() {
    super.initState();
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
      value = value.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
    }

    return value
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('٫', '.')
        .trim();
  }

  String _fa(String value) {
    const digits = '۰۱۲۳۴۵۶۷۸۹';

    return value.replaceAllMapped(
      RegExp(r'[0-9]'),
          (m) => digits[int.parse(m.group(0)!)],
    );
  }

  int _int(dynamic value) =>
      int.tryParse(_normal('${value ?? ''}')) ?? 0;

  String _money(dynamic value) {
    final amount = double.tryParse(_normal('$value')) ?? 0;
    final text = amount.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
    );
    return '${_fa(text)} تومان';
  }

  String _dateString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  String _dateText(DateTime d) {
    final j = Gregorian.fromDateTime(d).toJalali();
    return '${_fa('${j.year}')}/'
        '${_fa(j.month.toString().padLeft(2, '0'))}/'
        '${_fa(j.day.toString().padLeft(2, '0'))}';
  }

  String _errorText(Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  Future<void> _loadInitialData() async {
    try {
      final banks = await widget.service.getReceivableBanks();

      if (!mounted) return;

      setState(() {
        _banks = banks;
        if (banks.length == 1) {
          _bankId = _int(banks.first['id']);
        }
        _loading = false;
      });

      await _loadPayers();
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _message(_errorText(e), error: true);
    }
  }

  Future<void> _loadPayers({String search = ''}) async {
    setState(() {
      _loadingPayers = true;
      _payerId = null;
      _payers = [];
    });

    try {
      final results = await widget.service.getReceivablePayers(
        type: _payerType,
        search: search.trim(),
      );

      if (!mounted) return;

      setState(() {
        _payers = results;

        if (results.length == 1) {
          _payerId = _int(results.first['id']);
        }

        _loadingPayers = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingPayers = false);
      _message(_errorText(e), error: true);
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

  Future<void> _searchPayers(String value) async {
    // جست‌وجو هنگام تایپ با درخواست مستقل انجام می‌شود.
    // برای جلوگیری از نمایش نتیجه قدیمی، شناسه انتخابی پاک می‌شود.
    if (_saving) return;

    setState(() {
      _payerId = null;
      _loadingPayers = true;
    });

    try {
      final results = await widget.service.getReceivablePayers(
        type: _payerType,
        search: value.trim(),
      );

      if (!mounted) return;

      // فقط نتیجه جست‌وجوی جاری را نمایش بده.
      if (_payerSearch.text.trim() != value.trim()) return;

      setState(() {
        _payers = results;
        _payerId = results.length == 1 ? _int(results.first['id']) : null;
        _loadingPayers = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingPayers = false);
      _message(_errorText(e), error: true);
    }
  }

  String _payerName(Map<String, dynamic> payer) {
    final name = (payer['name'] ??
        payer['full_name'] ??
        payer['title'] ??
        payer['display_name'] ??
        payer['payer_name'] ??
        payer['username'] ??
        '')
        .toString()
        .trim();

    if (_payerType == 'owner' || _payerType == 'renter') {
      final unit = (payer['unit'] ?? '').toString().trim();

      if (unit.isNotEmpty) {
        return 'واحد ${_fa(unit)} - $name';
      }
    }

    return name.isEmpty
        ? 'پرداخت‌کننده ${_fa('${payer['id'] ?? ''}')}'
        : name;
  }

  Future<void> _chooseDate() async {
    final now = Gregorian.fromDateTime(DateTime.now()).toJalali();
    final initial = Gregorian.fromDateTime(_date).toJalali();

    final selected = await showDialog<Jalali>(
      context: context,
      builder: (ctx) => _ReceivableJalaliPicker(
        initial: initial,
        first: Jalali(1300, 1, 1),
        last: now,
      ),
    );

    if (selected != null && mounted) {
      setState(() => _date = selected.toDateTime());
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _teal),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
      ),
    );
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text, textDirection: TextDirection.rtl),
          backgroundColor: error ? Colors.red.shade700 : _teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    if (_bankId == null) {
      _message('حساب بانکی را انتخاب کنید.', error: true);
      return;
    }

    if (_payerId == null) {
      _message('پرداخت‌کننده را انتخاب کنید.', error: true);
      return;
    }

    final selectedPayer = _payers.where(
          (p) => _int(p['id']) == _payerId,
    );

    if (selectedPayer.isEmpty) {
      _message('پرداخت‌کننده انتخاب‌شده معتبر نیست.', error: true);
      return;
    }

    int? unitId;
    int? renterId;
    int? thirdPartyId;

    if (_payerType == 'owner') {
      unitId = _payerId;
    } else if (_payerType == 'renter') {
      renterId = _payerId;
    } else if (_payerType == 'other') {
      thirdPartyId = _payerId;
    }

    setState(() => _saving = true);

    try {
      await widget.service.receiveMoney(
        receivableId: _int(widget.item['id']),
        bankId: _bankId!,
        paymentDate: _dateString(_date),
        transactionReference: _normal(_reference.text),
        payerType: _payerType,
        unitId: unitId,
        renterId: renterId,
        thirdPartyId: thirdPartyId,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _message(_errorText(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            18,
            18,
            18,
            18 + MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: _loading
              ? const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          )
              : SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'ثبت دریافت وجه',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'مبلغ سند: ${_money(widget.item['amount'])}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),

                  DropdownButtonFormField<int>(
                    value: _bankId,
                    isExpanded: true,
                    decoration: _decoration(
                      'حساب بانکی مقصد *',
                      Icons.account_balance,
                    ),
                    items: _banks.map((bank) {
                      final name = bank['bank_name'] ?? bank['name'] ?? 'بانک';
                      final account = (bank['account_no'] ?? '').toString().trim();

                      return DropdownMenuItem<int>(
                        value: _int(bank['id']),
                        child: Text(
                          account.isEmpty
                              ? '$name'
                              : '$name - ${_fa(account)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _bankId = value),
                    validator: (_) =>
                    _bankId == null ? 'حساب بانکی را انتخاب کنید.' : null,
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    value: _payerType,
                    isExpanded: true,
                    decoration: _decoration(
                      'نوع پرداخت‌کننده *',
                      Icons.people_alt_outlined,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'owner',
                        child: Text('مالک واحد'),
                      ),
                      DropdownMenuItem(
                        value: 'renter',
                        child: Text('مستأجر'),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text('شخص دیگر'),
                      ),
                    ],
                    onChanged: _saving ? null : _changePayerType,
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _payerSearch,
                    enabled: !_saving,
                    onChanged: _searchPayers,
                    decoration: _decoration(
                      'جست‌وجوی پرداخت‌کننده',
                      Icons.search,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_loadingPayers)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_payers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'پرداخت‌کننده‌ای پیدا نشد.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: _payerId,
                      isExpanded: true,
                      decoration: _decoration(
                        'انتخاب پرداخت‌کننده *',
                        Icons.person_outline,
                      ),
                      items: _payers.map((payer) {
                        return DropdownMenuItem<int>(
                          value: _int(payer['id']),
                          child: Text(
                            _payerName(payer),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _payerId = value),
                      validator: (_) => _payerId == null
                          ? 'پرداخت‌کننده را انتخاب کنید.'
                          : null,
                    ),

                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _saving ? null : _chooseDate,
                    child: InputDecorator(
                      decoration: _decoration(
                        'تاریخ دریافت وجه *',
                        Icons.calendar_month,
                      ),
                      child: Text(_dateText(_date)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _reference,
                    enabled: !_saving,
                    maxLength: 20,
                    decoration: _decoration(
                      'شماره پیگیری (اختیاری)',
                      Icons.confirmation_number_outlined,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: _purple,
                      ),
                      icon: _saving
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _saving ? 'در حال ثبت...' : 'تأیید دریافت وجه',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ------------------------------------------------------------
// انتخابگر تاریخ شمسی
// ------------------------------------------------------------

class _ReceivableJalaliPicker extends StatefulWidget {
  final Jalali initial;
  final Jalali first;
  final Jalali last;

  const _ReceivableJalaliPicker({
    required this.initial,
    required this.first,
    required this.last,
  });

  @override
  State<_ReceivableJalaliPicker> createState() =>
      _ReceivableJalaliPickerState();
}

class _ReceivableJalaliPickerState
    extends State<_ReceivableJalaliPicker> {
  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);

  late Jalali _selected;
  late Jalali _month;

  @override
  void initState() {
    super.initState();

    _selected = widget.initial;
    _month = Jalali(widget.initial.year, widget.initial.month, 1);
  }

  bool _sameDay(Jalali a, Jalali b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _allowed(Jalali date) {
    return date.compareTo(widget.first) >= 0 &&
        date.compareTo(widget.last) <= 0;
  }

  void _changeMonth(int delta) {
    final next = _month.addMonths(delta);

    if (next.year < widget.first.year ||
        next.year > widget.last.year) {
      return;
    }

    setState(() => _month = next);
  }
  String _fa(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    for (int i = 0; i < english.length; i++) {
      value = value.replaceAll(english[i], persian[i]);
    }

    return value;
  }
  @override
  Widget build(BuildContext context) {
    final firstDay = _month.weekDay;
    final days = _month.monthLength;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  Expanded(
                    child: Text(
                      '${_month.formatter.mN} ${_fa('${_month.year}')}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('ش'),
                  Text('ی'),
                  Text('د'),
                  Text('س'),
                  Text('چ'),
                  Text('پ'),
                  Text('ج'),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: days + firstDay - 1,
                itemBuilder: (_, index) {
                  if (index < firstDay - 1) {
                    return const SizedBox.shrink();
                  }

                  final day = index - firstDay + 2;
                  final date = Jalali(
                    _month.year,
                    _month.month,
                    day,
                  );

                  final selected = _sameDay(date, _selected);
                  final allowed = _allowed(date);

                  return InkWell(
                    onTap: allowed
                        ? () => setState(() => _selected = date)
                        : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? _purple : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _fa('$day'),
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : allowed
                              ? Colors.black87
                              : Colors.black26,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),

                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('انصراف'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _teal,
                    ),
                    onPressed: () => Navigator.pop(context, _selected),
                    child: const Text('تأیید'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}