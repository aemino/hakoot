import 'dart:async';
import 'dart:convert';
import 'dart:html';

import '../http.dart';
import '../models/game.dart';
import 'view.dart';

class HostCreateView extends View {
  TextAreaElement templateInput;
  ButtonElement doneButton;

  StreamSubscription<Event> doneButtonClickStream;
  Completer<Game> _onGameCreateCompleter;
  Future<Game> get onGameCreate => _onGameCreateCompleter.future;

  HostCreateView() : super(querySelector('#view-host-create'));

  @override
  Future<void> init() async {
    templateInput =
        viewElement.querySelector('#template-input') as TextAreaElement;
    doneButton = viewElement.querySelector('#done-button') as ButtonElement;

    doneButtonClickStream = doneButton.onClick.listen(onDoneButtonClick);

    _onGameCreateCompleter = Completer();

    await super.init();
  }

  @override
  Future<void> dispose() async {
    if (_onGameCreateCompleter.isCompleted) _onGameCreateCompleter = null;

    await doneButtonClickStream?.cancel();

    _onGameCreateCompleter?.complete();
    await doneButtonClickStream?.cancel();

    await super.dispose();
  }

  Future<void> onDoneButtonClick(Event event) async {
    final triviaTemplate = templateInput.value;

    try {
      print("sending req");
      print((apiUrl()..appendPath('/games')).toUri());
      print({'triviaTemplate': triviaTemplate});
      final response = await client.post(
          (apiUrl()..appendPath('/games')).toUri(),
          body: {'triviaTemplate': triviaTemplate});
      print("got response");

      print(response.statusCode);
      print(response.body);

      final game = Game.fromJson(json.decode(response.body));
      _onGameCreateCompleter.complete(game);
    } catch (err) {}
  }
}
