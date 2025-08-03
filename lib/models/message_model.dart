
class Message {
  final String messageId;
  final String senderId;
  final String text;
  final DateTime timestamp;

  Message({
    required this.messageId,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

   Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      messageId: map['messageId'],
      senderId: map['senderId'],
      text: map['text'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
