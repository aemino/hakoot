import 'base.dart';

class Player extends Model {
  final String id;
  final String displayName;
  int funds = 0;
  int bets = 0;

  Player(this.id, this.displayName, this.funds);

  factory Player.fromJson(dynamic json) => Player(json['id'] as String,
      json['displayName'] as String, json['funds'] as int);
}
