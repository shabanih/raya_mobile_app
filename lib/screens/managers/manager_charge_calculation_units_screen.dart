
import 'package:flutter/material.dart';

import '../../services/manager_charge_calculation_service.dart';

const Color _primaryColor = Color(0xFF00ACC1);
const Color _purpleColor = Color(0xFF610DB5);
const Color _greenColor = Color(0xFF2E7D32);
const Color _orangeColor = Color(0xFFEF6C00);

class ManagerChargeCalculationUnitsScreen extends StatefulWidget {
  final int calculationId;
  final String? calculationName;

  const ManagerChargeCalculationUnitsScreen({
    super.key,
    required this.calculationId,
    this.calculationName,
  });

  @override
  State<ManagerChargeCalculationUnitsScreen> createState() =>
      _ManagerChargeCalculationUnitsScreenState();
}

class _ManagerChargeCalculationUnitsScreenState
    extends State<ManagerChargeCalculationUnitsScreen> {
  final ManagerChargeCalculationService _service =
  ManagerChargeCalculationService();

  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  bool _processing = false;
  bool _sendSms = false;

  String _filter = 'all';
  String _chargeName = '';
  String _details = '';

  List<Map<String, dynamic>> _units = [];

  // واحدهای انتخاب‌شده برای ارسال اعلان
  final Set<int> _selectedSendIds = {};

  // واحدهای انتخاب‌شده برای لغو اعلان
  final Set<int> _selectedCancelIds = {};

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // تبدیل اعداد فارسی و عربی
  // ----------------------------------------------------------

  String _toEnglishDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';

    for (int i = 0; i < 10; i++) {
      value = value.replaceAll(persian[i], '$i');
      value = value.replaceAll(arabic[i], '$i');
    }

    return value;
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '۰';

    final normalized = _toEnglishDigits(value.toString());
    final number = num.tryParse(normalized);

    if (number == null) return value.toString();

    final rounded = number.round();
    final text = rounded.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);

      final remaining = text.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }

    return _toPersianDigits(buffer.toString());
  }

  String _toPersianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    for (int i = 0; i < 10; i++) {
      value = value.replaceAll(english[i], persian[i]);
    }

    return value;
  }

  String _money(dynamic value) => '${_formatNumber(value)} تومان';

  String _decimal(dynamic value) {
    if (value == null) return '۰';

    final normalized = _toEnglishDigits(value.toString());
    final number = num.tryParse(normalized);

    if (number == null) return value.toString();

    final result = number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toString();

    return _toPersianDigits(result);
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse(_toEnglishDigits(value?.toString() ?? '')) ?? 0;
  }

  bool _boolValue(dynamic value) {
    if (value == true || value == 1) return true;

    if (value is String) {
      final text = _toEnglishDigits(value).toLowerCase().trim();
      return text == 'true' || text == '1';
    }

    return false;
  }

  // ----------------------------------------------------------
  // خواندن پاسخ API
  // ----------------------------------------------------------

  Future<void> _loadUnits() async {
    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final dynamic response =
      await _service.getCalculationUnitsData(widget.calculationId);

      if (response is! Map) {
        throw Exception('ساختار پاسخ سرور معتبر نیست.');
      }

      final Map<String, dynamic> data =
      Map<String, dynamic>.from(response);

      if (data['success'] == false) {
        throw Exception(
          data['message']?.toString() ?? 'دریافت اطلاعات واحدها ناموفق بود.',
        );
      }

      final dynamic calculationData = data['calculation'];

      final Map<String, dynamic> calculation =
      calculationData is Map
          ? Map<String, dynamic>.from(calculationData)
          : <String, dynamic>{};

      final dynamic results = data['results'];

      if (results is! List) {
        throw Exception('فهرست واحدها در پاسخ سرور وجود ندارد.');
      }

      final List<Map<String, dynamic>> loadedUnits = [];

      for (final dynamic item in results) {
        if (item is Map) {
          loadedUnits.add(Map<String, dynamic>.from(item));
        }
      }

      if (!mounted) return;

      setState(() {
        _units = loadedUnits;

        _chargeName = (calculation['name'] ??
            calculation['title'] ??
            widget.calculationName ??
            'شارژ محاسباتی')
            .toString();

        _details = (calculation['details'] ?? '').toString();

        _selectedSendIds.clear();
        _selectedCancelIds.clear();
      });
    } catch (e) {
      if (mounted) {
        _showMessage(
          'دریافت اطلاعات با خطا مواجه شد: ${_cleanError(e)}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  // ----------------------------------------------------------
  // اطلاعات هر واحد
  // ----------------------------------------------------------

  int _unitId(Map<String, dynamic> unit) {
    return _intValue(unit['unit_id'] ?? unit['id']);
  }

  String _unitNumber(Map<String, dynamic> unit) {
    return (unit['unit'] ?? unit['unit_number'] ?? '-').toString();
  }

  bool _isPaid(Map<String, dynamic> unit) {
    return _boolValue(unit['is_paid']);
  }

  bool _isNotified(Map<String, dynamic> unit) {
    return _boolValue(unit['send_notification']);
  }

  bool _isSmsSent(Map<String, dynamic> unit) {
    return _boolValue(unit['send_sms']);
  }

  String _residentType(Map<String, dynamic> unit) {
    return (unit['resident_type'] ?? '').toString().toLowerCase().trim();
  }

  bool _isOwner(Map<String, dynamic> unit) {
    final type = _residentType(unit);
    return type == 'owner' || type == 'مالک';
  }

  bool _isRenter(Map<String, dynamic> unit) {
    final type = _residentType(unit);
    return type == 'renter' ||
        type == 'tenant' ||
        type == 'مستاجر' ||
        type == 'مستأجر';
  }

  bool _isEmptyUnit(Map<String, dynamic> unit) {
    final type = _residentType(unit);
    return type == 'empty' ||
        type == 'vacant' ||
        type == 'خالی' ||
        type == 'empty_unit';
  }

  // پرداخت‌شده‌ها قابل انتخاب نیستند.
  bool _canSend(Map<String, dynamic> unit) {
    return _unitId(unit) > 0 && !_isPaid(unit) && !_isNotified(unit);
  }

  // فقط اعلان واحد پرداخت‌نشده قابل لغو است.
  bool _canCancel(Map<String, dynamic> unit) {
    return _unitId(unit) > 0 && !_isPaid(unit) && _isNotified(unit);
  }

  bool _isSelected(Map<String, dynamic> unit) {
    final id = _unitId(unit);

    return _selectedSendIds.contains(id) ||
        _selectedCancelIds.contains(id);
  }

  void _toggleUnit(Map<String, dynamic> unit, bool selected) {
    final id = _unitId(unit);

    if (id <= 0 || _isPaid(unit)) return;

    setState(() {
      _selectedSendIds.remove(id);
      _selectedCancelIds.remove(id);

      if (!selected) return;

      if (_canSend(unit)) {
        _selectedSendIds.add(id);
      } else if (_canCancel(unit)) {
        _selectedCancelIds.add(id);
      }
    });
  }

  // ----------------------------------------------------------
  // فیلتر و جستجو
  // ----------------------------------------------------------

  List<Map<String, dynamic>> get _filteredUnits {
    final query = _toEnglishDigits(
      _searchController.text.trim().toLowerCase(),
    );

    return _units.where((unit) {
      bool matchesFilter;

      switch (_filter) {
        case 'owner':
          matchesFilter = _isOwner(unit);
          break;
        case 'renter':
          matchesFilter = _isRenter(unit);
          break;
        case 'empty':
          matchesFilter = _isEmptyUnit(unit);
          break;
        default:
          matchesFilter = true;
      }

      if (!matchesFilter) return false;
      if (query.isEmpty) return true;

      final unitNumber = _toEnglishDigits(_unitNumber(unit)).toLowerCase();
      final unitId = _unitId(unit).toString();
      final area = _toEnglishDigits(
        (unit['area'] ?? '').toString(),
      ).toLowerCase();

      return unitNumber.contains(query) ||
          unitId.contains(query) ||
          area.contains(query);
    }).toList();
  }

  List<Map<String, dynamic>> get _selectableFilteredUnits {
    return _filteredUnits.where((unit) {
      return _canSend(unit) || _canCancel(unit);
    }).toList();
  }

  int get _selectedCount =>
      _selectedSendIds.length + _selectedCancelIds.length;

  bool get _allFilteredSelected {
    final selectable = _selectableFilteredUnits;

    return selectable.isNotEmpty &&
        selectable.every((unit) => _isSelected(unit));
  }

  void _toggleSelectAll(bool selected) {
    setState(() {
      for (final unit in _selectableFilteredUnits) {
        final id = _unitId(unit);

        _selectedSendIds.remove(id);
        _selectedCancelIds.remove(id);

        if (!selected) continue;

        if (_canSend(unit)) {
          _selectedSendIds.add(id);
        } else if (_canCancel(unit)) {
          _selectedCancelIds.add(id);
        }
      }
    });
  }

  // ----------------------------------------------------------
  // ارسال اعلان
  // ----------------------------------------------------------

  Future<void> _showSendOptions() async {
    if (_selectedSendIds.isEmpty || _processing) return;

    bool sendSms = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'ارسال شارژ به واحدها',
                textAlign: TextAlign.right,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${_toPersianDigits(_selectedSendIds.length.toString())} واحد برای ارسال انتخاب شده است.',
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'ارسال پیامک',
                      textAlign: TextAlign.right,
                    ),
                    value: sendSms,
                    activeColor: _purpleColor,
                    onChanged: (value) {
                      setDialogState(() {
                        sendSms = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('انصراف'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('تأیید ارسال'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await _sendSelected(sendSms: sendSms);
    }
  }

  Future<void> _sendSelected({required bool sendSms}) async {
    if (_selectedSendIds.isEmpty || _processing) return;

    final ids = _selectedSendIds.toList();

    setState(() {
      _processing = true;
    });

    try {
      final dynamic response = await _service.sendCalculationToUnits(
        widget.calculationId,
        ids,
        sendSms: sendSms,
      );

      final Map<String, dynamic> result = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};

      if (result['success'] == false) {
        throw Exception(
          result['message']?.toString() ?? 'ارسال شارژ ناموفق بود.',
        );
      }

      String message =
      (result['message'] ?? 'عملیات ارسال شارژ انجام شد.').toString();

      if (sendSms && result['sms_success'] == false) {
        final smsMessage = result['sms_message']?.toString();

        if (smsMessage != null && smsMessage.isNotEmpty) {
          message = '$message\n$smsMessage';
        }
      }

      if (!mounted) return;

      _showMessage(
        message,
        isError: sendSms && result['sms_success'] == false,
      );

      await _loadUnits();
    } catch (e) {
      if (mounted) {
        _showMessage(
          'ارسال شارژ با خطا مواجه شد: ${_cleanError(e)}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  // ----------------------------------------------------------
  // لغو اعلان
  // ----------------------------------------------------------

  Future<void> _cancelSelected() async {
    if (_selectedCancelIds.isEmpty || _processing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('لغو اعلان شارژ'),
          content: Text(
            'اعلان شارژ برای ${_toPersianDigits(_selectedCancelIds.length.toString())} واحد لغو شود؟',
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('انصراف'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('لغو اعلان'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _processing = true;
    });

    try {
      final ids = _selectedCancelIds.toList();

      final dynamic response =
      await _service.cancelCalculationForUnits(
        widget.calculationId,
        ids,
      );

      final Map<String, dynamic> result = response is Map
          ? Map<String, dynamic>.from(response)
          : <String, dynamic>{};

      if (result['success'] == false) {
        throw Exception(
          result['message']?.toString() ?? 'لغو اعلان ناموفق بود.',
        );
      }

      if (!mounted) return;

      _showMessage(
        (result['message'] ?? 'اعلان واحدهای انتخاب‌شده لغو شد.')
            .toString(),
      );

      await _loadUnits();
    } catch (e) {
      if (mounted) {
        _showMessage(
          'لغو اعلان با خطا مواجه شد: ${_cleanError(e)}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
        ),
        backgroundColor: isError ? Colors.red.shade700 : _greenColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ----------------------------------------------------------
  // رابط کاربری
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'واحدهای شارژ محاسباتی',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'بروزرسانی',
              onPressed: _loading || _processing ? null : _loadUnits,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _loading
            ? const Center(
          child: CircularProgressIndicator(color: _primaryColor),
        )
            : Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            _buildSearch(),
            _buildSelectionBar(),
            Expanded(
              child: _filteredUnits.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                onRefresh: _loadUnits,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    4,
                    12,
                    16,
                  ),
                  itemCount: _filteredUnits.length,
                  itemBuilder: (context, index) {
                    return _buildUnitCard(
                      _filteredUnits[index],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _loading ? null : _buildBottomActions(),
      ),
    );
  }

  // ----------------------------------------------------------
  // کارت هدر نام شارژ
  // ----------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryColor, Color(0xFF008C9E)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'نام شارژ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _chargeName.isEmpty ? 'شارژ محاسباتی' : _chargeName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_details.trim().isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    _details,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 7),
                Text(
                  'تعداد واحدها: ${_toPersianDigits(_units.length.toString())}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // فیلتر مالک، مستأجر و خالی
  // ----------------------------------------------------------

  Widget _buildFilters() {
    final options = <Map<String, String>>[
      {'key': 'all', 'label': 'همه'},
      {'key': 'owner', 'label': 'مالکین'},
      {'key': 'renter', 'label': 'مستأجرین'},
      {'key': 'empty', 'label': 'واحدهای خالی'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: options.map((option) {
          final selected = _filter == option['key'];

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () {
                setState(() {
                  _filter = option['key']!;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 2,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? _primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  option['label']!,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ----------------------------------------------------------
  // جستجو
  // ----------------------------------------------------------

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 5),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        textAlign: TextAlign.right,
        decoration: InputDecoration(
          hintText: 'جستجو بر اساس شماره واحد یا متراژ',
          hintStyle: const TextStyle(fontSize: 12),
          prefixIcon: const Icon(
            Icons.search,
            color: _primaryColor,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
            icon: const Icon(Icons.close),
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // انتخاب همه و شمارنده
  // ----------------------------------------------------------

  Widget _buildSelectionBar() {
    final total = _units.length;
    final selected = _selectedCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 5, 12, 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Checkbox(
            value: _allFilteredSelected,
            tristate: true,
            activeColor: _primaryColor,
            onChanged: _selectableFilteredUnits.isEmpty
                ? null
                : (value) => _toggleSelectAll(value == true),
          ),
          const Expanded(
            child: Text(
              'انتخاب همه واحدها',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: _purpleColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '${_toPersianDigits(selected.toString())} از ${_toPersianDigits(total.toString())} واحد',
              style: const TextStyle(
                color: _purpleColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // کارت واحد
  // ----------------------------------------------------------

  Widget _buildUnitCard(Map<String, dynamic> unit) {
    final id = _unitId(unit);
    final paid = _isPaid(unit);
    final notified = _isNotified(unit);
    final smsSent = _isSmsSent(unit);
    final selected = _isSelected(unit);

    final total = unit['total'] ?? unit['cost_total'] ?? 0;
    final area = unit['area'] ?? 0;
    final people = unit['people_count'] ?? 0;
    final otherCost = unit['other_cost_amount'] ?? 0;
    final costTotal = unit['cost_total'] ?? total;
    final documentNumber = unit['financial_document_number'];

    final Color statusColor = paid
        ? _greenColor
        : notified
        ? _orangeColor
        : _primaryColor;

    final Color cardColor = selected
        ? _primaryColor.withOpacity(0.035)
        : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: selected
              ? _primaryColor.withOpacity(0.7)
              : Colors.grey.shade200,
          width: selected ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 5, 8),
            child: Row(
              children: [
                Checkbox(
                  value: selected,
                  activeColor: _purpleColor,
                  onChanged: paid
                      ? null
                      : (value) =>
                      _toggleUnit(unit, value ?? false),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _purpleColor.withOpacity(0.09),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(
                          Icons.home_work_outlined,
                          color: _purpleColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'واحد ${_unitNumber(unit)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (paid)
                  _statusChip(
                    'پرداخت شده',
                    _greenColor,
                    Icons.check_circle_outline,
                  )
                else if (notified)
                  _statusChip(
                    'اعلان ثبت شده',
                    _orangeColor,
                    Icons.notifications_active_outlined,
                  ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200),

          // متراژ و تعداد نفرات در یک سطر
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 11,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _infoItem(
                    icon: Icons.square_foot,
                    label: 'متراژ',
                    value: '${_decimal(area)} متر',
                    color: _primaryColor,
                  ),
                ),
                Container(
                  height: 35,
                  width: 1,
                  color: Colors.grey.shade200,
                ),
                Expanded(
                  child: _infoItem(
                    icon: Icons.people_alt_outlined,
                    label: 'تعداد نفرات',
                    value: _formatNumber(people),
                    color: _purpleColor,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              children: [
                _amountRow(
                  'مبلغ پایه سهم واحد',
                  _money(costTotal),
                ),
                const SizedBox(height: 5),
                _amountRow(
                  'هزینه اضافی',
                  _money(otherCost),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'مبلغ نهایی شارژ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          _money(total),
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: _primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (documentNumber != null &&
                    documentNumber.toString().trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'شماره سند مالی: $documentNumber',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (notified || smsSent) ...[
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      if (notified)
                        _statusChip(
                          'اعلان ثبت شده',
                          _orangeColor,
                          Icons.notifications_active_outlined,
                        ),
                      if (notified && smsSent)
                        const SizedBox(width: 7),
                      if (smsSent)
                        _statusChip(
                          'پیامک ارسال شده',
                          _greenColor,
                          Icons.sms_outlined,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 21),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _amountRow(String label, String amount) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            amount,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(
      String label,
      Color color,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 65),
        Icon(
          Icons.inbox_outlined,
          size: 62,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 12),
        Text(
          _units.isEmpty
              ? 'واحدی برای این شارژ ثبت نشده است.'
              : 'واحدی با این فیلتر یا جستجو پیدا نشد.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // دکمه‌های عملیات پایین صفحه
  // ----------------------------------------------------------

  Widget _buildBottomActions() {
    final hasSendSelection = _selectedSendIds.isNotEmpty;
    final hasCancelSelection = _selectedCancelIds.isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 17,
                      color: _purpleColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'انتخاب‌شده: ${_toPersianDigits(_selectedCount.toString())} واحد',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _processing
                          ? null
                          : () {
                        setState(() {
                          _selectedSendIds.clear();
                          _selectedCancelIds.clear();
                        });
                      },
                      child: const Text('لغو انتخاب'),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _processing || !hasSendSelection
                        ? null
                        : _showSendOptions,
                    icon: const Icon(Icons.send),
                    label: Text(
                      'ارسال شارژ (${_toPersianDigits(_selectedSendIds.length.toString())})',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _processing || !hasCancelSelection
                        ? null
                        : _cancelSelected,
                    icon: const Icon(Icons.notifications_off_outlined),
                    label: Text(
                      'لغو اعلان (${_toPersianDigits(_selectedCancelIds.length.toString())})',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_processing) ...[
              const SizedBox(height: 9),
              const LinearProgressIndicator(color: _primaryColor),
            ],
          ],
        ),
      ),
    );
  }
}
