import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatScreenBubble extends StatelessWidget {
  final String messageId;
  final String senderName;
  final String message;
  final bool isMine;
  final DateTime time;
  final bool isEdited;
  final int likesCount;
  final bool isLiked;

  final List<Map<String, dynamic>> reactions;

  const ChatScreenBubble({
    super.key,
    required this.messageId,
    required this.senderName,
    required this.message,
    required this.isMine,
    required this.time,
    this.isEdited = false,
    this.likesCount = 0,
    this.reactions = const [],
    this.isLiked = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat('HH:mm').format(time);
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // ❌ PP KAPALI (ileride açılacak)
          // if (!isMine) _avatar(),
          // if (!isMine) const SizedBox(width: 8),

          Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // 👤 İSİM + SAAT (ÜSTTE)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isMine ? "Ben" : senderName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeString,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // 💬 MESAJ BALONU
              Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color:
                      isMine ? const Color(0xFF3C5885) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft:
                        isMine ? const Radius.circular(18) : Radius.zero,
                    bottomRight:
                        isMine ? Radius.zero : const Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: isMine ? Colors.white : Colors.black87,
                  ),
                ),
              ),

              // ✏️ DÜZENLENDİ
              if (isEdited)
                const Padding(
                  padding: EdgeInsets.only(top: 4, left: 6),
                  child: Text(
                    "Düzenlendi",
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),

              // ❤️ LIKE (GÖRÜLDÜ KALDIRILDI)
              if (likesCount > 0)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 14,
                        color: isLiked ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        likesCount.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // ❌ PP KAPALI
          // if (isMine) const SizedBox(width: 8),
          // if (isMine) _avatar(),
        ],
      ),
    );
  }

  /*
  // 👤 AVATAR (ŞİMDİLİK KAPALI)
  Widget _avatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade300,
      ),
      child: const Icon(Icons.person, size: 18, color: Colors.white),
    );
  }
  */
}
