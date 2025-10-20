// lib/models/problem.dart - CÓDIGO COMPLETO E CORRETO
import 'package:cloud_firestore/cloud_firestore.dart';

enum ProblemType {
  traffic_light,
  pothole,
  traffic_jam,
  accident,
  construction,
  signage,
  other
}

enum ProblemSeverity { low, medium, high }

enum ProblemStatus { pending, in_progress, resolved }

class Problem {
  final String id;
  final String title;
  final String description;
  final String location;
  final double latitude;
  final double longitude;
  final ProblemType type;
  final ProblemSeverity severity;
  final DateTime createdAt;
  final ProblemStatus status;
  final int likes;
  final String reportedBy;

  Problem({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.severity,
    required this.createdAt,
    required this.status,
    this.likes = 0,
    this.reportedBy = 'Usuário Anônimo',
  });

  // ✅ Converter para Map (salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'type': type.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.toString().split('.').last,
      'likes': likes,
      'reportedBy': reportedBy,
    };
  }

  // ✅ Criar a partir do Map (ler do Firestore)
  factory Problem.fromMap(Map<String, dynamic> map, String documentId) {
    return Problem(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      type: _stringToProblemType(map['type']),
      severity: _stringToProblemSeverity(map['severity']),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: _stringToProblemStatus(map['status']),
      likes: map['likes'] ?? 0,
      reportedBy: map['reportedBy'] ?? 'Usuário Anônimo',
    );
  }

  // ✅ Métodos auxiliares de conversão
  static ProblemType _stringToProblemType(String? type) {
    switch (type) {
      case 'traffic_light':
        return ProblemType.traffic_light;
      case 'pothole':
        return ProblemType.pothole;
      case 'traffic_jam':
        return ProblemType.traffic_jam;
      case 'accident':
        return ProblemType.accident;
      case 'construction':
        return ProblemType.construction;
      case 'signage':
        return ProblemType.signage;
      default:
        return ProblemType.other;
    }
  }

  static ProblemSeverity _stringToProblemSeverity(String? severity) {
    switch (severity) {
      case 'high':
        return ProblemSeverity.high;
      case 'medium':
        return ProblemSeverity.medium;
      default:
        return ProblemSeverity.low;
    }
  }

  static ProblemStatus _stringToProblemStatus(String? status) {
    switch (status) {
      case 'in_progress':
        return ProblemStatus.in_progress;
      case 'resolved':
        return ProblemStatus.resolved;
      default:
        return ProblemStatus.pending;
    }
  }

  // ✅ Helper: Nome do tipo de problema
  static String typeToString(ProblemType type) {
    switch (type) {
      case ProblemType.traffic_light:
        return 'Semáforo com defeito';
      case ProblemType.pothole:
        return 'Buraco na via';
      case ProblemType.traffic_jam:
        return 'Congestionamento';
      case ProblemType.accident:
        return 'Acidente';
      case ProblemType.construction:
        return 'Obra';
      case ProblemType.signage:
        return 'Problema de sinalização';
      case ProblemType.other:
        return 'Outro';
    }
  }

  // ✅ Helper: Nome da severidade
  static String severityToString(ProblemSeverity severity) {
    switch (severity) {
      case ProblemSeverity.high:
        return 'Alta';
      case ProblemSeverity.medium:
        return 'Média';
      case ProblemSeverity.low:
        return 'Baixa';
    }
  }

  // ✅ Helper: Nome do status
  static String statusToString(ProblemStatus status) {
    switch (status) {
      case ProblemStatus.pending:
        return 'Pendente';
      case ProblemStatus.in_progress:
        return 'Em Andamento';
      case ProblemStatus.resolved:
        return 'Resolvido';
    }
  }
}
