import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'subcategories_screen.dart';
import '../../widgets/app_drawer.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _client = Supabase.instance.client;
  List<dynamic> _categories = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final response = await _client.from('categories').select();
    setState(() => _categories = response);
  }

  void _onCategoryTap(Map category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubcategoriesScreen(
          categoryId: category['id'],
          categoryName: category['name'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _categories.where((c) {
      final name = c['name'].toString().toLowerCase();
      return name.contains(_search.toLowerCase());
    }).toList();

    return Scaffold(
      endDrawer: const AppDrawer(),

      // 🔹 ÜST BAR
      appBar: AppBar(
        title: const Text(
          'Ana Kategoriler',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
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

      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Hastalık veya kategori ara',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 🧩 GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final category = filtered[index];
                return _CategoryCard(
                  category: category,
                  onTap: () => _onCategoryTap(category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// her bir kart için widget
class _CategoryCard extends StatelessWidget {
  final Map category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  String? _getCategoryImage(String? imageName) {
    if (imageName == null || imageName.isEmpty) return null;

    return Supabase.instance.client.storage
        .from('category-images')
        .getPublicUrl(imageName);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getCategoryImage(category['image_url']);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // 🔹 ARKA PLAN RESİM
            Positioned.fill(
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 200),
                      placeholder: (context, url) =>
                          Container(color: Colors.grey.shade300),
                      errorWidget: (context, url, error) =>
                          Container(color: Colors.grey.shade300),
                    )
                  : Container(color: Colors.grey.shade300),
            ),

            // 🔹 KARARTMA
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.55),
                    ],
                  ),
                ),
              ),
            ),

            // 🔹 SADECE HASTALIK ADI
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  category['name'] ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
