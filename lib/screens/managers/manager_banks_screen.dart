import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/manager_bank_service.dart';

class ManagerBanksScreen extends StatefulWidget {
  const ManagerBanksScreen({super.key});

  @override
  State<ManagerBanksScreen> createState() =>
      _ManagerBanksScreenState();
}

class _ManagerBanksScreenState
    extends State<ManagerBanksScreen> {
  late final ManagerBankService _bankService;

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _banks = [];

  @override
  void initState() {
    super.initState();

    _bankService = ManagerBankService(
      apiService: ApiService(),
    );

    _loadBanks();
  }

  Future<void> _loadBanks() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final banks = await _bankService.getBanks();

      if (!mounted) return;

      setState(() {
        _banks = banks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception:')) {
      return text.substring(10).trim();
    }

    return text;
  }

  String _formatMoney(dynamic value) {
    if (value == null) return '۰';

    final number =
        double.tryParse(
          value.toString().replaceAll(',', ''),
        ) ??
            0;

    final integer =
    number.toInt().toString();

    final formatted =
    integer.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
    );

    return _toPersianDigits(formatted);
  }

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

  String _bankName(
      Map<String, dynamic> bank,
      ) {
    return bank['bank_name']?.toString() ??
        'بانک نامشخص';
  }

  String _accountNumber(
      Map<String, dynamic> bank,
      ) {
    return bank['account_no']?.toString() ?? '';
  }

  String _accountHolder(
      Map<String, dynamic> bank,
      ) {
    return bank['account_holder_name']
        ?.toString() ??
        '';
  }

  double _balance(
      Map<String, dynamic> bank,
      ) {
    return double.tryParse(
      bank['current_balance']
          ?.toString()
          .replaceAll(',', '') ??
          '0',
    ) ??
        0;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        const Color(0xFFF5F7FA),

        appBar: AppBar(
          title: const Text(
            'حساب‌های بانکی',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor:
          const Color(0xFF00ACC1),
          foregroundColor: Colors.white,
          elevation: 0,
        ),

        body: RefreshIndicator(
          onRefresh: _loadBanks,
          child: _buildBody(),
        ),

        floatingActionButton:
        FloatingActionButton(
          backgroundColor:
          const Color(0xFF00ACC1),
          foregroundColor: Colors.white,
          onPressed: () {
            _showComingSoon(
              'صفحه ثبت حساب بانکی را در مرحله بعد اضافه می‌کنیم.',
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
            MediaQuery.of(context).size.height *
                0.3,
          ),
          Center(
            child: Padding(
              padding:
              const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 55,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _loadBanks,
                    icon: const Icon(
                      Icons.refresh,
                    ),
                    label: const Text(
                      'تلاش مجدد',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_banks.isEmpty) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
            MediaQuery.of(context).size.height *
                0.3,
          ),
          const Center(
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_outlined,
                  size: 65,
                  color: Colors.grey,
                ),
                SizedBox(height: 15),
                Text(
                  'هنوز حساب بانکی ثبت نشده است.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        12,
        16,
        12,
        90,
      ),
      physics:
      const AlwaysScrollableScrollPhysics(),
      children: [
        _buildSummary(),

        const SizedBox(height: 14),

        ..._banks.map(
              (bank) => Padding(
            padding:
            const EdgeInsets.only(bottom: 12),
            child: _buildBankCard(bank),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    double totalBalance = 0;

    for (final bank in _banks) {
      totalBalance += _balance(bank);
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00ACC1),
            Color(0xFF008FA1),
          ],
        ),
        borderRadius:
        BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'موجودی کل حساب‌ها',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatMoney(totalBalance)} ریال',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          Text(
            _toPersianDigits(
              '${_banks.length}',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 5),

          const Text(
            'حساب',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankCard(
      Map<String, dynamic> bank,
      ) {
    final isDefault =
        bank['is_default'] == true;

    final isGateway =
        bank['is_gateway'] == true;

    final houseName =
    bank['house_name']?.toString();

    final accountHolder =
    _accountHolder(bank);

    final accountNumber =
    _accountNumber(bank);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(18),
        onTap: () {
          _showBankDetails(bank);
        },
        child: Padding(
          padding:
          const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF00ACC1,
                      ).withValues(
                        alpha: 0.1,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color:
                      Color(0xFF00ACC1),
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          _bankName(bank),
                          style:
                          const TextStyle(
                            fontSize: 17,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),

                        if (houseName != null &&
                            houseName
                                .trim()
                                .isNotEmpty)
                          Padding(
                            padding:
                            const EdgeInsets
                                .only(
                              top: 4,
                            ),
                            child: Text(
                              houseName,
                              style:
                              const TextStyle(
                                fontSize: 12,
                                color:
                                Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showComingSoon(
                          'صفحه ویرایش حساب را در مرحله بعد اضافه می‌کنیم.',
                        );
                      } else if (value ==
                          'delete') {
                        _confirmDelete(bank);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text('ویرایش'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text('حذف'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFF7F8FA),
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.credit_card,
                      size: 20,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        accountNumber.isEmpty
                            ? 'شماره حساب ثبت نشده'
                            : accountNumber,
                        style:
                        const TextStyle(
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (accountHolder
                  .trim()
                  .isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        accountHolder,
                        style:
                        const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'موجودی فعلی',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatMoney(_balance(bank))} ریال',
                          style:
                          const TextStyle(
                            fontSize: 17,
                            fontWeight:
                            FontWeight.bold,
                            color:
                            Color(0xFF00838F),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isDefault)
                    _buildBadge(
                      'پیش‌فرض',
                      const Color(
                        0xFF7B1FA2,
                      ),
                    ),

                  if (isGateway) ...[
                    const SizedBox(width: 6),
                    _buildBadge(
                      'درگاه',
                      const Color(
                        0xFF2E7D32,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
      String text,
      Color color,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.1,
        ),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showBankDetails(
      Map<String, dynamic> bank,
      ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 4,
                      decoration:
                      BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius:
                        BorderRadius.circular(
                          10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    _bankName(bank),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 18),

                  _detailRow(
                    'شماره حساب',
                    _accountNumber(bank),
                  ),

                  _detailRow(
                    'صاحب حساب',
                    _accountHolder(bank),
                  ),

                  _detailRow(
                    'شماره کارت',
                    bank['cart_number']
                        ?.toString() ??
                        '',
                  ),

                  _detailRow(
                    'شماره شبا',
                    bank['sheba_number']
                        ?.toString() ??
                        '',
                  ),

                  _detailRow(
                    'موجودی اولیه',
                    '${_formatMoney(bank['initial_fund'])} ریال',
                  ),

                  _detailRow(
                    'موجودی فعلی',
                    '${_formatMoney(bank['current_balance'])} ریال',
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },
                      child:
                      const Text('بستن'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
      String title,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      Map<String, dynamic> bank,
      ) async {
    final id = bank['id'];

    if (id == null) return;

    final result =
    await showDialog<bool>(
      context: context,
      builder: (_) {
        return Directionality(
          textDirection:
          TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'حذف حساب بانکی',
            ),
            content: Text(
              'آیا از حذف حساب ${_bankName(bank)} اطمینان دارید؟',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    false,
                  );
                },
                child:
                const Text('انصراف'),
              ),
              ElevatedButton(
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.red,
                  foregroundColor:
                  Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(
                    context,
                    true,
                  );
                },
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (result != true) return;

    try {
      await _bankService.deleteBank(
        id is int
            ? id
            : int.parse(id.toString()),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'حساب بانکی با موفقیت حذف شد.',
          ),
        ),
      );

      await _loadBanks();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            _cleanError(e),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showComingSoon(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}