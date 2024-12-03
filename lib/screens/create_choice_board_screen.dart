import 'package:flutter/material.dart';
import '../models/choice_board.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CreateChoiceBoardScreen extends StatefulWidget {
  final ChoiceBoard? initialChoiceBoard;
  final ValueChanged<ChoiceBoard> onSave;

  CreateChoiceBoardScreen({this.initialChoiceBoard, required this.onSave});

  @override
  _CreateChoiceBoardScreenState createState() => _CreateChoiceBoardScreenState();
}

class _CreateChoiceBoardScreenState extends State<CreateChoiceBoardScreen> {
  late TextEditingController _nameController;
  late List<TextEditingController> _choiceControllers;
  late List<Choice> _choices;
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  String? _boardImagePath; // Variable to hold the board image path

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialChoiceBoard?.name ?? '');
    _choices = widget.initialChoiceBoard?.choices ?? [];
    _choiceControllers = _choices.map((choice) => TextEditingController(text: choice.text)).toList();
    _boardImagePath = widget.initialChoiceBoard?.imagePath; // Initialize board image path if provided
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var controller in _choiceControllers) {
      controller.dispose();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickBoardImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _boardImagePath = pickedFile.path;
      });
    }
  }

  Future<void> _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _choices[index] = Choice(
          imagePath: pickedFile.path,
          audioPath: _choices[index].audioPath,
          text: _choices[index].text,
        );
      });
    }
  }

  Future<void> _pickAudio(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result != null && result.files.single.path != null) {
      String audioPath = result.files.single.path!;
      setState(() {
        _choices[index] = Choice(
          imagePath: _choices[index].imagePath,
          audioPath: audioPath,
          text: _choices[index].text,
        );
      });
    }
  }

  void _playPauseAudio(String audioPath) async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.setFilePath(audioPath);
      await _audioPlayer.play();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void _deleteAudio(int index) {
    setState(() {
      _choices[index] = Choice(
        imagePath: _choices[index].imagePath,
        audioPath: '',
        text: _choices[index].text,
      );
    });
  }

  void _deleteChoice(int index) {
    setState(() {
      _choices.removeAt(index);
      _choiceControllers.removeAt(index).dispose();
    });
  }

  void _showConfirmationDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm'),
          content: Text('Do you want to save or edit the choice board?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'edit');
              },
              child: Text('Edit'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, 'save');
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == 'save') {
      _saveChoiceBoard();
    }
  }

  void _saveChoiceBoard() {
    bool hasValidChoices = _choices.length >= 2 &&
        _choices.where((choice) =>
        choice.imagePath.isNotEmpty ||
            choice.text.trim().isNotEmpty &&
                choice.text.trim() != 'text').length >= 2;

    if (_nameController.text.isEmpty || !hasValidChoices) {
      _showErrorDialog();
    } else {
      final choiceBoard = ChoiceBoard(
        name: _nameController.text,
        choices: _choices,
        imagePath: _boardImagePath, // Save the board image path
      );
      widget.onSave(choiceBoard);
      Navigator.pop(context);
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text('The choice board must have at least two valid choices with image or text content or both (audio is optional).'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSaveChoiceConfirmationDialog(int index) async {
    final result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Save'),
          content: Text('Do you want to save this choice?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // Don't save
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true); // Save the choice
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _saveChoice(index); // Save the choice if confirmed
    }
  }

  void _saveChoice(int index) async {
    Choice choice = _choices[index];
    SharedPreferences prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> choiceData = {
      'text': choice.text,
      'imagePath': choice.imagePath,
      'audioPath': choice.audioPath,
    };

    List<String>? savedChoices = prefs.getStringList('savedChoices');
    savedChoices = savedChoices ?? [];
    savedChoices.add(jsonEncode(choiceData));
    await prefs.setStringList('savedChoices', savedChoices);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo[100],
        centerTitle: true,
        title: Text(
          widget.initialChoiceBoard == null ? 'Create Choice Board' : 'Edit Choice Board',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _showConfirmationDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[200],
                shadowColor: Colors.blue[900],
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(
                'Save',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickBoardImage,
              child: _boardImagePath == null
                  ? Icon(Icons.add_photo_alternate, size: 100)
                  : Image.file(File(_boardImagePath!), height: 100, width: 100),
            ),
            SizedBox(height: 8.0),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Board Name'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _choices.length,
                itemBuilder: (context, index) {
                  final choice = _choices[index];
                  TextEditingController controller = _choiceControllers[index];

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Add Save Choice button and confirmation dialog in the ListView.builder
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () => _pickImage(index),
                                  child: choice.imagePath.isEmpty
                                      ? Icon(Icons.add_photo_alternate, size: 100)
                                      : Image.file(File(choice.imagePath), height: 100, width: 100),
                                ),
                                SizedBox(height: 8.0),
                                choice.audioPath.isEmpty
                                    ? TextButton(
                                  onPressed: () => _pickAudio(index),
                                  child: Text('Select Audio'),
                                )
                                    : Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                                      onPressed: () => _playPauseAudio(choice.audioPath),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () => _pickAudio(index),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () => _deleteAudio(index),
                                    ),
                                  ],
                                ),
                                // Save Choice Button
                                ElevatedButton(
                                  onPressed: () => _showSaveChoiceConfirmationDialog(index),
                                  child: Text('Save Choice'),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(width: 16.0),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: controller,
                                  decoration: InputDecoration(labelText: 'Text'),
                                  onChanged: (value) {
                                    setState(() {
                                      _choices[index] = Choice(
                                        imagePath: choice.imagePath,
                                        audioPath: choice.audioPath,
                                        text: value,
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteChoice(index),
                          ),


                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _choices.add(Choice(imagePath: '', audioPath: '', text: ''));
                  _choiceControllers.add(TextEditingController(text: ''));
                });
              },
              child: Text('Add Choice'),
            ),
          ],
        ),
      ),
    );
  }
}
