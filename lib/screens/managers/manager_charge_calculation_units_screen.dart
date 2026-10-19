
import 'package:flutter/material.dart';

import '../../services/manager_charge_calculation_service.dart';

const Color _primaryColor = Color(0xFF00ACC1);
const Color _purpleColor = Color(0xFF610DB5);

class ManagerChargeCalculationUnitsScreen extends StatefulWidget {
  final int calculationId;
  final String? calculationName;

  const ManagerChargeCalculationUnitsScreen({
    super.key,
    required this.calculationId,
    this.calculationName,
  });

  @override
  State<ManagerChargeCalculationUnitsScreen> createState() =>
      _ManagerChargeCalculationUnitsScreenState();
}

class _ManagerChargeCalculationUnitsScreenState
    extends State<ManagerChargeCalculationUnitsScreen> {
  final ManagerChargeCalculationService _service =
  ManagerChargeCalculationService();

  bool _loading = true;
  bool _sending = false;
  bool _sendSms = false;

  Map<String, dynamic> _data = {};
  List<Map<String, dynamic>> _units = [];
  final Set<int> _selectedUnitIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(
      value.toString().replaceAll(',', '').trim(),
    ) ??
        0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) return value.toDouble();

    final normalized = value.toString().trim().replaceAll(',', '');
    return double.tryParse(normalized) ?? 0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    return ['true', '1', 'yes'].contains(
      value.toString().toLowerCase(),
    );
  }

  String _formatNumber(dynamic value) {
    final number = _toDouble(value);
    final fixed = number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');

    final parts = fixed.split('.');
    final integer = parts[0];
    final buffer = StringBuffer();

    for (int i = 0; i < integer.length; i++) {
      buffer.write(integer[i]);

      final remaining = integer.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    if (parts.length > 1 && parts[1].isNotEmpty) {
      buffer.write('.');
      buffer.write(parts[1]);
    }

    return buffer.toString();
  }

  String _text(dynamic value, [String fallback = '—']) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }

    return value.toString();
  }

  int _unitId(Map<String, dynamic> unit) {
    return _toInt(
      unit['unit_id'] ??
          unit['id'] ??
          unit['unit_pk'],
    );
  }

  String _unitName(Map<String, dynamic> unit) {
    return _text(
      unit['unit'] ??
          unit['unit_name'] ??
          unit['unit_number'] ??
          unit['name'],
      'واحد ${_unitId(unit)}',
    );
  }

  double _unitTotal(Map<String, dynamic> unit) {
    return _toDouble(
      unit['total'] ??
          unit['cost_total'] ??
          unit['total_amount'],
    );
  }

  bool _isPaid(Map<String, dynamic> unit) {
    return _toBool(unit['is_paid']);
  }

  bool _isNotified(Map<String, dynamic> unit) {
    return _toBool(unit['send_notification']) ||
        unit['send_notification_date'] != null;
  }

  bool _canSelect(Map<String, dynamic> unit) {
    return !_isPaid(unit) && !_isNotified(unit);
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final response = await _service.getCalculationUnitsData(
        widget.calculationId,
      );

      final rawResults = response['results'] ??
          response['units'] ??
          response['data'] ??
          response['items'] ??
          [];

      final loadedUnits = rawResults is List
          ? rawResults
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;

      setState(() {
        _data = response;
        _units = loadedUnits;

        _selectedUnitIds
          ..clear()
          ..addAll(
            _units
                .where(_canSelect)
                .map(_unitId)
                .where((id) => id > 0),
          );

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage(
        'دریافت اطلاعات واحدها ناموفق بود: $e',
        error: true,
      );
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int get _eligibleCount => _units.where(_canSelect).length;

  double get _selectedTotal {
    return _units
        .where((unit) => _selectedUnitIds.contains(_unitId(unit)))
        .fold<double>(0, (sum, unit) => sum + _unitTotal(unit));
  }

  double get _allTotal {
    return _units.fold<double>(0, (sum, unit) => sum + _unitTotal(unit));
  }

  void _toggleUnit(Map<String, dynamic> unit, bool? checked) {
    final id = _unitId(unit);
    if (id <= 0 || !_canSelect(unit)) return;

    setState(() {
      if (checked == true) {
        _selectedUnitIds.add(id);
      } else {
        _selectedUnitIds.remove(id);
      }
    });
  }

  void _toggleAll(bool? checked) {
    setState(() {
      if (checked == true) {
        _selectedUnitIds
          ..clear()
          ..addAll(
            _units
                .where(_canSelect)
                .map(_unitId)
                .where((id) => id > 0),
          );
      } else {
        _selectedUnitIds.clear();
      }
    });
  }

  Future<void> _sendCharges() async {
    if (_selectedUnitIds.isEmpty) {
      _showMessage('حداقل یک واحد را انتخاب کنید.', error: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('تأیید ارسال شارژ'),
          content: Text(
            'شارژ برای ${_selectedUnitIds.length} واحد ارسال شود؟'
                '${_sendSms ? '\nبرای ارسال پیامک نیز درخواست ثبت می‌شود.' : ''}'
                '\n\nمبلغ مجموع واحدهای انتخاب‌شده: '
                '${_formatNumber(_selectedTotal)} تومان',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _primaryColor,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('تأیید و ارسال'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _sending = true);

    try {
      final response = await _service.sendCalculationToUnits(
        widget.calculationId,
        _selectedUnitIds.toList(),
        sendSms: _sendSms,
      );

      if (!mounted) return;

      final createdCount = _toInt(
        response['created_count'] ??
            response['success_count'] ??
            response['count'],
      );

      final skippedCount = response['skipped_paid_unit_ids'] is List
          ? (response['skipped_paid_unit_ids'] as List).length
          : 0;

      final smsSuccess = response['sms_success'];
      final smsMessage = _text(response['sms_message'], '');

      final message = StringBuffer();

      message.write(
        createdCount > 0
            ? 'شارژ برای $createdCount واحد ثبت شد.'
            : 'درخواست ارسال انجام شد.',
      );

      if (skippedCount > 0) {
        message.write(' $skippedCount واحد پرداخت‌شده ارسال نشد.');
      }

      if (_sendSms && smsSuccess == false && smsMessage.isNotEmpty) {
        message.write('\nوضعیت پیامک: $smsMessage');
      }

      _showMessage(
        message.toString(),
        error: response['success'] == false,
      );

      await _loadData();
    } catch (e) {
      if (mounted) {
        _showMessage('ارسال شارژ ناموفق بود: $e', error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 23),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unitCard(Map<String, dynamic> unit) {
    final id = _unitId(unit);
    final selected = _selectedUnitIds.contains(id);
    final paid = _isPaid(unit);
    final notified = _isNotified(unit);
    final eligible = _canSelect(unit);

    final status = paid
        ? 'پرداخت‌شده'
        : notified
        ? 'شارژ ارسال شده'
        : 'آماده ارسال';

    final statusColor = paid
        ? Colors.green
        : notified
        ? Colors.orange
        : _primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: eligible ? (value) => _toggleUnit(unit, value) : null,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: _purpleColor,
        title: Row(
          children: [
            Expanded(
              child: Text(
                _unitName(unit),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              '${_formatNumber(_unitTotal(unit))} تومان',
              style: const TextStyle(
                color: _purpleColor,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _detail(
                    Icons.square_foot,
                    'متراژ: ${_formatNumber(unit['area'])}',
                  ),
                  _detail(
                    Icons.people_outline,
                    'نفرات: ${_text(unit['people_count'], '0')}',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_toBool(unit['send_sms'])) ...[
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.sms_outlined,
                      size: 15,
                      color: _primaryColor,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'پیامک ثبت شده',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
              if (_text(unit['financial_document_number'], '') != '')
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    'شماره سند: ${unit['financial_document_number']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _eligibleCount > 0 &&
        _selectedUnitIds.length == _eligibleCount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text('پیش‌نمایش و توزیع شارژ'),
        actions: [
          IconButton(
            tooltip: 'بروزرسانی',
            onPressed: _loading || _sending ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: _units.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 140),
            Icon(
              Icons.home_work_outlined,
              size: 65,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Center(
              child: Text('اطلاعاتی برای نمایش واحدها وجود ندارد.'),
            ),
          ],
        )
            : ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Text(
              _text(
                widget.calculationName ??
                    (_data['calculation'] is Map
                        ? (_data['calculation'] as Map)['name']
                        : null),
                'محاسبه شارژ شماره ${widget.calculationId}',
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _summaryCard(
                  title: 'تعداد واحدها',
                  value: '${_units.length}',
                  icon: Icons.apartment,
                  color: _primaryColor,
                ),
                const SizedBox(width: 10),
                _summaryCard(
                  title: 'قابل ارسال',
                  value: '$_eligibleCount',
                  icon: Icons.mark_email_unread_outlined,
                  color: _purpleColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'جمع مبالغ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _amountRow('مجموع همه واحدها', _allTotal),
                  const SizedBox(height: 6),
                  _amountRow(
                    'مجموع واحدهای انتخاب‌شده',
                    _selectedTotal,
                    highlight: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: allSelected,
              onChanged: _toggleAll,
              activeColor: _purpleColor,
              title: const Text(
                'انتخاب همه واحدهای قابل ارسال',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'واحدهای پرداخت‌شده یا دارای شارژ ارسال‌شده قابل انتخاب نیستند.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const Divider(),
            ..._units.map(_unitCard),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: _primaryColor.withValues(alpha: 0.07),
              child: CheckboxListTile(
                value: _sendSms,
                onChanged: _sending
                    ? null
                    : (value) {
                  setState(() {
                    _sendSms = value ?? false;
                  });
                },
                activeColor: _primaryColor,
                secondary: const Icon(
                  Icons.sms_outlined,
                  color: _primaryColor,
                ),
                title: const Text(
                  'درخواست ارسال پیامک',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'هزینه و نتیجه ارسال پیامک تابع سرویس پیامک و پاسخ سرور است.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _sending ? null : _sendCharges,
                style: FilledButton.styleFrom(
                  backgroundColor: _purpleColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: _sending
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.send),
                label: Text(
                  _sending
                      ? 'در حال ارسال...'
                      : 'تأیید و ارسال شارژ '
                      '(${_selectedUnitIds.length} واحد)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _amountRow(
      String label,
      double amount, {
        bool highlight = false,
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          '${_formatNumber(amount)} تومان',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: highlight ? _purpleColor : null,
          ),
        ),
      ],
    );
  }
}
