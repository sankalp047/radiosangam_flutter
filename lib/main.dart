import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'src/services/radio_service.dart';
import 'src/pages/splash_page.dart';
import 'src/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init background audio ONCE before runApp (per docs).
  await JustAudioBackground.init(
    androidNotificationChannelId: 'radio_sangam_playback',
    androidNotificationChannelName: 'Radio Sangam Playback',
    androidNotificationOngoing: true,
  );

  // Optional: ensure the service singleton is created early.
  RadioService.instance.init();

  runApp(const RadioSangamApp());
}

class RadioSangamApp extends StatelessWidget {
  const RadioSangamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radio Sangam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      routes: {
        '/': (_) => const SplashPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}
