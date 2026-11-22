import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/role_guard.dart';
import '../l10n/app_localizations.dart';
import '../models/family_space.dart';
import '../providers/family_provider.dart';

enum _SetupMode { create, join }

/// Creates the family space or joins an existing one with an invite code.
class FamilySetupScreen extends ConsumerStatefulWidget {
  const FamilySetupScreen({
    super.key,
    this.createdFamily,
    this.onCreated,
    this.onContinue,
  });

  final FamilySpace? createdFamily;
  final ValueChanged<FamilySpace>? onCreated;
  final VoidCallback? onContinue;

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends ConsumerState<FamilySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _joinController = TextEditingController();

  _SetupMode _mode = _SetupMode.create;
  bool _busy = false;
  bool _joinBusy = false;
  bool _joinNotFound = false;

  @override
  void dispose() {
    _nameController.dispose();
    _joinController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() => _busy = true);
    try {
      final family = await ref
          .read(familySpaceProvider.notifier)
          .createFamily(_nameController.text.trim());
      widget.onCreated?.call(family);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final code = _joinController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _joinBusy = true;
      _joinNotFound = false;
    });
    try {
      final family = await ref
          .read(familySpaceProvider.notifier)
          .joinByCode(code);
      widget.onCreated?.call(family);
    } on NotFoundException {
      if (!mounted) return;
      setState(() {
        _joinBusy = false;
        _joinNotFound = true;
      });
    } finally {
      if (mounted) setState(() => _joinBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final created = widget.createdFamily;

    // View when family was just created: show invite code celebratory card
    if (created != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.familySetupTitle)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.celebration_rounded,
                      color: Color(0xFF2E7D32),
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  created.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.familyInviteTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Monospace Invite Code Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'INVITE CODE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        created.inviteCode,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy to Clipboard'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: created.inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Code ${created.inviteCode} copied!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.familyInviteBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: widget.onContinue,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    l10n.familySetupContinue,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.familySetupTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented Mode Selector: Create vs Join
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _TabButton(
                        icon: Icons.add_home_work_rounded,
                        label: 'Create New Space',
                        isSelected: _mode == _SetupMode.create,
                        onTap: () => setState(() => _mode = _SetupMode.create),
                      ),
                    ),
                    Expanded(
                      child: _TabButton(
                        icon: Icons.group_add_rounded,
                        label: 'Join with Code',
                        isSelected: _mode == _SetupMode.join,
                        onTap: () => setState(() => _mode = _SetupMode.join),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _mode == _SetupMode.create
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Form(
                  key: _formKey,
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.favorite_outline, color: scheme.primary, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Name Your Family Space',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'e.g. Sharma Family Care, Dad\'s Care Hub',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: l10n.familyNameLabel,
                              hintText: 'e.g. Sharma Family Care',
                              prefixIcon: const Icon(Icons.home_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            validator: (value) => (value ?? '').trim().isEmpty
                                ? l10n.fieldRequired
                                : null,
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _busy ? null : _create,
                            icon: _busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check_circle_outline),
                            label: Text(
                              _busy ? 'Creating...' : l10n.familyCreateSubmit,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                secondChild: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.vpn_key_outlined, color: scheme.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.joinWithCodeTitle,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Enter the 6-character code shared by your family',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _joinController,
                          maxLength: 8,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            letterSpacing: 3.0,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            labelText: l10n.joinCodeLabel,
                            hintText: 'e.g. KP-7249',
                            prefixIcon: const Icon(Icons.tag),
                            errorText: _joinNotFound ? l10n.joinCodeNotFound : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _joinBusy ? null : _join,
                          icon: _joinBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.login),
                          label: Text(
                            _joinBusy ? 'Joining...' : l10n.joinCodeButton,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
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
