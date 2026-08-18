import 'package:flutter/material.dart';

import '../services/poll_service.dart';

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

  // پاسخ‌های انتخاب‌شده
  final Map<int, List<int>> selectedChoices = {};

  @override
  void initState() {
    super.initState();

    loadPoll();
  }

  // =====================================================
  // دریافت نظرسنجی
  // =====================================================


  Future<void> loadPoll() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      debugPrint(
          '========== POLL FLUTTER DEBUG =========='
      );

      debugPrint(
        'POLL ID: ${widget.pollId}',
      );

      final result =
      await PollService.getPoll(
        widget.pollId,
      );

      debugPrint(
        'POLL RESULT: $result',
      );

      if (!mounted) return;

      setState(() {
        poll = result;
        isLoading = false;
      });

    } catch (e, stackTrace) {

      debugPrint(
          '========== POLL ERROR =========='
      );

      debugPrint(
        'ERROR: $e',
      );

      debugPrint(
        'STACK: $stackTrace',
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;

        errorMessage =
            e.toString().replaceFirst(
              'Exception: ',
              '',
            );
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
  // ثبت انتخاب گزینه
  // =====================================================

  void selectChoice({
    required int questionId,
    required int choiceId,
    required String questionType,
  }) {
    // اگر نظرسنجی قبلاً پاسخ داده شده
    // دیگر اجازه تغییر نمی‌دهیم.
    if (poll?['has_voted'] == true) {
      return;
    }

    setState(() {
      if (questionType == 'multi') {
        final current =
            selectedChoices[questionId] ?? [];

        if (current.contains(choiceId)) {
          current.remove(choiceId);
        } else {
          current.add(choiceId);
        }

        selectedChoices[questionId] =
        List<int>.from(current);

      } else {
        selectedChoices[questionId] = [
          choiceId,
        ];
      }
    });
  }

  // =====================================================
  // بررسی کامل بودن پاسخ‌ها
  // =====================================================

  bool validateAnswers() {
    final questions =
    List<Map<String, dynamic>>.from(
      poll?['questions'] ?? [],
    );

    for (final question in questions) {
      final questionId =
      int.parse(question['id'].toString());

      final type =
      question['question_type']
          ?.toString();

      final selected =
          selectedChoices[questionId] ?? [];

      if (type == 'multi') {
        if (selected.isEmpty) {
          return false;
        }
      } else {
        if (selected.length != 1) {
          return false;
        }
      }
    }

    return true;
  }

  // =====================================================
  // ثبت رأی
  // =====================================================

  Future<void> submitVote() async {
    // امنیت سمت Flutter
    if (poll?['has_voted'] == true) {
      return;
    }

    if (!validateAnswers()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لطفاً به همه سؤال‌ها پاسخ دهید.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final answers =
    selectedChoices.entries.map((entry) {
      return {
        'question_id': entry.key,
        'choice_ids': entry.value,
      };
    }).toList();

    try {
      await PollService.submitVote(
        pollId: widget.pollId,
        answers: answers,
      );

      // بعد از ثبت رأی، اطلاعات جدید را
      // دوباره از سرور می‌گیریم.
      final result =
      await PollService.getPoll(widget.pollId);

      if (!mounted) return;

      setState(() {
        poll = result;
        isSubmitting = false;
        selectedChoices.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'رأی شما با موفقیت ثبت شد.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =====================================================
  // Build
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
        const Color(0xffF5F8FA),

        appBar: AppBar(
          backgroundColor:
          const Color(0xff00ACC1),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,

          title: const Text(
            'نظرسنجی',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
        child: CircularProgressIndicator(
          color: Color(0xff00ACC1),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 55,
              color: Colors.grey,
            ),

            const SizedBox(height: 15),

            Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: loadPoll,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xff00ACC1),
                foregroundColor: Colors.white,
              ),
              child: const Text(
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
          'نظرسنجی پیدا نشد.',
        ),
      );
    }

    final hasVoted =
        poll!['has_voted'] == true;

    return RefreshIndicator(
      color: const Color(0xff00ACC1),
      onRefresh: loadPoll,

      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          20,
          18,
          35,
        ),

        children: [
          _buildPollHeader(),

          const SizedBox(height: 20),

          if (hasVoted)
            _buildVotedMessage(),

          const SizedBox(height: 10),

          _buildQuestions(
            showResults: hasVoted,
          ),

          if (!hasVoted) ...[
            const SizedBox(height: 25),

            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                isSubmitting
                    ? null
                    : submitVote,

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xff00ACC1),
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
                  width: 24,
                  height: 24,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'ثبت رأی',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // Header
  // =====================================================

  Widget _buildPollHeader() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(
              0.05,
            ),
            blurRadius: 12,
            offset:
            const Offset(0, 5),
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

                decoration: BoxDecoration(
                  color: Colors.amber
                      .withOpacity(0.15),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.poll_outlined,
                  color: Colors.amber,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  poll?['title']
                      ?.toString() ??
                      '-',

                  style:
                  const TextStyle(
                    fontSize: 18,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    Color(0xff263238),
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),

          if (poll?['description'] != null &&
              poll!['description']
                  .toString()
                  .trim()
                  .isNotEmpty) ...[
            const SizedBox(height: 15),

            Text(
              poll!['description']
                  .toString(),

              style:
              const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // پیام رأی داده شده
  // =====================================================

  Widget _buildVotedMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),

      decoration: BoxDecoration(
        color: Colors.green
            .withOpacity(0.08),

        borderRadius:
        BorderRadius.circular(15),

        border: Border.all(
          color: Colors.green
              .withOpacity(0.20),
        ),
      ),

      child: const Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 23,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'شما در این نظرسنجی شرکت کرده‌اید.',
              style: TextStyle(
                color: Colors.green,
                fontSize: 13,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // Questions
  // =====================================================

  Widget _buildQuestions({
    required bool showResults,
  }) {
    final questions =
    List<Map<String, dynamic>>.from(
      poll?['questions'] ?? [],
    );

    return Column(
      children: [
        for (int i = 0;
        i < questions.length;
        i++)
          _buildQuestion(
            question: questions[i],
            number: i + 1,
            showResults: showResults,
          ),
      ],
    );
  }

  // =====================================================
  // Question
  // =====================================================

  Widget _buildQuestion({
    required Map<String, dynamic> question,
    required int number,
    required bool showResults,
  }) {
    final questionId =
    int.parse(
      question['id'].toString(),
    );

    final type =
        question['question_type']
            ?.toString() ??
            'single';

    final choices =
    List<Map<String, dynamic>>.from(
      question['choices'] ?? [],
    );

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 16,
      ),

      padding:
      const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(
              0.05,
            ),
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
            '$number. ${question['title'] ?? '-'}',

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

          const SizedBox(height: 15),

          for (final choice in choices)
            showResults
                ? _buildResultChoice(
              choice,
            )
                : _buildSelectableChoice(
              questionId:
              questionId,
              questionType:
              type,
              choice:
              choice,
            ),
        ],
      ),
    );
  }

  // =====================================================
  // گزینه انتخابی
  // =====================================================

  Widget _buildSelectableChoice({
    required int questionId,
    required String questionType,
    required Map<String, dynamic> choice,
  }) {
    final choiceId =
    int.parse(
      choice['id'].toString(),
    );

    final selected =
        selectedChoices[questionId]
            ?.contains(choiceId) ??
            false;

    return InkWell(
      borderRadius:
      BorderRadius.circular(13),

      onTap: () {
        selectChoice(
          questionId: questionId,
          choiceId: choiceId,
          questionType:
          questionType,
        );
      },

      child: Container(
        margin:
        const EdgeInsets.only(
          bottom: 8,
        ),

        padding:
        const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: selected
              ? const Color(
            0xff00ACC1,
          ).withOpacity(0.08)
              : Colors.transparent,

          borderRadius:
          BorderRadius.circular(13),

          border: Border.all(
            color: selected
                ? const Color(
              0xff00ACC1,
            )
                : Colors.grey
                .withOpacity(0.20),
          ),
        ),

        child: Row(
          children: [
            Icon(
              questionType == 'multi'
                  ? selected
                  ? Icons
                  .check_box_rounded
                  : Icons
                  .check_box_outline_blank
                  : selected
                  ? Icons
                  .radio_button_checked
                  : Icons
                  .radio_button_off,

              color: selected
                  ? const Color(
                0xff00ACC1,
              )
                  : Colors.grey,

              size: 23,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                choice['title']
                    ?.toString() ??
                    '-',

                style:
                const TextStyle(
                  fontSize: 14,
                  color:
                  Color(0xff37474F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // نتیجه هر گزینه
  // =====================================================

  Widget _buildResultChoice(
      Map<String, dynamic> choice,
      ) {
    final title =
        choice['title']
            ?.toString() ??
            '-';

    final percentage =
        double.tryParse(
          choice['percentage']
              ?.toString() ??
              '0',
        ) ??
            0;

    final voteCount =
        int.tryParse(
          choice['vote_count']
              ?.toString() ??
              '0',
        ) ??
            0;

    final percentText =
    toPersianDigits(
      percentage
          .toStringAsFixed(1),
    );

    final voteText =
    toPersianDigits(
      voteCount.toString(),
    );

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),

      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 13,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    Color(0xff37474F),
                  ),
                ),
              ),

              Text(
                '$percentText٪',

                style:
                const TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.bold,
                  color:
                  Color(0xff00ACC1),
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          ClipRRect(
            borderRadius:
            BorderRadius.circular(
              10,
            ),

            child: LinearProgressIndicator(
              minHeight: 9,

              value:
              (percentage / 100)
                  .clamp(
                0.0,
                1.0,
              ),

              backgroundColor:
              const Color(
                0xffE8EEF0,
              ),

              valueColor:
              const AlwaysStoppedAnimation<
                  Color>(
                Color(0xff00ACC1),
              ),
            ),
          ),

          const SizedBox(height: 4),

          Align(
            alignment:
            Alignment.centerLeft,

            child: Text(
              '$voteText رأی',

              style:
              const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}