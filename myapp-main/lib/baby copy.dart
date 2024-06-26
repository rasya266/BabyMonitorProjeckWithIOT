// ignore_for_file: prefer_const_constructors, use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:io';
import 'dart:math';
import 'dart:convert';

void main() {
  String token = generateToken();
  runApp(MaterialApp(
    home: BabyView(token: token),
  ));
}

String generateToken() {
  Random random = Random();
  String token = '';
  for (int i = 0; i < 6; i++) {
    token += random.nextInt(10).toString();
  }
  return token;
}

class BabyView extends StatefulWidget {
  final String token;

  const BabyView({Key? key, required this.token}) : super(key: key);

  @override
  _BabyViewState createState() => _BabyViewState();
}

class _BabyViewState extends State<BabyView> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;
  late bool _isRecording = false;
  int _selectedCameraIndex = 0;
  late IO.Socket _socket;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    initializeSocket();
  }

  Future<void> initializeCamera() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      _cameras = await availableCameras();
      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.medium,
      );

      await _cameraController.initialize();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing cameras: $e');
      showCameraErrorDialog(e);
    }
  }

  void showCameraErrorDialog(dynamic e) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Camera Error'),
          content: Text('Failed to initialize the camera: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void initializeSocket() {
    _socket = IO.io(
        'https://hcfjzjl0-3000.asse.devtunnels.ms/',
        IO.OptionBuilder()
            .setTransports(['websocket']) // for Flutter or Dart VM
            .build());

    _socket.connect();

    _socket.onConnect((_) {
      print('Connected to the socket server');
    });

    _socket.onDisconnect((_) {
      print('Disconnected from the socket server');
    });

    _socket.onError((data) {
      print('Socket.IO error: $data');
    });

    _socket.onConnectError((data) {
      print('Socket.IO connection error: $data');
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(generateToken()),
        ),
        body: Column(
          children: [
            Expanded(
              child: CameraPreview(_cameraController),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _isRecording ? stopRecording() : startRecording();
                  },
                  child:
                      Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    switchCamera();
                  },
                  child: Icon(Icons.switch_camera),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
  }

  Future<void> startRecording() async {
    try {
      await _cameraController.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
      recordAndSendVideo();
    } catch (e) {
      print('Error starting video recording: $e');
      showCameraErrorDialog(e);
    }
  }

  Future<void> stopRecording() async {
    try {
      await _cameraController.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
    } catch (e) {
      print('Error stopping video recording: $e');
      showCameraErrorDialog(e);
    }
  }

  void switchCamera() async {
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
      initializeCamera();
    });
  }

  Future<void> recordAndSendVideo() async {
    while (_isRecording) {
      await Future.delayed(Duration(seconds: 10));
      if (!_isRecording) break;

      final XFile videoFile = await _cameraController.stopVideoRecording();
      final String videoPath = videoFile.path;

      print('Video recorded: $videoPath');

      await sendVideoToServer(videoPath);

      if (_isRecording) {
        await _cameraController.startVideoRecording();
      }
    }
  }

  Future<void> sendVideoToServer(String path) async {
    try {
      final File videoFile = File(path);
      final List<int> videoBytes = await videoFile.readAsBytes();
      final String base64Video = base64Encode(videoBytes);
      _socket.emit('videoChunk', {'data': base64Video});
      print('Video sent to server');
    } catch (e) {
      print('Error sending video to server: $e');
      showCameraErrorDialog(e);
    }
  }
}
