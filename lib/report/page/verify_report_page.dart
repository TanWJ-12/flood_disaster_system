import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fyp/report/page/report_detail.dart';

class VerifyReportPage extends StatefulWidget {
  const VerifyReportPage({super.key});

  @override
  State<VerifyReportPage> createState() => _VerifyReportPageState();
}

class _VerifyReportPageState extends State<VerifyReportPage> {
  void _handleAction(Future<void> action, String message) async {
    await action;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Reports'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('status', isEqualTo: 'Submitted')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending reports to verify.'));
          }
          final reports = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            separatorBuilder: (context, i) => const Divider(),
            itemBuilder: (context, i) {
              final report = reports[i];
              final data = report.data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(data['title'] ?? 'No Title'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['description'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(data['description']),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Status: ${data['status']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Verify (Yes)',
                        onPressed: () {
                          _handleAction(
                            report.reference.update({'status': 'Verified'}),
                            'Report verified.'
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Reject (No)',
                        onPressed: () {
                          _handleAction(
                            report.reference.update({'status': 'Rejected'}),
                            'Report rejected.'
                          );
                        },
                      ),
                    ],
                  ),
                  onLongPress: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => ReportDetail(report: data),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
