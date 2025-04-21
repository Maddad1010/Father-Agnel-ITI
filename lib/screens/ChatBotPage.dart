import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  _ChatBotPageState createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  static const apiKey = "AIzaSyBT9Nj9mcNU53MOcOg8CZZQWTL4mZ5LeZI";
  final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
  bool _isTyping = false;

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;
    final message = _controller.text;

    setState(() {
      _messages.add(Message(isUser: true, message: message, date: DateTime.now()));
      _isTyping = true;
    });

    _controller.clear();

    final content = [Content.text(message)];
    final response = await model.generateContent(content);

    setState(() {
      _messages.add(Message(isUser: false, message: response.text ?? "Agnel AI: No response", date: DateTime.now()));
      _isTyping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Agnel AI Chatbot'),
        foregroundColor: Colors.white,
        backgroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF131E3A), Color(0xFF09203F)],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return Messages(
                      isUser: message.isUser,
                      message: message.message,
                      date: DateFormat('HH:mm').format(message.date),
                    );
                  },
                ),
              ),
              if (_isTyping) const ThreeDots(),
              _buildInputField(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.black54,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blueAccent,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final bool isUser;
  final String message;
  final DateTime date;

  Message({required this.isUser, required this.message, required this.date});
}

class Messages extends StatelessWidget {
  final bool isUser;
  final String message;
  final String date;

  const Messages({
    super.key,
    required this.isUser,
    required this.message,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isUser ? const Radius.circular(15) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUser ? "You" : "Agnel AI",
              style: TextStyle(
                fontSize: 12,
                color: isUser ? Colors.white70 : Colors.white60,
              ),
            ),
            const SizedBox(height: 5),
            RichText(
              text: TextSpan(
                children: _buildMessageSpans(message, isUser),
              ),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                date,
                style: TextStyle(fontSize: 10, color: isUser ? Colors.white60 : Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _buildMessageSpans(String message, bool isUser) {
    final boldStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white);
    final normalStyle = TextStyle(fontSize: 16, color: Colors.white);

    List<TextSpan> spans = [];
    RegExp regExp = RegExp(r'\\(.?)\\'); // Detects **bold text*
    int start = 0;

    for (RegExpMatch match in regExp.allMatches(message)) {
      if (match.start > start) {
        spans.add(TextSpan(text: message.substring(start, match.start), style: normalStyle));
      }
      spans.add(TextSpan(text: match.group(1), style: boldStyle)); // Apply bold formatting
      start = match.end;
    }

    if (start < message.length) {
      spans.add(TextSpan(text: message.substring(start), style: normalStyle));
    }

    return spans;
  }
}

class ThreeDots extends StatelessWidget {
  const ThreeDots({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _dot(),
          const SizedBox(width: 5),
          _dot(),
          const SizedBox(width: 5),
          _dot(),
        ],
      ),
    );
  }

  Widget _dot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.white54,
        shape: BoxShape.circle,
      ),
    );
  }
}