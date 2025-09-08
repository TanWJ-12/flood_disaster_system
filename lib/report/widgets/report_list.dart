import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fyp/report/page/report_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportList extends StatefulWidget {
  const ReportList({super.key});

  @override
  State<ReportList> createState() => _ReportListState();
}

class _ReportListState extends State<ReportList> {
  Future<bool> _getIsAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    return doc.data()?['role'] == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _getIsAdmin(),
      builder: (context, adminSnapshot) {
        final isAdmin = adminSnapshot.data ?? false;
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('reports').snapshots(),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No report added yet'));
            }

            final reportDocs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: reportDocs.length,
              itemBuilder: (ctx, index) {
                final reportData =
                    reportDocs[index].data() as Map<String, dynamic>;

                Color boxColor;
                switch ((reportData['status'] ?? '').toString().toLowerCase()) {
                  case 'verified':
                    boxColor = Colors.green.shade100;
                    break;
                  case 'rejected':
                    boxColor = Colors.red.shade100;
                    break;
                  case 'fixed':
                    boxColor = Colors.blue.shade100;
                    break;
                  case 'submitted':
                  default:
                    boxColor = Colors.white;
                }
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: boxColor,
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
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundImage: NetworkImage(
                            reportData['image_url'],
                          ),
                        ),
                        title: Text(
                          reportData['title'] ?? 'No Title',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Created by: ${reportData['user_name'] ?? 'Unknown'}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${reportData['created_time'] ?? 'Unknown'}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        onTap: () async {
                          // Example async navigation with mounted check
                          await Future.delayed(
                            const Duration(milliseconds: 10),
                          );
                          if (!mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (ctx) => ReportDetail(report: reportData),
                            ),
                          );
                        },
                      ),
                      if (isAdmin &&
                          (reportData['status']?.toString().toLowerCase() == 'verified'))
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.build, size: 18, color: Colors.blue),
                            label: const Text('Mark as Fixed', style: TextStyle(color: Colors.blue)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              side: const BorderSide(color: Colors.blue, width: 1.5),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('reports')
                                  .doc(reportDocs[index].id)
                                  .update({'status': 'Fixed'});
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Report marked as fixed.'),
                                ),
                              );
                            },
                          ),
                        ),
                      if (isAdmin &&
                          (reportData['status']?.toString().toLowerCase() == 'rejected'))
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            label: const Text('Delete', style: TextStyle(color: Colors.red)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              side: const BorderSide(color: Colors.red, width: 1.5),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Report'),
                                  content: const Text('Are you sure you want to delete this report? This action cannot be undone.'),
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
                                await FirebaseFirestore.instance
                                    .collection('reports')
                                    .doc(reportDocs[index].id)
                                    .delete();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Report deleted.')),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
