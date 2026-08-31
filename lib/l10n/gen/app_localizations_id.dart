// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get profile => 'Profile';

  @override
  String get goodMorning => 'Selamat Pagi';

  @override
  String get goodAfternoon => 'Selamat Siang';

  @override
  String get goodEvening => 'Selamat Malam';

  @override
  String viewingMonthWarning(String month) {
    return 'Melihat $month. Progress harian tetap mengikuti tanggal yang dipilih di Habits.';
  }

  @override
  String get todaysProgress => 'Progress Hari Ini';

  @override
  String progressWithDate(String date) {
    return 'Progress · $date';
  }

  @override
  String get useToday => 'Kembali ke hari ini';

  @override
  String unableToLoadProgress(String error) {
    return 'Gagal memuat progress: $error';
  }

  @override
  String habitsCompletedRatio(int completed, int total) {
    return '$completed dari $total habit selesai';
  }

  @override
  String sleepWithDate(String date) {
    return 'Tidur · $date';
  }

  @override
  String get loading => 'Memuat…';

  @override
  String get unableToLoadSleepLog => 'Gagal memuat log tidur';

  @override
  String get tapToLogSleep => 'Tap untuk mencatat jam tidur';

  @override
  String hoursLogged(String hours) {
    return '$hours jam tercatat';
  }

  @override
  String activityHeatmapMonth(String month) {
    return 'Heatmap Aktivitas · $month';
  }

  @override
  String unableToLoadHeatmap(String error) {
    return 'Gagal memuat heatmap: $error';
  }

  @override
  String get profileAndSettings => 'Profile & Pengaturan';

  @override
  String get myProfile => 'My Profile';

  @override
  String get settings => 'Pengaturan';

  @override
  String get dataManagement => 'Manajemen Data';

  @override
  String get exportDataToCsv => 'Export Data ke CSV';

  @override
  String get habitsLogsAndJournals => 'Habit, log, dan journal';

  @override
  String get backupDataJson => 'Backup Data (JSON)';

  @override
  String get fullStructuredBackup => 'Backup semua struktur data';

  @override
  String get restoreData => 'Restore Data';

  @override
  String get restoreFromJsonBackup => 'Restore dari file backup JSON';

  @override
  String get dailyReminder => 'Daily Reminder';

  @override
  String atTime(String time) {
    return 'Pukul $time';
  }

  @override
  String get off => 'Mati';

  @override
  String get csvExportCompleted => 'Export CSV selesai';

  @override
  String exportFailed(String error) {
    return 'Export gagal: $error';
  }

  @override
  String get backupCompleted => 'Backup berhasil dibuat';

  @override
  String backupFailed(String error) {
    return 'Backup gagal: $error';
  }

  @override
  String get dataRestoredSuccessfully => 'Data berhasil di-restore';

  @override
  String get restoreCanceled => 'Restore dibatalkan';

  @override
  String restoreFailed(String error) {
    return 'Restore gagal: $error';
  }

  @override
  String get language => 'Bahasa';

  @override
  String get newHabit => 'Tambah Habit';

  @override
  String get habitName => 'Nama habit';

  @override
  String get descriptionOptional => 'Deskripsi (opsional)';

  @override
  String get cancel => 'Batal';

  @override
  String get add => 'Tambah';

  @override
  String failedToSaveHabit(String error) {
    return 'Gagal menyimpan habit: $error';
  }

  @override
  String get habits => 'Habit';

  @override
  String habitsDoneRatio(int completed, int total) {
    return '$completed/$total selesai';
  }

  @override
  String get today => 'Hari Ini';

  @override
  String unableToLoadHabits(String error) {
    return 'Gagal memuat habit: $error';
  }

  @override
  String unableToLoadCompletionData(String error) {
    return 'Gagal memuat data progress: $error';
  }

  @override
  String get noActiveHabits => 'Belum ada habit aktif untuk hari ini';

  @override
  String get habitsCreatedAfterExcluded =>
      'Habit yang dibuat setelah tanggal yang dipilih sengaja disembunyikan.';

  @override
  String get deleteHabit => 'Hapus Habit';

  @override
  String deleteHabitConfirmation(String habitName) {
    return 'Hapus \"$habitName\" beserta seluruh progress-nya?';
  }

  @override
  String get delete => 'Hapus';

  @override
  String get markIncomplete => 'Tandai belum selesai';

  @override
  String get markComplete => 'Tandai selesai';

  @override
  String get dailyProgress => 'Progress Harian';

  @override
  String get sleepTracker => 'Jam Tidur';

  @override
  String get logSleep => 'Catat Jam Tidur';

  @override
  String get timeInBed => 'Waktu tidur';

  @override
  String xHours(String hours) {
    return '$hours jam';
  }

  @override
  String get notesOptional => 'Catatan (opsional)';

  @override
  String get howDidYouSleep => 'Bagaimana tidurmu hari ini?';

  @override
  String get save => 'Simpan';

  @override
  String unableToSaveSleepLog(String error) {
    return 'Gagal menyimpan log tidur: $error';
  }

  @override
  String get journal => 'Jurnal';

  @override
  String get todaysEntry => 'Catatan Hari Ini';

  @override
  String get journalHint => 'Tulis tentang harimu, evaluasi progress-mu...';

  @override
  String get cannotAddJournalFuture =>
      'Tidak bisa menambah jurnal untuk hari yang belum terjadi.';

  @override
  String get journalAutoSaveHint =>
      '💡 Journal kamu auto-save setiap kali mengetik. Santai aja.';

  @override
  String get howAreYouFeeling => 'Gimana perasaanmu hari ini?';

  @override
  String errorMessage(String error) {
    return 'Error: $error';
  }

  @override
  String failedToSave(String error) {
    return 'Gagal menyimpan: $error';
  }

  @override
  String get moodAwful => 'Buruk';

  @override
  String get moodBad => 'Jelek';

  @override
  String get moodOkay => 'Biasa aja';

  @override
  String get moodGood => 'Oke';

  @override
  String get moodGreat => 'Senang';

  @override
  String get statistics => 'Statistik';

  @override
  String get completionRate => 'Completion Rate';

  @override
  String ratePercentage(String rate) {
    return '$rate%';
  }

  @override
  String get activeHabits => 'Habit Aktif';

  @override
  String get averageSleep => 'Rata-rata Tidur';

  @override
  String get habitConsistency => 'Konsistensi Habit';

  @override
  String get moodCorrelation => 'Korelasi Mood';

  @override
  String get noMoodData => 'Belum ada data mood bulan ini.';

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
  String get navHabits => 'Habit';

  @override
  String get navJournal => 'Jurnal';

  @override
  String get navStats => 'Statistik';
}
