// ✅ DASHBOARD COM DADOS REAIS DO FIREBASE

import 'package:flutter/material.dart';
import 'package:testetcc/models/problem.dart';
import 'package:testetcc/services/database_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _secretTapCount = 0; // ✅ Contador de toques secretos

  // ✅ FUNÇÃO SECRETA PARA LIMPAR DADOS DE TESTE
  void _onSecretTap() {
    setState(() {
      _secretTapCount++;
    });

    if (_secretTapCount >= 5) {
      _secretTapCount = 0;
      _showAdminMenu();
    }
  }

  // ✅ MENU SECRETO DE ADMINISTRADOR
  void _showAdminMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.orange),
            SizedBox(width: 8),
            Text('Painel de Administrador'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Você descobriu o menu secreto! 🔐'),
            SizedBox(height: 16),
            Text(
              'O que deseja fazer?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _confirmClearTestData();
            },
            icon: Icon(Icons.delete_forever),
            label: Text('Limpar Dados de Teste'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ CONFIRMAÇÃO ANTES DE DELETAR
  void _confirmClearTestData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text('Atenção!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Você está prestes a deletar TODOS os problemas de teste do banco de dados.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                '⚠️ Esta ação NÃO pode ser desfeita!\n\nTodos os problemas com menos de 10 curtidas serão removidos.',
                style: TextStyle(fontSize: 13),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Digite CONFIRMAR para prosseguir:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showConfirmationDialog();
            },
            child: Text('Continuar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ DIÁLOGO FINAL COM CAMPO DE TEXTO
  void _showConfirmationDialog() {
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmação Final'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Digite CONFIRMAR em letras maiúsculas:'),
            SizedBox(height: 12),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'CONFIRMAR',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (confirmController.text == 'CONFIRMAR') {
                Navigator.pop(context);
                _clearTestData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Texto incorreto. Operação cancelada.'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: Text('Deletar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FUNÇÃO QUE DELETA OS DADOS DE TESTE
  Future<void> _clearTestData() async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deletando dados de teste...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final problems = await DatabaseService.getAllProblemsStream().first;
      int deletedCount = 0;

      // Deletar problemas com menos de 10 curtidas (assumindo que são testes)
      for (var problem in problems) {
        if (problem.likes < 10) {
          await DatabaseService.deleteProblem(problem.id);
          deletedCount++;
        }
      }

      // Fechar loading
      Navigator.pop(context);

      // Mostrar resultado
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 8),
              Text('Concluído!'),
            ],
          ),
          content: Text(
            '$deletedCount problema(s) de teste foram deletados com sucesso.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      // Fechar loading
      Navigator.pop(context);

      // Mostrar erro
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 32),
              SizedBox(width: 8),
              Text('Erro!'),
            ],
          ),
          content: Text('Erro ao deletar dados: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _onSecretTap, // ✅ TOQUE SECRETO NO TÍTULO
          child: Text('Dashboard - Gestores'),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.map),
            onPressed: () => Navigator.pushNamed(context, '/'),
            tooltip: 'Ver Mapa',
          ),
        ],
      ),
      body: StreamBuilder<List<Problem>>(
        stream: DatabaseService.getAllProblemsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Erro ao carregar dados'),
                  SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando dados...'),
                ],
              ),
            );
          }

          final allProblems = snapshot.data!;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRealTimeStats(allProblems),
                SizedBox(height: 16),
                _buildRecentReports(allProblems),
                SizedBox(height: 16),
                _buildCriticalPoints(allProblems),
                SizedBox(height: 16),
                _buildProblemsByType(allProblems),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ ESTATÍSTICAS EM TEMPO REAL
  Widget _buildRealTimeStats(List<Problem> problems) {
    final activeCount =
        problems.where((p) => p.status != ProblemStatus.resolved).length;
    final inProgressCount =
        problems.where((p) => p.status == ProblemStatus.in_progress).length;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final resolvedTodayCount = problems
        .where((p) =>
            p.status == ProblemStatus.resolved && p.createdAt.isAfter(today))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.analytics, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Estatísticas em Tempo Real',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _buildStatCard(
                    'Problemas Ativos', activeCount, Colors.red)),
            SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    'Resolvidos Hoje', resolvedTodayCount, Colors.green)),
            SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    'Em Andamento', inProgressCount, Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Card(
      elevation: 3,
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ PROBLEMAS RECENTES (ÚLTIMOS 5)
  Widget _buildRecentReports(List<Problem> problems) {
    // Ordenar por data (mais recentes primeiro)
    final sortedProblems = List<Problem>.from(problems)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final recentProblems = sortedProblems.take(5).toList();

    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Problemas Recentes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Text(
                  'Últimos ${recentProblems.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (recentProblems.isEmpty)
              Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 50, color: Colors.green),
                      SizedBox(height: 8),
                      Text('Nenhum problema reportado!'),
                    ],
                  ),
                ),
              )
            else
              ...recentProblems
                  .map((problem) => _buildReportItem(problem))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(Problem problem) {
    Color severityColor;
    switch (problem.severity) {
      case ProblemSeverity.high:
        severityColor = Colors.red;
        break;
      case ProblemSeverity.medium:
        severityColor = Colors.orange;
        break;
      case ProblemSeverity.low:
        severityColor = Colors.yellow[700]!;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: severityColor, width: 4)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: severityColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  problem.title,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  problem.location,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _getTimeAgo(problem.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
              SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.thumb_up, size: 12, color: Colors.blue),
                  SizedBox(width: 2),
                  Text('${problem.likes}', style: TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ PONTOS CRÍTICOS (AGRUPADOS POR LOCALIZAÇÃO)
  Widget _buildCriticalPoints(List<Problem> problems) {
    final activeProblems =
        problems.where((p) => p.status != ProblemStatus.resolved).toList();

    // Agrupar por localização (pegar primeira parte do endereço)
    final Map<String, List<Problem>> grouped = {};
    for (var problem in activeProblems) {
      final location = problem.location.split(' - ')[0]; // Ex: "Centro"
      grouped[location] = grouped[location] ?? [];
      grouped[location]!.add(problem);
    }

    // Ordenar por quantidade de problemas
    final sortedLocations = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Pontos Críticos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (sortedLocations.isEmpty)
              Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 50, color: Colors.green),
                      SizedBox(height: 8),
                      Text('Nenhum ponto crítico identificado!'),
                    ],
                  ),
                ),
              )
            else
              ...sortedLocations.take(5).map((entry) {
                final location = entry.key;
                final locationProblems = entry.value;
                final highSeverityCount = locationProblems
                    .where((p) => p.severity == ProblemSeverity.high)
                    .length;

                String level;
                Color color;

                if (highSeverityCount >= 2 || locationProblems.length >= 3) {
                  level = 'Alto';
                  color = Colors.red;
                } else if (highSeverityCount >= 1 ||
                    locationProblems.length >= 2) {
                  level = 'Médio';
                  color = Colors.orange;
                } else {
                  level = 'Baixo';
                  color = Colors.green;
                }

                return _buildCriticalPointItem(
                  location,
                  level,
                  color,
                  locationProblems.length,
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalPointItem(
      String location, String level, Color color, int problemCount) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                Text(
                  '$problemCount problema${problemCount > 1 ? 's' : ''} ativo${problemCount > 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(
              level,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: color,
          ),
        ],
      ),
    );
  }

  // ✅ PROBLEMAS POR TIPO
  Widget _buildProblemsByType(List<Problem> problems) {
    final typeCount = <ProblemType, int>{};

    for (var problem in problems) {
      if (problem.status != ProblemStatus.resolved) {
        typeCount[problem.type] = (typeCount[problem.type] ?? 0) + 1;
      }
    }

    final sortedTypes = typeCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Problemas por Tipo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            if (sortedTypes.isEmpty)
              Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('Sem dados para exibir')),
              )
            else
              ...sortedTypes.map((entry) {
                final type = entry.key;
                final count = entry.value;
                final percentage = (count /
                        problems
                            .where((p) => p.status != ProblemStatus.resolved)
                            .length *
                        100)
                    .toStringAsFixed(1);

                return _buildTypeItem(type, count, percentage);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeItem(ProblemType type, int count, String percentage) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              Problem.typeToString(type),
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
          ),
          SizedBox(width: 8),
          Text(
            '$percentage%',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return '${(difference.inDays / 7).floor()}sem atrás';
    }
  }
}
