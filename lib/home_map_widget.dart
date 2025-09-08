import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:math' as math;
import 'package:fyp/report/page/report_detail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserMapWidget extends StatefulWidget {
  const UserMapWidget({super.key});

  @override
  State<UserMapWidget> createState() => _UserMapWidgetState();
}

class _UserMapWidgetState extends State<UserMapWidget> {
  LatLng? _userLocation;
  GoogleMapController? _mapController;
  Set<Marker> _reportMarkers = {};

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  _fetchVerifiedReports();
  }
  Future<void> _fetchVerifiedReports() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reports')
        .where('status', isEqualTo: 'Verified')
        .get();
    final markers = <Marker>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final loc = data['location'];
      if (loc != null && loc['latitude'] != null && loc['longitude'] != null) {
        markers.add(
          Marker(
            markerId: MarkerId('report_${doc.id}'),
            position: LatLng(loc['latitude'], loc['longitude']),
            infoWindow: InfoWindow(
              title: data['title'] ?? 'Verified Report',
              snippet: data['description'] ?? '',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
    }
    setState(() {
      _reportMarkers = markers;
    });
  }

  Future<void> _getUserLocation() async {
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
    });
    if (_mapController != null && _userLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _userLocation!, zoom: 16),
        ),
      );
    }
  }

  // Helper to find the nearest marker to a tapped LatLng
  Marker? _findNearestMarker(LatLng tap, {double thresholdMeters = 100}) {
    Marker? nearest;
    double minDist = double.infinity;
    for (final marker in _reportMarkers) {
      final dist = _distanceBetween(tap, marker.position);
      if (dist < minDist && dist < thresholdMeters) {
        minDist = dist;
        nearest = marker;
      }
    }
    return nearest;
  }

  double _distanceBetween(LatLng a, LatLng b) {
    const double R = 6371000; // meters
    final dLat = (b.latitude - a.latitude) * math.pi / 180.0;
    final dLng = (b.longitude - a.longitude) * math.pi / 180.0;
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;
    final aVal = math.pow(math.sin(dLat / 2), 2) +
        math.pow(math.sin(dLng / 2), 2) * math.cos(lat1) * math.cos(lat2);
    final c = 2 * math.atan2(math.sqrt(aVal), math.sqrt(1 - aVal));
    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
          child: Text(
            'Verified Reports Map',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 0, 0, 0),
                ),
          ),
        ),
        Flexible(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            margin: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 650,
                child: _userLocation == null
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _userLocation!,
                          zoom: 16,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        markers: _reportMarkers,
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        onLongPress: (latLng) async {
                          final nearest = _findNearestMarker(latLng);
                          if (nearest != null) {
                            // Find the report data for this marker
                            final snapshot = await FirebaseFirestore.instance
                                .collection('reports')
                                .where('status', isEqualTo: 'Verified')
                                .get();
                            QueryDocumentSnapshot<Map<String, dynamic>>? doc;
                            for (final d in snapshot.docs) {
                              final loc = d['location'];
                              if (loc != null &&
                                  loc['latitude'] == nearest.position.latitude &&
                                  loc['longitude'] == nearest.position.longitude) {
                                doc = d;
                                break;
                              }
                            }
                            if (doc != null && mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (ctx) => ReportDetail(report: doc!.data()),
                                ),
                              );
                            }
                          }
                        },
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
