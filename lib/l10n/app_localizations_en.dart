// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Family Care Hub';

  @override
  String get homeTitle => 'Appointments';

  @override
  String get homeEmptyState => 'No appointments booked yet.';

  @override
  String get bookAppointmentFab => 'Book appointment';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearanceSection => 'Appearance';

  @override
  String get settingsThemeLabel => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsLanguageSection => 'Language';

  @override
  String get settingsLanguageLabel => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी';

  @override
  String get settingsConsentSection => 'Consent';

  @override
  String get settingsConsentHint =>
      'Turn off any choice to withdraw your consent.';

  @override
  String get settingsConsentNotSignedIn => 'Sign in to manage consent.';

  @override
  String get analyticsToggleTitle => 'Share usage analytics';

  @override
  String get analyticsToggleBody =>
      'Keep a local count of actions such as completed tasks. No names, phone numbers or health details are stored, and nothing is sent anywhere.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingPage1Title => 'What this app stores';

  @override
  String get onboardingPage1Body =>
      'Family care records, tasks and appointments are stored on this phone. You choose what you agree to on the next screen.';

  @override
  String get onboardingPage2Title => 'Your choices';

  @override
  String get onboardingPage2Body =>
      'Nothing is ticked by default. You can change these any time in Settings.';

  @override
  String get onboardingPage3Title => 'Sign in';

  @override
  String get consentDataStorage => 'Store my family\'s care data on this phone';

  @override
  String get consentOcrProcessing => 'Read text from photos of documents (OCR)';

  @override
  String get consentWhatsappSharing => 'Share summaries through WhatsApp';

  @override
  String get signInNameLabel => 'Your name';

  @override
  String get signInPhoneLabel => 'Phone number';

  @override
  String get signInSubmit => 'Continue';

  @override
  String get signInNameRequired => 'Please enter your name.';

  @override
  String get signInPhoneRequired => 'Please enter a phone number.';

  @override
  String get signInStubNotice =>
      'Sign-in is local on this device for now. No code is sent.';

  @override
  String get familySetupTitle => 'Create your family space';

  @override
  String get familyNameLabel => 'Family or care recipient name';

  @override
  String get familyCreateSubmit => 'Create family space';

  @override
  String get familyInviteTitle => 'Invite code';

  @override
  String get familyInviteBody =>
      'Share this code with family members so they can join.';

  @override
  String get familySetupContinue => 'Continue to app';

  @override
  String get joinWithCodeTitle => 'Join with a code';

  @override
  String get joinCodeLabel => '6-character invite code';

  @override
  String get joinCodeButton => 'Join family';

  @override
  String get joinCodeNotFound =>
      'No family matches that code. Check it and try again.';

  @override
  String get navHome => 'Home';

  @override
  String get navMembers => 'Members';

  @override
  String get navRecords => 'Records';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navTimeline => 'Timeline';

  @override
  String get dashboardPendingTasks => 'Pending tasks by person';

  @override
  String get dashboardNoPendingTasks => 'No pending tasks.';

  @override
  String get dashboardOverdue => 'Overdue';

  @override
  String get dashboardNoOverdue => 'Nothing overdue.';

  @override
  String get dashboardAppointments => 'Appointments';

  @override
  String get dashboardRecentActivity => 'Recent activity';

  @override
  String get dashboardNoActivity => 'No activity yet.';

  @override
  String get dashboardUnknownMember => 'Unknown member';

  @override
  String get dashboardPendingOverdueTitle => 'Pending and overdue';

  @override
  String dashboardOverdueCount(int count) {
    return 'Overdue: $count';
  }

  @override
  String dashboardMemberPendingCount(String name, int count) {
    return '$name: $count pending';
  }

  @override
  String get dashboardPendingEmptyAction =>
      'No pending tasks. Tap here to open Tasks and add one.';

  @override
  String get activityFamilyCreated => 'Created the family space';

  @override
  String get activityMemberRoleChanged => 'Changed a member\'s role';

  @override
  String get activityMemberJoined => 'A member joined the family';

  @override
  String get activityMemberRemoved => 'Removed a member';

  @override
  String get activityRecordCreated => 'Added a record';

  @override
  String get activityRecordUpdated => 'Updated a record';

  @override
  String get activityRecordDeleted => 'Deleted a record';

  @override
  String get activityTaskCreated => 'Added a task';

  @override
  String get activityTaskUpdated => 'Updated a task';

  @override
  String get activityTaskCompleted => 'Completed a task';

  @override
  String get activityTaskDeleted => 'Deleted a task';

  @override
  String get taskStatusTodo => 'To do';

  @override
  String get taskStatusDone => 'Done';

  @override
  String get taskStatusSkipped => 'Skipped';

  @override
  String get taskStatusOverdue => 'Overdue';

  @override
  String get recurrenceNone => 'Does not repeat';

  @override
  String get recurrenceDaily => 'Daily';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get recurrenceMonthly => 'Monthly';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleCaregiver => 'Caregiver';

  @override
  String get roleViewer => 'Viewer';

  @override
  String get roleDelegate => 'Delegate';

  @override
  String get memberYouSuffix => '(you)';

  @override
  String get membersTitle => 'Family members';

  @override
  String get membersEmpty => 'No members yet.';

  @override
  String get memberChangeRole => 'Change role';

  @override
  String get memberChangeRoleTitle => 'Choose a role';

  @override
  String get memberRemove => 'Remove';

  @override
  String get memberRemoveConfirm =>
      'Remove this member? They lose access straight away.';

  @override
  String get membersMenuTooltip => 'More';

  @override
  String get actionDeniedMessage => 'You do not have permission for that.';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get saveAction => 'Save';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get recordsTitle => 'Records';

  @override
  String get recordsSearchHint => 'Search by title, tag or date (YYYY-MM-DD)';

  @override
  String get recordsEmpty => 'No records yet.';

  @override
  String get recordsNoMatch => 'No records match your search.';

  @override
  String get recordAddFab => 'Add record';

  @override
  String get recordNewTitle => 'New record';

  @override
  String get recordTitleLabel => 'Title';

  @override
  String get recordTypeLabel => 'Type (for example prescription or lab report)';

  @override
  String get recordDateLabel => 'Date';

  @override
  String get recordTagsLabel => 'Tags, separated by commas';

  @override
  String get recordCaregiversOnly => 'Caregivers only (hidden from viewers)';

  @override
  String get recordEditTitle => 'Edit record';

  @override
  String get recordDeleteAction => 'Delete';

  @override
  String get recordDeleteConfirmTitle => 'Delete this record?';

  @override
  String get recordDeleteConfirmBody =>
      'The record will be removed for everyone in the family. This cannot be undone.';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get tasksEmpty => 'No tasks yet.';

  @override
  String get taskAddFab => 'Add task';

  @override
  String get taskNewTitle => 'New task';

  @override
  String get taskEditTitle => 'Edit task';

  @override
  String get taskEditAction => 'Edit';

  @override
  String get taskTitleLabel => 'Title';

  @override
  String get taskDescriptionLabel => 'Description (optional)';

  @override
  String get taskDueLabel => 'Due';

  @override
  String get taskAssigneeLabel => 'Assign to';

  @override
  String get taskRecurrenceLabel => 'Repeats';

  @override
  String get taskCompleteAction => 'Complete';

  @override
  String get taskSnoozeAction => 'Snooze 1 hour';

  @override
  String get taskReassignAction => 'Reassign';

  @override
  String get taskReassignTitle => 'Assign to';

  @override
  String get taskSkipAction => 'Mark skipped';

  @override
  String get taskDeleteAction => 'Delete';

  @override
  String get taskDeleteConfirmTitle => 'Delete this task?';

  @override
  String get taskDeleteConfirmBody =>
      'This task will be removed for everyone in the family. This cannot be undone.';

  @override
  String get taskCompletedLabel => 'Completed by';

  @override
  String get taskUnassigned => 'Unassigned';

  @override
  String get timelineTitle => 'Timeline';

  @override
  String get timelineFilterType => 'Type';

  @override
  String get timelineFilterPerson => 'Person';

  @override
  String get timelineFilterAll => 'All';

  @override
  String get timelineTypeAppointment => 'Appointments';

  @override
  String get timelineTypeRecord => 'Records';

  @override
  String get timelineTypeTask => 'Completed tasks';

  @override
  String get timelineEmpty => 'Nothing here yet.';

  @override
  String get medicinesTitle => 'Medicines';

  @override
  String get medicinesPrescriptionNote =>
      'Follow your doctor\'s prescription for the schedule. Medicine times and doses come from the prescription, not from this app.';

  @override
  String get medicinesEmpty => 'No medicines yet.';

  @override
  String get medicineAddFab => 'Add medicine';

  @override
  String get medicineNewTitle => 'New medicine';

  @override
  String get medicineNameLabel => 'Name';

  @override
  String get medicineScheduleLabel => 'Schedule note (optional)';

  @override
  String get medicineQuantityLabel => 'Quantity on hand';

  @override
  String get medicineDailyUsageLabel => 'Used per day';

  @override
  String get medicineRefillThresholdLabel => 'Refill warning (days left)';

  @override
  String get medicineNumberInvalid => 'Enter a whole number, 0 or more.';

  @override
  String get medicineUsageNotSet => 'Usage not set';

  @override
  String medicineDaysRemaining(int days) {
    return '$days days left';
  }

  @override
  String get medicineLowStock => 'Low stock';

  @override
  String get medicineAddRefillTask => 'Add refill task';

  @override
  String refillTaskTitle(String name) {
    return 'Refill $name';
  }

  @override
  String get refillTaskAdded => 'Refill task added.';

  @override
  String get emergencyTitle => 'Emergency info';

  @override
  String get emergencyBloodGroupLabel => 'Blood group';

  @override
  String get emergencyAllergiesLabel => 'Allergies';

  @override
  String get emergencyConditionsLabel => 'Medical conditions';

  @override
  String get emergencyContactLabel => 'Emergency contact';

  @override
  String get emergencyContactNameLabel => 'Contact name';

  @override
  String get emergencyContactPhoneLabel => 'Contact phone';

  @override
  String get emergencyHospitalLabel => 'Preferred hospital';

  @override
  String get emergencyDoctorLabel => 'Doctor contact';

  @override
  String get emergencyNotSet => 'Not set';

  @override
  String get emergencyCall112 => 'Call 112';

  @override
  String get emergencyCallNote =>
      'Dial 112 on your phone. This app cannot make calls.';

  @override
  String get emergencyDisclaimer =>
      'This app does not replace emergency services. In an emergency, call 112 first.';

  @override
  String get emergencyEditAction => 'Edit';

  @override
  String get emergencyEditTitle => 'Edit emergency info';

  @override
  String get closeAction => 'Close';

  @override
  String get navMedicines => 'Medicines';

  @override
  String get dueSoonLabel => 'Due soon';

  @override
  String get taskReminderBody => 'Due in 30 minutes';

  @override
  String get careGlanceTitle => 'Care at a glance';

  @override
  String careGlanceSummary(int done, int total) {
    return '$done of $total tasks done';
  }

  @override
  String get careGlanceWeekTitle => 'Completed in the last 7 days';

  @override
  String get careGlanceWeekChartLabel =>
      'Bar chart of tasks completed per day over the last 7 days';

  @override
  String careGlanceWeekSummary(int count) {
    return '$count tasks completed in the last 7 days';
  }

  @override
  String get careGlanceEmpty => 'No tasks yet, so there is nothing to chart.';

  @override
  String careGlanceChartLabel(int todo, int done, int skipped, int overdue) {
    return 'Task status: $todo to do, $done done, $skipped skipped, $overdue overdue';
  }

  @override
  String get summaryTitle => 'Care summary';

  @override
  String get summaryShareAction => 'Share summary';

  @override
  String get summaryCopyAction => 'Copy';

  @override
  String get summaryCopiedMessage =>
      'Summary copied. Paste it in WhatsApp to send it.';

  @override
  String get summaryExcludesNote =>
      'Attachments and Caregivers-only records are left out. You send this yourself in WhatsApp. The app does not post for you.';

  @override
  String summaryRecipientLine(String name) {
    return 'Care recipient: $name';
  }

  @override
  String summaryPeriodLine(String from, String to) {
    return 'Period: $from to $to';
  }

  @override
  String get summarySectionAppointments => 'Upcoming appointments';

  @override
  String summaryAppointmentLine(String when, String doctor) {
    return '$when - $doctor';
  }

  @override
  String get summarySectionTasks => 'Pending and overdue tasks';

  @override
  String summaryTaskLine(String name, String title, String due) {
    return '$name: $title (due $due)';
  }

  @override
  String summaryTaskOverdueLine(String name, String title, String due) {
    return '$name: $title (overdue, due $due)';
  }

  @override
  String get summarySectionMedicines => 'Medicines to refill';

  @override
  String summaryMedicineLine(String name, String status) {
    return '$name: $status';
  }

  @override
  String get summarySectionRecords => 'Recent records';

  @override
  String summaryRecordLine(String date, String title) {
    return '$date $title';
  }

  @override
  String get summarySectionActivity => 'Recent activity';

  @override
  String summaryActivityLine(String when, String action, String name) {
    return '$when $action ($name)';
  }

  @override
  String get summaryNone => 'None';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get ocrTitle => 'Scan a record';

  @override
  String get ocrIntro =>
      'Take a photo of a prescription or report, or pick one from your gallery. The text is read on this device.';

  @override
  String get ocrCamera => 'Camera';

  @override
  String get ocrGallery => 'Gallery';

  @override
  String get ocrProcessing => 'Reading text...';

  @override
  String get ocrNeedsConsent =>
      'Reading text from photos needs your consent. Turn on \'Read text from photos of documents (OCR)\' in Settings, then try again.';

  @override
  String get ocrFailed =>
      'We could not read any text from this image. Try a clearer photo, or enter the record yourself.';

  @override
  String get ocrEnterManually => 'Enter manually';

  @override
  String get ocrReviewTitle => 'Check scanned text';

  @override
  String get ocrTextLabel => 'Text read from the image (you can edit it)';

  @override
  String get ocrSuggestedDates => 'Dates found in the text (tap one to use it)';

  @override
  String get ocrSave => 'Save record';

  @override
  String get ocrSaved => 'Record saved from scan';

  @override
  String get glanceChartToggle => 'Show as chart';

  @override
  String get glanceTableToggle => 'Show as table';

  @override
  String get glanceTableMedicine => 'Medicine';

  @override
  String get glanceTableDaysLeft => 'Days left';

  @override
  String get glanceTableRefillAt => 'Refill at (days)';

  @override
  String get glanceMedicinesTitle => 'Medicine stock';

  @override
  String glanceMedicinesSummary(int low, int total) {
    return '$low of $total medicines need a refill';
  }

  @override
  String glanceMedicinesChartLabel(int total, int low) {
    return 'Days of stock left for $total medicines, $low below refill level';
  }

  @override
  String get glanceMedicineRefill => 'Refill';

  @override
  String get glanceMedicineMarkerLabel =>
      'The thin line marks the refill level for each medicine.';

  @override
  String glanceNoMedicineData(int count) {
    return '$count medicines have no daily usage set, so they are not charted.';
  }
}
