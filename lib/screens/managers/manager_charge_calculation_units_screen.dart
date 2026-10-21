import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_charge_calculation_service.dart';

const Color _primaryColor = Color(0xFF00ACC1);
const Color _purpleColor = Color(0xFF610DB5);

class ManagerChargeCalculationUnitsScreen extends StatefulWidget {
  final int calculationId;
  final String calculationName;

  const ManagerChargeCalculationUnitsScreen({
    super.key,
    required this.calculationId,
    required this.calculationName,
  });

  @override
  State<ManagerChargeCalculationUnitsScreen> createState() =>
      _ManagerChargeCalculationUnitsScreenState();
}

class _ManagerChargeCalculationUnitsScreenState
    extends State<ManagerChargeCalculationUnitsScreen> {
  final ManagerChargeCalculationService _service =
  ManagerChargeCalculationService();

  final TextEditingController _searchController =
  TextEditingController();

  bool _loading = true;
  bool _sending = false;

  List<Map<String, dynamic>> _units = [];
  Map<String, dynamic> _calculation = {};

  final Set<int> _selectedIds = {};

  String _residentFilter = 'all';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refresh);
    _loadUnits();
  }

  @override
  void dispose() {
    _searchController.removeListener(_refresh);
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String _latinDigits(String value) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';

    for (int i = 0; i < 10; i++) {
      value = value.replaceAll(fa[i], '$i');
      value = value.replaceAll(ar[i], '$i');
    }

    return value;
  }

  String _persianDigits(dynamic value) {
    const en = '0123456789';
    const fa = '۰۱۲۳۴۵۶۷۸۹';

    String result = value?.toString() ?? '';

    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(en[i], fa[i]);
    }

    return result;
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(
      _latinDigits(value?.toString() ?? '').trim(),
    ) ??
        0;
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    if (value == null) return 0;

    return double.tryParse(
      _latinDigits(value.toString())
          .replaceAll(',', '')
          .replaceAll('٬', '')
          .replaceAll('٫', '.')
          .trim(),
    ) ??
        0;
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
    ].contains(text);
  }

  String _money(dynamic value) {
    final amount = _number(value).round();
    final digits = amount.abs().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);

      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    return _persianDigits(
      '${amount < 0 ? '-' : ''}$buffer',
    );
  }

  String _formatCount(dynamic value) {
    final number = _number(value);

    final result = number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(2);

    return _persianDigits(result);
  }

  String _dateText(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return 'ثبت نشده';
    }

    try {
      // استخراج تاریخ از پاسخ API مانند 2026-10-22 یا ISO datetime
      final datePart = text.contains('T')
          ? text.split('T').first
          : text.split(' ').first;

      final parts = datePart.split('-');

      if (parts.length != 3) {
        return _persianDigits(datePart.replaceAll('-', '/'));
      }

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      // اگر تاریخ از قبل شمسی باشد، دوباره تبدیل نکن
      if (year >= 1200 && year <= 1600) {
        return _persianDigits(
          '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}',
        );
      }

      final jalali = Gregorian(year, month, day).toJalali();

      final formatted =
          '${jalali.year}/'
          '${jalali.month.toString().padLeft(2, '0')}/'
          '${jalali.day.toString().padLeft(2, '0')}';

      return _persianDigits(formatted);
    } catch (_) {
      return _persianDigits(text);
    }
  }

  Future<void> _loadUnits() async {
    if (_sending) return;

    setState(() => _loading = true);

    try {
      // این متد باید پاسخ کامل GET را برگرداند:
      // success, calculation, count, results
      final data = await _service.getCalculationUnitsData(
        widget.calculationId,
      );

      if (!mounted) return;

      if (data['success'] == false) {
        throw Exception(
          data['message']?.toString() ??
              'دریافت اطلاعات واحدها ناموفق بود.',
        );
      }

      final rawResults = data['results'];

      setState(() {
        _calculation = data['calculation'] is Map
            ? Map<String, dynamic>.from(data['calculation'])
            : <String, dynamic>{};

        _units = rawResults is List
            ? rawResults
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
        )
            .toList()
            : <Map<String, dynamic>>[];

        _selectedIds.clear();
      });
    } catch (e) {
      if (mounted) {
        _showMessage(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  int _unitId(Map<String, dynamic> unit) {
    return _intValue(unit['unit_id'] ?? unit['id']);
  }

  String _unitNumber(Map<String, dynamic> unit) {
    final value = unit['unit'] ?? unit['unit_number'];
    return value?.toString().trim().isNotEmpty == true
        ? value.toString()
        : 'نامشخص';
  }

  String _residentType(Map<String, dynamic> unit) {
    return (unit['resident_type'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
  }

  bool _isRenter(Map<String, dynamic> unit) {
    return _residentType(unit) == 'renter';
  }

  bool _isVacant(Map<String, dynamic> unit) {
    return _residentType(unit) == 'empty';
  }

  bool _isPaid(Map<String, dynamic> unit) {
    return _boolValue(unit['is_paid']);
  }

  String _residentName(Map<String, dynamic> unit) {
    if (_isVacant(unit)) return 'واحد خالی';

    final name = (unit['resident_name'] ?? '').toString().trim();

    if (name.isNotEmpty) return name;

    return _isRenter(unit)
        ? 'نام مستأجر ثبت نشده'
        : 'نام مالک ثبت نشده';
  }

  double _area(Map<String, dynamic> unit) {
    return _number(unit['area']);
  }

  double _peopleCount(Map<String, dynamic> unit) {
    return _number(unit['people_count']);
  }

  double _otherCost(Map<String, dynamic> unit) {
    return _number(unit['other_cost_amount']);
  }

  double _totalAmount(Map<String, dynamic> unit) {
    // از total استفاده می‌کنیم؛ مبلغ اضافی دوباره جمع نمی‌شود.
    return _number(unit['total']);
  }

  List<Map<String, dynamic>> get _filteredUnits {
    final query = _latinDigits(
      _searchController.text.trim().toLowerCase(),
    );

    return _units.where((unit) {
      if (_residentFilter == 'owner' &&
          (_isRenter(unit) || _isVacant(unit))) {
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
          '${_unitNumber(unit)} '
              '${_residentName(unit)} '
              '${_unitId(unit)}',
        ).toLowerCase();

        if (!searchable.contains(query)) return false;
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
    if (id <= 0) return;

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

  Future<void> _showSendOptions() async {
    if (_selectedIds.isEmpty || _sending) {
      _showMessage('ابتدا واحدهای موردنظر را انتخاب کنید.');
      return;
    }

    final sendSms = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool sms = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('ارسال شارژ تسهیم هزینه'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'شارژ برای '
                        '${_persianDigits(_selectedIds.length)} '
                        'واحد ارسال می‌شود.',
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<bool>(
                    value: false,
                    groupValue: sms,
                    activeColor: _primaryColor,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('ارسال سیستمی'),
                    subtitle: const Text(
                      'ثبت اعلان داخل اپلیکیشن',
                    ),
                    onChanged: (value) {
                      setDialogState(() => sms = value ?? false);
                    },
                  ),
                  RadioListTile<bool>(
                    value: true,
                    groupValue: sms,
                    activeColor: _primaryColor,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('ارسال سیستمی و پیامکی'),
                    subtitle: const Text(
                      'ثبت اعلان و درخواست ارسال پیامک',
                    ),
                    onChanged: (value) {
                      setDialogState(() => sms = value ?? true);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('انصراف'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryColor,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext, sms);
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

  Future<void> _sendSelected({
    required bool sendSms,
  }) async {
    if (_selectedIds.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      // این متد باید در Service و API ارسال تسهیم هزینه تعریف شود.
      final result = await _service.sendCalculationChargeToUnits(
        widget.calculationId,
        _selectedIds.toList(),
        sendSms: sendSms,
      );

      if (!mounted) return;

      _showMessage(
        result['message']?.toString() ??
            result['detail']?.toString() ??
            'درخواست ارسال ثبت شد.',
      );

      await _reloadAfterAction();
    } catch (e) {
      if (mounted) {
        _showMessage(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _cancelSelected() async {
    if (_selectedIds.isEmpty || _sending) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('لغو اعلان شارژ'),
        content: Text(
          'اعلان شارژ برای '
              '${_persianDigits(_selectedIds.length)} '
              'واحد لغو شود؟',
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
            child: const Text('لغو اعلان'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _sending = true);

    try {
      // این متد باید در Service و API لغو اعلان تعریف شود.
      final result = await _service.cancelCalculationChargeForUnits(
        widget.calculationId,
        _selectedIds.toList(),
      );

      if (!mounted) return;

      _showMessage(
        result['message']?.toString() ??
            result['detail']?.toString() ??
            'درخواست لغو اعلان ثبت شد.',
      );

      await _reloadAfterAction();
    } catch (e) {
      if (mounted) {
        _showMessage(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _reloadAfterAction() async {
    // وضعیت دکمه ارسال را برای مدت دریافت اطلاعات آزاد می‌کنیم.
    if (mounted) setState(() => _sending = false);
    await _loadUnits();
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

  Widget _residentChip(String label, String value) {
    final selected = _residentFilter == value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: _primaryColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontSize: 12,
        ),
        onSelected: (_) {
          setState(() {
            _residentFilter = value;
            _selectedIds.clear();
          });
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final name = _calculation['name']?.toString().trim().isNotEmpty == true
        ? _calculation['name'].toString().trim()
        : widget.calculationName;

    final startDate = _calculation['start_date'] ??
        _calculation['calculation_start_date'] ??
        _calculation['period_start'];
    final endDate = _calculation['end_date'] ??
        _calculation['calculation_end_date'] ??
        _calculation['period_end'];
    final deadline = _calculation['payment_deadline'] ??
        _calculation['deadline'];

    return Card(
      color: _purpleColor,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calculate_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: Colors.white30),
            _headerInfo(
              'بازه محاسبه',
              '${_dateText(startDate)} تا ${_dateText(endDate)}',
            ),
            _headerInfo(
              'مهلت پرداخت',
              _dateText(deadline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildUnitCard(Map<String, dynamic> unit) {
    final id = _unitId(unit);
    final selected = _selectedIds.contains(id);
    final vacant = _isVacant(unit);
    final renter = _isRenter(unit);
    final paid = _isPaid(unit);

    final systemSent = _boolValue(unit['send_notification']);
    final smsSent = _boolValue(unit['send_sms']);

    final amount = _totalAmount(unit);
    final residentName = _residentName(unit);

    final cardColor = vacant
        ? const Color(0xFFFFF0F0)
        : paid
        ? const Color(0xFFE5F5E9)
        : systemSent
        ? const Color(0xFFFFF4E5)
        : Colors.white;

    final statusBorderColor = vacant
        ? Colors.red
        : paid
        ? const Color(0xFF81C784)
        : systemSent
        ? const Color(0xFFFFCC80)
        : Colors.grey.shade300;

    final borderColor = selected ? _purpleColor : statusBorderColor;

    return Card(
      color: cardColor,
      elevation: selected ? 2 : 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor,
          width: selected ? 1.5 : 0.8,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: id <= 0 ? null : () => _toggleUnit(id, !selected),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: selected,
                activeColor: _purpleColor,
                onChanged: id <= 0
                    ? null
                    : (value) => _toggleUnit(id, value ?? false),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        if (vacant && !paid)
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 19,
                          ),
                        if (paid)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF2E7D32),
                            size: 19,
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      vacant
                          ? 'وضعیت: واحد خالی'
                          : '${renter ? 'مستأجر' : 'مالک'}: $residentName',
                      style: TextStyle(
                        fontSize: 12,
                        color: vacant
                            ? Colors.red.shade800
                            : Colors.grey.shade800,
                        fontWeight:
                        vacant ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text(
                          'متراژ: ${_formatCount(_area(unit))} متر',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'تعداد نفرات: ${_formatCount(_peopleCount(unit))}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (unit['financial_document_number'] != null)
                          Text(
                            'سند: ${_persianDigits(unit['financial_document_number'])}',
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_money(amount)} تومان',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: paid
                                  ? Colors.green.shade800
                                  : _purpleColor,
                            ),
                          ),
                        ),
                        if (systemSent)
                          const Tooltip(
                            message: 'اعلان سیستمی ثبت شده',
                            child: Icon(
                              Icons.notifications_active_rounded,
                              color: Colors.deepOrange,
                              size: 19,
                            ),
                          ),
                        if (smsSent)
                          const Padding(
                            padding: EdgeInsets.only(right: 5),
                            child: Tooltip(
                              message: 'وضعیت پیامک: ارسال‌شده',
                              child: Icon(
                                Icons.sms_rounded,
                                color: Colors.blue,
                                size: 19,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (paid)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'پرداخت شده',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    // if (systemSent && !paid)
                    //   const Padding(
                    //     padding: EdgeInsets.only(top: 4),
                    //     child: Text(
                    //       'اعلان شده',
                    //       style: TextStyle(
                    //         color: Colors.deepOrange,
                    //         fontSize: 11,
                    //         fontWeight: FontWeight.bold,
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



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
                  backgroundColor: _primaryColor,
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

  @override
  Widget build(BuildContext context) {
    final filteredUnits = _filteredUnits;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          title: const Text(
            'واحدهای تسهیم هزینه',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'به‌روزرسانی',
              onPressed: _loading || _sending ? null : _loadUnits,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildHeader(),
            Padding(
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
                    onPressed: _searchController.clear,
                    icon: const Icon(Icons.close_rounded),
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _residentChip('همه واحدها', 'all'),
                  _residentChip('مالکین', 'owner'),
                  _residentChip('مستأجرین', 'renter'),
                  _residentChip('واحدهای خالی', 'empty'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _allFilteredSelected,
                    activeColor: _primaryColor,
                    onChanged: filteredUnits.isEmpty
                        ? null
                        : (_) => _toggleSelectAll(),
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
                      color: _purpleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : filteredUnits.isEmpty
                  ? const Center(
                child: Text('واحدی برای نمایش پیدا نشد.'),
              )
                  : RefreshIndicator(
                onRefresh: _loadUnits,
                child: ListView.builder(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    bottom: 12,
                    top: 5,
                  ),
                  itemCount: filteredUnits.length,
                  itemBuilder: (context, index) =>
                      _buildUnitCard(filteredUnits[index]),
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
