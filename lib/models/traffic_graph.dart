// models/traffic_graph.dart
class TrafficGraph {
  final Map<String, Intersection> intersections = {};
  final List<Road> roads = [];

  void addIntersection(Intersection intersection) {
    intersections[intersection.id] = intersection;
  }

  void addRoad(Road road) {
    roads.add(road);
    intersections[road.fromId]?.connections.add(road);
  }

  // Algoritmo de Dijkstra para encontrar menor caminho
  List<String> findShortestPath(String fromId, String toId) {
    Map<String, double> distances = {};
    Map<String, String?> previous = {};
    Set<String> unvisited = {};

    // Inicializar distâncias
    for (String id in intersections.keys) {
      distances[id] = double.infinity;
      previous[id] = null;
      unvisited.add(id);
    }
    distances[fromId] = 0.0;

    while (unvisited.isNotEmpty) {
      // Encontrar nó não visitado com menor distância
      String current = unvisited.reduce(
        (a, b) => distances[a]! < distances[b]! ? a : b,
      );
      unvisited.remove(current);

      if (current == toId) break;

      // Atualizar distâncias dos vizinhos
      for (Road road in intersections[current]?.connections ?? []) {
        if (unvisited.contains(road.toId)) {
          double newDist = distances[current]! + road.weight;
          if (newDist < distances[road.toId]!) {
            distances[road.toId] = newDist;
            previous[road.toId] = current;
          }
        }
      }
    }

    // Reconstruir caminho
    List<String> path = [];
    String? current = toId;
    while (current != null) {
      path.insert(0, current);
      current = previous[current];
    }

    return distances[toId] == double.infinity ? [] : path;
  }

  // Identificar nós críticos (alta centralidade)
  Map<String, double> calculateCriticalNodes() {
    Map<String, double> centrality = {};

    for (String nodeId in intersections.keys) {
      centrality[nodeId] = 0.0;

      // Calcular quantos caminhos mais curtos passam por este nó
      for (String from in intersections.keys) {
        for (String to in intersections.keys) {
          if (from != to && from != nodeId && to != nodeId) {
            List<String> path = findShortestPath(from, to);
            if (path.contains(nodeId)) {
              centrality[nodeId] = centrality[nodeId]! + 1.0;
            }
          }
        }
      }
    }

    return centrality;
  }

  // Analisar fluxo entre regiões
  Map<String, Map<String, double>> analyzeRegionalFlow() {
    Map<String, Map<String, double>> flowMatrix = {};

    for (String from in intersections.keys) {
      flowMatrix[from] = {};
      for (String to in intersections.keys) {
        if (from != to) {
          List<String> path = findShortestPath(from, to);
          double pathWeight = 0.0;

          for (int i = 0; i < path.length - 1; i++) {
            Road? road = roads
                .where((r) => r.fromId == path[i] && r.toId == path[i + 1])
                .firstOrNull;
            pathWeight += road?.weight ?? 0.0;
          }

          flowMatrix[from]![to] = pathWeight;
        }
      }
    }

    return flowMatrix;
  }
}

class Intersection {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<Road> connections;
  final String region;

  Intersection({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.region,
    List<Road>? connections,
  }) : connections = connections ?? [];
}

class Road {
  final String id;
  final String fromId;
  final String toId;
  final double weight; // Representa congestionamento/tempo
  final String name;
  final double distance;

  Road({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.weight,
    required this.name,
    required this.distance,
  });
}
