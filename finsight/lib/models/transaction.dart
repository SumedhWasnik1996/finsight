  class FinTransaction {
    final String id, merchant, currency, category, date;
    final double amount;
    final bool   isSubscription;
    const FinTransaction({required this.id, required this.merchant,
      required this.amount, required this.currency,
      required this.category, required this.date,
      required this.isSubscription});
    factory FinTransaction.fromMap(Map<String,dynamic> m) =>
      FinTransaction(id:m['id'], merchant:m['merchant'],
        amount:(m['amount'] as num).toDouble(),
        currency:m['currency']??'GBP', category:m['category']??'other',
        date:m['date'], isSubscription:(m['is_subscription']??0)==1);
  }
