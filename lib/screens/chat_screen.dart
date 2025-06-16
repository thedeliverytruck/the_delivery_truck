import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_app_bar.dart';

class ChatScreen extends StatefulWidget {
  final String jobId;
  final String recipientName;
  final String recipientPhone;

  const ChatScreen({
    super.key,
    required this.jobId,
    required this.recipientName,
    required this.recipientPhone,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _auth = FirebaseAuth.instance;
  late String _currentUserId;
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.currentUser?.uid ?? '';
    _controller.addListener(_handleTyping);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTyping);
    _controller.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _handleTyping() {
    if (!_isTyping) {
      _isTyping = true;
      _setTypingStatus(true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      _setTypingStatus(false);
    });
  }

  void _setTypingStatus(bool isTyping) {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.jobId)
        .collection('typing')
        .doc(_currentUserId)
        .set({'isTyping': isTyping});
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    _setTypingStatus(false);

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.jobId)
        .collection('messages')
        .add({
      'senderId': _currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'reaction': null,
    });
  }

  void _callRecipient() async {
    final uri = Uri.parse('tel:${widget.recipientPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer')),
      );
    }
  }

  void _addReaction(DocumentReference messageRef) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['👍', '❤️', '😂', '😮', '😢', '👏'].map((emoji) {
            return GestureDetector(
              onTap: () {
                messageRef.update({'reaction': emoji});
                Navigator.pop(context);
              },
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${time.month}/${time.day}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.jobId)
        .collection('messages')
        .orderBy('timestamp');

    final typingRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.jobId)
        .collection('typing');

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        title: 'Chat with ${widget.recipientName}',
        showBackButton: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messageRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messages.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == _currentUserId;
                    final timestamp = msg['timestamp'] as Timestamp?;
                    final reaction = msg['reaction'] as String?;

                    return GestureDetector(
                      onLongPress: () => _addReaction(msg.reference),
                      child: Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blueAccent : Colors.grey[800],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg['text'] ?? '',
                                style: const TextStyle(fontSize: 16, color: Colors.white),
                              ),
                              if (reaction != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(reaction, style: const TextStyle(fontSize: 16)),
                                ),
                              if (timestamp != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _formatTimestamp(timestamp.toDate()),
                                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: typingRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final typingUsers = snapshot.data!.docs.where((doc) {
                return doc.id != _currentUserId && doc['isTyping'] == true;
              }).toList();

              if (typingUsers.isNotEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(left: 16, top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Typing...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const Divider(color: Colors.white24, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.yellow),
                  onPressed: _sendMessage,
                ),
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.greenAccent),
                  onPressed: _callRecipient,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
