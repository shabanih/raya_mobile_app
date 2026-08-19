import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ManualPaymentScreen extends StatefulWidget {
  final int chargeId;
  final Map<String, dynamic> charge;
  final List<Map<String, dynamic>> banks;

  const ManualPaymentScreen({
    super.key,
    required this.chargeId,
    required this.charge,
    required this.banks,
  });

  @override
  State<ManualPaymentScreen> createState() =>
      _ManualPaymentScreenState();
}

class _ManualPaymentScreenState
    extends State<ManualPaymentScreen> {
  final ApiService _apiService = ApiService();

  final TextEditingController transactionController =
  TextEditingController();

  Map<String, dynamic>? selectedBank;

  DateTime? selectedDate;

  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();

    if (widget.banks.isNotEmpty) {
      selectedBank = widget.banks.firstWhere(
            (bank) => bank['is_default'] == true,
        orElse: () => widget.banks.first,
      );
    }
  }

  @override
  void dispose() {
    transactionController.dispose();
    super.dispose();
  }

  String toPersianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    for (int i = 0; i < english.length; i++) {
      value = value.replaceAll(
        english[i],
        persian[i],
      );
    }

    return value;
  }

  String formatAmount(dynamic value) {
    final amount =
        int.tryParse(value?.toString() ?? '0') ?? 0;

    final text = amount.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 &&
          (text.length - i) % 3 == 0) {
        buffer.write('٬');
      }

      buffer.write(text[i]);
    }

    return toPersianDigits(
      buffer.toString(),
    );
  }

  String formatDate(DateTime date) {
    return toPersianDigits(
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}',
    );
  }

  Future<void> selectDate() async {
    final now = DateTime.now();

    final result = await showDatePicker(
      context: context,
      initialDate:
      selectedDate ?? now,
      firstDate:
      DateTime(now.year - 2),
      lastDate:
      now,
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
      });
    }
  }

  Future<void> submitPayment() async {
    if (selectedBank == null) {
      _showMessage(
        'لطفاً حساب بانکی را انتخاب کنید.',
      );
      return;
    }

    if (transactionController.text
        .trim()
        .isEmpty) {
      _showMessage(
        'لطفاً کد پیگیری را وارد کنید.',
      );
      return;
    }

    if (selectedDate == null) {
      _showMessage(
        'لطفاً تاریخ پرداخت را انتخاب کنید.',
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final paymentDate =
          '${selectedDate!.year}-'
          '${selectedDate!.month.toString().padLeft(2, '0')}-'
          '${selectedDate!.day.toString().padLeft(2, '0')}';

      final result =
      await _apiService.submitManualChargePayment(
        chargeId: widget.chargeId,
        bankId: selectedBank!['id'],
        transactionReference:
        transactionController.text.trim(),
        paymentDate: paymentDate,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return Directionality(
              textDirection:
              TextDirection.rtl,
              child: AlertDialog(
                title: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    SizedBox(width: 8),
                    Text('پرداخت ثبت شد'),
                  ],
                ),
                content: const Text(
                  'پرداخت شارژ با موفقیت ثبت شد.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'باشه',
                    ),
                  ),
                ],
              ),
            );
          },
        );

        if (!mounted) return;

        Navigator.pop(
          context,
          true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection:
          TextDirection.rtl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.charge['title']
            ?.toString() ??
            'شارژ';

    final amount =
        widget.charge['amount'] ?? 0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        const Color(0xffF7F9FA),
        appBar: AppBar(
          title: const Text(
            'پرداخت دستی',
          ),
          centerTitle: true,
          backgroundColor:
          const Color(0xff00ACC1),
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _buildChargeInfo(
              title,
              amount,
            ),

            const SizedBox(height: 22),

            const Text(
              'حساب مقصد',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (widget.banks.isEmpty)
              _buildNoBank()
            else
              ...widget.banks.map(
                _buildBankCard,
              ),

            const SizedBox(height: 22),

            const Text(
              'کد پیگیری',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller:
              transactionController,
              keyboardType:
              TextInputType.number,
              decoration:
              InputDecoration(
                hintText:
                'کد پیگیری را وارد کنید',
                prefixIcon: const Icon(
                  Icons.confirmation_number_outlined,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(15),
                  borderSide:
                  BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'تاریخ پرداخت',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            InkWell(
              onTap: selectDate,
              borderRadius:
              BorderRadius.circular(15),
              child: Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color:
                      Color(0xff00ACC1),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedDate == null
                            ? 'انتخاب تاریخ پرداخت'
                            : formatDate(
                          selectedDate!,
                        ),
                        style: TextStyle(
                          color:
                          selectedDate == null
                              ? Colors.grey
                              : const Color(
                            0xff263238,
                          ),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons
                          .keyboard_arrow_down_rounded,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed:
                isSubmitting ||
                    widget.banks.isEmpty
                    ? null
                    : submitPayment,
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xff610DB5),
                  foregroundColor:
                  Colors.white,
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                    Colors.white,
                  ),
                )
                    : const Text(
                  'ثبت پرداخت',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChargeInfo(
      String title,
      dynamic amount,
      ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${formatAmount(amount)} تومان',
            style: const TextStyle(
              fontSize: 20,
              fontWeight:
              FontWeight.bold,
              color: Color(0xff610DB5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard(
      Map<String, dynamic> bank,
      ) {
    final isSelected =
        selectedBank?['id'] ==
            bank['id'];

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBank = bank;
        });
      },
      child: Container(
        margin:
        const EdgeInsets.only(bottom: 10),
        padding:
        const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? const Color(0xff00ACC1)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected
                  ? const Color(0xff00ACC1)
                  : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    bank['bank_name']
                        ?.toString() ??
                        '-',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'شماره کارت: ${bank['cart_number'] ?? '-'}',
                    style:
                    const TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'صاحب حساب: ${bank['account_holder_name'] ?? '-'}',
                    style:
                    const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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

  Widget _buildNoBank() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.orange
            .withOpacity(0.08),
        borderRadius:
        BorderRadius.circular(15),
      ),
      child: const Text(
        'برای این ساختمان حساب بانکی فعالی برای پرداخت دستی ثبت نشده است.',
        style: TextStyle(
          color: Colors.orange,
          fontSize: 13,
        ),
      ),
    );
  }
}