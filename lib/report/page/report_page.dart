import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:fyp/report/provider/user_report.dart';
import 'package:fyp/report/page/add_report.dart';
import 'package:fyp/report/widgets/report_list.dart';

class ReportPage extends ConsumerWidget {
  const ReportPage ({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final userReport = ref.watch(userReportProvider);


    return Scaffold(
      appBar: AppBar(
        title: Text('Report'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx)=>const AddReportPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ReportList(
          // report: userReport,
        ),
      ),
    );
  }
}