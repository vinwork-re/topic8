import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLiteHelper {
  static final SQLiteHelper instance = SQLiteHelper._init();
  static Database? _database;

  SQLiteHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('products_db_sqlite.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        price REAL,
        quantity INTEGER,
        categoryId INTEGER,
        FOREIGN KEY (categoryId) REFERENCES categories(id)
      )
    ''');

    // Thêm vài loại mặc định
    await db.insert('categories', {'name': 'Điện thoại'});
    await db.insert('categories', {'name': 'Laptop'});
    await db.insert('categories', {'name': 'Phụ kiện'});
  }

  // Insert
  Future<int> insertProduct(Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert('products', data);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await instance.database;
    return await db.query('categories');
  }

  Future<List<Map<String, dynamic>>> getProducts({String keyword = ''}) async {
    final db = await instance.database;
    if (keyword.isEmpty) {
      return await db.rawQuery('''
        SELECT p.*, c.name AS categoryName
        FROM products p
        JOIN categories c ON p.categoryId = c.id
        ORDER BY p.id DESC
      ''');
    } else {
      return await db.rawQuery('''
        SELECT p.*, c.name AS categoryName
        FROM products p
        JOIN categories c ON p.categoryId = c.id
        WHERE p.name LIKE ?
        ORDER BY p.id DESC
      ''', ['%$keyword%']);
    }
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}
