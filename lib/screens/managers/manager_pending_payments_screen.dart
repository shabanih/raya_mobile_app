
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/api_service.dart';
import '../../services/manager_pending_payments_service.dart';


class ManagerPendingPaymentsScreen extends StatefulWidget {
  const ManagerPendingPaymentsScreen({super.key});

  @override
  State<ManagerPendingPaymentsScreen> createState() =>
      _ManagerPendingPaymentsScreenState();
}

class _ManagerPendingPaymentsScreenState
    extends State<ManagerPendingPaymentsScreen> {
  late final ManagerPendingPaymentsService _service;

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _payments = [];
  Map<String, dynamic> _statistics = {};

  String _selectedType = 'all';
  int? _approvingPaymentId;

  @override
  void initState() {
    super.initState();
    _service = ManagerPendingPaymentsService(
      apiService: ApiService(),
    );
    _loadPayments();
  }
  // تبدیل اعداد انگلیسی و عربی به فارسی
  String _toPersianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    return value.split('').map((char) {
      final index = english.indexOf(char);

      if (index != -1) {
        return persian[index];
      }

      if (char == '٠' ||
          char == '١' ||
          char == '٢' ||
          char == '٣' ||
          char == '٤' ||
          char == '٥' ||
          char == '٦' ||
          char == '٧' ||
          char == '٨' ||
          char == '٩') {
        const arabic = '٠١٢٣٤٥٦٧٨٩';
        return persian[arabic.indexOf(char)];
      }

      return char;
    }).join();
  }



// نمایش تاریخ شمسی
  String _formatJalaliDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '-';
    }

    try {
      final date = DateTime.parse(value.toString()).toLocal();

      final jalali = Jalali.fromDateTime(date);

      final year = jalali.year.toString().padLeft(4, '0');
      final month = jalali.month.toString().padLeft(2, '0');
      final day = jalali.day.toString().padLeft(2, '0');

      return _toPersianDigits('$year/$month/$day');
    } catch (_) {
      // اگر تاریخ با قالب دیگری از API دریافت شد،
      // حداقل اعداد آن فارسی نمایش داده می‌شوند.
      return _toPersianDigits(value.toString());
    }
  }

  Future<void> _loadPayments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.getPendingPayments(
        type: _selectedType == 'all' ? null : _selectedType,
      );

      if (!mounted) return;

      setState(() {
        _payments = List<Map<String, dynamic>>.from(
          result['payments'] ?? [],
        );

        _statistics = Map<String, dynamic>.from(
          result['statistics'] ?? {},
        );

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _approvePayment(
      Map<String, dynamic> payment,
      ) async {
    final int? paymentId = int.tryParse(
      payment['payment_id']?.toString() ?? '',
    );

    final String paymentType =
        payment['payment_type']?.toString() ?? '';

    if (paymentId == null || paymentType.isEmpty) {
      _showMessage('اطلاعات پرداخت معتبر نیست.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید پرداخت'),
        content: const Text(
          'آیا از تأیید این پرداخت اطمینان دارید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأیید'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _approvingPaymentId = paymentId;
    });

    try {
      final result = await _service.approvePayment(
        paymentId: paymentId,
        paymentType: paymentType,
      );

      if (!mounted) return;

      _showMessage(
        result['message']?.toString() ??
            'پرداخت با موفقیت تأیید شد.',
      );

      await _loadPayments();
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _approvingPaymentId = null;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int _toInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatAmount(dynamic value) {
    final amount = double.tryParse(
      value?.toString().replaceAll(',', '') ?? '',
    ) ??
        0;

    final formatted = amount.toInt().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
    );

    return _toPersianDigits(formatted);
  }

  String _typeTitle(dynamic type) {
    switch (type?.toString()) {
      case 'monthly':
        return 'شارژ ماهانه';
      case 'civil':
        return 'شارژ عمرانی';
      case 'sewage':
        return 'هزینه فاضلاب';
      default:
        return type?.toString() ?? 'پرداخت';
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _toInt(_statistics['total']);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: RefreshIndicator(
        onRefresh: _loadPayments,
        child: _loading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : _error != null
            ? ListView(
          children: [
            const SizedBox(height: 120),
            Center(child: Text(_error!)),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _loadPayments,
                child: const Text('تلاش مجدد'),
              ),
            ),
          ],
        )
            : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatistics(total),
            const SizedBox(height: 16),
            _buildFilters(),
            const SizedBox(height: 12),
            if (_payments.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 70),
                child: Center(
                  child: Text(
                    'پرداخت در انتظار تأیید وجود ندارد.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),
                ),
              )
            else
              ..._payments.map(_buildPaymentCard),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(int total) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFEDE7F6),
              child: Icon(
                Icons.pending_actions,
                color: Color(0xFF610DB5),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'پرداخت‌های در انتظار تأیید',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              _toPersianDigits(total.toString()),
              style: const TextStyle(
                color: Color(0xFF610DB5),
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 8,
      children: [
        _filterChip('همه', 'all'),
        _filterChip('شارژ ماهانه', 'monthly'),
        _filterChip('شارژ عمرانی', 'civil'),
        _filterChip('هزینه فاضلاب', 'sewage'),
      ],
    );
  }

  Widget _filterChip(String title, String value) {
    final selected = _selectedType == value;

    return ChoiceChip(
      label: Text(title),
      selected: selected,
      selectedColor: const Color(0xFFE1D1F2),
      onSelected: (_) {
        if (_selectedType == value) return;

        setState(() {
          _selectedType = value;
        });

        _loadPayments();
      },
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final paymentId = _toInt(payment['payment_id']);
    final isApproving = _approvingPaymentId == paymentId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _typeTitle(
                      payment['payment_type_display'] ??
                          payment['payment_type'],
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  'واحد ${_toPersianDigits(payment['unit_number']?.toString() ?? '-')}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const Divider(height: 22),

            _infoRow(
              'نام مالک',
              payment['owner_name'] ?? '-',
            ),

            _infoRow(
              'پرداخت‌کننده',
              payment['payer_name'] ?? '-',
            ),

            _infoRow(
              'مبلغ',
              '${_formatAmount(payment['amount'])} تومان',
            ),

            _infoRow(
              'شماره پیگیری',
              _toPersianDigits(
                payment['transaction_reference']?.toString() ?? '-',
              ),
            ),

            _infoRow(
              'تاریخ پرداخت',
              _formatJalaliDate(payment['payment_submitted_at']),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isApproving || _approvingPaymentId != null
                    ? null
                    : () => _approvePayment(payment),
                icon: isApproving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  isApproving ? 'در حال تأیید...' : 'تأیید پرداخت',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00ACC1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
