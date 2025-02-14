import 'package:collection/collection.dart';

import '../models/transaction.dart';

/// Compares two dates by year, month, and day
bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Returns the next occurrence date based on the periodicity
DateTime getNextOccurrence(DateTime current, Periodicity periodicity) {
  switch (periodicity) {
    case Periodicity.day:
      return current.add(const Duration(days: 1));
    case Periodicity.week:
      return current.add(const Duration(days: 7));
    case Periodicity.month:
      return DateTime(current.year, current.month + 1, current.day);
    case Periodicity.year:
      return DateTime(current.year + 1, current.month, current.day);
    default:
      return current;
  }
}

/// Generates occurrences for a transaction within the given date range
List<TransactionOccurrence> generateOccurrences(
    Transaction t, DateTime startRange, DateTime endRange) {
  List<TransactionOccurrence> occ = [];
  DateTime occurrence = t.startDate;
  while (occurrence.isBefore(startRange)) {
    occurrence = getNextOccurrence(occurrence, t.periodicity);
    if (t.endDate != null && occurrence.isAfter(t.endDate!)) break;
  }
  while (!occurrence.isAfter(endRange)) {
    if (t.endDate != null && occurrence.isAfter(t.endDate!)) break;
    occ.add(TransactionOccurrence(transaction: t, date: occurrence));
    if (t.periodicity == Periodicity.none) break;
    occurrence = getNextOccurrence(occurrence, t.periodicity);
  }
  return occ;
}

/// Returns all occurrences within the specified range, considering overrides
List<TransactionOccurrence> getOccurrencesInRange(
  List<Transaction> transactions,
  DateTime startRange,
  DateTime endRange,
  List<OccurrenceOverride> overrides,
) {
  List<TransactionOccurrence> occurrences = [];
  for (Transaction t in transactions) {
    if (t.periodicity == Periodicity.none) {
      if (!t.startDate.isBefore(startRange) && !t.startDate.isAfter(endRange)) {
        OccurrenceOverride? ov = overrides.firstWhereOrNull((ov) =>
            ov.transactionId == t.id && isSameDate(ov.date, t.startDate));
        if (ov != null) {
          if (ov.newTransaction == null) continue;
          occurrences.add(TransactionOccurrence(
              transaction: ov.newTransaction!, date: ov.date));
        } else {
          occurrences
              .add(TransactionOccurrence(transaction: t, date: t.startDate));
        }
      }
    } else {
      List<TransactionOccurrence> occ =
          generateOccurrences(t, startRange, endRange);
      for (var o in occ) {
        OccurrenceOverride? ov = overrides.firstWhereOrNull(
            (ov) => ov.transactionId == t.id && isSameDate(ov.date, o.date));
        if (ov != null) {
          if (ov.newTransaction == null) continue;
          occurrences.add(TransactionOccurrence(
              transaction: ov.newTransaction!, date: o.date));
        } else {
          occurrences.add(o);
        }
      }
    }
  }
  occurrences.sort((a, b) => a.date.compareTo(b.date));
  return occurrences;
}
