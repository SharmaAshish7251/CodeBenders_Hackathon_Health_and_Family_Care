import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/role_guard.dart';
import '../l10n/app_localizations.dart';
import '../models/emergency_info.dart';
import '../providers/emergency_provider.dart';
import '../providers/family_provider.dart';
import '../providers/session_provider.dart';
import '../repositories/analytics_repository.dart';

/// Bottom sheet with the family's emergency details. It reads local data only,
/// so it works offline. It does not dial; the user dials 112 on their phone.
class EmergencySheet extends ConsumerWidget {
  const EmergencySheet({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) {
    ref.read(analyticsRepositoryProvider).log(AnalyticsEvents.emergencyOpened);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const EmergencySheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final info = ref.watch(emergencyInfoProvider).value;
    final role = ref.watch(currentRoleProvider);
    final hasFamily = ref.watch(familySpaceProvider).value != null;
    final canEdit = hasFamily &&
        role != null &&
        canWrite(role, WriteAction.updateEmergencyInfo);

    final contact = [
      info?.emergencyContactName,
      info?.emergencyContactPhone,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' · ');

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with SOS Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emergency_rounded, color: Color(0xFFC62828), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.emergencyTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Offline Ready • Instant Access',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canEdit)
                  IconButton.filledTonal(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: l10n.emergencyEditAction,
                    onPressed: () => _edit(context, ref, info),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Big Red Emergency Call Button
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.call, size: 22),
              label: Text(
                l10n.emergencyCall112,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onPressed: () => _showNote(context, l10n.emergencyCallNote),
            ),
            const SizedBox(height: 16),

            // Vitals & Critical Info Grid
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BLOOD GROUP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Colors.red[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          info?.bloodGroup ?? 'Not Set',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HOSPITAL',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          info?.hospital ?? 'Not Set',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Allergies & Chronic Conditions Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFE65100)),
                      const SizedBox(width: 6),
                      const Text(
                        'ALLERGIES & CONDITIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Allergies: ${info?.allergies ?? "None declared"}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF37474F)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Conditions: ${info?.conditions ?? "None declared"}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF37474F)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Emergency Contact & Doctor Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone_in_talk_outlined, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Primary Contact',
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            Text(
                              contact.isEmpty ? l10n.emergencyNotSet : contact,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Icon(Icons.medical_services_outlined, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Doctor Contact',
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            Text(
                              info?.doctorContact ?? l10n.emergencyNotSet,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.emergencyDisclaimer,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNote(BuildContext context, String message) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.emergencyCall112),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.closeAction),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    EmergencyInfo? current,
  ) async {
    final familyId = ref.read(familySpaceProvider).value?.id;
    if (familyId == null) return;
    final l10n = AppLocalizations.of(context)!;

    final updated = await showDialog<EmergencyInfo>(
      context: context,
      builder: (dialogContext) => _EmergencyFormDialog(
        familyId: familyId,
        current: current,
      ),
    );
    if (updated == null) return;
    try {
      await ref.read(emergencyInfoProvider.notifier).save(updated);
    } on RoleDeniedException {
      if (!context.mounted) return;
      await _showNote(context, l10n.actionDeniedMessage);
    }
  }
}

/// Returns trimmed text, or null when the field is empty.
String? _nullIfBlank(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

class _EmergencyFormDialog extends StatefulWidget {
  const _EmergencyFormDialog({required this.familyId, this.current});

  final String familyId;
  final EmergencyInfo? current;

  @override
  State<_EmergencyFormDialog> createState() => _EmergencyFormDialogState();
}

class _EmergencyFormDialogState extends State<_EmergencyFormDialog> {
  late final _bloodGroupController =
      TextEditingController(text: widget.current?.bloodGroup ?? '');
  late final _allergiesController =
      TextEditingController(text: widget.current?.allergies ?? '');
  late final _conditionsController =
      TextEditingController(text: widget.current?.conditions ?? '');
  late final _contactNameController =
      TextEditingController(text: widget.current?.emergencyContactName ?? '');
  late final _contactPhoneController =
      TextEditingController(text: widget.current?.emergencyContactPhone ?? '');
  late final _hospitalController =
      TextEditingController(text: widget.current?.hospital ?? '');
  late final _doctorController =
      TextEditingController(text: widget.current?.doctorContact ?? '');

  @override
  void dispose() {
    _bloodGroupController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _hospitalController.dispose();
    _doctorController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      EmergencyInfo(
        familyId: widget.familyId,
        bloodGroup: _nullIfBlank(_bloodGroupController.text),
        allergies: _nullIfBlank(_allergiesController.text),
        conditions: _nullIfBlank(_conditionsController.text),
        emergencyContactName: _nullIfBlank(_contactNameController.text),
        emergencyContactPhone: _nullIfBlank(_contactPhoneController.text),
        hospital: _nullIfBlank(_hospitalController.text),
        doctorContact: _nullIfBlank(_doctorController.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.emergencyEditTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _bloodGroupController,
              decoration:
                  InputDecoration(labelText: l10n.emergencyBloodGroupLabel),
            ),
            TextField(
              controller: _allergiesController,
              decoration: InputDecoration(labelText: l10n.emergencyAllergiesLabel),
            ),
            TextField(
              controller: _conditionsController,
              decoration:
                  InputDecoration(labelText: l10n.emergencyConditionsLabel),
            ),
            TextField(
              controller: _contactNameController,
              decoration:
                  InputDecoration(labelText: l10n.emergencyContactNameLabel),
            ),
            TextField(
              controller: _contactPhoneController,
              keyboardType: TextInputType.phone,
              decoration:
                  InputDecoration(labelText: l10n.emergencyContactPhoneLabel),
            ),
            TextField(
              controller: _hospitalController,
              decoration: InputDecoration(labelText: l10n.emergencyHospitalLabel),
            ),
            TextField(
              controller: _doctorController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l10n.emergencyDoctorLabel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelAction),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.saveAction)),
      ],
    );
  }
}
