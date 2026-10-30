import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_property_service.dart';

class ManagerPropertyScreen extends StatefulWidget {
  const ManagerPropertyScreen({super.key});

  @override
  State<ManagerPropertyScreen> createState() =>
      _ManagerPropertyScreenState();
}

class _ManagerPropertyScreenState extends State<ManagerPropertyScreen> {
  static const Color teal = Color(0xFF00ACC1);
  static const Color purple = Color(0xFF610DB5);
  static const Color background = Color(0xFFF6F7FB);

  final service = ManagerPropertyService.instance;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> items = [];
  bool loading = true;
  String paymentFilter = 'all';
  String search = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String cleanError(Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  String normalize(String value) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';

    for (var i = 0; i < 10; i++) {
      value = value.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
    }

    return value.replaceAll(',', '').replaceAll('٬', '').trim();
  }

  String fa(String value) {
    const digits = '۰۱۲۳۴۵۶۷۸۹';
    return value.replaceAllMapped(
      RegExp(r'[0-9]'),
          (m) => digits[int.parse(m.group(0)!)],
    );
  }

  int intValue(dynamic value) =>
      int.tryParse(normalize('${value ?? ''}')) ?? 0;

  double number(dynamic value) =>
      double.tryParse(normalize('${value ?? ''}')) ?? 0;

  String money(dynamic value) {
    final amount = number(value).round().toString();
    final formatted = amount.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
    );
    return '${fa(formatted)} تومان';
  }

  bool isPaid(Map<String, dynamic> item) {
    final value = item['is_paid'];
    return value == true || value == 1 || value == 'true';
  }

  String dateText(dynamic value) {
    if (value == null || value.toString().isEmpty) return '—';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return fa(value.toString());

    final j = Gregorian.fromDateTime(date).toJalali();

    return fa(
      '${j.year}/'
          '${j.month.toString().padLeft(2, '0')}/'
          '${j.day.toString().padLeft(2, '0')}',
    );
  }

  void message(String text, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text, textDirection: TextDirection.rtl),
          backgroundColor: error ? Colors.red.shade700 : teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    try {
      final result = await service.getProperties(
        paymentStatus: paymentFilter,
      );

      if (!mounted) return;
      setState(() => items = result);
    } catch (e) {
      message(cleanError(e), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> get filtered {
    final query = normalize(search).toLowerCase();

    return items.where((item) {
      if (query.isEmpty) return true;

      final text = [
        item['property_name'],
        item['property_code'],
        item['property_location'],
        item['property_unit'],
        item['company_name'],
        item['receiver_name'],
        item['document_number'],
        item['financial_document_number'],
        item['transaction_reference'],
        item['details'],
      ].whereType<Object>().join(' ');

      return normalize(text).toLowerCase().contains(query);
    }).toList();
  }

  double get total => filtered.fold(
    0,
        (sum, item) => sum + number(item['property_price']),
  );

  Future<void> changeFilter(String value) async {
    if (paymentFilter == value) return;
    setState(() => paymentFilter = value);
    await loadData();
  }

  Future<void> openForm({Map<String, dynamic>? item}) async {
    if (item != null && isPaid(item)) {
      message('اموال پرداخت‌شده قابل ویرایش نیست.', error: true);
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PropertyFormSheet(
        service: service,
        item: item,
      ),
    );

    if (result == true && mounted) {
      await loadData();
      message(item == null ? 'اموال با موفقیت ثبت شد.' : 'اطلاعات اموال ویرایش شد.');
    }
  }

  Future<void> pay(Map<String, dynamic> item) async {
    if (isPaid(item)) {
      message('این اموال قبلاً پرداخت شده است.', error: true);
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PropertyPaymentSheet(
        service: service,
        item: item,
      ),
    );

    if (result == true && mounted) {
      await loadData();
      message('پرداخت با موفقیت ثبت شد.');
    }
  }

  Future<void> cancelPayment(Map<String, dynamic> item) async {
    if (!isPaid(item)) {
      message('این اموال هنوز پرداخت نشده است.', error: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('لغو پرداخت'),
          content: Text(
            'پرداخت مبلغ ${money(item['property_price'])} لغو شود؟\n'
                'موجودی حساب بانکی مجدداً محاسبه خواهد شد.',
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
      await service.cancelPropertyPayment(intValue(item['id']));

      if (!mounted) return;
      await loadData();
      message('پرداخت لغو شد و موجودی بانک مجدداً محاسبه شد.');
    } catch (e) {
      message(cleanError(e), error: true);
    }
  }

  Future<void> delete(Map<String, dynamic> item) async {
    if (isPaid(item)) {
      message('اموال پرداخت‌شده قابل حذف نیست.', error: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف اموال'),
          content: const Text('آیا از حذف این اموال مطمئن هستید؟'),
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
      await service.deleteProperty(intValue(item['id']));

      if (!mounted) return;
      await loadData();
      message('اموال حذف شد.');
    } catch (e) {
      message(cleanError(e), error: true);
    }
  }

  void showDetails(Map<String, dynamic> item) {
    final docs = item['documents'];

    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('جزئیات اموال'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                detail('نام اموال', item['property_name']),
                detail('کد اموال', fa('${item['property_code'] ?? '—'}')),
                detail('ارزش اموال', money(item['property_price'])),
                detail('تعداد', fa('${item['count'] ?? '—'}')),
                detail('واحد مرتبط', item['property_unit']),
                detail('آدرس', item['property_location']),
                detail('دریافت‌کننده', item['receiver_name']),
                detail('فروشنده', item['company_name']),
                detail(
                  'شماره سند',
                  fa('${item['document_number'] ?? '—'}'),
                ),
                detail(
                  'شماره سند مالی',
                  fa('${item['financial_document_number'] ?? '—'}'),
                ),
                detail('تاریخ خرید', dateText(item['property_purchase_date'])),
                detail(
                  'وضعیت پرداخت',
                  isPaid(item) ? 'پرداخت‌شده' : 'پرداخت‌نشده',
                ),
                detail('حساب بانکی', item['bank_name']),
                detail('تاریخ پرداخت', dateText(item['payment_date'])),
                detail(
                  'شماره پیگیری',
                  fa('${item['transaction_reference'] ?? '—'}'),
                ),
                detail('توضیحات', item['details']),
                if (docs is List)
                  ...docs.asMap().entries.map((entry) {
                    final doc = entry.value;
                    return detail(
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

  Widget detail(String label, dynamic value) {
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

  Widget info(IconData icon, String text, {Color color = Colors.black54}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(text, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  Widget filterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: paymentFilter == value,
      selectedColor: teal.withValues(alpha: .15),
      checkmarkColor: teal,
      onSelected: (_) => changeFilter(value),
    );
  }

  Widget propertyCard(Map<String, dynamic> item) {
    final paid = isPaid(item);

    final name = (item['property_name'] ?? '').toString().trim();
    final title = name.isEmpty ? 'اموال بدون نام' : name;
    final docNo = item['financial_document_number'];

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
                        : Icons.home_work_outlined,
                    color: paid ? Colors.green.shade700 : Colors.orange.shade800,
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
                    money(item['property_price']),
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      color: purple,
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
                info(
                  Icons.calendar_month_rounded,
                  'خرید: ${dateText(item['property_purchase_date'])}',
                ),
                info(
                  Icons.inventory_2_outlined,
                  'تعداد: ${fa('${item['count'] ?? 0}') }',
                ),
                info(
                  paid ? Icons.check_circle : Icons.schedule,
                  paid ? 'پرداخت‌شده' : 'پرداخت‌نشده',
                  color: paid ? Colors.green : Colors.orange.shade800,
                ),
                if (docNo != null)
                  info(Icons.numbers_rounded, 'سند ${fa('$docNo')}'),
                if ((item['property_code'] ?? '').toString().isNotEmpty)
                  info(
                    Icons.qr_code_rounded,
                    'کد ${fa('${item['property_code']}')}',
                  ),
              ],
            ),
            if ((item['company_name'] ?? '').toString().trim().isNotEmpty) ...[
              const SizedBox(height: 9),
              info(
                Icons.business_outlined,
                item['company_name'].toString(),
              ),
            ],
            if ((item['property_location'] ?? '').toString().trim().isNotEmpty) ...[
              const SizedBox(height: 9),
              info(
                Icons.location_on_outlined,
                item['property_location'].toString(),
              ),
            ],
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
                  tooltip: paid ? 'لغو پرداخت' : 'ثبت پرداخت',
                  onPressed: () => paid ? cancelPayment(item) : pay(item),
                  icon: Icon(
                    paid ? Icons.cancel_outlined : Icons.payments_outlined,
                    color: paid ? Colors.red : Colors.green.shade700,
                  ),
                ),
                IconButton(
                  tooltip: 'جزئیات',
                  onPressed: () => showDetails(item),
                  icon: const Icon(Icons.visibility_outlined, color: teal),
                ),
                if (!paid)
                  IconButton(
                    tooltip: 'ویرایش',
                    onPressed: () => openForm(item: item),
                    icon: const Icon(Icons.edit_outlined, color: purple),
                  ),
                if (!paid)
                  IconButton(
                    tooltip: 'حذف',
                    onPressed: () => delete(item),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
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
    final data = filtered;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: const Text(
            'مدیریت اموال',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          backgroundColor: teal,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'تازه‌سازی',
              onPressed: loadData,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => openForm(),
          backgroundColor: purple,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('ثبت اموال'),
        ),
        body: RefreshIndicator(
          onRefresh: loadData,
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
                        colors: [teal, Color(0xFF00838F)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.home_work_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'مجموع ارزش اموال نمایش‌داده‌شده',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                money(total),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${fa(data.length.toString())} مورد',
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
                    controller: searchController,
                    onChanged: (v) => setState(() => search = v),
                    decoration: InputDecoration(
                      hintText: 'جست‌وجوی نام، کد، فروشنده یا شماره سند...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: search.isEmpty
                          ? null
                          : IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() => search = '');
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
                    filterChip('همه', 'all'),
                    filterChip('پرداخت‌نشده', 'unpaid'),
                    filterChip('پرداخت‌شده', 'paid'),
                  ],
                ),
              ),
              if (loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (data.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.home_work_outlined,
                            size: 64,
                            color: teal,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'اموالی پیدا نشد',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'می‌توانید اموال جدیدی ثبت کنید یا فیلتر را تغییر دهید.',
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
                          (_, index) => propertyCard(data[index]),
                      childCount: data.length,
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

// ------------------------------------------------------------------
// فرم ثبت و ویرایش اموال
// ------------------------------------------------------------------

class _PropertyFormSheet extends StatefulWidget {
  final ManagerPropertyService service;
  final Map<String, dynamic>? item;

  const _PropertyFormSheet({
    required this.service,
    this.item,
  });

  @override
  State<_PropertyFormSheet> createState() => _PropertyFormSheetState();
}

class _PropertyFormSheetState extends State<_PropertyFormSheet> {
  static const Color teal = Color(0xFF00ACC1);
  static const Color purple = Color(0xFF610DB5);

  final formKey = GlobalKey<FormState>();

  // final receiverName = TextEditingController();
  final companyName = TextEditingController();
  final documentNumber = TextEditingController();
  final count = TextEditingController();
  final propertyName = TextEditingController();
  final propertyUnit = TextEditingController();
  final propertyLocation = TextEditingController();
  final propertyCode = TextEditingController();
  final propertyPrice = TextEditingController();
  final details = TextEditingController();

  final picker = ImagePicker();
  final List<File> files = [];

  DateTime purchaseDate = DateTime.now();
  bool purchaseDateSelected = false;
  bool saving = false;

  bool get editing => widget.item != null;

  int? parseInteger(String value) {
    final normalized = normal(value);

    // اگر مقدار از API به شکل 2.0 آمده باشد
    final parsedDouble = double.tryParse(normalized);

    if (parsedDouble == null ||
        !parsedDouble.isFinite ||
        parsedDouble != parsedDouble.truncateToDouble()) {
      return null;
    }

    return parsedDouble.toInt();
  }

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    if (item == null) return;

    // receiverName.text = '${item['receiver_name'] ?? ''}';
    companyName.text = '${item['company_name'] ?? ''}';
    documentNumber.text = '${item['document_number'] ?? ''}';
    count.text = '${item['count'] ?? ''}';
    propertyName.text = '${item['property_name'] ?? ''}';
    propertyUnit.text = '${item['property_unit'] ?? ''}';
    propertyLocation.text = '${item['property_location'] ?? ''}';
    propertyCode.text = '${item['property_code'] ?? ''}';
    propertyPrice.text = '${item['property_price'] ?? ''}';
    details.text = '${item['details'] ?? ''}';

    final date = DateTime.tryParse(
      '${item['property_purchase_date'] ?? ''}',
    );

    if (date != null) {
      purchaseDate = date;
      purchaseDateSelected = true;
    }
  }

  @override
  void dispose() {
    // receiverName.dispose();
    companyName.dispose();
    documentNumber.dispose();
    count.dispose();
    propertyName.dispose();
    propertyUnit.dispose();
    propertyLocation.dispose();
    propertyCode.dispose();
    propertyPrice.dispose();
    details.dispose();
    super.dispose();
  }

  String normal(String value) {
    const faDigits = '۰۱۲۳۴۵۶۷۸۹';
    const arDigits = '٠١٢٣٤٥٦٧٨٩';

    for (var i = 0; i < 10; i++) {
      value = value
          .replaceAll(faDigits[i], '$i')
          .replaceAll(arDigits[i], '$i');
    }

    return value.replaceAll(',', '').replaceAll('٬', '').trim();
  }

  String fa(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    return value.replaceAllMapped(
      RegExp(r'[0-9]'),
          (m) => persian[int.parse(m.group(0)!)],
    );
  }
  final List<DropdownMenuItem<String>> propertyUnitItems = const [
    DropdownMenuItem(value: '', child: Text('--- انتخاب کنید ---')),
    DropdownMenuItem(value: 'عدد', child: Text('عدد')),
    DropdownMenuItem(value: 'دستگاه', child: Text('دستگاه')),
    DropdownMenuItem(value: 'تخته', child: Text('تخته')),
    DropdownMenuItem(value: 'کپسول', child: Text('کپسول')),

  ];


  String dateText(DateTime d) {
    final j = Gregorian.fromDateTime(d).toJalali();

    return '${fa('${j.year}')}/'
        '${fa(j.month.toString().padLeft(2, '0'))}/'
        '${fa(j.day.toString().padLeft(2, '0'))}';
  }

  String dateString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  InputDecoration decoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: teal),
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

  void showMessage(String text, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, textDirection: TextDirection.rtl),
        backgroundColor: error ? Colors.red.shade700 : teal,
      ),
    );
  }

  Future<DateTime?> chooseJalaliDate(DateTime current) async {
    final initial = Gregorian.fromDateTime(current).toJalali();
    final now = Gregorian.fromDateTime(DateTime.now()).toJalali();

    final selected = await showDialog<Jalali>(
      context: context,
      builder: (_) => _PropertyJalaliPicker(
        initial: initial,
        first: Jalali(1300, 1, 1),
        last: Jalali(now.year + 20, 12, 29),
      ),
    );

    return selected?.toDateTime();
  }

  Future<void> choosePurchaseDate() async {
    final selected = await chooseJalaliDate(purchaseDate);

    if (selected != null && mounted) {
      setState(() {
        purchaseDate = selected;
        purchaseDateSelected = true;
      });
    }
  }

  Future<void> pickImages() async {
    if (saving) return;

    try {
      final selected = await picker.pickMultiImage(imageQuality: 85);
      if (!mounted || selected.isEmpty) return;

      var limitReached = false;

      setState(() {
        for (final image in selected) {
          if (files.any((f) => f.path == image.path)) continue;

          if (files.length >= 2) {
            limitReached = true;
            break;
          }

          files.add(File(image.path));
        }
      });

      if (limitReached) {
        showMessage(
          'حداکثر دو تصویر جدید قابل پیوست است.',
          error: true,
        );
      }
    } catch (e) {
      showMessage('انتخاب تصویر ناموفق بود: $e', error: true);
    }
  }

  Future<void> save() async {
    if (saving || !formKey.currentState!.validate()) return;

    final priceValue = int.tryParse(normal(propertyPrice.text));
    final countValue = parseInteger(count.text);
    final documentValue = int.tryParse(normal(documentNumber.text));

    if (priceValue == null || priceValue <= 0) {
      showMessage('ارزش اموال باید عدد صحیح و بیشتر از صفر باشد.', error: true);
      return;
    }

    if (countValue == null || countValue <= 0) {
      showMessage('تعداد باید عدد صحیح و بیشتر از صفر باشد.', error: true);
      return;
    }

    if (documentValue == null) {
      showMessage('شماره سند باید عدد صحیح باشد.', error: true);
      return;
    }

    setState(() => saving = true);

    try {
      final params = {
        // 'receiverName': receiverName.text.trim(),
        'companyName': companyName.text.trim(),
        'documentNumber': normal(documentNumber.text),
        'count': normal(count.text),
        'propertyName': propertyName.text.trim(),
        'propertyUnit': propertyUnit.text.trim(),
        'propertyLocation': propertyLocation.text.trim(),
        'propertyCode': propertyCode.text.trim(),
        'propertyPrice': normal(propertyPrice.text),
        'propertyPurchaseDate': purchaseDateSelected
            ? dateString(purchaseDate)
            : '',
        'details': details.text.trim(),
        'filePaths': files.map((f) => f.path).toList(),
      };

      if (editing) {
        await widget.service.updateProperty(
          id: int.parse('${widget.item!['id']}'),
          // receiverName: params['receiverName']!.toString(),
          companyName: params['companyName']!.toString(),
          documentNumber: params['documentNumber']!.toString(),
          count: params['count']!.toString(),
          propertyName: params['propertyName']!.toString(),
          propertyUnit: params['propertyUnit']!.toString(),
          propertyLocation: params['propertyLocation']!.toString(),
          propertyCode: params['propertyCode']!.toString(),
          propertyPrice: params['propertyPrice']!.toString(),
          propertyPurchaseDate:
          params['propertyPurchaseDate']!.toString(),
          details: params['details']!.toString(),
          filePaths: params['filePaths'] as List<String>,
        );
      } else {
        await widget.service.createProperty(
          // receiverName: params['receiverName']!.toString(),
          companyName: params['companyName']!.toString(),
          documentNumber: params['documentNumber']!.toString(),
          count: params['count']!.toString(),
          propertyName: params['propertyName']!.toString(),
          propertyUnit: params['propertyUnit']!.toString(),
          propertyLocation: params['propertyLocation']!.toString(),
          propertyCode: params['propertyCode']!.toString(),
          propertyPrice: params['propertyPrice']!.toString(),
          propertyPurchaseDate:
          params['propertyPurchaseDate']!.toString(),
          details: params['details']!.toString(),
          filePaths: params['filePaths'] as List<String>,
        );
      }


      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget dateField() {
    return InkWell(
      onTap: saving ? null : choosePurchaseDate,
      child: InputDecorator(
        decoration: decoration(
          'تاریخ خرید (اختیاری)',
          Icons.calendar_month,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                purchaseDateSelected
                    ? dateText(purchaseDate)
                    : 'انتخاب تاریخ خرید',
                textDirection: TextDirection.rtl,
              ),
            ),
            if (purchaseDateSelected)
              IconButton(
                tooltip: 'پاک کردن تاریخ',
                onPressed: saving
                    ? null
                    : () => setState(() => purchaseDateSelected = false),
                icon: const Icon(Icons.close, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLength = 400,
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: decoration(label, icon),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final existingDocs = widget.item?['documents'];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * .9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      editing ? 'ویرایش اموال' : 'ثبت اموال جدید',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: formKey,
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    textField(
                      controller: propertyName,
                      label: 'نام اموال *',
                      icon: Icons.home_work_outlined,
                      maxLength: 400,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'نام اموال را وارد کنید.'
                          : null,
                    ),

                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: propertyUnit.text.isEmpty ? '' : propertyUnit.text,
                      isExpanded: true,
                      decoration: decoration(
                        'واحد کالا *',
                        Icons.apartment_outlined,
                      ),
                      items: propertyUnitItems,
                      onChanged: saving
                          ? null
                          : (value) {
                        if (value != null) {
                          setState(() => propertyUnit.text = value);
                        }
                      },
                      validator: (value) =>
                      value == null || value.isEmpty
                          ? 'واحد کالا را انتخاب کنید.'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    textField(
                      controller: count,
                      label: 'تعداد *',
                      icon: Icons.numbers_rounded,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = parseInteger(v ?? '');

                        if (n == null || n <= 0) {
                          return 'تعداد باید عدد صحیح و بیشتر از صفر باشد.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 10),
                    textField(
                      controller: propertyCode,
                      label: 'کد اموال *',
                      icon: Icons.qr_code_rounded,
                      maxLength: 200,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'کد اموال را وارد کنید.'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    textField(
                      controller: propertyPrice,
                      label: 'ارزش اموال به تومان *',
                      icon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(normal(v ?? ''));
                        if (n == null || n <= 0) {
                          return 'ارزش اموال را به‌صورت عدد صحیح وارد کنید.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    textField(
                      controller: documentNumber,
                      label: 'شماره فاکتور *',
                      icon: Icons.description_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (int.tryParse(normal(v ?? '')) == null) {
                          return 'شماره فاکتور باید عدد صحیح باشد.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    // textField(
                    //   controller: receiverName,
                    //   label: 'نام دریافت‌کننده *',
                    //   icon: Icons.person_outline,
                    //   maxLength: 200,
                    //   validator: (v) => v == null || v.trim().isEmpty
                    //       ? 'نام دریافت‌کننده را وارد کنید.'
                    //       : null,
                    // ),
                    // const SizedBox(height: 10),
                    textField(
                      controller: companyName,
                      label: 'نام فروشنده',
                      icon: Icons.business_outlined,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 10),

                    textField(
                      controller: propertyLocation,
                      label: 'آدرس اموال *',
                      icon: Icons.location_on_outlined,
                      maxLength: 400,
                      minLines: 1,
                      maxLines: 3,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'آدرس اموال را وارد کنید.'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    dateField(),
                    const SizedBox(height: 10),
                    textField(
                      controller: details,
                      label: 'توضیحات تکمیلی',
                      icon: Icons.notes,
                      maxLength: 4000,
                      minLines: 2,
                      maxLines: 4,
                    ),
                    if (existingDocs is List && existingDocs.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'مدارک ثبت‌شده',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...existingDocs.map(
                            (doc) => ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.attach_file,
                            color: teal,
                          ),
                          title: Text(
                            doc is Map ? '${doc['url'] ?? 'مدرک'}' : '$doc',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const Text(
                        'مدارک قبلی حذف نمی‌شوند؛ فایل‌های جدید به آن‌ها اضافه خواهند شد.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: saving || files.length >= 2
                            ? null
                            : pickImages,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('افزودن تصویر پیوست'),
                      ),
                    ),
                    Text(
                      'حداکثر دو مدرک جدید قابل پیوست است.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    ...files.asMap().entries.map(
                          (entry) => ListTile(
                        leading: const Icon(
                          Icons.image_outlined,
                          color: teal,
                        ),
                        title: Text(
                          entry.value.path.split(Platform.pathSeparator).last,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          onPressed: saving
                              ? null
                              : () => setState(
                                () => files.removeAt(entry.key),
                          ),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: saving ? null : save,
                        style: FilledButton.styleFrom(
                          backgroundColor: purple,
                        ),
                        icon: saving
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(Icons.save),
                        label: Text(
                          saving
                              ? 'در حال ذخیره...'
                              : editing
                              ? 'ذخیره تغییرات'
                              : 'ثبت اموال',
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

// ------------------------------------------------------------------
// فرم پرداخت اموال
// ------------------------------------------------------------------

class _PropertyPaymentSheet extends StatefulWidget {
  final ManagerPropertyService service;
  final Map<String, dynamic> item;

  const _PropertyPaymentSheet({
    required this.service,
    required this.item,
  });

  @override
  State<_PropertyPaymentSheet> createState() =>
      _PropertyPaymentSheetState();
}

class _PropertyPaymentSheetState extends State<_PropertyPaymentSheet> {
  static const Color teal = Color(0xFF00ACC1);
  static const Color purple = Color(0xFF610DB5);

  final formKey = GlobalKey<FormState>();
  final reference = TextEditingController();

  List<Map<String, dynamic>> banks = [];

  int? bankId;
  DateTime date = DateTime.now();

  bool loading = true;
  bool saving = false;

  String? paymentError;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  @override
  void dispose() {
    reference.dispose();
    super.dispose();
  }

  String normal(String value) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';

    for (var i = 0; i < 10; i++) {
      value = value.replaceAll(fa[i], '$i').replaceAll(ar[i], '$i');
    }

    return value.replaceAll(',', '').replaceAll('٬', '').trim();
  }

  int intValue(dynamic value) =>
      int.tryParse(normal('${value ?? ''}')) ?? 0;

  String fa(String value) {
    const digits = '۰۱۲۳۴۵۶۷۸۹';
    return value.replaceAllMapped(
      RegExp(r'[0-9]'),
          (m) => digits[int.parse(m.group(0)!)],
    );
  }

  String money(dynamic value) {
    final amount = (double.tryParse(normal('$value')) ?? 0)
        .round()
        .toString();

    final formatted = amount.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
    );

    return '${fa(formatted)} تومان';
  }

  String dateText(DateTime d) {
    final j = Gregorian.fromDateTime(d).toJalali();

    return '${fa('${j.year}')}/'
        '${fa(j.month.toString().padLeft(2, '0'))}/'
        '${fa(j.day.toString().padLeft(2, '0'))}';
  }

  String dateString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

  InputDecoration decoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: teal),
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

  String errorText(Object error) =>
      error.toString().replaceFirst('Exception: ', '').trim();

  Future<void> loadInitialData() async {
    try {
      final result = await widget.service.getBanks();

      if (!mounted) return;

      setState(() {
        banks = result;

        if (banks.length == 1) {
          bankId = intValue(banks.first['id']);
        }

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        paymentError = errorText(e);
      });
    }
  }

  Future<void> chooseDate() async {
    final now = Gregorian.fromDateTime(DateTime.now()).toJalali();
    final initial = Gregorian.fromDateTime(date).toJalali();

    final selected = await showDialog<Jalali>(
      context: context,
      builder: (_) => _PropertyJalaliPicker(
        initial: initial,
        first: Jalali(1300, 1, 1),
        last: now,
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        date = selected.toDateTime();
        paymentError = null;
      });
    }
  }

  Future<void> save() async {
    if (saving) return;

    setState(() => paymentError = null);

    if (!formKey.currentState!.validate()) return;

    if (bankId == null) {
      setState(() => paymentError = 'حساب بانکی را انتخاب کنید.');
      return;
    }

    setState(() {
      saving = true;
      paymentError = null;
    });

    try {
      await widget.service.payProperty(
        id: intValue(widget.item['id']),
        bankId: bankId!,
        paymentDate: dateString(date),
        transactionReference: normal(reference.text),
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => paymentError = errorText(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget buildPaymentError() {
    if (paymentError == null || paymentError!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              paymentError!,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: Colors.red.shade800,
                fontSize: 13,
                height: 1.7,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: saving
                ? null
                : () => setState(() => paymentError = null),
            icon: const Icon(Icons.close, size: 18),
          ),
        ],
      ),
    );
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: loading
              ? const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          )
              : SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Text(
                    'ثبت پرداخت اموال',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'مبلغ اموال: ${money(widget.item['property_price'])}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: purple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<int>(
                    value: bankId,
                    isExpanded: true,
                    decoration: decoration(
                      'حساب بانکی مبدأ *',
                      Icons.account_balance,
                    ),
                    items: banks.map((bank) {
                      final name =
                          bank['bank_name'] ?? bank['name'] ?? 'بانک';
                      final account =
                      (bank['account_no'] ?? '').toString();

                      return DropdownMenuItem<int>(
                        value: intValue(bank['id']),
                        child: Text(
                          account.trim().isEmpty
                              ? '$name'
                              : '$name - ${fa(account)}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: saving
                        ? null
                        : (v) {
                      setState(() {
                        bankId = v;
                        paymentError = null;
                      });
                    },
                    validator: (_) => bankId == null
                        ? 'حساب بانکی را انتخاب کنید.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: saving ? null : chooseDate,
                    child: InputDecorator(
                      decoration: decoration(
                        'تاریخ پرداخت *',
                        Icons.calendar_month,
                      ),
                      child: Text(dateText(date)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: reference,
                    enabled: !saving,
                    maxLength: 20,
                    decoration: decoration(
                      'شماره پیگیری (اختیاری)',
                      Icons.confirmation_number_outlined,
                    ),
                  ),
                  const SizedBox(height: 8),
                  buildPaymentError(),
                  SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: saving ? null : save,
                      style: FilledButton.styleFrom(
                        backgroundColor: purple,
                      ),
                      icon: saving
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
                        saving ? 'در حال ثبت...' : 'تأیید پرداخت',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// انتخابگر تاریخ شمسی
// ------------------------------------------------------------------

class _PropertyJalaliPicker extends StatefulWidget {
  final Jalali initial;
  final Jalali first;
  final Jalali last;

  const _PropertyJalaliPicker({
    required this.initial,
    required this.first,
    required this.last,
  });

  @override
  State<_PropertyJalaliPicker> createState() =>
      _PropertyJalaliPickerState();
}

class _PropertyJalaliPickerState extends State<_PropertyJalaliPicker> {
  static const Color teal = Color(0xFF00ACC1);
  static const Color purple = Color(0xFF610DB5);

  late Jalali selected;
  late Jalali month;

  @override
  void initState() {
    super.initState();
    selected = widget.initial;
    month = Jalali(widget.initial.year, widget.initial.month, 1);
  }

  String fa(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    for (var i = 0; i < english.length; i++) {
      value = value.replaceAll(english[i], persian[i]);
    }

    return value;
  }

  bool sameDay(Jalali a, Jalali b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool allowed(Jalali date) =>
      date.compareTo(widget.first) >= 0 &&
          date.compareTo(widget.last) <= 0;

  void changeMonth(int delta) {
    final next = month.addMonths(delta);

    if (next.year < widget.first.year || next.year > widget.last.year) {
      return;
    }

    setState(() => month = next);
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = month.weekDay;
    final days = month.monthLength;

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
                    onPressed: () => changeMonth(-1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  Expanded(
                    child: Text(
                      '${month.formatter.mN} ${fa('${month.year}')}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => changeMonth(1),
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
                  final date = Jalali(month.year, month.month, day);
                  final isSelected = sameDay(date, selected);
                  final isAllowed = allowed(date);

                  return InkWell(
                    onTap: isAllowed
                        ? () => setState(() => selected = date)
                        : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? purple : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        fa('$day'),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isAllowed
                              ? Colors.black87
                              : Colors.black26,
                          fontWeight: isSelected
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
                    style: FilledButton.styleFrom(backgroundColor: teal),
                    onPressed: () => Navigator.pop(context, selected),
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