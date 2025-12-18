import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfigs {
  static String get pusherAppId => dotenv.env['PUSHER_APP_ID'] ?? '';
  static String get pusherKey => dotenv.env['PUSHER_KEY'] ?? '';
  static String get pusherSecret => dotenv.env['PUSHER_SECRET'] ?? '';
  static String get pusherCluster => dotenv.env['PUSHER_CLUSTER'] ?? 'ap2';

  // Helper to verify all keys are loaded
  static bool get isConfigured =>
      pusherAppId.isNotEmpty && pusherKey.isNotEmpty && pusherSecret.isNotEmpty;
}
