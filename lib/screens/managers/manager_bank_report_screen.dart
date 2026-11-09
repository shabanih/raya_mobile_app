
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_bank_service.dart';

class ManagerBankReportScreen extends StatefulWidget {
  final ManagerBankService bankService;

  const ManagerBankReportScreen({
    super.key,
    required this.bankService,
  });

  @override
  State<ManagerBankReportScreen> createState() =>
      _ManagerBankReportScreenState();
}

class _ManagerBankReportScreenState
    extends State<ManagerBankReportScreen> {
  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);
  static const Color _background = Color(0xFFF6F7FB);

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _banks = [];

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result =
      await widget.bankService.getBankReportBanks();

      if (!mounted) return;

      setState(() {
        _banks = result;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          toolbarHeight: 88,
          title: const Text(
            'فهرست بانک‌ها',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF00ACC1),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _teal),
      );
    }

    if (_error != null) {
      return _ErrorView(
        message: _error!,
        onRetry: _loadBanks,
      );
    }

    if (_banks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadBanks,
        color: _teal,
        child: ListView(
          children: const [
            SizedBox(height: 180),
            Icon(
              Icons.account_balance_outlined,
              size: 65,
              color: Colors.grey,
            ),
            SizedBox(height: 15),
            Center(
              child: Text(
                'حساب بانکی فعالی وجود ندارد.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBanks,
      color: _teal,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeader(),
          const SizedBox(height: 18),
          ..._banks.map(_buildBankCard),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_teal, _purple],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.account_balance,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'حساب‌های بانکی',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_fa(_banks.length.toString())} حساب بانکی',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Colors.white,
            size: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard(Map<String, dynamic> bank) {
    final bankId = int.tryParse(
      bank['id']?.toString() ?? '',
    ) ??
        0;

    final bankName = bank['bank_name']?.toString() ?? '-';
    final holder =
        bank['account_holder_name']?.toString() ?? '-';
    final accountNo = bank['account_no']?.toString() ?? '-';
    final balance = _money(bank['current_balance']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: bankId == 0
              ? null
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ManagerBankReportDetailScreen(
                  bankService: widget.bankService,
                  bank: bank,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: _teal.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: _teal.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: _teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        bankName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263238),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 15,
                      color: Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _infoRow('صاحب حساب', holder),
                const SizedBox(height: 9),
                _infoRow('شماره حساب', _fa(accountNo)),
                const Divider(height: 22),
                Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: _teal,
                      size: 20,
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'موجودی حساب',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$balance تومان',
                      style: const TextStyle(
                        color: _purple,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Row(
      children: [
        SizedBox(
          width: 95,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF37474F),
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================================
// صفحه گردش حساب یک بانک
// =====================================================

class ManagerBankReportDetailScreen extends StatefulWidget {
  final ManagerBankService bankService;
  final Map<String, dynamic> bank;

  const ManagerBankReportDetailScreen({
    super.key,
    required this.bankService,
    required this.bank,
  });

  @override
  State<ManagerBankReportDetailScreen> createState() =>
      _ManagerBankReportDetailScreenState();
}

class _ManagerBankReportDetailScreenState
    extends State<ManagerBankReportDetailScreen> {
  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);
  static const Color _red = Color(0xFFE53935);
  static const Color _background = Color(0xFFF6F7FB);

  bool _loading = true;
  String? _error;

  int _limit = 20;
  double _currentBalance = 0;

  List<Map<String, dynamic>> _transactions = [];

  int get _bankId =>
      int.tryParse(widget.bank['id']?.toString() ?? '') ?? 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data =
      await widget.bankService.getBankReportTransactions(
        bankId: _bankId,
        limit: _limit,
      );

      if (!mounted) return;

      final bankData = data['bank'];

      setState(() {
        _currentBalance = _toDouble(data['current_balance']);

        if (bankData is Map) {
          // اطلاعات بانک از پاسخ گزارش به‌روز می‌شود.
        }

        final results = data['results'];

        _transactions = results is List
            ? results
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
        )
            .toList()
            : [];

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _changeLimit(int? value) async {
    if (value == null || value == _limit) return;

    setState(() {
      _limit = value;
    });

    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final bankName =
        widget.bank['bank_name']?.toString() ?? 'گزارش بانک';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          toolbarHeight: 88,
          title: Text(
            bankName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF00ACC1),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _teal),
      );
    }

    if (_error != null) {
      return _ErrorView(
        message: _error!,
        onRetry: _loadData,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _teal,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBalanceCard(),
          const SizedBox(height: 18),
          _buildLimitSelector(),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(
                Icons.receipt_long,
                color: _purple,
                size: 21,
              ),
              const SizedBox(width: 8),
              const Text(
                'تراکنش‌های حساب',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                '${_fa(_transactions.length.toString())} تراکنش',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_transactions.isEmpty)
            _emptyTransactions()
          else
            ..._transactions.map(_buildTransactionCard),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_teal, _purple],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'موجودی فعلی حساب',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            '${_money(_currentBalance)} تومان',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          // const Divider(color: Colors.white30),
          // const SizedBox(height: 8),
          // Text(
          //   'شماره حساب: ${widget.bank['account_no'] ?? '-'}',
          //   style: const TextStyle(
          //     color: Colors.white,
          //     fontSize: 12,
          //   ),
          // ),
          // const SizedBox(height: 6),
          // Text(
          //   'صاحب حساب: ${widget.bank['account_holder_name'] ?? '-'}',
          //   style: const TextStyle(
          //     color: Colors.white,
          //     fontSize: 12,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildLimitSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.filter_list,
                color: _teal,
                size: 21,
              ),
              SizedBox(width: 8),
              // Text(
              //   'تعداد تراکنش‌های اخیر',
              //   style: TextStyle(
              //     fontSize: 13,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [10, 20, 30].map((value) {
              final selected = _limit == value;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () => _changeLimit(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? _teal.withValues(alpha: 0.12)
                            : const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: selected
                              ? _teal
                              : Colors.grey.shade200,
                          width: selected ? 1.6 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _fa(value.toString()),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? _teal
                                  : const Color(0xFF455A64),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'تراکنش',
                            style: TextStyle(
                              fontSize: 11,
                              color: selected
                                  ? _teal
                                  : Colors.grey.shade600,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          if (selected) ...[
                            const SizedBox(height: 5),
                            const Icon(
                              Icons.check_circle,
                              color: _teal,
                              size: 17,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
      Map<String, dynamic> transaction,
      ) {
    final type =
        transaction['transaction_type']?.toString() ?? '';

    final isDeposit = type == 'deposit';
    final color = isDeposit ? _teal : _red;

    final label =
        transaction['transaction_label']?.toString() ??
            (isDeposit ? 'واریز' : 'برداشت');

    final amount = _money(transaction['amount']);

    final documentNumber =
        transaction['financial_document_number']?.toString() ??
            '-';

    final date = _dateText(transaction['payment_date']);

    final description =
        transaction['payment_description']?.toString() ?? '';

    final receiver = _fa(
      transaction['receiver_name']?.toString() ?? '-',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),

        border: Border(
          right: BorderSide(
            color: color,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    isDeposit
                        ? Icons.south_west
                        : Icons.north_east,
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
                        label,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'سند شماره ${_fa(documentNumber)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$amount تومان',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(height: 23),
            _detailRow('تاریخ', date),
            const SizedBox(height: 9),
            _detailRow('در وجه', receiver),
            if (description.trim().isNotEmpty) ...[
              const SizedBox(height: 9),
              _detailRow('شرح', description),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 65,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF37474F),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyTransactions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 45),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 50,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Text(
            'تراکنشی برای این حساب ثبت نشده است.',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// نمایش خطا
// =====================================================

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// توابع تبدیل اعداد و تاریخ
// =====================================================

String _fa(String value) {
  const english = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';

  var result = value;

  for (var i = 0; i < english.length; i++) {
    result = result.replaceAll(
      english[i],
      persian[i],
    );
  }

  return result;
}

double _toDouble(dynamic value) {
  if (value == null) return 0;

  if (value is num) return value.toDouble();

  return double.tryParse(
    value.toString().replaceAll(',', ''),
  ) ??
      0;
}

String _money(dynamic value) {
  final number = _toDouble(value).round();
  final text = number.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < text.length; i++) {
    buffer.write(text[i]);

    final remaining = text.length - i - 1;

    if (remaining > 0 && remaining % 3 == 0) {
      buffer.write(',');
    }
  }

  return _fa(buffer.toString());
}

String _dateText(dynamic value) {
  if (value == null || value.toString().isEmpty) {
    return '-';
  }

  try {
    final date = DateTime.parse(value.toString());
    final jalali = Jalali.fromDateTime(date);

    return _fa(
      '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/'
          '${jalali.day.toString().padLeft(2, '0')}',
    );
  } catch (_) {
    return value.toString();
  }
}
