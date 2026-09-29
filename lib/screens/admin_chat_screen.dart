import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firestore = FirebaseFirestore.instance;

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return DateFormat('h:mm a').format(date);
    }
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Admin Chat',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/admin'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: adminNav,
        activeRoute: '/admin/chat',
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Conversations',
                        style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chats')
                    .orderBy('lastMessageTime', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, color: Colors.white.withOpacity(0.1), size: 60),
                          const SizedBox(height: 16),
                          Text('No active conversations.',
                              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final customerName = data['customerName'] ?? 'Customer';
                      final customerId = data['customerId'] ?? '';
                      final lastMsg = data['lastMessage'] ?? '';
                      final time = data['lastMessageTime'] as Timestamp?;
                      final unread = data['unreadByAdmin'] ?? 0;

                      return InkWell(
                        onTap: () {
                          // Reset unread count
                          _firestore.collection('chats').doc(customerId).update({'unreadByAdmin': 0});
                          
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => _AdminChatThreadScreen(
                                customerId: customerId,
                                customerName: customerName,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.gold,
                                child: Text(
                                  customerName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                      color: AppColors.background, fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(customerName,
                                        style: const TextStyle(
                                            color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(
                                      lastMsg,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: unread > 0 ? AppColors.white : AppColors.lightGray,
                                        fontSize: 13,
                                        fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(_formatTime(time),
                                      style: const TextStyle(color: Color(0xFF7A7E9E), fontSize: 11)),
                                  const SizedBox(height: 6),
                                  if (unread > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                                      child: Text(
                                        '$unread',
                                        style: const TextStyle(
                                            color: AppColors.background, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminChatThreadScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  const _AdminChatThreadScreen({required this.customerId, required this.customerName});

  @override
  State<_AdminChatThreadScreen> createState() => _AdminChatThreadScreenState();
}

class _AdminChatThreadScreenState extends State<_AdminChatThreadScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final messageData = {
      'text': text,
      'senderId': 'admin',
      'senderName': 'Admin',
      'isAdmin': true,
      'timestamp': FieldValue.serverTimestamp(),
    };

    _messageController.clear();

    await _firestore
        .collection('chats')
        .doc(widget.customerId)
        .collection('messages')
        .add(messageData);

    await _firestore.collection('chats').doc(widget.customerId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '...';
    return DateFormat('h:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.gold,
              child: Text(widget.customerName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: AppColors.background, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(width: 10),
            Text(widget.customerName,
                style: const TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chats')
                    .doc(widget.customerId)
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isNotEmpty) _scrollToBottom();

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final isAdmin = data['isAdmin'] ?? false;
                      final text = data['text'] ?? '';
                      final timestamp = data['timestamp'] as Timestamp?;

                      return Align(
                        alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isAdmin ? AppColors.gold : AppColors.surface,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isAdmin ? 12 : 2),
                              bottomRight: Radius.circular(isAdmin ? 2 : 12),
                            ),
                            border: isAdmin ? null : Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(text,
                                  style: TextStyle(
                                      color: isAdmin ? AppColors.background : AppColors.white,
                                      fontSize: 13.5,
                                      height: 1.35)),
                              const SizedBox(height: 4),
                              Text(_formatTime(timestamp),
                                  style: TextStyle(
                                      color: isAdmin ? AppColors.background.withOpacity(0.6) : const Color(0xFF7A7E9E),
                                      fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: AppColors.white, fontSize: 13.5),
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.gold),
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _send,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                      child: const Icon(Icons.send, color: AppColors.background, size: 19),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
