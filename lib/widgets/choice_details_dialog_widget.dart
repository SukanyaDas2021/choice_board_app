import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChoiceDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> choice;
  final VoidCallback onClose;

  ChoiceDetailsDialog({required this.choice, required this.onClose});

  @override
  Widget build(BuildContext context) {
    String? text = choice['text'];
    String? imagePath = choice['imagePath'];
    String? audioPath = choice['audioPath'];

    bool isImageValid = imagePath != null && imagePath.trim().isNotEmpty;
    bool isAudioValid = audioPath != null && audioPath.trim().isNotEmpty;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Display larger image if valid
                  isImageValid
                      ? Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.5, // 50% of screen height
                      maxWidth: MediaQuery.of(context).size.width * 0.9,  // 90% of screen width
                    ),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain, // Ensures the image fits inside the container
                    ),
                  )
                      : Icon(
                    Icons.image_not_supported,
                    size: 150,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),

                  // Display text
                  Text(
                    text ?? 'No Text',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),

                  // Audio playback button
                  if (isAudioValid)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.play_arrow, size: 36),
                          onPressed: () async {
                            // Play audio logic here
                            final audioPlayer = AudioPlayer();
                            await audioPlayer.setFilePath(audioPath!);
                            await audioPlayer.play();
                          },
                        ),
                        SizedBox(width: 16),
                        IconButton(
                          icon: Icon(Icons.pause, size: 36),
                          onPressed: () async {
                            // Pause audio logic here
                            final audioPlayer = AudioPlayer();
                            await audioPlayer.pause();
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          // Close button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onClose,
              child: CircleAvatar(
                backgroundColor: Colors.red,
                child: Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
