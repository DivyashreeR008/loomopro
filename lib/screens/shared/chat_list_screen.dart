
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:loomopro/models/artisan_model.dart';
import 'package:loomopro/models/chat_room_model.dart';
import 'package:loomopro/screens/shared/chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final DatabaseReference _chatRoomsRef = FirebaseDatabase.instance.ref('chat_rooms');

  Future<Map<String, String>> _getParticipantDetails(ChatRoom chatRoom) async {
    final otherUserId = chatRoom.participants.firstWhere((id) => id != _currentUserId, orElse: () => '');
    if (otherUserId.isEmpty) return {'name': 'Unknown User', 'imageUrl': ''};

    var snapshot = await FirebaseDatabase.instance.ref('artisans/$otherUserId').get();
    if (snapshot.exists) {
      final artisan = Artisan.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
      return {'name': artisan.name, 'imageUrl': artisan.profilePictureUrl ?? ''};
    }
    
    // In a future step, you would also check a 'customers' node.
    // For now, we can assume the other user is a customer if not an artisan.
    // We can get their phone number from the auth object if needed.
    return {'name': 'Customer', 'imageUrl': ''};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _chatRoomsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load chats.'));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text('You have no active conversations.'),
            );
          }

          final allChatRoomsMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          // Client-side filter: Find all chat rooms where the current user is a participant.
          final userChatRooms = allChatRoomsMap.entries
              .map((entry) => ChatRoom.fromMap(Map<String, dynamic>.from(entry.value)))
              .where((room) => room.participants.contains(_currentUserId))
              .toList();

          if (userChatRooms.isEmpty) {
            return const Center(
              child: Text('You have no active conversations.'),
            );
          }

          userChatRooms.sort((a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp));

          return ListView.builder(
            itemCount: userChatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = userChatRooms[index];
              return FutureBuilder<Map<String, String>>(
                future: _getParticipantDetails(chatRoom),
                builder: (context, detailSnapshot) {
                  if (!detailSnapshot.hasData) {
                    return const ListTile(title: Text('Loading chat...'));
                  }
                  final participantDetails = detailSnapshot.data!;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: participantDetails['imageUrl']!.isNotEmpty
                          ? NetworkImage(participantDetails['imageUrl']!)
                          : null,
                      child: participantDetails['imageUrl']!.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      participantDetails['name']!,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      chatRoom.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatRoomId: chatRoom.chatRoomId,
                          recipientName: participantDetails['name']!,
                        ),
                      ));
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
