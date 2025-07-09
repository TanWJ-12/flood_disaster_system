import 'package:uuid/uuid.dart';
import 'dart:io';

const uuid = Uuid();

class ReportLocation{
  const ReportLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;
}

class Report {
  Report({required this.title, required this.description, required this.image, required this.location, 
    required this.severity, required this.status, required this.userName, required this.createdTime
  }) : id = uuid.v4();
  final String id;
  final String title;
  final String description;
  final File image;
  final ReportLocation location;
  final String severity;
  final String status;
  final String userName;
  final String createdTime;
}