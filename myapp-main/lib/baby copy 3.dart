// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'dart:async';
// import 'package:fluttertoast/fluttertoast.dart';


// class CameraScreen extends StatefulWidget {
//   final CameraDescription camera;

//   const CameraScreen({Key? key, required this.camera}) : super(key: key);

//   @override
//   _CameraScreenState createState() => _CameraScreenState();
// }

// class _CameraScreenState extends State<CameraScreen> {
//   late CameraController _controller;
//   late Future<void> _initializeControllerFuture;
//   late IO.Socket _socket;
//   late Timer _timer;
//   bool _isRecording = false;
//   late FlutterFFmpeg _ffmpeg;
//   late String _videoPath;
//   late String _audioPath;
//   ResolutionPreset _currentResolution = ResolutionPreset.low;

//   @override
//   void initState() {
//     super.initState();
//     _initializeController();
//   }

//   void _initializeController() {
//     _controller = CameraController(
//       widget.camera,
//       _currentResolution,
//       enableAudio: false, // Tetap menggunakan audio
//     );
//     _initializeControllerFuture = _controller.initialize();

//     // Inisialisasi socket.io
//     _socket = IO.io('https://hcfjzjl0-3000.asse.devtunnels.ms/', IO.OptionBuilder().setTransports(['websocket']).build());
//     _socket.onConnect((_) {
//       print('Connected to socket.io server');
//       Fluttertoast.showToast(
//         msg: "Terhubung",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.black,
//         textColor: Colors.white,
//       );
//     });

//     _socket.onDisconnect((_) {
//       print('Disconnected from socket.io server');
//     });

//     _initializeControllerFuture.then((_) {
//       // Mulai merekam video
//       _startVideoRecording();
//     });
//   }

//   Future<void> _startVideoRecording() async {
//     if (_isRecording) return;

//     try {
//       await _controller.startVideoRecording();
//       _isRecording = true;
//       _timer = Timer.periodic(Duration(seconds: 10), (Timer t) => _sendVideoSegment());
//       Fluttertoast.showToast(
//         msg: "siap rekam",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.black,
//         textColor: Colors.white,
//       );
//     } catch (e) {
//       print('Error starting video recording: $e');
//       Fluttertoast.showToast(
//         msg: "Error rekam",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.black,
//         textColor: Colors.white,
//       );
//     }
//   }

//   Future<void> _sendVideoSegment() async {
//     if (!_isRecording) return;

//     try {
//       final videoFile = await _controller.stopVideoRecording();
//       final videoBytes = await videoFile.readAsBytes();
//       var _videoPath  = videoFile.path;

//       // Ekstrak audio
//       _audioPath = '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.aac';
//       await _ffmpeg.execute('-i $_videoPath -vn -acodec copy $_audioPath');

//       // Kompres video tanpa audio
//       final compressedVideoPath = '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.mp4';
//       await _ffmpeg.execute('-i $_videoPath -vcodec libx264 -an $compressedVideoPath');

//       // Gabungkan video dan audio
//       final outputPath = '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}_output.mp4';
//       await _ffmpeg.execute('-i $compressedVideoPath -i $_audioPath -c copy $outputPath');

//       final outputBytes = await File(outputPath).readAsBytes();

//       // Kirim data video dalam chunk yang lebih kecil
//       const int chunkSize = 64 * 1024; // 64 KB
//       for (int i = 0; i < outputBytes.length; i += chunkSize) {
//         final end = (i + chunkSize < outputBytes.length) ? i + chunkSize : outputBytes.length;
//         _socket.emit('videoChunk', outputBytes.sublist(i, end));
//       }

//       Fluttertoast.showToast(
//         msg: "Mengirim data ke server",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.black,
//         textColor: Colors.white,
//       );

//       // Mulai merekam video lagi
//       await _controller.startVideoRecording();
//     } catch (e) {
//       print('Error sending video segment: $e');
//       Fluttertoast.showToast(
//         msg: "Gagal mengirim data ke server",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.black,
//         textColor: Colors.white,
//       );
//     }
//   }

//   Future<Uint8List> _compressVideo(Uint8List videoBytes) async {
//     // Contoh sederhana kompresi, disarankan menggunakan library khusus kompresi video
//     // Seperti ffmpeg atau lainnya untuk hasil yang lebih baik
//     return videoBytes.sublist(0, videoBytes.length ~/ 2); // Hanya contoh, mengambil setengah ukuran asli
//   }

//   void _onResolutionChanged(ResolutionPreset resolution) {
//     setState(() {
//       _currentResolution = resolution;
//       _initializeController();
//     });
//   }

//   @override
//   void dispose() {
//     _timer.cancel();
//     _controller.dispose();
//     _socket.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Camera'),
//         actions: [
//           PopupMenuButton<ResolutionPreset>(
//             onSelected: _onResolutionChanged,
//             itemBuilder: (BuildContext context) {
//               return <PopupMenuEntry<ResolutionPreset>>[
//                 const PopupMenuItem<ResolutionPreset>(
//                   value: ResolutionPreset.low,
//                   child: Text('Low'),
//                 ),
//                 const PopupMenuItem<ResolutionPreset>(
//                   value: ResolutionPreset.medium,
//                   child: Text('Medium'),
//                 ),
//                 const PopupMenuItem<ResolutionPreset>(
//                   value: ResolutionPreset.high,
//                   child: Text('High'),
//                 ),
//                 const PopupMenuItem<ResolutionPreset>(
//                   value: ResolutionPreset.veryHigh,
//                   child: Text('Very High'),
//                 ),
//                 const PopupMenuItem<ResolutionPreset>(
//                   value: ResolutionPreset.ultraHigh,
//                   child: Text('Ultra High'),
//                 ),
//                 const PopupMenuItem<ResolutionPreset>(
//                   value: ResolutionPreset.max,
//                   child: Text('Max'),
//                 ),
//               ];
//             },
//           ),
//         ],
//       ),
//       body: FutureBuilder<void>(
//         future: _initializeControllerFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.done) {
//             return CameraPreview(_controller);
//           } else {
//             return Center(child: CircularProgressIndicator());
//           }
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         child: Icon(Icons.camera),
//         onPressed: () async {
//           try {
//             await _initializeControllerFuture;
//             await _startVideoRecording();
//           } catch (e) {
//             print(e);
//           }
//         },
//       ),
//     );
//   }
// }
