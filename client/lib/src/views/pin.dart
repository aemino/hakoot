import 'dart:async';
import 'dart:convert';
import 'dart:html';

import '../http.dart';
import '../models/game.dart';
import 'view.dart';

int pinLength = 6;

class PinView extends View {
  InputElement pinInput;

  StreamSubscription<Event> inputChangeStream;
  Timer pinCheckDebounce;
  Completer<Game> _onGameJoinCompleter;
  Future<Game> get onGameJoin => _onGameJoinCompleter.future;

  PinView() : super(querySelector('#view-pin'));

  @override
  Future<void> init() async {
    pinInput = viewElement.querySelector('#pin-input') as InputElement;
    inputChangeStream = pinInput.onInput.listen(onInputChange);

    _onGameJoinCompleter = Completer();

    await super.init();
  }

  @override
  Future<void> dispose() async {
    if (_onGameJoinCompleter.isCompleted) _onGameJoinCompleter = null;

    pinCheckDebounce?.cancel();
    await inputChangeStream?.cancel();
    _onGameJoinCompleter?.complete();

    await super.dispose();
  }

  void onInputChange(Event event) {
    final pinValue = pinInput.value;
    if (pinValue.length != pinLength) return;

    pinCheckDebounce?.cancel();
    pinCheckDebounce =
        Timer(Duration(milliseconds: 500), () => usePin(pinValue));
  }

  Future<void> usePin(String pin) async {
    if (pin == "\$HOST\$") {
      _onGameJoinCompleter.complete(Game(pin, null));
      return;
    }

    try {
      final response =
          await client.get((apiUrl()..appendPath('/games/$pin')).toUri());
      
      if (response.statusCode != 200) {
        throw Error();
      }

      final game = Game.fromJson(json.decode(response.body));

      Timer.run(
          () => transientClasses(pinInput, ['success'], Duration(seconds: 1)));

      // Actually complete with a websocket url or something...
      _onGameJoinCompleter.complete(game);
    } catch (err) {
      Timer.run(
          () => transientClasses(pinInput, ['failure'], Duration(seconds: 1)));
    }
  }
}
