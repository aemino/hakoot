import 'dart:async';
import 'dart:html';
import 'dart:math';

import '../components/leaderboard.dart';
import '../game_interfaces/base.dart';
import '../game_interfaces/host.dart';
import 'view.dart';

class HostIntermissionView extends View {
  final HostGameInterface gameInterface;
  final RoundEndPacket round;

  HeadingElement answerElement;
  DivElement leaderboardElement;
  ButtonElement nextButton;

  StreamSubscription<Event> nextButtonClickSubscription;

  HostIntermissionView(this.gameInterface, this.round)
      : super(querySelector('#view-host-intermission'));

  @override
  Future<void> init() async {
    answerElement = (viewElement.querySelector('#answer') as HeadingElement)
      ..text = round.answer;

    final playersByFunds = gameInterface.players.values.toList()
      ..sort((a, b) => b.funds - a.funds);

    leaderboardElement =
        (viewElement.querySelector('#leaderboard') as DivElement)
          ..children = [
            LeaderboardComponent(
                    playersByFunds.sublist(0, min(playersByFunds.length, 5)))
                .make()
          ];
    
    nextButton = viewElement.querySelector('#next-button') as ButtonElement;
    nextButtonClickSubscription =
        nextButton.onClick.listen(onNextButtonClick);

    await super.init();
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
  }

  Future<void> onNextButtonClick(Event event) async {
    await gameInterface.start();
  }
}
