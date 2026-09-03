import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
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
    Locale('id'),
  ];

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @viewingMonthWarning.
  ///
  /// In en, this message translates to:
  /// **'Viewing {month}. Daily check-ins still follow the selected date from Habits.'**
  String viewingMonthWarning(String month);

  /// No description provided for @todaysProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todaysProgress;

  /// No description provided for @progressWithDate.
  ///
  /// In en, this message translates to:
  /// **'Progress · {date}'**
  String progressWithDate(String date);

  /// No description provided for @useToday.
  ///
  /// In en, this message translates to:
  /// **'Use today'**
  String get useToday;

  /// No description provided for @unableToLoadProgress.
  ///
  /// In en, this message translates to:
  /// **'Unable to load progress: {error}'**
  String unableToLoadProgress(String error);

  /// No description provided for @habitsCompletedRatio.
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} habits'**
  String habitsCompletedRatio(int completed, int total);

  /// No description provided for @sleepWithDate.
  ///
  /// In en, this message translates to:
  /// **'Sleep · {date}'**
  String sleepWithDate(String date);

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @unableToLoadSleepLog.
  ///
  /// In en, this message translates to:
  /// **'Unable to load sleep log'**
  String get unableToLoadSleepLog;

  /// No description provided for @tapToLogSleep.
  ///
  /// In en, this message translates to:
  /// **'Tap to log sleep'**
  String get tapToLogSleep;

  /// No description provided for @hoursLogged.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours logged'**
  String hoursLogged(String hours);

  /// No description provided for @activityHeatmapMonth.
  ///
  /// In en, this message translates to:
  /// **'Activity Heatmap · {month}'**
  String activityHeatmapMonth(String month);

  /// No description provided for @unableToLoadHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Unable to load heatmap: {error}'**
  String unableToLoadHeatmap(String error);

  /// No description provided for @profileAndSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get profileAndSettings;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @exportDataToCsv.
  ///
  /// In en, this message translates to:
  /// **'Export Data to CSV'**
  String get exportDataToCsv;

  /// No description provided for @habitsLogsAndJournals.
  ///
  /// In en, this message translates to:
  /// **'Habits, logs, and journals'**
  String get habitsLogsAndJournals;

  /// No description provided for @backupDataJson.
  ///
  /// In en, this message translates to:
  /// **'Backup Data (JSON)'**
  String get backupDataJson;

  /// No description provided for @fullStructuredBackup.
  ///
  /// In en, this message translates to:
  /// **'Full structured backup'**
  String get fullStructuredBackup;

  /// No description provided for @restoreData.
  ///
  /// In en, this message translates to:
  /// **'Restore Data'**
  String get restoreData;

  /// No description provided for @restoreFromJsonBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from JSON backup'**
  String get restoreFromJsonBackup;

  /// No description provided for @dailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get dailyReminder;

  /// No description provided for @atTime.
  ///
  /// In en, this message translates to:
  /// **'At {time}'**
  String atTime(String time);

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @csvExportCompleted.
  ///
  /// In en, this message translates to:
  /// **'CSV Export completed'**
  String get csvExportCompleted;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @backupCompleted.
  ///
  /// In en, this message translates to:
  /// **'Backup completed'**
  String get backupCompleted;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailed(String error);

  /// No description provided for @dataRestoredSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully'**
  String get dataRestoredSuccessfully;

  /// No description provided for @restoreCanceled.
  ///
  /// In en, this message translates to:
  /// **'Restore canceled'**
  String get restoreCanceled;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(String error);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @newHabit.
  ///
  /// In en, this message translates to:
  /// **'New Habit'**
  String get newHabit;

  /// No description provided for @habitName.
  ///
  /// In en, this message translates to:
  /// **'Habit name'**
  String get habitName;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @failedToSaveHabit.
  ///
  /// In en, this message translates to:
  /// **'Failed to save habit: {error}'**
  String failedToSaveHabit(String error);

  /// No description provided for @habits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get habits;

  /// No description provided for @noHabitsYet.
  ///
  /// In en, this message translates to:
  /// **'No habits yet'**
  String get noHabitsYet;

  /// No description provided for @tapToCreateHabit.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first habit'**
  String get tapToCreateHabit;

  /// No description provided for @habitsDoneRatio.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} done'**
  String habitsDoneRatio(int completed, int total);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @unableToLoadHabits.
  ///
  /// In en, this message translates to:
  /// **'Unable to load habits: {error}'**
  String unableToLoadHabits(String error);

  /// No description provided for @unableToLoadCompletionData.
  ///
  /// In en, this message translates to:
  /// **'Unable to load completion data: {error}'**
  String unableToLoadCompletionData(String error);

  /// No description provided for @noActiveHabits.
  ///
  /// In en, this message translates to:
  /// **'No active habits for this date'**
  String get noActiveHabits;

  /// No description provided for @habitsCreatedAfterExcluded.
  ///
  /// In en, this message translates to:
  /// **'Habits created after the selected date are intentionally excluded.'**
  String get habitsCreatedAfterExcluded;

  /// No description provided for @deleteHabit.
  ///
  /// In en, this message translates to:
  /// **'Delete Habit'**
  String get deleteHabit;

  /// No description provided for @deleteHabitConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{habitName}\" and all its logs?'**
  String deleteHabitConfirmation(String habitName);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @markIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Mark incomplete'**
  String get markIncomplete;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get markComplete;

  /// No description provided for @dailyProgress.
  ///
  /// In en, this message translates to:
  /// **'Daily Progress'**
  String get dailyProgress;

  /// No description provided for @sleepTracker.
  ///
  /// In en, this message translates to:
  /// **'Sleep Tracker'**
  String get sleepTracker;

  /// No description provided for @logSleep.
  ///
  /// In en, this message translates to:
  /// **'Log Sleep'**
  String get logSleep;

  /// No description provided for @timeInBed.
  ///
  /// In en, this message translates to:
  /// **'Time in bed'**
  String get timeInBed;

  /// No description provided for @xHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String xHours(String hours);

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @howDidYouSleep.
  ///
  /// In en, this message translates to:
  /// **'How did you sleep?'**
  String get howDidYouSleep;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @unableToSaveSleepLog.
  ///
  /// In en, this message translates to:
  /// **'Unable to save sleep log: {error}'**
  String unableToSaveSleepLog(String error);

  /// No description provided for @journal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @todaysEntry.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Entry'**
  String get todaysEntry;

  /// No description provided for @journalHint.
  ///
  /// In en, this message translates to:
  /// **'Write about your day, reflect on your progress...'**
  String get journalHint;

  /// No description provided for @cannotAddJournalFuture.
  ///
  /// In en, this message translates to:
  /// **'Cannot add journal entries for future dates.'**
  String get cannotAddJournalFuture;

  /// No description provided for @journalAutoSaveHint.
  ///
  /// In en, this message translates to:
  /// **'💡 Your journal auto-saves as you type. Take your time.'**
  String get journalAutoSaveHint;

  /// No description provided for @howAreYouFeeling.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling?'**
  String get howAreYouFeeling;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorMessage(String error);

  /// No description provided for @failedToSave.
  ///
  /// In en, this message translates to:
  /// **'Failed to save: {error}'**
  String failedToSave(String error);

  /// No description provided for @moodAwful.
  ///
  /// In en, this message translates to:
  /// **'Awful'**
  String get moodAwful;

  /// No description provided for @moodBad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get moodBad;

  /// No description provided for @moodOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get moodOkay;

  /// No description provided for @moodGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get moodGood;

  /// No description provided for @moodGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get moodGreat;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @completionRate.
  ///
  /// In en, this message translates to:
  /// **'Completion Rate'**
  String get completionRate;

  /// No description provided for @ratePercentage.
  ///
  /// In en, this message translates to:
  /// **'{rate}%'**
  String ratePercentage(String rate);

  /// No description provided for @activeHabits.
  ///
  /// In en, this message translates to:
  /// **'Active Habits'**
  String get activeHabits;

  /// No description provided for @averageSleep.
  ///
  /// In en, this message translates to:
  /// **'Average Sleep'**
  String get averageSleep;

  /// No description provided for @habitConsistency.
  ///
  /// In en, this message translates to:
  /// **'Habit Consistency'**
  String get habitConsistency;

  /// No description provided for @moodCorrelation.
  ///
  /// In en, this message translates to:
  /// **'Mood Correlation'**
  String get moodCorrelation;

  /// No description provided for @noMoodData.
  ///
  /// In en, this message translates to:
  /// **'No mood data available for this month.'**
  String get noMoodData;

  /// No description provided for @habitInsightsFor.
  ///
  /// In en, this message translates to:
  /// **'Habit insights for {month}'**
  String habitInsightsFor(String month);

  /// No description provided for @unableToLoadStatistics.
  ///
  /// In en, this message translates to:
  /// **'Unable to load statistics: {error}'**
  String unableToLoadStatistics(String error);

  /// No description provided for @dailyCompletionRate.
  ///
  /// In en, this message translates to:
  /// **'Daily Completion Rate'**
  String get dailyCompletionRate;

  /// No description provided for @sleepDurationHours.
  ///
  /// In en, this message translates to:
  /// **'Sleep Duration (Hours)'**
  String get sleepDurationHours;

  /// No description provided for @moodVsHabitCompletion.
  ///
  /// In en, this message translates to:
  /// **'Mood vs. Habit Completion'**
  String get moodVsHabitCompletion;

  /// No description provided for @avgCompletionGroupedByMood.
  ///
  /// In en, this message translates to:
  /// **'Average completion rate grouped by daily mood'**
  String get avgCompletionGroupedByMood;

  /// No description provided for @avgCompletion.
  ///
  /// In en, this message translates to:
  /// **'Avg Completion'**
  String get avgCompletion;

  /// No description provided for @bestDay.
  ///
  /// In en, this message translates to:
  /// **'Best Day'**
  String get bestDay;

  /// No description provided for @activeDays.
  ///
  /// In en, this message translates to:
  /// **'Active Days'**
  String get activeDays;

  /// No description provided for @avgSleep.
  ///
  /// In en, this message translates to:
  /// **'Avg Sleep'**
  String get avgSleep;

  /// No description provided for @noCompletionData.
  ///
  /// In en, this message translates to:
  /// **'No completion data'**
  String get noCompletionData;

  /// No description provided for @noSleepData.
  ///
  /// In en, this message translates to:
  /// **'No sleep data'**
  String get noSleepData;

  /// No description provided for @saveSleepLog.
  ///
  /// In en, this message translates to:
  /// **'Save Sleep Log'**
  String get saveSleepLog;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navHabits.
  ///
  /// In en, this message translates to:
  /// **'Habits'**
  String get navHabits;

  /// No description provided for @navJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get navJournal;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;
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
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
