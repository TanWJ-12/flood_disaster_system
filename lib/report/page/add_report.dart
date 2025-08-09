import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyp/report/models/report.dart';
import 'package:fyp/report/provider/user_report.dart';
import 'package:fyp/report/widgets/image_input.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:fyp/report/widgets/location_input.dart';

class AddReportPage extends ConsumerStatefulWidget {
  const AddReportPage({super.key});

  @override
  ConsumerState<AddReportPage> createState() {
    return _AddReportPageState();
  }
}

class _AddReportPageState extends ConsumerState<AddReportPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedImage;
  ReportLocation? _selectedLocation;
  String _selectedSeverity = 'Low'; // Default severity
  final String _status = 'Submitted'; // Default status
  String _createdTime = '';
  final user = FirebaseAuth.instance.currentUser;
  var _isUploading = false;//1

  Future<String?> _getUserName() async {
    
    if (user == null) return null;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    return userDoc.data()?['username'];
  }

  void _saveReport() async {

    setState((){
      _isUploading = true;
    });//2
    
    final enteredText = _titleController.text;
    final enteredDescription = _descriptionController.text;

    if (enteredText.isEmpty ||
        enteredDescription.isEmpty ||
        _selectedImage == null ||
        _selectedLocation == null) {
      return;
    }

    final userName = await _getUserName();
    if (userName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch user information.')),
      );
      return;
    }

    final createdTime = DateTime.now(); // Automatically capture created time
    _createdTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(createdTime);

    

    ref.read(userReportProvider.notifier).addReport(
          enteredText,
          enteredDescription,
          _selectedImage!,
          _selectedLocation!,
          _selectedSeverity,
          _status,
          userName,
          _createdTime,
        );

    final storageRef = FirebaseStorage.instance
            .ref()
            .child('report_image')
            .child('${user!.uid}_$createdTime.jpg');

    await storageRef.putFile(_selectedImage!);
    final imageUrl = await storageRef.getDownloadURL();

    // Save additional fields to Firestore or your backend
    await FirebaseFirestore.instance.collection('reports').add({
      'title': enteredText,
      'description': enteredDescription,
      'severity': _selectedSeverity,
      'status': _status,
      'created_time': _createdTime,
      'user_name': userName,
      'image_url': imageUrl,
      'location': {
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'address': _selectedLocation!.address,
      },
    });

    Navigator.of(context).pop();

    
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add new Report'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Title'),
              controller: _titleController,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3, // Multiline input
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedSeverity,
              items: const [
                DropdownMenuItem(value: 'Low', child: Text('Low')),
                DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                DropdownMenuItem(value: 'High', child: Text('High')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSeverity = value!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ImageInput(
              onPickImage: (image) {
                _selectedImage = image;
              },
            ),
            const SizedBox(height: 12),
            LocationInput(
              onSelectLocation: (location) {
                _selectedLocation = location;
              },
            ),
            const SizedBox(height: 16),
            if (_isUploading)
              const CircularProgressIndicator(),
            if (!_isUploading)
              ElevatedButton.icon(
                onPressed: _saveReport,
                icon: const Icon(Icons.add),
                label: const Text('Add Report'),
              ),
          ],
        ),
      ),
    );
  }
}