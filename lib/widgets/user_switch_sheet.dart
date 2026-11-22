import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_data_seeder.dart';
import '../models/family_member.dart';
import '../providers/session_provider.dart';
import 'care_toast.dart';

/// Modal bottom sheet allowing users in Demo Mode to switch between
/// different personas (Admin, Caregiver, Viewer, Delegate) to test
/// distinct perspectives, tasks, and permission gates.
class UserSwitchSheet extends ConsumerWidget {
  const UserSwitchSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const UserSwitchSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currentUser = ref.watch(currentUserProvider).value;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.switch_account_rounded,
                    color: scheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Switch Demo Profile',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFECB3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'DEMO MODE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Test app behavior across different family roles & permission gates.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Persona Cards
            for (final persona in DemoDataSeeder.personas) ...[
              _PersonaTile(
                persona: persona,
                isActive: currentUser?.id == persona.id,
                onTap: () async {
                  await ref
                      .read(currentUserProvider.notifier)
                      .switchUser(persona.toLocalUser());
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    CareToast.showSuccess(
                      context,
                      title: 'Switched to ${persona.name}',
                      subtitle: 'Active Role: ${persona.role.name.toUpperCase()} (${persona.relation})',
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _PersonaTile extends StatelessWidget {
  const _PersonaTile({
    required this.persona,
    required this.isActive,
    required this.onTap,
  });

  final DemoPersona persona;
  final bool isActive;
  final VoidCallback onTap;

  Color _roleColor(Role role) {
    return switch (role) {
      Role.admin => const Color(0xFF00695C),
      Role.caregiver => const Color(0xFF2E7D32),
      Role.viewer => const Color(0xFFE65100),
      Role.delegate => const Color(0xFF1565C0),
    };
  }

  Color _roleBg(Role role) {
    return switch (role) {
      Role.admin => const Color(0xFFE0F2F1),
      Role.caregiver => const Color(0xFFE8F5E9),
      Role.viewer => const Color(0xFFFFF3E0),
      Role.delegate => const Color(0xFFE3F2FD),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rColor = _roleColor(persona.role);
    final rBg = _roleBg(persona.role);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? scheme.primaryContainer.withValues(alpha: 0.35)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? scheme.primary : scheme.outlineVariant.withValues(alpha: 0.35),
            width: isActive ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: rBg,
              child: Icon(persona.icon, color: rColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Text info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          persona.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: rBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: rColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          persona.role.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: rColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    persona.relation,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    persona.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Active Radio / Check indicator
            if (isActive)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.outlineVariant, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
