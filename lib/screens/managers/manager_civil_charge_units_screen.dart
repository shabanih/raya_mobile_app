
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_civil_charge_service.dart';

class ManagerCivilChargeUnitsScreen extends StatefulWidget {
  final int chargeId;
  final String chargeName;

  const ManagerCivilChargeUnitsScreen({
    super.key,
    required this.chargeId,
    required this.chargeName,
  });

  @override
  State<ManagerCivilChargeUnitsScreen> createState() =>
      _ManagerCivilChargeUnitsScreenState();
}

class _ManagerCivilChargeUnitsScreenState
    extends State<ManagerCivilChargeUnitsScreen> {
  static const Color teal = Color(0xFF00ACC1);
  static const Color purple = Color(0xFF610DB5);
  static const Color sentColor = Color(0xFFEF8C22);
  static const Color paidColor = Color(0xFF2E7D32);

  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic> _charge = {};
  List<Map<String, dynamic>> _units = [];
  final Set<int> _selectedIds = {};

  bool _loading = true;
  bool _processing = false;
  String _search = '';
  String _filter = 'all';

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

  // --------------------------------------------------
  // تبدیل اعداد برای نمایش فارسی
  // --------------------------------------------------

  String _toPersianDigits(dynamic value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    return (value ?? '').toString().replaceAllMapped(
      RegExp(r'[0-9]'),
          (match) => persian[english.indexOf(match.group(0)!)],
    );
  }

  // تبدیل اعداد فارسی و عربی به انگلیسی برای پردازش
  String _normalizeDigits(dynamic value) {
    return (value ?? '')
        .toString()
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
  }

  // --------------------------------------------------
  // دریافت اطلاعات
  // --------------------------------------------------

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final unitsResponse =
      await ManagerCivilChargeService.getChargeUnitsData(
        widget.chargeId,
      );

      final chargeResponse =
      await ManagerCivilChargeService.getCharge(
        widget.chargeId,
      );

      if (chargeResponse == null) {
        throw Exception('اطلاعات شارژ عمرانی پیدا نشد.');
      }

      final units = _extractUnits(unitsResponse);

      if (!mounted) return;

      setState(() {
        _charge = Map<String, dynamic>.from(chargeResponse);
        _units = units;

        final existingIds = units.map(_unitId).toSet();
        _selectedIds.removeWhere(
              (id) => !existingIds.contains(id),
        );

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _message('دریافت اطلاعات ناموفق بود: $e');
    }
  }

  List<Map<String, dynamic>> _extractUnits(dynamic response) {
    if (response is List) {
      return response
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (response is Map) {
      for (final key in ['results', 'units', 'data', 'items']) {
        final value = response[key];

        if (value is List) {
          return value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    }

    return [];
  }

  // --------------------------------------------------
  // توابع تبدیل داده
  // --------------------------------------------------

  dynamic _value(
      Map<String, dynamic> data,
      List<String> keys,
      ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  int _int(dynamic value) {
    final text = _normalizeDigits(value)
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .trim();

    return int.tryParse(text) ??
        double.tryParse(text)?.toInt() ??
        0;
  }

  double _double(dynamic value) {
    final text = _normalizeDigits(value)
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('٫', '.')
        .trim();

    return double.tryParse(text) ?? 0;
  }

  String _money(dynamic value) {
    final text = _double(value).round().toString();
    final result = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      result.write(text[i]);

      final remaining = text.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        result.write(',');
      }
    }

    return _toPersianDigits(result.toString());
  }

  String _date(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'ثبت نشده';
    }

    final raw = _normalizeDigits(value).trim();
    final match = RegExp(
      r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})',
    ).firstMatch(raw);

    if (match != null) {
      final year = int.tryParse(match.group(1)!) ?? 0;
      final month = int.tryParse(match.group(2)!) ?? 0;
      final day = int.tryParse(match.group(3)!) ?? 0;

      if (year >= 1200 && year <= 1600) {
        return _toPersianDigits(
          '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}',
        );
      }
    }

    try {
      final jalali = Jalali.fromDateTime(DateTime.parse(raw));

      return _toPersianDigits(
        '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}',
      );
    } catch (_) {
      return _toPersianDigits(value);
    }
  }

  // --------------------------------------------------
  // اطلاعات شارژ
  // --------------------------------------------------

  dynamic get _chargeAmount => _value(
    _charge,
    ['amount', 'total_amount', 'civil_amount', 'charge_amount'],
  );

  dynamic get _prepayment =>
      _value(_charge, ['prepayment', 'prepayment_amount']);

  int get _installmentCount =>
      _int(_value(_charge, ['installment_count']));

  dynamic get _firstDueDate =>
      _value(_charge, ['first_due_date', 'due_date']);

  bool get _hasInstallments =>
      _double(_prepayment) > 0 || _installmentCount > 0;

  // --------------------------------------------------
  // اطلاعات واحد و ساکن
  // --------------------------------------------------

  int _unitId(Map<String, dynamic> unit) =>
      _int(_value(unit, ['id', 'unit_id']));

  String _unitNumber(Map<String, dynamic> unit) {
    final value = _value(unit, ['unit_number', 'unit_name', 'unit']);

    if (value is Map) {
      return (value['unit_number'] ??
          value['name'] ??
          value['number'] ??
          value['id'] ??
          'واحد')
          .toString();
    }

    return value?.toString() ?? 'واحد ${_unitId(unit)}';
  }

  String _residentType(Map<String, dynamic> unit) {
    final value = (_value(
      unit,
      ['resident_type', 'residence_type', 'occupant_type'],
    ) ??
        '')
        .toString()
        .toLowerCase()
        .trim();

    if (['owner', 'مالک', 'owner_resident'].contains(value)) {
      return 'owner';
    }

    if (['renter', 'tenant', 'مستاجر', 'مستأجر'].contains(value)) {
      return 'renter';
    }

    if (unit['is_renter'] == true) return 'renter';

    final name = _value(
      unit,
      ['resident_name', 'owner_name', 'renter_name', 'full_name'],
    );

    if (name != null) return 'owner';

    return 'empty';
  }

  String _residentName(Map<String, dynamic> unit) {
    final type = _residentType(unit);

    final residentName = _value(
      unit,
      ['resident_name', 'resident_full_name'],
    );

    if (residentName != null) {
      return residentName.toString().trim();
    }

    if (type == 'owner') {
      return (_value(
        unit,
        ['owner_name', 'owner_full_name', 'full_name'],
      ) ??
          'نام مالک ثبت نشده')
          .toString();
    }

    if (type == 'renter') {
      return (_value(
        unit,
        ['renter_name', 'tenant_name', 'full_name'],
      ) ??
          'نام مستأجر ثبت نشده')
          .toString();
    }

    return 'بدون ساکن';
  }

  int _peopleCount(Map<String, dynamic> unit) {
    return _int(
      _value(unit, [
        'people_count',
        'resident_count',
        'renter_people_count',
        'owner_people_count',
      ]),
    );
  }

  double _unitAmount(Map<String, dynamic> unit) {
    return _double(
      _value(
        unit,
        ['charge_amount', 'amount', 'civil_amount', 'total_amount'],
      ) ??
          _chargeAmount,
    );
  }

  double _unitPrepayment(Map<String, dynamic> unit) {
    return _double(
      _value(unit, ['prepayment_amount', 'prepayment']) ?? _prepayment,
    );
  }

  int _unitInstallments(Map<String, dynamic> unit) {
    return _int(
      _value(unit, ['installment_count']) ?? _installmentCount,
    );
  }

  double _unitInstallmentAmount(Map<String, dynamic> unit) {
    final explicit = _value(
      unit,
      ['installment_amount', 'per_installment_amount'],
    );

    if (explicit != null) return _double(explicit);

    final count = _unitInstallments(unit);
    if (count <= 0) return 0;

    final remaining = _unitAmount(unit) - _unitPrepayment(unit);
    return remaining > 0 ? remaining / count : 0;
  }

  bool _isSent(Map<String, dynamic> unit) =>
      unit['sent'] == true;

  bool _hasPaid(Map<String, dynamic> unit) =>
      unit['has_paid_installment'] == true;

  // --------------------------------------------------
  // فیلتر و انتخاب واحدها
  // --------------------------------------------------

  List<Map<String, dynamic>> get _filteredUnits {
    final query = _normalizeDigits(_search).toLowerCase().trim();

    return _units.where((unit) {
      final number =
      _normalizeDigits(_unitNumber(unit)).toLowerCase();
      final resident = _residentName(unit).toLowerCase();

      final matchesSearch = query.isEmpty ||
          number.contains(query) ||
          resident.contains(_search.trim().toLowerCase());

      final type = _residentType(unit);

      final matchesFilter = _filter == 'all' ||
          (_filter == 'owner' && type == 'owner') ||
          (_filter == 'renter' && type == 'renter') ||
          (_filter == 'empty' && type == 'empty');

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void _toggleUnit(Map<String, dynamic> unit, bool selected) {
    final id = _unitId(unit);
    if (id <= 0) return;

    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _toggleVisibleUnits() {
    setState(() {
      final visibleIds = _filteredUnits
          .map(_unitId)
          .where((id) => id > 0)
          .toSet();

      final allSelected = visibleIds.isNotEmpty &&
          visibleIds.every(_selectedIds.contains);

      if (allSelected) {
        _selectedIds.removeAll(visibleIds);
      } else {
        _selectedIds.addAll(visibleIds);
      }
    });
  }

  // --------------------------------------------------
  // ارسال اعلان
  // --------------------------------------------------

  Future<void> _sendCharge() async {
    if (_processing) return;

    if (_selectedIds.isEmpty) {
      _message('ابتدا واحدهای موردنظر را انتخاب کنید.');
      return;
    }

    final confirmed = await _confirm(
      title: 'ارسال اعلان شارژ',
      message:
      'اعلان شارژ برای ${_toPersianDigits(_selectedIds.length)} واحد ارسال شود؟',
      confirmText: 'ارسال',
      color: teal,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processing = true);

    try {
      final response =
      await ManagerCivilChargeService.sendChargeToUnits(
        civilId: widget.chargeId,
        unitIds: _selectedIds.toList(),
      );

      if (!mounted) return;

      if (response is Map && response['success'] == false) {
        _message(
          (response['message'] ?? 'ارسال شارژ انجام نشد.').toString(),
        );
      } else {
        _selectedIds.clear();
        _message('درخواست ارسال شارژ انجام شد.');
      }

      await _loadData();
    } catch (e) {
      if (mounted) _message('خطا در ارسال شارژ: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  // --------------------------------------------------
  // لغو اعلان
  // --------------------------------------------------

  Future<void> _cancelCharge() async {
    if (_processing) return;

    if (_selectedIds.isEmpty) {
      _message('برای لغو اعلان، ابتدا واحدها را انتخاب کنید.');
      return;
    }

    final confirmed = await _confirm(
      title: 'لغو اعلان شارژ',
      message:
      'اعلان شارژ برای ${_toPersianDigits(_selectedIds.length)} واحد انتخاب‌شده لغو شود؟ واحد دارای قسط پرداخت‌شده از لغو مستثنا می‌شود.',
      confirmText: 'لغو اعلان',
      color: Colors.red,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processing = true);

    try {
      final response =
      await ManagerCivilChargeService.cancelChargeForUnits(
        civilId: widget.chargeId,
        unitIds: _selectedIds.toList(),
      );

      if (!mounted) return;

      if (response is Map && response['success'] == false) {
        _message(
          (response['message'] ?? 'لغو اعلان انجام نشد.').toString(),
        );
      } else if (response is Map) {
        final cancelled = _int(response['cancelled_units_count']);
        final skippedPaid = _int(response['skipped_paid_units_count']);

        _message(
          'اعلان لغوشده برای ${_toPersianDigits(cancelled)} واحد؛ '
              '${_toPersianDigits(skippedPaid)} واحد به علت پرداخت قسط مستثنا شد.',
        );
        _selectedIds.clear();
      } else {
        _message('درخواست لغو اعلان انجام شد.');
        _selectedIds.clear();
      }

      await _loadData();
    } catch (e) {
      if (mounted) _message('خطا در لغو اعلان: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmText,
    required Color color,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(title, textAlign: TextAlign.right),
          content: Text(message, textAlign: TextAlign.right),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: color),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmText),
            ),
          ],
        ),
      ),
    );
  }

  void _message(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _toPersianDigits(text),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // --------------------------------------------------
  // رابط کاربری
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text(
            'ارسال شارژ عمرانی ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: teal,
          foregroundColor: Colors.white,
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _loading ? null : _loadData,
              icon: const Icon(Icons.refresh),
              tooltip: 'بارگذاری مجدد',
            ),
          ],
        ),
        body: _loading
            ? const Center(
          child: CircularProgressIndicator(color: teal),
        )
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _buildHeader(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: _buildSearch(),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildFilters(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildSelectAll(),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: _filteredUnits.isEmpty
                    ? ListView(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(30),
                  children: const [
                    SizedBox(height: 35),
                    Center(
                      child: Text(
                        'واحدی برای نمایش پیدا نشد.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                )
                    : ListView.builder(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    12,
                  ),
                  itemCount: _filteredUnits.length,
                  itemBuilder: (context, index) =>
                      _buildUnitCard(_filteredUnits[index]),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: _buildActions(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // هدر شارژ
  // --------------------------------------------------

  Widget _buildHeader() {
    final name = (_value(_charge, ['name', 'title']) ??
        widget.chargeName)
        .toString();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFFE0F7FA), Colors.white],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: teal,
                  size: 32,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _toPersianDigits(name),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow(
              'مبلغ شارژ',
              '${_money(_chargeAmount)} تومان',
              purple,
            ),
            const SizedBox(height: 9),
            _infoRow('اولین سررسید', _date(_firstDueDate)),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // ردیف اطلاعات راست‌چین
  // --------------------------------------------------

  Widget _infoRow(
      String label,
      String value, [
        Color color = Colors.black87,
      ]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            _toPersianDigits(label),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            _toPersianDigits(value),
            textAlign: TextAlign.left,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------
  // جستجو
  // --------------------------------------------------

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      onChanged: (value) => setState(() => _search = value),
      decoration: InputDecoration(
        hintText: 'جستجوی شماره واحد یا نام ساکن...',
        hintTextDirection: TextDirection.rtl,
        prefixIcon: const Icon(Icons.search, color: teal),
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
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // فیلترها
  // --------------------------------------------------

  Widget _buildFilters() {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _filterChip('همه', 'all'),
            _filterChip('مالک', 'owner'),
            _filterChip('مستأجر', 'renter'),
            _filterChip('واحد خالی', 'empty'),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String title, String value) {
    final selected = _filter == value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: ChoiceChip(
        label: Text(title),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: teal.withValues(alpha: 0.16),
        checkmarkColor: teal,
      ),
    );
  }

  // --------------------------------------------------
  // انتخاب همه
  // --------------------------------------------------

  Widget _buildSelectAll() {
    final visibleIds = _filteredUnits
        .map(_unitId)
        .where((id) => id > 0)
        .toSet();

    final allSelected = visibleIds.isNotEmpty &&
        visibleIds.every(_selectedIds.contains);

    return Row(
      children: [
        Checkbox(
          value: allSelected,
          activeColor: teal,
          onChanged: visibleIds.isEmpty
              ? null
              : (_) => _toggleVisibleUnits(),
        ),
        const Expanded(
          child: Text(
            'انتخاب همه واحدهای نمایش‌داده‌شده',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text('${_toPersianDigits(_filteredUnits.length)} واحد'),
      ],
    );
  }

  // --------------------------------------------------
  // کارت فشرده واحد
  // --------------------------------------------------

  Widget _buildUnitCard(Map<String, dynamic> unit) {
    final selected = _selectedIds.contains(_unitId(unit));
    final sent = _isSent(unit);
    final paid = _hasPaid(unit);
    final type = _residentType(unit);

    final Color cardColor = paid
        ? const Color(0xFFE8F5E9)
        : sent
        ? const Color(0xFFFFF8E8)
        : selected
        ? const Color(0xFFF0FBFC)
        : Colors.white;

    final Color borderColor = paid
        ? const Color(0xFF81C784)
        : sent
        ? const Color(0xFFFFCC80)
        : selected
        ? teal
        : Colors.black12;

    final residentLabel = type == 'owner'
        ? 'مالک'
        : type == 'renter'
        ? 'مستأجر'
        : 'خالی';

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0.5,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _toggleUnit(unit, !selected),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 16,
          ),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                activeColor: teal,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize:
                MaterialTapTargetSize.shrinkWrap,
                onChanged: (value) =>
                    _toggleUnit(unit, value ?? false),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.door_front_door_outlined,
                  color: purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 7,
                  runSpacing: 3,
                  children: [
                    Text(
                      _toPersianDigits(_unitNumber(unit)),
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '$residentLabel: ${_residentName(unit)}',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (paid)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.check_circle,
                    color: paidColor,
                    size: 22,
                  ),
                )
              else if (sent)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: sentColor,
                    size: 22,
                  ),
                ),
              IconButton(
                tooltip: 'جزئیات واحد',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(
                  minWidth: 34,
                  minHeight: 34,
                ),
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.visibility_outlined,
                  color: purple,
                  size: 21,
                ),
                onPressed: () => _showUnitDetails(unit),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // جزئیات راست‌چین واحد
  // --------------------------------------------------

  void _showUnitDetails(Map<String, dynamic> unit) {
    final type = _residentType(unit);
    final paid = _hasPaid(unit);
    final sent = _isSent(unit);
    final peopleCount = _peopleCount(unit);

    final showInstallments =
        _unitInstallments(unit) > 0 ||
            _unitPrepayment(unit) > 0;

    final residentLabel = type == 'owner'
        ? 'مالک'
        : type == 'renter'
        ? 'مستأجر'
        : 'خالی';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.door_front_door_outlined,
                  color: purple,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'جزئیات ${_toPersianDigits(_unitNumber(unit))}',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _infoRow(
                    'ساکن',
                    '$residentLabel: ${_residentName(unit)}',
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    'تعداد ساکنان',
                    '${_toPersianDigits(peopleCount)} نفر',
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    'مبلغ شارژ واحد',
                    '${_money(_unitAmount(unit))} تومان',
                    purple,
                  ),
                  if (showInstallments) ...[
                    const SizedBox(height: 10),
                    _infoRow(
                      'پیش‌پرداخت',
                      '${_money(_unitPrepayment(unit))} تومان',
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      'تعداد اقساط',
                      '${_toPersianDigits(_unitInstallments(unit))} قسط',
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      'مبلغ هر قسط',
                      '${_money(_unitInstallmentAmount(unit))} تومان',
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        paid
                            ? Icons.check_circle
                            : sent
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_none,
                        color: paid
                            ? paidColor
                            : sent
                            ? sentColor
                            : Colors.blueGrey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          paid
                              ? 'دارای قسط پرداخت‌شده'
                              : sent
                              ? 'اعلان ارسال شده است'
                              : 'اعلانی ارسال نشده است',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
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
        );
      },
    );
  }

  // --------------------------------------------------
  // دکمه‌های پایین
  // --------------------------------------------------

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _processing ? null : _cancelCharge,
            icon: const Icon(Icons.notifications_off_outlined),
            label: const Text(
              'لغو اعلان',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: _processing ? null : _sendCharge,
            icon: _processing
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Icon(Icons.send),
            label: Text(
              _processing ? 'در حال انجام...' : 'ارسال شارژ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
