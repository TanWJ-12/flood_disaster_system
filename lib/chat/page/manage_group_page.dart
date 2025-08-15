import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ManageGroupPage extends StatefulWidget {
  final String groupId;
  final String adminUserId;
  const ManageGroupPage({super.key, required this.groupId, required this.adminUserId});

  @override
  State<ManageGroupPage> createState() => _ManageGroupPageState();
}

class _ManageGroupPageState extends State<ManageGroupPage> {
  final _nameController = TextEditingController();
  File? _groupImage;
  String? _imageUrl;
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchGroupData();
  }

  Future<void> _fetchGroupData() async {
    setState(() => _isLoading = true);
    final doc = await FirebaseFirestore.instance.collection('chats').doc(widget.groupId).get();
    final data = doc.data();
    if (data == null) return;

    _nameController.text = data['name'] ?? '';
    _imageUrl = data['image_url'] ?? '';

    // Fetch members
    final memberIds = List<String>.from(data['members'] ?? []);
    final memberSnaps = await FirebaseFirestore.instance
        .collection('users')
        .where('user_id', whereIn: memberIds)
        .get();
    _members = memberSnaps.docs.map((d) => d.data()).toList();

    // Fetch requests
    final requestIds = List<String>.from(data['requests'] ?? []);
    final requestSnaps = requestIds.isNotEmpty
        ? await FirebaseFirestore.instance
            .collection('users')
            .where('user_id', whereIn: requestIds)
            .get()
        : null;
    _requests = requestSnaps?.docs.map((d) => d.data()).toList() ?? [];

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (picked != null) {
      setState(() {
        _groupImage = File(picked.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    String? imageUrl = _imageUrl;
    if (_groupImage != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('group_images')
          .child('${widget.groupId}.jpg');
      await ref.putFile(_groupImage!);
      imageUrl = await ref.getDownloadURL();
    }
    await FirebaseFirestore.instance.collection('chats').doc(widget.groupId).update({
      'name': _nameController.text.trim(),
      'image_url': imageUrl ?? '',
    });
    setState(() {
      _isLoading = false;
      _imageUrl = imageUrl;
      _groupImage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group info updated')),
    );
  }

  Future<void> _removeMember(String userId) async {
    await FirebaseFirestore.instance.collection('chats').doc(widget.groupId).update({
      'members': FieldValue.arrayRemove([userId])
    });
    _fetchGroupData();
  }

  Future<void> _addMember(String userId) async {
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('user_id', isEqualTo: userId)
        .get();
    if (userSnap.docs.isEmpty) {
      setState(() => _error = 'User ID not found');
      return;
    }
    await FirebaseFirestore.instance.collection('chats').doc(widget.groupId).update({
      'members': FieldValue.arrayUnion([userId])
    });
    _fetchGroupData();
  }

  Future<void> _acceptRequest(String userId) async {
    await FirebaseFirestore.instance.collection('chats').doc(widget.groupId).update({
      'requests': FieldValue.arrayRemove([userId]),
      'members': FieldValue.arrayUnion([userId]),
    });
    _fetchGroupData();
  }

  Future<void> _rejectRequest(String userId) async {
    await FirebaseFirestore.instance.collection('chats').doc(widget.groupId).update({
      'requests': FieldValue.arrayRemove([userId]),
    });
    _fetchGroupData();
  }

  void _showAddMemberDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Member'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'User ID'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final userId = controller.text.trim();
              Navigator.pop(ctx);
              await _addMember(userId);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Group'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group name and image
                  Row(
                    children: [
                      _groupImage != null
                          ? CircleAvatar(
                              backgroundImage: FileImage(_groupImage!),
                              radius: 28,
                            )
                          : (_imageUrl != null && _imageUrl!.isNotEmpty)
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(_imageUrl!),
                                  radius: 28,
                                )
                              : const CircleAvatar(
                                  radius: 28,
                                  child: Icon(Icons.group),
                                ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Group Name'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: _pickImage,
                        tooltip: 'Change Group Image',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Members
                  Row(
                    children: [
                      const Text('Members:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Member'),
                        onPressed: _showAddMemberDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _members.map((user) {
                      final userId = user['user_id'];
                      final username = user['username'] ?? userId;
                      final imageUrl = user['image_url'];
                      return Chip(
                        avatar: imageUrl != null && imageUrl.isNotEmpty
                            ? CircleAvatar(backgroundImage: NetworkImage(imageUrl))
                            : const CircleAvatar(child: Icon(Icons.person)),
                        label: Text(username),
                        onDeleted: userId == widget.adminUserId
                            ? null
                            : () => _removeMember(userId),
                        deleteIcon: userId == widget.adminUserId ? null : const Icon(Icons.close),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Requests
                  if (_requests.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Join Requests:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._requests.map((user) {
                          final userId = user['user_id'];
                          final username = user['username'] ?? userId;
                          final imageUrl = user['image_url'];
                          return Card(
                            child: ListTile(
                              leading: imageUrl != null && imageUrl.isNotEmpty
                                  ? CircleAvatar(backgroundImage: NetworkImage(imageUrl))
                                  : const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(username),
                              subtitle: Text(userId),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () => _acceptRequest(userId),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () => _rejectRequest(userId),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
    );
  }
}