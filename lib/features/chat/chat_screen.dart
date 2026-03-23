// lib/features/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../widgets/app_drawer.dart';
import '../../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String subcategoryId;
  final String subcategoryName;

  const ChatScreen({
    super.key,
    required this.subcategoryId,
    required this.subcategoryName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _client = Supabase.instance.client;
  final _messageController = TextEditingController();
  final Map<String, int> _likesCount = {};
  final Set<String> _likedMessageIds = {};

  Timer? _typingTimer;
  bool _isTyping = false;
  String? _typingUser;

  List<dynamic> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadLikes();
    _subscribeToMessages();
    _subscribeToLikes();
    _listenTypingStatus();
  }

  void _subscribeToLikes() {
    final userId = _client.auth.currentUser!.id;

    _client.from('message_likes').stream(primaryKey: ['id']).listen((rows) {
      final Map<String, int> counts = {};
      final Set<String> liked = {};

      for (final row in rows) {
        final msgId = row['message_id'] as String;
        counts[msgId] = (counts[msgId] ?? 0) + 1;

        if (row['user_id'] == userId) {
          liked.add(msgId);
        }
      }

      setState(() {
        _likesCount
          ..clear()
          ..addAll(counts);

        _likedMessageIds
          ..clear()
          ..addAll(liked);
      });
    });
  }

  Future<void> _loadLikes() async {
    final userId = _client.auth.currentUser!.id;

    final res = await _client
        .from('message_likes')
        .select('message_id, user_id');

    final Map<String, int> counts = {};
    final Set<String> liked = {};

    for (final row in res) {
      final msgId = row['message_id'] as String;
      counts[msgId] = (counts[msgId] ?? 0) + 1;

      if (row['user_id'] == userId) {
        liked.add(msgId);
      }
    }

    setState(() {
      _likesCount
        ..clear()
        ..addAll(counts);

      _likedMessageIds
        ..clear()
        ..addAll(liked);
    });
  }

  // ------------------------------------------------------------
  //  YAZIYOR DURUMU
  // ------------------------------------------------------------
  void _listenTypingStatus() {
    _client
        .from('typing_status')
        .stream(primaryKey: ['subcategory_id', 'user_id'])
        .eq('subcategory_id', widget.subcategoryId)
        .listen((data) {
          final othersTyping = data.where(
            (e) =>
                e['user_id'] != _client.auth.currentUser!.id &&
                e['is_typing'] == true,
          );

          setState(() {
            _typingUser = othersTyping.isNotEmpty
                ? othersTyping.first['user_id']
                : null;
          });
        });
  }

  void _handleTyping(String text) async {
    final userId = _client.auth.currentUser!.id;

    if (!_isTyping) {
      _isTyping = true;
      await _client.from('typing_status').upsert({
        'subcategory_id': widget.subcategoryId,
        'user_id': userId,
        'is_typing': true,
      });
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () async {
      _isTyping = false;
      await _client.from('typing_status').upsert({
        'subcategory_id': widget.subcategoryId,
        'user_id': userId,
        'is_typing': false,
      });
    });
  }

  // ------------------------------------------------------------
  //  MESAJLARI YÜKLE
  // ------------------------------------------------------------
  Future<void> _loadMessages() async {
    final res = await _client
        .from('messages')
        .select('id, content, sender_id, created_at, is_edited')
        .eq('subcategory_id', widget.subcategoryId)
        .order('created_at');

    setState(() => _messages = res);
  }

  void _subscribeToMessages() {
    _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('subcategory_id', widget.subcategoryId)
        .order('created_at')
        .map(
          (rows) => rows
              .map(
                (row) => {
                  'id': row['id'],
                  'content': row['content'],
                  'sender_id': row['sender_id'],
                  'created_at': row['created_at'],
                  'is_edited': row['is_edited'],
                },
              )
              .toList(),
        )
        .listen((data) {
          setState(() => _messages = data);
        });
  }

  // ------------------------------------------------------------
  //  MESAJ GÖNDER
  // ------------------------------------------------------------
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await _client.from('messages').insert({
      'subcategory_id': widget.subcategoryId,
      'sender_id': _client.auth.currentUser!.id,
      'content': text,
    });

    _messageController.clear();
  }

  // ------------------------------------------------------------
  //  PROFİLDEN İSİM ÇEK
  // ------------------------------------------------------------
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

  // ------------------------------------------------------------
  //  MESAJ BASILI TUTMA MENÜSÜ
  // ------------------------------------------------------------
  void _onLongPressMessage(Map msg) {
    final isMine = msg['sender_id'] == _client.auth.currentUser!.id;

    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMine)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text("Düzenle"),
              onTap: () {
                Navigator.pop(context);
                _editMessage(msg);
              },
            ),
          ListTile(
            leading: const Icon(Icons.emoji_emotions),
            title: const Text("Tepki Ver"),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  //  MESAJ DÜZENLEME
  // ------------------------------------------------------------

  Future<void> _toggleLike(Map msg) async {
    final userId = _client.auth.currentUser!.id;
    final messageId = msg['id'] as String;

    final isLiked = _likedMessageIds.contains(messageId);

    // 🔥 OPTIMISTIC UI
    setState(() {
      if (isLiked) {
        _likedMessageIds.remove(messageId);
        _likesCount[messageId] = (_likesCount[messageId] ?? 1) - 1;
      } else {
        _likedMessageIds.add(messageId);
        _likesCount[messageId] = (_likesCount[messageId] ?? 0) + 1;
      }
    });

    try {
      if (isLiked) {
        await _client
            .from('message_likes')
            .delete()
            .eq('message_id', messageId)
            .eq('user_id', userId);
      } else {
        await _client.from('message_likes').insert({
          'message_id': messageId,
          'user_id': userId,
        });
      }
    } catch (e) {
      // ❌ Hata olursa geri al
      _loadLikes();
    }
  }

  void _editMessage(Map msg) {
    final controller = TextEditingController(text: msg['content']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Mesajı Düzenle"),
        content: TextField(controller: controller, maxLines: null),
        actions: [
          TextButton(
            child: const Text("İptal"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Kaydet"),
            onPressed: () async {
              await _client
                  .from('messages')
                  .update({
                    "content": controller.text.trim(),
                    "is_edited": true,
                  })
                  .eq('id', msg['id']);

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  //  ARAYÜZ
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.white.withOpacity(0.95),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF3C5885),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.subcategoryName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.circle, size: 8, color: Color(0xFF4CD9B0)),
                  SizedBox(width: 6),
                  Text(
                    "125 Çevrimiçi",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4CD9B0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF3C5885)),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ],
        ),
      ),

      endDrawer: const AppDrawer(),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final senderId = msg['sender_id'];
                final isMine = senderId == _client.auth.currentUser!.id;

                return FutureBuilder<String>(
                  future: _getUserDisplayName(senderId),
                  builder: (context, snapshot) {
                    final name = snapshot.data ?? "Kullanıcı";

                    final likeCount = _likesCount[msg['id']] ?? 0;
                    final isLiked = _likedMessageIds.contains(msg['id']);

                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onDoubleTap: () => _toggleLike(msg),
                      onLongPress: () => _onLongPressMessage(msg),
                      child: ChatScreenBubble(
                        messageId: msg['id'],
                        senderName: name,
                        message: msg['content'],
                        isMine: isMine,
                        time: DateTime.parse(msg['created_at']),
                        isEdited: msg['is_edited'] == true,
                        likesCount: likeCount,
                        isLiked: isLiked,
                        reactions:
                            [], // Emoji desteği kaldırıldıysa boş kalabilir
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (_typingUser != null)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                "Bir kullanıcı yazıyor...",
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),

          // --------------------------------------------------------
          //  MESAJ GÖNDERME ALANI
          // --------------------------------------------------------
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ➕ BUTONU
                  IconButton(
                    icon: const Icon(Icons.add_circle, size: 28),
                    color: Colors.grey,
                    onPressed: () {
                      // ileride dosya / foto
                    },
                  ),

                  // 💬 MESAJ INPUT
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              onChanged: _handleTyping,
                              minLines: 1,
                              maxLines: 5,
                              decoration: const InputDecoration(
                                hintText: "Bir mesaj yaz...",
                                border: InputBorder.none,
                              ),
                            ),
                          ),

                          // 🙂 EMOJI (şimdilik pasif)
                          IconButton(
                            icon: const Icon(
                              Icons.sentiment_satisfied_outlined,
                            ),
                            color: Colors.grey,
                            onPressed: () {
                              // emoji picker sonra
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ➤ GÖNDER BUTONU
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF3C5885),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
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
