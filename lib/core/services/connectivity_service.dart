import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus { online, offline, wifi, mobile }

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
    switch (result) {
      case ConnectivityResult.none:
        _controller.add(NetworkStatus.offline);
        break;
      case ConnectivityResult.wifi:
        _controller.add(NetworkStatus.wifi);
        break;
      case ConnectivityResult.mobile:
        _controller.add(NetworkStatus.mobile);
        break;
      default:
        _controller.add(NetworkStatus.online);
        break;
    }
  }
  
  // Vérifier l'état actuel de la connectivité
  Future<NetworkStatus> checkConnectivity() async {
    ConnectivityResult result = await _connectivity.checkConnectivity();
    switch (result) {
      case ConnectivityResult.none:
        return NetworkStatus.offline;
      case ConnectivityResult.wifi:
        return NetworkStatus.wifi;
      case ConnectivityResult.mobile:
        return NetworkStatus.mobile;
      default:
        return NetworkStatus.online;
    }
  }
  
  void dispose() {
    _controller.close();
  }
}