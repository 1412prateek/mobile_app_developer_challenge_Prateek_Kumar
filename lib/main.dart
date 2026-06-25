import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/story_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(
    const ProviderScope(
      child: PebloApp(),
    ),
  );
}

class PebloApp extends StatelessWidget {
  const PebloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peblo Story Buddy',
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: false, // i just checked after the release version latency and performance
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Outfit', // Uses bundled local Outfit asset
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo,
          secondary: Colors.amber,
          background: Colors.indigo.shade50,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
      home: const StoryPage(),
    );
  }
}
