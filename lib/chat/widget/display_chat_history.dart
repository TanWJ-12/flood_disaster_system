import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp/chat/page/broadcast_page.dart';
import 'package:fyp/chat/page/chat_page.dart';

class DisplayChatHistory extends StatefulWidget {
  const DisplayChatHistory({super.key});

  @override
  State<DisplayChatHistory> createState() => _DisplayChatHistoryState();
}

class _DisplayChatHistoryState extends State<DisplayChatHistory> {
  String? _userId;

  Future<void> _fetchMyUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    _userId = doc.data()?['user_id'];
  }

  // Helper function for time formatting
  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final time = timestamp.toDate();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} h';
    } else {
      return '${diff.inDays} d';
    }
  }

  String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  void initState() {
    super.initState();
    _fetchMyUserId().then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final chatDocs = snapshot.hasData ? snapshot.data!.docs : [];
        List<Widget> chatTiles = [];

        if (chatDocs.isEmpty) {
          return const Center(child: Text('No chats yet.'));
        }

        for (var idx = 0; idx < chatDocs.length; idx++) {
          final chat = chatDocs[idx].data() as Map<String, dynamic>;
          final type = chat['type'];
          final members = List<String>.from(chat['members'] ?? []);

          // Broadcast: show to all users
          if (type == 'broadcast') {
            chatTiles.add(
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.campaign)),
                title: const Text('Announcements'),
                subtitle: Text(truncateText(chat['lastMessage'] ?? '', 16)),
                trailing: Text(_formatTime(chat['lastMessageTime'])),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => BroadcastPage(),
                    ),
                  );
                },
              ),
            );
            continue;
          }

          // Group or private: show only if user is a member
          if (members.contains(_userId)) {
            final isGroup = type == 'group';
            String? targetUserId;
            if (!isGroup) {
              targetUserId = members.firstWhere((id) => id != _userId);
            }
            chatTiles.add(
              FutureBuilder<DocumentSnapshot>(
                future:
                    isGroup
                        ? null
                        : FirebaseFirestore.instance
                            .collection('users')
                            .where('user_id', isEqualTo: targetUserId)
                            .limit(1)
                            .get()
                            .then((snap) => snap.docs.first),
                builder: (ctx, userSnap) {
                  String title = '';
                  String? imageUrl;
                  if (isGroup) {
                    title = chat['name'] ?? 'Group Chat';
                    imageUrl = chat['image_url'];
                  } else if (userSnap.hasData && userSnap.data != null) {
                    final userData =
                        userSnap.data!.data() as Map<String, dynamic>;
                    title = userData['username'] ?? '';
                    imageUrl = userData['image_url'];
                  }
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          imageUrl != null && imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null,
                      child:
                          imageUrl == null || imageUrl.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                    ),
                    title: Text(truncateText(title, 16)),
                    subtitle: Text(truncateText(chat['lastMessage'] ?? '', 16)),
                    trailing: Text(_formatTime(chat['lastMessageTime'])),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (ctx) => ChatPage(
                                chatId: chatDocs[idx].id,
                                chatType: isGroup ? 'group' : 'private',
                                targetUserId: isGroup ? null : targetUserId,
                                groupName: isGroup ? chat['name'] : null,
                                groupImage: isGroup ? chat['image_url'] : null,
                              ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          }
        }
        return ListView(
          children: chatTiles,
        );
      },
    );
  }
}
