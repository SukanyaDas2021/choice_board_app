import 'package:flutter/material.dart';
import '../models/choice_board.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';

class ChoiceInputWidget extends StatefulWidget {
  final Choice choice;
  final ValueChanged<Choice> onChoiceChanged;

  ChoiceInputWidget({required this.choice, required this.onChoiceChanged});

  @override
  _ChoiceInputWidgetState createState() => _ChoiceInputWidgetState();
}

class _ChoiceInputWidgetState extends State<ChoiceInputWidget> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _textController = TextEditingController(text: widget.choice.text.isEmpty ? 'text' : widget.choice.text);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      print('Saving image path: ${pickedFile}');
      widget.onChoiceChanged(Choice(
        imagePath: pickedFile.path,
        audioPath: widget.choice.audioPath,
        text: _textController.text,
      ));
    }
  }

  Future<void> _pickAudio(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);

    if (result != null && result.files.single.path != null) {
      String audioPath = result.files.single.path!;
      widget.onChoiceChanged(Choice(
        imagePath: widget.choice.imagePath,
        audioPath: audioPath,
        text: _textController.text,
      ));
    }
  }

  void _playPauseAudio() async {
    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.setFilePath(widget.choice.audioPath);
      await _audioPlayer.play();
    }
    setState(() {
      isPlaying = !isPlaying;
    });
  }

  void _deleteAudio() {
    widget.onChoiceChanged(Choice(
      imagePath: widget.choice.imagePath,
      audioPath: '',
      text: _textController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Column
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(context),
                    child: widget.choice.imagePath.isEmpty
                        ? Icon(Icons.add_photo_alternate, size: 100)
                        : Image.file(File(widget.choice.imagePath), height: 100, width: 100),
                  ),
                  SizedBox(height: 8.0),
                  widget.choice.audioPath.isEmpty
                      ? TextButton(
                    onPressed: () => _pickAudio(context),
                    child: Text('Select Audio'),
                  )
                      : Row(
                    children: [
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: _playPauseAudio,
                      ),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _pickAudio(context),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: _deleteAudio,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.0),
            // Text Field Column
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _textController,
                    decoration: InputDecoration(labelText: 'Text'),
                    onChanged: (value) {
                      widget.onChoiceChanged(Choice(
                        imagePath: widget.choice.imagePath,
                        audioPath: widget.choice.audioPath,
                        text: value,
                      ));
                    },
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
