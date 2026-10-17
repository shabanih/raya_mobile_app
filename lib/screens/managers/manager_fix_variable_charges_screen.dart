
import 'package:flutter/material.dart';

import '../../services/manager_fix_variable_charge_service.dart';

class ManagerFixVariableChargesScreen extends StatefulWidget {
  const ManagerFixVariableChargesScreen({super.key});

  @override
  State<ManagerFixVariableChargesScreen> createState() =>
      _ManagerFixVariableChargesScreenState();
}

class _ManagerFixVariableChargesScreenState
    extends State<ManagerFixVariableChargesScreen> {
  static const Color primaryColor = Color(0xff00ACC1);
  static const Color secondaryColor = Color(0xff610DB5);

  final ManagerFixVariableChargeService _service =
  ManagerFixVariableChargeService();

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
        _charges = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _cleanError(e);
        _loading = false;
      });
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  String _stringValue(
      Map<String, dynamic> data,
      List<String> keys, {
        String fallback = '-',
      }) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  num _numberValue(
      Map<String, dynamic> data,
      List<String> keys,
      ) {
    for (final key in keys) {
      final value = data[key];

      if (value is num) return value;

      if (value != null) {
        final parsed = num.tryParse(
          value.toString().replaceAll(',', ''),
        );

        if (parsed != null) return parsed;
      }
    }

    return 0;
  }

  String _money(num value) {
    final rounded = value.round();
    final text = rounded.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);

      final remaining = text.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    return '${buffer.toString()} تومان';
  }

  bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;

    if (value is num) return value != 0;

    if (value is String) {
      switch (value.toLowerCase().trim()) {
        case 'true':
        case '1':
        case 'yes':
          return true;
        case 'false':
        case '0':
        case 'no':
          return false;
      }
    }

    return fallback;
  }

  bool _canDelete(Map<String, dynamic> charge) {
    return _asBool(charge['can_delete']);
  }

  Future<void> _deleteCharge(
      Map<String, dynamic> charge,
      ) async {
    final idValue = charge['id'];
    final id = idValue is int
        ? idValue
        : int.tryParse(idValue?.toString() ?? '');

    if (id == null) {
      _showMessage('شناسه شارژ معتبر نیست.');
      return;
    }

    if (!_canDelete(charge)) {
      _showMessage(
        'این شارژ طبق وضعیت فعلی قابل حذف نیست.',
      );
      return;
    }

    final name = _stringValue(
      charge,
      ['name', 'title'],
      fallback: 'شارژ',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'حذف شارژ',
            textAlign: TextAlign.right,
          ),
          content: Text(
            'آیا از حذف «$name» مطمئن هستید؟',
            textAlign: TextAlign.right,
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
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await _service.deleteCharge(id);

      if (!mounted) return;

      setState(() {
        _charges.removeWhere((item) {
          final itemId = item['id'];
          return itemId.toString() == id.toString();
        });
      });

      _showMessage('شارژ با موفقیت حذف شد.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(_cleanError(e));
    }
  }

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
        ),
      );
  }

  Future<void> _openCharge(
      Map<String, dynamic> charge,
      ) async {
    // صفحه جزئیات و وضعیت واحدها را در مرحله بعد اضافه می‌کنیم.
    final id = charge['id'];

    if (id == null) {
      _showMessage('شناسه شارژ معتبر نیست.');
      return;
    }

    _showMessage(
      'شارژ شماره $id انتخاب شد؛ صفحه جزئیات را در مرحله بعد متصل می‌کنیم.',
    );
  }

  Widget _buildAmount(
      String title,
      num amount,
      IconData icon,
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xffF5F7FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: secondaryColor,
              size: 21,
            ),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _money(amount),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargeCard(
      Map<String, dynamic> charge,
      ) {
    final name = _stringValue(
      charge,
      ['name', 'title'],
      fallback: 'شارژ بدون نام',
    );

    final deadline = _stringValue(
      charge,
      [
        'payment_deadline',
        'payment_deadline_date',
        'deadline',
      ],
    );

    final unitCount = _numberValue(
      charge,
      ['unit_count', 'units_count', 'total_units'],
    );

    final fixedAmount = _numberValue(
      charge,
      ['unit_fix_amount'],
    );

    final personAmount = _numberValue(
      charge,
      ['unit_variable_person_amount'],
    );

    final areaAmount = _numberValue(
      charge,
      ['unit_variable_area_amount'],
    );

    final parkingAmount = _numberValue(
      charge,
      ['extra_parking_amount'],
    );

    final canEdit = _asBool(charge['can_edit']);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openCharge(charge),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.calculate_outlined,
                      color: primaryColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'تعداد واحد: ${unitCount == 0 ? '-' : unitCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'عملیات',
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteCharge(charge);
                      } else if (value == 'details') {
                        _openCharge(charge);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text('جزئیات و واحدها'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        enabled: _canDelete(charge),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'حذف شارژ',
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildAmount(
                    'ثابت هر واحد',
                    fixedAmount,
                    Icons.home_work_outlined,
                  ),
                  const SizedBox(width: 7),
                  _buildAmount(
                    'هر نفر',
                    personAmount,
                    Icons.people_outline,
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  _buildAmount(
                    'هر متر',
                    areaAmount,
                    Icons.square_foot,
                  ),
                  const SizedBox(width: 7),
                  _buildAmount(
                    'پارکینگ اضافه',
                    parkingAmount,
                    Icons.local_parking_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.event_outlined,
                    color: Colors.black54,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'مهلت پرداخت: $deadline',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  if (canEdit)
                    const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: primaryColor,
                    ),
                  const SizedBox(width: 4),
                  const Text(
                    'مشاهده',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.chevron_left,
                    color: primaryColor,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
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
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
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
              size: 65,
              color: Colors.black26,
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'هنوز شارژ ثابتی و متغیری ثبت نشده است.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCharges,
      color: primaryColor,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(
          top: 8,
          bottom: 90,
        ),
        itemCount: _charges.length,
        itemBuilder: (context, index) {
          return _buildChargeCard(_charges[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF4F6F9),
        appBar: AppBar(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          title: const Text(
            'شارژ ثابت و متغیر',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'تازه‌سازی',
              onPressed: _loadCharges,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          onPressed: () {
            _showMessage(
              'فرم ثبت شارژ را در مرحله بعد اضافه می‌کنیم.',
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('ثبت شارژ جدید'),
        ),
      ),
    );
  }
}
