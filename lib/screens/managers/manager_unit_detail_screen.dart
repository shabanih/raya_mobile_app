
import 'package:flutter/material.dart';

import '../../services/manager_unit_service.dart';
import 'manager_unit_owner_screen.dart';
import 'manager_unit_renter_screen.dart';

class ManagerUnitDetailScreen extends StatefulWidget {
  final int unitId;

  const ManagerUnitDetailScreen({
    super.key,
    required this.unitId,
  });

  @override
  State<ManagerUnitDetailScreen> createState() =>
      _ManagerUnitDetailScreenState();
}

class _ManagerUnitDetailScreenState
    extends State<ManagerUnitDetailScreen> {
  static const Color primaryColor = Color(0xff00ACC1);
  static const Color unitColor = Color(0xff610DB5);
  static const Color backgroundColor = Color(0xffF7F9FA);

  final ManagerUnitService _unitService = ManagerUnitService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? _unit;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _isChangingStatus = false;

  String? _errorMessage;

  final TextEditingController _unitNumberController =
  TextEditingController();
  final TextEditingController _floorController =
  TextEditingController();
  final TextEditingController _areaController =
  TextEditingController();
  final TextEditingController _bedroomsController =
  TextEditingController();
  final TextEditingController _parkingNumberController =
  TextEditingController();
  final TextEditingController _parkingPlaceController =
  TextEditingController();
  final TextEditingController _extraParkingFirstController =
  TextEditingController();
  final TextEditingController _extraParkingSecondController =
  TextEditingController();
  final TextEditingController _unitPhoneController =
  TextEditingController();
  final TextEditingController _detailsController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUnit();
  }

  @override
  void dispose() {
    _unitNumberController.dispose();
    _floorController.dispose();
    _areaController.dispose();
    _bedroomsController.dispose();
    _parkingNumberController.dispose();
    _parkingPlaceController.dispose();
    _extraParkingFirstController.dispose();
    _extraParkingSecondController.dispose();
    _unitPhoneController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  // =========================================================
  // Load unit
  // =========================================================

  Future<void> _loadUnit() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _unitService.getUnit(widget.unitId);

      if (!mounted) return;

      _unit = _extractUnit(result);
      _fillForm();

      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _cleanError(e);
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic>? _extractUnit(dynamic result) {
    if (result is! Map) return null;

    final map = Map<String, dynamic>.from(result);

    // اگر پاسخ API شامل یک شیء داخلی به نام unit باشد
    final nestedUnit = map['unit'];
    if (nestedUnit is Map) {
      return Map<String, dynamic>.from(nestedUnit);
    }

    // اگر پاسخ به صورت data ارسال شده باشد
    final data = map['data'];
    if (data is Map) {
      final nestedDataUnit = data['unit'];
      if (nestedDataUnit is Map) {
        return Map<String, dynamic>.from(nestedDataUnit);
      }
      return Map<String, dynamic>.from(data);
    }

    final resultData = map['result'];
    if (resultData is Map) {
      return Map<String, dynamic>.from(resultData);
    }

    return map;
  }

  // =========================================================
  // Form
  // =========================================================

  void _fillForm() {
    final unit = _unit;
    if (unit == null) return;

    _unitNumberController.text = _toPersianDigits(
      _firstValue(unit, ['unit', 'unit_number', 'number']),
    );

    _floorController.text = _toPersianDigits(
      _firstValue(unit, ['floor_number', 'floor']),
    );

    _areaController.text = _toPersianDigits(
      _firstValue(unit, ['area', 'unit_area']),
    );

    _bedroomsController.text = _toPersianDigits(
      _firstValue(unit, ['bedrooms_count', 'bedrooms']),
    );

    _parkingNumberController.text = _toPersianDigits(
      _firstValue(unit, ['parking_number']),
    );

    _parkingPlaceController.text =
        _firstValue(unit, ['parking_place']);

    _extraParkingFirstController.text =
        _firstValue(unit, ['extra_parking_first']);

    _extraParkingSecondController.text =
        _firstValue(unit, ['extra_parking_second']);

    _unitPhoneController.text = _toPersianDigits(
      _firstValue(unit, ['unit_phone']),
    );

    _detailsController.text =
        _firstValue(unit, ['unit_details', 'details']);
  }

  String _firstValue(
      Map<String, dynamic> map,
      List<String> keys, {
        String fallback = '',
      }) {
    for (final key in keys) {
      final value = map[key];

      if (value == null || value is Map || value is List) {
        continue;
      }

      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') {
        return text;
      }
    }

    return fallback;
  }

  String _normalizeDigits(String value) {
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';

    var result = value;

    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(persian[i], '$i');
      result = result.replaceAll(arabic[i], '$i');
    }

    return result;
  }

  String _toPersianDigits(dynamic value) {
    if (value == null) return '';

    var result = value.toString();
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    for (var i = 0; i < 10; i++) {
      result = result.replaceAll('$i', persian[i]);
    }

    return result;
  }

  void _startEditing() {
    _fillForm();

    setState(() {
      _isEditing = true;
      _errorMessage = null;
    });
  }

  void _cancelEditing() {
    _fillForm();

    setState(() {
      _isEditing = false;
    });
  }
  // =========================================================
  // DeActive or Active unit
  // ========================================================

  Future<void> _changeUnitStatus() async {
    if (_isChangingStatus || _unit == null) return;

    final newStatus = !_unitIsActive();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          newStatus ? 'فعال‌سازی واحد' : 'غیرفعال کردن واحد',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('تأیید'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _unit!['is_active'] = newStatus;
    });

    try {
      await _unitService.updateUnitStatus(
        widget.unitId,
        newStatus,
      );

      if (!mounted) return;

      setState(() {
        _unit!['is_active'] = newStatus;
      });

      _showMessage(
        newStatus
            ? 'واحد با موفقیت فعال شد.'
            : 'واحد با موفقیت غیرفعال شد.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        _cleanError(e),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isChangingStatus = false);
      }
    }
  }


  // =========================================================
  // Save unit
  // =========================================================

  Future<void> _saveUnit() async {
    if (_isSaving) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final unitNumber = int.tryParse(
      _normalizeDigits(_unitNumberController.text.trim()),
    );

    if (unitNumber == null || unitNumber <= 0) {
      _showMessage('شماره واحد معتبر نیست.', isError: true);
      return;
    }

    final areaText =
    _normalizeDigits(_areaController.text.trim())
        .replaceAll(',', '.');

    final area = double.tryParse(areaText);

    if (area == null || area <= 0) {
      _showMessage('متراژ معتبر نیست.', isError: true);
      return;
    }

    int? parseOptionalInt(String value) {
      final text = _normalizeDigits(value.trim());
      if (text.isEmpty) return null;
      return int.tryParse(text);
    }

    setState(() => _isSaving = true);

    try {
      // فقط فیلدهای خود واحد ارسال می‌شوند.
      // مالک و مستأجر باید از APIهای مربوط به خودشان ویرایش شوند.
      final data = <String, dynamic>{
        'unit': unitNumber,
        'floor_number': parseOptionalInt(_floorController.text),
        'area': areaText,
        'bedrooms_count':
        parseOptionalInt(_bedroomsController.text),
        'parking_number':
        _parkingNumberController.text.trim(),
        'parking_place':
        _parkingPlaceController.text.trim(),
        'extra_parking_first':
        _extraParkingFirstController.text.trim(),
        'extra_parking_second':
        _extraParkingSecondController.text.trim(),
        'unit_phone': _normalizeDigits(
          _unitPhoneController.text.trim(),
        ),
        'unit_details': _detailsController.text.trim(),
      };

      await _unitService.updateUnit(widget.unitId, data);

      if (!mounted) return;

      _showMessage('اطلاعات واحد با موفقیت ویرایش شد.');

      await _loadUnit();
    } catch (e) {
      if (!mounted) return;
      _showMessage(_cleanError(e), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // =========================================================
  // Errors
  // =========================================================

  String _cleanError(dynamic error) {
    var message = error.toString().trim();

    if (message.startsWith('Exception: ')) {
      message = message.substring('Exception: '.length);
    }

    return message.isEmpty ? 'خطایی رخ داده است.' : message;
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.right,
          ),
          backgroundColor: isError ? Colors.red : primaryColor,
        ),
      );
  }

  // =========================================================
  // Unit values
  // =========================================================

  String _unitNumber() {
    final value = _firstValue(
      _unit ?? {},
      ['unit', 'unit_number', 'number'],
      fallback: '-',
    );

    return _toPersianDigits(value);
  }

  String _unitField(
      List<String> keys, {
        String fallback = '-',
      }) {
    return _firstValue(_unit ?? {}, keys, fallback: fallback);
  }

  bool _parseBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = _normalizeDigits(value.toString())
        .toLowerCase()
        .trim();

    if (['true', '1', 'yes', 'active', 'فعال'].contains(text)) {
      return true;
    }

    if ([
      'false',
      '0',
      'no',
      'inactive',
      'غیرفعال',
    ].contains(text)) {
      return false;
    }

    return fallback;
  }



  bool _unitIsActive() {
    final dynamic data = _unit;

    if (data is! Map) return false;

    dynamic value = data['is_active'];

    // فقط اگر مقدار unit یک Map باشد، وضعیت داخلی را بخوان.
    if (value == null && data['unit'] is Map) {
      value = data['unit']['is_active'];
    }

    if (value == null && data['data'] is Map) {
      value = data['data']['is_active'];
    }

    if (value is bool) return value;
    if (value is num) return value != 0;

    if (value is String) {
      final normalized = value.trim().toLowerCase();

      if (normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes') {
        return true;
      }

      if (normalized == 'false' ||
          normalized == '0' ||
          normalized == 'no') {
        return false;
      }
    }

    return false;
  }



  // =========================================================
  // Owner
  // =========================================================

  Map<String, dynamic>? _owner() {
    final unit = _unit;
    if (unit == null) return null;

    for (final key in [
      'owner',
      'current_owner',
      'active_owner',
    ]) {
      final value = unit[key];
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
    }

    final name = unit['owner_name'];
    final mobile = unit['owner_mobile'];

    if ((name == null || name.toString().trim().isEmpty) &&
        (mobile == null || mobile.toString().trim().isEmpty)) {
      return null;
    }

    return {
      'name': name,
      'owner_name': name,
      'mobile': mobile,
      'owner_mobile': mobile,
      'national_code': unit['owner_national_code'],
      'people_count': unit['owner_people_count'],
      'details': unit['owner_details'],
      'purchase_date': unit['purchase_date'],
      'is_active': unit['owner_is_active'],
    };
  }

  String _ownerValue(List<String> keys, {String fallback = '-'}) {
    final owner = _owner();
    if (owner == null) return fallback;

    return _firstValue(owner, keys, fallback: fallback);
  }

  String _ownerName() {
    return _ownerValue(
      ['name', 'full_name', 'owner_name'],
      fallback: 'مالک ثبت نشده',
    );
  }

  String _ownerMobile() {
    return _toPersianDigits(
      _ownerValue(['mobile', 'owner_mobile', 'phone']),
    );
  }

  String _ownerNationalCode() {
    return _toPersianDigits(
      _ownerValue(['national_code', 'owner_national_code']),
    );
  }

  String _ownerPeopleCount() {
    return _toPersianDigits(
      _ownerValue(
        ['people_count', 'owner_people_count'],
        fallback: '۰',
      ),
    );
  }

  String _ownerDetails() {
    return _ownerValue(
      ['details', 'owner_details'],
      fallback: '',
    );
  }

  bool _hasOwner() {
    final owner = _owner();
    if (owner == null) return false;

    final name = owner['name'] ??
        owner['full_name'] ??
        owner['owner_name'];

    return name != null && name.toString().trim().isNotEmpty;
  }

  bool _ownerIsActive() {
    if (!_hasOwner()) return false;

    final owner = _owner();
    final value = owner?['is_active'] ??
        owner?['owner_is_active'] ??
        owner?['owner_active'];

    // اگر API وضعیت مالک را نفرستاده باشد، وجود اطلاعات مالک
    // به‌تنهایی برای تشخیص قطعی فعال بودن کافی نیست.
    return _parseBool(value, fallback: true);
  }

  String _ownerPurchaseDate() {
    return _formatShamsiDate(
      _owner()?['purchase_date'] ??
          _owner()?['owner_purchase_date'],
    );
  }

  // =========================================================
  // Renter: prioritize active_renter from API
  // =========================================================

  Map<String, dynamic>? _renter() {
    final unit = _unit;
    if (unit == null) return null;

    final activeRenter = unit['active_renter'];
    if (activeRenter is Map) {
      return Map<String, dynamic>.from(activeRenter);
    }

    final renter = unit['renter'];
    if (renter is Map) {
      return Map<String, dynamic>.from(renter);
    }

    final renters = unit['renters'];
    if (renters is List) {
      Map<String, dynamic>? latest;

      for (final item in renters) {
        if (item is! Map) continue;

        final map = Map<String, dynamic>.from(item);
        final name = map['renter_name'] ??
            map['name'] ??
            map['full_name'];

        if (name == null || name.toString().trim().isEmpty) {
          continue;
        }

        latest ??= map;

        if (_parseBool(
          map['renter_is_active'] ?? map['is_active'],
          fallback: false,
        )) {
          return map;
        }
      }

      return latest;
    }

    // اطلاعات مستأجر مستقیم، اگر ویو از این ساختار استفاده کند.
    final name = unit['renter_name'];
    final mobile = unit['renter_mobile'];

    if ((name == null || name.toString().trim().isEmpty) &&
        (mobile == null || mobile.toString().trim().isEmpty)) {
      return null;
    }

    return {
      'id': unit['renter_id'],
      'name': name,
      'renter_name': name,
      'mobile': mobile,
      'renter_mobile': mobile,
      'national_code': unit['renter_national_code'],
      'people_count': unit['renter_people_count'],
      'start_date': unit['renter_start_date'] ?? unit['start_date'],
      'end_date': unit['renter_end_date'] ?? unit['end_date'],
      'contract_number': unit['contract_number'],
      'estate_name': unit['estate_name'],
      'details': unit['renter_details'],
      'renter_is_active': unit['renter_is_active'],
    };
  }

  String _renterValue(
      List<String> keys, {
        String fallback = '-',
      }) {
    final renter = _renter();
    if (renter == null) return fallback;

    return _firstValue(renter, keys, fallback: fallback);
  }


  bool _hasRenter() {
    final unit = _unit;
    if (unit == null) return false;

    // وجود مستأجر فعال یا غیرفعال در پاسخ API
    for (final key in ['active_renter', 'renter']) {
      final value = unit[key];

      if (value is Map) {
        final name = value['name'] ??
            value['renter_name'] ??
            value['full_name'];

        if (name != null && name.toString().trim().isNotEmpty) {
          return true;
        }
      }
    }

    // بررسی فهرست مستأجران، شامل مستأجران غیرفعال
    final renters = unit['renters'];

    if (renters is List && renters.isNotEmpty) {
      for (final item in renters) {
        if (item is! Map) continue;

        final name = item['name'] ??
            item['renter_name'] ??
            item['full_name'];

        if (name != null && name.toString().trim().isNotEmpty) {
          return true;
        }
      }
    }

    // بررسی اطلاعات مستقیم مستأجر در پاسخ API
    final name = unit['renter_name'] ?? unit['renter_full_name'];
    final mobile = unit['renter_mobile'];

    return (name != null && name.toString().trim().isNotEmpty) ||
        (mobile != null && mobile.toString().trim().isNotEmpty);
  }


  bool _renterIsActive() {
    final renter = _renter();
    if (renter == null) return false;

    return _parseBool(
      renter['renter_is_active'] ??
          renter['is_active'] ??
          renter['active'],
      fallback: false,
    );
  }

  String _renterName() {
    return _renterValue(
      ['renter_name', 'name', 'full_name'],
      fallback: 'مستأجر ثبت نشده',
    );
  }

  String _renterMobile() {
    return _toPersianDigits(
      _renterValue(['renter_mobile', 'mobile', 'phone']),
    );
  }

  String _renterNationalCode() {
    return _toPersianDigits(
      _renterValue(['renter_national_code', 'national_code']),
    );
  }

  String _renterPeopleCount() {
    return _toPersianDigits(
      _renterValue(
        ['renter_people_count', 'people_count'],
        fallback: '۰',
      ),
    );
  }

  String _renterStartDate() {
    return _formatShamsiDate(
      _renter()?['start_date'] ??
          _renter()?['renter_start_date'],
    );
  }

  String _renterEndDate() {
    final value = _renter()?['end_date'] ??
        _renter()?['renter_end_date'];

    if (value == null || value.toString().trim().isEmpty) {
      return 'تا کنون';
    }

    return _formatShamsiDate(value);
  }

  String _renterContractNumber() {
    return _toPersianDigits(
      _renterValue(['contract_number']),
    );
  }

  String _renterEstateName() {
    return _renterValue(['estate_name', 'agency_name']);
  }

  String _renterDetails() {
    return _renterValue(
      ['details', 'renter_details'],
      fallback: '',
    );
  }

  // =========================================================
  // Residence status
  // =========================================================

  String _residenceStatus() {
    if (!_unitIsActive()) return 'غیرفعال';

    if (_hasRenter() && _renterIsActive()) {
      return 'ساکن - مستأجر';
    }

    if (_hasOwner() && _ownerIsActive()) {
      return 'ساکن - مالک';
    }

    if (_hasRenter() || _hasOwner()) {
      return 'غیرفعال';
    }

    return 'خالی';
  }

  // =========================================================
  // Date formatting
  // =========================================================

  String _formatShamsiDate(dynamic value) {
    if (value == null) return '-';

    var date = _normalizeDigits(value.toString().trim());
    if (date.isEmpty) return '-';

    if (date.contains('T')) {
      date = date.split('T').first;
    }
    if (date.contains(' ')) {
      date = date.split(' ').first;
    }

    if (date.contains('/')) {
      final parts = date.split('/');
      if (parts.length >= 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);

        if (year != null && month != null && day != null) {
          if (year < 1500) {
            return _toPersianDigits(
              '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}',
            );
          }

          return _toPersianDigits(
            '${_gregorianToJalali(year, month, day).join('/')}',
          );
        }
      }
    }

    final parts = date.split('-');
    if (parts.length < 3) return _toPersianDigits(date);

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) {
      return _toPersianDigits(date);
    }

    if (year < 1500) {
      return _toPersianDigits(
        '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}',
      );
    }

    final jalali = _gregorianToJalali(year, month, day);

    return _toPersianDigits(
      '${jalali[0]}/${jalali[1].toString().padLeft(2, '0')}/${jalali[2].toString().padLeft(2, '0')}',
    );
  }

  List<int> _gregorianToJalali(int gy, int gm, int gd) {
    final gDaysInMonth = [
      31, 28, 31, 30, 31, 30,
      31, 31, 30, 31, 30, 31,
    ];

    final jDaysInMonth = [
      31, 31, 31, 31, 31, 31,
      30, 30, 30, 30, 30, 29,
    ];

    final gy2 = gy - 1600;
    final gm2 = gm - 1;
    final gd2 = gd - 1;

    var gDayNo = 365 * gy2 +
        ((gy2 + 3) ~/ 4) -
        ((gy2 + 99) ~/ 100) +
        ((gy2 + 399) ~/ 400);

    for (var i = 0; i < gm2; i++) {
      gDayNo += gDaysInMonth[i];
    }

    if (gm2 > 1 &&
        ((gy % 4 == 0 && gy % 100 != 0) || gy % 400 == 0)) {
      gDayNo++;
    }

    gDayNo += gd2;

    var jDayNo = gDayNo - 79;
    final jNp = jDayNo ~/ 12053;
    var jy = 979 + 33 * jNp;

    jDayNo %= 12053;
    jy += 4 * (jDayNo ~/ 1461);
    jDayNo %= 1461;

    if (jDayNo >= 366) {
      jy += (jDayNo - 1) ~/ 365;
      jDayNo = (jDayNo - 1) % 365;
    }

    var jm = 0;

    for (var i = 0;
    i < 11 && jDayNo >= jDaysInMonth[i];
    i++) {
      jDayNo -= jDaysInMonth[i];
      jm++;
    }

    return [jy, jm + 1, jDayNo + 1];
  }

  // =========================================================
  // Widgets
  // =========================================================

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value.isEmpty ? '-' : value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _personInfoRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: unitColor, size: 19),
          const SizedBox(width: 9),
          SizedBox(
            width: 92,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String title, bool active) {
    final color = active ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        '$title: ${active ? 'فعال' : 'غیرفعال'}',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _personCard({
    required String name,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool exists,
    required List<Widget> details,
    required Widget status,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: exists ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: exists ? color : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (exists) ...[
            const Divider(height: 25),
            ...details,
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: status,
            ),
          ],
        ],
      ),
    );
  }

  Widget _managementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(top: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryColor, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: primaryColor,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // Edit form
  // =========================================================

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: unitColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'در این فرم فقط مشخصات واحد تغییر می‌کند. '
                  'برای تغییر مالک یا مستأجر از بخش مربوط به همان شخص استفاده کنید.',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13),
            ),
          ),
          _editField(
            controller: _unitNumberController,
            label: 'شماره واحد',
            icon: Icons.numbers,
            keyboardType: TextInputType.number,
            validator: (value) {
              final number = int.tryParse(
                _normalizeDigits((value ?? '').trim()),
              );

              if (number == null || number <= 0) {
                return 'شماره واحد معتبر وارد کنید';
              }

              return null;
            },
          ),
          _editField(
            controller: _floorController,
            label: 'طبقه',
            icon: Icons.layers_outlined,
            keyboardType: TextInputType.number,
          ),
          _editField(
            controller: _areaController,
            label: 'متراژ',
            icon: Icons.square_foot,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (value) {
              final area = double.tryParse(
                _normalizeDigits((value ?? '').trim())
                    .replaceAll(',', '.'),
              );

              if (area == null || area <= 0) {
                return 'متراژ معتبر وارد کنید';
              }

              return null;
            },
          ),
          _editField(
            controller: _bedroomsController,
            label: 'تعداد خواب',
            icon: Icons.bed_outlined,
            keyboardType: TextInputType.number,
          ),
          _editField(
            controller: _parkingNumberController,
            label: 'شماره پارکینگ',
            icon: Icons.local_parking_outlined,
          ),
          _editField(
            controller: _parkingPlaceController,
            label: 'محل پارکینگ',
            icon: Icons.directions_car_outlined,
          ),
          _editField(
            controller: _extraParkingFirstController,
            label: 'پارکینگ اضافه اول',
            icon: Icons.add_circle_outline,
          ),
          _editField(
            controller: _extraParkingSecondController,
            label: 'پارکینگ اضافه دوم',
            icon: Icons.add_circle_outline,
          ),
          _editField(
            controller: _unitPhoneController,
            label: 'تلفن واحد',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          _editField(
            controller: _detailsController,
            label: 'توضیحات واحد',
            icon: Icons.notes_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveUnit,
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isSaving ? 'در حال ذخیره...' : 'ذخیره تغییرات',
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _isSaving ? null : _cancelEditing,
            child: const Text('انصراف'),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Normal body
  // =========================================================

  Widget _buildBody() {
    if (_unit == null) {
      return const Center(
        child: Text('اطلاعات واحد پیدا نشد.'),
      );
    }

    if (_isEditing) {
      return ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _header(
            title: 'ویرایش اطلاعات واحد',
            icon: Icons.edit_outlined,
          ),
          const SizedBox(height: 18),
          _buildEditForm(),
        ],
      );
    }

    final ownerExists = _hasOwner();
    final renterExists = _hasRenter();

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _loadUnit,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _header(
            title: 'واحد ${_unitNumber()}',
            icon: Icons.apartment_rounded,
          ),
          const SizedBox(height: 12),
          _infoCard(
            icon: Icons.verified_outlined,
            title: 'وضعیت واحد',
            value: _unitIsActive() ? 'فعال' : 'غیرفعال',
            valueColor: _unitIsActive() ? Colors.green : Colors.red,
          ),
          _infoCard(
            icon: Icons.numbers,
            title: 'شماره واحد',
            value: _unitNumber(),
          ),
          _infoCard(
            icon: Icons.layers_outlined,
            title: 'طبقه',
            value: _toPersianDigits(
              _unitField(['floor_number'], fallback: '-'),
            ),
          ),
          _infoCard(
            icon: Icons.square_foot,
            title: 'متراژ',
            value: '${_toPersianDigits(_unitField(['area']))} مترمربع',
          ),
          _infoCard(
            icon: Icons.bed_outlined,
            title: 'تعداد خواب',
            value: _toPersianDigits(
              _unitField(['bedrooms_count']),
            ),
          ),
          _infoCard(
            icon: Icons.local_parking_outlined,
            title: 'شماره پارکینگ',
            value: _toPersianDigits(
              _unitField(['parking_number']),
            ),
          ),
          _infoCard(
            icon: Icons.directions_car_outlined,
            title: 'محل پارکینگ',
            value: _unitField(['parking_place']),
          ),
          _infoCard(
            icon: Icons.add_circle_outline,
            title: 'پارکینگ اضافه اول',
            value: _unitField(['extra_parking_first']),
          ),
          _infoCard(
            icon: Icons.add_circle_outline,
            title: 'پارکینگ اضافه دوم',
            value: _unitField(['extra_parking_second']),
          ),
          _infoCard(
            icon: Icons.phone_outlined,
            title: 'تلفن واحد',
            value: _toPersianDigits(
              _unitField(['unit_phone']),
            ),
          ),
          _infoCard(
            icon: Icons.people_outline,
            title: 'تعداد ساکنین',
            value: _toPersianDigits(
              _unitField(['people_count'], fallback: '۰'),
            ),
          ),
          _infoCard(
            icon: Icons.home_outlined,
            title: 'وضعیت سکونت',
            value: _residenceStatus(),
          ),
          if (_unitField(
            ['unit_details', 'details'],
            fallback: '',
          ).trim().isNotEmpty)
            _infoCard(
              icon: Icons.notes_outlined,
              title: 'توضیحات واحد',
              value: _unitField(
                ['unit_details', 'details'],
                fallback: '',
              ),
            ),
          const SizedBox(height: 10),

// دکمه ویرایش مشخصات واحد
            SizedBox(
            height: 50,
            child: FilledButton.icon(
            onPressed: _startEditing,
            style: FilledButton.styleFrom(
            backgroundColor: unitColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            ),
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('ویرایش اطلاعات واحد'),
            ),
            ),

            const SizedBox(height: 10),

          // دکمه فعال‌سازی / غیرفعال‌سازی واحد
              SizedBox(
              height: 50,
              child: FilledButton.icon(
              onPressed:
              _isChangingStatus ? null : _changeUnitStatus,
              style: FilledButton.styleFrom(
              backgroundColor:
              _unitIsActive() ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              ),
              ),
              icon: _isChangingStatus
              ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
              ),
              )
                  : Icon(
              _unitIsActive()
              ? Icons.toggle_off_outlined
                  : Icons.toggle_on_outlined,
              ),
              label: Text(
              _isChangingStatus
              ? 'در حال تغییر وضعیت...'
                  : _unitIsActive()
              ? 'غیرفعال کردن واحد'
                  : 'فعال‌سازی واحد',
              ),
              ),
              ),

              const SizedBox(height: 24),

          _sectionTitle('مالک واحد', Icons.person_outline),
          const SizedBox(height: 10),
          _personCard(
            name: _ownerName(),
            subtitle: !ownerExists
                ? 'برای این واحد مالکی ثبت نشده است'
                : (_ownerIsActive()
                ? 'مالک فعلی واحد'
                : 'مالک غیرفعال'),
            icon: Icons.person_outline,
            color: primaryColor,
            exists: ownerExists,
            details: [
              _personInfoRow(
                Icons.phone_outlined,
                'شماره موبایل',
                _ownerMobile(),
              ),
              _personInfoRow(
                Icons.badge_outlined,
                'کد ملی',
                _ownerNationalCode(),
              ),
              _personInfoRow(
                Icons.people_outline,
                'تعداد نفرات',
                _ownerPeopleCount(),
              ),
              _personInfoRow(
                Icons.event_available_outlined,
                'تاریخ خرید',
                _ownerPurchaseDate(),
              ),
              if (_ownerDetails().trim().isNotEmpty)
                _personInfoRow(
                  Icons.notes_outlined,
                  'توضیحات',
                  _ownerDetails(),
                ),
            ],
            status: _statusChip('وضعیت مالک', _ownerIsActive()),
          ),
          _managementCard(
            icon: Icons.manage_accounts_outlined,
            title: ownerExists ? 'مدیریت مالک' : 'افزودن مالک',
            subtitle: 'ویرایش یا مدیریت اطلاعات مالک واحد',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManagerUnitOwnerScreen(
                    unitId: widget.unitId,
                  ),
                ),
              );

              if (mounted) await _loadUnit();
            },
          ),
          const SizedBox(height: 24),

          _sectionTitle('مستأجر واحد', Icons.people_outline),
          const SizedBox(height: 10),
          _personCard(
            name: _renterName(),
            subtitle: !renterExists
                ? 'برای این واحد مستأجری ثبت نشده است'
                : (_renterIsActive()
                ? 'مستأجر فعلی واحد'
                : 'آخرین مستأجر ثبت‌شده غیرفعال است'),
            icon: Icons.people_alt_outlined,
            color: unitColor,
            exists: renterExists,
            details: [
              _personInfoRow(
                Icons.phone_outlined,
                'شماره موبایل',
                _renterMobile(),
              ),
              _personInfoRow(
                Icons.badge_outlined,
                'کد ملی',
                _renterNationalCode(),
              ),
              _personInfoRow(
                Icons.people_outline,
                'تعداد نفرات',
                _renterPeopleCount(),
              ),
              _personInfoRow(
                Icons.date_range_outlined,
                'شروع سکونت',
                _renterStartDate(),
              ),
              _personInfoRow(
                Icons.event_outlined,
                'پایان سکونت',
                _renterEndDate(),
              ),
              _personInfoRow(
                Icons.description_outlined,
                'شماره قرارداد',
                _renterContractNumber(),
              ),
              _personInfoRow(
                Icons.business_outlined,
                'بنگاه',
                _renterEstateName(),
              ),
              if (_renterDetails().trim().isNotEmpty)
                _personInfoRow(
                  Icons.notes_outlined,
                  'توضیحات',
                  _renterDetails(),
                ),
            ],
            status: _statusChip('وضعیت مستأجر', _renterIsActive()),
          ),
          _managementCard(
            icon: Icons.people_alt_outlined,
            title: renterExists ? 'مدیریت مستأجر' : 'افزودن مستأجر',
            subtitle: 'افزودن مستأجر یا ویرایش مستأجر فعال',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ManagerUnitRenterScreen(
                    unitId: widget.unitId,
                  ),
                ),
              );

              if (mounted) await _loadUnit();
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _header({
    required String title,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: unitColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
          title: Text(
            _isEditing ? 'ویرایش واحد' : 'جزئیات واحد',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'بروزرسانی',
              onPressed: _isLoading ? null : _loadUnit,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: primaryColor,
          ),
        )
            : _errorMessage != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 54,
                ),
                const SizedBox(height: 15),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                FilledButton.icon(
                  onPressed: _loadUnit,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تلاش مجدد'),
                ),
              ],
            ),
          ),
        )
            : _buildBody(),
      ),
    );
  }
}
