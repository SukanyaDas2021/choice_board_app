import 'package:flutter/material.dart';
import '../models/choice_board.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';
import 'package:reorderable_grid/reorderable_grid.dart';

class ChoiceBoardDetailScreen extends StatefulWidget {
  final ChoiceBoard choiceBoard;

  ChoiceBoardDetailScreen({required this.choiceBoard});

  @override
  _ChoiceBoardDetailScreenState createState() => _ChoiceBoardDetailScreenState();
}

class _ChoiceBoardDetailScreenState extends State<ChoiceBoardDetailScreen> {
  late AudioPlayer _audioPlayer;
  late List<Choice> choices;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    choices = List.from(widget.choiceBoard.choices);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String audioPath) async {
    try {
      await _audioPlayer.setFilePath(audioPath);
      await _audioPlayer.play();
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = choices.removeAt(oldIndex);
      choices.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  widget.choiceBoard.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold, // Make the text bold
                  ),
                ),
              ),
            ),
            if (widget.choiceBoard.imagePath != null &&
                widget.choiceBoard.imagePath!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.file(
                  File(widget.choiceBoard.imagePath!),
                  width: 50, // Thumbnail width
                  height: 50, // Thumbnail height
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final itemCount = choices.length;
          double imageWidth = screenWidth * 0.8; // 80% of screen width
          double imageHeight = screenHeight * 0.4;
          double fontsize = MediaQuery.of(context).size.width * 0.05;

          // Determine the number of columns dynamically
          int crossAxisCount;
          if (itemCount == 3) {
            crossAxisCount = 3;
          } else if (itemCount <= 4) {
            crossAxisCount = 2;
          } else {
            crossAxisCount = 3;
          }

          final mainAxisSpacing = screenWidth * 0.02;
          final crossAxisSpacing = screenWidth * 0.02;
          final padding = screenWidth * 0.02;

          final childAspectRatio = (screenWidth / crossAxisCount) /
              (screenHeight / ((itemCount / crossAxisCount).ceil()));

          return ReorderableGridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              mainAxisSpacing: mainAxisSpacing,
              crossAxisSpacing: crossAxisSpacing,
            ),
            padding: EdgeInsets.all(padding),
            itemCount: choices.length,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              final choice = choices[index];
              return Card(
                key: ValueKey(choice),
                child: GestureDetector(
                  onTap: () {
                    if (choice.audioPath.isNotEmpty) {
                      _playAudio(choice.audioPath);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: choice.imagePath.isNotEmpty
                              ? Image.file(
                            File(choice.imagePath),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                          )
                             // : Icon(Icons.image, size: screenWidth * 0.1),
                              : Center(
                            child: Text(
                              choice.text,
                              style: TextStyle(
                                fontSize: fontsize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.0),
                        choice.imagePath.isNotEmpty
                        ? Text(
                            choice.text,
                            style: TextStyle( fontSize: fontsize, fontWeight: FontWeight.bold, ),
                          )
                      : Text(" ")
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
