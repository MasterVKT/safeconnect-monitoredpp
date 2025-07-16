// Importez les services
import 'package:monitored_app/core/services/websocket_service.dart';
import 'package:monitored_app/core/services/battery_monitor_service.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitored_app/core/models/user.dart';
import 'package:monitored_app/features/auth/models/auth_models.dart';
import 'package:monitored_app/features/auth/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return locator<AuthRepository>();
});

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel(ref.watch(authRepositoryProvider));
});

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthViewModel(this._repository) : super(AuthState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = AuthState.loading();
    
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<AuthResult> pairDevice(String pairingCode) async {
    state = AuthState.loading();
    
    final result = await _repository.pairDevice(pairingCode);
    
    result.when(
      success: (user) {
        if (user != null) {
          state = AuthState.authenticated(user);
          
          // Initialiser les services de connectivité
          locator<WebSocketService>().connect();
          locator<BatteryMonitorService>().startMonitoring();
        } else {
          state = AuthState.unauthenticated();
        }
      },
      error: (message, _) {
        state = AuthState.error(message);
      },
    );
    
    return result;
  }

  Future<void> signOut() async {
    // Arrêter les services avant la déconnexion
    locator<WebSocketService>().disconnect();
    locator<BatteryMonitorService>().stopMonitoring();
    
    await _repository.signOut();
    state = AuthState.unauthenticated();
  }
}

// Auth State
abstract class AuthState {
  const AuthState();

  factory AuthState.initial() = AuthStateInitial;
  factory AuthState.loading() = AuthStateLoading;
  factory AuthState.authenticated(User user) = AuthStateAuthenticated;
  factory AuthState.unauthenticated() = AuthStateUnauthenticated;
  factory AuthState.error(String message) = AuthStateError;

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(User user) authenticated,
    required T Function() unauthenticated,
    required T Function(String message) error,
  }) {
    if (this is AuthStateInitial) {
      return initial();
    } else if (this is AuthStateLoading) {
      return loading();
    } else if (this is AuthStateAuthenticated) {
      return authenticated((this as AuthStateAuthenticated).user);
    } else if (this is AuthStateUnauthenticated) {
      return unauthenticated();
    } else if (this is AuthStateError) {
      return error((this as AuthStateError).message);
    }
    
    throw Exception('Unknown state');
  }

  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(User user)? authenticated,
    T Function()? unauthenticated,
    T Function(String message)? error,
    required T Function() orElse,
  }) {
    if (this is AuthStateInitial && initial != null) {
      return initial();
    } else if (this is AuthStateLoading && loading != null) {
      return loading();
    } else if (this is AuthStateAuthenticated && authenticated != null) {
      return authenticated((this as AuthStateAuthenticated).user);
    } else if (this is AuthStateUnauthenticated && unauthenticated != null) {
      return unauthenticated();
    } else if (this is AuthStateError && error != null) {
      return error((this as AuthStateError).message);
    }
    
    return orElse();
  }
}

class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

class AuthStateAuthenticated extends AuthState {
  final User user;
  
  const AuthStateAuthenticated(this.user);
}

class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

class AuthStateError extends AuthState {
  final String message;
  
  const AuthStateError(this.message);
}