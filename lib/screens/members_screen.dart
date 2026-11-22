import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/role_guard.dart';
import '../l10n/app_localizations.dart';
import '../models/family_member.dart';
import '../providers/family_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/care_labels.dart';
import '../widgets/user_switch_sheet.dart';
import 'medicines_screen.dart';
import 'timeline_screen.dart';

enum _MemberAction { changeRole, remove }

/// Member list and Care Team Hub (PRD F1, F2).
class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final members = ref.watch(membersProvider);
    final family = ref.watch(familySpaceProvider).value;
    final role = ref.watch(currentRoleProvider);
    final userId = ref.watch(currentUserProvider).value?.id;
    final canManage = role != null && canWrite(role, WriteAction.manageMembers);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.membersTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: members.when(
        data: (list) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // Family Space Invite Header Card
              Card(
                elevation: 0,
                color: scheme.primaryContainer.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: scheme.primary.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.group_add_outlined, color: scheme.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  family?.name ?? 'Family Care Space',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Invite Code: ${family?.inviteCode ?? "KP-7249"}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: 'Copy Invite Code',
                            onPressed: () {
                              final code = family?.inviteCode ?? 'KP-7249';
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Invite code $code copied to clipboard'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.switch_account_rounded, size: 18),
                        label: const Text('Switch Demo Profile (Role Test)'),
                        onPressed: () => UserSwitchSheet.show(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Care & Health Trackers Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.timeline_rounded, color: scheme.primary, size: 20),
                      ),
                      title: const Text('Care Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Connected chronological view of appointments, Rx & completed care', style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const TimelineScreen()),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.medication_rounded, color: Color(0xFFE65100), size: 20),
                      ),
                      title: const Text('Medicines & Refill Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Prescription pill stock, days remaining & refill ordering', style: TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const MedicinesScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'CARE TEAM MEMBERS (${list.length})',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),

              if (list.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(l10n.membersEmpty),
                  ),
                )
              else
                for (final member in list) ...[
                  _MemberCard(
                    member: member,
                    isYou: member.id == userId,
                    canManage: canManage,
                    l10n: l10n,
                    onAction: (action) => _onAction(context, ref, member, action),
                  ),
                ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.genericError)),
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    FamilyMember member,
    _MemberAction action,
  ) async {
    switch (action) {
      case _MemberAction.changeRole:
        await _changeRole(context, ref, member);
      case _MemberAction.remove:
        await _remove(context, ref, member);
    }
  }

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    FamilyMember member,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showDialog<Role>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.memberChangeRoleTitle),
        children: [
          for (final role in Role.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(role),
              child: Text(roleLabel(l10n, role)),
            ),
        ],
      ),
    );
    if (picked == null) return;
    try {
      await ref.read(membersProvider.notifier).changeRole(member.id, picked);
    } on RoleDeniedException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.actionDeniedMessage)));
    }
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    FamilyMember member,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.memberRemoveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.memberRemove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(membersProvider.notifier).removeMember(member.id);
    } on RoleDeniedException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.actionDeniedMessage)));
    }
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isYou,
    required this.canManage,
    required this.l10n,
    required this.onAction,
  });

  final FamilyMember member;
  final bool isYou;
  final bool canManage;
  final AppLocalizations l10n;
  final void Function(_MemberAction) onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    member.name.isNotEmpty ? member.name[0] : '?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isYou ? '${member.name} ${l10n.memberYouSuffix}' : member.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: switch (member.role) {
                            Role.admin => const Color(0xFFEDE7F6),
                            Role.caregiver => const Color(0xFFE8F5E9),
                            Role.delegate => const Color(0xFFFFF8E1),
                            Role.viewer => scheme.surfaceContainerHighest,
                          },
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          roleLabel(l10n, member.role).toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: switch (member.role) {
                              Role.admin => const Color(0xFF512DA8),
                              Role.caregiver => const Color(0xFF2E7D32),
                              Role.delegate => const Color(0xFFE65100),
                              Role.viewer => scheme.onSurfaceVariant,
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 13, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        member.phone ?? 'No phone',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (member.phone != null && member.phone!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                tooltip: 'Copy Phone',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: member.phone!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Phone ${member.phone} copied!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            if (canManage && !isYou)
              PopupMenuButton<_MemberAction>(
                tooltip: l10n.membersMenuTooltip,
                onSelected: onAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _MemberAction.changeRole,
                    child: Text(l10n.memberChangeRole),
                  ),
                  PopupMenuItem(
                    value: _MemberAction.remove,
                    child: Text(l10n.memberRemove),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
