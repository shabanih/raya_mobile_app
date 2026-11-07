
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../services/api_service.dart';

class ManagerSuggestionScreen extends StatefulWidget {
  final String fullName;
  final String mobile;

  const ManagerSuggestionScreen({
    super.key,
    required this.fullName,
    required this.mobile,
  });

  @override
  State<ManagerSuggestionScreen> createState() =>
      _ManagerSuggestionScreenState();
}

class _ManagerSuggestionScreenState
    extends State<ManagerSuggestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSending = false;

  static const Color primaryColor = Color(0xFF00ACC1);
  static const Color secondaryColor = Color(0xFF610DB5);

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _toPersianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    for (int i = 0; i < english.length; i++) {
      value = value.replaceAll(english[i], persian[i]);
    }

    return value;
  }

  Future<void> _sendSuggestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final response = await ApiService().post(
        ApiConfig.contactUs,
        body: {
          'subject': _subjectController.text.trim(),
          'message': _messageController.text.trim(),
        },
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201 &&
          data is Map &&
          data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message']?.toString() ??
                  'پیشنهاد شما با موفقیت ثبت شد.',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data is Map
                  ? data['message']?.toString() ??
                  'ثبت پیشنهاد انجام نشد.'
                  : 'ثبت پیشنهاد انجام نشد.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'خطا در ارتباط با سرور. دوباره تلاش کنید.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: primaryColor,
        size: 21,
      ),
      filled: true,
      fillColor: const Color(0xFFF7FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: secondaryColor,
          size: 19,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),
      ],
    );
  }

  Widget _buildManagerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE0F7FA),
            Color(0xFFF3E5F5),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primaryColor.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.manage_accounts_rounded,
                  color: secondaryColor,
                  size: 27,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'اطلاعات مدیر ساختمان',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF37474F),
                  ),
                ),
              ),
              const Icon(
                Icons.verified_user_outlined,
                color: primaryColor,
                size: 21,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(
            Icons.person_outline,
            'نام مدیر',
            widget.fullName,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 11),
            child: Divider(height: 1),
          ),
          _infoRow(
            Icons.phone_android_rounded,
            'شماره همراه',
            _toPersianDigits(widget.mobile),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: secondaryColor.withOpacity(0.8),
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSending ? null : _sendSuggestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primaryColor.withOpacity(0.5),
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isSending
            ? const SizedBox(
          width: 23,
          height: 23,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_rounded, size: 20),
            SizedBox(width: 9),
            Text(
              'ثبت و ارسال پیشنهاد',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(
          toolbarHeight: 88,
          title: const Text(
            'ارسال پیشنهاد',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF263238),
          elevation: 0,
          surfaceTintColor: Colors.white,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildManagerInfoCard(),

                  const SizedBox(height: 25),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.035),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle(
                          'موضوع پیشنهاد',
                          Icons.edit_note_rounded,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _subjectController,
                          maxLength: 200,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          textInputAction: TextInputAction.next,
                          decoration: _inputDecoration(
                            hint: 'موضوع پیشنهاد را وارد کنید',
                            icon: Icons.title_rounded,
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'موضوع پیشنهاد را وارد کنید.';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        _sectionTitle(
                          'متن پیشنهاد',
                          Icons.message_outlined,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _messageController,
                          maxLength: 360,
                          maxLines: 6,
                          minLines: 5,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          textInputAction: TextInputAction.newline,
                          decoration: _inputDecoration(
                            hint: 'پیشنهاد یا انتقاد خود را بنویسید...',
                            icon: Icons.notes_rounded,
                          ).copyWith(
                            alignLabelWithHint: true,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 85),
                              child: Icon(
                                Icons.notes_rounded,
                                color: primaryColor,
                                size: 21,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'متن پیشنهاد را وارد کنید.';
                            }

                            if (value.trim().length > 360) {
                              return 'حداکثر ۳۶۰ کاراکتر مجاز است.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F7FA)
                                .withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: primaryColor,
                                size: 19,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'پیشنهادها و انتقادهای شما به تیم پشتیبانی رایا شارژ ارسال می‌شود.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.8,
                                    color: Color(0xFF455A64),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  _buildSubmitButton(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
