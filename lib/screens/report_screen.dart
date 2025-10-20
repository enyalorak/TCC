// ✅ REPORTSCREEN MELHORADA - TÍTULO INTELIGENTE

import 'package:flutter/material.dart';
import '../models/problem.dart';
import '../services/database_service.dart';

class ReportScreen extends StatefulWidget {
  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController =
      TextEditingController(); // ✅ Controller para o título

  String _title = '';
  String _description = '';
  ProblemType _selectedType = ProblemType.other;
  ProblemSeverity _selectedSeverity = ProblemSeverity.medium;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // ✅ SUGERIR TÍTULO AUTOMATICAMENTE BASEADO NO TIPO
  void _suggestTitle(String address) {
    if (_titleController.text.isEmpty ||
        _titleController.text.contains(Problem.typeToString(_selectedType))) {
      // ✅ ENCURTAR O ENDEREÇO PARA CABER NO LIMITE
      String location = address.split(' - ')[0]; // Pegar só o bairro

      // Se ainda for muito longo, pegar apenas a rua principal
      if (location.length > 40) {
        // Extrair apenas o nome da rua (antes da vírgula)
        location = location.split(',')[0];

        // Se ainda for longo, cortar
        if (location.length > 40) {
          location = location.substring(0, 37) + '...';
        }
      }

      final suggestedTitle =
          '${Problem.typeToString(_selectedType)} - $location';

      setState(() {
        _titleController.text = suggestedTitle;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Receber dados da localização
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final double latitude = args['latitude'];
    final double longitude = args['longitude'];
    final String address = args['address'] ?? 'Localização selecionada';

    return Scaffold(
      appBar: AppBar(
        title: Text('Reportar Problema'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CARD DE LOCALIZAÇÃO
              Card(
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.red, size: 24),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Localização',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        address,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // TIPO DE PROBLEMA
              Text(
                'Tipo de Problema *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonFormField<ProblemType>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: ProblemType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          _getTypeIcon(type),
                          SizedBox(width: 8),
                          Text(Problem.typeToString(type)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                      _suggestTitle(address); // ✅ Sugerir título ao mudar tipo
                    });
                  },
                ),
              ),

              SizedBox(height: 20),

              // GRAVIDADE
              Text(
                'Gravidade *',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              SegmentedButton<ProblemSeverity>(
                segments: [
                  ButtonSegment(
                    value: ProblemSeverity.low,
                    label: Text('Baixa'),
                    icon:
                        Icon(Icons.circle, color: Colors.yellow[700], size: 16),
                  ),
                  ButtonSegment(
                    value: ProblemSeverity.medium,
                    label: Text('Média'),
                    icon: Icon(Icons.circle, color: Colors.orange, size: 16),
                  ),
                  ButtonSegment(
                    value: ProblemSeverity.high,
                    label: Text('Alta'),
                    icon: Icon(Icons.circle, color: Colors.red, size: 16),
                  ),
                ],
                selected: {_selectedSeverity},
                onSelectionChanged: (Set<ProblemSeverity> selected) {
                  setState(() {
                    _selectedSeverity = selected.first;
                  });
                },
              ),

              SizedBox(height: 20),

              // ✅ TÍTULO MELHORADO COM SUGESTÕES
              Row(
                children: [
                  Text(
                    'Título do Problema *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  // ✅ BOTÃO PARA AUTO-PREENCHER
                  TextButton.icon(
                    onPressed: () => _suggestTitle(address),
                    icon: Icon(Icons.auto_awesome, size: 16),
                    label: Text('Sugerir', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                      padding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              TextFormField(
                controller: _titleController, // ✅ Usar controller
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: 'Ex: Buraco grande, Semáforo quebrado',
                  helperText: '💡 Seja breve e objetivo (3-8 palavras)',
                  helperStyle: TextStyle(color: Colors.blue[700]),
                  prefixIcon: Icon(Icons.title),
                  counterText: '', // Remover contador padrão
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, informe um título';
                  }
                  if (value.trim().length < 5) {
                    return 'Título muito curto (mínimo 5 caracteres)';
                  }
                  if (value.trim().length > 60) {
                    return 'Título muito longo (máximo 60 caracteres)';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _title = value;
                  });
                },
                onSaved: (value) => _title = value!.trim(),
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
              ),

              // ✅ CONTADOR CUSTOMIZADO E EXEMPLOS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Exemplos: "${_getTitleExample(_selectedType)}"',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Text(
                    '${_titleController.text.length}/60',
                    style: TextStyle(
                      fontSize: 12,
                      color: _titleController.text.length > 60
                          ? Colors.red
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // DESCRIÇÃO MELHORADA
              Text(
                'Descrição (opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText:
                      'Adicione detalhes que ajudem a identificar o problema...',
                  helperText: '📝 Quanto mais detalhes, melhor!',
                  helperStyle: TextStyle(color: Colors.grey[600]),
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.description),
                  ),
                ),
                maxLines: 4,
                maxLength: 500,
                onSaved: (value) => _description = value?.trim() ?? '',
                textCapitalization: TextCapitalization.sentences,
              ),

              SizedBox(height: 16),

              // ✅ DICA MELHORADA
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.blue[100]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tips_and_updates,
                            color: Colors.blue[700], size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Dicas para um bom relato:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    _buildTip('Use um título claro e direto'),
                    _buildTip('Indique pontos de referência se possível'),
                    _buildTip('Seu relato ajuda toda a comunidade'),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // BOTÃO ENVIAR
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _submitReport(latitude, longitude, address),
                  icon: _isSubmitting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.send, size: 24),
                  label: Text(
                    _isSubmitting ? 'Enviando...' : 'Enviar Problema',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                ),
              ),

              SizedBox(height: 12),

              // BOTÃO CANCELAR
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                  label: Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ WIDGET PARA DICAS
  Widget _buildTip(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.blue[700], fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.blue[900]),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ EXEMPLOS DE TÍTULO POR TIPO
  String _getTitleExample(ProblemType type) {
    switch (type) {
      case ProblemType.traffic_light:
        return 'Semáforo quebrado na esquina';
      case ProblemType.pothole:
        return 'Buraco grande na pista direita';
      case ProblemType.traffic_jam:
        return 'Trânsito parado no horário de pico';
      case ProblemType.accident:
        return 'Acidente com vítimas';
      case ProblemType.construction:
        return 'Obra bloqueando a via';
      case ProblemType.signage:
        return 'Placa de PARE caída';
      case ProblemType.other:
        return 'Problema na via pública';
    }
  }

  // SALVAR NO FIREBASE
  Future<void> _submitReport(
      double latitude, double longitude, String address) async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
    });

    try {
      // ✅ Se título estiver vazio, gerar automaticamente
      if (_title.isEmpty) {
        _title = _titleController.text.trim();
      }

      // ✅ Fallback: se ainda estiver vazio, usar tipo + local
      if (_title.isEmpty) {
        final location = address.split(' - ')[0];
        _title = '${Problem.typeToString(_selectedType)} - $location';
      }

      final problem = Problem(
        id: '',
        title: _title,
        description: _description,
        location: address,
        latitude: latitude,
        longitude: longitude,
        type: _selectedType,
        severity: _selectedSeverity,
        createdAt: DateTime.now(),
        status: ProblemStatus.pending,
        likes: 0,
        reportedBy: 'Usuário Anônimo',
      );

      print('📤 Enviando problema para o Firebase...');
      print('   Título: $_title');
      print('   Tipo: ${Problem.typeToString(_selectedType)}');

      String problemId = await DatabaseService.createProblem(problem);

      print('✅ Problema salvo com sucesso! ID: $problemId');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Problema reportado com sucesso!',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Ver no Mapa',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ),
        );

        await Future.delayed(Duration(seconds: 1));
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Erro ao salvar problema: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Erro ao enviar problema: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ÍCONES PARA CADA TIPO
  Widget _getTypeIcon(ProblemType type) {
    IconData icon;
    Color color;

    switch (type) {
      case ProblemType.traffic_light:
        icon = Icons.traffic;
        color = Colors.red;
        break;
      case ProblemType.pothole:
        icon = Icons.warning;
        color = Colors.orange;
        break;
      case ProblemType.traffic_jam:
        icon = Icons.car_crash;
        color = Colors.yellow[700]!;
        break;
      case ProblemType.accident:
        icon = Icons.local_hospital;
        color = Colors.red;
        break;
      case ProblemType.construction:
        icon = Icons.construction;
        color = Colors.orange;
        break;
      case ProblemType.signage:
        icon = Icons.signpost;
        color = Colors.blue;
        break;
      case ProblemType.other:
        icon = Icons.more_horiz;
        color = Colors.grey;
        break;
    }

    return Icon(icon, color: color, size: 20);
  }
}
