
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/api_service.dart';
import '../../services/manager_user_help_money_service.dart';

class ManagerUserHelpMoneyScreen extends StatefulWidget {
  const ManagerUserHelpMoneyScreen({super.key});

  @override
  State<ManagerUserHelpMoneyScreen> createState() =>
      _ManagerUserHelpMoneyScreenState();
}

class _ManagerUserHelpMoneyScreenState
    extends State<ManagerUserHelpMoneyScreen> {

  static const Color primaryColor = Color(0xFF00ACC1);
  static const Color secondaryColor = Color(0xFF610DB5);

  late final ManagerUserHelpMoneyService _service;

  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _payments = [];

  int _totalAmount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();

    _service = ManagerUserHelpMoneyService(
      apiService: ApiService(),
    );

    _loadPayments();
  }

  // =====================================================
  // دریافت اطلاعات
  // =====================================================

  Future<void> _loadPayments() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _service.getUserHelpMoney();

      if (!mounted) return;

      final statistics = result['statistics'] is Map
          ? Map<String, dynamic>.from(result['statistics'])
          : <String, dynamic>{};

      final receivedPayments = result['payments'];

      final payments = receivedPayments is List
          ? receivedPayments
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _payments = payments;

        _totalAmount = _toInt(
          statistics['total_amount'],
        );

        _totalCount = _toInt(
          statistics['total_count'],
        );
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
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
  // تبدیل عدد به int
  // =====================================================

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = _toEnglishDigits(
      value?.toString() ?? '',
    );

    return int.tryParse(
      text.replaceAll(',', '').replaceAll('٬', '').trim(),
    ) ?? 0;
  }

  // =====================================================
  // تبدیل اعداد انگلیسی و عربی به فارسی
  // =====================================================

  String _toPersianDigits(String value) {
    const englishDigits = '0123456789';
    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';

    for (int i = 0; i < 10; i++) {
      value = value.replaceAll(
        englishDigits[i],
        persianDigits[i],
      );

      value = value.replaceAll(
        arabicDigits[i],
        persianDigits[i],
      );
    }

    return value;
  }

  // =====================================================
  // تبدیل اعداد فارسی و عربی به انگلیسی
  // =====================================================

  String _toEnglishDigits(String value) {
    const englishDigits = '0123456789';
    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';

    for (int i = 0; i < 10; i++) {
      value = value.replaceAll(
        persianDigits[i],
        englishDigits[i],
      );

      value = value.replaceAll(
        arabicDigits[i],
        englishDigits[i],
      );
    }

    return value;
  }

  // =====================================================
  // فرمت مبلغ
  // =====================================================

  String _formatMoney(dynamic value) {
    final amount = _toInt(value);

    final formatted = NumberFormat('#,###').format(amount);

    return '${_toPersianDigits(formatted)} تومان';
  }

  // =====================================================
  // دریافت مقدار متنی
  // =====================================================

  String _text(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;

    final result = value.toString().trim();

    if (result.isEmpty || result == 'null') {
      return fallback;
    }

    return _toPersianDigits(result);
  }

  // =====================================================
  // تبدیل تاریخ میلادی به شمسی
  // =====================================================

  String _formatJalaliDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return '';
    }

    try {
      final dateString = value.toString().trim();

      final datePart = dateString
          .split('T')
          .first
          .split(' ')
          .first;

      final parts = datePart.split('-');

      if (parts.length != 3) {
        return _toPersianDigits(dateString);
      }

      final year = int.tryParse(
        _toEnglishDigits(parts[0]),
      );

      final month = int.tryParse(
        _toEnglishDigits(parts[1]),
      );

      final day = int.tryParse(
        _toEnglishDigits(parts[2]),
      );

      if (year == null || month == null || day == null) {
        return _toPersianDigits(dateString);
      }

      // اگر تاریخ از قبل شمسی باشد
      if (year >= 1300 && year <= 1500) {
        return _toPersianDigits(
          '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}',
        );
      }

      // تبدیل تاریخ میلادی به شمسی
      final dateTime = DateTime(year, month, day);

      final jalali = Jalali.fromDateTime(dateTime);

      return _toPersianDigits(
        '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}',
      );
    } catch (_) {
      return _toPersianDigits(value.toString());
    }
  }

  // =====================================================
  // استخراج شماره واحد
  // =====================================================

  String _getUnitNumber(Map<String, dynamic> payment) {
    final unit = payment['unit'];

    if (payment['unit_number'] != null) {
      return _text(payment['unit_number']);
    }

    if (unit is Map) {
      return _text(
        unit['unit'] ??
            unit['unit_number'] ??
            unit['number'],
      );
    }

    return _text(unit);
  }

  // =====================================================
  // استخراج نام مالک یا مستأجر
  // =====================================================

  String _getResidentName(Map<String, dynamic> payment) {
    return _text(
      payment['resident_name'],
      fallback: '-',
    );
  }

  // =====================================================
  // کارت خلاصه
  // =====================================================

  Widget _buildSummaryCard() {
    return Container(
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
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'مجموع مبالغ کمک ساکنین',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            _formatMoney(_totalAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _buildSummaryItem(
                Icons.people_alt_outlined,
                'کل کمک‌ها',
                _totalCount,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // آیتم کارت خلاصه
  // =====================================================

  Widget _buildSummaryItem(
      IconData icon,
      String title,
      int count,
      ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 19,
          ),

          const SizedBox(height: 6),

          Text(
            _toPersianDigits(count.toString()),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // کارت کمک ساکن
  // =====================================================

  Widget _buildPaymentCard(Map<String, dynamic> payment) {

    final residentName = _getResidentName(payment);

    final unitNumber = _getUnitNumber(payment);

    final amount = payment['amount'];

    final description = _text(
      payment['description'],
      fallback: 'بدون شرح',
    );

    final details = _text(
      payment['details'],
      fallback: '',
    );

    final registerDate = _formatJalaliDate(
      payment['register_date'],
    );

    final paymentDate = _formatJalaliDate(
      payment['payment_date'],
    );

    final transactionReference = _text(
      payment['transaction_reference'],
      fallback: '',
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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

          // =========================================
          // مشخصات مالک یا مستأجر
          // =========================================

          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.volunteer_activism_outlined,
                  color: primaryColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      residentName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      unitNumber == '-'
                          ? 'واحد مشخص نشده'
                          : 'واحد $unitNumber',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 25),

          // =========================================
          // مبلغ
          // =========================================

          Row(
            children: [
              Text(
                'مبلغ کمک',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),

              const Spacer(),

              Text(
                _formatMoney(amount),
                style: const TextStyle(
                  color: secondaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // =========================================
          // شرح کمک
          // =========================================

          _buildInfoRow(
            Icons.description_outlined,
            'شرح',
            description,
          ),

          const SizedBox(height: 10),

          // =========================================
          // تاریخ ثبت شمسی
          // =========================================

          _buildInfoRow(
            Icons.calendar_today_outlined,
            'تاریخ ثبت',
            registerDate,
          ),

          // =========================================
          // تاریخ پرداخت شمسی
          // =========================================

          if (paymentDate.isNotEmpty) ...[
            const SizedBox(height: 10),

            _buildInfoRow(
              Icons.event_available_outlined,
              'تاریخ پرداخت',
              paymentDate,
            ),
          ],

          // =========================================
          // شماره پیگیری
          // =========================================

          if (transactionReference.isNotEmpty) ...[
            const SizedBox(height: 10),

            _buildInfoRow(
              Icons.receipt_long_outlined,
              'شماره پیگیری',
              transactionReference,
            ),
          ],

          // =========================================
          // توضیحات
          // =========================================

          if (details.isNotEmpty) ...[
            const SizedBox(height: 10),

            _buildInfoRow(
              Icons.notes_outlined,
              'توضیحات',
              details,
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // ردیف اطلاعات
  // =====================================================

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

  // =====================================================
  // وضعیت خالی
  // =====================================================

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 65,
              color: Colors.grey.shade400,
            ),

            const SizedBox(height: 15),

            const Text(
              'هنوز کمکی توسط ساکنین ثبت نشده است.',
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

  // =====================================================
  // رابط اصلی
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),

        appBar: AppBar(
          toolbarHeight: 88,
          title: const Text(
            'کمک‌های ساکنین',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _loading ? null : _loadPayments,
              icon: const Icon(Icons.refresh),
              tooltip: 'بروزرسانی',
            ),
          ],
        ),

        body: RefreshIndicator(
          onRefresh: _loadPayments,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(),

              const SizedBox(height: 20),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(35),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  ),
                )

              else if (_error != null)
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
                        onPressed: _loadPayments,
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                )

              else if (_payments.isEmpty)
                  SizedBox(
                    height: 250,
                    child: _buildEmpty(),
                  )

                else ...[
                    Text(
                      'فهرست کمک‌ها '
                          '(${_toPersianDigits(_payments.length.toString())})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 12),

                    ..._payments.map(_buildPaymentCard),
                  ],
            ],
          ),
        ),
      ),
    );
  }
}
