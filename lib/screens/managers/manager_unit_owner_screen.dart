import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_unit_service.dart';

class ManagerUnitOwnerScreen extends StatefulWidget {
  final int unitId;

  const ManagerUnitOwnerScreen({
    super.key,
    required this.unitId,
  });

  @override
  State<ManagerUnitOwnerScreen> createState() =>
      _ManagerUnitOwnerScreenState();
}

class _ManagerUnitOwnerScreenState
    extends State<ManagerUnitOwnerScreen> {
  static const Color primaryColor = Color(0xff00ACC1);
  static const Color unitColor = Color(0xff610DB5);

  final ManagerUnitService _unitService = ManagerUnitService();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _mobileController =
  TextEditingController();

  final TextEditingController _nationalCodeController =
  TextEditingController();

  final TextEditingController _purchaseDateController =
  TextEditingController();

  final TextEditingController _peopleCountController =
  TextEditingController();

  final TextEditingController _detailsController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final TextEditingController _passwordConfirmController =
  TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool _hasOwner = false;
  bool _isAddingNew = false;
  bool _isEditing = false;

  bool _ownerIsActive = true;

  bool _showPassword = false;
  bool _showPasswordConfirm = false;

  String? _errorMessage;

  Map<String, dynamic>? _unit;

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
    _purchaseDateController.dispose();
    _peopleCountController.dispose();
    _detailsController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();

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
        _isAddingNew = false;
        _isEditing = false;
      });
    }

    // ---------------------------------------------------------
    // اطلاعات فعلی مالک را موقتاً نگه می‌داریم.
    // اگر API بعد از غیرفعال شدن مالک را برنگرداند،
    // اطلاعات از بین نرود.
    // ---------------------------------------------------------

    final previousOwner = _currentOwnerSnapshot();

    try {
      final unit = await _unitService.getUnit(widget.unitId);

      if (!mounted) return;

      _unit = unit;

      _clearForm();

      final owner = _extractOwner(unit);

      if (owner != null) {
        _hasOwner = _ownerHasInformation(owner);

        if (_hasOwner) {
          _fillOwner(owner);
        }
      } else if (previousOwner != null &&
          _ownerHasInformation(previousOwner)) {
        // -----------------------------------------------------
        // اگر Backend مالک غیرفعال را از خروجی حذف کرده باشد،
        // اطلاعات قبلی را نگه می‌داریم.
        // -----------------------------------------------------

        _hasOwner = true;

        _fillOwner(previousOwner);
      } else {
        _hasOwner = false;
        _ownerIsActive = _unitIsActive(unit);
      }

      if (_peopleCountController.text.trim().isEmpty) {
        _peopleCountController.text = '۱';
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
  // Extract Owner
  // =========================================================

  Map<String, dynamic>? _extractOwner(
      Map<String, dynamic> unit,
      ) {
    final owner = unit['owner'];

    if (owner is Map) {
      return Map<String, dynamic>.from(owner);
    }

    // اگر Backend اطلاعات مالک را مستقیماً در Unit داده باشد.
    if (unit.containsKey('owner_name') ||
        unit.containsKey('owner_mobile') ||
        unit.containsKey('owner_national_code')) {
      return {
        'name': unit['owner_name'],
        'mobile': unit['owner_mobile'],
        'national_code': unit['owner_national_code'],
        'purchase_date': unit['purchase_date'],
        'people_count':
        unit['owner_people_count'] ??
            unit['people_count'],
        'details': unit['owner_details'],
        'is_active':
        unit['is_active'],
      };
    }

    return null;
  }

  // =========================================================
  // Owner Snapshot
  // =========================================================

  Map<String, dynamic>? _currentOwnerSnapshot() {
    if (!_hasOwner &&
        _nameController.text.trim().isEmpty) {
      return null;
    }

    return {
      'name': _nameController.text.trim(),
      'mobile': _normalizeDigits(
        _mobileController.text.trim(),
      ),
      'national_code': _normalizeDigits(
        _nationalCodeController.text.trim(),
      ),
      'purchase_date':
      _purchaseDateController.text.trim(),
      'people_count':
      _normalizeDigits(
        _peopleCountController.text.trim(),
      ),
      'details':
      _detailsController.text.trim(),
      'is_active': _ownerIsActive,
    };
  }

  // =========================================================
  // Owner Has Information
  // =========================================================

  bool _ownerHasInformation(
      Map<String, dynamic> owner,
      ) {
    final name =
        owner['name'] ??
            owner['owner_name'] ??
            '';

    final mobile =
        owner['mobile'] ??
            owner['owner_mobile'] ??
            '';

    final nationalCode =
        owner['national_code'] ??
            owner['owner_national_code'] ??
            '';

    return name.toString().trim().isNotEmpty ||
        mobile.toString().trim().isNotEmpty ||
        nationalCode.toString().trim().isNotEmpty;
  }

  // =========================================================
  // Unit Active
  // =========================================================

  bool _unitIsActive(
      Map<String, dynamic> unit,
      ) {
    return _parseBool(
      unit['is_active'],
      fallback: true,
    );
  }

  // =========================================================
  // Fill Owner
  // =========================================================

  void _fillOwner(
      Map<String, dynamic> owner,
      ) {
    final name =
        owner['name'] ??
            owner['owner_name'] ??
            '';

    final mobile =
        owner['mobile'] ??
            owner['owner_mobile'] ??
            '';

    final nationalCode =
        owner['national_code'] ??
            owner['owner_national_code'] ??
            '';

    final peopleCount =
        owner['people_count'] ??
            owner['owner_people_count'] ??
            1;

    final details =
        owner['details'] ??
            owner['owner_details'] ??
            '';

    _nameController.text =
        name.toString();

    _mobileController.text =
        _toPersianDigits(mobile);

    _nationalCodeController.text =
        _toPersianDigits(nationalCode);

    _peopleCountController.text =
        _toPersianDigits(peopleCount);

    _detailsController.text =
        details.toString();

    _purchaseDateController.text =
        _formatPurchaseDate(
          owner['purchase_date'],
        );

    _ownerIsActive = _parseBool(
      owner['is_active'] ??
          owner['owner_is_active'] ??
          owner['active'] ??
          _unit?['is_active'],
      fallback: true,
    );

    _passwordController.clear();
    _passwordConfirmController.clear();
  }

  // =========================================================
  // Clear
  // =========================================================

  void _clearForm() {
    _nameController.clear();
    _mobileController.clear();
    _nationalCodeController.clear();
    _purchaseDateController.clear();
    _peopleCountController.clear();
    _detailsController.clear();
    _passwordController.clear();
    _passwordConfirmController.clear();

    _ownerIsActive = true;
  }

  // =========================================================
  // Start Edit
  // =========================================================

  void _startEditOwner() {
    if (!_hasOwner) return;

    setState(() {
      _isEditing = true;
      _isAddingNew = false;

      _passwordController.clear();
      _passwordConfirmController.clear();
    });
  }

  // =========================================================
  // Start Add
  // =========================================================

  void _startAddNewOwner() {
    setState(() {
      _isAddingNew = true;
      _isEditing = false;

      _clearForm();

      _peopleCountController.text = '۱';
      _ownerIsActive = true;
    });
  }

  // =========================================================
  // Cancel Edit
  // =========================================================

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _isAddingNew = false;

      _clearForm();

      final owner = _extractOwner(
        _unit ?? {},
      );

      if (owner != null) {
        _hasOwner = true;
        _fillOwner(owner);
      }
    });
  }

  // =========================================================
  // Cancel Add
  // =========================================================

  void _cancelAdd() {
    setState(() {
      _isAddingNew = false;
      _isEditing = false;

      _clearForm();

      final owner = _extractOwner(
        _unit ?? {},
      );

      if (owner != null) {
        _hasOwner = true;
        _fillOwner(owner);
      }
    });
  }

  // =========================================================
  // Digits
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
  // Boolean
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
        text == 'yes' ||
        text == 'active') {
      return true;
    }

    if (text == 'false' ||
        text == '0' ||
        text == 'no' ||
        text == 'inactive') {
      return false;
    }

    return fallback;
  }

  // =========================================================
  // Unit Number
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
  // Parse Purchase Date
  // =========================================================

  Jalali? _parsePurchaseDate(
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

    final normalized =
    _normalizeDigits(text)
        .replaceAll('/', '-');

    final jalaliMatch = RegExp(
      r'^(13|14|15)\d{2}-\d{1,2}-\d{1,2}',
    ).firstMatch(normalized);

    if (jalaliMatch != null) {
      final parts =
      normalized.split('-');

      if (parts.length >= 3) {
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
          } catch (_) {}
        }
      }
    }

    final dateTime =
    DateTime.tryParse(normalized);

    if (dateTime != null) {
      return Jalali.fromDateTime(
        dateTime.toLocal(),
      );
    }

    return null;
  }

  // =========================================================
  // Format Purchase Date
  // =========================================================

  String _formatPurchaseDate(
      dynamic value,
      ) {
    final date =
    _parsePurchaseDate(value);

    if (date == null) {
      return '';
    }

    final text =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    return _toPersianDigits(text);
  }

  // =========================================================
  // Select Purchase Date
  // =========================================================

  Future<void> _selectPurchaseDate() async {
    FocusScope.of(context).unfocus();

    final initialDate =
        _parsePurchaseDate(
          _purchaseDateController.text,
        ) ??
            Jalali.now();

    final result =
    await showDialog<Jalali>(
      context: context,
      builder: (dialogContext) {
        return _CompactShamsiDatePicker(
          initialDate: initialDate,
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    final formatted =
        '${result.year.toString().padLeft(4, '0')}-'
        '${result.month.toString().padLeft(2, '0')}-'
        '${result.day.toString().padLeft(2, '0')}';

    setState(() {
      _purchaseDateController.text =
          _toPersianDigits(formatted);
    });
  }

  // =========================================================
  // Owner Data
  // =========================================================

  Map<String, dynamic> _ownerData() {
    final peopleCount =
        int.tryParse(
          _normalizeDigits(
            _peopleCountController.text.trim(),
          ),
        ) ??
            1;

    final data =
    <String, dynamic>{
      'owner_name':
      _nameController.text.trim(),

      'owner_mobile':
      _normalizeDigits(
        _mobileController.text.trim(),
      ),

      'owner_national_code':
      _normalizeDigits(
        _nationalCodeController.text.trim(),
      ),

      'owner_people_count':
      peopleCount,

      'owner_details':
      _detailsController.text.trim(),

      // وضعیت مالک و واحد
      'is_active':
      _ownerIsActive,
    };

    final purchaseDate =
    _purchaseDateController.text.trim();

    if (purchaseDate.isNotEmpty) {
      data['purchase_date'] =
          _normalizeDigits(purchaseDate);
    }

    final password =
        _passwordController.text;

    final passwordConfirm =
        _passwordConfirmController.text;

    if (password.isNotEmpty) {
      data['password'] =
          password;

      data['password_confirm'] =
          passwordConfirm;
    }

    return data;
  }

  // =========================================================
  // Save
  // =========================================================

  Future<void> _saveOwner() async {
    if (!_isAddingNew &&
        !_isEditing) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSaving || _isDeleting) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final data = _ownerData();

      if (_isEditing) {
        await _unitService.updateOwner(
          widget.unitId,
          data,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'اطلاعات مالک با موفقیت ویرایش شد.',
            ),
            backgroundColor: primaryColor,
          ),
        );
      } else if (_isAddingNew) {
        await _unitService.createOwner(
          widget.unitId,
          data,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'مالک جدید با موفقیت ثبت شد.',
            ),
            backgroundColor: primaryColor,
          ),
        );
      }

      // -------------------------------------------------------
      // قبلاً Navigator.pop داشتیم.
      // الان صفحه را نمی‌بندیم و اطلاعات جدید را می‌گیریم.
      // -------------------------------------------------------

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
  // Deactivate Owner / Unit
  // =========================================================

  Future<void> _deleteOwner() async {
    if (!_hasOwner ||
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
              'غیرفعال کردن مالک و واحد',
            ),
            content: const Text(
              'با غیرفعال کردن مالک، واحد نیز غیرفعال می‌شود.\n\n'
                  'اطلاعات مالک حذف نمی‌شود و همچنان '
                  'در جزئیات قابل مشاهده خواهد بود.\n\n'
                  'آیا ادامه می‌دهید؟',
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
                style:
                FilledButton.styleFrom(
                  backgroundColor:
                  Colors.red,
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

    // اطلاعات مالک را قبل از درخواست نگه می‌داریم.
    final ownerSnapshot =
    _currentOwnerSnapshot();

    setState(() {
      _isDeleting = true;
    });

    try {
      await _unitService.deleteOwner(
        widget.unitId,
      );

      if (!mounted) return;

      // -------------------------------------------------------
      // مهم:
      // صفحه بسته نمی‌شود.
      // مالک همچنان نمایش داده می‌شود.
      // -------------------------------------------------------

      setState(() {
        _hasOwner = true;
        _ownerIsActive = false;

        if (ownerSnapshot != null) {
          _fillOwner({
            ...ownerSnapshot,
            'is_active': false,
          });
        }

        // وضعیت واحد نیز غیرفعال شده است.
        if (_unit != null) {
          _unit = {
            ..._unit!,
            'is_active': false,
            'owner': {
              ...(ownerSnapshot ?? {}),
              'is_active': false,
            },
          };
        }
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'مالک و واحد با موفقیت غیرفعال شدند. اطلاعات مالک حذف نشده است.',
          ),
          backgroundColor: Colors.red,
        ),
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
  // Activate Owner / Unit
  // =========================================================

  Future<void> _activateOwner() async {
    if (!_hasOwner ||
        _isSaving ||
        _isDeleting) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final data =
      _ownerData();

      data['is_active'] = true;

      await _unitService.updateOwner(
        widget.unitId,
        data,
      );

      if (!mounted) return;

      setState(() {
        _ownerIsActive = true;

        if (_unit != null) {
          _unit = {
            ..._unit!,
            'is_active': true,
            'owner': {
              ...(_unit!['owner'] is Map
                  ? Map<String, dynamic>.from(
                _unit!['owner'],
              )
                  : <String, dynamic>{}),
              'is_active': true,
            },
          };
        }
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'مالک و واحد با موفقیت فعال شدند.',
          ),
          backgroundColor: Colors.green,
        ),
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
  // Error
  // =========================================================

  String _cleanError(dynamic error) {
    String message =
    error.toString();

    if (message.startsWith(
        'Exception: ')) {
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

  void _showError(dynamic error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
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
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 13,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines:
        obscureText ? 1 : maxLines,
        obscureText: obscureText,
        textDirection:
        TextDirection.rtl,
        textAlign: TextAlign.right,
        validator: validator,
        decoration:
        InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: primaryColor,
          ),
          suffixIcon:
          suffixIcon,
          filled: true,
          fillColor: Colors.white,
          border:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              12,
            ),
            borderSide: BorderSide(
              color:
              Colors.grey.shade300,
            ),
          ),
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              12,
            ),
            borderSide: BorderSide(
              color:
              Colors.grey.shade300,
            ),
          ),
          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(
              12,
            ),
            borderSide:
            const BorderSide(
              color: primaryColor,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // Owner Status
  // =========================================================

  Widget _buildOwnerStatus() {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 13,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration:
      BoxDecoration(
        color: _ownerIsActive
            ? Colors.green
            .withOpacity(0.08)
            : Colors.red
            .withOpacity(0.08),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: _ownerIsActive
              ? Colors.green
              .withOpacity(0.25)
              : Colors.red
              .withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _ownerIsActive
                ? Icons
                .check_circle_outline
                : Icons.block_outlined,
            color: _ownerIsActive
                ? Colors.green
                : Colors.red,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  'وضعیت مالک و واحد',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.bold,
                    color: _ownerIsActive
                        ? Colors.green
                        .shade700
                        : Colors.red
                        .shade700,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  _ownerIsActive
                      ? 'مالک و واحد فعال هستند'
                      : 'مالک و واحد غیرفعال هستند',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _ownerIsActive,
            activeColor: Colors.green,
            onChanged: (value) {
              setState(() {
                _ownerIsActive =
                    value;
              });
            },
          ),
        ],
      ),
    );
  }

  // =========================================================
  // Header
  // =========================================================

  Widget _buildHeader() {
    String title;

    if (_isAddingNew) {
      title =
      'افزودن مالک جدید';
    } else if (_isEditing) {
      title =
      'ویرایش مالک';
    } else if (_hasOwner) {
      title =
      'مالک فعلی';
    } else {
      title =
      'افزودن مالک';
    }

    return Container(
      padding:
      const EdgeInsets.all(
        18,
      ),
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
            width: 55,
            height: 55,
            decoration:
            BoxDecoration(
              color: Colors.white
                  .withOpacity(0.18),
              borderRadius:
              BorderRadius.circular(
                14,
              ),
            ),
            child: Icon(
              _isAddingNew
                  ? Icons
                  .person_add_outlined
                  : _isEditing
                  ? Icons
                  .edit_outlined
                  : Icons
                  .person_outline,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(
            width: 14,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  title,
                  style:
                  const TextStyle(
                    color:
                    Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  'واحد ${_unitNumber()}',
                  style:
                  const TextStyle(
                    color:
                    Colors.white,
                    fontSize: 21,
                    fontWeight:
                    FontWeight.bold,
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
  // Current Owner
  // =========================================================

  Widget _buildCurrentOwnerInfo() {
    if (!_hasOwner ||
        _isAddingNew ||
        _isEditing) {
      return const SizedBox();
    }

    return Container(
      padding:
      const EdgeInsets.all(
        16,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color:
          _ownerIsActive
              ? Colors.grey.shade300
              : Colors.red
              .withOpacity(0.35),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _ownerIsActive
                    ? Icons
                    .verified_user_outlined
                    : Icons
                    .block_outlined,
                color: _ownerIsActive
                    ? Colors.green
                    : Colors.red,
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Text(
                  _ownerIsActive
                      ? 'مالک فعال واحد'
                      : 'مالک غیرفعال',
                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration:
                BoxDecoration(
                  color:
                  _ownerIsActive
                      ? Colors.green
                      .withOpacity(
                    0.1,
                  )
                      : Colors.red
                      .withOpacity(
                    0.1,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    20,
                  ),
                ),
                child: Text(
                  _ownerIsActive
                      ? 'فعال'
                      : 'غیرفعال',
                  style: TextStyle(
                    color:
                    _ownerIsActive
                        ? Colors.green
                        : Colors.red,
                    fontSize: 12,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          _infoRow(
            'نام',
            _nameController.text,
          ),

          _infoRow(
            'موبایل',
            _toPersianDigits(
              _mobileController.text,
            ),
          ),

          _infoRow(
            'کد ملی',
            _toPersianDigits(
              _nationalCodeController
                  .text,
            ),
          ),

          _infoRow(
            'تعداد نفرات',
            _toPersianDigits(
              _peopleCountController
                  .text,
            ),
          ),

          if (_purchaseDateController
              .text
              .trim()
              .isNotEmpty)
            _infoRow(
              'تاریخ خرید',
              _purchaseDateController
                  .text,
            ),

          if (_detailsController
              .text
              .trim()
              .isNotEmpty)
            _infoRow(
              'توضیحات',
              _detailsController
                  .text,
            ),
        ],
      ),
    );
  }

  // =========================================================
  // Info Row
  // =========================================================

  Widget _infoRow(
      String title,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 95,
            child: Text(
              title,
              style: TextStyle(
                color:
                Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty
                  ? '-'
                  : value,
              style:
              const TextStyle(
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
  // Build
  // =========================================================

  @override
  Widget build(
      BuildContext context) {
    String appBarTitle;

    if (_isAddingNew) {
      appBarTitle =
      'افزودن مالک جدید';
    } else if (_isEditing) {
      appBarTitle =
      'ویرایش مالک';
    } else {
      appBarTitle =
      'مدیریت مالک';
    }

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
            appBarTitle,
            style:
            const TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),
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
              height: 15,
            ),
            Text(
              _errorMessage!,
              textAlign:
              TextAlign.center,
            ),
            const SizedBox(
              height: 15,
            ),
            FilledButton.icon(
              style:
              FilledButton.styleFrom(
                backgroundColor:
                primaryColor,
              ),
              onPressed:
              _loadUnit,
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
    );
  }

  // =========================================================
  // Form
  // =========================================================

  Widget _buildForm() {
    if (_hasOwner &&
        !_isAddingNew &&
        !_isEditing) {
      return ListView(
        padding:
        const EdgeInsets.all(
          14,
        ),
        children: [
          _buildHeader(),

          const SizedBox(
            height: 18,
          ),

          _buildCurrentOwnerInfo(),

          const SizedBox(
            height: 14,
          ),

          // ---------------------------------------------------
          // Edit
          // ---------------------------------------------------

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
              _startEditOwner,
              icon: const Icon(
                Icons.edit_outlined,
              ),
              label: const Text(
                'ویرایش اطلاعات مالک',
                style:
                TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          // ---------------------------------------------------
          // Add New Owner
          // ---------------------------------------------------

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
                  color:
                  primaryColor,
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
              _startAddNewOwner,
              icon: const Icon(
                Icons
                    .person_add_alt_1,
              ),
              label: const Text(
                'افزودن مالک جدید',
                style:
                TextStyle(
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          // ---------------------------------------------------
          // Activate / Deactivate
          // ---------------------------------------------------

          if (_ownerIsActive)
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
                    color:
                    Colors.red,
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
                    : _deleteOwner,
                icon: _isDeleting
                    ? const SizedBox(
                  width: 19,
                  height: 19,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                    Colors.red,
                  ),
                )
                    : const Icon(
                  Icons
                      .block_outlined,
                ),
                label: const Text(
                  'غیرفعال کردن مالک و واحد',
                  style:
                  TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                style:
                FilledButton.styleFrom(
                  backgroundColor:
                  Colors.green,
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
                _isSaving
                    ? null
                    : _activateOwner,
                icon: _isSaving
                    ? const SizedBox(
                  width: 19,
                  height: 19,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                    Colors.white,
                  ),
                )
                    : const Icon(
                  Icons
                      .check_circle_outline,
                ),
                label: const Text(
                  'فعال کردن مالک و واحد',
                  style:
                  TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ),

          const SizedBox(
            height: 30,
          ),
        ],
      );
    }

    final isEdit = _isEditing;

    return Form(
      key: _formKey,
      child: ListView(
        padding:
        const EdgeInsets.all(
          14,
        ),
        children: [
          _buildHeader(),

          const SizedBox(
            height: 20,
          ),

          if (isEdit)
            Container(
              padding:
              const EdgeInsets.all(
                12,
              ),
              margin:
              const EdgeInsets.only(
                bottom: 15,
              ),
              decoration:
              BoxDecoration(
                color: primaryColor
                    .withOpacity(
                  0.08,
                ),
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
                border:
                Border.all(
                  color: primaryColor
                      .withOpacity(
                    0.25,
                  ),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    color:
                    primaryColor,
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      'اطلاعات مالک فعلی را ویرایش می‌کنید. اگر رمز عبور را خالی بگذارید، رمز قبلی تغییر نمی‌کند.',
                      style:
                      TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_hasOwner &&
              _isAddingNew)
            Container(
              padding:
              const EdgeInsets.all(
                12,
              ),
              margin:
              const EdgeInsets.only(
                bottom: 15,
              ),
              decoration:
              BoxDecoration(
                color: Colors.orange
                    .withOpacity(
                  0.10,
                ),
                borderRadius:
                BorderRadius.circular(
                  12,
                ),
                border:
                Border.all(
                  color: Colors.orange
                      .withOpacity(
                    0.35,
                  ),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color:
                    Colors.orange,
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      'با ثبت مالک جدید، مالک فعلی غیرفعال شده و سابقه او حفظ می‌شود.',
                      style:
                      TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Text(
            isEdit
                ? 'ویرایش اطلاعات مالک'
                : 'اطلاعات مالک جدید',
            style:
            const TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          _textField(
            controller:
            _nameController,
            label:
            'نام و نام خانوادگی',
            icon:
            Icons.person_outline,
            hint:
            'نام مالک را وارد کنید',
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'نام مالک را وارد کنید';
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
            'مثلاً ۰۹۱۲۱۲۳۴۵۶۷',
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
            hint:
            'مثلاً ۰۰۱۲۳۴۵۶۷۸',
            keyboardType:
            TextInputType.number,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return null;
              }

              final code =
              _normalizeDigits(
                value.trim(),
              );

              if (code.length != 10) {
                return 'کد ملی باید ۱۰ رقم باشد';
              }

              return null;
            },
          ),

          // ===================================================
          // Purchase Date
          // ===================================================

          Padding(
            padding:
            const EdgeInsets.only(
              bottom: 13,
            ),
            child: InkWell(
              onTap:
              _selectPurchaseDate,
              borderRadius:
              BorderRadius.circular(
                13,
              ),
              child: Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration:
                BoxDecoration(
                  color:
                  Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                    13,
                  ),
                  border:
                  Border.all(
                    color:
                    Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .calendar_today_outlined,
                      color:
                      primaryColor,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Expanded(
                      child:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            'تاریخ خرید',
                            style:
                            TextStyle(
                              fontSize:
                              12,
                              color: Colors
                                  .grey
                                  .shade600,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            _purchaseDateController
                                .text
                                .trim()
                                .isNotEmpty
                                ? _purchaseDateController
                                .text
                                : 'انتخاب تاریخ شمسی',
                            style:
                            TextStyle(
                              fontSize:
                              15,
                              fontWeight:
                              FontWeight
                                  .w600,
                              color: _purchaseDateController
                                  .text
                                  .trim()
                                  .isNotEmpty
                                  ? const Color(
                                0xff263238,
                              )
                                  : Colors
                                  .grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_left,
                      color:
                      Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
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

          _buildOwnerStatus(),

          _textField(
            controller:
            _detailsController,
            label:
            'توضیحات',
            icon:
            Icons.notes_outlined,
            hint:
            'توضیحات مربوط به مالک',
            maxLines: 4,
          ),

          const SizedBox(
            height: 4,
          ),

          _textField(
            controller:
            _passwordController,
            label:
            isEdit
                ? 'رمز عبور جدید'
                : 'رمز عبور',
            icon:
            Icons.lock_outline,
            hint:
            isEdit
                ? 'در صورت عدم تغییر خالی بگذارید'
                : 'رمز عبور مالک',
            obscureText:
            !_showPassword,
            suffixIcon:
            IconButton(
              onPressed: () {
                setState(() {
                  _showPassword =
                  !_showPassword;
                });
              },
              icon: Icon(
                _showPassword
                    ? Icons
                    .visibility_off_outlined
                    : Icons
                    .visibility_outlined,
              ),
            ),
            validator: (value) {
              final password =
                  value ?? '';

              if (isEdit &&
                  password.isEmpty) {
                return null;
              }

              if (password.length <
                  6) {
                return 'رمز عبور باید حداقل ۶ کاراکتر باشد';
              }

              return null;
            },
          ),

          _textField(
            controller:
            _passwordConfirmController,
            label:
            'تکرار رمز عبور',
            icon:
            Icons
                .lock_reset_outlined,
            hint:
            'رمز عبور را مجدداً وارد کنید',
            obscureText:
            !_showPasswordConfirm,
            suffixIcon:
            IconButton(
              onPressed: () {
                setState(() {
                  _showPasswordConfirm =
                  !_showPasswordConfirm;
                });
              },
              icon: Icon(
                _showPasswordConfirm
                    ? Icons
                    .visibility_off_outlined
                    : Icons
                    .visibility_outlined,
              ),
            ),
            validator: (value) {
              final password =
                  _passwordController
                      .text;

              final confirm =
                  value ?? '';

              if (password.isEmpty &&
                  confirm.isEmpty) {
                return null;
              }

              if (password !=
                  confirm) {
                return 'رمز عبور و تکرار آن یکسان نیستند';
              }

              return null;
            },
          ),

          const SizedBox(
            height: 8,
          ),

          SizedBox(
            height: 52,
            child:
            FilledButton.icon(
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
                  : _saveOwner,
              icon: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2,
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
                    : 'ثبت مالک جدید',
                style:
                const TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          OutlinedButton(
            onPressed: _isSaving
                ? null
                : isEdit
                ? _cancelEdit
                : _cancelAdd,
            child:
            const Text(
              'انصراف',
            ),
          ),

          const SizedBox(
            height: 30,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Compact Shamsi Date Picker
// فقط سال، ماه و روز
// ============================================================================

class _CompactShamsiDatePicker
    extends StatefulWidget {
  final Jalali initialDate;

  const _CompactShamsiDatePicker({
    required this.initialDate,
  });

  @override
  State<_CompactShamsiDatePicker>
  createState() =>
      _CompactShamsiDatePickerState();
}

class _CompactShamsiDatePickerState
    extends State<
        _CompactShamsiDatePicker> {
  static const Color primaryColor =
  Color(0xff00ACC1);

  late int _year;
  late int _month;
  late int _day;

  static const List<String>
  _monthNames = [
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

    final now =
    Jalali.now();

    _year =
        widget.initialDate.year;

    _month =
        widget.initialDate.month;

    _day =
        widget.initialDate.day;

    if (_year < now.year - 20 ||
        _year > now.year + 20) {
      _year = now.year;
    }

    if (_month < 1 ||
        _month > 12) {
      _month = now.month;
    }

    _fixDay();
  }

  int get _monthLength {
    return Jalali(
      _year,
      _month,
      1,
    ).monthLength;
  }

  void _fixDay() {
    final maxDay =
        _monthLength;

    if (_day < 1) {
      _day = 1;
    }

    if (_day > maxDay) {
      _day = maxDay;
    }
  }

  String _toPersianDigits(
      dynamic value) {
    return value
        .toString()
        .replaceAll(
        '0', '۰')
        .replaceAll(
        '1', '۱')
        .replaceAll(
        '2', '۲')
        .replaceAll(
        '3', '۳')
        .replaceAll(
        '4', '۴')
        .replaceAll(
        '5', '۵')
        .replaceAll(
        '6', '۶')
        .replaceAll(
        '7', '۷')
        .replaceAll(
        '8', '۸')
        .replaceAll(
        '9', '۹');
  }

  @override
  Widget build(
      BuildContext context) {
    final now =
    Jalali.now();

    final years =
    List<int>.generate(
      41,
          (index) =>
      now.year - 20 + index,
    );

    final days =
    List<int>.generate(
      _monthLength,
          (index) =>
      index + 1,
    );

    if (!years.contains(
        _year)) {
      _year = now.year;
      _fixDay();
    }

    if (_month < 1 ||
        _month > 12) {
      _month = now.month;
      _fixDay();
    }

    if (!days.contains(
        _day)) {
      _day = days.last;
    }

    return Directionality(
      textDirection:
      TextDirection.rtl,
      child:
      AlertDialog(
        titlePadding:
        const EdgeInsets
            .fromLTRB(
          20,
          16,
          20,
          8,
        ),
        contentPadding:
        const EdgeInsets
            .fromLTRB(
          16,
          8,
          16,
          8,
        ),
        actionsPadding:
        const EdgeInsets
            .fromLTRB(
          16,
          0,
          16,
          10,
        ),
        title:
        const Text(
          'انتخاب تاریخ خرید',
          textAlign:
          TextAlign.right,
          style:
          TextStyle(
            fontSize: 17,
            fontWeight:
            FontWeight.bold,
          ),
        ),
        content:
        SizedBox(
          width: 420,
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Expanded(
                flex: 2,
                child:
                DropdownButtonFormField<
                    int>(
                  value:
                  _day,
                  isExpanded:
                  true,
                  decoration:
                  const InputDecoration(
                    labelText:
                    'روز',
                    border:
                    OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets
                        .symmetric(
                      horizontal:
                      10,
                      vertical:
                      8,
                    ),
                  ),
                  items: days
                      .map(
                        (day) =>
                        DropdownMenuItem<
                            int>(
                          value:
                          day,
                          child:
                          Text(
                            _toPersianDigits(
                                day),
                            textAlign:
                            TextAlign.center,
                          ),
                        ),
                  )
                      .toList(),
                  onChanged:
                      (value) {
                    if (value ==
                        null) {
                      return;
                    }

                    setState(() {
                      _day =
                          value;
                    });
                  },
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                flex: 3,
                child:
                DropdownButtonFormField<
                    int>(
                  value:
                  _month,
                  isExpanded:
                  true,
                  decoration:
                  const InputDecoration(
                    labelText:
                    'ماه',
                    border:
                    OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets
                        .symmetric(
                      horizontal:
                      10,
                      vertical:
                      8,
                    ),
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
                        child:
                        Text(
                          _monthNames[
                          index],
                          overflow:
                          TextOverflow
                              .ellipsis,
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

                    setState(() {
                      _month =
                          value;
                      _fixDay();
                    });
                  },
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                flex: 3,
                child:
                DropdownButtonFormField<
                    int>(
                  value:
                  _year,
                  isExpanded:
                  true,
                  decoration:
                  const InputDecoration(
                    labelText:
                    'سال',
                    border:
                    OutlineInputBorder(),
                    contentPadding:
                    EdgeInsets
                        .symmetric(
                      horizontal:
                      10,
                      vertical:
                      8,
                    ),
                  ),
                  items:
                  years.map(
                        (year) =>
                        DropdownMenuItem<
                            int>(
                          value:
                          year,
                          child:
                          Text(
                            _toPersianDigits(
                                year),
                            textAlign:
                            TextAlign
                                .center,
                          ),
                        ),
                  ).toList(),
                  onChanged:
                      (value) {
                    if (value ==
                        null) {
                      return;
                    }

                    setState(() {
                      _year =
                          value;
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
            onPressed: () {
              Navigator.pop(
                context,
              );
            },
            child:
            const Text(
              'انصراف',
              style:
              TextStyle(
                color:
                Colors.grey,
              ),
            ),
          ),
          FilledButton(
            style:
            FilledButton.styleFrom(
              backgroundColor:
              primaryColor,
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal:
                20,
                vertical:
                10,
              ),
            ),
            onPressed: () {
              Navigator.pop(
                context,
                Jalali(
                  _year,
                  _month,
                  _day,
                ),
              );
            },
            child:
            const Text(
              'تأیید',
              style:
              TextStyle(
                color:
                Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}