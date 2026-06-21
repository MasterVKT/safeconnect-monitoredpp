import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:monitored_app/app/locator.dart';
import 'package:monitored_app/core/services/stealth_service.dart';

class CalculatorDisguiseScreen extends StatefulWidget {
  const CalculatorDisguiseScreen({Key? key}) : super(key: key);

  @override
  State<CalculatorDisguiseScreen> createState() => _CalculatorDisguiseScreenState();
}

class _CalculatorDisguiseScreenState extends State<CalculatorDisguiseScreen> {
  final StealthService _stealthService = locator<StealthService>();
  
  String _display = '0';
  String _expression = '';
  bool _shouldResetDisplay = true;
  List<String> _secretSequence = [];
  final List<String> _requiredSequence = ['1', '3', '3', '7']; // Secret code: 1337
  
  @override
  void initState() {
    super.initState();
    _loadCalculatorSettings();
  }

  Future<void> _loadCalculatorSettings() async {
    try {
      final uiConfig = await _stealthService.getCurrentUIConfig();
      if (uiConfig != null && uiConfig['secret_access_pattern'] != null) {
        final pattern = uiConfig['secret_access_pattern'].toString();
        _requiredSequence.clear();
        _requiredSequence.addAll(pattern.split(''));
      }
    } catch (e) {
      debugPrint('Error loading calculator settings: $e');
    }
  }

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _display = '0';
        _expression = '';
        _shouldResetDisplay = true;
        _secretSequence.clear();
      } else if (value == '=') {
        _calculateResult();
        _shouldResetDisplay = true;
      } else if (['+', '-', '×', '÷'].contains(value)) {
        if (!_shouldResetDisplay) {
          _expression += _display + _getOperatorSymbol(value);
          _shouldResetDisplay = true;
        }
      } else {
        // Number input
        _handleNumberInput(value);
        _checkSecretSequence(value);
      }
    });

    // Haptic feedback for realistic calculator feel
    HapticFeedback.lightImpact();
  }

  void _handleNumberInput(String value) {
    if (_shouldResetDisplay) {
      _display = value;
      _shouldResetDisplay = false;
    } else {
      if (_display == '0') {
        _display = value;
      } else {
        _display += value;
      }
    }
  }

  void _checkSecretSequence(String input) {
    _secretSequence.add(input);
    
    // Keep only the last required sequence length
    if (_secretSequence.length > _requiredSequence.length) {
      _secretSequence.removeAt(0);
    }
    
    // Check if sequence matches
    if (_secretSequence.length == _requiredSequence.length) {
      bool matches = true;
      for (int i = 0; i < _requiredSequence.length; i++) {
        if (_secretSequence[i] != _requiredSequence[i]) {
          matches = false;
          break;
        }
      }
      
      if (matches) {
        _handleSecretAccess();
      }
    }
  }

  void _handleSecretAccess() {
    // Show subtle indication and navigate to real app
    HapticFeedback.mediumImpact();
    
    // Brief visual feedback
    setState(() {
      _display = 'ACCESS';
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.of(context).pushReplacementNamed('/main');
    });
  }

  String _getOperatorSymbol(String operator) {
    switch (operator) {
      case '×': return '*';
      case '÷': return '/';
      default: return operator;
    }
  }

  void _calculateResult() {
    try {
      final fullExpression = _expression + _display;
      if (fullExpression.isEmpty) return;
      
      // Simple calculation for disguise purposes
      // In a real calculator, you'd use a proper expression parser
      final result = _evaluateSimpleExpression(fullExpression);
      _display = result.toString();
      _expression = '';
    } catch (e) {
      _display = 'Error';
      _expression = '';
    }
  }

  double _evaluateSimpleExpression(String expression) {
    // Simplified calculation for demonstration
    // In production, use a proper math expression parser
    if (expression.contains('+')) {
      final parts = expression.split('+');
      return double.parse(parts[0]) + double.parse(parts[1]);
    } else if (expression.contains('-')) {
      final parts = expression.split('-');
      return double.parse(parts[0]) - double.parse(parts[1]);
    } else if (expression.contains('*')) {
      final parts = expression.split('*');
      return double.parse(parts[0]) * double.parse(parts[1]);
    } else if (expression.contains('/')) {
      final parts = expression.split('/');
      return double.parse(parts[0]) / double.parse(parts[1]);
    }
    return double.parse(expression);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Calculator'),
        backgroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Display
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Expression display
                  if (_expression.isNotEmpty)
                    Text(
                      _expression,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Main display
                  Text(
                    _display,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Button Grid
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[900],
              child: Column(
                children: [
                  _buildButtonRow(['C', '±', '%', '÷']),
                  _buildButtonRow(['7', '8', '9', '×']),
                  _buildButtonRow(['4', '5', '6', '-']),
                  _buildButtonRow(['1', '2', '3', '+']),
                  _buildLastRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonRow(List<String> buttons) {
    return Expanded(
      child: Row(
        children: buttons.map((button) => _buildButton(button)).toList(),
      ),
    );
  }

  Widget _buildLastRow() {
    return Expanded(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildButton('0'),
          ),
          Expanded(
            child: _buildButton('.'),
          ),
          Expanded(
            child: _buildButton('='),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text) {
    final isOperator = ['+', '-', '×', '÷', '='].contains(text);
    final isSpecial = ['C', '±', '%'].contains(text);
    
    Color buttonColor;
    Color textColor;
    
    if (isOperator) {
      buttonColor = Colors.orange;
      textColor = Colors.white;
    } else if (isSpecial) {
      buttonColor = Colors.grey[600]!;
      textColor = Colors.black;
    } else {
      buttonColor = Colors.grey[800]!;
      textColor = Colors.white;
    }

    return Container(
      margin: const EdgeInsets.all(1),
      child: Material(
        color: buttonColor,
        child: InkWell(
          onTap: () => _onButtonPressed(text),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}