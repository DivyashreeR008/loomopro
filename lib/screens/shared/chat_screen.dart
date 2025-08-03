
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:loomopro/models/message_model.dart';
import 'package:loomopro/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String recipientName;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.recipientName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _chatService = ChatService();
  final _currentUser = FirebaseAuth.instance.currentUser;

  void _sendMessage() {
    _chatService.sendMessage(widget.chatRoomId, _messageController.text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _chatService.getMessagesStream(widget.chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('Say hello!'));
                }
                final messagesMap = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final messages = messagesMap.entries.map((e) {
                  return Message.fromMap(Map<String, dynamic>.from(e.value));
                }).toList();
                messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUser!.uid;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey[300],
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24.0)),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
