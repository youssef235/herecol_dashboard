class Payment {
  final String id;
  final double amount;
  final DateTime date;

  Payment({
    required this.id,
    required this.amount,
    required this.date,
  });

  factory Payment.fromFirestore(Map<String, dynamic> data) {
    return Payment(
      id: data['id'],
      amount: data['amount'],
      date: DateTime.parse(data['date']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }
}