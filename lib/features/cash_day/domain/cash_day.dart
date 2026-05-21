/// Um dia de caixa. Agrupa as vendas. `date` é a chave yyyy-MM-dd.
class CashDay {
  final int? id;
  final String date;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String status;

  const CashDay({
    this.id,
    required this.date,
    required this.openedAt,
    this.closedAt,
    this.status = 'open',
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'date': date,
        'opened_at': openedAt.toIso8601String(),
        'closed_at': closedAt?.toIso8601String(),
        'status': status,
      };

  factory CashDay.fromMap(Map<String, Object?> map) => CashDay(
        id: map['id'] as int?,
        date: map['date'] as String,
        openedAt: DateTime.parse(map['opened_at'] as String),
        closedAt: map['closed_at'] == null
            ? null
            : DateTime.parse(map['closed_at'] as String),
        status: map['status'] as String? ?? 'open',
      );
}
