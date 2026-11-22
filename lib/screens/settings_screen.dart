import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_data_seeder.dart';
import '../l10n/app_localizations.dart';
import '../models/consent.dart';
import '../providers/family_provider.dart';
import '../providers/session_provider.dart';
import '../providers/settings_provider.dart';
import '../repositories/analytics_repository.dart';
import '../widgets/user_switch_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Family Card with Invite Code & All Users Data
          const _FamilyCard(),
          _SectionHeader(text: l10n.settingsAppearanceSection),
          Text(l10n.settingsThemeLabel),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.settingsThemeLight),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.settingsThemeDark),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.settingsThemeSystem),
              ),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) {
              notifier.setThemeMode(selection.first);
              ref.read(analyticsRepositoryProvider).log(AnalyticsEvents.themeChanged);
            },
          ),
          const SizedBox(height: 24),
          _SectionHeader(text: l10n.settingsLanguageSection),
          Text(l10n.settingsLanguageLabel),
          const SizedBox(height: 8),
          SegmentedButton<Locale>(
            segments: [
              ButtonSegment(
                value: const Locale('en'),
                label: Text(l10n.languageEnglish),
              ),
              ButtonSegment(
                value: const Locale('hi'),
                label: Text(l10n.languageHindi),
              ),
            ],
            selected: {settings.locale},
            onSelectionChanged: (selection) {
              notifier.setLocale(selection.first);
              ref.read(analyticsRepositoryProvider).log(AnalyticsEvents.languageChanged);
            },
          ),
          const SizedBox(height: 24),
          _SectionHeader(text: l10n.settingsConsentSection),
          _ConsentSection(l10n: l10n),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.analyticsToggleTitle),
            subtitle: Text(l10n.analyticsToggleBody),
            value: settings.analyticsEnabled,
            onChanged: notifier.setAnalyticsEnabled,
          ),
          const SizedBox(height: 16),
          const _SolutionArchitectureCard(),
        ],
      ),
    );
  }
}

class _SolutionArchitectureCard extends StatelessWidget {
  const _SolutionArchitectureCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.architecture_rounded, color: scheme.primary, size: 22),
        ),
        title: const Text(
          'Hackathon Problem 4 Architecture',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: const Text(
          '10-second glance, sensitive data, monetization',
          style: TextStyle(fontSize: 11),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          _ArchItem(
            icon: Icons.speed_rounded,
            title: '1. What sibling 2,000 km away sees in 10s:',
            desc:
                '• Live recipient status badge (Father, 72, Jaipur)\n• Action Needed Today alert banner\n• Daily completion ring (50% ring with Completed/Pending/Refills)\n• Shared Care Today banner ("Priya gave morning BP meds; Sunita recorded 124/82")\n• 1-tap plain-language WhatsApp Care Update for family chat',
          ),
          const SizedBox(height: 12),
          _ArchItem(
            icon: Icons.security_rounded,
            title: '2. Sensitive health information handling:',
            desc:
                '• Local-first on-device encrypted database (no cloud leak)\n• Granular consent toggles (Storage, OCR, WhatsApp)\n• Role Guard: Viewers cannot see Caregivers-only medical records\n• Strict guardrail: Informational coordination only; clinical decisions stay with doctors',
          ),
          const SizedBox(height: 12),
          _ArchItem(
            icon: Icons.monetization_on_outlined,
            title: '3. Monetization & Who Pays:',
            desc:
                '• B2C Family: Free core; \$4.99/mo for automated WhatsApp reports & multi-family coordination\n• B2B2C Employer Benefit: Subsidized corporate eldercare benefit for remote employees (reducing caregiver absenteeism)\n• B2B Home Care Agencies: SaaS tool for professional nursing agencies managing multiple patient families',
          ),
        ],
      ),
    );
  }
}

class _ArchItem extends StatelessWidget {
  const _ArchItem({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.4,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Consent switches (PRD F19). Turning one off withdraws that consent.
class _ConsentSection extends ConsumerWidget {
  const _ConsentSection({required this.l10n});

  final AppLocalizations l10n;

  String _label(ConsentPurpose purpose) {
    return switch (purpose) {
      ConsentPurpose.dataStorage => l10n.consentDataStorage,
      ConsentPurpose.ocrProcessing => l10n.consentOcrProcessing,
      ConsentPurpose.whatsappSharing => l10n.consentWhatsappSharing,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return Text(l10n.settingsConsentNotSignedIn);

    final consents = ref.watch(consentProvider).value ??
        const <ConsentPurpose, bool>{};
    final notifier = ref.read(consentProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.settingsConsentHint),
        for (final purpose in ConsentPurpose.values)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_label(purpose)),
            value: consents[purpose] ?? false,
            onChanged: (value) => notifier.setConsent(purpose, value),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _FamilyCard extends ConsumerWidget {
  const _FamilyCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final family = ref.watch(familySpaceProvider).value;
    final members = ref.watch(membersProvider).value ?? const [];
    final currentUser = ref.watch(currentUserProvider).value;

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      color: scheme.surfaceContainerLow,
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
                    color: scheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.family_restroom, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        family?.name ?? "Family Care Space",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${members.length} active family members',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Invite Code Display Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FAMILY INVITE CODE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          family?.inviteCode ?? 'KP-7249',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Copy Invite Code',
                    onPressed: () {
                      final code = family?.inviteCode ?? 'KP-7249';
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invite code $code copied to clipboard')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ALL USERS DATA',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            if (members.isEmpty)
              Text('No members data available', style: theme.textTheme.bodySmall)
            else
              for (final member in members) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: scheme.surfaceContainerHighest,
                    child: Text(
                      member.name.isNotEmpty ? member.name[0] : '?',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  title: Text(
                    member.name + (member.id == currentUser?.id ? ' (You)' : ''),
                    style: theme.textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    member.phone ?? 'No phone provided',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      member.role.name.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSecondaryContainer,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
              ],
            const SizedBox(height: 16),
            // Switch Demo Profile Button
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.switch_account_rounded, size: 18),
              label: const Text('Switch Active Demo Profile'),
              onPressed: () => UserSwitchSheet.show(context),
            ),
            const SizedBox(height: 8),
            // Seed Demo Data Button
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
              ),
              icon: const Icon(Icons.auto_fix_high, size: 18),
              label: const Text('Reset & Seed Demo Data'),
              onPressed: () async {
                await DemoDataSeeder.seed(ref);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demo data loaded for Ramesh Sharma (Father, 72)')),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            // Switch to Clean Manual Setup
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
              ),
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('Switch to Clean Manual Setup'),
              onPressed: () async {
                await DemoDataSeeder.clearAll(ref);
                if (context.mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
