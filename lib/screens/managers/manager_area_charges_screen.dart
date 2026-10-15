
import 'package:flutter/material.dart';

import '../../services/manager_area_charge_services.dart';
import 'manager_area_charge_units_screen.dart';

class ManagerAreaChargesScreen extends StatefulWidget {
  const ManagerAreaChargesScreen({super.key});

  @override
  State<ManagerAreaChargesScreen> createState() =>
      _ManagerAreaChargesScreenState();
}

class _ManagerAreaChargesScreenState
    extends State<ManagerAreaChargesScreen> {
  static const Color primaryColor = Color(0xff00ACC1);
  static const Color secondaryColor = Color(0xff610DB5);

  final ManagerAreaChargeService _service =
  ManagerAreaChargeService();

  List<Map<String, dynamic>> _charges = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCharges();
  }

  Future<void> _loadCharges() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final result = await _service.getCharges();

      if (!mounted) return;

      setState(() {
        _charges = result
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _value(
      Map<String, dynamic> item,
      List<String> keys, {
        String fallback = '',
      }) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  int _intValue(
      Map<String, dynamic> item,
      List<String> keys,
      ) {
    for (final key in keys) {
      final value = item[key];

      if (value is num) return value.toInt();

      if (value != null) {
        final parsed = int.tryParse(
          _latinDigits(value.toString()).replaceAll(',', '').trim(),
        );
        if (parsed != null) return parsed;
      }
    }
    return 0;
  }

  String _latinDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';

    var result = value;

    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(persian[i], '$i');
      result = result.replaceAll(arabic[i], '$i');
    }

    return result;
  }

  String _persianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }

    return result;
  }

  String _money(dynamic value) {
    final raw = _latinDigits(value?.toString() ?? '0')
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .trim();

    final number = num.tryParse(raw) ?? 0;
    final text = number.toInt().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      buffer.write(text[i]);

      final remaining = text.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    return _persianDigits(buffer.toString());
  }

  Future<void> _deleteCharge(
      Map<String, dynamic> charge,
      ) async {
    final id = _intValue(charge, ['id', 'pk']);

    if (id <= 0) {
      _showMessage('شناسه شارژ معتبر نیست.');
      return;
    }

    final name = _value(
      charge,
      ['name'],
      fallback: 'بدون نام',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف شارژ'),
        content: Text(
          'آیا از حذف شارژ «$name» مطمئن هستید؟',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteCharge(id);

      if (!mounted) return;

      _showMessage('شارژ با موفقیت حذف شد.');
      await _loadCharges();
    } catch (e) {
      if (!mounted) return;
      _showMessage('حذف شارژ انجام نشد: $e');
    }
  }

  // اصلاح اصلی: صفحه واحدها charge و service دریافت می‌کند.
  Future<void> _openUnits(
      Map<String, dynamic> charge,
      ) async {
    final id = _intValue(charge, ['id', 'pk']);

    if (id <= 0) {
      _showMessage('شناسه شارژ معتبر نیست.');
      return;
    }

    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerAreaChargeUnitsScreen(
          charge: Map<String, dynamic>.from(charge),
          service: _service,
        ),
      ),
    );

    if (!mounted) return;

    await _loadCharges();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          title: const Text('مدیریت شارژ متراژی'),
          actions: [
            IconButton(
              tooltip: 'بارگذاری مجدد',
              onPressed: _loading ? null : _loadCharges,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              const Text(
                'دریافت فهرست شارژها با خطا مواجه شد.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadCharges,
                icon: const Icon(Icons.refresh),
                label: const Text('تلاش مجدد'),
              ),
            ],
          ),
        ),
      );
    }

    if (_charges.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCharges,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 150),
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Center(
              child: Text('هنوز شارژ متراژی ثبت نشده است.'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCharges,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _charges.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final charge = _charges[index];

          final name = _value(
            charge,
            ['name'],
            fallback: 'شارژ متراژی',
          );

          final id = _intValue(charge, ['id', 'pk']);
          final areaAmount = _intValue(
            charge,
            ['area_amount', 'areaAmount'],
          );
          final otherCost = _intValue(
            charge,
            ['other_cost_amount', 'otherCostAmount'],
          );
          final unitCount = _intValue(
            charge,
            ['unit_count', 'unitCount'],
          );

          final status = _value(
            charge,
            ['status'],
            fallback: 'نامشخص',
          );

          final deadline = _value(
            charge,
            [
              'payment_deadline',
              'payment_deadline_date',
              'paymentDeadline',
            ],
            fallback: 'تعیین نشده',
          );

          final finalized =
              charge['is_finalized'] == true ||
                  charge['is_finalized'] == 1;

          return Card(
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                    secondaryColor.withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.square_foot,
                      color: secondaryColor,
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'شناسه: ${_persianDigits(id.toString())}',
                    ),
                  ),
                  trailing: _statusChip(status, finalized),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _infoRow(
                        Icons.square_foot,
                        'مبلغ هر متر مربع',
                        '${_money(areaAmount)} تومان',
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        Icons.add_card,
                        'هزینه جانبی',
                        '${_money(otherCost)} تومان',
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        Icons.apartment,
                        'تعداد واحد',
                        _persianDigits(unitCount.toString()),
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        Icons.event,
                        'مهلت پرداخت',
                        deadline,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceAround,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      TextButton.icon(
                        onPressed: () => _openUnits(charge),
                        icon: const Icon(
                          Icons.apartment,
                          size: 18,
                        ),
                        label: const Text('مدیریت واحدها'),
                      ),
                      TextButton.icon(
                        onPressed: () => _deleteCharge(charge),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                        ),
                        label: const Text('حذف'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      children: [
        const SizedBox(width: 0),
        Icon(icon, size: 18, color: primaryColor),
        const SizedBox(width: 8),
        Expanded(child: Text(title)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String status, bool finalized) {
    final color = finalized
        ? Colors.green
        : status == 'cancelled'
        ? Colors.red
        : Colors.orange;

    final label = finalized
        ? 'نهایی شده'
        : status == 'draft'
        ? 'پیش‌نویس'
        : status == 'calculated'
        ? 'محاسبه شده'
        : status == 'cancelled'
        ? 'لغو شده'
        : status;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
