import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/chat/widget/broadcast_bubble.dart';

class BroadcastPage extends StatelessWidget {
  const BroadcastPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('chats').doc('broadcast').get(),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final doc = snapshot.data;
          if (doc == null || !doc.exists) {
            return const Center(child: Text('No announcements yet.'));
          }
          final data = doc.data() as Map<String, dynamic>;
          final messages = (data['messages'] as List<dynamic>? ?? []).reversed;
          if (messages.isEmpty) {
            return const Center(child: Text('No announcements yet.'));
          }
          return ListView(
            children: messages.map((msg) {
              return BroadcastBubble(
                message: msg['message'] ?? '',
                urgency: msg['urgency'] ?? 'Update',
                timestamp: (msg['timestamp'] as Timestamp).toDate(),
                imageUrl: msg['image_url'],
                location: msg['location'] != null
                    ? {'lat': msg['location']['lat'], 'lng': msg['location']['lng'], 'address': msg['location']['address']}
                    : null,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}