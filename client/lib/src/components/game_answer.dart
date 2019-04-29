import 'dart:html';

import '../models/game.dart';

class GameAnswerComponent {
  final GameAnswer answer;

  GameAnswerComponent(this.answer);

  DivElement make() => DivElement()
    ..className = 'game-answer'
    ..children = [
      ParagraphElement()
        ..className = 'answer'
        ..text = answer.answer,
      SpanElement()
        ..className = 'funds'
        ..text = 'total bets: ${answer.totalFunds.toString()}'
    ];
}
