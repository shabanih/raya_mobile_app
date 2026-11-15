import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../../services/manager_announcement_service.dart';

class ManagerAnnouncementsScreen extends StatefulWidget {
  const ManagerAnnouncementsScreen({super.key});

  @override
  State<ManagerAnnouncementsScreen> createState() =>
      _ManagerAnnouncementsScreenState();
}

class _ManagerAnnouncementsScreenState
    extends State<ManagerAnnouncementsScreen> {
  bool isLoading = true;
  bool isRefreshing = false;

  List<Map<String, dynamic>> announcements = [];

  @override
  void initState() {
    super.initState();
    loadAnnouncements();
  }

  // دریافت اطلاعیه‌ها
  Future<void> loadAnnouncements() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final result = await ManagerAnnouncementService.getAnnouncements();

      if (!mounted) return;

      setState(() {
        announcements = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      _showError(_cleanError(e));
    }
  }

  // تازه‌سازی
  Future<void> refreshAnnouncements() async {
    if (mounted) {
      setState(() => isRefreshing = true);
    }

    try {
      final result = await ManagerAnnouncementService.getAnnouncements();

      if (!mounted) return;
      setState(() => announcements = result);
    } catch (e) {
      if (mounted) _showError(_cleanError(e));
    } finally {
      if (mounted) {
        setState(() => isRefreshing = false);
      }
    }
  }

  // ایجاد اطلاعیه
  Future<void> createAnnouncement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ManagerAnnouncementFormScreen(),
      ),
    );

    if (result == true) await loadAnnouncements();
  }

  // ویرایش اطلاعیه
  Future<void> editAnnouncement(
      Map<String, dynamic> announcement,
      ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerAnnouncementFormScreen(
          announcement: announcement,
        ),
      ),
    );

    if (result == true) await loadAnnouncements();
  }

  // حذف اطلاعیه
  Future<void> deleteAnnouncement(
      Map<String, dynamic> announcement,
      ) async {
    final id = int.tryParse(announcement['id']?.toString() ?? '');
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'حذف اطلاعیه',
          textAlign: TextAlign.right,
        ),
        content: const Text(
          'آیا از حذف این اطلاعیه مطمئن هستید؟',
          textAlign: TextAlign.right,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _showLoading();

    try {
      await ManagerAnnouncementService.deleteAnnouncement(id);

      if (!mounted) return;
      Navigator.pop(context);

      setState(() {
        announcements.removeWhere(
              (item) => item['id'].toString() == id.toString(),
        );
      });

      _showSuccess('اطلاعیه با موفقیت حذف شد.');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showError(_cleanError(e));
    }
  }

  // فعال / غیرفعال کردن اطلاعیه
  Future<void> toggleAnnouncementStatus(
      Map<String, dynamic> announcement,
      ) async {
    final id = int.tryParse(announcement['id']?.toString() ?? '');
    if (id == null) return;

    final currentStatus = announcement['is_active'] == true;
    final title = announcement['title']?.toString() ?? '';
    final showInMarquee = announcement['show_in_marquee'] == true;

    _showLoading();

    try {
      await ManagerAnnouncementService.changeStatus(
        id: id,
        isActive: !currentStatus,
        title: title,
        showInMarquee: showInMarquee,
      );

      if (!mounted) return;
      Navigator.pop(context);

      setState(() {
        announcement['is_active'] = !currentStatus;
      });

      _showSuccess(
        !currentStatus ? 'اطلاعیه فعال شد.' : 'اطلاعیه غیرفعال شد.',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showError(_cleanError(e));
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xff00ACC1),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _cleanError(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ')
        ? text.substring(11)
        : text;
  }

  String toPersianDigits(String value) {
    const english = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';

    for (int i = 0; i < english.length; i++) {
      value = value.replaceAll(english[i], persian[i]);
    }
    return value;
  }

  int _documentCount(Map<String, dynamic> announcement) {
    final documents = announcement['documents'];
    return documents is List ? documents.length : 0;
  }

  String formatPersianDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '-';

    final text = value.toString().trim();

    try {
      final date = DateTime.parse(text);
      final jalali = Jalali.fromDateTime(date);
      final result = '${jalali.year}/'
          '${jalali.month.toString().padLeft(2, '0')}/'
          '${jalali.day.toString().padLeft(2, '0')}';
      return toPersianDigits(result);
    } catch (_) {
      return toPersianDigits(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF5F7FA),
        appBar: AppBar(
          toolbarHeight: 88,
          elevation: 0,
          backgroundColor: const Color(0xff00ACC1),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            'مدیریت اطلاعیه‌ها',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xff00ACC1),
          foregroundColor: Colors.white,
          onPressed: createAnnouncement,
          icon: const Icon(Icons.add_rounded),
          label: const Text(
            'ایجاد اطلاعیه',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: Color(0xff00ACC1),
          ),
        )
            : RefreshIndicator(
          color: const Color(0xff00ACC1),
          onRefresh: refreshAnnouncements,
          child: announcements.isEmpty
              ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.28,
              ),
              Icon(
                Icons.campaign_outlined,
                size: 70,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'هنوز اطلاعیه‌ای ثبت نشده است.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'برای ایجاد اطلاعیه روی دکمه پایین صفحه بزنید.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
            ],
          )
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 100),
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              return _buildAnnouncementCard(
                announcements[index],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(
      Map<String, dynamic> announcement,
      ) {
    final isActive = announcement['is_active'] == true;
    final showInMarquee = announcement['show_in_marquee'] == true;
    final title = announcement['title']?.toString() ?? '';
    final date = formatPersianDate(announcement['created_at']);
    final documentsCount = _documentCount(announcement);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xff00ACC1).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: Color(0xff00ACC1),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    title.isEmpty ? 'بدون متن' : title,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff263238),
                      height: 1.8,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert,
                    color: Color(0xff546E7A),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      editAnnouncement(announcement);
                    } else if (value == 'delete') {
                      deleteAnnouncement(announcement);
                    } else if (value == 'status') {
                      toggleAnnouncementStatus(announcement);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('ویرایش'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'status',
                      child: Row(
                        children: [
                          Icon(
                            isActive
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isActive
                                ? 'غیرفعال کردن'
                                : 'فعال کردن',
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'حذف',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 13),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _buildInfoChip(
                  icon: Icons.calendar_today_outlined,
                  text: date,
                ),
                _buildStatusChip(isActive),
                if (showInMarquee)
                  _buildInfoChip(
                    icon: Icons.view_headline_rounded,
                    text: 'نمایش در نوار اطلاعیه',
                  ),
                if (documentsCount > 0)
                  _buildInfoChip(
                    icon: Icons.attach_file_rounded,
                    text: '${toPersianDigits(documentsCount.toString())} پیوست',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.10)
            : Colors.red.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive
                ? Icons.check_circle_outline
                : Icons.cancel_outlined,
            size: 15,
            color: isActive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'فعال' : 'غیرفعال',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffF1F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: const Color(0xff607D8B),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff546E7A),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// فرم ایجاد / ویرایش اطلاعیه
// =======================================================

class ManagerAnnouncementFormScreen extends StatefulWidget {
  final Map<String, dynamic>? announcement;

  const ManagerAnnouncementFormScreen({
    super.key,
    this.announcement,
  });

  bool get isEdit => announcement != null;

  @override
  State<ManagerAnnouncementFormScreen> createState() =>
      _ManagerAnnouncementFormScreenState();
}

class _ManagerAnnouncementFormScreenState
    extends State<ManagerAnnouncementFormScreen> {
  final TextEditingController titleController = TextEditingController();
  final FocusNode titleFocusNode = FocusNode();

  bool showInMarquee = false;
  bool isActive = true;
  bool isSaving = false;

  // فایل‌های جدید انتخاب‌شده (عکس، PDF، Word، Excel و ...)
  List<File> selectedFiles = [];

  // شناسه پیوست‌های قبلی که مدیر برای حذف انتخاب کرده است
  List<int> deletedDocumentIds = [];

  // پیوست‌هایی که از قبل روی سرور وجود دارند
  List<Map<String, dynamic>> existingDocuments = [];

  @override
  void initState() {
    super.initState();

    final data = widget.announcement;
    if (data == null) return;

    titleController.text = data['title']?.toString() ?? '';
    showInMarquee = data['show_in_marquee'] == true;
    isActive = data['is_active'] != false;

    final documents = data['documents'];
    if (documents is List) {
      existingDocuments = documents
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    titleFocusNode.dispose();
    super.dispose();
  }

  // انتخاب هم‌زمان عکس و فایل با File Picker
  Future<void> pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result.isEmpty) return;

      final files = result
          .where((file) => file.path != null)
          .map((file) => File(file.path!))
          .toList();

      if (files.isEmpty) return;

      setState(() {
        selectedFiles.addAll(files);
      });
    } catch (e) {
      debugPrint('خطا در انتخاب فایل: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در انتخاب فایل: $e'),
        ),
      );
    }
  }
  // تشخیص فایل تصویری
  bool _isImageFile(String path) {
    final extension = _extension(path);
    return const [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'heic',
      'heif',
    ].contains(extension);
  }

  String _extension(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == name.length - 1) return '';
    return name.substring(dotIndex + 1).toLowerCase();
  }

  // آیکون متناسب با پسوند فایل
  IconData _fileIcon(String path) {
    switch (_extension(path)) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'doc':
      case 'docx':
      case 'odt':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
      case 'csv':
      case 'ods':
        return Icons.table_chart_outlined;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_outlined;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip_outlined;
      case 'txt':
        return Icons.text_snippet_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  String _fileName(File file) {
    return file.path.split(Platform.pathSeparator).last;
  }

  // نام پیوست قبلی از اطلاعات API
  String _existingDocumentName(Map<String, dynamic> document) {
    final suppliedName = document['name'] ??
        document['file_name'] ??
        document['filename'] ??
        document['title'];

    if (suppliedName != null &&
        suppliedName.toString().trim().isNotEmpty) {
      return suppliedName.toString();
    }

    final url = document['url']?.toString() ?? '';
    if (url.isNotEmpty) {
      final cleanUrl = Uri.tryParse(url)?.path ?? url;
      final parts = cleanUrl.split('/').where((part) => part.isNotEmpty).toList();
      return parts.isNotEmpty ? parts.last : 'پیوست ثبت‌شده';
    }

    return 'پیوست ثبت‌شده';
  }

  // حذف پیوست قبلی
  void removeExistingDocument(int index) {
    if (index < 0 || index >= existingDocuments.length) return;

    final document = existingDocuments[index];
    final id = int.tryParse(document['id']?.toString() ?? '');

    setState(() {
      if (id != null) deletedDocumentIds.add(id);
      existingDocuments.removeAt(index);
    });
  }

  // حذف فایل جدید
  void removeSelectedFile(int index) {
    if (index < 0 || index >= selectedFiles.length) return;

    setState(() {
      selectedFiles.removeAt(index);
    });
  }

  // ثبت اطلاعیه
  Future<void> saveAnnouncement() async {
    final title = titleController.text.trim();

    if (title.isEmpty) {
      _showError('متن اطلاعیه را وارد کنید.');
      titleFocusNode.requestFocus();
      return;
    }

    if (isSaving) return;

    setState(() => isSaving = true);

    try {
      if (widget.isEdit) {
        final id = int.tryParse(
          widget.announcement!['id']?.toString() ?? '',
        );

        if (id == null) {
          throw Exception('شناسه اطلاعیه نامعتبر است.');
        }

        await ManagerAnnouncementService.updateAnnouncement(
          id: id,
          title: title,
          showInMarquee: showInMarquee,
          isActive: isActive,
          files: selectedFiles,
          deletedDocumentIds: deletedDocumentIds,
        );
      } else {
        await ManagerAnnouncementService.createAnnouncement(
          title: title,
          showInMarquee: showInMarquee,
          files: selectedFiles,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError(_cleanError(e));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  String _cleanError(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ')
        ? text.substring(11)
        : text;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textAlign: TextAlign.right),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xff00ACC1),
        ),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xff37474F),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentLeading({
    required String pathOrUrl,
    required bool isNetwork,
  }) {
    final image = _isImageFile(pathOrUrl);

    if (image && isNetwork) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          pathOrUrl,
          width: 55,
          height: 55,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _documentIconBox(
            Icons.broken_image_outlined,
          ),
        ),
      );
    }

    if (image && !isNetwork) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(pathOrUrl),
          width: 55,
          height: 55,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _documentIconBox(
            Icons.broken_image_outlined,
          ),
        ),
      );
    }

    return _documentIconBox(_fileIcon(pathOrUrl));
  }

  Widget _documentIconBox(IconData icon) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xffE0F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 29,
        color: const Color(0xff00ACC1),
      ),
    );
  }

  Widget _buildExistingDocumentTile(
      Map<String, dynamic> document,
      int index,
      ) {
    final url = document['url']?.toString() ?? '';
    final name = _existingDocumentName(document);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildDocumentLeading(
            pathOrUrl: url.isNotEmpty ? url : name,
            isNetwork: url.isNotEmpty,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff455A64),
              ),
            ),
          ),
          IconButton(
            onPressed: isSaving
                ? null
                : () => removeExistingDocument(index),
            tooltip: 'حذف پیوست',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFileTile(File file, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildDocumentLeading(
            pathOrUrl: file.path,
            isNetwork: false,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _fileName(file),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff455A64),
              ),
            ),
          ),
          IconButton(
            onPressed: isSaving
                ? null
                : () => removeSelectedFile(index),
            tooltip: 'حذف فایل',
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEdit;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF5F7FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xff00ACC1),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            isEdit ? 'ویرایش اطلاعیه' : 'ایجاد اطلاعیه',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // متن اطلاعیه
                _buildSectionTitle(
                  'متن اطلاعیه',
                  Icons.campaign_outlined,
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: titleController,
                    focusNode: titleFocusNode,
                    minLines: 6,
                    maxLines: 12,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      hintText: 'متن اطلاعیه را وارد کنید...',
                      hintStyle: TextStyle(
                        color: Color(0xff9E9E9E),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // نمایش در نوار اطلاعیه
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    value: showInMarquee,
                    activeColor: const Color(0xff00ACC1),
                    title: const Text(
                      'نمایش در نوار اطلاعیه',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'اطلاعیه در نوار اطلاعیه ساختمان نمایش داده شود.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xff78909C),
                      ),
                    ),
                    secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xff00ACC1).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.view_headline_rounded,
                        color: Color(0xff00ACC1),
                      ),
                    ),
                    onChanged: isSaving
                        ? null
                        : (value) {
                      setState(() => showInMarquee = value);
                    },
                  ),
                ),

                if (isEdit) ...[
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      value: isActive,
                      activeColor: Colors.green,
                      title: const Text(
                        'فعال بودن اطلاعیه',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'اطلاعیه‌های غیرفعال برای ساکنین نمایش داده نمی‌شوند.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff78909C),
                        ),
                      ),
                      secondary: Icon(
                        isActive
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        color: isActive ? Colors.green : Colors.red,
                      ),
                      onChanged: isSaving
                          ? null
                          : (value) {
                        setState(() => isActive = value);
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // انتخاب عکس و فایل
                _buildSectionTitle(
                  'پیوست‌های اطلاعیه',
                  Icons.attach_file_rounded,
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: isSaving ? null : pickFiles,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xff00ACC1).withOpacity(0.30),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.upload_file_rounded,
                          size: 38,
                          color: Color(0xff00ACC1),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'انتخاب عکس و فایل',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff263238),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'امکان انتخاب هم‌زمان چند عکس و فایل وجود دارد',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xff78909C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // پیوست‌های قبلی
                if (existingDocuments.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  const Text(
                    'پیوست‌های قبلی',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff455A64),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    existingDocuments.length,
                        (index) => _buildExistingDocumentTile(
                      existingDocuments[index],
                      index,
                    ),
                  ),
                ],

                // فایل‌های جدید
                if (selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  const Text(
                    'پیوست‌های جدید',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff455A64),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    selectedFiles.length,
                        (index) => _buildSelectedFileTile(
                      selectedFiles[index],
                      index,
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // ثبت اطلاعیه
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : saveAnnouncement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff00ACC1),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xffB0BEC5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Icon(
                      isEdit
                          ? Icons.save_outlined
                          : Icons.add_rounded,
                    ),
                    label: Text(
                      isSaving
                          ? 'در حال ثبت...'
                          : isEdit
                          ? 'ذخیره تغییرات'
                          : 'ثبت اطلاعیه',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
