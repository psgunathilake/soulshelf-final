import 'package:flutter/material.dart';

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> messages = [];

  void sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    String userText = _controller.text;

    setState(() {
      messages.add({"sender": "user", "text": userText});
      messages.add({"sender": "bot", "text": botReply(userText)});
    });

    _controller.clear();
  }

  String botReply(String text) {
    text = text.toLowerCase();

    if (text.contains("book")) {
      return "📚 Try reading:\n• Atomic Habits\n• Deep Work\n• The Alchemist";
    } else if (text.contains("song")) {
      return "🎵 Songs for you:\n• Perfect\n• Blinding Lights\n• Let Her Go";
    } else if (text.contains("movie") || text.contains("film")) {
      return "🎬 Movies:\n• Interstellar\n• Inception\n• The Dark Knight";
    } else if (text.contains("journal")) {
      return "📝 Journal idea:\nWhat made you smile today?";
    } else if (text.contains("quote")) {
      return "💬 \"Believe you can and you're halfway there.\"";
    } else {
      return "🤖 Ask me about books, songs, movies, quotes, or journal ideas!";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "AI Assistant",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  bool isUser = msg["sender"] == "user";

                  return Align(
                    alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.deepPurple
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        msg["text"]!,
                        style: TextStyle(
                            color: isUser ? Colors.white : Colors.black),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Ask me something...",
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
