import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/app_database.dart';
import '../data/sqlite_product_repository.dart';
import '../domain/product.dart';
import '../domain/product_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return SqliteProductRepository(ref.watch(appDatabaseProvider));
});

/// Todos os produtos (ativos e inativos) — usado na tela de gestão.
final productListProvider =
    AsyncNotifierProvider<ProductListNotifier, List<Product>>(
  ProductListNotifier.new,
);

class ProductListNotifier extends AsyncNotifier<List<Product>> {
  ProductRepository get _repo => ref.read(productRepositoryProvider);

  @override
  Future<List<Product>> build() => _repo.getAll();

  Future<void> _refresh() async {
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  Future<void> createProduct(Product product) async {
    await _repo.create(product);
    await _refresh();
  }

  Future<void> editProduct(Product product) async {
    await _repo.update(product);
    await _refresh();
  }

  Future<void> removeProduct(int id) async {
    await _repo.delete(id);
    await _refresh();
  }

  Future<void> toggleActive(Product product) async {
    await _repo.update(product.copyWith(active: !product.active));
    await _refresh();
  }
}

/// Apenas produtos ativos — usado na tela de venda.
final activeProductsProvider = FutureProvider<List<Product>>((ref) async {
  // Refaz quando a lista geral muda.
  ref.watch(productListProvider);
  return ref.watch(productRepositoryProvider).getAll(onlyActive: true);
});
