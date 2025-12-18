import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:e2ee_chatapp/core/core/constants/env_configs.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:uuid/uuid.dart';

class PusherService {
  final String appId = EnvConfigs.pusherAppId;
  final String key = EnvConfigs.pusherKey;
  final String secret = EnvConfigs.pusherSecret;
  final String cluster = EnvConfigs.pusherCluster;

  PusherChannelsFlutter? _pusher;
  String? _currentChannel;
  String? _currentUsername;

  StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  StreamController<String> _userJoinedController =
      StreamController<String>.broadcast();
  StreamController<String> _userLeftController =
      StreamController<String>.broadcast();

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<String> get userJoinedStream => _userJoinedController.stream;
  Stream<String> get userLeftStream => _userLeftController.stream;

  Future<void> connect({
    required String roomId,
    required String username,
  }) async {
    _currentChannel = 'chat-$roomId';
    _currentUsername = username;

    _ensureControllersOpen();

    _pusher = PusherChannelsFlutter.getInstance();

    try {
      await _pusher!.init(
        apiKey: key,
        cluster: cluster,
        onConnectionStateChange: (currentState, previousState) {
          debugPrint('Connection state: $currentState');
        },
        onError: (message, code, error) {
          debugPrint('Pusher error: $message code: $code exception: $error');
        },
        onSubscriptionSucceeded: (channelName, data) {
          debugPrint('Subscription succeeded: $channelName');
        },
        onSubscriptionError: (message, error) {
          debugPrint('Subscription error: $message Exception: $error');
        },
      );

      await _pusher!.subscribe(
        channelName: _currentChannel!,
        onEvent: (event) {
          debugPrint('Channel event: ${event.eventName}');
          _handleEvent(event);
        },
      );

      await _pusher!.connect();
    } catch (e) {
      debugPrint('Error connecting to Pusher: $e');
      rethrow;
    }
  }

  void _ensureControllersOpen() {
    if (_messageController.isClosed) {
      _messageController = StreamController<Map<String, dynamic>>.broadcast();
    }
    if (_userJoinedController.isClosed) {
      _userJoinedController = StreamController<String>.broadcast();
    }
    if (_userLeftController.isClosed) {
      _userLeftController = StreamController<String>.broadcast();
    }
  }

  void _handleEvent(PusherEvent event) {
    if (_messageController.isClosed) {
      debugPrint('Warning: Controllers are closed, cannot process event');
      return;
    }

    try {
      if (event.eventName == 'message') {
        final data = jsonDecode(event.data);
        debugPrint('PusherService: Adding message to stream');
        _messageController.add(data);
      } else if (event.eventName == 'user-joined') {
        final data = jsonDecode(event.data);
        final joinedUsername = data['username'] as String;
        if (joinedUsername != _currentUsername) {
          _userJoinedController.add(joinedUsername);
        }
      } else if (event.eventName == 'user-left') {
        final data = jsonDecode(event.data);
        _userLeftController.add(data['username'] as String);
      }
    } catch (e) {
      debugPrint('Error handling event: $e');
    }
  }

  Future<void> _triggerEvent({
    required String eventName,
    required Map<String, dynamic> data,
  }) async {
    if (_currentChannel == null) {
      throw Exception('Not connected to a channel');
    }

    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
        .toString();
    final bodyMap = {
      'name': eventName,
      'channel': _currentChannel,
      'data': jsonEncode(data),
    };
    final body = jsonEncode(bodyMap);

    final authString =
        'POST\n/apps/$appId/events\nauth_key=$key&auth_timestamp=$timestamp&auth_version=1.0&body_md5=${md5.convert(utf8.encode(body)).toString()}';
    final authSignature = Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(authString)).toString();

    final url = Uri.parse(
      'https://api-$cluster.pusher.com/apps/$appId/events?auth_key=$key&auth_timestamp=$timestamp&auth_version=1.0&body_md5=${md5.convert(utf8.encode(body)).toString()}&auth_signature=$authSignature',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Pusher HTTP API error: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error triggering event: $e');
      rethrow;
    }
  }

  Future<void> sendMessage({
    required String content,
    required String username,
  }) async {
    final messageData = {
      'id': const Uuid().v4(),
      'message': content,
      'username': username,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _triggerEvent(eventName: 'message', data: messageData);
  }

  Future<void> announceUserJoined(String username) async {
    try {
      await _triggerEvent(
        eventName: 'user-joined',
        data: {'username': username},
      );
    } catch (e) {
      debugPrint('Error announcing user joined: $e');
    }
  }

  Future<void> announceUserLeft(String username) async {
    try {
      await _triggerEvent(eventName: 'user-left', data: {'username': username});
    } catch (e) {
      debugPrint('Error announcing user left: $e');
    }
  }

  Future<void> disconnect() async {
    if (_currentUsername != null) {
      await announceUserLeft(_currentUsername!);
    }

    if (_currentChannel != null && _pusher != null) {
      try {
        await _pusher!.unsubscribe(channelName: _currentChannel!);
      } catch (e) {
        debugPrint('Error unsubscribing: $e');
      }
    }

    if (_pusher != null) {
      try {
        await _pusher!.disconnect();
      } catch (e) {
        debugPrint('Error disconnecting: $e');
      }
    }

    _currentChannel = null;
    _currentUsername = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _messageController.close();
    await _userJoinedController.close();
    await _userLeftController.close();
  }
}
