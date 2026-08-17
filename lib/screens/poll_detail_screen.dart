import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class PollDetailScreen extends StatefulWidget {
  final int pollId;

  const PollDetailScreen({
    super.key,
    required this.pollId,
  });

  @override
  State<PollDetailScreen> createState() =>
      _PollDetailScreenState();
}

class _PollDetailScreenState
    extends State<PollDetailScreen> {

  bool isLoading = true;
  bool isSubmitting = false;

  String? errorMessage;

  Map<String, dynamic>? poll;

  final Map<int, dynamic> answers = {};

  @override
  void initState() {
    super.initState();
    loadPoll();
  }

  // =====================================================
  // دریافت جزئیات نظرسنجی
  // =====================================================

  Future<void> loadPoll() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token =
      await TokenStorage.getAccessToken();

      if (token == null || token.isEmpty) {
        throw Exception(
          'توکن ورود پیدا نشد.',
        );
      }

      final response = await http.get(
        Uri.parse(
          '${ApiConfig.polls}${widget.pollId}/',
        ),
        headers: {
          'Authorization':
          'Bearer $token',
          'Content-Type':
          'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(
          utf8.decode(
            response.bodyBytes,
          ),
        );

        if (!mounted) return;

        setState(() {
          poll =
          Map<String, dynamic>.from(
            data['poll'] ?? data,
          );

          isLoading = false;
        });

        return;
      }

      if (response.statusCode == 401) {
        throw Exception(
          'نشست کاربر منقضی شده است.',
        );
      }

      throw Exception(
        'خطا در دریافت نظرسنجی.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
        'دریافت نظرسنجی با خطا مواجه شد.';
      });
    }
  }

  // =====================================================
  // تبدیل اعداد
  // =====================================================

  String toPersianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    for (int i = 0; i < english.length; i++) {
      value = value.replaceAll(
        english[i],
        persian[i],
      );
    }

    return value;
  }

  // =====================================================
  // سؤالات
  // =====================================================

  List<dynamic> get questions {
    return (poll?['questions'] as List?) ?? [];
  }

  // =====================================================
  // صفحه
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        const Color(0xffF5F8FA),

        appBar: AppBar(
          backgroundColor:
          const Color(0xff00ACC1),
          foregroundColor:
          Colors.white,
          elevation: 0,
          centerTitle: true,

          title: const Text(
            'نظرسنجی',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),

        body: _buildBody(),
      ),
    );
  }

  // =====================================================
  // Body
  // =====================================================

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child:
        CircularProgressIndicator(
          color:
          Color(0xff00ACC1),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [

            const Icon(
              Icons.error_outline_rounded,
              size: 50,
              color: Colors.grey,
            ),

            const SizedBox(
              height: 15,
            ),

            Text(
              errorMessage!,
              style:
              const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            ElevatedButton(
              onPressed:
              loadPoll,
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xff00ACC1,
                ),
                foregroundColor:
                Colors.white,
              ),
              child:
              const Text(
                'تلاش مجدد',
              ),
            ),
          ],
        ),
      );
    }

    if (poll == null) {
      return const Center(
        child: Text(
          'اطلاعات نظرسنجی پیدا نشد.',
        ),
      );
    }

    final title =
        poll!['title']
            ?.toString() ??
            '-';

    final description =
    poll!['description']
        ?.toString();

    if (questions.isEmpty) {
      return Center(
        child: Text(
          'برای این نظرسنجی سؤالی ثبت نشده است.',
          style:
          const TextStyle(
            color: Colors.grey,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding:
      const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        30,
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,

        children: [

          // =================================================
          // اطلاعات نظرسنجی
          // =================================================

          Container(
            padding:
            const EdgeInsets.all(20),

            decoration:
            BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(
                22,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(0.05),
                  blurRadius: 10,
                  offset:
                  const Offset(0, 4),
                ),
              ],
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Row(
                  children: [

                    Container(
                      width: 50,
                      height: 50,

                      decoration:
                      BoxDecoration(
                        color: Colors.amber
                            .withOpacity(
                          0.15,
                        ),
                        shape:
                        BoxShape.circle,
                      ),

                      child:
                      const Icon(
                        Icons.poll_outlined,
                        color:
                        Colors.amber,
                        size: 28,
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    Expanded(
                      child: Text(
                        title,
                        style:
                        const TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                          color:
                          Color(
                            0xff263238,
                          ),
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),

                if (description !=
                    null &&
                    description
                        .trim()
                        .isNotEmpty) ...[

                  const SizedBox(
                    height: 15,
                  ),

                  Text(
                    description,
                    style:
                    const TextStyle(
                      fontSize: 14,
                      color:
                      Colors.grey,
                      height: 1.8,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // =================================================
          // سؤالات
          // =================================================

          ...questions
              .asMap()
              .entries
              .map(
                (entry) {

              final index =
                  entry.key;

              final question =
              Map<String, dynamic>
                  .from(
                entry.value,
              );

              return _buildQuestion(
                question,
                index,
              );
            },
          ),

          const SizedBox(
            height: 10,
          ),

          // =================================================
          // ثبت پاسخ
          // =================================================

          SizedBox(
            height: 52,

            child:
            ElevatedButton(
              onPressed:
              isSubmitting
                  ? null
                  : _submitPoll,

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xff00ACC1,
                ),
                foregroundColor:
                Colors.white,
                elevation: 0,

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),
                ),
              ),

              child: isSubmitting
                  ? const SizedBox(
                width: 22,
                height: 22,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color:
                  Colors.white,
                ),
              )
                  : const Text(
                'ثبت پاسخ‌ها',
                style:
                TextStyle(
                  fontSize: 15,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // سؤال
  // =====================================================

  Widget _buildQuestion(
      Map<String, dynamic> question,
      int index,
      ) {
    final questionId =
        int.tryParse(
          question['id']
              ?.toString() ??
              '',
        ) ??
            index;

    final title =
        question['title']
            ?.toString() ??
            '-';

    final type =
        question['question_type']
            ?.toString() ??
            'single';

    final choices =
        (question['choices'] as List?) ??
            [];

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 16,
      ),

      padding:
      const EdgeInsets.all(18),

      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          20,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.05),
            blurRadius: 10,
            offset:
            const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Text(
            '${toPersianDigits((index + 1).toString())}. $title',

            style:
            const TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.bold,
              color:
              Color(0xff263238),
              height: 1.7,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          if (type == 'yesno')
            _buildYesNo(
              questionId,
            )
          else if (type == 'multi')
            _buildMultiChoice(
              questionId,
              choices,
            )
          else
            _buildSingleChoice(
              questionId,
              choices,
            ),
        ],
      ),
    );
  }

  // =====================================================
  // بلی / خیر
  // =====================================================

  Widget _buildYesNo(
      int questionId,
      ) {
    final selected =
    answers[questionId];

    return Column(
      children: [

        RadioListTile<String>(
          value: 'yes',
          groupValue:
          selected,

          title:
          const Text('بلی'),

          activeColor:
          const Color(
            0xff00ACC1,
          ),

          contentPadding:
          EdgeInsets.zero,

          onChanged:
              (value) {
            setState(() {
              answers[
              questionId] =
                  value;
            });
          },
        ),

        RadioListTile<String>(
          value: 'no',
          groupValue:
          selected,

          title:
          const Text('خیر'),

          activeColor:
          const Color(
            0xff00ACC1,
          ),

          contentPadding:
          EdgeInsets.zero,

          onChanged:
              (value) {
            setState(() {
              answers[
              questionId] =
                  value;
            });
          },
        ),
      ],
    );
  }

  // =====================================================
  // تک انتخابی
  // =====================================================

  Widget _buildSingleChoice(
      int questionId,
      List<dynamic> choices,
      ) {
    final selected =
    answers[questionId];

    return Column(
      children:
      choices.map((item) {

        final choice =
        Map<String, dynamic>
            .from(item);

        final choiceId =
        choice['id'];

        return RadioListTile<dynamic>(
          value: choiceId,
          groupValue:
          selected,

          title: Text(
            choice['title']
                ?.toString() ??
                '-',
          ),

          activeColor:
          const Color(
            0xff00ACC1,
          ),

          contentPadding:
          EdgeInsets.zero,

          onChanged:
              (value) {
            setState(() {
              answers[
              questionId] =
                  value;
            });
          },
        );
      }).toList(),
    );
  }

  // =====================================================
  // چند انتخابی
  // =====================================================

  Widget _buildMultiChoice(
      int questionId,
      List<dynamic> choices,
      ) {
    final selected =
    List<dynamic>.from(
      answers[questionId] ??
          [],
    );

    return Column(
      children:
      choices.map((item) {

        final choice =
        Map<String, dynamic>
            .from(item);

        final choiceId =
        choice['id'];

        final isSelected =
        selected.contains(
          choiceId,
        );

        return CheckboxListTile(
          value:
          isSelected,

          title: Text(
            choice['title']
                ?.toString() ??
                '-',
          ),

          activeColor:
          const Color(
            0xff00ACC1,
          ),

          contentPadding:
          EdgeInsets.zero,

          onChanged:
              (value) {

            setState(() {

              final updated =
              List<dynamic>.from(
                selected,
              );

              if (value == true) {

                if (!updated
                    .contains(
                  choiceId,
                )) {
                  updated.add(
                    choiceId,
                  );
                }

              } else {
                updated.remove(
                  choiceId,
                );
              }

              answers[
              questionId] =
                  updated;
            });
          },
        );
      }).toList(),
    );
  }

  // =====================================================
  // ثبت پاسخ
  // =====================================================

  Future<void> _submitPoll() async {

    if (answers.length <
        questions.length) {

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'لطفاً به همه سؤالات پاسخ دهید.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSubmitting = true;
    });

    // فعلاً ارسال واقعی پاسخ‌ها
    // را بعد از نهایی شدن API انجام می‌دهیم.

    await Future.delayed(
      const Duration(
        milliseconds: 500,
      ),
    );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'پاسخ‌های شما ثبت شد.',
        ),
      ),
    );

    Navigator.pop(
      context,
      true,
    );
  }
}