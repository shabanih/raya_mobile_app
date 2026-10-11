
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

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

  final ManagerUnitService _unitService = ManagerUnitService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _nationalCodeController = TextEditingController();
  final _peopleCountController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _contractNumberController = TextEditingController();
  final _estateNameController = TextEditingController();
  final _detailsController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _hasRenter = false;
  bool _isAddingNew = false;
  bool _isEditing = false;
  bool _renterIsActive = true;

  String? _errorMessage;

  Map<String, dynamic>? _unit;
  Map<String, dynamic>? _lastKnownRenter;
  int? _renterId;

  @override
  void initState() {
    super.initState();
    _loadUnit();
  }

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
  // Helpers
  // =========================================================

  Map<String, dynamic>? _asMap(dynamic value) {
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
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  int? _extractRenterId(Map<String, dynamic> renter) {
    for (final value in [
      renter['id'],
      renter['renter_id'],
      renter['pk'],
    ]) {
      if (value is int) return value;
      if (value != null) {
        final parsed = int.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  bool _parseBool(dynamic value, {bool fallback = true}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value.toString().trim().toLowerCase();

    if (['true', '1', 'yes', 'active'].contains(text)) {
      return true;
    }
    if (['false', '0', 'no', 'inactive'].contains(text)) {
      return false;
    }

    return fallback;
  }

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
        .replaceAll('۹', '9')
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');
  }

  String _toPersianDigits(dynamic value) {
    if (value == null) return '';

    return value.toString()
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

  String _unitNumber() {
    return _toPersianDigits(
      _unit?['unit'] ?? _unit?['unit_number'] ?? '-',
    );
  }

  // =========================================================
  // Shamsi calendar
  // =========================================================

  Jalali? _parseShamsiDate(dynamic value) {
    if (value == null) return null;

    final text = _normalizeDigits(
      value.toString().trim(),
    ).replaceAll('/', '-');

    if (text.isEmpty) return null;

    // تاریخ شمسی
    final match = RegExp(
      r'^(13|14|15)\d{2}-\d{1,2}-\d{1,2}',
    ).firstMatch(text);

    if (match != null) {
      final parts = text.split('-');

      if (parts.length >= 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);

        if (year != null && month != null && day != null) {
          try {
            final date = Jalali(year, month, day);

            if (month >= 1 &&
                month <= 12 &&
                day >= 1 &&
                day <= date.monthLength) {
              return date;
            }
          } catch (_) {}
        }
      }
    }

    // تاریخ میلادی دریافتی از API
    final dateTime = DateTime.tryParse(text);

    if (dateTime != null) {
      return Jalali.fromDateTime(dateTime.toLocal());
    }

    return null;
  }

  String _formatShamsiDate(dynamic value) {
    final date = _parseShamsiDate(value);
    if (date == null) return '';

    final formatted =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    return _toPersianDigits(formatted);
  }

  Future<void> _selectShamsiDate({
    required TextEditingController controller,
    required String title,
  }) async {
    FocusScope.of(context).unfocus();

    final initialDate =
        _parseShamsiDate(controller.text) ?? Jalali.now();

    final result = await showDialog<Jalali>(
      context: context,
      builder: (_) => _CompactRenterShamsiDatePicker(
        initialDate: initialDate,
        title: title,
      ),
    );

    if (result == null || !mounted) return;

    final formatted =
        '${result.year.toString().padLeft(4, '0')}-'
        '${result.month.toString().padLeft(2, '0')}-'
        '${result.day.toString().padLeft(2, '0')}';

    setState(() {
      controller.text = _toPersianDigits(formatted);
    });
  }

  Widget _datePickerField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool requiredDate = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: FormField<String>(
        validator: (_) {
          if (requiredDate && controller.text.trim().isEmpty) {
            return '$label را انتخاب کنید';
          }
          return null;
        },
        builder: (field) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () async {
                  await _selectShamsiDate(
                    controller: controller,
                    title: label,
                  );

                  field.didChange(controller.text);
                  field.validate();
                },
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: label,
                    prefixIcon: Icon(icon, color: primaryColor),
                    suffixIcon: const Icon(
                      Icons.calendar_month_outlined,
                      color: primaryColor,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    errorText: field.errorText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      controller.text.trim().isEmpty
                          ? 'انتخاب تاریخ شمسی'
                          : controller.text,
                      style: TextStyle(
                        color: controller.text.trim().isEmpty
                            ? Colors.grey
                            : const Color(0xff263238),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              if (!requiredDate &&
                  controller.text.trim().isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        controller.clear();
                        field.didChange('');
                        field.validate();
                      });
                    },
                    icon: const Icon(Icons.clear, size: 17),
                    label: const Text('پاک کردن تاریخ'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // Load unit and renter
  // =========================================================

  Future<void> _loadUnit() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _isAddingNew = false;
        _isEditing = false;
      });
    }

    // نگهداری اطلاعات قبلی برای جلوگیری از محو شدن
    // اطلاعات مستأجر در صورت حذف‌شدن از پاسخ API.
    final previousRenter = _currentRenterSnapshot();

    try {
      final unit = await _unitService.getUnit(widget.unitId);

      if (!mounted) return;

      _unit = unit;
      _clearForm();

      dynamic renterValue = unit['active_renter'];
      renterValue ??= unit['renter'];

      var renter = _asMap(renterValue);

      if (renter != null && _renterHasInformation(renter)) {
        _lastKnownRenter = Map<String, dynamic>.from(renter);
      } else if (previousRenter != null &&
          _renterHasInformation(previousRenter)) {
        renter = previousRenter;
        _lastKnownRenter = Map<String, dynamic>.from(previousRenter);
      } else if (_lastKnownRenter != null) {
        renter = Map<String, dynamic>.from(_lastKnownRenter!);
      }

      if (renter != null && _renterHasInformation(renter)) {
        _hasRenter = true;
        _fillRenter(renter);
      } else {
        _hasRenter = false;
        _renterIsActive = true;
      }

      if (_peopleCountController.text.trim().isEmpty) {
        _peopleCountController.text = '۱';
      }

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

  bool _renterHasInformation(Map<String, dynamic> renter) {
    final name = _firstString(
      renter,
      ['renter_name', 'name'],
    );
    final mobile = _firstString(
      renter,
      ['renter_mobile', 'mobile'],
    );
    return name.isNotEmpty || mobile.isNotEmpty;
  }

  Map<String, dynamic>? _currentRenterSnapshot() {
    if (!_hasRenter && _nameController.text.trim().isEmpty) {
      return _lastKnownRenter;
    }

    return {
      'id': _renterId,
      'renter_name': _nameController.text.trim(),
      'renter_mobile': _normalizeDigits(_mobileController.text.trim()),
      'renter_national_code':
      _normalizeDigits(_nationalCodeController.text.trim()),
      'renter_people_count':
      _normalizeDigits(_peopleCountController.text.trim()),
      'start_date': _normalizeDigits(_startDateController.text.trim()),
      'end_date': _normalizeDigits(_endDateController.text.trim()),
      'contract_number': _contractNumberController.text.trim(),
      'estate_name': _estateNameController.text.trim(),
      'renter_details': _detailsController.text.trim(),
      'renter_is_active': _renterIsActive,
    };
  }

  void _fillRenter(Map<String, dynamic> renter) {
    _renterId = _extractRenterId(renter);

    _nameController.text = _firstString(
      renter,
      ['renter_name', 'name'],
    );

    _mobileController.text = _toPersianDigits(
      _firstString(renter, ['renter_mobile', 'mobile']),
    );

    _nationalCodeController.text = _toPersianDigits(
      _firstString(
        renter,
        ['renter_national_code', 'national_code'],
      ),
    );

    _peopleCountController.text = _toPersianDigits(
      _firstString(
        renter,
        ['renter_people_count', 'people_count'],
      ),
    );

    _startDateController.text = _formatShamsiDate(
      renter['start_date'] ?? renter['renter_start_date'],
    );

    _endDateController.text = _formatShamsiDate(
      renter['end_date'] ?? renter['renter_end_date'],
    );

    _contractNumberController.text = _firstString(
      renter,
      ['contract_number'],
    );

    _estateNameController.text = _firstString(
      renter,
      ['estate_name'],
    );

    _detailsController.text = _firstString(
      renter,
      ['renter_details', 'details'],
    );

    _renterIsActive = _parseBool(
      renter['renter_is_active'] ??
          renter['is_active'] ??
          renter['active'],
    );

    _lastKnownRenter = Map<String, dynamic>.from(renter);
  }

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

  void _restoreCurrentRenter() {
    _clearForm();

    final renter = _lastKnownRenter;
    if (renter != null) {
      _fillRenter(renter);
    }

    if (_peopleCountController.text.trim().isEmpty) {
      _peopleCountController.text = '۱';
    }
  }

  // =========================================================
  // Edit / Add / Cancel
  // =========================================================

  void _startEditRenter() {
    if (!_hasRenter) return;

    if (_renterId == null) {
      _showError(
        'شناسه مستأجر دریافت نشد. لطفاً اطلاعات واحد را بازخوانی کنید.',
      );
      return;
    }

    setState(() {
      _isEditing = true;
      _isAddingNew = false;
    });
  }

  void _startAddNewRenter() {
    setState(() {
      _isAddingNew = true;
      _isEditing = false;
      _clearForm();
      _peopleCountController.text = '۱';
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _isAddingNew = false;
      _restoreCurrentRenter();
    });
  }

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
  // Renter data
  // =========================================================

  Map<String, dynamic> _renterData() {
    final peopleCount = int.tryParse(
      _normalizeDigits(_peopleCountController.text.trim()),
    ) ??
        1;

    return <String, dynamic>{
      'renter_name': _nameController.text.trim(),
      'renter_mobile':
      _normalizeDigits(_mobileController.text.trim()),
      'renter_national_code':
      _normalizeDigits(_nationalCodeController.text.trim()),
      'renter_people_count': peopleCount,
      'start_date':
      _normalizeDigits(_startDateController.text.trim()),
      'end_date':
      _normalizeDigits(_endDateController.text.trim()),
      'contract_number': _contractNumberController.text.trim(),
      'estate_name': _estateNameController.text.trim(),
      'renter_details': _detailsController.text.trim(),
      'renter_is_active': true,
    };
  }

  // =========================================================
  // Save
  // =========================================================

  Future<void> _saveRenter() async {
    if (!_isAddingNew && !_isEditing) return;

    if (!_formKey.currentState!.validate()) return;
    if (_isSaving || _isDeleting) return;

    if (_isEditing && _renterId == null) {
      _showError('شناسه مستأجر مشخص نیست. دوباره وارد صفحه شوید.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = _renterData();

      if (_isEditing) {
        await _unitService.updateRenter(
          widget.unitId,
          _renterId!,
          data,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('اطلاعات مستأجر با موفقیت ویرایش شد.'),
            backgroundColor: primaryColor,
          ),
        );
      } else if (_isAddingNew) {
        await _unitService.createRenter(widget.unitId, data);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('مستأجر جدید با موفقیت ثبت شد.'),
            backgroundColor: primaryColor,
          ),
        );
      }

      if (!mounted) return;

      // حفظ اطلاعات تازه تا در صورت حذف مستأجر غیرفعال از API
      // اطلاعات صفحه فوراً از دست نرود.
      _lastKnownRenter = {
        ...data,
        if (_renterId != null) 'id': _renterId,
      };

      await _loadUnit();
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // =========================================================
  // Deactivate renter
  // =========================================================

  Future<void> _deleteRenter() async {
    if (!_hasRenter ||
        _renterId == null ||
        _isAddingNew ||
        _isEditing) {
      return;
    }

    if (_isSaving || _isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('غیرفعال کردن مستأجر'),
            content: const Text(
              'آیا از غیرفعال کردن مستأجر فعلی این واحد اطمینان دارید؟\n\n'
                  'اطلاعات و سابقه سکونت مستأجر حذف نخواهد شد.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('انصراف'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('غیرفعال کردن'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    final snapshot = _currentRenterSnapshot();

    setState(() => _isDeleting = true);

    try {
      await _unitService.deleteRenter(
        widget.unitId,
        _renterId!,
      );

      if (!mounted) return;

      // اطلاعات مستأجر را در همین صفحه نگه می‌داریم.
      if (snapshot != null) {
        _lastKnownRenter = {
          ...snapshot,
          'renter_is_active': false,
        };
      }

      setState(() {
        _hasRenter = true;
        _renterIsActive = false;
        _isAddingNew = false;
        _isEditing = false;

        if (_lastKnownRenter != null) {
          _fillRenter(_lastKnownRenter!);
          _renterIsActive = false;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'مستأجر غیرفعال شد؛ اطلاعات او همچنان نمایش داده می‌شود.',
          ),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  // =========================================================
  // Reactivate renter
  // =========================================================

  Future<void> _activateRenter() async {
    if (!_hasRenter || _renterId == null) {
      _showError(
        'شناسه مستأجر در دسترس نیست؛ امکان فعال‌سازی وجود ندارد.',
      );
      return;
    }

    if (_isSaving || _isDeleting) return;

    setState(() => _isSaving = true);

    try {
      final data = _renterData();
      data['renter_is_active'] = true;

      await _unitService.updateRenter(
        widget.unitId,
        _renterId!,
        data,
      );

      if (!mounted) return;

      _renterIsActive = true;
      _lastKnownRenter = {
        ...data,
        'id': _renterId,
        'renter_is_active': true,
      };

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('مستأجر با موفقیت فعال شد.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // =========================================================
  // Error
  // =========================================================

  String _cleanError(dynamic error) {
    var message = error.toString();

    if (message.startsWith('Exception: ')) {
      message = message.substring('Exception: '.length);
    }

    return message.trim().isEmpty
        ? 'خطایی رخ داده است.'
        : message;
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
  // Text field
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
      padding: const EdgeInsets.only(bottom: 13),
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
          prefixIcon: Icon(icon, color: primaryColor),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
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
  // Header
  // =========================================================

  Widget _buildHeader() {
    final title = _isAddingNew
        ? 'افزودن مستأجر جدید'
        : _isEditing
        ? 'ویرایش مستأجر'
        : _hasRenter
        ? 'مستأجر ثبت‌شده'
        : 'افزودن مستأجر';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
  // Current renter info
  // =========================================================

  Widget _buildCurrentRenterInfo() {
    if (!_hasRenter || _isAddingNew || _isEditing) {
      return const SizedBox.shrink();
    }

    final statusColor =
    _renterIsActive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _renterIsActive
              ? Colors.grey.shade300
              : Colors.red.withOpacity(0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _renterIsActive
                    ? Icons.verified_user_outlined
                    : Icons.block_outlined,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _renterIsActive
                      ? 'مستأجر فعال واحد'
                      : 'مستأجر غیرفعال',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _renterIsActive ? 'فعال' : 'غیرفعال',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow('نام', _nameController.text),
          _infoRow('موبایل', _mobileController.text),
          _infoRow('کد ملی', _nationalCodeController.text),
          _infoRow('تعداد نفرات', _peopleCountController.text),
          _infoRow('شروع سکونت', _startDateController.text),
          if (_endDateController.text.trim().isNotEmpty)
            _infoRow('پایان سکونت', _endDateController.text),
          if (_contractNumberController.text.trim().isNotEmpty)
            _infoRow('شماره قرارداد', _contractNumberController.text),
          if (_estateNameController.text.trim().isNotEmpty)
            _infoRow('نام بنگاه', _estateNameController.text),
          if (_detailsController.text.trim().isNotEmpty)
            _infoRow('توضیحات', _detailsController.text),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Error screen
  // =========================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 15),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              onPressed: _loadUnit,
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final appBarTitle = _isAddingNew
        ? 'افزودن مستأجر جدید'
        : _isEditing
        ? 'ویرایش مستأجر'
        : 'مدیریت مستأجر';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF7F9FA),
        appBar: AppBar(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            appBarTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
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
  // Form
  // =========================================================

  Widget _buildForm() {
    if (_hasRenter && !_isAddingNew && !_isEditing) {
      return ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _buildHeader(),
          const SizedBox(height: 18),
          _buildCurrentRenterInfo(),
          const SizedBox(height: 14),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _startEditRenter,
              icon: const Icon(Icons.edit_outlined),
              label: const Text(
                'ویرایش اطلاعات مستأجر',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: const BorderSide(color: primaryColor),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _startAddNewRenter,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('افزودن مستأجر جدید'),
          ),
          const SizedBox(height: 10),

          if (_renterIsActive)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isDeleting ? null : _deleteRenter,
              icon: _isDeleting
                  ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.red,
                ),
              )
                  : const Icon(Icons.block_outlined),
              label: const Text('غیرفعال کردن مستأجر'),
            )
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isSaving ? null : _activateRenter,
              icon: _isSaving
                  ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('فعال کردن مستأجر'),
            ),

          const SizedBox(height: 30),
        ],
      );
    }

    final isEdit = _isEditing;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _buildHeader(),
          const SizedBox(height: 20),

          if (isEdit)
            _messageBox(
              icon: Icons.edit_outlined,
              color: primaryColor,
              text:
              'اطلاعات مستأجر فعلی را ویرایش می‌کنید. با ذخیره، همان رکورد مستأجر به‌روزرسانی می‌شود.',
            ),

          if (_hasRenter && _isAddingNew)
            _messageBox(
              icon: Icons.info_outline,
              color: Colors.orange,
              text:
              'با ثبت مستأجر جدید، مستأجر فعال قبلی غیرفعال می‌شود و سابقه سکونت او باید در Backend حفظ شود.',
            ),

          Text(
            isEdit ? 'ویرایش اطلاعات مستأجر' : 'اطلاعات مستأجر جدید',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          _textField(
            controller: _nameController,
            label: 'نام و نام خانوادگی',
            icon: Icons.person_outline,
            hint: 'نام مستأجر را وارد کنید',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'نام مستأجر را وارد کنید';
              }
              return null;
            },
          ),

          _textField(
            controller: _mobileController,
            label: 'شماره موبایل',
            icon: Icons.phone_outlined,
            hint: 'مثلاً 09121234567',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'شماره موبایل را وارد کنید';
              }

              final mobile = _normalizeDigits(value.trim());

              if (mobile.length != 11 || !mobile.startsWith('09')) {
                return 'شماره موبایل معتبر نیست';
              }

              return null;
            },
          ),

          _textField(
            controller: _nationalCodeController,
            label: 'کد ملی',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
          ),

          _textField(
            controller: _peopleCountController,
            label: 'تعداد نفرات',
            icon: Icons.people_outline,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'تعداد نفرات را وارد کنید';
              }

              final count = int.tryParse(
                _normalizeDigits(value.trim()),
              );

              if (count == null || count < 0) {
                return 'تعداد نفرات معتبر نیست';
              }

              return null;
            },
          ),

          const SizedBox(height: 4),
          const Text(
            'مدت سکونت و قرارداد',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),

          // تقویم شمسی تاریخ شروع
          _datePickerField(
            controller: _startDateController,
            label: 'تاریخ شروع سکونت',
            icon: Icons.calendar_today_outlined,
            requiredDate: true,
          ),

          // تقویم شمسی تاریخ پایان
          _datePickerField(
            controller: _endDateController,
            label: 'تاریخ پایان سکونت',
            icon: Icons.event_outlined,
          ),

          _textField(
            controller: _contractNumberController,
            label: 'شماره قرارداد',
            icon: Icons.description_outlined,
          ),

          _textField(
            controller: _estateNameController,
            label: 'نام بنگاه',
            icon: Icons.business_outlined,
          ),

          _textField(
            controller: _detailsController,
            label: 'توضیحات',
            icon: Icons.notes_outlined,
            hint: 'توضیحات مربوط به مستأجر',
            maxLines: 4,
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed:
              _isSaving || _isDeleting ? null : _saveRenter,
              icon: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Icon(
                isEdit
                    ? Icons.save_outlined
                    : Icons.person_add_outlined,
              ),
              label: Text(
                isEdit ? 'ذخیره تغییرات' : 'ثبت مستأجر جدید',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          OutlinedButton(
            onPressed: _isSaving
                ? null
                : isEdit
                ? _cancelEdit
                : _cancelAdd,
            child: const Text('انصراف'),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _messageBox({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// Compact Shamsi Date Picker
// انتخاب سال، ماه و روز شمسی
// =============================================================

class _CompactRenterShamsiDatePicker extends StatefulWidget {
  final Jalali initialDate;
  final String title;

  const _CompactRenterShamsiDatePicker({
    required this.initialDate,
    required this.title,
  });

  @override
  State<_CompactRenterShamsiDatePicker> createState() =>
      _CompactRenterShamsiDatePickerState();
}

class _CompactRenterShamsiDatePickerState
    extends State<_CompactRenterShamsiDatePicker> {
  static const Color primaryColor = Color(0xff00ACC1);

  late int _year;
  late int _month;
  late int _day;

  static const List<String> _monthNames = [
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

  @override
  void initState() {
    super.initState();

    final now = Jalali.now();

    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
    _day = widget.initialDate.day;

    if (_year < now.year - 20 || _year > now.year + 20) {
      _year = now.year;
    }

    if (_month < 1 || _month > 12) {
      _month = now.month;
    }

    _fixDay();
  }

  int get _monthLength => Jalali(_year, _month, 1).monthLength;

  void _fixDay() {
    if (_day < 1) _day = 1;
    if (_day > _monthLength) _day = _monthLength;
  }

  String _persianDigits(dynamic value) {
    return value.toString()
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

  @override
  Widget build(BuildContext context) {
    final now = Jalali.now();

    final years = List<int>.generate(
      41,
          (index) => now.year - 20 + index,
    );

    final days = List<int>.generate(
      _monthLength,
          (index) => index + 1,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        title: Text(
          widget.title,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 420,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  value: _day,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'روز',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  items: days.map((day) {
                    return DropdownMenuItem<int>(
                      value: day,
                      child: Text(
                        _persianDigits(day),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _day = value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<int>(
                  value: _month,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'ماه',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  items: List.generate(12, (index) {
                    final month = index + 1;

                    return DropdownMenuItem<int>(
                      value: month,
                      child: Text(
                        _monthNames[index],
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _month = value;
                      _fixDay();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<int>(
                  value: _year,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'سال',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  items: years.map((year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(
                        _persianDigits(year),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _year = value;
                      _fixDay();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'انصراف',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
            onPressed: () {
              Navigator.pop(
                context,
                Jalali(_year, _month, _day),
              );
            },
            child: const Text(
              'تأیید',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
