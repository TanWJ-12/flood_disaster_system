import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fyp/chat/page/broadcast_page.dart';
import 'package:fyp/chat/widget/broadcast_bubble.dart';

class DisplayBroadcastChat extends StatefulWidget {
  const DisplayBroadcastChat({super.key});

  @override
  State<DisplayBroadcastChat> createState() => _DisplayBroadcastChatState();
}

class _DisplayBroadcastChatState extends State<DisplayBroadcastChat> {


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('broadcasts')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return Container();
              final broadcasts = snapshot.data!.docs;
              if (broadcasts.isEmpty) return Container();
              return Column(
                children: broadcasts.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => const BroadcastPage()),
                      );
                    },
                    child: BroadcastBubble(
                      message: data['message'],
                      urgency: data['urgency'],
                      timestamp: data['timestamp'].toDate(),
                      imageUrl: data['image_url'],
                      location: data['location'] != null
                          ? {'lat': data['location']['lat'], 'lng': data['location']['lng']}
                          : null,
                    ),
                  );
                }).toList(),
              );
     },
     );

    }
  }
