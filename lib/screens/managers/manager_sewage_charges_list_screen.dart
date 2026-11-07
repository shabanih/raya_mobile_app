
import 'package:flutter/material.dart';

import '../../services/manager_sewage_charge_list_service.dart';
import 'manager_sewage_charge_units_list_screen.dart';

class ManagerSewageChargesListScreen extends StatefulWidget {
  const ManagerSewageChargesListScreen({super.key});

  @override
  State<ManagerSewageChargesListScreen> createState() =>
      _ManagerSewageChargesListScreenState();
}

class _ManagerSewageChargesListScreenState
    extends State<ManagerSewageChargesListScreen> {
  static const Color teal = Color(0xFF00ACC1);
  static const Color purple = Color(0xFF610DB5);

  final ManagerSewageChargeListService _service =
  ManagerSewageChargeListService();

  final TextEditingController _searchController =
  TextEditingController();

  List<Map<String, dynamic>> _charges = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCharges();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _int(dynamic value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _fa(String value) {
    const en = '0123456789';
    const fa = '۰۱۲۳۴۵۶۷۸۹';

    for (int i = 0; i < 10; i++) {
      value = value.replaceAll(en[i], fa[i]);
    }

    return value;
  }

  String _money(dynamic value) {
    final number = _int(value);

    return _fa(
      number.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (_) => ',',
      ),
    );
  }

  String _date(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'ثبت نشده';
    }

    try {
      final date = DateTime.parse(value.toString());

      final converted = _gregorianToJalali(
        date.year,
        date.month,
        date.day,
      );

      return '${_fa(converted[0].toString().padLeft(4, '0'))}/'
          '${_fa(converted[1].toString().padLeft(2, '0'))}/'
          '${_fa(converted[2].toString().padLeft(2, '0'))}';
    } catch (_) {
      return _fa(value.toString());
    }
  }

  List<int> _gregorianToJalali(int gy, int gm, int gd) {
    final gDays = <int>[
      0, 31, 59, 90, 120, 151,
      181, 212, 243, 273, 304, 334
    ];

    int gy2 = gm > 2 ? gy + 1 : gy;

    int days = 355666 +
        365 * gy +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400) +
        gd +
        gDays[gm - 1];

    int jy = -1595 + 33 * (days ~/ 12053);
    days %= 12053;

    jy += 4 * (days ~/ 1461);
    days %= 1461;

    if (days > 365) {
      jy += (days - 1) ~/ 365;
      days = (days - 1) % 365;
    }

    int jm;
    int jd;

    if (days < 186) {
      jm = 1 + days ~/ 31;
      jd = 1 + days % 31;
    } else {
      jm = 7 + (days - 186) ~/ 30;
      jd = 1 + (days - 186) % 30;
    }

    return [jy, jm, jd];
  }

  Future<void> _loadCharges() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.getCharges(
        search: _searchController.text,
      );

      if (!mounted) return;

      setState(() {
        _charges = data;
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

  Widget _info(
      String title,
      String value,
      IconData icon,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: teal, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
          Text(
            value,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final id = _int(item['id']);

    final name = item['name']?.toString() ?? 'شارژ فاضلاب';

    final amount = item['amount'] ?? 0;
    final prepayment = item['prepayment'] ?? 0;
    final count = item['installment_count'] ?? 0;

    final sent = item['sent_units_count'] ??
        item['sent_count'] ??
        item['sent_units'] ??
        0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: teal.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.water_drop_outlined,
                    color: teal,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'units') {
                      _openUnits(id, name);
                    } else if (value == 'details') {
                      _showDetails(item);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'units',
                      child: Text('مشاهده واحدها و اقساط'),
                    ),
                    PopupMenuItem(
                      value: 'details',
                      child: Text('جزئیات شارژ'),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            _info(
              'مبلغ کل شارژ',
              '${_money(amount)} ریال',
              Icons.payments_outlined,
            ),
            _info(
              'پیش‌پرداخت',
              '${_money(prepayment)} ریال',
              Icons.account_balance_wallet_outlined,
            ),
            _info(
              'تعداد اقساط',
              _fa(count.toString()),
              Icons.format_list_numbered,
            ),
            _info(
              'اولین سررسید',
              _date(item['first_due_date']),
              Icons.calendar_month_outlined,
            ),
            _info(
              'واحدهای ارسال‌شده',
              _fa(sent.toString()),
              Icons.send_outlined,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _openUnits(id, name),
                icon: const Icon(Icons.apartment),
                label: const Text('مشاهده واحدها و اقساط'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openUnits(int id, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerSewageChargeUnitsListScreen(
          sewageId: id,
          sewageName: name,
        ),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> item) {
    final details = item['details']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'جزئیات شارژ فاضلاب',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: purple,
                  ),
                ),
                const SizedBox(height: 18),
                _detailRow('نام شارژ', item['name'] ?? '-'),
                _detailRow(
                  'مبلغ کل',
                  '${_money(item['amount'])} ریال',
                ),
                _detailRow(
                  'پیش‌پرداخت',
                  '${_money(item['prepayment'])} ریال',
                ),
                _detailRow(
                  'تعداد اقساط',
                  _fa((item['installment_count'] ?? 0).toString()),
                ),
                _detailRow(
                  'اولین سررسید',
                  _date(item['first_due_date']),
                ),
                const SizedBox(height: 10),
                const Text(
                  'توضیحات',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  details.isEmpty ? 'توضیحاتی ثبت نشده است.' : details,
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Flexible(
            child: Text(
              value.toString(),
              textAlign: TextAlign.left,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 88,
          title: const Text('مدیریت شارژ فاضلاب'),
          backgroundColor: teal,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _loadCharges,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                onSubmitted: (_) => _loadCharges(),
                decoration: InputDecoration(
                  hintText: 'جست‌وجوی شارژ فاضلاب...',
                  hintTextDirection: TextDirection.rtl,
                  prefixIcon: const Icon(Icons.search, color: teal),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _loadCharges();
                    },
                    icon: const Icon(Icons.close),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadCharges,
                        child: const Text('تلاش مجدد'),
                      ),
                    ],
                  ),
                ),
              )
                  : _charges.isEmpty
                  ? const Center(
                child: Text('شارژ فاضلابی ثبت نشده است.'),
              )
                  : RefreshIndicator(
                onRefresh: _loadCharges,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _charges.length,
                  itemBuilder: (_, index) =>
                      _buildCard(_charges[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
