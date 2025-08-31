
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
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
	bool _isSaving = false;

	Future<void> _saveReliefCenter() async {
		setState(() { _isSaving = true; _error = null; });
		try {
			// Validate required fields
			if (_nameController.text.trim().isEmpty || _selectedLocation == null) {
				setState(() { _error = 'Name and location are required.'; _isSaving = false; });
				return;
			}
			if (_phoneError != null || _emailError != null) {
				setState(() { _error = 'Please fix contact info errors.'; _isSaving = false; });
				return;
			}

			String? imageUrl;
			if (_imageFile != null) {
				final ref = FirebaseStorage.instance
						.ref()
						.child('relief_center_images')
						.child('${DateTime.now().millisecondsSinceEpoch}.jpg');
				await ref.putFile(_imageFile!);
				imageUrl = await ref.getDownloadURL();
			}

			final doc = {
				'name': _nameController.text.trim(),
				'image_url': imageUrl ?? '',
				'location': {
					'latitude': _selectedLocation!.latitude,
					'longitude': _selectedLocation!.longitude,
					'address': _selectedLocation!.address,
				},
				'resources': _resources,
				'capacity': int.tryParse(_capacityController.text.trim()) ?? 0,
				'phone': _phoneController.text.trim(),
				'email': _emailController.text.trim(),
				'description': _descriptionController.text.trim(),
				'last_updated': Timestamp.fromDate(_lastUpdated),
				'created_at': Timestamp.now(),
			};

			await FirebaseFirestore.instance.collection('relief_centers').add(doc);

			if (mounted) {
				setState(() { _isSaving = false; });
				ScaffoldMessenger.of(context).showSnackBar(
					const SnackBar(content: Text('Relief center added successfully!')),
				);
				Navigator.of(context).pop();
			}
		} catch (e) {
			setState(() { _error = 'Failed to save: $e'; _isSaving = false; });
		}
	}
	final _capacityController = TextEditingController();
	final _phoneController = TextEditingController();
	final _emailController = TextEditingController();
	final _descriptionController = TextEditingController();
	DateTime _lastUpdated = DateTime.now();

	String? _phoneError;
	String? _emailError;

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
				_error = 'Resource name and value required.';
			});
			return;
		}
		if (_resources.any((r) => r['name'].toLowerCase() == name.toLowerCase())) {
			setState(() {
				_error = 'Resource already exists.';
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
				_error = 'Resource name and value required.';
			});
			return;
		}
		if (_resources.asMap().entries.any((e) => e.key != _editingResourceIndex && e.value['name'].toLowerCase() == name.toLowerCase())) {
			setState(() {
				_error = 'Resource already exists.';
			});
			return;
		}
		setState(() {
			_resources[_editingResourceIndex!] = {'name': name, 'value': value};
			_editingResourceIndex = null;
			_resourceNameController.clear();
			_resourceValueController.clear();
			_error = null;
		});
	}
		File? _imageFile;
		final _nameController = TextEditingController();
		ReportLocation? _selectedLocation;
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

		void _onSelectLocation(ReportLocation location) {
			setState(() {
				_selectedLocation = location;
			});
		}

	@override
	Widget build(BuildContext context) {
						const SizedBox(height: 32);
						SizedBox(
							width: double.infinity,
							child: ElevatedButton.icon(
								icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
								label: const Text('Save Relief Center'),
								onPressed: _isSaving ? null : _saveReliefCenter,
							),
						);
					return Scaffold(
						appBar: AppBar(
							title: const Text('Add Relief Center'),
						),
						body: SingleChildScrollView(
							padding: const EdgeInsets.all(16),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Row(
										children: [
											_imageFile != null
													? CircleAvatar(
															backgroundImage: FileImage(_imageFile!),
															radius: 32,
														)
													: const CircleAvatar(
															radius: 32,
															child: Icon(Icons.image),
														),
											const SizedBox(width: 12),
											ElevatedButton.icon(
												icon: const Icon(Icons.image),
												label: const Text('Pick Image'),
												onPressed: _pickImage,
											),
										],
									),
									const SizedBox(height: 16),
									TextField(
										controller: _nameController,
										decoration: const InputDecoration(labelText: 'Relief Center Name'),
									),
									const SizedBox(height: 16),
									LocationInput(
										onSelectLocation: _onSelectLocation,
									),
									if (_selectedLocation != null)
										Padding(
											padding: const EdgeInsets.only(top: 8),
											child: Text('Location: ${_selectedLocation!.address}'),
										),
									if (_error != null)
										Padding(
											padding: const EdgeInsets.only(top: 8),
											child: Text(_error!, style: const TextStyle(color: Colors.red)),
										),
									const SizedBox(height: 24),
									Text('Resources Available', style: Theme.of(context).textTheme.titleMedium),
									Row(
										children: [
											Expanded(
												child: TextField(
													controller: _resourceNameController,
													decoration: const InputDecoration(labelText: 'Resource Name'),
												),
											),
											const SizedBox(width: 8),
											Expanded(
												child: TextField(
													controller: _resourceValueController,
													decoration: const InputDecoration(labelText: 'Resource Value'),
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
									const SizedBox(height: 24),
									Text('Capacity', style: Theme.of(context).textTheme.titleMedium),
									TextField(
										controller: _capacityController,
										decoration: const InputDecoration(labelText: 'Maximum Capacity'),
										keyboardType: TextInputType.number,
										onChanged: (_) => _updateTimestamp(),
									),
									const SizedBox(height: 24),
									Text('Contact Info', style: Theme.of(context).textTheme.titleMedium),
									TextField(
										controller: _phoneController,
										decoration: InputDecoration(
											labelText: 'Phone Number',
											errorText: _phoneError,
										),
										keyboardType: TextInputType.phone,
										onChanged: (val) {
											setState(() {
												_phoneError = _validatePhone(val) ? null : 'Invalid phone format';
												_updateTimestamp();
											});
										},
									),
									const SizedBox(height: 8),
									TextField(
										controller: _emailController,
										decoration: InputDecoration(
											labelText: 'Email',
											errorText: _emailError,
										),
										keyboardType: TextInputType.emailAddress,
										onChanged: (val) {
											setState(() {
												_emailError = _validateEmail(val) ? null : 'Invalid email format';
												_updateTimestamp();
											});
										},
									),
									const SizedBox(height: 24),
									Text('Description', style: Theme.of(context).textTheme.titleMedium),
									TextField(
										controller: _descriptionController,
										decoration: const InputDecoration(labelText: 'Description'),
										maxLines: 3,
										onChanged: (_) => _updateTimestamp(),
									),
									const SizedBox(height: 24),
									Text('Last Updated: ${_lastUpdated.toLocal().toString().substring(0, 19)}'),
								],
							),
						),
					);
		}
	}
