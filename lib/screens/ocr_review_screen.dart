import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/database.dart';
import '../data/role_guard.dart';
import '../l10n/app_localizations.dart';
import '../models/appointment.dart';
import '../models/record.dart';
import '../providers/care_provider.dart';
import '../providers/family_provider.dart';
import '../providers/session_provider.dart';
import '../repositories/analytics_repository.dart';
import '../services/ocr_service.dart';

/// Review step for a scanned document (PRD F9). The extracted text and the
/// suggested dates can be edited. Nothing is saved until the user presses Save.
/// Cancel or back leaves without saving anything.
class OcrReviewScreen extends ConsumerStatefulWidget {
  const OcrReviewScreen({
    super.key,
    required this.imagePath,
    required this.ocrText,
  });

  /// Image picked by the user. It is copied into app storage only on Save.
  final String imagePath;

  final String ocrText;

  @override
  ConsumerState<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends ConsumerState<OcrReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _textController = TextEditingController(text: widget.ocrText);
  final _titleController = TextEditingController();
  final _typeController = TextEditingController();
  late final List<DateTime> _suggestedDates =
      extractDateCandidates(widget.ocrText);

  /// Starts on today. A suggested date only changes this when the user taps it.
  DateTime _date = DateTime.now();
  bool _caregiversOnly = false;
  bool _saving = false;

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    _typeController.dispose();
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

  /// Copies the original image into app storage under the record id.
  Future<String> _storeImage(String recordId) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, 'attachments'));
    await directory.create(recursive: true);
    final extension = p.extension(widget.imagePath).toLowerCase();
    final target = p.join(
      directory.path,
      '$recordId${extension.isEmpty ? '.jpg' : extension}',
    );
    await File(widget.imagePath).copy(target);
    return target;
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (_saving || form == null || !form.validate()) return;
    final family = ref.read(familySpaceProvider).value;
    final user = ref.read(currentUserProvider).value;
    if (family == null || user == null) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);

    final recordId = newEntityId();
    String? storedPath;
    try {
      storedPath = await _storeImage(recordId);
      final ocrText = _textController.text.trim();
      await ref.read(recordsProvider.notifier).add(
            CareRecord(
              id: recordId,
              familyId: family.id,
              title: _titleController.text.trim(),
              date: _date,
              type: _typeController.text.trim(),
              tags: const [],
              visibility: _caregiversOnly
                  ? RecordVisibility.caregiversOnly
                  : RecordVisibility.family,
              uploaderId: user.id,
              attachmentPath: storedPath,
              ocrText: ocrText.isEmpty ? null : ocrText,
            ),
          );
      // The repository skips the write when the user has opted out of analytics.
      await ref.read(analyticsRepositoryProvider).log(AnalyticsEvents.ocrSaved);
      navigator.pop(true);
    } on RoleDeniedException {
      await _removeStoredImage(storedPath);
      messenger.showSnackBar(SnackBar(content: Text(l10n.actionDeniedMessage)));
      if (mounted) setState(() => _saving = false);
    } on Exception {
      await _removeStoredImage(storedPath);
      messenger.showSnackBar(SnackBar(content: Text(l10n.genericError)));
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Removes a copied image when the record was not saved, so no orphan file
  /// is left behind.
  Future<void> _removeStoredImage(String? path) async {
    if (path == null) return;
    try {
      await File(path).delete();
    } on FileSystemException {
      // Nothing more to do: the file was never linked to a record.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final role = ref.watch(currentRoleProvider);
    final canSave = role != null && canWrite(role, WriteAction.createRecord);

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.ocrReviewTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Image Preview Card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.file(
                File(widget.imagePath),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 18),

            // Extracted OCR text field
            TextFormField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: l10n.ocrTextLabel,
                prefixIcon: const Icon(Icons.text_snippet_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                alignLabelWithHint: true,
              ),
              minLines: 4,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 14),

            if (_suggestedDates.isNotEmpty) ...[
              Text(
                l10n.ocrSuggestedDates,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final date in _suggestedDates)
                    ActionChip(
                      avatar: const Icon(Icons.event, size: 14),
                      label: Text(formatDate(date)),
                      onPressed: () => setState(() => _date = date),
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.recordTitleLabel,
                hintText: 'e.g. Dr. Mehta Prescription Slip',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _typeController,
              decoration: InputDecoration(
                labelText: l10n.recordTypeLabel,
                hintText: 'e.g. Prescription, Lab Report',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 12),

            // Date picker card
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, size: 20, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.recordDateLabel,
                            style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          Text(
                            formatDate(_date),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_calendar, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                secondary: Icon(Icons.lock_outline, color: scheme.primary, size: 20),
                value: _caregiversOnly,
                title: Text(
                  l10n.recordCaregiversOnly,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onChanged: (value) => setState(() => _caregiversOnly = value),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancelAction),
                ),
              ),
              if (canSave) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _saving ? null : _save,
                    child: Text(
                      _saving ? 'Saving...' : l10n.ocrSave,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
