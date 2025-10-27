import 'package:flutter/material.dart';
import 'database/drift_database.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProductPage(),
    );
  }
}

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final db = AppDatabase();

  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final searchCtrl = TextEditingController();

  int? selectedCategory;
  String keyword = '';

  @override
  void initState() {
    super.initState();
    _setupCategories();
    searchCtrl.addListener(() {
      setState(() => keyword = searchCtrl.text);
    });
  }

  Future<void> _setupCategories() async {
    final cats = await db.select(db.categories).get();
    if (cats.isEmpty) {
      await db.insertCategory(CategoriesCompanion.insert(name: 'Điện thoại'));
      await db.insertCategory(CategoriesCompanion.insert(name: 'Laptop'));
      await db.insertCategory(CategoriesCompanion.insert(name: 'Phụ kiện'));
    }
    final updated = await db.select(db.categories).get();
    setState(() {
      selectedCategory = updated.first.id;
    });
  }

  Future<void> _addProduct() async {
    if (selectedCategory == null) return;
    await db.insertProduct(
      ProductsCompanion.insert(
        name: nameCtrl.text,
        price: double.tryParse(priceCtrl.text) ?? 0,
        quantity: int.tryParse(qtyCtrl.text) ?? 0,
        categoryId: selectedCategory!,
      ),
    );
    nameCtrl.clear();
    priceCtrl.clear();
    qtyCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final stream = keyword.isEmpty
        ? db.watchProducts()
        : db.searchProducts(keyword);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm - Drift ORM'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // Ô tìm kiếm
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Tìm kiếm sản phẩm...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Form thêm sản phẩm
          ExpansionTile(
            title: const Text('➕ Thêm sản phẩm mới'),
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Tên sản phẩm'),
                    ),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Giá'),
                    ),
                    TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Số lượng'),
                    ),
                    FutureBuilder(
                      future: db.select(db.categories).get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final cats = snapshot.data!;
                        return DropdownButton<int>(
                          value: selectedCategory,
                          items: cats
                              .map((e) => DropdownMenuItem<int>(
                                    value: e.id,
                                    child: Text(e.name),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() {
                            selectedCategory = v;
                          }),
                        );
                      },
                    ),
                    ElevatedButton(
                      onPressed: _addProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      child: const Text('Thêm sản phẩm'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(),

          // Danh sách sản phẩm
          Expanded(
            child: StreamBuilder<List<ProductWithCategory>>(
              stream: stream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data!;
                if (list.isEmpty) {
                  return const Center(child: Text('Không có sản phẩm.'));
                }
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final item = list[i];
                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      child: ListTile(
                        title: Text(item.product.name),
                        subtitle: Text(
                            'Giá: ${item.product.price} | SL: ${item.product.quantity}\nLoại: ${item.category.name}'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => db.deleteProduct(item.product.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
