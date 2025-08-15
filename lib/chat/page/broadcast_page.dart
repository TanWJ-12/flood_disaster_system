import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/chat/widget/broadcast_bubble.dart';

class BroadcastPage extends StatelessWidget {
  const BroadcastPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('broadcasts')
            .orderBy('timestamp', descending: true)
            .get(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final broadcasts = snapshot.data!.docs;
          return ListView(
            children: broadcasts.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return BroadcastBubble(
                message: data['message'],
                urgency: data['urgency'],
                timestamp: data['timestamp'].toDate(),
                imageUrl: data['image_url'],
                location: data['location'] != null
                    ? {'lat': data['location']['lat'], 'lng': data['location']['lng']}
                    : null,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}