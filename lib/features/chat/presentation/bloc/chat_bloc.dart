import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _userJoinedSubscription;
  StreamSubscription? _userLeftSubscription;

  ChatBloc({required this.chatRepository}) : super(ChatInitial()) {
    on<ConnectToRoomEvent>(_onConnectToRoom);
    on<SendMessageEvent>(_onSendMessage);
    on<MessageReceivedEvent>(_onMessageReceived);
    on<UserJoinedEvent>(_onUserJoined);
    on<UserLeftEvent>(_onUserLeft);
    on<DisconnectFromRoomEvent>(_onDisconnectFromRoom);
    on<ChatErrorEvent>((event, emit) {
      emit(ChatError(message: event.message));
    });
  }

  Future<void> _onConnectToRoom(
    ConnectToRoomEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatConnecting());

    try {
      _cancelSubscriptions();

      await chatRepository.connect(
        roomId: event.roomId,
        pin: event.pin,
        username: event.username,
      );

      _messageSubscription = chatRepository.messageStream.listen(
        (message) {
          debugPrint('BLoC: Received message from stream: ${message.content}');
          add(MessageReceivedEvent(message: message));
        },
        onError: (error) {
          debugPrint('BLoC: Stream Error caught: $error');
          add(ChatErrorEvent(message: error.toString()));
        },
      );

      _userJoinedSubscription = chatRepository.userJoinedStream.listen((
        username,
      ) {
        add(UserJoinedEvent(username: username));
      });

      _userLeftSubscription = chatRepository.userLeftStream.listen((username) {
        add(UserLeftEvent(username: username));
      });

      emit(ChatConnected(messages: const [], activeUsers: [event.username]));
    } catch (e) {
      // Ensure streams are cancelled if connection fails
      await _cancelSubscriptions();
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatConnected) {
      try {
        await chatRepository.sendMessage(
          content: event.content,
          username: event.username,
        );
      } catch (e) {
        emit(ChatError(message: 'Failed to send message: ${e.toString()}'));
        // Restore previous state
        if (state is ChatConnected) {
          final currentState = state as ChatConnected;
          emit(currentState);
        }
      }
    }
  }

  void _onMessageReceived(MessageReceivedEvent event, Emitter<ChatState> emit) {
    if (state is ChatConnected) {
      final currentState = state as ChatConnected;

      // Add the message sender to active users if not already present
      final updatedUsers =
          currentState.activeUsers.contains(event.message.username)
          ? currentState.activeUsers
          : [...currentState.activeUsers, event.message.username];
      emit(
        currentState.copyWith(
          messages: [...currentState.messages, event.message],
          activeUsers: updatedUsers,
        ),
      );
    }
  }

  void _onUserJoined(UserJoinedEvent event, Emitter<ChatState> emit) {
    if (state is ChatConnected) {
      final currentState = state as ChatConnected;
      if (!currentState.activeUsers.contains(event.username)) {
        emit(
          currentState.copyWith(
            activeUsers: [...currentState.activeUsers, event.username],
          ),
        );
      }
    }
  }

  void _onUserLeft(UserLeftEvent event, Emitter<ChatState> emit) {
    if (state is ChatConnected) {
      final currentState = state as ChatConnected;
      emit(
        currentState.copyWith(
          activeUsers: currentState.activeUsers
              .where((user) => user != event.username)
              .toList(),
        ),
      );
    }
  }

  Future<void> _onDisconnectFromRoom(
    DisconnectFromRoomEvent event,
    Emitter<ChatState> emit,
  ) async {
    // Cancel all stream subscriptions
    await _cancelSubscriptions();

    await chatRepository.disconnect();
    emit(ChatInitial());
  }

  Future<void> _cancelSubscriptions() async {
    await _messageSubscription?.cancel();
    await _userJoinedSubscription?.cancel();
    await _userLeftSubscription?.cancel();
    _messageSubscription = null;
    _userJoinedSubscription = null;
    _userLeftSubscription = null;
  }

  @override
  Future<void> close() async {
    // Ensure they are closed when BLoC is closed
    await _cancelSubscriptions();
    await chatRepository.disconnect();
    return super.close();
  }
}
