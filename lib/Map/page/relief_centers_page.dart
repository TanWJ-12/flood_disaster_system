import 'package:fyp/Map/widget/distance_calculator.dart';

import 'package:flutter/material.dart';
import 'package:fyp/Map/page/add_relief_center_page.dart';
import 'package:fyp/Map/page/update_remain_page.dart';
import 'package:fyp/Map/page/edit_relief_center_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class ReliefCentersPage extends StatefulWidget {
  const ReliefCentersPage({super.key});

  @override
  State<ReliefCentersPage> createState() => _ReliefCentersPageState();
}

class _ReliefCentersPageState extends State<ReliefCentersPage> {
  Map<String, dynamic>? _selectedCenter;

  void _showReliefCenterInfo(Map<String, dynamic> center) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder:
          (ctx) => Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: [
                      const Icon(Icons.home, size: 28, color: Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          center['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Location & Distance chip
                  if (center['address'] != null || center['distance'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.directions,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Location & Distance',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (center['address'] != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              center['address'],
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (center['distance'] != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.directions_walk,
                            color: Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Distance: ${(center['distance'] / 1000).toStringAsFixed(2)} km',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Divider for contact section
                  if ((center['phone'] != null &&
                          center['phone'].toString().isNotEmpty) ||
                      (center['email'] != null &&
                          center['email'].toString().isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.contact_phone,
                                  color: Colors.teal,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Contact',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (center['phone'] != null &&
                      center['phone'].toString().isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.teal, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          center['phone'],
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  if (center['email'] != null &&
                      center['email'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.email,
                            color: Colors.deepPurple,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              center['email'],
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (center['capacity'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.people,
                                      color: Colors.orange,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Capacity',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              '${center['remain_capacity'] ?? center['capacity']}/${center['capacity']}',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (center['resources'] != null &&
                      center['resources'] is List &&
                      (center['resources'] as List).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.brown.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.inventory,
                                      color: Colors.brown,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Resources',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.brown,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ...((center['resources'] as List).map(
                            (r) => Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 2.0,
                                horizontal: 8.0,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: Colors.brown,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      r['remain'] != null
                                        ? '${r['name']}: ${r['remain']}/${r['value']}'
                                        : '${r['name']}: ${r['value']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  if (center['description'] != null &&
                      center['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.blueGrey,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Description',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 14,
                            ),
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              center['description'],
                              style: const TextStyle(
                                fontSize: 15,
                                fontStyle: FontStyle.italic,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
    );
  }

  LatLng? _userLocation;
  List<Map<String, dynamic>> _reliefCenters = [];
  Set<Marker> _markers = {};
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(3.139, 101.6869),
    zoom: 14,
  );
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _setInitialCameraPosition();
    _checkAdmin();
    _fetchReliefCenters();
  }

  Future<void> _setInitialCameraPosition() async {
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }
    final userLocation = await location.getLocation();
    setState(() {
      _userLocation = LatLng(
        userLocation.latitude ?? 3.139,
        userLocation.longitude ?? 101.6869,
      );
      _initialCameraPosition = CameraPosition(target: _userLocation!, zoom: 16);
    });
    if (_mapController != null && _userLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _userLocation!, zoom: 16),
        ),
      );
    }
  }

  Future<void> _fetchReliefCenters() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('relief_centers').get();
    final List<Map<String, dynamic>> centers = [];
    final markers =
        snapshot.docs
            .map((doc) {
              final data = doc.data();
              final lat = data['location']['latitude'] as double?;
              final lng = data['location']['longitude'] as double?;
              final name = data['name'] as String?;
              if (lat == null || lng == null || name == null) return null;
              final center = {
                'id': doc.id,
                'name': name,
                'lat': lat,
                'lng': lng,
                'address': data['location']['address'],
                'phone': data['phone'],
                'email': data['email'],
                'capacity': data['capacity'],
                'remain_capacity': data['remain_capacity'],
                'resources': data['resources'],
                'description': data['description'],
              };
              centers.add(center);
              return Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(lat, lng),
                // Remove infoWindow tap, so tap does nothing
                infoWindow: const InfoWindow(),
              );
            })
            .whereType<Marker>()
            .toSet();
    setState(() {
      _markers = markers;
      _reliefCenters = centers;
    });
  }

  bool _isAdmin = false;
  bool _loading = true;

  Future<void> _checkAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isAdmin = false;
        _loading = false;
      });
      return;
    }
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final role = doc.data()?['role'];
    setState(() {
      _isAdmin = role == 'admin';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relief Centers Map'),
        actions:
            _loading
                ? null
                : _isAdmin
                ? [
                  IconButton(
                    icon: const Icon(Icons.add_location_alt),
                    tooltip: 'Add Relief Center',
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => AddReliefCenterPage(),
                        ),
                      );
                      // Reload relief centers after returning
                      _fetchReliefCenters();
                    },
                  ),
                ]
                : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 250,
                  child: GoogleMap(
                    initialCameraPosition: _initialCameraPosition,
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (_userLocation != null) {
                        controller.moveCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(target: _userLocation!, zoom: 16),
                          ),
                        );
                      }
                    },
                    onLongPress: (latLng) {
                      // Find the nearest marker to the long-press location
                      Marker? nearest;
                      double minDist = double.infinity;
                      for (final marker in _markers) {
                        final dist = ((latLng.latitude - marker.position.latitude).abs() +
                            (latLng.longitude - marker.position.longitude).abs());
                        if (dist < minDist) {
                          minDist = dist;
                          nearest = marker;
                        }
                      }
                      if (nearest != null && minDist < 0.0005) { // ~50m threshold
                        final center = _reliefCenters.firstWhere(
                          (c) => c['lat'] == nearest!.position.latitude && c['lng'] == nearest.position.longitude,
                          orElse: () => {},
                        );
                        if (center.isNotEmpty) {
                          _showReliefCenterInfo(center);
                        }
                      }
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'List of Relief Centers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 600),
                  // Match the map's width and optionally set a max width for better appearance on large screens
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _userLocation == null
                        ? const Center(child: CircularProgressIndicator())
                        : Builder(
                            builder: (context) {
                              final centersWithDistance =
                                  _reliefCenters.map((center) {
                                    final distance =
                                        DistanceCalculator.calculateDistance(
                                          _userLocation!,
                                          LatLng(center['lat'], center['lng']),
                                        );
                                    return {...center, 'distance': distance};
                                  }).toList();
                              centersWithDistance.sort(
                                (a, b) => (a['distance'] as double).compareTo(
                                  b['distance'] as double,
                                ),
                              );
                              return ListView.separated(
                                itemCount: centersWithDistance.length,
                                separatorBuilder:
                                    (context, index) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: Divider(
                                            height: 1.5,
                                            color: Colors.grey.shade500,
                                            thickness: 1.2,
                                          ),
                                        ),
                                itemBuilder: (context, index) {
                                  final center = centersWithDistance[index];
                                  final isSelected =
                                      _selectedCenter != null &&
                                      _selectedCenter!['id'] == center['id'];
                                  return GestureDetector(
                                    onTap: () async {
                                      if (_mapController != null) {
                                        await _mapController!.animateCamera(
                                          CameraUpdate.newCameraPosition(
                                            CameraPosition(
                                              target: LatLng(
                                                center['lat'],
                                                center['lng'],
                                              ),
                                              zoom: 16,
                                            ),
                                          ),
                                        );
                                      }
                                      setState(() {
                                        _selectedCenter = center;
                                      });
                                    },
                                    onLongPress: () {
                                      setState(() {
                                        _selectedCenter = center;
                                      });
                                      _showReliefCenterInfo(center);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      margin: const EdgeInsets.symmetric(vertical: 4),
                                      decoration: isSelected
                                          ? BoxDecoration(
                                              color: Colors.grey.shade900,
                                              border: Border.all(color: Colors.black, width: 2.5),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.18),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            )
                                          : BoxDecoration(
                                              color: const Color.fromARGB(255, 255, 255, 255),
                                              border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                      
                                      child: ListTile(
                                        leading: Icon(Icons.location_on, color: isSelected ? Colors.white : Colors.grey),
                                        title: Text(
                                          center['name'] ?? '',
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? Colors.white : Colors.black,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${center['address'] ?? ''}\n${(center['distance'] / 1000).toStringAsFixed(2)} km away',
                                          style: TextStyle(
                                            color: isSelected ? Colors.grey.shade200 : Colors.black87,
                                          ),
                                        ),
                                        trailing: _isAdmin
                                            ? PopupMenuButton<String>(
                                                icon: Icon(Icons.more_vert, color: isSelected ? Colors.grey.shade200 : Colors.black87),
                                                onSelected: (value) async {
                                                  if (value == 'update_remain') {
                                                    final updated = await Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (ctx) => UpdateRemainPage(
                                                          reliefCenterId: center['id'],
                                                          capacity: center['capacity'] ?? 0,
                                                          remainCapacity: center['remain_capacity'] ?? center['capacity'] ?? 0,
                                                          resources: (center['resources'] as List?)?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [],
                                                        ),
                                                      ),
                                                    );
                                                    if (updated == true) {
                                                      _fetchReliefCenters();
                                                    }
                                                  } else if (value == 'modify_data') {
                                                    final updated = await Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (ctx) => EditReliefCenterPage(reliefCenterId: center['id']),
                                                      ),
                                                    );
                                                    if (updated == true) {
                                                      _fetchReliefCenters();
                                                    }
                                                  } else if (value == 'delete_center') {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (ctx) => AlertDialog(
                                                        title: const Text('Delete Relief Center'),
                                                        content: const Text('Are you sure you want to delete this relief center? This action cannot be undone.'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.of(ctx).pop(false),
                                                            child: const Text('Cancel'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () => Navigator.of(ctx).pop(true),
                                                            child: const Text('Yes, Delete'),
                                                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      await FirebaseFirestore.instance.collection('relief_centers').doc(center['id']).delete();
                                                      _fetchReliefCenters();
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('Relief center deleted.')),
                                                        );
                                                      }
                                                    }
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(
                                                    value: 'update_remain',
                                                    child: ListTile(
                                                      leading: Icon(Icons.update),
                                                      title: Text('Update Remain'),
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'modify_data',
                                                    child: ListTile(
                                                      leading: Icon(Icons.edit),
                                                      title: Text('Modify Data'),
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: 'delete_center',
                                                    child: ListTile(
                                                      leading: const Icon(Icons.delete, color: Colors.red),
                                                      title: const Text('Delete Relief Center', style: TextStyle(color: Colors.red)),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : null,

                                        tileColor: Colors.transparent,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
