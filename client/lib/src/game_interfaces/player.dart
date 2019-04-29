import 'dart:async';

import '../events.dart';
import '../http.dart';
import '../models/game.dart';
import '../models/player.dart';
import 'base.dart';

class PlayerGameInterface extends GameInterface {
  final Game game;
  Player me;
  GameStatus status = GameStatus.lobby;

  int previousFunds = 0;

  final Map<String, int> playerFunds = {};
  final Map<String, GameAnswer> answers = {};

  final EventStream<void> onGameStart = EventStream();
  final EventStream<void> onGameEnd = EventStream();
  final EventStream<void> onAnswerMapUpdate = EventStream();
  final EventStream<int> onFundsUpdate = EventStream();
  final EventStream<int> onBetsUpdate = EventStream();
  final EventStream<RoundStartPacket> onRoundStart = EventStream();
  final EventStream<RoundEndPacket> onRoundEnd = EventStream();
  StreamSubscription<dynamic> _onPacketSubscription;

  PlayerGameInterface(this.game);

  Future<void> connect() async {
    await connectSocket((wsUrl()..appendPath('/ws/games/${game.pin}')).toUri());

    _onPacketSubscription = onPacket.listen((packet) {
      final type = packet["type"] as int;
      final data = packet["data"];

      switch (type) {
        case 4:
          status = GameStatus.started;
          onGameStart.add(null);
          break;
        case 5:
          final roundStartPacket = RoundStartPacket.fromJson(data);
          status = GameStatus.round;

          final newFunds = roundStartPacket.funds[me.id];
          previousFunds = newFunds;
          me.funds = newFunds;
          me.bets = 0;
          onFundsUpdate.add(me.funds);
          onBetsUpdate.add(me.bets);

          playerFunds.addAll(roundStartPacket.funds);

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
          status = GameStatus.intermission;

          final newFunds = roundEndPacket.funds[me.id];
          me.funds = newFunds;
          onFundsUpdate.add(me.funds);

          playerFunds.addAll(roundEndPacket.funds);

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

  Future<PlayerReadyPacket> identify() async {
    sendPacket(type: 0, data: {'token': game.token});

    final packetJson =
        await onPacket.firstWhere((packet) => (packet['type'] as int) == 1);

    final readyPacket = PlayerReadyPacket.fromJson(packetJson["data"]);
    me = readyPacket.me;

    return readyPacket;
  }

  Future<void> suggestAnswer(String answer) async {
    sendPacket(type: 6, data: {'answer': answer});
  }

  Future<void> bet(GameAnswer answer, int amount) async {
    if (me.funds < amount) return;

    sendPacket(type: 8, data: {'id': answer.id, 'amount': amount});
    me
      ..funds -= amount
      ..bets += amount;

    onFundsUpdate.add(me.funds);
    onBetsUpdate.add(me.bets);
  }
}
