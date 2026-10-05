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

  final ManagerUnitService _unitService =
  ManagerUnitService();

  Map<String, dynamic>? _unit;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUnit();
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
      final unit =
      await _unitService.getUnit(widget.unitId);

      if (!mounted) return;

      setState(() {
        _unit = unit;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      String message = e.toString();

      if (message.startsWith('Exception: ')) {
        message =
            message.substring('Exception: '.length);
      }

      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  // =========================================================
  // Helpers
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

  String _value(
      List<String> keys, {
        String defaultValue = '-',
      }) {
    if (_unit == null) {
      return defaultValue;
    }

    for (final key in keys) {
      final value = _unit![key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return defaultValue;
  }

  String _unitNumber() {
    return _toPersianDigits(
      _value([
        'unit',
        'unit_number',
        'unit_name',
        'number',
        'name',
        'title',
      ]),
    );
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

  String _residenceStatus() {
    final value = _unit?['status_residence'];

    if (value == null ||
        value.toString().trim().isEmpty) {
      return 'ثبت نشده';
    }

    return value.toString();
  }

  Map<String, dynamic>? _owner() {
    final owner = _unit?['owner'];

    if (owner is Map) {
      return Map<String, dynamic>.from(owner);
    }

    return null;
  }

  Map<String, dynamic>? _renter() {
    final renter = _unit?['active_renter'];

    if (renter is Map) {
      return Map<String, dynamic>.from(renter);
    }

    return null;
  }

  bool _hasOwner() {
    final owner = _owner();

    if (owner == null) {
      return false;
    }

    final name = owner['name'];

    return name != null &&
        name.toString().trim().isNotEmpty;
  }

  bool _hasRenter() {
    final renter = _renter();

    if (renter == null) {
      return false;
    }

    final name = renter['name'];

    return name != null &&
        name.toString().trim().isNotEmpty;
  }

  String _ownerName() {
    final owner = _owner();

    if (owner == null) {
      return 'مالک ثبت نشده';
    }

    final name = owner['name'];

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
      owner['mobile'] ?? '-',
    );
  }

  String _ownerNationalCode() {
    final owner = _owner();

    if (owner == null) {
      return '-';
    }

    return _toPersianDigits(
      owner['national_code'] ?? '-',
    );
  }

  String _ownerPeopleCount() {
    final owner = _owner();

    if (owner == null) {
      return '-';
    }

    return _toPersianDigits(
      owner['people_count'] ?? 0,
    );
  }

  String _ownerDetails() {
    final owner = _owner();

    if (owner == null) {
      return '';
    }

    return owner['details']?.toString() ?? '';
  }

  String _renterName() {
    final renter = _renter();

    if (renter == null) {
      return 'مستاجر ثبت نشده';
    }

    final name = renter['name'];

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
      renter['mobile'] ?? '-',
    );
  }

  String _renterNationalCode() {
    final renter = _renter();

    if (renter == null) {
      return '-';
    }

    return _toPersianDigits(
      renter['national_code'] ?? '-',
    );
  }

  String _renterPeopleCount() {
    final renter = _renter();

    if (renter == null) {
      return '-';
    }

    return _toPersianDigits(
      renter['people_count'] ?? 0,
    );
  }

  String _renterStartDate() {
    final renter = _renter();

    if (renter == null) {
      return '-';
    }

    return renter['start_date']?.toString() ?? '-';
  }

  String _renterEndDate() {
    final renter = _renter();

    if (renter == null) {
      return '-';
    }

    return renter['end_date']?.toString() ?? '-';
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

    return renter['estate_name']?.toString() ?? '-';
  }

  String _renterDetails() {
    final renter = _renter();

    if (renter == null) {
      return '';
    }

    return renter['details']?.toString() ?? '';
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
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
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
  // Section Title
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
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // Management Card
  // =========================================================

  Widget _managementCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.10),
                  borderRadius:
                  BorderRadius.circular(12),
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
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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
  // Owner Card
  // =========================================================

  Widget _ownerCard() {
    final hasOwner = _hasOwner();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: primaryColor,
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
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: hasOwner
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasOwner
                          ? 'مالک فعلی واحد'
                          : 'برای این واحد مالکی ثبت نشده است',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasOwner
                            ? primaryColor
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
            if (_ownerDetails().trim().isNotEmpty)
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
  // Renter Card
  // =========================================================

  Widget _renterCard() {
    final hasRenter = _hasRenter();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people_outline,
                  color: primaryColor,
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
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: hasRenter
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasRenter
                          ? 'مستاجر فعلی واحد'
                          : 'برای این واحد مستاجری ثبت نشده است',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasRenter
                            ? primaryColor
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
        ],
      ),
    );
  }

  // =========================================================
  // Person Info Row
  // =========================================================

  Widget _personInfoRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 90,
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
              value,
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

  // =========================================================
  // History
  // =========================================================

  Widget _historySection() {
    final histories = _unit?['histories'];

    if (histories is! List ||
        histories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.history,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'سابقه‌ای برای این واحد ثبت نشده است.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: histories.map<Widget>((item) {
        if (item is! Map) {
          return const SizedBox.shrink();
        }

        final history =
        Map<String, dynamic>.from(item);

        final name =
            history['name']?.toString() ?? '-';

        final type =
            history['resident_type_display']
                ?.toString() ??
                history['resident_type']
                    ?.toString() ??
                '-';

        final fromDate =
            history['from_date']?.toString() ?? '-';

        final toDate =
        history['to_date']?.toString();

        final peopleCount =
            history['people_count'] ?? 0;

        final isActive =
            history['is_active'] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                  primaryColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.history,
                  color: primaryColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            textAlign:
                            TextAlign.right,
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration:
                            BoxDecoration(
                              color: primaryColor
                                  .withOpacity(
                                  0.10),
                              borderRadius:
                              BorderRadius
                                  .circular(20),
                            ),
                            child: const Text(
                              'فعلی',
                              style: TextStyle(
                                color:
                                primaryColor,
                                fontSize: 10,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    _historyRow(
                      'نوع',
                      type,
                    ),
                    _historyRow(
                      'تعداد نفرات',
                      _toPersianDigits(
                        peopleCount,
                      ),
                    ),
                    _historyRow(
                      'از تاریخ',
                      fromDate,
                    ),
                    _historyRow(
                      'تا تاریخ',
                      toDate == null ||
                          toDate.trim().isEmpty
                          ? 'تا کنون'
                          : toDate,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _historyRow(
      String title,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
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

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _loadUnit,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // =================================================
          // Header
          // =================================================

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius:
              BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color:
                    Colors.white.withOpacity(0.18),
                    borderRadius:
                    BorderRadius.circular(14),
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
                      const Text(
                        'واحد مسکونی',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'واحد ${_unitNumber()}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white,
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

          // =================================================
          // Unit information
          // =================================================

          _sectionTitle(
            'اطلاعات واحد',
            icon: Icons.home_work_outlined,
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
            icon: Icons.local_parking_outlined,
            title: 'شماره پارکینگ',
            value: _parkingNumber(),
          ),

          const SizedBox(height: 8),

          _infoCard(
            icon: Icons.directions_car_outlined,
            title: 'محل پارکینگ',
            value: _parkingPlace(),
          ),

          const SizedBox(height: 8),

          _infoCard(
            icon: Icons.add_circle_outline,
            title: 'پارکینگ اضافه اول',
            value: _extraParkingFirst(),
          ),

          const SizedBox(height: 8),

          _infoCard(
            icon: Icons.add_circle_outline,
            title: 'پارکینگ اضافه دوم',
            value: _extraParkingSecond(),
          ),

          const SizedBox(height: 8),

          _infoCard(
            icon: Icons.phone_outlined,
            title: 'تلفن واحد',
            value: _unitPhone(),
          ),

          const SizedBox(height: 8),

          _infoCard(
            icon: Icons.people_outline,
            title: 'تعداد ساکنین',
            value: _peopleCount(),
          ),

          const SizedBox(height: 8),

          _infoCard(
            icon: Icons.home_outlined,
            title: 'وضعیت سکونت',
            value: _residenceStatus(),
          ),

          if (_unitDetails().trim().isNotEmpty &&
              _unitDetails() != '-') ...[
            const SizedBox(height: 8),
            _infoCard(
              icon: Icons.notes_outlined,
              title: 'توضیحات واحد',
              value: _unitDetails(),
            ),
          ],

          const SizedBox(height: 22),

          // =================================================
          // Owner
          // =================================================

          _sectionTitle(
            'مالک واحد',
            icon: Icons.person_outline,
          ),

          const SizedBox(height: 10),

          _ownerCard(),

          const SizedBox(height: 10),

          _managementCard(
            icon: Icons.manage_accounts_outlined,
            title: _hasOwner()
                ? 'ویرایش / مدیریت مالک'
                : 'افزودن مالک',
            subtitle: _hasOwner()
                ? 'ویرایش یا حذف اطلاعات مالک واحد'
                : 'برای این واحد مالک ثبت کنید',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ManagerUnitOwnerScreen(
                        unitId: widget.unitId,
                      ),
                ),
              );

              if (mounted) {
                _loadUnit();
              }
            },
          ),

          const SizedBox(height: 22),

          // =================================================
          // Renter
          // =================================================

          _sectionTitle(
            'مستاجر واحد',
            icon: Icons.people_outline,
          ),

          const SizedBox(height: 10),

          _renterCard(),

          const SizedBox(height: 10),

          _managementCard(
            icon: Icons.people_alt_outlined,
            title: _hasRenter()
                ? 'ویرایش / مدیریت مستاجر'
                : 'افزودن مستاجر',
            subtitle: _hasRenter()
                ? 'ویرایش یا حذف اطلاعات مستاجر واحد'
                : 'برای این واحد مستاجر ثبت کنید',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ManagerUnitRenterScreen(
                        unitId: widget.unitId,
                      ),
                ),
              );

              if (mounted) {
                _loadUnit();
              }
            },
          ),

          const SizedBox(height: 22),

          // =================================================
          // History
          // =================================================

          _sectionTitle(
            'سوابق سکونت',
            icon: Icons.history,
          ),

          const SizedBox(height: 10),

          _historySection(),

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
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F9FA),
        appBar: AppBar(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'جزئیات واحد',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              onPressed:
              _isLoading ? null : _loadUnit,
              icon: const Icon(
                Icons.refresh,
              ),
              tooltip: 'بروزرسانی',
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
            padding:
            const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 15),
                Text(
                  _errorMessage!,
                  textAlign:
                  TextAlign.center,
                ),
                const SizedBox(height: 15),
                FilledButton.icon(
                  style:
                  FilledButton.styleFrom(
                    backgroundColor:
                    primaryColor,
                    foregroundColor:
                    Colors.white,
                  ),
                  onPressed: _loadUnit,
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
        )
            : _buildBody(),
      ),
    );
  }
}