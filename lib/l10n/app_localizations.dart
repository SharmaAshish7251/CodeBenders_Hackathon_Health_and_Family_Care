import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Family Care Hub'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get homeTitle;

  /// No description provided for @homeEmptyState.
  ///
  /// In en, this message translates to:
  /// **'No appointments booked yet.'**
  String get homeEmptyState;

  /// No description provided for @bookAppointmentFab.
  ///
  /// In en, this message translates to:
  /// **'Book appointment'**
  String get bookAppointmentFab;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceSection;

  /// No description provided for @settingsThemeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsThemeLabel;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsLanguageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageSection;

  /// No description provided for @settingsLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @settingsConsentSection.
  ///
  /// In en, this message translates to:
  /// **'Consent'**
  String get settingsConsentSection;

  /// No description provided for @settingsConsentHint.
  ///
  /// In en, this message translates to:
  /// **'Turn off any choice to withdraw your consent.'**
  String get settingsConsentHint;

  /// No description provided for @settingsConsentNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage consent.'**
  String get settingsConsentNotSignedIn;

  /// No description provided for @analyticsToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Share usage analytics'**
  String get analyticsToggleTitle;

  /// No description provided for @analyticsToggleBody.
  ///
  /// In en, this message translates to:
  /// **'Keep a local count of actions such as completed tasks. No names, phone numbers or health details are stored, and nothing is sent anywhere.'**
  String get analyticsToggleBody;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In en, this message translates to:
  /// **'What this app stores'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Body.
  ///
  /// In en, this message translates to:
  /// **'Family care records, tasks and appointments are stored on this phone. You choose what you agree to on the next screen.'**
  String get onboardingPage1Body;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Your choices'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Body.
  ///
  /// In en, this message translates to:
  /// **'Nothing is ticked by default. You can change these any time in Settings.'**
  String get onboardingPage2Body;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get onboardingPage3Title;

  /// No description provided for @consentDataStorage.
  ///
  /// In en, this message translates to:
  /// **'Store my family\'s care data on this phone'**
  String get consentDataStorage;

  /// No description provided for @consentOcrProcessing.
  ///
  /// In en, this message translates to:
  /// **'Read text from photos of documents (OCR)'**
  String get consentOcrProcessing;

  /// No description provided for @consentWhatsappSharing.
  ///
  /// In en, this message translates to:
  /// **'Share summaries through WhatsApp'**
  String get consentWhatsappSharing;

  /// No description provided for @signInNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get signInNameLabel;

  /// No description provided for @signInPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get signInPhoneLabel;

  /// No description provided for @signInSubmit.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get signInSubmit;

  /// No description provided for @signInNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name.'**
  String get signInNameRequired;

  /// No description provided for @signInPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a phone number.'**
  String get signInPhoneRequired;

  /// No description provided for @signInStubNotice.
  ///
  /// In en, this message translates to:
  /// **'Sign-in is local on this device for now. No code is sent.'**
  String get signInStubNotice;

  /// No description provided for @familySetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your family space'**
  String get familySetupTitle;

  /// No description provided for @familyNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Family or care recipient name'**
  String get familyNameLabel;

  /// No description provided for @familyCreateSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create family space'**
  String get familyCreateSubmit;

  /// No description provided for @familyInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get familyInviteTitle;

  /// No description provided for @familyInviteBody.
  ///
  /// In en, this message translates to:
  /// **'Share this code with family members so they can join.'**
  String get familyInviteBody;

  /// No description provided for @familySetupContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue to app'**
  String get familySetupContinue;

  /// No description provided for @joinWithCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get joinWithCodeTitle;

  /// No description provided for @joinCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-character invite code'**
  String get joinCodeLabel;

  /// No description provided for @joinCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Join family'**
  String get joinCodeButton;

  /// No description provided for @joinCodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'No family matches that code. Check it and try again.'**
  String get joinCodeNotFound;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get navMembers;

  /// No description provided for @navRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get navRecords;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get navTimeline;

  /// No description provided for @dashboardPendingTasks.
  ///
  /// In en, this message translates to:
  /// **'Pending tasks by person'**
  String get dashboardPendingTasks;

  /// No description provided for @dashboardNoPendingTasks.
  ///
  /// In en, this message translates to:
  /// **'No pending tasks.'**
  String get dashboardNoPendingTasks;

  /// No description provided for @dashboardOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get dashboardOverdue;

  /// No description provided for @dashboardNoOverdue.
  ///
  /// In en, this message translates to:
  /// **'Nothing overdue.'**
  String get dashboardNoOverdue;

  /// No description provided for @dashboardAppointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get dashboardAppointments;

  /// No description provided for @dashboardRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get dashboardRecentActivity;

  /// No description provided for @dashboardNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity yet.'**
  String get dashboardNoActivity;

  /// No description provided for @dashboardUnknownMember.
  ///
  /// In en, this message translates to:
  /// **'Unknown member'**
  String get dashboardUnknownMember;

  /// No description provided for @dashboardPendingOverdueTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending and overdue'**
  String get dashboardPendingOverdueTitle;

  /// No description provided for @dashboardOverdueCount.
  ///
  /// In en, this message translates to:
  /// **'Overdue: {count}'**
  String dashboardOverdueCount(int count);

  /// No description provided for @dashboardMemberPendingCount.
  ///
  /// In en, this message translates to:
  /// **'{name}: {count} pending'**
  String dashboardMemberPendingCount(String name, int count);

  /// No description provided for @dashboardPendingEmptyAction.
  ///
  /// In en, this message translates to:
  /// **'No pending tasks. Tap here to open Tasks and add one.'**
  String get dashboardPendingEmptyAction;

  /// No description provided for @activityFamilyCreated.
  ///
  /// In en, this message translates to:
  /// **'Created the family space'**
  String get activityFamilyCreated;

  /// No description provided for @activityMemberRoleChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed a member\'s role'**
  String get activityMemberRoleChanged;

  /// No description provided for @activityMemberJoined.
  ///
  /// In en, this message translates to:
  /// **'A member joined the family'**
  String get activityMemberJoined;

  /// No description provided for @activityMemberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed a member'**
  String get activityMemberRemoved;

  /// No description provided for @activityRecordCreated.
  ///
  /// In en, this message translates to:
  /// **'Added a record'**
  String get activityRecordCreated;

  /// No description provided for @activityRecordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated a record'**
  String get activityRecordUpdated;

  /// No description provided for @activityRecordDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted a record'**
  String get activityRecordDeleted;

  /// No description provided for @activityTaskCreated.
  ///
  /// In en, this message translates to:
  /// **'Added a task'**
  String get activityTaskCreated;

  /// No description provided for @activityTaskUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated a task'**
  String get activityTaskUpdated;

  /// No description provided for @activityTaskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed a task'**
  String get activityTaskCompleted;

  /// No description provided for @activityTaskDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted a task'**
  String get activityTaskDeleted;

  /// No description provided for @taskStatusTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get taskStatusTodo;

  /// No description provided for @taskStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskStatusDone;

  /// No description provided for @taskStatusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get taskStatusSkipped;

  /// No description provided for @taskStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get taskStatusOverdue;

  /// No description provided for @recurrenceNone.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get recurrenceNone;

  /// No description provided for @recurrenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get recurrenceDaily;

  /// No description provided for @recurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurrenceWeekly;

  /// No description provided for @recurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurrenceMonthly;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Caregiver'**
  String get roleCaregiver;

  /// No description provided for @roleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get roleViewer;

  /// No description provided for @roleDelegate.
  ///
  /// In en, this message translates to:
  /// **'Delegate'**
  String get roleDelegate;

  /// No description provided for @memberYouSuffix.
  ///
  /// In en, this message translates to:
  /// **'(you)'**
  String get memberYouSuffix;

  /// No description provided for @membersTitle.
  ///
  /// In en, this message translates to:
  /// **'Family members'**
  String get membersTitle;

  /// No description provided for @membersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No members yet.'**
  String get membersEmpty;

  /// No description provided for @memberChangeRole.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get memberChangeRole;

  /// No description provided for @memberChangeRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a role'**
  String get memberChangeRoleTitle;

  /// No description provided for @memberRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get memberRemove;

  /// No description provided for @memberRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this member? They lose access straight away.'**
  String get memberRemoveConfirm;

  /// No description provided for @membersMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get membersMenuTooltip;

  /// No description provided for @actionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission for that.'**
  String get actionDeniedMessage;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get fieldRequired;

  /// No description provided for @recordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get recordsTitle;

  /// No description provided for @recordsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title, tag or date (YYYY-MM-DD)'**
  String get recordsSearchHint;

  /// No description provided for @recordsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records yet.'**
  String get recordsEmpty;

  /// No description provided for @recordsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No records match your search.'**
  String get recordsNoMatch;

  /// No description provided for @recordAddFab.
  ///
  /// In en, this message translates to:
  /// **'Add record'**
  String get recordAddFab;

  /// No description provided for @recordNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New record'**
  String get recordNewTitle;

  /// No description provided for @recordTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get recordTitleLabel;

  /// No description provided for @recordTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type (for example prescription or lab report)'**
  String get recordTypeLabel;

  /// No description provided for @recordDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get recordDateLabel;

  /// No description provided for @recordTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags, separated by commas'**
  String get recordTagsLabel;

  /// No description provided for @recordCaregiversOnly.
  ///
  /// In en, this message translates to:
  /// **'Caregivers only (hidden from viewers)'**
  String get recordCaregiversOnly;

  /// No description provided for @recordEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit record'**
  String get recordEditTitle;

  /// No description provided for @recordDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get recordDeleteAction;

  /// No description provided for @recordDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this record?'**
  String get recordDeleteConfirmTitle;

  /// No description provided for @recordDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The record will be removed for everyone in the family. This cannot be undone.'**
  String get recordDeleteConfirmBody;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// No description provided for @tasksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet.'**
  String get tasksEmpty;

  /// No description provided for @taskAddFab.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get taskAddFab;

  /// No description provided for @taskNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New task'**
  String get taskNewTitle;

  /// No description provided for @taskEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get taskEditTitle;

  /// No description provided for @taskEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get taskEditAction;

  /// No description provided for @taskTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get taskTitleLabel;

  /// No description provided for @taskDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get taskDescriptionLabel;

  /// No description provided for @taskDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get taskDueLabel;

  /// No description provided for @taskAssigneeLabel.
  ///
  /// In en, this message translates to:
  /// **'Assign to'**
  String get taskAssigneeLabel;

  /// No description provided for @taskRecurrenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get taskRecurrenceLabel;

  /// No description provided for @taskCompleteAction.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get taskCompleteAction;

  /// No description provided for @taskSnoozeAction.
  ///
  /// In en, this message translates to:
  /// **'Snooze 1 hour'**
  String get taskSnoozeAction;

  /// No description provided for @taskReassignAction.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get taskReassignAction;

  /// No description provided for @taskReassignTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign to'**
  String get taskReassignTitle;

  /// No description provided for @taskSkipAction.
  ///
  /// In en, this message translates to:
  /// **'Mark skipped'**
  String get taskSkipAction;

  /// No description provided for @taskDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get taskDeleteAction;

  /// No description provided for @taskDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this task?'**
  String get taskDeleteConfirmTitle;

  /// No description provided for @taskDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This task will be removed for everyone in the family. This cannot be undone.'**
  String get taskDeleteConfirmBody;

  /// No description provided for @taskCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed by'**
  String get taskCompletedLabel;

  /// No description provided for @taskUnassigned.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get taskUnassigned;

  /// No description provided for @timelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timelineTitle;

  /// No description provided for @timelineFilterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get timelineFilterType;

  /// No description provided for @timelineFilterPerson.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get timelineFilterPerson;

  /// No description provided for @timelineFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get timelineFilterAll;

  /// No description provided for @timelineTypeAppointment.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get timelineTypeAppointment;

  /// No description provided for @timelineTypeRecord.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get timelineTypeRecord;

  /// No description provided for @timelineTypeTask.
  ///
  /// In en, this message translates to:
  /// **'Completed tasks'**
  String get timelineTypeTask;

  /// No description provided for @timelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get timelineEmpty;

  /// No description provided for @medicinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get medicinesTitle;

  /// No description provided for @medicinesPrescriptionNote.
  ///
  /// In en, this message translates to:
  /// **'Follow your doctor\'s prescription for the schedule. Medicine times and doses come from the prescription, not from this app.'**
  String get medicinesPrescriptionNote;

  /// No description provided for @medicinesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No medicines yet.'**
  String get medicinesEmpty;

  /// No description provided for @medicineAddFab.
  ///
  /// In en, this message translates to:
  /// **'Add medicine'**
  String get medicineAddFab;

  /// No description provided for @medicineNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New medicine'**
  String get medicineNewTitle;

  /// No description provided for @medicineNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get medicineNameLabel;

  /// No description provided for @medicineScheduleLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule note (optional)'**
  String get medicineScheduleLabel;

  /// No description provided for @medicineQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity on hand'**
  String get medicineQuantityLabel;

  /// No description provided for @medicineDailyUsageLabel.
  ///
  /// In en, this message translates to:
  /// **'Used per day'**
  String get medicineDailyUsageLabel;

  /// No description provided for @medicineRefillThresholdLabel.
  ///
  /// In en, this message translates to:
  /// **'Refill warning (days left)'**
  String get medicineRefillThresholdLabel;

  /// No description provided for @medicineNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number, 0 or more.'**
  String get medicineNumberInvalid;

  /// No description provided for @medicineUsageNotSet.
  ///
  /// In en, this message translates to:
  /// **'Usage not set'**
  String get medicineUsageNotSet;

  /// No description provided for @medicineDaysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String medicineDaysRemaining(int days);

  /// No description provided for @medicineLowStock.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get medicineLowStock;

  /// No description provided for @medicineAddRefillTask.
  ///
  /// In en, this message translates to:
  /// **'Add refill task'**
  String get medicineAddRefillTask;

  /// No description provided for @refillTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Refill {name}'**
  String refillTaskTitle(String name);

  /// No description provided for @refillTaskAdded.
  ///
  /// In en, this message translates to:
  /// **'Refill task added.'**
  String get refillTaskAdded;

  /// No description provided for @emergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency info'**
  String get emergencyTitle;

  /// No description provided for @emergencyBloodGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Blood group'**
  String get emergencyBloodGroupLabel;

  /// No description provided for @emergencyAllergiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get emergencyAllergiesLabel;

  /// No description provided for @emergencyConditionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Medical conditions'**
  String get emergencyConditionsLabel;

  /// No description provided for @emergencyContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact'**
  String get emergencyContactLabel;

  /// No description provided for @emergencyContactNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact name'**
  String get emergencyContactNameLabel;

  /// No description provided for @emergencyContactPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact phone'**
  String get emergencyContactPhoneLabel;

  /// No description provided for @emergencyHospitalLabel.
  ///
  /// In en, this message translates to:
  /// **'Preferred hospital'**
  String get emergencyHospitalLabel;

  /// No description provided for @emergencyDoctorLabel.
  ///
  /// In en, this message translates to:
  /// **'Doctor contact'**
  String get emergencyDoctorLabel;

  /// No description provided for @emergencyNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get emergencyNotSet;

  /// No description provided for @emergencyCall112.
  ///
  /// In en, this message translates to:
  /// **'Call 112'**
  String get emergencyCall112;

  /// No description provided for @emergencyCallNote.
  ///
  /// In en, this message translates to:
  /// **'Dial 112 on your phone. This app cannot make calls.'**
  String get emergencyCallNote;

  /// No description provided for @emergencyDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This app does not replace emergency services. In an emergency, call 112 first.'**
  String get emergencyDisclaimer;

  /// No description provided for @emergencyEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get emergencyEditAction;

  /// No description provided for @emergencyEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit emergency info'**
  String get emergencyEditTitle;

  /// No description provided for @closeAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeAction;

  /// No description provided for @navMedicines.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get navMedicines;

  /// No description provided for @dueSoonLabel.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get dueSoonLabel;

  /// No description provided for @taskReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Due in 30 minutes'**
  String get taskReminderBody;

  /// No description provided for @careGlanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Care at a glance'**
  String get careGlanceTitle;

  /// No description provided for @careGlanceSummary.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} tasks done'**
  String careGlanceSummary(int done, int total);

  /// No description provided for @careGlanceWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Completed in the last 7 days'**
  String get careGlanceWeekTitle;

  /// No description provided for @careGlanceWeekChartLabel.
  ///
  /// In en, this message translates to:
  /// **'Bar chart of tasks completed per day over the last 7 days'**
  String get careGlanceWeekChartLabel;

  /// No description provided for @careGlanceWeekSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} tasks completed in the last 7 days'**
  String careGlanceWeekSummary(int count);

  /// No description provided for @careGlanceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet, so there is nothing to chart.'**
  String get careGlanceEmpty;

  /// No description provided for @careGlanceChartLabel.
  ///
  /// In en, this message translates to:
  /// **'Task status: {todo} to do, {done} done, {skipped} skipped, {overdue} overdue'**
  String careGlanceChartLabel(int todo, int done, int skipped, int overdue);

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Care summary'**
  String get summaryTitle;

  /// No description provided for @summaryShareAction.
  ///
  /// In en, this message translates to:
  /// **'Share summary'**
  String get summaryShareAction;

  /// No description provided for @summaryCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get summaryCopyAction;

  /// No description provided for @summaryCopiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Summary copied. Paste it in WhatsApp to send it.'**
  String get summaryCopiedMessage;

  /// No description provided for @summaryExcludesNote.
  ///
  /// In en, this message translates to:
  /// **'Attachments and Caregivers-only records are left out. You send this yourself in WhatsApp. The app does not post for you.'**
  String get summaryExcludesNote;

  /// No description provided for @summaryRecipientLine.
  ///
  /// In en, this message translates to:
  /// **'Care recipient: {name}'**
  String summaryRecipientLine(String name);

  /// No description provided for @summaryPeriodLine.
  ///
  /// In en, this message translates to:
  /// **'Period: {from} to {to}'**
  String summaryPeriodLine(String from, String to);

  /// No description provided for @summarySectionAppointments.
  ///
  /// In en, this message translates to:
  /// **'Upcoming appointments'**
  String get summarySectionAppointments;

  /// No description provided for @summaryAppointmentLine.
  ///
  /// In en, this message translates to:
  /// **'{when} - {doctor}'**
  String summaryAppointmentLine(String when, String doctor);

  /// No description provided for @summarySectionTasks.
  ///
  /// In en, this message translates to:
  /// **'Pending and overdue tasks'**
  String get summarySectionTasks;

  /// No description provided for @summaryTaskLine.
  ///
  /// In en, this message translates to:
  /// **'{name}: {title} (due {due})'**
  String summaryTaskLine(String name, String title, String due);

  /// No description provided for @summaryTaskOverdueLine.
  ///
  /// In en, this message translates to:
  /// **'{name}: {title} (overdue, due {due})'**
  String summaryTaskOverdueLine(String name, String title, String due);

  /// No description provided for @summarySectionMedicines.
  ///
  /// In en, this message translates to:
  /// **'Medicines to refill'**
  String get summarySectionMedicines;

  /// No description provided for @summaryMedicineLine.
  ///
  /// In en, this message translates to:
  /// **'{name}: {status}'**
  String summaryMedicineLine(String name, String status);

  /// No description provided for @summarySectionRecords.
  ///
  /// In en, this message translates to:
  /// **'Recent records'**
  String get summarySectionRecords;

  /// No description provided for @summaryRecordLine.
  ///
  /// In en, this message translates to:
  /// **'{date} {title}'**
  String summaryRecordLine(String date, String title);

  /// No description provided for @summarySectionActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get summarySectionActivity;

  /// No description provided for @summaryActivityLine.
  ///
  /// In en, this message translates to:
  /// **'{when} {action} ({name})'**
  String summaryActivityLine(String when, String action, String name);

  /// No description provided for @summaryNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get summaryNone;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @ocrTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a record'**
  String get ocrTitle;

  /// No description provided for @ocrIntro.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of a prescription or report, or pick one from your gallery. The text is read on this device.'**
  String get ocrIntro;

  /// No description provided for @ocrCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get ocrCamera;

  /// No description provided for @ocrGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get ocrGallery;

  /// No description provided for @ocrProcessing.
  ///
  /// In en, this message translates to:
  /// **'Reading text...'**
  String get ocrProcessing;

  /// No description provided for @ocrNeedsConsent.
  ///
  /// In en, this message translates to:
  /// **'Reading text from photos needs your consent. Turn on \'Read text from photos of documents (OCR)\' in Settings, then try again.'**
  String get ocrNeedsConsent;

  /// No description provided for @ocrFailed.
  ///
  /// In en, this message translates to:
  /// **'We could not read any text from this image. Try a clearer photo, or enter the record yourself.'**
  String get ocrFailed;

  /// No description provided for @ocrEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get ocrEnterManually;

  /// No description provided for @ocrReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Check scanned text'**
  String get ocrReviewTitle;

  /// No description provided for @ocrTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Text read from the image (you can edit it)'**
  String get ocrTextLabel;

  /// No description provided for @ocrSuggestedDates.
  ///
  /// In en, this message translates to:
  /// **'Dates found in the text (tap one to use it)'**
  String get ocrSuggestedDates;

  /// No description provided for @ocrSave.
  ///
  /// In en, this message translates to:
  /// **'Save record'**
  String get ocrSave;

  /// No description provided for @ocrSaved.
  ///
  /// In en, this message translates to:
  /// **'Record saved from scan'**
  String get ocrSaved;

  /// No description provided for @glanceChartToggle.
  ///
  /// In en, this message translates to:
  /// **'Show as chart'**
  String get glanceChartToggle;

  /// No description provided for @glanceTableToggle.
  ///
  /// In en, this message translates to:
  /// **'Show as table'**
  String get glanceTableToggle;

  /// No description provided for @glanceTableMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get glanceTableMedicine;

  /// No description provided for @glanceTableDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'Days left'**
  String get glanceTableDaysLeft;

  /// No description provided for @glanceTableRefillAt.
  ///
  /// In en, this message translates to:
  /// **'Refill at (days)'**
  String get glanceTableRefillAt;

  /// No description provided for @glanceMedicinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Medicine stock'**
  String get glanceMedicinesTitle;

  /// No description provided for @glanceMedicinesSummary.
  ///
  /// In en, this message translates to:
  /// **'{low} of {total} medicines need a refill'**
  String glanceMedicinesSummary(int low, int total);

  /// No description provided for @glanceMedicinesChartLabel.
  ///
  /// In en, this message translates to:
  /// **'Days of stock left for {total} medicines, {low} below refill level'**
  String glanceMedicinesChartLabel(int total, int low);

  /// No description provided for @glanceMedicineRefill.
  ///
  /// In en, this message translates to:
  /// **'Refill'**
  String get glanceMedicineRefill;

  /// No description provided for @glanceMedicineMarkerLabel.
  ///
  /// In en, this message translates to:
  /// **'The thin line marks the refill level for each medicine.'**
  String get glanceMedicineMarkerLabel;

  /// No description provided for @glanceNoMedicineData.
  ///
  /// In en, this message translates to:
  /// **'{count} medicines have no daily usage set, so they are not charted.'**
  String glanceNoMedicineData(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
