
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:camera/camera.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'dart:async';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'dart:math';
// import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

// class CameraScreen extends StatefulWidget {
//   final CameraDescription camera;

//   const CameraScreen({Key? key, required this.camera}) : super(key: key);

//   @override
//   _CameraScreenState createState() => _CameraScreenState();
// }

// String generateToken() {
//   Random random = Random();
//   String token = '';
//   for (int i = 0; i < 6; i++) {
//     token += random.nextInt(10).toString();
//   }
//   return token;
// }

// class _CameraScreenState extends State<CameraScreen> {
//   late CameraController _controller;
//   late Future<void> _initializeControllerFuture;
//   late IO.Socket _socket;
//   late Timer _timer;
//   bool _isRecording = false;
//   ResolutionPreset _currentResolution = ResolutionPreset.medium;

//   @override
//   void initState() {
//     super.initState();
//     _initializeController();
//   }

  

//   void _initializeController() {
//     _controller = CameraController(
//       widget.camera,
//       _currentResolution,
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
//       _timer = Timer.periodic(Duration(seconds: 5), (Timer t) => _sendVideoSegment());
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
//       print(videoFile.path);
//       print(await File(videoFile.path).length());
//       String path = videoFile.path;
//       String opath = path;

//       // String opath = "${videoFile.path.replaceAll(".mp4", "")}2.mp4";
//       await FFmpegKit.execute('-framerate 120 -i $path $opath').then((session) async {

//         final videoBytes = await File(opath).readAsBytes();
//         print("After opet");
//         print(await File(opath).length());
//         // Kirim data video ke server
//         _socket.emit('videoChunk', videoBytes);
//         Fluttertoast.showToast(
//           msg: "Mengirim data ke server",
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.black,
//           textColor: Colors.white,
//         );

//          // Mulai merekam video lagi
//          await _controller.startVideoRecording();
//       });

      
     
//     } catch (e) {
//       print('Error sending video segment: $e');
//       Fluttertoast.showToast(
//         msg: "Gagal mengirim data ke server ",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.black,
//         textColor: Colors.white,
//       );
//     }
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
//         title: Text(generateToken()),
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