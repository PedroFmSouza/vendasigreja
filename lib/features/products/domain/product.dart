/// Produto vendável. `price` em centavos.
class Product {
  final int? id;
  final String name;
  final int price;
  final String category;
  final bool active;
  final DateTime createdAt;

  const Product({
    this.id,
    required this.name,
    required this.price,
    this.category = 'Geral',
    this.active = true,
    required this.createdAt,
  });

  Product copyWith({
    int? id,
    String? name,
    int? price,
    String? category,
    bool? active,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'price': price,
        'category': category,
        'active': active ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory Product.fromMap(Map<String, Object?> map) => Product(
        id: map['id'] as int?,
        name: map['name'] as String,
        price: map['price'] as int,
        category: map['category'] as String? ?? 'Geral',
        active: (map['active'] as int? ?? 1) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
