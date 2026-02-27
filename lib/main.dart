import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/draw_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AirWritingApp());
}

class AirWritingApp extends StatelessWidget {
  const AirWritingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AirWriting',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.purpleAccent,
        ),
        sliderTheme: SliderThemeData(
          thumbColor: Colors.cyanAccent,
          overlayColor: Colors.cyanAccent.withOpacity(0.2),
        ),
      ),
      home: const DrawScreen(),
    );
  }
}
