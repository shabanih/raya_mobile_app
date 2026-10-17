
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_fix_person_area_charge_service.dart';

class ManagerFixPersonAreaChargeUnitsScreen extends StatefulWidget {
  final Map<String, dynamic> charge;
  final ManagerFixPersonAreaChargeService service;

  const ManagerFixPersonAreaChargeUnitsScreen({
    super.key,
    required this.charge,
    required this.service,
  });

  @override
  State<ManagerFixPersonAreaChargeUnitsScreen> createState() =>
      _ManagerFixPersonAreaChargeUnitsScreenState();
}

class _ManagerFixPersonAreaChargeUnitsScreenState
    extends State<ManagerFixPersonAreaChargeUnitsScreen> {
  static const Color primaryColor = Color(0xff00ACC1);
  static const Color purpleColor = Color(0xff610DB5);

  bool _loading = true;
  bool _sending = false;

  List<Map<String, dynamic>> _units = [];
  final Set<int> _selectedIds = {};
  final TextEditingController _searchController = TextEditingController();

  String _residentFilter = 'all';

  int get _chargeId => _intValue(
    widget.charge['id'] ??
        widget.charge['pk'] ??
        widget.charge['charge_id'],
  );

  String get _chargeName {
    final value = (
        widget.charge['name'] ??
            widget.charge['title'] ??
            'شارژ واحدی متراژی نفری'
    ).toString().trim();

    return value.isEmpty ? 'شارژ واحدی متراژی نفری' : value;
  }

  double get _fixAmount =>
      _number(widget.charge['fix_charge_amount'] ?? 0);

  double get _areaAmount =>
      _number(widget.charge['area_amount'] ?? 0);

  double get _personAmount =>
      _number(widget.charge['person_amount'] ?? 0);

  double get _otherCost =>
      _number(widget.charge['other_cost_amount'] ?? 0);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadUnits();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    if (mounted) setState(() => _loading = true);

    try {
      final result = await widget.service.getChargeUnits(
        _chargeId,
        search: _searchController.text.trim(),
        residentType: _residentFilter,
      );

      if (!mounted) return;

      setState(() {
        _units = result;
        _selectedIds.clear();
      });
    } catch (e) {
      if (mounted) _showMessage(_cleanError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --------------------------------------------------
  // تبدیل مقادیر
  // --------------------------------------------------

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(_latinDigits(value?.toString() ?? '')) ?? 0;
  }

  String _latinDigits(String input) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';

    var result = input;

    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(persian[i], '$i');
      result = result.replaceAll(arabic[i], '$i');
    }

    return result;
  }

  String _persianDigits(dynamic value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    var result = value?.toString() ?? '';

    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }

    return result;
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    if (value == null) return 0;

    final raw = _latinDigits(value.toString())
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('٫', '.')
        .trim();

    return double.tryParse(raw) ?? 0;
  }

  String _money(dynamic value) {
    final integer = _number(value).round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < integer.length; i++) {
      buffer.write(integer[i]);

      final remaining = integer.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    return _persianDigits(buffer.toString());
  }

  String _formatCount(double value) {
    final formatted = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);

    return _persianDigits(formatted);
  }

  bool _boolValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = _latinDigits(
      value?.toString().toLowerCase() ?? '',
    ).trim();

    return const [
      'true',
      '1',
      'yes',
      'بله',
      'ارسال شده',
      'ارسال‌شده',
      'موفق',
    ].contains(text);
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst('Exception: ', '').trim();

  // --------------------------------------------------
  // اطلاعات واحد
  // --------------------------------------------------

  int _unitId(Map<String, dynamic> unit) {
    return _intValue(unit['id'] ?? unit['unit_id'] ?? unit['unit_pk']);
  }

  String _unitNumber(Map<String, dynamic> unit) {
    final value = unit['unit'] ??
        unit['unit_number'] ??
        unit['unit_name'] ??
        unit['unit_display'];

    if (value == null || value.toString().trim().isEmpty) {
      return 'نامشخص';
    }

    return value.toString().trim();
  }

  double _unitArea(Map<String, dynamic> unit) {
    return _number(unit['area'] ?? 0);
  }

  double _unitPeople(Map<String, dynamic> unit) {
    return _number(unit['people_count'] ?? 0);
  }

  bool _isRenter(Map<String, dynamic> unit) =>
      unit['resident_type']?.toString() == 'renter';

  bool _isVacant(Map<String, dynamic> unit) {
    return unit['resident_type']?.toString() == 'empty';
  }

  String _residentName(Map<String, dynamic> unit) {
    if (_isRenter(unit)) {
      final renter = unit['renter_name']?.toString().trim() ?? '';
      return renter.isEmpty ? 'نام مستأجر ثبت نشده' : renter;
    }

    final owner = unit['owner_name']?.toString().trim() ?? '';
    return owner.isEmpty ? 'نام مالک ثبت نشده' : owner;
  }

  bool _isPaid(Map<String, dynamic> unit) =>
      _boolValue(unit['is_paid']);

  bool _isSystemSent(Map<String, dynamic> unit) =>
      _boolValue(unit['is_notified'] ?? unit['send_notification']);

  bool _isSmsSent(Map<String, dynamic> unit) =>
      _boolValue(unit['send_sms']);

  String _smsDate(Map<String, dynamic> unit) =>
      (unit['send_sms_date'] ?? '').toString();

  String _jalaliDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '—';
    }

    final normalized = _latinDigits(value.toString().trim());

    if (RegExp(r'^(13|14)\d{2}[-/]\d{1,2}[-/]\d{1,2}$')
        .hasMatch(normalized)) {
      return _persianDigits(normalized.replaceAll('-', '/'));
    }

    try {
      final datePart =
      normalized.length >= 10 ? normalized.substring(0, 10) : normalized;
      final date = DateTime.parse(datePart);
      final jalali = Jalali.fromDateTime(date);

      return _persianDigits(
        '${jalali.year.toString().padLeft(4, '0')}/'
            '${jalali.month.toString().padLeft(2, '0')}/'
            '${jalali.day.toString().padLeft(2, '0')}',
      );
    } catch (_) {
      return _persianDigits(normalized);
    }
  }

  // --------------------------------------------------
  // محاسبه مبلغ شارژ هر واحد
  // --------------------------------------------------

  double _unitChargeAmount(Map<String, dynamic> unit) {
    // مبلغ محاسبه‌شده بک‌اند در اولویت است.
    final currentAmount = unit['current_charge'];

    if (currentAmount != null) {
      return _number(currentAmount);
    }

    // فرمول:
    // مبلغ ثابت + متراژ × نرخ هر متر
    // + تعداد نفرات × نرخ هر نفر + هزینه متفرقه
    return _fixAmount +
        (_unitArea(unit) * _areaAmount) +
        (_unitPeople(unit) * _personAmount) +
        _otherCost;
  }

  // --------------------------------------------------
  // فیلتر و انتخاب واحدها
  // --------------------------------------------------

  List<Map<String, dynamic>> get _filteredUnits {
    final query = _latinDigits(
      _searchController.text.trim().toLowerCase(),
    );

    return _units.where((unit) {
      if (_residentFilter == 'owner' && _isRenter(unit)) {
        return false;
      }

      if (_residentFilter == 'renter' && !_isRenter(unit)) {
        return false;
      }

      if (_residentFilter == 'empty' && !_isVacant(unit)) {
        return false;
      }

      if (query.isNotEmpty) {
        final searchable = _latinDigits(
          '${_unitNumber(unit)} ${_residentName(unit)} ${_unitId(unit)}'
              .toLowerCase(),
        );

        if (!searchable.contains(query)) return false;
      }

      return true;
    }).toList();
  }

  bool get _allFilteredSelected {
    final ids = _filteredUnits.map(_unitId).where((id) => id > 0).toSet();

    return ids.isNotEmpty && ids.every(_selectedIds.contains);
  }

  void _toggleUnit(int id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _toggleSelectAll() {
    final ids = _filteredUnits.map(_unitId).where((id) => id > 0).toSet();

    setState(() {
      if (ids.isNotEmpty && ids.every(_selectedIds.contains)) {
        _selectedIds.removeAll(ids);
      } else {
        _selectedIds.addAll(ids);
      }
    });
  }

  // --------------------------------------------------
  // ارسال شارژ
  // --------------------------------------------------

  Future<void> _showSendOptions() async {
    if (_selectedIds.isEmpty) {
      _showMessage('ابتدا واحدهای موردنظر را انتخاب کنید.');
      return;
    }

    final sendSms = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool selectedOption = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'روش ارسال شارژ',
                textAlign: TextAlign.right,
              ),
              content: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'شارژ برای ${_persianDigits(_selectedIds.length)} '
                          'واحد ارسال می‌شود.',
                    ),
                    const SizedBox(height: 10),
                    RadioListTile<bool>(
                      value: false,
                      groupValue: selectedOption,
                      activeColor: primaryColor,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('ارسال سیستمی'),
                      subtitle: const Text(
                        'ثبت شارژ و اعلان داخل اپلیکیشن',
                      ),
                      onChanged: (value) {
                        setDialogState(() => selectedOption = value!);
                      },
                    ),
                    RadioListTile<bool>(
                      value: true,
                      groupValue: selectedOption,
                      activeColor: primaryColor,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('ارسال سیستمی و پیامکی'),
                      subtitle: const Text(
                        'ثبت شارژ و تلاش برای ارسال پیامک',
                      ),
                      onChanged: (value) {
                        setDialogState(() => selectedOption = value!);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('انصراف'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext, selectedOption);
                  },
                  child: const Text('ادامه'),
                ),
              ],
            );
          },
        );
      },
    );

    if (sendSms == null || !mounted) return;

    await _sendSelected(sendSms: sendSms);
  }

  Future<void> _sendSelected({required bool sendSms}) async {
    if (_selectedIds.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      final result = await widget.service.sendChargeToUnits(
        _chargeId,
        _selectedIds.toList(),
        sendSms: sendSms,
      );

      if (!mounted) return;

      final detail = result['detail']?.toString();

      _showMessage(
        detail?.isNotEmpty == true
            ? detail!
            : 'درخواست ارسال شارژ ثبت شد.',
      );

      await _loadUnits();
    } catch (e) {
      if (mounted) _showMessage(_cleanError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // --------------------------------------------------
  // لغو اعلان
  // --------------------------------------------------

  Future<void> _cancelSelected() async {
    if (_selectedIds.isEmpty || _sending) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('لغو اعلان شارژ'),
        content: Text(
          'اعلان شارژ برای ${_persianDigits(_selectedIds.length)} '
              'واحد انتخاب‌شده لغو شود؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('لغو اعلان'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _sending = true);

    try {
      final result = await widget.service.cancelChargeForUnits(
        _chargeId,
        _selectedIds.toList(),
      );

      if (!mounted) return;

      _showMessage(
        result['detail']?.toString() ?? 'درخواست لغو اعلان ثبت شد.',
      );

      await _loadUnits();
    } catch (e) {
      if (mounted) _showMessage(_cleanError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, textAlign: TextAlign.right),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // --------------------------------------------------
  // سربرگ شارژ
  // --------------------------------------------------

  Widget _headerInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildChargeHeader() {
    final deadline = widget.charge['payment_deadline'];
    final details = widget.charge['details'] ?? '';
    final totalPeople = widget.charge['total_people'];
    final totalArea = widget.charge['total_area'];

    return Card(
      color: purpleColor,
      elevation: 2,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.apartment_rounded,
                  color: Colors.white,
                  size: 23,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _chargeName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 7,
              children: [
                _headerInfo(
                  Icons.payments_outlined,
                  'ثابت هر واحد: ${_money(_fixAmount)} تومان',
                ),
                _headerInfo(
                  Icons.straighten_rounded,
                  'هر متر: ${_money(_areaAmount)} تومان',
                ),
                _headerInfo(
                  Icons.person_outline_rounded,
                  'هر نفر: ${_money(_personAmount)} تومان',
                ),
                if (_otherCost > 0)
                  _headerInfo(
                    Icons.receipt_long_outlined,
                    'هزینه متفرقه: ${_money(_otherCost)} تومان',
                  ),
                if (deadline != null)
                  _headerInfo(
                    Icons.event_outlined,
                    'مهلت: ${_jalaliDate(deadline)}',
                  ),
                _headerInfo(
                  Icons.apartment_rounded,
                  '${_persianDigits(_units.length)} واحد',
                ),
                if (totalArea != null)
                  _headerInfo(
                    Icons.square_foot_rounded,
                    '${_formatCount(_number(totalArea))} متر',
                  ),
                if (totalPeople != null)
                  _headerInfo(
                    Icons.groups_rounded,
                    '${_persianDigits(totalPeople)} نفر',
                  ),
              ],
            ),
            if (details.toString().trim().isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                details.toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // فیلتر ساکنان
  // --------------------------------------------------

  Widget _buildResidentFilters() {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _residentChip('همه ساکنان', 'all'),
            _residentChip('مالکین', 'owner'),
            _residentChip('مستأجرین', 'renter'),
            _residentChip('واحدهای خالی', 'empty'),
          ],
        ),
      ),
    );
  }

  Widget _residentChip(String label, String value) {
    final selected = _residentFilter == value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: primaryColor,
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontSize: 12,
        ),
        onSelected: (_) async {
          setState(() {
            _residentFilter = value;
            _selectedIds.clear();
          });
          await _loadUnits();
        },
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 5),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'جست‌وجوی شماره واحد یا نام ساکن',
          hintStyle: const TextStyle(fontSize: 12),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
            tooltip: 'پاک کردن جست‌وجو',
            onPressed: () async {
              _searchController.clear();
              await _loadUnits();
            },
            icon: const Icon(Icons.close_rounded),
          ),
          isDense: true,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (_) => _loadUnits(),
      ),
    );
  }

  Widget _buildSelectionBar() {
    final filtered = _filteredUnits;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 5),
      child: Row(
        children: [
          Checkbox(
            value: _allFilteredSelected,
            activeColor: primaryColor,
            onChanged: filtered.isEmpty ? null : (_) => _toggleSelectAll(),
          ),
          const Expanded(
            child: Text(
              'انتخاب واحدهای نمایش‌داده‌شده',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Text(
            '${_persianDigits(_selectedIds.length)} انتخاب',
            style: const TextStyle(
              color: purpleColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'از ${_persianDigits(filtered.length)}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // رنگ کارت
  // --------------------------------------------------

  Color _unitCardColor(Map<String, dynamic> unit) {
    if (_isVacant(unit)) return const Color(0xfffff0f0);
    if (_isPaid(unit)) return const Color(0xffE5F5E9);
    if (_isSystemSent(unit)) return const Color(0xfffff0dc);
    return Colors.white;
  }

  Color _unitBorderColor(Map<String, dynamic> unit) {
    if (_isVacant(unit)) return Colors.red;
    if (_isPaid(unit)) return const Color(0xff81C784);
    if (_isSystemSent(unit)) return const Color(0xffffcc80);
    return Colors.grey.shade300;
  }

  // --------------------------------------------------
  // کارت واحد
  // --------------------------------------------------

  Widget _buildUnitCard(Map<String, dynamic> unit) {
    final id = _unitId(unit);
    final selected = _selectedIds.contains(id);
    final paid = _isPaid(unit);
    final smsSent = _isSmsSent(unit);
    final systemSent = _isSystemSent(unit);
    final vacant = _isVacant(unit);

    final area = _unitArea(unit);
    final people = _unitPeople(unit);
    final amount = _unitChargeAmount(unit);
    final smsDate = _smsDate(unit).trim();

    final paymentDate = unit['payment_date'] ?? unit['paid_at'];

    final residentType =
    vacant ? 'خالی' : (_isRenter(unit) ? 'مستأجر' : 'مالک');

    return Card(
      color: _unitCardColor(unit),
      elevation: selected ? 2 : 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? purpleColor : _unitBorderColor(unit),
          width: vacant || selected ? 1.5 : 0.8,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: id <= 0 ? null : () => _toggleUnit(id, !selected),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                activeColor: purpleColor,
                onChanged: id <= 0
                    ? null
                    : (value) => _toggleUnit(id, value ?? false),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'واحد ${_persianDigits(_unitNumber(unit))}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (vacant)
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                        if (paid)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xff2E7D32),
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      vacant
                          ? 'وضعیت: خالی'
                          : '$residentType: ${_residentName(unit)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: vacant ? Colors.red.shade800 : Colors.grey.shade800,
                        fontWeight:
                        vacant ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 12,
                      runSpacing: 5,
                      children: [
                        Text(
                          'متراژ: ${_formatCount(area)} متر',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'تعداد نفرات: ${_formatCount(people)} نفر',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'مبلغ ثابت: ${_money(_fixAmount)} تومان',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'هر متر: ${_money(_areaAmount)} تومان',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'هر نفر: ${_money(_personAmount)} تومان',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (_otherCost > 0)
                          Text(
                            'هزینه متفرقه: ${_money(_otherCost)} تومان',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_money(amount)} تومان',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: paid ? const Color(0xff2E7D32) : purpleColor,
                            ),
                          ),
                        ),
                        if (systemSent)
                          const Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Tooltip(
                              message: 'اعلان سیستمی ثبت شده',
                              child: Icon(
                                Icons.notifications_active_rounded,
                                color: Colors.deepOrange,
                                size: 19,
                              ),
                            ),
                          ),
                        if (smsSent)
                          Tooltip(
                            message: smsDate.isEmpty
                                ? 'پیامک ثبت شده'
                                : 'پیامک: ${_jalaliDate(smsDate)}',
                            child: const Icon(
                              Icons.sms_rounded,
                              color: Colors.blue,
                              size: 19,
                            ),
                          ),
                      ],
                    ),
                    if (paid && paymentDate != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        'تاریخ پرداخت: ${_jalaliDate(paymentDate)}',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    if (smsDate.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'تاریخ ارسال پیامک: ${_jalaliDate(smsDate)}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // دکمه‌های پایین صفحه
  // --------------------------------------------------

  Widget _buildBottomActions() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                _sending || _selectedIds.isEmpty ? null : _cancelSelected,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('لغو اعلان'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  minimumSize: const Size(0, 45),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed:
                _sending || _selectedIds.isEmpty ? null : _showSendOptions,
                icon: _sending
                    ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _sending
                      ? 'لطفاً صبر کنید'
                      : 'ارسال (${_persianDigits(_selectedIds.length)})',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // صفحه اصلی
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final filteredUnits = _filteredUnits;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          title: const Text(
            'ارسال اطلاعیه شارژ واحدی متراژی نفری',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'به‌روزرسانی',
              onPressed: _loading || _sending ? null : _loadUnits,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            _buildChargeHeader(),
            _buildResidentFilters(),
            _buildSearch(),
            _buildSelectionBar(),
            const Divider(height: 1),
            Expanded(
              child: filteredUnits.isEmpty
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.apartment_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'واحدی با این مشخصات پیدا نشد.',
                        textAlign: TextAlign.center,
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          _searchController.clear();
                          setState(() {
                            _residentFilter = 'all';
                          });
                          await _loadUnits();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('نمایش همه واحدها'),
                      ),
                    ],
                  ),
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadUnits,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: 5,
                    bottom: 12,
                  ),
                  itemCount: filteredUnits.length,
                  itemBuilder: (context, index) =>
                      _buildUnitCard(filteredUnits[index]),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _loading ? null : _buildBottomActions(),
      ),
    );
  }
}
