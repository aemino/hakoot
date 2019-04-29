import 'dart:async';
import 'dart:html';
import 'dart:math';

import '../components/leaderboard.dart';
import '../game_interfaces/host.dart';
import 'view.dart';

class HostResultsView extends View {
  final HostGameInterface gameInterface;

  HeadingElement winnerNameElement;
  DivElement leaderboardElement;

  HostResultsView(this.gameInterface)
      : super(querySelector('#view-host-results'));

  @override
  Future<void> init() async {
    final playersByFunds = gameInterface.players.values.toList()
      ..sort((a, b) => b.funds - a.funds);

    winnerNameElement = (viewElement.querySelector('#winner-name')
        as HeadingElement)
      ..text = playersByFunds[0].displayName;

    leaderboardElement =
        (viewElement.querySelector('#leaderboard') as DivElement)
          ..children = [
            LeaderboardComponent(
                    playersByFunds.sublist(0, min(playersByFunds.length, 5)))
                .make()
          ];

    await super.init();
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
  }
}
