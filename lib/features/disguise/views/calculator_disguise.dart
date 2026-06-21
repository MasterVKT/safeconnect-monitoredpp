import 'package:flutter/material.dart';

class CalculatorDisguise extends StatefulWidget {
  const CalculatorDisguise({super.key});

  @override
  State<CalculatorDisguise> createState() => _CalculatorDisguiseState();
}

class _CalculatorDisguiseState extends State<CalculatorDisguise> {
  String _display = '0';
  String _previousOperand = '';
  String _operator = '';
  bool _isNewEntry = true;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Calculator'),
        backgroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildDisplay(),
          _buildButtons(),
        ],
      ),
    );
  }
  
  Widget _buildDisplay() {
    return Expanded(
      flex: 2,
      child: Container(
        width: double.infinity,
        color: Colors.black,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _display,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w300,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildButtons() {
    return Expanded(
      flex: 3,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _buildButtonRow(['C', '±', '%', '÷']),
            _buildButtonRow(['7', '8', '9', '×']),
            _buildButtonRow(['4', '5', '6', '-']),
            _buildButtonRow(['1', '2', '3', '+']),
            _buildButtonRow(['0', '', '.', '=']),
          ],
        ),
      ),
    );
  }
  
  Widget _buildButtonRow(List<String> buttons) {
    return Expanded(
      child: Row(
        children: buttons.map((button) {
          if (button.isEmpty) {
            return const Expanded(child: SizedBox());
          }
          
          return Expanded(
            flex: button == '0' ? 2 : 1,
            child: Container(
              margin: const EdgeInsets.all(4),
              child: ElevatedButton(
                onPressed: () => _onButtonPressed(button),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getButtonColor(button),
                  foregroundColor: _getButtonTextColor(button),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(button == '0' ? 50 : 100),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Container(
                  alignment: Alignment.center,
                  height: 70,
                  child: Text(
                    button,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Color _getButtonColor(String button) {
    if (['÷', '×', '-', '+', '='].contains(button)) {
      return Colors.orange;
    } else if (['C', '±', '%'].contains(button)) {
      return Colors.grey.shade600;
    } else {
      return Colors.grey.shade800;
    }
  }
  
  Color _getButtonTextColor(String button) {
    if (['C', '±', '%'].contains(button)) {
      return Colors.black;
    } else {
      return Colors.white;
    }
  }
  
  void _onButtonPressed(String button) {
    setState(() {
      switch (button) {
        case 'C':
          _clear();
          break;
        case '±':
          _toggleSign();
          break;
        case '%':
          _percentage();
          break;
        case '÷':
        case '×':
        case '-':
        case '+':
          _setOperator(button);
          break;
        case '=':
          _calculate();
          break;
        case '.':
          _addDecimal();
          break;
        default:
          _addDigit(button);
      }
    });
  }
  
  void _clear() {
    _display = '0';
    _previousOperand = '';
    _operator = '';
    _isNewEntry = true;
  }
  
  void _toggleSign() {
    if (_display != '0') {
      _display = _display.startsWith('-') 
          ? _display.substring(1)
          : '-$_display';
    }
  }
  
  void _percentage() {
    final value = double.tryParse(_display) ?? 0;
    _display = (value / 100).toString();
    _removeTrailingZeros();
  }
  
  void _setOperator(String op) {
    if (_operator.isNotEmpty && !_isNewEntry) {
      _calculate();
    }
    _operator = op;
    _previousOperand = _display;
    _isNewEntry = true;
  }
  
  void _calculate() {
    if (_operator.isEmpty || _previousOperand.isEmpty) return;
    
    final prev = double.tryParse(_previousOperand) ?? 0;
    final current = double.tryParse(_display) ?? 0;
    double result = 0;
    
    switch (_operator) {
      case '÷':
        result = current != 0 ? prev / current : 0;
        break;
      case '×':
        result = prev * current;
        break;
      case '-':
        result = prev - current;
        break;
      case '+':
        result = prev + current;
        break;
    }
    
    _display = result.toString();
    _removeTrailingZeros();
    _operator = '';
    _previousOperand = '';
    _isNewEntry = true;
  }
  
  void _addDecimal() {
    if (!_display.contains('.')) {
      _display += '.';
      _isNewEntry = false;
    }
  }
  
  void _addDigit(String digit) {
    if (_isNewEntry) {
      _display = digit;
      _isNewEntry = false;
    } else {
      if (_display.length < 10) {
        _display = _display == '0' ? digit : _display + digit;
      }
    }
  }
  
  void _removeTrailingZeros() {
    if (_display.contains('.')) {
      _display = _display.replaceAll(RegExp(r'\.?0*$'), '');
    }
    if (_display.isEmpty || _display == '-') {
      _display = '0';
    }
  }
}