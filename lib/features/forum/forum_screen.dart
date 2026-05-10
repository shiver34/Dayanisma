import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/app_drawer.dart';
import 'create_thread_screen.dart';
import 'thread_detail_screen.dart';

class ForumScreen extends StatefulWidget {
  final String subcategoryId;
  final String subcategoryName;

  const ForumScreen({
    super.key,
    required this.subcategoryId,
    required this.subcategoryName,
  });

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final _client = Supabase.instance.client;
  List<dynamic> _threads = [];
  Map<String, int> _threadLikeCounts = {};
  String _threadSort = 'newest';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    try {
      setState(() => _isLoading = true);
      
      final response = await _client
          .from('forum_threads')
          .select()
          .eq('subcategory_id', widget.subcategoryId)
          .order('created_at', ascending: false);

      await _loadThreadLikes();

      setState(() {
        _threads = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  Future<void> _loadThreadLikes() async {
    try {
      final res = await _client.from('forum_thread_likes').select('thread_id');
      final counts = <String, int>{};

      for (final row in res) {
        final threadId = row['thread_id'] as String;
        counts[threadId] = (counts[threadId] ?? 0) + 1;
      }

      _threadLikeCounts = counts;
    } catch (e) {
      debugPrint('Thread likes yukleme hatasi: $e');
    }
  }

  List<dynamic> get _sortedThreads {
    final sorted = List<dynamic>.from(_threads);

    if (_threadSort == 'most_liked') {
      sorted.sort((a, b) {
        final bLikes = _threadLikeCounts[b['id']] ?? 0;
        final aLikes = _threadLikeCounts[a['id']] ?? 0;
        final likeCompare = bLikes.compareTo(aLikes);
        if (likeCompare != 0) return likeCompare;

        final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
        final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
      return sorted;
    }

    sorted.sort((a, b) {
      final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(0);
      final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(0);
      return bDate.compareTo(aDate);
    });
    return sorted;
  }

  String get _threadSortLabel {
    if (_threadSort == 'most_liked') return 'En Cok Begenilen';
    return 'En Yeni';
  }

  Future<String> _getUserDisplayName(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select('first_name, last_name')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return "Anonim";

      final first = data['first_name'] ?? "";
      final last = data['last_name'] ?? "";

      if (first.isNotEmpty && last.isNotEmpty) {
        return "$first ${last[0]}.";
      } else if (first.isNotEmpty) {
        return first;
      } else {
        return "Anonim";
      }
    } catch (e) {
      return "Anonim";
    }
  }

  void _onThreadTap(Map thread) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ThreadDetailScreen(
          threadId: thread['id'],
          threadTitle: thread['title'],
          subcategoryName: widget.subcategoryName,
        ),
      ),
    ).then((_) => _loadThreads());
  }

  void _onCreateThread() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateThreadScreen(
          subcategoryId: widget.subcategoryId,
          subcategoryName: widget.subcategoryName,
        ),
      ),
    ).then((_) => _loadThreads());
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}d önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}s önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}g önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8E1F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8E1F0),
        elevation: 0,
        surfaceTintColor: Colors.transparent, // Material 3 tint engelleme
        shadowColor: Colors.black.withOpacity(0.05),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.subcategoryName,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF1E293B)),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onCreateThread,
        backgroundColor: const Color(0xFF2C5282), // Ana mavi
        elevation: 4,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Yeni Sohbet',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _threads.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bu kategoride henüz konu yok',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'İlk konuyu sen başlat!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Konular (${_threads.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          PopupMenuButton<String>(
                            initialValue: _threadSort,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) {
                              setState(() => _threadSort = value);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'newest',
                                child: Text('En Yeni'),
                              ),
                              PopupMenuItem(
                                value: 'most_liked',
                                child: Text('En Cok Begenilen'),
                              ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.sort,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _threadSortLabel,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          top: 16,
                          left: 16,
                          right: 16,
                          bottom: 80,
                        ),
                        itemCount: _sortedThreads.length,
                        itemBuilder: (context, index) {
                          final thread = _sortedThreads[index];
                          return _ThreadListItem(
                            thread: thread,
                            likeCount: _threadLikeCounts[thread['id']] ?? 0,
                            onTap: () => _onThreadTap(thread),
                            getUserDisplayName: _getUserDisplayName,
                            formatDate: _formatDate,
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}

// 🔹 THREAD LİST İTEMİ WIDGET
class _ThreadListItem extends StatelessWidget {
  final Map thread;
  final int likeCount;
  final VoidCallback onTap;
  final Future<String> Function(String) getUserDisplayName;
  final String Function(String) formatDate;

  const _ThreadListItem({
    required this.thread,
    required this.likeCount,
    required this.onTap,
    required this.getUserDisplayName,
    required this.formatDate,
  });

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue.shade400,
      Colors.green.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.red.shade400,
    ];
    return colors[name.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FutureBuilder<String>(
          future: getUserDisplayName(thread['user_id']),
          builder: (context, snapshot) {
            final userName = snapshot.data ?? "A";
            final initial = userName.isNotEmpty ? userName[0].toUpperCase() : "A";
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👦 AVATAR
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _getAvatarColor(userName).withOpacity(0.15),
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: _getAvatarColor(userName),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                
                const SizedBox(width: 14),
                
                // 📝 İÇERİK
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Başlık
                      Text(
                        thread['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Kullanıcı ve Tarih
                      Text(
                        '$userName • ${formatDate(thread['created_at'])}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // İstatistikler (Görüntüleme & Cevap)
                      Row(
                        children: [
                          _StatBadge(
                            icon: Icons.chat_bubble_rounded,
                            count: thread['reply_count'] ?? 0,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 16),
                          _StatBadge(
                            icon: Icons.remove_red_eye_rounded,
                            count: thread['view_count'] ?? 0,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 16),
                          _StatBadge(
                            icon: Icons.thumb_up_alt_rounded,
                            count: likeCount,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final int count;
  final MaterialColor color;

  const _StatBadge({
    required this.icon,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color.shade400,
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 13,
            color: color.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
