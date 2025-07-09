import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fyp/report/models/report.dart';
import 'dart:io';

class  UserReportNotifier extends StateNotifier<List<Report>> {
  UserReportNotifier() :super(const []);

  void addReport(
    String title, 
    String description, 
    File image, 
    ReportLocation location, 
    String severity, 
    String status, 
    String userName,
    String createdTime
  ){
    final newReport = Report(
      title: title, 
      description: description, 
      image: image, 
      location: location, 
      severity: severity, 
      status: status, 
      userName: userName,
      createdTime: createdTime,
    );
    state = [newReport,...state];
    }
}

final userReportProvider = StateNotifierProvider<UserReportNotifier,List<Report>>(
  (ref) => UserReportNotifier(),
);