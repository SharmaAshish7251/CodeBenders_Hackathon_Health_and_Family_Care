import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/role_guard.dart';
import '../l10n/app_localizations.dart';
import '../models/appointment.dart';
import '../models/record.dart';
import '../providers/care_provider.dart';
import '../providers/family_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/care_toast.dart';
import 'ocr_capture_screen.dart';

/// Searchable list of care records (PRD F3). The search box matches the title,
/// any tag, the date as YYYY-MM-DD, or text read from a scanned image.
class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  String _query = '';

  bool _matches(CareRecord record, String query) {
    if (query.isEmpty) return true;
    final needle = query.toLowerCase();
    if (record.title.toLowerCase().contains(needle)) return true;
    if (formatDate(record.date).contains(needle)) return true;
    if (record.ocrText?.toLowerCase().contains(needle) ?? false) return true;
    return record.tags.any((tag) => tag.toLowerCase().contains(needle));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final records = ref.watch(recordsProvider);
    final role = ref.watch(currentRoleProvider);
    final canCreate = role != null && canWrite(role, WriteAction.createRecord);
    final canEdit = role != null && canWrite(role, WriteAction.updateRecord);
    final canDelete = role != null && canWrite(role, WriteAction.deleteRecord);
    final query = _query.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recordsTitle),
        actions: [
          if (canCreate)
            IconButton(
              icon: const Icon(Icons.document_scanner_outlined),
              tooltip: l10n.ocrTitle,
              onPressed: () => _scanRecord(context),
            ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _addRecord(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.recordAddFab),
            )
          : null,
      body: Column(
        children: [
          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.recordsSearchHint,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _query = ''),
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: records.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 56,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.recordsEmpty,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                final matches =
                    list.where((record) => _matches(record, query)).toList();
                if (matches.isEmpty) {
                  return Center(child: Text(l10n.recordsNoMatch));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final record = matches[index];
                    final theme = Theme.of(context);
                    final scheme = theme.colorScheme;
                    final isPrescription = record.type.toLowerCase().contains('prescription');
                    final isLab = record.type.toLowerCase().contains('lab');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: canEdit
                            ? () => _editRecord(context, record, canDelete)
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isPrescription
                                      ? const Color(0xFFE8F5E9)
                                      : isLab
                                          ? const Color(0xFFE3F2FD)
                                          : scheme.primaryContainer.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isPrescription
                                      ? Icons.medication_outlined
                                      : isLab
                                          ? Icons.biotech_outlined
                                          : Icons.description_outlined,
                                  color: isPrescription
                                      ? const Color(0xFF2E7D32)
                                      : isLab
                                          ? const Color(0xFF1565C0)
                                          : scheme.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            record.title,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (record.visibility == RecordVisibility.caregiversOnly)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 6),
                                            child: Icon(
                                              Icons.lock_outline,
                                              size: 16,
                                              color: scheme.outline,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: scheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            record.type.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: scheme.onSurfaceVariant,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          formatDate(record.date),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                        ),
                                        if (record.ocrText != null && record.ocrText!.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE0F2F1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.auto_awesome, size: 10, color: Color(0xFF00695C)),
                                                SizedBox(width: 2),
                                                Text(
                                                  'OCR',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF00695C),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (record.tags.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        children: [
                                          for (final tag in record.tags)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '#$tag',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: scheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text(l10n.genericError)),
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the OCR flow. Its "Enter manually" choice opens the normal form.
  Future<void> _scanRecord(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final outcome = await Navigator.of(context).push<OcrCaptureOutcome>(
      MaterialPageRoute(builder: (_) => const OcrCaptureScreen()),
    );
    if (!context.mounted) return;
    if (outcome == OcrCaptureOutcome.saved) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.ocrSaved)));
    } else if (outcome == OcrCaptureOutcome.enterManually) {
      await _addRecord(context);
    }
  }

  Future<void> _addRecord(BuildContext context) async {
    final family = ref.read(familySpaceProvider).value;
    final user = ref.read(currentUserProvider).value;
    if (family == null || user == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    final result = await showModalBottomSheet<_RecordFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _RecordFormSheet(
        familyId: family.id,
        uploaderId: user.id,
      ),
    );
    final record = result?.record;
    if (record == null) return;
    try {
      await ref.read(recordsProvider.notifier).add(record);
      if (context.mounted) {
        CareToast.showSuccess(
          context,
          title: 'Record Saved',
          subtitle: record.title,
        );
      }
    } on RoleDeniedException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.actionDeniedMessage)));
    }
  }

  Future<void> _editRecord(
    BuildContext context,
    CareRecord existing,
    bool canDelete,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    final result = await showModalBottomSheet<_RecordFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _RecordFormSheet(
        familyId: existing.familyId,
        uploaderId: existing.uploaderId,
        existing: existing,
        canDelete: canDelete,
      ),
    );
    if (result == null) return;
    try {
      if (result.delete) {
        await ref.read(recordsProvider.notifier).remove(existing.id);
        if (context.mounted) {
          CareToast.showSuccess(
            context,
            title: 'Record Deleted',
            subtitle: existing.title,
          );
        }
      } else if (result.record != null) {
        await ref.read(recordsProvider.notifier).edit(result.record!);
        if (context.mounted) {
          CareToast.showSuccess(
            context,
            title: 'Record Updated',
            subtitle: result.record!.title,
          );
        }
      }
    } on RoleDeniedException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.actionDeniedMessage)));
    }
  }
}

/// What the record form returns: a saved record, or a request to delete it.
class _RecordFormResult {
  const _RecordFormResult.save(this.record) : delete = false;
  const _RecordFormResult.delete()
      : record = null,
        delete = true;

  final CareRecord? record;
  final bool delete;
}

class _RecordCategory {
  final String id;
  final String labelEn;
  final String labelHi;
  final IconData icon;

  const _RecordCategory({
    required this.id,
    required this.labelEn,
    required this.labelHi,
    required this.icon,
  });
}

const _kRecordCategories = [
  _RecordCategory(
    id: 'Prescription',
    labelEn: 'Prescription',
    labelHi: 'पर्चा',
    icon: Icons.medication_outlined,
  ),
  _RecordCategory(
    id: 'Lab Report',
    labelEn: 'Lab Report',
    labelHi: 'लैब रिपोर्ट',
    icon: Icons.science_outlined,
  ),
  _RecordCategory(
    id: 'Consultation',
    labelEn: 'Consultation',
    labelHi: 'परामर्श',
    icon: Icons.medical_services_outlined,
  ),
  _RecordCategory(
    id: 'Scan / Imaging',
    labelEn: 'Scan / X-Ray',
    labelHi: 'स्कैन / एक्स-रे',
    icon: Icons.document_scanner_outlined,
  ),
  _RecordCategory(
    id: 'Bill / Receipt',
    labelEn: 'Bill / Invoice',
    labelHi: 'बिल / रसीद',
    icon: Icons.receipt_long_outlined,
  ),
  _RecordCategory(
    id: 'Other',
    labelEn: 'Other',
    labelHi: 'अन्य',
    icon: Icons.edit_note_outlined,
  ),
];

const _kRecordTagSuggestions = [
  'Cardiology',
  'Routine',
  'Blood Test',
  'Urgent',
  'BP',
  'Diabetes',
  'Follow-up',
];

/// Modern bottom sheet form for adding or editing a medical record.
class RecordFormSheet extends StatefulWidget {
  const RecordFormSheet({
    super.key,
    required this.familyId,
    required this.uploaderId,
    this.existing,
    this.canDelete = false,
  });

  final String familyId;
  final String uploaderId;
  final CareRecord? existing;
  final bool canDelete;

  @override
  State<RecordFormSheet> createState() => _RecordFormSheetState();
}

typedef _RecordFormSheet = RecordFormSheet;

class _RecordFormSheetState extends State<RecordFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _customTypeController;
  final TextEditingController _customTagController = TextEditingController();

  late DateTime _date;
  late bool _caregiversOnly;
  late String _selectedCategory;
  late bool _isCustomType;
  late final List<String> _tags;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _date = existing?.date ?? DateTime.now();
    _caregiversOnly = existing?.visibility == RecordVisibility.caregiversOnly;
    _tags = existing != null ? List<String>.from(existing.tags) : <String>[];

    final rawType = existing?.type ?? '';
    _selectedCategory = _resolveInitialCategory(rawType);
    _isCustomType = _selectedCategory == 'Other';
    _customTypeController = TextEditingController(
      text: _isCustomType ? rawType : '',
    );
  }

  String _resolveInitialCategory(String rawType) {
    if (rawType.isEmpty) return 'Prescription';
    final lower = rawType.toLowerCase();
    for (final cat in _kRecordCategories) {
      if (cat.id == 'Other') continue;
      if (lower == cat.id.toLowerCase() ||
          lower == cat.labelEn.toLowerCase() ||
          lower == cat.labelHi.toLowerCase()) {
        return cat.id;
      }
    }
    if (lower.contains('rx') || lower.contains('presc') || lower.contains('पर्चा')) {
      return 'Prescription';
    }
    if (lower.contains('lab') || lower.contains('test') || lower.contains('रिपोर्ट')) {
      return 'Lab Report';
    }
    if (lower.contains('consult') || lower.contains('परामर्श')) {
      return 'Consultation';
    }
    if (lower.contains('scan') || lower.contains('x-ray') || lower.contains('mri') || lower.contains('स्कैन')) {
      return 'Scan / Imaging';
    }
    if (lower.contains('bill') || lower.contains('invoice') || lower.contains('receipt') || lower.contains('बिल')) {
      return 'Bill / Receipt';
    }
    return 'Other';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _customTypeController.dispose();
    _customTagController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _addCustomTag() {
    final text = _customTagController.text.trim();
    if (text.isNotEmpty && !_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _customTagController.clear();
      });
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
      } else {
        _tags.add(tag);
      }
    });
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recordDeleteConfirmTitle),
        content: Text(l10n.recordDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.recordDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop(const _RecordFormResult.delete());
    }
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final finalType = _isCustomType
        ? _customTypeController.text.trim()
        : _selectedCategory;

    Navigator.of(context).pop(
      _RecordFormResult.save(
        CareRecord(
          id: widget.existing?.id ?? newEntityId(),
          familyId: widget.familyId,
          title: _titleController.text.trim(),
          date: _date,
          type: finalType.isNotEmpty ? finalType : _selectedCategory,
          tags: _tags,
          visibility: _caregiversOnly
              ? RecordVisibility.caregiversOnly
              : RecordVisibility.family,
          uploaderId: widget.uploaderId,
          attachmentPath: widget.existing?.attachmentPath,
          ocrText: widget.existing?.ocrText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Sheet Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        widget.existing == null
                            ? Icons.note_add_rounded
                            : Icons.edit_document,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.existing == null
                                ? l10n.recordNewTitle
                                : l10n.recordEditTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isHindi
                                ? 'पर्चा, टेस्ट रिपोर्ट या मेडिकल दस्तावेज़ सुरक्षित रखें'
                                : 'Prescription, lab report or medical document',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: l10n.cancelAction,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Record Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: l10n.recordTitleLabel,
                    hintText: isHindi
                        ? 'उदा. डॉ. मेहता पर्चा या ब्लड टेस्ट'
                        : 'e.g. Dr. Mehta Consultation, Lipid Profile',
                    prefixIcon: const Icon(Icons.description_outlined),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? l10n.fieldRequired : null,
                ),
                const SizedBox(height: 18),

                // Category Selection Chips
                Text(
                  isHindi ? 'दस्तावेज़ प्रकार' : 'Record Category',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final cat in _kRecordCategories)
                      ChoiceChip(
                        avatar: Icon(cat.icon, size: 16),
                        label: Text(isHindi ? cat.labelHi : cat.labelEn),
                        selected: _selectedCategory == cat.id,
                        selectedColor: theme.colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          fontWeight: _selectedCategory == cat.id
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedCategory == cat.id
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat.id;
                              _isCustomType = cat.id == 'Other';
                              if (!_isCustomType) {
                                _customTypeController.text = cat.id;
                              }
                            });
                          }
                        },
                      ),
                  ],
                ),

                // Custom Type field if "Other" is chosen
                if (_isCustomType) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _customTypeController,
                    decoration: InputDecoration(
                      labelText: l10n.recordTypeLabel,
                      hintText: isHindi ? 'उदा. डिस्चार्ज समरी, ईसीजी' : 'e.g. Discharge Summary, ECG',
                      prefixIcon: const Icon(Icons.category_outlined),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (val) =>
                        _isCustomType && (val ?? '').trim().isEmpty
                            ? l10n.fieldRequired
                            : null,
                  ),
                ],
                const SizedBox(height: 18),

                // Record Date Card
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.calendar_month_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.recordDateLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatDate(_date),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.edit_calendar_outlined, size: 16),
                          label: Text(isHindi ? 'बदलें' : 'Change'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Tags Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isHindi ? 'टैग्स' : 'Tags',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_tags.isNotEmpty)
                      Text(
                        '${_tags.length} selected',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Selected Tags Wrap
                if (_tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final tag in _tags)
                        InputChip(
                          label: Text('#$tag'),
                          onDeleted: () => setState(() => _tags.remove(tag)),
                          deleteIconColor: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                          labelStyle: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // Quick Suggestion Tags
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final suggestion in _kRecordTagSuggestions)
                      ActionChip(
                        label: Text('+ #$suggestion'),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: _tags.contains(suggestion)
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: _tags.contains(suggestion)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        backgroundColor: _tags.contains(suggestion)
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : null,
                        onPressed: () => _toggleTag(suggestion),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Custom Tag Input Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customTagController,
                        onSubmitted: (_) => _addCustomTag(),
                        decoration: InputDecoration(
                          hintText: isHindi ? 'कस्टम टैग जोड़ें...' : 'Add custom tag...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: _addCustomTag,
                      child: Text(isHindi ? 'जोड़ें' : 'Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Caregivers-Only Privacy Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _caregiversOnly
                        ? const Color(0xFFFFF3E0).withValues(alpha: 0.6)
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _caregiversOnly
                          ? const Color(0xFFFFB74D)
                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                      width: _caregiversOnly ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _caregiversOnly
                              ? const Color(0xFFFFE0B2)
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _caregiversOnly ? Icons.lock_rounded : Icons.lock_open_rounded,
                          color: _caregiversOnly
                              ? const Color(0xFFE65100)
                              : theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.recordCaregiversOnly,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _caregiversOnly ? const Color(0xFFE65100) : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isHindi
                                  ? 'दर्शकों से छिपा रहेगा, केवल देखभालकर्ता देख सकेंगे'
                                  : 'Hidden from viewers; only full caregivers can access',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _caregiversOnly,
                        onChanged: (val) => setState(() => _caregiversOnly = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    if (widget.canDelete) ...[
                      IconButton.outlined(
                        style: IconButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(
                            color: theme.colorScheme.error.withValues(alpha: 0.5),
                          ),
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded),
                        tooltip: l10n.recordDeleteAction,
                        onPressed: _confirmDelete,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.cancelAction),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 20),
                        onPressed: _save,
                        label: Text(
                          l10n.saveAction,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
