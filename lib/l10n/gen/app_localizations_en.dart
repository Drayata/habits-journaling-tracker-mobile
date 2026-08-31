// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get profile => 'Profile';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String viewingMonthWarning(String month) {
    return 'Viewing $month. Daily check-ins still follow the selected date from Habits.';
  }

  @override
  String get todaysProgress => 'Today\'s Progress';

  @override
  String progressWithDate(String date) {
    return 'Progress · $date';
  }

  @override
  String get useToday => 'Use today';

  @override
  String unableToLoadProgress(String error) {
    return 'Unable to load progress: $error';
  }

  @override
  String habitsCompletedRatio(int completed, int total) {
    return '$completed of $total habits';
  }

  @override
  String sleepWithDate(String date) {
    return 'Sleep · $date';
  }

  @override
  String get loading => 'Loading…';

  @override
  String get unableToLoadSleepLog => 'Unable to load sleep log';

  @override
  String get tapToLogSleep => 'Tap to log sleep';

  @override
  String hoursLogged(String hours) {
    return '$hours hours logged';
  }

  @override
  String activityHeatmapMonth(String month) {
    return 'Activity Heatmap · $month';
  }

  @override
  String unableToLoadHeatmap(String error) {
    return 'Unable to load heatmap: $error';
  }

  @override
  String get profileAndSettings => 'Profile & Settings';

  @override
  String get myProfile => 'My Profile';

  @override
  String get settings => 'Settings';

  @override
  String get dataManagement => 'Data Management';

  @override
  String get exportDataToCsv => 'Export Data to CSV';

  @override
  String get habitsLogsAndJournals => 'Habits, logs, and journals';

  @override
  String get backupDataJson => 'Backup Data (JSON)';

  @override
  String get fullStructuredBackup => 'Full structured backup';

  @override
  String get restoreData => 'Restore Data';

  @override
  String get restoreFromJsonBackup => 'Restore from JSON backup';

  @override
  String get dailyReminder => 'Daily Reminder';

  @override
  String atTime(String time) {
    return 'At $time';
  }

  @override
  String get off => 'Off';

  @override
  String get csvExportCompleted => 'CSV Export completed';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get backupCompleted => 'Backup completed';

  @override
  String backupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String get dataRestoredSuccessfully => 'Data restored successfully';

  @override
  String get restoreCanceled => 'Restore canceled';

  @override
  String restoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get language => 'Language';

  @override
  String get newHabit => 'New Habit';

  @override
  String get habitName => 'Habit name';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String failedToSaveHabit(String error) {
    return 'Failed to save habit: $error';
  }

  @override
  String get habits => 'Habits';

  @override
  String habitsDoneRatio(int completed, int total) {
    return '$completed/$total done';
  }

  @override
  String get today => 'Today';

  @override
  String unableToLoadHabits(String error) {
    return 'Unable to load habits: $error';
  }

  @override
  String unableToLoadCompletionData(String error) {
    return 'Unable to load completion data: $error';
  }

  @override
  String get noActiveHabits => 'No active habits for this date';

  @override
  String get habitsCreatedAfterExcluded =>
      'Habits created after the selected date are intentionally excluded.';

  @override
  String get deleteHabit => 'Delete Habit';

  @override
  String deleteHabitConfirmation(String habitName) {
    return 'Delete \"$habitName\" and all its logs?';
  }

  @override
  String get delete => 'Delete';

  @override
  String get markIncomplete => 'Mark incomplete';

  @override
  String get markComplete => 'Mark complete';

  @override
  String get dailyProgress => 'Daily Progress';

  @override
  String get sleepTracker => 'Sleep Tracker';

  @override
  String get logSleep => 'Log Sleep';

  @override
  String get timeInBed => 'Time in bed';

  @override
  String xHours(String hours) {
    return '$hours hours';
  }

  @override
  String get notesOptional => 'Notes (optional)';

  @override
  String get howDidYouSleep => 'How did you sleep?';

  @override
  String get save => 'Save';

  @override
  String unableToSaveSleepLog(String error) {
    return 'Unable to save sleep log: $error';
  }

  @override
  String get journal => 'Journal';

  @override
  String get todaysEntry => 'Today\'s Entry';

  @override
  String get journalHint => 'Write about your day, reflect on your progress...';

  @override
  String get cannotAddJournalFuture =>
      'Cannot add journal entries for future dates.';

  @override
  String get journalAutoSaveHint =>
      '💡 Your journal auto-saves as you type. Take your time.';

  @override
  String get howAreYouFeeling => 'How are you feeling?';

  @override
  String errorMessage(String error) {
    return 'Error: $error';
  }

  @override
  String failedToSave(String error) {
    return 'Failed to save: $error';
  }

  @override
  String get moodAwful => 'Awful';

  @override
  String get moodBad => 'Bad';

  @override
  String get moodOkay => 'Okay';

  @override
  String get moodGood => 'Good';

  @override
  String get moodGreat => 'Great';

  @override
  String get statistics => 'Statistics';

  @override
  String get completionRate => 'Completion Rate';

  @override
  String ratePercentage(String rate) {
    return '$rate%';
  }

  @override
  String get activeHabits => 'Active Habits';

  @override
  String get averageSleep => 'Average Sleep';

  @override
  String get habitConsistency => 'Habit Consistency';

  @override
  String get moodCorrelation => 'Mood Correlation';

  @override
  String get noMoodData => 'No mood data available for this month.';

  @override
  String habitInsightsFor(String month) {
    return 'Habit insights for $month';
  }

  @override
  String unableToLoadStatistics(String error) {
    return 'Unable to load statistics: $error';
  }

  @override
  String get dailyCompletionRate => 'Daily Completion Rate';

  @override
  String get sleepDurationHours => 'Sleep Duration (Hours)';

  @override
  String get moodVsHabitCompletion => 'Mood vs. Habit Completion';

  @override
  String get avgCompletionGroupedByMood =>
      'Average completion rate grouped by daily mood';

  @override
  String get avgCompletion => 'Avg Completion';

  @override
  String get bestDay => 'Best Day';

  @override
  String get activeDays => 'Active Days';

  @override
  String get avgSleep => 'Avg Sleep';

  @override
  String get noCompletionData => 'No completion data';

  @override
  String get noSleepData => 'No sleep data';

  @override
  String get saveSleepLog => 'Save Sleep Log';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navHabits => 'Habits';

  @override
  String get navJournal => 'Journal';

  @override
  String get navStats => 'Stats';
}
