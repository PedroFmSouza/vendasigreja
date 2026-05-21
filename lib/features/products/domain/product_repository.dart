import 'product.dart';

/// Interface de dados de produtos. Hoje implementada por SQLite; futuramente
/// pode ser trocada por uma implementação de API sem alterar a UI.
abstract class ProductRepository {
  Future<List<Product>> getAll({bool onlyActive = false});
  Future<Product> create(Product product);
  Future<void> update(Product product);
  Future<void> delete(int id);
  Future<List<String>> categories();
}
