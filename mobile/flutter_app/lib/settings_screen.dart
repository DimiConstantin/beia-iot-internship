import 'package:flutter/material.dart';
import 'settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _hostController;
  late double _threshold;
  late int _refreshSeconds;
  late bool _darkMode;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController(text: AppSettings.backendHost);
    _threshold = AppSettings.threshold;
    _refreshSeconds = AppSettings.refreshSeconds;
    _darkMode = AppSettings.darkMode;
  }

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    AppSettings.backendHost = _hostController.text.trim();
    AppSettings.threshold = _threshold;
    AppSettings.refreshSeconds = _refreshSeconds;
    AppSettings.darkMode = _darkMode;
    await AppSettings.save();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved — restart may be needed')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // tema
          SwitchListTile(
            title: const Text('Dark mode'),
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
          const Divider(),

          // adresa backend
          const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              'Backend address',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextField(
            controller: _hostController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "10.0.7.26:5001",
            ),
          ),
          const Divider(),

          // prag
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Threshold: ${_threshold.toStringAsFixed(1)}°C',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Slider(
            min: 15,
            max: 40,
            divisions: 50,
            value: _threshold,
            label: '${_threshold.toStringAsFixed(1)}°C',
            onChanged: (v) => setState(() => _threshold = v),
          ),
          const Divider(),

          // interval refresh
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Refresh interval: $_refreshSeconds s',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Slider(
            min: 1,
            max: 30,
            divisions: 29,
            value: _refreshSeconds.toDouble(),
            label: '$_refreshSeconds s',
            onChanged: (v) => setState(() => _refreshSeconds = v.round()),
          ),
          const SizedBox(height: 24),

          ElevatedButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}
