import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      // USE ONLY FOR DEVELOPMENT/TESTING.
      ..badCertificateCallback = 
          (X509Certificate cert, String host, int port) => true;
  }
}