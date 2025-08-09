import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp/chat/page/chat_page.dart';

class UserSearchPage extends StatefulWidget {
  const UserSearchPage({super.key});

  @override
  State<UserSearchPage> createState() => _UserSearchPageState();
}

class _UserSearchPageState extends State<UserSearchPage> {
  final _searchController = TextEditingController();
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  String? _error;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _fetchMyUserId();
  }

  Future<void> _fetchMyUserId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
    setState(() {
      _myUserId = doc.data()?['user_id'];
    });
  }

  Future<void> _searchUser() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _userData = null;
      _error = null;
    });
    final searchId = _searchController.text.trim();
    if (searchId == _myUserId) {
      setState(() {
        _isLoading = false;
        _error = "You can't search yourself.";
      });
      return;
    }
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('user_id', isEqualTo: searchId)
        .get();
    if (query.docs.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'User not found';
      });
      return;
    }
    setState(() {
      _userData = query.docs.first.data();
      _isLoading = false;
    });
  }

  Future<void> _startPrivateChat() async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null || _userData == null) return;
  final otherUid = _userData!['user_id'];
  final myUid = _myUserId;

  // Check if chat already exists
  final chatQuery = await FirebaseFirestore.instance
      .collection('chats')
      .where('type', isEqualTo: 'private')
      .where('members', arrayContains: myUid)
      .get();

  String? chatId;
  for (var doc in chatQuery.docs) {
    final members = List<String>.from(doc['members'] ?? []);
    if (members.contains(otherUid)) {
      chatId = doc.id;
      break;
    }
  }

  // If not, create new chat with metadata
  if (chatId == null) {
    final chatDoc = await FirebaseFirestore.instance.collection('chats').add({
      'type': 'private',
      'members': [myUid, otherUid],
      'lastMessage': '',
      'lastMessageSender': '',
      'lastMessageTime': Timestamp.now(),
    });
    chatId = chatDoc.id;
  }

  // Navigate to chat page
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (ctx) => ChatPage(
        chatId: chatId!,
        chatType: 'private',
        targetUserId: otherUid,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Search User'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Enter User ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchUser,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading) const CircularProgressIndicator(),
            if (_error != null) Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
            if (_userData != null)
              Padding(
                padding: EdgeInsets.only(top: 24, bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(_userData!['image_url'] ?? ''),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _userData!['username'] ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text('User ID: ${_userData!['user_id'] ?? ''}'),
                    Text(_userData!['email'] ?? ''),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.chat),
                      label: const Text('Send Message'),
                      onPressed: _startPrivateChat,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}