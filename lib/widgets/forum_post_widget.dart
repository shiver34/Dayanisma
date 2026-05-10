import 'package:flutter/material.dart';

class ForumPostWidget extends StatelessWidget {
  final String postId;
  final String userName;
  final String content;
  final String timestamp;
  final bool isEdited;
  final int likeCount;
  final bool isLiked;
  final VoidCallback onLikeTap;
  final VoidCallback? onReplyTap;
  final bool isAuthor;

  const ForumPostWidget({
    super.key,
    required this.postId,
    required this.userName,
    required this.content,
    required this.timestamp,
    this.isEdited = false,
    this.likeCount = 0,
    this.isLiked = false,
    required this.onLikeTap,
    this.onReplyTap,
    this.isAuthor = false,
  });

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF22C55E),
      const Color(0xFFF97316),
      const Color(0xFFA855F7),
      const Color(0xFF14B8A6),
      const Color(0xFFEF4444),
    ];
    return colors[name.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : "A";
    String? replyToName;
    String? replyPreview;
    var displayContent = content;

    if (content.startsWith('[reply_to:')) {
      final endIndex = content.indexOf(']');
      if (endIndex != -1) {
        final replyData = content.substring(10, endIndex).trim();
        final parts = replyData.split('|');
        replyToName = parts.first.trim();
        if (parts.length > 1 && parts[1].trim().isNotEmpty) {
          replyPreview = parts.sublist(1).join('|').trim();
        }
        displayContent = content.substring(endIndex + 1).trimLeft();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        userName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    if (isAuthor) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C5282),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'YAZAR',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      timestamp,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (replyToName != null) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: const Border(
                        left: BorderSide(color: Color(0xFF2C5282), width: 3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$replyToName kisisine yanit',
                          style: const TextStyle(
                          fontSize: 12,
                            color: Color(0xFF2C5282),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (replyPreview != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            replyPreview!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                Text(
                  displayContent,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF334155),
                  ),
                ),
                if (isEdited)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Duzenlendi',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onLikeTap,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLiked
                                ? Icons.thumb_up_alt
                                : Icons.thumb_up_alt_outlined,
                            size: 16,
                            color: isLiked
                                ? const Color(0xFF2C5282)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            likeCount > 0 ? '$likeCount Begeni' : 'Begen',
                            style: TextStyle(
                              fontSize: 12,
                              color: isLiked
                                  ? const Color(0xFF2C5282)
                                  : const Color(0xFF94A3B8),
                              fontWeight:
                                  isLiked ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    GestureDetector(
                      onTap: onReplyTap,
                      child: Text(
                        'Yanitla',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
