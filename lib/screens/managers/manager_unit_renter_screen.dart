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
    _peopleCountController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _contractNumberController.dispose();
    _estateNameController.dispose();
    _detailsController.dispose();

    super.dispose();
  }

  // =========================================================
  // Load unit
  // =========================================================

  Future<void> _loadUnit() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _hasRenter = false;
      });
    }

    try {
      final unit =
      await _unitService.getUnit(widget.unitId);

      if (!mounted) return;

      _unit = unit;

      // -------------------------------------------------------
      // پاک کردن اطلاعات قبلی فرم
      // -------------------------------------------------------

      _clearForm();

      // -------------------------------------------------------
      // دریافت مستاجر فعال
      // -------------------------------------------------------

      final renter = unit['active_renter'];

      if (renter is Map) {
        final renterMap =
        Map<String, dynamic>.from(renter);

        final name =
            renterMap['name']?.toString().trim() ?? '';

        _hasRenter = name.isNotEmpty;

        if (_hasRenter) {
          _nameController.text = name;

          _mobileController.text =
              renterMap['mobile']?.toString() ?? '';

          _nationalCodeController.text =
              renterMap['national_code']?.toString() ?? '';

          _peopleCountController.text =
              renterMap['people_count']?.toString() ?? '';

          _startDateController.text =
              renterMap['start_date']?.toString() ?? '';

          _endDateController.text =
              renterMap['end_date']?.toString() ?? '';

          _contractNumberController.text =
              renterMap['contract_number']?.toString() ?? '';

          _estateNameController.text =
              renterMap['estate_name']?.toString() ?? '';

          _detailsController.text =
              renterMap['details']?.toString() ?? '';
        }
      }

      // -------------------------------------------------------
      // مقدار پیش فرض تعداد نفرات
      // -------------------------------------------------------

      if (_peopleCountController.text.trim().isEmpty) {
        _peopleCountController.text = '1';
      }

      setState(() {
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
  // Clear form
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
  // Persian / English digits
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
  // Save renter
  // =========================================================

  Future<void> _saveRenter() async {
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
      final peopleCount = int.tryParse(
        _normalizeDigits(
          _peopleCountController.text.trim(),
        ),
      );

      final data = <String, dynamic>{
        'renter_name':
        _nameController.text.trim(),

        'renter_mobile':
        _mobileController.text.trim(),

        'renter_national_code':
        _nationalCodeController.text.trim(),

        'renter_people_count':
        peopleCount ?? 1,

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

        'renter_is_active': true,
      };

      // -------------------------------------------------------
      // ویرایش مستاجر
      // -------------------------------------------------------

      if (_hasRenter) {
        final result =
        await _unitService.updateRenter(
          widget.unitId,
          data,
        );

        debugPrint(
          'update renter result: $result',
        );
      }

      // -------------------------------------------------------
      // ایجاد مستاجر
      // -------------------------------------------------------

      else {
        final result =
        await _unitService.createRenter(
          widget.unitId,
          data,
        );

        debugPrint(
          'create renter result: $result',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _hasRenter
                ? 'اطلاعات مستاجر با موفقیت ویرایش شد.'
                : 'مستاجر با موفقیت ثبت شد.',
          ),
          backgroundColor: primaryColor,
        ),
      );

      Navigator.pop(context, true);
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
  // Delete renter
  // =========================================================

  Future<void> _deleteRenter() async {
    // -------------------------------------------------------
    // بررسی وجود مستاجر
    // -------------------------------------------------------

    if (!_hasRenter) {
      _showError(
        'مستاجر فعالی برای این واحد وجود ندارد.',
      );
      return;
    }

    if (_isSaving || _isDeleting) {
      return;
    }

    // -------------------------------------------------------
    // تایید حذف
    // -------------------------------------------------------

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'حذف مستاجر',
            ),
            content: const Text(
              'آیا از حذف مستاجر این واحد اطمینان دارید؟\n\n'
                  'سوابق سکونت مستاجر قبلی حذف نخواهد شد.',
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
                  'حذف مستاجر',
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

    // -------------------------------------------------------
    // Delete
    // -------------------------------------------------------

    setState(() {
      _isDeleting = true;
    });

    try {
      await _unitService.deleteRenter(
        widget.unitId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'مستاجر با موفقیت حذف شد.',
          ),
          backgroundColor: primaryColor,
        ),
      );

      Navigator.pop(context, true);
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

  void _showError(dynamic error) {
    String message = error.toString();

    if (message.startsWith('Exception: ')) {
      message =
          message.substring('Exception: '.length);
    }

    if (message.trim().isEmpty) {
      message = 'خطایی رخ داده است.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
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
          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
          focusedBorder:
          OutlineInputBorder(
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
            child: const Icon(
              Icons.people_outline,
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
                  _hasRenter
                      ? 'مدیریت مستاجر'
                      : 'افزودن مستاجر',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
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
  // Build
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        const Color(0xffF7F9FA),

        appBar: AppBar(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            _hasRenter
                ? 'مدیریت مستاجر'
                : 'افزودن مستاجر',
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
  // Error view
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
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 15),

            FilledButton.icon(
              style:
              FilledButton.styleFrom(
                backgroundColor:
                primaryColor,
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
    );
  }

  // =========================================================
  // Form
  // =========================================================

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding:
        const EdgeInsets.all(14),
        children: [
          _buildHeader(),

          const SizedBox(height: 20),

          const Text(
            'اطلاعات مستاجر',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          // ---------------------------------------------------
          // Name
          // ---------------------------------------------------

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

          // ---------------------------------------------------
          // Mobile
          // ---------------------------------------------------

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
                  !mobile.startsWith('09')) {
                return 'شماره موبایل معتبر نیست';
              }

              return null;
            },
          ),

          // ---------------------------------------------------
          // National code
          // ---------------------------------------------------

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

          // ---------------------------------------------------
          // People count
          // ---------------------------------------------------

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

          // ---------------------------------------------------
          // Start date
          // ---------------------------------------------------

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

          // ---------------------------------------------------
          // End date
          // ---------------------------------------------------

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

          // ---------------------------------------------------
          // Contract number
          // ---------------------------------------------------

          _textField(
            controller:
            _contractNumberController,
            label:
            'شماره قرارداد',
            icon:
            Icons.description_outlined,
          ),

          // ---------------------------------------------------
          // Estate
          // ---------------------------------------------------

          _textField(
            controller:
            _estateNameController,
            label:
            'نام بنگاه',
            icon:
            Icons.business_outlined,
          ),

          // ---------------------------------------------------
          // Details
          // ---------------------------------------------------

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

          // ===================================================
          // Save button
          // ===================================================

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
                _hasRenter
                    ? Icons
                    .save_outlined
                    : Icons
                    .person_add_outlined,
              ),
              label: Text(
                _hasRenter
                    ? 'ذخیره تغییرات'
                    : 'ثبت مستاجر',
                style:
                const TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),

          // ===================================================
          // Delete button
          // ===================================================

          if (_hasRenter) ...[
            const SizedBox(height: 10),

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
                _isSaving ||
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
                label:
                const Text(
                  'حذف مستاجر',
                  style:
                  TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}