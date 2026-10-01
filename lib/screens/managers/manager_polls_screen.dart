import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/manager_poll_service.dart';

import 'manager_poll_create_screen.dart';
import 'manager_poll_detail_screen.dart';

class ManagerPollsScreen extends StatefulWidget {
  const ManagerPollsScreen({
    super.key,
  });

  @override
  State<ManagerPollsScreen> createState() =>
      _ManagerPollsScreenState();
}

class _ManagerPollsScreenState
    extends State<ManagerPollsScreen> {
  late final ManagerPollService pollService;

  bool isLoading = true;
  bool isProcessing = false;

  String? errorMessage;

  List<Map<String, dynamic>> polls = [];

  static const Color primaryColor =
  Color(0xff00838F);

  @override
  void initState() {
    super.initState();

    pollService = ManagerPollService(
      apiService: ApiService(),
    );

    loadPolls();
  }

  // =====================================================
  // دریافت لیست
  // =====================================================

  Future<void> loadPolls() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
      await pollService.getPolls();

      if (!mounted) return;

      setState(() {
        polls = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage =
            _cleanError(e);
      });
    }
  }

  // =====================================================
  // پاک کردن Exception
  // =====================================================

  String _cleanError(Object error) {
    String text = error.toString();

    if (text.startsWith('Exception:')) {
      text = text.substring(
        'Exception:'.length,
      );
    }

    return text.trim();
  }

  // =====================================================
  // فعال / غیرفعال
  // =====================================================

  Future<void> togglePoll(
      Map<String, dynamic> poll,
      ) async {
    final int? pollId =
    int.tryParse(
      poll['id']?.toString() ?? '',
    );

    if (pollId == null) {
      return;
    }

    final bool currentActive =
    isActive(poll);

    final bool newActive =
    !currentActive;

    setState(() {
      isProcessing = true;
    });

    try {
      await pollService.togglePollActive(
        id: pollId,
        isActive: newActive,
      );

      if (!mounted) return;

      await loadPolls();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              newActive
                  ? 'نظرسنجی فعال شد.'
                  : 'نظرسنجی غیرفعال شد.',
            ),
            behavior:
            SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _cleanError(e),
            ),
            behavior:
            SnackBarBehavior.floating,
          ),
        );
    }
  }

  // =====================================================
  // حذف
  // =====================================================

  Future<void> deletePoll(
      Map<String, dynamic> poll,
      ) async {
    final int? pollId =
    int.tryParse(
      poll['id']?.toString() ?? '',
    );

    if (pollId == null) {
      return;
    }

    if (hasVotes(poll)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'این نظرسنجی دارای پاسخ است و امکان حذف آن وجود ندارد.',
            ),
            behavior:
            SnackBarBehavior.floating,
          ),
        );

      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection:
          TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'حذف نظرسنجی',
            ),
            content: Text(
              'آیا از حذف نظرسنجی «${pollTitle(poll)}» اطمینان دارید؟',
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
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    true,
                  );
                },
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.red,
                  foregroundColor:
                  Colors.white,
                ),
                child: const Text(
                  'حذف',
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
      isProcessing = true;
    });

    try {
      await pollService.deletePoll(
        pollId,
      );

      if (!mounted) return;

      await loadPolls();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'نظرسنجی با موفقیت حذف شد.',
            ),
            behavior:
            SnackBarBehavior.floating,
          ),
        );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _cleanError(e),
            ),
            behavior:
            SnackBarBehavior.floating,
          ),
        );
    }
  }

  // =====================================================
  // ایجاد
  // =====================================================

  Future<void> createPoll() async {
    final result =
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const ManagerPollCreateScreen(),
      ),
    );

    if (result == true) {
      await loadPolls();
    }
  }

  // =====================================================
  // ویرایش
  // =====================================================

  Future<void> editPoll(
      Map<String, dynamic> poll,
      ) async {
    if (hasVotes(poll)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'این نظرسنجی دارای پاسخ است و امکان ویرایش آن وجود ندارد.',
            ),
            behavior:
            SnackBarBehavior.floating,
          ),
        );

      return;
    }

    final int? pollId =
    int.tryParse(
      poll['id']?.toString() ?? '',
    );

    if (pollId == null) {
      return;
    }

    final result =
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ManagerPollCreateScreen(
              pollId: pollId,
            ),
      ),
    );

    if (result == true) {
      await loadPolls();
    }
  }

  // =====================================================
  // مشاهده جزئیات
  // =====================================================

  Future<void> showPollDetail(
      Map<String, dynamic> poll,
      ) async {
    final int? pollId =
    int.tryParse(
      poll['id']?.toString() ?? '',
    );

    if (pollId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'شناسه نظرسنجی نامعتبر است.',
            ),
            behavior:
            SnackBarBehavior.floating,
          ),
        );

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ManagerPollDetailScreen(
              pollId: pollId,
            ),
      ),
    );
  }

  // =====================================================
  // نمایش نتایج
  // =====================================================

  Future<void> showResults(
      Map<String, dynamic> poll,
      ) async {
    final int? pollId =
    int.tryParse(
      poll['id']?.toString() ?? '',
    );

    if (pollId == null) {
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final result =
      await pollService.getPollResults(
        pollId,
      );

      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      await _showResultsDialog(
        result,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _cleanError(e),
            ),
            behavior:
            SnackBarBehavior.floating,
          ),
        );
    }
  }

  // =====================================================
  // دیالوگ نتایج
  // =====================================================

  Future<void> _showResultsDialog(
      Map<String, dynamic> result,
      ) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection:
          TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'نتایج نظرسنجی',
            ),
            content: SizedBox(
              width: 500,
              child:
              SingleChildScrollView(
                child:
                _buildResultsContent(
                  result,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                },
                child: const Text(
                  'بستن',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // محتوای نتایج
  // =====================================================

  Widget _buildResultsContent(
      Map<String, dynamic> result,
      ) {
    final questions =
    result['questions'];

    if (questions is List &&
        questions.isNotEmpty) {
      return Column(
        children: List.generate(
          questions.length,
              (index) {
            return _buildQuestionResult(
              questions[index],
              index,
            );
          },
        ),
      );
    }

    return const Padding(
      padding:
      EdgeInsets.symmetric(
        vertical: 20,
      ),
      child: Center(
        child: Text(
          'نتیجه‌ای برای نمایش وجود ندارد.',
        ),
      ),
    );
  }

  // =====================================================
  // نتیجه سؤال
  // =====================================================

  Widget _buildQuestionResult(
      dynamic question,
      int index,
      ) {
    if (question is! Map) {
      return const SizedBox.shrink();
    }

    final title =
        question['title'] ??
            question['question'] ??
            '';

    final choices =
    question['choices'];

    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
      const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius:
        BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            '${toPersianDigits(index + 1)}. $title',
            style: const TextStyle(
              fontWeight:
              FontWeight.bold,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 10),

          if (choices is List)
            ...List.generate(
              choices.length,
                  (choiceIndex) {
                return _resultItem(
                  choices[choiceIndex],
                );
              },
            ),
        ],
      ),
    );
  }

  // =====================================================
  // آیتم نتیجه
  // =====================================================

  Widget _resultItem(
      dynamic choice,
      ) {
    if (choice is! Map) {
      return const SizedBox.shrink();
    }

    final title =
        choice['title'] ??
            choice['choice'] ??
            choice['text'] ??
            '';

    final count =
        choice['vote_count'] ??
            choice['votes'] ??
            choice['count'] ??
            0;

    final percentage =
        choice['percentage'] ??
            choice['percent'] ??
            0;

    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toString(),
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ),

          Text(
            '${toPersianDigits(count)} رأی',
            style: const TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(width: 8),

          Text(
            '${toPersianDigits(percentage)}٪',
            style: const TextStyle(
              fontSize: 12,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // ارقام فارسی
  // =====================================================

  String toPersianDigits(
      dynamic value,
      ) {
    String text =
        value?.toString() ?? '';

    const english =
        '0123456789';

    const persian =
        '۰۱۲۳۴۵۶۷۸۹';

    for (int i = 0;
    i < english.length;
    i++) {
      text = text.replaceAll(
        english[i],
        persian[i],
      );
    }

    return text;
  }

  // =====================================================
  // عنوان نظرسنجی
  // =====================================================

  String pollTitle(
      Map<String, dynamic> poll,
      ) {
    final value =
    poll['title'];

    if (value == null ||
        value.toString().trim().isEmpty) {
      return 'بدون عنوان';
    }

    return value.toString();
  }

  // =====================================================
  // وضعیت فعال
  // =====================================================

  bool isActive(
      Map<String, dynamic> poll,
      ) {
    final value =
    poll['is_active'];

    if (value is bool) {
      return value;
    }

    if (value is String) {
      return value.toLowerCase() ==
          'true' ||
          value == '1';
    }

    return false;
  }

  // =====================================================
  // آیا رأی دارد؟
  // =====================================================

  bool hasVotes(
      Map<String, dynamic> poll,
      ) {
    final value =
    poll['has_votes'];

    if (value is bool) {
      return value;
    }

    final voteCount =
        poll['vote_count'] ??
            poll['votes_count'] ??
            poll['participant_count'] ??
            0;

    return (int.tryParse(
      voteCount.toString(),
    ) ??
        0) >
        0;
  }

  // =====================================================
  // کارت نظرسنجی
  // =====================================================

  Widget buildPollCard(
      Map<String, dynamic> poll,
      ) {
    final active =
    isActive(poll);

    final voted =
    hasVotes(poll);

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // =================================================
            // عنوان
            // =================================================

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration:
                  BoxDecoration(
                    color: primaryColor,
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: const Icon(
                    Icons.poll_outlined,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        pollTitle(poll),
                        style:
                        const TextStyle(
                          fontSize: 15,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration:
                        BoxDecoration(
                          color: active
                              ? Colors.green
                              .withOpacity(
                            0.10,
                          )
                              : Colors.red
                              .withOpacity(
                            0.10,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            7,
                          ),
                        ),
                        child: Text(
                          active
                              ? 'فعال'
                              : 'غیرفعال',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                            FontWeight.bold,
                            color: active
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (voted) ...[
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                  Colors.orange.shade50,
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color:
                      Colors.orange.shade800,
                    ),

                    const SizedBox(width: 7),

                    const Expanded(
                      child: Text(
                        'برای این نظرسنجی رأی ثبت شده است.',
                        style: TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // =================================================
            // ردیف اول
            // =================================================

            Row(
              children: [
                if (!voted)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                      isProcessing
                          ? null
                          : () => editPoll(
                        poll,
                      ),
                      icon:
                      const Icon(
                        Icons.edit_outlined,
                        size: 18,
                      ),
                      label:
                      const Text(
                        'ویرایش',
                      ),
                      style:
                      OutlinedButton.styleFrom(
                        foregroundColor:
                        primaryColor,
                        side:
                        const BorderSide(
                          color:
                          primaryColor,
                        ),
                      ),
                    ),
                  ),

                if (!voted)
                  const SizedBox(width: 8),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                    isProcessing
                        ? null
                        : () => togglePoll(
                      poll,
                    ),
                    icon: Icon(
                      active
                          ? Icons
                          .toggle_on_outlined
                          : Icons
                          .toggle_off_outlined,
                      size: 20,
                    ),
                    label: Text(
                      active
                          ? 'غیرفعال'
                          : 'فعال',
                    ),
                    style:
                    OutlinedButton.styleFrom(
                      foregroundColor:
                      active
                          ? Colors.orange
                          : Colors.green,
                      side: BorderSide(
                        color: active
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // =================================================
            // ردیف دوم
            // =================================================

            Row(
              children: [
                if (!voted)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                      isProcessing
                          ? null
                          : () => deletePoll(
                        poll,
                      ),
                      icon:
                      const Icon(
                        Icons.delete_outline,
                        size: 18,
                      ),
                      label:
                      const Text(
                        'حذف',
                      ),
                      style:
                      OutlinedButton.styleFrom(
                        foregroundColor:
                        Colors.red,
                        side:
                        const BorderSide(
                          color:
                          Colors.red,
                        ),
                      ),
                    ),
                  ),

                if (!voted)
                  const SizedBox(width: 8),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                    isProcessing
                        ? null
                        : () => showResults(
                      poll,
                    ),
                    icon:
                    const Icon(
                      Icons.bar_chart_outlined,
                      size: 18,
                    ),
                    label:
                    const Text(
                      'نتایج',
                    ),
                    style:
                    OutlinedButton.styleFrom(
                      foregroundColor:
                      primaryColor,
                      side:
                      const BorderSide(
                        color:
                        primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // =================================================
            // مشاهده جزئیات
            // =================================================

            SizedBox(
              width: double.infinity,
              child:
              OutlinedButton.icon(
                onPressed:
                isProcessing
                    ? null
                    : () =>
                    showPollDetail(
                      poll,
                    ),
                icon:
                const Icon(
                  Icons.info_outline,
                  size: 18,
                ),
                label:
                const Text(
                  'مشاهده جزئیات',
                ),
                style:
                OutlinedButton.styleFrom(
                  foregroundColor:
                  primaryColor,
                  side:
                  const BorderSide(
                    color: primaryColor,
                  ),
                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // Build
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
        const Color(0xffF5F7F8),

        appBar: AppBar(
          title: const Text(
            'نظرسنجی‌ها',
          ),
          centerTitle: true,
          backgroundColor:
          primaryColor,
          foregroundColor:
          Colors.white,
          elevation: 0,

          actions: [
            IconButton(
              onPressed:
              isLoading
                  ? null
                  : loadPolls,
              icon: const Icon(
                Icons.refresh,
              ),
              tooltip: 'بروزرسانی',
            ),
          ],
        ),

        floatingActionButton:
        FloatingActionButton.extended(
          onPressed:
          isProcessing
              ? null
              : createPoll,
          backgroundColor:
          primaryColor,
          foregroundColor:
          Colors.white,
          icon: const Icon(
            Icons.add,
          ),
          label: const Text(
            'نظرسنجی جدید',
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
          color: primaryColor,
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding:
          const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color:
                Colors.red.shade300,
              ),

              const SizedBox(height: 16),

              Text(
                errorMessage!,
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed:
                loadPolls,
                icon: const Icon(
                  Icons.refresh,
                ),
                label: const Text(
                  'تلاش مجدد',
                ),
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  primaryColor,
                  foregroundColor:
                  Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (polls.isEmpty) {
      return RefreshIndicator(
        color: primaryColor,
        onRefresh: loadPolls,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 150),
            Center(
              child: Text(
                'هنوز نظرسنجی‌ای ثبت نشده است.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: loadPolls,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ),
        itemCount: polls.length,
        itemBuilder:
            (context, index) {
          return buildPollCard(
            polls[index],
          );
        },
      ),
    );
  }
}