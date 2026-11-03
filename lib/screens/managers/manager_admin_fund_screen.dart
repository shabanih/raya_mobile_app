
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/api_service.dart';
import '../../services/manager_admin_fund_service.dart';

class ManagerAdminFundScreen extends StatefulWidget {
  const ManagerAdminFundScreen({super.key});

  @override
  State<ManagerAdminFundScreen> createState() =>
      _ManagerAdminFundScreenState();
}

class _ManagerAdminFundScreenState
    extends State<ManagerAdminFundScreen> {
  static const Color primaryColor = Color(0xFF00ACC1);
  static const Color secondaryColor = Color(0xFF610DB5);

  late final ManagerAdminFundService _service;

  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _transactions = [];

  int _totalAmount = 0;
  int _totalCount = 0;

  // شناسه تراکنش‌هایی که جزئیات آن‌ها باز شده است
  final Set<String> _expandedTransactions = {};

  @override
  void initState() {
    super.initState();

    _service = ManagerAdminFundService(
      apiService: ApiService(),
    );

    _loadTransactions();
  }

  // دریافت تراکنش‌ها
  Future<void> _loadTransactions() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.getAdminFunds();

      if (!mounted) return;

      final statistics = result['statistics'] is Map
          ? Map<String, dynamic>.from(result['statistics'])
          : <String, dynamic>{};

      final receivedTransactions = result['transactions'];

      final transactions = receivedTransactions is List
          ? receivedTransactions
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _transactions = transactions;
        _totalAmount = _toInt(statistics['total_amount']);
        _totalCount = _toInt(
          statistics['total_count'] ?? transactions.length,
        );

        // پس از دریافت مجدد، جزئیات بسته باشند
        _expandedTransactions.clear();
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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = _toEnglishDigits(value?.toString() ?? '');

    return int.tryParse(
      text.replaceAll(',', '').replaceAll('٬', '').trim(),
    ) ??
        0;
  }

  String _toPersianDigits(String value) {
    const englishDigits = '0123456789';
    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';

    for (int i = 0; i < 10; i++) {
      value = value.replaceAll(englishDigits[i], persianDigits[i]);
      value = value.replaceAll(arabicDigits[i], persianDigits[i]);
    }

    return value;
  }

  String _toEnglishDigits(String value) {
    const englishDigits = '0123456789';
    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';

    for (int i = 0; i < 10; i++) {
      value = value.replaceAll(persianDigits[i], englishDigits[i]);
      value = value.replaceAll(arabicDigits[i], englishDigits[i]);
    }

    return value;
  }

  String _formatMoney(dynamic value) {
    final amount = _toInt(value);
    final formatted = NumberFormat('#,###').format(amount);

    return '${_toPersianDigits(formatted)} تومان';
  }

  String _text(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;

    final result = value.toString().trim();

    if (result.isEmpty || result == 'null') {
      return fallback;
    }

    return _toPersianDigits(result);
  }

  String _formatJalaliDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '';
    }

    try {
      final dateString = value.toString().trim();

      final datePart = dateString.split('T').first.split(' ').first;

      final parts = datePart.split('-');

      if (parts.length != 3) {
        return _toPersianDigits(dateString);
      }

      final year = int.tryParse(_toEnglishDigits(parts[0]));
      final month = int.tryParse(_toEnglishDigits(parts[1]));
      final day = int.tryParse(_toEnglishDigits(parts[2]));

      if (year == null || month == null || day == null) {
        return _toPersianDigits(dateString);
      }

      if (year >= 1300 && year <= 1500) {
        return _toPersianDigits(
          '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}',
        );
      }

      final jalali = Jalali.fromDateTime(
        DateTime(year, month, day),
      );

      return _toPersianDigits(
        '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}',
      );
    } catch (_) {
      return _toPersianDigits(value.toString());
    }
  }

  String _getTransactionType(Map<String, dynamic> transaction) {
    switch (transaction['transaction_type']?.toString()) {
      case 'sms_credit':
        return 'شارژ حساب پیامک';
      case 'subscription':
        return 'خرید اشتراک';
      default:
        return 'سایر تراکنش‌ها';
    }
  }

  IconData _getTransactionIcon(
      Map<String, dynamic> transaction,
      ) {
    switch (transaction['transaction_type']?.toString()) {
      case 'sms_credit':
        return Icons.sms_outlined;
      case 'subscription':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  Color _getTransactionColor(
      Map<String, dynamic> transaction,
      ) {
    switch (transaction['transaction_type']?.toString()) {
      case 'sms_credit':
        return primaryColor;
      case 'subscription':
        return secondaryColor;
      default:
        return Colors.blueGrey;
    }
  }

  Map<String, dynamic> _getDetails(
      Map<String, dynamic> transaction,
      ) {
    final details = transaction['details'];

    if (details is Map) {
      return Map<String, dynamic>.from(details);
    }

    return {};
  }

  // کارت خلاصه همراه با دکمه رفرش
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'مجموع پرداخت‌های مالی مدیر',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'بروزرسانی',
                onPressed: _loading ? null : _loadTransactions,
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 5),

          Text(
            _formatMoney(_totalAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: Colors.white70,
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                '${_toPersianDigits(_totalCount.toString())} تراکنش ثبت‌شده',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // کارت هر تراکنش با جزئیات بازشونده
  Widget _buildTransactionCard(
      Map<String, dynamic> transaction,
      ) {
    final type = _getTransactionType(transaction);
    final icon = _getTransactionIcon(transaction);
    final color = _getTransactionColor(transaction);

    final details = _getDetails(transaction);

    final transactionType =
    transaction['transaction_type']?.toString();

    final description = _text(
      transaction['payment_description'],
      fallback: 'بدون شرح',
    );

    final paymentDate = _formatJalaliDate(
      transaction['payment_date'],
    );

    final createdDate = _formatJalaliDate(
      transaction['created_at'],
    );

    final transactionNo = _text(
      transaction['transaction_no'],
      fallback: '',
    );

    final gateway = _text(
      transaction['payment_gateway'],
    );

    final isPaid = transaction['is_paid'] == true;

    final transactionId = _text(
      transaction['id'],
    );

    final amount = transaction['amount'];

    final isExpanded = _expandedTransactions.contains(transactionId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اطلاعات اصلی تراکنش
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 23,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 7),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.green.withValues(alpha: 0.10)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPaid ? 'موفق' : 'ناموفق',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPaid
                        ? Colors.green.shade700
                        : Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // مبلغ
          Row(
            children: [
              Text(
                'مبلغ پرداخت',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                _formatMoney(amount),
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // تاریخ پرداخت
          if (paymentDate.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 7),
                Text(
                  'تاریخ پرداخت: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  paymentDate,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          // دکمه باز و بسته کردن جزئیات
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedTransactions.remove(transactionId);
                } else {
                  _expandedTransactions.add(transactionId);
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 7,
                horizontal: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isExpanded ? 'بستن جزئیات' : 'جزئیات بیشتر',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: color,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // بخش اطلاعات تکمیلی
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 20),

                const Text(
                  'اطلاعات تکمیلی تراکنش',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                _buildInfoRow(
                  Icons.numbers_outlined,
                  'شناسه تراکنش',
                  transactionId,
                ),

                if (createdDate.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.calendar_today_outlined,
                    'تاریخ ثبت',
                    createdDate,
                  ),
                ],

                if (gateway != '-') ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.account_balance_outlined,
                    'درگاه پرداخت',
                    gateway,
                  ),
                ],

                if (transactionNo.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.receipt_long_outlined,
                    'شماره پیگیری',
                    transactionNo,
                  ),
                ],

                // جزئیات شارژ پیامک
                if (transactionType == 'sms_credit') ...[
                  const Divider(height: 25),

                  const Text(
                    'جزئیات شارژ پیامک',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (details['credit_amount'] != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.sms_outlined,
                      'مبلغ شارژ',
                      _formatMoney(details['credit_amount']),
                    ),
                  ],

                  if (details['amount_with_tax'] != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.calculate_outlined,
                      'مبلغ با مالیات',
                      _formatMoney(details['amount_with_tax']),
                    ),
                  ],

                  if (_text(details['res_num'], fallback: '').isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.tag_outlined,
                      'شناسه سفارش',
                      _text(details['res_num']),
                    ),
                  ],
                ],

                // جزئیات اشتراک
                if (transactionType == 'subscription') ...[
                  const Divider(height: 25),

                  const Text(
                    'جزئیات اشتراک',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (details['plan_name'] != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.workspace_premium_outlined,
                      'نام طرح اشتراک',
                      _text(details['plan_name']),
                    ),
                  ],

                  if (details['units_count'] != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.apartment_outlined,
                      'تعداد واحد',
                      _text(details['units_count']),
                    ),
                  ],

                  if (details['total_amount'] != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.payments_outlined,
                      'مبلغ کل',
                      _formatMoney(details['total_amount']),
                    ),
                  ],

                  if (details['discount_amount'] != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.discount_outlined,
                      'مبلغ تخفیف',
                      _formatMoney(details['discount_amount']),
                    ),
                  ],

                  if (details['final_amount'] != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.account_balance_wallet_outlined,
                      'مبلغ نهایی اشتراک',
                      _formatMoney(details['final_amount']),
                    ),
                  ],

                  if (details['is_trial'] == true) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.card_giftcard_outlined,
                      'نوع اشتراک',
                      'آزمایشی',
                    ),
                  ],

                  if (details['start_date'] != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.play_circle_outline,
                      'شروع اشتراک',
                      _formatJalaliDate(details['start_date']),
                    ),
                  ],

                  if (details['end_date'] != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.event_outlined,
                      'پایان اشتراک',
                      _formatJalaliDate(details['end_date']),
                    ),
                  ],
                ],
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  // ردیف اطلاعات تکمیلی
  Widget _buildInfoRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 17,
          color: Colors.grey.shade500,
        ),

        const SizedBox(width: 8),

        Text(
          '$title:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // وضعیت خالی
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 65,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 15),

            const Text(
              'هنوز تراکنش مالی ثبت نشده است.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),

        body: RefreshIndicator(
          onRefresh: _loadTransactions,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(),

              const SizedBox(height: 20),

              if (_loading && _transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(35),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  ),
                )
              else if (_error != null && _transactions.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 40,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 12),

                      ElevatedButton(
                        onPressed: _loadTransactions,
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                )
              else if (_transactions.isEmpty)
                  SizedBox(
                    height: 250,
                    child: _buildEmpty(),
                  )
                else ...[
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'تراکنش‌های مالی',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          '${_toPersianDigits(_transactions.length.toString())} مورد',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    ..._transactions.map(_buildTransactionCard),
                  ],
            ],
          ),
        ),
      ),
    );
  }
}
