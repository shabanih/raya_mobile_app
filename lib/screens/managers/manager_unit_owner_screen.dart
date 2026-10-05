import 'package:flutter/material.dart';

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

  final ManagerUnitService _unitService =
  ManagerUnitService();

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

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool _hasOwner = false;

  String? _errorMessage;

  Map<String, dynamic>? _unit;

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
    _purchaseDateController.dispose();
    _peopleCountController.dispose();
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
      });
    }

    try {
      final unit =
      await _unitService.getUnit(widget.unitId);

      if (!mounted) return;

      _unit = unit;

      final owner = unit['owner'];

      if (owner is Map) {
        final ownerMap =
        Map<String, dynamic>.from(owner);

        final name =
            ownerMap['name']?.toString().trim() ?? '';

        _hasOwner = name.isNotEmpty;

        if (_hasOwner) {
          _nameController.text = name;

          _mobileController.text =
              ownerMap['mobile']?.toString() ?? '';

          _nationalCodeController.text =
              ownerMap['national_code']?.toString() ?? '';

          _peopleCountController.text =
              ownerMap['people_count']?.toString() ?? '';

          _detailsController.text =
              ownerMap['details']?.toString() ?? '';

          final purchaseDate =
          ownerMap['purchase_date'];

          if (purchaseDate != null) {
            _purchaseDateController.text =
                purchaseDate.toString();
          }
        }
      }

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
  // Save
  // =========================================================

  Future<void> _saveOwner() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final data = <String, dynamic>{
        'owner_name':
        _nameController.text.trim(),

        'owner_mobile':
        _mobileController.text.trim(),

        'owner_national_code':
        _nationalCodeController.text.trim(),

        'owner_people_count':
        int.tryParse(
          _peopleCountController.text
              .trim()
              .replaceAll('۰', '0')
              .replaceAll('۱', '1')
              .replaceAll('۲', '2')
              .replaceAll('۳', '3')
              .replaceAll('۴', '4')
              .replaceAll('۵', '5')
              .replaceAll('۶', '6')
              .replaceAll('۷', '7')
              .replaceAll('۸', '8')
              .replaceAll('۹', '9'),
        ) ??
            1,

        'owner_details':
        _detailsController.text.trim(),
      };

      final purchaseDate =
      _purchaseDateController.text.trim();

      if (purchaseDate.isNotEmpty) {
        data['purchase_date'] = purchaseDate;
      }

      if (_hasOwner) {
        await _unitService.updateOwner(
          widget.unitId,
          data,
        );
      } else {
        await _unitService.createOwner(
          widget.unitId,
          data,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _hasOwner
                ? 'اطلاعات مالک با موفقیت ویرایش شد.'
                : 'مالک با موفقیت ثبت شد.',
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
  // Delete
  // =========================================================

  Future<void> _deleteOwner() async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'حذف مالک',
            ),
            content: const Text(
              'آیا از حذف مالک این واحد اطمینان دارید؟\n\n'
                  'سوابق مالک قبلی حذف نخواهد شد و در سوابق سکونت باقی می‌ماند.',
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
                  'حذف مالک',
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
      await _unitService.deleteOwner(
        widget.unitId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'مالک با موفقیت حذف شد.',
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
              Icons.person_outline,
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
                  _hasOwner
                      ? 'مدیریت مالک'
                      : 'افزودن مالک',
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
            _hasOwner
                ? 'مدیریت مالک'
                : 'افزودن مالک',
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
        padding: const EdgeInsets.all(24),
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
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
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
        padding: const EdgeInsets.all(14),
        children: [
          _buildHeader(),

          const SizedBox(height: 20),

          const Text(
            'اطلاعات مالک',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _textField(
            controller: _nameController,
            label: 'نام و نام خانوادگی',
            icon: Icons.person_outline,
            hint: 'نام مالک را وارد کنید',
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'نام مالک را وارد کنید';
              }

              return null;
            },
          ),

          _textField(
            controller: _mobileController,
            label: 'شماره موبایل',
            icon: Icons.phone_outlined,
            hint: 'مثلاً 09121234567',
            keyboardType:
            TextInputType.phone,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'شماره موبایل را وارد کنید';
              }

              final mobile =
              value.trim()
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

              if (mobile.length != 11 ||
                  !mobile.startsWith('09')) {
                return 'شماره موبایل معتبر نیست';
              }

              return null;
            },
          ),

          _textField(
            controller:
            _nationalCodeController,
            label: 'کد ملی',
            icon: Icons.badge_outlined,
            keyboardType:
            TextInputType.number,
          ),

          _textField(
            controller:
            _purchaseDateController,
            label: 'تاریخ خرید',
            icon:
            Icons.calendar_today_outlined,
            hint: 'مثلاً 1404-01-01',
          ),

          _textField(
            controller:
            _peopleCountController,
            label: 'تعداد نفرات',
            icon: Icons.people_outline,
            keyboardType:
            TextInputType.number,
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'تعداد نفرات را وارد کنید';
              }

              final count =
              int.tryParse(
                value.trim()
                    .replaceAll('۰', '0')
                    .replaceAll('۱', '1')
                    .replaceAll('۲', '2')
                    .replaceAll('۳', '3')
                    .replaceAll('۴', '4')
                    .replaceAll('۵', '5')
                    .replaceAll('۶', '6')
                    .replaceAll('۷', '7')
                    .replaceAll('۸', '8')
                    .replaceAll('۹', '9'),
              );

              if (count == null ||
                  count < 0) {
                return 'تعداد نفرات معتبر نیست';
              }

              return null;
            },
          ),

          _textField(
            controller:
            _detailsController,
            label: 'توضیحات',
            icon: Icons.notes_outlined,
            hint: 'توضیحات مربوط به مالک',
            maxLines: 4,
          ),

          const SizedBox(height: 8),

          // =================================================
          // Save button
          // =================================================

          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
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
              _isSaving || _isDeleting
                  ? null
                  : _saveOwner,
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
                  : Icon(
                _hasOwner
                    ? Icons.save_outlined
                    : Icons.person_add_outlined,
              ),
              label: Text(
                _hasOwner
                    ? 'ذخیره تغییرات'
                    : 'ثبت مالک',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),

          // =================================================
          // Delete
          // =================================================

          if (_hasOwner) ...[
            const SizedBox(height: 10),

            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
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
                        12),
                  ),
                ),
                onPressed:
                _isSaving ||
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
                    color: Colors.red,
                  ),
                )
                    : const Icon(
                  Icons
                      .delete_outline,
                ),
                label: const Text(
                  'حذف مالک',
                  style: TextStyle(
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