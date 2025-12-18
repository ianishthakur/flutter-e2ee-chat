import 'package:e2ee_chatapp/core/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/message.dart';
import '../bloc/chat_bloc.dart';

class ChatRoomScreen extends StatefulWidget {
  final String username;
  final String roomId;
  final String pin;
  final String? roomName;

  const ChatRoomScreen({
    super.key,
    required this.username,
    required this.roomId,
    required this.pin,
    this.roomName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late final ChatBloc _chatBloc;

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _chatBloc = context.read<ChatBloc>();

    context.read<ChatBloc>().add(
      ConnectToRoomEvent(
        roomId: widget.roomId,
        pin: widget.pin,
        username: widget.username,
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _chatBloc.add(SendMessageEvent(content: text, username: widget.username));
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomName ?? 'Chat Room'),
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatConnected) {
                  final userCount = state.activeUsers.length;
                  return Text(
                    '$userCount ${userCount == 1 ? 'user' : 'users'} online',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        actions: [
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              if (state is ChatConnected) {
                return IconButton(
                  icon: const Icon(Icons.people),
                  onPressed: () => _showUsersDialog(context, state.activeUsers),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatError) {
            if (state.message.contains('PIN') ||
                state.message.contains('DECRYPTION')) {
              Navigator.pop(context, false);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else if (state is ChatConnected) {
            final isNearBottom =
                _scrollController.hasClients &&
                _scrollController.position.pixels >=
                    _scrollController.position.maxScrollExtent - 200;

            if (isNearBottom) {
              _scrollToBottom();
            }
          }
        },
        builder: (context, state) {
          if (state is ChatInitial || state is ChatConnecting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Connecting to room...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          if (state is ChatConnected) {
            return Column(
              children: [
                Expanded(
                  child: state.messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: AppColors.withOpacity(
                                  AppColors.textPrimaryColor(context),
                                  0.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppColors.withOpacity(
                                        AppColors.textPrimaryColor(context),
                                        0.5,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Send a message to start the conversation',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.withOpacity(
                                        AppColors.textPrimaryColor(context),
                                        0.3,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final message = state.messages[index];
                            final isMe = message.username == widget.username;
                            final showDateHeader =
                                index == 0 ||
                                !_isSameDay(
                                  state.messages[index - 1].timestamp,
                                  message.timestamp,
                                );

                            return Column(
                              children: [
                                if (showDateHeader)
                                  _buildDateHeader(message.timestamp),
                                _buildMessageBubble(message, isMe),
                              ],
                            );
                          },
                        ),
                ),
                _buildMessageInput(),
              ],
            );
          }

          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == yesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMM dd, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.dividerColor(context))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondaryColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.dividerColor(context))),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  message.username,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.bubbleSent
                    : AppColors.bubbleReceivedColor(context),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe
                          ? AppColors.textOnPrimary
                          : AppColors.textPrimaryColor(context),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      color: isMe
                          ? AppColors.withOpacity(AppColors.textOnPrimary, 0.7)
                          : AppColors.withOpacity(
                              AppColors.textPrimaryColor(context),
                              0.5,
                            ),
                      fontSize: 11,
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

  void _showUsersDialog(BuildContext context, List<String> users) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Users'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final isCurrentUser = user == widget.username;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    user[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.textOnPrimary),
                  ),
                ),
                title: Text(user),
                trailing: isCurrentUser
                    ? Chip(
                        label: const Text(
                          'You',
                          style: TextStyle(fontSize: 12),
                        ),
                        backgroundColor: AppColors.primary,
                        labelStyle: const TextStyle(
                          color: AppColors.textOnPrimary,
                        ),
                      )
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor(context),
        boxShadow: [
          BoxShadow(
            color: AppColors.withOpacity(AppColors.textPrimary, 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerColor(context),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: _sendMessage,
              mini: true,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.send, color: AppColors.textOnPrimary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatBloc.add(DisconnectFromRoomEvent());
    super.dispose();
  }
}
