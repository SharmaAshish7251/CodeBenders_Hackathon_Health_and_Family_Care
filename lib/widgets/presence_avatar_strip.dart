import 'package:flutter/material.dart';
import '../models/family_member.dart';
import '../theme/care_theme.dart';

enum PresenceStatus { active, recent, inactive }

/// Displays an active members strip with presence indicators (Design Spec section 5 & 6).
class PresenceAvatarStrip extends StatelessWidget {
  const PresenceAvatarStrip({
    super.key,
    required this.members,
    this.selectedMemberId,
    this.onMemberSelected,
  });

  final List<FamilyMember> members;
  final String? selectedMemberId;
  final ValueChanged<String?>? onMemberSelected;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 92,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final member = members[index];
          final isSelected = member.id == selectedMemberId;
          // In a mock/local session, alternate or set first as active, others as recent/inactive
          final status = index == 0
              ? PresenceStatus.active
              : (index % 2 == 0
                  ? PresenceStatus.recent
                  : PresenceStatus.inactive);

          return _MemberAvatarItem(
            member: member,
            status: status,
            isSelected: isSelected,
            onTap: () {
              if (onMemberSelected != null) {
                onMemberSelected!(isSelected ? null : member.id);
              }
            },
          );
        },
      ),
    );
  }
}

class _MemberAvatarItem extends StatelessWidget {
  const _MemberAvatarItem({
    required this.member,
    required this.status,
    required this.isSelected,
    required this.onTap,
  });

  final FamilyMember member;
  final PresenceStatus status;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final customColors = theme.extension<CareCustomColors>();

    Color dotColor;
    switch (status) {
      case PresenceStatus.active:
        dotColor = customColors?.success ?? const Color(0xFF1F6B3A);
        break;
      case PresenceStatus.recent:
        dotColor = customColors?.warning ?? const Color(0xFF8A5A00);
        break;
      case PresenceStatus.inactive:
        dotColor = scheme.outline;
        break;
    }

    final initials = member.name.trim().isNotEmpty
        ? member.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : '?';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primaryContainer.withValues(alpha: 0.6)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: scheme.primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: scheme.surfaceContainerHighest,
                  child: Text(
                    initials,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: scheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 58,
              child: Text(
                member.name,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
