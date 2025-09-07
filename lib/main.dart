import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:torudex/api/firebase_api.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:torudex/wrapper.dart';
import 'package:torudex/theme/theme_provider.dart';
import 'package:torudex/l10n/translation_service.dart';

//global object for accessing device screen size
late Size mq;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await dotenv.load();
  await Firebase.initializeApp();
  // Đăng ký background message handler
  FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

  // Init Firebase API
  final firebaseApi = FirebaseApi();
  await firebaseApi.initNotifications();
  await dotenv.load(fileName: ".env");

  await initializeDateFormatting('vi_VN', null);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const ToruDex(),
    ),
  );
}

class ToruDex extends StatelessWidget {
  const ToruDex({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GetMaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'ToruDex',
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const Wrapper(),
      locale: TranslationService.defaultLocale,
      fallbackLocale: TranslationService.fallbackLocale,
      translations: TranslationService(),
    );
  }
}
