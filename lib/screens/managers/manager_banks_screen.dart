import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/api_service.dart';
import '../../services/manager_bank_service.dart';
import 'manager_bank_transfers_screen.dart';

// اگر صفحه انتقال بانکی در فایل جداگانه است، import آن را اضافه کن.
// مثال:
// import 'manager_bank_transfer_screen.dart';

// ==================================================================
// Formatter شماره شبا
// IR ثابت است و کاربر فقط 24 رقم بعد از IR وارد می‌کند.
// ==================================================================

class _ShebaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String value = newValue.text.toUpperCase();

    value = value.replaceAll(RegExp(r'\s+'), '');

    if (value.isEmpty) {
      return const TextEditingValue(
        text: 'IR',
        selection: TextSelection.collapsed(
          offset: 2,
        ),
      );
    }

    String digits;

    if (value.startsWith('IR')) {
      digits = value
          .substring(2)
          .replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
    } else {
      digits = value.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
    }

    if (digits.length > 24) {
      digits = digits.substring(0, 24);
    }

    final result = 'IR$digits';

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(
        offset: result.length,
      ),
    );
  }
}

// ==================================================================
// صفحه حساب‌های بانکی
// ==================================================================

class ManagerBanksScreen extends StatefulWidget {
  /// ساختمان انتخاب‌شده از صفحه قبل
  final int? houseId;

  /// نام ساختمان انتخاب‌شده از صفحه قبل
  final String? houseName;

  const ManagerBanksScreen({
    super.key,
    this.houseId,
    this.houseName,
  });

  @override
  State<ManagerBanksScreen> createState() =>
      _ManagerBanksScreenState();
}

class _ManagerBanksScreenState extends State<ManagerBanksScreen> {
  late final ManagerBankService _bankService;

  List<Map<String, dynamic>> _banks = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _bankService = ManagerBankService(
      apiService: ApiService(),
    );

    _loadBanks();
  }

  // ============================================================
  // دریافت حساب‌ها
  // ============================================================

  Future<void> _loadBanks() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final banks = await _bankService.getBanks();

      if (!mounted) return;

      setState(() {
        _banks = banks;
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

  // ============================================================
  // انتقال بین بانکی
  // ============================================================

  Future<void> _openBankTransfer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerBankTransfersScreen(
          houseId: widget.houseId,
          houseName: widget.houseName,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadBanks();
    }
  }

  // ============================================================
  // افزودن / ویرایش حساب
  // ============================================================

  Future<void> _openBankForm({
    Map<String, dynamic>? bank,
  }) async {
    int? selectedHouseId;
    String? selectedHouseName;

    if (bank != null) {
      selectedHouseId = _toInt(
        bank['house_id'] ??
            (bank['house'] is Map
                ? bank['house']['id']
                : bank['house']),
      );

      selectedHouseName = _houseNameFromBank(bank);
    } else {
      selectedHouseId = widget.houseId;
      selectedHouseName = widget.houseName;

      if (selectedHouseId == null && _banks.isNotEmpty) {
        final firstBank = _banks.first;

        selectedHouseId = _toInt(
          firstBank['house_id'] ??
              (firstBank['house'] is Map
                  ? firstBank['house']['id']
                  : firstBank['house']),
        );

        selectedHouseName = _houseNameFromBank(firstBank);
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerBankFormScreen(
          bank: bank,
          houseId: selectedHouseId,
          houseName: selectedHouseName,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadBanks();
    }
  }

  // ============================================================
  // حذف
  // ============================================================

  Future<void> _confirmDelete(
      Map<String, dynamic> bank,
      ) async {
    final bankId = _toInt(bank['id']);

    if (bankId == null) {
      _showMessage(
        'شناسه حساب بانکی معتبر نیست.',
        isError: true,
      );
      return;
    }

    final bankName =
    (bank['bank_name'] ?? 'این حساب').toString();

    final accountNo =
    (bank['account_no'] ?? '').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'حذف حساب بانکی',
              textAlign: TextAlign.right,
            ),
            content: Text(
              'آیا از حذف حساب «$bankName'
                  '${accountNo.isNotEmpty ? ' - $accountNo' : ''}» مطمئن هستید؟',
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child: const Text('انصراف'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _bankService.deleteBank(bankId);

      if (!mounted) return;

      _showMessage(
        'حساب بانکی با موفقیت حذف شد.',
      );

      await _loadBanks();
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        isError: true,
      );
    }
  }

  // ============================================================
  // جزئیات
  // ============================================================

  void _showBankDetails(
      Map<String, dynamic> bank,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _BankDetailsSheet(
          bank: bank,
        );
      },
    );
  }

  // ============================================================
  // پیام
  // ============================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.right,
          ),
          backgroundColor: isError
              ? Colors.red
              : const Color(0xff00838F),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // int
  // ============================================================

  int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      _normalizeDigits(
        value.toString(),
      ),
    );
  }

  // ============================================================
  // اعداد فارسی
  // ============================================================

  String _toPersianDigits(
      String value,
      ) {
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

  // ============================================================
  // مبلغ
  // ============================================================

  String _formatAmount(
      dynamic value,
      ) {
    if (value == null) {
      return '۰';
    }

    num? number;

    if (value is num) {
      number = value;
    } else {
      number = num.tryParse(
        value
            .toString()
            .replaceAll(',', ''),
      );
    }

    if (number == null) {
      return value.toString();
    }

    final text = number
        .toStringAsFixed(
      number % 1 == 0 ? 0 : 2,
    )
        .replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
    );

    return _toPersianDigits(text);
  }

  // ============================================================
  // نام ساختمان
  // ============================================================

  String _houseNameFromBank(
      Map<String, dynamic> bank,
      ) {
    final direct = bank['house_name'];

    if (direct != null &&
        direct.toString().trim().isNotEmpty) {
      return direct.toString();
    }

    final house = bank['house'];

    if (house is Map) {
      final name =
          house['name'] ??
              house['house_name'] ??
              house['title'];

      return name?.toString() ?? '';
    }

    return '';
  }

  // ============================================================
  // خطا
  // ============================================================

  String _cleanError(
      Object error,
      ) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(11);
    }

    return text;
  }

  // ============================================================
  // Normalize digits
  // ============================================================

  String _normalizeDigits(
      String value,
      ) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const english = '0123456789';

    var result = value;

    for (var i = 0; i < 10; i++) {
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

  // ============================================================
  // مجموع موجودی
  // ============================================================

  num _totalBalance() {
    num total = 0;

    for (final bank in _banks) {
      final value = bank['current_balance'];

      if (value is num) {
        total += value;
      } else {
        total +=
            num.tryParse(
              value
                  ?.toString()
                  .replaceAll(',', '') ??
                  '',
            ) ??
                0;
      }
    }

    return total;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        const Color(0xffF5F7FA),
        appBar: AppBar(
          title: const Text(
            'حساب‌های بانکی',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor:
          const Color(0xff263238),
          elevation: 0,
        ),
        body: RefreshIndicator(
          onRefresh: _loadBanks,
          child: _buildBody(),
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xff00ACC1),
        ),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Padding(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 30,
            ),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadBanks,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ),
        ],
      );
    }

    if (_banks.isEmpty) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          30,
        ),
        children: [
          _buildTopActionButtons(),
          const SizedBox(height: 35),
          Icon(
            Icons.account_balance_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          const Text(
            'هنوز حساب بانکی ثبت نشده است.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                _openBankForm();
              },
              icon: const Icon(Icons.add),
              label: const Text(
                'افزودن حساب بانکی',
              ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xff00ACC1),
                foregroundColor:
                Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        30,
      ),
      children: [
        // ========================================================
        // دکمه‌های اصلی صفحه
        // ========================================================

        _buildTopActionButtons(),

        const SizedBox(height: 16),

        _buildSummaryCard(),

        const SizedBox(height: 20),

        Row(
          children: [
            const Expanded(
              child: Text(
                'حساب‌های بانکی',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff263238),
                ),
              ),
            ),
            Text(
              '${_toPersianDigits(_banks.length.toString())} حساب',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ..._banks.map(
              (bank) => _buildBankCard(bank),
        ),
      ],
    );
  }

  // ============================================================
  // دکمه‌های بالای صفحه
  // ============================================================

  Widget _buildTopActionButtons() {
    return Row(
      children: [
        // --------------------------------------------------------
        // انتقال بین بانکی
        // --------------------------------------------------------

        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _openBankTransfer,
              icon: const Icon(
                Icons.swap_horiz_rounded,
                size: 23,
              ),
              label: const Text(
                'انتقال بین بانکی',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                const Color(0xffFAF5FC),
                side: const BorderSide(
                  color: Color(0xffFAF5FC),
                  width: 1.2,
                ),
                backgroundColor:
                const Color(0xff7B1FA2),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // --------------------------------------------------------
        // افزودن حساب
        // --------------------------------------------------------

        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                _openBankForm();
              },
              icon: const Icon(
                Icons.add_rounded,
                size: 23,
              ),
              label: const Text(
                'افزودن حساب',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xff00ACC1),
                foregroundColor:
                Colors.white,
                elevation: 0,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xff00ACC1),
            Color(0xff00838F),
          ],
        ),
        borderRadius:
        BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
              Colors.white.withOpacity(.18),
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'مجموع موجودی حساب‌ها',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_formatAmount(_totalBalance())} تومان',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BANK CARD
  // ============================================================

  Widget _buildBankCard(
      Map<String, dynamic> bank,
      ) {
    final bankName =
    (bank['bank_name'] ?? 'بانک').toString();

    final accountNo =
    (bank['account_no'] ?? '').toString();

    final balance =
        bank['current_balance'] ?? 0;

    final isDefault =
        bank['is_default'] == true;

    final isGateway =
        bank['is_gateway'] == true;

    final isActive =
        bank['is_active'] != false;

    final houseName =
    _houseNameFromBank(bank);

    return Container(
      margin:
      const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(18),
        onTap: () {
          _showBankDetails(bank);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color:
                      const Color(0xffE0F7FA),
                      borderRadius:
                      BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color:
                      Color(0xff00838F),
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                bankName,
                                maxLines: 1,
                                overflow:
                                TextOverflow.ellipsis,
                                style:
                                const TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                  fontSize: 16,
                                  color:
                                  Color(0xff263238),
                                ),
                              ),
                            ),
                            if (isDefault) ...[
                              const SizedBox(width: 6),
                              _buildBadge(
                                'پیش‌فرض',
                                const Color(0xff1565C0),
                              ),
                            ],
                          ],
                        ),
                        if (accountNo.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            'شماره حساب: $accountNo',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                              Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if (houseName.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            houseName,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                              Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                  const Color(0xffF5F7FA),
                  borderRadius:
                  BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'موجودی فعلی',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                              Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_formatAmount(balance)} تومان',
                            style:
                            const TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.bold,
                              color:
                              Color(0xff00838F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isGateway)
                      _buildBadge(
                        'درگاه',
                        const Color(0xff7B1FA2),
                      ),
                    const SizedBox(width: 6),
                    _buildBadge(
                      isActive
                          ? 'فعال'
                          : 'غیرفعال',
                      isActive
                          ? const Color(0xff2E7D32)
                          : Colors.grey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade200,
                    ),
                  ),
                ),
                padding:
                const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          _showBankDetails(bank);
                        },
                        icon: const Icon(
                          Icons.visibility_outlined,
                          size: 18,
                        ),
                        label:
                        const Text('جزئیات'),
                        style:
                        TextButton.styleFrom(
                          foregroundColor:
                          const Color(
                            0xff263238,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 25,
                      color:
                      Colors.grey.shade200,
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          _openBankForm(
                            bank: bank,
                          );
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                        ),
                        label:
                        const Text('ویرایش'),
                        style:
                        TextButton.styleFrom(
                          foregroundColor:
                          const Color(
                            0xff00ACC1,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 25,
                      color:
                      Colors.grey.shade200,
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          _confirmDelete(bank);
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                        ),
                        label:
                        const Text('حذف'),
                        style:
                        TextButton.styleFrom(
                          foregroundColor:
                          Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BADGE
  // ============================================================

  Widget _buildBadge(
      String text,
      Color color,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ==================================================================
// جزئیات حساب
// ==================================================================

class _BankDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> bank;

  const _BankDetailsSheet({
    required this.bank,
  });

  String _value(
      String key, [
        String defaultValue = '-',
      ]) {
    final value = bank[key];

    if (value == null ||
        value.toString().trim().isEmpty) {
      return defaultValue;
    }

    return value.toString();
  }

  String _formatAmount(
      dynamic value,
      ) {
    if (value == null) {
      return '۰';
    }

    num? number;

    if (value is num) {
      number = value;
    } else {
      number = num.tryParse(
        value
            .toString()
            .replaceAll(',', ''),
      );
    }

    if (number == null) {
      return value.toString();
    }

    final text = number
        .toStringAsFixed(
      number % 1 == 0 ? 0 : 2,
    )
        .replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
    );

    return _toPersianDigits(text);
  }

  String _toPersianDigits(
      String value,
      ) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(
        english[i],
        persian[i],
      );
    }

    return result;
  }

  String _formatDate(
      dynamic value,
      ) {
    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return '-';
    }

    final dateTime =
    DateTime.tryParse(text);

    if (dateTime != null) {
      final jalali =
      Jalali.fromDateTime(
        dateTime.toLocal(),
      );

      return _toPersianDigits(
        '${jalali.year}/'
            '${jalali.month.toString().padLeft(2, '0')}/'
            '${jalali.day.toString().padLeft(2, '0')}',
      );
    }

    return _toPersianDigits(
      text.replaceAll('-', '/'),
    );
  }

  String _houseName() {
    final direct = bank['house_name'];

    if (direct != null &&
        direct.toString().trim().isNotEmpty) {
      return direct.toString();
    }

    final house = bank['house'];

    if (house is Map) {
      final name =
          house['name'] ??
              house['house_name'] ??
              house['title'];

      if (name != null) {
        return name.toString();
      }
    }

    return '-';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration:
        const BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.vertical(
            top: Radius.circular(25),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          25,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color:
                    Colors.grey.shade300,
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                          0xffE0F7FA,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          15,
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color:
                        Color(0xff00838F),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _value(
                          'bank_name',
                          'حساب بانکی',
                        ),
                        style:
                        const TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _detailRow(
                  'ساختمان',
                  _houseName(),
                ),
                _detailRow(
                  'نام صاحب حساب',
                  _value(
                    'account_holder_name',
                  ),
                ),
                _detailRow(
                  'شماره حساب',
                  _value('account_no'),
                ),
                _detailRow(
                  'شماره شبا',
                  _value('sheba_number'),
                ),
                _detailRow(
                  'شماره کارت',
                  _value('cart_number'),
                ),
                _detailRow(
                  'موجودی اولیه',
                  '${_formatAmount(bank['initial_fund'])} تومان',
                ),
                _detailRow(
                  'موجودی فعلی',
                  '${_formatAmount(bank['current_balance'])} تومان',
                ),
                _detailRow(
                  'تاریخ افتتاح',
                  _formatDate(
                    bank['create_at'],
                  ),
                ),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (bank['is_default'] == true)
                      _badge(
                        'حساب پیش‌فرض',
                        const Color(0xff1565C0),
                      ),
                    if (bank['is_gateway'] == true)
                      _badge(
                        'حساب درگاه',
                        const Color(0xff7B1FA2),
                      ),
                    _badge(
                      bank['is_active'] == false
                          ? 'غیرفعال'
                          : 'فعال',
                      bank['is_active'] == false
                          ? Colors.grey
                          : const Color(
                        0xff2E7D32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
      String title,
      String value,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        vertical: 11,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 115,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color:
                Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style:
              const TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(
      String text,
      Color color,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight:
          FontWeight.bold,
        ),
      ),
    );
  }
}

// ==================================================================
// فرم افزودن / ویرایش
// ==================================================================

class ManagerBankFormScreen extends StatefulWidget {
  final Map<String, dynamic>? bank;

  final int? houseId;

  final String? houseName;

  const ManagerBankFormScreen({
    super.key,
    this.bank,
    this.houseId,
    this.houseName,
  });

  @override
  State<ManagerBankFormScreen> createState() =>
      _ManagerBankFormScreenState();
}

class _ManagerBankFormScreenState
    extends State<ManagerBankFormScreen> {
  final _formKey =
  GlobalKey<FormState>();

  final _bankNameController =
  TextEditingController();

  final _accountHolderController =
  TextEditingController();

  final _accountNoController =
  TextEditingController();

  final _shebaController =
  TextEditingController();

  final _cardController =
  TextEditingController();

  final _initialFundController =
  TextEditingController();

  late final ApiService _apiService;

  late final ManagerBankService _bankService;

  bool _isSaving = false;

  bool _isDefault = false;
  bool _isGateway = false;
  bool _isActive = true;

  String? _selectedHouseId;
  String? _selectedHouseName;

  Jalali? _selectedOpeningDate;

  bool get _isEdit =>
      widget.bank != null;

  static const List<String> _bankChoices = [
    'ملی',
    'ملت',
    'تجارت',
    'صادرات',
    'رسالت',
    'صنعت و معدن',
    'کشاورزی',
    'مسکن',
    'رفاه',
    'سپه',
    'سینا',
    'توسعه صادرات',
    'پست بانک',
    'پاسارگاد',
    'اقتصاد نوین',
    'پارسیان',
    'سامان',
    'گردشگری',
    'کارآفرین',
    'دی',
    'شهر',
    'ایران زمین',
    'مهر ایران',
  ];

  @override
  void initState() {
    super.initState();

    _apiService = ApiService();

    _bankService =
        ManagerBankService(
          apiService: _apiService,
        );

    _fillForm();
  }

  void _fillForm() {
    final bank = widget.bank;

    if (bank == null) {
      _selectedOpeningDate =
          Jalali.now();

      _selectedHouseId =
          widget.houseId?.toString();

      _selectedHouseName =
          widget.houseName ?? '';

      _shebaController.text = 'IR';

      return;
    }

    _bankNameController.text =
        (bank['bank_name'] ?? '')
            .toString();

    _accountHolderController.text =
        (bank['account_holder_name'] ?? '')
            .toString();

    _accountNoController.text =
        (bank['account_no'] ?? '')
            .toString();

    _shebaController.text =
        _normalizeShebaForDisplay(
          bank['sheba_number']?.toString() ?? '',
        );

    _cardController.text =
        (bank['cart_number'] ?? '')
            .toString();

    final initialFund =
    bank['initial_fund'];

    if (initialFund != null) {
      _initialFundController.text =
          initialFund.toString();
    }

    _selectedOpeningDate =
        _parseBankDate(
          bank['create_at'],
        );

    final houseId =
        bank['house_id'] ??
            (bank['house'] is Map
                ? bank['house']['id']
                : bank['house']);

    _selectedHouseId =
        houseId?.toString();

    _selectedHouseName =
        bank['house_name']?.toString() ??
            (bank['house'] is Map
                ? bank['house']['name']
                ?.toString() ??
                bank['house']['house_name']
                    ?.toString() ??
                bank['house']['title']
                    ?.toString() ??
                ''
                : '');

    _isDefault =
        bank['is_default'] == true;

    _isGateway =
        bank['is_gateway'] == true;

    _isActive =
        bank['is_active'] != false;
  }

  String _normalizeShebaForDisplay(
      String value,
      ) {
    value = value.trim().toUpperCase();

    if (value.isEmpty) {
      return 'IR';
    }

    value = value.replaceAll(
      RegExp(r'\s+'),
      '',
    );

    String digits;

    if (value.startsWith('IR')) {
      digits = value
          .substring(2)
          .replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
    } else {
      digits = value.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
    }

    if (digits.length > 24) {
      digits = digits.substring(0, 24);
    }

    return 'IR$digits';
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountHolderController.dispose();
    _accountNoController.dispose();
    _shebaController.dispose();
    _cardController.dispose();
    _initialFundController.dispose();

    super.dispose();
  }

  int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      _normalizeDigits(
        value.toString(),
      ),
    );
  }

  Widget _buildHouseSelector() {
    final hasHouse =
        _selectedHouseId != null &&
            _selectedHouseId!
                .trim()
                .isNotEmpty;

    final name =
        _selectedHouseName?.trim() ?? '';

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: Container(
        width: double.infinity,
        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        decoration:
        BoxDecoration(
          color: const Color(0xffF8FDFF),
          borderRadius:
          BorderRadius.circular(13),
          border: Border.all(
            color: hasHouse
                ? const Color(0xffB2EBF2)
                : Colors.red.shade300,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration:
              BoxDecoration(
                color:
                const Color(0xffE0F7FA),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.business_outlined,
                color: Color(0xff00838F),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'ساختمان',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                          Colors.grey.shade600,
                        ),
                      ),
                      if (hasHouse) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            const Color(0xffE0F2F1),
                            borderRadius:
                            BorderRadius.circular(
                              10,
                            ),
                          ),
                          child: const Text(
                            'پیش‌فرض',
                            style: TextStyle(
                              fontSize: 9,
                              color:
                              Color(0xff00838F),
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    hasHouse
                        ? (name.isNotEmpty
                        ? name
                        : 'شناسه ساختمان: $_selectedHouseId')
                        : 'ساختمان مشخص نشده است',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.w600,
                      color: hasHouse
                          ? const Color(0xff263238)
                          : Colors.red,
                    ),
                  ),
                  if (hasHouse) ...[
                    const SizedBox(height: 3),
                    Text(
                      'ساختمان حساب بانکی به صورت خودکار تعیین شده است.',
                      style: TextStyle(
                        fontSize: 10,
                        color:
                        Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasHouse)
              const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: Colors.grey,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankSelector() {
    final currentBank =
    _bankNameController.text.trim();

    final selectedBank =
    _bankChoices.contains(currentBank)
        ? currentBank
        : null;

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: DropdownButtonFormField<String>(
        value: selectedBank,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'نام بانک',
          hintText: 'بانک را انتخاب کنید',
          prefixIcon: const Icon(
            Icons.account_balance_outlined,
            color: Color(0xff00ACC1),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(13),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(13),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          focusedBorder:
          const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(13),
            ),
            borderSide: BorderSide(
              color: Color(0xff00ACC1),
              width: 1.5,
            ),
          ),
        ),
        items: _bankChoices.map((bank) {
          return DropdownMenuItem<String>(
            value: bank,
            child: Text(
              bank,
              textAlign: TextAlign.right,
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value == null) {
            return;
          }

          setState(() {
            _bankNameController.text = value;
          });
        },
        validator: (value) {
          if (value == null ||
              value.trim().isEmpty) {
            return 'نام بانک را انتخاب کنید.';
          }

          return null;
        },
      ),
    );
  }

  Jalali? _parseBankDate(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    final text =
    value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    final dateTime =
    DateTime.tryParse(text);

    if (dateTime != null) {
      return Jalali.fromDateTime(
        dateTime.toLocal(),
      );
    }

    final normalized =
    _normalizeDigits(
      text,
    ).replaceAll('-', '/');

    final parts =
    normalized.split('/');

    if (parts.length == 3) {
      final year =
      int.tryParse(parts[0]);

      final month =
      int.tryParse(parts[1]);

      final day =
      int.tryParse(parts[2]);

      if (year != null &&
          month != null &&
          day != null) {
        try {
          return Jalali(
            year,
            month,
            day,
          );
        } catch (_) {
          return null;
        }
      }
    }

    return null;
  }

  String _openingDateForApi() {
    if (_selectedOpeningDate == null) {
      return '';
    }

    final gregorian =
    _selectedOpeningDate!.toDateTime();

    return '${gregorian.year}-'
        '${gregorian.month.toString().padLeft(2, '0')}-'
        '${gregorian.day.toString().padLeft(2, '0')}';
  }

  String _formatJalaliDate(
      Jalali date,
      ) {
    final text =
        '${date.year.toString().padLeft(4, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}';

    return _toPersianDigits(text);
  }

  Future<void> _selectOpeningDate() async {
    final now = Jalali.now();

    final current =
        _selectedOpeningDate ?? now;

    int selectedYear =
        current.year;

    int selectedMonth =
        current.month;

    int selectedDay =
        current.day;

    final result =
    await showDialog<Jalali>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            final monthLength =
                Jalali(
                  selectedYear,
                  selectedMonth,
                  1,
                ).monthLength;

            if (selectedDay >
                monthLength) {
              selectedDay =
                  monthLength;
            }

            const monthNames = [
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

            return Directionality(
              textDirection:
              TextDirection.rtl,
              child: AlertDialog(
                title: const Text(
                  'انتخاب تاریخ افتتاح حساب',
                  textAlign:
                  TextAlign.right,
                  style: TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                content: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child:
                          DropdownButtonFormField<
                              int>(
                            value:
                            selectedDay,
                            decoration:
                            const InputDecoration(
                              labelText:
                              'روز',
                              border:
                              OutlineInputBorder(),
                            ),
                            items:
                            List.generate(
                              monthLength,
                                  (index) {
                                final day =
                                    index + 1;

                                return DropdownMenuItem<
                                    int>(
                                  value:
                                  day,
                                  child: Text(
                                    _toPersianDigits(
                                      day.toString(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            onChanged:
                                (value) {
                              if (value ==
                                  null) {
                                return;
                              }

                              setDialogState(
                                    () {
                                  selectedDay =
                                      value;
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          flex: 2,
                          child:
                          DropdownButtonFormField<
                              int>(
                            value:
                            selectedMonth,
                            decoration:
                            const InputDecoration(
                              labelText:
                              'ماه',
                              border:
                              OutlineInputBorder(),
                            ),
                            items:
                            List.generate(
                              12,
                                  (index) {
                                final month =
                                    index + 1;

                                return DropdownMenuItem<
                                    int>(
                                  value:
                                  month,
                                  child: Text(
                                    monthNames[
                                    index],
                                  ),
                                );
                              },
                            ),
                            onChanged:
                                (value) {
                              if (value ==
                                  null) {
                                return;
                              }

                              setDialogState(
                                    () {
                                  selectedMonth =
                                      value;
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedYear,
                      decoration:
                      const InputDecoration(
                        labelText: 'سال',
                        border:
                        OutlineInputBorder(),
                      ),
                      items:
                      List.generate(
                        21,
                            (index) {
                          final year =
                              now.year -
                                  10 +
                                  index;

                          return DropdownMenuItem<
                              int>(
                            value: year,
                            child: Text(
                              _toPersianDigits(
                                year.toString(),
                              ),
                            ),
                          );
                        },
                      ),
                      onChanged:
                          (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(
                              () {
                            selectedYear =
                                value;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding:
                      const EdgeInsets.all(
                        14,
                      ),
                      decoration:
                      BoxDecoration(
                        color:
                        const Color(
                          0xffE0F7FA,
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          12,
                        ),
                      ),
                      child: Text(
                        _formatJalaliDate(
                          Jalali(
                            selectedYear,
                            selectedMonth,
                            selectedDay,
                          ),
                        ),
                        textAlign:
                        TextAlign.center,
                        style:
                        const TextStyle(
                          color:
                          Color(0xff00838F),
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                      );
                    },
                    child:
                    const Text('انصراف'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        dialogContext,
                        Jalali(
                          selectedYear,
                          selectedMonth,
                          selectedDay,
                        ),
                      );
                    },
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(
                        0xff00ACC1,
                      ),
                      foregroundColor:
                      Colors.white,
                    ),
                    child:
                    const Text('تأیید'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _selectedOpeningDate =
            result;
      });
    }
  }

  Widget _buildOpeningDateSelector() {
    final hasDate =
        _selectedOpeningDate != null;

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: InkWell(
        onTap: _selectOpeningDate,
        borderRadius:
        BorderRadius.circular(13),
        child: Container(
          width: double.infinity,
          padding:
          const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          decoration:
          BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.circular(13),
            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xff00ACC1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تاریخ افتتاح حساب',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                        Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      hasDate
                          ? _formatJalaliDate(
                        _selectedOpeningDate!,
                      )
                          : 'انتخاب تاریخ شمسی',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w600,
                        color: hasDate
                            ? const Color(
                          0xff263238,
                        )
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final houseId =
    _toInt(_selectedHouseId);

    if (houseId == null) {
      _showError(
        'ساختمان حساب بانکی مشخص نشده است.',
      );
      return;
    }

    if (_selectedOpeningDate == null) {
      _showError(
        'تاریخ افتتاح حساب را انتخاب کنید.',
      );
      return;
    }

    final initialFundText =
    _normalizeDigits(
      _initialFundController.text.trim(),
    )
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('،', '');

    final initialFund =
    initialFundText.isEmpty
        ? 0
        : int.tryParse(
      initialFundText,
    );

    if (initialFund == null) {
      _showError(
        'موجودی اولیه معتبر نیست.',
      );
      return;
    }

    final bankName =
    _bankNameController.text.trim();

    final accountHolder =
    _accountHolderController.text.trim();

    final accountNo =
    _normalizeDigits(
      _accountNoController.text.trim(),
    );

    final sheba =
    _normalizeShebaForDisplay(
      _normalizeDigits(
        _shebaController.text.trim(),
      ),
    );

    final card =
    _normalizeDigits(
      _cardController.text.trim(),
    ).replaceAll(' ', '');

    if (bankName.isEmpty) {
      _showError(
        'نام بانک را انتخاب کنید.',
      );
      return;
    }

    if (!_bankChoices.contains(bankName)) {
      _showError(
        'بانک انتخاب‌شده معتبر نیست.',
      );
      return;
    }

    if (accountHolder.isEmpty) {
      _showError(
        'نام صاحب حساب را وارد کنید.',
      );
      return;
    }

    if (accountNo.isEmpty) {
      _showError(
        'شماره حساب را وارد کنید.',
      );
      return;
    }

    if (sheba.isEmpty ||
        sheba == 'IR') {
      _showError(
        'شماره شبا را وارد کنید.',
      );
      return;
    }

    if (!RegExp(
      r'^IR[0-9]{24}$',
    ).hasMatch(sheba)) {
      _showError(
        'شماره شبا باید شامل IR و دقیقاً ۲۴ رقم باشد.',
      );
      return;
    }

    if (card.isEmpty) {
      _showError(
        'شماره کارت را وارد کنید.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final createAt =
      _openingDateForApi();

      if (createAt.isEmpty) {
        throw Exception(
          'تاریخ افتتاح حساب معتبر نیست.',
        );
      }

      if (_isEdit) {
        final id =
        _toInt(widget.bank!['id']);

        if (id == null) {
          throw Exception(
            'شناسه حساب بانکی معتبر نیست.',
          );
        }

        await _bankService.updateBank(
          id: id,
          houseId: houseId,
          bankName: bankName,
          accountHolderName:
          accountHolder,
          accountNo: accountNo,
          shebaNumber: sheba,
          cartNumber: card,
          createAt: createAt,
          initialFund: initialFund,
          isActive: _isActive,
          isDefault: _isDefault,
          isGateway: _isGateway,
        );
      } else {
        await _bankService.createBank(
          houseId: houseId,
          bankName: bankName,
          accountHolderName:
          accountHolder,
          accountNo: accountNo,
          shebaNumber: sheba,
          cartNumber: card,
          createAt: createAt,
          initialFund: initialFund,
          isActive: _isActive,
          isDefault: _isDefault,
          isGateway: _isGateway,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _isEdit
                  ? 'حساب بانکی با موفقیت ویرایش شد.'
                  : 'حساب بانکی با موفقیت اضافه شد.',
              textAlign: TextAlign.right,
            ),
            backgroundColor:
            const Color(0xff00838F),
          ),
        );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _cleanError(e),
              textAlign: TextAlign.right,
            ),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.right,
          ),
          backgroundColor: Colors.red,
        ),
      );
  }

  String _normalizeDigits(
      String value,
      ) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    const english = '0123456789';

    var result = value;

    for (var i = 0; i < 10; i++) {
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

  String _toPersianDigits(
      String value,
      ) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    var result = value;

    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(
        english[i],
        persian[i],
      );
    }

    return result;
  }

  String _cleanError(
      Object error,
      ) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(11);
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        const Color(0xffF5F7FA),
        appBar: AppBar(
          title: Text(
            _isEdit
                ? 'ویرایش حساب بانکی'
                : 'افزودن حساب بانکی',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor:
          const Color(0xff263238),
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding:
            const EdgeInsets.fromLTRB(
              16,
              20,
              16,
              30,
            ),
            children: [
              _buildSectionTitle(
                'اطلاعات حساب',
              ),
              const SizedBox(height: 10),
              _buildHouseSelector(),
              _buildBankSelector(),
              _buildTextField(
                controller:
                _accountHolderController,
                label: 'نام صاحب حساب',
                icon:
                Icons.person_outline,
                required: true,
              ),
              _buildTextField(
                controller:
                _accountNoController,
                label: 'شماره حساب',
                icon:
                Icons.numbers_outlined,
                required: true,
                keyboardType:
                TextInputType.number,
              ),
              _buildShebaField(),
              _buildTextField(
                controller:
                _cardController,
                label: 'شماره کارت',
                icon:
                Icons.credit_card_outlined,
                required: true,
                keyboardType:
                TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildSectionTitle(
                'اطلاعات مالی',
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller:
                _initialFundController,
                label: 'موجودی اولیه',
                icon:
                Icons.account_balance_wallet,
                required: false,
                keyboardType:
                TextInputType.number,
                suffixText: 'تومان',
              ),
              _buildOpeningDateSelector(),
              const SizedBox(height: 12),
              _buildSectionTitle(
                'تنظیمات حساب',
              ),
              const SizedBox(height: 8),
              _buildSwitchTile(
                title:
                'حساب پیش‌فرض باشد',
                subtitle:
                'برای حساب اصلی ساختمان',
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value;
                  });
                },
                icon:
                Icons.star_border_rounded,
              ),
              _buildSwitchTile(
                title:
                'حساب پیش‌فرض درگاه باشد',
                subtitle:
                'برای دریافت پرداخت‌های اینترنتی',
                value: _isGateway,
                onChanged: (value) {
                  setState(() {
                    _isGateway = value;
                  });
                },
                icon:
                Icons.payment_outlined,
              ),
              _buildSwitchTile(
                title:
                'حساب فعال باشد',
                subtitle:
                'حساب غیرفعال در عملیات مالی استفاده نمی‌شود',
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
                icon:
                Icons.check_circle_outline,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 52,
                child:
                ElevatedButton.icon(
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
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.save_outlined,
                  ),
                  label: Text(
                    _isSaving
                        ? 'در حال ذخیره...'
                        : _isEdit
                        ? 'ذخیره تغییرات'
                        : 'ثبت حساب بانکی',
                    style:
                    const TextStyle(
                      fontSize: 15,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(
                      0xff00ACC1,
                    ),
                    foregroundColor:
                    Colors.white,
                    disabledBackgroundColor:
                    Colors.grey.shade400,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShebaField() {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: TextFormField(
        controller: _shebaController,
        keyboardType:
        TextInputType.number,
        textDirection:
        TextDirection.ltr,
        textAlign: TextAlign.left,
        maxLength: 26,
        inputFormatters: [
          _ShebaInputFormatter(),
        ],
        decoration: InputDecoration(
          labelText: 'شماره شبا',
          hintText:
          'IR000000000000000000000000',
          counterText: '',
          prefixIcon: const Icon(
            Icons
                .account_balance_wallet_outlined,
            color: Color(0xff00ACC1),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(13),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(13),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          focusedBorder:
          const OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(13),
            ),
            borderSide: BorderSide(
              color: Color(0xff00ACC1),
              width: 1.5,
            ),
          ),
        ),
        validator: (value) {
          final sheba =
              value?.trim().toUpperCase() ?? '';

          if (sheba.isEmpty ||
              sheba == 'IR') {
            return 'شماره شبا را وارد کنید.';
          }

          if (!RegExp(
            r'^IR[0-9]{24}$',
          ).hasMatch(sheba)) {
            return 'شماره شبا باید شامل IR و ۲۴ رقم باشد.';
          }

          return null;
        },
      ),
    );
  }

  Widget _buildSectionTitle(
      String title,
      ) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration:
          BoxDecoration(
            color:
            const Color(0xff00ACC1),
            borderRadius:
            BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight:
            FontWeight.bold,
            color:
            Color(0xff263238),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController
    controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    TextDirection? direction,
    String? hint,
    String? suffixText,
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textDirection:
        direction ?? TextDirection.rtl,
        decoration:
        InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color:
            const Color(0xff00ACC1),
          ),
          suffixText: suffixText,
          filled: true,
          fillColor: Colors.white,
          border:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(13),
            borderSide:
            BorderSide(
              color:
              Colors.grey.shade300,
            ),
          ),
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(13),
            borderSide:
            BorderSide(
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
            borderSide:
            BorderSide(
              color:
              Color(0xff00ACC1),
              width: 1.5,
            ),
          ),
        ),
        validator: required
            ? (value) {
          if (value == null ||
              value.trim().isEmpty) {
            return '$label را وارد کنید.';
          }

          return null;
        }
            : null,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>
    onChanged,
    required IconData icon,
  }) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color:
          Colors.grey.shade200,
        ),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(
          icon,
          color:
          const Color(0xff00ACC1),
        ),
        title: Text(
          title,
          style:
          const TextStyle(
            fontWeight:
            FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color:
            Colors.grey.shade600,
          ),
        ),
        activeColor:
        const Color(0xff00ACC1),
      ),
    );
  }
}