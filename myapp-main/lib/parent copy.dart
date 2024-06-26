// ignore_for_file: use_super_parameters, prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ParentView extends StatefulWidget {
  final String token;

  const ParentView({Key? key, required this.token}) : super(key: key);

  @override
  _ParentViewState createState() => _ParentViewState();
}

class _ParentViewState extends State<ParentView> {
  final _tokenController = TextEditingController();

// ignore: unused_field, unnecessary_new
  static SocketClient client = SocketClient();

  @override
  void initState() {
    super.initState();
    _tokenController.text = widget.token;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Parent View'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: 'Token',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                print(
                    'Accessing baby camera with token: ${_tokenController.text}');
              },
              child: Text('Access Baby Camera'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ParentView(
      token: '',
    ),
  ));
}

class SocketClient {
  late IO.Socket _socket;

  String url = "http://localhost:3000/";

  SocketClient() {
    _socket = IO.io(url, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket.connect();

    _socket.onConnect((_) {
      print('Connection established');
    });

    _socket.onDisconnect((_) {
      print('Connection disconnected');
    });

    _socket.on('event', (data) {
      print('Received data: $data');
    });
  }

  void emit(String event, [dynamic data]) {
    _socket.emit(event, data);
  }

  void dispose() {
    _socket.disconnect();
    _socket.dispose();
  }
}
