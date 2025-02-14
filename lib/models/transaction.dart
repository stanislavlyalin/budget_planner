/// Transaction types
enum TransactionType { income, expense }

/// Periodicity options
enum Periodicity { none, day, week, month, year }

/// Transaction model
class Transaction {
  final String id;
  final TransactionType type;
  final String name;
  final double amount;
  final DateTime startDate;
  final Periodicity periodicity;
  final DateTime? endDate;

  Transaction({
    required this.id,
    required this.type,
    required this.name,
    required this.amount,
    required this.startDate,
    required this.periodicity,
    this.endDate,
  });

  Transaction copyWith({
    String? id,
    TransactionType? type,
    String? name,
    double? amount,
    DateTime? startDate,
    Periodicity? periodicity,
    DateTime? endDate,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      periodicity: periodicity ?? this.periodicity,
      endDate: endDate ?? this.endDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'name': name,
        'amount': amount,
        'startDate': startDate.toIso8601String(),
        'periodicity': periodicity.index,
        'endDate': endDate?.toIso8601String(),
      };

  static Transaction fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        type: TransactionType.values[json['type']],
        name: json['name'],
        amount: json['amount'],
        startDate: DateTime.parse(json['startDate']),
        periodicity: Periodicity.values[json['periodicity']],
        endDate:
            json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      );
}

/// Single occurrence of a transaction
class TransactionOccurrence {
  final Transaction transaction;
  final DateTime date;
  TransactionOccurrence({
    required this.transaction,
    required this.date,
  });
}

/// Override model for a single occurrence
/// If newTransaction is null, the occurrence is considered deleted.
class OccurrenceOverride {
  final String transactionId;
  final DateTime date;
  final Transaction? newTransaction;
  OccurrenceOverride({
    required this.transactionId,
    required this.date,
    this.newTransaction,
  });

  Map<String, dynamic> toJson() => {
        'transactionId': transactionId,
        'date': date.toIso8601String(),
        'newTransaction': newTransaction?.toJson(),
      };

  static OccurrenceOverride fromJson(Map<String, dynamic> json) =>
      OccurrenceOverride(
        transactionId: json['transactionId'],
        date: DateTime.parse(json['date']),
        newTransaction: json['newTransaction'] != null
            ? Transaction.fromJson(json['newTransaction'])
            : null,
      );
}
