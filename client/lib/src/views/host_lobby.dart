import 'dart:async';
import 'dart:html';

import '../game_interfaces/host.dart';
import '../models/game.dart';
import 'view.dart';

class HostLobbyView extends View {
  ButtonElement startButton;
  DivElement playerList;

  final HostGameInterface gameInterface;
  Game get game => gameInterface.game;

  StreamSubscription<Event> startButtonClickSubscription;
  Completer<void> _onGameStartCompleter;
  Future<void> get onGameStart => _onGameStartCompleter.future;

  StreamSubscription<void> playerListUpdateSubscription;

  HostLobbyView(this.gameInterface) : super(querySelector('#view-host-lobby'));

  @override
  Future<void> init() async {
    startButton = viewElement.querySelector('#start-button') as ButtonElement;
    startButtonClickSubscription =
        startButton.onClick.listen(onStartButtonClick);

    _onGameStartCompleter = Completer();

    viewElement.querySelector('#game-pin').text = game.pin;

    playerList = viewElement.querySelector('#player-list') as DivElement;
    playerListUpdateSubscription = gameInterface.onPlayerMapUpdate.listen((_) {
      playerList.children = gameInterface.players.values
          .map((player) => SpanElement()..text = player.displayName)
          .toList();
    });

    await super.init();
  }

  @override
  Future<void> dispose() async {
    if (_onGameStartCompleter.isCompleted) _onGameStartCompleter = null;

    await startButtonClickSubscription?.cancel();
    _onGameStartCompleter?.complete();

    await playerListUpdateSubscription?.cancel();

    await super.dispose();
  }

  void onStartButtonClick(Event event) {
    _onGameStartCompleter.complete();
  }
}
