import 'dart:io';
import 'package:flutter/material.dart';

// import 'package:image_picker/image_picker.dart';
import 'package:fyp/report/widgets/location_input.dart';
import 'package:fyp/report/models/report.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddReliefCenterPage extends StatefulWidget {
  const AddReliefCenterPage({super.key});

  @override
  State<AddReliefCenterPage> createState() => _AddReliefCenterPageState();
}

class _AddReliefCenterPageState extends State<AddReliefCenterPage> {
  final FocusNode _idFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _capacityFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _resourceNameFocus = FocusNode();
  final FocusNode _resourceValueFocus = FocusNode();

  @override
  void dispose() {
    _idFocus.dispose();
    _nameFocus.dispose();
    _capacityFocus.dispose();
    _descriptionFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _resourceNameFocus.dispose();
    _resourceValueFocus.dispose();
    super.dispose();
  }

  // Error variables for each field
  String? _idError,
      _nameError,
      _capacityError,
      _descriptionError,
      _resourceInputError,
      _phoneError,
      _emailError,
      _error;
  final _idController = TextEditingController();
  bool _isSaving = false;

  Future<void> _saveReliefCenter() async {
    setState(() {
      _idError = null;
      _nameError = null;
      _capacityError = null;
      _descriptionError = null;
      _phoneError = null;
      _emailError = null;
      _error = null;
    });

    final id = _idController.text.trim();
    final name = _nameController.text.trim();
    final capacity = _capacityController.text.trim();
    final description = _descriptionController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    bool hasError = false;
    if (id.isEmpty) {
      setState(() {
        _idError = 'Relief Center ID is required.';
      });
      hasError = true;
    }
    final idQuery =
        await FirebaseFirestore.instance
            .collection('relief_centers')
            .where('id', isEqualTo: id)
            .get();
    if (idQuery.docs.isNotEmpty) {
      setState(() {
        _idError =
            'Relief Center ID already exists. Please choose another one.';
      });
      hasError = true;
    }
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Name is required.';
      });
      hasError = true;
    }
    if (_selectedLocation == null) {
      setState(() {
        _error = 'Location is required.';
      });
      hasError = true;
    }
    if (capacity.isEmpty) {
      setState(() {
        _capacityError = 'Capacity is required.';
      });
      hasError = true;
    } else if (int.tryParse(capacity) == null) {
      setState(() {
        _capacityError = 'Capacity must be a number.';
      });
      hasError = true;
    }
    if (phone.isEmpty) {
      setState(() {
        _phoneError = 'Phone number is required.';
      });
      hasError = true;
    } else if (!_validatePhone(phone)) {
      setState(() {
        _phoneError = 'Invalid phone format';
      });
      hasError = true;
    }
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Email is required.';
      });
      hasError = true;
    } else if (!_validateEmail(email)) {
      setState(() {
        _emailError = 'Invalid email format';
      });
      hasError = true;
    }
    if (hasError) {
      setState(() {
        _isSaving = false;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      // Validate required fields
      if (_nameController.text.trim().isEmpty || _selectedLocation == null) {
        setState(() {
          _error = 'Name and location are required.';
          _isSaving = false;
        });
        return;
      }
      if (_phoneError != null || _emailError != null) {
        setState(() {
          _error = 'Please fix contact info errors.';
          _isSaving = false;
        });
        return;
      }

      // String? imageUrl;
      // if (_imageFile != null) {
      //   final ref = FirebaseStorage.instance
      //       .ref()
      //       .child('relief_center_images')
      //       .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      //   await ref.putFile(_imageFile!);
      //   imageUrl = await ref.getDownloadURL();
      // }

      final int capacity = int.tryParse(_capacityController.text.trim()) ?? 0;
      final List<Map<String, dynamic>> resourcesWithRemain = _resources.map((r) {
        final value = r['value'].toString();
        return {
          'name': r['name'],
          'value': value,
          'remain': value,
        };
      }).toList();
      final doc = {
        'id': id,
        'name': _nameController.text.trim(),
        // 'image_url': imageUrl ?? '',
        'location': {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
          'address': _selectedLocation!.address,
        },
        'resources': resourcesWithRemain,
        'capacity': capacity,
        'remain_capacity': capacity,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'description': _descriptionController.text.trim(),
        'last_updated': Timestamp.fromDate(_lastUpdated),
        'created_at': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('relief_centers').add(doc);

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relief center added successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to save: $e';
        _isSaving = false;
      });
    }
  }

  final _capacityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _lastUpdated = DateTime.now();

  void _updateTimestamp() {
    setState(() {
      _lastUpdated = DateTime.now();
    });
  }

  bool _validatePhone(String phone) {
    final phoneRegExp = RegExp(r'^(\+?\d{1,4}[\s-]?)?(\d{10,12})$');
    return phoneRegExp.hasMatch(phone);
  }

  bool _validateEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  final _resourceNameController = TextEditingController();
  final _resourceValueController = TextEditingController();
  final List<Map<String, dynamic>> _resources = [];
  int? _editingResourceIndex;

  void _addResource() {
    final name = _resourceNameController.text.trim();
    final value = _resourceValueController.text.trim();
    if (name.isEmpty || value.isEmpty) {
      setState(() {
        _resourceInputError = 'Resource name and value are required.';
      });
      return;
    }
    if (double.tryParse(value) == null) {
      setState(() {
        _resourceInputError = 'Resource value must be a number.';
      });
      return;
    }
    if (_resources.any((r) => r['name'].toLowerCase() == name.toLowerCase())) {
      setState(() {
        _resourceInputError = 'Resource already exists.';
      });
      return;
    }
    setState(() {
      _resources.add({'name': name, 'value': value});
      _resourceNameController.clear();
      _resourceValueController.clear();
      _error = null;
    });
  }

  void _deleteResource(int index) {
    setState(() {
      _resources.removeAt(index);
      _editingResourceIndex = null;
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
      setState(() {
        _resourceInputError = 'Resource name and value are required.';
      });
      return;
    }
    if (double.tryParse(value) == null) {
      setState(() {
        _resourceInputError = 'Resource value must be a number.';
      });
      return;
    }
    if (_resources.asMap().entries.any(
      (e) =>
          e.key != _editingResourceIndex &&
          e.value['name'].toLowerCase() == name.toLowerCase(),
    )) {
      setState(() {
        _resourceInputError = 'Resource already exists.';
      });
      return;
    }
    setState(() {
      _resources[_editingResourceIndex!] = {'name': name, 'value': value};
      _editingResourceIndex = null;
      _resourceNameController.clear();
      _resourceValueController.clear();
      _resourceInputError = null;
    });
  }

  File? _imageFile;
  final _nameController = TextEditingController();
  ReportLocation? _selectedLocation;

  // Future<void> _pickImage() async {
  //   final picker = ImagePicker();
  //   final picked = await picker.pickImage(
  //     source: ImageSource.gallery,
  //     imageQuality: 60,
  //   );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Relief Center')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  //           backgroundImage: FileImage(_imageFile!),
                  //           radius: 32,
                  //         )
                  //         : const CircleAvatar(
                  //           radius: 32,
                  //           child: Icon(Icons.image),
                  //         ),
                  //     const SizedBox(width: 12),
                  //     ElevatedButton.icon(
                  //       icon: const Icon(Icons.image),
                  //       label: const Text('Pick Image'),
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: _idController,
                    focusNode: _idFocus,
                    decoration: InputDecoration(
                      labelText: 'Relief Center ID (unique)',
                      errorText: _idError,
                    ),
                    onTap: () {
                      if (_idError != null) setState(() => _idError = null);
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
                      if (_descriptionError != null) {
                        setState(() => _descriptionError = null);
                      }
                    },
                    onChanged: (_) => _updateTimestamp(),
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
                      if (_phoneError != null) {
                        setState(() => _phoneError = null);
                      }
                    },
                    onChanged: (val) {
                      setState(() {
                        _phoneError =
                            val.isEmpty || _validatePhone(val)
                                ? null
                                : 'Invalid phone format';
                        _updateTimestamp();
                      });
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
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                    onChanged: (val) {
                      setState(() {
                        _emailError =
                            val.isEmpty || _validateEmail(val)
                                ? null
                                : 'Invalid email format';
                        _updateTimestamp();
                      });
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
                    onInteract: () {
                      if (_error != null) setState(() => _error = null);
                    },
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
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
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
                      if (_capacityError != null) {
                        setState(() => _capacityError = null);
                      }
                    },
                    onChanged: (_) => _updateTimestamp(),
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
                            if (_resourceInputError != null) {
                              setState(() => _resourceInputError = null);
                            }
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
                            if (_resourceInputError != null) {
                              setState(() => _resourceInputError = null);
                            }
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
                    children:
                        _resources.asMap().entries.map((entry) {
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
                icon:
                    _isSaving
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.save),
                label: const Text('Save Relief Center'),
                onPressed: _isSaving ? null : _saveReliefCenter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
