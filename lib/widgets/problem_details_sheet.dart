import 'package:flutter/material.dart';
import '../models/problem_report.dart';
import '../services/map_service.dart';

class ProblemDetailsSheet extends StatefulWidget {
  final ProblemReport problem;

  const ProblemDetailsSheet({Key? key, required this.problem})
    : super(key: key);

  @override
  State<ProblemDetailsSheet> createState() => _ProblemDetailsSheetState();
}

class _ProblemDetailsSheetState extends State<ProblemDetailsSheet> {
  final MapService _mapService = MapService();
  final TextEditingController _commentController = TextEditingController();
  late ProblemReport _currentProblem;
  bool _hasLiked = false;

  @override
  void initState() {
    super.initState();
    _currentProblem = widget.problem;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            _buildHeader(),

            SizedBox(height: 16),

            // STATUS E MÉTRICAS
            _buildStatusRow(),

            SizedBox(height: 16),

            // DESCRIÇÃO
            _buildDescriptionCard(),

            SizedBox(height: 16),

            // INFORMAÇÕES ADICIONAIS
            _buildInfoCard(),

            SizedBox(height: 16),

            // FOTOS (se houver)
            if (_currentProblem.photoUrls.isNotEmpty) ...[
              _buildPhotosCard(),
              SizedBox(height: 16),
            ],

            // COMENTÁRIOS
            _buildCommentsSection(),

            SizedBox(height: 16),

            // AÇÕES DO USUÁRIO
            _buildActionButtons(),

            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getProblemTypeColor(_currentProblem.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getProblemIcon(_currentProblem.type),
            size: 24,
            color: _getProblemTypeColor(_currentProblem.type),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentProblem.type,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Reportado ${_formatTimestamp(_currentProblem.timestamp)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildStatusRow() {
    return Row(
      children: [
        Expanded(child: _buildStatusChip()),
        SizedBox(width: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.thumb_up, size: 16, color: Colors.blue),
              SizedBox(width: 4),
              Text(
                '${_currentProblem.likes}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.comment, size: 16, color: Colors.green),
              SizedBox(width: 4),
              Text(
                '${_currentProblem.comments.length}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    return Chip(
      avatar: Icon(
        _getStatusIcon(_currentProblem.status),
        size: 16,
        color: Colors.white,
      ),
      label: Text(
        _getStatusText(_currentProblem.status),
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: _getStatusColor(_currentProblem.status),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descrição',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _currentProblem.description,
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildInfoRow(
              'Localização',
              '${_currentProblem.latitude.toStringAsFixed(6)}, ${_currentProblem.longitude.toStringAsFixed(6)}',
            ),
            _buildInfoRow(
              'Data/Hora',
              _formatDateTime(_currentProblem.timestamp),
            ),
            _buildInfoRow(
              'Usuário',
              'Usuário #${_currentProblem.userId.substring(0, 8)}',
            ),
            if (_currentProblem.intersectionId.isNotEmpty)
              _buildInfoRow('Intersecção', _currentProblem.intersectionId),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fotos (${_currentProblem.photoUrls.length})',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Container(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _currentProblem.photoUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(right: 8),
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.image, color: Colors.grey[600]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comentários (${_currentProblem.comments.length})',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),

            // LISTA DE COMENTÁRIOS
            if (_currentProblem.comments.isNotEmpty)
              ...(_currentProblem.comments.map(
                (comment) => _buildCommentItem(comment),
              )),

            // MENSAGEM QUANDO NÃO HÁ COMENTÁRIOS
            if (_currentProblem.comments.isEmpty)
              Container(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Nenhum comentário ainda.\nSeja o primeiro a comentar!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

            SizedBox(height: 12),

            // CAMPO PARA NOVO COMENTÁRIO
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Adicione um comentário...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.blue,
                child: Text(
                  comment.userName[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  comment.userName,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Text(
                _formatTimestamp(comment.timestamp),
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(comment.text, style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _toggleLike,
            icon: Icon(_hasLiked ? Icons.thumb_up : Icons.thumb_up_outlined),
            label: Text(_hasLiked ? 'Curtido' : 'Curtir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _hasLiked ? Colors.blue : Colors.grey[200],
              foregroundColor: _hasLiked ? Colors.white : Colors.black87,
              padding: EdgeInsets.all(12),
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _shareProblem,
            icon: Icon(Icons.share),
            label: Text('Compartilhar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  // MÉTODOS DE AÇÃO

  void _toggleLike() {
    setState(() {
      if (_hasLiked) {
        _currentProblem = ProblemReport(
          id: _currentProblem.id,
          userId: _currentProblem.userId,
          intersectionId: _currentProblem.intersectionId,
          type: _currentProblem.type,
          description: _currentProblem.description,
          latitude: _currentProblem.latitude,
          longitude: _currentProblem.longitude,
          timestamp: _currentProblem.timestamp,
          photoUrls: _currentProblem.photoUrls,
          status: _currentProblem.status,
          likes: _currentProblem.likes - 1,
          comments: _currentProblem.comments,
        );
      } else {
        _currentProblem = ProblemReport(
          id: _currentProblem.id,
          userId: _currentProblem.userId,
          intersectionId: _currentProblem.intersectionId,
          type: _currentProblem.type,
          description: _currentProblem.description,
          latitude: _currentProblem.latitude,
          longitude: _currentProblem.longitude,
          timestamp: _currentProblem.timestamp,
          photoUrls: _currentProblem.photoUrls,
          status: _currentProblem.status,
          likes: _currentProblem.likes + 1,
          comments: _currentProblem.comments,
        );
      }
      _hasLiked = !_hasLiked;
    });

    // Atualizar no serviço
    _mapService.updateProblemReport(_currentProblem);

    // Mostrar feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_hasLiked ? 'Problema curtido!' : 'Like removido'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;

    Comment newComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current_user', // Em produção, usar ID do usuário logado
      userName: 'Usuário Atual', // Em produção, usar nome do usuário logado
      text: _commentController.text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      List<Comment> newComments = List.from(_currentProblem.comments);
      newComments.add(newComment);

      _currentProblem = ProblemReport(
        id: _currentProblem.id,
        userId: _currentProblem.userId,
        intersectionId: _currentProblem.intersectionId,
        type: _currentProblem.type,
        description: _currentProblem.description,
        latitude: _currentProblem.latitude,
        longitude: _currentProblem.longitude,
        timestamp: _currentProblem.timestamp,
        photoUrls: _currentProblem.photoUrls,
        status: _currentProblem.status,
        likes: _currentProblem.likes,
        comments: newComments,
      );
    });

    // Limpar campo
    _commentController.clear();

    // Atualizar no serviço
    _mapService.updateProblemReport(_currentProblem);

    // Mostrar feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Comentário adicionado!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareProblem() {
    // Implementar compartilhamento
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Funcionalidade de compartilhamento em desenvolvimento'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // MÉTODOS AUXILIARES

  IconData _getProblemIcon(String type) {
    switch (type) {
      case 'Semáforo com defeito':
        return Icons.traffic;
      case 'Buraco na via':
        return Icons.warning;
      case 'Congestionamento':
        return Icons.traffic_outlined;
      case 'Acidente':
        return Icons.car_crash;
      case 'Falta de sinalização':
        return Icons.sign_language;
      case 'Obra não sinalizada':
        return Icons.construction;
      default:
        return Icons.report_problem;
    }
  }

  Color _getProblemTypeColor(String type) {
    switch (type) {
      case 'Semáforo com defeito':
      case 'Acidente':
        return Colors.red;
      case 'Buraco na via':
      case 'Obra não sinalizada':
        return Colors.orange;
      case 'Congestionamento':
        return Colors.yellow[700]!;
      case 'Falta de sinalização':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(ProblemStatus status) {
    switch (status) {
      case ProblemStatus.pending:
        return Icons.schedule;
      case ProblemStatus.inProgress:
        return Icons.build;
      case ProblemStatus.resolved:
        return Icons.check_circle;
      case ProblemStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getStatusText(ProblemStatus status) {
    switch (status) {
      case ProblemStatus.pending:
        return 'Pendente';
      case ProblemStatus.inProgress:
        return 'Em Andamento';
      case ProblemStatus.resolved:
        return 'Resolvido';
      case ProblemStatus.rejected:
        return 'Rejeitado';
    }
  }

  Color _getStatusColor(ProblemStatus status) {
    switch (status) {
      case ProblemStatus.pending:
        return Colors.orange;
      case ProblemStatus.inProgress:
        return Colors.blue;
      case ProblemStatus.resolved:
        return Colors.green;
      case ProblemStatus.rejected:
        return Colors.red;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    Duration difference = DateTime.now().difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}min atrás';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h atrás';
    } else {
      return '${difference.inDays}d atrás';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} às ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
