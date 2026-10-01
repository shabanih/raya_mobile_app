import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/api_service.dart';
import '../../services/manager_bank_service.dart';

class ManagerBankTransfersScreen extends StatefulWidget {
  final int? houseId;
  final String? houseName;

  const ManagerBankTransfersScreen({
    super.key,
    this.houseId,
    this.houseName,
  });

  @override
  State<ManagerBankTransfersScreen> createState() =>
      _ManagerBankTransfersScreenState();
}

class _ManagerBankTransfersScreenState
    extends State<ManagerBankTransfersScreen> {
  // =====================================================
  // رنگ اصلی
  // =====================================================

  static const Color primaryColor =
  Color(0xff00ACC1);

  static const Color darkPrimaryColor =
  Color(0xff00838F);

  // =====================================================
  // Service
  // =====================================================

  late final ManagerBankService _bankService;

  // =====================================================
  // وضعیت
  // =====================================================

  bool _isLoading = true;
  bool _isLoadingBanks = false;

  String? _errorMessage;

  List<Map<String, dynamic>> _transfers = [];
  List<Map<String, dynamic>> _banks = [];

  // =====================================================
  // Init
  // =====================================================

  @override
  void initState() {
    super.initState();

    _bankService = ManagerBankService(
      apiService: ApiService(),
    );

    _loadData();
  }

  // =====================================================
  // دریافت اطلاعات
  // =====================================================

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _bankService.getBankTransfers(),
        _bankService.getBanks(),
      ]);

      if (!mounted) return;

      setState(() {
        _transfers = List<Map<String, dynamic>>.from(
          results[0] as List,
        );

        _banks = List<Map<String, dynamic>>.from(
          results[1] as List,
        );

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  // =====================================================
  // انتقال جدید
  // =====================================================

  Future<void> _openCreateTransfer() async {
    if (_isLoadingBanks) return;

    if (_banks.length < 2) {
      _showMessage(
        'برای انتقال بین بانکی حداقل دو حساب بانکی فعال لازم است.',
        isError: true,
      );
      return;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _BankTransferFormSheet(
          banks: _banks,
          service: _bankService,
          houseId: widget.houseId,
          houseName: widget.houseName,
        );
      },
    );

    if (result == true) {
      await _loadData();
    }
  }

  // =====================================================
  // لغو انتقال
  // =====================================================

  Future<void> _cancelTransfer(
      Map<String, dynamic> transfer,
      ) async {
    final id = _toInt(
      transfer['id'],
    );

    if (id == null) {
      _showMessage(
        'شناسه انتقال نامعتبر است.',
        isError: true,
      );
      return;
    }

    final fromBank =
        transfer['from_bank_name']?.toString() ??
            'نامشخص';

    final toBank =
        transfer['to_bank_name']?.toString() ??
            'نامشخص';

    final amount = _formatAmount(
      transfer['amount'],
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'لغو انتقال',
            textAlign: TextAlign.right,
          ),
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              'آیا از لغو این انتقال مطمئن هستید؟\n\n'
                  'از: $fromBank\n'
                  'به: $toBank\n'
                  'مبلغ: $amount تومان',
              textAlign: TextAlign.right,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'انصراف',
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'لغو انتقال',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    _showLoadingDialog();

    try {
      await _bankService.deleteBankTransfer(
        id,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      _showMessage(
        'انتقال با موفقیت لغو شد.',
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop();

      _showMessage(
        _cleanError(e),
        isError: true,
      );
    }
  }

  // =====================================================
  // Loading Dialog
  // =====================================================

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // Body
  // =====================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 55,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'تلاش مجدد',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_transfers.isEmpty) {
      return RefreshIndicator(
        color: primaryColor,
        onRefresh: _loadData,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 100),
            Icon(
              Icons.swap_horiz,
              size: 75,
              color: primaryColor.withOpacity(.45),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'هنوز انتقال بین بانکی ثبت نشده است.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'برای انتقال وجه بین حساب‌ها،\n'
                    'دکمه «انتقال جدید» را بزنید.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  height: 1.7,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          12,
          12,
          12,
          100,
        ),
        itemCount: _transfers.length,
        itemBuilder: (context, index) {
          return _buildTransferCard(
            _transfers[index],
          );
        },
      ),
    );
  }

  // =====================================================
  // کارت انتقال
  // =====================================================

  Widget _buildTransferCard(
      Map<String, dynamic> transfer,
      ) {
    final fromBank =
        transfer['from_bank_name']?.toString() ??
            'نامشخص';

    final toBank =
        transfer['to_bank_name']?.toString() ??
            'نامشخص';

    final amount = _formatAmount(
      transfer['amount'],
    );

    final date = _formatJalaliDate(
      transfer['payment_date'],
    );

    final createDate = _formatDateTime(
      transfer['created_at'],
    );

    final transactionNo =
    transfer['transaction_no']?.toString();

    final documentNumber =
    transfer['financial_document_number']
        ?.toString();

    final description = (
        transfer['payment_description'] ??
            transfer['description']
    )?.toString().trim();

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      elevation: 3,
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            // =================================================
            // Header
            // =================================================

            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                    primaryColor.withOpacity(.12),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.swap_horiz,
                    color: primaryColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'انتقال بین بانکی',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                    Colors.green.withOpacity(.10),
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'انجام شده',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // =================================================
            // مسیر انتقال
            // =================================================

            _buildTransferSummary(
              fromBank,
              toBank,
            ),

            const SizedBox(height: 12),

            // =================================================
            // اطلاعات انتقال
            // =================================================

            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xffF7FAFB),
                borderRadius:
                BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    'مبلغ',
                    '$amount تومان',
                    isAmount: true,
                  ),
                  if (date.isNotEmpty)
                    _buildInfoRow(
                      'تاریخ انتقال',
                      date,
                    ),
                  if (transactionNo != null &&
                      transactionNo.trim().isNotEmpty)
                    _buildInfoRow(
                      'شماره تراکنش',
                      transactionNo,
                    ),
                  if (documentNumber != null &&
                      documentNumber.trim().isNotEmpty)
                    _buildInfoRow(
                      'شماره سند مالی',
                      documentNumber,
                    ),
                  if (description != null &&
                      description.trim().isNotEmpty)
                    _buildInfoRow(
                      'شرح انتقال',
                      description,
                    ),
                  if (createDate.isNotEmpty)
                    _buildInfoRow(
                      'تاریخ ثبت',
                      createDate,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // =================================================
            // لغو
            // =================================================

            SizedBox(
              height: 45,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _cancelTransfer(transfer),
                icon: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.red,
                ),
                label: const Text(
                  'لغو انتقال',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style:
                OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Colors.red.shade300,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // خلاصه مسیر انتقال
  // =====================================================

  Widget _buildTransferSummary(
      String fromBank,
      String toBank,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withOpacity(.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.swap_horiz,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              textAlign: TextAlign.right,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
                children: [
                  const TextSpan(
                    text: 'انتقال از ',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  TextSpan(
                    text: fromBank,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(
                    text: ' به ',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  TextSpan(
                    text: toBank,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ردیف اطلاعات
  // =====================================================

  Widget _buildInfoRow(
      String title,
      String value, {
        bool isAmount = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _toPersianDigits(value),
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: isAmount ? 14 : 12,
                fontWeight: isAmount
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: isAmount
                    ? darkPrimaryColor
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Helpers
  // =====================================================

  int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    return int.tryParse(
      value.toString(),
    );
  }

  String _formatAmount(dynamic value) {
    final number = _toInt(value) ?? 0;

    final text =
    number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
    );

    return _toPersianDigits(text);
  }

  String _toPersianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(
        english[i],
        persian[i],
      );
    }

    return result;
  }

  String _formatJalaliDate(dynamic value) {
    if (value == null) return '';

    final text = value.toString().trim();

    if (text.isEmpty) return '';

    try {
      final date = DateTime.tryParse(text);

      if (date == null) {
        return _toPersianDigits(
          text.split('T').first,
        );
      }

      final jalali =
      Jalali.fromDateTime(date);

      return _toPersianDigits(
        '${jalali.year}/'
            '${jalali.month.toString().padLeft(2, '0')}/'
            '${jalali.day.toString().padLeft(2, '0')}',
      );
    } catch (_) {
      return _toPersianDigits(
        text.split('T').first,
      );
    }
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '';

    final text = value.toString().trim();

    if (text.isEmpty) return '';

    try {
      final date = DateTime.tryParse(text);

      if (date == null) {
        return '';
      }

      final jalali =
      Jalali.fromDateTime(date);

      return _toPersianDigits(
        '${jalali.year}/'
            '${jalali.month.toString().padLeft(2, '0')}/'
            '${jalali.day.toString().padLeft(2, '0')} '
            '${date.hour.toString().padLeft(2, '0')}:'
            '${date.minute.toString().padLeft(2, '0')}',
      );
    } catch (_) {
      return '';
    }
  }

  String _cleanError(dynamic error) {
    var text = error.toString();

    if (text.startsWith('Exception: ')) {
      text = text.substring(
        'Exception: '.length,
      );
    }

    return text.trim();
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
        ),
        backgroundColor: isError
            ? Colors.red.shade700
            : Colors.green.shade700,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'انتقال بین بانکی',
          ),
          centerTitle: true,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'بروزرسانی',
              onPressed: _loadData,
              icon: const Icon(
                Icons.refresh,
              ),
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButton:
        FloatingActionButton.extended(
          onPressed: _openCreateTransfer,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(
            Icons.add,
          ),
          label: const Text(
            'انتقال جدید',
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// فرم انتقال جدید
// ============================================================================

class _BankTransferFormSheet extends StatefulWidget {
  final List<Map<String, dynamic>> banks;
  final ManagerBankService service;
  final int? houseId;
  final String? houseName;

  const _BankTransferFormSheet({
    required this.banks,
    required this.service,
    this.houseId,
    this.houseName,
  });

  @override
  State<_BankTransferFormSheet> createState() =>
      _BankTransferFormSheetState();
}

class _BankTransferFormSheetState
    extends State<_BankTransferFormSheet> {
  static const Color primaryColor =
  Color(0xff00ACC1);

  static const Color darkPrimaryColor =
  Color(0xff00838F);

  final _formKey =
  GlobalKey<FormState>();

  final _amountController =
  TextEditingController();

  final _transactionController =
  TextEditingController();

  final _descriptionController =
  TextEditingController();

  int? _fromBankId;
  int? _toBankId;

  DateTime _paymentDate =
  DateTime.now();

  bool _isSaving = false;

  // =====================================================
  // Init
  // =====================================================

  @override
  void initState() {
    super.initState();

    if (widget.banks.length >= 2) {
      _fromBankId = _toInt(
        widget.banks[0]['id'],
      );

      _toBankId = _toInt(
        widget.banks[1]['id'],
      );
    }
  }

  // =====================================================
  // Dispose
  // =====================================================

  @override
  void dispose() {
    _amountController.dispose();
    _transactionController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  // =====================================================
// تبدیل اعداد انگلیسی به فارسی
// =====================================================

  String _toPersianDigits(String value) {
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

  // =====================================================
  // نام ماه جلالی
  // =====================================================

  String _jalaliMonthName(int month) {
    const months = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];

    if (month < 1 || month > 12) {
      return '';
    }

    return months[month - 1];
  }

  // =====================================================
  // تقویم جلالی
  // =====================================================

  Widget _buildJalaliCalendar({
    required Jalali month,
    required Jalali selectedDate,
    required ValueChanged<Jalali> onSelected,
  }) {
    final firstDay = Jalali(
      month.year,
      month.month,
      1,
    );

    final int daysInMonth =
    month.month <= 6
        ? 31
        : month.month <= 11
        ? 30
        : month.isLeapYear()
        ? 30
        : 29;

    /*
      در shamsi_date:
      شنبه    = 0
      یکشنبه  = 1
      دوشنبه  = 2
      سه‌شنبه = 3
      چهارشنبه= 4
      پنجشنبه = 5
      جمعه    = 6
    */

    final int leadingDays =
        firstDay.weekDay;

    final int totalCells =
        ((leadingDays + daysInMonth) / 7)
            .ceil() *
            7;

    return GridView.builder(
      physics:
      const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate:
      const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.15,
      ),
      itemBuilder:
          (context, index) {
        final int dayNumber =
            index -
                leadingDays +
                1;

        if (dayNumber < 1 ||
            dayNumber > daysInMonth) {
          return const SizedBox();
        }

        final date = Jalali(
          month.year,
          month.month,
          dayNumber,
        );

        final bool isSelected =
            date.year ==
                selectedDate.year &&
                date.month ==
                    selectedDate.month &&
                date.day ==
                    selectedDate.day;

        return InkWell(
          borderRadius:
          BorderRadius.circular(10),
          onTap: () {
            onSelected(date);
          },
          child: Container(
            margin:
            const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor
                  : Colors.transparent,
              borderRadius:
              BorderRadius.circular(10),
            ),
            alignment:
            Alignment.center,
            child: Text(
              _toPersianDigits(
                dayNumber.toString(),
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // نمایش تقویم جلالی
  // =====================================================

  Future<Jalali?> _showJalaliDateDialog({
    required Jalali initialDate,
    required String title,
  }) async {
    return showDialog<Jalali>(
      context: context,
      builder: (dialogContext) {
        Jalali selectedDate =
            initialDate;

        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor:
              Colors.white,
              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(20),
              ),
              titlePadding:
              const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                5,
              ),
              contentPadding:
              const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                8,
              ),
              actionsPadding:
              const EdgeInsets.fromLTRB(
                16,
                4,
                16,
                12,
              ),
              title: Row(
                textDirection:
                TextDirection.rtl,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration:
                    BoxDecoration(
                      color:
                      primaryColor
                          .withOpacity(.10),
                      borderRadius:
                      BorderRadius.circular(
                        11,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .calendar_month_outlined,
                      color:
                      primaryColor,
                      size: 21,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign:
                      TextAlign.right,
                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Color(0xff263238),
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 360,
                height: 390,
                child: Directionality(
                  textDirection:
                  TextDirection.rtl,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 5,
                      ),

                      // =========================================
                      // Header ماه
                      // =========================================

                      Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 6,
                          vertical: 5,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          primaryColor
                              .withOpacity(
                            .06,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            13,
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip:
                              'ماه قبل',
                              onPressed: () {
                                setDialogState(
                                      () {
                                    selectedDate =
                                        selectedDate
                                            .addMonths(
                                          -1,
                                        );
                                  },
                                );
                              },
                              icon:
                              const Icon(
                                Icons
                                    .chevron_right,
                                color:
                                darkPrimaryColor,
                              ),
                            ),

                            Expanded(
                              child: Center(
                                child: Text(
                                  '${_jalaliMonthName(selectedDate.month)} '
                                      '${_toPersianDigits(selectedDate.year.toString())}',
                                  style:
                                  const TextStyle(
                                    fontSize:
                                    15,
                                    fontWeight:
                                    FontWeight.bold,
                                    color:
                                    Color(
                                      0xff263238,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            IconButton(
                              tooltip:
                              'ماه بعد',
                              onPressed: () {
                                setDialogState(
                                      () {
                                    selectedDate =
                                        selectedDate
                                            .addMonths(
                                          1,
                                        );
                                  },
                                );
                              },
                              icon:
                              const Icon(
                                Icons
                                    .chevron_left,
                                color:
                                darkPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      // =========================================
                      // نام روزهای هفته
                      // =========================================

                      Row(
                        children: [
                          for (final day
                          in [
                            'ش',
                            'ی',
                            'د',
                            'س',
                            'چ',
                            'پ',
                            'ج',
                          ])
                            Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style:
                                  TextStyle(
                                    fontSize:
                                    12,
                                    fontWeight:
                                    FontWeight.bold,
                                    color:
                                    Colors.grey
                                        .shade600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(
                        height: 7,
                      ),

                      const Divider(
                        height: 1,
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      // =========================================
                      // روزهای ماه
                      // =========================================

                      Expanded(
                        child:
                        _buildJalaliCalendar(
                          month:
                          selectedDate,
                          selectedDate:
                          selectedDate,
                          onSelected:
                              (date) {
                            setDialogState(
                                  () {
                                selectedDate =
                                    date;
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text(
                    'انصراف',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      selectedDate,
                    );
                  },
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    primaryColor,
                    foregroundColor:
                    Colors.white,
                    elevation: 0,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        11,
                      ),
                    ),
                  ),
                  child: const Text(
                    'تأیید',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =====================================================
  // انتخاب تاریخ انتقال - جلالی واقعی
  // =====================================================

  Future<void> _selectPaymentDate() async {
    final Jalali initialDate =
    Jalali.fromDateTime(
      _paymentDate,
    );

    final Jalali? picked =
    await _showJalaliDateDialog(
      initialDate: initialDate,
      title: 'انتخاب تاریخ انتقال',
    );

    if (picked == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _paymentDate =
          picked.toDateTime();
    });
  }

  // =====================================================
  // ذخیره
  // =====================================================

  Future<void> _save() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fromBankId == null ||
        _toBankId == null) {
      _showError(
        'حساب مبدأ و مقصد را انتخاب کنید.',
      );
      return;
    }

    if (_fromBankId == _toBankId) {
      _showError(
        'حساب مبدأ و مقصد نمی‌توانند یکسان باشند.',
      );
      return;
    }

    final amount = _parseAmount(
      _amountController.text,
    );

    if (amount <= 0) {
      _showError(
        'مبلغ انتقال باید بیشتر از صفر باشد.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.service.createBankTransfer(
        fromBankId: _fromBankId!,
        toBankId: _toBankId!,
        amount: amount,
        transactionReference:
        _transactionController.text
            .trim()
            .isEmpty
            ? null
            : _transactionController.text
            .trim(),
        paymentDate: _formatDateForApi(
          _paymentDate,
        ),
        paymentDescription:
        _descriptionController.text
            .trim()
            .isEmpty
            ? null
            : _descriptionController.text
            .trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showError(
        _cleanError(e),
      );
    }
  }

  // =====================================================
  // تبدیل مبلغ
  // =====================================================

  int _parseAmount(String value) {
    var text = value.replaceAll(
      ',',
      '',
    );

    text = _normalizeDigits(
      text,
    );

    return int.tryParse(text) ?? 0;
  }

  String _normalizeDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const english = '0123456789';

    var result = value;

    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(
        persian[i],
        english[i],
      );

      result = result.replaceAll(
        arabic[i],
        english[i],
      );
    }

    return result;
  }

  // =====================================================
  // تاریخ API
  // =====================================================

  String _formatDateForApi(
      DateTime date,
      ) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // =====================================================
  // نمایش تاریخ انتخاب شده
  // =====================================================

  String _formatSelectedDate() {
    final jalali =
    Jalali.fromDateTime(
      _paymentDate,
    );

    return _toPersianDigits(
      '${jalali.year}/'
          '${jalali.month.toString().padLeft(2, '0')}/'
          '${jalali.day.toString().padLeft(2, '0')}',
    );
  }

  // =====================================================
  // نمایش نام بانک
  // =====================================================

  String _bankName(
      Map<String, dynamic> bank,
      ) {
    return bank['bank_name']?.toString() ??
        'حساب بانکی';
  }

  String _bankSubtitle(
      Map<String, dynamic> bank,
      ) {
    final account =
    bank['account_no']
        ?.toString()
        .trim();

    if (account != null &&
        account.isNotEmpty) {
      return 'حساب: ${_toPersianDigits(account)}';
    }

    final house =
    bank['house_name']
        ?.toString()
        .trim();

    if (house != null &&
        house.isNotEmpty) {
      return house;
    }

    return '';
  }

  // =====================================================
  // بانک مبدأ
  // =====================================================

  Widget _buildFromBankSelector() {
    return DropdownButtonFormField<int>(
      value: _fromBankId,
      isExpanded: true,
      decoration: _inputDecoration(
        'حساب مبدأ',
        Icons.account_balance,
      ),
      items: widget.banks
          .map(
            (bank) {
          final id = _toInt(
            bank['id'],
          );

          if (id == null) {
            return null;
          }

          return DropdownMenuItem<int>(
            value: id,
            child: Text(
              _bankName(bank),
              overflow:
              TextOverflow.ellipsis,
            ),
          );
        },
      )
          .whereType<
          DropdownMenuItem<int>>()
          .toList(),
      onChanged: _isSaving
          ? null
          : (value) {
        setState(() {
          _fromBankId = value;

          if (_toBankId == value) {
            final other =
            widget.banks.firstWhere(
                  (bank) =>
              _toInt(
                bank['id'],
              ) !=
                  value,
              orElse: () => {},
            );

            _toBankId =
                _toInt(
                  other['id'],
                );
          }
        });
      },
      validator: (value) {
        if (value == null) {
          return 'حساب مبدأ را انتخاب کنید.';
        }

        return null;
      },
    );
  }

  // =====================================================
  // بانک مقصد
  // =====================================================

  Widget _buildToBankSelector() {
    final availableBanks =
    widget.banks.where(
          (bank) =>
      _toInt(
        bank['id'],
      ) !=
          _fromBankId,
    );

    return DropdownButtonFormField<int>(
      value: _toBankId != _fromBankId
          ? _toBankId
          : null,
      isExpanded: true,
      decoration: _inputDecoration(
        'حساب مقصد',
        Icons.account_balance,
      ),
      items: availableBanks
          .map(
            (bank) {
          final id = _toInt(
            bank['id'],
          );

          if (id == null) {
            return null;
          }

          return DropdownMenuItem<int>(
            value: id,
            child: Text(
              _bankName(bank),
              overflow:
              TextOverflow.ellipsis,
            ),
          );
        },
      )
          .whereType<
          DropdownMenuItem<int>>()
          .toList(),
      onChanged: _isSaving
          ? null
          : (value) {
        setState(() {
          _toBankId = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'حساب مقصد را انتخاب کنید.';
        }

        if (value == _fromBankId) {
          return 'حساب مقصد باید با مبدأ متفاوت باشد.';
        }

        return null;
      },
    );
  }

  // =====================================================
  // مبلغ
  // =====================================================

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType:
      TextInputType.number,
      textDirection:
      TextDirection.ltr,
      textAlign: TextAlign.left,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(
            r'[0-9۰-۹٠-٩,]',
          ),
        ),
      ],
      decoration:
      _inputDecoration(
        'مبلغ انتقال',
        Icons.payments_outlined,
      ).copyWith(
        suffixText: 'تومان',
      ),
      validator: (value) {
        final amount =
        _parseAmount(
          value ?? '',
        );

        if (amount <= 0) {
          return 'مبلغ انتقال را وارد کنید.';
        }

        return null;
      },
    );
  }

  // =====================================================
  // شماره تراکنش
  // =====================================================

  Widget _buildTransactionField() {
    return TextFormField(
      controller:
      _transactionController,
      textDirection:
      TextDirection.ltr,
      textAlign: TextAlign.left,
      decoration:
      _inputDecoration(
        'شماره تراکنش',
        Icons.receipt_long_outlined,
      ).copyWith(
        hintText: 'اختیاری',
      ),
    );
  }

  // =====================================================
  // توضیحات
  // =====================================================

  Widget _buildDescriptionField() {
    return TextFormField(
      controller:
      _descriptionController,
      maxLines: 3,
      enabled: !_isSaving,
      textDirection:
      TextDirection.rtl,
      textAlign: TextAlign.right,
      decoration:
      _inputDecoration(
        'شرح انتقال',
        Icons.description_outlined,
      ).copyWith(
        hintText:
        'مثلاً بابت پرداخت قبض برق، خرید لوازم مشاعات و...',
      ),
    );
  }

  // =====================================================
  // تاریخ
  // =====================================================

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _isSaving
          ? null
          : _selectPaymentDate,
      borderRadius:
      BorderRadius.circular(13),
      child: InputDecorator(
        decoration:
        _inputDecoration(
          'تاریخ انتقال',
          Icons.calendar_month_outlined,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatSelectedDate(),
                textAlign:
                TextAlign.right,
                style:
                const TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Decoration
  // =====================================================

  InputDecoration _inputDecoration(
      String label,
      IconData icon,
      ) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: primaryColor,
      ),
      filled: true,
      fillColor: Colors.white,
      border:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          13,
        ),
        borderSide: BorderSide(
          color:
          Colors.grey.shade300,
        ),
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          13,
        ),
        borderSide: BorderSide(
          color:
          Colors.grey.shade300,
        ),
      ),
      focusedBorder:
      const OutlineInputBorder(
        borderRadius:
        BorderRadius.all(
          Radius.circular(13),
        ),
        borderSide: BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
    );
  }

  // =====================================================
  // خطا
  // =====================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
        ),
        backgroundColor:
        Colors.red.shade700,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  String _cleanError(dynamic error) {
    var text =
    error.toString();

    if (text.startsWith(
      'Exception: ',
    )) {
      text = text.substring(
        'Exception: '.length,
      );
    }

    return text.trim();
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  // =====================================================
  // Build فرم
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.only(
            top: 25,
          ),
          child: Container(
            decoration:
            const BoxDecoration(
              color:
              Color(0xffF7F9FA),
              borderRadius:
              BorderRadius.vertical(
                top:
                Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                // =================================================
                // Header
                // =================================================

                Padding(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    18,
                    14,
                    12,
                    8,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'انتقال جدید',
                          style:
                          TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                        _isSaving
                            ? null
                            : () =>
                            Navigator.pop(
                              context,
                            ),
                        icon:
                        const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(
                  height: 1,
                ),

                // =================================================
                // Form
                // =================================================

                Expanded(
                  child:
                  SingleChildScrollView(
                    padding:
                    const EdgeInsets
                        .fromLTRB(
                      16,
                      16,
                      16,
                      25,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch,
                        children: [
                          _buildFromBankSelector(),

                          const SizedBox(
                            height: 13,
                          ),

                          _buildToBankSelector(),

                          const SizedBox(
                            height: 13,
                          ),

                          _buildAmountField(),

                          const SizedBox(
                            height: 13,
                          ),

                          _buildDateSelector(),

                          const SizedBox(
                            height: 13,
                          ),

                          _buildTransactionField(),

                          const SizedBox(
                            height: 13,
                          ),

                          _buildDescriptionField(),

                          const SizedBox(
                            height: 22,
                          ),

                          SizedBox(
                            height: 50,
                            child:
                            ElevatedButton
                                .icon(
                              onPressed:
                              _isSaving
                                  ? null
                                  : _save,
                              icon: _isSaving
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                CircularProgressIndicator(
                                  strokeWidth:
                                  2.2,
                                  color:
                                  Colors.white,
                                ),
                              )
                                  : const Icon(
                                Icons
                                    .swap_horiz,
                              ),
                              label:
                              Text(
                                _isSaving
                                    ? 'در حال ثبت...'
                                    : 'ثبت انتقال',
                              ),
                              style:
                              ElevatedButton
                                  .styleFrom(
                                backgroundColor:
                                primaryColor,
                                foregroundColor:
                                Colors.white,
                                disabledBackgroundColor:
                                primaryColor
                                    .withOpacity(
                                  .5,
                                ),
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(
                                    13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}