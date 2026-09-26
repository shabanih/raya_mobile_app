import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/manager_message_service.dart';
import 'manager_create_message_screen.dart';
import 'manager_message_detail_screen.dart';
import 'manager_message_recipients_screen.dart';

class ManagerMessagesScreen extends StatefulWidget {
  const ManagerMessagesScreen({super.key});

  @override
  State<ManagerMessagesScreen> createState() =>
      _ManagerMessagesScreenState();
}

class _ManagerMessagesScreenState
    extends State<ManagerMessagesScreen> {
  final ManagerMessageService _service =
  ManagerMessageService();

  final TextEditingController _searchController =
  TextEditingController();

  Timer? _searchTimer;

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // Load messages
  // ------------------------------------------------------------

  Future<void> _loadMessages({
    bool showLoading = true,
  }) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _service.getMessages(
        query: _searchController.text.trim(),
      );

      final dynamic results = response['results'];

      final List<Map<String, dynamic>> loadedMessages = [];

      if (results is List) {
        for (final item in results) {
          if (item is Map) {
            loadedMessages.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      if (!mounted) return;

      setState(() {
        _messages = loadedMessages;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanExceptionMessage(e);
      });
    }
  }

  // ------------------------------------------------------------
  // Search
  // ------------------------------------------------------------

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();

    _searchTimer = Timer(
      const Duration(milliseconds: 400),
          () {
        _loadMessages();
      },
    );
  }

  // ------------------------------------------------------------
  // Create message
  // ------------------------------------------------------------

  Future<void> _createMessage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const ManagerCreateMessageScreen(),
      ),
    );

    if (result == true) {
      await _loadMessages();
    }
  }

  // ------------------------------------------------------------
  // Edit message
  // ------------------------------------------------------------

  Future<void> _editMessage(
      Map<String, dynamic> message,
      ) async {
    final dynamic idValue = message['id'];

    final int? messageId =
    int.tryParse(idValue?.toString() ?? '');

    if (messageId == null) {
      _showError('شناسه پیام پیدا نشد.');
      return;
    }

    final String initialTitle =
        message['title']?.toString() ?? '';

    final String initialMessage =
        message['message']?.toString() ?? '';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _EditMessageSheet(
          initialTitle: initialTitle,
          initialMessage: initialMessage,
          onSave: (
              String title,
              String messageText,
              ) async {
            try {
              await _service.updateMessage(
                messageId: messageId,
                title: title,
                message: messageText,
              );

              if (!mounted) return;

              Navigator.pop(context);

              _showSuccess(
                'پیام با موفقیت ویرایش شد.',
              );

              await _loadMessages(
                showLoading: false,
              );
            } catch (e) {
              if (!mounted) return;

              _showError(
                _cleanExceptionMessage(e),
              );
            }
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // Delete message
  // ------------------------------------------------------------

  Future<void> _deleteMessage(
      Map<String, dynamic> message,
      ) async {
    final dynamic idValue = message['id'];

    final int? messageId =
    int.tryParse(idValue?.toString() ?? '');

    if (messageId == null) {
      _showError('شناسه پیام پیدا نشد.');
      return;
    }

    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'حذف پیام',
            ),
            content: const Text(
              'آیا از حذف این پیام اطمینان دارید؟',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    false,
                  );
                },
                child: const Text(
                  'انصراف',
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                    true,
                  );
                },
                style: FilledButton.styleFrom(
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

    try {
      await _service.deleteMessage(
        messageId,
      );

      if (!mounted) return;

      _showSuccess(
        'پیام با موفقیت حذف شد.',
      );

      await _loadMessages(
        showLoading: false,
      );
    } catch (e) {
      if (!mounted) return;

      _showError(
        _cleanExceptionMessage(e),
      );
    }
  }

  // ------------------------------------------------------------
  // Send message
  // ------------------------------------------------------------

  Future<void> _sendMessage(
      Map<String, dynamic> message,
      ) async {
    final dynamic idValue = message['id'];

    final int? messageId =
    int.tryParse(idValue?.toString() ?? '');

    if (messageId == null) {
      _showError(
        'شناسه پیام پیدا نشد.',
      );
      return;
    }

    // بدون نمایش هشدار، مستقیماً وارد صفحه انتخاب گیرندگان می‌شویم.
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ManagerMessageRecipientsScreen(
              messageId: messageId,
            ),
      ),
    );

    // اگر ارسال با موفقیت انجام شد،
    // لیست پیام‌ها را دوباره دریافت می‌کنیم.
    if (result == true) {
      await _loadMessages();
    }
  }

  // ------------------------------------------------------------
  // View message
  // ------------------------------------------------------------

  Future<void> _viewMessage(
      Map<String, dynamic> message,
      ) async {
    final dynamic idValue = message['id'];

    final int? messageId =
    int.tryParse(idValue?.toString() ?? '');

    if (messageId == null) {
      _showError(
        'شناسه پیام پیدا نشد.',
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ManagerMessageDetailScreen(
              messageId: messageId,
            ),
      ),
    );
  }

  // ------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------

  String _cleanExceptionMessage(
      Object error,
      ) {
    final String value =
    error.toString().trim();

    if (value.startsWith('Exception:')) {
      return value.substring(
        'Exception:'.length,
      ).trim();
    }

    return value.isEmpty
        ? 'خطایی رخ داده است.'
        : value;
  }

  void _showError(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textDirection:
            TextDirection.rtl,
          ),
          backgroundColor:
          Colors.red.shade700,
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }

  void _showSuccess(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textDirection:
            TextDirection.rtl,
          ),
          backgroundColor:
          Colors.green.shade700,
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }

  String _normalizeDigits(
      String value,
      ) {
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

  String _formatNumber(
      dynamic value,
      ) {
    if (value == null) {
      return '۰';
    }

    final String normalized =
    _normalizeDigits(
      value.toString(),
    );

    final int? number =
    int.tryParse(normalized);

    if (number == null) {
      return value.toString();
    }

    return _toPersianDigits(
      number.toString(),
    );
  }

  String _toPersianDigits(
      String value,
      ) {
    return value
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

  String _formatDate(
      dynamic value,
      ) {
    if (value == null) {
      return '';
    }

    final String text =
    value.toString().trim();

    if (text.isEmpty) {
      return '';
    }

    try {
      final DateTime date =
      DateTime.parse(text).toLocal();

      final String year =
      _toPersianDigits(
        date.year.toString(),
      );

      final String month =
      _toPersianDigits(
        date.month
            .toString()
            .padLeft(2, '0'),
      );

      final String day =
      _toPersianDigits(
        date.day
            .toString()
            .padLeft(2, '0'),
      );

      final String hour =
      _toPersianDigits(
        date.hour
            .toString()
            .padLeft(2, '0'),
      );

      final String minute =
      _toPersianDigits(
        date.minute
            .toString()
            .padLeft(2, '0'),
      );

      return '$year/$month/$day - $hour:$minute';
    } catch (_) {
      return text;
    }
  }

  // ------------------------------------------------------------
  // Build
  // ------------------------------------------------------------

  @override
  Widget build(
      BuildContext context,
      ) {
    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'مدیریت پیام‌ها',
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: () =>
              _loadMessages(),
          child: _buildBody(),
        ),
        floatingActionButton:
        FloatingActionButton.extended(
          onPressed:
          _createMessage,
          backgroundColor:
          const Color(
            0xff5E35B1,
          ),
          foregroundColor:
          Colors.white,
          icon: const Icon(
            Icons.add,
          ),
          label: const Text(
            'پیام جدید',
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        100,
      ),
      children: [
        _buildSearchBox(),
        const SizedBox(
          height: 16,
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.only(
              top: 80,
            ),
            child: Center(
              child:
              CircularProgressIndicator(),
            ),
          )
        else if (_errorMessage != null)
          _buildErrorState()
        else if (_messages.isEmpty)
            _buildEmptyState()
          else
            ..._messages.map(
              _buildMessageCard,
            ),
      ],
    );
  }

  // ------------------------------------------------------------
  // Search box
  // ------------------------------------------------------------

  Widget _buildSearchBox() {
    return TextField(
      controller:
      _searchController,
      onChanged:
      _onSearchChanged,
      textDirection:
      TextDirection.rtl,
      decoration:
      InputDecoration(
        hintText:
        'جستجو در عنوان یا متن پیام...',
        prefixIcon:
        const Icon(
          Icons.search,
        ),
        suffixIcon:
        _searchController.text
            .trim()
            .isNotEmpty
            ? IconButton(
          onPressed: () {
            _searchController.clear();
            _loadMessages();
            setState(() {});
          },
          icon:
          const Icon(
            Icons.clear,
          ),
        )
            : null,
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
          borderSide:
          const BorderSide(
            color:
            Color(0xff5E35B1),
            width: 2,
          ),
        ),
        filled: true,
        fillColor:
        Colors.white,
      ),
    );
  }

  // ------------------------------------------------------------
  // Error
  // ------------------------------------------------------------

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 60,
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color:
            Colors.red.shade400,
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            _errorMessage ??
                'خطایی رخ داده است.',
            textAlign:
            TextAlign.center,
          ),
          const SizedBox(
            height: 20,
          ),
          FilledButton.icon(
            onPressed:
            _loadMessages,
            style:
            FilledButton.styleFrom(
              backgroundColor:
              const Color(
                0xff5E35B1,
              ),
              foregroundColor:
              Colors.white,
            ),
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'تلاش مجدد',
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Empty
  // ------------------------------------------------------------

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 70,
      ),
      child: Column(
        children: [
          Icon(
            Icons.mark_unread_chat_alt_outlined,
            size: 72,
            color:
            Colors.grey.shade400,
          ),
          const SizedBox(
            height: 18,
          ),
          const Text(
            'هنوز پیامی ایجاد نشده است.',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w600,
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            'برای ایجاد اولین پیام، روی «پیام جدید» بزنید.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color:
              Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Message card
  // ------------------------------------------------------------

  Widget _buildMessageCard(
      Map<String, dynamic> message,
      ) {
    final bool isSent =
        message['send_notification'] ==
            true;

    final String title =
        message['title']
            ?.toString()
            .trim() ??
            '';

    final String messageText =
        message['message']
            ?.toString()
            .trim() ??
            '';

    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),
      elevation: 1.5,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(
          16,
        ),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment
              .stretch,
          children: [
            Row(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration:
                  BoxDecoration(
                    color: isSent
                        ? Colors.green
                        .withOpacity(
                      0.12,
                    )
                        : Colors.orange
                        .withOpacity(
                      0.12,
                    ),
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
                    ),
                  ),
                  child: Icon(
                    isSent
                        ? Icons
                        .mark_email_read_outlined
                        : Icons
                        .drafts_outlined,
                    color: isSent
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child:
                            Text(
                              title.isEmpty
                                  ? 'بدون عنوان'
                                  : title,
                              maxLines:
                              2,
                              overflow:
                              TextOverflow
                                  .ellipsis,
                              style:
                              const TextStyle(
                                fontSize:
                                16,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          _buildStatusChip(
                            isSent,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 7,
                      ),
                      Text(
                        _formatDate(
                          isSent
                              ? message[
                          'send_notification_date']
                              : message[
                          'created_at'],
                        ),
                        style:
                        TextStyle(
                          fontSize:
                          12,
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 14,
            ),
            Container(
              width:
              double.infinity,
              padding:
              const EdgeInsets.all(
                12,
              ),
              decoration:
              BoxDecoration(
                color: Colors
                    .grey
                    .shade50,
                borderRadius:
                BorderRadius
                    .circular(
                  12,
                ),
              ),
              child: Text(
                messageText.isEmpty
                    ? 'بدون متن'
                    : messageText,
                maxLines: 4,
                overflow:
                TextOverflow
                    .ellipsis,
                style:
                const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                ),
              ),
            ),
            if (isSent) ...[
              const SizedBox(
                height: 14,
              ),
              _buildSentStatistics(
                message,
              ),
            ],
            const SizedBox(
              height: 14,
            ),
            _buildActions(
              message,
              isSent,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // Status chip
  // ------------------------------------------------------------

  Widget _buildStatusChip(
      bool isSent,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration:
      BoxDecoration(
        color: isSent
            ? Colors.green
            .withOpacity(
          0.12,
        )
            : Colors.orange
            .withOpacity(
          0.12,
        ),
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      child: Text(
        isSent
            ? 'ارسال شده'
            : 'آماده ارسال',
        style: TextStyle(
          fontSize: 11,
          fontWeight:
          FontWeight.w700,
          color: isSent
              ? Colors.green
              : Colors.orange
              .shade800,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // Statistics
  // ------------------------------------------------------------

  Widget _buildSentStatistics(
      Map<String, dynamic> message,
      ) {
    final dynamic recipientCount =
    message[
    'recipient_count'];

    final dynamic readCount =
    message['read_count'];

    final dynamic unreadCount =
    message[
    'unread_count'];

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10,
      ),
      decoration:
      BoxDecoration(
        color: Colors.green
            .withOpacity(
          0.06,
        ),
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: Colors.green
              .withOpacity(
            0.15,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatisticItem(
              icon: Icons
                  .people_outline,
              title: 'گیرندگان',
              value:
              _formatNumber(
                recipientCount,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 35,
            color:
            Colors.grey.shade300,
          ),
          Expanded(
            child: _buildStatisticItem(
              icon: Icons
                  .done_all,
              title: 'خوانده شده',
              value:
              _formatNumber(
                readCount,
              ),
              iconColor:
              Colors.green,
            ),
          ),
          Container(
            width: 1,
            height: 35,
            color:
            Colors.grey.shade300,
          ),
          Expanded(
            child: _buildStatisticItem(
              icon: Icons
                  .mark_email_unread_outlined,
              title: 'خوانده نشده',
              value:
              _formatNumber(
                unreadCount,
              ),
              iconColor:
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticItem({
    required IconData icon,
    required String title,
    required String value,
    Color? iconColor,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 19,
          color:
          iconColor ??
              const Color(
                0xff5E35B1,
              ),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          value,
          style:
          const TextStyle(
            fontSize: 14,
            fontWeight:
            FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 2,
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color:
            Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------

  Widget _buildActions(
      Map<String, dynamic> message,
      bool isSent,
      ) {
    if (isSent) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () =>
              _viewMessage(message),
          icon: const Icon(
            Icons.visibility_outlined,
            size: 18,
          ),
          label: const Text(
            'مشاهده جزئیات',
          ),
          style:
          OutlinedButton.styleFrom(
            foregroundColor:
            const Color(
              0xff5E35B1,
            ),
            side: const BorderSide(
              color:
              Color(0xff5E35B1),
            ),
            padding:
            const EdgeInsets
                .symmetric(
              vertical: 12,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                _editMessage(
                  message,
                ),
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
            ),
            label: const Text(
              'ویرایش',
            ),
            style:
            OutlinedButton.styleFrom(
              foregroundColor:
              const Color(
                0xff5E35B1,
              ),
              side: const BorderSide(
                color:
                Color(0xff5E35B1),
              ),
              padding:
              const EdgeInsets
                  .symmetric(
                vertical: 11,
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        SizedBox(
          width: 48,
          height: 44,
          child: OutlinedButton(
            onPressed: () =>
                _deleteMessage(
                  message,
                ),
            style:
            OutlinedButton.styleFrom(
              foregroundColor:
              Colors.red,
              side: const BorderSide(
                color: Colors.red,
              ),
              padding:
              EdgeInsets.zero,
            ),
            child: const Icon(
              Icons.delete_outline,
              size: 20,
            ),
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          child: FilledButton.icon(
            onPressed: () =>
                _sendMessage(
                  message,
                ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff00ACC1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
              vertical: 11,
              ),

            ),
            icon: const Icon(
              Icons.send_outlined,
              size: 18,
            ),
            label: const Text(
              'ارسال',
            ),
          ),
        ),
      ],
    );
  }
}

// ===================================================================
// Edit Message Sheet
// ===================================================================

class _EditMessageSheet
    extends StatefulWidget {
  final String initialTitle;
  final String initialMessage;

  final Future<void> Function(
      String title,
      String message,
      ) onSave;

  const _EditMessageSheet({
    required this.initialTitle,
    required this.initialMessage,
    required this.onSave,
  });

  @override
  State<_EditMessageSheet> createState() =>
      _EditMessageSheetState();
}

class _EditMessageSheetState
    extends State<_EditMessageSheet> {
  late final TextEditingController
  _titleController;

  late final TextEditingController
  _messageController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _titleController =
        TextEditingController(
          text: widget.initialTitle,
        );

    _messageController =
        TextEditingController(
          text: widget.initialMessage,
        );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String title =
    _titleController.text.trim();

    final String message =
    _messageController.text.trim();

    if (title.isEmpty) {
      _showError(
        'عنوان پیام را وارد کنید.',
      );
      return;
    }

    if (message.isEmpty) {
      _showError(
        'متن پیام را وارد کنید.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(
        title,
        message,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textDirection:
            TextDirection.rtl,
          ),
          backgroundColor:
          Colors.red.shade700,
          behavior:
          SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final double bottom =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: Container(
        padding:
        EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + bottom,
        ),
        decoration:
        const BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.vertical(
            top: Radius.circular(
              24,
            ),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .stretch,
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration:
                  BoxDecoration(
                    color: Colors
                        .grey
                        .shade300,
                    borderRadius:
                    BorderRadius
                        .circular(
                      10,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const Text(
                'ویرایش پیام',
                textAlign:
                TextAlign.center,
                style:
                TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              TextField(
                controller:
                _titleController,
                textDirection:
                TextDirection.rtl,
                textInputAction:
                TextInputAction.next,
                decoration:
                InputDecoration(
                  labelText:
                  'عنوان پیام',
                  hintText:
                  'عنوان پیام را وارد کنید',
                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
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
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 14,
              ),
              TextField(
                controller:
                _messageController,
                textDirection:
                TextDirection.rtl,
                minLines: 5,
                maxLines: 10,
                decoration:
                InputDecoration(
                  labelText:
                  'متن پیام',
                  hintText:
                  'متن پیام را وارد کنید',
                  alignLabelWithHint:
                  true,
                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius
                        .circular(
                      12,
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
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width:
                double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed:
                  _isSaving
                      ? null
                      : _save,
                  style:
                  FilledButton.styleFrom(
                    backgroundColor:
                    const Color(
                      0xff5E35B1,
                    ),
                    foregroundColor:
                    Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                    CircularProgressIndicator(
                      strokeWidth:
                      2,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Text(
                    'ذخیره تغییرات',
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