
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/api_service.dart';
import '../../services/manager_fund_turnover_service.dart';

class ManagerFundTurnoverScreen extends StatefulWidget {
  const ManagerFundTurnoverScreen({super.key});

  @override
  State<ManagerFundTurnoverScreen> createState() =>
      _ManagerFundTurnoverScreenState();
}

class _ManagerFundTurnoverScreenState
    extends State<ManagerFundTurnoverScreen> {
  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);
  static const Color _background = Color(0xFFF6F7FB);

  final ManagerFundTurnoverService _service =
  ManagerFundTurnoverService(
    apiService: ApiService(),
  );

  List<Map<String, dynamic>> _funds = [];

  double _totalDebtor = 0;
  double _totalCreditor = 0;
  double _balance = 0;

  int _limit = 20;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _cleanError(Object e) =>
      e.toString().replaceFirst('Exception: ', '');

  void _message(String text, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text, textDirection: TextDirection.rtl),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Colors.red.shade700 : _teal,
        ),
      );
  }

  String _normalizeDigits(String value) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';

    for (var i = 0; i < 10; i++) {
      value = value
          .replaceAll(fa[i], '$i')
          .replaceAll(ar[i], '$i');
    }

    return value;
  }
  String _bankDisplay(Map<String, dynamic> fund) {
    final display = (fund['bank_display'] ?? '').toString().trim();

    if (display.isNotEmpty) return display;

    final bankName = (fund['bank_name'] ?? '').toString().trim();
    final accountNumber = (
        fund['bank_account_number'] ??
            fund['account_number'] ??
            ''
    ).toString().trim();

    if (bankName.isEmpty && accountNumber.isEmpty) return '';

    if (bankName.isEmpty) return _fa(accountNumber);
    if (accountNumber.isEmpty) return bankName;

    return '$bankName - ${_fa(accountNumber)}';
  }

  String _fa(String value) {
    const digits = '۰۱۲۳۴۵۶۷۸۹';

    return value.replaceAllMapped(
      RegExp(r'[0-9]'),
          (m) => digits[int.parse(m.group(0)!)],
    );
  }

  double _number(dynamic value) {
    final text = _normalizeDigits((value ?? '0').toString())
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('٫', '.');

    return double.tryParse(text) ?? 0;
  }

  String _money(dynamic value) {
    final amount = _number(value).round();

    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => ',',
    );

    return '${_fa(formatted)} تومان';
  }

  String _dateText(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'بدون تاریخ';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) return _fa(value.toString());

    final j = Gregorian.fromDateTime(date).toJalali();

    return _fa(
      '${j.year}/${j.month.toString().padLeft(2, '0')}/'
          '${j.day.toString().padLeft(2, '0')}',
    );
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await _service.getFundTurnover(
        limit: _limit,
      );

      if (!mounted) return;

      final summary = response['summary'] is Map
          ? Map<String, dynamic>.from(response['summary'])
          : <String, dynamic>{};

      final results = response['results'];

      setState(() {
        _totalDebtor = _number(summary['total_debtor']);
        _totalCreditor = _number(summary['total_creditor']);
        _balance = _number(summary['balance']);

        _funds = results is List
            ? results
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
        )
            .toList()
            : [];

        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _cleanError(e);
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _changeLimit(int value) async {
    if (_limit == value) return;

    setState(() {
      _limit = value;
    });

    await _loadData();
  }

  void _showDetails(Map<String, dynamic> fund) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FundDetailsSheet(
        fund: fund,
        money: _money,
        dateText: _dateText,
        fa: _fa,
      ),
    );
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
            'گردش صندوق',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'تازه‌سازی',
              onPressed: _loading ? null : _loadData,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _summarySection(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _limitSelector(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        color: _teal,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'آخرین گردش‌های صندوق',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${_fa(_funds.length.toString())} مورد',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_loading && _funds.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null && _funds.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _errorView(),
                )
              else if (_funds.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _emptyView(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          return _fundCard(_funds[index]);
                        },
                        childCount: _funds.length,
                      ),
                    ),
                  ),

              if (_loading && _funds.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),

              if (_error != null && _funds.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // خلاصه گردش صندوق
  // =====================================================

  Widget _summarySection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'جمع بدهکار',
                amount: _totalDebtor,
                icon: Icons.arrow_downward_rounded,
                color: _teal,
                background: const Color(0xFFE0F7FA),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                title: 'جمع بستانکار',
                amount: _totalCreditor,
                icon: Icons.arrow_upward_rounded,
                color: _purple,
                background: const Color(0xFFF3E5F5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _balance >= 0
                  ? const Color(0xFFC8E6C9)
                  : const Color(0xFFFFCDD2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _balance >= 0
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: _balance >= 0
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'مانده صندوق',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _money(_balance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        color: _balance >= 0
                            ? Colors.green.shade800
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 125),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            _money(amount),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // انتخاب تعداد گردش
  // =====================================================

  Widget _limitSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFB0BEC5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تعداد گردش‌های قابل نمایش',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [10, 20, 30].map((value) {
              final selected = _limit == value;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _loading
                        ? null
                        : () => _changeLimit(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: selected
                            ? _teal
                            : const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${_fa(value.toString())} مورد آخر',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: selected
                                ? Colors.white
                                : Colors.black54,
                          ),
                        ),
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

  // =====================================================
  // کارت هر گردش
  // =====================================================

  Widget _fundCard(Map<String, dynamic> fund) {
    final debtor = _number(fund['debtor_amount']);
    final creditor = _number(fund['creditor_amount']);

    final isDebtor = debtor > 0;
    final isCreditor = creditor > 0;

    final color = isDebtor
        ? _teal
        : isCreditor
        ? _purple
        : Colors.blueGrey;

    final amount = isDebtor ? debtor : creditor;

    final description =
    (fund['payment_description'] ?? '').toString().trim();

    final title = description.isEmpty
        ? 'گردش بدون شرح'
        : description;

    final docNo = fund['doc_number'];

    // فقط طرف مرتبط با نوع گردش نمایش داده می‌شود.
    final personLabel = isDebtor
        ? 'پرداخت‌کننده'
        : isCreditor
        ? 'دریافت‌کننده'
        : '';

    final personName = isDebtor
        ? (fund['payer'] ?? '').toString().trim()
        : isCreditor
        ? (fund['receiver'] ?? '').toString().trim()
        : '';

    final bankDisplay = _bankDisplay(fund);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCreditor
              ? const Color(0xFF610DB5) // بردر کارت بستانکار
              : const Color(0xFFD5E8EF), // بردر کارت بدهکار
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: isCreditor
                          ? const Color(0xFF610DB5)
                          : const Color(0xFFD5E8EF),
                      width: 1.2,
                    )
                  ),
                  child: Icon(
                    isDebtor
                        ? Icons.arrow_downward_rounded
                        : isCreditor
                        ? Icons.arrow_upward_rounded
                        : Icons.receipt_long_rounded,
                    color: color,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _dateText(fund['payment_date']),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _money(amount),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isDebtor
                          ? 'بدهکار'
                          : isCreditor
                          ? 'بستانکار'
                          : 'بدون مبلغ',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const Divider(height: 24),

            Wrap(
              spacing: 15,
              runSpacing: 10,
              children: [
                if (personName.isNotEmpty)
                  _info(
                    isDebtor
                        ? Icons.person_outline_rounded
                        : Icons.person_pin_circle_outlined,
                    '$personLabel: $personName',
                  ),

                if (bankDisplay.isNotEmpty)
                  _info(
                    Icons.account_balance_rounded,
                    bankDisplay,
                  ),

                if (fund['financial_document_number'] != null)
                  _info(
                    Icons.numbers_rounded,
                    'سند ${_fa(fund['financial_document_number'].toString())}',
                  ),
              ],
            ),

            if (fund['is_initial'] == true) ...[
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerRight,
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    'افتتاحیه حساب',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.black45),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // حالت خالی و خطا
  // =====================================================

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 65,
              color: _teal.withValues(alpha: .6),
            ),
            const SizedBox(height: 14),
            const Text(
              'گردشی برای نمایش وجود ندارد.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'پس از ثبت دریافت یا پرداخت، گردش‌های صندوق در این قسمت نمایش داده می‌شوند.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 55,
            ),
            const SizedBox(height: 12),
            const Text(
              'دریافت گزارش با خطا مواجه شد.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
              ),
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
// جزئیات گردش صندوق
// =====================================================

class _FundDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> fund;
  final String Function(dynamic) money;
  final String Function(dynamic) dateText;
  final String Function(String) fa;

  const _FundDetailsSheet({
    required this.fund,
    required this.money,
    required this.dateText,
    required this.fa,
  });

  static const Color _teal = Color(0xFF00ACC1);
  static const Color _purple = Color(0xFF610DB5);

  String _value(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '—';
    }

    return value.toString();
  }

  Widget _detail(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _value(value),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final debtor = fund['debtor_amount'];
    final creditor = fund['creditor_amount'];

    final debtorValue = debtor ?? 0;
    final creditorValue = creditor ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * .85,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF6F7FB),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'جزئیات گردش صندوق',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_teal, Color(0xFF00838F)],
                      ),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'مانده صندوق پس از این گردش',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          money(fund['final_amount']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 21,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _detail('شماره فاکتور', fa('${fund['doc_number'] ?? '—'}')),
                        _detail(
                          'شماره سند مالی',
                          fa('${fund['financial_document_number'] ?? '—'}'),
                        ),
                        _detail('تاریخ پرداخت', dateText(fund['payment_date'])),
                        _detail('شرح تراکنش', fund['payment_description']),
                        const Divider(height: 18),
                        _detail('پرداخت‌کننده', fund['payer']),
                        _detail('نوع پرداخت‌کننده', _payerType(fund['payer_type'])),
                        _detail('دریافت‌کننده', fund['receiver']),
                        _detail('نوع دریافت‌کننده', _payerType(fund['receiver_type'])),
                        _detail('واحد', fund['unit']),
                        _detail('حساب بانکی', fund['bank_name']),
                        const Divider(height: 18),
                        _detail('مبلغ تراکنش', money(fund['amount'])),
                        _detail(
                          'مبلغ بدهکار',
                          money(debtorValue),
                        ),
                        _detail(
                          'مبلغ بستانکار',
                          money(creditorValue),
                        ),
                        _detail('مانده پس از گردش', money(fund['final_amount'])),
                        const Divider(height: 18),
                        _detail('شماره پیگیری', fund['transaction_no']),
                        _detail('درگاه پرداخت', fund['payment_gateway']),
                        _detail(
                          'نوع سند',
                          fund['is_initial'] == true
                              ? 'افتتاحیه حساب'
                              : 'سند عادی',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('بستن'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _payerType(dynamic value) {
    switch (value) {
      case 'owner':
        return 'مالک';
      case 'renter':
        return 'مستأجر';
      case 'other':
        return 'سایر';
      default:
        return '—';
    }
  }
}
