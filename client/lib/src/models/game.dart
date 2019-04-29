import 'base.dart';

class Game extends Model {
  final String pin;
  final String token;

  Game(this.pin, this.token);

  factory Game.fromJson(dynamic json) =>
      Game(json['pin'] as String, json['token'] as String);
}

class GameAnswer extends Model {
  final String id;
  final String answer;
  final int totalFunds;

  GameAnswer(this.id, this.answer, this.totalFunds);

  factory GameAnswer.fromJson(dynamic json) => GameAnswer(json['id'] as String,
      json['answer'] as String, json['totalFunds'] as int);
}
