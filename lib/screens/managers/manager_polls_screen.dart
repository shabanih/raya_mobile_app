import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/manager_poll_service.dart';

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

  // =====================================================
  // Service
  // =====================================================

  late final ManagerPollService pollService;

  // =====================================================
  // وضعیت
  // =====================================================

  bool isLoading = true;

  bool isProcessing = false;

  String? errorMessage;

  List<Map<String, dynamic>> polls = [];

  // =====================================================
  // رنگ اصلی
  // =====================================================

  static const Color primaryColor =
  Color(0xff00838F);

  // =====================================================
  // Init
  // =====================================================

  @override
  void initState() {
    super.initState();

    pollService = ManagerPollService(
      apiService: ApiService(),
    );

    loadPolls();
  }

  // =====================================================
  // دریافت نظرسنجی‌ها
  // =====================================================

  Future<void> loadPolls() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final result = await pollService.getPolls();

      if (!mounted) {
        return;
      }

      setState(() {
        polls = result;
        isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'MANAGER POLLS ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        errorMessage =
            _errorMessage(e);
      });
    }
  }

  // =====================================================
  // متن خطا
  // =====================================================

  String _errorMessage(dynamic error) {
    final message =
    error.toString();

    if (message.startsWith(
      'Exception: ',
    )) {
      return message.substring(
        11,
      );
    }

    if (message.trim().isNotEmpty) {
      return message;
    }

    return 'دریافت نظرسنجی‌ها با خطا مواجه شد.';
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

    if (isProcessing) {
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

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
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

      await loadPolls();
    } catch (e) {
      debugPrint(
        'TOGGLE POLL ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            _errorMessage(e),
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
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

    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'حذف نظرسنجی',
          ),
          content: const Text(
            'آیا از حذف این نظرسنجی مطمئن هستید؟',
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
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (isProcessing) {
      return;
    }

    try {
      setState(() {
        isProcessing = true;
      });

      await pollService.deletePoll(
        pollId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'نظرسنجی با موفقیت حذف شد.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      await loadPolls();
    } catch (e) {
      debugPrint(
        'DELETE POLL ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            _errorMessage(e),
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  // =====================================================
  // ساخت نظرسنجی
  // =====================================================

  Future<void> createPoll() async {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'صفحه ساخت نظرسنجی در مرحله بعد اضافه می‌شود.',
        ),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // =====================================================
  // ویرایش
  // =====================================================

  Future<void> editPoll(
      Map<String, dynamic> poll,
      ) async {

    if (hasVotes(poll)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'این نظرسنجی دارای رأی است و امکان ویرایش ندارد.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'صفحه ویرایش نظرسنجی در مرحله بعد اضافه می‌شود.',
        ),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // =====================================================
  // نتایج
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

    try {
      setState(() {
        isProcessing = true;
      });

      final result =
      await pollService.getPollResults(
        pollId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isProcessing = false;
      });

      await _showResultsDialog(
        result,
      );
    } catch (e) {
      debugPrint(
        'POLL RESULTS ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            _errorMessage(e),
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =====================================================
  // نمایش نتایج
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
              width:
              double.maxFinite,
              child: SingleChildScrollView(
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

    final participantCount =
    result['participant_count'];

    final eligibleCount =
    result['eligible_count'];

    final notParticipatedCount =
    result[
    'not_participated_count'];

    final percentage =
    result['percentage'];

    final questions =
    result['questions'];

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        if (eligibleCount != null)
          _resultItem(
            'تعداد افراد مجاز',
            eligibleCount,
          ),

        if (participantCount != null)
          _resultItem(
            'تعداد شرکت‌کنندگان',
            participantCount,
          ),

        if (notParticipatedCount != null)
          _resultItem(
            'تعداد شرکت‌نکرده‌ها',
            notParticipatedCount,
          ),

        if (percentage != null)
          _resultItem(
            'درصد مشارکت',
            percentage,
          ),

        if (questions is List) ...[
          const SizedBox(
            height: 12,
          ),
          const Text(
            'نتایج سؤالات',
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          ...questions.map(
                (item) {
              if (item is Map) {
                return _buildQuestionResult(
                  Map<String, dynamic>.from(
                    item,
                  ),
                );
              }

              return const SizedBox();
            },
          ),
        ],
      ],
    );
  }

  // =====================================================
  // نتیجه یک مقدار
  // =====================================================

  Widget _resultItem(
      String title,
      dynamic value,
      ) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 7,
      ),
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(0xffF5F8FA),
        borderRadius:
        BorderRadius.circular(
          8,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style:
              const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
          Text(
            toPersianDigits(
              value.toString(),
            ),
            style:
            const TextStyle(
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // نتیجه سؤال
  // =====================================================

  Widget _buildQuestionResult(
      Map<String, dynamic> question,
      ) {

    final title =
        question['question'] ??
            question['title'] ??
            question['text'] ??
            'سؤال';

    final voteCount =
    question['vote_count'];

    final choices =
    question['choices'];

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
      const EdgeInsets.all(
        10,
      ),
      decoration:
      BoxDecoration(
        border:
        Border.all(
          color:
          const Color(
            0xffECEFF1,
          ),
        ),
        borderRadius:
        BorderRadius.circular(
          10,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            title.toString(),
            style:
            const TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          if (voteCount != null) ...[
            const SizedBox(
              height: 6,
            ),
            Text(
              'تعداد رأی: '
                  '${toPersianDigits(voteCount.toString())}',
              style:
              const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],

          if (choices is List) ...[
            const SizedBox(
              height: 8,
            ),
            ...choices.map(
                  (choice) {
                if (choice is Map) {
                  final map =
                  Map<String, dynamic>.from(
                    choice,
                  );

                  final name =
                      map['choice'] ??
                          map['text'] ??
                          map['title'] ??
                          '';

                  final count =
                      map['vote_count'] ??
                          map['count'];

                  final percent =
                  map['percentage'];

                  return Padding(
                    padding:
                    const EdgeInsets.only(
                      bottom: 5,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.toString(),
                            style:
                            const TextStyle(
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (count != null)
                          Text(
                            toPersianDigits(
                              count.toString(),
                            ),
                            style:
                            const TextStyle(
                              fontSize: 11,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        if (percent != null)
                          Padding(
                            padding:
                            const EdgeInsets.only(
                              right: 8,
                            ),
                            child: Text(
                              '${toPersianDigits(percent.toString())}٪',
                              style:
                              const TextStyle(
                                fontSize: 10,
                                color:
                                Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
          ],
        ],
      ),
    );
  }

  // =====================================================
  // تبدیل اعداد
  // =====================================================

  String toPersianDigits(
      String value,
      ) {
    const english =
        '0123456789';

    const persian =
        '۰۱۲۳۴۵۶۷۸۹';

    for (
    int i = 0;
    i < english.length;
    i++
    ) {
      value = value.replaceAll(
        english[i],
        persian[i],
      );
    }

    return value;
  }

  // =====================================================
  // عنوان نظرسنجی
  // =====================================================

  String pollTitle(
      Map<String, dynamic> poll,
      ) {

    final value =
        poll['title'] ??
            poll['name'] ??
            'بدون عنوان';

    return value
        .toString()
        .trim();
  }

  // =====================================================
  // وضعیت فعال
  // =====================================================

  bool isActive(
      Map<String, dynamic> poll,
      ) {
    return poll['is_active'] == true;
  }

  // =====================================================
  // آیا رأی دارد؟
  // =====================================================

  bool hasVotes(
      Map<String, dynamic> poll,
      ) {
    return poll['has_votes'] == true;
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
        bottom: 12,
      ),
      padding:
      const EdgeInsets.all(
        14,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border:
        Border.all(
          color:
          const Color(
            0xffECEFF1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [

          Row(
            children: [

              Container(
                width: 46,
                height: 46,
                decoration:
                BoxDecoration(
                  color:
                  primaryColor
                      .withOpacity(
                    0.10,
                  ),
                  shape:
                  BoxShape.circle,
                ),
                child:
                const Icon(
                  Icons.poll_outlined,
                  color:
                  primaryColor,
                  size: 25,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child:
                Text(
                  pollTitle(
                    poll,
                  ),
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    Color(
                      0xff263238,
                    ),
                  ),
                ),
              ),

              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration:
                BoxDecoration(
                  color: active
                      ? Colors.green
                      .withOpacity(
                    0.10,
                  )
                      : Colors.grey
                      .withOpacity(
                    0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
                child:
                Text(
                  active
                      ? 'فعال'
                      : 'غیرفعال',
                  style:
                  TextStyle(
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w600,
                    color: active
                        ? Colors.green
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          if (voted)
            Row(
              children: [

                const Icon(
                  Icons.how_to_vote_outlined,
                  size: 17,
                  color: Colors.grey,
                ),

                const SizedBox(
                  width: 6,
                ),

                const Expanded(
                  child:
                  Text(
                    'برای این نظرسنجی رأی ثبت شده است.',
                    style:
                    TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(
            height: 10,
          ),

          Row(
            children: [

              if (!voted)
                Expanded(
                  child:
                  OutlinedButton.icon(
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
                const SizedBox(
                  width: 8,
                ),

              Expanded(
                child:
                OutlinedButton.icon(
                  onPressed:
                  isProcessing
                      ? null
                      : () => togglePoll(
                    poll,
                  ),
                  icon:
                  Icon(
                    active
                        ? Icons
                        .pause_circle_outline
                        : Icons
                        .play_circle_outline,
                    size: 18,
                  ),
                  label:
                  Text(
                    active
                        ? 'غیرفعال کردن'
                        : 'فعال کردن',
                  ),
                  style:
                  OutlinedButton.styleFrom(
                    foregroundColor:
                    active
                        ? Colors.orange
                        : Colors.green,
                    side:
                    BorderSide(
                      color:
                      active
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          Row(
            children: [

              if (!voted)
                Expanded(
                  child:
                  OutlinedButton.icon(
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
                const SizedBox(
                  width: 8,
                ),

              Expanded(
                child:
                OutlinedButton.icon(
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
                    const Color(
                      0xff3949AB,
                    ),
                    side:
                    const BorderSide(
                      color:
                      Color(
                        0xff3949AB,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
      child:
      Scaffold(
        backgroundColor:
        const Color(
          0xffF5F8FA,
        ),

        appBar:
        AppBar(
          backgroundColor:
          primaryColor,
          foregroundColor:
          Colors.white,
          elevation: 0,
          title:
          const Text(
            'مدیریت نظرسنجی',
            style:
            TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          centerTitle:
          true,
        ),

        floatingActionButton:
        FloatingActionButton(
          onPressed:
          isProcessing
              ? null
              : createPoll,
          backgroundColor:
          primaryColor,
          foregroundColor:
          Colors.white,
          child:
          const Icon(
            Icons.add,
          ),
        ),

        body:
        RefreshIndicator(
          color:
          primaryColor,
          onRefresh:
          loadPolls,
          child:
          _buildBody(),
        ),
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
          primaryColor,
        ),
      );
    }

    if (errorMessage != null) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: [

          const SizedBox(
            height: 180,
          ),

          Icon(
            Icons.error_outline,
            size: 55,
            color:
            Colors.grey.shade400,
          ),

          const SizedBox(
            height: 12,
          ),

          Center(
            child:
            Padding(
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 25,
              ),
              child:
              Text(
                errorMessage!,
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          Center(
            child:
            ElevatedButton(
              onPressed:
              loadPolls,
              child:
              const Text(
                'تلاش مجدد',
              ),
            ),
          ),
        ],
      );
    }

    if (polls.isEmpty) {
      return ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: [

          const SizedBox(
            height: 170,
          ),

          Center(
            child:
            Container(
              width: 80,
              height: 80,
              decoration:
              BoxDecoration(
                color:
                primaryColor
                    .withOpacity(
                  0.10,
                ),
                shape:
                BoxShape.circle,
              ),
              child:
              const Icon(
                Icons.poll_outlined,
                size: 42,
                color:
                primaryColor,
              ),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          const Center(
            child:
            Text(
              'هنوز نظرسنجی‌ای ایجاد نشده است.',
              style:
              TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          const Center(
            child:
            Text(
              'برای ایجاد نظرسنجی از دکمه + استفاده کنید.',
              style:
              TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding:
      const EdgeInsets.fromLTRB(
        12,
        16,
        12,
        90,
      ),
      itemCount:
      polls.length,
      itemBuilder:
          (
          context,
          index,
          ) {
        return buildPollCard(
          polls[index],
        );
      },
    );
  }
}