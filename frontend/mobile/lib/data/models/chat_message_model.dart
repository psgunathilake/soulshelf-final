enum ChatSender { user, bot }

class ChatMessageModel {
  final String id;
  final ChatSender sender;
  final String text;
  final DateTime timestamp;

  const ChatMessageModel({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender.name,
        'text': text,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  Map<String, dynamic> toHive() => toJson();

  factory ChatMessageModel.fromJson(Map<String, dynamic> j) => ChatMessageModel(
        id: j['id'] as String,
        sender: ChatSender.values.byName(j['sender'] as String),
        text: j['text'] as String,
        timestamp: DateTime.fromMillisecondsSinceEpoch(j['timestamp'] as int),
      );

  factory ChatMessageModel.fromHive(Map map) =>
      ChatMessageModel.fromJson(Map<String, dynamic>.from(map));

  ChatMessageModel copyWith({
    String? id,
    ChatSender? sender,
    String? text,
    DateTime? timestamp,
  }) =>
      ChatMessageModel(
        id: id ?? this.id,
        sender: sender ?? this.sender,
        text: text ?? this.text,
        timestamp: timestamp ?? this.timestamp,
      );
}
