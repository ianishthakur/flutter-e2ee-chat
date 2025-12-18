import '../entities/message.dart';

abstract class ChatRepository {
  Stream<Message> get messageStream;
  Stream<String> get userJoinedStream;
  Stream<String> get userLeftStream;

  Future<void> connect({
    required String roomId,
    required String pin,
    required String username,
  });

  Future<void> sendMessage({required String content, required String username});

  Future<void> disconnect();
}
