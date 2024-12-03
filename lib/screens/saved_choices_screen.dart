import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedChoicesScreen extends StatefulWidget {
  @override
  _SavedChoicesScreenState createState() => _SavedChoicesScreenState();
}

class _SavedChoicesScreenState extends State<SavedChoicesScreen> {
  List<Map<String, dynamic>> savedChoices = [];
  AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  String? currentAudioPath;

  @override
  void initState() {
    super.initState();
    loadSavedChoices();

    // Listen to audio player state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        setState(() {
          isPlaying = false;
          currentAudioPath = null;  // Reset current audio path once the audio completes
        });
      }
    });
  }

  Future<void> loadSavedChoices() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedChoicesJson = prefs.getStringList('savedChoices');
    if (savedChoicesJson != null) {
      setState(() {
        savedChoices = savedChoicesJson
            .map((choice) => Map<String, dynamic>.from(jsonDecode(choice)))
            .toList();
      });
    }
  }

  Future<void> _playPauseAudio(String audioPath) async {
    if (currentAudioPath == audioPath && isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (currentAudioPath != audioPath) {
        await _audioPlayer.setFilePath(audioPath);
      }
      await _audioPlayer.play();
    }
    setState(() {
      isPlaying = !isPlaying;
      currentAudioPath = audioPath;
    });
  }

  Future<void> _deleteChoice(int index) async {
    bool? deleteConfirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Choice'),
          content: Text('Are you sure you want to delete this choice?'),
          actions: <Widget>[
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (deleteConfirmed == true) {
      setState(() {
        savedChoices.removeAt(index);
      });
      // Update SharedPreferences after deletion
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> updatedChoicesJson =
      savedChoices.map((choice) => jsonEncode(choice)).toList();
      await prefs.setStringList('savedChoices', updatedChoicesJson);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Choices'),
        backgroundColor: Colors.indigo[100],
      ),
      body: savedChoices.isEmpty
          ? Center(child: Text('No saved choices available.'))
          : ListView.builder(
        itemCount: savedChoices.length,
        itemBuilder: (context, index) {
          final choice = savedChoices[index];
          // Validate the audio path (it should be non-null, not empty, and not just whitespace)
          String? audioPath = choice['audioPath'];
          bool isAudioValid = audioPath != null && audioPath.trim().isNotEmpty;

          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              leading: choice['imagePath'] != null
                  ? Image.file(
                File(choice['imagePath']),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
                  : null,
              title: Text(choice['text'] ?? 'No Text'),
              subtitle: isAudioValid
                  ? Row(
                children: [
                  IconButton(
                    icon: Icon(isPlaying && currentAudioPath == audioPath
                        ? Icons.pause
                        : Icons.play_arrow),
                    onPressed: () => _playPauseAudio(audioPath),
                  ),
                ],
              )
                  : null,
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _deleteChoice(index),
              ),
            ),
          );
        },
      ),
    );
  }
}
