import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp/chat/widget/message_bubble.dart';

class ChatPage extends StatefulWidget {
  final String? chatId;
  final String chatType; // 'private' or 'group'
  final String? targetUserId; // For private chat
  final String? groupName; // For group chat
  final String? groupImage; // For group chat
  final Map<String, String>? userNames; // For group chat: userId -> username
  final Map<String, String>? userImages; // For group chat: userId -> image url

  const ChatPage({
    super.key,
    required this.chatId,
    required this.chatType,
    this.targetUserId,
    this.groupName,
    this.groupImage,
    this.userNames,
    this.userImages,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _targetUserData; // For private chat

  @override
  void initState() {
    super.initState();
    if (widget.chatType == 'private' && widget.targetUserId != null) {
      _fetchTargetUserData();
    }
  }

  Future<void> _fetchTargetUserData() async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('user_id', isEqualTo: widget.targetUserId)
        .get();
    if (query.docs.isNotEmpty) {
      setState(() {
        _targetUserData = query.docs.first.data();
      });
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc();

    await messageRef.set({
      'text': text,
      'createdAt': Timestamp.now(),
      'senderId': _currentUser!.uid,
    });

    // Update chat meta for chat list
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
      'lastMessage': text,
      'lastMessageSender': _currentUser.uid,
      'lastMessageTime': Timestamp.now(),
    }, SetOptions(merge: true));

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    Widget appBarTitle;

    if (widget.chatType == 'group') {
      appBarTitle = Row(
        children: [
          if (widget.groupImage != null && widget.groupImage!.isNotEmpty)
            CircleAvatar(
              backgroundImage: NetworkImage(widget.groupImage!),
            ),
          if (widget.groupImage != null && widget.groupImage!.isNotEmpty)
            const SizedBox(width: 8),
          Text(widget.groupName ?? 'Group Chat'),
        ],
      );
    } else {
      // Private chat
      if (_targetUserData == null) {
        appBarTitle = const Text('Chat');
      } else {
        appBarTitle = Row(
          children: [
            if (_targetUserData!['image_url'] != null &&
                (_targetUserData!['image_url'] as String).isNotEmpty)
              CircleAvatar(
                backgroundImage: NetworkImage(_targetUserData!['image_url']),
              ),
            if (_targetUserData!['image_url'] != null &&
                (_targetUserData!['image_url'] as String).isNotEmpty)
              const SizedBox(width: 8),
            Text(_targetUserData!['username'] ?? 'User'),
          ],
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: appBarTitle,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                String? lastSenderId;
                return ListView.builder(
                  reverse: false,
                  itemCount: docs.length,
                  itemBuilder: (ctx, idx) {
                    final msg = docs[idx].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == _currentUser!.uid;
                    final showAvatarAndName = lastSenderId != msg['senderId'];
                    lastSenderId = msg['senderId'];

                    String? senderName;
                    String? senderImage;
                    if (widget.chatType == 'group') {
                      senderName = widget.userNames?[msg['senderId']];
                      senderImage = widget.userImages?[msg['senderId']];
                    } else if (_targetUserData != null) {
                      if (isMe) {
                        senderName = 'You';
                        senderImage = null;
                      } else {
                        senderName = _targetUserData!['username'];
                        senderImage = _targetUserData!['image_url'];
                      }
                    }

                    return MessageBubble(
                      message: msg['text'] ?? '',
                      isMe: isMe,
                      senderName: showAvatarAndName ? senderName : null,
                      senderImage: showAvatarAndName ? senderImage : null,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Send a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}