// models/problem_report.dart
class ProblemReport {
  final String id;
  final String userId;
  final String intersectionId;
  final String type;
  final String description;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final List<String> photoUrls;
  final ProblemStatus status;
  final int likes;
  final List<Comment> comments;

  ProblemReport({
    required this.id,
    required this.userId,
    required this.intersectionId,
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.photoUrls = const [],
    this.status = ProblemStatus.pending,
    this.likes = 0,
    this.comments = const [],
  });
}

enum ProblemStatus { pending, inProgress, resolved, rejected }

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.timestamp,
  });
}
