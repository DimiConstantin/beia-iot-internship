import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'settings.dart'; // adauga sus, langa celelalte importuri
import 'settings_screen.dart';
import 'chatbot_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.load();
  runApp(const TelemetryApp());
}

// o inregistrare: valoare + momentul citirii
class Reading {
  final double value;
  final DateTime time;
  Reading(this.value, this.time);
}

class TelemetryApp extends StatelessWidget {
  const TelemetryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temperature Sensor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF028090),
          brightness: AppSettings.darkMode ? Brightness.dark : Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String _backendUrl = "http://10.0.7.26:5001/temperature";

  double _temperature = 22.0;
  DateTime _lastUpdate = DateTime.now();
  bool _connected = true;
  final List<Reading> _history = [];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(
      Duration(seconds: AppSettings.refreshSeconds),
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final response = await http
          .get(Uri.parse(_backendUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final temp = (data["temperature"] as num).toDouble();

        setState(() {
          _temperature = temp;
          _lastUpdate = DateTime.now();
          _connected = true;
          _history.add(Reading(temp, _lastUpdate));
          if (_history.length > 100) _history.removeAt(0);
        });
      } else {
        setState(() => _connected = false);
      }
    } catch (e) {
      setState(() => _connected = false);
    }
  }

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Main Dashboard'),
              onTap: () => Navigator.pop(context), // deja aici
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ).then(
                  (_) => setState(() {}),
                ); // reimprospateaza dashboard-ul la revenire
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Chatbot'),
              onTap: () {
                Navigator.pop(context); // Închide meniul de jos
                Navigator.push(
                  context,
                  MaterialPageRoute(
                  builder: (_) => const ChatbotScreen(),
      ),
    );
  },
),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm:ss').format(_lastUpdate);
    final chartData = _history.length > 20
        ? _history.sublist(_history.length - 20)
        : _history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Telemetry'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: _openMenu),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _statusChip(),
              const SizedBox(height: 24),
              _temperatureCard(),
              const SizedBox(height: 24),
              Expanded(child: _chartCard(chartData)),
              const SizedBox(height: 16),
              Text(
                'Last update: $timeStr',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refresh,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _statusChip() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.circle,
          size: 12,
          color: _connected ? Colors.greenAccent : Colors.redAccent,
        ),
        const SizedBox(width: 8),
        Text(
          _connected ? 'Connected' : 'Disconnected',
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _temperatureCard() {
    final over = _temperature > AppSettings.threshold;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Text(
              'Current temperature',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Text(
              '${_temperature.toStringAsFixed(1)}°C',
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: over ? Colors.redAccent : const Color(0xFF00A896),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard(List<Reading> data) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '  History',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: 15,
                  maxY: 30,
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < data.length; i++)
                          FlSpot(i.toDouble(), data[i].value),
                      ],
                      isCurved: true,
                      color: const Color(0xFF02C39A),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF02C39A).withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const String _historyUrl = "http://10.0.7.26:5001/history";

  List<Reading> _readings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(Uri.parse(_historyUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final readings = data.map((item) {
          return Reading(
            (item["temperature"] as num).toDouble(),
            DateTime.parse(item["time"]),
          );
        }).toList();

        setState(() {
          _readings = readings;
          _loading = false;
        });
      } else {
        setState(() {
          _error = "Server error: ${response.statusCode}";
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Could not load history";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadHistory, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_readings.isEmpty) {
      return const Center(child: Text('No readings yet'));
    }
    return ListView.separated(
      itemCount: _readings.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final r = _readings[index];
        final over = r.value > AppSettings.threshold;
        final timeStr = DateFormat('HH:mm:ss').format(r.time.toLocal());
        return ListTile(
          leading: Icon(
            Icons.circle,
            color: over ? Colors.redAccent : Colors.greenAccent,
            size: 16,
          ),
          title: Text('${r.value.toStringAsFixed(1)}°C'),
          subtitle: Text(timeStr),
          trailing: over
              ? const Text(
                  'Over threshold',
                  style: TextStyle(color: Colors.redAccent),
                )
              : null,
        );
      },
    );
  }
}
