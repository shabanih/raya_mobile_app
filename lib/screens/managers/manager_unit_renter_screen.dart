import 'package:flutter/material.dart';

import '../../services/manager_unit_service.dart';

class ManagerUnitRenterScreen extends StatefulWidget {
  final int unitId;

  const ManagerUnitRenterScreen({
    super.key,
    required this.unitId,
  });

  @override
  State<ManagerUnitRenterScreen> createState() =>
      _ManagerUnitRenterScreenState();
}

class _ManagerUnitRenterScreenState
    extends State<ManagerUnitRenterScreen> {
  static const Color primaryColor = Color(0xff00ACC1);

  final ManagerUnitService _unitService =
  ManagerUnitService();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _mobileController =
  TextEditingController();

  final TextEditingController _nationalCodeController =
  TextEditingController();

  final TextEditingController _peopleCountController =
  TextEditingController();

  final TextEditingController _startDateController =
  TextEditingController();

  final TextEditingController _endDateController =
  TextEditingController();

  final TextEditingController _contractNumberController =
  TextEditingController();

  final TextEditingController _estateNameController =
  TextEditingController();

  final TextEditingController _detailsController =
  TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool _hasRenter = false;

  /// افزودن مستاجر جدید
  bool _isAddingNew = false;

  /// ویرایش مستاجر فعلی
  bool _isEditing = false;

  String? _errorMessage;

  Map<String, dynamic>? _unit;

  /// شناسه مستاجر فعال
  int? _renterId;

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
    _nameController.dispose();
    _mobileController.dispose();
    _nationalCodeController.dispose();
    _peopleCountController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _contractNumberController.dispose();
    _estateNameController.dispose();
    _detailsController.dispose();

    super.dispose();
  }

  // =========================================================
  // Load Unit
  // =========================================================

  Future<void> _loadUnit() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _hasRenter = false;
        _renterId = null;
        _isAddingNew = false;
        _isEditing = false;
      });
    }

    try {
      final unit =
      await _unitService.getUnit(widget.unitId);

      if (!mounted) return;

      _unit = unit;

      _clearForm();

      // -------------------------------------------------------
      // دریافت مستاجر فعال
      // -------------------------------------------------------

      dynamic renterValue =
      unit['active_renter'];

      // برای سازگاری با پاسخ‌های احتمالی دیگر
      renterValue ??= unit['renter'];

      final renter =
      _asMap(renterValue);

      if (renter != null) {
        _renterId =
            _extractRenterId(renter);

        final name =
        _firstString(
          renter,
          [
            'renter_name',
            'name',
          ],
        );

        _hasRenter =
            name.trim().isNotEmpty;

        if (_hasRenter) {
          _fillRenter(renter);
        }
      }

      if (_peopleCountController.text
          .trim()
          .isEmpty) {
        _peopleCountController.text = '1';
      }

      // -------------------------------------------------------
      // اگر مستاجر ندارد، مستقیماً حالت افزودن فعال شود
      // -------------------------------------------------------

      if (!_hasRenter) {
        _isAddingNew = true;
        _isEditing = false;
      }

      setState(() {
        _isLoading = false;
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
  // Map helpers
  // =========================================================

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  String _firstString(
      Map<String, dynamic> map,
      List<String> keys,
      ) {
    for (final key in keys) {
      final value = map[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '';
  }

  int? _extractRenterId(
      Map<String, dynamic> renter,
      ) {
    final candidates = [
      renter['id'],
      renter['renter_id'],
      renter['pk'],
    ];

    for (final value in candidates) {
      if (value == null) {
        continue;
      }

      if (value is int) {
        return value;
      }

      final parsed =
      int.tryParse(
        value.toString(),
      );

      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  // =========================================================
  // Fill
  // =========================================================

  void _fillRenter(
      Map<String, dynamic> renter,
      ) {
    _renterId =
        _extractRenterId(renter);

    _nameController.text =
        _firstString(
          renter,
          [
            'renter_name',
            'name',
          ],
        );

    _mobileController.text =
        _firstString(
          renter,
          [
            'renter_mobile',
            'mobile',
          ],
        );

    _nationalCodeController.text =
        _firstString(
          renter,
          [
            'renter_national_code',
            'national_code',
          ],
        );

    _peopleCountController.text =
        _firstString(
          renter,
          [
            'renter_people_count',
            'people_count',
          ],
        );

    _startDateController.text =
        _firstString(
          renter,
          [
            'start_date',
            'renter_start_date',
          ],
        );

    _endDateController.text =
        _firstString(
          renter,
          [
            'end_date',
            'renter_end_date',
          ],
        );

    _contractNumberController.text =
        _firstString(
          renter,
          [
            'contract_number',
          ],
        );

    _estateNameController.text =
        _firstString(
          renter,
          [
            'estate_name',
          ],
        );

    _detailsController.text =
        _firstString(
          renter,
          [
            'renter_details',
            'details',
          ],
        );
  }

  // =========================================================
  // Clear
  // =========================================================

  void _clearForm() {
    _nameController.clear();
    _mobileController.clear();
    _nationalCodeController.clear();
    _peopleCountController.clear();
    _startDateController.clear();
    _endDateController.clear();
    _contractNumberController.clear();
    _estateNameController.clear();
    _detailsController.clear();
  }

  // =========================================================
  // Restore current renter
  // =========================================================

  void _restoreCurrentRenter() {
    _clearForm();

    if (_unit == null) {
      return;
    }

    dynamic renterValue =
    _unit!['active_renter'];

    renterValue ??= _unit!['renter'];

    final renter =
    _asMap(renterValue);

    if (renter != null) {
      _fillRenter(renter);
    }

    if (_peopleCountController.text
        .trim()
        .isEmpty) {
      _peopleCountController.text = '1';
    }
  }

  // =========================================================
  // Start Edit
  // =========================================================

  void _startEditRenter() {
    if (!_hasRenter) {
      return;
    }

    if (_renterId == null) {
      _showError(
        'شناسه مستاجر فعلی دریافت نشد. '
            'لطفاً ابتدا اطلاعات واحد را بازخوانی کنید.',
      );
      return;
    }

    setState(() {
      _isEditing = true;
      _isAddingNew = false;
    });
  }

  // =========================================================
  // Start Add New
  // =========================================================

  void _startAddNewRenter() {
    setState(() {
      _isAddingNew = true;
      _isEditing = false;

      _clearForm();

      _peopleCountController.text = '1';
    });
  }

  // =========================================================
  // Cancel Edit
  // =========================================================

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _isAddingNew = false;

      _restoreCurrentRenter();
    });
  }

  // =========================================================
  // Cancel Add
  // =========================================================

  void _cancelAdd() {
    if (!_hasRenter) {
      Navigator.pop(context, false);
      return;
    }

    setState(() {
      _isAddingNew = false;
      _isEditing = false;

      _restoreCurrentRenter();
    });
  }

  // =========================================================
  // Digits
  // =========================================================

  String _normalizeDigits(
      String value,
      ) {
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

  String _toPersianDigits(
      dynamic value,
      ) {
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
  // Unit number
  // =========================================================

  String _unitNumber() {
    final value = _unit?['unit'];

    if (value != null) {
      return _toPersianDigits(value);
    }

    return _toPersianDigits(
      _unit?['unit_number'] ?? '-',
    );
  }

  // =========================================================
  // Renter data
  // =========================================================

  Map<String, dynamic> _renterData() {
    final peopleCount =
        int.tryParse(
          _normalizeDigits(
            _peopleCountController.text.trim(),
          ),
        ) ??
            1;

    return <String, dynamic>{
      'renter_name':
      _nameController.text.trim(),

      'renter_mobile':
      _normalizeDigits(
        _mobileController.text.trim(),
      ),

      'renter_national_code':
      _normalizeDigits(
        _nationalCodeController.text.trim(),
      ),

      'renter_people_count':
      peopleCount,

      'start_date':
      _startDateController.text.trim(),

      'end_date':
      _endDateController.text.trim(),

      'contract_number':
      _contractNumberController.text.trim(),

      'estate_name':
      _estateNameController.text.trim(),

      'renter_details':
      _detailsController.text.trim(),

      'renter_is_active':
      true,
    };
  }

  // =========================================================
  // Save
  // =========================================================

  Future<void> _saveRenter() async {
    if (!_isAddingNew && !_isEditing) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSaving || _isDeleting) {
      return;
    }

    // -------------------------------------------------------
    // برای ویرایش باید شناسه مستاجر داشته باشیم
    // -------------------------------------------------------

    if (_isEditing &&
        _renterId == null) {
      _showError(
        'شناسه مستاجر فعلی مشخص نیست. '
            'لطفاً دوباره وارد صفحه شوید.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final data =
      _renterData();

      // =====================================================
      // ویرایش مستاجر فعلی
      // =====================================================

      if (_isEditing) {
        debugPrint(
          'Updating renter: '
              'unit=${widget.unitId}, '
              'renter=$_renterId',
        );

        await _unitService.updateRenter(
          widget.unitId,
          _renterId!,
          data,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'اطلاعات مستاجر با موفقیت ویرایش شد.',
            ),
            backgroundColor: primaryColor,
          ),
        );
      }

      // =====================================================
      // افزودن مستاجر جدید
      // =====================================================

      else if (_isAddingNew) {
        debugPrint(
          'Creating new renter: '
              'unit=${widget.unitId}',
        );

        await _unitService.createRenter(
          widget.unitId,
          data,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'مستاجر جدید با موفقیت ثبت شد.',
            ),
            backgroundColor: primaryColor,
          ),
        );
      }

      if (!mounted) return;

      Navigator.pop(
        context,
        true,
      );
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
  // Delete / Deactivate
  // =========================================================

  Future<void> _deleteRenter() async {
    if (!_hasRenter ||
        _renterId == null ||
        _isAddingNew ||
        _isEditing) {
      return;
    }

    if (_isSaving || _isDeleting) {
      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'غیرفعال کردن مستاجر',
            ),
            content: const Text(
              'آیا از غیرفعال کردن مستاجر فعلی '
                  'این واحد اطمینان دارید؟\n\n'
                  'اطلاعات و سابقه سکونت مستاجر '
                  'حذف نخواهد شد.',
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
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () {
                  Navigator.pop(
                    context,
                    true,
                  );
                },
                child: const Text(
                  'غیرفعال کردن',
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

    setState(() {
      _isDeleting = true;
    });

    try {
      debugPrint(
        'Deleting renter: '
            'unit=${widget.unitId}, '
            'renter=$_renterId',
      );

      await _unitService.deleteRenter(
        widget.unitId,
        _renterId!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'مستاجر فعلی غیرفعال شد.',
          ),
          backgroundColor: primaryColor,
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) return;

      _showError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // =========================================================
  // Error
  // =========================================================

  String _cleanError(
      dynamic error,
      ) {
    String message =
    error.toString();

    if (message.startsWith(
      'Exception: ',
    )) {
      message =
          message.substring(
            'Exception: '.length,
          );
    }

    if (message.trim().isEmpty) {
      return 'خطایی رخ داده است.';
    }

    return message;
  }

  void _showError(
      dynamic error,
      ) {
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
  // Text Field
  // =========================================================

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 13,
      ),
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
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(12),
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
  // Header
  // =========================================================

  Widget _buildHeader() {
    String title;

    if (_isAddingNew) {
      title = 'افزودن مستاجر جدید';
    } else if (_isEditing) {
      title = 'ویرایش مستاجر';
    } else if (_hasRenter) {
      title = 'مستاجر فعلی';
    } else {
      title = 'افزودن مستاجر';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color:
              Colors.white.withOpacity(0.18),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: Icon(
              _isAddingNew
                  ? Icons.person_add_outlined
                  : _isEditing
                  ? Icons.edit_outlined
                  : Icons.people_outline,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'واحد ${_unitNumber()}',
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

  // =========================================================
  // Current Renter
  // =========================================================

  Widget _buildCurrentRenterInfo() {
    if (!_hasRenter ||
        _isAddingNew ||
        _isEditing) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'مستاجر فعال واحد',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green
                      .withOpacity(0.1),
                  borderRadius:
                  BorderRadius.circular(20),
                ),
                child: const Text(
                  'فعال',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(
            'نام',
            _nameController.text,
          ),
          _infoRow(
            'موبایل',
            _mobileController.text,
          ),
          _infoRow(
            'کد ملی',
            _nationalCodeController.text,
          ),
          _infoRow(
            'تعداد نفرات',
            _peopleCountController.text,
          ),
          _infoRow(
            'شروع سکونت',
            _startDateController.text,
          ),
          if (_endDateController.text
              .trim()
              .isNotEmpty)
            _infoRow(
              'پایان سکونت',
              _endDateController.text,
            ),
          if (_contractNumberController.text
              .trim()
              .isNotEmpty)
            _infoRow(
              'شماره قرارداد',
              _contractNumberController.text,
            ),
          if (_estateNameController.text
              .trim()
              .isNotEmpty)
            _infoRow(
              'نام بنگاه',
              _estateNameController.text,
            ),
          if (_detailsController.text
              .trim()
              .isNotEmpty)
            _infoRow(
              'توضیحات',
              _detailsController.text,
            ),
        ],
      ),
    );
  }

  Widget _infoRow(
      String title,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty
                  ? '-'
                  : value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
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
    String appBarTitle;

    if (_isAddingNew) {
      appBarTitle =
      'افزودن مستاجر جدید';
    } else if (_isEditing) {
      appBarTitle =
      'ویرایش مستاجر';
    } else {
      appBarTitle =
      'مدیریت مستاجر';
    }

    return Directionality(
      textDirection: TextDirection.rtl,
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
            appBarTitle,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _isLoading
            ? const Center(
          child:
          CircularProgressIndicator(
            color: primaryColor,
          ),
        )
            : _errorMessage != null
            ? _buildError()
            : _buildForm(),
      ),
    );
  }

  // =========================================================
  // Error
  // =========================================================

  Widget _buildError() {
    return Center(
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
              ),
              onPressed: _loadUnit,
              icon:
              const Icon(Icons.refresh),
              label:
              const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // Form
  // =========================================================

  Widget _buildForm() {
    // =======================================================
    // نمایش مستاجر فعلی
    // =======================================================

    if (_hasRenter &&
        !_isAddingNew &&
        !_isEditing) {
      return ListView(
        padding:
        const EdgeInsets.all(14),
        children: [
          _buildHeader(),
          const SizedBox(height: 18),
          _buildCurrentRenterInfo(),
          const SizedBox(height: 14),

          // -------------------------------------------------
          // ویرایش
          // -------------------------------------------------

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
                  BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              onPressed:
              _startEditRenter,
              icon: const Icon(
                Icons.edit_outlined,
              ),
              label: const Text(
                'ویرایش اطلاعات مستاجر',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // -------------------------------------------------
          // افزودن مستاجر جدید
          // -------------------------------------------------

          SizedBox(
            height: 52,
            child:
            OutlinedButton.icon(
              style:
              OutlinedButton.styleFrom(
                foregroundColor:
                primaryColor,
                side:
                const BorderSide(
                  color: primaryColor,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              onPressed:
              _startAddNewRenter,
              icon: const Icon(
                Icons.person_add_alt_1,
              ),
              label: const Text(
                'افزودن مستاجر جدید',
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // -------------------------------------------------
          // غیرفعال کردن
          // -------------------------------------------------

          SizedBox(
            height: 50,
            child:
            OutlinedButton.icon(
              style:
              OutlinedButton.styleFrom(
                foregroundColor:
                Colors.red,
                side:
                const BorderSide(
                  color: Colors.red,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              onPressed:
              _isDeleting
                  ? null
                  : _deleteRenter,
              icon: _isDeleting
                  ? const SizedBox(
                width: 19,
                height: 19,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.red,
                ),
              )
                  : const Icon(
                Icons
                    .delete_outline,
              ),
              label: const Text(
                'غیرفعال کردن مستاجر',
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      );
    }

    // =======================================================
    // فرم ویرایش / افزودن
    // =======================================================

    final isEdit = _isEditing;

    return Form(
      key: _formKey,
      child: ListView(
        padding:
        const EdgeInsets.all(14),
        children: [
          _buildHeader(),

          const SizedBox(height: 20),

          // -------------------------------------------------
          // پیام ویرایش
          // -------------------------------------------------

          if (isEdit)
            Container(
              padding:
              const EdgeInsets.all(12),
              margin:
              const EdgeInsets.only(
                bottom: 15,
              ),
              decoration:
              BoxDecoration(
                color: primaryColor
                    .withOpacity(0.08),
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
                border: Border.all(
                  color: primaryColor
                      .withOpacity(0.25),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    color: primaryColor,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'اطلاعات مستاجر فعلی را ویرایش می‌کنید. با ذخیره، همان رکورد مستاجر به‌روزرسانی می‌شود و سابقه سکونت جدیدی ایجاد نمی‌شود.',
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // -------------------------------------------------
          // پیام افزودن مستاجر جدید
          // -------------------------------------------------

          if (_hasRenter &&
              _isAddingNew)
            Container(
              padding:
              const EdgeInsets.all(12),
              margin:
              const EdgeInsets.only(
                bottom: 15,
              ),
              decoration:
              BoxDecoration(
                color: Colors.orange
                    .withOpacity(0.10),
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
                border: Border.all(
                  color: Colors.orange
                      .withOpacity(0.35),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'با ثبت مستاجر جدید، مستاجر فعلی غیرفعال شده و سابقه سکونت او حفظ می‌شود.',
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Text(
            isEdit
                ? 'ویرایش اطلاعات مستاجر'
                : 'اطلاعات مستاجر جدید',
            style: const TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _textField(
            controller:
            _nameController,
            label:
            'نام و نام خانوادگی',
            icon:
            Icons.person_outline,
            hint:
            'نام مستاجر را وارد کنید',
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'نام مستاجر را وارد کنید';
              }

              return null;
            },
          ),

          _textField(
            controller:
            _mobileController,
            label:
            'شماره موبایل',
            icon:
            Icons.phone_outlined,
            hint:
            'مثلاً 09121234567',
            keyboardType:
            TextInputType.phone,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'شماره موبایل را وارد کنید';
              }

              final mobile =
              _normalizeDigits(
                value.trim(),
              );

              if (mobile.length != 11 ||
                  !mobile.startsWith(
                    '09',
                  )) {
                return 'شماره موبایل معتبر نیست';
              }

              return null;
            },
          ),

          _textField(
            controller:
            _nationalCodeController,
            label:
            'کد ملی',
            icon:
            Icons.badge_outlined,
            keyboardType:
            TextInputType.number,
          ),

          _textField(
            controller:
            _peopleCountController,
            label:
            'تعداد نفرات',
            icon:
            Icons.people_outline,
            keyboardType:
            TextInputType.number,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'تعداد نفرات را وارد کنید';
              }

              final count =
              int.tryParse(
                _normalizeDigits(
                  value.trim(),
                ),
              );

              if (count == null ||
                  count < 0) {
                return 'تعداد نفرات معتبر نیست';
              }

              return null;
            },
          ),

          const SizedBox(height: 4),

          const Text(
            'مدت سکونت',
            style: TextStyle(
              fontSize: 15,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          _textField(
            controller:
            _startDateController,
            label:
            'تاریخ شروع',
            icon:
            Icons.calendar_today_outlined,
            hint:
            'مثلاً 1405-01-01',
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'تاریخ شروع را وارد کنید';
              }

              return null;
            },
          ),

          _textField(
            controller:
            _endDateController,
            label:
            'تاریخ پایان',
            icon:
            Icons.event_outlined,
            hint:
            'مثلاً 1406-01-01',
          ),

          _textField(
            controller:
            _contractNumberController,
            label:
            'شماره قرارداد',
            icon:
            Icons.description_outlined,
          ),

          _textField(
            controller:
            _estateNameController,
            label:
            'نام بنگاه',
            icon:
            Icons.business_outlined,
          ),

          _textField(
            controller:
            _detailsController,
            label:
            'توضیحات',
            icon:
            Icons.notes_outlined,
            hint:
            'توضیحات مربوط به مستاجر',
            maxLines: 4,
          ),

          const SizedBox(height: 8),

          // -------------------------------------------------
          // Save
          // -------------------------------------------------

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
                  BorderRadius.circular(
                    12,
                  ),
                ),
              ),
              onPressed:
              _isSaving ||
                  _isDeleting
                  ? null
                  : _saveRenter,
              icon: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                  Colors.white,
                ),
              )
                  : Icon(
                isEdit
                    ? Icons
                    .save_outlined
                    : Icons
                    .person_add_outlined,
              ),
              label: Text(
                isEdit
                    ? 'ذخیره تغییرات'
                    : 'ثبت مستاجر جدید',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // -------------------------------------------------
          // Cancel
          // -------------------------------------------------

          OutlinedButton(
            onPressed:
            _isSaving
                ? null
                : isEdit
                ? _cancelEdit
                : _cancelAdd,
            child:
            const Text('انصراف'),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}