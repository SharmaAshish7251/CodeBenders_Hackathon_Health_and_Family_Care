import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/consent.dart';
import 'sign_in_screen.dart';

/// First-run onboarding flow:
/// 1. Welcome & Key Value Pillars
/// 2. Privacy & Granular Consents
/// 3. Sign-in (with Demo Data vs Manual Setup toggle)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 3;

  final _pageController = PageController();
  final Map<ConsentPurpose, bool> _consents = {
    for (final purpose in ConsentPurpose.values) purpose: true,
  };
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    setState(() => _page = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  String _consentLabel(AppLocalizations l10n, ConsentPurpose purpose) {
    return switch (purpose) {
      ConsentPurpose.dataStorage => l10n.consentDataStorage,
      ConsentPurpose.ocrProcessing => l10n.consentOcrProcessing,
      ConsentPurpose.whatsappSharing => l10n.consentWhatsappSharing,
    };
  }

  IconData _consentIcon(ConsentPurpose purpose) {
    return switch (purpose) {
      ConsentPurpose.dataStorage => Icons.cloud_done_outlined,
      ConsentPurpose.ocrProcessing => Icons.document_scanner_outlined,
      ConsentPurpose.whatsappSharing => Icons.chat_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  if (_page > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => _goTo(_page - 1),
                      tooltip: l10n.onboardingBack,
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  // Step Indicator Dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_pageCount, (index) {
                      final isSelected = index == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? scheme.primary
                              : scheme.outlineVariant.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Page 1: Welcome & Pillars
                  _WelcomePage(
                    l10n: l10n,
                    onNext: () => _goTo(1),
                  ),

                  // Page 2: Consent
                  _ConsentPage(
                    l10n: l10n,
                    consents: _consents,
                    onToggle: (purpose, value) {
                      setState(() => _consents[purpose] = value);
                    },
                    consentLabel: (p) => _consentLabel(l10n, p),
                    consentIcon: _consentIcon,
                    onNext: () => _goTo(2),
                  ),

                  // Page 3: Sign In with Toggle
                  SignInScreen(consents: Map.of(_consents)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.l10n, required this.onNext});

  final AppLocalizations l10n;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.volunteer_activism_rounded, color: scheme.primary, size: 40),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.onboardingPage1Title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingPage1Body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Pillar 1: Shared Care
          _PillarCard(
            icon: Icons.hub_outlined,
            title: 'One Shared Family Hub',
            description:
                'Appointments, prescriptions, and daily care tasks synchronized across all siblings and relatives.',
          ),
          const SizedBox(height: 12),

          // Pillar 2: WhatsApp Summaries
          _PillarCard(
            icon: Icons.mark_chat_read_outlined,
            title: 'WhatsApp Care Summaries',
            description:
                'Generate clear, plain-language weekly updates to share directly with family on WhatsApp.',
          ),
          const SizedBox(height: 12),

          // Pillar 3: Offline & Private
          _PillarCard(
            icon: Icons.shield_outlined,
            title: 'Privacy & Offline First',
            description:
                'All critical emergency info, medicines, and records work seamlessly even without internet.',
          ),
          const SizedBox(height: 28),

          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              l10n.onboardingNext,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  const _PillarCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentPage extends StatelessWidget {
  const _ConsentPage({
    required this.l10n,
    required this.consents,
    required this.onToggle,
    required this.consentLabel,
    required this.consentIcon,
    required this.onNext,
  });

  final AppLocalizations l10n;
  final Map<ConsentPurpose, bool> consents;
  final void Function(ConsentPurpose, bool) onToggle;
  final String Function(ConsentPurpose) consentLabel;
  final IconData Function(ConsentPurpose) consentIcon;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.privacy_tip_outlined, color: scheme.primary, size: 36),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.onboardingPage2Title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingPage2Body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          for (final purpose in ConsentPurpose.values) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (consents[purpose] ?? false)
                      ? scheme.primary.withValues(alpha: 0.5)
                      : scheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(consentIcon(purpose), color: scheme.primary, size: 20),
                ),
                title: Text(
                  consentLabel(purpose),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: consents[purpose] ?? false,
                onChanged: (val) => onToggle(purpose, val),
              ),
            ),
          ],
          const SizedBox(height: 20),

          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              l10n.onboardingNext,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
