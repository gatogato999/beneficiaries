import 'package:beneficiaries/backup_reminder.dart';
import 'package:flutter_test/flutter_test.dart';

const day = Duration.millisecondsPerDay;

void main() {
  final t0 = DateTime(2026, 3, 1, 10);
  final t0ms = t0.millisecondsSinceEpoch;

  group('shouldRemindBackup', () {
    test('nothing to back up: no records, or no unsaved change', () {
      expect(shouldRemindBackup(recordCount: 0, dirtySinceMs: t0ms, now: t0.add(const Duration(days: 60))), isFalse);
      expect(shouldRemindBackup(recordCount: 5, dirtySinceMs: null, now: t0.add(const Duration(days: 60))), isFalse);
    });

    test('not before 14 days, from 14 days on', () {
      expect(shouldRemindBackup(recordCount: 5, dirtySinceMs: t0ms, now: t0.add(const Duration(days: 13, hours: 23))), isFalse);
      expect(shouldRemindBackup(recordCount: 5, dirtySinceMs: t0ms, now: t0.add(const Duration(days: 14))), isTrue);
      expect(shouldRemindBackup(recordCount: 5, dirtySinceMs: t0ms, now: t0.add(const Duration(days: 90))), isTrue);
    });

    test('a snooze hides it until it ends', () {
      final now = t0.add(const Duration(days: 20));
      final until = now.add(const Duration(days: 7)).millisecondsSinceEpoch;
      expect(shouldRemindBackup(recordCount: 5, dirtySinceMs: t0ms, snoozeUntilMs: until, now: now), isFalse);
      expect(shouldRemindBackup(recordCount: 5, dirtySinceMs: t0ms, snoozeUntilMs: until, now: now.add(const Duration(days: 7))), isTrue);
    });

    test('a change dated in the future (wrong clock) never reminds', () {
      expect(shouldRemindBackup(recordCount: 5, dirtySinceMs: t0ms + 30 * day, now: t0), isFalse);
    });
  });

  group('daysBetween', () {
    test('counts calendar days across month ends and leap years', () {
      expect(daysBetween(DateTime(2026, 1, 31), DateTime(2026, 2, 1)), 1);
      expect(daysBetween(DateTime(2028, 2, 28), DateTime(2028, 3, 1)), 2);
      expect(daysBetween(DateTime(2026, 3, 1, 23, 59), DateTime(2026, 3, 2, 0, 1)), 1);
    });
    test('same day is 0 and a wrong clock is 0, never negative', () {
      expect(daysBetween(DateTime(2026, 3, 1, 8), DateTime(2026, 3, 1, 20)), 0);
      expect(daysBetween(DateTime(2026, 3, 5), DateTime(2026, 3, 1)), 0);
    });
  });

  group('describeLastExport', () {
    final now = DateTime(2026, 3, 20, 12);
    test('never', () => expect(describeLastExport(null, now), 'لم تُحفظ بعد'));
    test('today, yesterday, two days', () {
      expect(describeLastExport(DateTime(2026, 3, 20, 1), now), 'اليوم (2026-03-20)');
      expect(describeLastExport(DateTime(2026, 3, 19), now), 'أمس (2026-03-19)');
      expect(describeLastExport(DateTime(2026, 3, 18), now), 'قبل يومين (2026-03-18)');
    });
    test('3 to 10 days use the plural, 11 and more use the singular form', () {
      expect(describeLastExport(DateTime(2026, 3, 17), now), 'قبل 3 أيام (2026-03-17)');
      expect(describeLastExport(DateTime(2026, 3, 10), now), 'قبل 10 أيام (2026-03-10)');
      expect(describeLastExport(DateTime(2026, 3, 9), now), 'قبل 11 يوماً (2026-03-09)');
      expect(describeLastExport(DateTime(2026, 1, 5), now), 'قبل 74 يوماً (2026-01-05)');
    });
  });
}
