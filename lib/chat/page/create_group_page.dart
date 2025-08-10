import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _groupIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _userIdController = TextEditingController();
  final List<String> _members = [];
  File? _groupImage;
  String? _error;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (picked != null) {
      setState(() {
        _groupImage = File(picked.path);
      });
    }
  }

  Future<void> _addUser() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) return;
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('user_id', isEqualTo: userId)
        .get();
    if (userSnap.docs.isEmpty) {
      setState(() => _error = 'User ID not found');
      return;
    }
    if (_members.contains(userId)) {
      setState(() => _error = 'User already added');
      return;
    }
    setState(() {
      _members.add(userId);
      _userIdController.clear();
      _error = null;
    });
  }

  Future<bool> _isGroupIdUnique(String groupId) async {
    final doc = await FirebaseFirestore.instance.collection('chats').doc(groupId).get();
    return !doc.exists;
  }

  Future<void> _createGroup() async {
    final groupId = _groupIdController.text.trim();
    final groupName = _nameController.text.trim();
    if (groupId.isEmpty || groupName.isEmpty || _members.isEmpty) {
      setState(() => _error = 'Please fill all fields and add at least one member.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (!await _isGroupIdUnique(groupId)) {
      setState(() {
        _isLoading = false;
        _error = 'Group Chat ID already exists. Please choose another one.';
      });
      return;
    }

    String? imageUrl;
    if (_groupImage != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('group_images')
          .child('$groupId.jpg');
      await ref.putFile(_groupImage!);
      imageUrl = await ref.getDownloadURL();
    }

    final adminUid = FirebaseAuth.instance.currentUser?.uid;
    final adminUserDoc = await FirebaseFirestore.instance.collection('users').doc(adminUid).get();
    final adminUserId = adminUserDoc['user_id'];

    // Add admin to members if not already
    if (!_members.contains(adminUserId)) {
      _members.add(adminUserId);
    }

    await FirebaseFirestore.instance.collection('chats').doc(groupId).set({
      'type': 'group',
      'groupId': groupId,
      'name': groupName,
      'image_url': imageUrl ?? '',
      'members': _members,
      'admin': adminUserId,
      'requests': [],
      'createdAt': Timestamp.now(),
      'lastMessage': '',
      'lastMessageSender': '',
      'lastMessageTime': Timestamp.now(),
    });

    setState(() {
      _isLoading = false;
    });

    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group created successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _groupIdController,
              decoration: const InputDecoration(labelText: 'Group Chat ID (unique)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Group Name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _groupImage != null
                    ? CircleAvatar(
                        backgroundImage: FileImage(_groupImage!),
                        radius: 28,
                      )
                    : const CircleAvatar(
                        radius: 28,
                        child: Icon(Icons.group),
                      ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('Pick Group Image'),
                  onPressed: _pickImage,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userIdController,
                    decoration: const InputDecoration(labelText: 'User ID to Add'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addUser,
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: _members.map((id) => Chip(label: Text(id))).toList(),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _createGroup,
                    child: const Text('Create Group'),
                  ),
          ],
        ),
      ),
    );
  }
}