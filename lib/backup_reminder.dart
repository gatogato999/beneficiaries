/// The reminder starts when changes have been waiting this many days without a backup.
const kBackupAfterDays = 14;

/// "Later" hides the reminder for this many days.
const kSnoozeDays = 7;

/// Whether to show the "save a backup" banner.
/// [dirtySinceMs] is when the first change after the last backup was made (null = nothing to back up).
bool shouldRemindBackup({
  required int recordCount,
  int? dirtySinceMs,
  int? snoozeUntilMs,
  required DateTime now,
}) {
  if (recordCount == 0 || dirtySinceMs == null) return false;
  final nowMs = now.millisecondsSinceEpoch;
  if (snoozeUntilMs != null && nowMs < snoozeUntilMs) return false;
  return nowMs - dirtySinceMs >= kBackupAfterDays * Duration.millisecondsPerDay;
}

/// Whole calendar days from [from] to [to] (never negative, so a wrong clock cannot give nonsense).
int daysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  final d = b.difference(a).inDays;
  return d < 0 ? 0 : d;
}

/// Arabic text for the "last backup" line in the Other tab.
String describeLastExport(DateTime? last, DateTime now) {
  if (last == null) return 'لم تُحفظ بعد';
  final days = daysBetween(last, now);
  final when = switch (days) {
    0 => 'اليوم',
    1 => 'أمس',
    2 => 'قبل يومين',
    _ when days <= 10 => 'قبل $days أيام',
    _ => 'قبل $days يوماً',
  };
  final m = last.month.toString().padLeft(2, '0');
  final d = last.day.toString().padLeft(2, '0');
  return '$when (${last.year}-$m-$d)';
}
