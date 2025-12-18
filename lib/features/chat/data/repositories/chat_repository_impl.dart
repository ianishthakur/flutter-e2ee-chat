import 'dart:async';

import 'package:e2ee_chatapp/core/services/encryption_services.dart';
import 'package:e2ee_chatapp/features/chat/data/datasources/pusher_services.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final PusherService pusherService;
  final EncryptionService encryptionService;

  // Make these late and reinitialize them on connect
  StreamController<Message> _messageController =
      StreamController<Message>.broadcast();
  StreamController<String> _userJoinedController =
      StreamController<String>.broadcast();
  StreamController<String> _userLeftController =
      StreamController<String>.broadcast();

  // Store subscriptions to cancel them later
  StreamSubscription? _messageSubscription;
  StreamSubscription? _userJoinedSubscription;
  StreamSubscription? _userLeftSubscription;

  String? _currentPin;

  ChatRepositoryImpl({
    required this.pusherService,
    required this.encryptionService,
  });

  @override
  Stream<Message> get messageStream => _messageController.stream;

  @override
  Stream<String> get userJoinedStream => _userJoinedController.stream;

  @override
  Stream<String> get userLeftStream => _userLeftController.stream;

  @override
  Future<void> connect({
    required String roomId,
    required String pin,
    required String username,
  }) async {
    _currentPin = pin;

    await _cancelSubscriptions();

    if (_messageController.isClosed) {
      _messageController = StreamController<Message>.broadcast();
    }
    if (_userJoinedController.isClosed) {
      _userJoinedController = StreamController<String>.broadcast();
    }
    if (_userLeftController.isClosed) {
      _userLeftController = StreamController<String>.broadcast();
    }

    await pusherService.connect(roomId: roomId, username: username);

    _messageSubscription = pusherService.messageStream.listen(
      (data) {
        try {
          final encryptedContent = data['message'] as String;
          final sendUsername = data['username'] as String;
          final timestamp = DateTime.parse(data['timestamp'] as String);
          final messageId = data['id'] as String;

          final decryptedContent = encryptionService.decrypt(
            encryptedContent,
            pin,
          );

          final message = MessageModel(
            id: messageId,
            content: decryptedContent,
            username: sendUsername,
            timestamp: timestamp,
          );

          debugPrint('Repo: Decrypted message added to stream: ${message.content}');

          if (!_messageController.isClosed) {
            _messageController.add(message);
          }
        } catch (e) {
          debugPrint('❌ Decryption failed: Wrong PIN');

          if (!_messageController.isClosed) {
            _messageController.add(
              MessageModel(
                id: 'error-${DateTime.now().millisecondsSinceEpoch}',
                content: '[Encrypted message - Wrong PIN]',
                username: 'System',
                timestamp: DateTime.now(),
              ),
            );

            // This is what the Bloc will catch to emit ChatError.
            _messageController.addError('DECRYPTION_FAILED_PIN');
          }
        }
      },
      onError: (error) {
        debugPrint('Stream error: $error');
      },
    );

    _userJoinedSubscription = pusherService.userJoinedStream.listen((username) {
      if (!_userJoinedController.isClosed) {
        _userJoinedController.add(username);
      }
    });

    _userLeftSubscription = pusherService.userLeftStream.listen((username) {
      if (!_userLeftController.isClosed) {
        _userLeftController.add(username);
      }
    });

    await pusherService.announceUserJoined(username);
  }

  @override
  Future<void> sendMessage({
    required String content,
    required String username,
  }) async {
    if (_currentPin == null) {
      throw Exception('Not connected to a room');
    }

    final encryptedContent = encryptionService.encrypt(content, _currentPin!);

    await pusherService.sendMessage(
      content: encryptedContent,
      username: username,
    );
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
  Future<void> disconnect() async {
    await _cancelSubscriptions();

    await pusherService.disconnect();

    _currentPin = null;
  }

  Future<void> dispose() async {
    await _cancelSubscriptions();
    await pusherService.dispose();
    await _messageController.close();
    await _userJoinedController.close();
    await _userLeftController.close();
  }
}
