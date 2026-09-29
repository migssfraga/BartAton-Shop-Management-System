import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/app_drawer.dart';
import '../services/user_service.dart';

class CustomerChatScreen extends StatefulWidget {
  const CustomerChatScreen({super.key});

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _displayName = 'User';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await UserService().getCurrentUserData();
    if (mounted && userData != null) {
      setState(() {
        _displayName = userData['displayName'] ?? 'Customer';
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final messageData = {
      'text': text,
      'senderId': user.uid,
      'senderName': _displayName,
      'isAdmin': false,
      'timestamp': FieldValue.serverTimestamp(),
    };

    _messageController.clear();

    // Add to messages subcollection
    await _firestore
        .collection('chats')
        .doc(user.uid)
        .collection('messages')
        .add(messageData);

    // Update parent doc for admin list
    await _firestore.collection('chats').doc(user.uid).set({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'customerName': _displayName,
      'customerId': user.uid,
      'unreadByAdmin': FieldValue.increment(1),
    }, SetOptions(merge: true));

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
    final user = _auth.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Please login')));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: 'Chat with Admin',
        showBackButton: true,
        onBackTap: () => Navigator.of(context).pushReplacementNamed('/customer'),
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      drawer: AppDrawer(
        items: customerNav,
        activeRoute: '/customer/chat',
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chats')
                    .doc(user.uid)
                    .collection('messages')
                    .orderBy('timestamp', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.gold));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  
                  // Scroll to bottom when new messages arrive
                  if (docs.isNotEmpty) {
                    _scrollToBottom();
                  }

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, color: Colors.white.withOpacity(0.1), size: 60),
                          const SizedBox(height: 16),
                          Text('No messages yet.\nStart a conversation with Admin!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14)),
                        ],
                      ),
                    );
                  }

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
                        alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isAdmin ? AppColors.surface : AppColors.gold,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft: Radius.circular(isAdmin ? 2 : 12),
                              bottomRight: Radius.circular(isAdmin ? 12 : 2),
                            ),
                            border: isAdmin ? Border.all(color: AppColors.border) : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                text,
                                style: TextStyle(
                                  color: isAdmin ? AppColors.white : AppColors.background,
                                  fontSize: 13.5,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(timestamp),
                                style: TextStyle(
                                  color: isAdmin ? const Color(0xFF7A7E9E) : AppColors.background.withOpacity(0.6),
                                  fontSize: 10,
                                ),
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
            // ---- Message input ----
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
