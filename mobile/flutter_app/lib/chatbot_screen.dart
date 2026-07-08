import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'settings.dart';
import 'package:intl/intl.dart';

// Structura pentru a diferenția mesajele tale de cele ale bot-ului
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          "Hi! I'm your IoT assistant. Type 'help' to see available commands.",
      isUser: false,
    ),
  ];
  bool _isTyping = false;

  // Funcția care preia inputul și îl adaugă în UI
  void _sendMessage() {
    final text = _controller.text.trim().toLowerCase();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _controller.clear();
    
    // Trimite către logica de procesare
    _handleCommand(text);
  }

  // Logica de tip Switch-Case pentru comenzi
  Future<void> _handleCommand(String command) async {
    setState(() => _isTyping = true);
    String reply = "";

    switch (command) {
      case 'help':
        reply =
            "Supported commands:\n- 'temp' : show current temperature\n- 'status' : connection details\n- 'history' : info about latest readings";
        break;

      case 'temp':
      case 'temperature':
        try {
          final res = await http
              .get(Uri.parse(AppSettings.temperatureUrl))
              .timeout(const Duration(seconds: 5));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            // Time formatting
            final parsedTime = DateTime.parse(data['time']).toLocal();
            final formattedTime = DateFormat(
              'HH:mm:ss on dd/MM/yyyy',
            ).format(parsedTime);

            reply =
                "The reported temperature is ${data['temperature']}°C (updated at $formattedTime).";
          } else {
            reply = "Error reading sensor (Code: ${res.statusCode}).";
          }
        } catch (e) {
          reply = "Backend is not responding. Check your connection.";
        }
        break;

      case 'status':
        reply =
            "🔗 Connected to: ${AppSettings.backendHost}\n⚠️ Alert threshold: ${AppSettings.threshold}°C\n⏱️ Refresh: ${AppSettings.refreshSeconds}s";
        break;

      case 'history':
        try {
          final res = await http
              .get(Uri.parse(AppSettings.historyUrl))
              .timeout(const Duration(seconds: 5));
          if (res.statusCode == 200) {
            final List<dynamic> data = jsonDecode(res.body);
            if (data.isEmpty) {
              reply = "No readings found in the database.";
            } else {
              // Time formatting
              final parsedTime = DateTime.parse(data.first['time']).toLocal();
              final formattedTime = DateFormat(
                'HH:mm:ss on dd/MM/yyyy',
              ).format(parsedTime);

              reply =
                  "There are ${data.length} recent readings stored. The latest record is from $formattedTime.";
            }
          } else {
            reply = "Could not access history.";
          }
        } catch (e) {
          reply = "Network error reaching backend.";
        }
        break;

      default:
        reply = "Command not recognized. Type 'help' for a valid list.";
    }

    // Show bot response
    setState(() {
      _messages.add(ChatMessage(text: reply, isUser: false));
      _isTyping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Chatbot'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Zona cu bulele de chat
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? const Color(0xFF028090) : Colors.grey[800],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: msg.isUser ? const Radius.circular(20) : const Radius.circular(0),
                        bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(20),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          // Indicator vizual în timp ce bot-ul face request-ul HTTP
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          // Câmpul de input și butonul de send
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Type a command...",
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF028090),
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}