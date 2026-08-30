import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';

class SettingsState {
  final bool isReminderEnabled;
  final TimeOfDay reminderTime;

  SettingsState({
    required this.isReminderEnabled,
    required this.reminderTime,
  });

  SettingsState copyWith({
    bool? isReminderEnabled,
    TimeOfDay? reminderTime,
  }) {
    return SettingsState(
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  static const _keyEnabled = 'reminder_enabled';
  static const _keyHour = 'reminder_hour';
  static const _keyMinute = 'reminder_minute';

  @override
  Future<SettingsState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_keyEnabled) ?? false;
    final hour = prefs.getInt(_keyHour) ?? 20; // Default 8 PM
    final minute = prefs.getInt(_keyMinute) ?? 0;

    return SettingsState(
      isReminderEnabled: isEnabled,
      reminderTime: TimeOfDay(hour: hour, minute: minute),
    );
  }

  Future<void> toggleReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, value);

    state = AsyncData(state.value!.copyWith(isReminderEnabled: value));

    if (value) {
      final hasPermission = await NotificationService().requestPermission();
      if (hasPermission) {
        await NotificationService().scheduleDailyReminder(
            state.value!.reminderTime.hour, state.value!.reminderTime.minute);
      } else {
        // If permission denied, revert switch
        await prefs.setBool(_keyEnabled, false);
        state = AsyncData(state.value!.copyWith(isReminderEnabled: false));
      }
    } else {
      await NotificationService().cancelAllNotifications();
    }
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHour, time.hour);
    await prefs.setInt(_keyMinute, time.minute);

    state = AsyncData(state.value!.copyWith(reminderTime: time));

    if (state.value!.isReminderEnabled) {
      await NotificationService().scheduleDailyReminder(time.hour, time.minute);
    }
  }
}
