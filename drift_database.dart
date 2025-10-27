import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'drift_database.g.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get price => real()();
  IntColumn get quantity => integer()();
  IntColumn get categoryId => integer()();
}
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}
@DriftDatabase(tables: [Products, Categories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  @override
  int get schemaVersion => 1;

  // Insert
  Future<int> insertProduct(ProductsCompanion entry) =>
      into(products).insert(entry);
  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);
  // Delete
  Future<int> deleteProduct(int id) =>
      (delete(products)..where((tbl) => tbl.id.equals(id))).go();
  // Watch all products
  Stream<List<ProductWithCategory>> watchProducts() {
    final query = select(products).join([
      innerJoin(categories, categories.id.equalsExp(products.categoryId)),
    ]);

    return query.watch().map((rows) => rows.map((row) {
          return ProductWithCategory(
            product: row.readTable(products),
            category: row.readTable(categories),
          );
        }).toList());
  }

  // Watch products with keyword
  Stream<List<ProductWithCategory>> searchProducts(String keyword) {
    final query = select(products).join([
      innerJoin(categories, categories.id.equalsExp(products.categoryId)),
    ])
      ..where(products.name.like('%$keyword%'));

    return query.watch().map((rows) => rows.map((row) {
          return ProductWithCategory(
            product: row.readTable(products),
            category: row.readTable(categories),
          );
        }).toList());
  }
}

class ProductWithCategory {
  final Product product;
  final Category category;

  ProductWithCategory({
    required this.product,
    required this.category,
  });
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'products_db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
