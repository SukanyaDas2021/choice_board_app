class ChoiceBoard {
  String name;
  List<Choice> choices;

  ChoiceBoard({required this.name, required this.choices});

  Map<String, dynamic> toJson() => {
    'name': name,
    'choices': choices.map((choice) => choice.toJson()).toList(),
  };

  factory ChoiceBoard.fromJson(Map<String, dynamic> json) {
    return ChoiceBoard(
      name: json['name'],
      choices: (json['choices'] as List).map((item) => Choice.fromJson(item)).toList(),
    );
  }
}

class Choice {
  String imagePath;
  String audioPath;
  String text;

  Choice({this.imagePath = '', this.audioPath = '', this.text = ''});

  Map<String, dynamic> toJson() => {
    'imagePath': imagePath,
    'audioPath': audioPath,
    'text': text,
  };

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      imagePath: json['imagePath'],
      audioPath: json['audioPath'],
      text: json['text'],
    );
  }
}
