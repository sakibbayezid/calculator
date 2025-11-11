import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(CalculatorApp());
}

class CalculatorApp extends StatefulWidget {
  @override
  _CalculatorAppState createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark);
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: CalculatorScreen(
        onThemeToggle: _toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool isDark;

  CalculatorScreen({required this.onThemeToggle, required this.isDark});

  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _input = '';
  String _output = '0';

  final List<String> _buttons = [
    'AC', '÷', '×', '⌫',
    '7', '8', '9', '−',
    '4', '5', '6', '+',
    '1', '2', '3', '=',
    '0', '.',
  ];

  void _buttonPressed(String value) {
    setState(() {
      if (value == 'AC') {
        _input = '';
        _output = '0';
      } else if (value == '⌫') {
        if (_input.isNotEmpty) {
          _input = _input.substring(0, _input.length - 1);
        }
      } else if (value == '=') {
        _calculateResult();
      } else {
        if (_isOperator(value)) {
          if (_input.isEmpty || _isOperator(_input[_input.length - 1])) {
            return;
          }
        }
        _input += value;
      }
    });
  }

  bool _isOperator(String x) {
    return ['+', '−', '×', '÷'].contains(x);
  }

  void _calculateResult() {
    try {
      String finalInput = _input
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('−', '-');

      Parser p = Parser();
      Expression exp = p.parse(finalInput);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      _output = eval.toString().replaceAll(RegExp(r"\.0+$"), '');
    } catch (e) {
      _output = 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calculator'),
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => widget.onThemeToggle(!widget.isDark),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerRight,
            child: Text(
              _input,
              style: TextStyle(fontSize: 28, color: Colors.grey),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerRight,
            child: Text(
              _output,
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(8),
              child: GridView.builder(
                itemCount: _buttons.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemBuilder: (context, index) {
                  final buttonText = _buttons[index];
                  final isOperatorButton = _isOperator(buttonText) ||
                      buttonText == '=' ||
                      buttonText == 'AC' ||
                      buttonText == '⌫';
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOperatorButton
                          ? Colors.orange
                          : Theme.of(context).colorScheme.secondaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _buttonPressed(buttonText),
                    child: Text(
                      buttonText,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
