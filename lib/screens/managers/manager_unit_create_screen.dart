import 'package:flutter/material.dart';

import '../../services/manager_unit_service.dart';

class ManagerUnitCreateScreen extends StatefulWidget {
  const ManagerUnitCreateScreen({super.key});

  @override
  State<ManagerUnitCreateScreen> createState() =>
      _ManagerUnitCreateScreenState();
}

class _ManagerUnitCreateScreenState
    extends State<ManagerUnitCreateScreen> {
  final ManagerUnitService _unitService =
  ManagerUnitService();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _unitNumberController =
  TextEditingController();

  final TextEditingController _floorController =
  TextEditingController();

  final TextEditingController _areaController =
  TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _unitNumberController.dispose();
    _floorController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final data = <String, dynamic>{
        'unit_number':
        _unitNumberController.text.trim(),
        'floor': _floorController.text.trim(),
        'area': _areaController.text.trim(),
      };

      await _unitService.createUnit(data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'واحد با موفقیت ایجاد شد.',
            textAlign: TextAlign.right,
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      String message = e.toString();

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
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'افزودن واحد',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTextField(
                controller: _unitNumberController,
                label: 'شماره واحد',
                hint: 'مثلاً ۱',
                icon: Icons.home_work_outlined,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'شماره واحد را وارد کنید';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              _buildTextField(
                controller: _floorController,
                label: 'طبقه',
                hint: 'مثلاً ۲',
                icon: Icons.layers_outlined,
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 14),

              _buildTextField(
                controller: _areaController,
                label: 'متراژ',
                hint: 'مثلاً ۱۲۰',
                icon: Icons.square_foot,
                keyboardType:
                const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
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
                  label: Text(
                    _isSaving
                        ? 'در حال ذخیره...'
                        : 'ذخیره واحد',
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