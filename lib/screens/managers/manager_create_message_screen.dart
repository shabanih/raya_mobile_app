import 'package:flutter/material.dart';

import '../../services/manager_message_service.dart';

class ManagerCreateMessageScreen extends StatefulWidget {
  const ManagerCreateMessageScreen({
    super.key,
  });

  @override
  State<ManagerCreateMessageScreen> createState() =>
      _ManagerCreateMessageScreenState();
}

class _ManagerCreateMessageScreenState
    extends State<ManagerCreateMessageScreen> {
  final ManagerMessageService _service =
  ManagerMessageService();

  final TextEditingController _titleController =
  TextEditingController();

  final TextEditingController _messageController =
  TextEditingController();

  final FocusNode _titleFocusNode =
  FocusNode();

  final FocusNode _messageFocusNode =
  FocusNode();

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _titleFocusNode.dispose();
    _messageFocusNode.dispose();

    super.dispose();
  }

  // =====================================================
  // ایجاد و ذخیره پیام
  // =====================================================

  Future<void> _createMessage() async {
    final title =
    _titleController.text.trim();

    final message =
    _messageController.text.trim();

    // -----------------------------------------------------
    // بررسی عنوان
    // -----------------------------------------------------

    if (title.isEmpty) {
      _showMessage(
        'لطفاً عنوان پیام را وارد کنید.',
      );

      _titleFocusNode.requestFocus();
      return;
    }

    // -----------------------------------------------------
    // بررسی متن
    // -----------------------------------------------------

    if (message.isEmpty) {
      _showMessage(
        'لطفاً متن پیام را وارد کنید.',
      );

      _messageFocusNode.requestFocus();
      return;
    }

    // -----------------------------------------------------
    // جلوگیری از چند بار کلیک
    // -----------------------------------------------------

    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ---------------------------------------------------
      // ذخیره پیام به عنوان Draft
      // ---------------------------------------------------

      await _service.createMessage(
        title: title,
        message: message,
      );

      if (!mounted) {
        return;
      }

      // ---------------------------------------------------
      // پیام ذخیره شد
      // مستقیماً به لیست پیام‌ها برمی‌گردیم
      // ---------------------------------------------------

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'پیام با موفقیت ذخیره شد.',
              textDirection:
              TextDirection.rtl,
            ),
            behavior:
            SnackBarBehavior.floating,
          ),
        );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      String error =
      e.toString();

      if (error.startsWith(
        'Exception: ',
      )) {
        error = error.substring(
          'Exception: '.length,
        );
      }

      _showMessage(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =====================================================
  // نمایش پیام
  // =====================================================

  void _showMessage(
      String message,
      ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textDirection:
            TextDirection.rtl,
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        const Color(0xffF7F8FC),

        // =================================================
        // AppBar
        // =================================================

        appBar: AppBar(
          title: const Text(
            'پیام جدید',
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor:
          const Color(0xff5E35B1),
          foregroundColor:
          Colors.white,
          elevation: 0,
        ),

        // =================================================
        // Body
        // =================================================

        body: SafeArea(
          child:
          SingleChildScrollView(
            padding:
            const EdgeInsets.all(16),
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                // =========================================
                // کارت ایجاد پیام
                // =========================================

                Container(
                  padding:
                  const EdgeInsets.all(16),
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.white,
                    borderRadius:
                    BorderRadius.circular(
                      16,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                        Colors.black
                            .withOpacity(
                          0.05,
                        ),
                        blurRadius:
                        10,
                        offset:
                        const Offset(
                          0,
                          3,
                        ),
                      ),
                    ],
                  ),
                  child:
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .stretch,
                    children: [
                      // ===================================
                      // عنوان بخش
                      // ===================================

                      const Text(
                        'ایجاد پیام',
                        style:
                        TextStyle(
                          fontSize:
                          18,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // ===================================
                      // عنوان پیام
                      // ===================================

                      TextField(
                        controller:
                        _titleController,
                        focusNode:
                        _titleFocusNode,
                        textDirection:
                        TextDirection.rtl,
                        textAlign:
                        TextAlign.right,
                        textInputAction:
                        TextInputAction.next,
                        decoration:
                        InputDecoration(
                          labelText:
                          'عنوان پیام',
                          hintText:
                          'عنوان پیام را وارد کنید',
                          prefixIcon:
                          const Icon(
                            Icons
                                .title_rounded,
                            color:
                            Color(
                              0xff5E35B1,
                            ),
                          ),
                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              12,
                            ),
                          ),
                          enabledBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              12,
                            ),
                            borderSide:
                            BorderSide(
                              color:
                              Colors
                                  .grey
                                  .shade300,
                            ),
                          ),
                          focusedBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              12,
                            ),
                            borderSide:
                            const BorderSide(
                              color:
                              Color(
                                0xff5E35B1,
                              ),
                              width:
                              2,
                            ),
                          ),
                        ),
                        onSubmitted:
                            (_) {
                          _messageFocusNode
                              .requestFocus();
                        },
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ===================================
                      // متن پیام
                      // ===================================

                      TextField(
                        controller:
                        _messageController,
                        focusNode:
                        _messageFocusNode,
                        textDirection:
                        TextDirection.rtl,
                        textAlign:
                        TextAlign.right,
                        minLines:
                        7,
                        maxLines:
                        12,
                        keyboardType:
                        TextInputType.multiline,
                        decoration:
                        InputDecoration(
                          labelText:
                          'متن پیام',
                          hintText:
                          'متن پیام را وارد کنید',
                          alignLabelWithHint:
                          true,
                          prefixIcon:
                          const Padding(
                            padding:
                            EdgeInsets.only(
                              bottom:
                              120,
                            ),
                            child:
                            Icon(
                              Icons
                                  .message_outlined,
                              color:
                              Color(
                                0xff5E35B1,
                              ),
                            ),
                          ),
                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              12,
                            ),
                          ),
                          enabledBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              12,
                            ),
                            borderSide:
                            BorderSide(
                              color:
                              Colors
                                  .grey
                                  .shade300,
                            ),
                          ),
                          focusedBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              12,
                            ),
                            borderSide:
                            const BorderSide(
                              color:
                              Color(
                                0xff5E35B1,
                              ),
                              width:
                              2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // ===================================
                      // دکمه ذخیره
                      // ===================================

                      SizedBox(
                        height: 52,
                        child:
                        ElevatedButton(
                          onPressed:
                          _isLoading
                              ? null
                              : _createMessage,
                          style:
                          ElevatedButton
                              .styleFrom(
                            backgroundColor:
                            const Color(
                              0xff5E35B1,
                            ),
                            foregroundColor:
                            Colors.white,
                            disabledBackgroundColor:
                            Colors
                                .grey
                                .shade400,
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                12,
                              ),
                            ),
                          ),
                          child:
                          _isLoading
                              ? const SizedBox(
                            width:
                            24,
                            height:
                            24,
                            child:
                            CircularProgressIndicator(
                              strokeWidth:
                              2.5,
                              color:
                              Colors.white,
                            ),
                          )
                              : const Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                            children: [
                              Icon(
                                Icons
                                    .save_rounded,
                              ),
                              SizedBox(
                                width:
                                8,
                              ),
                              Text(
                                'ذخیره پیام',
                                style:
                                TextStyle(
                                  fontSize:
                                  15,
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}