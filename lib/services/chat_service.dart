
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:loomopro/models/chat_room_model.dart';
import 'package:loomopro/models/message_model.dart';

class ChatService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String getChatRoomId(String artisanId, String productId) {
    final customerId = _auth.currentUser!.uid;
    final ids = [customerId, artisanId];
    ids.sort();
    return '${ids[0]}_${ids[1]}_$productId';
  }

  Future<String> createOrGetChatRoom(String artisanId, String productId) async {
    final chatRoomId = getChatRoomId(artisanId, productId);
    final chatRoomRef = _db.child('chat_rooms/$chatRoomId');
    final customerId = _auth.currentUser!.uid;

    final snapshot = await chatRoomRef.get();
    if (!snapshot.exists) {
      final newChatRoom = ChatRoom(
        chatRoomId: chatRoomId,
        participants: [customerId, artisanId],
        lastMessage: 'Chat started.',
        lastMessageTimestamp: DateTime.now(),
        productId: productId,
      );
      await chatRoomRef.set(newChatRoom.toJson());

      // Denormalize: Add chat room reference to each user's own list
      await _db.child('user_chats/$customerId/$chatRoomId').set(true);
      await _db.child('user_chats/$artisanId/$chatRoomId').set(true);
    }
    return chatRoomId;
  }

  Future<void> sendMessage(String chatRoomId, String text) async {
    if (text.trim().isEmpty) return;

    final messageRef = _db.child('messages/$chatRoomId').push();
    final message = Message(
      messageId: messageRef.key!,
      senderId: _auth.currentUser!.uid,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    await messageRef.set(message.toJson());

    await _db.child('chat_rooms/$chatRoomId').update({
      'lastMessage': text.trim(),
      'lastMessageTimestamp': DateTime.now().toIso8601String(),
    });
  }

  Stream<DatabaseEvent> getMessagesStream(String chatRoomId) {
    return _db
        .child('messages/$chatRoomId')
        .orderByChild('timestamp')
        .onValue;
  }
  
  // This new method is more complex but necessary for a scalable chat list.
  // It listens to the user's list of chat IDs and then fetches the details for each chat.
  // For simplicity in this step, we'll use a slightly different approach on the UI side.
  // The UI will fetch the list of IDs, then fetch each room.
  Stream<DatabaseEvent> getChatListStream() {
    final userId = _auth.currentUser!.uid;
    // This points to the list of chat rooms for the current user.
    // The UI will need to handle fetching the details of each room.
    return _db.child('chat_rooms').orderByChild('participants/0').equalTo(userId).onValue;
  }
}
