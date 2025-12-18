part of 'chat_bloc.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatConnecting extends ChatState {}

class ChatConnected extends ChatState {
  final List<Message> messages;
  final List<String> activeUsers;

  const ChatConnected({required this.messages, required this.activeUsers});

  ChatConnected copyWith({List<Message>? messages, List<String>? activeUsers}) {
    return ChatConnected(
      messages: messages ?? this.messages,
      activeUsers: activeUsers ?? this.activeUsers,
    );
  }

  @override
  List<Object?> get props => [messages, activeUsers];
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object?> get props => [message];
}
