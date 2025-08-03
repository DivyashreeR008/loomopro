
class ChatRoom {
  final String chatRoomId;
  final List<String> participants; // List of user UIDs
  final String lastMessage;
  final DateTime lastMessageTimestamp;
  final String productId;

  ChatRoom({
    required this.chatRoomId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    required this.productId,
  });

  Map<String, dynamic> toJson() {
    return {
      'chatRoomId': chatRoomId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp.toIso8601String(),
      'productId': productId,
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      chatRoomId: map['chatRoomId'],
      participants: List<String>.from(map['participants']),
      lastMessage: map['lastMessage'],
      lastMessageTimestamp: DateTime.parse(map['lastMessageTimestamp']),
      productId: map['productId'],
    );
  }
}
