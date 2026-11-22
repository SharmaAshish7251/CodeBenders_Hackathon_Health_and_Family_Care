import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'firebase_options.dart';
import 'theme/care_theme.dart';
import 'widgets/emergency_button.dart';
import 'widgets/empty_state_card.dart';
import 'widgets/interactive_task_card.dart';
import 'widgets/offline_banner.dart';
import 'widgets/presence_avatar_strip.dart';
import 'widgets/today_progress_ring.dart';
import 'widgets/user_switch_sheet.dart';


import 'l10n/app_localizations.dart';
import 'models/activity_event.dart';
import 'models/appointment.dart';
import 'models/family_member.dart';
import 'models/family_space.dart';
import 'models/task.dart';
import 'providers/appointments_provider.dart';
import 'providers/family_provider.dart';
import 'providers/care_provider.dart';
import 'providers/medicine_provider.dart';
import 'providers/session_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/book_appointment_sheet.dart';
import 'screens/family_setup_screen.dart';
import 'screens/members_screen.dart';
import 'screens/ocr_capture_screen.dart';
import 'screens/medicines_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/records_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/summary_dialog.dart';
import 'screens/tasks_screen.dart';
import 'screens/timeline_screen.dart';
import 'services/reminder_service.dart';
import 'widgets/care_labels.dart';

/// Window for the "Due soon" label. This reminder is in-app only: it shows on
/// the dashboard while the app is open. No OS notifications are scheduled.
const reminderOffset = Duration(minutes: 30);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization note: $e');
  }
  await reminderService.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: settings.locale,
      theme: CareTheme.light(),
      darkTheme: CareTheme.dark(),
      themeMode: settings.themeMode,
      home: const AppEntry(),
    );
  }
}

/// Decides which first-run step to show: onboarding and sign-in, then family
/// setup, then the home dashboard.
class AppEntry extends ConsumerStatefulWidget {
  const AppEntry({super.key});

  @override
  ConsumerState<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends ConsumerState<AppEntry> {
  /// Set when a family was just created, so its invite code stays on screen
  /// until the user continues.
  FamilySpace? _justCreated;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final family = ref.watch(familySpaceProvider);

    if ((user.isLoading && !user.hasValue) ||
        (family.isLoading && !family.hasValue)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user.hasError || family.hasError) {
      return Scaffold(body: Center(child: Text(l10n.genericError)));
    }
    if (user.value == null) return const OnboardingScreen();

    final created = _justCreated;
    if (created != null) {
      return FamilySetupScreen(
        createdFamily: created,
        onContinue: () => setState(() => _justCreated = null),
      );
    }
    if (family.value == null) {
      return FamilySetupScreen(
        onCreated: (space) => setState(() => _justCreated = space),
      );
    }
    return Builder(
      builder: (context) => MyHomePage(
        title: AppLocalizations.of(context)!.homeTitle,
      ),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_currentIndex) {
        0 => _PulseTab(title: widget.title),
        1 => const TasksScreen(),
        2 => const RecordsScreen(),
        3 => const MembersScreen(),
        _ => _PulseTab(title: widget.title),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Pulse',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Health Vault',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Family Hub',
          ),
        ],
      ),
    );
  }
}

/// The primary "Pulse" dashboard matching the KinPulse design.
class _PulseTab extends ConsumerWidget {
  const _PulseTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(appointmentsProvider);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tasks = ref.watch(tasksProvider).value ?? const <CareTask>[];
    final members = ref.watch(membersProvider).value ?? const <FamilyMember>[];
    final activity =
        ref.watch(activityProvider).value ?? const <ActivityEvent>[];
    final user = ref.watch(currentUserProvider).value;
    final settings = ref.watch(settingsProvider);
    final medicines = ref.watch(medicinesProvider).value ?? const [];

    final names = {for (final member in members) member.id: member.name};
    final now = DateTime.now();
    final open = tasks.where((task) => task.status == TaskStatus.todo).toList();
    final overdue = open.where((task) => task.dueAt.isBefore(now)).toList();
    final completed = tasks.where((task) => task.status == TaskStatus.done).toList();
    final totalToday = open.length + completed.length;

    // Check for medicine low on stock
    final lowStockMed = medicines.where((m) =>
        m.dailyUsage > 0 &&
        (m.quantityOnHand / m.dailyUsage) <= m.refillThresholdDays).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KinPulse',
              style: theme.textTheme.titleLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            InkWell(
              onTap: () => UserSwitchSheet.show(context),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz, size: 14, color: scheme.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        user?.name ?? 'Rahul (Bangalore)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, size: 16, color: scheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Language switcher pill
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              minimumSize: const Size(0, 30),
              visualDensity: VisualDensity.compact,
              backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final nextLocale = settings.locale.languageCode == 'en'
                  ? const Locale('hi')
                  : const Locale('en');
              ref.read(settingsProvider.notifier).setLocale(nextLocale);
            },
            child: Text(
              settings.locale.languageCode == 'en' ? 'EN' : 'हि',
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // Dark/Light mode toggle
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            icon: Icon(
              settings.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode_outlined,
              size: 19,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () {
              final nextMode = settings.themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
              ref.read(settingsProvider.notifier).setThemeMode(nextMode);
            },
          ),
          // Settings button
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            icon: const Icon(Icons.settings_outlined, size: 19),
            tooltip: l10n.settingsTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            ),
          ),
          // Emergency SOS button (breathing pulse)
          const EmergencyButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          // Offline indicator
          const OfflineBanner(status: SyncStatus.online),

          // 1. Hero Care Recipient & Status Card
          Card(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFC8E6C9),
                        child: const Icon(Icons.person, color: Color(0xFF2E7D32), size: 28),
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
                                    'Ramesh Sharma',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFECB3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE65100),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'LIVE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFE65100),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Father • Age 72 • Jaipur, Rajasthan',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        tooltip: 'Refresh Care Data',
                        onPressed: () {
                          ref.invalidate(tasksProvider);
                          ref.invalidate(recordsProvider);
                          ref.invalidate(medicinesProvider);
                          ref.invalidate(activityProvider);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Action Needed Today banner
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const MedicinesScreen()),
                    ),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFE082)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Text(
                                      'Action Needed Today',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFFE65100),
                                      ),
                                    ),
                                    Spacer(),
                                    Text(
                                      'View Refills →',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE65100),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lowStockMed != null
                                      ? '${lowStockMed.name} is running low (${lowStockMed.quantityOnHand ~/ lowStockMed.dailyUsage} days left).'
                                      : 'Telmisartan (Telma 40) is running low (4 days left).',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF424242),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats row: Progress ring + Completed + Pending + Refills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TodayProgressRing(
                        completed: completed.length,
                        total: totalToday > 0 ? totalToday : 1,
                        size: 72,
                        strokeWidth: 8,
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.done_all, color: Color(0xFF2E7D32), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${completed.length}',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Text('Completed', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.hourglass_empty, color: Color(0xFF00695C), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${open.length}',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Text('Pending', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const MedicinesScreen()),
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.medication, color: Color(0xFFC62828), size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '1',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const Text('Refills', style: TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 2. Routine & Streak Card
          Card(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE0B2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Text('🔥', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text(
                              '12-Day Streak',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB2DFDB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '100% Routine',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF004D40),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Weekly Days Row: M, T, W, T, F, S, S
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final d in [
                        ('M', true),
                        ('T', true),
                        ('W', true),
                        ('T', true),
                        ('F', true),
                        ('S', true),
                        ('S', false),
                      ])
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: d.$2
                                  ? const Color(0xFF2E7D32)
                                  : scheme.surfaceContainerHighest,
                              child: d.$2
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: scheme.onSurfaceVariant,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d.$1,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.favorite, color: Color(0xFFE91E63), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Shared Care Today: Priya (Jaipur) gave morning BP meds; Sunita recorded 124/82.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Quick Action Buttons Row (WhatsApp Update + Scan Rx Slip + Timeline & Meds)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text(
                          'WhatsApp Update',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => SummaryDialog.show(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.document_scanner_outlined, size: 18),
                        label: const Text(
                          'Scan Rx Slip',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const OcrCaptureScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ActionChip(
                        avatar: const Icon(Icons.timeline_rounded, size: 16),
                        label: const Text('Care Timeline', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const TimelineScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ActionChip(
                        avatar: const Icon(Icons.medication_outlined, size: 16),
                        label: const Text('Medicine Stock', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const MedicinesScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. Active Family Caregivers
          if (members.isNotEmpty) ...[
            _SectionHeader(text: 'Care Team on Duty'),
            PresenceAvatarStrip(members: members),
          ],

          // 5. Today's Appointments
          _SectionHeader(text: l10n.dashboardAppointments),
          if (appointments.isEmpty)
            _EmptyLine(text: l10n.homeEmptyState)
          else
            for (final Appointment appointment in appointments)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.medical_services_outlined, color: scheme.primary, size: 22),
                  ),
                  title: Text(
                    appointment.doctorName,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    appointment.note == null
                        ? appointment.formattedDateTime
                        : '${appointment.formattedDateTime} • ${appointment.note}',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Scheduled',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

          // 6. Overdue & Pending Tasks
          if (overdue.isNotEmpty) ...[
            _SectionHeader(text: l10n.dashboardOverdue),
            for (final task in overdue)
              InteractiveTaskCard(
                task: task,
                assigneeName: names[task.assigneeId],
              ),
          ],

          _SectionHeader(text: l10n.dashboardPendingTasks),
          if (open.isEmpty)
            EmptyStateCard(
              icon: Icons.task_alt,
              title: l10n.dashboardNoPendingTasks,
              actionLabel: l10n.taskAddFab,
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const TasksScreen()),
              ),
            )
          else
            for (final task in open)
              InteractiveTaskCard(
                task: task,
                assigneeName: names[task.assigneeId],
                isDueSoon: _isDueSoon(task, now),
              ),

          // 7. Care Analytics Overview
          const _CareAtAGlanceCard(),

          // 8. Recent Activity feed
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.dashboardRecentActivity,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.timeline_rounded, size: 16),
                  label: const Text('Full Timeline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const TimelineScreen()),
                  ),
                ),
              ],
            ),
          ),
          if (activity.isEmpty)
            _EmptyLine(text: l10n.dashboardNoActivity)
          else
            for (final event in activity.take(4))
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                elevation: 0,
                color: scheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
                    child: Icon(Icons.history_rounded, size: 16, color: scheme.primary),
                  ),
                  title: Text(
                    activityLabel(l10n, event.action),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${names[event.actorId] ?? l10n.dashboardUnknownMember} • ${formatDateTime(event.at)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
          const SizedBox(height: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => BookAppointmentSheet.show(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.bookAppointmentFab),
      ),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// True for a pending task due within [reminderOffset] of [now]. Overdue tasks
/// are excluded because they already show under Overdue.
bool _isDueSoon(CareTask task, DateTime now) {
  return !task.dueAt.isBefore(now) &&
      task.dueAt.difference(now) <= reminderOffset;
}

/// "Care at a glance": a pie chart of task counts by status and a bar chart of
/// tasks completed per day over the last 7 days. Both read the derived
/// providers in care_provider.dart, so no counting happens here.
class _CareAtAGlanceCard extends ConsumerWidget {
  const _CareAtAGlanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final counts = ref.watch(taskStatusCountsProvider);
    final perDay = ref.watch(taskCompletedPerDayProvider);

    var maxPerDay = 1;
    var weekDone = 0;
    for (final count in perDay) {
      weekDone += count;
      if (count > maxPerDay) maxPerDay = count;
    }

    // Index 0 is six days ago, index 6 is today (matches taskCompletedPerDayProvider).
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final today = DateTime.now();
    String dayLabel(int index) {
      final day = DateTime(today.year, today.month, today.day - (6 - index));
      return DateFormat.E(localeName).format(day);
    }

    PieChartSectionData section(int value, Color color) {
      return PieChartSectionData(
        value: value.toDouble(),
        color: color,
        radius: 28,
      );
    }

    Widget legend(Color color, String label, int count) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text('$label: $count'),
        ],
      );
    }

    final chartLabel = l10n.careGlanceChartLabel(
      counts.todo,
      counts.done,
      counts.skipped,
      counts.overdue,
    );

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.careGlanceTitle,
              style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary),
            ),
            const SizedBox(height: 8),
            if (counts.total == 0)
              Text(l10n.careGlanceEmpty)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: chartLabel,
                          child: SizedBox(
                            height: 160,
                            child: PieChart(
                              PieChartData(
                                centerSpaceRadius: 40,
                                sectionsSpace: 2,
                                sections: [
                                  // Zero-count sections are skipped.
                                  if (counts.todo > 0)
                                    section(counts.todo, scheme.primary),
                                  if (counts.done > 0)
                                    section(counts.done, scheme.tertiary),
                                  if (counts.skipped > 0)
                                    section(counts.skipped, scheme.outline),
                                  if (counts.overdue > 0)
                                    section(counts.overdue, scheme.error),
                                ],
                              ),
                              duration: const Duration(milliseconds: 300),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            legend(scheme.primary, l10n.taskStatusTodo, counts.todo),
                            legend(scheme.tertiary, l10n.taskStatusDone, counts.done),
                            legend(scheme.outline, l10n.taskStatusSkipped, counts.skipped),
                            legend(scheme.error, l10n.taskStatusOverdue, counts.overdue),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(l10n.careGlanceSummary(counts.done, counts.total)),
                ],
              ),
            const SizedBox(height: 12),
            Text(
              l10n.careGlanceWeekTitle,
              style: theme.textTheme.labelLarge,
            ),
            Semantics(
              label: l10n.careGlanceWeekChartLabel,
              child: SizedBox(
                height: 120,
                child: BarChart(
                  BarChartData(
                    maxY: maxPerDay.toDouble(),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index > 6) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(dayLabel(index)),
                            );
                          },
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < 7; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: perDay[i].toDouble(),
                              color: scheme.primary,
                              width: 14,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 300),
                ),
              ),
            ),
            Text(l10n.careGlanceWeekSummary(weekDone)),
          ],
        ),
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(text),
    );
  }
}
