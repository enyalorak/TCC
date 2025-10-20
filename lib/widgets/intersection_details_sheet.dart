import 'package:flutter/material.dart';
import '../models/traffic_graph.dart';

class IntersectionDetailsSheet extends StatelessWidget {
  final Intersection intersection;
  final TrafficGraph trafficGraph;

  const IntersectionDetailsSheet({
    Key? key,
    required this.intersection,
    required this.trafficGraph,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Road> connections = intersection.connections;
    Map<String, double> criticalNodes = trafficGraph.calculateCriticalNodes();
    double criticality = criticalNodes[intersection.id] ?? 0.0;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER COM TÍTULO E ÍCONE
          Row(
            children: [
              Icon(
                Icons.traffic,
                size: 32,
                color: _getCriticalityColor(criticality),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      intersection.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Região: ${intersection.region}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close),
              ),
            ],
          ),

          SizedBox(height: 16),

          // CHIP DE CRITICIDADE
          Row(
            children: [
              _buildCriticalityChip(criticality),
              SizedBox(width: 12),
              Text(
                'Índice: ${criticality.toStringAsFixed(1)}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // INFORMAÇÕES GEOGRÁFICAS
          _buildInfoCard('Localização', [
            _buildInfoRow('Latitude', intersection.latitude.toStringAsFixed(6)),
            _buildInfoRow(
              'Longitude',
              intersection.longitude.toStringAsFixed(6),
            ),
            _buildInfoRow('Região', intersection.region),
          ]),

          SizedBox(height: 16),

          // CONEXÕES E TRÁFEGO
          _buildConnectionsCard(connections),

          SizedBox(height: 20),

          // ANÁLISE DE TRÁFEGO
          _buildTrafficAnalysisCard(criticality, connections),

          SizedBox(height: 20),

          // BOTÕES DE AÇÃO
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.directions),
                  label: Text('Ver Rotas'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/analysis');
                  },
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.all(12)),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.report),
                  label: Text('Reportar'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/report');
                  },
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.all(12)),
                ),
              ),
            ],
          ),

          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCriticalityChip(double criticality) {
    String level;
    Color color;
    IconData icon;

    if (criticality > 5) {
      level = 'CRÍTICO';
      color = Colors.red;
      icon = Icons.warning;
    } else if (criticality > 2) {
      level = 'MODERADO';
      color = Colors.orange;
      icon = Icons.error_outline;
    } else {
      level = 'NORMAL';
      color = Colors.green;
      icon = Icons.check_circle_outline;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        level,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildConnectionsCard(List<Road> connections) {
    if (connections.isEmpty) {
      return _buildInfoCard('Conexões', [
        Text(
          'Nenhuma conexão mapeada',
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ]);
    }

    return _buildInfoCard(
      'Conexões (${connections.length})',
      connections.map((road) {
        Intersection? target = trafficGraph.intersections[road.toId];
        String trafficStatus = _getTrafficStatus(road.weight);
        Color statusColor = _getTrafficColor(road.weight);

        return Container(
          margin: EdgeInsets.symmetric(vertical: 4),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.arrow_forward, color: statusColor, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target?.name ?? 'Destino desconhecido',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 2),
                    Text(
                      road.name,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    trafficStatus,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    '${road.weight.toStringAsFixed(1)} min',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrafficAnalysisCard(double criticality, List<Road> connections) {
    double avgTrafficTime = connections.isNotEmpty
        ? connections.map((r) => r.weight).reduce((a, b) => a + b) /
              connections.length
        : 0.0;

    String recommendation = _getRecommendation(criticality, avgTrafficTime);

    return _buildInfoCard('Análise de Tráfego', [
      _buildAnalysisRow(
        'Criticidade',
        _getCriticalityText(criticality),
        _getCriticalityColor(criticality),
      ),
      _buildAnalysisRow(
        'Tempo Médio',
        '${avgTrafficTime.toStringAsFixed(1)} min',
        _getTrafficColor(avgTrafficTime),
      ),
      _buildAnalysisRow('Conexões', '${connections.length} vias', Colors.blue),
      SizedBox(height: 12),
      Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                recommendation,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildAnalysisRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // MÉTODOS AUXILIARES

  Color _getCriticalityColor(double criticality) {
    if (criticality > 5) return Colors.red;
    if (criticality > 2) return Colors.orange;
    return Colors.green;
  }

  String _getCriticalityText(double criticality) {
    if (criticality > 5) return 'Crítica';
    if (criticality > 2) return 'Moderada';
    return 'Normal';
  }

  Color _getTrafficColor(double weight) {
    if (weight <= 2.5) return Colors.green;
    if (weight <= 4.0) return Colors.yellow[700]!;
    return Colors.red;
  }

  String _getTrafficStatus(double weight) {
    if (weight <= 2.5) return 'Livre';
    if (weight <= 4.0) return 'Moderado';
    return 'Lento';
  }

  String _getRecommendation(double criticality, double avgTrafficTime) {
    if (criticality > 5) {
      return 'Intersecção crítica! Requer intervenção imediata, como semáforos inteligentes ou rotatórias.';
    } else if (criticality > 2) {
      return 'Monitoramento necessário. Considerar melhorias na sinalização.';
    } else if (avgTrafficTime > 4.0) {
      return 'Fluxo lento detectado. Verificar possíveis gargalos nas vias conectadas.';
    } else {
      return 'Intersecção funcionando adequadamente. Manter monitoramento regular.';
    }
  }
}
