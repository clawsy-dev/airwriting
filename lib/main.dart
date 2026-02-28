import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/camera_draw_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
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
        colorScheme: const ColorScheme.dark(primary: Colors.cyanAccent),
      ),
      home: const _PermissionGate(),
    );
  }
}

class _PermissionGate extends StatefulWidget {
  const _PermissionGate();

  @override
  State<_PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<_PermissionGate> {
  bool _loading = true;
  List<CameraDescription> _cameras = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() { _loading = false; _error = 'Camera permission denied'; });
      return;
    }
    try {
      _cameras = await availableCameras();
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _loading = false; _error = 'Camera error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
    );
    if (_error != null) return Scaffold(
      body: Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),
    );
    return CameraDrawScreen(cameras: _cameras);
  }
}
