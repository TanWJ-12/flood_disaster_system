import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class BroadcastCreatePage extends StatefulWidget {
  const BroadcastCreatePage({super.key});

  @override
  State<BroadcastCreatePage> createState() => _BroadcastCreatePageState();
}

class _BroadcastCreatePageState extends State<BroadcastCreatePage> {
  final _messageController = TextEditingController();
  String _urgency = 'Update';
  File? _imageFile;
  String? _imageUrl;
  double? _lat;
  double? _lng;
  bool _isLoading = false;
  String? _error;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _pickLocation() async {
    // For demo: just ask for lat/lng manually
    final latController = TextEditingController();
    final lngController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: lngController,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _lat = double.tryParse(latController.text);
                _lng = double.tryParse(lngController.text);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Set Location'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendBroadcast() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      setState(() => _error = 'Message cannot be empty.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    String? imageUrl;
    if (_imageFile != null) {
      final ref = FirebaseStorage.instance
          .ref()
          .child('broadcast_images')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_imageFile!);
      imageUrl = await ref.getDownloadURL();
    }

    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('broadcasts').add({
      'message': message,
      'urgency': _urgency,
      'timestamp': Timestamp.now(),
      'sender': user?.uid,
      'image_url': imageUrl ?? '',
      'location': (_lat != null && _lng != null)
          ? {'lat': _lat, 'lng': _lng}
          : null,
    });

    setState(() => _isLoading = false);
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast sent!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Broadcast')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _urgency,
              decoration: const InputDecoration(labelText: 'Urgency'),
              items: const [
                DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                DropdownMenuItem(value: 'Warning', child: Text('Warning')),
                DropdownMenuItem(value: 'Update', child: Text('Update')),
              ],
              onChanged: (val) => setState(() => _urgency = val ?? 'Update'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _imageFile != null
                    ? CircleAvatar(
                        backgroundImage: FileImage(_imageFile!),
                        radius: 28,
                      )
                    : const CircleAvatar(
                        radius: 28,
                        child: Icon(Icons.image),
                      ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('Attach Image (optional)'),
                  onPressed: _pickImage,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, color: _lat != null && _lng != null ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                Text(_lat != null && _lng != null
                    ? 'Location: $_lat, $_lng'
                    : 'No location attached'),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_location),
                  label: const Text('Attach Location (optional)'),
                  onPressed: _pickLocation,
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _sendBroadcast,
                    child: const Text('Send Broadcast'),
                  ),
          ],
        ),
      ),
    );
  }
}