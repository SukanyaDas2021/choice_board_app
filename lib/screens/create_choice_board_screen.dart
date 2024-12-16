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
  _CreateChoiceBoardScreenState createState() =>
      _CreateChoiceBoardScreenState();
}

class _CreateChoiceBoardScreenState extends State<CreateChoiceBoardScreen> {
  late TextEditingController _nameController;
  late List<TextEditingController> _choiceControllers;
  late List<Choice> _choices;
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  String? _boardImagePath; // Variable to hold the board image path
  bool showSaveButton = false; // Flag to show "Save Choice" button for the newly added choice

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.initialChoiceBoard?.name ?? '');
    _choices = widget.initialChoiceBoard?.choices ?? [];
    _choiceControllers = _choices
        .map((choice) => TextEditingController(text: choice.text))
        .toList();
    _boardImagePath = widget.initialChoiceBoard
        ?.imagePath; // Initialize board image path if provided
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
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.audio);

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
        _choices
                .where((choice) =>
                    choice.imagePath.isNotEmpty ||
                    choice.text.trim().isNotEmpty &&
                        choice.text.trim() != 'text')
                .length >=
            2;

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
          content: Text(
              'The choice board must have at least two valid choices with image or text content or both (audio is optional).'),
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Save Choice?"),
          content: Text("Do you want to save this choice?"),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                // Mark choice as saved
                if (_choices[index].text.trim().isEmpty) {
                  // Show error message if the text is empty
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: A choice must have text to be saved!')),
                  );
                  return;
                }
                setState(() {
                  _choices[index].saved = true;
                  _choices[index] = _choices[index].copyWith(saved: true);
                });

                // Save the choice to SharedPreferences
                SharedPreferences prefs = await SharedPreferences.getInstance();
                List<String> savedChoicesJson = prefs.getStringList('savedChoices') ?? [];

                // Add the current choice to the saved choices list
                savedChoicesJson.add(jsonEncode(_choices[index].toJson()));

                // Save the updated list back to SharedPreferences
                await prefs.setStringList('savedChoices', savedChoicesJson);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Choice saved for future use!')),
                );

                Navigator.of(context).pop();
              },
              child: Text("Yes"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("No"),
            ),
          ],
        );
      },
    );
  }


  // Function to pick saved choices from SharedPreferences
  Future<void> _pickSavedChoice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedChoices = prefs.getStringList('savedChoices');
    savedChoices = savedChoices ?? [];

    // Check if there are no saved choices
    if (savedChoices.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('No Saved Choices'),
            content: Text('There are no saved choices to select from.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return; // Exit the function early if no saved choices exist
    }

    final selectedChoice = await showDialog<Choice>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(
            'Select from Saved Choice',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.deepPurple,
            ),
           ),
          children: savedChoices?.map((choiceData) {
            if (choiceData == null || choiceData.isEmpty) {
              return Container(); // Skip empty or null choiceData
            }

            try {
              Map<String, dynamic> decodedChoice = jsonDecode(choiceData);
              Choice choice = Choice(
                text: decodedChoice['text'] ?? '',
                imagePath: decodedChoice['imagePath'] ?? '',
                audioPath: decodedChoice['audioPath'] ?? '',
                saved: decodedChoice['saved'] ?? '',
              );

              return SimpleDialogOption(
                onPressed: () {
                  choice.saved = true;
                  Navigator.pop(context, choice);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Display Image if available
                    choice.imagePath.isNotEmpty
                        ? Image.file(
                      File(choice.imagePath),
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                    )
                        : SizedBox(width: 50, height: 50), // Placeholder for alignment
                    SizedBox(width: 10), // Spacing between elements

                    // Display Text
                    Expanded(
                      child: Text(
                        choice.text,
                        style: TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),

                    SizedBox(width: 10), // Spacing between elements

                    // Display Audio Play button if audio exists
                    choice.audioPath.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.play_arrow),
                      onPressed: () => _playPauseAudio(choice.audioPath),
                    )
                        : Container(), // Empty container if no audio
                  ],
                ),
              );
            } catch (e) {
              // If decoding fails, return an empty container (skip this choice)
              return Container();
            }
          }).toList(),
        );
      },
    );

    if (selectedChoice != null) {
      setState(() {
        // Check if the selected choice already exists
        bool isChoiceExist =
        _choices.any((choice) => choice.text == selectedChoice.text);
        if (!isChoiceExist) {
          _choices.add(selectedChoice);
          _choiceControllers
              .add(TextEditingController(text: selectedChoice.text));
        }
      });
    }
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
      body: SingleChildScrollView(
        child: Padding(
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
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _choices.length,
                itemBuilder: (context, index) {
                  final choice = _choices[index];
                  TextEditingController controller = _choiceControllers[index];
                  showSaveButton = widget.initialChoiceBoard == null ? true : false;
                  // Determine if the choice is newly added
                  bool isNewChoice = widget.initialChoiceBoard == null && choice.saved;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                if (!choice.saved)
                                  ElevatedButton(
                                    onPressed: () => _showSaveChoiceConfirmationDialog(index),
                                    child: Text('Save Choice'),
                                  ), // Hide for existing choices
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
                                        saved: choice.saved,
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

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _pickSavedChoice,
                    child: Text('Select from Saved Choice'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _choices.add(Choice(imagePath: '', audioPath: '', text: '', saved: false));
                        _choiceControllers.add(TextEditingController(text: ''));
                        //showSaveButton = true;
                      });
                    },
                    child: Text('Add New Choice'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}
