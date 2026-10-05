import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/manager_unit_service.dart';
import 'manager_unit_create_screen.dart';
import 'manager_unit_detail_screen.dart';

class ManagerUnitsScreen extends StatefulWidget {
  const ManagerUnitsScreen({
    super.key,
  });

  @override
  State<ManagerUnitsScreen> createState() =>
      _ManagerUnitsScreenState();
}

class _ManagerUnitsScreenState
    extends State<ManagerUnitsScreen> {

  static const Color primaryColor =
  Color(0xff00ACC1);

  final ManagerUnitService _service =
  ManagerUnitService();

  final TextEditingController _searchController =
  TextEditingController();

  Timer? _searchTimer;

  List<Map<String, dynamic>> _units = [];

  bool _isLoading = true;
  bool _isDeleting = false;

  String _residentType = 'all';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _onSearchChanged,
    );

    _loadUnits();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
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
  // Load units
  // =========================================================

  Future<void> _loadUnits() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final units = await _service.getUnits(
        search: _searchController.text.trim(),
        residentType: _residentType,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _units = units;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      _showError(
        _cleanError(e),
      );
    }
  }

  // =========================================================
  // Search
  // =========================================================

  void _onSearchChanged() {
    _searchTimer?.cancel();

    _searchTimer = Timer(
      const Duration(
        milliseconds: 500,
      ),
          () {
        _loadUnits();
      },
    );
  }

  // =========================================================
  // Resident filter
  // =========================================================

  void _changeResidentType(
      String type,
      ) {
    if (_residentType == type) {
      return;
    }

    setState(() {
      _residentType = type;
    });

    _loadUnits();
  }

  // =========================================================
  // Create unit
  // =========================================================

  Future<void> _openCreateUnit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const ManagerUnitCreateScreen(),
      ),
    );

    if (result == true) {
      _loadUnits();
    }
  }

  // =========================================================
  // Detail
  // =========================================================

  Future<void> _openUnitDetail(
      Map<String, dynamic> unit,
      ) async {
    final id = _toInt(
      unit['id'],
    );

    if (id == null) {
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ManagerUnitDetailScreen(
              unitId: id,
            ),
      ),
    );

    if (result == true) {
      _loadUnits();
    }
  }

  // =========================================================
  // Delete unit
  // =========================================================

  Future<void> _confirmDelete(
      Map<String, dynamic> unit,
      ) async {
    final id = _toInt(
      unit['id'],
    );

    if (id == null) {
      return;
    }

    final unitNumber = _unitName(
      unit,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'حذف واحد',
              textAlign: TextAlign.right,
            ),
            content: Text(
              'آیا از حذف واحد $unitNumber مطمئن هستید؟',
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    false,
                  );
                },
                child: const Text(
                  'انصراف',
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
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
                child: const Text(
                  'حذف',
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _deleteUnit(id);
  }

  Future<void> _deleteUnit(
      int id,
      ) async {
    if (_isDeleting) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _service.deleteUnit(
        id,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'واحد با موفقیت حذف شد.',
            textAlign: TextAlign.right,
          ),
          backgroundColor:
          Colors.green,
        ),
      );

      await _loadUnits();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        _cleanError(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // =========================================================
  // Helpers
  // =========================================================

  int? _toInt(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  String _unitName(
      Map<String, dynamic> unit,
      ) {
    return _toPersianDigits(
      unit['unit'] ?? '-',
    );
  }

  String _floorName(
      Map<String, dynamic> unit,
      ) {
    final floor = unit['floor_number'];

    if (floor == null) {
      return '-';
    }

    final floorInt = _toInt(floor);

    if (floorInt == null) {
      return _toPersianDigits(
        floor,
      );
    }

    if (floorInt == 0) {
      return 'همکف';
    }

    if (floorInt < 0) {
      return 'زیرزمین ${_toPersianDigits(floorInt.abs())}';
    }

    return 'طبقه ${_toPersianDigits(floorInt)}';
  }

  String _areaName(
      Map<String, dynamic> unit,
      ) {
    final area = unit['area'];

    if (area == null ||
        area.toString().trim().isEmpty) {
      return '-';
    }

    return _toPersianDigits(
      area,
    );
  }

  bool _hasOwner(
      Map<String, dynamic> unit,
      ) {
    final owner = unit['owner'];

    if (owner is Map) {
      final name = owner['name'];

      return name != null &&
          name.toString().trim().isNotEmpty;
    }

    return false;
  }

  bool _hasRenter(
      Map<String, dynamic> unit,
      ) {
    final renter =
    unit['active_renter'];

    if (renter is Map) {
      final name = renter['name'];

      return name != null &&
          name.toString().trim().isNotEmpty;
    }

    return false;
  }

  String _ownerName(
      Map<String, dynamic> unit,
      ) {
    final owner = unit['owner'];

    if (owner is Map) {
      final name = owner['name'];

      if (name != null &&
          name.toString().trim().isNotEmpty) {
        return name.toString();
      }
    }

    return 'مالک ثبت نشده';
  }

  String _renterName(
      Map<String, dynamic> unit,
      ) {
    final renter =
    unit['active_renter'];

    if (renter is Map) {
      final name = renter['name'];

      if (name != null &&
          name.toString().trim().isNotEmpty) {
        return name.toString();
      }
    }

    return 'مستاجر ثبت نشده';
  }

  String _cleanError(
      dynamic error,
      ) {
    final text = error
        .toString()
        .replaceFirst(
      'Exception: ',
      '',
    );

    return text.trim().isEmpty
        ? 'خطایی رخ داده است.'
        : text;
  }

  void _showError(
      String message,
      ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.right,
        ),
        backgroundColor:
        Colors.red,
      ),
    );
  }

  // =========================================================
  // Filter chip
  // =========================================================

  Widget _buildFilterChip({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final selected =
        _residentType == value;

    return ChoiceChip(
      selected: selected,
      onSelected: (_) {
        _changeResidentType(
          value,
        );
      },
      selectedColor:
      primaryColor.withOpacity(
        0.15,
      ),
      backgroundColor:
      Colors.grey.shade100,
      side: BorderSide(
        color: selected
            ? primaryColor
            : Colors.grey.shade300,
      ),
      avatar: Icon(
        icon,
        size: 18,
        color: selected
            ? primaryColor
            : Colors.grey.shade600,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: selected
              ? FontWeight.bold
              : FontWeight.normal,
          color: selected
              ? primaryColor
              : Colors.grey.shade700,
        ),
      ),
      labelPadding:
      const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
    );
  }

  // =========================================================
  // Unit card
  // =========================================================

  Widget _buildUnitCard(
      Map<String, dynamic> unit,
      ) {
    final hasOwner =
    _hasOwner(unit);

    final hasRenter =
    _hasRenter(unit);

    return Card(
      elevation: 1.5,
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        onTap: () {
          _openUnitDetail(
            unit,
          );
        },
        child: Padding(
          padding:
          const EdgeInsets.all(
            12,
          ),
          child: Column(
            children: [

              // =================================================
              // Header
              // =================================================

              Row(
                crossAxisAlignment:
                CrossAxisAlignment
                    .center,
                children: [

                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                    BoxDecoration(
                      color: primaryColor
                          .withOpacity(
                        0.10,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(
                        12,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .home_work_outlined,
                      color:
                      primaryColor,
                      size: 26,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [

                        Text(
                          'واحد ${_unitName(unit)}',
                          style:
                          const TextStyle(
                            fontSize: 17,
                            fontWeight:
                            FontWeight.bold,
                            color:
                            Colors.black87,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          '${_floorName(unit)}  •  ${_areaName(unit)} متر',
                          style:
                          TextStyle(
                            fontSize: 12,
                            color:
                            Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color:
                      Colors.grey.shade700,
                    ),
                    onSelected:
                        (value) {
                      if (value ==
                          'details') {
                        _openUnitDetail(
                          unit,
                        );
                      }

                      if (value ==
                          'delete') {
                        _confirmDelete(
                          unit,
                        );
                      }
                    },
                    itemBuilder:
                        (context) {
                      return const [
                        PopupMenuItem(
                          value:
                          'details',
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .visibility_outlined,
                                size: 20,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                'جزئیات',
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value:
                          'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons
                                    .delete_outline,
                                size: 20,
                                color:
                                Colors.red,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                'حذف',
                                style:
                                TextStyle(
                                  color:
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              const Divider(
                height: 1,
              ),

              const SizedBox(
                height: 12,
              ),

              // =================================================
              // Owner
              // =================================================

              _buildPersonRow(
                icon:
                Icons.person_outline,
                title:
                'مالک',
                name:
                _ownerName(unit),
                active:
                hasOwner,
              ),

              const SizedBox(
                height: 8,
              ),

              // =================================================
              // Renter
              // =================================================

              _buildPersonRow(
                icon:
                Icons.person_pin_outlined,
                title:
                'مستاجر',
                name:
                _renterName(unit),
                active:
                hasRenter,
              ),

              const SizedBox(
                height: 10,
              ),

              // =================================================
              // Bottom information
              // =================================================

              Row(
                children: [

                  if (unit['parking_number'] !=
                      null &&
                      unit['parking_number']
                          .toString()
                          .trim()
                          .isNotEmpty)
                    Expanded(
                      child: _buildInfoItem(
                        icon:
                        Icons.local_parking_outlined,
                        text:
                        'پارکینگ ${_toPersianDigits(unit['parking_number'])}',
                      ),
                    ),

                  if (unit['bedrooms_count'] !=
                      null)
                    Expanded(
                      child: _buildInfoItem(
                        icon:
                        Icons.bed_outlined,
                        text:
                        '${_toPersianDigits(unit['bedrooms_count'])} خواب',
                      ),
                    ),

                  Expanded(
                    child: _buildInfoItem(
                      icon:
                      Icons.people_outline,
                      text:
                      '${_toPersianDigits(unit['people_count'] ?? 0)} نفر',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // Person row
  // =========================================================

  Widget _buildPersonRow({
    required IconData icon,
    required String title,
    required String name,
    required bool active,
  }) {
    final Color color = active
        ? primaryColor
        : Colors.grey.shade500;

    final Color textColor = active
        ? const Color(0xff00838F)
        : Colors.grey.shade600;

    return Row(
      children: [

        Icon(
          icon,
          size: 20,
          color: color,
        ),

        const SizedBox(
          width: 8,
        ),

        SizedBox(
          width: 55,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
              FontWeight.bold,
              color:
              Colors.grey.shade700,
            ),
          ),
        ),

        const SizedBox(
          width: 5,
        ),

        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              fontWeight: active
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // Info item
  // =========================================================

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.center,
      children: [

        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),

        const SizedBox(
          width: 4,
        ),

        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color:
              Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // Empty state
  // =========================================================

  Widget _buildEmptyState() {
    String message;

    if (_searchController.text
        .trim()
        .isNotEmpty) {
      message =
      'واحدی با این جستجو پیدا نشد.';
    } else if (_residentType ==
        'owner') {
      message =
      'واحدی با مالک ثبت‌شده وجود ندارد.';
    } else if (_residentType ==
        'renter') {
      message =
      'واحدی با مستاجر فعال وجود ندارد.';
    } else {
      message =
      'هنوز هیچ واحدی ثبت نشده است.';
    }

    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [

            Container(
              width: 80,
              height: 80,
              decoration:
              BoxDecoration(
                color: primaryColor
                    .withOpacity(
                  0.10,
                ),
                shape:
                BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .home_work_outlined,
                size: 40,
                color:
                primaryColor,
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            Text(
              message,
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                fontSize: 14,
                color:
                Colors.grey.shade700,
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            if (_searchController
                .text
                .trim()
                .isEmpty &&
                _residentType ==
                    'all')
              ElevatedButton.icon(
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  primaryColor,
                  foregroundColor:
                  Colors.white,
                ),
                onPressed:
                _openCreateUnit,
                icon: const Icon(
                  Icons
                      .add_home_work_outlined,
                ),
                label: const Text(
                  'افزودن اولین واحد',
                ),
              ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // Loading
  // =========================================================

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: primaryColor,
      ),
    );
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: Scaffold(

        appBar: AppBar(
          backgroundColor:
          primaryColor,
          foregroundColor:
          Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'مدیریت واحدها',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
              FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              tooltip:
              'بروزرسانی',
              onPressed:
              _isLoading
                  ? null
                  : () {
                _loadUnits();
              },
              icon: const Icon(
                Icons.refresh,
                color:
                Colors.white,
              ),
            ),
          ],
        ),

        floatingActionButton:
        FloatingActionButton.extended(
          backgroundColor:
          primaryColor,
          foregroundColor:
          Colors.white,
          onPressed:
          _isDeleting
              ? null
              : _openCreateUnit,
          icon: const Icon(
            Icons
                .add_home_work_outlined,
          ),
          label: const Text(
            'افزودن واحد',
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),

        body: SafeArea(
          child: Column(
            children: [

              // =================================================
              // Search
              // =================================================

              Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  12,
                  12,
                  12,
                  8,
                ),
                child: TextField(
                  controller:
                  _searchController,
                  textDirection:
                  TextDirection.rtl,
                  textAlign:
                  TextAlign.right,
                  decoration:
                  InputDecoration(
                    hintText:
                    'جستجوی واحد، مالک یا شماره همراه...',
                    hintTextDirection:
                    TextDirection.rtl,
                    prefixIcon:
                    const Icon(
                      Icons.search,
                      color:
                      primaryColor,
                    ),
                    suffixIcon:
                    _searchController
                        .text
                        .isNotEmpty
                        ? IconButton(
                      onPressed:
                          () {
                        _searchController
                            .clear();
                      },
                      icon:
                      const Icon(
                        Icons.clear,
                      ),
                    )
                        : null,
                    filled: true,
                    fillColor:
                    Colors.grey.shade100,
                    border:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius
                          .circular(
                        14,
                      ),
                      borderSide:
                      BorderSide.none,
                    ),
                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius
                          .circular(
                        14,
                      ),
                      borderSide:
                      const BorderSide(
                        color:
                        primaryColor,
                        width: 1.2,
                      ),
                    ),
                    contentPadding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),

              // =================================================
              // Filters
              // =================================================

              SingleChildScrollView(
                scrollDirection:
                Axis.horizontal,
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  children: [

                    _buildFilterChip(
                      value: 'all',
                      label:
                      'همه واحدها',
                      icon:
                      Icons.home_work_outlined,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    _buildFilterChip(
                      value: 'owner',
                      label:
                      'فقط مالکین',
                      icon:
                      Icons.person_outline,
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    _buildFilterChip(
                      value: 'renter',
                      label:
                      'فقط مستاجرین',
                      icon:
                      Icons
                          .person_pin_outlined,
                    ),
                  ],
                ),
              ),

              // =================================================
              // Count
              // =================================================

              Padding(
                padding:
                const EdgeInsets
                    .fromLTRB(
                  14,
                  8,
                  14,
                  4,
                ),
                child: Row(
                  children: [

                    Text(
                      '${_toPersianDigits(_units.length)} واحد',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors
                            .grey.shade600,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const Spacer(),

                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                          primaryColor,
                        ),
                      ),
                  ],
                ),
              ),

              // =================================================
              // List
              // =================================================

              Expanded(
                child: _isLoading &&
                    _units.isEmpty
                    ? _buildLoading()
                    : _units.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                  color:
                  primaryColor,
                  onRefresh:
                  _loadUnits,
                  child:
                  ListView.builder(
                    physics:
                    const AlwaysScrollableScrollPhysics(),
                    padding:
                    const EdgeInsets.fromLTRB(
                      12,
                      8,
                      12,
                      100,
                    ),
                    itemCount:
                    _units.length,
                    itemBuilder:
                        (
                        context,
                        index,
                        ) {
                      return _buildUnitCard(
                        _units[index],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}