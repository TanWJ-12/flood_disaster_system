import 'package:flutter/material.dart';

class BroadcastBubble extends StatelessWidget {
  final String message;
  final String urgency;
  final DateTime timestamp;
  final String? imageUrl;
  final Map<String, double>? location;

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
                child: Image.network(imageUrl!),
              ),
            if (location != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Location: ${location!['lat']}, ${location!['lng']}'),
              ),
          ],
        ),
      ),
    );
  }
}