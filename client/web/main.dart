import 'dart:async';
import 'dart:html' hide WebSocket;

import 'package:client/client.dart';

Future<void> main() async {
  querySelectorAll('.init-disabled')
      .forEach((element) => element.classes.remove('init-disabled'));

  final pinView = PinView();

  await pinView.init();
  final game = await pinView.onGameJoin;
  await pinView.dispose();

  if (game.pin == "\$HOST\$") {
    await hostMain();
  } else {
    await playerMain(game);
  }
}

Future<void> hostMain() async {
  final hostCreateView = HostCreateView();
  await hostCreateView.init();
  final game = await hostCreateView.onGameCreate;
  await hostCreateView.dispose();

  final gameInterface = HostGameInterface(game);
  final onRoundStart = StreamIterator(gameInterface.onRoundStart.buffered());
  final onRoundEnd = StreamIterator(gameInterface.onRoundEnd.buffered());

  await gameInterface.connect();
  await gameInterface.identify();

  final hostLobbyView = HostLobbyView(gameInterface);
  await hostLobbyView.init();

  await hostLobbyView.onGameStart;

  await gameInterface.start();
  await hostLobbyView.dispose();

  View currentView;
  while (true) {
    print(0);
    if (!await onRoundStart.moveNext()) {
      await currentView?.dispose();
      break;
    }
    print(1);

    await currentView?.dispose();
    currentView = HostRoundView(gameInterface, onRoundStart.current);
    await currentView.init();
    await onRoundEnd.moveNext();
    await currentView.dispose();
    currentView = HostIntermissionView(gameInterface, onRoundEnd.current);
    await currentView.init();
  }

  final resultsView = HostResultsView(gameInterface);
  await resultsView.init();
}

Future<void> playerMain(Game game) async {
  final gameInterface = PlayerGameInterface(game);
  final onRoundStart = StreamIterator(gameInterface.onRoundStart.buffered());
  final onRoundEnd = StreamIterator(gameInterface.onRoundEnd.buffered());
  
  await gameInterface.connect();
  final ready = await gameInterface.identify();

  final lobbyView = LobbyView(ready.me);
  await lobbyView.init();

  await gameInterface.onGameStart.first;

  gameInterface.onFundsUpdate.listen(print);

  await lobbyView.dispose();

  View currentView;
  while (true) {
    print(0);
    if (!await onRoundStart.moveNext()) {
      await currentView?.dispose();
      break;
    }
    print(1);

    await currentView?.dispose();
    currentView = RoundView(gameInterface, onRoundStart.current);
    await currentView.init();
    await onRoundEnd.moveNext();
    await currentView.dispose();
    currentView = IntermissionView(gameInterface, onRoundEnd.current);
    await currentView.init();
  }

  final resultsView = ResultsView(gameInterface);
  await resultsView.init();
}
