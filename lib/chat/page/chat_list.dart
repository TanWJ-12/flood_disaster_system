import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fyp/chat/page/broadcast_create_page.dart';
import 'package:fyp/chat/page/create_group_page.dart';
import 'package:fyp/chat/page/user_search_page.dart';
import 'package:fyp/chat/widget/display_broadcast_chat.dart';
import 'package:fyp/chat/widget/display_chat_history.dart';

class ChatListPage extends StatefulWidget {
  final BuildContext? mainScaffoldContext;
  final void Function(int)? onTabChange;
  const ChatListPage({super.key, this.mainScaffoldContext, this.onTabChange});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  String? _role;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    // log
    // print('XXX chat list initialized');
  }

  Future<void> _fetchUserRole() async {
    // log
    // print('XXX _fetchUserRole called');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    setState(() {
      // log
      // print('XXX _fetchUserRole setState called');
      _role = doc.data()?['role'];
      _userId = doc.data()?['user_id'];
    });
  }

  // void _showCreateGroupDialog() {
  //   String groupName = '';
  //   showDialog(
  //     context: context,
  //     builder:
  //         (ctx) => AlertDialog(
  //           title: const Text('Create Group Chat'),
  //           content: TextField(
  //             decoration: const InputDecoration(labelText: 'Group Name'),
  //             onChanged: (value) => groupName = value,
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.of(ctx).pop(),
  //               child: const Text('Cancel'),
  //             ),
  //             ElevatedButton(
  //               onPressed: () async {
  //                 if (groupName.trim().isEmpty) return;
  //                 final user = FirebaseAuth.instance.currentUser;
  //                 final groupDoc = await FirebaseFirestore.instance
  //                     .collection('chats')
  //                     .add({
  //                       'type': 'group',
  //                       'name': groupName,
  //                       'image_url': '', // You can add image upload later
  //                       'members': [user!.uid],
  //                       'createdBy': user.uid,
  //                       'createdAt': Timestamp.now(),
  //                     });
  //                 Navigator.of(ctx).pop();
  //                 // Optionally navigate to the new group chat
  //               },
  //               child: const Text('Create'),
  //             ),
  //           ],
  //         ),
  //   );
  // }

  // void _showBroadcastDialog() {
  //   String message = '';
  //   showDialog(
  //     context: context,
  //     builder:
  //         (ctx) => AlertDialog(
  //           title: const Text('Send Broadcast Message'),
  //           content: TextField(
  //             decoration: const InputDecoration(labelText: 'Message'),
  //             onChanged: (value) => message = value,
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.of(ctx).pop(),
  //               child: const Text('Cancel'),
  //             ),
  //             ElevatedButton(
  //               onPressed: () async {
  //                 if (message.trim().isEmpty) return;
  //                 final user = FirebaseAuth.instance.currentUser;
  //                 await FirebaseFirestore.instance
  //                     .collection('broadcasts')
  //                     .add({
  //                       'message': message,
  //                       'sender': user!.uid,
  //                       'createdAt': Timestamp.now(),
  //                     });
  //                 Navigator.of(ctx).pop();
  //               },
  //               child: const Text('Send'),
  //             ),
  //           ],
  //         ),
  //   );
  // }

  void _showJoinGroupDialog(BuildContext context) {
    final controller = TextEditingController();
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Join Group'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Group Chat ID'),
                ),
                if (errorMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(errorMsg!, style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final groupId = controller.text.trim();
                  if (groupId.isEmpty) {
                    setState(() => errorMsg = 'Please enter a group chat ID.');
                    return;
                  }
                  final groupDoc = await FirebaseFirestore.instance.collection('chats').doc(groupId).get();
                  if (!groupDoc.exists || groupDoc['type'] != 'group') {
                    setState(() => errorMsg = 'Group not found.');
                    return;
                  }
                  final user = FirebaseAuth.instance.currentUser;
                  final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
                  final userId = userDoc['user_id'];
                  if ((groupDoc['members'] as List).contains(userId)) {
                    setState(() => errorMsg = 'You are already a member of this group.');
                    return;
                  }
                  if ((groupDoc['requests'] as List).contains(userId)) {
                    setState(() => errorMsg = 'You have already requested to join.');
                    return;
                  }
                  await groupDoc.reference.update({
                    'requests': FieldValue.arrayUnion([userId])
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request sent to group admin.')),
                  );
                },
                child: const Text('Join'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // log
    // print('XXX scaffolding chats page');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          if (_role == 'admin')
            IconButton(
              icon: const Icon(Icons.campaign), // Use campaign icon for broadcast
              tooltip: 'Send Broadcast',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const BroadcastCreatePage()),
                );
              },
            ),
          if (_role == 'admin')
            IconButton(
              icon: const Icon(Icons.group_add),
              tooltip: 'Create Group Chat',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const CreateGroupPage()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'Join Group',
            onPressed: () => _showJoinGroupDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Search User by ID',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const UserSearchPage()),
              );
            },
          ),
        ],
      ),
      body:
      _role == null || _userId == null
          ? const Center(child: CircularProgressIndicator())
          :
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            DisplayBroadcastChat(),
            DisplayChatHistory(
              // report: userReport,
            ),
          ],
        ),
      ),
    );
  }
}
