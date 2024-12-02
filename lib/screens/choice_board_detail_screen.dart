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
            if (widget.choiceBoard.imagePath != null && widget.choiceBoard.imagePath!.isNotEmpty)
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
          final itemCount = widget.choiceBoard.choices.length;

          // Determine the number of columns
          int crossAxisCount;

          if (itemCount == 3) {
            crossAxisCount = 3; // 3 items in a single row
          } else if (itemCount <= 4) {
            crossAxisCount = 2; // 2 items per row if 4 or fewer items
          } else {
            crossAxisCount = 3; // Default to 3 columns
          }

          // Calculate dynamic spacing based on screen width
          final mainAxisSpacing = screenWidth * 0.02; // 2% of screen width
          final crossAxisSpacing = screenWidth * 0.02; // 2% of screen width
          final padding = screenWidth * 0.02; // 2% of screen width

          // Adjust childAspectRatio to fit all items within the screen height
          final childAspectRatio = (screenWidth / crossAxisCount) / (screenHeight / ((itemCount / crossAxisCount).ceil()));

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
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2.0), // Black border with width of 2.0
                  ),
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
