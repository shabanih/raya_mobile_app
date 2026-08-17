import 'package:flutter/material.dart';

import '../services/poll_service.dart';
import 'poll_detail_screen.dart';

class PollsScreen extends StatefulWidget {
  const PollsScreen({
    super.key,
  });

  @override
  State<PollsScreen> createState() =>
      _PollsScreenState();
}

class _PollsScreenState
    extends State<PollsScreen> {

  bool isLoading = true;

  String? errorMessage;

  List<Map<String, dynamic>> polls = [];

  @override
  void initState() {
    super.initState();

    loadPolls();
  }

  Future<void> loadPolls() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result =
      await PollService.getPolls();

      if (!mounted) return;

      setState(() {
        polls = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });
    }
  }

  String toPersianDigits(
      String value) {

    const english =
        '0123456789';

    const persian =
        '۰۱۲۳۴۵۶۷۸۹';

    for (int i = 0;
    i < english.length;
    i++) {
      value = value.replaceAll(
        english[i],
        persian[i],
      );
    }

    return value;
  }

  @override
  Widget build(
      BuildContext context) {

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
            'نظرسنجی‌ها',
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
              loadPolls,
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                    0xff00ACC1),
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

    if (polls.isEmpty) {
      return RefreshIndicator(
        color:
        const Color(0xff00ACC1),
        onRefresh:
        loadPolls,
        child: ListView(
          children: const [

            SizedBox(
              height: 180,
            ),

            Icon(
              Icons.poll_outlined,
              size: 70,
              color: Colors.grey,
            ),

            SizedBox(
              height: 15,
            ),

            Center(
              child: Text(
                'نظرسنجی فعالی وجود ندارد.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color:
      const Color(0xff00ACC1),
      onRefresh:
      loadPolls,
      child: ListView.builder(
        padding:
        const EdgeInsets.fromLTRB(
          18,
          20,
          18,
          30,
        ),
        itemCount:
        polls.length,
        itemBuilder:
            (context, index) {

          final poll =
          polls[index];

          return _PollCard(
            poll: poll,
            toPersianDigits:
            toPersianDigits,
          );
        },
      ),
    );
  }
}

class _PollCard
    extends StatelessWidget {

  final Map<String, dynamic> poll;

  final String Function(String)
  toPersianDigits;

  const _PollCard({
    required this.poll,
    required this.toPersianDigits,
  });

  @override
  Widget build(
      BuildContext context) {

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),

      padding:
      const EdgeInsets.all(17),

      decoration:
      BoxDecoration(
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

      child: InkWell(
        borderRadius:
        BorderRadius.circular(20),

        onTap: () {

          final id =
          poll['id'];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PollDetailScreen(
                    pollId: id,
                  ),
            ),
          );
        },

        child: Row(
          children: [

            Container(
              width: 48,
              height: 48,
              decoration:
              BoxDecoration(
                color:
                Colors.amber
                    .withOpacity(
                  0.15,
                ),
                shape:
                BoxShape.circle,
              ),
              child: const Icon(
                Icons.poll_outlined,
                color:
                Colors.amber,
                size: 27,
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
                    poll['title']
                        ?.toString() ??
                        '-',
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

                  if (poll['description'] !=
                      null) ...[

                    const SizedBox(
                      height: 5,
                    ),

                    Text(
                      poll['description']
                          .toString(),
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      const TextStyle(
                        fontSize: 13,
                        color:
                        Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const Icon(
              Icons.chevron_left_rounded,
              color: Colors.grey,
              size: 25,
            ),
          ],
        ),
      ),
    );
  }
}