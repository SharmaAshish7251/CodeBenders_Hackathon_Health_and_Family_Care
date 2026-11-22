import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_data_seeder.dart';
import '../l10n/app_localizations.dart';
import '../models/consent.dart';
import '../providers/family_provider.dart';
import '../providers/session_provider.dart';

enum _SignInMode { demo, manual }

/// Sign-in screen featuring an interactive toggle between:
/// 1. Explore with Pre-loaded Demo Data (Instant Tour)
/// 2. Set up Family Manually (Fresh Start)
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key, required this.consents});

  /// Consent choices made during onboarding. Saved once the user is signed in.
  final Map<ConsentPurpose, bool> consents;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  _SignInMode _mode = _SignInMode.demo;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitManual() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() => _busy = true);
    try {
      final user = await ref.read(currentUserProvider.notifier).signIn(
            name: _nameController.text,
            phone: _phoneController.text,
          );
      await ref.read(consentProvider.notifier).saveAll(user.id, widget.consents);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _launchDemo() async {
    setState(() => _busy = true);
    try {
      await DemoDataSeeder.seed(ref);
      await ref
          .read(consentProvider.notifier)
          .saveAll(DemoDataSeeder.userRahulId, widget.consents);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.favorite_rounded, color: scheme.primary, size: 28),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.onboardingPage3Title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Choose how you want to get started with KinPulse',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Interactive Mode Toggle Button / Segmented Control
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ModeTabButton(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Explore Demo',
                    isSelected: _mode == _SignInMode.demo,
                    onTap: () => setState(() => _mode = _SignInMode.demo),
                  ),
                ),
                Expanded(
                  child: _ModeTabButton(
                    icon: Icons.edit_note_rounded,
                    label: 'Setup Manually',
                    isSelected: _mode == _SignInMode.manual,
                    onTap: () => setState(() => _mode = _SignInMode.manual),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Dynamic Body based on selected toggle
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _mode == _SignInMode.demo
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _DemoDataCard(
              busy: _busy,
              onLaunch: _launchDemo,
            ),
            secondChild: _ManualSetupForm(
              formKey: _formKey,
              nameController: _nameController,
              phoneController: _phoneController,
              busy: _busy,
              l10n: l10n,
              onSubmit: _submitManual,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  const _ModeTabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: isSelected ? scheme.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      elevation: isSelected ? 1 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoDataCard extends StatelessWidget {
  const _DemoDataCard({
    required this.busy,
    required this.onLaunch,
  });

  final bool busy;
  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instant Live Demo Space',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Pre-loaded with sample family care data',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Feature Highlights of Demo Data
            _FeatureRow(
              icon: Icons.person_outline_rounded,
              text: 'Care Recipient: Ramesh Sharma (Father, 72)',
            ),
            const SizedBox(height: 8),
            _FeatureRow(
              icon: Icons.task_alt_rounded,
              text: '4 Daily Tasks (2 completed, 2 pending)',
            ),
            const SizedBox(height: 8),
            _FeatureRow(
              icon: Icons.medication_outlined,
              text: 'Medicine Stock: Telmisartan (4 days remaining)',
            ),
            const SizedBox(height: 8),
            _FeatureRow(
              icon: Icons.groups_outlined,
              text: 'Care Team: Rahul (Admin), Priya & Sunita (Nurse)',
            ),
            const SizedBox(height: 8),
            _FeatureRow(
              icon: Icons.switch_account_rounded,
              text: 'In-App Role Switching: Admin, Caregiver & Viewer',
            ),
            const SizedBox(height: 20),

            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: busy ? null : onLaunch,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.rocket_launch_rounded),
              label: Text(
                busy ? 'Loading Demo Workspace...' : 'Explore Demo Workspace',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _ManualSetupForm extends StatelessWidget {
  const _ManualSetupForm({
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.busy,
    required this.l10n,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final bool busy;
  final AppLocalizations l10n;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Form(
      key: formKey,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter Your Information',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in to create your family space or join an existing one.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.signInNameLabel,
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? l10n.signInNameRequired
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.signInPhoneLabel,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? l10n.signInPhoneRequired
                    : null,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.signInStubNotice,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: busy ? null : onSubmit,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.arrow_forward),
                label: Text(
                  busy ? 'Signing in...' : 'Continue to Family Setup',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
