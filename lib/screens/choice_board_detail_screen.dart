import 'package:flutter/material.dart';
import '../models/choice_board.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:io';

class ChoiceBoardDetailScreen extends StatefulWidget {
  final ChoiceBoard choiceBoard;

  ChoiceBoardDetailScreen({required this.choiceBoard});

  @override
  _ChoiceBoardDetailScreenState createState() => _ChoiceBoardDetailScreenState();
}

class _ChoiceBoardDetailScreenState extends State<ChoiceBoardDetailScreen> {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.choiceBoard.name)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final itemCount = widget.choiceBoard.choices.length;

          // Calculate the number of columns and rows based on the number of items
          int crossAxisCount;
          int rowCount;

          if (itemCount <= 2) {
            crossAxisCount = itemCount;
            rowCount = 1;
          } else if (itemCount <= 4) {
            crossAxisCount = 2;
            rowCount = (itemCount / 2).ceil();
          } else if (itemCount <= 6) {
            crossAxisCount = 3;
            rowCount = (itemCount / 3).ceil();
          } else {
            crossAxisCount = 4;
            rowCount = (itemCount / 4).ceil();
          }

          // Calculate dynamic spacing based on screen width
          final mainAxisSpacing = screenWidth * 0.02; // 2% of screen width
          final crossAxisSpacing = screenWidth * 0.02; // 2% of screen width
          final padding = screenWidth * 0.02; // 2% of screen width

          // Adjust childAspectRatio to fit all items within the screen height
          final childAspectRatio = (screenWidth / crossAxisCount) / (screenHeight / rowCount);

          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              mainAxisSpacing: mainAxisSpacing,
              crossAxisSpacing: crossAxisSpacing,
            ),
            padding: EdgeInsets.all(padding),
            itemCount: widget.choiceBoard.choices.length,
            itemBuilder: (context, index) {
              final choice = widget.choiceBoard.choices[index];
              return GestureDetector(
                onTap: () {
                  if (choice.audioPath.isNotEmpty) {
                    _playAudio(choice.audioPath);
                  }
                },
                child: Container(
                  color: Colors.grey[300],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: choice.imagePath.isNotEmpty
                            ? Image.file(
                          File(choice.imagePath),
                          width: double.infinity, // Fit the width of the container
                          height: double.infinity, // Fit the height of the container
                          fit: BoxFit.contain, // Ensure the whole image is displayed
                        )
                            : Icon(Icons.image, size: 50), // Set a default size if no image
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        choice.text,
                        style: TextStyle(
                          fontSize: 18, // Increase the font size
                          fontWeight: FontWeight.bold, // Make the text bold
                        ),
                      ),
                    ],
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
