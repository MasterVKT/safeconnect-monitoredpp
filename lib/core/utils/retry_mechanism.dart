import 'dart:math';

class RetryMechanism {
  final int _maxRetries;
  final Duration _initialDelay;
  final double _backoffFactor;
  int _currentRetry = 0;
  
  RetryMechanism({
    int maxRetries = 5,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffFactor = 2.0,
  }) : 
    _maxRetries = maxRetries,
    _initialDelay = initialDelay,
    _backoffFactor = backoffFactor;
  
  bool get canRetry => _currentRetry < _maxRetries;
  
  Duration get nextDelay {
    if (_currentRetry >= _maxRetries) {
      throw Exception('Maximum retries exceeded');
    }
    
    // Calcul du délai avec backoff exponentiel et un peu de jitter
    final delay = _initialDelay.inMilliseconds * pow(_backoffFactor, _currentRetry).toInt();
    final jitter = Random().nextInt((delay * 0.1).toInt() + 1); // 10% max de jitter
    
    _currentRetry++;
    return Duration(milliseconds: delay + jitter);
  }
  
  void reset() {
    _currentRetry = 0;
  }
}