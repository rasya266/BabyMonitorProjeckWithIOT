// ignore_for_file: duplicate_import

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:babymonitoring/baby.dart';
import 'package:babymonitoring/parent.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mengambil daftar kamera yang tersedia di perangkat
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark, // Mengubah tema menjadi abu-abu
        primaryColor: Colors.grey[800], // Ubah warna primer menjadi abu-abu tua
        scaffoldBackgroundColor:
            Colors.grey[200], // Ubah warna latar belakang menjadi abu-abu muda
        appBarTheme: AppBarTheme(
          color: Colors.grey[800], // Ubah warna app bar menjadi abu-abu tua
        ),
        textTheme: ThemeData.dark().textTheme.copyWith(
              bodyLarge: TextStyle(
                color: Colors.grey[700], // Ubah warna teks menjadi abu-abu tua
              ),
            ),
      ),
      home: HomeScreen(camera: firstCamera)));
}

class HomeScreen extends StatelessWidget {
  final CameraDescription camera;

  const HomeScreen({Key? key, required this.camera}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BabyMonitor')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 200, // adjust the height and width to your liking
              width: 200,
              child: Image.asset('assets/bayi.png'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(camera: camera),
                  ),
                );
              },
              child: const Text('Baby camera'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoStreamViewer(),
                  ),
                );
              },
              child: const Text('Parent view'),
            ),
          ],
        ),
      ),
    );
  }
}
