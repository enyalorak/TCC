// ✅ MapScreen COMPLETAMENTE INTEGRADO COM FIREBASE

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

import 'package:testetcc/services/location_service.dart';
import 'package:testetcc/models/problem.dart';
import 'package:testetcc/services/database_service.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isReportMode = false;
  LatLng? _selectedReportLocation;

  static const LatLng _colatinaMar = LatLng(-19.5407, -40.6306);

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  // ✅ STREAM DO FIREBASE
  StreamSubscription<List<Problem>>? _problemsSubscription;
  List<Problem> _allProblems = [];

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _listenToFirebaseProblems(); // ✅ Escutar problemas em tempo real
  }

  @override
  void dispose() {
    _problemsSubscription?.cancel();
    super.dispose();
  }

  // ✅ ESCUTAR PROBLEMAS DO FIREBASE EM TEMPO REAL
  void _listenToFirebaseProblems() {
    print('🔄 Iniciando escuta de problemas do Firebase...');

    _problemsSubscription = DatabaseService.getAllProblemsStream().listen(
      (problems) {
        print('📥 Recebeu ${problems.length} problemas do Firebase');

        setState(() {
          _allProblems = problems;
          _updateMapMarkers(); // ✅ Atualizar marcadores no mapa
        });
      },
      onError: (error) {
        print('❌ Erro ao escutar problemas: $error');
      },
    );
  }

  // ✅ ATUALIZAR MARCADORES DO MAPA COM DADOS DO FIREBASE
  void _updateMapMarkers() {
    print('🗺️ Atualizando marcadores no mapa...');

    // Limpar apenas marcadores de problemas (manter localização atual e seleção)
    _markers.removeWhere((marker) =>
        marker.markerId.value != 'current_location' &&
        marker.markerId.value != 'selected_location');

    // Adicionar marcadores dos problemas do Firebase
    for (final problem in _allProblems) {
      // Não mostrar problemas resolvidos
      if (problem.status == ProblemStatus.resolved) continue;

      // Escolher cor do marcador baseado na severidade
      BitmapDescriptor markerIcon;
      switch (problem.severity) {
        case ProblemSeverity.high:
          markerIcon =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
          break;
        case ProblemSeverity.medium:
          markerIcon =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
          break;
        case ProblemSeverity.low:
          markerIcon =
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
          break;
      }

      _markers.add(
        Marker(
          markerId: MarkerId(problem.id),
          position: LatLng(problem.latitude, problem.longitude),
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: problem.title,
            snippet:
                '${problem.location}\n${problem.likes} curtidas • ${_getTimeAgo(problem.createdAt)}',
          ),
          onTap: () => _showProblemDetailsBottomSheet(problem),
        ),
      );
    }

    print('✅ ${_markers.length} marcadores no mapa');
  }

  Future<void> _initializeMap() async {
    try {
      await _requestPermissions();
      await _getCurrentLocation();
    } catch (e) {
      print('Erro na inicialização: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermissions() async {
    PermissionStatus locationStatus = await Permission.location.request();
    if (locationStatus.isDenied) {
      throw Exception('Permissão de localização negada');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviço de localização desabilitado');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
      });

      _addCurrentLocationMarker();
    } catch (e) {
      print('Erro ao obter localização: $e');
      setState(() {
        _currentPosition = Position(
          latitude: _colatinaMar.latitude,
          longitude: _colatinaMar.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      });
      _addCurrentLocationMarker();
    }
  }

  void _addCurrentLocationMarker() {
    if (_currentPosition != null) {
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId('current_location'),
            position:
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
              title: 'Sua localização atual',
              snippet:
                  'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
            ),
          ),
        );

        _circles.add(
          Circle(
            circleId: CircleId('location_accuracy'),
            center:
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            radius: _currentPosition!.accuracy.clamp(10.0, 100.0),
            fillColor: Colors.blue.withOpacity(0.1),
            strokeColor: Colors.blue,
            strokeWidth: 1,
          ),
        );
      });
    }
  }

  // ✅ MOSTRAR DETALHES DO PROBLEMA EM BOTTOM SHEET
  void _showProblemDetailsBottomSheet(Problem problem) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com título e status
            Row(
              children: [
                Expanded(
                  child: Text(
                    problem.title,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(problem.status),
              ],
            ),
            SizedBox(height: 8),

            // Tipo e Severidade
            Row(
              children: [
                Chip(
                  label: Text(Problem.typeToString(problem.type)),
                  backgroundColor: Colors.blue[50],
                ),
                SizedBox(width: 8),
                Chip(
                  label: Text(Problem.severityToString(problem.severity)),
                  backgroundColor:
                      _getSeverityColor(problem.severity).withOpacity(0.2),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Descrição
            if (problem.description.isNotEmpty) ...[
              Text(
                problem.description,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
            ],

            // Informações
            _buildInfoRow(Icons.location_on, problem.location),
            _buildInfoRow(Icons.access_time, _getTimeAgo(problem.createdAt)),
            _buildInfoRow(Icons.person, problem.reportedBy),

            SizedBox(height: 16),

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await DatabaseService.likeProblem(problem.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('👍 Problema curtido!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: Icon(Icons.thumb_up),
                    label: Text('Curtir (${problem.likes})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/dashboard');
                    },
                    icon: Icon(Icons.dashboard),
                    label: Text('Dashboard'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ProblemStatus status) {
    Color color;
    String text;

    switch (status) {
      case ProblemStatus.pending:
        color = Colors.orange;
        text = 'Pendente';
        break;
      case ProblemStatus.in_progress:
        color = Colors.blue;
        text = 'Em Andamento';
        break;
      case ProblemStatus.resolved:
        color = Colors.green;
        text = 'Resolvido';
        break;
    }

    return Chip(
      label: Text(text, style: TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }

  Color _getSeverityColor(ProblemSeverity severity) {
    switch (severity) {
      case ProblemSeverity.high:
        return Colors.red;
      case ProblemSeverity.medium:
        return Colors.orange;
      case ProblemSeverity.low:
        return Colors.yellow[700]!;
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
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
    } else {
      return '${difference.inDays}d atrás';
    }
  }

  // ✅ MOSTRAR LISTA DE PROBLEMAS
  void _showProblemsListBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Problemas Ativos',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Lista de problemas
              Expanded(
                child: _allProblems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle,
                                size: 80, color: Colors.green),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum problema reportado!',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Que ótimo! Tudo tranquilo por aqui.',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _allProblems.length,
                        padding: EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final problem = _allProblems[index];

                          // Não mostrar resolvidos
                          if (problem.status == ProblemStatus.resolved) {
                            return SizedBox.shrink();
                          }

                          return Card(
                            margin: EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _showProblemDetailsBottomSheet(problem);

                                // Centralizar no problema
                                mapController?.animateCamera(
                                  CameraUpdate.newCameraPosition(
                                    CameraPosition(
                                      target: LatLng(
                                          problem.latitude, problem.longitude),
                                      zoom: 16.0,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _getSeverityColor(
                                                problem.severity),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            problem.title,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        _buildStatusChip(problem.status),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on,
                                            size: 14, color: Colors.grey[600]),
                                        SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            problem.location,
                                            style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.thumb_up,
                                            size: 14, color: Colors.blue),
                                        SizedBox(width: 4),
                                        Text('${problem.likes}',
                                            style: TextStyle(fontSize: 12)),
                                        SizedBox(width: 16),
                                        Icon(Icons.access_time,
                                            size: 14, color: Colors.grey[600]),
                                        SizedBox(width: 4),
                                        Text(
                                          _getTimeAgo(problem.createdAt),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    if (_currentPosition != null) {
      Future.delayed(Duration(seconds: 1), () {
        _centerOnCurrentLocation();
      });
    } else {
      Future.delayed(Duration(seconds: 1), () {
        mapController!.animateCamera(
          CameraUpdate.newLatLng(_colatinaMar),
        );
      });
    }
  }

  void _onMapTap(LatLng position) {
    if (_isReportMode) {
      setState(() {
        _selectedReportLocation = position;
        _markers.removeWhere(
            (marker) => marker.markerId.value == 'selected_location');

        _markers.add(
          Marker(
            markerId: MarkerId('selected_location'),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet),
            infoWindow: InfoWindow(
              title: 'Local selecionado',
              snippet: 'Toque em "Confirmar" para reportar problema aqui',
            ),
          ),
        );
      });

      _showReportConfirmation(position);
    }
  }

  void _showReportConfirmation(LatLng position) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Local selecionado para reportar problema',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text('Coordenadas:'),
                  Text(
                    'Lat: ${position.latitude.toStringAsFixed(6)}',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                  Text(
                    'Lng: ${position.longitude.toStringAsFixed(6)}',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _cancelReportMode();
                    },
                    child: Text('Cancelar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmReportLocation(position);
                    },
                    child: Text('Confirmar Local'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReportLocation(LatLng position) async {
    _cancelReportMode();

    String address = await LocationService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final result = await Navigator.pushNamed(
      context,
      '/report',
      arguments: {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
      },
    );

    // ✅ Após reportar, centralizar no novo problema
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Problema salvo! Aguarde aparecer no mapa...'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _centerOnCurrentLocation() {
    if (_currentPosition != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target:
                LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 16.0,
          ),
        ),
      );
    }
  }

  void _toggleReportMode() {
    setState(() {
      _isReportMode = !_isReportMode;

      if (!_isReportMode) {
        _selectedReportLocation = null;
        _markers.removeWhere(
            (marker) => marker.markerId.value == 'selected_location');
      }
    });
  }

  void _cancelReportMode() {
    setState(() {
      _isReportMode = false;
      _selectedReportLocation = null;
      _markers.removeWhere(
          (marker) => marker.markerId.value == 'selected_location');
    });
  }

  void _showLegendBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Legenda',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            _buildLegendItem(Colors.blue, 'Sua localização'),
            _buildLegendItem(Colors.red, 'Problema Crítico'),
            _buildLegendItem(Colors.orange, 'Problema Moderado'),
            _buildLegendItem(Colors.yellow[700]!, 'Atenção'),
            if (_isReportMode)
              _buildLegendItem(Colors.purple, 'Local selecionado'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Mapa de Trânsito - Colatina'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Carregando mapa...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: Text('Mapa de Trânsito - Colatina'),
          backgroundColor:
              _isReportMode ? Colors.orange[600] : Colors.blue[600],
          foregroundColor: Colors.white,
          actions: [
            // ✅ BOTÃO DASHBOARD
            if (!_isReportMode)
              IconButton(
                icon: Icon(Icons.dashboard),
                onPressed: () => Navigator.pushNamed(context, '/dashboard'),
                tooltip: 'Dashboard',
              ),

            if (_isReportMode)
              TextButton(
                onPressed: _cancelReportMode,
                child: Text('Cancelar', style: TextStyle(color: Colors.white)),
              )
            else
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _getCurrentLocation,
                tooltip: 'Atualizar localização',
              ),
          ],
        ),
        body: Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              onTap: _onMapTap,
              initialCameraPosition: CameraPosition(
                target: _currentPosition != null
                    ? LatLng(
                        _currentPosition!.latitude, _currentPosition!.longitude)
                    : _colatinaMar,
                zoom: 14.0,
              ),
              markers: _markers,
              circles: _circles,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
            ),

            if (_isReportMode)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.orange[600],
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Toque no mapa para selecionar o local do problema',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            // ✅ BOTÃO DE LEGENDA
            Positioned(
              top: _isReportMode ? 60 : 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'legend_button',
                mini: true,
                onPressed: _showLegendBottomSheet,
                backgroundColor: Colors.white,
                elevation: 3,
                child:
                    Icon(Icons.help_outline, color: Colors.grey[700], size: 20),
                tooltip: 'Ver legenda',
              ),
            ),

            // ✅ BOTÃO GPS - REPOSICIONADO
            if (_currentPosition != null)
              Positioned(
                top: _isReportMode ? 60 : 16,
                right: 70, // ✅ Ao lado do botão de legenda
                child: FloatingActionButton(
                  heroTag: 'gps_button',
                  mini: true,
                  onPressed: _centerOnCurrentLocation,
                  backgroundColor: Colors.blue[600],
                  child: Icon(Icons.my_location, color: Colors.white, size: 20),
                  elevation: 3,
                  tooltip: 'Centralizar no GPS',
                ),
              ),

            // ✅ CARD COM CONTADOR DINÂMICO
            Positioned(
              bottom: 60,
              left: 16,
              right: 16,
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // ✅ CLICÁVEL - MOSTRA LISTA DE PROBLEMAS
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showProblemsListBottomSheet,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${_allProblems.where((p) => p.status != ProblemStatus.resolved).length}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Problemas',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: Colors.blue[700],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currentPosition != null
                                ? Icons.gps_fixed
                                : Icons.gps_not_fixed,
                            color: _currentPosition != null
                                ? Colors.green
                                : Colors.orange,
                          ),
                          Text(
                            _currentPosition != null ? 'GPS Ativo' : 'Sem GPS',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_currentPosition != null) SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'report',
              onPressed: _isReportMode ? _cancelReportMode : _toggleReportMode,
              icon: Icon(_isReportMode ? Icons.close : Icons.add_location),
              label: Text(_isReportMode ? 'Cancelar' : 'Reportar Aqui'),
              backgroundColor:
                  _isReportMode ? Colors.grey[600] : Colors.orange[600],
            ),
            SizedBox(height: 115),
          ],
        ));
  }
}
