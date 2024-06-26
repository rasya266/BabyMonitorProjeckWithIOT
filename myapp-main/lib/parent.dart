// ignore_for_file: unused_field, prefer_final_fields

import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:video_player/video_player.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:babymonitoring/config.dart';

class VideoStreamViewer extends StatefulWidget {
  @override
  _VideoStreamViewerState createState() => _VideoStreamViewerState();
}

class _VideoStreamViewerState extends State<VideoStreamViewer> {
  VideoPlayerController? _controller;
  late io.Socket _socket;
  late List<int> _videoBuffer;
  bool _isBuffering = false;
  String _userInput = '';
  double _humidity = 0;
  double _temperature = 0;

  // Fungsi untuk menampilkan dialog input

  @override
  void initState() {
    super.initState();
    _videoBuffer = [];
    _initializeSocket();
  }

  Future<void> _showInputDialog() async {
    TextEditingController _controller = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Dialog tidak dapat ditutup dengan tap di luar
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Masukkan Room ID'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Silakan masukkan token / room-id:'),
                TextField(
                  controller: _controller,
                  decoration:
                      InputDecoration(hintText: 'Masukkan id room/token'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Hubungkan'),
              onPressed: () {
                _socket.emit('join_room', _controller.text);

                setState(() {
                  _userInput = _controller.text;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _initializeSocket() {
    _socket = io.io(
        Config().url, io.OptionBuilder().setTransports(['websocket']).build());
    _socket.onConnect((_) {
      print('Connected to socket.io server');
      _showInputDialog();
      Fluttertoast.showToast(
        msg: "Terhubung",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
    });

    _socket.on('sensorData', (data) {
      try {
        _temperature = data['data']['suhu'].toDouble();
        _humidity = data['data']['kelembapan'].toDouble();
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Error " + e.toString(),
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black,
          textColor: Colors.white,
        );
      }
    });

    _socket.on('videoChunk', (chunk) {
      setState(() {
        _videoBuffer.addAll(List<int>.from(chunk));
      });
      if (!_isBuffering) {
        _playBufferedVideo();
      }
    });

    _socket.onDisconnect((_) {
      print('Disconnected from socket.io server');
    });
  }

  Future<void> _playBufferedVideo() async {
    setState(() {
      _isBuffering = true;
    });

    if (_videoBuffer.isNotEmpty) {
      try {
        final file = File(
            '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.webm');
        await file.writeAsBytes(Uint8List.fromList(_videoBuffer));

        _controller?.dispose();
        _controller = VideoPlayerController.file(file)
          ..initialize().then((_) {
            setState(() {
              _isBuffering = false;
              _videoBuffer.clear();
              _controller!.play();
            });
          });
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Error initializing video: $e",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.black,
          textColor: Colors.white,
        );
        setState(() {
          _isBuffering = false;
        });
      }
    } else {
      setState(() {
        _isBuffering = false;
      });
      Fluttertoast.showToast(
        msg: "Buffer kosong",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Stream Viewer')),
      body: Center(
        child: Stack(
          children: [
            _isBuffering ||
                    (_controller != null && !_controller!.value.isInitialized)
                ? CircularProgressIndicator()
                : _controller != null && _controller!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      )
                    : Text('No video available'),
            Positioned(
              left: 10,
              top: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Temperature: ${_temperature.toStringAsFixed(1)}°C',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Humidity: ${_humidity.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
