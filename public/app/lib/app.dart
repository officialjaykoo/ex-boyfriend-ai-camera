import 'package:flutter/material.dart';

import 'screens/camera_screen.dart';

class ExbfCameraApp extends StatelessWidget {
  const ExbfCameraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ex-Boyfriend Camera',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xfff06ab7)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const CameraScreen(),
    );
  }
}
