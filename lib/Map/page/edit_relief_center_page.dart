import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/report/widgets/location_input.dart';
import 'package:fyp/report/models/report.dart';

class EditReliefCenterPage extends StatefulWidget {
  final String reliefCenterId;
  const EditReliefCenterPage({Key? key, required this.reliefCenterId}) : super(key: key);

  @override
  State<EditReliefCenterPage> createState() => _EditReliefCenterPageState();
}

class _EditReliefCenterPageState extends State<EditReliefCenterPage> {
  bool _validatePhone(String phone) {
    final phoneRegExp = RegExp(r'^(\+?\d{1,4}[\s-]?)?(\d{10,12})$');
    return phoneRegExp.hasMatch(phone);
  }

  bool _validateEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }
  // Focus nodes for error clearing
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _capacityFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _resourceNameFocus = FocusNode();
  final FocusNode _resourceValueFocus = FocusNode();

  @override
  void dispose() {
    _nameFocus.dispose();
    _capacityFocus.dispose();
    _descriptionFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _resourceNameFocus.dispose();
    _resourceValueFocus.dispose();
    super.dispose();
  }

  bool _loading = true;
  bool _saving = false;
  String? _nameError, _capacityError, _descriptionError, _phoneError, _emailError, _resourceInputError, _error;

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _capacityController = TextEditingController();
  final _resourceNameController = TextEditingController();
  final _resourceValueController = TextEditingController();
  List<Map<String, dynamic>> _resources = [];
  int? _editingResourceIndex;
  // File? _imageFile;
  // String? _imageUrl;
  ReportLocation? _selectedLocation;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('relief_centers').doc(widget.reliefCenterId).get();
      final data = doc.data();
      if (data == null) {
        setState(() {
          _error = 'Relief center not found.';
          _loading = false;
        });
        return;
      }
      _nameController.text = data['name'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _emailController.text = data['email'] ?? '';
      _capacityController.text = data['capacity']?.toString() ?? '';
      _resources = (data['resources'] as List?)?.map((e) {
        final map = Map<String, dynamic>.from(e);
        map['value'] = map['value']?.toString() ?? '';
        if (map.containsKey('remain')) {
          map['remain'] = map['remain']?.toString() ?? map['value'];
        }
        return map;
      }).toList() ?? [];
      // _imageUrl = data['image_url'] ?? '';
      _selectedLocation = ReportLocation(
        latitude: data['location']['latitude'],
        longitude: data['location']['longitude'],
        address: data['location']['address'],
      );
      _lastUpdated = (data['last_updated'] as Timestamp?)?.toDate();
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load data: $e';
        _loading = false;
      });
    }
  }

  // Future<void> _pickImage() async {
  //   final picker = ImagePicker();
  //   final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
  //   if (picked != null) {
  //     setState(() {
  //       _imageFile = File(picked.path);
  //     });
  //   }
  // }

  void _onSelectLocation(ReportLocation location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _addResource() {
    final name = _resourceNameController.text.trim();
    final value = _resourceValueController.text.trim();
    if (name.isEmpty || value.isEmpty) {
      setState(() { _resourceInputError = 'Resource name and value are required.'; });
      return;
    }
    if (double.tryParse(value) == null) {
      setState(() { _resourceInputError = 'Resource value must be a number.'; });
      return;
    }
    if (_resources.any((r) => r['name'].toLowerCase() == name.toLowerCase())) {
      setState(() { _resourceInputError = 'Resource already exists.'; });
      return;
    }
    setState(() {
      _resources.add({'name': name, 'value': value});
      _resourceNameController.clear();
      _resourceValueController.clear();
      _resourceInputError = null;
      _error = null;
    });
  }

  void _editResource(int index) {
    setState(() {
      _editingResourceIndex = index;
      _resourceNameController.text = _resources[index]['name'];
      _resourceValueController.text = _resources[index]['value'];
    });
  }

  void _saveResourceEdit() {
    final name = _resourceNameController.text.trim();
    final value = _resourceValueController.text.trim();
    if (name.isEmpty || value.isEmpty) {
      setState(() { _resourceInputError = 'Resource name and value are required.'; });
      return;
    }
    if (double.tryParse(value) == null) {
      setState(() { _resourceInputError = 'Resource value must be a number.'; });
      return;
    }
    if (_resources.asMap().entries.any((e) => e.key != _editingResourceIndex && e.value['name'].toLowerCase() == name.toLowerCase())) {
      setState(() { _resourceInputError = 'Resource already exists.'; });
      return;
    }
    setState(() {
      _resources[_editingResourceIndex!] = {'name': name, 'value': value};
      _editingResourceIndex = null;
      _resourceNameController.clear();
      _resourceValueController.clear();
      _resourceInputError = null;
      _error = null;
    });
  }

  void _deleteResource(int index) {
    setState(() {
      _resources.removeAt(index);
      _editingResourceIndex = null;
    });
  }

  Future<void> _saveChanges() async {
    setState(() {
      _nameError = null;
      _capacityError = null;
      _descriptionError = null;
      _phoneError = null;
      _emailError = null;
      _resourceInputError = null;
      _error = null;
    });

    final name = _nameController.text.trim();
    final capacity = _capacityController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final description = _descriptionController.text.trim();

    bool hasError = false;
    if (name.isEmpty) {
      setState(() { _nameError = 'Name is required.'; });
      hasError = true;
    }
    if (_selectedLocation == null) {
      setState(() { _error = 'Location is required.'; });
      hasError = true;
    }
    if (capacity.isEmpty) {
      setState(() { _capacityError = 'Capacity is required.'; });
      hasError = true;
    } else if (int.tryParse(capacity) == null) {
      setState(() { _capacityError = 'Capacity must be a number.'; });
      hasError = true;
    }
    if (phone.isEmpty) {
      setState(() { _phoneError = 'Phone number is required.'; });
      hasError = true;
    } else if (!_validatePhone(phone)) {
      setState(() { _phoneError = 'Invalid phone format.'; });
      hasError = true;
    }
    if (email.isEmpty) {
      setState(() { _emailError = 'Email is required.'; });
      hasError = true;
    } else if (!_validateEmail(email)) {
      setState(() { _emailError = 'Invalid email format.'; });
      hasError = true;
    }
    if (hasError) {
      setState(() { _saving = false; });
      return;
    }

    setState(() { _saving = true; _error = null; });
    try {
      // String? imageUrl = _imageUrl;
      // if (_imageFile != null) {
      //   final ref = FirebaseStorage.instance
      //       .ref()
      //       .child('relief_center_images')
      //       .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      //   await ref.putFile(_imageFile!);
      //   imageUrl = await ref.getDownloadURL();
      // }
      final int newCapacity = int.tryParse(capacity) ?? 0;
      // Fetch previous remain_capacity to adjust if total capacity changes
      final docSnap = await FirebaseFirestore.instance.collection('relief_centers').doc(widget.reliefCenterId).get();
      int prevCapacity = docSnap.data()?['capacity'] ?? newCapacity;
      int prevRemain = docSnap.data()?['remain_capacity'] ?? newCapacity;
      int remainCapacity = prevRemain + (newCapacity - prevCapacity);
      if (remainCapacity > newCapacity) remainCapacity = newCapacity;
      // Update resources remain: if value changed, set remain = value; else keep remain
      List<Map<String, dynamic>> resourcesWithRemain = [];
      final prevResources = (docSnap.data()?['resources'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
      for (var r in _resources) {
        final valueStr = r['value'].toString();
        final value = double.tryParse(valueStr) ?? 0;
        final prev = prevResources.firstWhere(
          (pr) => pr['name'].toString().toLowerCase() == r['name'].toString().toLowerCase(),
          orElse: () => <String, dynamic>{},
        );
        // If value changed, set remain = value; else keep remain
        String remainStr = valueStr;
        if (prev.isNotEmpty) {
          final prevValue = double.tryParse(prev['value'].toString()) ?? value;
          if (prevValue == value) {
            remainStr = prev['remain']?.toString() ?? valueStr;
          }
        }
        resourcesWithRemain.add({
          'name': r['name'],
          'value': valueStr,
          'remain': remainStr,
        });
      }

  // If capacity changed, set remain_capacity = newCapacity
  // (handled below in update)
      await FirebaseFirestore.instance.collection('relief_centers').doc(widget.reliefCenterId).update({
        'name': name,
        'description': description,
        'phone': phone,
        'email': email,
        'capacity': newCapacity,
        'remain_capacity': newCapacity,
        'resources': resourcesWithRemain,
        // 'image_url': imageUrl ?? '',
        'location': {
          'latitude': _selectedLocation?.latitude,
          'longitude': _selectedLocation?.longitude,
          'address': _selectedLocation?.address,
        },
        'last_updated': DateTime.now(),
      });
      if (mounted) {
        setState(() { _saving = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relief center updated successfully!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() { _error = 'Failed to save: $e'; _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Relief Center')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.2),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Basic Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  // Row(
                  //   children: [
                  //     _imageFile != null
                  //         ? CircleAvatar(
                  //             backgroundImage: FileImage(_imageFile!),
                  //             radius: 32,
                  //           )
                  //         : (_imageUrl != null && _imageUrl!.isNotEmpty)
                  //             ? CircleAvatar(
                  //                 backgroundImage: NetworkImage(_imageUrl!),
                  //                 radius: 32,
                  //               )
                  //             : const CircleAvatar(
                  //                 radius: 32,
                  //                 child: Icon(Icons.image),
                  //               ),
                  //     const SizedBox(width: 12),
                  //     ElevatedButton.icon(
                  //       icon: const Icon(Icons.image),
                  //       label: const Text('Change Image'),
                  //       onPressed: _pickImage,
                  //     ),
                  //   ],
                  // ),
                  // const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    decoration: InputDecoration(
                      labelText: 'Relief Center Name',
                      errorText: _nameError,
                    ),
                    onTap: () {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.2),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextField(
                    controller: _descriptionController,
                    focusNode: _descriptionFocus,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      errorText: _descriptionError,
                    ),
                    maxLines: 3,
                    onTap: () {
                      if (_descriptionError != null) setState(() => _descriptionError = null);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.2),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact Info',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      errorText: _phoneError,
                    ),
                    keyboardType: TextInputType.phone,
                    onTap: () {
                      if (_phoneError != null) setState(() => _phoneError = null);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: _emailError,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onTap: () {
                      if (_emailError != null) setState(() => _emailError = null);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.2),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  LocationInput(
                    onSelectLocation: _onSelectLocation,
                    initialLocation: _selectedLocation,
                  ),
                  if (_selectedLocation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 1.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.place, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedLocation!.address,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.2),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capacity (people)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextField(
                    controller: _capacityController,
                    focusNode: _capacityFocus,
                    decoration: InputDecoration(
                      labelText: 'Maximum Capacity',
                      errorText: _capacityError,
                    ),
                    keyboardType: TextInputType.number,
                    onTap: () {
                      if (_capacityError != null) setState(() => _capacityError = null);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Resources Available',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _resourceNameController,
                          focusNode: _resourceNameFocus,
                          decoration: const InputDecoration(
                            labelText: 'Resource Name',
                          ),
                          onTap: () {
                            if (_resourceInputError != null) setState(() => _resourceInputError = null);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _resourceValueController,
                          focusNode: _resourceValueFocus,
                          decoration: const InputDecoration(
                            labelText: 'Resource Value',
                          ),
                          keyboardType: TextInputType.number,
                          onTap: () {
                            if (_resourceInputError != null) setState(() => _resourceInputError = null);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      _editingResourceIndex == null
                          ? ElevatedButton(
                              onPressed: _addResource,
                              child: const Icon(Icons.add),
                            )
                          : ElevatedButton(
                              onPressed: _saveResourceEdit,
                              child: const Icon(Icons.save),
                            ),
                    ],
                  ),
                  if (_resourceInputError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(
                        _resourceInputError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Column(
                    children: _resources.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final resource = entry.value;
                      return Card(
                        child: ListTile(
                          title: Text('${resource['name']}'),
                          subtitle: Text('Value: ${resource['value']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.settings),
                                tooltip: 'Edit',
                                onPressed: () => _editResource(idx),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Delete',
                                onPressed: () => _deleteResource(idx),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save Changes'),
                onPressed: _saving ? null : _saveChanges,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
