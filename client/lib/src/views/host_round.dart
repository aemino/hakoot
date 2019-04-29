import 'dart:async';
import 'dart:html';

import '../components/game_answer.dart';
import '../game_interfaces/base.dart';
import '../game_interfaces/host.dart';
import 'view.dart';

class HostRoundView extends View {
  final HostGameInterface gameInterface;
  final RoundStartPacket round;

  HeadingElement questionElement;
  HeadingElement timerElement;
  DivElement answerList;

  Timer roundTimer;

  StreamSubscription<void> answerListUpdateSubscription;

  HostRoundView(this.gameInterface, this.round)
      : super(querySelector('#view-host-round'));

  @override
  Future<void> init() async {
    questionElement = viewElement.querySelector('#round-question')
        as HeadingElement
      ..text = round.question;

    var remainingRoundSeconds = round.roundDuration.inSeconds;
    timerElement = viewElement.querySelector('#round-timer') as HeadingElement
      ..text = 'time remaining: $remainingRoundSeconds';

    roundTimer = Timer.periodic(Duration(seconds: 1), (_) {
      remainingRoundSeconds--;

      if (remainingRoundSeconds <= 0) roundTimer?.cancel();

      timerElement.text = 'time remaining: $remainingRoundSeconds';
    });

    answerList = viewElement.querySelector('#answer-list') as DivElement;
    answerListUpdateSubscription = gameInterface.onAnswerMapUpdate.listen((_) {
      answerList.children = gameInterface.answers.values
          .map((answer) => GameAnswerComponent(answer).make())
          .toList();
    });

    await super.init();
  }

  @override
  Future<void> dispose() async {
    roundTimer?.cancel();
    await answerListUpdateSubscription?.cancel();

    await super.dispose();
  }
}
