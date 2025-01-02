import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/choice_details_dialog_widget.dart';

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

    _audioPlayer.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        setState(() {
          isPlaying = false;
          currentAudioPath = null;
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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> updatedChoicesJson =
      savedChoices.map((choice) => jsonEncode(choice)).toList();
      await prefs.setStringList('savedChoices', updatedChoicesJson);
    }
  }


  Future<void> _editChoice(int index) async {
    final choice = savedChoices[index];
    String? updatedText = choice['text'];
    String? updatedImagePath = choice['imagePath'];
    String? updatedAudioPath = choice['audioPath'];
    bool? updatedSaved = choice['saved'];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Choice'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text field for editing text
                    TextField(
                      controller: TextEditingController(text: updatedText),
                      decoration: InputDecoration(labelText: 'Text'),
                      onChanged: (value) {
                        updatedText = value;
                        updatedSaved = false;
                      },
                    ),
                    SizedBox(height: 20),

                    // Display image or choose image button
                    updatedImagePath != null && File(updatedImagePath!).existsSync()
                        ? Column(
                      children: [
                        Image.file(File(updatedImagePath!), height: 100, width: 100),
                        TextButton.icon(
                          onPressed: () async {
                            final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                            if (pickedFile != null) {
                              setState(() {
                                updatedImagePath = pickedFile.path;
                                updatedSaved = false;
                              });
                            }
                          },
                          icon: Icon(Icons.edit),
                          label: Text('Change Image'),
                        ),
                      ],
                    )
                        : TextButton.icon(
                      onPressed: () async {
                        final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            updatedImagePath = pickedFile.path;
                          });
                        }
                      },
                      icon: Icon(Icons.add_a_photo),
                      label: Text('Choose Image'),
                    ),
                    SizedBox(height: 20),

                    // Audio controls
                    updatedAudioPath != null && updatedAudioPath!.trim().isNotEmpty
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.play_arrow),
                          onPressed: () async {
                            await _audioPlayer.setFilePath(updatedAudioPath!);
                            await _audioPlayer.play();
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () async {
                            final pickedAudio = await FilePicker.platform.pickFiles(type: FileType.audio);
                            if (pickedAudio != null) {
                              setState(() {
                                updatedAudioPath = pickedAudio.files.single.path!;
                                updatedSaved = false;
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              updatedAudioPath = null;
                            });
                          },
                        ),
                      ],
                    )
                        : TextButton.icon(
                      onPressed: () async {
                        final pickedAudio = await FilePicker.platform.pickFiles(type: FileType.audio);
                        if (pickedAudio != null) {
                          setState(() {
                            updatedAudioPath = pickedAudio.files.single.path!;
                          });
                        }
                      },
                      icon: Icon(Icons.audiotrack),
                      label: Text('Add Audio'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Save changes to the choice
                    setState(() {
                      savedChoices[index] = {
                        'text': updatedText,
                        'imagePath': updatedImagePath,
                        'audioPath': updatedAudioPath,
                        'saved': updatedSaved,
                      };
                    });

                    _updateChoicesInPrefs(); // Persist changes
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    // Force screen rebuild by calling setState after dialog closes
    setState(() {});
  }


  Future<void> _addNewChoice() async {
    String? newText;
    String? newImagePath;
    String? newAudioPath;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Create New Choice',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.deepPurple,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: InputDecoration(labelText: 'Text'),
                      onChanged: (value) {
                        newText = value;
                      },
                    ),
                    SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: () async {
                        final pickedFile = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );
                        if (pickedFile != null) {
                          setState(() {
                            newImagePath = pickedFile.path;
                          });
                        }
                      },
                      icon: Icon(Icons.add_a_photo),
                      label: Text(newImagePath == null ? 'Add Image' : 'Change Image'),
                    ),
                    if (newImagePath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Image.file(
                          File(newImagePath!),
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: () async {
                        final pickedAudio = await FilePicker.platform.pickFiles(
                          type: FileType.audio,
                        );
                        if (pickedAudio != null) {
                          setState(() {
                            newAudioPath = pickedAudio.files.single.path!;
                          });
                        }
                      },
                      icon: Icon(Icons.audiotrack),
                      label: Text(newAudioPath == null ? 'Add Audio' : 'Change Audio'),
                    ),
                    if (newAudioPath != null)
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                newAudioPath = null;
                              });
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (newText != null && newText!.trim().isNotEmpty) {
                      // Update the state
                      setState(() {
                        savedChoices.add({
                          'text': newText,
                          'imagePath': newImagePath,
                          'audioPath': newAudioPath,
                          'saved': true,
                        });
                      });

                      // Save the updated list to SharedPreferences
                      await _updateChoicesInPrefs();

                      // Refresh the UI by reloading the choices
                      await loadSavedChoices();

                      // Close the dialog
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateChoicesInPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> updatedChoicesJson =
    savedChoices.map((choice) => jsonEncode(choice)).toList();
    await prefs.setStringList('savedChoices', updatedChoicesJson);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _searchChoice() async {
    final searchText = await showDialog<String>(
      context: context,
      builder: (context) {
        TextEditingController searchController = TextEditingController();
        return AlertDialog(
          title: Text('Search Choice'),
          content: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Enter choice text',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null); // Cancel search
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(searchController.text);
              },
              child: Text('Search'),
            ),
          ],
        );
      },
    );

    if (searchText != null && searchText.trim().isNotEmpty) {
      final foundChoices = savedChoices.where((choice) =>
      choice['text']?.toLowerCase().contains(searchText.toLowerCase()) ?? false)
          .toList();

      if (foundChoices.isEmpty) {
        showDialog(
          context: context,
          builder: (context) =>
              AlertDialog(
                title: Text('No Results'),
                content: Text('No saved choices match your search.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
        );
      }
      else {
        // Do something with foundChoices (e.g., display them in a new dialog or update UI)
        showDialog(
            context: context,
            builder: (context)
            {
              final screenWidth = MediaQuery.of(context).size.width;
              return AlertDialog(
                title: Text('Search Results', textAlign: TextAlign.center,),
                content: SizedBox(
                  width: screenWidth * 0.75, //double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: foundChoices.length,
                    itemBuilder: (context, index) {
                      final choice = foundChoices[index];
                      String? imagePath = choice['imagePath'];
                      String? audioPath = choice['audioPath'];
                      bool isImageValid =
                          imagePath != null && imagePath
                              .trim()
                              .isNotEmpty;
                      bool isAudioValid =
                          audioPath != null && audioPath
                              .trim()
                              .isNotEmpty;

                      return ListTile(
                        leading: isImageValid
                            ? Image.file(
                          File(imagePath),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                            : SizedBox(width: 50, height: 50),
                        // Placeholder for alignment
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                choice['text'] ?? 'No Text',
                                style: TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (isAudioValid)
                              IconButton(
                                icon: Icon(Icons.play_arrow),
                                onPressed: () => _playPauseAudio(audioPath),
                              ),
                          ],
                        ),
                            //: null,
                        // Empty if no audio
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Close'),
                  ),
                ],
              );
            }
          );
        }
      }
    }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Saved Choices',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal[900],
            ),
            textAlign: TextAlign.center,
          ),
          elevation: 10,
          shadowColor: Colors.tealAccent,
          backgroundColor: Colors.transparent, // Set to transparent for gradient
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal[100]!, Colors.green[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tooltip(
                message: 'Add new choice',
                child: InkWell(
                  onTap: _addNewChoice,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purpleAccent.withOpacity(0.4),
                          blurRadius: 8,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.add, size: 24, color: Colors.indigo[800]),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.indigo[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Tooltip(
                message: 'Search choices',
                child: InkWell(
                  onTap: _searchChoice,
                  borderRadius: BorderRadius.circular(50),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purpleAccent.withOpacity(0.4),
                          blurRadius: 8,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 24, color: Colors.indigo[800]),
                        const SizedBox(width: 4),
                        Text(
                          'Search',
                          style: TextStyle(
                            color: Colors.indigo[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: savedChoices.isEmpty
          ? Center(child: Text('No saved choices available.'))
          : ListView.builder(
        itemCount: savedChoices.length,
        itemBuilder: (context, index) {
          final choice = savedChoices[index];
          String? imagePath = choice['imagePath'];
          String? audioPath = choice['audioPath'];
          bool isImageValid =
              imagePath != null && imagePath.trim().isNotEmpty;
          bool isAudioValid =
              audioPath != null && audioPath.trim().isNotEmpty;

          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16), //EdgeInsets.all(10),
            child: ListTile(
              leading: isImageValid
                  ? Image.file(
                  File(imagePath),
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue[800],),
                    onPressed: () => _editChoice(index),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red,),
                    onPressed: () => _deleteChoice(index),
                  ),
                ],
              ),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => ChoiceDetailsDialog(
                    choice: choice,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                );
              },
              tileColor: Colors.lightBlue[50],
            ),
          );
        },
      ),
    );
  }
}
