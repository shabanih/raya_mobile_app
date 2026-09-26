import 'package:flutter/material.dart';

import '../../services/manager_message_service.dart';

class ManagerMessageRecipientsScreen extends StatefulWidget {
  final int messageId;

  const ManagerMessageRecipientsScreen({
    super.key,
    required this.messageId,
  });

  @override
  State<ManagerMessageRecipientsScreen> createState() =>
      _ManagerMessageRecipientsScreenState();
}

class _ManagerMessageRecipientsScreenState
    extends State<ManagerMessageRecipientsScreen> {
  final ManagerMessageService _service =
  ManagerMessageService();

  final TextEditingController _searchController =
  TextEditingController();

  List<Map<String, dynamic>> _recipients = [];

  final Set<String> _selectedRecipientKeys = {};

  bool _isLoading = true;
  bool _isSending = false;

  bool _sendToAll = true;

  String _recipientFilter = 'all';

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _loadRecipients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // تبدیل اعداد فارسی و عربی به انگلیسی
  // =========================================================

  String _normalizeDigits(String value) {
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
        .replaceAll('۹', '9')
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');
  }

  // =========================================================
  // نرمال‌سازی متن جستجو
  // =========================================================

  String _normalizeSearchText(String value) {
    var result = value.trim().toLowerCase();

    result = _normalizeDigits(result);

    result = result
        .replaceAll('ي', 'ی')
        .replaceAll('ى', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('ۀ', 'ه')
        .replaceAll('ة', 'ه');

    result = result.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    return result;
  }

  // =========================================================
  // دریافت لیست گیرندگان
  // =========================================================

  Future<void> _loadRecipients() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result =
      await _service.getUnits();

      final dynamic data =
          result['results'] ??
              result['data'] ??
              [];

      if (data is List) {
        _recipients = data
            .whereType<Map>()
            .map(
              (item) =>
          Map<String, dynamic>.from(item),
        )
            .toList();
      } else {
        _recipients = [];
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'خطا در دریافت لیست گیرندگان: $e',
            textDirection:
            TextDirection.rtl,
          ),
          backgroundColor:
          Colors.red,
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  // =========================================================
  // شناسه یکتا
  // =========================================================

  String _recipientKey(
      Map<String, dynamic> recipient,
      ) {
    final dynamic unitId =
        recipient['unit_id'] ??
            recipient['id'];

    final String type =
        recipient['recipient_type']
            ?.toString()
            .toLowerCase() ??
            'owner';

    return '$unitId-$type';
  }

  // =========================================================
  // نوع گیرنده
  // =========================================================

  String _recipientType(
      Map<String, dynamic> recipient,
      ) {
    final String type =
        recipient['recipient_type']
            ?.toString()
            .toLowerCase() ??
            'owner';

    if (type == 'renter') {
      return 'مستأجر';
    }

    return 'مالک';
  }

  // =========================================================
  // نام گیرنده
  // =========================================================

  String _recipientName(
      Map<String, dynamic> recipient,
      ) {
    final String name =
        recipient['recipient_name']
            ?.toString()
            .trim() ??
            '';

    if (name.isEmpty) {
      return 'بدون نام';
    }

    return name;
  }

  // =========================================================
  // موبایل
  // =========================================================

  String _mobile(
      Map<String, dynamic> recipient,
      ) {
    return recipient['mobile']
        ?.toString()
        .trim() ??
        '';
  }

  // =========================================================
  // شماره واحد
  // =========================================================

  String _unitNumber(
      Map<String, dynamic> recipient,
      ) {
    final dynamic unit =
        recipient['unit'] ??
            recipient['unit_number'] ??
            recipient['unit_id'] ??
            recipient['id'];

    if (unit == null) {
      return '-';
    }

    return unit.toString().trim();
  }

  // =========================================================
  // جستجو
  // =========================================================

  bool _matchesSearch(
      Map<String, dynamic> recipient,
      String search,
      ) {
    if (search.isEmpty) {
      return true;
    }

    final String unit =
    _normalizeSearchText(
      _unitNumber(recipient),
    );

    final String name =
    _normalizeSearchText(
      _recipientName(recipient),
    );

    final String mobile =
    _normalizeSearchText(
      _mobile(recipient),
    );

    return unit.contains(search) ||
        name.contains(search) ||
        mobile.contains(search);
  }

  // =========================================================
  // فیلتر + جستجو
  // =========================================================

  List<Map<String, dynamic>>
  _filteredRecipients() {
    final String search =
    _normalizeSearchText(
      _searchController.text,
    );

    return _recipients.where(
          (recipient) {
        final String type =
            recipient['recipient_type']
                ?.toString()
                .toLowerCase() ??
                'owner';

        if (_recipientFilter == 'owner' &&
            type != 'owner') {
          return false;
        }

        if (_recipientFilter == 'renter' &&
            type != 'renter') {
          return false;
        }

        return _matchesSearch(
          recipient,
          search,
        );
      },
    ).toList();
  }

  // =========================================================
  // انتخاب همه نتایج فعلی
  // =========================================================

  void _selectAllRecipients() {
    final List<Map<String, dynamic>>
    filtered =
    _filteredRecipients();

    setState(() {
      for (final recipient in filtered) {
        _selectedRecipientKeys.add(
          _recipientKey(recipient),
        );
      }
    });
  }

  // =========================================================
  // حذف انتخاب
  // =========================================================

  void _clearSelection() {
    setState(() {
      _selectedRecipientKeys.clear();
    });
  }

  // =========================================================
  // تغییر انتخاب
  // =========================================================

  void _toggleRecipient(
      Map<String, dynamic> recipient,
      ) {
    final String key =
    _recipientKey(recipient);

    setState(() {
      if (_selectedRecipientKeys
          .contains(key)) {
        _selectedRecipientKeys
            .remove(key);
      } else {
        _selectedRecipientKeys.add(key);
      }
    });
  }

  // =========================================================
  // ارسال پیام
  // =========================================================

  Future<void> _sendMessage() async {
    if (_isSending) {
      return;
    }

    if (!_sendToAll &&
        _selectedRecipientKeys.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'حداقل یک مالک یا مستأجر را انتخاب کنید.',
            textDirection:
            TextDirection.rtl,
          ),
        ),
      );

      return;
    }

    // فقط هشدار تأیید ارسال
    final bool confirmed =
    await _showSendConfirmation();

    if (!confirmed) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final List<Map<String, dynamic>>
      recipients = [];

      if (!_sendToAll) {
        for (final recipient
        in _recipients) {
          final String key =
          _recipientKey(recipient);

          if (!_selectedRecipientKeys
              .contains(key)) {
            continue;
          }

          recipients.add({
            'unit_id':
            recipient['unit_id'] ??
                recipient['id'],
            'type':
            recipient[
            'recipient_type'] ??
                'owner',
          });
        }
      }

      await _service.sendMessage(
        messageId: widget.messageId,
        sendToAll: _sendToAll,
        recipients: recipients,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'پیام با موفقیت ارسال شد.',
            textDirection:
            TextDirection.rtl,
          ),
          backgroundColor:
          Color(0xff00ACC1),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'خطا در ارسال پیام: $e',
            textDirection:
            TextDirection.rtl,
          ),
          backgroundColor:
          Colors.red,
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSending = false;
      });
    }
  }

  // =========================================================
  // هشدار تأیید ارسال
  // =========================================================

  Future<bool> _showSendConfirmation() async {
    final int count =
    _sendToAll
        ? _recipients.length
        : _selectedRecipientKeys.length;

    final bool? result =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection:
          TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'هشدار',
            ),
            content: Text(
              _sendToAll
                  ? 'پیام برای تمام گیرندگان دارای شماره موبایل ارسال می‌شود.\n\nتعداد گیرندگان: $count'
                  : 'پیام برای $count گیرنده انتخاب‌شده ارسال می‌شود.',
              textAlign:
              TextAlign.right,
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
                style:
                FilledButton.styleFrom(
                  backgroundColor:
                  const Color(
                    0xff00ACC1,
                  ),
                  foregroundColor:
                  Colors.white,
                ),
                child: const Text(
                  'ارسال',
                ),
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }

  // =========================================================
  // فیلترها
  // =========================================================

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection:
      Axis.horizontal,
      child: Row(
        children: [
          _filterButton(
            title: 'همه',
            value: 'all',
          ),
          const SizedBox(
            width: 8,
          ),
          _filterButton(
            title: 'فقط مالکین',
            value: 'owner',
          ),
          const SizedBox(
            width: 8,
          ),
          _filterButton(
            title: 'فقط مستأجرین',
            value: 'renter',
          ),
        ],
      ),
    );
  }

  Widget _filterButton({
    required String title,
    required String value,
  }) {
    final bool selected =
        _recipientFilter == value;

    return ChoiceChip(
      label: Text(title),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _recipientFilter = value;
        });
      },
      selectedColor:
      const Color(0xff00ACC1)
          .withOpacity(0.18),
    );
  }

  // =========================================================
  // کارت گیرنده
  // =========================================================

  Widget _buildRecipientItem(
      Map<String, dynamic> recipient,
      ) {
    final String key =
    _recipientKey(recipient);

    final bool selected =
    _selectedRecipientKeys
        .contains(key);

    final String type =
    _recipientType(recipient);

    final String name =
    _recipientName(recipient);

    final String mobile =
    _mobile(recipient);

    final String unit =
    _unitNumber(recipient);

    final bool isRenter =
        recipient['recipient_type']
            ?.toString()
            .toLowerCase() ==
            'renter';

    return Card(
      margin:
      const EdgeInsets.only(
        bottom: 8,
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        onTap: () {
          _toggleRecipient(
            recipient,
          );
        },
        child: Padding(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                activeColor:
                const Color(
                  0xff00ACC1,
                ),
                onChanged: (_) {
                  _toggleRecipient(
                    recipient,
                  );
                },
              ),
              const SizedBox(
                width: 4,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      'واحد $unit - $type: $name',
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: isRenter
                              ? Colors.orange
                              : Colors.blueGrey,
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          mobile.isEmpty
                              ? 'شماره موبایل ندارد'
                              : mobile,
                          style:
                          TextStyle(
                            color: mobile
                                .isEmpty
                                ? Colors.red
                                : Colors
                                .grey[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // حالت ارسال
  // =========================================================

  Widget _buildSendMode() {
    return Column(
      children: [
        RadioListTile<bool>(
          activeColor:
          const Color(0xff00ACC1),
          value: true,
          groupValue:
          _sendToAll,
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _sendToAll = value;
            });
          },
          title: const Text(
            'همه مالکین و مستأجرین',
          ),
          subtitle:
          const Text(
            'ارسال به تمام گیرندگان دارای شماره موبایل',
          ),
        ),
        RadioListTile<bool>(
          activeColor:
          const Color(0xff00ACC1),
          value: false,
          groupValue:
          _sendToAll,
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _sendToAll = value;
            });
          },
          title: const Text(
            'گیرندگان انتخابی',
          ),
          subtitle: Text(
            _selectedRecipientKeys
                .isEmpty
                ? 'برای انتخاب مالک یا مستأجر از لیست استفاده کنید'
                : '${_selectedRecipientKeys.length} گیرنده انتخاب شده',
          ),
        ),
      ],
    );
  }

  // =========================================================
  // جستجو
  // =========================================================

  Widget _buildSearch() {
    return TextField(
      controller:
      _searchController,
      textDirection:
      TextDirection.rtl,
      textAlign:
      TextAlign.right,
      keyboardType:
      TextInputType.text,
      decoration:
      InputDecoration(
        hintText:
        'جستجو بر اساس شماره واحد، نام یا موبایل',
        prefixIcon:
        const Icon(
          Icons.search,
        ),
        suffixIcon:
        _searchController
            .text
            .isNotEmpty
            ? IconButton(
          onPressed: () {
            _searchController
                .clear();
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
            12,
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
          borderSide:
          const BorderSide(
            color:
            Color(0xff00ACC1),
            width: 2,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // نوار انتخاب
  // =========================================================

  Widget _buildSelectionToolbar() {
    final List<Map<String, dynamic>>
    filtered =
    _filteredRecipients();

    return Row(
      children: [
        Text(
          '${filtered.length} گیرنده',
          style:
          const TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed:
          filtered.isEmpty
              ? null
              : _selectAllRecipients,
          icon:
          const Icon(
            Icons.select_all,
          ),
          label:
          const Text(
            'انتخاب همه',
          ),
        ),
        TextButton(
          onPressed:
          _selectedRecipientKeys
              .isEmpty
              ? null
              : _clearSelection,
          child:
          const Text(
            'لغو انتخاب',
          ),
        ),
      ],
    );
  }

  // =========================================================
  // دکمه ارسال
  // =========================================================

  Widget _buildSendButton() {
    final bool enabled =
        !_isSending &&
            (
                _sendToAll ||
                    _selectedRecipientKeys
                        .isNotEmpty
            );

    return SafeArea(
      child: Padding(
        padding:
        const EdgeInsets.all(
          12,
        ),
        child: SizedBox(
          width:
          double.infinity,
          height: 52,
          child:
          FilledButton.icon(
            onPressed:
            enabled
                ? _sendMessage
                : null,
            style:
            FilledButton.styleFrom(
              backgroundColor:
              const Color(
                0xff00ACC1,
              ),
              foregroundColor:
              Colors.white,
              disabledBackgroundColor:
              Colors.grey.shade300,
              disabledForegroundColor:
              Colors.grey.shade600,
            ),
            icon:
            _isSending
                ? const SizedBox(
              width: 20,
              height: 20,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
                color:
                Colors.white,
              ),
            )
                : const Icon(
              Icons.send,
            ),
            label: Text(
              _isSending
                  ? 'در حال ارسال...'
                  : _sendToAll
                  ? 'ارسال برای همه'
                  : 'ارسال برای ${_selectedRecipientKeys.length} نفر',
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // Build
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final List<Map<String, dynamic>>
    filtered =
    _filteredRecipients();

    return Directionality(
      textDirection:
      TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title:
          const Text(
            'انتخاب گیرندگان پیام',
          ),
        ),
        body: _isLoading
            ? const Center(
          child:
          CircularProgressIndicator(),
        )
            : Column(
          children: [
            Expanded(
              child:
              RefreshIndicator(
                onRefresh:
                _loadRecipients,
                child:
                ListView(
                  padding:
                  const EdgeInsets.all(
                    12,
                  ),
                  children: [
                    _buildSendMode(),

                    if (!_sendToAll) ...[
                      const SizedBox(
                        height: 8,
                      ),
                      _buildSearch(),
                      const SizedBox(
                        height: 10,
                      ),
                      _buildFilters(),
                      const SizedBox(
                        height: 4,
                      ),
                      _buildSelectionToolbar(),
                      const SizedBox(
                        height: 4,
                      ),
                      if (filtered
                          .isEmpty)
                        const Padding(
                          padding:
                          EdgeInsets.all(
                            30,
                          ),
                          child:
                          Center(
                            child:
                            Text(
                              'گیرنده‌ای پیدا نشد.',
                            ),
                          ),
                        )
                      else
                        ...filtered.map(
                          _buildRecipientItem,
                        ),
                    ],

                    if (_sendToAll)
                      Card(
                        child:
                        Padding(
                          padding:
                          const EdgeInsets.all(
                            16,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons
                                    .info_outline,
                                color:
                                Color(
                                  0xff00ACC1,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child:
                                Text(
                                  'در این حالت پیام برای تمام مالکین و مستأجرین فعال که شماره موبایل دارند ارسال خواهد شد.',
                                  style:
                                  TextStyle(
                                    color:
                                    Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }
}