import 'package:flutter/material.dart';
import 'database/sqlite_helper.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ProductPage(),
  ));
}

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final db = SQLiteHelper.instance;

  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final qtyCtrl = TextEditingController();
  final searchCtrl = TextEditingController();

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> categories = [];
  int? selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
    searchCtrl.addListener(() => _search());
  }

  Future<void> _loadData() async {
    categories = await db.getCategories();
    selectedCategory = categories.first['id'];
    await _search();
  }

  Future<void> _search() async {
    final keyword = searchCtrl.text;
    products = await db.getProducts(keyword: keyword);
    setState(() {});
  }

  Future<void> _addProduct() async {
    if (selectedCategory == null) return;
    await db.insertProduct({
      'name': nameCtrl.text,
      'price': double.tryParse(priceCtrl.text) ?? 0,
      'quantity': int.tryParse(qtyCtrl.text) ?? 0,
      'categoryId': selectedCategory!,
    });
    nameCtrl.clear();
    priceCtrl.clear();
    qtyCtrl.clear();
    await _search();
  }

  Future<void> _deleteProduct(int id) async {
    await db.deleteProduct(id);
    await _search();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sản phẩm - SQLite'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // ô tìm kiếm
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Tìm kiếm sản phẩm...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // form thêm sản phẩm
          ExpansionTile(
            title: const Text('➕ Thêm sản phẩm mới'),
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
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
                    DropdownButton<int>(
                      value: selectedCategory,
                      items: categories
                          .map((e) => DropdownMenuItem<int>(
                                value: e['id'],
                                child: Text(e['name']),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => selectedCategory = v),
                    ),
                    ElevatedButton(
                      onPressed: _addProduct,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal),
                      child: const Text('Thêm sản phẩm'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // danh sách
          Expanded(
            child: ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, i) {
                final item = products[i];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: ListTile(
                    title: Text(item['name']),
                    subtitle: Text(
                        'Giá: ${item['price']} | SL: ${item['quantity']}\nLoại: ${item['categoryName']}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteProduct(item['id']),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
