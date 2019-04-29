import 'dart:async';
import 'dart:html';

import '../components/game_answer.dart';
import '../game_interfaces/base.dart';
import '../game_interfaces/player.dart';
import '../models/game.dart';
import 'view.dart';

class RoundView extends View {
  final PlayerGameInterface gameInterface;
  final RoundStartPacket round;

  InputElement answerInput;
  ButtonElement submitButton;
  SpanElement fundsElement;
  SpanElement betsElement;
  DivElement answerList;

  StreamSubscription<Event> submitButtonClickSubscription;
  StreamSubscription<void> answerListUpdateSubscription;
  List<StreamSubscription<Event>> betButtonClickSubscriptions = [];

  RoundView(this.gameInterface, this.round)
      : super(querySelector('#view-round'));

  @override
  Future<void> init() async {
    answerInput = viewElement.querySelector('#answer-input') as InputElement;
    submitButton = viewElement.querySelector('#submit-button') as ButtonElement;

    submitButtonClickSubscription =
        submitButton.onClick.listen(onSubmitButtonClick);

    fundsElement = viewElement.querySelector('#funds') as SpanElement
      ..text = gameInterface.me.funds.toString();
    
    betsElement = viewElement.querySelector('#bets') as SpanElement
      ..text = gameInterface.me.bets.toString();

    gameInterface.onFundsUpdate
        .listen((funds) => fundsElement.text = funds.toString());
    
    gameInterface.onBetsUpdate
        .listen((bets) => betsElement.text = bets.toString());

    answerList = viewElement.querySelector('#answer-list') as DivElement;
    answerListUpdateSubscription = gameInterface.onAnswerMapUpdate.listen((_) {
      answerList.children = gameInterface.answers.values.map((answer) {
        final component = GameAnswerComponent(answer).make();

        component.children.addAll(List.generate(2, (_) => BRElement()));

        final buttons = [50, 100, 500, 1000].map((amount) {
          final button = ButtonElement()..text = 'bet ${amount.toString()}';
          final subscription = button.onClick
              .listen((event) => onBetButtonClick(event, answer, amount));

          betButtonClickSubscriptions.add(subscription);
          return button;
        });

        component.children.addAll(buttons);

        return component;
      }).toList();
    });

    await super.init();
  }

  @override
  Future<void> dispose() async {
    await submitButtonClickSubscription?.cancel();
    await answerListUpdateSubscription?.cancel();

    await Future.wait(betButtonClickSubscriptions
        .map((subscription) => subscription?.cancel())
        .where((subscription) => subscription != null));

    await super.dispose();
  }

  Future<void> onSubmitButtonClick(Event event) async {
    final answer = answerInput.value;

    if (answer.isEmpty || answer.length > 20) {
      return;
    }

    answerInput.value = '';
    await gameInterface.suggestAnswer(answer);
  }

  Future<void> onBetButtonClick(
      Event event, GameAnswer answer, int amount) async {
    await gameInterface.bet(answer, amount);
  }
}
