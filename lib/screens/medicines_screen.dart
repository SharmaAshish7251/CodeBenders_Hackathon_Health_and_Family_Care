import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/role_guard.dart';
import '../l10n/app_localizations.dart';
import '../models/medicine.dart';
import '../models/task.dart';
import '../providers/care_provider.dart';
import '../providers/family_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/care_toast.dart';

/// Family medicine stock with days remaining and a refill task action (PRD F6).
/// The schedule is free text and must follow the doctor's prescription.
class MedicinesScreen extends ConsumerWidget {
  const MedicinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final medicines = ref.watch(medicinesProvider);
    final role = ref.watch(currentRoleProvider);
    final canCreate = role != null && canWrite(role, WriteAction.createMedicine);
    final canRefill = role != null && canWrite(role, WriteAction.createTask);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.medicinesTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _addMedicine(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.medicineAddFab),
            )
          : null,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.medicinesPrescriptionNote,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: medicines.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.medication_outlined, size: 56, color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Text(
                          l10n.medicinesEmpty,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final medicine = list[index];
                    return _medicineCard(
                      context: context,
                      ref: ref,
                      medicine: medicine,
                      canRefill: canRefill,
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

  Widget _medicineCard({
    required BuildContext context,
    required WidgetRef ref,
    required Medicine medicine,
    required bool canRefill,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final days = medicine.daysRemaining;
    final isLow = days != null && days < medicine.refillThresholdDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLow
              ? const Color(0xFFFFB74D)
              : scheme.outlineVariant.withValues(alpha: 0.4),
          width: isLow ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isLow
                        ? const Color(0xFFFFF3E0)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isLow ? Icons.warning_amber_rounded : Icons.medication_rounded,
                    color: isLow ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicine.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stock: ${medicine.quantityOnHand} units (${medicine.dailyUsage} / day)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLow ? const Color(0xFFFFEBEE) : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    days != null ? '$days days left' : 'Usage not set',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isLow ? const Color(0xFFC62828) : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (medicine.scheduleNote != null && medicine.scheduleNote!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: scheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        medicine.scheduleNote!,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isLow && canRefill) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(38),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_shopping_cart, size: 16),
                label: Text(l10n.medicineAddRefillTask),
                onPressed: () => _addRefillTask(context, ref, medicine),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _addMedicine(BuildContext context, WidgetRef ref) async {
    final family = ref.read(familySpaceProvider).value;
    final user = ref.read(currentUserProvider).value;
    if (family == null || user == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final medicine = await showDialog<Medicine>(
      context: context,
      builder: (dialogContext) => _MedicineFormDialog(familyId: family.id),
    );
    if (medicine == null) return;
    try {
      await ref.read(medicinesProvider.notifier).add(medicine);
    } on RoleDeniedException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.actionDeniedMessage)));
    }
  }

  /// Creates one refill task for the signed-in user through the task repository.
  Future<void> _addRefillTask(
    BuildContext context,
    WidgetRef ref,
    Medicine medicine,
  ) async {
    final family = ref.read(familySpaceProvider).value;
    final user = ref.read(currentUserProvider).value;
    if (family == null || user == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final task = CareTask(
      id: newEntityId(),
      familyId: family.id,
      title: l10n.refillTaskTitle(medicine.name),
      dueAt: DateTime.now(),
      assigneeId: user.id,
      status: TaskStatus.todo,
      recurrence: Recurrence.none,
    );
    try {
      await ref.read(taskRepositoryProvider).create(actorId: user.id, task: task);
      ref.invalidate(tasksProvider);
      ref.invalidate(activityProvider);
      if (context.mounted) {
        CareToast.showSuccess(
          context,
          title: 'Refill Task Created',
          subtitle: task.title,
        );
      }
    } on RoleDeniedException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.actionDeniedMessage)));
    }
  }
}

/// Parses a stock count. Returns null when the text is not a whole number of
/// 0 or more.
int? _parseCount(String? value) {
  final parsed = int.tryParse((value ?? '').trim());
  if (parsed == null || parsed < 0) return null;
  return parsed;
}

class _MedicineFormDialog extends StatefulWidget {
  const _MedicineFormDialog({required this.familyId});

  final String familyId;

  @override
  State<_MedicineFormDialog> createState() => _MedicineFormDialogState();
}

class _MedicineFormDialogState extends State<_MedicineFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _quantityController = TextEditingController(text: '0');
  final _dailyUsageController = TextEditingController(text: '0');
  final _thresholdController = TextEditingController(text: '7');

  @override
  void dispose() {
    _nameController.dispose();
    _scheduleController.dispose();
    _quantityController.dispose();
    _dailyUsageController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final schedule = _scheduleController.text.trim();
    Navigator.of(context).pop(
      Medicine(
        id: newEntityId(),
        familyId: widget.familyId,
        name: _nameController.text.trim(),
        scheduleNote: schedule.isEmpty ? null : schedule,
        quantityOnHand: _parseCount(_quantityController.text) ?? 0,
        dailyUsage: _parseCount(_dailyUsageController.text) ?? 0,
        refillThresholdDays: _parseCount(_thresholdController.text) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String? countValidator(String? value) =>
        _parseCount(value) == null ? l10n.medicineNumberInvalid : null;

    return AlertDialog(
      title: Text(l10n.medicineNewTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.medicineNameLabel),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? l10n.fieldRequired : null,
              ),
              TextFormField(
                controller: _scheduleController,
                decoration:
                    InputDecoration(labelText: l10n.medicineScheduleLabel),
              ),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration:
                    InputDecoration(labelText: l10n.medicineQuantityLabel),
                validator: countValidator,
              ),
              TextFormField(
                controller: _dailyUsageController,
                keyboardType: TextInputType.number,
                decoration:
                    InputDecoration(labelText: l10n.medicineDailyUsageLabel),
                validator: countValidator,
              ),
              TextFormField(
                controller: _thresholdController,
                keyboardType: TextInputType.number,
                decoration:
                    InputDecoration(labelText: l10n.medicineRefillThresholdLabel),
                validator: countValidator,
              ),
            ],
          ),
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
