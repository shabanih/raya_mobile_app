import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'manual_civil_payment_screen.dart';

class CivilPaymentMethodScreen extends StatefulWidget {
  final int installmentId;

  const CivilPaymentMethodScreen({
    super.key,
    required this.installmentId,
  });

  @override
  State<CivilPaymentMethodScreen> createState() =>
      _CivilPaymentMethodScreenState();
}

class _CivilPaymentMethodScreenState
    extends State<CivilPaymentMethodScreen> {

  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool _isSubmitting = false;

  Map<String, dynamic>? _data;

  String? _error;

  int? _selectedBankId;

  final TextEditingController _transactionController =
  TextEditingController();

  final TextEditingController _paymentDateController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _transactionController.dispose();
    _paymentDateController.dispose();
    super.dispose();
  }

  // =====================================================
  // دریافت روش‌های پرداخت
  // =====================================================

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data =
      await _apiService.getCivilInstallmentPaymentMethods(
        widget.installmentId,
      );

      if (!mounted) return;

      setState(() {
        _data = data;
        _isLoading = false;
      });

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = _cleanError(e);
      });
    }
  }

  // =====================================================
  // متن خطا
  // =====================================================

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(11);
    }

    return text;
  }

  // =====================================================
  // فرمت مبلغ
  // =====================================================

  String _formatAmount(dynamic value) {
    if (value == null) {
      return '۰';
    }

    final number =
        int.tryParse(value.toString()) ?? 0;

    final formatted =
    number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
    );

    return formatted;
  }

  // =====================================================
  // انتخاب تاریخ پرداخت
  // =====================================================

  Future<void> _selectPaymentDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      locale: const Locale('fa'),
    );

    if (selected == null) {
      return;
    }

    final date =
        '${selected.year.toString().padLeft(4, '0')}-'
        '${selected.month.toString().padLeft(2, '0')}-'
        '${selected.day.toString().padLeft(2, '0')}';

    _paymentDateController.text = date;
  }

  // =====================================================
  // ثبت پرداخت
  // =====================================================

  Future<void> _submitPayment() async {

    if (_selectedBankId == null) {
      _showMessage(
        'لطفاً حساب بانکی را انتخاب کنید.',
        isError: true,
      );
      return;
    }

    final transactionReference =
    _transactionController.text.trim();

    final paymentDate =
    _paymentDateController.text.trim();

    if (transactionReference.isEmpty) {
      _showMessage(
        'لطفاً کد پیگیری پرداخت را وارد کنید.',
        isError: true,
      );
      return;
    }

    if (paymentDate.isEmpty) {
      _showMessage(
        'لطفاً تاریخ پرداخت را انتخاب کنید.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {

      final result =
      await _apiService.submitManualCivilInstallmentPayment(
        installmentId: widget.installmentId,
        bankId: _selectedBankId!,
        transactionReference:
        transactionReference,
        paymentDate: paymentDate,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      final message =
          result['message']?.toString() ??
              'درخواست پرداخت با موفقیت ثبت شد.';

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'پرداخت ثبت شد',
              textAlign: TextAlign.right,
            ),
            content: Text(
              message,
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('متوجه شدم'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);

    } catch (e) {

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showMessage(
        _cleanError(e),
        isError: true,
      );
    }
  }

  // =====================================================
  // نمایش پیام
  // =====================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =====================================================
  // کارت اطلاعات قسط
  // =====================================================

  Widget _buildInstallmentCard() {

    final installment =
    _data?['installment'];

    if (installment is! Map) {
      return const SizedBox();
    }

    final civilName =
        installment['civil_name']?.toString() ??
            'شارژ عمرانی';

    final installmentNumber =
        installment['installment_number']?.toString() ??
            '-';

    final amount =
    installment['amount'];

    final dueDate =
        installment['due_date']?.toString() ??
            '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [

          const Text(
            'شارژ عمرانی',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            civilName,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [

              Expanded(
                child: _buildInfoItem(
                  title: 'شماره قسط',
                  value: installmentNumber,
                ),
              ),

              Expanded(
                child: _buildInfoItem(
                  title: 'مبلغ',
                  value:
                  '${_formatAmount(amount)} تومان',
                ),
              ),

            ],
          ),

          const SizedBox(height: 14),

          _buildInfoItem(
            title: 'تاریخ سررسید',
            value: dueDate,
          ),
        ],
      ),
    );
  }

  // =====================================================
  // آیتم اطلاعات
  // =====================================================

  Widget _buildInfoItem({
    required String title,
    required String value,
  }) {

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [

        Text(
          title,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // =====================================================
  // کارت حساب بانکی
  // =====================================================

  Widget _buildBankCard(
      Map bank,
      ) {

    final bankId =
    int.tryParse(
      bank['id'].toString(),
    );

    final selected =
        _selectedBankId == bankId;

    final bankName =
        bank['bank_name']?.toString() ??
            'بانک';

    final accountNumber =
        bank['account_no']?.toString() ??
            '-';

    final cardNumber =
        bank['cart_number']?.toString() ??
            '-';

    final sheba =
        bank['sheba_number']?.toString() ??
            '-';

    final holder =
        bank['account_holder_name']
            ?.toString() ??
            '-';

    return GestureDetector(
      onTap: () {

        if (bankId == null) {
          return;
        }

        setState(() {
          _selectedBankId = bankId;
        });
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(18),
          border: Border.all(
            width: selected ? 2 : 1,
            color: selected
                ? const Color(0xff00ACC1)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset:
              const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [

            Row(
              children: [

                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected
                      ? const Color(0xff00ACC1)
                      : Colors.grey,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    bankName,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            if (holder != '-')
              _buildBankRow(
                'صاحب حساب',
                holder,
              ),

            if (accountNumber != '-')
              _buildBankRow(
                'شماره حساب',
                accountNumber,
              ),

            if (cardNumber != '-')
              _buildBankRow(
                'شماره کارت',
                cardNumber,
              ),

            if (sheba != '-')
              _buildBankRow(
                'شماره شبا',
                sheba,
              ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // ردیف اطلاعات بانک
  // =====================================================

  Widget _buildBankRow(
      String title,
      String value,
      ) {

    return Padding(
      padding:
      const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Text(
            title,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // فرم ثبت پرداخت
  // =====================================================

  Widget _buildPaymentForm() {

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset:
            const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [

          const Text(
            'ثبت اطلاعات واریز',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          TextField(
            controller:
            _transactionController,
            keyboardType:
            TextInputType.number,
            textDirection:
            TextDirection.ltr,
            decoration:
            InputDecoration(
              labelText:
              'کد پیگیری',
              hintText:
              'کد پیگیری واریز را وارد کنید',
              prefixIcon:
              const Icon(
                Icons.receipt_long,
              ),
              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller:
            _paymentDateController,
            readOnly: true,
            textDirection:
            TextDirection.ltr,
            onTap:
            _selectPaymentDate,
            decoration:
            InputDecoration(
              labelText:
              'تاریخ پرداخت',
              hintText:
              'تاریخ واریز را انتخاب کنید',
              prefixIcon:
              const Icon(
                Icons.calendar_month,
              ),
              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed:
              _isSubmitting
                  ? null
                  : _submitPayment,
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xff00ACC1),
                foregroundColor:
                Colors.white,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(15),
                ),
              ),
              child:
              _isSubmitting
                  ? const SizedBox(
                width: 24,
                height: 24,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color:
                  Colors.white,
                ),
              )
                  : const Text(
                'ثبت درخواست پرداخت',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // صفحه اصلی
  // =====================================================

  @override
  Widget build(BuildContext context) {

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(

        backgroundColor:
        const Color(0xffF6F8FA),

        appBar: AppBar(
          title: const Text(
            'روش پرداخت قسط عمرانی',
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor:
          const Color(0xff00ACC1),
          foregroundColor:
          Colors.white,
        ),

        body: _buildBody(),
      ),
    );
  }

  // =====================================================
  // Body
  // =====================================================

  Widget _buildBody() {

    if (_isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(
          color:
          Color(0xff00ACC1),
        ),
      );
    }

    if (_error != null) {

      return Center(
        child: Padding(
          padding:
          const EdgeInsets.all(24),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [

              const Icon(
                Icons.error_outline,
                size: 55,
                color: Colors.redAccent,
              ),

              const SizedBox(height: 15),

              Text(
                _error!,
                textAlign:
                TextAlign.center,
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed:
                _loadPaymentMethods,
                child:
                const Text(
                  'تلاش مجدد',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final banks =
    _data?['payment_banks'];

    final paymentMethods =
    _data?['payment_methods'];

    final hasBanks =
        banks is List && banks.isNotEmpty;

    final hasManualPayment =
        paymentMethods is List &&
            paymentMethods.any(
                  (item) =>
              item is Map &&
                  item['type'] == 'manual' &&
                  item['available'] == true,
            );

    if (!hasBanks ||
        !hasManualPayment) {

      return ListView(
        padding:
        const EdgeInsets.all(16),
        children: [

          _buildInstallmentCard(),

          const SizedBox(height: 20),

          Container(
            padding:
            const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(20),
            ),
            child: const Column(
              children: [

                Icon(
                  Icons.account_balance_outlined,
                  size: 50,
                  color: Colors.grey,
                ),

                SizedBox(height: 12),

                Text(
                  'حساب بانکی برای پرداخت این قسط ثبت نشده است.',
                  textAlign:
                  TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding:
      const EdgeInsets.all(16),
      children: [

        _buildInstallmentCard(),

        const SizedBox(height: 22),

        const Text(
          'روش پرداخت',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding:
          const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(18),
            border: Border.all(
              color:
              const Color(0xff00ACC1),
            ),
          ),
          child: Row(
            children: [

              const Icon(
                Icons.credit_card,
                color:
                Color(0xff00ACC1),
                size: 30,
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [

                    Text(
                      'کارت به کارت',
                      textAlign:
                      TextAlign.right,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'واریز مبلغ قسط به حساب ساختمان و ثبت کد پیگیری',
                      textAlign:
                      TextAlign.right,
                      style: TextStyle(
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

        const SizedBox(height: 22),

        const Text(
          'حساب‌های بانکی ساختمان',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        ...banks
            .whereType<Map>()
            .map(
              (bank) =>
              _buildBankCard(bank),
        ),

        const SizedBox(height: 8),

        _buildPaymentForm(),

        const SizedBox(height: 30),
      ],
    );
  }
}