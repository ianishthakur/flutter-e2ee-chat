import 'package:e2ee_chatapp/core/services/encryption_services.dart';
import 'package:e2ee_chatapp/features/chat/data/datasources/pusher_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/presentation/bloc/chat_bloc.dart';
import 'features/chat/presentation/pages/username_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // NOTE: HttpOverrides is only used for local development
  // with self-signed certificates. Disabled for production security.
  // HttpOverrides.global = MyHttpOverrides();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(
        chatRepository: ChatRepositoryImpl(
          pusherService: PusherService(),
          encryptionService: EncryptionService(),
        ),
      ),
      child: MaterialApp(
        title: 'E2EE Chat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.dmSansTextTheme(),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            brightness: Brightness.dark,
          ),
          textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const UsernameScreen(),
      ),
    );
  }
}
