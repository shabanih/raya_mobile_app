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

  final ManagerUnitService _unitService = ManagerUnitService();

  final GlobalKey<FormState> _editFormKey =
  GlobalKey<FormState>();

  Map<String, dynamic>? _unit;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditingUnit = false;

  String? _errorMessage;

  // =========================================================
  // Unit edit controllers
  // =========================================================

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

  final TextEditingController _peopleCountController =
  TextEditingController();

  final TextEditingController _unitDetailsController =
  TextEditingController();

  // =========================================================
  // Init
  // =========================================================

  @override
  void initState() {
    super.initState();
    _loadUnit();
  }

  // =========================================================
  // Dispose
  // =========================================================

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
    _peopleCountController.dispose();
    _unitDetailsController.dispose();

    super.dispose();
  }

  // =========================================================
  // Load
  // =========================================================

  Future<void> _loadUnit() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final unit = await _unitService.getUnit(widget.unitId);

      if (!mounted) return;

      _unit = unit;

      _fillUnitEditForm();

      setState(() {
        _isLoading = false;
        _isEditingUnit = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _cleanError(e);
        _isLoading = false;
      });
    }
  }

  // =========================================================
  // Fill edit form
  // =========================================================

  void _fillUnitEditForm() {
    if (_unit == null) return;

    _unitNumberController.text = _toPersianDigits(
      _rawValue([
        'unit_number',
        'unit',
        'number',
      ]),
    );

    _floorController.text = _toPersianDigits(
      _rawValue([
        'floor_number',
        'floor',
        'floor_name',
      ]),
    );

    _areaController.text = _toPersianDigits(
      _rawValue([
        'area',
        'unit_area',
        'square_meter',
      ]),
    );

    _bedroomsController.text = _toPersianDigits(
      _rawValue([
        'bedrooms_count',
        'bedrooms',
        'room_count',
      ]),
    );

    _parkingNumberController.text = _toPersianDigits(
      _rawValue([
        'parking_number',
      ]),
    );

    _parkingPlaceController.text = _rawValue([
      'parking_place',
    ]);

    _extraParkingFirstController.text = _rawValue([
      'extra_parking_first',
    ]);

    _extraParkingSecondController.text = _rawValue([
      'extra_parking_second',
    ]);

    _unitPhoneController.text = _toPersianDigits(
      _rawValue([
        'unit_phone',
        'phone',
      ]),
    );

    _peopleCountController.text = _toPersianDigits(
      _rawValue([
        'people_count',
      ]),
    );

    _unitDetailsController.text = _rawValue([
      'unit_details',
      'details',
      'description',
    ]);
  }

  // =========================================================
  // Raw value
  // =========================================================

  String _rawValue(List<String> keys) {
    if (_unit == null) {
      return '';
    }

    for (final key in keys) {
      final value = _unit![key];

      if (value == null) {
        continue;
      }

      if (value is Map) {
        continue;
      }

      final text = value.toString().trim();

      if (text.isNotEmpty && text != '-') {
        return text;
      }
    }

    return '';
  }

  // =========================================================
  // Start edit unit
  // =========================================================

  void _startEditUnit() {
    _fillUnitEditForm();

    setState(() {
      _isEditingUnit = true;
      _errorMessage = null;
    });
  }

  // =========================================================
  // Cancel edit
  // =========================================================

  void _cancelEditUnit() {
    _fillUnitEditForm();

    setState(() {
      _isEditingUnit = false;
    });
  }

  // =========================================================
  // Normalize digits
  // =========================================================

  String _normalizeDigits(String value) {
    return value
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9');
  }

  // =========================================================
  // Persian digits
  // =========================================================

  String _toPersianDigits(dynamic value) {
    if (value == null) {
      return '';
    }

    return value
        .toString()
        .replaceAll('0', '۰')
        .replaceAll('1', '۱')
        .replaceAll('2', '۲')
        .replaceAll('3', '۳')
        .replaceAll('4', '۴')
        .replaceAll('5', '۵')
        .replaceAll('6', '۶')
        .replaceAll('7', '۷')
        .replaceAll('8', '۸')
        .replaceAll('9', '۹');
  }

  // =========================================================
  // Save unit
  // =========================================================

  Future<void> _saveUnit() async {
    if (!_editFormKey.currentState!.validate()) {
      return;
    }

    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final data = <String, dynamic>{
        'unit_number': _normalizeDigits(
          _unitNumberController.text.trim(),
        ),
        'floor_number': _normalizeDigits(
          _floorController.text.trim(),
        ),
        'area': _normalizeDigits(
          _areaController.text.trim(),
        ),
        'bedrooms_count': _normalizeDigits(
          _bedroomsController.text.trim(),
        ),
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
        'people_count': _normalizeDigits(
          _peopleCountController.text.trim(),
        ),
        'unit_details':
        _unitDetailsController.text.trim(),
      };

      await _unitService.updateUnit(
        widget.unitId,
        data,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'اطلاعات واحد با موفقیت ویرایش شد.',
          ),
          backgroundColor: primaryColor,
        ),
      );

      await _loadUnit();
    } catch (e) {
      if (!mounted) return;

      _showError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // =========================================================
  // Error
  // =========================================================

  String _cleanError(dynamic error) {
    String message = error.toString();

    if (message.startsWith('Exception: ')) {
      message = message.substring('Exception: '.length);
    }

    if (message.trim().isEmpty) {
      return 'خطایی رخ داده است.';
    }

    return message;
  }

  void _showError(dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _cleanError(error),
          textAlign: TextAlign.right,
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  // =========================================================
  // Boolean parser
  // =========================================================

  bool _parseBool(
      dynamic value, {
        bool fallback = false,
      }) {
    if (value == null) {
      return fallback;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text =
    value.toString().toLowerCase().trim();

    if (text == 'true' ||
        text == '1' ||
        text == 'active' ||
        text == 'فعال' ||
        text == 'yes') {
      return true;
    }

    if (text == 'false' ||
        text == '0' ||
        text == 'inactive' ||
        text == 'غیرفعال' ||
        text == 'no') {
      return false;
    }

    return fallback;
  }

  // =========================================================
  // Helpers
  // =========================================================

  String _value(
      List<String> keys, {
        String defaultValue = '-',
      }) {
    if (_unit == null) {
      return defaultValue;
    }

    for (final key in keys) {
      final value = _unit![key];

      if (value == null) {
        continue;
      }

      if (value is Map) {
        continue;
      }

      if (value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return defaultValue;
  }

  // =========================================================
  // Unit information
  // =========================================================

  String _unitNumber() {
    if (_unit == null) {
      return '-';
    }

    final candidates = [
      _unit!['unit_number'],
      _unit!['unit'],
      _unit!['number'],
    ];

    for (final value in candidates) {
      if (value == null) {
        continue;
      }

      if (value is Map) {
        final map =
        Map<String, dynamic>.from(value);

        final nested =
            map['unit_number'] ??
                map['unit'] ??
                map['number'] ??
                map['value'];

        if (nested != null &&
            nested.toString().trim().isNotEmpty) {
          return _toPersianDigits(nested);
        }

        continue;
      }

      if (value.toString().trim().isNotEmpty) {
        return _toPersianDigits(value);
      }
    }

    return '-';
  }

  String _floor() {
    return _toPersianDigits(
      _value([
        'floor_number',
        'floor',
        'floor_name',
      ]),
    );
  }

  String _area() {
    final value = _value([
      'area',
      'unit_area',
      'square_meter',
    ]);

    if (value == '-') {
      return value;
    }

    return '${_toPersianDigits(value)} مترمربع';
  }

  String _bedrooms() {
    final value = _value([
      'bedrooms_count',
      'bedrooms',
      'room_count',
    ]);

    return _toPersianDigits(value);
  }

  String _parkingNumber() {
    return _toPersianDigits(
      _value([
        'parking_number',
      ]),
    );
  }

  String _parkingPlace() {
    return _value([
      'parking_place',
    ]);
  }

  String _extraParkingFirst() {
    return _value([
      'extra_parking_first',
    ]);
  }

  String _extraParkingSecond() {
    return _value([
      'extra_parking_second',
    ]);
  }

  String _unitPhone() {
    return _toPersianDigits(
      _value([
        'unit_phone',
        'phone',
      ]),
    );
  }

  String _peopleCount() {
    return _toPersianDigits(
      _value([
        'people_count',
      ]),
    );
  }

  String _unitDetails() {
    return _value([
      'unit_details',
      'details',
      'description',
    ]);
  }

  // =========================================================
  // Unit active status
  // =========================================================

  bool _unitIsActive() {
    if (_unit == null) {
      return true;
    }

    return _parseBool(
      _unit!['is_active'] ??
          _unit!['unit_is_active'] ??
          _unit!['active'],
      fallback: true,
    );
  }

  // =========================================================
  // Owner
  // =========================================================

  Map<String, dynamic>? _owner() {
    if (_unit == null) {
      return null;
    }

    // -------------------------------------------------------
    // مالک کامل
    // -------------------------------------------------------

    final owner =
        _unit!['owner'] ??
            _unit!['current_owner'] ??
            _unit!['active_owner'] ??
            _unit!['inactive_owner'];

    if (owner is Map) {
      return Map<String, dynamic>.from(owner);
    }

    // -------------------------------------------------------
    // مالک مستقیم روی Unit
    // -------------------------------------------------------

    final ownerName =
    _unit!['owner_name'];

    final ownerMobile =
    _unit!['owner_mobile'];

    if ((ownerName != null &&
        ownerName.toString().trim().isNotEmpty) ||
        (ownerMobile != null &&
            ownerMobile.toString().trim().isNotEmpty)) {
      return {
        'id':
        _unit!['owner_id'],

        'name':
        ownerName,

        'owner_name':
        ownerName,

        'mobile':
        ownerMobile,

        'owner_mobile':
        ownerMobile,

        'national_code':
        _unit!['owner_national_code'],

        'people_count':
        _unit!['owner_people_count'],

        'details':
        _unit!['owner_details'],

        'purchase_date':
        _unit!['purchase_date'],

        'is_active':
        _unit!['owner_is_active'] ??
            _unit!['owner_active'] ??
            _unit!['is_owner_active'] ??
            _unit!['is_active'] ??
            true,
      };
    }

    return null;
  }

  bool _hasOwner() {
    final owner = _owner();

    if (owner == null) {
      return false;
    }

    final name =
        owner['name'] ??
            owner['full_name'] ??
            owner['owner_name'];

    return name != null &&
        name.toString().trim().isNotEmpty;
  }

  String _ownerName() {
    final owner = _owner();

    if (owner == null) {
      return 'مالک ثبت نشده';
    }

    final name =
        owner['name'] ??
            owner['full_name'] ??
            owner['owner_name'];

    if (name == null ||
        name.toString().trim().isEmpty) {
      return 'مالک ثبت نشده';
    }

    return name.toString();
  }

  String _ownerMobile() {
    final owner = _owner();

    if (owner == null) {
      return '-';
    }

    return _toPersianDigits(
      owner['mobile'] ??
          owner['phone'] ??
          owner['owner_mobile'] ??
          '-',
    );
  }

  String _ownerNationalCode() {
    final owner = _owner();

    if (owner == null) {
      return '-';
    }

    return _toPersianDigits(
      owner['national_code'] ??
          owner['owner_national_code'] ??
          '-',
    );
  }

  String _ownerPeopleCount() {
    final owner = _owner();

    if (owner == null) {
      return '-';
    }

    return _toPersianDigits(
      owner['people_count'] ??
          owner['owner_people_count'] ??
          0,
    );
  }

  String _ownerDetails() {
    final owner = _owner();

    if (owner == null) {
      return '';
    }

    return (
        owner['details'] ??
            owner['owner_details'] ??
            ''
    ).toString();
  }

  // =========================================================
  // Owner purchase date
  // =========================================================

  String _ownerPurchaseDate() {
    final owner = _owner();

    if (owner == null) {
      return '-';
    }

    final value =
        owner['purchase_date'] ??
            owner['owner_purchase_date'];

    if (value == null ||
        value.toString().trim().isEmpty) {
      return '-';
    }

    return _formatShamsiDate(value);
  }

  // =========================================================
  // Owner active status
  // =========================================================

  bool _ownerIsActive() {
    final owner = _owner();

    if (owner == null) {
      return false;
    }

    final value =
        owner['is_active'] ??
            owner['owner_is_active'] ??
            owner['owner_active'];

    return _parseBool(
      value,
      fallback: _unitIsActive(),
    );
  }

  // =========================================================
  // Renter
  // =========================================================

  Map<String, dynamic>? _renter() {
    if (_unit == null) {
      return null;
    }

    // -------------------------------------------------------
    // 1. مستاجر فعال
    // -------------------------------------------------------

    final activeRenter =
    _unit!['active_renter'];

    if (activeRenter is Map) {
      return Map<String, dynamic>.from(
        activeRenter,
      );
    }

    // -------------------------------------------------------
    // 2. مستاجر معمولی
    // -------------------------------------------------------

    final renter =
    _unit!['renter'];

    if (renter is Map) {
      return Map<String, dynamic>.from(
        renter,
      );
    }

    // -------------------------------------------------------
    // 3. مستاجر غیرفعال
    // -------------------------------------------------------

    final inactiveRenter =
        _unit!['inactive_renter'] ??
            _unit!['last_renter'] ??
            _unit!['previous_renter'] ??
            _unit!['current_renter'];

    if (inactiveRenter is Map) {
      return Map<String, dynamic>.from(
        inactiveRenter,
      );
    }

    // -------------------------------------------------------
    // 4. لیست مستاجرها
    // -------------------------------------------------------

    final renters =
    _unit!['renters'];

    if (renters is List &&
        renters.isNotEmpty) {
      Map<String, dynamic>? latestRenter;

      for (final item in renters) {
        if (item is! Map) {
          continue;
        }

        final map =
        Map<String, dynamic>.from(item);

        final name =
            map['name'] ??
                map['renter_name'] ??
                map['full_name'];

        if (name == null ||
            name.toString().trim().isEmpty) {
          continue;
        }

        // آخرین رکورد معتبر
        latestRenter = map;

        final active =
        _parseBool(
          map['renter_is_active'] ??
              map['is_active'] ??
              map['active'],
          fallback: false,
        );

        // اگر فعال است همان را برگردان
        if (active) {
          return map;
        }
      }

      if (latestRenter != null) {
        return latestRenter;
      }
    }

    // -------------------------------------------------------
    // 5. مستاجر مستقیم روی Unit
    // -------------------------------------------------------

    final renterName =
    _unit!['renter_name'];

    final renterMobile =
    _unit!['renter_mobile'];

    if ((renterName != null &&
        renterName.toString().trim().isNotEmpty) ||
        (renterMobile != null &&
            renterMobile.toString().trim().isNotEmpty)) {
      return {
        'id':
        _unit!['renter_id'],

        'name':
        renterName,

        'renter_name':
        renterName,

        'mobile':
        renterMobile,

        'renter_mobile':
        renterMobile,

        'national_code':
        _unit!['renter_national_code'],

        'people_count':
        _unit!['renter_people_count'],

        'start_date':
        _unit!['renter_start_date'] ??
            _unit!['start_date'],

        'end_date':
        _unit!['renter_end_date'] ??
            _unit!['end_date'],

        'contract_number':
        _unit!['contract_number'],

        'estate_name':
        _unit!['estate_name'] ??
            _unit!['agency_name'],

        'details':
        _unit!['renter_details'] ??
            _unit!['details'],

        'renter_is_active':
        _unit!['renter_is_active'] ??
            _unit!['renter_active'] ??
            false,
      };
    }

    // -------------------------------------------------------
    // 6. سوابق سکونت
    // -------------------------------------------------------

    final histories =
        _unit!['residence_history'] ??
            _unit!['residence_histories'] ??
            _unit!['histories'];

    if (histories is List &&
        histories.isNotEmpty) {
      Map<String, dynamic>? latestRenter;

      for (final item in histories) {
        if (item is! Map) {
          continue;
        }

        final map =
        Map<String, dynamic>.from(item);

        final residentType =
        (
            map['resident_type'] ??
                map['type'] ??
                map['person_type'] ??
                ''
        )
            .toString()
            .toLowerCase();

        final renterName =
            map['renter_name'] ??
                map['name'] ??
                map['full_name'];

        final looksLikeRenter =
            residentType.contains('renter') ||
                residentType.contains('مستاجر') ||
                residentType.contains('مستأجر') ||
                map['renter_id'] != null ||
                map['renter_name'] != null;

        if (looksLikeRenter &&
            renterName != null &&
            renterName.toString().trim().isNotEmpty) {
          latestRenter = map;
        }
      }

      if (latestRenter != null) {
        return latestRenter;
      }
    }

    return null;
  }

  bool _hasRenter() {
    final renter = _renter();

    if (renter == null) {
      return false;
    }

    final name =
        renter['name'] ??
            renter['renter_name'] ??
            renter['full_name'];

    return name != null &&
        name.toString().trim().isNotEmpty;
  }

  bool _renterIsActive() {
    final renter = _renter();

    if (renter == null) {
      return false;
    }

    final value =
        renter['renter_is_active'] ??
            renter['is_active'] ??
            renter['active'];

    if (value != null) {
      return _parseBool(
        value,
        fallback: false,
      );
    }

    // اگر رکورد از active_renter آمده باشد
    if (_unit?['active_renter'] != null) {
      return true;
    }

    return false;
  }

  String _renterName() {
    final renter = _renter();

    if (renter == null) {
      return 'مستاجر ثبت نشده';
    }

    final name =
        renter['name'] ??
            renter['renter_name'] ??
            renter['full_name'];

    if (name == null ||
        name.toString().trim().isEmpty) {
      return 'مستاجر ثبت نشده';
    }

    return name.toString();
  }

  String _renterMobile() {
    final renter = _renter();

    if (renter == null) {
      return '-';
    }

    return _toPersianDigits(
      renter['mobile'] ??
          renter['renter_mobile'] ??
          renter['phone'] ??
          '-',
    );
  }

  String _renterNationalCode() {
    final renter = _renter();

    if (renter == null) {
      return '-';
    }

    return _toPersianDigits(
      renter['national_code'] ??
          renter['renter_national_code'] ??
          '-',
    );
  }

  String _renterPeopleCount() {
    final renter = _renter();

    if (renter == null) {
      return '-';
    }

    return _toPersianDigits(
      renter['people_count'] ??
          renter['renter_people_count'] ??
          0,
    );
  }

  String _renterStartDate() {
    final renter = _renter();

    if (renter == null) {
      return '-';
    }

    final value =
        renter['start_date'] ??
            renter['renter_start_date'];

    return _formatShamsiDate(value);
  }

  String _renterEndDate() {
    final renter = _renter();

    if (renter == null) {
      return '-';
    }

    final value =
        renter['end_date'] ??
            renter['renter_end_date'];

    if (value == null ||
        value.toString().trim().isEmpty) {
      return 'تا کنون';
    }

    return _formatShamsiDate(value);
  }

  String _renterContractNumber() {
    final renter = _renter();

    if (renter == null) {
      return '-';
    }

    return _toPersianDigits(
      renter['contract_number'] ?? '-',
    );
  }

  String _renterEstateName() {
    final renter = _renter();

    if (renter == null) {
      return '-';
    }

    return (
        renter['estate_name'] ??
            renter['agency_name'] ??
            '-'
    ).toString();
  }

  String _renterDetails() {
    final renter = _renter();

    if (renter == null) {
      return '';
    }

    return (
        renter['details'] ??
            renter['renter_details'] ??
            ''
    ).toString();
  }

  // =========================================================
  // Owner status row
  // =========================================================

  Widget _ownerStatusRow(bool active) {
    final color =
    active ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.center,
        children: [
          Icon(
            active
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            size: 19,
            color: color,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 90,
            child: Text(
              'وضعیت مالک',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                  color.withOpacity(0.10),
                  borderRadius:
                  BorderRadius.circular(20),
                  border: Border.all(
                    color:
                    color.withOpacity(0.30),
                  ),
                ),
                child: Text(
                  active ? 'فعال' : 'غیرفعال',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Renter status row
  // =========================================================

  Widget _renterStatusRow() {
    final active = _renterIsActive();

    final color =
    active ? Colors.green : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.center,
        children: [
          Icon(
            active
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            size: 19,
            color: color,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 90,
            child: Text(
              'وضعیت مستاجر',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                  color.withOpacity(0.10),
                  borderRadius:
                  BorderRadius.circular(20),
                  border: Border.all(
                    color:
                    color.withOpacity(0.30),
                  ),
                ),
                child: Text(
                  active ? 'فعال' : 'غیرفعال',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // =========================================================
  // Gregorian -> Jalali
  // =========================================================

  String _formatShamsiDate(dynamic value) {
    if (value == null) {
      return '-';
    }

    String date =
    value.toString().trim();

    if (date.isEmpty) {
      return '-';
    }

    date = _normalizeDigits(date);

    if (date.contains('/')) {
      final parts = date.split('/');

      if (parts.length >= 3) {
        return _toPersianDigits(
          '${parts[0]}/${parts[1].padLeft(2, '0')}/${parts[2].padLeft(2, '0')}',
        );
      }
    }

    if (date.contains('T')) {
      date = date.split('T').first;
    }

    if (date.contains(' ')) {
      date = date.split(' ').first;
    }

    final parts = date.split('-');

    if (parts.length < 3) {
      return _toPersianDigits(date);
    }

    final year =
    int.tryParse(parts[0]);

    final month =
    int.tryParse(parts[1]);

    final day =
    int.tryParse(parts[2]);

    if (year == null ||
        month == null ||
        day == null) {
      return _toPersianDigits(date);
    }

    if (year < 1500) {
      return _toPersianDigits(
        '$year/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}',
      );
    }

    final jalali =
    _gregorianToJalali(
      year,
      month,
      day,
    );

    return _toPersianDigits(
      '${jalali[0]}/${jalali[1].toString().padLeft(2, '0')}/${jalali[2].toString().padLeft(2, '0')}',
    );
  }

  List<int> _gregorianToJalali(
      int gy,
      int gm,
      int gd,
      ) {
    final gDaysInMonth = <int>[
      31,
      28,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31,
    ];

    final jDaysInMonth = <int>[
      31,
      31,
      31,
      31,
      31,
      31,
      30,
      30,
      30,
      30,
      30,
      29,
    ];

    int gy2 = gy - 1600;
    int gm2 = gm - 1;
    int gd2 = gd - 1;

    int gDayNo =
        365 * gy2 +
            ((gy2 + 3) ~/ 4) -
            ((gy2 + 99) ~/ 100) +
            ((gy2 + 399) ~/ 400);

    for (int i = 0; i < gm2; i++) {
      gDayNo += gDaysInMonth[i];
    }

    if (gm2 > 1 &&
        ((gy % 4 == 0 &&
            gy % 100 != 0) ||
            gy % 400 == 0)) {
      gDayNo++;
    }

    gDayNo += gd2;

    int jDayNo =
        gDayNo - 79;

    int jNp =
        jDayNo ~/ 12053;

    int jy =
        979 + (33 * jNp);

    jDayNo %= 12053;

    jy +=
        4 * (jDayNo ~/ 1461);

    jDayNo %= 1461;

    if (jDayNo >= 366) {
      jy +=
          (jDayNo - 1) ~/ 365;

      jDayNo =
          (jDayNo - 1) % 365;
    }

    int jm = 0;

    for (int i = 0;
    i < 11 &&
        jDayNo >=
            jDaysInMonth[i];
    i++) {
      jDayNo -=
      jDaysInMonth[i];

      jm++;
    }

    return [
      jy,
      jm + 1,
      jDayNo + 1,
    ];
  }

  // =========================================================
  // Residence status
  // =========================================================

  String _residenceStatus() {
    final unitActive =
    _unitIsActive();

    if (!unitActive) {
      return 'غیرفعال';
    }

    if (_hasRenter() &&
        _renterIsActive()) {
      return 'ساکن - مستاجر';
    }

    if (_hasOwner() &&
        _ownerIsActive()) {
      return 'ساکن - مالک';
    }

    if (_hasRenter() ||
        _hasOwner()) {
      return 'غیرفعال';
    }

    return 'خالی';
  }

  // =========================================================
  // Text field
  // =========================================================

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: primaryColor,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(12),
          ),
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(12),
            borderSide: BorderSide(
              color:
              Colors.grey.shade300,
            ),
          ),
          focusedBorder:
          const OutlineInputBorder(
            borderRadius:
            BorderRadius.all(
              Radius.circular(12),
            ),
            borderSide: BorderSide(
              color: primaryColor,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // Unit edit form
  // =========================================================

  Widget _buildUnitEditForm() {
    return Form(
      key: _editFormKey,
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          Container(
            padding:
            const EdgeInsets.all(14),
            margin:
            const EdgeInsets.only(
              bottom: 15,
            ),
            decoration: BoxDecoration(
              color:
              unitColor.withOpacity(0.07),
              borderRadius:
              BorderRadius.circular(12),
              border: Border.all(
                color:
                unitColor.withOpacity(0.20),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.edit_outlined,
                  color: unitColor,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'در این قسمت فقط مشخصات خود واحد ویرایش می‌شود. اطلاعات مالک، مستاجر و سوابق سکونت تغییری نخواهد کرد.',
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _editField(
            controller:
            _unitNumberController,
            label: 'شماره واحد',
            icon: Icons.numbers,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'شماره واحد را وارد کنید';
              }

              return null;
            },
          ),

          _editField(
            controller:
            _floorController,
            label: 'طبقه',
            icon: Icons.layers_outlined,
            keyboardType:
            TextInputType.number,
          ),

          _editField(
            controller:
            _areaController,
            label: 'متراژ',
            icon: Icons.square_foot,
            keyboardType:
            const TextInputType.numberWithOptions(
              decimal: true,
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'متراژ را وارد کنید';
              }

              final area =
              double.tryParse(
                _normalizeDigits(
                  value.trim(),
                ),
              );

              if (area == null ||
                  area <= 0) {
                return 'متراژ معتبر نیست';
              }

              return null;
            },
          ),

          _editField(
            controller:
            _bedroomsController,
            label: 'تعداد خواب',
            icon: Icons.bed_outlined,
            keyboardType:
            TextInputType.number,
          ),

          _editField(
            controller:
            _parkingNumberController,
            label: 'شماره پارکینگ',
            icon:
            Icons.local_parking_outlined,
          ),

          _editField(
            controller:
            _parkingPlaceController,
            label: 'محل پارکینگ',
            icon:
            Icons.directions_car_outlined,
          ),

          _editField(
            controller:
            _extraParkingFirstController,
            label: 'پارکینگ اضافه اول',
            icon:
            Icons.add_circle_outline,
          ),

          _editField(
            controller:
            _extraParkingSecondController,
            label: 'پارکینگ اضافه دوم',
            icon:
            Icons.add_circle_outline,
          ),

          _editField(
            controller:
            _unitPhoneController,
            label: 'تلفن واحد',
            icon: Icons.phone_outlined,
            keyboardType:
            TextInputType.phone,
          ),

          _editField(
            controller:
            _peopleCountController,
            label: 'تعداد ساکنین',
            icon:
            Icons.people_outline,
            keyboardType:
            TextInputType.number,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'تعداد ساکنین را وارد کنید';
              }

              final count =
              int.tryParse(
                _normalizeDigits(
                  value.trim(),
                ),
              );

              if (count == null ||
                  count < 0) {
                return 'تعداد ساکنین معتبر نیست';
              }

              return null;
            },
          ),

          _editField(
            controller:
            _unitDetailsController,
            label: 'توضیحات واحد',
            icon:
            Icons.notes_outlined,
            maxLines: 4,
          ),

          const SizedBox(height: 5),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style:
              FilledButton.styleFrom(
                backgroundColor:
                primaryColor,
                foregroundColor:
                Colors.white,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),
              onPressed:
              _isSaving
                  ? null
                  : _saveUnit,
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
              label: const Text(
                'ذخیره تغییرات واحد',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          OutlinedButton(
            onPressed:
            _isSaving
                ? null
                : _cancelEditUnit,
            child:
            const Text('انصراف'),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Info Card
  // =========================================================

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(13),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
              primaryColor.withOpacity(0.10),
              borderRadius:
              BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign:
                  TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  textAlign:
                  TextAlign.right,
                  style:
                  const TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Section title
  // =========================================================

  Widget _sectionTitle(
      String title, {
        IconData? icon,
      }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 21,
            color: primaryColor,
          ),
          const SizedBox(width: 7),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // Management card
  // =========================================================

  Widget _managementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      color: Colors.white,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding:
          const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                BoxDecoration(
                  color:
                  primaryColor
                      .withOpacity(
                    0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textAlign:
                      TextAlign.right,
                      style:
                      const TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign:
                      TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                        Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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

  // =========================================================
  // Unit status card
  // =========================================================

  Widget _unitStatusCard() {
    final active =
    _unitIsActive();

    final color =
    active ? Colors.green : Colors.red;

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color:
        color.withOpacity(0.08),
        borderRadius:
        BorderRadius.circular(12),
        border: Border.all(
          color:
          color.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            active
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            color: color,
            size: 21,
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'وضعیت واحد',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 5,
            ),
            decoration:
            BoxDecoration(
              color:
              color.withOpacity(0.10),
              borderRadius:
              BorderRadius.circular(
                20,
              ),
            ),
            child: Text(
              active
                  ? 'فعال'
                  : 'غیرفعال',
              style: TextStyle(
                color: color,
                fontWeight:
                FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Owner card
  // =========================================================

  Widget _ownerCard() {
    final hasOwner =
    _hasOwner();

    final ownerActive =
    _ownerIsActive();

    return Container(
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color: ownerActive
              ? Colors.grey.shade200
              : Colors.red.withOpacity(
            0.35,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                BoxDecoration(
                  color:
                  ownerActive
                      ? primaryColor
                      .withOpacity(
                    0.10,
                  )
                      : Colors.red
                      .withOpacity(
                    0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  ownerActive
                      ? Icons.person_outline
                      : Icons.person_off_outlined,
                  color: ownerActive
                      ? primaryColor
                      : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ownerName(),
                      textAlign:
                      TextAlign.right,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.bold,
                        color: hasOwner
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasOwner
                          ? (ownerActive
                          ? 'مالک فعلی واحد'
                          : 'مالک غیرفعال')
                          : 'برای این واحد مالکی ثبت نشده است',
                      textAlign:
                      TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasOwner
                            ? (ownerActive
                            ? primaryColor
                            : Colors.red)
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (hasOwner) ...[
            const Divider(height: 24),

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

            _ownerStatusRow(
              ownerActive,
            ),

            if (_ownerDetails()
                .trim()
                .isNotEmpty)
              _personInfoRow(
                Icons.notes_outlined,
                'توضیحات',
                _ownerDetails(),
              ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // Renter card
  // =========================================================

  Widget _renterCard() {
    final hasRenter =
    _hasRenter();

    final renterActive =
    _renterIsActive();

    return Container(
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color: renterActive
              ? Colors.grey.shade200
              : Colors.red.withOpacity(
            0.35,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration:
                BoxDecoration(
                  color:
                  renterActive
                      ? unitColor
                      .withOpacity(
                    0.10,
                  )
                      : Colors.red
                      .withOpacity(
                    0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  renterActive
                      ? Icons.people_outline
                      : Icons.person_off_outlined,
                  color: renterActive
                      ? primaryColor
                      : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      _renterName(),
                      textAlign:
                      TextAlign.right,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.bold,
                        color: hasRenter
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasRenter
                          ? (renterActive
                          ? 'مستاجر فعلی واحد'
                          : 'مستاجر غیرفعال')
                          : 'برای این واحد مستاجری ثبت نشده است',
                      textAlign:
                      TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasRenter
                            ? (renterActive
                            ? unitColor
                            : Colors.red)
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (hasRenter) ...[
            const Divider(height: 24),

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

            _renterStatusRow(),

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

            if (_renterDetails()
                .trim()
                .isNotEmpty)
              _personInfoRow(
                Icons.notes_outlined,
                'توضیحات',
                _renterDetails(),
              ),
          ],
        ],
      ),
    );
  }

  // =========================================================
  // Person info row
  // =========================================================

  Widget _personInfoRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: unitColor,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color:
                Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign:
              TextAlign.right,
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

  // =========================================================
  // Body
  // =========================================================

  Widget _buildBody() {
    if (_unit == null) {
      return const Center(
        child: Text(
          'اطلاعات واحد پیدا نشد.',
        ),
      );
    }

    // =======================================================
    // EDIT MODE
    // =======================================================

    if (_isEditingUnit) {
      return SingleChildScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding:
        const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              padding:
              const EdgeInsets.all(18),
              decoration:
              BoxDecoration(
                color: unitColor,
                borderRadius:
                BorderRadius.circular(
                  16,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration:
                    BoxDecoration(
                      color: Colors.white
                          .withOpacity(
                        0.18,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 31,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ویرایش اطلاعات واحد',
                          style: TextStyle(
                            color:
                            Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'واحد ${_unitNumber()}',
                          style:
                          const TextStyle(
                            color:
                            Colors.white,
                            fontSize: 22,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildUnitEditForm(),

            const SizedBox(height: 30),
          ],
        ),
      );
    }

    // =======================================================
    // NORMAL MODE
    // =======================================================

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _loadUnit,
      child: ListView(
        padding:
        const EdgeInsets.all(14),
        children: [
          // =================================================
          // Unit Header
          // =================================================

          Container(
            padding:
            const EdgeInsets.all(18),
            decoration:
            BoxDecoration(
              color: unitColor,
              borderRadius:
              BorderRadius.circular(
                16,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration:
                  BoxDecoration(
                    color: Colors.white
                        .withOpacity(
                      0.18,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: Colors.white,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'واحد ${_unitNumber()}',
                        textAlign:
                        TextAlign.right,
                        style:
                        const TextStyle(
                          color:
                          Colors.white,
                          fontSize: 22,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _unitIsActive()
                                ? Icons
                                .check_circle_outline
                                : Icons
                                .cancel_outlined,
                            color: _unitIsActive()
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(
                            width: 6,
                          ),
                          Text(
                            _unitIsActive()
                                ? 'واحد فعال'
                                : 'واحد غیرفعال',
                            style:
                            TextStyle(
                              color: _unitIsActive()
                                  ? Colors
                                  .greenAccent
                                  : Colors
                                  .redAccent,
                              fontSize: 12,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _unitStatusCard(),

          const SizedBox(height: 20),

          // =================================================
          // Unit information
          // =================================================

          _sectionTitle(
            'اطلاعات واحد',
            icon:
            Icons.home_work_outlined,
          ),

          const SizedBox(height: 10),

          _infoCard(
            icon: Icons.numbers,
            title: 'شماره واحد',
            value: _unitNumber(),
          ),

          const SizedBox(height: 8),

          _infoCard(
            icon: Icons.layers_outlined,
            title: 'طبقه',
            value: _floor(),
          ),

          const SizedBox(height: 8),

          _infoCard(
            icon: Icons.square_foot,
            title: 'متراژ',
            value: _area(),
          ),

          const SizedBox(height: 8),

          _infoCard(
            icon: Icons.bed_outlined,
            title: 'تعداد خواب',
            value: _bedrooms(),
          ),

          const SizedBox(height: 8),

          _infoCard(
            icon:
            Icons.local_parking_outlined,
            title: 'شماره پارکینگ',
            value: _parkingNumber(),
          ),

          const SizedBox(height: 8),

          _infoCard(
            icon:
            Icons.directions_car_outlined,
            title: 'محل پارکینگ',
            value: _parkingPlace(),
          ),

          const SizedBox(height: 8),

          _infoCard(
            icon:
            Icons.add_circle_outline,
            title: 'پارکینگ اضافه اول',
            value:
            _extraParkingFirst(),
          ),

          const SizedBox(height: 8),

          _infoCard(
            icon:
            Icons.add_circle_outline,
            title: 'پارکینگ اضافه دوم',
            value:
            _extraParkingSecond(),
          ),

          const SizedBox(height: 8),

          _infoCard(
            icon: Icons.phone_outlined,
            title: 'تلفن واحد',
            value: _unitPhone(),
          ),

          const SizedBox(height: 8),

          _infoCard(
            icon:
            Icons.people_outline,
            title: 'تعداد ساکنین',
            value: _peopleCount(),
          ),

          const SizedBox(height: 8),

          _infoCard(
            icon:
            Icons.home_outlined,
            title: 'وضعیت سکونت',
            value:
            _residenceStatus(),
          ),

          if (_unitDetails()
              .trim()
              .isNotEmpty &&
              _unitDetails() != '-') ...[
            const SizedBox(height: 8),
            _infoCard(
              icon:
              Icons.notes_outlined,
              title: 'توضیحات واحد',
              value:
              _unitDetails(),
            ),
          ],

          // =================================================
          // EDIT UNIT BUTTON
          // =================================================

          const SizedBox(height: 18),

          SizedBox(
            height: 52,
            child:
            FilledButton.icon(
              style:
              FilledButton.styleFrom(
                backgroundColor:
                unitColor,
                foregroundColor:
                Colors.white,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              onPressed:
              _startEditUnit,
              icon: const Icon(
                Icons.edit_outlined,
              ),
              label: const Text(
                'ویرایش اطلاعات واحد',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

          // =================================================
          // Owner
          // =================================================

          _sectionTitle(
            'مالک واحد',
            icon:
            Icons.person_outline,
          ),

          const SizedBox(height: 10),

          _ownerCard(),

          const SizedBox(height: 10),

          _managementCard(
            icon:
            Icons.manage_accounts_outlined,
            title: _hasOwner()
                ? (_ownerIsActive()
                ? 'ویرایش / مدیریت مالک'
                : 'مدیریت مالک غیرفعال')
                : 'افزودن مالک',
            subtitle: _hasOwner()
                ? (_ownerIsActive()
                ? 'ویرایش، افزودن مالک جدید یا غیرفعال کردن مالک فعلی'
                : 'مشاهده اطلاعات مالک قبلی یا فعال‌سازی مجدد مالک')
                : 'برای این واحد مالک ثبت کنید',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ManagerUnitOwnerScreen(
                        unitId:
                        widget.unitId,
                      ),
                ),
              );

              if (mounted) {
                await _loadUnit();
              }
            },
          ),

          const SizedBox(height: 22),

          // =================================================
          // Renter
          // =================================================

          _sectionTitle(
            'مستاجر واحد',
            icon:
            Icons.people_outline,
          ),

          const SizedBox(height: 10),

          _renterCard(),

          const SizedBox(height: 10),

          _managementCard(
            icon:
            Icons.people_alt_outlined,
            title: _hasRenter()
                ? (_renterIsActive()
                ? 'ویرایش / مدیریت مستاجر'
                : 'مدیریت مستاجر غیرفعال')
                : 'افزودن مستاجر',
            subtitle: _hasRenter()
                ? (_renterIsActive()
                ? 'ویرایش، افزودن مستاجر جدید یا غیرفعال کردن مستاجر فعلی'
                : 'مشاهده اطلاعات مستاجر قبلی یا افزودن مستاجر جدید')
                : 'برای این واحد مستاجر ثبت کنید',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ManagerUnitRenterScreen(
                        unitId:
                        widget.unitId,
                      ),
                ),
              );

              if (mounted) {
                await _loadUnit();
              }
            },
          ),

          const SizedBox(height: 30),
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
      textDirection:
      TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        const Color(0xffF7F9FA),

        appBar: AppBar(
          backgroundColor:
          primaryColor,
          foregroundColor:
          Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            _isEditingUnit
                ? 'ویرایش واحد'
                : 'جزئیات واحد',
            style:
            const TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),
          actions: [
            if (!_isEditingUnit)
              IconButton(
                onPressed:
                _isLoading
                    ? null
                    : _loadUnit,
                icon:
                const Icon(
                  Icons.refresh,
                ),
                tooltip:
                'بروزرسانی',
              ),
          ],
        ),

        body: _isLoading
            ? const Center(
          child:
          CircularProgressIndicator(
            color:
            primaryColor,
          ),
        )
            : _errorMessage != null
            ? Center(
          child: Padding(
            padding:
            const EdgeInsets.all(
              24,
            ),
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment
                  .center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(
                    height: 15),
                Text(
                  _errorMessage!,
                  textAlign:
                  TextAlign.center,
                ),
                const SizedBox(
                    height: 15),
                FilledButton.icon(
                  style:
                  FilledButton.styleFrom(
                    backgroundColor:
                    primaryColor,
                    foregroundColor:
                    Colors.white,
                  ),
                  onPressed:
                  _loadUnit,
                  icon:
                  const Icon(
                    Icons.refresh,
                  ),
                  label:
                  const Text(
                    'تلاش مجدد',
                  ),
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