extension LogicalDay on DateTime {
  /// Returns the "logical day" for habit/sleep tracking purposes.
  /// If the time is before 04:00 AM, it mathematically belongs to the previous calendar day.
  DateTime logicalDay() {
    // If the hour is less than 4 (00:00 - 03:59), subtract a day
    final normalized = hour < 4 ? subtract(const Duration(days: 1)) : this;
    // Strip the time to return only the date component
    return DateTime(normalized.year, normalized.month, normalized.day);
  }
}
