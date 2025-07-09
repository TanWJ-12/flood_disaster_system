import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fyp/report/page/report_detail.dart';

class ReportList extends StatelessWidget {
  const ReportList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No report added yet'),
          );
        }

        final reportDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: reportDocs.length,
          itemBuilder: (ctx, index) {
            final reportData = reportDocs[index].data() as Map<String, dynamic>;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(reportData['image_url']),
                ),
                title: Text(
                  reportData['title'] ?? 'No Title',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // const SizedBox(height: 4),
                    // Text(
                    //   reportData['location']['address'] ?? 'No Address',
                    //   style: Theme.of(context).textTheme.bodySmall,
                    // ),
                    // const SizedBox(height: 2),
                    Text(
                      'Created by: ${reportData['user_name'] ?? 'Unknown'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${reportData['created_time'] ?? 'Unknown'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
                onTap: () {
                  // Navigate to the report detail page
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => ReportDetail(report: reportData),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}