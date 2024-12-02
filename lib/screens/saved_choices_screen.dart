import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:image_picker/image_picker.dart';
import '../models/database_helper.dart';
import '../models/choice_board.dart';
import 'dart:io';
import '../widgets/choice_input_widget.dart';

class SavedChoicesScreen extends StatefulWidget {
  @override
  _SavedChoicesScreenState createState() => _SavedChoicesScreenState();
}

class _SavedChoicesScreenState extends State<SavedChoicesScreen> {
  List<Map<String, dynamic>> _savedChoices = [];
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadSavedChoices();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSavedChoices() async {
    List<Map<String, dynamic>> choices = await DatabaseHelper().getSavedChoices();
    setState(() {
      _savedChoices = choices;
    });
  }

  Future<void> _playAudio(String audioPath) async {
    try {
      await _audioPlayer.setFilePath(audioPath);
      await _audioPlayer.play();
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final updatedChoice = {
        ..._savedChoices[index],
        'image': pickedFile.path,
      };

      // Update the choice in the database
      await DatabaseHelper().updateSavedChoice(_savedChoices[index]['id'], updatedChoice);

      // Reload the choices
      _loadSavedChoices();
    }
  }

  void _addNewChoice() async {
    Choice newChoice = Choice(imagePath: '', audioPath: '', text: '');
    bool isSaved = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChoiceInputWidget(
                choice: newChoice,
                onChoiceChanged: (choice) {
                  setState(() {
                    newChoice = choice;
                  });
                },
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (newChoice.text.isNotEmpty ||
                          newChoice.imagePath.isNotEmpty ||
                          newChoice.audioPath.isNotEmpty) {
                        isSaved = true;
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Cannot save an empty choice.')),
                        );
                      }
                    },
                    child: Text('Save'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (isSaved) {
      await DatabaseHelper().insertSavedChoice({
        'text': newChoice.text,
        'image': newChoice.imagePath,
        'sound': newChoice.audioPath,
      });
      _loadSavedChoices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Saved Choices'),
      ),
      body: _savedChoices.isEmpty
          ? Center(child: Text('No saved choices yet.'))
          : ListView.builder(
        itemCount: _savedChoices.length,
        itemBuilder: (context, index) {
          var choice = _savedChoices[index];
          return ListTile(
            leading: GestureDetector(
              onTap: () => _pickImage(index),
              child: choice['image'] != null && File(choice['image']).existsSync()
                  ? Image.file(
                File(choice['image']),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
                  : Icon(Icons.image, size: 50, color: Colors.grey),
            ),
            title: Text(choice['text'] ?? 'No text'),
            subtitle: Row(
              children: [
                if (choice['sound'] != null && choice['sound'].isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.play_arrow),
                    onPressed: () {
                      _playAudio(choice['sound']);
                    },
                  ),
                Expanded(
                  child: Text(choice['sound'] != null && choice['sound'].isNotEmpty
                      ? 'Tap the play icon to hear sound'
                      : ''),
                ),
              ],
            ),
            onTap: () {
              // Logic for using the saved choice
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewChoice,
        child: Icon(Icons.add),
      ),
    );
  }
}
