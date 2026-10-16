import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_fixed_charge_service.dart';

class ManagerFixedChargeUnitsScreen extends StatefulWidget {
  final Map<String, dynamic> charge;
  final ManagerFixedChargeService service;

  const ManagerFixedChargeUnitsScreen({
    super.key,
    required this.charge,
    required this.service,
  });

  @override
  State<ManagerFixedChargeUnitsScreen> createState() =>
      _ManagerFixedChargeUnitsScreenState();
}

class _ManagerFixedChargeUnitsScreenState
    extends State<ManagerFixedChargeUnitsScreen> {
  static const Color primaryColor = Color(0xff00ACC1);
  static const Color purpleColor = Color(0xff610DB5);

  bool _loading = true;
  bool _sending = false;

  List<Map<String, dynamic>> _units = [];
  final Set<int> _selectedIds = {};

  final TextEditingController _searchController =
  TextEditingController();

  // all / owner / renter
  String _residentFilter = 'all';

  int get _chargeId => _intValue(widget.charge['id']);

  String get _chargeName {
    final value = (
        widget.charge['name'] ??
            widget.charge['title'] ??
            widget.charge['charge_name'] ??
            widget.charge['charge_title'] ??
            'شارژ ثابت'
    ).toString().trim();

    if (value.isEmpty) return 'شارژ ثابت';

    final normalized = value
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    const translations = {
      'fixed charge': 'شارژ ثابت',
      'monthly fixed charge': 'شارژ ثابت ماهانه',
      'fixed monthly charge': 'شارژ ثابت ماهانه',
      'monthly charge': 'شارژ ماهانه',
      'charge': 'شارژ',
      'civil charge': 'شارژ عمرانی',
      'maintenance charge': 'شارژ نگهداری',
      'building charge': 'شارژ ساختمان',
      'building fixed charge': 'شارژ ثابت ساختمان',
      'fixed building charge': 'شارژ ثابت ساختمان',
      'common charge': 'شارژ مشاعات',
      'common area charge': 'شارژ مشاعات',
      'service charge': 'شارژ خدمات',
      'repair charge': 'شارژ تعمیرات',
      'water charge': 'شارژ آب',
      'electricity charge': 'شارژ برق',
      'monthly building charge': 'شارژ ماهانه ساختمان',
    };

    return translations[normalized] ?? value;
  }

  @override
  void initState() {
    super.initState();
    _loadUnits();

    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --------------------------------------------------
  // دریافت واحدها
  // --------------------------------------------------

  Future<void> _loadUnits() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final result = await widget.service.getChargeUnits(_chargeId);

      if (!mounted) return;

      setState(() {
        _units = result;
        _selectedIds.clear();
      });
    } catch (e) {
      if (mounted) {
        _showMessage(_cleanError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // --------------------------------------------------
  // تبدیل مقادیر
  // --------------------------------------------------

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(
      _latinDigits(value?.toString() ?? ''),
    ) ??
        0;
  }

  double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();

    final raw = _latinDigits(value?.toString() ?? '')
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll(' ', '')
        .trim();

    return double.tryParse(raw) ?? 0.0;
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

  String _money(dynamic value) {
    final number = _doubleValue(value);
    final integer = number.round().toString();
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

  bool _boolValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text =
    _latinDigits(value?.toString().toLowerCase() ?? '').trim();

    return text == 'true' ||
        text == '1' ||
        text == 'yes' ||
        text == 'بله' ||
        text == 'ارسال شده' ||
        text == 'ارسال‌شده' ||
        text == 'موفق';
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  // --------------------------------------------------
  // اطلاعات واحد
  // --------------------------------------------------

  int _unitId(Map<String, dynamic> unit) {
    return _intValue(
      unit['unit_id'] ??
          unit['unit_pk'] ??
          unit['id'] ??
          unit['unit'],
    );
  }

  String _unitNumber(Map<String, dynamic> unit) {
    final value = unit['unit_number'] ??
        unit['unit_name'] ??
        unit['unit_display'] ??
        unit['number'] ??
        unit['unit'] ??
        unit['name'] ??
        _unitId(unit);

    if (value is Map) {
      return (
          value['unit_number'] ??
              value['number'] ??
              value['name'] ??
              value['unit'] ??
              '—'
      ).toString();
    }

    return value.toString();
  }

  bool _isRenter(Map<String, dynamic> unit) {
    final type = (
        unit['resident_type'] ??
            unit['resident_type_display'] ??
            unit['residence_type'] ??
            ''
    ).toString().toLowerCase();

    if (type.contains('renter') ||
        type.contains('tenant') ||
        type.contains('مستاجر') ||
        type.contains('مستأجر')) {
      return true;
    }

    return _boolValue(
      unit['is_renter'] ??
          unit['has_active_renter'] ??
          unit['active_renter'],
    );
  }

  String _residentName(Map<String, dynamic> unit) {
    final renterName =
        unit['renter_name'] ?? unit['active_renter_name'];

    final ownerName = unit['owner_name'] ??
        unit['resident_name'] ??
        unit['full_name'];

    final name = _isRenter(unit)
        ? (renterName ?? ownerName)
        : (ownerName ?? renterName);

    if (name == null || name.toString().trim().isEmpty) {
      return 'نام ثبت نشده';
    }

    return name.toString().trim();
  }

  bool _isPaid(Map<String, dynamic> unit) {
    return _boolValue(
      unit['is_paid'] ??
          unit['paid'] ??
          unit['payment_completed'] ??
          unit['is_payment_completed'],
    );
  }

  bool _isSystemSent(Map<String, dynamic> unit) {
    final chargeData = _chargeData(unit);

    return _boolValue(
      unit['is_notified'] ??
          unit['send_notification'] ??
          unit['notification_sent'] ??
          unit['is_sent'] ??
          unit['sent'] ??
          chargeData?['send_notification'] ??
          chargeData?['notification_sent'],
    );
  }

  Map<String, dynamic>? _chargeData(
      Map<String, dynamic> unit,
      ) {
    for (final key in const [
      'charge',
      'unified_charge',
      'charge_data',
      'fixed_charge',
    ]) {
      final value = unit[key];

      if (value is Map<String, dynamic>) {
        return value;
      }

      if (value is Map) {
        return value.map(
              (key, value) => MapEntry(key.toString(), value),
        );
      }
    }

    return null;
  }

  // --------------------------------------------------
  // وضعیت پیامک
  // --------------------------------------------------

  bool _isSmsSent(Map<String, dynamic> unit) {
    final chargeData = _chargeData(unit);

    final sources = <Map<String, dynamic>>[
      unit,
      if (chargeData != null) chargeData,
    ];

    const statusKeys = [
      'send_sms',
      'sms_sent',
      'is_sms_sent',
      'sms_notification_sent',
      'sms_delivered',
      'is_sms_delivered',
      'sms_success',
      'sms_status',
      'sms_state',
    ];

    const dateKeys = [
      'send_sms_date',
      'sms_date',
      'sms_sent_at',
      'sms_sent_date',
      'sms_notification_date',
    ];

    for (final source in sources) {
      for (final key in statusKeys) {
        final value = source[key];

        if (value == null) continue;

        if (value is bool && value) return true;
        if (value is num && value > 0) return true;

        final text = _latinDigits(
          value.toString().trim().toLowerCase(),
        );

        if (const [
          'true',
          '1',
          'yes',
          'sent',
          'success',
          'delivered',
          'ارسال شده',
          'ارسال‌شده',
          'موفق',
          'تحویل شده',
          'تحویل‌شده',
        ].contains(text)) {
          return true;
        }
      }

      for (final key in dateKeys) {
        final value = source[key];

        if (value != null &&
            value.toString().trim().isNotEmpty) {
          return true;
        }
      }
    }

    return false;
  }

  // --------------------------------------------------
  // تشخیص واحد خالی
  // --------------------------------------------------

  bool _isVacant(Map<String, dynamic> unit) {
    final status = (
        unit['status_residence_display'] ??
            unit['residence_status_display'] ??
            unit['status_residence'] ??
            unit['residence_status'] ??
            unit['residence_state'] ??
            ''
    ).toString().trim().toLowerCase();

    if (const [
      'خالی',
      'خالی است',
      'بدون ساکن',
      'vacant',
      'empty',
      'unoccupied',
    ].contains(status)) {
      return true;
    }

    if (unit.containsKey('is_occupied')) {
      return !_boolValue(unit['is_occupied']);
    }

    if (unit.containsKey('is_vacant')) {
      return _boolValue(unit['is_vacant']);
    }

    if (unit.containsKey('status_residence')) {
      final value = unit['status_residence'];

      if (value is bool) return !value;

      final normalized = _latinDigits(
        value.toString().trim().toLowerCase(),
      );

      if (const [
        '0',
        'false',
        'vacant',
        'empty',
      ].contains(normalized)) {
        return true;
      }
    }

    return false;
  }

  // --------------------------------------------------
  // مبلغ شارژ هر واحد
  // --------------------------------------------------

  dynamic _unitAmount(Map<String, dynamic> unit) {
    final chargeData = _chargeData(unit);

    // ابتدا مبلغ مربوط به همان واحد
    if (chargeData != null) {
      final nestedAmount = chargeData['current_charge'] ??
          chargeData['unit_charge_amount'] ??
          chargeData['fix_amount'] ??
          chargeData['total_charge_month'] ??
          chargeData['total_charge'] ??
          chargeData['total_amount'] ??
          chargeData['charge_amount'] ??
          chargeData['amount'] ??
          chargeData['amount_due'];

      if (nestedAmount != null) {
        return nestedAmount;
      }
    }

    final unitAmount = unit['current_charge'] ??
        unit['unit_charge_amount'] ??
        unit['fix_amount'] ??
        unit['total_charge_month'] ??
        unit['total_charge'] ??
        unit['total_amount'] ??
        unit['charge_amount'] ??
        unit['amount_due'] ??
        unit['amount'] ??
        unit['monthly_charge'] ??
        unit['charge_total'];

    if (unitAmount != null) {
      return unitAmount;
    }

    // در صورت نبود مبلغ واحد، از مبلغ شارژ اصلی استفاده می‌شود.
    return widget.charge['fix_amount'] ??
        widget.charge['total_amount'] ??
        widget.charge['charge_amount'] ??
        widget.charge['amount'] ??
        0;
  }

  // --------------------------------------------------
  // جمع مبلغ واحدهای انتخاب‌شده
  // --------------------------------------------------

  double get _selectedTotalAmount {
    return _units
        .where(
          (unit) => _selectedIds.contains(_unitId(unit)),
    )
        .fold<double>(
      0.0,
          (sum, unit) {
        return sum + _doubleValue(_unitAmount(unit));
      },
    );
  }

  // --------------------------------------------------
  // تاریخ شمسی
  // --------------------------------------------------

  String _jalaliDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '—';
    }

    final text = value.toString().trim();
    final normalized = _latinDigits(text);

    if (RegExp(r'^(13|14)\d{2}[-/]\d{1,2}[-/]\d{1,2}$')
        .hasMatch(normalized)) {
      return _persianDigits(normalized.replaceAll('-', '/'));
    }

    try {
      final datePart = normalized.length >= 10
          ? normalized.substring(0, 10)
          : normalized;

      final date = DateTime.parse(datePart);
      final jalali = Jalali.fromDateTime(date);

      return _persianDigits(
        '${jalali.year.toString().padLeft(4, '0')}/'
            '${jalali.month.toString().padLeft(2, '0')}/'
            '${jalali.day.toString().padLeft(2, '0')}',
      );
    } catch (_) {
      return _persianDigits(text);
    }
  }

  // --------------------------------------------------
  // فیلتر جست‌وجو
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

      if (query.isNotEmpty) {
        final searchable = _latinDigits(
          '${_unitNumber(unit)} '
              '${_residentName(unit)} '
              '${_unitId(unit)}'.toLowerCase(),
        );

        if (!searchable.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool get _allFilteredSelected {
    final ids = _filteredUnits
        .map(_unitId)
        .where((id) => id > 0)
        .toSet();

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
    final ids = _filteredUnits
        .map(_unitId)
        .where((id) => id > 0)
        .toSet();

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
                      'شارژ برای '
                          '${_persianDigits(_selectedIds.length)} '
                          'واحد ارسال می‌شود.',
                      textAlign: TextAlign.right,
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
                        setDialogState(
                              () => selectedOption = value!,
                        );
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
                        setDialogState(
                              () => selectedOption = value!,
                        );
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
                  onPressed: () => Navigator.pop(
                    dialogContext,
                    selectedOption,
                  ),
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

  Future<void> _sendSelected({
    required bool sendSms,
  }) async {
    if (_selectedIds.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      final result = await widget.service.sendChargeToUnits(
        _chargeId,
        _selectedIds.toList(),
        sendSms: sendSms,
      );

      if (!mounted) return;

      final success = _boolValue(
        result['ok'] ?? result['success'] ?? true,
      );

      final smsSent = _boolValue(result['sms_sent']);

      final message = result['detail'] ??
          result['message'] ??
          result['sms_message'];

      if (!success) {
        _showMessage(
          message?.toString() ?? 'ارسال شارژ ناموفق بود.',
        );
        return;
      }

      String successMessage;

      if (!sendSms) {
        successMessage = message?.toString().isNotEmpty == true
            ? message.toString()
            : 'شارژ با موفقیت ثبت و ارسال سیستمی شد.';
      } else if (smsSent) {
        final smsCount = result['sms_count'] ??
            result['total_sms'] ??
            _selectedIds.length;

        successMessage = 'شارژ ثبت شد؛ پیامک برای '
            '${_persianDigits(smsCount)} گیرنده ارسال شد.';
      } else {
        successMessage = message?.toString().isNotEmpty == true
            ? 'شارژ سیستمی ثبت شد؛ وضعیت پیامک: $message'
            : 'شارژ سیستمی ثبت شد، اما ارسال پیامک تأیید نشد.';
      }

      _showMessage(successMessage);
      await _loadUnits();
    } catch (e) {
      if (mounted) {
        _showMessage(_cleanError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  // --------------------------------------------------
  // لغو شارژ
  // --------------------------------------------------

  Future<void> _cancelSelected() async {
    if (_selectedIds.isEmpty || _sending) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('لغو شارژ'),
        content: Text(
          'شارژ برای '
              '${_persianDigits(_selectedIds.length)} '
              'واحد لغو شود؟',
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
            child: const Text('لغو شارژ'),
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
        (result['detail'] ??
            result['message'] ??
            'عملیات لغو شارژ انجام شد.')
            .toString(),
      );

      await _loadUnits();
    } catch (e) {
      if (mounted) {
        _showMessage(_cleanError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  // --------------------------------------------------
  // پیام
  // --------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.right,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // --------------------------------------------------
  // سربرگ شارژ
  // --------------------------------------------------

  Widget _buildChargeHeader() {
    final amount = widget.charge['fix_amount'] ??
        widget.charge['total_amount'] ??
        widget.charge['charge_amount'] ??
        widget.charge['amount'] ??
        0;

    final deadline = widget.charge['payment_deadline'] ??
        widget.charge['payment_deadline_date'];

    final description =
        widget.charge['details'] ?? widget.charge['description'] ?? '';

    return Card(
      color: purpleColor,
      elevation: 2,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 23,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _chargeName,
                    textAlign: TextAlign.right,
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
                  '${_money(amount)} تومان',
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
              ],
            ),
            if (description.toString().trim().isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                description.toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
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

  Widget _headerInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: Colors.white70,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _residentChip('همه ساکنان', 'all'),
            _residentChip('مالکین', 'owner'),
            _residentChip('مستأجرین', 'renter'),
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
        onSelected: (_) {
          setState(() => _residentFilter = value);
        },
      ),
    );
  }

  // --------------------------------------------------
  // جست‌وجو
  // --------------------------------------------------

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
            onPressed: () => _searchController.clear(),
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
      ),
    );
  }

  // --------------------------------------------------
  // انتخاب همه
  // --------------------------------------------------

  Widget _buildSelectionBar() {
    final filtered = _filteredUnits;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 5),
      child: Row(
        children: [
          Checkbox(
            value: _allFilteredSelected,
            activeColor: primaryColor,
            onChanged:
            filtered.isEmpty ? null : (_) => _toggleSelectAll(),
          ),
          const Expanded(
            child: Text(
              'انتخاب واحدهای نمایش‌داده‌شده',
              textAlign: TextAlign.right,
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
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
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
    final vacant = _isVacant(unit);

    final paymentDate = unit['payment_date'] ??
        unit['paid_at'] ??
        unit['payment_date_shamsi'];

    final chargeData = _chargeData(unit);

    final smsDate = unit['send_sms_date'] ??
        unit['sms_date'] ??
        chargeData?['send_sms_date'] ??
        chargeData?['sms_date'];

    final amount = _unitAmount(unit);

    final residentType = vacant
        ? 'خالی'
        : (_isRenter(unit) ? 'مستأجر' : 'مالک');

    return Card(
      color: _unitCardColor(unit),
      elevation: selected ? 2 : 0.5,
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 9,
          ),
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
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (vacant)
                          const Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 18,
                            ),
                          ),
                        if (paid)
                          const Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xff2E7D32),
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      vacant
                          ? 'وضعیت: خالی'
                          : '$residentType: ${_residentName(unit)}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color: vacant
                            ? Colors.red.shade800
                            : Colors.grey.shade800,
                        fontWeight:
                        vacant ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  '${_money(amount)} تومان',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: paid
                                        ? const Color(0xff2E7D32)
                                        : purpleColor,
                                  ),
                                ),
                              ),
                              if (smsSent) ...[
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: smsDate == null
                                      ? 'پیامک ارسال شده'
                                      : 'پیامک: ${_jalaliDate(smsDate)}',
                                  child: const Icon(
                                    Icons.sms_rounded,
                                    color: Colors.blue,
                                    size: 19,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (paid && paymentDate != null)
                          Flexible(
                            child: Text(
                              'تاریخ پرداخت: ${_jalaliDate(paymentDate)}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
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

  // --------------------------------------------------
  // دکمه‌های پایین + جمع مبلغ انتخاب‌شده
  // --------------------------------------------------

  // -------------------- دکمه‌های پایین --------------------

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
                onPressed: _sending || _selectedIds.isEmpty
                    ? null
                    : _cancelSelected,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('لغو شارژ'),
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
                onPressed: _sending || _selectedIds.isEmpty
                    ? null
                    : _showSendOptions,
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
            ' ارسال اطلاعیه شارژ ثابت',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'بروزرسانی',
              onPressed: _loading || _sending ? null : _loadUnits,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: _loading
            ? const Center(
          child: CircularProgressIndicator(),
        )
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
                        onPressed: () {
                          _searchController.clear();

                          setState(() {
                            _residentFilter = 'all';
                          });

                          _loadUnits();
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
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    top: 5,
                    bottom: 12,
                  ),
                  itemCount: filteredUnits.length,
                  itemBuilder: (context, index) {
                    return _buildUnitCard(
                      filteredUnits[index],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar:
        _loading ? null : _buildBottomActions(),
      ),
    );
  }
}