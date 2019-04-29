import 'dart:convert';
import 'dart:html';

import '../models/game.dart';
import '../models/player.dart';

enum GameStatus {
  lobby,
  started,
  round,
  intermission,
  ended
}

class HostReadyPacket {
  final List<Player> players;

  HostReadyPacket(this.players);

  factory HostReadyPacket.fromJson(dynamic json) =>
      HostReadyPacket((json["players"] as List<dynamic>)
          .map((playerJson) => Player.fromJson(playerJson))
          .toList());
}

class PlayerReadyPacket {
  final Player me;

  PlayerReadyPacket(this.me);

  factory PlayerReadyPacket.fromJson(dynamic json) =>
      PlayerReadyPacket(Player.fromJson(json['me']));
}

class PlayerPresencePacket {
  final Player player;

  PlayerPresencePacket(this.player);

  factory PlayerPresencePacket.fromJson(dynamic json) =>
      PlayerPresencePacket(Player.fromJson(json["player"]));
}

class RoundStartPacket {
  final String question;
  final Map<String, int> funds;
  final Duration roundDuration;

  RoundStartPacket(this.question, this.funds, this.roundDuration);

  factory RoundStartPacket.fromJson(dynamic json) => RoundStartPacket(
      json["question"] as String,
      (json["funds"] as Map).cast(),
      Duration(seconds: json["durationSeconds"] as int));
}

class AnswerUpdatePacket {
  final GameAnswer answer;

  AnswerUpdatePacket(this.answer);

  factory AnswerUpdatePacket.fromJson(dynamic json) =>
      AnswerUpdatePacket(GameAnswer.fromJson(json['answer']));
}

class RoundEndPacket {
  final String answer;
  final Map<String, int> funds;
  final Duration roundDuration;

  RoundEndPacket(this.answer, this.funds, this.roundDuration);

  factory RoundEndPacket.fromJson(dynamic json) => RoundEndPacket(
      json["answer"] as String,
      (json["funds"] as Map).cast(),
      Duration(seconds: json["intermissionSeconds"] as int));
}

abstract class GameInterface {
  WebSocket socket;
  Stream<dynamic> onPacket;

  GameInterface();

  Future<Event> connectSocket(Uri url) {
    socket = WebSocket(url.toString());
    onPacket =
        socket.onMessage.map((event) => json.decode(event.data as String));

    socket.onMessage.listen((message) => print(message.data));

    return socket.onOpen.first;
  }

  void sendPacket({int type, dynamic data}) =>
      socket.sendString(json.encode({'type': type, 'data': data}));
}
