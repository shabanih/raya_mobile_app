
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_charge_calculation_service.dart';
import 'manager_charge_calculation_units_screen.dart'
as units_screen;

const Color _primaryColor = Color(0xFF00ACC1);
const Color _purpleColor = Color(0xFF610DB5);

const List<Map<String, String>> _basisOptions = [
  {'value': 'equal', 'label': 'مساوی بین واحدها'},
  {'value': 'area', 'label': 'بر اساس متراژ'},
  {'value': 'person', 'label': 'بر اساس تعداد نفرات'},
];

const List<Map<String, String>> _scopeOptions = [
  {'value': 'all', 'label': 'تمام واحدهای فعال'},
  {'value': 'occupied', 'label': 'واحدهای دارای ساکن'},
  {'value': 'vacant', 'label': 'واحدهای خالی'},
  {'value': 'selected', 'label': 'واحدهای انتخاب‌شده'},
];

class ManagerChargeCalculationItemsScreen extends StatefulWidget {
  final int calculationId;
  final String? calculationName;

  const ManagerChargeCalculationItemsScreen({
    super.key,
    required this.calculationId,
    this.calculationName,
  });

  @override
  State<ManagerChargeCalculationItemsScreen> createState() =>
      _ManagerChargeCalculationItemsScreenState();
}

class _ManagerChargeCalculationItemsScreenState
    extends State<ManagerChargeCalculationItemsScreen> {
  final ManagerChargeCalculationService _service =
  ManagerChargeCalculationService();

  bool _loading = true;
  bool _saving = false;

  Map<String, dynamic> _calculation = {};
  List<Map<String, dynamic>> _expenseGroups = [];
  List<Map<String, dynamic>> _maintenanceGroups = [];
  List<Map<String, dynamic>> _units = [];

  String _searchQuery = '';
  int _tabIndex = 0;

  // تعداد رکوردهای هزینه، نه تعداد سرفصل‌ها
  int get _totalExpenseRecords {
    return _expenseGroups.fold<int>(
      0,
          (total, group) {
        return total + _mapList(group['expenses']).length;
      },
    );
  }

  // ============================================================
  // شروع صفحه
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // دریافت اطلاعات
  // ============================================================

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final dynamic response =
      await _service.getCalculationItems(widget.calculationId);

      if (response is! Map) {
        throw Exception('پاسخ سرور معتبر نیست.');
      }

      final data = Map<String, dynamic>.from(response);

      if (data['success'] == false) {
        throw Exception(
          _text(data['message'], 'دریافت اطلاعات ناموفق بود.'),
        );
      }

      final calculation = _asMap(data['calculation']);
      final expenses = _mapList(data['expense_groups']);
      final maintenances = _mapList(data['maintenance_groups']);
      final units = _mapList(data['units']);

      for (final group in expenses) {
        _normalizeGroup(group, isMaintenance: false);
      }

      for (final group in maintenances) {
        _normalizeGroup(group, isMaintenance: true);
      }

      if (!mounted) return;

      setState(() {
        _calculation = calculation;
        _expenseGroups = expenses;
        _maintenanceGroups = maintenances;
        _units = units;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      _showMessage(
        'دریافت اطلاعات با خطا مواجه شد: ${_cleanError(e)}',
        isError: true,
      );
    }
  }

  void _normalizeGroup(
      Map<String, dynamic> group, {
        required bool isMaintenance,
      }) {
    group['type'] = isMaintenance ? 'maintenance' : 'expense';
    group['group_id'] = _toInt(group['group_id']);
    group['selected'] = _toBool(group['selected']);

    final basis = _text(group['basis'], 'equal');
    group['basis'] = _validBasis(basis) ? basis : 'equal';

    final scope = _text(group['scope'], 'all');
    group['scope'] = _validScope(scope) ? scope : 'all';

    final rawIds = group['selected_unit_ids'];

    group['selected_unit_ids'] = rawIds is List
        ? rawIds.map(_toInt).where((id) => id > 0).toSet().toList()
        : <int>[];

    if (!isMaintenance) {
      group['expenses'] = _mapList(group['expenses']);
    }
  }

  // ============================================================
  // ذخیره تنظیمات
  // ============================================================

  Future<void> _save() async {
    if (_saving) return;

    final allGroups = [
      ..._expenseGroups,
      ..._maintenanceGroups,
    ];

    final selectedGroups = allGroups
        .where((group) => _toBool(group['selected']))
        .toList();

    if (selectedGroups.isEmpty) {
      _showMessage(
        'حداقل یک گروه هزینه یا تعمیرات را انتخاب کنید.',
        isError: true,
      );
      return;
    }

    for (final group in selectedGroups) {
      final scope = _text(group['scope'], 'all');
      final ids = _selectedUnitIds(group);

      if (!_validBasis(_text(group['basis'], 'equal'))) {
        _showMessage('مبنای تسهیم معتبر نیست.', isError: true);
        return;
      }

      if (!_validScope(scope)) {
        _showMessage('محدوده واحدها معتبر نیست.', isError: true);
        return;
      }

      if (scope == 'selected' && ids.isEmpty) {
        _showMessage(
          'برای گروه «${_groupTitle(group)}» حداقل یک واحد انتخاب کنید.',
          isError: true,
        );

        await _openUnitSelector(group);
        return;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'ذخیره تنظیمات',
          textAlign: TextAlign.right,
        ),
        content: Text(
          'تنظیمات تسهیم ${_formatNumber(selectedGroups.length)} '
              'گروه انتخاب‌شده ذخیره شود؟\n\n'
              'این عملیات فقط تنظیمات محاسبه را ذخیره می‌کند و '
              'شارژ یا پیامک ارسال نمی‌کند.',
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
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
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final groupsPayload = <Map<String, dynamic>>[];

    for (final group in allGroups) {
      groupsPayload.add({
        'type': _text(group['type'], 'expense'),
        'group_id': _toInt(group['group_id']),
        'selected': _toBool(group['selected']),
        'basis': _text(group['basis'], 'equal'),
        'scope': _text(group['scope'], 'all'),
        'selected_unit_ids': _selectedUnitIds(group),
      });
    }

    setState(() => _saving = true);

    try {
      final dynamic response = await _service.saveCalculationItems(
        widget.calculationId,
        groups: groupsPayload,
      );

      if (response is! Map) {
        throw Exception('پاسخ ذخیره‌سازی سرور معتبر نیست.');
      }

      final data = Map<String, dynamic>.from(response);

      if (data['success'] != true) {
        throw Exception(
          _text(data['message'], 'ذخیره تنظیمات ناموفق بود.'),
        );
      }

      if (!mounted) return;

      _showMessage(
        _text(data['message'], 'تنظیمات با موفقیت ذخیره شد.'),
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'ذخیره تنظیمات ناموفق بود: ${_cleanError(e)}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // ============================================================
  // رفتن به صفحه نمایش واحدها و اعلان شارژ
  // فقط جابه‌جایی به صفحه؛ بدون ارسال پیامک یا اعلان
  // ============================================================

  Future<void> _goToUnitsScreen() async {
    if (_saving) return;

    final title = _text(
      _calculation['name'],
      widget.calculationName ?? 'محاسبه شارژ',
    );

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            units_screen.ManagerChargeCalculationUnitsScreen(
              calculationId: widget.calculationId,
              calculationName: title,
            ),
      ),
    );
  }

  // ============================================================
  // انتخاب واحدهای مشخص
  // ============================================================

  Future<void> _openUnitSelector(
      Map<String, dynamic> group,
      ) async {
    if (_units.isEmpty) {
      _showMessage(
        'فهرست واحدهای فعال ساختمان دریافت نشده است.',
        isError: true,
      );
      return;
    }

    final initialIds = _selectedUnitIds(group).toSet();

    final result = await showDialog<Set<int>>(
      context: context,
      builder: (dialogContext) {
        final selectedIds = Set<int>.from(initialIds);
        String query = '';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredUnits = _units.where((unit) {
              final name = _fa(unit['unit']);
              return name.toLowerCase().contains(query.toLowerCase());
            }).toList();

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: const Text(
                  'انتخاب واحدها',
                  textAlign: TextAlign.right,
                ),
                content: SizedBox(
                  width: 420,
                  height: 420,
                  child: Column(
                    children: [
                      Text(
                        _groupTitle(group),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        decoration: InputDecoration(
                          hintText: 'جست‌وجوی شماره واحد',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setDialogState(() => query = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                selectedIds.addAll(
                                  filteredUnits.map(
                                        (unit) => _toInt(unit['id']),
                                  ),
                                );
                              });
                            },
                            child: const Text('انتخاب نتایج'),
                          ),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                selectedIds.removeAll(
                                  filteredUnits.map(
                                        (unit) => _toInt(unit['id']),
                                  ),
                                );
                              });
                            },
                            child: const Text('لغو نتایج'),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_formatNumber(selectedIds.length)} '
                              'واحد انتخاب شده',
                          style: const TextStyle(
                            color: _purpleColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: filteredUnits.isEmpty
                            ? const Center(
                          child: Text('واحدی پیدا نشد.'),
                        )
                            : ListView.builder(
                          itemCount: filteredUnits.length,
                          itemBuilder: (context, index) {
                            final unit = filteredUnits[index];
                            final id = _toInt(unit['id']);
                            final name = _fa(unit['unit']).isEmpty
                                ? 'بدون شماره'
                                : _fa(unit['unit']);

                            return CheckboxListTile(
                              value: selectedIds.contains(id),
                              activeColor: _primaryColor,
                              controlAffinity:
                              ListTileControlAffinity.leading,
                              title: Text(
                                'واحد $name',
                                textAlign: TextAlign.right,
                              ),
                              onChanged: (checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    selectedIds.add(id);
                                  } else {
                                    selectedIds.remove(id);
                                  }
                                });
                              },
                            );
                          },
                        ),
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
                      backgroundColor: _primaryColor,
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext, selectedIds);
                    },
                    child: const Text('تأیید انتخاب'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null || !mounted) return;

    setState(() {
      group['selected_unit_ids'] = result.toList();
      group['scope'] = 'selected';
    });
  }

  // ============================================================
  // تغییر تنظیمات
  // ============================================================

  void _toggleGroup(
      Map<String, dynamic> group,
      bool? value,
      ) {
    setState(() {
      group['selected'] = value ?? false;
    });
  }

  void _changeBasis(
      Map<String, dynamic> group,
      String? value,
      ) {
    if (value == null || !_validBasis(value)) return;

    setState(() {
      group['basis'] = value;
    });
  }

  Future<void> _changeScope(
      Map<String, dynamic> group,
      String? value,
      ) async {
    if (value == null || !_validScope(value)) return;

    setState(() {
      group['scope'] = value;
    });

    if (value == 'selected') {
      await _openUnitSelector(group);
    }
  }

  // ============================================================
  // رابط کاربری
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'انتخاب هزینه‌ و محاسبه',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'بارگذاری مجدد',
            onPressed: _loading || _saving ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          color: _primaryColor,
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadData,
        child: _buildBody(),
      ),
      bottomNavigationBar: _loading ? null : _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    final title = _text(
      _calculation['name'],
      widget.calculationName ?? 'محاسبه شارژ',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        _buildCalculationHeader(title),
        const SizedBox(height: 12),
        _buildSummary(),
        const SizedBox(height: 12),
        _buildTabs(),
        const SizedBox(height: 12),
        _buildSearchBox(),
        const SizedBox(height: 12),
        if (_tabIndex == 0) ...[
          if (_filteredExpenseGroups.isEmpty)
            _emptyState('هزینه‌ای در بازه این محاسبه وجود ندارد.')
          else
            ..._filteredExpenseGroups.map(_buildExpenseCard),
        ] else ...[
          if (_filteredMaintenanceGroups.isEmpty)
            _emptyState('تعمیراتی در بازه این محاسبه وجود ندارد.')
          else
            ..._filteredMaintenanceGroups.map(_buildMaintenanceCard),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCalculationHeader(String title) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE0F7FA),
                  child: Icon(
                    Icons.calculate_outlined,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
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
              'شروع بازه',
              _formatDate(_calculation['start_date']),
            ),
            _infoRow(
              'پایان بازه',
              _formatDate(_calculation['end_date']),
            ),
            _infoRow(
              'مهلت پرداخت',
              _formatDate(_calculation['payment_deadline']),
            ),
            _infoRow(
              'وضعیت محاسبه',
              _calculationStatus(_calculation['status']),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // خلاصه مبالغ
  // ============================================================

  Widget _buildSummary() {
    final expenseTotal = _expenseGroups.fold<double>(
      0,
          (sum, group) => sum + _toDouble(group['total_amount']),
    );

    final maintenanceTotal = _maintenanceGroups.fold<double>(
      0,
          (sum, group) => sum + _toDouble(group['total_amount']),
    );

    return Row(
      children: [
        Expanded(
          child: _summaryTile(
            title: 'مجموع هزینه‌ها',
            value: _formatNumber(expenseTotal),
            icon: Icons.receipt_long_outlined,
            color: _primaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _summaryTile(
            title: 'مجموع تعمیرات',
            value: _formatNumber(maintenanceTotal),
            icon: Icons.handyman_outlined,
            color: _purpleColor,
          ),
        ),
      ],
    );
  }

  Widget _summaryTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$value تومان',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // تب‌ها: تعداد رکوردهای واقعی هزینه و تعداد تعمیرات
  // ============================================================

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              label:
              'هزینه‌ها (${_formatNumber(_totalExpenseRecords)})',
              selected: _tabIndex == 0,
              onTap: () => setState(() => _tabIndex = 0),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _tabButton(
              label:
              'تعمیرات (${_formatNumber(_maintenanceGroups.length)})',
              selected: _tabIndex == 1,
              onTap: () => setState(() => _tabIndex = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? _primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // جست‌وجوی راست‌چین
  // ============================================================

  Widget _buildSearchBox() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: TextField(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        onChanged: (value) {
          setState(() => _searchQuery = value.trim());
        },
        decoration: InputDecoration(
          hintText: _tabIndex == 0
              ? 'جست‌وجوی هزینه'
              : 'جست‌وجوی هزینه تعمیرات',
          hintTextDirection: TextDirection.rtl,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredExpenseGroups {
    if (_searchQuery.isEmpty) return _expenseGroups;

    final query = _searchQuery.toLowerCase();

    return _expenseGroups.where((group) {
      if (_groupTitle(group).toLowerCase().contains(query)) {
        return true;
      }

      return _mapList(group['expenses']).any((expense) {
        return _text(expense['title'], '')
            .toLowerCase()
            .contains(query);
      });
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredMaintenanceGroups {
    if (_searchQuery.isEmpty) return _maintenanceGroups;

    final query = _searchQuery.toLowerCase();

    return _maintenanceGroups.where((group) {
      return _groupTitle(group).toLowerCase().contains(query);
    }).toList();
  }

  // ============================================================
  // کارت هزینه‌ها
  // ============================================================

  Widget _buildExpenseCard(Map<String, dynamic> group) {
    final expenses = _mapList(group['expenses']);
    final paid = _toInt(group['paid_count']);
    final unpaid = _toInt(group['unpaid_count']);
    final inactive = _toInt(group['inactive_count']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _toBool(group['selected'])
              ? _primaryColor.withValues(alpha: 0.65)
              : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: _toBool(group['selected']),
                  activeColor: _primaryColor,
                  onChanged: (value) => _toggleGroup(group, value),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _groupTitle(group),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_formatNumber(expenses.length)} هزینه',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),

                // دکمه کوچک چشم برای نمایش جزئیات
                IconButton(
                  tooltip: 'مشاهده جزئیات هزینه‌ها',
                  onPressed: () => _showExpenseDetails(group),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.visibility_outlined,
                    color: _purpleColor,
                    size: 20,
                  ),
                ),
              ],
            ),
            const Divider(),
            _infoRow(
              'مجموع مبلغ',
              '${_formatNumber(group['total_amount'])} تومان',
              valueColor: _purpleColor,
            ),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.start,
              spacing: 6,
              runSpacing: 6,
              children: [
                _statusChip(
                  'پرداخت‌شده: ${_formatNumber(paid)}',
                  Colors.green,
                ),
                _statusChip(
                  'پرداخت‌نشده: ${_formatNumber(unpaid)}',
                  Colors.orange,
                ),
                if (inactive > 0)
                  _statusChip(
                    'غیرفعال: ${_formatNumber(inactive)}',
                    Colors.grey,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _buildAllocationControls(group),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // جزئیات هزینه‌ها
  // ============================================================

  void _showExpenseDetails(Map<String, dynamic> group) {
    final expenses = _mapList(group['expenses']);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            'جزئیات ${_groupTitle(group)}',
            textAlign: TextAlign.right,
          ),
          content: SizedBox(
            width: 500,
            height: 420,
            child: expenses.isEmpty
                ? const Center(child: Text('جزئیاتی وجود ندارد.'))
                : ListView.separated(
              itemCount: expenses.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final expense = expenses[index];
                final isPaid = _toBool(expense['is_paid']);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _text(expense['title'], 'هزینه'),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _infoRow(
                      'مبلغ',
                      '${_formatNumber(expense['amount'])} تومان',
                    ),
                    _infoRow(
                      'تاریخ هزینه',
                      _formatDate(expense['date']),
                    ),
                    _infoRow(
                      'شماره سند',
                      _fa(
                        expense['financial_document_number'] ??
                            expense['doc_no'] ??
                            'ثبت نشده',
                      ),
                    ),
                    _infoRow(
                      'واحد مرتبط',
                      _fa(expense['unit'] ?? 'عمومی'),
                    ),
                    _infoRow(
                      'دریافت‌کننده',
                      _text(expense['receiver_name'], 'ثبت نشده'),
                    ),
                    _infoRow(
                      'وضعیت پرداخت',
                      isPaid ? 'پرداخت‌شده' : 'پرداخت‌نشده',
                      valueColor:
                      isPaid ? Colors.green : Colors.orange,
                    ),
                    _infoRow(
                      'وضعیت',
                      _toBool(expense['is_active'])
                          ? 'فعال'
                          : 'غیرفعال',
                    ),
                    if (expense['payment_date'] != null)
                      _infoRow(
                        'تاریخ پرداخت',
                        _formatDate(expense['payment_date']),
                      ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('بستن'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // کارت تعمیرات
  // فقط مبلغ، تاریخ شروع، تاریخ پایان و وضعیت پرداخت
  // ============================================================

  Widget _buildMaintenanceCard(Map<String, dynamic> group) {
    final isPaid = _toBool(group['is_paid']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _toBool(group['selected'])
              ? _purpleColor.withValues(alpha: 0.65)
              : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: _toBool(group['selected']),
                  activeColor: _purpleColor,
                  onChanged: (value) => _toggleGroup(group, value),
                ),
                Expanded(
                  child: Text(
                    _groupTitle(group),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.handyman_outlined,
                  color: _purpleColor,
                  size: 28,
                ),
              ],
            ),
            const Divider(),
            _infoRow(
              'مبلغ تعمیرات',
              '${_formatNumber(group['total_amount'])} تومان',
              valueColor: _purpleColor,
            ),
            _infoRow(
              'شروع تعمیرات',
              _formatDate(group['date']),
            ),
            _infoRow(
              'پایان تعمیرات',
              _formatDate(group['maintenance_end_date']),
            ),
            _infoRow(
              'وضعیت پرداخت',
              isPaid ? 'پرداخت‌شده' : 'پرداخت‌نشده',
              valueColor: isPaid ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 10),
            _buildAllocationControls(group),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // تنظیمات تسهیم
  // محدوده واحدها و مبنای تسهیم در دو ردیف راست‌چین
  // ============================================================

  Widget _buildAllocationControls(Map<String, dynamic> group) {
    final enabled = _toBool(group['selected']);
    final scope = _text(group['scope'], 'all');
    final basis = _text(group['basis'], 'equal');
    final selectedIds = _selectedUnitIds(group);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // محدوده واحدها
            DropdownButtonFormField<String>(
              value: _validScope(scope) ? scope : 'all',
              isExpanded: true,
              alignment: AlignmentDirectional.centerStart,
              decoration: const InputDecoration(
                labelText: 'محدوده واحدها',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
              ),
              items: _scopeOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  alignment: AlignmentDirectional.centerStart,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      option['label']!,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
              onChanged:
              enabled ? (value) => _changeScope(group, value) : null,
            ),
            const SizedBox(height: 12),

            // مبنای تسهیم
            DropdownButtonFormField<String>(
              value: _validBasis(basis) ? basis : 'equal',
              isExpanded: true,
              alignment: AlignmentDirectional.centerStart,
              decoration: const InputDecoration(
                labelText: 'مبنای تسهیم',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
              ),
              items: _basisOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  alignment: AlignmentDirectional.centerStart,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      option['label']!,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),
              onChanged:
              enabled ? (value) => _changeBasis(group, value) : null,
            ),

            if (scope == 'selected') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedIds.isEmpty
                          ? 'هنوز واحدی انتخاب نشده است.'
                          : '${_formatNumber(selectedIds.length)} '
                          'واحد انتخاب شده',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: selectedIds.isEmpty
                            ? Colors.red
                            : _purpleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed:
                    enabled ? () => _openUnitSelector(group) : null,
                    icon: const Icon(Icons.apartment),
                    label: const Text('انتخاب واحدها'),
                  ),
                ],
              ),
            ],

            if (!enabled)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'برای فعال‌شدن تنظیمات، ابتدا گروه را انتخاب کنید.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // دکمه‌های پایین صفحه
  // ============================================================

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _saving
                      ? 'در حال ذخیره...'
                      : 'ذخیره محاسبه',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _saving ? null : _goToUnitsScreen,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _purpleColor,
                  side: const BorderSide(color: _purpleColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.apartment_outlined),
                label: const Text(
                  'نمایش واحدها و اعلان شارژ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ابزارهای رابط کاربری
  // ============================================================

  Widget _infoRow(
      String label,
      String value, {
        Color? valueColor,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 50,
            color: Colors.black38,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // توابع کمکی
  // ============================================================

  String _groupTitle(Map<String, dynamic> group) {
    if (_text(group['type'], '') == 'maintenance') {
      return _text(group['title'], 'تعمیرات');
    }

    return _text(group['category'], 'هزینه عمومی');
  }

  List<int> _selectedUnitIds(Map<String, dynamic> group) {
    final value = group['selected_unit_ids'];

    if (value is! List) return <int>[];

    return value.map(_toInt).where((id) => id > 0).toSet().toList();
  }

  bool _validBasis(String value) {
    return const {'equal', 'area', 'person'}.contains(value);
  }

  bool _validScope(String value) {
    return const {'all', 'occupied', 'vacant', 'selected'}.contains(value);
  }

  String _calculationStatus(dynamic value) {
    switch (_text(value, '')) {
      case 'draft':
        return 'پیش‌نویس';
      case 'calculated':
        return 'محاسبه‌شده';
      case 'finalized':
        return 'نهایی‌شده';
      case 'cancelled':
        return 'لغوشده';
      default:
        return _fa(_text(value, 'نامشخص'));
    }
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'ثبت نشده';
    }

    try {
      final date = DateTime.parse(value.toString());
      final jalali = Jalali.fromDateTime(date);

      final formatted =
          '${jalali.year}/'
          '${jalali.month.toString().padLeft(2, '0')}/'
          '${jalali.day.toString().padLeft(2, '0')}';

      return _toPersianDigits(formatted);
    } catch (_) {
      return _toPersianDigits(value.toString());
    }
  }

  String _formatNumber(dynamic value) {
    final number = _toDouble(value);

    final text = number.toStringAsFixed(
      number == number.truncateToDouble() ? 0 : 2,
    );

    final parts = text.split('.');
    final integerPart = parts[0];
    final buffer = StringBuffer();

    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(integerPart[i]);
    }

    final formatted = parts.length > 1 && parts[1] != '00'
        ? '${buffer.toString()}.${parts[1]}'
        : buffer.toString();

    return _toPersianDigits(formatted);
  }

  String _toPersianDigits(String value) {
    const englishDigits = '0123456789';
    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';

    return value.replaceAllMapped(
      RegExp(r'[0-9]'),
          (match) =>
      persianDigits[englishDigits.indexOf(match.group(0)!)],
    );
  }

  String _fa(dynamic value) {
    return _toPersianDigits(value?.toString() ?? '');
  }

  String _text(dynamic value, [String fallback = '']) {
    if (value == null) return fallback;

    final result = value.toString().trim();

    if (result.isEmpty || result.toLowerCase() == 'null') {
      return fallback;
    }

    return result;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(
      value?.toString().replaceAll(',', '').trim() ?? '',
    ) ??
        0;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(
      value?.toString().replaceAll(',', '').trim() ?? '',
    ) ??
        0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().toLowerCase().trim();

    return text == 'true' || text == '1' || text == 'yes';
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
          backgroundColor:
          isError ? Colors.red.shade700 : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
