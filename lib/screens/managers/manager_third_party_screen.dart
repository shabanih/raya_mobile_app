
import 'package:flutter/material.dart';

import '../../services/manager_third_party_service.dart';

class ManagerThirdPartyScreen extends StatefulWidget {
  const ManagerThirdPartyScreen({super.key});

  @override
  State<ManagerThirdPartyScreen> createState() =>
      _ManagerThirdPartyScreenState();
}

class _ManagerThirdPartyScreenState
    extends State<ManagerThirdPartyScreen> {

  static const Color teal = Color(0xFF00ACC1);
  static const Color purple = Color(0xFF610DB5);
  static const Color background = Color(0xFFF6F7FB);

  final service = ManagerThirdPartyService.instance;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> items = [];

  bool loading = true;
  String search = '';

  String personFilter = 'all';
  String statusFilter = 'all';

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

  // ---------------------------------------------------------
  // ابزارهای عمومی
  // ---------------------------------------------------------

  String cleanError(Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  String normalize(String value) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';

    for (var i = 0; i < 10; i++) {
      value = value
          .replaceAll(fa[i], '$i')
          .replaceAll(ar[i], '$i');
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

  bool isActive(Map<String, dynamic> item) {
    final value = item['is_active'];

    return value == true || value == 1 || value == 'true';
  }

  String personTypeText(dynamic value) {
    switch (value?.toString()) {
      case 'person':
        return 'شخص حقیقی';
      case 'company':
        return 'شرکت یا کسب‌وکار';
      default:
        return 'نامشخص';
    }
  }

  void message(String text, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            text,
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: error ? Colors.red.shade700 : teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ---------------------------------------------------------
  // دریافت اطلاعات
  // ---------------------------------------------------------

  Future<void> loadData() async {
    setState(() => loading = true);

    try {
      final result = await service.getThirdParties();

      if (!mounted) return;

      setState(() => items = result);
    } catch (e) {
      message(cleanError(e), error: true);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  // ---------------------------------------------------------
  // فیلتر و جستجو
  // ---------------------------------------------------------

  List<Map<String, dynamic>> get filtered {
    final query = normalize(search).toLowerCase();

    return items.where((item) {
      final type = item['person_type']?.toString() ?? '';

      if (personFilter != 'all' && type != personFilter) {
        return false;
      }

      final active = isActive(item);

      if (statusFilter == 'active' && !active) {
        return false;
      }

      if (statusFilter == 'inactive' && active) {
        return false;
      }

      if (query.isEmpty) return true;

      final text = [
        item['name'],
        item['mobile'],
        item['description'],
        personTypeText(type),
      ].whereType<Object>().join(' ');

      return normalize(text).toLowerCase().contains(query);
    }).toList();
  }

  int get totalCount => items.length;

  int get activeCount =>
      items.where((item) => isActive(item)).length;

  int get inactiveCount => totalCount - activeCount;

  int get personCount => items
      .where((item) => item['person_type'] == 'person')
      .length;

  int get companyCount => items
      .where((item) => item['person_type'] == 'company')
      .length;

  // ---------------------------------------------------------
  // باز کردن فرم ثبت و ویرایش
  // ---------------------------------------------------------

  Future<void> openForm({
    Map<String, dynamic>? item,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ThirdPartyFormSheet(
        service: service,
        item: item,
      ),
    );

    if (result == true && mounted) {
      await loadData();

      message(
        item == null
            ? 'طرف حساب با موفقیت ثبت شد.'
            : 'اطلاعات طرف حساب ویرایش شد.',
      );
    }
  }

  // ---------------------------------------------------------
  // حذف طرف حساب
  // ---------------------------------------------------------

  Future<void> delete(Map<String, dynamic> item) async {
    final id = intValue(item['id']);

    final name = item['name']?.toString() ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف طرف حساب'),
          content: Text(
            'آیا از حذف "$name" مطمئن هستید؟',
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
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await service.deleteThirdParty(id);

      if (!mounted) return;

      await loadData();

      message('طرف حساب حذف شد.');
    } catch (e) {
      message(cleanError(e), error: true);
    }
  }

  // ---------------------------------------------------------
  // نمایش جزئیات
  // ---------------------------------------------------------

  void showDetails(Map<String, dynamic> item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('جزئیات طرف حساب'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                detail('نام', item['name']),
                detail(
                  'نوع طرف حساب',
                  personTypeText(item['person_type']),
                ),
                detail(
                  'شماره موبایل',
                  fa('${item['mobile'] ?? '—'}'),
                ),
                detail(
                  'وضعیت',
                  isActive(item) ? 'فعال' : 'غیرفعال',
                ),
                detail(
                  'توضیحات',
                  item['description'],
                ),
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
    final text = value == null ||
        value.toString().trim().isEmpty
        ? '—'
        : value.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        '$label: $text',
        style: const TextStyle(height: 1.8),
      ),
    );
  }

  // ---------------------------------------------------------
  // ابزارهای نمایشی
  // ---------------------------------------------------------

  Widget info(
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
          style: TextStyle(
            fontSize: 11,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget filterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: personFilter == value,
      selectedColor: teal.withValues(alpha: .15),
      checkmarkColor: teal,
      onSelected: (_) {
        setState(() => personFilter = value);
      },
    );
  }

  Widget statusChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: statusFilter == value,
      selectedColor: purple.withValues(alpha: .12),
      checkmarkColor: purple,
      onSelected: (_) {
        setState(() => statusFilter = value);
      },
    );
  }

  // ---------------------------------------------------------
  // کارت طرف حساب
  // ---------------------------------------------------------

  Widget thirdPartyCard(Map<String, dynamic> item) {
    final active = isActive(item);

    final name = (item['name'] ?? '').toString();

    final type = item['person_type']?.toString() ?? '';

    final mobile = (item['mobile'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEDEDF3),
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
                    color: type == 'company'
                        ? purple.withValues(alpha: .10)
                        : teal.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    type == 'company'
                        ? Icons.business_outlined
                        : Icons.person_outline_rounded,
                    color: type == 'company' ? purple : teal,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.green.withValues(alpha: .10)
                        : Colors.red.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    active ? 'فعال' : 'غیرفعال',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: active ? Colors.green.shade700 : Colors.red,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            Wrap(
              spacing: 15,
              runSpacing: 10,
              children: [
                info(
                  type == 'company'
                      ? Icons.business_outlined
                      : Icons.person_outline,
                  personTypeText(type),
                  color: type == 'company' ? purple : teal,
                ),
                if (mobile.isNotEmpty)
                  info(
                    Icons.phone_android_outlined,
                    fa(mobile),
                  ),
                info(
                  active
                      ? Icons.check_circle_outline
                      : Icons.block_outlined,
                  active ? 'قابل انتخاب در فرم‌ها' : 'غیرفعال در فرم‌ها',
                  color: active ? Colors.green : Colors.red,
                ),
              ],
            ),

            if ((item['description'] ?? '')
                .toString()
                .trim()
                .isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                item['description'].toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  height: 1.8,
                ),
              ),
            ],

            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'جزئیات',
                  onPressed: () => showDetails(item),
                  icon: const Icon(
                    Icons.visibility_outlined,
                    color: teal,
                  ),
                ),
                IconButton(
                  tooltip: 'ویرایش',
                  onPressed: () => openForm(item: item),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: purple,
                  ),
                ),
                IconButton(
                  tooltip: 'حذف',
                  onPressed: () => delete(item),
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

  // ---------------------------------------------------------
  // صفحه اصلی
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final data = filtered;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: background,

        appBar: AppBar(
          title: const Text(
            'مدیریت اشخاص ثالث',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
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
          label: const Text('ثبت طرف حساب'),
        ),

        body: RefreshIndicator(
          onRefresh: loadData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [

              // -------------------------------------------------
              // کارت آمار
              // -------------------------------------------------

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          teal,
                          Color(0xFF00838F),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'تعداد کل اشخاص ثالث',
                                style: TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                fa(totalCount.toString()),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 25,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // -------------------------------------------------
              // جستجو
              // -------------------------------------------------

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: searchController,
                    onChanged: (v) {
                      setState(() => search = v);
                    },
                    decoration: InputDecoration(
                      hintText: 'جست‌وجوی نام، شماره موبایل یا توضیحات...',
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

              // -------------------------------------------------
              // فیلتر نوع
              // -------------------------------------------------

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'نوع طرف حساب',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      filterChip('همه', 'all'),
                      filterChip('اشخاص حقیقی', 'person'),
                      filterChip('شرکت‌ها', 'company'),
                    ],
                  ),
                ),
              ),

              // -------------------------------------------------
              // فیلتر وضعیت
              // -------------------------------------------------

              // const SliverToBoxAdapter(
              //   child: Padding(
              //     padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              //     child: Align(
              //       alignment: Alignment.centerRight,
              //       child: Text(
              //         'وضعیت',
              //         style: TextStyle(
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
              //
              // SliverToBoxAdapter(
              //   child: Padding(
              //     padding: const EdgeInsets.all(16),
              //     child: Wrap(
              //       spacing: 8,
              //       children: [
              //         statusChip('همه', 'all'),
              //         statusChip('فعال', 'active'),
              //         statusChip('غیرفعال', 'inactive'),
              //       ],
              //     ),
              //   ),
              // ),

              // -------------------------------------------------
              // لیست
              // -------------------------------------------------

              if (loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
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
                            Icons.groups_outlined,
                            size: 64,
                            color: teal,
                          ),
                          SizedBox(height: 14),
                          Text(
                            'طرف حسابی پیدا نشد',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'می‌توانید طرف حساب جدیدی ثبت کنید یا فیلترها را تغییر دهید.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )

              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    16, 4, 16, 100,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (_, index) => thirdPartyCard(data[index]),
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

  Widget _stat(
      String label,
      int value,
      IconData icon,
      ) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fa(value.toString()),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// فرم ثبت و ویرایش شخص ثالث
// ==================================================================

class _ThirdPartyFormSheet extends StatefulWidget {
  final ManagerThirdPartyService service;
  final Map<String, dynamic>? item;

  const _ThirdPartyFormSheet({
    required this.service,
    this.item,
  });

  @override
  State<_ThirdPartyFormSheet> createState() =>
      _ThirdPartyFormSheetState();
}

class _ThirdPartyFormSheetState
    extends State<_ThirdPartyFormSheet> {

  static const Color teal = Color(0xFF00ACC1);
  static const Color purple = Color(0xFF610DB5);

  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final descriptionController = TextEditingController();

  String personType = 'person';
  bool active = true;
  bool saving = false;

  bool get editing => widget.item != null;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    if (item != null) {
      nameController.text = '${item['name'] ?? ''}';
      mobileController.text = '${item['mobile'] ?? ''}';
      descriptionController.text =
      '${item['description'] ?? ''}';

      personType =
      item['person_type'] == 'company' ? 'company' : 'person';

      active = item['is_active'] == true ||
          item['is_active'] == 1 ||
          item['is_active'] == 'true';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    mobileController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String normalize(String value) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';

    for (var i = 0; i < 10; i++) {
      value = value
          .replaceAll(fa[i], '$i')
          .replaceAll(ar[i], '$i');
    }

    return value.trim();
  }

  InputDecoration decoration(
      String label,
      IconData icon,
      ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: teal),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE4E7EC),
        ),
      ),
    );
  }

  void showMessage(String text, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: error ? Colors.red.shade700 : teal,
      ),
    );
  }

  // ---------------------------------------------------------
  // ذخیره اطلاعات
  // ---------------------------------------------------------

  Future<void> save() async {
    if (saving) return;

    if (!formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      final name = nameController.text.trim();
      final mobile = normalize(mobileController.text);

      final description = descriptionController.text.trim();

      if (editing) {
        await widget.service.updateThirdParty(
          id: int.parse('${widget.item!['id']}'),
          name: name,
          personType: personType,
          mobile: mobile,
          description: description,
          isActive: active,
        );
      } else {
        await widget.service.createThirdParty(
          name: name,
          personType: personType,
          mobile: mobile,
          description: description,
          isActive: active,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  // ---------------------------------------------------------
  // فیلد متنی
  // ---------------------------------------------------------

  Widget textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLength = 500,
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !saving,
      maxLength: maxLength,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      decoration: decoration(label, icon),
      validator: validator,
    );
  }

  // ---------------------------------------------------------
  // رابط کاربری فرم
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * .85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [

            // عنوان فرم

            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      editing
                          ? 'ویرایش طرف حساب'
                          : 'ثبت طرف حساب جدید',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: saving
                        ? null
                        : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // محتوای فرم

            Expanded(
              child: Form(
                key: formKey,
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [

                    // نوع شخص

                    const Text(
                      'نوع طرف حساب',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _typeOption(
                            value: 'person',
                            title: 'شخص حقیقی',
                            icon: Icons.person_outline,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _typeOption(
                            value: 'company',
                            title: 'شرکت یا کسب‌وکار',
                            icon: Icons.business_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // نام

                    textField(
                      controller: nameController,
                      label: personType == 'person'
                          ? 'نام و نام خانوادگی *'
                          : 'نام شرکت یا کسب‌وکار *',
                      icon: personType == 'person'
                          ? Icons.person_outline
                          : Icons.business_outlined,
                      maxLength: 200,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'نام طرف حساب را وارد کنید.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // موبایل

                    textField(
                      controller: mobileController,
                      label: 'شماره موبایل',
                      icon: Icons.phone_android_outlined,
                      maxLength: 20,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 12),

                    // توضیحات

                    textField(
                      controller: descriptionController,
                      label: 'توضیحات',
                      icon: Icons.notes_outlined,
                      maxLength: 500,
                      minLines: 3,
                      maxLines: 5,
                    ),

                    const SizedBox(height: 12),

                    // وضعیت فعال بودن

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE4E7EC),
                        ),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: teal,
                        title: const Text(
                          'طرف حساب فعال باشد',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          active
                              ? 'در فرم‌های مالی قابل انتخاب است.'
                              : 'در فرم‌های مالی قابل انتخاب نیست.',
                          style: const TextStyle(fontSize: 11),
                        ),
                        value: active,
                        onChanged: saving
                            ? null
                            : (value) {
                          setState(() => active = value);
                        },
                      ),
                    ),

                    const SizedBox(height: 25),

                    // دکمه ذخیره

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
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          saving
                              ? 'در حال ذخیره...'
                              : editing
                              ? 'ذخیره تغییرات'
                              : 'ثبت طرف حساب',
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

  // ---------------------------------------------------------
  // انتخاب نوع طرف حساب
  // ---------------------------------------------------------

  Widget _typeOption({
    required String value,
    required String title,
    required IconData icon,
  }) {
    final selected = personType == value;

    return InkWell(
      onTap: saving
          ? null
          : () {
        setState(() => personType = value);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? teal.withValues(alpha: .09)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? teal : const Color(0xFFE4E7EC),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? teal : Colors.black54,
              size: 27,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: selected ? teal : Colors.black87,
              ),
            ),
            const SizedBox(height: 5),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: teal,
                size: 17,
              )
            else
              const SizedBox(height: 17),
          ],
        ),
      ),
    );
  }
}
