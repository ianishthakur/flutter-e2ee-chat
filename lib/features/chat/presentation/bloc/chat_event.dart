part of 'chat_bloc.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ConnectToRoomEvent extends ChatEvent {
  final String roomId;
  final String pin;
  final String username;

  const ConnectToRoomEvent({
    required this.roomId,
    required this.pin,
    required this.username,
  });

  @override
  List<Object?> get props => [roomId, pin, username];
}

class SendMessageEvent extends ChatEvent {
  final String content;
  final String username;

  const SendMessageEvent({required this.content, required this.username});

  @override
  List<Object?> get props => [content, username];
}

class MessageReceivedEvent extends ChatEvent {
  final Message message;

  const MessageReceivedEvent({required this.message});

  @override
  List<Object?> get props => [message];
}

class UserJoinedEvent extends ChatEvent {
  final String username;

  const UserJoinedEvent({required this.username});

  @override
  List<Object?> get props => [username];
}

class UserLeftEvent extends ChatEvent {
  final String username;

  const UserLeftEvent({required this.username});

  @override
  List<Object?> get props => [username];
}

class DisconnectFromRoomEvent extends ChatEvent {
  const DisconnectFromRoomEvent();
}

final class ChatErrorEvent extends ChatEvent {
  final String message;
  const ChatErrorEvent({required this.message});

  @override
  List<Object?> get props => [message];
}
