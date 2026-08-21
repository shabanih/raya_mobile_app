import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../services/api_service.dart';
import 'civil_installments_screen.dart';

class CivilChargeScreen extends StatefulWidget {
  const CivilChargeScreen({super.key});

  @override
  State<CivilChargeScreen> createState() =>
      _CivilChargeScreenState();
}

class _CivilChargeScreenState
    extends State<CivilChargeScreen> {
  // =====================================================
  // Colors
  // =====================================================

  static const Color primaryColor =
  Color(0xff610DB5);

  static const Color textColor =
  Color(0xff263238);

  static const Color backgroundColor =
  Color(0xffF7F9FA);

  // =====================================================
  // State
  // =====================================================

  bool isLoading = true;

  String? errorMessage;

  List<Map<String, dynamic>> charges = [];

  // =====================================================
  // Init
  // =====================================================

  @override
  void initState() {
    super.initState();

    loadCivilCharges();
  }

  // =====================================================
  // دریافت شارژهای عمرانی
  // =====================================================

  Future<void> loadCivilCharges() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final result =
      await ApiService().getCivilCharges();

      debugPrint('====================================');
      debugPrint(
        'CIVIL CHARGES COUNT: ${result.length}',
      );

      for (final item in result) {
        debugPrint(
          'CIVIL CHARGE ITEM: $item',
        );
      }

      debugPrint('====================================');

      if (!mounted) return;

      setState(() {
        charges = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'CIVIL CHARGES ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
        'دریافت شارژهای عمرانی با خطا مواجه شد.';
      });
    }
  }

  // =====================================================
  // تبدیل عدد انگلیسی به فارسی
  // =====================================================

  String toPersianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    for (
    int i = 0;
    i < english.length;
    i++
    ) {
      value = value.replaceAll(
        english[i],
        persian[i],
      );
    }

    return value;
  }

  // =====================================================
  // فرمت مبلغ
  // =====================================================

  String formatAmount(dynamic value) {
    if (value == null) {
      return '۰';
    }

    if (value is num) {
      return _formatNumber(
        value.toInt(),
      );
    }

    String text =
    value.toString();

    text = text
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('.0', '')
        .trim();

    final number =
        int.tryParse(text) ?? 0;

    return _formatNumber(number);
  }

  String _formatNumber(int number) {
    final text =
    number.toString();

    final buffer =
    StringBuffer();

    for (
    int i = 0;
    i < text.length;
    i++
    ) {
      if (
      i > 0 &&
          (text.length - i) % 3 == 0) {
        buffer.write('٬');
      }

      buffer.write(text[i]);
    }

    return toPersianDigits(
      buffer.toString(),
    );
  }

  // =====================================================
  // تاریخ
  // =====================================================

  String formatDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return '-';
    }

    try {
      final dateTime = DateTime.parse(text);

      final jalali = Jalali.fromDateTime(dateTime);

      return toPersianDigits(
        '${jalali.year}/'
            '${jalali.month.toString().padLeft(2, '0')}/'
            '${jalali.day.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      debugPrint('DATE CONVERSION ERROR: $e');

      return toPersianDigits(
        text.length >= 10
            ? text.substring(0, 10)
            : text,
      );
    }
  }

  // =====================================================
  // مجموع مبلغ شارژها
  // =====================================================

  int get totalAmount {
    int total = 0;

    for (final item in charges) {
      final amount =
          item['amount'] ?? 0;

      if (amount is num) {
        total += amount.toInt();
      } else {
        final text = amount
            .toString()
            .replaceAll(',', '')
            .replaceAll('٬', '')
            .replaceAll('.0', '');

        total +=
            int.tryParse(text) ?? 0;
      }
    }

    return total;
  }

  // =====================================================
  // Header
  // =====================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset:
            const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.construction_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'شارژ عمرانی',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight:
                    FontWeight.bold,
                    color: textColor,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'مشاهده و پرداخت هزینه‌های عمرانی ساختمان',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color:
              primaryColor.withOpacity(0.10),
              borderRadius:
              BorderRadius.circular(10),
            ),
            child: Text(
              toPersianDigits(
                charges.length.toString(),
              ),
              style: const TextStyle(
                color: primaryColor,
                fontSize: 13,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // کارت خلاصه
  // =====================================================

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius:
        BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
            primaryColor.withOpacity(0.22),
            blurRadius: 16,
            offset:
            const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
              Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'مجموع هزینه‌های عمرانی',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        formatAmount(
                          totalAmount,
                        ),
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    const Text(
                      'تومان',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // کارت شارژ
  // =====================================================

  Widget _buildChargeCard(
      Map<String, dynamic> item,
      ) {
    final id = item['id'];

    final name =
    item['name']
        ?.toString()
        .trim();

    final details =
    item['details']
        ?.toString()
        .trim();

    final amount =
        item['amount'] ?? 0;

    final prepayment =
        item['prepayment'] ?? 0;

    final installmentCount =
        item['installment_count'] ?? 0;

    final totalInstallments =
        item['total_installments'] ??
            installmentCount;

    final paidInstallments =
        item['paid_installments_count'] ??
            0;

    final firstDueDate =
    item['first_due_date'];

    return Material(
      color: Colors.white,
      borderRadius:
      BorderRadius.circular(20),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(20),
        onTap: () {
          if (id == null) {
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CivilInstallmentsScreen(
                    civilId:
                    int.tryParse(
                      id.toString(),
                    ) ??
                        0,
                    civilName:
                    name != null &&
                        name.isNotEmpty
                        ? name
                        : 'شارژ عمرانی',
                  ),
            ),
          );
        },
        child: Container(
          padding:
          const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(20),
            border: Border.all(
              color:
              Colors.black.withOpacity(0.04),
            ),
            boxShadow: [
              BoxShadow(
                color:
                Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset:
                const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              // ===============================
              // Header
              // ===============================

              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                      primaryColor.withOpacity(
                        0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        15,
                      ),
                    ),
                    child: const Icon(
                      Icons.construction_outlined,
                      color: primaryColor,
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          name != null &&
                              name.isNotEmpty
                              ? name
                              : 'شارژ عمرانی',
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight.bold,
                            color: textColor,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          details != null &&
                              details.isNotEmpty
                              ? details
                              : 'هزینه عمرانی ساختمان',
                          maxLines: 2,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: primaryColor,
                  ),
                ],
              ),

              const SizedBox(height: 15),

              const Divider(
                height: 1,
              ),

              const SizedBox(height: 14),

              // ===============================
              // مبلغ
              // ===============================

              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon:
                      Icons.payments_outlined,
                      title: 'مبلغ کل',
                      value:
                      '${formatAmount(amount)} تومان',
                    ),
                  ),

                  Container(
                    width: 1,
                    height: 42,
                    color:
                    Colors.grey.withOpacity(
                      0.20,
                    ),
                  ),

                  Expanded(
                    child: _buildInfoItem(
                      icon:
                      Icons.format_list_numbered,
                      title: 'تعداد اقساط',
                      value: toPersianDigits(
                        totalInstallments.toString(),
                      ),
                    ),
                  ),
                ],
              ),

              // ===============================
              // پیش پرداخت
              // ===============================

              if (prepayment != null &&
                  prepayment.toString() != '0')
                Padding(
                  padding:
                  const EdgeInsets.only(
                    top: 14,
                  ),
                  child: _buildInfoRow(
                    icon:
                    Icons.account_balance_wallet,
                    title: 'پیش‌پرداخت',
                    value:
                    '${formatAmount(prepayment)} تومان',
                  ),
                ),

              // ===============================
              // تاریخ شروع
              // ===============================

              if (firstDueDate != null)
                Padding(
                  padding:
                  const EdgeInsets.only(
                    top: 10,
                  ),
                  child: _buildInfoRow(
                    icon:
                    Icons.calendar_today_outlined,
                    title: 'تاریخ شروع اقساط',
                    value:
                    formatDate(firstDueDate),
                  ),
                ),

              const SizedBox(height: 14),

              // ===============================
              // Progress
              // ===============================

              _buildProgress(
                paid: int.tryParse(
                  paidInstallments.toString(),
                ) ??
                    0,
                total: int.tryParse(
                  totalInstallments.toString(),
                ) ??
                    0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // Info Item
  // =====================================================

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 19,
          color: primaryColor,
        ),

        const SizedBox(height: 5),

        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          value,
          maxLines: 1,
          overflow:
          TextOverflow.ellipsis,
          textAlign:
          TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight:
            FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // Info Row
  // =====================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      textDirection:
      TextDirection.rtl,
      children: [
        Icon(
          icon,
          color: primaryColor,
          size: 17,
        ),

        const SizedBox(width: 8),

        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),

        const Spacer(),

        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight:
            FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // Progress
  // =====================================================

  Widget _buildProgress({
    required int paid,
    required int total,
  }) {
    double progress = 0;

    if (total > 0) {
      progress = paid / total;
    }

    if (progress > 1) {
      progress = 1;
    }

    return Column(
      children: [
        Row(
          textDirection:
          TextDirection.rtl,
          children: [
            const Text(
              'وضعیت پرداخت',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),

            const Spacer(),

            Text(
              '${toPersianDigits(paid.toString())} از '
                  '${toPersianDigits(total.toString())} پرداخت شده',
              style: const TextStyle(
                fontSize: 10,
                color: primaryColor,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        ClipRRect(
          borderRadius:
          BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor:
            primaryColor.withOpacity(
              0.10,
            ),
            valueColor:
            const AlwaysStoppedAnimation(
              primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // Empty
  // =====================================================

  Widget _buildEmpty() {
    return Center(
      child: SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color:
                primaryColor.withOpacity(
                  0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.construction_outlined,
                size: 45,
                color: primaryColor,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'شارژ عمرانی وجود ندارد',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                FontWeight.bold,
                color: textColor,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'در حال حاضر هیچ شارژ عمرانی برای شما ثبت نشده است.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed:
              loadCivilCharges,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'بروزرسانی',
              ),
              style:
              OutlinedButton.styleFrom(
                foregroundColor:
                primaryColor,
                side: const BorderSide(
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Error
  // =====================================================

  Widget _buildError() {
    return Center(
      child: SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 55,
              color: Colors.redAccent,
            ),

            const SizedBox(height: 16),

            Text(
              errorMessage ??
                  'خطا در دریافت اطلاعات',
              textAlign:
              TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 18),

            ElevatedButton.icon(
              onPressed:
              loadCivilCharges,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'تلاش مجدد',
              ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                primaryColor,
                foregroundColor:
                Colors.white,
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Loading
  // =====================================================

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: primaryColor,
      ),
    );
  }

  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        backgroundColor,

        appBar: AppBar(
          backgroundColor:
          backgroundColor,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor:
          Colors.transparent,
          title: const Text(
            'شارژ عمرانی',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(
            color: textColor,
          ),
        ),

        body: RefreshIndicator(
          color: primaryColor,
          onRefresh:
          loadCivilCharges,
          child: isLoading
              ? _buildLoading()
              : errorMessage != null
              ? _buildError()
              : charges.isEmpty
              ? _buildEmpty()
              : ListView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            padding:
            const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              30,
            ),
            children: [
              _buildHeader(),

              const SizedBox(
                height: 14,
              ),

              _buildSummaryCard(),

              const SizedBox(
                height: 18,
              ),

              const Text(
                'لیست شارژهای عمرانی',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              for (
              final item
              in charges
              ) ...[
                _buildChargeCard(
                  item,
                ),

                const SizedBox(
                  height: 12,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}