import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../forum/forum_screen.dart';
import '../../widgets/app_drawer.dart';

class SubcategoriesScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const SubcategoriesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<SubcategoriesScreen> createState() => _SubcategoriesScreenState();
}

class _SubcategoriesScreenState extends State<SubcategoriesScreen> {
  final _client = Supabase.instance.client;
  List<dynamic> _subcategories = [];

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
  }

  Future<void> _loadSubcategories() async {
    final response = await _client
        .from('subcategories')
        .select()
        .eq('category_id', widget.categoryId);
    setState(() {
      _subcategories = response;
    });
  }

  void _onSubcategoryTap(Map subcategory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ForumScreen(
          subcategoryId: subcategory['id'],
          subcategoryName: subcategory['name'],
        ),
      ),
    );
    debugPrint("Alt kategori seçildi: ${subcategory['name']}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  elevation: 0,
  centerTitle: true,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back_ios_new),
    onPressed: () => Navigator.pop(context),
  ),
  title: Text(
    widget.categoryName,
    style: const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 18,
    ),
  ),
  actions: [
    Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => Scaffold.of(context).openEndDrawer(),
      ),
    ),
  ],
),

      endDrawer: const AppDrawer(), // Sağ üstten açılan drawer
     body: Column(
  children: [
    // 🔍 Arama
    Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Alt kategori ara...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ),

    // 📋 Liste
    Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _subcategories.length,
        itemBuilder: (context, index) {
          final subcategory = _subcategories[index];
          return _SubcategoryItem(
            title: subcategory['name'],
            onTap: () => _onSubcategoryTap(subcategory),
          );
        },
      ),
    ),
  ],
),

    );
  }
}

class _SubcategoryItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _SubcategoryItem({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // 🟦 Sol ikon (şimdilik sabit)
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    color: Color(0xFF2B4C7E),
                  ),
                ),

                const SizedBox(width: 12),

                // 📄 Başlık
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // ➡️ Ok
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

