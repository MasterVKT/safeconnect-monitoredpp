import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus { online, offline }

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<NetworkStatus> _controller = StreamController<NetworkStatus>.broadcast();
  
  Stream<NetworkStatus> get status => _controller.stream;
  
  ConnectivityService() {
    // Initialiser l'état
    _init();
  }
  
  void _init() async {
    // Vérifier la connectivité au démarrage
    ConnectivityResult result = await _connectivity.checkConnectivity();
    _checkStatus(result);
    
    // Écouter les changements de connectivité
    _connectivity.onConnectivityChanged.listen((result) {
      _checkStatus(result);
    });
  }
  
  void _checkStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      _controller.add(NetworkStatus.offline);
    } else {
      _controller.add(NetworkStatus.online);
    }
  }
  
  // Vérifier l'état actuel de la connectivité
  Future<NetworkStatus> checkConnectivity() async {
    ConnectivityResult result = await _connectivity.checkConnectivity();
    return result == ConnectivityResult.none ? NetworkStatus.offline : NetworkStatus.online;
  }
  
  void dispose() {
    _controller.close();
  }
}