import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:video_player/video_player.dart';
import 'dart:typed_data';
import 'dart:io';

class VideoStreamViewer extends StatefulWidget {
  @override
  _VideoStreamViewerState createState() => _VideoStreamViewerState();
}

class _VideoStreamViewerState extends State<VideoStreamViewer> {
  VideoPlayerController? _controller;
  late IO.Socket _socket;
  late List<int> _videoBuffer;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    _videoBuffer = [];
    _initializeSocket();
  }

  void _initializeSocket() {
    _socket = IO.io('https://hcfjzjl0-3000.asse.devtunnels.ms/', IO.OptionBuilder().setTransports(['websocket']).build());
    _socket.onConnect((_) {
      print('Connected to socket.io server');
      Fluttertoast.showToast(
        msg: "Terhubung",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
    });

    _socket.on('videoChunk', (chunk) {
      Fluttertoast.showToast(
        msg: "Menerima chunk",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
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
    Fluttertoast.showToast(
      msg: "Play start",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black,
      textColor: Colors.white,
    );
    if (_videoBuffer.isNotEmpty) {
      try {
        final file = File('${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}.webm');
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
        child: _isBuffering || (_controller != null && !_controller!.value.isInitialized)
            ? CircularProgressIndicator()
            : _controller != null && _controller!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  )
                : Text('No video available'),
      ),
    );
  }
}
