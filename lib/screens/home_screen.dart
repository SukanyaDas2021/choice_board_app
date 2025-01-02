import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../models/choice_board.dart';
import 'create_choice_board_screen.dart';
import 'choice_board_detail_screen.dart';
import 'saved_choices_screen.dart'; // Make sure you import the screen for saved choices

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChoiceBoard> choiceBoards = [];

  @override
  void initState() {
    super.initState();
    loadChoiceBoards();
  }

  Future<void> loadChoiceBoards() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? boards = prefs.getStringList('choiceBoards');
    if (boards != null) {
      setState(() {
        choiceBoards = boards.map((board) => ChoiceBoard.fromJson(jsonDecode(board))).toList();
      });
    }
  }

  void saveChoiceBoard(ChoiceBoard choiceBoard) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      choiceBoards.add(choiceBoard);
    });
    List<String> boards = choiceBoards.map((board) => jsonEncode(board.toJson())).toList();
    prefs.setStringList('choiceBoards', boards);
  }

  void updateChoiceBoard(int index, ChoiceBoard updatedBoard) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      choiceBoards[index] = updatedBoard;
    });
    List<String> boards = choiceBoards.map((board) => jsonEncode(board.toJson())).toList();
    prefs.setStringList('choiceBoards', boards);
  }

  void deleteChoiceBoard(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      choiceBoards.removeAt(index);
    });
    List<String> boards = choiceBoards.map((board) => jsonEncode(board.toJson())).toList();
    prefs.setStringList('choiceBoards', boards);
  }

  void showDeleteConfirmationDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Choice Board'),
          content: Text('Are you sure you want to delete this choice board?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[200],
              ),
              child: Text('Delete'),
              onPressed: () {
                deleteChoiceBoard(index);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Choice Board',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.indigo[900],
          ),
          textAlign: TextAlign.center,
        ),
        elevation: 10,
        shadowColor: Colors.purpleAccent,
        backgroundColor: Colors.transparent, // Set to transparent for gradient
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[100]!, Colors.indigo[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          // Create New Choice Board Button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Add New Choice',
              child: InkWell(
                onTap: () async {
                  final ChoiceBoard? newBoard = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateChoiceBoardScreen(
                        onSave: saveChoiceBoard,
                      ),
                    ),
                  );
                  if (newBoard != null) {
                    saveChoiceBoard(newBoard);
                  }
                },
                borderRadius: BorderRadius.circular(8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          // View Saved Choices Button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'View Saved Choices',
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SavedChoicesScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 24, color: Colors.indigo[800]),
                      const SizedBox(width: 4),
                      Text(
                        'Choice',
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
      body: choiceBoards.isEmpty
          ? Center(child: Text('No choice boards created yet.'))
          : ListView.builder(
        itemCount: choiceBoards.length,
        itemBuilder: (context, index) {
          final choiceBoard = choiceBoards[index];
          return Card(
            elevation: 3,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              contentPadding:
              EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              leading: choiceBoard.imagePath != null &&
                  choiceBoard.imagePath!.isNotEmpty
                  ? Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Image.file(
                  File(choiceBoard.imagePath!),
                  width: 50, // Thumbnail width
                  height: 50, // Thumbnail height
                  fit: BoxFit.cover,
                ),
              )
                  : null, // Show leading image if available, otherwise null
              title: Text(
                choiceBoard.name,
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.indigo),
                    onPressed: () async {
                      final ChoiceBoard? updatedBoard =
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CreateChoiceBoardScreen(
                                onSave: (choiceBoard) =>
                                    updateChoiceBoard(
                                        index, choiceBoard),
                                initialChoiceBoard: choiceBoards[index],
                              ),
                        ),
                      );
                      if (updatedBoard != null) {
                        updateChoiceBoard(index, updatedBoard);
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDeleteConfirmationDialog(context, index);
                    },
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChoiceBoardDetailScreen(
                      choiceBoard: choiceBoards[index],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

}
