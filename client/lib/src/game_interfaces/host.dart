import 'dart:async';

import '../events.dart';
import '../http.dart';
import '../models/game.dart';
import '../models/player.dart';
import 'base.dart';

class HostGameInterface extends GameInterface {
  final Game game;
  final Map<String, Player> players = {};
  final Map<String, GameAnswer> answers = {};

  GameStatus status = GameStatus.lobby;

  final EventStream<void> onGameStart = EventStream();
  final EventStream<void> onGameEnd = EventStream();
  final EventStream<void> onPlayerMapUpdate = EventStream();
  final EventStream<void> onAnswerMapUpdate = EventStream();
  final EventStream<RoundStartPacket> onRoundStart = EventStream();
  final EventStream<RoundEndPacket> onRoundEnd = EventStream();
  StreamSubscription<dynamic> _onPacketSubscription;

  HostGameInterface(this.game);

  Future<void> connect() async {
    await connectSocket((wsUrl()..appendPath('/ws/games/${game.pin}')).toUri());

    _onPacketSubscription = onPacket.listen((packet) {
      final type = packet["type"] as int;
      final data = packet["data"];

      switch (type) {
        case 2:
          final presencePacket = PlayerPresencePacket.fromJson(data);
          final player = presencePacket.player;
          players[player.id] = player;
          onPlayerMapUpdate.add(null);
          break;
        case 3:
          final presencePacket = PlayerPresencePacket.fromJson(data);
          final player = presencePacket.player;
          players[player.id] = player;
          onPlayerMapUpdate.add(null);
          break;
        case 4:
          status = GameStatus.started;
          onGameStart.add(null);
          break;
        case 5:
          final roundStartPacket = RoundStartPacket.fromJson(data);
          status = GameStatus.round;

          for (final entry in roundStartPacket.funds.entries) {
            players[entry.key].funds = entry.value;
          }

          answers.clear();
          onAnswerMapUpdate.add(null);

          onRoundStart.add(roundStartPacket);
          break;
        case 7:
          final answerUpdatePacket = AnswerUpdatePacket.fromJson(data);
          final answer = answerUpdatePacket.answer;
          onAnswerMapUpdate.add(null);
          answers[answer.id] = answer;
          break;
        case 10:
          final roundEndPacket = RoundEndPacket.fromJson(data);

          for (final entry in roundEndPacket.funds.entries) {
            players[entry.key].funds = entry.value;
          }

          status = GameStatus.intermission;
          onRoundEnd.add(roundEndPacket);
          break;
        case 11:
          status = GameStatus.ended;
          onRoundStart.close();
          onRoundEnd.close();
          onGameEnd.add(null);
          break;
      }
    });
  }

  Future<HostReadyPacket> identify() async {
    sendPacket(type: 0, data: {'token': game.token});

    final packetJson =
        await onPacket.firstWhere((packet) => (packet['type'] as int) == 1);

    final readyPacket = HostReadyPacket.fromJson(packetJson["data"]);

    players.addEntries(
        readyPacket.players.map((player) => MapEntry(player.id, player)));
    onPlayerMapUpdate.add(null);

    return readyPacket;
  }

  Future<void> start() async {
    sendPacket(type: 4, data: {});

    await onPacket.firstWhere((packet) => (packet['type'] as int) == 4);
  }
}
