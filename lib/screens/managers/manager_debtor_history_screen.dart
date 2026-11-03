
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/api_service.dart';
import '../../services/manager_debtor_report_service.dart';

class ManagerDebtorHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> debtor;

  const ManagerDebtorHistoryScreen({
    super.key,
    required this.debtor,
  });

  @override
  State<ManagerDebtorHistoryScreen> createState() =>
      _ManagerDebtorHistoryScreenState();
}

class _ManagerDebtorHistoryScreenState
    extends State<ManagerDebtorHistoryScreen> {

  static const Color primaryColor = Color(0xFF00ACC1);
  static const Color secondaryColor = Color(0xFF610DB5);

  late final ManagerDebtorReportService _service;

  bool _loading = true;
  String? _error;

  Map<String, dynamic> _unit = {};
  Map<String, dynamic> _debtor = {};
  Map<String, dynamic> _summary = {};

  List<Map<String, dynamic>> _monthly = [];
  List<Map<String, dynamic>> _civil = [];
  List<Map<String, dynamic>> _sewage = [];

  @override
  void initState() {
    super.initState();

    _service = ManagerDebtorReportService(
      apiService: ApiService(),
    );

    _loadHistory();
  }

  // =====================================================
  // تبدیل عدد
  // =====================================================

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(
      value?.toString()
          .replaceAll(',', '')
          .replaceAll('٬', '')
          .trim() ??
          '',
    ) ?? 0;
  }

  // =====================================================
  // تبدیل اعداد به فارسی
  // =====================================================

  String _toPersianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';

    for (int i = 0; i < 10; i++) {
      value = value.replaceAll(english[i], persian[i]);
      value = value.replaceAll(arabic[i], persian[i]);
    }

    return value;
  }

  // =====================================================
  // فرمت مبلغ
  // =====================================================

  String _money(dynamic value) {
    final amount = _toInt(value);

    final formatted = NumberFormat('#,###').format(amount);

    return '${_toPersianDigits(formatted)} تومان';
  }

  // =====================================================
  // بررسی مبلغ قابل نمایش
  // =====================================================

  bool _hasPositiveAmount(Map<String, dynamic> item) {
    return _toInt(item['amount']) > 0;
  }

  // =====================================================
  // تبدیل تاریخ میلادی به شمسی
  // =====================================================

  String _toJalaliDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '-';
    }

    final dateText = value.toString().trim();

    try {
      final date = DateTime.parse(dateText);
      final jalali = Jalali.fromDateTime(date);

      final formatted =
          '${jalali.year.toString().padLeft(4, '0')}/'
          '${jalali.month.toString().padLeft(2, '0')}/'
          '${jalali.day.toString().padLeft(2, '0')}';

      return _toPersianDigits(formatted);
    } catch (_) {
      return _toPersianDigits(dateText);
    }
  }

  // =====================================================
  // دریافت مقدار از چند کلید احتمالی
  // =====================================================

  dynamic _getValue(
      Map<String, dynamic> item,
      List<String> keys, {
        dynamic fallback,
      }) {
    for (final key in keys) {
      final value = item[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }

    return fallback;
  }

  // =====================================================
  // دریافت سوابق بدهی
  // =====================================================

  Future<void> _loadHistory() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final unitId = _toInt(widget.debtor['unit_id']);
      final debtorId = _toInt(widget.debtor['debtor_id']);
      final debtorType =
          widget.debtor['debtor_type']?.toString() ?? '';

      final result = await _service.getDebtorHistory(
        unitId: unitId,
        debtorType: debtorType,
        debtorId: debtorId,
      );

      if (!mounted) return;

      final history =
          result['history'] as Map<String, dynamic>? ?? {};

      setState(() {
        _unit = result['unit'] as Map<String, dynamic>? ?? {};
        _debtor = result['debtor'] as Map<String, dynamic>? ?? {};
        _summary = result['summary'] as Map<String, dynamic>? ?? {};

        _monthly = List<Map<String, dynamic>>.from(
          history['monthly'] ?? [],
        ).where(_hasPositiveAmount).toList();

        _civil = List<Map<String, dynamic>>.from(
          history['civil'] ?? [],
        ).where(_hasPositiveAmount).toList();

        _sewage = List<Map<String, dynamic>>.from(
          history['sewage'] ?? [],
        ).where(_hasPositiveAmount).toList();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // =====================================================
  // اطلاعات بالای صفحه
  // =====================================================

  Widget _buildHeader() {
    final unitNumber = _getValue(
      _unit,
      ['number', 'unit_number', 'unit'],
      fallback: widget.debtor['unit_number'] ?? '-',
    );

    final debtorName = _getValue(
      _debtor,
      ['name', 'debtor_name'],
      fallback: widget.debtor['debtor_name'] ?? '-',
    );

    final debtorType = _getValue(
      _debtor,
      ['type', 'debtor_type'],
      fallback: widget.debtor['debtor_type'] ?? '',
    ).toString();

    final isOwner = debtorType == 'owner';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primaryColor,
            secondaryColor,
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.apartment_rounded,
                color: Colors.white,
                size: 25,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'واحد ${_toPersianDigits(unitNumber.toString())}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOwner ? 'مالک' : 'مستأجر',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.person_outline,
                color: Colors.white70,
                size: 19,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  debtorName.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const Divider(
            color: Colors.white30,
            height: 25,
          ),

          const Text(
            'مجموع کل بدهی',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            _money(
              _summary['total_debt'] ??
                  widget.debtor['total_debt'],
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // کارت عنوان هر بخش
  // =====================================================

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required dynamic total,
  }) {
    return Row(
      children: [
        Container(
          width: 39,
          height: 39,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icon,
            color: color,
            size: 21,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${_toPersianDigits(count.toString())} مورد',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        Flexible(
          child: Text(
            _money(total),
            textAlign: TextAlign.end,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // کارت عمومی هر سابقه
  // =====================================================

  Widget _buildRecordCard({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // =====================================================
  // ردیف اطلاعات
  // =====================================================

  Widget _buildInfoRow(
      String title,
      dynamic value, {
        bool important = false,
        Color? valueColor,
      }) {
    final text = value == null || value.toString().trim().isEmpty
        ? '-'
        : value.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            flex: 6,
            child: Text(
              _toPersianDigits(text),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontSize: 12,
                fontWeight: important
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // بخش شارژ ماهیانه
  // =====================================================

  Widget _buildMonthlySection() {
    if (_monthly.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = _monthly.fold<int>(
      0,
          (sum, item) => sum + _toInt(item['amount']),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'شارژ ماهیانه',
          icon: Icons.receipt_long_rounded,
          color: primaryColor,
          count: _monthly.length,
          total: total,
        ),

        ..._monthly.map((item) {
          final description = _getValue(
            item,
            ['title', 'description', 'details', 'name'],
            fallback: 'شارژ ماهیانه',
          );

          final baseCharge = item['base_charge'] ?? 0;
          final penalty = item['penalty_amount'] ?? 0;
          final payable = item['amount'] ?? 0;

          final dueDate = _getValue(
            item,
            ['payment_deadline_date', 'due_date'],
            fallback: '-',
          );

          return _buildRecordCard(
            children: [
              _buildInfoRow(
                'شرح',
                description,
                important: true,
              ),

              const Divider(height: 12),

              _buildInfoRow(
                'اصل شارژ',
                _money(baseCharge),
              ),

              _buildInfoRow(
                'مبلغ جریمه',
                _money(penalty),
                valueColor: _toInt(penalty) > 0
                    ? Colors.red
                    : null,
              ),

              const Divider(height: 12),

              _buildInfoRow(
                'قابل پرداخت',
                _money(payable),
                important: true,
                valueColor: secondaryColor,
              ),

              _buildInfoRow(
                'تاریخ سررسید',
                _toJalaliDate(dueDate),
              ),

              if (item['created_at'] != null)
                _buildInfoRow(
                  'تاریخ ثبت',
                  _toJalaliDate(item['created_at']),
                ),
            ],
          );
        }),
      ],
    );
  }

  // =====================================================
  // بخش شارژ عمرانی
  // =====================================================

  Widget _buildCivilSection() {
    if (_civil.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = _civil.fold<int>(
      0,
          (sum, item) => sum + _toInt(item['amount']),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'شارژ عمرانی',
          icon: Icons.construction_rounded,
          color: secondaryColor,
          count: _civil.length,
          total: total,
        ),

        ..._civil.map((item) {
          final description = _getValue(
            item,
            ['title', 'description', 'details', 'name'],
            fallback: 'شارژ عمرانی',
          );

          final installment =
              item['installment_number'] ?? '-';

          final payable = item['amount'] ?? 0;
          final dueDate = item['due_date'] ?? '-';

          return _buildRecordCard(
            children: [
              _buildInfoRow(
                'شرح',
                description,
                important: true,
              ),

              const Divider(height: 12),

              _buildInfoRow(
                'شماره قسط',
                installment,
              ),

              const Divider(height: 12),

              _buildInfoRow(
                'قابل پرداخت',
                _money(payable),
                important: true,
                valueColor: secondaryColor,
              ),

              _buildInfoRow(
                'تاریخ سررسید',
                _toJalaliDate(dueDate),
              ),
            ],
          );
        }),
      ],
    );
  }

  // =====================================================
  // بخش هزینه فاضلاب
  // =====================================================

  Widget _buildSewageSection() {
    if (_sewage.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = _sewage.fold<int>(
      0,
          (sum, item) => sum + _toInt(item['amount']),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: 'هزینه فاضلاب',
          icon: Icons.water_drop_rounded,
          color: Colors.deepOrange,
          count: _sewage.length,
          total: total,
        ),

        ..._sewage.map((item) {
          final description = _getValue(
            item,
            ['title', 'description', 'details', 'name'],
            fallback: 'هزینه فاضلاب',
          );

          final installment =
              item['installment_number'] ?? '-';

          final payable = item['amount'] ?? 0;
          final dueDate = item['due_date'] ?? '-';

          return _buildRecordCard(
            children: [
              _buildInfoRow(
                'شرح',
                description,
                important: true,
              ),

              const Divider(height: 12),

              _buildInfoRow(
                'شماره قسط',
                installment,
              ),

              const Divider(height: 12),

              _buildInfoRow(
                'قابل پرداخت',
                _money(payable),
                important: true,
                valueColor: Colors.deepOrange,
              ),

              _buildInfoRow(
                'تاریخ سررسید',
                _toJalaliDate(dueDate),
              ),
            ],
          );
        }),
      ],
    );
  }

  // =====================================================
  // صفحه اصلی
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),

        appBar: AppBar(
          title: const Text(
            'سوابق بدهی',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF00ACC1),
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh),
              tooltip: 'بروزرسانی',
            ),
          ],
        ),

        body: _loading
            ? const Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        )
            : _error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 45,
                ),

                const SizedBox(height: 12),

                Text(
                  _error!,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 15),

                ElevatedButton(
                  onPressed: _loadHistory,
                  child: const Text('تلاش مجدد'),
                ),
              ],
            ),
          ),
        )
            : RefreshIndicator(
          onRefresh: _loadHistory,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),

              if (_monthly.isNotEmpty) ...[
                const SizedBox(height: 25),
                _buildMonthlySection(),
              ],

              if (_civil.isNotEmpty) ...[
                const SizedBox(height: 25),
                _buildCivilSection(),
              ],

              if (_sewage.isNotEmpty) ...[
                const SizedBox(height: 25),
                _buildSewageSection(),
              ],

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
