import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/journal_repository.dart';
import '../../../data/repositories/media_repository.dart';
import '../../../data/repositories/stats_repository.dart';
import '../../../data/services/openai_service.dart';

/// FR8 — AI chatbot. Memory-only: messages live in `_messages` only;
/// closing the bottom sheet drops the conversation. OpenAI receives a
/// fresh system prompt on every send so the bot reflects the user's latest
/// journal moods + media stats (not a snapshot from when the sheet opened).
class ChatBot extends ConsumerStatefulWidget {
  const ChatBot({super.key});

  @override
  ConsumerState<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends ConsumerState<ChatBot> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<({String role, String text})> _messages = [];
  bool _sending = false;
  String? _lastError;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add((role: 'user', text: text));
      _sending = true;
      _lastError = null;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final reply = await ref.read(openaiServiceProvider).sendMessage(
            systemPrompt: _buildSystemPrompt(),
            history: _messages.sublist(0, _messages.length - 1),
            userMessage: text,
          );
      if (!mounted) return;
      setState(() {
        _messages.add((role: 'assistant', text: reply));
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _lastError = _classifyError(e);
      });
      _scrollToBottom();
    }
  }

  String _classifyError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('openai_api_key missing')) {
      return 'OPENAI_API_KEY not loaded. Run via ./scripts/run-dev.ps1 instead of plain flutter run.';
    }
    if (s.contains('401') ||
        s.contains('invalid_api_key') ||
        s.contains('incorrect api key')) {
      return 'API key rejected by OpenAI. Check the OPENAI_API_KEY value in .env.local.';
    }
    if (s.contains('insufficient_quota') || s.contains('billing')) {
      return 'OpenAI account has no credit. Add credits at platform.openai.com.';
    }
    if (s.contains('rate') || s.contains('429') || s.contains('quota')) {
      return 'Too many messages — wait a moment and try again.';
    }
    if (s.contains('socket') ||
        s.contains('connection') ||
        s.contains('timeout') ||
        s.contains('unreachable') ||
        s.contains('failed host lookup')) {
      return "Couldn't reach the assistant — check your connection.";
    }
    return 'Something went wrong: ${e.toString()}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  String _buildSystemPrompt() {
    final media = ref.read(mediaRepositoryProvider);
    final stats = ref.read(statsRepositoryProvider).getStats();

    final books = media.getAllBooks();
    final songs = media.getAllSongs();
    final shows = media.getAllShows();

    final topBookGenre = _topGenre(books.map((b) => b.genre));
    final topSongGenre = _topGenre(songs.map((s) => s.genre));
    final topShowGenre = _topGenre(shows.map((s) => s.genre));

    final moods = _recentMoodLabels();
    final streak = (stats?['streak'] as int?) ?? 0;

    final buf = StringBuffer();
    buf.writeln(
        "You are SoulShelf's friendly assistant. The user tracks their books,");
    buf.writeln(
        "songs, shows, journals, and daily plans in this app. Stay focused on");
    buf.writeln(
        "those topics — if asked unrelated things (politics, weather, news,");
    buf.writeln(
        "general trivia), politely redirect to media tracking, journaling,");
    buf.writeln('or planning.');
    buf.writeln();
    buf.writeln('About this user:');
    buf.write('- Books: ${books.length}');
    if (topBookGenre != null) buf.write(' (top genre: $topBookGenre)');
    buf.writeln();
    buf.write('- Songs: ${songs.length}');
    if (topSongGenre != null) buf.write(' (top genre: $topSongGenre)');
    buf.writeln();
    buf.write('- Shows: ${shows.length}');
    if (topShowGenre != null) buf.write(' (top genre: $topShowGenre)');
    buf.writeln();
    buf.writeln('- Journaling streak: $streak days');
    if (moods.isNotEmpty) {
      buf.writeln('- Recent moods (newest first): ${moods.join(", ")}');
    }
    buf.writeln();
    buf.writeln('Be conversational and concise (2–4 sentences usually).');
    buf.writeln(
        'Suggest things based on their patterns when it fits. Never reference');
    buf.writeln("data they didn't actually save.");
    return buf.toString();
  }

  static String? _topGenre(Iterable<String?> genres) {
    final counts = <String, int>{};
    for (final g in genres) {
      final t = g?.trim();
      if (t == null || t.isEmpty) continue;
      counts[t] = (counts[t] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Most recent up-to-7 journal mood labels, newest first. Skips entries
  /// with mood == 0 (unset).
  List<String> _recentMoodLabels() {
    final entries = ref.read(journalRepositoryProvider).getAllEntries();
    final sorted = [...entries]
      ..sort((a, b) => b.value.updatedAt.compareTo(a.value.updatedAt));
    return sorted
        .where((e) => e.value.mood > 0)
        .take(7)
        .map((e) => _moodLabel(e.value.mood))
        .toList(growable: false);
  }

  static String _moodLabel(int m) => switch (m) {
        1 => 'very low',
        2 => 'low',
        3 => 'neutral',
        4 => 'good',
        5 => 'great',
        _ => 'unspecified',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/chat_bg.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'AI Assistant',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: _messages.isEmpty && !_sending
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            "Ask me about your books, songs, shows, or "
                            'journal — I see your saved data.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.black54, fontSize: 14),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _messages.length +
                            (_sending ? 1 : 0) +
                            (_lastError != null ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i < _messages.length) {
                            final msg = _messages[i];
                            return _MessageBubble(
                              text: msg.text,
                              isUser: msg.role == 'user',
                            );
                          }
                          if (_sending && i == _messages.length) {
                            return const _TypingBubble();
                          }
                          return _ErrorBubble(text: _lastError!);
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_sending,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: 'Ask me something...',
                          contentPadding: const EdgeInsets.all(12),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.85),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      onPressed: _sending ? null : _send,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE5E5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE57373)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, size: 18, color: Color(0xFFC62828)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(color: Color(0xFFC62828)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Thinking…',
                style: TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
