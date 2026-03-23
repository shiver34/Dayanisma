import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/app_drawer.dart';

class GroupListScreen extends StatefulWidget {
  final String subcategoryId;
  final String subcategoryName;

  const GroupListScreen({
    super.key,
    required this.subcategoryId,
    required this.subcategoryName,
  });

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final _client = Supabase.instance.client;
  List<dynamic> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final response = await _client
        .from('groups')
        .select()
        .eq('subcategory_id', widget.subcategoryId);

    setState(() {
      _groups = response;
    });
  }

  void _onGroupTap(Map group) {
    // TODO: Sohbet ekranına geçiş yapılacak
    debugPrint("Grup seçildi: ${group['name']}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text('${widget.subcategoryName} Grupları'),
      ),
      drawer: const AppDrawer(), // ← Drawer menüsü
      body: ListView.builder(
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return ListTile(
            title: Text(group['name']),
            subtitle: Text(group['description'] ?? ''),
            onTap: () => _onGroupTap(group),
          );
        },
      ),
    );
  }
}
