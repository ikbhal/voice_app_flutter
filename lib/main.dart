// import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Recorder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AudioRecorderScreen(),
    );
  }
}

class AudioRecorderScreen extends StatefulWidget {
  @override
  _AudioRecorderScreenState createState() => _AudioRecorderScreenState();
}

class _AudioRecorderScreenState extends State<AudioRecorderScreen> {
  AudioPlayer audioPlayer = AudioPlayer();
  String? recordingPath;
  List<String> messages = [];
  FlutterSoundRecorder? _audioRecorder;

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    fetchMessages();
  }

  Future<void> startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    final recordingName = DateTime.now().toIso8601String();
    final path = '${directory.path}/$recordingName.wav';
    recordingPath = path;

    // Codec.pcm16;
    // await audioPlayer.startRecorder(toFile: path, codec: Codec.pcm16);
    // await _audioRecorder!.openAudioSession();
    // _audioRecorder = FlutterSoundRecorder();
    await _audioRecorder!.startRecorder(toFile: path);

    Fluttertoast.showToast(msg: 'Recording started');
  }

  Future<void> stopRecording() async {
    if (recordingPath != null) {
      // await audioPlayer.stopRecorder();
      if (_audioRecorder != null) {
        await _audioRecorder!.stopRecorder();
        // _audioRecorder = null;
      }

      Fluttertoast.showToast(msg: 'Recording stopped');
    }
  }

  Future<void> playMessage(String path) async {
    await audioPlayer.stop();
    await audioPlayer.play(path, isLocal: true);
  }

  Future<void> fetchMessages() async {
    final apiUrl = 'http://localhost:5000/list_messages';
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body)['messages'];
      setState(() {
        messages = responseData.cast<String>();
      });
    }
  }

  Future<void> addMessage(String path) async {
    final apiUrl = 'http://localhost:5000/add_message';
    final uri = Uri.parse(apiUrl);
    final request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('audio', path));

    final response = await request.send();

    if (response.statusCode == 200) {
      Fluttertoast.showToast(msg: 'Message added successfully');
      await fetchMessages();
    } else {
      Fluttertoast.showToast(msg: 'Failed to add message');
    }
  }

  Future<void> deleteMessage(String filename) async {
    final apiUrl = 'http://localhost:5000/delete_message/$filename';
    final response = await http.delete(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      Fluttertoast.showToast(msg: 'Message deleted successfully');
      await fetchMessages();
    } else {
      Fluttertoast.showToast(msg: 'Failed to delete message');
    }
  }

  Future<void> confirmDeleteMessage(String filename) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                deleteMessage(filename);
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildMessageTile(String filename) {
    final fileName = filename.split('_').last;

    return ListTile(
      title: Text(fileName),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: () {
          confirmDeleteMessage(filename);
        },
      ),
      onTap: () {
        playMessage(filename);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Recorder'),
      ),
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (BuildContext context, int index) {
          return buildMessageTile(messages[index]);
        },
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        children: [
          SpeedDialChild(
            child: Icon(Icons.mic),
            label: 'Start Recording',
            onTap: startRecording,
          ),
          SpeedDialChild(
            child: Icon(Icons.stop),
            label: 'Stop Recording',
            onTap: stopRecording,
          ),
        ],
      ),
    );
  }
}
