import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp/chat/widget/message_bubble.dart';
import 'package:fyp/chat/page/manage_group_page.dart'; // Import your manage group page

class ChatPage extends StatefulWidget {
  final String? chatId;
  final String chatType; // 'private' or 'group'
  final String? targetUserId; // For private chat
  final String? groupName; // For group chat
  final String? groupImage; // For group chat
  // final Map<String, String>? userNames; // For group chat: userId -> username
  // final Map<String, String>? userImages; // For group chat: userId -> image url

  const ChatPage({
    super.key,
    required this.chatId,
    required this.chatType,
    this.targetUserId,
    this.groupName,
    this.groupImage,
    // this.userNames,
    // this.userImages,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController(); // Add this
  final _currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _targetUserData; // For private chat
  bool _isAdmin = false;

  Map<String, dynamic>? userDataMap; // For group chat
  bool _groupUserLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.chatType == 'private' && widget.targetUserId != null) {
      _fetchTargetUserData();
    }
    if (widget.chatType == 'group' && widget.chatId != null) {
      _checkAdmin();
      _fetchGroupUserData();
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

  Future<void> _fetchGroupUserData() async {
    if (widget.chatId == null) return;
    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
    final data = chatDoc.data();
    if (data != null && data['members'] != null) {
      List<dynamic> memberIds = List.from(data['members']);
      Map<String, dynamic> tempUserDataMap = {};
      for (var memberId in memberIds) {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('user_id', isEqualTo: memberId)
            .get();
        if (userQuery.docs.isNotEmpty) {
          final userData = userQuery.docs.first.data();
          final docId = userQuery.docs.first.id;
          tempUserDataMap[docId] = {
            'username': userData['username'],
            'image_url': userData['image_url'],
          };
          //log
          print('XXXFetched user data for docId $docId: ${tempUserDataMap[docId]}');
        }
      }
      setState(() {
        userDataMap = tempUserDataMap;
        _groupUserLoading = false;
      });
    } else {
      setState(() {
        _groupUserLoading = false;
      });
    }
  }

  Future<void> _checkAdmin() async {
    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
    final data = chatDoc.data();
    if (data != null && _currentUser != null) {
      final adminUserId = data['admin'];
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).get();
      final myUserId = userDoc['user_id'];
      setState(() {
        _isAdmin = myUserId == adminUserId;
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

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).set({
      'lastMessage': text,
      'lastMessageSender': _currentUser.uid,
      'lastMessageTime': Timestamp.now(),
    }, SetOptions(merge: true));

    _controller.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
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
          Text(truncateText(widget.groupName ?? 'Group Chat', 8)),
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
            Text(truncateText(_targetUserData!['username'] ?? 'User', 10)),
          ],
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: appBarTitle,
        actions: [
          if (widget.chatType == 'group' && _isAdmin)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Manage Group',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => ManageGroupPage(
                      groupId: widget.chatId!,
                      adminUserId: _currentUser!.uid,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: (widget.chatType == 'group' && _groupUserLoading)
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
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
                      String? nowSenderId;
                      String? nextSenderId;
                      // Scroll to bottom when messages are loaded
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            0.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      });
                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true, // Stack messages from bottom up
                        itemCount: docs.length,
                        itemBuilder: (ctx, idx) {
                          int now = docs.length - 1 - idx;
                          int next = docs.length - 2 - idx;
                          final msgNow = docs[now].data() as Map<String, dynamic>;
                          nowSenderId = msgNow['senderId'];
                          final isMe = nowSenderId == _currentUser!.uid;
                          bool showAvatarAndName = true;
                          if (now > 0) {
                            final msgNext = docs[next].data() as Map<String, dynamic>;
                            nextSenderId = msgNext['senderId'];
                            showAvatarAndName = nowSenderId != nextSenderId;
                          }

                          String? senderName;
                          String? senderImage;
                          if (widget.chatType == 'group'&& showAvatarAndName && userDataMap != null) {
                            //log
                            print('XXXFetching user data for $nowSenderId');
                              //log
                              print('XXXDisplaying sender info for $nowSenderId: ${userDataMap![nowSenderId]}');
                              senderName = userDataMap![nowSenderId]?['username'];
                              senderImage = userDataMap![nowSenderId]?['image_url'];
                            
                            //log
                            print('XXXname and image: $senderName, $senderImage');
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
                            message: msgNow['text'] ?? '',
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