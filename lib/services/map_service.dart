import 'dart:math' as math;

import '../models/problem_report.dart';
import '../models/traffic_graph.dart';

class MapService {
  static List<ProblemReport> _problems = [];
  static TrafficGraph? _trafficGraph;

  /// Define lista de problemas reportados
  void setProblemReports(List<ProblemReport> problems) {
    _problems = problems;
  }

  /// Obtém todos os problemas reportados
  List<ProblemReport> getProblemReports() {
    return List.from(_problems);
  }

  /// Adiciona um novo problema
  void addProblemReport(ProblemReport problem) {
    _problems.add(problem);
  }

  /// Remove um problema
  void removeProblemReport(String problemId) {
    _problems.removeWhere((problem) => problem.id == problemId);
  }

  /// Atualiza um problema existente
  void updateProblemReport(ProblemReport updatedProblem) {
    int index = _problems.indexWhere(
      (problem) => problem.id == updatedProblem.id,
    );
    if (index != -1) {
      _problems[index] = updatedProblem;
    }
  }

  /// Obtém problemas por status
  List<ProblemReport> getProblemsByStatus(ProblemStatus status) {
    return _problems.where((problem) => problem.status == status).toList();
  }

  /// Obtém problemas por tipo
  List<ProblemReport> getProblemsByType(String type) {
    return _problems.where((problem) => problem.type == type).toList();
  }

  /// Obtém problemas em uma área específica (raio em metros)
  List<ProblemReport> getProblemsInArea(
    double centerLatitude,
    double centerLongitude,
    double radiusInMeters,
  ) {
    return _problems.where((problem) {
      double distance = _calculateDistance(
        centerLatitude,
        centerLongitude,
        problem.latitude,
        problem.longitude,
      );
      return distance <= radiusInMeters;
    }).toList();
  }

  /// Obtém problemas por região
  List<ProblemReport> getProblemsByRegion(String region) {
    // Assumindo que intersectionId contém informação da região
    return _problems.where((problem) {
      // Lógica para determinar região baseada na localização
      return _determineRegion(problem.latitude, problem.longitude) == region;
    }).toList();
  }

  /// Obtém estatísticas dos problemas
  Map<String, dynamic> getProblemStatistics() {
    Map<String, int> statusCount = {};
    Map<String, int> typeCount = {};
    Map<String, int> regionCount = {};

    for (ProblemReport problem in _problems) {
      // Contar por status
      String status = problem.status.toString().split('.').last;
      statusCount[status] = (statusCount[status] ?? 0) + 1;

      // Contar por tipo
      typeCount[problem.type] = (typeCount[problem.type] ?? 0) + 1;

      // Contar por região
      String region = _determineRegion(problem.latitude, problem.longitude);
      regionCount[region] = (regionCount[region] ?? 0) + 1;
    }

    return {
      'total': _problems.length,
      'byStatus': statusCount,
      'byType': typeCount,
      'byRegion': regionCount,
      'averageLikes': _problems.isNotEmpty
          ? _problems.map((p) => p.likes).reduce((a, b) => a + b) /
                _problems.length
          : 0,
    };
  }

  /// Obtém os problemas mais curtidos
  List<ProblemReport> getMostLikedProblems({int limit = 10}) {
    List<ProblemReport> sortedProblems = List.from(_problems);
    sortedProblems.sort((a, b) => b.likes.compareTo(a.likes));
    return sortedProblems.take(limit).toList();
  }

  /// Obtém problemas recentes
  List<ProblemReport> getRecentProblems({int limit = 10}) {
    List<ProblemReport> sortedProblems = List.from(_problems);
    sortedProblems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sortedProblems.take(limit).toList();
  }

  /// Define o grafo de tráfego
  void setTrafficGraph(TrafficGraph graph) {
    _trafficGraph = graph;
  }

  /// Obtém o grafo de tráfego
  TrafficGraph? getTrafficGraph() {
    return _trafficGraph;
  }

  /// Incrementa likes de um problema
  void likeProblem(String problemId) {
    int index = _problems.indexWhere((problem) => problem.id == problemId);
    if (index != -1) {
      ProblemReport problem = _problems[index];
      _problems[index] = ProblemReport(
        id: problem.id,
        userId: problem.userId,
        intersectionId: problem.intersectionId,
        type: problem.type,
        description: problem.description,
        latitude: problem.latitude,
        longitude: problem.longitude,
        timestamp: problem.timestamp,
        photoUrls: problem.photoUrls,
        status: problem.status,
        likes: problem.likes + 1,
        comments: problem.comments,
      );
    }
  }

  /// Adiciona comentário a um problema
  void addComment(String problemId, Comment comment) {
    int index = _problems.indexWhere((problem) => problem.id == problemId);
    if (index != -1) {
      ProblemReport problem = _problems[index];
      List<Comment> newComments = List.from(problem.comments);
      newComments.add(comment);

      _problems[index] = ProblemReport(
        id: problem.id,
        userId: problem.userId,
        intersectionId: problem.intersectionId,
        type: problem.type,
        description: problem.description,
        latitude: problem.latitude,
        longitude: problem.longitude,
        timestamp: problem.timestamp,
        photoUrls: problem.photoUrls,
        status: problem.status,
        likes: problem.likes,
        comments: newComments,
      );
    }
  }

  /// Atualiza status de um problema
  void updateProblemStatus(String problemId, ProblemStatus newStatus) {
    int index = _problems.indexWhere((problem) => problem.id == problemId);
    if (index != -1) {
      ProblemReport problem = _problems[index];
      _problems[index] = ProblemReport(
        id: problem.id,
        userId: problem.userId,
        intersectionId: problem.intersectionId,
        type: problem.type,
        description: problem.description,
        latitude: problem.latitude,
        longitude: problem.longitude,
        timestamp: problem.timestamp,
        photoUrls: problem.photoUrls,
        status: newStatus,
        likes: problem.likes,
        comments: problem.comments,
      );
    }
  }

  /// Busca problemas por texto
  List<ProblemReport> searchProblems(String searchText) {
    String lowercaseSearch = searchText.toLowerCase();

    return _problems.where((problem) {
      return problem.type.toLowerCase().contains(lowercaseSearch) ||
          problem.description.toLowerCase().contains(lowercaseSearch);
    }).toList();
  }

  /// Obtém problemas críticos (baseado em likes e tipo)
  List<ProblemReport> getCriticalProblems() {
    const criticalTypes = ['Semáforo com defeito', 'Acidente'];
    const minLikes = 10;

    return _problems.where((problem) {
      return criticalTypes.contains(problem.type) || problem.likes >= minLikes;
    }).toList();
  }

  /// Exporta dados para análise
  Map<String, dynamic> exportDataForAnalysis() {
    return {
      'problems': _problems
          .map(
            (p) => {
              'id': p.id,
              'type': p.type,
              'latitude': p.latitude,
              'longitude': p.longitude,
              'timestamp': p.timestamp.toIso8601String(),
              'likes': p.likes,
              'status': p.status.toString(),
              'region': _determineRegion(p.latitude, p.longitude),
            },
          )
          .toList(),
      'statistics': getProblemStatistics(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Limpa todos os problemas (para testes)
  void clearAllProblems() {
    _problems.clear();
  }

  /// Carrega problemas simulados para demonstração
  void loadSampleData() {
    _problems = [
      ProblemReport(
        id: '1',
        userId: 'user123',
        intersectionId: 'centro_principal',
        type: 'Semáforo com defeito',
        description:
            'Semáforo não está funcionando corretamente, fase amarela muito longa',
        latitude: -19.5407,
        longitude: -40.6306,
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        status: ProblemStatus.pending,
        likes: 15,
        comments: [
          Comment(
            id: 'c1',
            userId: 'user456',
            userName: 'João Silva',
            text: 'Confirmo, passei por lá agora há pouco',
            timestamp: DateTime.now().subtract(Duration(hours: 1)),
          ),
        ],
      ),

      ProblemReport(
        id: '2',
        userId: 'user456',
        intersectionId: 'maria_gracas',
        type: 'Buraco na via',
        description:
            'Buraco grande na pista da direita, veículos desviando perigosamente',
        latitude: -19.5207,
        longitude: -40.6256,
        timestamp: DateTime.now().subtract(Duration(hours: 5)),
        status: ProblemStatus.inProgress,
        likes: 8,
        comments: [],
      ),

      ProblemReport(
        id: '3',
        userId: 'user789',
        intersectionId: 'esplanada',
        type: 'Congestionamento',
        description: 'Trânsito muito lento no horário de pico da tarde',
        latitude: -19.5357,
        longitude: -40.6206,
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
        status: ProblemStatus.pending,
        likes: 23,
        comments: [
          Comment(
            id: 'c2',
            userId: 'user101',
            userName: 'Maria Santos',
            text: 'Todo dia é assim nesse horário',
            timestamp: DateTime.now().subtract(Duration(minutes: 25)),
          ),
          Comment(
            id: 'c3',
            userId: 'user102',
            userName: 'Pedro Costa',
            text: 'Precisam de um semáforo aqui',
            timestamp: DateTime.now().subtract(Duration(minutes: 20)),
          ),
        ],
      ),

      ProblemReport(
        id: '4',
        userId: 'user234',
        intersectionId: 'sao_silvano',
        type: 'Falta de sinalização',
        description:
            'Placa de pare está danificada, motoristas não estão respeitando',
        latitude: -19.5607,
        longitude: -40.6356,
        timestamp: DateTime.now().subtract(Duration(days: 1)),
        status: ProblemStatus.resolved,
        likes: 12,
        comments: [],
      ),

      ProblemReport(
        id: '5',
        userId: 'user567',
        intersectionId: 'nossa_senhora_fatima',
        type: 'Obra não sinalizada',
        description: 'Obra na via sem sinalização adequada, causando confusão',
        latitude: -19.5457,
        longitude: -40.6406,
        timestamp: DateTime.now().subtract(Duration(hours: 8)),
        status: ProblemStatus.pending,
        likes: 6,
        comments: [],
      ),
    ];
  }

  // MÉTODOS PRIVADOS

  /// Calcula distância entre dois pontos em metros
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // metros
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);

    double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  /// Converte graus para radianos
  double _toRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  /// Determina região baseada nas coordenadas
  String _determineRegion(double latitude, double longitude) {
    // Centro de Colatina
    const double centerLat = -19.5407;
    const double centerLng = -40.6306;

    if (latitude < centerLat) {
      return longitude < centerLng ? 'Sudoeste' : 'Sudeste';
    } else {
      return longitude < centerLng ? 'Noroeste' : 'Nordeste';
    }
  }
}

/// Extensões para facilitar uso
extension ProblemReportListExtensions on List<ProblemReport> {
  /// Filtra por data
  List<ProblemReport> filterByDate(DateTime start, DateTime end) {
    return where(
      (problem) =>
          problem.timestamp.isAfter(start) && problem.timestamp.isBefore(end),
    ).toList();
  }

  /// Filtra por área
  List<ProblemReport> filterByArea(
    double centerLat,
    double centerLng,
    double radiusInMeters,
  ) {
    return where((problem) {
      double distance = MapService()._calculateDistance(
        centerLat,
        centerLng,
        problem.latitude,
        problem.longitude,
      );
      return distance <= radiusInMeters;
    }).toList();
  }

  /// Ordena por likes
  List<ProblemReport> sortByLikes({bool descending = true}) {
    List<ProblemReport> sorted = List.from(this);
    sorted.sort(
      (a, b) =>
          descending ? b.likes.compareTo(a.likes) : a.likes.compareTo(b.likes),
    );
    return sorted;
  }

  /// Ordena por data
  List<ProblemReport> sortByDate({bool descending = true}) {
    List<ProblemReport> sorted = List.from(this);
    sorted.sort(
      (a, b) => descending
          ? b.timestamp.compareTo(a.timestamp)
          : a.timestamp.compareTo(b.timestamp),
    );
    return sorted;
  }
}
