
import 'package:flutter/material.dart';

import '../../services/manager_sewage_charge_list_service.dart';
import 'manager_sewage_charge_installments_list_screen.dart';

class ManagerSewageChargeUnitsListScreen extends StatefulWidget {
  final int sewageId;
  final String sewageName;

  const ManagerSewageChargeUnitsListScreen({
    super.key,
    required this.sewageId,
    required this.sewageName,
  });

  @override
  State<ManagerSewageChargeUnitsListScreen> createState() =>
      _ManagerSewageChargeUnitsListScreenState();
}

class _ManagerSewageChargeUnitsListScreenState
    extends State<ManagerSewageChargeUnitsListScreen> {
  static const Color teal = Color(0xFF00ACC1);
  static const Color purple = Color(0xFF610DB5);
  static const Color backgroundColor = Color(0xFFF6F7FB);

  final ManagerSewageChargeListService _service =
  ManagerSewageChargeListService();

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _units = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.getUnits(
        sewageId: widget.sewageId,
        search: _searchController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _units = result
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = value.toString().replaceAll(',', '').trim();
    return int.tryParse(text) ?? 0;
  }

  String _money(dynamic value) {
    final amount = _toInt(value);
    final text = amount.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);

      final remaining = text.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    return '${_fa(buffer.toString())} تومان';
  }

  String _fa(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    for (int i = 0; i < english.length; i++) {
      value = value.replaceAll(english[i], persian[i]);
    }

    return value;
  }

  String _ownerName(Map<String, dynamic> unit) {
    final value = unit['owner_name'] ??
        unit['owner_full_name'] ??
        unit['owner'];

    if (value == null || value.toString().trim().isEmpty) {
      return 'مالک مشخص نشده';
    }

    // اگر API به جای نام، آبجکت مالک برگرداند.
    if (value is Map) {
      final firstName = value['first_name'] ?? '';
      final lastName = value['last_name'] ?? '';
      final fullName = '$firstName $lastName'.trim();

      return fullName.isEmpty ? 'مالک مشخص نشده' : fullName;
    }

    return value.toString().trim();
  }

  List<dynamic> _installments(Map<String, dynamic> unit) {
    final value = unit['installments'];
    return value is List ? value : [];
  }

  int _installmentsTotal(Map<String, dynamic> unit) {
    if (unit['installments_total_amount'] != null) {
      return _toInt(unit['installments_total_amount']);
    }

    int total = 0;

    for (final item in _installments(unit)) {
      if (item is! Map) continue;

      final number = _toInt(item['installment_number']);

      // قسط صفر، پیش‌پرداخت است و در مجموع اقساط محاسبه نمی‌شود.
      if (number > 0) {
        total += _toInt(item['amount']);
      }
    }

    return total;
  }

  int _prepayment(Map<String, dynamic> unit) {
    if (unit['prepayment'] != null) {
      return _toInt(unit['prepayment']);
    }

    if (unit['prepayment_per_unit'] != null) {
      return _toInt(unit['prepayment_per_unit']);
    }

    if (unit['prepayment_amount'] != null) {
      return _toInt(unit['prepayment_amount']);
    }

    for (final item in _installments(unit)) {
      if (item is Map &&
          _toInt(item['installment_number']) == 0) {
        return _toInt(
          item['prepayment_per_unit'] ?? item['amount'],
        );
      }
    }

    return 0;
  }

  int _totalAmount(Map<String, dynamic> unit) {
    if (unit['total_charge_amount'] != null) {
      return _toInt(unit['total_charge_amount']);
    }

    return _prepayment(unit) + _installmentsTotal(unit);
  }

  int _paidAmount(Map<String, dynamic> unit) {
    if (unit['paid_amount'] != null) {
      return _toInt(unit['paid_amount']);
    }

    int total = 0;

    for (final item in _installments(unit)) {
      if (item is Map && item['is_paid'] == true) {
        total += _toInt(item['amount']);
      }
    }

    return total;
  }

  int _remainingAmount(Map<String, dynamic> unit) {
    if (unit['remaining_installments_amount'] != null) {
      return _toInt(unit['remaining_installments_amount']);
    }

    if (unit['unpaid_amount'] != null) {
      return _toInt(unit['unpaid_amount']);
    }

    return (_totalAmount(unit) - _paidAmount(unit)).clamp(
      0,
      _totalAmount(unit),
    ).toInt();
  }

  double _progress(Map<String, dynamic> unit) {
    final total = _totalAmount(unit);
    if (total <= 0) return 0;

    return (_paidAmount(unit) / total).clamp(0.0, 1.0);
  }

  int _unitNumber(Map<String, dynamic> unit) {
    return _toInt(unit['unit'] ?? unit['unit_number']);
  }

  Future<void> _openInstallments(Map<String, dynamic> unit) async {
    final unitId = _toInt(unit['id']);
    if (unitId <= 0) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerSewageChargeInstallmentsListScreen(
          sewageId: widget.sewageId,
          unitId: unitId,
          unitName: _unitNumber(unit).toString(),
          ownerName: _ownerName(unit),
          sewageName: widget.sewageName,
        ),
      ),
    );

    if (!mounted) return;

    await _loadUnits();
  }

  Widget _buildSearchBox() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        onSubmitted: (_) => _loadUnits(),
        decoration: InputDecoration(
          hintText: 'جستجو بر اساس شماره واحد یا نام مالک',
          hintStyle: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          prefixIcon: IconButton(
            icon: const Icon(Icons.search, color: teal),
            onPressed: _loadUnits,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () {
              _searchController.clear();
              _loadUnits();
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountBox({
    required String title,
    required int amount,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              amount == 0 ? '۰' : _money(amount),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitCard(Map<String, dynamic> unit) {
    final unitNumber = _unitNumber(unit);
    final owner = _ownerName(unit);

    final total = _totalAmount(unit);
    final prepayment = _prepayment(unit);
    final installmentsTotal = _installmentsTotal(unit);
    final paid = _paidAmount(unit);
    final remaining = _remainingAmount(unit);
    final progress = _progress(unit);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 7,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEDEEF3),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: teal,
                  size: 25,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'واحد ${_fa(unitNumber.toString())}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF292D3E),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 15,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            owner,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'فاضلاب',
                  style: TextStyle(
                    fontSize: 10,
                    color: purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _buildAmountBox(
                title: 'مبلغ کل',
                amount: total,
                color: purple,
                icon: Icons.receipt_long_outlined,
              ),
              const SizedBox(width: 8),
              _buildAmountBox(
                title: 'پیش‌پرداخت',
                amount: prepayment,
                color: teal,
                icon: Icons.payments_outlined,
              ),
              const SizedBox(width: 8),
              _buildAmountBox(
                title: 'مجموع اقساط',
                amount: installmentsTotal,
                color: Colors.blue,
                icon: Icons.calendar_month_outlined,
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _buildPaymentInfo(
                  title: 'پرداخت‌شده',
                  amount: paid,
                  color: const Color(0xFF159B70),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPaymentInfo(
                  title: 'مانده بدهی',
                  amount: remaining,
                  color: const Color(0xFFE05B5B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'وضعیت پرداخت',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
              Text(
                '${_fa((progress * 100).round().toString())}٪',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: teal,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFECEEF3),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF16A34A),
              ),
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            width: double.infinity,
            height: 43,
            child: ElevatedButton.icon(
              onPressed: () => _openInstallments(unit),
              icon: const Icon(
                Icons.receipt_long_outlined,
                size: 18,
              ),
              label: const Text(
                'مشاهده اقساط',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfo({
    required String title,
    required int amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            amount == 0 ? '۰' : _money(amount),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: teal),
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
                size: 42,
              ),
              const SizedBox(height: 12),
              const Text(
                'دریافت اطلاعات واحدها با خطا مواجه شد',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _loadUnits,
                icon: const Icon(Icons.refresh),
                label: const Text('تلاش مجدد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_units.isEmpty) {
      return RefreshIndicator(
        color: teal,
        onRefresh: _loadUnits,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 110),
            Icon(
              Icons.apartment_outlined,
              size: 65,
              color: Colors.black26,
            ),
            SizedBox(height: 15),
            Center(
              child: Text(
                'واحدی برای این شارژ پیدا نشد',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: teal,
      onRefresh: _loadUnits,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 25),
        itemCount: _units.length,
        itemBuilder: (context, index) {
          return _buildUnitCard(_units[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: teal,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'واحدهای ${widget.sewageName}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed: _loadUnits,
              icon: const Icon(Icons.refresh),
              tooltip: 'بروزرسانی',
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchBox(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}
