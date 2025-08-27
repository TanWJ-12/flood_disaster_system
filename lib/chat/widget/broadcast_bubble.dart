import 'package:flutter/material.dart';
import 'package:fyp/report/models/report.dart';
import 'package:fyp/report/page/map.dart';

class BroadcastBubble extends StatelessWidget {
  final String message;
  final String urgency;
  final DateTime timestamp;
  final String? imageUrl;
  final Map<String, dynamic>? location;

  const BroadcastBubble({
    super.key,
    required this.message,
    required this.urgency,
    required this.timestamp,
    this.imageUrl,
    this.location,
  });

  Color getUrgencyColor() {
    switch (urgency) {
      case 'Critical':
        return Colors.red;
      case 'Warning':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String get locationImage {
    final lat = location?['lat'];
    final lng = location?['lng'];
    return 'https://maps.googleapis.com/maps/api/staticmap?center=$lat,$lng&zoom=16&size=600x300&maptype=roadmap&markers=color:red%7Clabel:A%7C$lat,$lng&key=AIzaSyBwwBs-ziUyNBkEl-1K2bhgVUMVMGftatM';
  }

  ReportLocation get reportLocation {
    final lat = location?['lat'];
    final lng = location?['lng'];
    return ReportLocation(latitude: lat!, longitude: lng!, address: '');
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: getUrgencyColor(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    urgency,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Text(
                  '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 16)),
            if (imageUrl != null && imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => Scaffold(
                            appBar: AppBar(),
                            body: Center(
                              child: Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      height: 240,
                    ),
                  ),
                ),
              ),
            if (location != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => MapPage(
                            location: reportLocation,
                            isSelecting: false,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 1), // Black border
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(locationImage),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            location!['address'] ?? 'No Address',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ),
          ],
        ),
      ),
    );
  }
}