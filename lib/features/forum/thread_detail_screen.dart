import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/forum_post_widget.dart';

class ThreadDetailScreen extends StatefulWidget {
  final String threadId;
  final String threadTitle;
  final String subcategoryName;

  const ThreadDetailScreen({
    super.key,
    required this.threadId,
    required this.threadTitle,
    required this.subcategoryName,
  });

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  final _client = Supabase.instance.client;
  final _replyController = TextEditingController();

  Map<String, dynamic>? _thread;
  List<dynamic> _posts = [];
  Map<String, int> _likesCounts = {};
  Set<String> _likedPostIds = {};
  int _threadLikeCount = 0;
  bool _isThreadLiked = false;

  bool _isLoading = true;
  bool _isReplying = false;
  String _replySort = 'newest';
  String? _replyingToName;
  String? _replyingToPreview;

  @override
  void initState() {
    super.initState();
    _loadThreadAndPosts();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadThreadAndPosts() async {
    try {
      final threadData = await _client
          .from('forum_threads')
          .select()
          .eq('id', widget.threadId)
          .single();

      await _client.from('forum_threads').update({
        'view_count': (threadData['view_count'] ?? 0) + 1,
      }).eq('id', widget.threadId);

      final postsData = await _client
          .from('forum_posts')
          .select()
          .eq('thread_id', widget.threadId)
          .order('created_at', ascending: true);

      await _loadLikes();
      await _loadThreadLikes();

      setState(() {
        _thread = threadData;
        _posts = postsData;
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
      final userId = _client.auth.currentUser!.id;
      final res = await _client
          .from('forum_thread_likes')
          .select('thread_id, user_id')
          .eq('thread_id', widget.threadId);

      var count = 0;
      var liked = false;

      for (final row in res) {
        count++;
        if (row['user_id'] == userId) liked = true;
      }

      setState(() {
        _threadLikeCount = count;
        _isThreadLiked = liked;
      });
    } catch (e) {
      debugPrint('Thread likes yukleme hatasi: $e');
    }
  }

  Future<void> _loadLikes() async {
    try {
      final userId = _client.auth.currentUser!.id;

      final res = await _client
          .from('forum_post_likes')
          .select('post_id, user_id');

      final Map<String, int> counts = {};
      final Set<String> liked = {};

      for (final row in res) {
        final postId = row['post_id'] as String;
        counts[postId] = (counts[postId] ?? 0) + 1;

        if (row['user_id'] == userId) {
          liked.add(postId);
        }
      }

      setState(() {
        _likesCounts = counts;
        _likedPostIds = liked;
      });
    } catch (e) {
      debugPrint('Likes yükleme hatası: $e');
    }
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

  Future<void> _sendReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isReplying = true);

    try {
      final userId = _client.auth.currentUser!.id;
      final replyPreview = _replyingToPreview == null
          ? null
          : _replyingToPreview!
                .replaceAll('\n', ' ')
                .replaceAll(']', ')')
                .trim();
      final contentToSave = _replyingToName == null
          ? content
          : '[reply_to: $_replyingToName|$replyPreview]\n$content';

      await _client.from('forum_posts').insert({
        'thread_id': widget.threadId,
        'user_id': userId,
        'content': contentToSave,
      });

      await _client.from('forum_threads').update({
        'reply_count': (_thread?['reply_count'] ?? 0) + 1,
        'last_reply_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.threadId);

      _replyController.clear();
      _replyingToName = null;
      _replyingToPreview = null;
      _loadThreadAndPosts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      setState(() => _isReplying = false);
    }
  }

  Future<void> _toggleLike(String postId) async {
    final userId = _client.auth.currentUser!.id;
    final isLiked = _likedPostIds.contains(postId);

    setState(() {
      if (isLiked) {
        _likedPostIds.remove(postId);
        _likesCounts[postId] = (_likesCounts[postId] ?? 1) - 1;
      } else {
        _likedPostIds.add(postId);
        _likesCounts[postId] = (_likesCounts[postId] ?? 0) + 1;
      }
    });

    try {
      if (isLiked) {
        await _client
            .from('forum_post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId);
      } else {
        await _client.from('forum_post_likes').insert({
          'post_id': postId,
          'user_id': userId,
        });
      }
    } catch (e) {
      _loadLikes();
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
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

  Future<void> _toggleThreadLike() async {
    final userId = _client.auth.currentUser!.id;
    final wasLiked = _isThreadLiked;

    setState(() {
      _isThreadLiked = !wasLiked;
      _threadLikeCount = wasLiked
          ? (_threadLikeCount > 0 ? _threadLikeCount - 1 : 0)
          : _threadLikeCount + 1;
    });

    try {
      if (wasLiked) {
        await _client
            .from('forum_thread_likes')
            .delete()
            .eq('thread_id', widget.threadId)
            .eq('user_id', userId);
      } else {
        await _client.from('forum_thread_likes').insert({
          'thread_id': widget.threadId,
          'user_id': userId,
        });
      }
    } catch (e) {
      _loadThreadLikes();
    }
  }

  void _startReplyTo(String userName, String content) {
    setState(() {
      _replyingToName = userName;
      _replyingToPreview = _cleanReplyPreview(content);
    });
  }

  String _cleanReplyPreview(String content) {
    var text = content.trim();
    if (text.startsWith('[reply_to:')) {
      final endIndex = text.indexOf(']');
      if (endIndex != -1) {
        text = text.substring(endIndex + 1).trim();
      }
    }

    text = text.replaceAll('\n', ' ').trim();
    if (text.length > 80) return '${text.substring(0, 80)}...';
    return text;
  }

  List<dynamic> get _sortedPosts {
    final sorted = List<dynamic>.from(_posts);

    if (_replySort == 'most_liked') {
      sorted.sort((a, b) {
        final bLikes = _likesCounts[b['id']] ?? 0;
        final aLikes = _likesCounts[a['id']] ?? 0;
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

  String get _replySortLabel {
    if (_replySort == 'most_liked') return 'En Cok Begenilen';
    return 'En Yeni';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
      backgroundColor: const Color(0xFFE8E1F0),
        appBar: AppBar(
          backgroundColor: const Color(0xFFE8E1F0),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: const Text('Yükleniyor...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final threadUserId = _thread?['user_id'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFE8E1F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8E1F0),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Discussion',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const AppDrawer(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // ═══════════════════════════════════════
                // 📌 ANA KONU KARTI
                // ═══════════════════════════════════════
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1).withOpacity(0.7),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar + İsim + Tarih + Kategori etiketi
                      FutureBuilder<String>(
                        future: _getUserDisplayName(threadUserId),
                        builder: (context, snapshot) {
                          final userName = snapshot.data ?? "A";
                          final initial = userName.isNotEmpty
                              ? userName[0].toUpperCase()
                              : "A";

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    _getAvatarColor(userName).withOpacity(0.15),
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    color: _getAvatarColor(userName),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    Text(
                                      _formatDate(
                                          _thread?['created_at'] ?? ''),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Kategori etiketi
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFFDBA74),
                                  ),
                                ),
                                child: Text(
                                  widget.subcategoryName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFEA580C),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Başlık
                      Text(
                        widget.threadTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Açıklama
                      if ((_thread?['description'] ?? '').isNotEmpty)
                        Text(
                          _thread!['description'],
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Color(0xFF475569),
                          ),
                        ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          GestureDetector(
                            onTap: _toggleThreadLike,
                            child: Row(
                              children: [
                                Icon(
                                  _isThreadLiked
                                      ? Icons.thumb_up_alt
                                      : Icons.thumb_up_alt_outlined,
                                  size: 18,
                                  color: _isThreadLiked
                                      ? const Color(0xFF2C5282)
                                      : Colors.grey[500],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _threadLikeCount > 0
                                      ? '$_threadLikeCount Begeni'
                                      : 'Begen',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _isThreadLiked
                                        ? const Color(0xFF2C5282)
                                        : Colors.grey[600],
                                    fontWeight: _isThreadLiked
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Icon(
                            Icons.share_outlined,
                            size: 18,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Paylas',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ═══════════════════════════════════════
                // 💬 CEVAPLAR BAŞLIĞI
                // ═══════════════════════════════════════
                if (_posts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cevaplar (${_posts.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF334155),
                          ),
                        ),
                        PopupMenuButton<String>(
                          initialValue: _replySort,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            setState(() => _replySort = value);
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
                                  _replySortLabel,
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

                if (_posts.isNotEmpty) const SizedBox(height: 12),

                // ═══════════════════════════════════════
                // 💬 CEVAP LİSTESİ
                // ═══════════════════════════════════════
                ..._sortedPosts.map((post) {
                  final likeCount = _likesCounts[post['id']] ?? 0;
                  final isLiked = _likedPostIds.contains(post['id']);
                  final isPostAuthor = post['user_id'] == threadUserId;

                  return Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: FutureBuilder<String>(
                          future: _getUserDisplayName(post['user_id']),
                          builder: (context, snapshot) {
                            final userName = snapshot.data ?? "Kullanıcı";
                            return ForumPostWidget(
                              postId: post['id'],
                              userName: userName,
                              content: post['content'],
                              timestamp: _formatDate(post['created_at']),
                              isEdited: post['is_edited'] ?? false,
                              likeCount: likeCount,
                              isLiked: isLiked,
                              onLikeTap: () => _toggleLike(post['id']),
                              onReplyTap: () =>
                                  _startReplyTo(userName, post['content']),
                              isAuthor: isPostAuthor,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),

          // ═══════════════════════════════════════
          // ✍️ CEVAP YAZMA ALANI
          // ═══════════════════════════════════════
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyingToName != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.reply,
                            size: 18,
                            color: Color(0xFF2C5282),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$_replyingToName kisisine yanit veriyorsun',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF2C5282),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (_replyingToPreview != null) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    _replyingToPreview!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() {
                              _replyingToName = null;
                              _replyingToPreview = null;
                            }),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _replyController,
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: "Bir cevap yaz...",
                              hintStyle: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _isReplying ? null : _sendReply,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isReplying
                                ? Colors.grey.shade400
                                : const Color(0xFF2C5282),
                            boxShadow: [
                              if (!_isReplying)
                                BoxShadow(
                                  color: const Color(
                                    0xFF2C5282,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                            ],
                          ),
                          child: _isReplying
                              ? const Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
