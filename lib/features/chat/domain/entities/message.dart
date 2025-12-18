import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String content;
  final String username;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.content,
    required this.username,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [id, content, username, timestamp];
}
